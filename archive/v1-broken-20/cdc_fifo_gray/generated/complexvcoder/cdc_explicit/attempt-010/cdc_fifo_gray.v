module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

    // Internal signals
    logic [WIDTH-1:0] src_data_gray;
    logic src_valid_gray;
    logic src_ready_gray;
    logic [WIDTH-1:0] dst_data_gray;
    logic dst_valid_gray;
    logic dst_ready_gray;

    // Convert src_data_i to gray code
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_gray <= 0;
        end else begin
            src_data_gray <= src_data_i;
        end
    end

    // Convert src_valid_i to gray code
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_gray <= 0;
        end else begin
            src_valid_gray <= src_valid_i;
        end
    end

    // Convert src_ready_o to gray code
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_gray <= 0;
        end else begin
            src_ready_gray <= src_ready_o;
        end
    end

    // Convert dst_data_o to gray code
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_gray <= 0;
        end else begin
            dst_data_gray <= dst_data_o;
        end
    end

    // Convert dst_valid_o to gray code
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_gray <= 0;
        end else begin
            dst_valid_gray <= dst_valid_o;
        end
    end

    // Convert dst_ready_i to gray code
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_gray <= 0;
        end else begin
            dst_ready_gray <= dst_ready_i;
        end
    end

    // FIFO in source clock domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_gray),
        .src_valid_i(src_valid_gray),
        .src_ready_o(src_ready_gray),
        .dst_data_o(src_data_gray),
        .dst_valid_o(src_valid_gray),
        .dst_ready_i(src_ready_gray)
    );

    // FIFO in destination clock domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_data_i(dst_data_gray),
        .src_valid_i(dst_valid_gray),
        .src_ready_o(dst_ready_gray),
        .dst_data_o(dst_data_gray),
        .dst_valid_o(dst_valid_gray),
        .dst_ready_i(dst_ready_gray)
    );

    // Synchronous crossing from source to destination
    sync_crossing #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_to_sync (
        .src_data_i(src_data_gray),
        .src_valid_i(src_valid_gray),
        .src_ready_o(src_ready_gray),
        .dst_data_o(dst_data_gray),
        .dst_valid_o(dst_valid_gray),
        .dst_ready_i(dst_ready_gray)
    );

    // Synchronous crossing from destination to source
    sync_crossing #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_sync_to_gray (
        .src_data_i(dst_data_gray),
        .src_valid_i(dst_valid_gray),
        .src_ready_o(dst_ready_gray),
        .dst_data_o(src_data_gray),
        .dst_valid_o(src_valid_gray),
        .dst_ready_i(src_ready_gray)
    );

endmodule
