module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] axi_awid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr_reg;
	wire [7 : 0] axi_awlen_reg;
	wire [2 : 0] axi_awsize_reg;
	wire [1 : 0] axi_awburst_reg;
	wire axi_awlock_reg;
	wire [3 : 0] axi_awcache_reg;
	wire [2 : 0] axi_awprot_reg;
	wire [3 : 0] axi_awqos_reg;
	wire axi_awvalid_reg;
	wire axi_awready_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb_reg;
	wire axi_wlast_reg;
	wire axi_wvalid_reg;
	wire axi_wready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] axi_bid_reg;
	wire [1 : 0] axi_bresp_reg;
	wire axi_bvalid_reg;
	wire axi_bready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] axi_arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr_reg;
	wire [7 : 0] axi_arlen_reg;
	wire [2 : 0] axi_arsize_reg;
	wire [1 : 0] axi_arburst_reg;
	wire axi_arlock_reg;
	wire [3 : 0] axi_arcache_reg;
	wire [2 : 0] axi_arprot_reg;
	wire [3 : 0] axi_arqos_reg;
	wire axi_arvalid_reg;
	wire axi_arready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] axi_rid_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata_reg;
	wire [1 : 0] axi_rresp_reg;
	wire axi_rlast_reg;
	wire axi_rvalid_reg;
	wire axi_rready_reg;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_awid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr_reg;
	wire [7 : 0] m_axi_awlen_reg;
	wire [2 : 0] m_axi_awsize_reg;
	wire [1 : 0] m_axi_awburst_reg;
	wire m_axi_awlock_reg;
	wire [3 : 0] m_axi_awcache_reg;
	wire [2 : 0] m_axi_awprot_reg;
	wire [3 : 0] m_axi_awqos_reg;
	wire m_axi_awvalid_reg;
	wire m_axi_awready_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_reg;
	wire m_axi_wlast_reg;
	wire m_axi_wvalid_reg;
	wire m_axi_wready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_bid_reg;
	wire [1 : 0] m_axi_bresp_reg;
	wire m_axi_bvalid_reg;
	wire m_axi_bready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr_reg;
	wire [7 : 0] m_axi_arlen_reg;
	wire [2 : 0] m_axi_arsize_reg;
	wire [1 : 0] m_axi_arburst_reg;
	wire m_axi_arlock_reg;
	wire [3 : 0] m_axi_arcache_reg;
	wire [2 : 0] m_axi_arprot_reg;
	wire [3 : 0] m_axi_arqos_reg;
	wire m_axi_arvalid_reg;
	wire m_axi_arready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_rid_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_reg;
	wire [1 : 0] m_axi_rresp_reg;
	wire m_axi_rlast_reg;
	wire m_axi_rvalid_reg;
	wire m_axi_rready_reg;

	// Reset logic
	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Forwarding logic
	assign S_AXI_AWREADY = m_axi_awready_reg;
	assign S_AXI_WREADY = m_axi_wready_reg;
	assign S_AXI_BID = m_axi_bid_reg;
	assign S_AXI_BRESP = m_axi_bresp_reg;
	assign S_AXI_BVALID = m_axi_bvalid_reg;
	assign S_AXI_ARREADY = m_axi_arready_reg;
	assign S_AXI_RID = m_axi_rid_reg;
	assign S_AXI_RDATA = m_axi_rdata_reg;
	assign S_AXI_RRESP = m_axi_rresp_reg;
	assign S_AXI_RLAST = m_axi_rlast_reg;
	assign S_AXI_RVALID = m_axi_rvalid_reg;

	assign m_axi_awid_reg = S_AXI_AWID;
	assign m_axi_awaddr_reg = S_AXI_AWADDR;
	assign m_axi_awlen_reg = S_AXI_AWLEN;
	assign m_axi_awsize_reg = S_AXI_AWSIZE;
	assign m_axi_awburst_reg = S_AXI_AWBURST;
	assign m_axi_awlock_reg = S_AXI_AWLOCK;
	assign m_axi_awcache_reg = S_AXI_AWCACHE;
	assign m_axi_awprot_reg = S_AXI_AWPROT;
	assign m_axi_awqos_reg = S_AXI_AWQOS;
	assign m_axi_awvalid_reg = S_AXI_AWVALID;

	assign m_axi_wdata_reg = S_AXI_WDATA;
	assign m_axi_wstrb_reg = S_AXI_WSTRB;
	assign m_axi_wlast_reg = S_AXI_WLAST;
	assign m_axi_wvalid_reg = S_AXI_WVALID;

	assign m_axi_arid_reg = S_AXI_ARID;
	assign m_axi_araddr_reg = S_AXI_ARADDR;
	assign m_axi_arlen_reg = S_AXI_ARLEN;
	assign m_axi_arsize_reg = S_AXI_ARSIZE;
	assign m_axi_arburst_reg = S_AXI_ARBURST;
	assign m_axi_arlock_reg = S_AXI_ARLOCK;
	assign m_axi_arcache_reg = S_AXI_ARCACHE;
	assign m_axi_arprot_reg = S_AXI_ARPROT;
	assign m_axi_arqos_reg = S_AXI_ARQOS;
	assign m_axi_arvalid_reg = S_AXI_ARVALID;

	assign S_AXI_BREADY = m_axi_bready_reg;
	assign S_AXI_RREADY = m_axi_rready_reg;

endmodule
