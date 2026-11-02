Implement the SystemVerilog module `cdc_counter`.

Maintain a source-domain binary event count, convert it to Gray code for transfer, synchronize it into the destination domain, and reconstruct the destination count.

Functional contract and interface notes:

Module : cdc_counter
Purpose: Self-contained CDC-safe binary counter. Owns the binary counter in
the source domain, registers the Gray code on the same clock edge,
then synchronizes to the destination domain via cdc_gray_sync.
Reusable primitive for credit counters, sequence numbers, etc.
Author : <author>
Date   : <date>

Required clock and reset behavior:

- Clock ports: i_src_clk, i_dst_clk.
- Reset ports: i_src_rst_n, i_dst_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_gray_sync: cdc_gray_sync #( .WIDTH (WIDTH), .SYNC_STAGES (SYNC_STAGES) ) u_gray_sync ( .i_clk (i_dst_clk), .i_rst_n (i_dst_rst_n), .i_gray (gray_r), .o_gray (o_dst_gray) );
- cdc_gray_conv: cdc_gray_conv #(.WIDTH(WIDTH)) u_gray2bin ( .i_binary ('0), .o_gray (), .i_gray (o_dst_gray), .o_binary (o_dst_count) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_counter #(
    parameter int unsigned WIDTH       = 4,
    parameter int unsigned SYNC_STAGES = 2
) (
    // Source clock domain
    input  logic                i_src_clk,
    input  logic                i_src_rst_n,
    input  logic                i_count_up,
    input  logic                i_count_down,
    output logic [WIDTH-1:0]    o_src_count,   // binary count in source domain
    // Destination clock domain
    input  logic                i_dst_clk,
    input  logic                i_dst_rst_n,
    output logic [WIDTH-1:0]    o_dst_gray,    // synchronized Gray in dst domain
    output logic [WIDTH-1:0]    o_dst_count    // synchronized binary in dst domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
