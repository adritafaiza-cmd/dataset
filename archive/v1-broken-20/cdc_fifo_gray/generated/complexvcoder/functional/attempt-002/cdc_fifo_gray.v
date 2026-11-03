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
    logic [WIDTH-1:0] gray_data;
    logic [LOG_DEPTH-1:0] src_wr_ptr_gray, src_rd_ptr_gray, dst_wr_ptr_gray, dst_rd_ptr_gray;
    logic [LOG_DEPTH-1:0] src_wr_ptr_sync, src_rd_ptr_sync, dst_wr_ptr_sync, dst_rd_ptr_sync;
    logic [LOG_DEPTH-1:0] src_full_gray, src_empty_gray, dst_full_gray, dst_empty_gray;
    logic [LOG_DEPTH-1:0] src_full_sync, src_empty_sync, dst_full_sync, dst_empty_sync;
    logic [LOG_DEPTH-1:0] src_valid_gray, src_valid_sync, dst_valid_gray, dst_valid_sync;
    logic [LOG_DEPTH-1:0] src_ready_gray, src_ready_sync, dst_ready_gray, dst_ready_sync;
    logic [LOG_DEPTH-1:0] src_data_gray, dst_data_gray;

    // FIFO core
    fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_core_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(gray_data),
        .valid_i(src_valid_gray),
        .ready_o(src_ready_gray),
        .full(fifo_full_gray),
        .empty(fifo_empty_gray)
    );

    // Gray encoder
    gray_encoder #(
        .WIDTH(WIDTH)
    ) gray_encoder_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .data_o(gray_data)
    );

    // Gray decoder
    gray_decoder #(
        .WIDTH(WIDTH)
    ) gray_decoder_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_data_gray),
        .valid_i(dst_valid_gray),
        .ready_o(dst_ready_i),
        .data_o(dst_data_o)
    );

    // Synchronization for source write pointer
    fifo_sync #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_wr_ptr_sync_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_wr_ptr_gray),
        .valid_i(1'b1),
        .ready_o(src_ready_gray),
        .data_o(src_wr_ptr_sync)
    );

    // Synchronization for source read pointer
    fifo_sync #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_rd_ptr_sync_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_rd_ptr_gray),
        .valid_i(1'b1),
        .ready_o(src_ready_gray),
        .data_o(src_rd_ptr_sync)
    );

    // Synchronization for destination write pointer
    fifo_sync #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_wr_ptr_sync_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_wr_ptr_gray),
        .valid_i(1'b1),
        .ready_o(dst_ready_gray),
        .data_o(dst_wr_ptr_sync)
    );

    // Synchronization for destination read pointer
    fifo_sync #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_rd_ptr_sync_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_rd_ptr_gray),
        .valid_i(1'b1),
        .ready_o(dst_ready_gray),
        .data_o(dst_rd_ptr_sync)
    );

    // Synchronization for source valid signal
    fifo_sync #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_valid_sync_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_valid_gray),
        .valid_i(1'b1),
        .ready_o(src_ready_gray),
        .data_o(src_valid_sync)
    );

    // Synchronization for source ready signal
    fifo_sync #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_ready_sync_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_ready_gray),
        .valid_i(1'b1),
        .ready_o(src_ready_gray),
        .data_o(src_ready_sync)
    );

    // Synchronization for destination valid signal
    fifo_sync #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_valid_sync_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_valid_gray),
        .valid_i(1'b1),
        .ready_o(dst_ready_gray),
        .data_o(dst_valid_sync)
    );

    // Synchronization for destination ready signal
    fifo_sync #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_ready_sync_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_ready_gray),
        .valid_i(1'b1),
        .ready_o(dst_ready_gray),
        .data_o(dst_ready_sync)
    );

    // Synchronization for source data
    fifo_sync #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_data_sync_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_gray),
        .valid_i(src_valid_gray),
        .ready_o(src_ready_gray),
        .data_o(src_data_sync)
    );

    // Synchronization for destination data
    fifo_sync #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_data_sync_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_data_gray),
        .valid_i(dst_valid_gray),
        .ready_o(dst_ready_gray),
        .data_o(dst_data_gray)
    );

endmodule
