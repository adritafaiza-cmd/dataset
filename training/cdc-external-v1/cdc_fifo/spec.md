Implement the SystemVerilog module `cdc_fifo`.

Implement a dual-clock FIFO with local binary pointers, Gray-coded pointer transfer through synchronizers, and domain-local full and empty decisions.

Functional contract and interface notes:

Module : cdc_fifo
Purpose: Async FIFO with Gray-code pointer synchronization.
Binary pointer and its Gray code are registered together in the
source domain on the same clock edge, so the synchronizer input is
always a stable FF output — no combinational glitches at CDC boundary.
Reference: Clifford E. Cummings, "Simulation and Synthesis Techniques for
Asynchronous FIFO Design", SNUG 2002.
Key techniques adopted from this work:
- Gray-code pointers for metastability-safe CDC
- Extra pointer MSB (PTR_WIDTH = addr_bits + 1) for
unambiguous full/empty detection
- Two-MSB-different rule for full flag generation
- Registering binary and Gray together in the source domain
Author : <author>
Date   : <date>

Required clock and reset behavior:

- Clock ports: i_wr_clk, i_rd_clk.
- Reset ports: i_wr_rst_n, i_rd_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_gray_sync: cdc_gray_sync #( .WIDTH (PTR_WIDTH), .SYNC_STAGES (SYNC_STAGES) ) u_rd_ptr_sync ( .i_clk (i_wr_clk), .i_rst_n (i_wr_rst_n), .i_gray (rd_ptr_gray_r), .o_gray (rd_ptr_gray_sync) );
- cdc_gray_sync: cdc_gray_sync #( .WIDTH (PTR_WIDTH), .SYNC_STAGES (SYNC_STAGES) ) u_wr_ptr_sync ( .i_clk (i_rd_clk), .i_rst_n (i_rd_rst_n), .i_gray (wr_ptr_gray_r), .o_gray (wr_ptr_gray_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_fifo #(
    parameter int WIDTH       = 8,
    parameter int DEPTH       = 4,
    parameter int SYNC_STAGES = 2,
    // Derived
    parameter int ADDR_WIDTH  = $clog2(DEPTH)
) (
    // Write domain
    input  logic                i_wr_clk,
    input  logic                i_wr_rst_n,
    input  logic                i_wr_en,
    input  logic [WIDTH-1:0]    i_wr_data,
    output logic                o_full,
    // Read domain
    input  logic                i_rd_clk,
    input  logic                i_rd_rst_n,
    input  logic                i_rd_en,
    output logic [WIDTH-1:0]    o_rd_data,
    output logic                o_empty
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
