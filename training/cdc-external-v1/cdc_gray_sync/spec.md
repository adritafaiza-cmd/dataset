Implement the SystemVerilog module `cdc_gray_sync`.

Synchronize each bit of a Gray-coded input through the configured synchronizer stages. The source must make only legal single-bit Gray transitions.

Functional contract and interface notes:

Module : cdc_gray_sync
Purpose: Bit-parallel synchronizer for a pre-registered Gray-code bus.
Instantiates one cdc_bit per bit, all clocked by the destination
clock. Caller must ensure i_gray is a registered flip-flop output
from the source clock domain — this module does not register it.
Author : <author>
Date   : <date>

Required clock and reset behavior:

- Clock ports: i_clk.
- Reset ports: i_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_bit: cdc_bit #( .SYNC_STAGES (SYNC_STAGES), .RESET_VALUE (1'b0) ) u_sync ( .i_clk (i_clk), .i_rst_n (i_rst_n), .i_async_in (i_gray[i]), .o_sync_out (o_gray[i]) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_gray_sync #(
    parameter int unsigned WIDTH       = 4,
    parameter int unsigned SYNC_STAGES = 2
) (
    // Destination clock domain
    input  logic                i_clk,
    input  logic                i_rst_n,
    // Data — i_gray must be a registered output from the source domain
    input  logic [WIDTH-1:0]    i_gray,
    output logic [WIDTH-1:0]    o_gray
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
