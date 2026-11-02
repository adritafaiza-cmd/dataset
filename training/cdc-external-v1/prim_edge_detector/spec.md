Implement the SystemVerilog module `prim_edge_detector`.

Optionally synchronize the asynchronous input, then compare its current and previous sampled levels to detect the selected edge polarity.

Functional contract and interface notes:

Edge Detector

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width (Width), .ResetValue (ResetValue) ) u_sync ( .clk_i, .rst_ni, .d_i, .q_o (q_sync_d) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_edge_detector #(
  parameter int unsigned Width = 1,
  parameter logic [Width-1:0] ResetValue = '0,
  // EnSync
  //
  // Enable Synchronizer to the input signal.
  // It is assumed that the input signal is glitch free (registered input).
  parameter bit EnSync  = 1'b 1
) (
  input clk_i,
  input rst_ni,
  input        [Width-1:0] d_i,
  output logic [Width-1:0] q_sync_o,
  output logic [Width-1:0] q_posedge_pulse_o,
  output logic [Width-1:0] q_negedge_pulse_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
