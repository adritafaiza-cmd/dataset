Implement the SystemVerilog module `amba_clock_gate_ctrl`.

Amba Clock Gate Ctrl module

Functional contract and interface notes:

Module: amba_clock_gate_ctrl
Purpose: Amba Clock Gate Ctrl module

Required clock and reset behavior:

- Clock ports: clk_in, clk_out.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (clk_in), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module amba_clock_gate_ctrl #(
    parameter int CG_IDLE_COUNT_WIDTH = 4,                   // Default width of idle counter
    parameter int ICW                 = CG_IDLE_COUNT_WIDTH
) (
    // Clock and Reset
    input logic clk_in,
    input logic aresetn,
    // Configuration Interface
    input logic         cfg_cg_enable,     // Global clock gate enable
    input logic [ICW-1:0] cfg_cg_idle_count, // Idle countdown value
    // Activity Monitoring
    input logic user_valid,  // Any user-side valid signal
    input logic axi_valid,   // Any AXI-side valid signal
    // Clock Gating Control Outputs
    output logic clk_out,   // Gated clock
    output logic gating,  // Active gating indicator
    output logic idle     // All buffers empty indicator
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
