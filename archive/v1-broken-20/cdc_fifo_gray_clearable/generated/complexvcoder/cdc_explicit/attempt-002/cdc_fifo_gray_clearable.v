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
    logic dst_valid_reg;
    logic dst_ready_reg;
    logic src_clear_pending;
    logic dst_clear_pending;

    // Sync FIFO instances
    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_reg)
    );

    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .data_i(src_data_reg),
        .valid_i(src_valid_reg),
        .ready_o(src_ready_o)
    );

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
        end else if (src_ready_reg && src_valid_i) begin
            src_clear_pending <= 1'b0;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
        end else if (dst_ready_i && dst_valid_reg) begin
            dst_clear_pending <= 1'b0;
        end
    end

    // Assign outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_fifo.data_o;
    assign dst_valid_o = dst_fifo.valid_o;

endmodule
