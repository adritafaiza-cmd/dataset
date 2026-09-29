Please act as a professional Verilog designer.

Implement a clearable two-phase valid/ready channel between asynchronous clocks.

Module name:
    cdc_2phase_clearable

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
    src_clear_i: See Behavior.
    src_data_i: Source payload.
    src_valid_i: Source valid.
    dst_rst_ni: Active-low destination-domain reset.
    dst_clk_i: Destination-domain clock.
    dst_clear_i: See Behavior.
    dst_ready_i: Destination ready.

Output ports:
    src_clear_pending_o: See Behavior.
    src_ready_o: Source ready.
    dst_clear_pending_o: See Behavior.
    dst_data_o: Destination payload.
    dst_valid_o: Destination valid.

Parameters:
    WIDTH: Payload width in bits.
    SYNC_STAGES: Implementation depth parameter. Choose a safe crossing yourself.
    CLEAR_ON_ASYNC_RESET: When set, also flush on async reset.

Behavior:
    - Every accepted source beat must appear exactly once at the destination, in order.
    - The channel may hold one outstanding item.
    - src_clear_i and dst_clear_i request a coordinated flush: isolate the channel, drop in-flight data, then return both sides to idle.
    - src_clear_pending_o / dst_clear_pending_o stay high until that side has finished the clear.
    - Reset and clear must not create a destination beat.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
