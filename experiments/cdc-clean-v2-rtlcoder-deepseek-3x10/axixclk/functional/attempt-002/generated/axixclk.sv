```
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

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_reg;
	reg [7 : 0] s_awlen_reg;
	reg [2 : 0] s_awsize_reg;
	reg [1 : 0] s_awburst_reg;
	reg s_awlock_reg;
	reg [3 : 0] s_awcache_reg;
	reg [2 : 0] s_awprot_reg;
	reg [3 : 0] s_awqos_reg;
	reg s_awvalid_reg;
	reg s_awready_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_reg;
	reg s_wlast_reg;
	reg s_wvalid_reg;
	reg s_wready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_reg;
	reg [1 : 0] s_bresp_reg;
	reg s_bvalid_reg;
	reg s_bready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_reg;
	reg [7 : 0] s_arlen_reg;
	reg [2 : 0] s_arsize_reg;
	reg [1 : 0] s_arburst_reg;
	reg s_arlock_reg;
	reg [3 : 0] s_arcache_reg;
	reg [2 : 0] s_arprot_reg;
	reg [3 : 0] s_arqos_reg;
	reg s_arvalid_reg;
	reg s_arready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_reg;
	reg [1 : 0] s_rresp_reg;
	reg s_rlast_reg;
	reg s_rvalid_reg;
	reg s_rready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0] m_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_reg;
	reg [7 : 0] m_awlen_reg;
	reg [2 : 0] m_awsize_reg;
	reg [1 : 0] m_awburst_reg;
	reg m_awlock_reg;
	reg [3 : 0] m_awcache_reg;
	reg [2 : 0] m_awprot_reg;
	reg [3 : 0] m_awqos_reg;
	reg m_awvalid_reg;
	reg m_awready_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_wvalid_reg;
	reg m_wready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_bid_reg;
	reg [1 : 0] m_bresp_reg;
	reg m_bvalid_reg;
	reg m_bready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr_reg;
	reg [7 : 0] m_arlen_reg;
	reg [2 : 0] m_arsize_reg;
	reg [1 : 0] m_arburst_reg;
	reg m_arlock_reg;
	reg [3 : 0] m_arcache_reg;
	reg [2 : 0] m_arprot_reg;
	reg [3 : 0] m_arqos_reg;
	reg m_arvalid_reg;
	reg m_arready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata_reg;
	reg [1 : 0] m_rresp_reg;
	reg m_rlast_reg;
	reg m_rvalid_reg;
	reg m_rready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_next;
	reg [7 : 0] s_awlen_next;
	reg [2 : 0] s_awsize_next;
	reg [1 : 0] s_awburst_next;
	reg s_awlock_next;
	reg [3 : 0] s_awcache_next;
	reg [2 : 0] s_awprot_next;
	reg [3 : 0] s_awqos_next;
	reg s_awvalid_next;
	reg s_awready_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_next;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_next;
	reg s_wlast_next;
	reg s_wvalid_next;
	reg s_wready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_next;
	reg [1 : 0] s_bresp_next;
	reg s_bvalid_next;
	reg s_bready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_next;
	reg [7 : 0] s_arlen_next;
	reg [2 : 0] s_arsize_next;
	reg [1 : 0] s_arburst_next;
	reg s_arlock_next;
	reg [3 : 0] s_arcache_next;
	reg [2 : 0] s_arprot_next;
	reg [3 : 0] s_arqos_next;
	reg s_arvalid_next;
	reg s_arready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_next;
	reg [1 : 0] s_rresp_next;
	reg s_rlast_next;
	reg s_rvalid_next;
	reg s_rready_next;

	reg [C_S_AXI_ID_WIDTH-1 : 0] m_awid_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_next;
	reg [7 : 0] m_awlen_next;
	reg [2 : 0] m_awsize_next;
	reg [1 : 0] m_awburst_next;
	reg m_awlock_next;
	reg [3 : 0] m_awcache_next;
	reg [2 : 0] m_awprot_next;
	reg [3 : 0] m_awqos_next;
	reg m_awvalid_next;
	reg m_awready_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_next;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_next;
	reg m_wlast_next;
	reg m_wvalid_next;
	reg m_wready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_bid_next;
	reg [1 : 0] m_bresp_next;
	reg m_bvalid_next;
	reg m_bready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_arid_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr_next;
	reg [7 : 0] m_arlen_next;
	reg [2 : 0] m_arsize_next;
	reg [1 : 0] m_arburst_next;
	reg m_arlock_next;
	reg [3 : 0] m_arcache_next;
	reg [2 : 0] m_arprot_next;
	reg [3 : 0] m_arqos_next;
	reg m_arvalid_next;
	reg m_arready_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_rid_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata_next;
	reg [1 : 0] m_rresp_next;
	reg m_rlast_next;
	reg m_rvalid_next;
	reg m_rready_next;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_ff;
	reg [7 : 0] s_awlen_ff;
	reg [2 : 0] s_awsize_ff;
	reg [1 : 0] s_awburst_ff;
	reg s_awlock_ff;
	reg [3 : 0] s_awcache_ff;
	reg [2 : 0] s_awprot_ff;
	reg [3 : 0] s_awqos_ff;
	reg s_awvalid_ff;
	reg s_awready_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_ff;
	reg s_wlast_ff;
	reg s_wvalid_ff;
	reg s_wready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_ff;
	reg [1 : 0] s_bresp_ff;
	reg s_bvalid_ff;
	reg s_bready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_ff;
	reg [7 : 0] s_arlen_ff;
	reg [2 : 0] s_arsize_ff;
	reg [1 : 0] s_arburst_ff;
	reg s_arlock_ff;
	reg [3 : 0] s_arcache_ff;
	reg [2 : 0] s_arprot_ff;
	reg [3 : 0] s_arqos_ff;
	reg s_arvalid_ff;
	reg s_arready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_ff;
	reg [1 : 0] s_rresp_ff;
	reg s_rlast_ff;
	reg s_rvalid_ff;
	reg s_rready_ff;

	reg [C_S_AXI_ID_WIDTH-1 : 0] m_awid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_ff;
	reg [7 : 0] m_awlen_ff;
	reg [2 : 0] m_awsize_ff;
	reg [1 : 0] m_awburst_ff;
	reg m_awlock_ff;
	reg [3 : 0] m_awcache_ff;
	reg [2 : 0] m_awprot_ff;
	reg [3 : 0] m_awqos_ff;
	reg m_awvalid_ff;
	reg m_awready_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_ff;
	reg m_wlast_ff;
	reg m_wvalid_ff;
	reg m_wready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_bid_ff;
	reg [1 : 0] m_bresp_ff;
	reg m_bvalid_ff;
	reg m_bready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_arid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr_ff;
	reg [7 : 0] m_arlen_ff;
	reg [2 : 0] m_arsize_ff;
	reg [1 : 0] m_arburst_ff;
	reg m_arlock_ff;
	reg [3 : 0] m_arcache_ff;
	reg [2 : 0] m_arprot_ff;
	reg [3 : 0] m_arqos_ff;
	reg m_arvalid_ff;
	reg m_arready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_rid_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata_ff;
	reg [1 : 0] m_rresp_ff;
	reg m_rlast_ff;
	reg m_rvalid_ff;
	reg m_rready_ff;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_ff_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_ff_next;
	reg [7 : 0] s_awlen_ff_next;
	reg [2 : 0] s_awsize_ff_next;
	reg [1 : 0] s_awburst_ff_next;
	reg s_awlock_ff_next;
	reg [3 : 0] s_awcache_ff_next;
	reg [2 : 0] s_awprot_ff_next;
	reg [3 : 0] s_awqos_ff_next;
	reg s_awvalid_ff_next;
	reg s_awready_ff_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_ff_next;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_ff_next;
	reg s_wlast_ff_next;
	reg s_wvalid_ff_next;
	reg s_wready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_ff_next;
	reg [1 : 0] s_bresp_ff_next;
	reg s_bvalid_ff_next;
	reg s_bready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_ff_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_ff_next;
	reg [7 : 0] s_arlen_ff_next;
	reg [2 : 0] s_arsize_ff_next;
	reg [1 : 0] s_arburst_ff_next;
	reg s_arlock_ff_next;
	reg [3 : 0] s_arcache_ff_next;
	reg [2 : 0] s_arprot_ff_next;
	reg [3 : 0] s_arqos_ff_next;
	reg s_arvalid_ff_next;
	reg s_arready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_ff_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_ff_next;
	reg [1 : 0] s_rresp_ff_next;
	reg s_rlast_ff_next;
	reg s_rvalid_ff_next;
	reg s_rready_ff_next;

	reg [C_S_AXI_ID_WIDTH-1 : 0] m_awid_ff_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_ff_next;
	reg [7 : 0] m_awlen_ff_next;
	reg [2 : 0] m_awsize_ff_next;
	reg [1 : 0] m_awburst_ff_next;
	reg m_awlock_ff_next;
	reg [3 : 0] m_awcache_ff_next;
	reg [2 : 0] m_awprot_ff_next;
	reg [3 : 0] m_awqos_ff_next;
	reg m_awvalid_ff_next;
	reg m_awready_ff_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_ff_next;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_ff_next;
	reg m_wlast_ff_next;
	reg m_wvalid_ff_next;
	reg m_wready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_bid_ff_next;
	reg [1 : 0] m_bresp_ff_next;
	reg m_bvalid_ff_next;
	reg m_bready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_arid_ff_next;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr_ff_next;
	reg [7 : 0] m_arlen_ff_next;
	reg [2 : 0] m_arsize_ff_next;
	reg [1 : 0] m_arburst_ff_next;
	reg m_arlock_ff_next;
	reg [3 : 0] m_arcache_ff_next;
	reg [2 : 0] m_arprot_ff_next;
	reg [3 : 0] m_arqos_ff_next;
	reg m_arvalid_ff_next;
	reg m_arready_ff_next;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_rid_ff_next;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata_ff_next;
	reg [1 : 0] m_rresp_ff_next;
	reg m_rlast_ff_next;
	reg m_rvalid_ff_next;
	reg m_rready_ff_next;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_ff_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_ff_ff;
	reg [7 : 0] s_awlen_ff_ff;
	reg [2 : 0] s_awsize_ff_ff;
	reg [1 : 0] s_awburst_ff_ff;
	reg s_awlock_ff_ff;
	reg [3 : 0] s_awcache_ff_ff;
	reg [2 : 0] s_awprot_ff_ff;
	reg [3 : 0] s_awqos_ff_ff;
	reg s_awvalid_ff_ff;
	reg s_awready_ff_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_ff_ff;
	reg s_wlast_ff_ff;
	reg s_wvalid_ff_ff;
	reg s_wready_ff_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_ff_ff;
	reg [1 : 0] s_bresp_ff_ff;
	reg s_bvalid_ff_ff;
	reg s_bready_ff_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_ff_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_ff_ff;
	reg [7 : 0] s_arlen_ff_ff;
	reg [2 : 0] s_arsize_ff_ff;
	reg [1 : 0] s_arburst_ff_ff;
	reg s_arlock_ff_ff;
	reg [3 : 0] s_arcache_ff_ff;
	reg [2 : 0] s_arprot_ff_ff;
	reg [3 : 0] s_arqos_ff_ff;
	reg s_arvalid_ff_ff;
	reg s_arready_ff_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_ff_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_ff_ff;
	reg [1 : 0] s_rresp_ff_ff;
	reg s_rlast_ff_ff;
	reg s_rvalid_ff_ff;
	reg s_rready_ff_ff;

	reg [C_S_AXI_ID_WIDTH-1 : 0] m_awid_ff_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_ff_ff;
	reg [7 : 0] m_awlen_ff_ff;
	reg [2 : 0] m_awsize_ff_ff;
	reg [1 : 0] m_awburst_ff_ff;
	reg m_awlock_ff_ff;
	reg [3 : 0] m_awcache_ff_ff;
	reg [2 : 0] m_awprot_ff_ff;
	reg [3 : 0] m_awqos_ff_ff;
	reg m_awvalid_ff_ff;
	reg m_awready_ff_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_ff_ff;
	reg m_wlast_ff_ff;
	reg m_wvalid_ff_ff;
	reg m_wready_ff_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_bid_ff_ff;
	reg [1 : 0] m_bresp_ff_ff;
	reg m_bvalid_ff_ff;
	reg m_bready_ff_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_arid_ff_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]