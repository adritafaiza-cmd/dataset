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

    // Internal signals
    logic [WIDTH-1:0]       src_fifo_data_o;
    logic                   src_fifo_valid_o;
    logic                   src_fifo_ready_i;
    logic                   src_fifo_clear_pending;
    logic                   dst_fifo_data_o;
    logic                   dst_fifo_valid_o;
    logic                   dst_fifo_ready_i;
    logic                   dst_fifo_clear_pending;

    // src_fifo instance
    async_fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_fifo_ready_i),
        .clear_i(dst_clear_i),
        .clear_pending_o(src_fifo_clear_pending),
        .data_o(src_fifo_data_o),
        .valid_o(src_fifo_valid_o)
    );

    // dst_fifo instance
    async_fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_o(dst_fifo_data_o),
        .valid_o(dst_fifo_valid_o),
        .ready_o(dst_fifo_ready_i),
        .clear_i(src_clear_i),
        .clear_pending_o(dst_fifo_clear_pending),
        .data_i(dst_data_o),
        .valid_i(dst_valid_o)
    );

    // Connect src_fifo and dst_fifo
    assign src_fifo.ready_i = dst_fifo.valid_i;
    assign dst_fifo.ready_i = src_fifo.valid_i;

    // Clear pending outputs
    assign src_clear_pending_o = src_fifo_clear_pending;
    assign dst_clear_pending_o = dst_fifo_clear_pending;

    // Source ready output
    assign src_ready_o = src_fifo_ready_i;

endmodule
