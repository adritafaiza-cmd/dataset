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

    localparam DEPTH = 2**LOG_DEPTH;

    // Sync FIFO for source clock domain
    fifo_sync #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_sync_src (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o)
    );

    // Sync FIFO for destination clock domain
    fifo_sync #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_sync_dst (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(fifo_sync_src.dst_data_o),
        .valid_i(fifo_sync_src.dst_valid_o),
        .ready_o(fifo_sync_src.dst_ready_i)
    );

    // 2-phase FIFO logic
    fifo_2phase #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_2phase_inst (
        .src_clk_i(dst_clk_i),
        .src_rst_ni(dst_rst_ni),
        .src_data_i(fifo_sync_dst.dst_data_o),
        .src_valid_i(fifo_sync_dst.dst_valid_o),
        .src_ready_o(fifo_sync_dst.dst_ready_i),
        .dst_clk_i(src_clk_i),
        .dst_rst_ni(src_rst_ni),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule
