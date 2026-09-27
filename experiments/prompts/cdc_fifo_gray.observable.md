Please act as a professional Verilog designer.

Implement a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.

src_clk_i and dst_clk_i are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Queue data between the source and destination sides, returning it once in order. Keep flow control sensible and start empty after reset.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

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
