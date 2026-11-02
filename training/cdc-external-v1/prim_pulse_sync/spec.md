Please act as a professional Verilog designer.

Implement a pulse bridge that converts a source-clock event into a one-cycle event in an independent destination clock domain.

Module name:
    prim_pulse_sync

Language:
    SystemVerilog

Clocks:
    clk_src_i: Rising-edge clock of the initiating source domain.
    clk_dst_i: Rising-edge clock of the receiving destination domain.

Resets:
    rst_src_ni: active low; asynchronous assertion.
    rst_dst_ni: active low; asynchronous assertion.

Input ports:
    clk_src_i: Rising-edge clock of the initiating source domain.
    rst_src_ni: Active-low asynchronous reset of source-domain state.
    src_pulse_i: Source-domain event indication, normally high for one source cycle.
    clk_dst_i: Rising-edge clock of the receiving destination domain.
    rst_dst_ni: Active-low asynchronous reset of destination-domain state.

Output ports:
    dst_pulse_o: One-destination-cycle event indication for each observed source toggle.

Parameters:
    None.

Behavior:
    - Toggle a source-domain level on each rising clk_src_i edge for which src_pulse_i is high.
    - Pass that level through a two-stage synchronizer clocked by clk_dst_i, then compare the synchronized value with its previous destination-cycle value using exclusive OR.
    - Drive dst_pulse_o for one destination-clock period after an observed toggle. Require source events to be separated enough for each transition to cross and be observed; this interface has no backpressure or event counter.
    - Asynchronously clear the source toggle with rst_src_ni and clear the destination synchronizer and history register with rst_dst_ni. Resetting only one side can itself appear as a toggle and generate a destination pulse, so coordinated reset is needed when that artifact is unacceptable.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_pulse_sync (
  // source clock domain
  input  logic clk_src_i,
  input  logic rst_src_ni,
  input  logic src_pulse_i,
  // destination clock domain
  input  logic clk_dst_i,
  input  logic rst_dst_ni,
  output logic dst_pulse_o
);
