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
    reg [WIDTH-1:0] src_data_reg;
    reg src_valid_reg;
    wire src_ready_reg;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    wire dst_ready_reg;
    reg src_clear_flag;
    reg dst_clear_flag;
    reg [LOG_DEPTH-1:0] src_count;
    reg [LOG_DEPTH-1:0] dst_count;
    reg [LOG_DEPTH-1:0] src_threshold;
    reg [LOG_DEPTH-1:0] dst_threshold;
    reg src_clear_pending;
    reg dst_clear_pending;

    // FIFO gray implementation for source domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_reg)
    );

    // FIFO gray implementation for destination domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_data_reg),
        .valid_i(dst_valid_reg),
        .ready_o(dst_ready_reg)
    );

    // Clear pending detector for source domain
    clear_pending_detector #(
        .WIDTH(1)
    ) clear_pending_src (
        .clear_i(src_clear_i),
        .clear_pending_i(fifo_gray_src.clear_pending_o),
        .clear_pending_o(src_clear_pending)
    );

    // Clear pending detector for destination domain
    clear_pending_detector #(
        .WIDTH(1)
    ) clear_pending_dst (
        .clear_i(dst_clear_i),
        .clear_pending_i(fifo_gray_dst.clear_pending_o),
        .clear_pending_o(dst_clear_pending)
    );

    // Clear flags and counters
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_flag <= 1'b0;
            src_clear_pending <= 1'b0;
            src_count <= 0;
        end else begin
            if (src_clear_i && !src_clear_flag) begin
                src_clear_flag <= 1'b1;
                src_clear_pending <= 1'b1;
                src_count <= 0;
            end else if (src_ready_reg && src_clear_flag) begin
                src_clear_flag <= 1'b0;
                src_clear_pending <= 1'b0;
            end else if (src_valid_i) begin
                src_count <= src_count + 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_flag <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_count <= 0;
        end else begin
            if (dst_clear_i && !dst_clear_flag) begin
                dst_clear_flag <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_count <= 0;
            end else if (dst_ready_reg && dst_clear_flag) begin
                dst_clear_flag <= 1'b0;
                dst_clear_pending <= 1'b0;
            end else if (dst_valid_reg) begin
                dst_count <= dst_count + 1;
            end
        end
    end

    // Connect FIFO outputs to internal signals
    assign src_data_reg = fifo_gray_src.data_o;
    assign src_valid_reg = fifo_gray_src.valid_o;
    assign src_ready_o = fifo_gray_src.ready_o;
    assign dst_data_reg = fifo_gray_dst.data_o;
    assign dst_valid_reg = fifo_gray_dst.valid_o;
    assign dst_ready_o = fifo_gray_dst.ready_o;

    // Connect clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
