module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH  = 2,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
    parameter [0:0] OPT_WRITE_ONLY = 1'b0,
    parameter [0:0] OPT_READ_ONLY = 1'b0,
    parameter XCLOCK_FFS = 2,
    parameter LGFIFO = 5
) (
    input wire                S_AXI_ACLK,
    input wire                S_AXI_ARESETN,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [7 : 0]            S_AXI_AWLEN,
    input wire [2 : 0]            S_AXI_AWSIZE,
    input wire [1 : 0]            S_AXI_AWBURST,
    input wire                S_AXI_AWLOCK,
    input wire [3 : 0]            S_AXI_AWCACHE,
    input wire [2 : 0]            S_AXI_AWPROT,
    input wire [3 : 0]            S_AXI_AWQOS,
    input wire                S_AXI_AWVALID,
    output wire                 S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire                S_AXI_WLAST,
    input wire                S_AXI_WVALID,
    output wire                 S_AXI_WREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output wire [1 : 0]           S_AXI_BRESP,
    output wire                 S_AXI_BVALID,
    input wire                S_AXI_BREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [7 : 0]            S_AXI_ARLEN,
    input wire [2 : 0]            S_AXI_ARSIZE,
    input wire [1 : 0]            S_AXI_ARBURST,
    input wire                S_AXI_ARLOCK,
    input wire [3 : 0]            S_AXI_ARCACHE,
    input wire [2 : 0]            S_AXI_ARPROT,
    input wire [3 : 0]            S_AXI_ARQOS,
    input wire                S_AXI_ARVALID,
    output wire                 S_AXI_ARREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0]           S_AXI_RRESP,
    output wire                 S_AXI_RLAST,
    output wire                 S_AXI_RVALID,
    input wire                S_AXI_RREADY,
    input wire                M_AXI_ACLK,
    output wire                 M_AXI_ARESETN,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [7 : 0]            M_AXI_AWLEN,
    output wire [2 : 0]            M_AXI_AWSIZE,
    output wire [1 : 0]            M_AXI_AWBURST,
    output wire                 M_AXI_AWLOCK,
    output wire [3 : 0]            M_AXI_AWCACHE,
    output wire [2 : 0]            M_AXI_AWPROT,
    output wire [3 : 0]            M_AXI_AWQOS,
    output wire                 M_AXI_AWVALID,
    input wire                M_AXI_AWREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output wire                 M_AXI_WLAST,
    output wire                 M_AXI_WVALID,
    input wire                M_AXI_WREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    input wire [1 : 0]            M_AXI_BRESP,
    input wire                 M_AXI_BVALID,
    output wire                 M_AXI_BREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [7 : 0]            M_AXI_ARLEN,
    output wire [2 : 0]            M_AXI_ARSIZE,
    output wire [1 : 0]            M_AXI_ARBURST,
    output wire                 M_AXI_ARLOCK,
    output wire [3 : 0]            M_AXI_ARCACHE,
    output wire [2 : 0]            M_AXI_ARPROT,
    output wire [3 : 0]            M_AXI_ARQOS,
    output wire                 M_AXI_ARVALID,
    input wire                M_AXI_ARREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0]            M_AXI_RRESP,
    input wire                 M_AXI_RLAST,
    input wire                 M_AXI_RVALID,
    output wire                 M_AXI_RREADY
);

    wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid_reg, m_axi_awid_reg;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr_reg, m_axi_awaddr_reg;
    wire [7 : 0] s_axi_awlen_reg, m_axi_awlen_reg;
    wire [2 : 0] s_axi_awsize_reg, m_axi_awsize_reg;
    wire [1 : 0] s_axi_awburst_reg, m_axi_awburst_reg;
    wire s_axi_awlock_reg, m_axi_awlock_reg;
    wire [3 : 0] s_axi_awcache_reg, m_axi_awcache_reg;
    wire [2 : 0] s_axi_awprot_reg, m_axi_awprot_reg;
    wire [3 : 0] s_axi_awqos_reg, m_axi_awqos_reg;
    wire s_axi_awvalid_reg, m_axi_awvalid_reg;
    wire s_axi_awready_reg, m_axi_awready_reg;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_reg, m_axi_wdata_reg;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_reg, m_axi_wstrb_reg;
    wire s_axi_wlast_reg, m_axi_wlast_reg;
    wire s_axi_wvalid_reg, m_axi_wvalid_reg;
    wire s_axi_wready_reg, m_axi_wready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid_reg, m_axi_bid_reg;
    wire [1 : 0] s_axi_bresp_reg, m_axi_bresp_reg;
    wire s_axi_bvalid_reg, m_axi_bvalid_reg;
    wire s_axi_bready_reg, m_axi_bready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_arid_reg, m_axi_arid_reg;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr_reg, m_axi_araddr_reg;
    wire [7 : 0] s_axi_arlen_reg, m_axi_arlen_reg;
    wire [2 : 0] s_axi_arsize_reg, m_axi_arsize_reg;
    wire [1 : 0] s_axi_arburst_reg, m_axi_arburst_reg;
    wire s_axi_arlock_reg, m_axi_arlock_reg;
    wire [3 : 0] s_axi_arcache_reg, m_axi_arcache_reg;
    wire [2 : 0] s_axi_arprot_reg, m_axi_arprot_reg;
    wire [3 : 0] s_axi_arqos_reg, m_axi_arqos_reg;
    wire s_axi_arvalid_reg, m_axi_arvalid_reg;
    wire s_axi_arready_reg, m_axi_arready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid_reg, m_axi_rid_reg;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_reg, m_axi_rdata_reg;
    wire [1 : 0] s_axi_rresp_reg, m_axi_rresp_reg;
    wire s_axi_rlast_reg, m_axi_rlast_reg;
    wire s_axi_rvalid_reg, m_axi_rvalid_reg;
    wire s_axi_rready_reg, m_axi_rready_reg;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_axi_awid_reg <= 0;
            s_axi_awaddr_reg <= 0;
            s_axi_awlen_reg <= 0;
            s_axi_awsize_reg <= 0;
            s_axi_awburst_reg <= 0;
            s_axi_awlock_reg <= 0;
            s_axi_awcache_reg <= 0;
            s_axi_awprot_reg <= 0;
            s_axi_awqos_reg <= 0;
            s_axi_awvalid_reg <= 0;
            s_axi_wdata_reg <= 0;
            s_axi_wstrb_reg <= 0;
            s_axi_wlast_reg <= 0;
            s_axi_wvalid_reg <= 0;
            s_axi_bid_reg <= 0;
            s_axi_bresp_reg <= 0;
            s_axi_bvalid_reg <= 0;
            s_axi_arid_reg <= 0;
            s_axi_araddr_reg <= 0;
            s_axi_arlen_reg <= 0;
            s_axi_arsize_reg <= 0;
            s_axi_arburst_reg <= 0;
            s_axi_arlock_reg <= 0;
            s_axi_arcache_reg <= 0;
            s_axi_arprot_reg <= 0;
            s_axi_arqos_reg <= 0;
            s_axi_arvalid_reg <= 0;
            s_axi_rid_reg <= 0;
            s_axi_rdata_reg <= 0;
            s_axi_rresp_reg <= 0;
            s_axi_rlast_reg <= 0;
            s_axi_rvalid_reg <= 0;
        end else begin
            s_axi_awid_reg <= S_AXI_AWID;
            s_axi_awaddr_reg <= S_AXI_AWADDR;
            s_axi_awlen_reg <= S_AXI_AWLEN;
            s_axi_awsize_reg <= S_AXI_AWSIZE;
            s_axi_awburst_reg <= S_AXI_AWBURST;
            s_axi_awlock_reg <= S_AXI_AWLOCK;
            s_axi_awcache_reg <= S_AXI_AWCACHE;
            s_axi_awprot_reg <= S_AXI_AWPROT;
            s_axi_awqos_reg <= S_AXI_AWQOS;
            s_axi_awvalid_reg <= S_AXI_AWVALID;
            s_axi_wdata_reg <= S_AXI_WDATA;
            s_axi_wstrb_reg <= S_AXI_WSTRB;
            s_axi_wlast_reg <= S_AXI_WLAST;
            s_axi_wvalid_reg <= S_AXI_WVALID;
            s_axi_bid_reg <= M_AXI_BID;
            s_axi_bresp_reg <= M_AXI_BRESP;
            s_axi_bvalid_reg <= M_AXI_BVALID;
            s_axi_arid_reg <= S_AXI_ARID;
            s_axi_araddr_reg <= S_AXI_ARADDR;
            s_axi_arlen_reg <= S_AXI_ARLEN;
            s_axi_arsize_reg <= S_AXI_ARSIZE;
            s_axi_arburst_reg <= S_AXI_ARBURST;
            s_axi_arlock_reg <= S_AXI_ARLOCK;
            s_axi_arcache_reg <= S_AXI_ARCACHE;
            s_axi_arprot_reg <= S_AXI_ARPROT;
            s_axi_arqos_reg <= S_AXI_ARQOS;
            s_axi_arvalid_reg <= S_AXI_ARVALID;
            s_axi_rid_reg <= M_AXI_RID;
            s_axi_rdata_reg <= M_AXI_RDATA;
            s_axi_rresp_reg <= M_AXI_RRESP;
            s_axi_rlast_reg <= M_AXI_RLAST;
            s_axi_rvalid_reg <= M_AXI_RVALID;
        end
    end

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_axi_awid_reg <= 0;
            m_axi_awaddr_reg <= 0;
            m_axi_awlen_reg <= 0;
            m_axi_awsize_reg <= 0;
            m_axi_awburst_reg <= 0;
            m_axi_awlock_reg <= 0;
            m_axi_awcache_reg <= 0;
            m_axi_awprot_reg <= 0;
            m_axi_awqos_reg <= 0;
            m_axi_awvalid_reg <= 0;
            m_axi_wdata_reg <= 0;
            m_axi_wstrb_reg <= 0;
            m_axi_wlast_reg <= 0;
            m_axi_wvalid_reg <= 0;
            m_axi_bid_reg <= 0;
            m_axi_bresp_reg <= 0;
            m_axi_bvalid_reg <= 0;
            m_axi_arid_reg <= 0;
            m_axi_araddr_reg <= 0;
            m_axi_arlen_reg <= 0;
            m_axi_arsize_reg <= 0;
            m_axi_arburst_reg <= 0;
            m_axi_arlock_reg <= 0;
            m_axi_arcache_reg <= 0;
            m_axi_arprot_reg <= 0;
            m_axi_arqos_reg <= 0;
            m_axi_arvalid_reg <= 0;
            m_axi_rid_reg <= 0;
            m_axi_rdata_reg <= 0;
            m_axi_rresp_reg <= 0;
            m_axi_rlast_reg <= 0;
            m_axi_rvalid_reg <= 0;
        end else begin
            m_axi_awid_reg <= s_axi_awid_reg;
            m_axi_awaddr_reg <= s_axi_awaddr_reg;
            m_axi_awlen_reg <= s_axi_awlen_reg;
            m_axi_awsize_reg <= s_axi_awsize_reg;
            m_axi_awburst_reg <= s_axi_awburst_reg;
            m_axi_awlock_reg <= s_axi_awlock_reg;
            m_axi_awcache_reg <= s_axi_awcache_reg;
            m_axi_awprot_reg <= s_axi_awprot_reg;
            m_axi_awqos_reg <= s_axi_awqos_reg;
            m_axi_awvalid_reg <= s_axi_awvalid_reg;
            m_axi_wdata_reg <= s_axi_wdata_reg;
            m_axi_wstrb_reg <= s_axi_wstrb_reg;
            m_axi_wlast_reg <= s_axi_wlast_reg;
            m_axi_wvalid_reg <= s_axi_wvalid_reg;
            m_axi_bid_reg <= s_axi_bid_reg;
            m_axi_bresp_reg <= s_axi_bresp_reg;
            m_axi_bvalid_reg <= s_axi_bvalid_reg;
            m_axi_arid_reg <= s_axi_arid_reg;
            m_axi_araddr_reg <= s_axi_araddr_reg;
            m_axi_arlen_reg <= s_axi_arlen_reg;
            m_axi_arsize_reg <= s_axi_arsize_reg;
            m_axi_arburst_reg <= s_axi_arburst_reg;
            m_axi_arlock_reg <= s_axi_arlock_reg;
            m_axi_arcache_reg <= s_axi_arcache_reg;
            m_axi_arprot_reg <= s_axi_arprot_reg;
            m_axi_arqos_reg <= s_axi_arqos_reg;
            m_axi_arvalid_reg <= s_axi_arvalid_reg;
            m_axi_rid_reg <= s_axi_rid_reg;
            m_axi_rdata_reg <= s_axi_rdata_reg;
            m_axi_rresp_reg <= s_axi_rresp_reg;
            m_axi_rlast_reg <= s_axi_rlast_reg;
            m_axi_rvalid_reg <= s_axi_rvalid_reg;
        end
    end

    assign S_AXI_AWREADY = m_axi_awready_reg;
    assign S_AXI_WREADY = m_axi_wready_reg;
    assign S_AXI_BID = s_axi_bid_reg;
    assign S_AXI_BRESP = s_axi_bresp_reg;
    assign S_AXI_BVALID = s_axi_bvalid_reg;
    assign S_AXI_ARREADY = m_axi_arready_reg;
    assign S_AXI_RID = s_axi_rid_reg;
    assign S_AXI_RDATA = s_axi_rdata_reg;
    assign S_AXI_RRESP = s_axi_rresp_reg;
    assign S_AXI_RLAST = s_axi_rlast_reg;
    assign S_AXI_RVALID = s_axi_rvalid_reg;

    assign M_AXI_ARESETN = S_AXI_ARESETN;
    assign M_AXI_AWID = s_axi_awid_reg;
    assign M_AXI_AWADDR = s_axi_awaddr_reg;
    assign M_AXI_AWLEN = s_axi_awlen_reg;
    assign M_AXI_AWSIZE = s_axi_awsize_reg;
    assign M_AXI_AWBURST = s_axi_awburst_reg;
    assign M_AXI_AWLOCK = s_axi_awlock_reg;
    assign M_AXI_AWCACHE = s_axi_awcache_reg;
    assign M_AXI_AWPROT = s_axi_awprot_reg;
    assign M_AXI_AWQOS = s_axi_awqos_reg;
    assign M_AXI_AWVALID = s_axi_awvalid_reg;
    assign M_AXI_WDATA = s_axi_wdata_reg;
    assign M_AXI_WSTRB = s_axi_wstrb_reg;
    assign M_AXI_WLAST = s_axi_wlast_reg;
    assign M_AXI_WVALID = s_axi_wvalid_reg;
    assign M_AXI_BREADY = s_axi_bready_reg;
    assign M_AXI_ARID = s_axi_arid_reg;
    assign M_AXI_ARADDR = s_axi_araddr_reg;
    assign M_AXI_ARLEN = s_axi_arlen_reg;
    assign M_AXI_ARSIZE = s_axi_arsize_reg;
    assign M_AXI_ARBURST = s_axi_arburst_reg;
    assign M_AXI_ARLOCK = s_axi_arlock_reg;
    assign M_AXI_ARCACHE = s_axi_arcache_reg;
    assign M_AXI_ARPROT = s_axi_arprot_reg;
    assign M_AXI_ARQOS = s_axi_arqos_reg;
    assign M_AXI_ARVALID = s_axi_arvalid_reg;
    assign M_AXI_RREADY = s_axi_rready_reg;

endmodule
