Implement the SystemVerilog module `clkmgr_clk_status`.

Transfer and combine clock-enabled status across the clock domains using a request/acknowledge synchronization path.

Functional contract and interface notes:

Wrapper module for computing enable / disable status on family of clocks

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width(NumClocks) ) u_en_sync ( .clk_i, .rst_ni, .d_i(ens_i), .q_o(ens_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module clkmgr_clk_status #(
  parameter int NumClocks = 1,
  parameter int FilterStages = 2
) (
  input clk_i,
  input rst_ni,
  input [NumClocks-1:0] ens_i,
  output logic status_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
