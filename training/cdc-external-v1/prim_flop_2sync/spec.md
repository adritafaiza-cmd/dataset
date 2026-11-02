Please act as a professional Verilog designer.

Implement Synchronize a vector through two destination-clocked flip-flop stages.

Module name:
    prim_flop_2sync

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    d_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    q_o: Output delivered in the receiving or local domain.

Parameters:
    Width: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ResetValue: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    EnablePrimCdcRand: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the level_sync, reset_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_flop_2sync #(
  parameter int               Width      = 16,
  parameter logic [Width-1:0] ResetValue = '0,
  parameter bit               EnablePrimCdcRand = 1
) (
  input                    clk_i,
  input                    rst_ni,
  input        [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
