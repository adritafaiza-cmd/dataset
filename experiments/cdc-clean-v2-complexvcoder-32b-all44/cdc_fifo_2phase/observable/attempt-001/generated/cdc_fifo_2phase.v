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

    // FIFO Buffer Instance
    fifo_buffer #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_buffer_inst (
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

module fifo_buffer #(
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

    // Internal Signals
    reg  [WIDTH-1:0]     fifo_memory [0:(2**LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]   write_pointer_gray, write_pointer_gray_synced;
    reg  [LOG_DEPTH:0]   read_pointer_gray, read_pointer_gray_synced;
    reg  [LOG_DEPTH:0]   write_pointer_bin;
    reg  [LOG_DEPTH:0]   read_pointer_bin;
    reg                  full_flag;
    reg                  empty_flag;

    // Binary to Gray code conversion
    function [LOG_DEPTH:0] bin_to_gray;
        input [LOG_DEPTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        reg [LOG_DEPTH:0] bin;
        bin = gray;
        for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Write Pointer Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_pointer_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            write_pointer_gray <= bin_to_gray(write_pointer_bin + 1);
        end
    end

    // Read Pointer Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_pointer_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            read_pointer_gray <= bin_to_gray(read_pointer_bin + 1);
        end
    end

    // Synchronize Gray Code Pointers
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_pointer_gray_synced <= 0;
        end else begin
            write_pointer_gray_synced <= write_pointer_gray;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_pointer_gray_synced <= 0;
        end else begin
            read_pointer_gray_synced <= read_pointer_gray;
        end
    end

    // Convert Gray Code Pointers to Binary
    always @(*) begin
        write_pointer_bin = gray_to_bin(write_pointer_gray);
        read_pointer_bin = gray_to_bin(read_pointer_gray_synced);
    end

    // Full Flag Logic
    always @(*) begin
        full_flag = (write_pointer_gray_synced == (read_pointer_gray + 1'b1));
    end

    // Empty Flag Logic
    always @(*) begin
        empty_flag = (write_pointer_gray_synced == read_pointer_gray_synced);
    end

    // Ready and Valid Logic
    assign src_ready_o = !full_flag & src_valid_i;
    assign dst_valid_o = !empty_flag & dst_ready_i;

    // Write Data to FIFO
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_memory[write_pointer_bin] <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo_memory[write_pointer_bin] <= src_data_i;
        end
    end

    // Read Data from FIFO
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= fifo_memory[read_pointer_bin];
        end
    end

endmodule
