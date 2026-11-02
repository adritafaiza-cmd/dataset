Implement the SystemVerilog module `sdpram_slave_axi4_axi4`.

AXI4-write + AXI4-read protocol wrapper for sdpram_core.

Functional contract and interface notes:

Module: sdpram_slave_axi4_axi4
Purpose: AXI4-write + AXI4-read protocol wrapper for sdpram_core.
Directly instantiates axi4_slave_wr + axi4_slave_rd (the
native AXI4 skid leaf modules) and pipes their FUB-side
outputs into the shared sdpram_core backend. No string-
switch generate plumbing; no fake AXI4 fields. One of the
four protocol permutations:
sdpram_slave_axi4_axi4    -- AXI4 wr,  AXI4 rd   <-- this file
sdpram_slave_axi4_axil    -- AXI4 wr,  AXIL rd
sdpram_slave_axil_axi4    -- AXIL wr,  AXI4 rd
sdpram_slave_axil_axil    -- AXIL wr,  AXIL rd
Burst concurrency: sdpram_core queues burst commands two deep per
direction and reloads its tracker the cycle the active burst
completes, so a burst boundary is FREE -- burst n+1's first
beat lands the cycle after burst n's last. The one stall a
master can still see is the stream-start fill: this wrapper's
registered skid leaf takes up to two W beats while the first
AW is still propagating to the core. See sdpram_core.sv's
"Burst concurrency" section and amba ISSUE-004 (fixed
2026-10-02 after Sean overruled its no-action close).

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
module sdpram_slave_axi4_axi4 #(
    parameter int    AXI_ID_WIDTH = 8,
    parameter int    ADDR_WIDTH   = 32,
    parameter int    DATA_WIDTH   = 256,
    parameter int    USER_WIDTH   = 1,
    parameter int    MEM_DEPTH    = 2048,
    // Forwarded to sdpram_core; see the long comment on its own USE_WSTRB.
    // The default is 1'b1, which is what every existing instantiation of this
    // wrapper already gets, so nothing changes for them. It is exposed
    // because at 1'b1 the core's write block mixes a full-word clear and a
    // byte-granular write on a muxed address, which Vivado cannot map to a
    // BRAM write port -- it drops the whole array into distributed RAM. A
    // consumer whose writer never asserts a partial strobe (a job engine that
    // writes whole beats, say) wants 1'b0 and block RAM. The AXI-Lite sibling
    // has always exposed this; the AXI4 one simply had not.
    parameter bit    USE_WSTRB    = 1'b1,
    parameter int    SKID_DEPTH_AW = 2,
    parameter int    SKID_DEPTH_W  = 2,
    parameter int    SKID_DEPTH_B  = 2,
    parameter int    SKID_DEPTH_AR = 2,
    parameter int    SKID_DEPTH_R  = 4
) (
    input  logic                        aclk,
    input  logic                        aresetn,
    // ---------------------------------------------------------------
    // AXI4 slave write channels (AW + W + B)
    // ---------------------------------------------------------------
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_awid,
    input  logic [ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  logic [7:0]                  s_axi_awlen,
    input  logic [2:0]                  s_axi_awsize,
    input  logic [1:0]                  s_axi_awburst,
    input  logic                        s_axi_awlock,
    input  logic [3:0]                  s_axi_awcache,
    input  logic [2:0]                  s_axi_awprot,
    input  logic [3:0]                  s_axi_awqos,
    input  logic [3:0]                  s_axi_awregion,
    input  logic [USER_WIDTH-1:0]       s_axi_awuser,
    input  logic                        s_axi_awvalid,
    output logic                        s_axi_awready,
    input  logic [DATA_WIDTH-1:0]       s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]     s_axi_wstrb,
    input  logic                        s_axi_wlast,
    input  logic [USER_WIDTH-1:0]       s_axi_wuser,
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,
    output logic [AXI_ID_WIDTH-1:0]     s_axi_bid,
    output logic [1:0]                  s_axi_bresp,
    output logic [USER_WIDTH-1:0]       s_axi_buser,
    output logic                        s_axi_bvalid,
    input  logic                        s_axi_bready,
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
