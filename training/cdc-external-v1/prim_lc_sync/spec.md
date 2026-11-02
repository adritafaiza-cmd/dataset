Please act as a professional Verilog designer.

Implement Synchronize and independently buffer life-cycle control signals for a receiving domain.

Module name:
    prim_lc_sync

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    lc_en_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    lc_en_o: Output delivered in the receiving or local domain.

Parameters:
    NumCopies: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    AsyncOn: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ResetValueIsOn: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the level_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_lc_sync #(
  // Number of separately buffered output signals.
  // The buffer cells have a don't touch constraint
  // on them such that synthesis tools won't collapse
  // all copies into one signal.
  parameter int NumCopies = 1,
  // This instantiates the synchronizer flops if set to 1.
  // In special cases where the receiver is in the same clock domain as the sender,
  // this can be set to 0. However, it is recommended to leave this at 1.
  parameter bit AsyncOn = 1,
  // 0: reset value is lc_ctrl_pkg::Off
  // 1: reset value is lc_ctrl_pkg::On
  parameter bit ResetValueIsOn = 0
) (
  input                                       clk_i,
  input                                       rst_ni,
  input  lc_ctrl_pkg::lc_tx_t                 lc_en_i,
  output lc_ctrl_pkg::lc_tx_t [NumCopies-1:0] lc_en_o
);
