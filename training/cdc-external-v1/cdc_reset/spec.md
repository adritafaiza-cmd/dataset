Implement the SystemVerilog module `cdc_reset`.

Assert reset asynchronously and release it only after SYNC_STAGES destination-clock edges through the release pipeline.

Functional contract and interface notes:

cdc_reset.sv — Reset Synchronizer
Async assert, synchronous deassert reset synchronizer.
This is the one valid use of async reset in FPGA design.
Active-low reset: i_async_rst_n=0 asserts instantly, deasserts after SYNC_STAGES clocks.

Required clock and reset behavior:

- Clock ports: i_clk.
- Reset ports: i_async_rst_n, o_sync_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_reset #(
    parameter int SYNC_STAGES = 2
) (
    input  logic i_clk,
    input  logic i_async_rst_n,    // Active-low async reset input
    output logic o_sync_rst_n      // Active-low synchronized reset output
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
