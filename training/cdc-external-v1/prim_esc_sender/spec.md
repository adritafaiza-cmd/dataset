Implement the SystemVerilog module `prim_esc_sender`.

Encode escalation requests and ping requests on a differential channel and synchronize the returning response before updating handshake and error state.

Functional contract and interface notes:

This module differentially encodes an escalation enable pulse
of arbitrary width.
The module supports in-band ping testing of the escalation
wires. This is accomplished by sending out a single, differentially
encoded pulse on esc_p/n which will be interpreted as a ping
request by the escalation receiver. Note that ping_req_i shall
be held high until either ping_ok_o or integ_fail_o is asserted.
Native escalation enable pulses are differentiated from ping
requests by making sure that these pulses are always longer than 1 cycle.
If there is a differential encoding error, integ_fail_o
will be asserted.
See also: prim_esc_receiver, prim_diff_decode, alert_handler

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_diff_decode: prim_diff_decode #( .AsyncOn(1'b0), .SkewCycles(SkewCycles) ) u_decode_resp ( .clk_i, .rst_ni, .diff_pi ( resp_p ), .diff_ni ( resp_n ), .level_o ( resp ), .rise_o ( ), .fall_o ( ), .event_o ( ), .sigint_o ( sigint_detected ) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_esc_sender
  import prim_esc_pkg::*;
#(
  // Number of cycles a differential skew is tolerated on the differential response signal.
  parameter int unsigned SkewCycles = 1
) (
  input           clk_i,
  input           rst_ni,
  // this triggers a ping test. keep asserted until ping_ok_o is pulsed high.
  input           ping_req_i,
  output logic    ping_ok_o,
  // asserted if signal integrity issue detected
  output logic    integ_fail_o,
  // escalation request signal
  input           esc_req_i,
  // escalation / ping response
  input esc_rx_t  esc_rx_i,
  // escalation output diff pair
  output esc_tx_t esc_tx_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
