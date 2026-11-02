Please act as a professional Verilog designer.

Implement a request/acknowledge clock-domain bridge with an associated stable data bus and an optional destination-side payload register.

Module name:
    prim_sync_reqack_data

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
    data_i: Payload from the direction selected by DataSrc2Dst; obey the handshake stability rules.

Output ports:
    src_ack_o: Source-domain acknowledgement completing the outstanding request.
    dst_req_o: Request presented to destination-domain logic after synchronization.
    data_o: Associated payload delivered directly or through the optional reverse-direction holding register.

Parameters:
    Width: Number of associated payload bits; default one.
    EnRstChks: Enable reset consistency assertions in the handshake helper; default zero.
    DataSrc2Dst: Select source-to-destination payload flow when one, or destination-to-source flow when zero; default one.
    DataReg: Capture reverse-direction data in a destination-clocked register when one; only valid with DataSrc2Dst=0; default zero.
    EnRzHs: Select four-phase return-to-zero control instead of the default two-phase toggle control.

Behavior:
    - Delegate control transfer to prim_sync_reqack, synchronizing request toward clk_dst_i and acknowledgement toward clk_src_i with two-stage synchronizers.
    - Hold the source request until its acknowledgement arrives and do not acknowledge at the destination without a request. req_chk_i affects assertion checking only.
    - Normally connect data_o directly to data_i. This data bus is not independently synchronized bit by bit; its producer must keep the word stable across the corresponding control exchange.
    - For source-to-destination data, hold the word while the source request awaits acknowledgement. For reverse data without a register, keep the response stable long enough for the source to sample it with acknowledgement, including the synchronization delay; retaining it until the next request is a valid discipline.
    - When DataSrc2Dst=0 and DataReg=1, capture data_i on dst_req_o && dst_ack_i using clk_dst_i and hold that value at data_o between destination handshakes. Do not enable this register for forward-direction payloads.
    - Apply the two active-low asynchronous resets to their local handshake state. Reset the optional payload register to zero with rst_dst_ni; the direct-through data path has no reset storage. Coordinate resets in toggle mode; return-to-zero mode allows isolated reset recovery without guaranteeing transaction retention.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_sync_reqack_data #(
  parameter int unsigned Width       = 1,
  parameter bit          EnRstChks   = 1'b0, // Enable reset-related assertion checks, disabled by
                                             // default.
  parameter bit          DataSrc2Dst = 1'b1, // Direction of data flow: 1'b1 = SRC to DST,
                                             //                         1'b0 = DST to SRC
  parameter bit          DataReg     = 1'b0, // Enable optional register stage for data,
                                             // only usable with DataSrc2Dst == 1'b0.
  parameter bit          EnRzHs      = 1'b0  // By Default, we the faster NRZ handshake protocol
                                             // (EnRzHs = 0) is used. Enable the RZ handshake
                                             // protocol if the FSMs need to be partial-reset-safe.
) (
  input  clk_src_i,       // REQ side, SRC domain
  input  rst_src_ni,      // REQ side, SRC domain
  input  clk_dst_i,       // ACK side, DST domain
  input  rst_dst_ni,      // ACK side, DST domain

  input  logic req_chk_i, // Used for gating assertions. Drive to 1 during normal operation.

  input  logic src_req_i, // REQ side, SRC domain
  output logic src_ack_o, // REQ side, SRC domain
  output logic dst_req_o, // ACK side, DST domain
  input  logic dst_ack_i, // ACK side, DST domain

  input  logic [Width-1:0] data_i,
  output logic [Width-1:0] data_o
);
