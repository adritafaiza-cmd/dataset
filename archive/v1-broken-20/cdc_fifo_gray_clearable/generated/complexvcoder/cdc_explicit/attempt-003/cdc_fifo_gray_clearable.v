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
    logic [WIDTH-1:0] src_data_gray;
    logic src_valid_gray;
    logic src_ready_gray;
    logic dst_data_gray;
    logic dst_valid_gray;
    logic dst_ready_gray;
    logic [LOG_DEPTH-1:0] src_gray_counter;
    logic [LOG_DEPTH-1:0] dst_gray_counter;
    logic src_gray_counter_gray;
    logic dst_gray_counter_gray;
    logic src_clear_flag;
    logic dst_clear_flag;
    logic src_clear_flag_gray;
    logic dst_clear_flag_gray;

    // Sync FIFO gray counter for source side
    sync_fifo_gray #(
        .WIDTH(LOG_DEPTH),
        .LOG_DEPTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_gray_counter_fifo (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_clear_i(src_clear_flag_gray),
        .src_data_i(src_gray_counter_gray),
        .src_valid_i(src_gray_counter_gray),
        .src_ready_o(src_ready_gray),
        .dst_rst_ni(src_rst_ni),
        .dst_clk_i(src_clk_i),
        .dst_clear_i(1'b0),
        .dst_data_o(src_gray_counter),
        .dst_valid_o(src_gray_counter_gray),
        .dst_ready_i(1'b1)
    );

    // Sync FIFO gray counter for destination side
    sync_fifo_gray #(
        .WIDTH(LOG_DEPTH),
        .LOG_DEPTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_gray_counter_fifo (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_clear_i(dst_clear_flag_gray),
        .src_data_i(dst_gray_counter_gray),
        .src_valid_i(dst_gray_counter_gray),
        .src_ready_o(dst_ready_gray),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_clear_i(1'b0),
        .dst_data_o(dst_gray_counter),
        .dst_valid_o(dst_gray_counter_gray),
        .dst_ready_i(1'b1)
    );

    // Convert payload to gray code
    assign src_data_gray = src_data_i;
    assign dst_data_gray = dst_data_o;

    // Convert valid signal to gray code
    assign src_valid_gray = src_valid_i;
    assign dst_valid_gray = dst_valid_o;

    // Convert ready signal to gray code
    assign src_ready_gray = src_ready_o;
    assign dst_ready_gray = dst_ready_i;

    // Gray code conversion logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter_gray <= 0;
        end else begin
            src_gray_counter_gray <= src_gray_counter;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter_gray <= 0;
        end else begin
            dst_gray_counter_gray <= dst_gray_counter;
        end
    end

    // Clear flag handling
    assign src_clear_flag = src_clear_i;
    assign dst_clear_flag = dst_clear_i;

    // Clear flag conversion logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_flag_gray <= 0;
        end else begin
            src_clear_flag_gray <= src_clear_flag;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_flag_gray <= 0;
        end else begin
            dst_clear_flag_gray <= dst_clear_flag;
        end
    end

    // Clear pending output
    assign src_clear_pending_o = src_clear_flag;
    assign dst_clear_pending_o = dst_clear_flag;

endmodule
