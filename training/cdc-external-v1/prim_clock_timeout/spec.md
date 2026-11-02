Please act as a professional Verilog designer.

Implement Detect that a monitored clock has stopped by exchanging a request with a reference clock domain.

Module name:
    prim_clock_timeout

Language:
    SystemVerilog

Clocks:
    clk_chk_i: Clock input for the associated clock domain.
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_chk_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_chk_i: Clock input for the associated clock domain.
    rst_chk_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    en_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    timeout_o: Output delivered in the receiving or local domain.

Parameters:
    TimeOutCnt: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    CntWidth: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the req_ack, level_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_clock_timeout #(
  parameter int TimeOutCnt = 16,
  localparam int CntWidth = prim_util_pkg::vbits(TimeOutCnt+1)
) (
  // clock to be checked
  input clk_chk_i,
  input rst_chk_ni,

  // clock used to measure whether clk_chk has stopped ticking
  input clk_i,
  input rst_ni,
  input en_i,
  output logic timeout_o
);
