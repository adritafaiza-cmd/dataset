Implement the SystemVerilog module `bridge_cdc_slave_arb`.

Slave-domain arbitration for a slave port on its own clock that

Functional contract and interface notes:

Module: bridge_cdc_slave_arb
Purpose: Slave-domain arbitration for a slave port on its own clock that
two or more masters share (bridge W9).
Description:
Each master reaches the slave through its own lanes: one async FIFO each
for AW, W and AR, crossing from the fabric clock (aclk) to the slave
clock (s_aclk). AW and AR are arbitrated on s_aclk by arbiter_matrix in
ACK mode, so the pick is made where the slave is served and the
crossings hold only requests not yet granted. (With one crossing behind
a fabric-side arbiter, granted requests queued in it and a master's
share followed its outstanding count: 0.18-0.20 against 0.80.)
- The grant is a flop and holds until the slave-side handshake; the
payload is the granted lane's FIFO head, muxed by the registered
grant ID. On the handshake the arbiter hands the grant on in the same
cycle -- to the same lane when it is the only one requesting, so one
lane alone still issues one request per cycle. If that lane's FIFO
has just emptied, the grant is stale: VALID is masked by the lane's
own valid and the grant is released with an ack of its own.
- W follows the AW pick: an owner FIFO records the granted lane at each
AW handshake, and its head selects the W lane until WLAST. With the
FIFO empty, the lane whose AW is being presented owns W at once (the
owner bypass): the grant is a flop, so this depends on no READY, and
WVALID before AWREADY (A3.3.1 allows it) never saw W and deadlocked
the fabric (bridge BUG-020). If the bypassed burst's WLAST goes before
its AW handshake, `own_ahead` marks it so the handshake pushes no
owner; the grant holds on that lane meanwhile (WAIT_GNT_ACK).
- B and R cross back to aclk through one async FIFO each; the fabric
routes them by the master-index bits of their ID.
- At most MAX_OUTSTANDING writes and MAX_OUTSTANDING reads are in
flight at the slave. The limit counts the AW/AR being presented
(registered), so a same-cycle grant handoff can never exceed it; it
also bounds the owner FIFO, whose entries live from AW to WLAST.
Parameters:
NM              - masters (lanes), >= 1
IW, ADDR_W, DW, UW - AXI4 ID / address / data / user widths
MAX_OUTSTANDING - per direction at the slave, >= 2
CDC_DEPTH       - entries per crossing FIFO (8 carries one beat per
cycle across the crossing's round trip)
HAS_WR, HAS_RD  - which directions exist
Lane payloads (fabric side), lane i at [i*PW +: PW]:
AW / AR: {id, addr, len, size, burst, lock, cache, prot, qos, region, user}
W:       {data, strb, last, user}
B:       {id, resp, user}           R: {id, data, resp, last, user}
Dependencies: gaxi_fifo_async (rtl/cdc), gaxi_fifo_sync (rtl/amba/gaxi),
arbiter_matrix (rtl/common)

Required clock and reset behavior:

- Clock ports: aclk, s_aclk.
- Reset ports: aresetn, s_aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (AXPW), .DEPTH (CDC_DEPTH) ) u_aw ( .axi_wr_aclk (aclk), .axi_wr_aresetn (aresetn), .axi_rd_aclk (s_aclk), .axi_rd_aresetn (s_aresetn), .wr_valid (lane_awvalid[i]), .wr_ready (lane_awready[i]), .wr_data (lane_aw[i*AXPW +: AXPW]), .rd_ready (aw_lr[i]), .rd_valid (aw_lv[i]), .rd_data (aw_ld[i]) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (WPW), .DEPTH (CDC_DEPTH) ) u_w ( .axi_wr_aclk (aclk), .axi_wr_aresetn (aresetn), .axi_rd_aclk (s_aclk), .axi_rd_aresetn (s_aresetn), .wr_valid (lane_wvalid[i]), .wr_ready (lane_wready[i]), .wr_data (lane_w[i*WPW +: WPW]), .rd_ready (w_lr[i]), .rd_valid (w_lv[i]), .rd_data (w_ld[i]) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (BPW), .DEPTH (CDC_DEPTH) ) u_b ( .axi_wr_aclk (s_aclk), .axi_wr_aresetn (s_aresetn), .axi_rd_aclk (aclk), .axi_rd_aresetn (aresetn), .wr_valid (m_axi_bvalid), .wr_ready (m_axi_bready), .wr_data ({m_axi_bid, m_axi_bresp, m_axi_buser}), .rd_ready (fab_bready), .rd_valid (fab_bvalid), .rd_data (fab_b) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (AXPW), .DEPTH (CDC_DEPTH) ) u_ar ( .axi_wr_aclk (aclk), .axi_wr_aresetn (aresetn), .axi_rd_aclk (s_aclk), .axi_rd_aresetn (s_aresetn), .wr_valid (lane_arvalid[i]), .wr_ready (lane_arready[i]), .wr_data (lane_ar[i*AXPW +: AXPW]), .rd_ready (ar_lr[i]), .rd_valid (ar_lv[i]), .rd_data (ar_ld[i]) );
- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (RPW), .DEPTH (CDC_DEPTH) ) u_r ( .axi_wr_aclk (s_aclk), .axi_wr_aresetn (s_aresetn), .axi_rd_aclk (aclk), .axi_rd_aresetn (aresetn), .wr_valid (m_axi_rvalid), .wr_ready (m_axi_rready), .wr_data ({m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_ruser}), .rd_ready (fab_rready), .rd_valid (fab_rvalid), .rd_data (fab_r) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module bridge_cdc_slave_arb #(
    parameter int NM              = 2,
    parameter int IW              = 4,
    parameter int ADDR_W          = 32,
    parameter int DW              = 32,
    parameter int UW              = 1,
    parameter int MAX_OUTSTANDING = 16,
    parameter int CDC_DEPTH       = 8,
    parameter int HAS_WR          = 1,
    parameter int HAS_RD          = 1,
    // Derived: do not override
    parameter int AXPW = IW + ADDR_W + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4 + UW,
    parameter int WPW  = DW + DW / 8 + 1 + UW,
    parameter int BPW  = IW + 2 + UW,
    parameter int RPW  = IW + DW + 2 + 1 + UW
) (
    input  logic                  aclk,
    input  logic                  aresetn,
    input  logic                  s_aclk,
    input  logic                  s_aresetn,
    // ---- fabric side (aclk): per-master lanes ----
    input  logic [NM-1:0]         lane_awvalid,
    output logic [NM-1:0]         lane_awready,
    input  logic [NM*AXPW-1:0]    lane_aw,
    input  logic [NM-1:0]         lane_wvalid,
    output logic [NM-1:0]         lane_wready,
    input  logic [NM*WPW-1:0]     lane_w,
    output logic                  fab_bvalid,
    input  logic                  fab_bready,
    output logic [BPW-1:0]        fab_b,
    input  logic [NM-1:0]         lane_arvalid,
    output logic [NM-1:0]         lane_arready,
    input  logic [NM*AXPW-1:0]    lane_ar,
    output logic                  fab_rvalid,
    input  logic                  fab_rready,
    output logic [RPW-1:0]        fab_r,
    // ---- slave side (s_aclk): AXI4 ----
    output logic [IW-1:0]         m_axi_awid,
    output logic [ADDR_W-1:0]     m_axi_awaddr,
    output logic [7:0]            m_axi_awlen,
    output logic [2:0]            m_axi_awsize,
    output logic [1:0]            m_axi_awburst,
    output logic                  m_axi_awlock,
    output logic [3:0]            m_axi_awcache,
    output logic [2:0]            m_axi_awprot,
    output logic [3:0]            m_axi_awqos,
    output logic [3:0]            m_axi_awregion,
    output logic [UW-1:0]         m_axi_awuser,
    output logic                  m_axi_awvalid,
    input  logic                  m_axi_awready,
    output logic [DW-1:0]         m_axi_wdata,
    output logic [DW/8-1:0]       m_axi_wstrb,
    output logic                  m_axi_wlast,
    output logic [UW-1:0]         m_axi_wuser,
    output logic                  m_axi_wvalid,
    input  logic                  m_axi_wready,
    input  logic [IW-1:0]         m_axi_bid,
    input  logic [1:0]            m_axi_bresp,
    input  logic [UW-1:0]         m_axi_buser,
    input  logic                  m_axi_bvalid,
    output logic                  m_axi_bready,
    output logic [IW-1:0]         m_axi_arid,
    output logic [ADDR_W-1:0]     m_axi_araddr,
    output logic [7:0]            m_axi_arlen,
    output logic [2:0]            m_axi_arsize,
    output logic [1:0]            m_axi_arburst,
    output logic                  m_axi_arlock,
    output logic [3:0]            m_axi_arcache,
    output logic [2:0]            m_axi_arprot,
    output logic [3:0]            m_axi_arqos,
    output logic [3:0]            m_axi_arregion,
    output logic [UW-1:0]         m_axi_aruser,
    output logic                  m_axi_arvalid,
    input  logic                  m_axi_arready,
    input  logic [IW-1:0]         m_axi_rid,
    input  logic [DW-1:0]         m_axi_rdata,
    input  logic [1:0]            m_axi_rresp,
    input  logic                  m_axi_rlast,
    input  logic [UW-1:0]         m_axi_ruser,
    input  logic                  m_axi_rvalid,
    output logic                  m_axi_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
