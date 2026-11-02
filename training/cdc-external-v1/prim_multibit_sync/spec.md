Please act as a professional Verilog designer.

Implement Transfer a multibit value only after synchronized samples remain consistent.

Module name:
    prim_multibit_sync

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    data_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    adds: Interface signal; preserve the source-declared protocol.
    data_o: Output delivered in the receiving or local domain.

Parameters:
    Width: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    NumChecks: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ResetValue: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the multi_bit_handshake, level_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_multibit_sync #(
  // Width of the multibit signal.
  parameter int               Width = 8,
  // Number of cycles the synchronized multi-bit signal needs to
  // be stable until it is relased to the output. Each check adds
  // a comparator and an additional delay register.
  parameter int               NumChecks = 1,
  // Reset value of the multibit signal.
  parameter logic [Width-1:0] ResetValue = '0
) (
  input clk_i,
  input rst_ni,
  input  logic [Width-1:0] data_i,
  output logic [Width-1:0] data_o
);
