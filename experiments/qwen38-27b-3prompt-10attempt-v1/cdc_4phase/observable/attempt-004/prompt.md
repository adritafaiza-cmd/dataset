Please act as a professional Verilog designer.

Implement a four-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

src_clk_i and dst_clk_i are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Move data across the two sides using a four-phase handshake, without losing an item when the receiver pauses. Respect the decoupled option and the configured reset-message behavior.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);
