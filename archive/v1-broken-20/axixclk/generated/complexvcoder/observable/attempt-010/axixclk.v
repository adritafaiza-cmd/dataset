`timescale 1ns / 1ps

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

	// Internal signals for S_AXI
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr_reg;
	wire [7 : 0] s_axi_awlen_reg;
	wire [2 : 0] s_axi_awsize_reg;
	wire [1 : 0] s_axi_awburst_reg;
	wire s_axi_awlock_reg;
	wire [3 : 0] s_axi_awcache_reg;
	wire [2 : 0] s_axi_awprot_reg;
	wire [3 : 0] s_axi_awqos_reg;
	wire s_axi_awvalid_reg;
	wire s_axi_wvalid_reg;
	wire s_axi_wlast_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_reg;
	wire s_axi_arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr_reg;
	wire [7 : 0] s_axi_arlen_reg;
	wire [2 : 0] s_axi_arsize_reg;
	wire [1 : 0] s_axi_arburst_reg;
	wire s_axi_arlock_reg;
	wire [3 : 0] s_axi_arcache_reg;
	wire [2 : 0] s_axi_arprot_reg;
	wire [3 : 0] s_axi_arqos_reg;
	wire s_axi_arvalid_reg;

	// Internal signals for M_AXI
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
	wire m_axi_wvalid_reg;
	wire m_axi_wlast_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_reg;
	wire m_axi_arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr_reg;
	wire [7 : 0] m_axi_arlen_reg;
	wire [2 : 0] m_axi_arsize_reg;
	wire [1 : 0] m_axi_arburst_reg;
	wire m_axi_arlock_reg;
	wire [3 : 0] m_axi_arcache_reg;
	wire [2 : 0] m_axi_arprot_reg;
	wire [3 : 0] m_axi_arqos_reg;
	wire m_axi_arvalid_reg;

	// AXI crossbar for S_AXI to M_AXI
	assign M_AXI_ACLK = S_AXI_ACLK;
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

	assign s_axi_awready = M_AXI_AWREADY;

	assign M_AXI_WDATA = s_axi_wdata_reg;
	assign M_AXI_WSTRB = s_axi_wstrb_reg;
	assign M_AXI_WLAST = s_axi_wlast_reg;
	assign M_AXI_WVALID = s_axi_wvalid_reg;

	assign s_axi_wready = M_AXI_WREADY;

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

	assign s_axi_arready = M_AXI_ARREADY;

	// AXI crossbar for M_AXI to S_AXI
	assign S_AXI_ACLK = M_AXI_ACLK;
	assign S_AXI_ARESETN = M_AXI_ARESETN;

	assign S_AXI_AWID = m_axi_awid_reg;
	assign S_AXI_AWADDR = m_axi_awaddr_reg;
	assign S_AXI_AWLEN = m_axi_awlen_reg;
	assign S_AXI_AWSIZE = m_axi_awsize_reg;
	assign S_AXI_AWBURST = m_axi_awburst_reg;
	assign S_AXI_AWLOCK = m_axi_awlock_reg;
	assign S_AXI_AWCACHE = m_axi_awcache_reg;
	assign S_AXI_AWPROT = m_axi_awprot_reg;
	assign S_AXI_AWQOS = m_axi_awqos_reg;
	assign S_AXI_AWVALID = m_axi_awvalid_reg;

	assign m_axi_awready = S_AXI_AWREADY;

	assign S_AXI_WDATA = m_axi_wdata_reg;
	assign S_AXI_WSTRB = m_axi_wstrb_reg;
	assign S_AXI_WLAST = m_axi_wlast_reg;
	assign S_AXI_WVALID = m_axi_wvalid_reg;

	assign m_axi_wready = S_AXI_WREADY;

	assign S_AXI_ARID = m_axi_arid_reg;
	assign S_AXI_ARADDR = m_axi_araddr_reg;
	assign S_AXI_ARLEN = m_axi_arlen_reg;
	assign S_AXI_ARSIZE = m_axi_arsize_reg;
	assign S_AXI_ARBURST = m_axi_arburst_reg;
	assign S_AXI_ARLOCK = m_axi_arlock_reg;
	assign S_AXI_ARCACHE = m_axi_arcache_reg;
	assign S_AXI_ARPROT = m_axi_arprot_reg;
	assign S_AXI_ARQOS = m_axi_arqos_reg;
	assign S_AXI_ARVALID = m_axi_arvalid_reg;

	assign m_axi_arready = S_AXI_ARREADY;

endmodule
