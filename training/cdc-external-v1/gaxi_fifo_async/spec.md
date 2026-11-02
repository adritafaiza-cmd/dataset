Implement the SystemVerilog module `gaxi_fifo_async`.

Gaxi Fifo Async module

Functional contract and interface notes:

Module: gaxi_fifo_async
Purpose: Gaxi Fifo Async module
Parameterized Asynchronous FIFO -- any DEPTH with Johnson pointers
(USE_JOHNSON=1), power-of-2 DEPTH with Gray (USE_JOHNSON=0). "Any even
depth" was stale language from the retired fifo_async_div2.

Required clock and reset behavior:

- Clock ports: axi_wr_aclk, axi_rd_aclk.
- Reset ports: axi_wr_aresetn, axi_rd_aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (N), .WIDTH (PTRW) ) rd_ptr_gray_cross_inst( .q (r_wdom_rd_ptr_gray), .d (r_rd_ptr_gray), .clk (axi_wr_aclk), .rst_n (axi_wr_aresetn) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (N), .WIDTH (PTRW) ) wr_ptr_gray_cross_inst( .q (r_rdom_wr_ptr_gray), .d (r_wr_ptr_gray), .clk (axi_rd_aclk), .rst_n (axi_rd_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module gaxi_fifo_async #(
    parameter fifo_mem_t MEM_STYLE = FIFO_AUTO,
    parameter int        REGISTERED       = 0,   // 0 = mux mode, 1 = flop mode
    parameter int        DATA_WIDTH       = 8,
    // DEPTH default is a POWER OF 2 so the all-defaults configuration is legal
    // under the default Gray encoding (USE_JOHNSON=0). Was 10, which became an
    // illegal default when USE_JOHNSON was introduced.
    parameter int        DEPTH            = 16,
    // Pointer CDC encoding.
    //   0 (default) = GRAY code. Pointer is AW+1 bits, converted with gray2bin.
    //                 Cheap and the industry-standard scheme, but REQUIRES a
    //                 power-of-2 DEPTH (a Gray sequence only has the
    //                 single-bit-change property when it wraps at 2**N).
    //   1           = JOHNSON code. Pointer is DEPTH bits (JCW), converted with
    //                 johnson2bin. Costs DEPTH flops per pointer instead of
    //                 AW+1, but supports ARBITRARY (non-power-of-2) DEPTH.
    // Both encodings change only one bit per increment, so both are safe to
    // synchronize; this selects cost vs depth flexibility, not CDC safety.
    parameter int        USE_JOHNSON      = 0,
    parameter int        N_FLOP_CROSS     = 2,
    parameter int        ALMOST_WR_MARGIN = 1,
    parameter int        ALMOST_RD_MARGIN = 1,
    parameter int        DW = DATA_WIDTH,
    parameter int        D  = DEPTH,
    parameter int        AW = $clog2(DEPTH),
    parameter int        JCW = D,   // Johnson Counter Width
    parameter int        N  = N_FLOP_CROSS
) (
    // clocks and resets
    input  logic            axi_wr_aclk,
                            axi_wr_aresetn,
                            axi_rd_aclk,
                            axi_rd_aresetn,
    // write side
    input  logic            wr_valid,
    output logic            wr_ready,   // not full
    input  logic [DW-1:0]   wr_data,
    // read side
    input  logic            rd_ready,
    output logic            rd_valid,   // not empty
    output logic [DW-1:0]   rd_data
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
