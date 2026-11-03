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
    localparam DEPTH = 1 << LOG_DEPTH;
    logic [WIDTH-1:0] src_fifo_data [DEPTH-1:0];
    logic [LOG_DEPTH-1:0] src_fifo_ptr;
    logic [LOG_DEPTH-1:0] src_fifo_wr_ptr;
    logic [LOG_DEPTH-1:0] src_fifo_rd_ptr;
    logic [LOG_DEPTH-1:0] src_fifo_full;
    logic [LOG_DEPTH-1:0] src_fifo_empty;
    logic [WIDTH-1:0] dst_fifo_data [DEPTH-1:0];
    logic [LOG_DEPTH-1:0] dst_fifo_ptr;
    logic [LOG_DEPTH-1:0] dst_fifo_wr_ptr;
    logic [LOG_DEPTH-1:0] dst_fifo_rd_ptr;
    logic [LOG_DEPTH-1:0] dst_fifo_full;
    logic [LOG_DEPTH-1:0] dst_fifo_empty;
    logic [WIDTH-1:0] src_gray_data;
    logic [WIDTH-1:0] dst_gray_data;
    logic [SYNC_STAGES-1:0] src_gray_sync [SYNC_STAGES];
    logic [SYNC_STAGES-1:0] dst_gray_sync [SYNC_STAGES];
    logic [WIDTH-1:0] src_gray_out;
    logic [WIDTH-1:0] dst_gray_out;

    // FIFO with Gray coding for source clock domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(src_rst_ni),
        .dst_clk_i(src_clk_i),
        .dst_data_o(src_gray_data),
        .dst_valid_o(src_fifo_valid),
        .dst_ready_i(src_fifo_ready)
    );

    // FIFO with Gray coding for destination clock domain
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_data_i(dst_gray_out),
        .src_valid_i(dst_gray_valid),
        .src_ready_o(dst_ready_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

    // Gray encoding for source data
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_sync <= '{default: 0};
        end else begin
            src_gray_sync <= {src_gray_sync[SYNC_STAGES-2:0], src_gray_data};
        end
    end

    assign src_gray_out = src_gray_sync[SYNC_STAGES-1];

    // Gray decoding for destination data
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_sync <= '{default: 0};
        end else begin
            dst_gray_sync <= {dst_gray_sync[SYNC_STAGES-2:0], dst_gray_data};
        end
    end

    assign dst_gray_out = dst_gray_sync[SYNC_STAGES-1];

endmodule
