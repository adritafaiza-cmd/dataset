module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal FIFO buffer module
    async_fifo_buffer #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_buffer (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule

module async_fifo_buffer #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 2 ** LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH + 1;

    reg [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] write_ptr_gray, read_ptr_gray;
    reg [ADDR_WIDTH-1:0] write_ptr_gray_synced, read_ptr_gray_synced;
    reg [ADDR_WIDTH-1:0] write_ptr, read_ptr;
    reg full, empty;

    // Gray code conversion functions
    function [ADDR_WIDTH-1:0] binary_to_gray;
        input [ADDR_WIDTH-1:0] bin;
        binary_to_gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH-1:0] gray_to_binary;
        input [ADDR_WIDTH-1:0] gray;
        reg [ADDR_WIDTH-1:0] bin;
        integer i;
        bin = gray;
        for (i = ADDR_WIDTH - 2; i >= 0; i = i - 1) begin
            bin[i] = bin[i + 1] ^ gray[i];
        end
        gray_to_binary = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr_gray <= 0;
            full <= 0;
        end else if (src_valid_i && !full) begin
            fifo_mem[gray_to_binary(write_ptr_gray)] <= src_data_i;
            write_ptr_gray <= binary_to_gray(gray_to_binary(write_ptr_gray) + 1);
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_ptr_gray_synced <= 0;
        end else begin
            write_ptr_gray_synced <= write_ptr_gray;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr_gray <= 0;
            empty <= 1;
        end else if (dst_valid_o && dst_ready_i) begin
            read_ptr_gray <= binary_to_gray(gray_to_binary(read_ptr_gray) + 1);
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr_gray_synced <= 0;
        end else begin
            read_ptr_gray_synced <= read_ptr_gray;
        end
    end

    // Decode gray pointers to binary
    assign write_ptr = gray_to_binary(write_ptr_gray);
    assign read_ptr = gray_to_binary(read_ptr_gray_synced);

    // Determine full and empty states
    assign full = (write_ptr_gray == binary_to_gray(gray_to_binary(read_ptr_gray_synced) + DEPTH));
    assign empty = (write_ptr_gray_synced == read_ptr_gray);

    // Ready and valid signals
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;
    assign dst_data_o = fifo_mem[read_ptr];

endmodule
