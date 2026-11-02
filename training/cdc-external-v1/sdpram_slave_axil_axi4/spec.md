Implement the SystemVerilog module `sdpram_slave_axil_axi4`.

AXIL-write + AXI4-read protocol wrapper for sdpram_core.

Functional contract and interface notes:

Module: sdpram_slave_axil_axi4
Purpose: AXIL-write + AXI4-read protocol wrapper for sdpram_core.
Write side instantiates axil4_slave_wr (single-beat);
read side instantiates axi4_slave_rd (full AXI4 with id /
len / size / burst). The wrapper bridges the AXIL write
FUB into sdpram_core's AXI-shaped FUB with single-beat
defaults (awlen=0, awsize=$clog2(STRB_W), awburst=INCR,
awid=0).

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module sdpram_slave_axil_axi4 #(
    parameter int    AXI_ID_WIDTH = 8,
    parameter int    ADDR_WIDTH   = 32,
    // DATA_WIDTH is shared by both sides; the AXI4-Lite side allows only 32 or
    // 64 bits (IHI 0022H B1.1.2, enforced by the axil4 width guard, #102).
    parameter int    DATA_WIDTH   = 64,
    parameter int    USER_WIDTH   = 1,
    parameter int    MEM_DEPTH    = 2048,
    parameter int    SKID_DEPTH_AW = 2,
    parameter int    SKID_DEPTH_W  = 2,
    parameter int    SKID_DEPTH_B  = 2,
    parameter int    SKID_DEPTH_AR = 2,
    parameter int    SKID_DEPTH_R  = 4
) (
    input  logic                        aclk,
    input  logic                        aresetn,
    // ---------------------------------------------------------------
    // AXIL slave write channels (AW + W + B)
    // ---------------------------------------------------------------
    input  logic [ADDR_WIDTH-1:0]       s_axil_awaddr,
    input  logic [2:0]                  s_axil_awprot,
    input  logic                        s_axil_awvalid,
    output logic                        s_axil_awready,
    input  logic [DATA_WIDTH-1:0]       s_axil_wdata,
    input  logic [DATA_WIDTH/8-1:0]     s_axil_wstrb,
    input  logic                        s_axil_wvalid,
    output logic                        s_axil_wready,
    output logic [1:0]                  s_axil_bresp,
    output logic                        s_axil_bvalid,
    input  logic                        s_axil_bready,
    // ---------------------------------------------------------------
    // AXI4 slave read channels (AR + R)
    // ---------------------------------------------------------------
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,
    input  logic [ADDR_WIDTH-1:0]       s_axi_araddr,
    input  logic [7:0]                  s_axi_arlen,
    input  logic [2:0]                  s_axi_arsize,
    input  logic [1:0]                  s_axi_arburst,
    input  logic                        s_axi_arlock,
    input  logic [3:0]                  s_axi_arcache,
    input  logic [2:0]                  s_axi_arprot,
    input  logic [3:0]                  s_axi_arqos,
    input  logic [3:0]                  s_axi_arregion,
    input  logic [USER_WIDTH-1:0]       s_axi_aruser,
    input  logic                        s_axi_arvalid,
    output logic                        s_axi_arready,
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
    output logic [DATA_WIDTH-1:0]       s_axi_rdata,
    output logic [1:0]                  s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [USER_WIDTH-1:0]       s_axi_ruser,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,
    // Bulk-clear control + debug
    input  logic                        i_cfg_start_clear,
    output logic                        o_cfg_done_clear,
    output logic [9:0]                  o_dbg_vr,
    output logic [9:0]                  o_dbg_fub_vr,
    output logic                        o_dbg_bram_wr,
    output logic                        o_dbg_bram_rd,
    output logic                        o_dbg_busy_wr,
    output logic                        o_dbg_busy_rd
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
