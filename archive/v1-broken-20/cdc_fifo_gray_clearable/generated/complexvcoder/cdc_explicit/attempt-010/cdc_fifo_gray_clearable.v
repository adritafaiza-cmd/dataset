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
    reg [WIDTH-1:0] src_fifo_data [0:((1 << LOG_DEPTH) - 1)];
    reg src_fifo_valid [0:((1 << LOG_DEPTH) - 1)];
    reg src_fifo_ready;
    reg [WIDTH-1:0] dst_fifo_data [0:((1 << LOG_DEPTH) - 1)];
    reg dst_fifo_valid;
    reg dst_fifo_ready;
    reg src_clear_pending;
    reg dst_clear_pending;

    // FIFO Gray module instances
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .clear_i(src_clear_i),
        .data_o(src_fifo_data[0]),
        .valid_o(src_fifo_valid[0]),
        .ready_i(src_fifo_ready)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_fifo_data[0]),
        .valid_i(dst_fifo_valid),
        .ready_o(dst_fifo_ready),
        .clear_i(dst_clear_i),
        .data_o(dst_data_o),
        .valid_o(dst_valid_o),
        .ready_i(dst_ready_i)
    );

    // Clear pending logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1;
        end else if (src_fifo_valid[0] && src_ready_o) begin
            src_clear_pending <= 0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1;
        end else if (dst_fifo_valid && dst_ready_i) begin
            dst_clear_pending <= 0;
        end
    end

    // Output clear pending
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    // Connect FIFO outputs to internal signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_ready <= 0;
        end else begin
            src_fifo_ready <= src_ready_o;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_data[0] <= 0;
            dst_fifo_valid <= 0;
        end else begin
            dst_fifo_data[0] <= src_fifo_data[0];
            dst_fifo_valid <= src_fifo_valid[0];
        end
    end

endmodule
