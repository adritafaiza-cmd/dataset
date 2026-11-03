```verilog
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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_ff;
	wire [7 : 0]			awlen_ff;
	wire [2 : 0]			awsize_ff;
	wire [1 : 0]			awburst_ff;
	wire				awlock_ff;
	wire [3 : 0]			awcache_ff;
	wire [2 : 0]			awprot_ff;
	wire [3 : 0]			awqos_ff;
	wire				awvalid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_ff;
	wire [7 : 0]			arlen_ff;
	wire [2 : 0]			arsize_ff;
	wire [1 : 0]			arburst_ff;
	wire				arlock_ff;
	wire [3 : 0]			arcache_ff;
	wire [2 : 0]			arprot_ff;
	wire [3 : 0]			arqos_ff;
	wire				arvalid_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;
	wire				rready_ff;

	wire				awready_sync;
	wire				wready_sync;
	wire				arready_sync;
	wire				rready_sync;

	wire				bready_sync;
	wire				bvalid_sync;
	wire				rvalid_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync;
	wire [1 : 0]			rresp_sync;
	wire				rlast_sync;

	wire				m_axi_aresetn_sync;

	wire				awvalid_sync;
	wire				wvalid_sync;
	wire				arvalid_sync;
	wire				m_axi_awready_sync;
	wire				m_axi_wready_sync;
	wire				m_axi_arready_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_awid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_awaddr_sync;
	wire [7 : 0]			m_axi_awlen_sync;
	wire [2 : 0]			m_axi_awsize_sync;
	wire [1 : 0]			m_axi_awburst_sync;
	wire				m_axi_awlock_sync;
	wire [3 : 0]			m_axi_awcache_sync;
	wire [2 : 0]			m_axi_awprot_sync;
	wire [3 : 0]			m_axi_awqos_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	m_axi_wstrb_sync;
	wire				m_axi_wlast_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_arid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_araddr_sync;
	wire [7 : 0]			m_axi_arlen_sync;
	wire [2 : 0]			m_axi_arsize_sync;
	wire [1 : 0]			m_axi_arburst_sync;
	wire				m_axi_arlock_sync;
	wire [3 : 0]			m_axi_arcache_sync;
	wire [2 : 0]			m_axi_arprot_sync;
	wire [3 : 0]			m_axi_arqos_sync;

	wire				m_axi_bready_sync;
	wire				m_axi_rready_sync;

	wire				m_axi_awvalid_sync;
	wire				m_axi_wvalid_sync;
	wire				m_axi_arvalid_sync;

	wire				m_axi_bvalid_sync;
	wire				m_axi_rvalid_sync;

	wire				m_axi_awready_sync_ff;
	wire				m_axi_wready_sync_ff;
	wire				m_axi_arready_sync_ff;

	wire				m_axi_bvalid_sync_ff;
	wire				m_axi_rvalid_sync_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff;
	wire [1 : 0]			m_axi_bresp_sync_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff;
	wire [1 : 0]			m_axi_rresp_sync_ff;
	wire				m_axi_rlast_sync_ff;

	wire				awready_sync_ff;
	wire				wready_sync_ff;
	wire				arready_sync_ff;
	wire				rready_sync_ff;

	wire				bready_sync_ff;
	wire				bvalid_sync_ff;
	wire				rvalid_sync_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff;
	wire [1 : 0]			bresp_sync_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff;
	wire [1 : 0]			rresp_sync_ff;
	wire				rlast_sync_ff;

	wire				m_axi_awvalid_sync_ff;
	wire				m_axi_wvalid_sync_ff;
	wire				m_axi_arvalid_sync_ff;

	wire				m_axi_bready_sync_ff;
	wire				m_axi_rready_sync_ff;

	wire				m_axi_awready_sync_ff2;
	wire				m_axi_wready_sync_ff2;
	wire				m_axi_arready_sync_ff2;

	wire				m_axi_bvalid_sync_ff2;
	wire				m_axi_rvalid_sync_ff2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff2;
	wire [1 : 0]			m_axi_bresp_sync_ff2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff2;
	wire [1 : 0]			m_axi_rresp_sync_ff2;
	wire				m_axi_rlast_sync_ff2;

	wire				awready_sync_ff2;
	wire				wready_sync_ff2;
	wire				arready_sync_ff2;
	wire				rready_sync_ff2;

	wire				bready_sync_ff2;
	wire				bvalid_sync_ff2;
	wire				rvalid_sync_ff2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff2;
	wire [1 : 0]			bresp_sync_ff2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff2;
	wire [1 : 0]			rresp_sync_ff2;
	wire				rlast_sync_ff2;

	wire				m_axi_awvalid_sync_ff2;
	wire				m_axi_wvalid_sync_ff2;
	wire				m_axi_arvalid_sync_ff2;

	wire				m_axi_bready_sync_ff2;
	wire				m_axi_rready_sync_ff2;

	wire				m_axi_awready_sync_ff3;
	wire				m_axi_wready_sync_ff3;
	wire				m_axi_arready_sync_ff3;

	wire				m_axi_bvalid_sync_ff3;
	wire				m_axi_rvalid_sync_ff3;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff3;
	wire [1 : 0]			m_axi_bresp_sync_ff3;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff3;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff3;
	wire [1 : 0]			m_axi_rresp_sync_ff3;
	wire				m_axi_rlast_sync_ff3;

	wire				awready_sync_ff3;
	wire				wready_sync_ff3;
	wire				arready_sync_ff3;
	wire				rready_sync_ff3;

	wire				bready_sync_ff3;
	wire				bvalid_sync_ff3;
	wire				rvalid_sync_ff3;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff3;
	wire [1 : 0]			bresp_sync_ff3;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff3;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff3;
	wire [1 : 0]			rresp_sync_ff3;
	wire				rlast_sync_ff3;

	wire				m_axi_awvalid_sync_ff3;
	wire				m_axi_wvalid_sync_ff3;
	wire				m_axi_arvalid_sync_ff3;

	wire				m_axi_bready_sync_ff3;
	wire				m_axi_rready_sync_ff3;

	wire				m_axi_awready_sync_ff4;
	wire				m_axi_wready_sync_ff4;
	wire				m_axi_arready_sync_ff4;

	wire				m_axi_bvalid_sync_ff4;
	wire				m_axi_rvalid_sync_ff4;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff4;
	wire [1 : 0]			m_axi_bresp_sync_ff4;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff4;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff4;
	wire [1 : 0]			m_axi_rresp_sync_ff4;
	wire				m_axi_rlast_sync_ff4;

	wire				awready_sync_ff4;
	wire				wready_sync_ff4;
	wire				arready_sync_ff4;
	wire				rready_sync_ff4;

	wire				bready_sync_ff4;
	wire				bvalid_sync_ff4;
	wire				rvalid_sync_ff4;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff4;
	wire [1 : 0]			bresp_sync_ff4;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff4;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff4;
	wire [1 : 0]			rresp_sync_ff4;
	wire				rlast_sync_ff4;

	wire				m_axi_awvalid_sync_ff4;
	wire				m_axi_wvalid_sync_ff4;
	wire				m_axi_arvalid_sync_ff4;

	wire				m_axi_bready_sync_ff4;
	wire				m_axi_rready_sync_ff4;

	wire				m_axi_awready_sync_ff5;
	wire				m_axi_wready_sync_ff5;
	wire				m_axi_arready_sync_ff5;

	wire				m_axi_bvalid_sync_ff5;
	wire				m_axi_rvalid_sync_ff5;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff5;
	wire [1 : 0]			m_axi_bresp_sync_ff5;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff5;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff5;
	wire [1 : 0]			m_axi_rresp_sync_ff5;
	wire				m_axi_rlast_sync_ff5;

	wire				awready_sync_ff5;
	wire				wready_sync_ff5;
	wire				arready_sync_ff5;
	wire				rready_sync_ff5;

	wire				bready_sync_ff5;
	wire				bvalid_sync_ff5;
	wire				rvalid_sync_ff5;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff5;
	wire [1 : 0]			bresp_sync_ff5;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff5;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff5;
	wire [1 : 0]			rresp_sync_ff5;
	wire				rlast_sync_ff5;

	wire				m_axi_awvalid_sync_ff5;
	wire				m_axi_wvalid_sync_ff5;
	wire				m_axi_arvalid_sync_ff5;

	wire				m_axi_bready_sync_ff5;
	wire				m_axi_rready_sync_ff5;

	wire				m_axi_awready_sync_ff6;
	wire				m_axi_wready_sync_ff6;
	wire				m_axi_arready_sync_ff6;

	wire				m_axi_bvalid_sync_ff6;
	wire				m_axi_rvalid_sync_ff6;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff6;
	wire [1 : 0]			m_axi_bresp_sync_ff6;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff6;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff6;
	wire [1 : 0]			m_axi_rresp_sync_ff6;
	wire				m_axi_rlast_sync_ff6;

	wire				awready_sync_ff6;
	wire				wready_sync_ff6;
	wire				arready_sync_ff6;
	wire				rready_sync_ff6;

	wire				bready_sync_ff6;
	wire				bvalid_sync_ff6;
	wire				rvalid_sync_ff6;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff6;
	wire [1 : 0]			bresp_sync_ff6;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff6;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff6;
	wire [1 : 0]			rresp_sync_ff6;
	wire				rlast_sync_ff6;

	wire				m_axi_awvalid_sync_ff6;
	wire				m_axi_wvalid_sync_ff6;
	wire				m_axi_arvalid_sync_ff6;

	wire				m_axi_bready_sync_ff6;
	wire				m_axi_rready_sync_ff6;

	wire				m_axi_awready_sync_ff7;
	wire				m_axi_wready_sync_ff7;
	wire				m_axi_arready_sync_ff7;

	wire				m_axi_bvalid_sync_ff7;
	wire				m_axi_rvalid_sync_ff7;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff7;
	wire [1 : 0]			m_axi_bresp_sync_ff7;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff7;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff7;
	wire [1 : 0]			m_axi_rresp_sync_ff7;
	wire				m_axi_rlast_sync_ff7;

	wire				awready_sync_ff7;
	wire				wready_sync_ff7;
	wire				arready_sync_ff7;
	wire				rready_sync_ff7;

	wire				bready_sync_ff7;
	wire				bvalid_sync_ff7;
	wire				rvalid_sync_ff7;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff7;
	wire [1 : 0]			bresp_sync_ff7;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff7;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff7;
	wire [1 : 0]			rresp_sync_ff7;
	wire				rlast_sync_ff7;

	wire				m_axi_awvalid_sync_ff7;
	wire				m_axi_wvalid_sync_ff7;
	wire				m_axi_arvalid_sync_ff7;

	wire				m_axi_bready_sync_ff7;
	wire				m_axi_rready_sync_ff7;

	wire				m_axi_awready_sync_ff8;
	wire				m_axi_wready_sync_ff8;
	wire				m_axi_arready_sync_ff8;

	wire				m_axi_bvalid_sync_ff8;
	wire				m_axi_rvalid_sync_ff8;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff8;
	wire [1 : 0]			m_axi_bresp_sync_ff8;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff8;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff8;
	wire [1 : 0]			m_axi_rresp_sync_ff8;
	wire				m_axi_rlast_sync_ff8;

	wire				awready_sync_ff8;
	wire				wready_sync_ff8;
	wire				arready_sync_ff8;
	wire				rready_sync_ff8;

	wire				bready_sync_ff8;
	wire				bvalid_sync_ff8;
	wire				rvalid_sync_ff8;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff8;
	wire [1 : 0]			bresp_sync_ff8;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff8;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff8;
	wire [1 : 0]			rresp_sync_ff8;
	wire				rlast_sync_ff8;

	wire				m_axi_awvalid_sync_ff8;
	wire				m_axi_wvalid_sync_ff8;
	wire				m_axi_arvalid_sync_ff8;

	wire				m_axi_bready_sync_ff8;
	wire				m_axi_rready_sync_ff8;

	wire				m_axi_awready_sync_ff9;
	wire				m_axi_wready_sync_ff9;
	wire				m_axi_arready_sync_ff9;

	wire				m_axi_bvalid_sync_ff9;
	wire				m_axi_rvalid_sync_ff9;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff9;
	wire [1 : 0]			m_axi_bresp_sync_ff9;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff9;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff9;
	wire [1 : 0]			m_axi_rresp_sync_ff9;
	wire				m_axi_rlast_sync_ff9;

	wire				awready_sync_ff9;
	wire				wready_sync_ff9;
	wire				arready_sync_ff9;
	wire				rready_sync_ff9;

	wire				bready_sync_ff9;
	wire				bvalid_sync_ff9;
	wire				rvalid_sync_ff9;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff9;
	wire [1 : 0]			bresp_sync_ff9;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff9;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff9;
	wire [1 : 0]			rresp_sync_ff9;
	wire				rlast_sync_ff9;

	wire				m_axi_awvalid_sync_ff9;
	wire				m_axi_wvalid_sync_ff9;
	wire				m_axi_arvalid_sync_ff9;

	wire				m_axi_bready_sync_ff9;
	wire				m_axi_rready_sync_ff9;

	wire				m_axi_awready_sync_ff10;
	wire				m_axi_wready_sync_ff10;
	wire				m_axi_arready_sync_ff10;

	wire				m_axi_bvalid_sync_ff10;
	wire				m_axi_rvalid_sync_ff10;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff10;
	wire [1 : 0]			m_axi_bresp_sync_ff10;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff10;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff10;
	wire [1 : 0]			m_axi_rresp_sync_ff10;
	wire				m_axi_rlast_sync_ff10;

	wire				awready_sync_ff10;
	wire				wready_sync_ff10;
	wire				arready_sync_ff10;
	wire				rready_sync_ff10;

	wire				bready_sync_ff10;
	wire				bvalid_sync_ff10;
	wire				rvalid_sync_ff10;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff10;
	wire [1 : 0]			bresp_sync_ff10;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff10;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff10;
	wire [1 : 0]			rresp_sync_ff10;
	wire				rlast_sync_ff10;

	wire				m_axi_awvalid_sync_ff10;
	wire				m_axi_wvalid_sync_ff10;
	wire				m_axi_arvalid_sync_ff10;

	wire				m_axi_bready_sync_ff10;
	wire				m_axi_rready_sync_ff10;

	wire				m_axi_awready_sync_ff11;
	wire				m_axi_wready_sync_ff11;
	wire				m_axi_arready_sync_ff11;

	wire				m_axi_bvalid_sync_ff11;
	wire				m_axi_rvalid_sync_ff11;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff11;
	wire [1 : 0]			m_axi_bresp_sync_ff11;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff11;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff11;
	wire [1 : 0]			m_axi_rresp_sync_ff11;
	wire				m_axi_rlast_sync_ff11;

	wire				awready_sync_ff11;
	wire				wready_sync_ff11;
	wire				arready_sync_ff11;
	wire				rready_sync_ff11;

	wire				bready_sync_ff11;
	wire				bvalid_sync_ff11;
	wire				rvalid_sync_ff11;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff11;
	wire [1 : 0]			bresp_sync_ff11;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff11;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff11;
	wire [1 : 0]			rresp_sync_ff11;
	wire				rlast_sync_ff11;

	wire				m_axi_awvalid_sync_ff11;
	wire				m_axi_wvalid_sync_ff11;
	wire				m_axi_arvalid_sync_ff11;

	wire				m_axi_bready_sync_ff11;
	wire				m_axi_rready_sync_ff11;

	wire				m_axi_awready_sync_ff12;
	wire				m_axi_wready_sync_ff12;
	wire				m_axi_arready_sync_ff12;

	wire				m_axi_bvalid_sync_ff12;
	wire				m_axi_rvalid_sync_ff12;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff12;
	wire [1 : 0]			m_axi_bresp_sync_ff12;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff12;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff12;
	wire [1 : 0]			m_axi_rresp_sync_ff12;
	wire				m_axi_rlast_sync_ff12;

	wire				awready_sync_ff12;
	wire				wready_sync_ff12;
	wire				arready_sync_ff12;
	wire				rready_sync_ff12;

	wire				bready_sync_ff12;
	wire				bvalid_sync_ff12;
	wire				rvalid_sync_ff12;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff12;
	wire [1 : 0]			bresp_sync_ff12;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff12;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff12;
	wire [1 : 0]			rresp_sync_ff12;
	wire				rlast_sync_ff12;

	wire				m_axi_awvalid_sync_ff12;
	wire				m_axi_wvalid_sync_ff12;
	wire				m_axi_arvalid_sync_ff12;

	wire				m_axi_bready_sync_ff12;
	wire				m_axi_rready_sync_ff12;

	wire				m_axi_awready_sync_ff13;
	wire				m_axi_wready_sync_ff13;
	wire				m_axi_arready_sync_ff13;

	wire				m_axi_bvalid_sync_ff13;
	wire				m_axi_rvalid_sync_ff13;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff13;
	wire [1 : 0]			m_axi_bresp_sync_ff13;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff13;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff13;
	wire [1 : 0]			m_axi_rresp_sync_ff13;
	wire				m_axi_rlast_sync_ff13;

	wire				awready_sync_ff13;
	wire				wready_sync_ff13;
	wire				arready_sync_ff13;
	wire				rready_sync_ff13;

	wire				bready_sync_ff13;
	wire				bvalid_sync_ff13;
	wire				rvalid_sync_ff13;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff13;
	wire [1 : 0]			bresp_sync_ff13;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff13;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff13;
	wire [1 : 0]			rresp_sync_ff13;
	wire				rlast_sync_ff13;

	wire				m_axi_awvalid_sync_ff13;
	wire				m_axi_wvalid_sync_ff13;
	wire				m_axi_arvalid_sync_ff13;

	wire				m_axi_bready_sync_ff13;
	wire				m_axi_rready_sync_ff13;

	wire				m_axi_awready_sync_ff14;
	wire				m_axi_wready_sync_ff14;
	wire				m_axi_arready_sync_ff14;

	wire				m_axi_bvalid_sync_ff14;
	wire				m_axi_rvalid_sync_ff14;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_sync_ff14;
	wire [1 : 0]			m_axi_bresp_sync_ff14;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_sync_ff14;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_sync_ff14;
	wire [1 : 0]			m_axi_rresp_sync_ff14;
	wire				m_axi_rlast_sync_ff14;

	wire				awready_sync_ff14;
	wire				wready_sync_ff14;
	wire				arready_sync_ff14;
	wire				rready_sync_ff14;

	wire				bready_sync_ff14;
	wire				bvalid_sync_ff14;
	wire				rvalid_sync_ff14;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync_ff14;
	wire [1 : 0]			bresp_sync_ff14;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync_ff14;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync_ff14;
	wire [1 : 0]			rresp_sync_ff14;
	wire				rlast_sync_ff14;

	wire				m_axi_awvalid_sync_ff14;
	wire				m_axi_wvalid_sync_ff14;
	wire				m_axi_arvalid_sync_ff14;

	wire				m_axi_bready_sync_ff14;
	wire				m_axi_rready_sync_ff14;

	wire				m_axi_awready_sync_ff15;
	wire				m_axi_wready_sync_ff15;
	wire				m_axi_arready_sync_ff15;
