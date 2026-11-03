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
    logic [WIDTH-1:0] src_fifo_in_data;
    logic src_fifo_in_valid;
    logic src_fifo_out_valid;
    logic [WIDTH-1:0] src_fifo_out_data;
    logic src_fifo_out_ready;
    logic dst_fifo_in_data;
    logic dst_fifo_in_valid;
    logic dst_fifo_out_valid;
    logic [WIDTH-1:0] dst_fifo_out_data;
    logic dst_fifo_out_ready;
    logic src_clear_request;
    logic dst_clear_request;
    logic src_clear_done;
    logic dst_clear_done;

    // FIFO instances
    fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_request),
        .clear_done_o(src_clear_done),
        .data_i(src_fifo_in_data),
        .valid_i(src_fifo_in_valid),
        .ready_o(src_fifo_out_ready)
    );

    fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_request),
        .clear_done_o(dst_clear_done),
        .data_i(dst_fifo_in_data),
        .valid_i(dst_fifo_in_valid),
        .ready_o(dst_fifo_out_ready)
    );

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 1'b0;
        end else begin
            src_clear_pending_o <= src_clear_request && !src_clear_done;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 1'b0;
        end else begin
            dst_clear_pending_o <= dst_clear_request && !dst_clear_done;
        end
    end

    // Source FIFO connections
    assign src_fifo_in_data = src_data_i;
    assign src_fifo_in_valid = src_valid_i && dst_ready_i;
    assign src_ready_o = src_fifo_out_ready;

    // Destination FIFO connections
    assign dst_fifo_in_data = src_fifo_out_data;
    assign dst_fifo_in_valid = src_fifo_out_valid;
    assign dst_valid_o = dst_fifo_out_valid;
    assign dst_data_o = dst_fifo_out_data;

    // Clear request logic
    assign src_clear_request = src_clear_i;
    assign dst_clear_request = dst_clear_i;

endmodule
