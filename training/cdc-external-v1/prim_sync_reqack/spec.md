Please act as a professional Verilog designer.

Implement a bidirectional control bridge that carries a request to a destination clock domain and returns its acknowledgement to the source domain.

Module name:
    prim_sync_reqack

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
    clk_dst_i: Rising-edge clock of the receiving destination domain.
    rst_dst_ni: Active-low asynchronous reset of destination-domain state.
    req_chk_i: Assertion-enable qualification for source request protocol checking.
    src_req_i: Source-domain request held until the returned acknowledgement.
    dst_ack_i: Destination-domain acknowledgement of the presented request.

Output ports:
    src_ack_o: Source-domain acknowledgement completing the outstanding request.
    dst_req_o: Request presented to destination-domain logic after synchronization.

Parameters:
    EnRstChks: Include assertions checking coordinated reset activity; default zero.
    EnRzHs: Use return-to-zero four-phase control when one and toggle-based two-phase control when zero; default zero.

Behavior:
    - The requester must hold src_req_i until src_ack_o completes the source handshake. The destination must assert dst_ack_i only in response to dst_req_o. Each request/acknowledge overlap denotes one transfer in its own domain.
    - In the default protocol, register alternating request and acknowledgement levels and cross them through two-stage synchronizers. Local even/odd state interprets each new level as the next transaction.
    - For EnRzHs=1, raise an internal request, wait for its acknowledgement, then return both internal levels to zero before accepting the next transaction. Use synchronized request and acknowledgement levels in both directions.
    - Allow the destination to delay its acknowledgement. Support either relative ordering of the clock rates; no common phase or fixed frequency ratio is required.
    - Use req_chk_i only to gate protocol assertions, not to gate functional transfers.
    - Asynchronously clear local protocol state with rst_src_ni or rst_dst_ni. Toggle mode requires overlapping resets of both domains to realign their phases; return-to-zero control can recover from an isolated domain reset, although reset does not preserve an outstanding transfer.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_sync_reqack #(
  parameter bit EnRstChks = 1'b0,   // Enable reset-related assertion checks, disabled by default.
  parameter bit EnRzHs = 1'b0       // By Default, the faster NRZ handshake protocol
                                    // (EnRzHs = 0) is used. Enable the RZ handshake protocol
                                    // if the FSMs need to be partial-reset-safe.
) (
  input  clk_src_i,       // REQ side, SRC domain
  input  rst_src_ni,      // REQ side, SRC domain
  input  clk_dst_i,       // ACK side, DST domain
  input  rst_dst_ni,      // ACK side, DST domain

  input  logic req_chk_i, // Used for gating assertions. Drive to 1 during normal operation.

  input  logic src_req_i, // REQ side, SRC domain
  output logic src_ack_o, // REQ side, SRC domain
  output logic dst_req_o, // ACK side, DST domain
  input  logic dst_ack_i  // ACK side, DST domain
);
