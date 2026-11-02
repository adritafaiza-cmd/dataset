Implement the SystemVerilog module `prim_diff_decode`.

Decode an asynchronous differential input after synchronization. Produce level and edge indications and flag invalid differential encodings using the configured skew tolerance.

Functional contract and interface notes:

This module decodes a differentially encoded signal and detects
incorrectly encoded differential states.
In case the differential pair crosses an asynchronous boundary, it has
to be re-synchronized to the local clock. This can be achieved by
setting the AsyncOn parameter to 1'b1. In that case, two additional
input registers are added (to counteract metastability), and
a pattern detector is instantiated that detects skewed level changes on
the differential pair (i.e., when level changes on the diff pair are
sampled one cycle apart due to a timing skew between the two wires).
See also: prim_alert_sender, prim_alert_receiver, alert_handler

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width(1), .ResetValue('0) ) i_sync_p ( .clk_i, .rst_ni, .d_i(diff_pi), .q_o(diff_pd) );
- prim_flop_2sync: prim_flop_2sync #( .Width(1), .ResetValue(1'b1) ) i_sync_n ( .clk_i, .rst_ni, .d_i(diff_ni), .q_o(diff_nd) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_diff_decode #(
  // enables additional synchronization logic
  parameter bit AsyncOn = 1'b0,
  // Number of cycles a differential skew is tolerated before a signal integrity issue is flagged.
  // Only has an effect if AsyncOn = 1
  // 0 means no skew is tolerated (any mismatch is an immediate signal integrity error).
  // 1 means a one-cycle skew is tolerated.
  // Values larger than 1 are also supported.
  parameter int unsigned SkewCycles = 1
) (
  input        clk_i,
  input        rst_ni,
  // input diff pair
  input        diff_pi,
  input        diff_ni,
  // logical level and
  // detected edges
  output logic level_o,
  output logic rise_o,
  output logic fall_o,
  // either rise or fall
  output logic event_o,
  //signal integrity issue detected
  output logic sigint_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
