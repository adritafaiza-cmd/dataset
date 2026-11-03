```verilog
module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH = 2,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
    parameter [0:0] OPT_WRITE_ONLY = 1'b0,
    parameter [0:0] OPT_READ_ONLY = 1'b0,
    parameter integer XCLOCK_FFS = 2,
    parameter integer LGFIFO = 5
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [7 : 0] S_AXI_AWLEN,
    input wire [2 : 0] S_AXI_AWSIZE,
    input wire [1 : 0] S_AXI_AWBURST,
    input wire S_AXI_AWLOCK,
    input wire [3 : 0] S_AXI_AWCACHE,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire [3 : 0] S_AXI_AWQOS,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WLAST,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [7 : 0] S_AXI_ARLEN,
    input wire [2 : 0] S_AXI_ARSIZE,
    input wire [1 : 0] S_AXI_ARBURST,
    input wire S_AXI_ARLOCK,
    input wire [3 : 0] S_AXI_ARCACHE,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire [3 : 0] S_AXI_ARQOS,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RLAST,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,
    input wire M_AXI_ACLK,
    output wire M_AXI_ARESETN,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [7 : 0] M_AXI_AWLEN,
    output wire [2 : 0] M_AXI_AWSIZE,
    output wire [1 : 0] M_AXI_AWBURST,
    output wire M_AXI_AWLOCK,
    output wire [3 : 0] M_AXI_AWCACHE,
    output wire [2 : 0] M_AXI_AWPROT,
    output wire [3 : 0] M_AXI_AWQOS,
    output wire M_AXI_AWVALID,
    input wire M_AXI_AWREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output wire M_AXI_WLAST,
    output wire M_AXI_WVALID,
    input wire M_AXI_WREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    input wire [1 : 0] M_AXI_BRESP,
    input wire M_AXI_BVALID,
    output wire M_AXI_BREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [7 : 0] M_AXI_ARLEN,
    output wire [2 : 0] M_AXI_ARSIZE,
    output wire [1 : 0] M_AXI_ARBURST,
    output wire M_AXI_ARLOCK,
    output wire [3 : 0] M_AXI_ARCACHE,
    output wire [2 : 0] M_AXI_ARPROT,
    output wire [3 : 0] M_AXI_ARQOS,
    output wire M_AXI_ARVALID,
    input wire M_AXI_ARREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire M_AXI_RLAST,
    input wire M_AXI_RVALID,
    output wire M_AXI_RREADY
);

    wire s_axi_awready, s_axi_wready, s_axi_bvalid, s_axi_arready, s_axi_rvalid;
    wire m_axi_awready, m_axi_wready, m_axi_bvalid, m_axi_arready, m_axi_rvalid;

    wire s_axi_awid_q, s_axi_awaddr_q, s_axi_awlen_q, s_axi_awsize_q, s_axi_awburst_q, s_axi_awlock_q, s_axi_awcache_q, s_axi_awprot_q, s_axi_awqos_q, s_axi_awvalid_q;
    wire s_axi_wdata_q, s_axi_wstrb_q, s_axi_wlast_q, s_axi_wvalid_q;
    wire s_axi_bid_q, s_axi_bresp_q, s_axi_bvalid_q;
    wire s_axi_arid_q, s_axi_araddr_q, s_axi_arlen_q, s_axi_arsize_q, s_axi_arburst_q, s_axi_arlock_q, s_axi_arcache_q, s_axi_arprot_q, s_axi_arqos_q, s_axi_arvalid_q;
    wire s_axi_rid_q, s_axi_rdata_q, s_axi_rresp_q, s_axi_rlast_q, s_axi_rvalid_q;

    wire m_axi_awid_q, m_axi_awaddr_q, m_axi_awlen_q, m_axi_awsize_q, m_axi_awburst_q, m_axi_awlock_q, m_axi_awcache_q, m_axi_awprot_q, m_axi_awqos_q, m_axi_awvalid_q;
    wire m_axi_wdata_q, m_axi_wstrb_q, m_axi_wlast_q, m_axi_wvalid_q;
    wire m_axi_bid_q, m_axi_bresp_q, m_axi_bvalid_q;
    wire m_axi_arid_q, m_axi_araddr_q, m_axi_arlen_q, m_axi_arsize_q, m_axi_arburst_q, m_axi_arlock_q, m_axi_arcache_q, m_axi_arprot_q, m_axi_arqos_q, m_axi_arvalid_q;
    wire m_axi_rid_q, m_axi_rdata_q, m_axi_rresp_q, m_axi_rlast_q, m_axi_rvalid_q;

    wire s_axi_awready_ff, s_axi_wready_ff, s_axi_bvalid_ff, s_axi_arready_ff, s_axi_rvalid_ff;
    wire m_axi_awready_ff, m_axi_wready_ff, m_axi_bvalid_ff, m_axi_arready_ff, m_axi_rvalid_ff;

    wire s_axi_awid_ff, s_axi_awaddr_ff, s_axi_awlen_ff, s_axi_awsize_ff, s_axi_awburst_ff, s_axi_awlock_ff, s_axi_awcache_ff, s_axi_awprot_ff, s_axi_awqos_ff, s_axi_awvalid_ff;
    wire s_axi_wdata_ff, s_axi_wstrb_ff, s_axi_wlast_ff, s_axi_wvalid_ff;
    wire s_axi_bid_ff, s_axi_bresp_ff, s_axi_bvalid_ff;
    wire s_axi_arid_ff, s_axi_araddr_ff, s_axi_arlen_ff, s_axi_arsize_ff, s_axi_arburst_ff, s_axi_arlock_ff, s_axi_arcache_ff, s_axi_arprot_ff, s_axi_arqos_ff, s_axi_arvalid_ff;
    wire s_axi_rid_ff, s_axi_rdata_ff, s_axi_rresp_ff, s_axi_rlast_ff, s_axi_rvalid_ff;

    wire m_axi_awid_ff, m_axi_awaddr_ff, m_axi_awlen_ff, m_axi_awsize_ff, m_axi_awburst_ff, m_axi_awlock_ff, m_axi_awcache_ff, m_axi_awprot_ff, m_axi_awqos_ff, m_axi_awvalid_ff;
    wire m_axi_wdata_ff, m_axi_wstrb_ff, m_axi_wlast_ff, m_axi_wvalid_ff;
    wire m_axi_bid_ff, m_axi_bresp_ff, m_axi_bvalid_ff;
    wire m_axi_arid_ff, m_axi_araddr_ff, m_axi_arlen_ff, m_axi_arsize_ff, m_axi_arburst_ff, m_axi_arlock_ff, m_axi_arcache_ff, m_axi_arprot_ff, m_axi_arqos_ff, m_axi_arvalid_ff;
    wire m_axi_rid_ff, m_axi_rdata_ff, m_axi_rresp_ff, m_axi_rlast_ff, m_axi_rvalid_ff;

    wire s_axi_awready_ff2, s_axi_wready_ff2, s_axi_bvalid_ff2, s_axi_arready_ff2, s_axi_rvalid_ff2;
    wire m_axi_awready_ff2, m_axi_wready_ff2, m_axi_bvalid_ff2, m_axi_arready_ff2, m_axi_rvalid_ff2;

    wire s_axi_awid_ff2, s_axi_awaddr_ff2, s_axi_awlen_ff2, s_axi_awsize_ff2, s_axi_awburst_ff2, s_axi_awlock_ff2, s_axi_awcache_ff2, s_axi_awprot_ff2, s_axi_awqos_ff2, s_axi_awvalid_ff2;
    wire s_axi_wdata_ff2, s_axi_wstrb_ff2, s_axi_wlast_ff2, s_axi_wvalid_ff2;
    wire s_axi_bid_ff2, s_axi_bresp_ff2, s_axi_bvalid_ff2;
    wire s_axi_arid_ff2, s_axi_araddr_ff2, s_axi_arlen_ff2, s_axi_arsize_ff2, s_axi_arburst_ff2, s_axi_arlock_ff2, s_axi_arcache_ff2, s_axi_arprot_ff2, s_axi_arqos_ff2, s_axi_arvalid_ff2;
    wire s_axi_rid_ff2, s_axi_rdata_ff2, s_axi_rresp_ff2, s_axi_rlast_ff2, s_axi_rvalid_ff2;

    wire m_axi_awid_ff2, m_axi_awaddr_ff2, m_axi_awlen_ff2, m_axi_awsize_ff2, m_axi_awburst_ff2, m_axi_awlock_ff2, m_axi_awcache_ff2, m_axi_awprot_ff2, m_axi_awqos_ff2, m_axi_awvalid_ff2;
    wire m_axi_wdata_ff2, m_axi_wstrb_ff2, m_axi_wlast_ff2, m_axi_wvalid_ff2;
    wire m_axi_bid_ff2, m_axi_bresp_ff2, m_axi_bvalid_ff2;
    wire m_axi_arid_ff2, m_axi_araddr_ff2, m_axi_arlen_ff2, m_axi_arsize_ff2, m_axi_arburst_ff2, m_axi_arlock_ff2, m_axi_arcache_ff2, m_axi_arprot_ff2, m_axi_arqos_ff2, m_axi_arvalid_ff2;
    wire m_axi_rid_ff2, m_axi_rdata_ff2, m_axi_rresp_ff2, m_axi_rlast_ff2, m_axi_rvalid_ff2;

    wire s_axi_awready_ff3, s_axi_wready_ff3, s_axi_bvalid_ff3, s_axi_arready_ff3, s_axi_rvalid_ff3;
    wire m_axi_awready_ff3, m_axi_wready_ff3, m_axi_bvalid_ff3, m_axi_arready_ff3, m_axi_rvalid_ff3;

    wire s_axi_awid_ff3, s_axi_awaddr_ff3, s_axi_awlen_ff3, s_axi_awsize_ff3, s_axi_awburst_ff3, s_axi_awlock_ff3, s_axi_awcache_ff3, s_axi_awprot_ff3, s_axi_awqos_ff3, s_axi_awvalid_ff3;
    wire s_axi_wdata_ff3, s_axi_wstrb_ff3, s_axi_wlast_ff3, s_axi_wvalid_ff3;
    wire s_axi_bid_ff3, s_axi_bresp_ff3, s_axi_bvalid_ff3;
    wire s_axi_arid_ff3, s_axi_araddr_ff3, s_axi_arlen_ff3, s_axi_arsize_ff3, s_axi_arburst_ff3, s_axi_arlock_ff3, s_axi_arcache_ff3, s_axi_arprot_ff3, s_axi_arqos_ff3, s_axi_arvalid_ff3;
    wire s_axi_rid_ff3, s_axi_rdata_ff3, s_axi_rresp_ff3, s_axi_rlast_ff3, s_axi_rvalid_ff3;

    wire m_axi_awid_ff3, m_axi_awaddr_ff3, m_axi_awlen_ff3, m_axi_awsize_ff3, m_axi_awburst_ff3, m_axi_awlock_ff3, m_axi_awcache_ff3, m_axi_awprot_ff3, m_axi_awqos_ff3, m_axi_awvalid_ff3;
    wire m_axi_wdata_ff3, m_axi_wstrb_ff3, m_axi_wlast_ff3, m_axi_wvalid_ff3;
    wire m_axi_bid_ff3, m_axi_bresp_ff3, m_axi_bvalid_ff3;
    wire m_axi_arid_ff3, m_axi_araddr_ff3, m_axi_arlen_ff3, m_axi_arsize_ff3, m_axi_arburst_ff3, m_axi_arlock_ff3, m_axi_arcache_ff3, m_axi_arprot_ff3, m_axi_arqos_ff3, m_axi_arvalid_ff3;
    wire m_axi_rid_ff3, m_axi_rdata_ff3, m_axi_rresp_ff3, m_axi_rlast_ff3, m_axi_rvalid_ff3;

    wire s_axi_awready_ff4, s_axi_wready_ff4, s_axi_bvalid_ff4, s_axi_arready_ff4, s_axi_rvalid_ff4;
    wire m_axi_awready_ff4, m_axi_wready_ff4, m_axi_bvalid_ff4, m_axi_arready_ff4, m_axi_rvalid_ff4;

    wire s_axi_awid_ff4, s_axi_awaddr_ff4, s_axi_awlen_ff4, s_axi_awsize_ff4, s_axi_awburst_ff4, s_axi_awlock_ff4, s_axi_awcache_ff4, s_axi_awprot_ff4, s_axi_awqos_ff4, s_axi_awvalid_ff4;
    wire s_axi_wdata_ff4, s_axi_wstrb_ff4, s_axi_wlast_ff4, s_axi_wvalid_ff4;
    wire s_axi_bid_ff4, s_axi_bresp_ff4, s_axi_bvalid_ff4;
    wire s_axi_arid_ff4, s_axi_araddr_ff4, s_axi_arlen_ff4, s_axi_arsize_ff4, s_axi_arburst_ff4, s_axi_arlock_ff4, s_axi_arcache_ff4, s_axi_arprot_ff4, s_axi_arqos_ff4, s_axi_arvalid_ff4;
    wire s_axi_rid_ff4, s_axi_rdata_ff4, s_axi_rresp_ff4, s_axi_rlast_ff4, s_axi_rvalid_ff4;

    wire m_axi_awid_ff4, m_axi_awaddr_ff4, m_axi_awlen_ff4, m_axi_awsize_ff4, m_axi_awburst_ff4, m_axi_awlock_ff4, m_axi_awcache_ff4, m_axi_awprot_ff4, m_axi_awqos_ff4, m_axi_awvalid_ff4;
    wire m_axi_wdata_ff4, m_axi_wstrb_ff4, m_axi_wlast_ff4, m_axi_wvalid_ff4;
    wire m_axi_bid_ff4, m_axi_bresp_ff4, m_axi_bvalid_ff4;
    wire m_axi_arid_ff4, m_axi_araddr_ff4, m_axi_arlen_ff4, m_axi_arsize_ff4, m_axi_arburst_ff4, m_axi_arlock_ff4, m_axi_arcache_ff4, m_axi_arprot_ff4, m_axi_arqos_ff4, m_axi_arvalid_ff4;
    wire m_axi_rid_ff4, m_axi_rdata_ff4, m_axi_rresp_ff4, m_axi_rlast_ff4, m_axi_rvalid_ff4;

    wire s_axi_awready_ff5, s_axi_wready_ff5, s_axi_bvalid_ff5, s_axi_arready_ff5, s_axi_rvalid_ff5;
    wire m_axi_awready_ff5, m_axi_wready_ff5, m_axi_bvalid_ff5, m_axi_arready_ff5, m_axi_rvalid_ff5;

    wire s_axi_awid_ff5, s_axi_awaddr_ff5, s_axi_awlen_ff5, s_axi_awsize_ff5, s_axi_awburst_ff5, s_axi_awlock_ff5, s_axi_awcache_ff5, s_axi_awprot_ff5, s_axi_awqos_ff5, s_axi_awvalid_ff5;
    wire s_axi_wdata_ff5, s_axi_wstrb_ff5, s_axi_wlast_ff5, s_axi_wvalid_ff5;
    wire s_axi_bid_ff5, s_axi_bresp_ff5, s_axi_bvalid_ff5;
    wire s_axi_arid_ff5, s_axi_araddr_ff5, s_axi_arlen_ff5, s_axi_arsize_ff5, s_axi_arburst_ff5, s_axi_arlock_ff5, s_axi_arcache_ff5, s_axi_arprot_ff5, s_axi_arqos_ff5, s_axi_arvalid_ff5;
    wire s_axi_rid_ff5, s_axi_rdata_ff5, s_axi_rresp_ff5, s_axi_rlast_ff5, s_axi_rvalid_ff5;

    wire m_axi_awid_ff5, m_axi_awaddr_ff5, m_axi_awlen_ff5, m_axi_awsize_ff5, m_axi_awburst_ff5, m_axi_awlock_ff5, m_axi_awcache_ff5, m_axi_awprot_ff5, m_axi_awqos_ff5, m_axi_awvalid_ff5;
    wire m_axi_wdata_ff5, m_axi_wstrb_ff5, m_axi_wlast_ff5, m_axi_wvalid_ff5;
    wire m_axi_bid_ff5, m_axi_bresp_ff5, m_axi_bvalid_ff5;
    wire m_axi_arid_ff5, m_axi_araddr_ff5, m_axi_arlen_ff5, m_axi_arsize_ff5, m_axi_arburst_ff5, m_axi_arlock_ff5, m_axi_arcache_ff5, m_axi_arprot_ff5, m_axi_arqos_ff5, m_axi_arvalid_ff5;
    wire m_axi_rid_ff5, m_axi_rdata_ff5, m_axi_rresp_ff5, m_axi_rlast_ff5, m_axi_rvalid_ff5;

    wire s_axi_awready_ff6, s_axi_wready_ff6, s_axi_bvalid_ff6, s_axi_arready_ff6, s_axi_rvalid_ff6;
    wire m_axi_awready_ff6, m_axi_wready_ff6, m_axi_bvalid_ff6, m_axi_arready_ff6, m_axi_rvalid_ff6;

    wire s_axi_awid_ff6, s_axi_awaddr_ff6, s_axi_awlen_ff6, s_axi_awsize_ff6, s_axi_awburst_ff6, s_axi_awlock_ff6, s_axi_awcache_ff6, s_axi_awprot_ff6, s_axi_awqos_ff6, s_axi_awvalid_ff6;
    wire s_axi_wdata_ff6, s_axi_wstrb_ff6, s_axi_wlast_ff6, s_axi_wvalid_ff6;
    wire s_axi_bid_ff6, s_axi_bresp_ff6, s_axi_bvalid_ff6;
    wire s_axi_arid_ff6, s_axi_araddr_ff6, s_axi_arlen_ff6, s_axi_arsize_ff6, s_axi_arburst_ff6, s_axi_arlock_ff6, s_axi_arcache_ff6, s_axi_arprot_ff6, s_axi_arqos_ff6, s_axi_arvalid_ff6;
    wire s_axi_rid_ff6, s_axi_rdata_ff6, s_axi_rresp_ff6, s_axi_rlast_ff6, s_axi_rvalid_ff6;

    wire m_axi_awid_ff6, m_axi_awaddr_ff6, m_axi_awlen_ff6, m_axi_awsize_ff6, m_axi_awburst_ff6, m_axi_awlock_ff6, m_axi_awcache_ff6, m_axi_awprot_ff6, m_axi_awqos_ff6, m_axi_awvalid_ff6;
    wire m_axi_wdata_ff6, m_axi_wstrb_ff6, m_axi_wlast_ff6, m_axi_wvalid_ff6;
    wire m_axi_bid_ff6, m_axi_bresp_ff6, m_axi_bvalid_ff6;
    wire m_axi_arid_ff6, m_axi_araddr_ff6, m_axi_arlen_ff6, m_axi_arsize_ff6, m_axi_arburst_ff6, m_axi_arlock_ff6, m_axi_arcache_ff6, m_axi_arprot_ff6, m_axi_arqos_ff6, m_axi_arvalid_ff6;
    wire m_axi_rid_ff6, m_axi_rdata_ff6, m_axi_rresp_ff6, m_axi_rlast_ff6, m_axi_rvalid_ff6;

    wire s_axi_awready_ff7, s_axi_wready_ff7, s_axi_bvalid_ff7, s_axi_arready_ff7, s_axi_rvalid_ff7;
    wire m_axi_awready_ff7, m_axi_wready_ff7, m_axi_bvalid_ff7, m_axi_arready_ff7, m_axi_rvalid_ff7;

    wire s_axi_awid_ff7, s_axi_awaddr_ff7, s_axi_awlen_ff7, s_axi_awsize_ff7, s_axi_awburst_ff7, s_axi_awlock_ff7, s_axi_awcache_ff7, s_axi_awprot_ff7, s_axi_awqos_ff7, s_axi_awvalid_ff7;
    wire s_axi_wdata_ff7, s_axi_wstrb_ff7, s_axi_wlast_ff7, s_axi_wvalid_ff7;
    wire s_axi_bid_ff7, s_axi_bresp_ff7, s_axi_bvalid_ff7;
    wire s_axi_arid_ff7, s_axi_araddr_ff7, s_axi_arlen_ff7, s_axi_arsize_ff7, s_axi_arburst_ff7, s_axi_arlock_ff7, s_axi_arcache_ff7, s_axi_arprot_ff7, s_axi_arqos_ff7, s_axi_arvalid_ff7;
    wire s_axi_rid_ff7, s_axi_rdata_ff7, s_axi_rresp_ff7, s_axi_rlast_ff7, s_axi_rvalid_ff7;

    wire m_axi_awid_ff7, m_axi_awaddr_ff7, m_axi_awlen_ff7, m_axi_awsize_ff7, m_axi_awburst_ff7, m_axi_awlock_ff7, m_axi_awcache_ff7, m_axi_awprot_ff7, m_axi_awqos_ff7, m_axi_awvalid_ff7;
    wire m_axi_wdata_ff7, m_axi_wstrb_ff7, m_axi_wlast_ff7, m_axi_wvalid_ff7;
    wire m_axi_bid_ff7, m_axi_bresp_ff7, m_axi_bvalid_ff7;
    wire m_axi_arid_ff7, m_axi_araddr_ff7, m_axi_arlen_ff7, m_axi_arsize_ff7, m_axi_arburst_ff7, m_axi_arlock_ff7, m_axi_arcache_ff7, m_axi_arprot_ff7, m_axi_arqos_ff7, m_axi_arvalid_ff7;
    wire m_axi_rid_ff7, m_axi_rdata_ff7, m_axi_rresp_ff7, m_axi_rlast_ff7, m_axi_rvalid_ff7;

    wire s_axi_awready_ff8, s_axi_wready_ff8, s_axi_bvalid_ff8, s_axi_arready_ff8, s_axi_rvalid_ff8;
    wire m_axi_awready_ff8, m_axi_wready_ff8, m_axi_bvalid_ff8, m_axi_arready_ff8, m_axi_rvalid_ff8;

    wire s_axi_awid_ff8, s_axi_awaddr_ff8, s_axi_awlen_ff8, s_axi_awsize_ff8, s_axi_awburst_ff8, s_axi_awlock_ff8, s_axi_awcache_ff8, s_axi_awprot_ff8, s_axi_awqos_ff8, s_axi_awvalid_ff8;
    wire s_axi_wdata_ff8, s_axi_wstrb_ff8, s_axi_wlast_ff8, s_axi_wvalid_ff8;
    wire s_axi_bid_ff8, s_axi_bresp_ff8, s_axi_bvalid_ff8;
    wire s_axi_arid_ff8, s_axi_araddr_ff8, s_axi_arlen_ff8, s_axi_arsize_ff8, s_axi_arburst_ff8, s_axi_arlock_ff8, s_axi_arcache_ff8, s_axi_arprot_ff8, s_axi_arqos_ff8, s_axi_arvalid_ff8;
    wire s_axi_rid_ff8, s_axi_rdata_ff8, s_axi_rresp_ff8, s_axi_rlast_ff8, s_axi_rvalid_ff8;

    wire m_axi_awid_ff8, m_axi_awaddr_ff8, m_axi_awlen_ff8, m_axi_awsize_ff8, m_axi_awburst_ff8, m_axi_awlock_ff8, m_axi_awcache_ff8, m_axi_awprot_ff8, m_axi_awqos_ff8, m_axi_awvalid_ff8;
    wire m_axi_wdata_ff8, m_axi_wstrb_ff8, m_axi_wlast_ff8, m_axi_wvalid_ff8;
    wire m_axi_bid_ff8, m_axi_bresp_ff8, m_axi_bvalid_ff8;
    wire m_axi_arid_ff8, m_axi_araddr_ff8, m_axi_arlen_ff8, m_axi_arsize_ff8, m_axi_arburst_ff8, m_axi_arlock_ff8, m_axi_arcache_ff8, m_axi_arprot_ff8, m_axi_arqos_ff8, m_axi_arvalid_ff8;
    wire m_axi_rid_ff8, m_axi_rdata_ff8, m_axi_rresp_ff8, m_axi_rlast_ff8, m_axi_rvalid_ff8;

    wire s_axi_awready_ff9, s_axi_wready_ff9, s_axi_bvalid_ff9, s_axi_arready_ff9, s_axi_rvalid_ff9;
    wire m_axi_awready_ff9, m_axi_wready_ff9, m_axi_bvalid_ff9, m_axi_arready_ff9, m_axi_rvalid_ff9;

    wire s_axi_awid_ff9, s_axi_awaddr_ff9, s_axi_awlen_ff9, s_axi_awsize_ff9, s_axi_awburst_ff9, s_axi_awlock_ff9, s_axi_awcache_ff9, s_axi_awprot_ff9, s_axi_awqos_ff9, s_axi_awvalid_ff9;
    wire s_axi_wdata_ff9, s_axi_wstrb_ff9, s_axi_wlast_ff9, s_axi_wvalid_ff9;
    wire s_axi_bid_ff9, s_axi_bresp_ff9, s_axi_bvalid_ff9;
    wire s_axi_arid_ff9, s_axi_araddr_ff9, s_axi_arlen_ff9, s_axi_arsize_ff9, s_axi_arburst_ff9, s_axi_arlock_ff9, s_axi_arcache_ff9, s_axi_arprot_ff9, s_axi_arqos_ff9, s_axi_arvalid_ff9;
    wire s_axi_rid_ff9, s_axi_rdata_ff9, s_axi_rresp_ff9, s_axi_rlast_ff9, s_axi_rvalid_ff9;

    wire m_axi_awid_ff9, m_axi_awaddr_ff9, m_axi_awlen_ff9, m_axi_awsize_ff9, m_axi_awburst_ff9, m_axi_awlock_ff9, m_axi_awcache_ff9, m_axi_awprot_ff9, m_axi_awqos_ff9, m_axi_awvalid_ff9;
    wire m_axi_wdata_ff9, m_axi_wstrb_ff9, m_axi_wlast_ff9, m_axi_wvalid_ff9;
    wire m_axi_bid_ff9, m_axi_bresp_ff9, m_axi_bvalid_ff9;
    wire m_axi_arid_ff9, m_axi_araddr_ff9, m_axi_arlen_ff9, m_axi_arsize_ff9, m_axi_arburst_ff9, m_axi_arlock_ff9, m_axi_arcache_ff9, m_axi_arprot_ff9, m_axi_arqos_ff9, m_axi_arvalid_ff9;
    wire m_axi_rid_ff9, m_axi_rdata_ff9, m_axi_rresp_ff9, m_axi_rlast_ff9, m_axi_rvalid_ff9;

    wire s_axi_awready_ff10, s_axi_wready_ff10, s_axi_bvalid_ff10, s_axi_arready_ff10, s_axi_rvalid_ff10;
    wire m_axi_awready_ff10, m_axi_wready_ff10, m_axi_bvalid_ff10, m_axi_arready_ff10, m_axi_rvalid_ff10;

    wire s_axi_awid_ff10, s_axi_awaddr_ff10, s_axi_awlen_ff10, s_axi_awsize_ff10, s_axi_awburst_ff10, s_axi_awlock_ff10, s_axi_awcache_ff10, s_axi_awprot_ff10, s_axi_awqos_ff10, s_axi_awvalid_ff10;
    wire s_axi_wdata_ff10, s_axi_wstrb_ff10, s_axi_wlast_ff10, s_axi_wvalid_ff10;
    wire s_axi_bid_ff10, s_axi_bresp_ff10, s_axi_bvalid_ff10;
    wire s_axi_arid_ff10, s_axi_araddr_ff10, s_axi_arlen_ff10, s_axi_arsize_ff10, s_axi_arburst_ff10, s_axi_arlock_ff10, s_axi_arcache_ff10, s_axi_arprot_ff10, s_axi_arqos_ff10, s_axi_arvalid_ff10;
    wire s_axi_rid_ff10, s_axi_rdata_ff10, s_axi_rresp_ff10, s_axi_rlast_ff10, s_axi_rvalid_ff10;

    wire m_axi_awid_ff10, m_axi_awaddr_ff10, m_axi_awlen_ff10, m_axi_awsize_ff10, m_axi_awburst_ff10, m_axi_awlock_ff10, m_axi_awcache_ff10, m_axi_awprot_ff10, m_axi_awqos_ff10, m_axi_awvalid_ff10;
    wire m_axi_wdata_ff10, m_axi_wstrb_ff10, m_axi_wlast_ff10, m_axi_wvalid_ff10;
    wire m_axi_bid_ff10, m_axi_bresp_ff10, m_axi_bvalid_ff10;
    wire m_axi_arid_ff10, m_axi_araddr_ff10, m_axi_arlen_ff10, m_axi_arsize_ff10, m_axi_arburst_ff10, m_axi_arlock_ff10, m_axi_arcache_ff10, m_axi_arprot_ff10, m_axi_arqos_ff10, m_axi_arvalid_ff10;
    wire m_axi_rid_ff10, m_axi_rdata_ff10, m_axi_rresp_ff10, m_axi_rlast_ff10, m_axi_rvalid_ff10;

    wire s_axi_awready_ff11, s_axi_wready_ff11, s_axi_bvalid_ff11, s_axi_arready_ff11, s_axi_rvalid_ff11;
    wire m_axi_awready_ff11, m_axi_wready_ff11, m_axi_bvalid_ff11, m_axi_arready_ff11, m_axi_rvalid_ff11;

    wire s_axi_awid_ff11, s_axi_awaddr_ff11, s_axi_awlen_ff11, s_axi_awsize_ff11, s_axi_awburst_ff11, s_axi_awlock_ff11, s_axi_awcache_ff11