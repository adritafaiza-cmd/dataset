Please act as a professional Verilog designer.

Implement a four-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

Module name:
    cdc_4phase

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
    DECOUPLED: When set, source may accept a new item before the previous destination handshake returns.
    SEND_RESET_MSG: When set, emit RESET_MSG after reset.
    RESET_MSG: Payload emitted after reset when SEND_RESET_MSG is set.

Behavior:
    - A source transfer is accepted when src_valid_i and src_ready_o are both high.
    - Each accepted item appears exactly once at the destination, in order.
    - While dst_valid_o is high and dst_ready_i is low, dst_data_o must stay stable.
    - DECOUPLED, when set, allows the source to accept a new item before the previous destination handshake fully returns.
    - SEND_RESET_MSG / RESET_MSG, when set, emit RESET_MSG after reset instead of staying idle.
    - Reset must not create a spurious destination beat unless SEND_RESET_MSG is set.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
