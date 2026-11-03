module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals for source and destination sides
    logic [WIDTH-1:0] src_data_reg;
    logic src_valid_reg;
    logic src_ready_reg;
    logic dst_valid_reg;
    logic dst_ready_reg;

    // Instantiate the FIFO_gray_clearable helper module
    fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_clearable_inst (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_clear_i(src_clear_i),
        .src_clear_pending_o(src_clear_pending_o),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_clear_i(dst_clear_i),
        .dst_clear_pending_o(dst_clear_pending_o),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule
