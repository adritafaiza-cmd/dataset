Please act as a professional Verilog designer.

Implement a clearable two-phase valid/ready channel between asynchronous clocks.

src_clk_i and dst_clk_i are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Move source data to the destination in order, holding it while the receiver waits. A clear request should flush the channel and let both sides return to idle without a stray transfer.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);
