Please act as a professional Verilog designer.

Implement Move register transactions and associated data between source and destination clock domains.

Module name:
    prim_reg_cdc

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
    src_regwen_i: Input control, event, payload, or encoded crossing signal.
    src_we_i: Input control, event, payload, or encoded crossing signal.
    src_re_i: Input control, event, payload, or encoded crossing signal.
    src_wd_i: Input control, event, payload, or encoded crossing signal.
    dst_ds_i: Input control, event, payload, or encoded crossing signal.
    dst_qs_i: Input control, event, payload, or encoded crossing signal.
    dst_update_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    src_busy_o: Output delivered in the receiving or local domain.
    src_qs_o: Output delivered in the receiving or local domain.
    dst_we_o: Output delivered in the receiving or local domain.
    dst_re_o: Output delivered in the receiving or local domain.
    dst_regwen_o: Output delivered in the receiving or local domain.
    dst_wd_o: Output delivered in the receiving or local domain.

Parameters:
    DataWidth: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    ResetVal: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    BitMask: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.
    DstWrReq: parameter controlling the corresponding width, protocol, filter, or reset behavior in the source.

Behavior:
    - Preserve the req_ack, pulse_sync, bundled_data crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_reg_cdc #(
  parameter int DataWidth = 32,
  parameter logic [DataWidth-1:0] ResetVal = 32'h0,
  parameter logic [DataWidth-1:0] BitMask = 32'hFFFFFFFF,
  // whether this instance needs to support independent hardware writes
  parameter bit DstWrReq = 0
) (
  input clk_src_i,
  input rst_src_ni,
  input clk_dst_i,
  input rst_dst_ni,
  input src_regwen_i,
  input src_we_i,
  input src_re_i,
  input [DataWidth-1:0] src_wd_i,
  output logic src_busy_o,
  output logic [DataWidth-1:0] src_qs_o,
  input  [DataWidth-1:0] dst_ds_i,
  input  [DataWidth-1:0] dst_qs_i,
  input  dst_update_i,
  output logic dst_we_o,
  output logic dst_re_o,
  output logic dst_regwen_o,
  output logic [DataWidth-1:0] dst_wd_o
);
