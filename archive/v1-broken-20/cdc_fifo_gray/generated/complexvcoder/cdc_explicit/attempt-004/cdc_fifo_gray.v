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
    logic [WIDTH-1:0] src_fifo_data [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH:0] src_fifo_ptr;
    logic [LOG_DEPTH:0] src_fifo_wr_ptr;
    logic [LOG_DEPTH:0] src_fifo_rd_ptr;
    logic [WIDTH-1:0] dst_fifo_data [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH:0] dst_fifo_ptr;
    logic [LOG_DEPTH:0] dst_fifo_wr_ptr;
    logic [LOG_DEPTH:0] dst_fifo_rd_ptr;
    logic [WIDTH-1:0] gray_counter_src;
    logic [WIDTH-1:0] gray_counter_dst;
    logic src_fifo_full;
    logic src_fifo_empty;
    logic dst_fifo_full;
    logic dst_fifo_empty;
    logic src_gray_tick;
    logic dst_gray_tick;

    // Sync FIFO for source domain
    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data(src_data_i),
        .valid(src_valid_i),
        .ready(src_ready_o),
        .full(src_fifo_full),
        .empty(src_fifo_empty)
    );

    // Sync FIFO for destination domain
    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data(dst_data_o),
        .valid(dst_valid_o),
        .ready(dst_ready_i),
        .full(dst_fifo_full),
        .empty(dst_fifo_empty)
    );

    // Gray counter for source domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .increment(src_valid_i & src_ready_o),
        .decrement(src_fifo_full),
        .counter(gray_counter_src)
    );

    // Gray counter for destination domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .increment(dst_ready_i),
        .decrement(dst_fifo_full),
        .counter(gray_counter_dst)
    );

    // Connect pointers
    assign src_fifo_ptr = gray_counter_src;
    assign dst_fifo_ptr = gray_counter_dst;

    // Gray counter for source domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .increment(src_valid_i & src_ready_o),
        .decrement(src_fifo_full),
        .counter(gray_counter_src)
    );

    // Gray counter for destination domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .increment(dst_ready_i),
        .decrement(dst_fifo_full),
        .counter(gray_counter_dst)
    );

    // Connect pointers
    assign src_fifo_ptr = gray_counter_src;
    assign dst_fifo_ptr = gray_counter_dst;

    // Gray counter for source domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .increment(src_valid_i & src_ready_o),
        .decrement(src_fifo_full),
        .counter(gray_counter_src)
    );

    // Gray counter for destination domain
    gray_counter #(
        .WIDTH(LOG_DEPTH)
    ) dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .increment(dst_ready_i),
        .decrement(dst_fifo_full),
        .counter(gray_counter_dst)
    );

    // Connect pointers
    assign src_fifo_ptr = gray_counter_src;
    assign dst_fifo_ptr = gray_counter_dst;

endmodule
