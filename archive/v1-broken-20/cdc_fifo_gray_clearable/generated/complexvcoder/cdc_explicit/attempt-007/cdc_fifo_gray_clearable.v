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
    logic [WIDTH-1:0] src_data_reg;
    logic src_valid_reg;
    logic src_ready_reg;
    logic dst_ready_reg;
    logic src_clear_req;
    logic dst_clear_req;
    logic src_clear_done;
    logic dst_clear_done;
    logic [LOG_DEPTH-1:0] src_count;
    logic [LOG_DEPTH-1:0] dst_count;

    // Sync clear requests across clock domains
    logic src_clear_req_sync;
    logic dst_clear_req_sync;
    logic src_clear_done_sync;
    logic dst_clear_done_sync;

    // Sync clear signals across clock domains
    logic src_clear_pending_sync;
    logic dst_clear_pending_sync;

    // Async FIFO instances
    async_fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_reg),
        .clear_i(src_clear_req_sync),
        .clear_pending_o(src_clear_pending_sync)
    );

    async_fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_o(dst_data_o),
        .valid_o(dst_valid_o),
        .ready_i(dst_ready_reg),
        .clear_i(dst_clear_req_sync),
        .clear_pending_o(dst_clear_pending_sync)
    );

    // Clear request synchronization
    sync_reset_ff #(
        .WIDTH(1)
    ) src_clear_req_sync_ff (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_clear_i),
        .q_o(src_clear_req_sync)
    );

    sync_reset_ff #(
        .WIDTH(1)
    ) dst_clear_req_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_clear_i),
        .q_o(dst_clear_req_sync)
    );

    // Clear done synchronization
    sync_reset_ff #(
        .WIDTH(1)
    ) src_clear_done_sync_ff (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_clear_done),
        .q_o(src_clear_done_sync)
    );

    sync_reset_ff #(
        .WIDTH(1)
    ) dst_clear_done_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_clear_done),
        .q_o(dst_clear_done_sync)
    );

    // Clear pending synchronization
    sync_reset_ff #(
        .WIDTH(1)
    ) src_clear_pending_sync_ff (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_clear_pending_sync),
        .q_o(src_clear_pending_o)
    );

    sync_reset_ff #(
        .WIDTH(1)
    ) dst_clear_pending_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_clear_pending_sync),
        .q_o(dst_clear_pending_o)
    );

    // Clear logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_req <= 0;
            src_clear_done <= 0;
        end else begin
            src_clear_req <= src_clear_req_sync;
            src_clear_done <= src_clear_done_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_req <= 0;
            dst_clear_done <= 0;
        end else begin
            dst_clear_req <= dst_clear_req_sync;
            dst_clear_done <= dst_clear_done_sync;
        end
    end

    // Ready logic
    assign src_ready_o = src_ready_reg;
    assign dst_ready_reg = dst_ready_i;

endmodule
