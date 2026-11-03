module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    logic [WIDTH-1:0]       fifo_core_inst_data_in;
    logic                   fifo_core_inst_valid_in;
    logic                   fifo_core_inst_ready_in;
    logic [WIDTH-1:0]       fifo_core_inst_data_out;
    logic                   fifo_core_inst_valid_out;
    logic                   fifo_core_inst_ready_out;
    logic [WIDTH-1:0]       cdc_crossing_inst_data_in;
    logic                   cdc_crossing_inst_valid_in;
    logic                   cdc_crossing_inst_ready_in;
    logic [WIDTH-1:0]       cdc_crossing_inst_data_out;
    logic                   cdc_crossing_inst_valid_out;
    logic                   cdc_crossing_inst_ready_out;

    // FIFO core instance
    fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_core_inst (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(fifo_core_inst_data_in),
        .valid_in(fifo_core_inst_valid_in),
        .ready_in(fifo_core_inst_ready_in),
        .data_out(fifo_core_inst_data_out),
        .valid_out(fifo_core_inst_valid_out),
        .ready_out(fifo_core_inst_ready_out)
    );

    // CDC crossing instance
    cdc_crossing #(
        .WIDTH(WIDTH)
    ) cdc_crossing_inst (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(cdc_crossing_inst_data_in),
        .valid_in(cdc_crossing_inst_valid_in),
        .ready_in(cdc_crossing_inst_ready_in),
        .data_out(cdc_crossing_inst_data_out),
        .valid_out(cdc_crossing_inst_valid_out),
        .ready_out(cdc_crossing_inst_ready_out)
    );

    // Connections between FIFO core and CDC crossing
    assign fifo_core_inst_data_in = cdc_crossing_inst_data_out;
    assign fifo_core_inst_valid_in = cdc_crossing_inst_valid_out;
    assign fifo_core_inst_ready_in = cdc_crossing_inst_ready_out;
    assign cdc_crossing_inst_data_in = fifo_core_inst_data_out;
    assign cdc_crossing_inst_valid_in = fifo_core_inst_valid_out;
    assign cdc_crossing_inst_ready_in = fifo_core_inst_ready_out;

    // Source ready logic
    assign src_ready_o = fifo_core_inst_ready_out;

    // Destination output logic
    assign dst_data_o = fifo_core_inst_data_out;
    assign dst_valid_o = fifo_core_inst_valid_out;

endmodule
