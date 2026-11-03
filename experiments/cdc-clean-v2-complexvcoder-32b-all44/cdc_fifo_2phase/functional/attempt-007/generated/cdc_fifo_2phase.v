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

    // FIFO core instance
    fifo_async #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_async_inst (
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

module fifo_async #(
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

    localparam DEPTH = 2**LOG_DEPTH;

    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [LOG_DEPTH:0] src_wr_ptr, dst_rd_ptr;
    reg [LOG_DEPTH:0] src_wr_ptr_gray, dst_wr_ptr_gray, dst_rd_ptr_gray;
    reg [LOG_DEPTH:0] src_wr_ptr_gray_sync, dst_wr_ptr_gray_sync;
    reg src_full, dst_empty;

    // Gray code conversion functions
    function [LOG_DEPTH:0] bin_to_gray;
        input [LOG_DEPTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        reg [LOG_DEPTH:0] bin;
        bin = gray;
        for (i = LOG_DEPTH-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray_to_bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && !src_full) begin
            fifo_mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
        end
    end

    // Synchronize src_wr_ptr_gray to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_wr_ptr_gray_sync <= 0;
        else
            src_wr_ptr_gray_sync <= src_wr_ptr_gray;
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1;
            dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
        end
    end

    // Synchronize dst_wr_ptr_gray to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_wr_ptr_gray_sync <= 0;
        else
            dst_wr_ptr_gray_sync <= dst_wr_ptr_gray;
    end

    // Calculate full and empty flags
    assign src_full = (src_wr_ptr_gray_sync == bin_to_gray({src_wr_ptr[LOG_DEPTH], ~src_wr_ptr[LOG_DEPTH-1:0]}));
    assign dst_empty = (dst_wr_ptr_gray_sync == dst_rd_ptr_gray);

    // Outputs
    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;
    assign dst_data_o = fifo_mem[dst_rd_ptr[LOG_DEPTH-1:0]];

endmodule
