module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

    // Internal signals
    logic [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_sync, rd_ptr_gray_sync;
    logic [LOG_DEPTH-1:0] wr_ptr_gray_n, rd_ptr_gray_n;
    logic full_gray, empty_gray;
    logic [WIDTH-1:0] dst_data_gray;

    // Gray encoding functions
    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        gray_encode = bin ^ (bin >> 1);
    endfunction

    function [LOG_DEPTH-1:0] gray_decode;
        input [LOG_DEPTH-1:0] gray;
        logic [LOG_DEPTH-1:0] bin;
        int i;
        bin = gray;
        for (i = 1; i < LOG_DEPTH; i = i + 1) begin
            bin = bin ^ (gray >> i);
        end
        gray_decode = bin;
    endfunction

    // FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_gray <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full_gray) begin
                mem[gray_encode(wr_ptr_gray)] <= src_data_i;
                wr_ptr_gray <= wr_ptr_gray + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_gray <= 0;
        end else begin
            if (dst_ready_i && !empty_gray) begin
                rd_ptr_gray <= rd_ptr_gray + 1;
            end
        end
    end

    // Gray encoding and decoding for pointers
    assign wr_ptr_gray_sync = gray_decode(gray_encode(wr_ptr_gray));
    assign rd_ptr_gray_sync = gray_decode(gray_encode(rd_ptr_gray));

    // Full and empty flags
    assign full_gray = gray_encode(wr_ptr_gray_sync) == gray_encode(rd_ptr_gray_sync) + 1;
    assign empty_gray = gray_encode(wr_ptr_gray_sync) == gray_encode(rd_ptr_gray_sync);

    // Destination output
    assign dst_data_gray = mem[gray_encode(rd_ptr_gray_sync)];
    assign dst_data_o = dst_data_gray;
    assign dst_valid_o = !empty_gray;

    // Source ready signal
    assign src_ready_o = !full_gray;

endmodule
