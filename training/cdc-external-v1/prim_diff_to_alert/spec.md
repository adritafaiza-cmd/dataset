Implement the SystemVerilog module `prim_diff_to_alert`.

Bridge a differential event input to the alert protocol, decoding and synchronizing the input and retaining a request until the alert handshake completes.

Functional contract and interface notes:

prim_diff_to_alert: This module receives a differentially encoded alert request and translates
that to an alert signal with the alert protocol.

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width(2), .ResetValue(2'b10) ) u_sync ( .clk_i, .rst_ni, .d_i ( {diff_ni, diff_pi} ), .q_o ( {diff_n_sync, diff_p_sync} ) );
- prim_alert_sender: prim_alert_sender #( .AsyncOn(AsyncOn), .SkewCycles(SkewCycles), .IsFatal(IsFatal) ) u_prim_alert_sender ( .clk_i, .rst_ni, .alert_test_i ( 1'b0 ), .alert_req_i ( alert_req ), .alert_ack_o (), .alert_state_o (), .alert_rx_i, .alert_tx_o );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_diff_to_alert #(
  // AsyncOn: Enables additional synchronization logic within the alert receiver.
  parameter bit AsyncOn = 1'b1,
  // Number of cycles a differential skew is tolerated on the alert signal
  parameter int unsigned SkewCycles = 1,
  // Alert sender will latch the incoming alert event permanently and
  // keep on sending alert events until the next reset.
  parameter bit IsFatal = 1'b1
) (
  input logic                       clk_i,
  input logic                       rst_ni,
  // Input diff pair (differentially encoded alert signal)
  input logic                       diff_pi,
  input logic                       diff_ni,
  // Alert pair (interface signals for the alert protocol)
  input  prim_alert_pkg::alert_rx_t alert_rx_i,
  output prim_alert_pkg::alert_tx_t alert_tx_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
