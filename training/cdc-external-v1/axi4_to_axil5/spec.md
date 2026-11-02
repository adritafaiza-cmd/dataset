Implement the SystemVerilog module `axi4_to_axil5`.

Implement axi4 to axil5 using the interface and behavioral contract below.

Functional contract and interface notes:

axi4_to_axil5: AXI4 slave -> AXI5-Lite master, read and write.
Pairs axi4_to_axil5_rd and axi4_to_axil5_wr, exactly as axi4_to_axil4
pairs its two halves. There is no logic here beyond the two
instantiations: every conversion decision lives in the halves, and every
AXI5-Lite sideband decision (what is forwarded, tied, or terminated) is
documented in their headers rather than restated here.
The AXI5-Lite side carries AWID/BID and ARID/RID (IHI 0022L B2.1.5, Table
B2.2), AXI_ID_WIDTH bits wide: the AXI4 ID crosses unchanged and returns on
the response. AxLOCK, AxMPAM, AxMECID, AxNSAID and xLOOP are not present
on AXI5-Lite and this converter has none of them (issue #102).
The AXI4 slave surface is the FULL AXI4 interface, not a subset. A master
upstream of this converter may be feeding a fabric whose other branches
reach AXI4 slaves, so nothing is dropped from the boundary on the grounds
that this particular downstream path cannot use it.

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
module axi4_to_axil5 #(
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_DATA_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // USER is the one AXI5-Lite optional group with an AXI4 source, so it is
    // the one with an ENABLE_ knob. Default OFF: with it off this converter
    // presents the behaviour of axi4_to_axil4 plus the AXI5-Lite ID, which is
    // what an integrator migrating an AXI4-Lite slave to an AXI5-Lite port
    // starts from. TRACE / POISON are tied to zero unconditionally; see the
    // halves for why there is no ENABLE_ for them.
    parameter bit ENABLE_USER       = 1'b0,
    parameter int USER_WIDTH        = 1,
    localparam int STRB_WIDTH   = AXI_DATA_WIDTH / 8,
    localparam int POISON_WIDTH = (AXI_DATA_WIDTH / 64) > 0
                                    ? (AXI_DATA_WIDTH / 64) : 1
) (
    input  logic                        aclk,
    input  logic                        aresetn,
    //==========================================================================
    // Slave AXI4 Interface (input, full protocol)
    //==========================================================================
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  logic [7:0]                  s_axi_arlen,
    input  logic [2:0]                  s_axi_arsize,
    input  logic [1:0]                  s_axi_arburst,
    input  logic                        s_axi_arlock,
    input  logic [3:0]                  s_axi_arcache,
    input  logic [2:0]                  s_axi_arprot,
    input  logic [3:0]                  s_axi_arqos,
    input  logic [3:0]                  s_axi_arregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_aruser,
    input  logic                        s_axi_arvalid,
    output logic                        s_axi_arready,
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
    output logic [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]                  s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_ruser,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  logic [7:0]                  s_axi_awlen,
    input  logic [2:0]                  s_axi_awsize,
    input  logic [1:0]                  s_axi_awburst,
    input  logic                        s_axi_awlock,
    input  logic [3:0]                  s_axi_awcache,
    input  logic [2:0]                  s_axi_awprot,
    input  logic [3:0]                  s_axi_awqos,
    input  logic [3:0]                  s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_awuser,
    input  logic                        s_axi_awvalid,
    output logic                        s_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [STRB_WIDTH-1:0]       s_axi_wstrb,
    input  logic                        s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_wuser,
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,
    output logic [AXI_ID_WIDTH-1:0]     s_axi_bid,
    output logic [1:0]                  s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_buser,
    output logic                        s_axi_bvalid,
    input  logic                        s_axi_bready,
    //==========================================================================
    // Master AXI5-Lite Interface (output)
    //==========================================================================
    output logic [AXI_ID_WIDTH-1:0]     m_axil_arid,
    output logic [AXI_ADDR_WIDTH-1:0]   m_axil_araddr,
    output logic [2:0]                  m_axil_arprot,
    output logic                        m_axil_arvalid,
    input  logic                        m_axil_arready,
    input  logic [AXI_ID_WIDTH-1:0]     m_axil_rid,
    input  logic [AXI_DATA_WIDTH-1:0]   m_axil_rdata,
    input  logic [1:0]                  m_axil_rresp,
    input  logic                        m_axil_rvalid,
    output logic                        m_axil_rready,
    output logic [AXI_ID_WIDTH-1:0]     m_axil_awid,
    output logic [AXI_ADDR_WIDTH-1:0]   m_axil_awaddr,
    output logic [2:0]                  m_axil_awprot,
    output logic                        m_axil_awvalid,
    input  logic                        m_axil_awready,
    output logic [AXI_DATA_WIDTH-1:0]   m_axil_wdata,
    output logic [STRB_WIDTH-1:0]       m_axil_wstrb,
    output logic                        m_axil_wvalid,
    input  logic                        m_axil_wready,
    input  logic [AXI_ID_WIDTH-1:0]     m_axil_bid,
    input  logic [1:0]                  m_axil_bresp,
    input  logic                        m_axil_bvalid,
    output logic                        m_axil_bready,
    // ---- AXI5-Lite optional signals, read ----------------------------
    output logic [USER_WIDTH-1:0]       m_axil_aruser,
    output logic                        m_axil_artrace,
    input  logic [USER_WIDTH-1:0]       m_axil_ruser,
    input  logic                        m_axil_rtrace,
    input  logic [POISON_WIDTH-1:0]     m_axil_rpoison,
    // ---- AXI5-Lite optional signals, write ---------------------------
    output logic [USER_WIDTH-1:0]       m_axil_awuser,
    output logic                        m_axil_awtrace,
    output logic [USER_WIDTH-1:0]       m_axil_wuser,
    output logic [POISON_WIDTH-1:0]     m_axil_wpoison,
    input  logic [USER_WIDTH-1:0]       m_axil_buser,
    input  logic                        m_axil_btrace
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
