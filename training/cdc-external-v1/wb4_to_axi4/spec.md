Implement the SystemVerilog module `wb4_to_axi4`.

Implement wb4 to axi4 using the interface and behavioral contract below.

Functional contract and interface notes:

wb4_to_axi4: Wishbone B4 slave in, AXI4 requester out.
wb4_to_axil4 does the work -- wb4_slave, the in-order response merge of
wb4_to_axil4_core, the axil4 masters -- and this wrapper promotes its
AXI4-Lite face to full AXI4 the way an AXI4-Lite requester is promoted
anywhere in the fabric: every transfer is one beat (AxLEN = 0, AxSIZE the
full width, INCR, WLAST = 1), the ID is a constant (DEFAULT_ID), the
attributes it cannot express are zero, and the response's ID and LAST are
dropped. SEL rides WSTRB unchanged; Wishbone carries no protection bits,
so AxPROT is AXIL_PROT.
ERR to the requester when the AXI response is SLVERR or DECERR (the core
maps resp[1]); Wishbone has no way to say which. RTY is never generated:
AXI has no retry to translate.
The bridge generator puts this in front of a master port declared
protocol = "wb4" and feeds the ordinary AXI4 timing wrapper with its
m_axi face -- the Wishbone counterpart of apb4_to_axi4.

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
module wb4_to_axi4
    import wb4_pkg::*;
#(
    parameter int ADDR_WIDTH      = 32,
    parameter int DATA_WIDTH      = 32,
    parameter int AXI_ID_WIDTH    = 1,
    parameter int AXI_USER_WIDTH  = 1,
    parameter logic [AXI_ID_WIDTH-1:0] DEFAULT_ID = '0,
    parameter logic [3:0] DEFAULT_CACHE = 4'b0000,
    parameter int CMD_DEPTH       = 2,
    parameter int RSP_DEPTH       = 2,
    parameter int MAX_OUTSTANDING = 16,
    parameter int CLASSIC         = 0,
    parameter int OUTSTANDING     = 1,
    parameter int SKID_DEPTH_AW   = 2,
    parameter int SKID_DEPTH_W    = 2,
    parameter int SKID_DEPTH_B    = 2,
    parameter int SKID_DEPTH_AR   = 2,
    parameter int SKID_DEPTH_R    = 2,
    parameter logic [2:0] AXIL_PROT = 3'b000,
    parameter int AW  = ADDR_WIDTH,
    parameter int DW  = DATA_WIDTH,
    parameter int SW  = DW / 8,
    parameter int IW  = AXI_ID_WIDTH,
    parameter int UW  = AXI_USER_WIDTH,
    parameter int CTW = WB4_CTI_WIDTH,
    parameter int BTW = WB4_BTE_WIDTH
) (
    input  logic              aclk,
    input  logic              aresetn,
    // Wishbone B4 slave (the external requester drives these)
    input  logic              s_wb_CYC,
    input  logic              s_wb_STB,
    input  logic              s_wb_WE,
    input  logic [AW-1:0]     s_wb_ADR,
    input  logic [DW-1:0]     s_wb_DAT_W,
    input  logic [SW-1:0]     s_wb_SEL,
    input  logic [CTW-1:0]    s_wb_CTI,
    input  logic [BTW-1:0]    s_wb_BTE,
    output logic              s_wb_STALL,
    output logic              s_wb_ACK,
    output logic              s_wb_ERR,
    output logic              s_wb_RTY,
    output logic [DW-1:0]     s_wb_DAT_R,
    // AXI4 requester
    output logic [IW-1:0]     m_axi_awid,
    output logic [AW-1:0]     m_axi_awaddr,
    output logic [7:0]        m_axi_awlen,
    output logic [2:0]        m_axi_awsize,
    output logic [1:0]        m_axi_awburst,
    output logic              m_axi_awlock,
    output logic [3:0]        m_axi_awcache,
    output logic [2:0]        m_axi_awprot,
    output logic [3:0]        m_axi_awqos,
    output logic [3:0]        m_axi_awregion,
    output logic [UW-1:0]     m_axi_awuser,
    output logic              m_axi_awvalid,
    input  logic              m_axi_awready,
    output logic [DW-1:0]     m_axi_wdata,
    output logic [SW-1:0]     m_axi_wstrb,
    output logic              m_axi_wlast,
    output logic [UW-1:0]     m_axi_wuser,
    output logic              m_axi_wvalid,
    input  logic              m_axi_wready,
    input  logic [IW-1:0]     m_axi_bid,
    input  logic [1:0]        m_axi_bresp,
    input  logic [UW-1:0]     m_axi_buser,
    input  logic              m_axi_bvalid,
    output logic              m_axi_bready,
    output logic [IW-1:0]     m_axi_arid,
    output logic [AW-1:0]     m_axi_araddr,
    output logic [7:0]        m_axi_arlen,
    output logic [2:0]        m_axi_arsize,
    output logic [1:0]        m_axi_arburst,
    output logic              m_axi_arlock,
    output logic [3:0]        m_axi_arcache,
    output logic [2:0]        m_axi_arprot,
    output logic [3:0]        m_axi_arqos,
    output logic [3:0]        m_axi_arregion,
    output logic [UW-1:0]     m_axi_aruser,
    output logic              m_axi_arvalid,
    input  logic              m_axi_arready,
    input  logic [IW-1:0]     m_axi_rid,
    input  logic [DW-1:0]     m_axi_rdata,
    input  logic [1:0]        m_axi_rresp,
    input  logic              m_axi_rlast,
    input  logic [UW-1:0]     m_axi_ruser,
    input  logic              m_axi_rvalid,
    output logic              m_axi_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
