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
    logic [WIDTH-1:0]       src_fifo_data_o;
    logic                   src_fifo_valid_o;
    logic                   src_fifo_ready_o;
    logic [WIDTH-1:0]       dst_fifo_data_o;
    logic                   dst_fifo_valid_o;
    logic                   dst_fifo_ready_o;

    // Source FIFO
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o)
    );

    // Destination FIFO
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(dst_fifo_data_o),
        .valid_i(dst_fifo_valid_o),
        .ready_o(dst_fifo_ready_o)
    );

    // Handshaking between source and destination FIFOs
    assign src_fifo_data_o = src_fifo.data_o;
    assign src_fifo_valid_o = src_fifo.valid_o;
    assign src_fifo_ready_o = src_fifo.ready_o;

    assign dst_fifo_data_o = dst_data_o;
    assign dst_fifo_valid_o = dst_valid_o;
    assign dst_fifo_ready_o = dst_ready_i;

endmodule
