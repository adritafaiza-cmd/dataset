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

    async_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) async_fifo_inst (
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

module async_fifo #(
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

    reg [WIDTH-1:0] fifo_memory [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] write_ptr_gray, read_ptr_gray;
    reg [LOG_DEPTH:0] write_ptr_gray_sync, read_ptr_gray_sync;
    wire [LOG_DEPTH-1:0] write_ptr_bin, read_ptr_bin, write_ptr_bin_sync, read_ptr_bin_sync;
    wire full, empty;

    // Gray to Binary conversion
    function [LOG_DEPTH-1:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        begin
            gray2bin = gray[LOG_DEPTH];
            for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
            end
        end
    endfunction

    // Binary to Gray conversion
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH-1:0] bin;
        integer i;
        begin
            bin2gray = bin[LOG_DEPTH-1];
            for (i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
                bin2gray[i] = bin[i+1] ^ bin[i];
            end
            bin2gray[LOG_DEPTH] = bin[LOG_DEPTH-1];
        end
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo_memory[write_ptr_bin] <= src_data_i;
            write_ptr_gray <= write_ptr_gray + 1;
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_ptr_gray_sync <= 0;
        end else begin
            write_ptr_gray_sync <= write_ptr_gray;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            read_ptr_gray <= read_ptr_gray + 1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr_gray_sync <= 0;
        end else begin
            read_ptr_gray_sync <= read_ptr_gray;
        end
    end

    // Calculate binary pointers
    assign write_ptr_bin = gray2bin(write_ptr_gray);
    assign read_ptr_bin = gray2bin(read_ptr_gray);
    assign write_ptr_bin_sync = gray2bin(write_ptr_gray_sync);
    assign read_ptr_bin_sync = gray2bin(read_ptr_gray_sync);

    // Calculate full and empty flags
    assign full = (write_ptr_bin_sync[LOG_DEPTH-1:0] == read_ptr_bin[LOG_DEPTH-1:0] && write_ptr_bin_sync[LOG_DEPTH] != read_ptr_bin[LOG_DEPTH]);
    assign empty = (write_ptr_bin_sync == read_ptr_bin_sync);

    // Source ready signal
    assign src_ready_o = !full;

    // Destination valid signal
    assign dst_valid_o = !empty;

    // Destination data output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= fifo_memory[read_ptr_bin];
        end
    end

endmodule
