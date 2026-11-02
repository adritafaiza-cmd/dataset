Implement the SystemVerilog module `rstmgr_por`.

Condition power-on reset with asynchronous assertion, synchronized release, and the configured reset stretching sequence in the destination clock domain.

Functional contract and interface notes:

This module stretches the POR

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni, scan_rst_ni, rst_no.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width(1), .ResetValue('0) ) u_rst_sync ( .clk_i(clk_i), .rst_ni(rst_ni), .d_i(1'b1), .q_o(rst_root_n_pre_mux) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module rstmgr_por #(
  parameter int FilterStages = 3,
  parameter int unsigned StretchCount = 32
) (
  input clk_i,
  input rst_ni,
  input scan_rst_ni,
  input scanmode_i,
  output logic rst_no
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
