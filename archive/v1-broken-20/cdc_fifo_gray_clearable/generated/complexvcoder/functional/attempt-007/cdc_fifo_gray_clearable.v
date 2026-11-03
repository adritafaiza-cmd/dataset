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
    logic [WIDTH-1:0] src_fifo_data;
    logic src_fifo_valid;
    logic src_fifo_ready;
    logic src_clear_done;
    logic dst_clear_done;

    // Sync FIFO instances
    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_clear_done),
        .dst_clk_i(dst_clk_i),
        .dst_data_o(src_fifo_data),
        .dst_valid_o(src_fifo_valid),
        .dst_ready_i(src_clear_i | dst_ready_i)
    );

    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_data_i(src_fifo_data),
        .src_valid_i(src_fifo_valid),
        .src_ready_o(src_fifo_ready),
        .dst_rst_ni(src_clear_done),
        .dst_clk_i(src_clk_i),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_clear_i)
    );

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i && src_fifo_valid && src_fifo_ready) begin
                src_clear_done <= 1'b0;
                src_clear_pending_o <= 1'b1;
            end else if (src_fifo_valid == 1'b0 && src_fifo_ready == 1'b0) begin
                src_clear_pending_o <= 1'b0;
                src_clear_done <= 1'b1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 1'b0;
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i && dst_fifo_valid && dst_fifo_ready) begin
                dst_clear_done <= 1'b0;
                dst_clear_pending_o <= 1'b1;
            end else if (dst_fifo_valid == 1'b0 && dst_fifo_ready == 1'b0) begin
                dst_clear_pending_o <= 1'b0;
                dst_clear_done <= 1'b1;
            end
        end
    end

endmodule
