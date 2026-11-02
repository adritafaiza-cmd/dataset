Implement the SystemVerilog module `prim_esc_receiver`.

Receive differential escalation and ping signaling, synchronize the incoming channel, distinguish ping from escalation by pulse duration, and provide the specified response pattern and timeout escalation.

Functional contract and interface notes:

This module decodes escalation enable pulses that have been encoded using
the prim_esc_sender module.
The module supports in-band ping testing of the escalation
wires. This is accomplished by the sender module that places a single-cycle,
differentially encoded pulse on esc_p/n which will be interpreted as a ping
request by the receiver module. The receiver module responds by sending back
the response pattern "1010".
Native escalation enable pulses are differentiated from ping
requests by making sure that these pulses are always longer than 1 cycle.
See also: prim_esc_sender, prim_diff_decode, alert_handler

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_diff_decode: prim_diff_decode #( .AsyncOn(1'b0), .SkewCycles(SkewCycles) ) u_decode_esc ( .clk_i, .rst_ni, .diff_pi ( esc_p ), .diff_ni ( esc_n ), .level_o ( esc_level ), .rise_o ( ), .fall_o ( ), .event_o ( ), .sigint_o ( sigint_detected ) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_esc_receiver
  import prim_esc_pkg::*;
#(
  // The number of escalation severities. Should be set to the Alert Handler's N_ESC_SEV when this
  // primitive is instantiated.
  parameter int N_ESC_SEV = 4,
  // The width of the Alert Handler's ping counter. Should be set to the Alert Handler's PING_CNT_DW
  // when this primitive is instantiated.
  parameter int PING_CNT_DW = 16,
  // Number of cycles a differential skew is tolerated on the differential escalation signal.
  parameter int unsigned SkewCycles = 1,
  // This counter monitors incoming ping requests and auto-escalates if the alert handler
  // ceases to send them regularly. The maximum number of cycles between subsequent ping requests
  // is N_ESC_SEV x (2 x 2 x 2**PING_CNT_DW), see also implementation of the ping timer
  // (alert_handler_ping_timer.sv). The timeout counter below uses a timeout that is 4x larger than
  // that in order to incorporate some margin.
  //
  // Do NOT modify this counter value, when instantiating it in the design. It is only exposed to
  // reduce the state space in the FPV testbench.
  localparam int MarginFactor = 4,
  localparam int NumWaitCounts = 2,
  localparam int NumTimeoutCounts = 2,
  parameter int TimeoutCntDw = $clog2(MarginFactor) +
                               $clog2(N_ESC_SEV) +
                               $clog2(NumWaitCounts) +
                               $clog2(NumTimeoutCounts) +
                               PING_CNT_DW
) (
  input           clk_i,
  input           rst_ni,
  // escalation enable
  output logic    esc_req_o,
  // escalation / ping response
  output esc_rx_t esc_rx_o,
  // escalation output diff pair
  input esc_tx_t  esc_tx_i
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
