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
	wire				awready_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire				wready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire				bready_ff;
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
	wire				arready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;
	wire				rready_ff;

	wire				awvalid_m;
	wire				awready_m;
	wire				wvalid_m;
	wire				wready_m;
	wire				bvalid_m;
	wire				bready_m;
	wire				arvalid_m;
	wire				arready_m;
	wire				rvalid_m;
	wire				rready_m;

	wire				awvalid_s;
	wire				awready_s;
	wire				wvalid_s;
	wire				wready_s;
	wire				bvalid_s;
	wire				bready_s;
	wire				arvalid_s;
	wire				arready_s;
	wire				rvalid_s;
	wire				rready_s;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m;
	wire [7 : 0]			awlen_m;
	wire [2 : 0]			awsize_m;
	wire [1 : 0]			awburst_m;
	wire				awlock_m;
	wire [3 : 0]			awcache_m;
	wire [2 : 0]			awprot_m;
	wire [3 : 0]			awqos_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m;
	wire				wlast_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m;
	wire [1 : 0]			bresp_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m;
	wire [7 : 0]			arlen_m;
	wire [2 : 0]			arsize_m;
	wire [1 : 0]			arburst_m;
	wire				arlock_m;
	wire [3 : 0]			arcache_m;
	wire [2 : 0]			arprot_m;
	wire [3 : 0]			arqos_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m;
	wire [1 : 0]			rresp_m;
	wire				rlast_m;

	wire				awvalid_s_ff;
	wire				awready_s_ff;
	wire				wvalid_s_ff;
	wire				wready_s_ff;
	wire				bvalid_s_ff;
	wire				bready_s_ff;
	wire				arvalid_s_ff;
	wire				arready_s_ff;
	wire				rvalid_s_ff;
	wire				rready_s_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_s_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_s_ff;
	wire [7 : 0]			awlen_s_ff;
	wire [2 : 0]			awsize_s_ff;
	wire [1 : 0]			awburst_s_ff;
	wire				awlock_s_ff;
	wire [3 : 0]			awcache_s_ff;
	wire [2 : 0]			awprot_s_ff;
	wire [3 : 0]			awqos_s_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_s_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_s_ff;
	wire				wlast_s_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_s_ff;
	wire [1 : 0]			bresp_s_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_s_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_s_ff;
	wire [7 : 0]			arlen_s_ff;
	wire [2 : 0]			arsize_s_ff;
	wire [1 : 0]			arburst_s_ff;
	wire				arlock_s_ff;
	wire [3 : 0]			arcache_s_ff;
	wire [2 : 0]			arprot_s_ff;
	wire [3 : 0]			arqos_s_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_s_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_s_ff;
	wire [1 : 0]			rresp_s_ff;
	wire				rlast_s_ff;

	wire				awvalid_m_ff;
	wire				awready_m_ff;
	wire				wvalid_m_ff;
	wire				wready_m_ff;
	wire				bvalid_m_ff;
	wire				bready_m_ff;
	wire				arvalid_m_ff;
	wire				arready_m_ff;
	wire				rvalid_m_ff;
	wire				rready_m_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m_ff;
	wire [7 : 0]			awlen_m_ff;
	wire [2 : 0]			awsize_m_ff;
	wire [1 : 0]			awburst_m_ff;
	wire				awlock_m_ff;
	wire [3 : 0]			awcache_m_ff;
	wire [2 : 0]			awprot_m_ff;
	wire [3 : 0]			awqos_m_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m_ff;
	wire				wlast_m_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m_ff;
	wire [1 : 0]			bresp_m_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m_ff;
	wire [7 : 0]			arlen_m_ff;
	wire [2 : 0]			arsize_m_ff;
	wire [1 : 0]			arburst_m_ff;
	wire				arlock_m_ff;
	wire [3 : 0]			arcache_m_ff;
	wire [2 : 0]			arprot_m_ff;
	wire [3 : 0]			arqos_m_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m_ff;
	wire [1 : 0]			rresp_m_ff;
	wire				rlast_m_ff;

	wire				awvalid_m_d;
	wire				awready_m_d;
	wire				wvalid_m_d;
	wire				wready_m_d;
	wire				bvalid_m_d;
	wire				bready_m_d;
	wire				arvalid_m_d;
	wire				arready_m_d;
	wire				rvalid_m_d;
	wire				rready_m_d;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m_d;
	wire [7 : 0]			awlen_m_d;
	wire [2 : 0]			awsize_m_d;
	wire [1 : 0]			awburst_m_d;
	wire				awlock_m_d;
	wire [3 : 0]			awcache_m_d;
	wire [2 : 0]			awprot_m_d;
	wire [3 : 0]			awqos_m_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m_d;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m_d;
	wire				wlast_m_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m_d;
	wire [1 : 0]			bresp_m_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m_d;
	wire [7 : 0]			arlen_m_d;
	wire [2 : 0]			arsize_m_d;
	wire [1 : 0]			arburst_m_d;
	wire				arlock_m_d;
	wire [3 : 0]			arcache_m_d;
	wire [2 : 0]			arprot_m_d;
	wire [3 : 0]			arqos_m_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m_d;
	wire [1 : 0]			rresp_m_d;
	wire				rlast_m_d;

	wire				awvalid_s_d;
	wire				awready_s_d;
	wire				wvalid_s_d;
	wire				wready_s_d;
	wire				bvalid_s_d;
	wire				bready_s_d;
	wire				arvalid_s_d;
	wire				arready_s_d;
	wire				rvalid_s_d;
	wire				rready_s_d;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_s_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_s_d;
	wire [7 : 0]			awlen_s_d;
	wire [2 : 0]			awsize_s_d;
	wire [1 : 0]			awburst_s_d;
	wire				awlock_s_d;
	wire [3 : 0]			awcache_s_d;
	wire [2 : 0]			awprot_s_d;
	wire [3 : 0]			awqos_s_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_s_d;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_s_d;
	wire				wlast_s_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_s_d;
	wire [1 : 0]			bresp_s_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_s_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_s_d;
	wire [7 : 0]			arlen_s_d;
	wire [2 : 0]			arsize_s_d;
	wire [1 : 0]			arburst_s_d;
	wire				arlock_s_d;
	wire [3 : 0]			arcache_s_d;
	wire [2 : 0]			arprot_s_d;
	wire [3 : 0]			arqos_s_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_s_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_s_d;
	wire [1 : 0]			rresp_s_d;
	wire				rlast_s_d;

	wire				awvalid_m_q;
	wire				awready_m_q;
	wire				wvalid_m_q;
	wire				wready_m_q;
	wire				bvalid_m_q;
	wire				bready_m_q;
	wire				arvalid_m_q;
	wire				arready_m_q;
	wire				rvalid_m_q;
	wire				rready_m_q;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m_q;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m_q;
	wire [7 : 0]			awlen_m_q;
	wire [2 : 0]			awsize_m_q;
	wire [1 : 0]			awburst_m_q;
	wire				awlock_m_q;
	wire [3 : 0]			awcache_m_q;
	wire [2 : 0]			awprot_m_q;
	wire [3 : 0]			awqos_m_q;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m_q;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m_q;
	wire				wlast_m_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m_q;
	wire [1 : 0]			bresp_m_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m_q;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m_q;
	wire [7 : 0]			arlen_m_q;
	wire [2 : 0]			arsize_m_q;
	wire [1 : 0]			arburst_m_q;
	wire				arlock_m_q;
	wire [3 : 0]			arcache_m_q;
	wire [2 : 0]			arprot_m_q;
	wire [3 : 0]			arqos_m_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m_q;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m_q;
	wire [1 : 0]			rresp_m_q;
	wire				rlast_m_q;

	wire				awvalid_s_q;
	wire				awready_s_q;
	wire				wvalid_s_q;
	wire				wready_s_q;
	wire				bvalid_s_q;
	wire				bready_s_q;
	wire				arvalid_s_q;
	wire				arready_s_q;
	wire				rvalid_s_q;
	wire				rready_s_q;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_s_q;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_s_q;
	wire [7 : 0]			awlen_s_q;
	wire [2 : 0]			awsize_s_q;
	wire [1 : 0]			awburst_s_q;
	wire				awlock_s_q;
	wire [3 : 0]			awcache_s_q;
	wire [2 : 0]			awprot_s_q;
	wire [3 : 0]			awqos_s_q;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_s_q;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_s_q;
	wire				wlast_s_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_s_q;
	wire [1 : 0]			bresp_s_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_s_q;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_s_q;
	wire [7 : 0]			arlen_s_q;
	wire [2 : 0]			arsize_s_q;
	wire [1 : 0]			arburst_s_q;
	wire				arlock_s_q;
	wire [3 : 0]			arcache_s_q;
	wire [2 : 0]			arprot_s_q;
	wire [3 : 0]			arqos_s_q;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_s_q;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_s_q;
	wire [1 : 0]			rresp_s_q;
	wire				rlast_s_q;

	wire				awvalid_m_d2;
	wire				awready_m_d2;
	wire				wvalid_m_d2;
	wire				wready_m_d2;
	wire				bvalid_m_d2;
	wire				bready_m_d2;
	wire				arvalid_m_d2;
	wire				arready_m_d2;
	wire				rvalid_m_d2;
	wire				rready_m_d2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m_d2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m_d2;
	wire [7 : 0]			awlen_m_d2;
	wire [2 : 0]			awsize_m_d2;
	wire [1 : 0]			awburst_m_d2;
	wire				awlock_m_d2;
	wire [3 : 0]			awcache_m_d2;
	wire [2 : 0]			awprot_m_d2;
	wire [3 : 0]			awqos_m_d2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m_d2;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m_d2;
	wire				wlast_m_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m_d2;
	wire [1 : 0]			bresp_m_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m_d2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m_d2;
	wire [7 : 0]			arlen_m_d2;
	wire [2 : 0]			arsize_m_d2;
	wire [1 : 0]			arburst_m_d2;
	wire				arlock_m_d2;
	wire [3 : 0]			arcache_m_d2;
	wire [2 : 0]			arprot_m_d2;
	wire [3 : 0]			arqos_m_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m_d2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m_d2;
	wire [1 : 0]			rresp_m_d2;
	wire				rlast_m_d2;

	wire				awvalid_s_d2;
	wire				awready_s_d2;
	wire				wvalid_s_d2;
	wire				wready_s_d2;
	wire				bvalid_s_d2;
	wire				bready_s_d2;
	wire				arvalid_s_d2;
	wire				arready_s_d2;
	wire				rvalid_s_d2;
	wire				rready_s_d2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_s_d2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_s_d2;
	wire [7 : 0]			awlen_s_d2;
	wire [2 : 0]			awsize_s_d2;
	wire [1 : 0]			awburst_s_d2;
	wire				awlock_s_d2;
	wire [3 : 0]			awcache_s_d2;
	wire [2 : 0]			awprot_s_d2;
	wire [3 : 0]			awqos_s_d2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_s_d2;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_s_d2;
	wire				wlast_s_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_s_d2;
	wire [1 : 0]			bresp_s_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_s_d2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_s_d2;
	wire [7 : 0]			arlen_s_d2;
	wire [2 : 0]			arsize_s_d2;
	wire [1 : 0]			arburst_s_d2;
	wire				arlock_s_d2;
	wire [3 : 0]			arcache_s_d2;
	wire [2 : 0]			arprot_s_d2;
	wire [3 : 0]			arqos_s_d2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_s_d2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_s_d2;
	wire [1 : 0]			rresp_s_d2;
	wire				rlast_s_d2;

	wire				awvalid_m_q2;
	wire				awready_m_q2;
	wire				wvalid_m_q2;
	wire				wready_m_q2;
	wire				bvalid_m_q2;
	wire				bready_m_q2;
	wire				arvalid_m_q2;
	wire				arready_m_q2;
	wire				rvalid_m_q2;
	wire				rready_m_q2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m_q2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m_q2;
	wire [7 : 0]			awlen_m_q2;
	wire [2 : 0]			awsize_m_q2;
	wire [1 : 0]			awburst_m_q2;
	wire				awlock_m_q2;
	wire [3 : 0]			awcache_m_q2;
	wire [2 : 0]			awprot_m_q2;
	wire [3 : 0]			awqos_m_q2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m_q2;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m_q2;
	wire				wlast_m_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m_q2;
	wire [1 : 0]			bresp_m_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m_q2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m_q2;
	wire [7 : 0]			arlen_m_q2;
	wire [2 : 0]			arsize_m_q2;
	wire [1 : 0]			arburst_m_q2;
	wire				arlock_m_q2;
	wire [3 : 0]			arcache_m_q2;
	wire [2 : 0]			arprot_m_q2;
	wire [3 : 0]			arqos_m_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m_q2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m_q2;
	wire [1 : 0]			rresp_m_q2;
	wire				rlast_m_q2;

	wire				awvalid_s_q2;
	wire				awready_s_q2;
	wire				wvalid_s_q2;
	wire				wready_s_q2;
	wire				bvalid_s_q2;
	wire				bready_s_q2;
	wire				arvalid_s_q2;
	wire				arready_s_q2;
	wire				rvalid_s_q2;
	wire				rready_s_q2;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_s_q2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_s_q2;
	wire [7 : 0]			awlen_s_q2;
	wire [2 : 0]			awsize_s_q2;
	wire [1 : 0]			awburst_s_q2;
	wire				awlock_s_q2;
	wire [3 : 0]			awcache_s_q2;
	wire [2 : 0]			awprot_s_q2;
	wire [3 : 0]			awqos_s_q2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_s_q2;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_s_q2;
	wire				wlast_s_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_s_q2;
	wire [1 : 0]			bresp_s_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_s_q2;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_s_q2;
	wire [7 : 0]			arlen_s_q2;
	wire [2 : 0]			arsize_s_q2;
	wire [1 : 0]			arburst_s_q2;
	wire				arlock_s_q2;
	wire [3 : 0]			arcache_s_q2;
	wire [2 : 0]			arprot_s_q2;
	wire [3 : 0]			arqos_s_q2;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_s_q2;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_s_q2;
	wire [1 : 0]			rresp_s_q2;
	wire				rlast_s_q2;

	assign M_AXI_ARESETN = ~S_AXI_ARESETN;

	assign awvalid_m = awvalid_s;
	assign awready_m = awready_s;
	assign wvalid_m = wvalid_s;
	assign wready_m = wready_s;
	assign bvalid_m = bvalid_s;
	assign bready_m = bready_s;
	assign arvalid_m = arvalid_s;
	assign arready_m = arready_s;
	assign rvalid_m = rvalid_s;
	assign rready_m = rready_s;

	assign awid_m = awid_s;
	assign awaddr_m = awaddr_s;
	assign awlen_m = awlen_s;
	assign awsize_m = awsize_s;
	assign awburst_m = awburst_s;
	assign awlock_m = awlock_s;
	assign awcache_m = awcache_s;
	assign awprot_m = awprot_s;
	assign awqos_m = awqos_s;
	assign wdata_m = wdata_s;
	assign wstrb_m = wstrb_s;
	assign wlast_m = wlast_s;
	assign bid_m = bid_s;
	assign bresp_m = bresp_s;
	assign arid_m = arid_s;
	assign araddr_m = araddr_s;
	assign arlen_m = arlen_s;
	assign arsize_m = arsize_s;
	assign arburst_m = arburst_s;
	assign arlock_m = arlock_s;
	assign arcache_m = arcache_s;
	assign arprot_m = arprot_s;
	assign arqos_m = arqos_s;
	assign rid_m = rid_s;
	assign rdata_m = rdata_s;
	assign rresp_m = rresp_s;
	assign rlast_m = rlast_s;

	assign awvalid_s = awvalid_m;
	assign awready_s = awready_m;
	assign wvalid_s = wvalid_m;
	assign wready_s = wready_m;
	assign bvalid_s = bvalid_m;
	assign bready_s = bready_m;
	assign arvalid_s = arvalid_m;
	assign arready_s = arready_m;
	assign rvalid_s = rvalid_m;
	assign rready_s = rready_m;

	assign awid_s = awid_m;
	assign awaddr_s = awaddr_m;
	assign awlen_s = awlen_m;
	assign awsize_s = awsize_m;
	assign awburst_s = awburst_m;
	assign awlock_s = awlock_m;
	assign awcache_s = awcache_m
