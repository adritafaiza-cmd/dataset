Please act as a professional Verilog designer.

Implement Arbitrate software and hardware register updates while synchronizing each transaction across domains.

Module name:
    prim_reg_cdc_arb

Language:
    SystemVerilog

Clocks:
    clk_src_i: Clock input for the associated clock domain.
    clk_dst_i: Clock input for the associated clock domain.

Resets:
    rst_src_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    rst_dst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_src_i: Clock input for the associated clock domain.
    rst_src_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    clk_dst_i: Clock input for the associated clock domain.
    rst_dst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    prim_reg_cdc: Interface signal; preserve the source-declared protocol.
    dst_req_i: Input control, event, payload, or encoded crossing signal.
    dst_update_i: Input control, event, payload, or encoded crossing signal.
    dst_ds_i: Input control, event, payload, or encoded crossing signal.
    dst_qs_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    src_ack_o: Output delivered in the receiving or local domain.
    src_update_o: Output delivered in the receiving or local domain.
    prim_subreg: Interface signal; preserve the source-declared protocol.
    dst_req_o: Output delivered in the receiving or local domain.
    dst_qs_o: Output delivered in the receiving or local domain.

Parameters:
    DataWidth: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ResetVal: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    DstWrReq: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the req_ack, pulse_sync, bundled_data crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_reg_cdc_arb #(
  parameter int DataWidth = 32,
  parameter logic [DataWidth-1:0] ResetVal = 32'h0,
  parameter bit DstWrReq = 0
) (
  input clk_src_i,
  input rst_src_ni,
  input clk_dst_i,
  input rst_dst_ni,
  // destination side acknowledging a software transaction
  output logic src_ack_o,
  // destination side requesting a source side update after
  // after hw update
  output logic src_update_o,
  // input request from prim_reg_cdc
  input dst_req_i,
  // output request to prim_subreg
  output logic dst_req_o,
  input dst_update_i,
  // ds allows us to sample the destination domain register
  // one cycle earlier instead of waiting for it to be reflected
  // in the qs.
  // This is important because a general use case is that interrupts
  // are captured alongside payloads from the destination domain into
  // the source domain. If we rely on `qs` only, then it is very likely
  // that the software observed value will be behind the interrupt
  // assertion.  If the destination clock is very slow, this can seem
  // an error on the part of the hardware.
  input [DataWidth-1:0] dst_ds_i,
  input [DataWidth-1:0] dst_qs_i,
  output logic [DataWidth-1:0] dst_qs_o
);
