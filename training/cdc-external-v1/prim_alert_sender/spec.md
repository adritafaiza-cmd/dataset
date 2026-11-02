Implement the SystemVerilog module `prim_alert_sender`.

Transmit an alert request over the differential alert protocol, synchronize the asynchronous acknowledgement and ping paths, and implement ping responses and the configured alert handshake.

Functional contract and interface notes:

The alert sender primitive module differentially encodes and transmits an
alert signal to the prim_alert_receiver module. An alert will be signalled
by a full handshake on alert_p/n and ack_p/n. The alert_req_i signal may
be continuously asserted, in which case the alert signalling handshake
will be repeatedly initiated.
The alert_req_i signal may also be used as part of req/ack. The parent module
can keep alert_req_i asserted until it has been ack'd (transferred to the alert
receiver).  The parent module is not required to use this.
In case the alert sender parameter IsFatal is set to 1, an incoming alert
alert_req_i is latched in a local register until the next reset, causing the
alert sender to behave as if alert_req_i were continuously asserted.
The alert_state_o output reflects the state of this internal latching register.
The alert sender also exposes an alert test input, which can be used to trigger
single alert handshakes. This input behaves exactly the same way as the
alert_req_i input with IsFatal set to 0. Test alerts do not cause alert_ack_o
to be asserted, nor are they latched until reset (regardless of the value of the
IsFatal parameter).
Further, this module supports in-band ping testing, which means that a level
change on the ping_p/n diff pair will result in a full-handshake response
on alert_p/n and ack_p/n.
The protocol works in both asynchronous and synchronous cases. In the
asynchronous case, the parameter AsyncOn must be set to 1'b1 in order to
instantiate additional synchronization logic. Further, it must be ensured
that the timing skew between all diff pairs is smaller than the shortest
clock period of the involved clocks.
Incorrectly encoded diff inputs can be detected and will be signalled
to the receiver by placing an inconsistent diff value on the differential
output (and continuously toggling it).
See also: prim_alert_receiver, prim_diff_decode, alert_handler

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_diff_decode: prim_diff_decode #( .AsyncOn(AsyncOn), .SkewCycles(SkewCycles) ) u_decode_ping ( .clk_i, .rst_ni, .diff_pi ( ping_p ), .diff_ni ( ping_n ), .level_o ( ), .rise_o ( ), .fall_o ( ), .event_o ( ping_event ), .sigint_o ( ping_sigint ) );
- prim_diff_decode: prim_diff_decode #( .AsyncOn(AsyncOn), .SkewCycles(SkewCycles) ) u_decode_ack ( .clk_i, .rst_ni, .diff_pi ( ack_p ), .diff_ni ( ack_n ), .level_o ( ack_level ), .rise_o ( ), .fall_o ( ), .event_o ( ), .sigint_o ( ack_sigint ) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_alert_sender
  import prim_alert_pkg::*;
#(
  // enables additional synchronization logic
  parameter bit AsyncOn = 1'b1,
  // Number of cycles a differential skew is tolerated on the differential ack/ping signal.
  parameter int unsigned SkewCycles = 1,
  // alert sender will latch the incoming alert event permanently and
  // keep on sending alert events until the next reset.
  parameter bit IsFatal = 1'b0
) (
  input             clk_i,
  input             rst_ni,
  // alert test trigger (this will never be latched, even if IsFatal == 1)
  input             alert_test_i,
  // native alert from the peripheral
  input             alert_req_i,
  output logic      alert_ack_o,
  // state of the alert latching register
  output logic      alert_state_o,
  // ping input diff pair and ack diff pair
  input alert_rx_t  alert_rx_i,
  // alert output diff pair
  output alert_tx_t alert_tx_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
