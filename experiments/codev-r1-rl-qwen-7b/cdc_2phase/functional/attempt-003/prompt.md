Please act as a professional Verilog designer.

Implement a two-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

Module name:
    cdc_2phase

Language:
    SystemVerilog

Clocks:
    src_clk_i: Independent asynchronous clock (async to dst_clk_i). No fixed frequency or phase relationship.
    dst_clk_i: Independent asynchronous clock (async to src_clk_i).

Resets:
    src_rst_ni: active-low.
    dst_rst_ni: active-low.

Input ports:
    src_rst_ni: Active-low source-domain reset.
    src_clk_i: Source-domain clock.
    src_data_i: Source payload.
    src_valid_i: Source valid.
    dst_rst_ni: Active-low destination-domain reset.
    dst_clk_i: Destination-domain clock.
    dst_ready_i: Destination ready.

Output ports:
    src_ready_o: Source ready.
    dst_data_o: Destination payload.
    dst_valid_o: Destination valid.

Parameters:
    WIDTH: Payload width in bits.

Behavior:
    - A source transfer is accepted on a rising src_clk_i edge when src_valid_i and src_ready_o are both high.
    - Every accepted source item must appear exactly once at the destination, in the original order.
    - A destination transfer completes on a rising dst_clk_i edge when dst_valid_o and dst_ready_i are both high.
    - While dst_valid_o is high and dst_ready_i is low, dst_valid_o must remain asserted and dst_data_o must remain stable.
    - The design may support one outstanding item.
    - src_ready_o must be low whenever a new source item cannot safely be accepted.
    - Reset must return both interfaces to an idle state and must not create a spurious destination transaction.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module cdc_2phase #(
  parameter WIDTH = 1
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
