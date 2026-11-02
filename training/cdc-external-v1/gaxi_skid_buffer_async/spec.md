Implement the SystemVerilog module `gaxi_skid_buffer_async`.

Gaxi Skid Buffer Async module

Functional contract and interface notes:

Module: gaxi_skid_buffer_async
Purpose: Gaxi Skid Buffer Async module
AXI Skid buffer where all ports are driven or received by a flop

Required clock and reset behavior:

- Clock ports: axi_wr_aclk, axi_rd_aclk.
- Reset ports: axi_wr_aresetn, axi_rd_aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .MEM_STYLE (MEM_STYLE), .DATA_WIDTH (DW), .DEPTH (DEPTH), .USE_JOHNSON (USE_JOHNSON), .N_FLOP_CROSS (N_FLOP_CROSS), .ALMOST_WR_MARGIN(1), .ALMOST_RD_MARGIN(1), .REGISTERED (REGISTERED) ) inst_gaxi_fifo_async ( .axi_wr_aclk (axi_wr_aclk), .axi_wr_aresetn(axi_wr_aresetn), .axi_rd_aclk (axi_rd_aclk), .axi_rd_aresetn(axi_rd_aresetn), .wr_valid (r_xfer_valid), .wr_ready (r_xfer_ready), .wr_data (r_xfer_data), .rd_ready (rd_ready), .rd_valid (rd_valid), .rd_data (rd_data) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module gaxi_skid_buffer_async #(
    parameter fifo_mem_t MEM_STYLE = FIFO_AUTO,
    parameter int REGISTERED = 0,  // 0 = mux mode, 1 = flop mode
    parameter int DATA_WIDTH    = 32,
    parameter int DEPTH         = 2,
    // Pointer CDC encoding, forwarded to the internal gaxi_fifo_async.
    //   0 = Gray (default)  -- requires a power-of-2 DEPTH
    //   1 = Johnson         -- any DEPTH, odd included
    // Must be exposed here: a wrapper that hides it cannot be built at a
    // non-power-of-2 depth, because the inner FIFO rejects that under Gray.
    parameter int USE_JOHNSON   = 0,
    parameter int N_FLOP_CROSS  = 2,
    parameter int DW = DATA_WIDTH
) (
    // Global Clock and Reset
    input  logic          axi_wr_aclk,
    input  logic          axi_wr_aresetn,
    input  logic          axi_rd_aclk,
    input  logic          axi_rd_aresetn,
    // input side
    input  logic          wr_valid,
    output logic          wr_ready,
    input  logic [DW-1:0] wr_data,
    // output side
    output logic          rd_valid,
    input  logic          rd_ready,
    output logic [DW-1:0] rd_data
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
