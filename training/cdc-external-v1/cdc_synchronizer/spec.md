Implement the SystemVerilog module `cdc_synchronizer`.

Multi-bit synchronizer for clock domain crossing

Functional contract and interface notes:

Module: cdc_synchronizer
Purpose: Multi-bit synchronizer for clock domain crossing
This module provides a simple CDC synchronizer interface that wraps
the glitch_free_n_dff_arn module for consistent naming across the
AMBA infrastructure.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (FLOP_COUNT), .WIDTH (WIDTH) ) u_sync ( .clk (clk), .rst_n (rst_n), .d (async_in), .q (sync_out) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_synchronizer #(
    parameter int WIDTH      = 1,   // Bus width to synchronize
    parameter int FLOP_COUNT = 3    // Number of synchronizer stages (2-5)
) (
    input  logic             clk,       // Destination clock
    input  logic             rst_n,     // Asynchronous active-low reset
    input  logic [WIDTH-1:0] async_in,  // Asynchronous input from source domain
    output logic [WIDTH-1:0] sync_out   // Synchronized output in destination domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
