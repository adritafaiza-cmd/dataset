Please act as a professional Verilog designer.

Implement Measure an input clock against a reference clock and report timing and timeout conditions.

Module name:
    prim_clock_meas

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.
    clk_ref_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    rst_ref_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    period: Interface signal; preserve the source-declared protocol.
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    clk_ref_i: Clock input for the associated clock domain.
    rst_ref_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    en_i: Input control, event, payload, or encoded crossing signal.
    max_cnt: Interface signal; preserve the source-declared protocol.
    min_cnt: Interface signal; preserve the source-declared protocol.
    domain: Interface signal; preserve the source-declared protocol.

Output ports:
    the: Interface signal; preserve the source-declared protocol.
    valid_o: Output delivered in the receiving or local domain.
    fast_o: Output delivered in the receiving or local domain.
    slow_o: Output delivered in the receiving or local domain.
    timeout_clk_ref_o: Output delivered in the receiving or local domain.
    ref_timeout_clk_o: Output delivered in the receiving or local domain.

Parameters:
    Cnt: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    RefCnt: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ClkTimeOutChkEn: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    RefTimeOutChkEn: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    CntWidth: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    RefCntWidth: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the level_sync, pulse_sync, req_ack crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_clock_meas #(
  // Maximum value of input clock counts over measurement period
  parameter int Cnt = 16,
  // Maximum value of reference clock counts over measurement period
  parameter int RefCnt = 1,
  parameter bit ClkTimeOutChkEn = 1,
  parameter bit RefTimeOutChkEn = 1,
  localparam int CntWidth = prim_util_pkg::vbits(Cnt),
  localparam int RefCntWidth = prim_util_pkg::vbits(RefCnt)
) (
  input clk_i,
  input rst_ni,
  input clk_ref_i,
  input rst_ref_ni,
  input en_i,
  input [CntWidth-1:0] max_cnt,
  input [CntWidth-1:0] min_cnt,
  // the output valid and fast/slow indications are all on the
  // input clock domain
  output logic valid_o,
  output logic fast_o,
  output logic slow_o,

  // signal on clk_i domain that indicates clk_ref has timed out
  output logic timeout_clk_ref_o,

  // signal on clk_ref_i domain that indicates clk has timed out
  output logic ref_timeout_clk_o
);
