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

	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_m, arid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_m, araddr_m;
	wire [7 : 0] awlen_m, arlen_m;
	wire [2 : 0] awsize_m, arsize_m;
	wire [1 : 0] awburst_m, arburst_m;
	wire awlock_m, arlock_m;
	wire [3 : 0] awcache_m, arcache_m;
	wire [2 : 0] awprot_m, arprot_m;
	wire [3 : 0] awqos_m, arqos_m;
	wire awvalid_m, arvalid_m;
	wire awready_s, arready_s;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] awdata_s, ardata_s;
	wire [3 : 0] awstrb_s, arstrb_s;
	wire awlast_s, arlast_s;
	wire awvalid_s, arvalid_s;
	wire awready_m, arready_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_m, rid_m;
	wire [1 : 0] bresp_m, rresp_m;
	wire bvalid_m, rvalid_m;
	wire bready_s, rready_s;

	// AXI master bridge
	assign M_AXI_ACLK = S_AXI_ACLK;
	assign M_AXI_ARESETN = S_AXI_ARESETN;
	assign M_AXI_AWID = awid_m;
	assign M_AXI_AWADDR = awaddr_m;
	assign M_AXI_AWLEN = awlen_m;
	assign M_AXI_AWSIZE = awsize_m;
	assign M_AXI_AWBURST = awburst_m;
	assign M_AXI_AWLOCK = awlock_m;
	assign M_AXI_AWCACHE = awcache_m;
	assign M_AXI_AWPROT = awprot_m;
	assign M_AXI_AWQOS = awqos_m;
	assign M_AXI_AWVALID = awvalid_m;
	assign awready_s = M_AXI_AWREADY;
	assign M_AXI_WDATA = awdata_s;
	assign M_AXI_WSTRB = awstrb_s;
	assign M_AXI_WLAST = awlast_s;
	assign M_AXI_WVALID = awvalid_s;
	assign awready_m = M_AXI_WREADY;
	assign M_AXI_BID = bid_m;
	assign M_AXI_BRESP = bresp_m;
	assign M_AXI_BVALID = bvalid_m;
	assign bready_s = M_AXI_BREADY;

	// AXI slave bridge
	assign S_AXI_AWREADY = arready_s;
	assign S_AXI_WREADY = awready_s;
	assign S_AXI_BID = bid_m;
	assign S_AXI_BRESP = bresp_m;
	assign S_AXI_BVALID = bvalid_m;
	assign S_AXI_ARREADY = awready_s;
	assign S_AXI_RID = rid_m;
	assign S_AXI_RDATA = ardata_s;
	assign S_AXI_RRESP = rresp_m;
	assign S_AXI_RLAST = arlast_s;
	assign S_AXI_RVALID = rvalid_m;

	// Clock-domain crossing logic
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_s, arid_s;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_s, araddr_s;
	wire [7 : 0] awlen_s, arlen_s;
	wire [2 : 0] awsize_s, arsize_s;
	wire [1 : 0] awburst_s, arburst_s;
	wire awlock_s, arlock_s;
	wire [3 : 0] awcache_s, arcache_s;
	wire [2 : 0] awprot_s, arprot_s;
	wire [3 : 0] awqos_s, arqos_s;
	wire awvalid_s, arvalid_s;
	wire awready_m, arready_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] awdata_s, ardata_s;
	wire [3 : 0] awstrb_s, arstrb_s;
	wire awlast_s, arlast_s;
	wire awvalid_s, arvalid_s;
	wire awready_m, arready_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_s, rid_s;
	wire [1 : 0] bresp_s, rresp_s;
	wire bvalid_s, rvalid_s;
	wire bready_m, rready_m;

	// AXI master bridge
	assign S_AXI_ACLK = M_AXI_ACLK;
	assign S_AXI_ARESETN = M_AXI_ARESETN;
	assign S_AXI_AWID = awid_s;
	assign S_AXI_AWADDR = awaddr_s;
	assign S_AXI_AWLEN = awlen_s;
	assign S_AXI_AWSIZE = awsize_s;
	assign S_AXI_AWBURST = awburst_s;
	assign S_AXI_AWLOCK = awlock_s;
	assign S_AXI_AWCACHE = awcache_s;
	assign S_AXI_AWPROT = awprot_s;
	assign S_AXI_AWQOS = awqos_s;
	assign S_AXI_AWVALID = awvalid_s;
	assign awready_m = S_AXI_AWREADY;
	assign S_AXI_WDATA = awdata_s;
	assign S_AXI_WSTRB = awstrb_s;
	assign S_AXI_WLAST = awlast_s;
	assign S_AXI_WVALID = awvalid_s;
	assign awready_s = S_AXI_WREADY;
	assign S_AXI_BID = bid_s;
	assign S_AXI_BRESP = bresp_s;
	assign S_AXI_BVALID = bvalid_s;
	assign bready_m = S_AXI_BREADY;

	// AXI slave bridge
	assign M_AXI_AWREADY = awready_s;
	assign M_AXI_WREADY = arready_s;
	assign M_AXI_BID = bid_s;
	assign M_AXI_BRESP = bresp_s;
	assign M_AXI_BVALID = bvalid_s;
	assign M_AXI_ARREADY = arready_s;
	assign M_AXI_RID = rid_s;
	assign M_AXI_RDATA = ardata_s;
	assign M_AXI_RRESP = rresp_s;
	assign M_AXI_RLAST = arlast_s;
	assign M_AXI_RVALID = rvalid_s;

endmodule
