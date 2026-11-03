The Verilog-2001 code for the AXI4 clock-domain bridge is as follows:

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

	// Internal signals
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr_int;
	reg [7 : 0] s_axi_awlen_int;
	reg [2 : 0] s_axi_awsize_int;
	reg [1 : 0] s_axi_awburst_int;
	reg s_axi_awlock_int;
	reg [3 : 0] s_axi_awcache_int;
	reg [2 : 0] s_axi_awprot_int;
	reg [3 : 0] s_axi_awqos_int;
	reg s_axi_awvalid_int;
	wire s_axi_awready_int;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int;
	reg s_axi_wlast_int;
	reg s_axi_wvalid_int;
	wire s_axi_wready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid_int;
	wire [1 : 0] s_axi_bresp_int;
	wire s_axi_bvalid_int;
	reg s_axi_bready_int;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_arid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr_int;
	reg [7 : 0] s_axi_arlen_int;
	reg [2 : 0] s_axi_arsize_int;
	reg [1 : 0] s_axi_arburst_int;
	reg s_axi_arlock_int;
	reg [3 : 0] s_axi_arcache_int;
	reg [2 : 0] s_axi_arprot_int;
	reg [3 : 0] s_axi_arqos_int;
	reg s_axi_arvalid_int;
	wire s_axi_arready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int;
	wire [1 : 0] s_axi_rresp_int;
	wire s_axi_rlast_int;
	wire s_axi_rvalid_int;
	reg s_axi_rready_int;

	// Internal signals for M_AXI
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_awid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr_int;
	reg [7 : 0] m_axi_awlen_int;
	reg [2 : 0] m_axi_awsize_int;
	reg [1 : 0] m_axi_awburst_int;
	reg m_axi_awlock_int;
	reg [3 : 0] m_axi_awcache_int;
	reg [2 : 0] m_axi_awprot_int;
	reg [3 : 0] m_axi_awqos_int;
	reg m_axi_awvalid_int;
	wire m_axi_awready_int;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int;
	reg m_axi_wlast_int;
	reg m_axi_wvalid_int;
	wire m_axi_wready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_bid_int;
	wire [1 : 0] m_axi_bresp_int;
	wire m_axi_bvalid_int;
	reg m_axi_bready_int;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_arid_int;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr_int;
	reg [7 : 0] m_axi_arlen_int;
	reg [2 : 0] m_axi_arsize_int;
	reg [1 : 0] m_axi_arburst_int;
	reg m_axi_arlock_int;
	reg [3 : 0] m_axi_arcache_int;
	reg [2 : 0] m_axi_arprot_int;
	reg [3 : 0] m_axi_arqos_int;
	reg m_axi_arvalid_int;
	wire m_axi_arready_int;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_rid_int;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int;
	wire [1 : 0] m_axi_rresp_int;
	wire m_axi_rlast_int;
	wire m_axi_rvalid_int;
	reg m_axi_rready_int;

	// Internal signals for clock domain crossing
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr_ff;
	reg [7 : 0] s_axi_awlen_ff;
	reg [2 : 0] s_axi_awsize_ff;
	reg [1 : 0] s_axi_awburst_ff;
	reg s_axi_awlock_ff;
	reg [3 : 0] s_axi_awcache_ff;
	reg [2 : 0] s_axi_awprot_ff;
	reg [3 : 0] s_axi_awqos_ff;
	reg s_axi_awvalid_ff;
	reg s_axi_awready_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_ff;
	reg s_axi_wlast_ff;
	reg s_axi_wvalid_ff;
	reg s_axi_wready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid_ff;
	reg [1 : 0] s_axi_bresp_ff;
	reg s_axi_bvalid_ff;
	reg s_axi_bready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_arid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr_ff;
	reg [7 : 0] s_axi_arlen_ff;
	reg [2 : 0] s_axi_arsize_ff;
	reg [1 : 0] s_axi_arburst_ff;
	reg s_axi_arlock_ff;
	reg [3 : 0] s_axi_arcache_ff;
	reg [2 : 0] s_axi_arprot_ff;
	reg [3 : 0] s_axi_arqos_ff;
	reg s_axi_arvalid_ff;
	reg s_axi_arready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_ff;
	reg [1 : 0] s_axi_rresp_ff;
	reg s_axi_rlast_ff;
	reg s_axi_rvalid_ff;
	reg s_axi_rready_ff;

	// Internal signals for M_AXI clock domain crossing
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_awid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr_ff;
	reg [7 : 0] m_axi_awlen_ff;
	reg [2 : 0] m_axi_awsize_ff;
	reg [1 : 0] m_axi_awburst_ff;
	reg m_axi_awlock_ff;
	reg [3 : 0] m_axi_awcache_ff;
	reg [2 : 0] m_axi_awprot_ff;
	reg [3 : 0] m_axi_awqos_ff;
	reg m_axi_awvalid_ff;
	reg m_axi_awready_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_ff;
	reg m_axi_wlast_ff;
	reg m_axi_wvalid_ff;
	reg m_axi_wready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_bid_ff;
	reg [1 : 0] m_axi_bresp_ff;
	reg m_axi_bvalid_ff;
	reg m_axi_bready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_arid_ff;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr_ff;
	reg [7 : 0] m_axi_arlen_ff;
	reg [2 : 0] m_axi_arsize_ff;
	reg [1 : 0] m_axi_arburst_ff;
	reg m_axi_arlock_ff;
	reg [3 : 0] m_axi_arcache_ff;
	reg [2 : 0] m_axi_arprot_ff;
	reg [3 : 0] m_axi_arqos_ff;
	reg m_axi_arvalid_ff;
	reg m_axi_arready_ff;
	reg [C_S_AXI_ID_WIDTH-1 : 0] m_axi_rid_ff;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_ff;
	reg [1 : 0] m_axi_rresp_ff;
	reg m_axi_rlast_ff;
	reg m_axi_rvalid_ff;
	reg m_axi_rready_ff;

	// Internal signals for reset
	reg s_axi_aresetn_int;
	reg m_axi_aresetn_int;

	// Internal signals for stall
	reg s_axi_stall_int;
	reg m_axi_stall_int;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff;
	reg s_axi_wlast_int_ff;
	reg s_axi_wvalid_int_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff;
	reg [1 : 0] s_axi_rresp_int_ff;
	reg s_axi_rlast_int_ff;
	reg s_axi_rvalid_int_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff;
	reg m_axi_wlast_int_ff;
	reg m_axi_wvalid_int_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff;
	reg [1 : 0] m_axi_rresp_int_ff;
	reg m_axi_rlast_int_ff;
	reg m_axi_rvalid_int_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff;
	reg s_axi_wlast_int_ff_ff;
	reg s_axi_wvalid_int_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff;
	reg s_axi_rlast_int_ff_ff;
	reg s_axi_rvalid_int_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff_ff;
	reg m_axi_wlast_int_ff_ff;
	reg m_axi_wvalid_int_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff_ff;
	reg [1 : 0] m_axi_rresp_int_ff_ff;
	reg m_axi_rlast_int_ff_ff;
	reg m_axi_rvalid_int_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff_ff;
	reg s_axi_wlast_int_ff_ff_ff;
	reg s_axi_wvalid_int_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff_ff;
	reg s_axi_rlast_int_ff_ff_ff;
	reg s_axi_rvalid_int_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff_ff_ff;
	reg m_axi_wlast_int_ff_ff_ff;
	reg m_axi_wvalid_int_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff_ff_ff;
	reg [1 : 0] m_axi_rresp_int_ff_ff_ff;
	reg m_axi_rlast_int_ff_ff_ff;
	reg m_axi_rvalid_int_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff_ff_ff;
	reg s_axi_wlast_int_ff_ff_ff_ff;
	reg s_axi_wvalid_int_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff_ff_ff;
	reg s_axi_rlast_int_ff_ff_ff_ff;
	reg s_axi_rvalid_int_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff_ff_ff_ff;
	reg m_axi_wlast_int_ff_ff_ff_ff;
	reg m_axi_wvalid_int_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff_ff_ff_ff;
	reg [1 : 0] m_axi_rresp_int_ff_ff_ff_ff;
	reg m_axi_rlast_int_ff_ff_ff_ff;
	reg m_axi_rvalid_int_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff_ff_ff_ff;
	reg s_axi_wlast_int_ff_ff_ff_ff_ff;
	reg s_axi_wvalid_int_ff_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff_ff_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff_ff_ff_ff;
	reg s_axi_rlast_int_ff_ff_ff_ff_ff;
	reg s_axi_rvalid_int_ff_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff_ff_ff_ff_ff;
	reg m_axi_wlast_int_ff_ff_ff_ff_ff;
	reg m_axi_wvalid_int_ff_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff_ff_ff_ff_ff;
	reg [1 : 0] m_axi_rresp_int_ff_ff_ff_ff_ff;
	reg m_axi_rlast_int_ff_ff_ff_ff_ff;
	reg m_axi_rvalid_int_ff_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff_ff_ff_ff_ff;
	reg s_axi_wlast_int_ff_ff_ff_ff_ff_ff;
	reg s_axi_wvalid_int_ff_ff_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff_ff_ff_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff_ff_ff_ff_ff;
	reg s_axi_rlast_int_ff_ff_ff_ff_ff_ff;
	reg s_axi_rvalid_int_ff_ff_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_int_ff_ff_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_int_ff_ff_ff_ff_ff_ff;
	reg m_axi_wlast_int_ff_ff_ff_ff_ff_ff;
	reg m_axi_wvalid_int_ff_ff_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_rdata_int_ff_ff_ff_ff_ff_ff;
	reg [1 : 0] m_axi_rresp_int_ff_ff_ff_ff_ff_ff;
	reg m_axi_rlast_int_ff_ff_ff_ff_ff_ff;
	reg m_axi_rvalid_int_ff_ff_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata_int_ff_ff_ff_ff_ff_ff_ff;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb_int_ff_ff_ff_ff_ff_ff_ff;
	reg s_axi_wlast_int_ff_ff_ff_ff_ff_ff_ff;
	reg s_axi_wvalid_int_ff_ff_ff_ff_ff_ff_ff;

	// Internal signals for read data
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata_int_ff_ff_ff_ff_ff_ff_ff;
	reg [1 : 0] s_axi_rresp_int_ff_ff_ff_ff_ff_ff_ff;
	reg s_axi_rlast_int_ff_ff_ff_ff_ff_ff_ff;
	reg s_axi_rvalid_int_ff_ff_ff_ff_ff_ff_ff;

	// Internal signals for write data
	reg [C_S_AXI_