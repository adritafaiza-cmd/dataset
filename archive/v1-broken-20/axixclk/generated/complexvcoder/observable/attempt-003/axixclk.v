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

	// AXI crossbar for clock domain crossing
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_s, awid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_s, awaddr_m;
	wire [7 : 0] awlen_s, awlen_m;
	wire [2 : 0] awsize_s, awsize_m;
	wire [1 : 0] awburst_s, awburst_m;
	wire awlock_s, awlock_m;
	wire [3 : 0] awcache_s, awcache_m;
	wire [2 : 0] awprot_s, awprot_m;
	wire [3 : 0] awqos_s, awqos_m;
	wire awvalid_s, awvalid_m;
	wire awready_s, awready_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_s, wdata_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_s, wstrb_m;
	wire wlast_s, wlast_m;
	wire wvalid_s, wvalid_m;
	wire wready_s, wready_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_s, bid_m;
	wire [1 : 0] bresp_s, bresp_m;
	wire bvalid_s, bvalid_m;
	wire bready_s, bready_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_s, arid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_s, araddr_m;
	wire [7 : 0] arlen_s, arlen_m;
	wire [2 : 0] arsize_s, arsize_m;
	wire [1 : 0] arburst_s, arburst_m;
	wire arlock_s, arlock_m;
	wire [3 : 0] arcache_s, arcache_m;
	wire [2 : 0] arprot_s, arprot_m;
	wire [3 : 0] arqos_s, arqos_m;
	wire arvalid_s, arvalid_m;
	wire arready_s, arready_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_s, rid_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_s, rdata_m;
	wire [1 : 0] rresp_s, rresp_m;
	wire rlast_s, rlast_m;
	wire rvalid_s, rvalid_m;
	wire rready_s, rready_m;

	// AXI4 crossbar instance
	axis_crossbar #(
		.S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) crossbar (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_AWID(awid_s),
		.S_AXI_AWADDR(awaddr_s),
		.S_AXI_AWLEN(awlen_s),
		.S_AXI_AWSIZE(awsize_s),
		.S_AXI_AWBURST(awburst_s),
		.S_AXI_AWLOCK(awlock_s),
		.S_AXI_AWCACHE(awcache_s),
		.S_AXI_AWPROT(awprot_s),
		.S_AXI_AWQOS(awqos_s),
		.S_AXI_AWVALID(awvalid_s),
		.S_AXI_AWREADY(awready_m),
		.S_AXI_WDATA(wdata_s),
		.S_AXI_WSTRB(wstrb_s),
		.S_AXI_WLAST(wlast_s),
		.S_AXI_WVALID(wvalid_s),
		.S_AXI_WREADY(wready_m),
		.S_AXI_BID(bid_m),
		.S_AXI_BRESP(bresp_m),
		.S_AXI_BVALID(bvalid_m),
		.S_AXI_BREADY(bready_s),
		.S_AXI_ARID(arid_s),
		.S_AXI_ARADDR(araddr_s),
		.S_AXI_ARLEN(arlen_s),
		.S_AXI_ARSIZE(arsize_s),
		.S_AXI_ARBURST(arburst_s),
		.S_AXI_ARLOCK(arlock_s),
		.S_AXI_ARCACHE(archache_s),
		.S_AXI_ARPROT(arprot_s),
		.S_AXI_ARQOS(arqos_s),
		.S_AXI_ARVALID(arvalid_s),
		.S_AXI_ARREADY(arready_m),
		.S_AXI_RID(rid_m),
		.S_AXI_RDATA(rdata_m),
		.S_AXI_RRESP(rresp_m),
		.S_AXI_RLAST(rlast_m),
		.S_AXI_RVALID(rvalid_m),
		.S_AXI_RREADY(rready_s),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_AWID(awid_m),
		.M_AXI_AWADDR(awaddr_m),
		.M_AXI_AWLEN(awlen_m),
		.M_AXI_AWSIZE(awsize_m),
		.M_AXI_AWBURST(awburst_m),
		.M_AXI_AWLOCK(awlock_m),
		.M_AXI_AWCACHE(awcache_m),
		.M_AXI_AWPROT(awprot_m),
		.M_AXI_AWQOS(awqos_m),
		.M_AXI_AWVALID(awvalid_m),
		.M_AXI_AWREADY(awready_s),
		.M_AXI_WDATA(wdata_m),
		.M_AXI_WSTRB(wstrb_m),
		.M_AXI_WLAST(wlast_m),
		.M_AXI_WVALID(wvalid_m),
		.M_AXI_WREADY(wready_s),
		.M_AXI_BID(bid_s),
		.M_AXI_BRESP(bresp_s),
		.M_AXI_BVALID(bvalid_m),
		.M_AXI_BREADY(bready_m),
		.M_AXI_ARID(arid_m),
		.M_AXI_ARADDR(araddr_m),
		.M_AXI_ARLEN(arlen_m),
		.M_AXI_ARSIZE(arsize_m),
		.M_AXI_ARBURST(arburst_m),
		.M_AXI_ARLOCK(arlock_m),
		.M_AXI_ARCACHE(archache_m),
		.M_AXI_ARPROT(arprot_m),
		.M_AXI_ARQOS(arqos_m),
		.M_AXI_ARVALID(arvalid_m),
		.M_AXI_ARREADY(arready_s),
		.M_AXI_RID(rid_s),
		.M_AXI_RDATA(rdata_s),
		.M_AXI_RRESP(rresp_s),
		.M_AXI_RLAST(rlast_s),
		.M_AXI_RVALID(rvalid_m),
		.M_AXI_RREADY(rready_s)
	);

	// S_AXI interface to AXI crossbar
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
	assign awready_s = S_AXI_AWREADY;
	assign S_AXI_WDATA = wdata_s;
	assign S_AXI_WSTRB = wstrb_s;
	assign S_AXI_WLAST = wlast_s;
	assign S_AXI_WVALID = wvalid_s;
	assign wready_s = S_AXI_WREADY;
	assign S_AXI_BID = bid_m;
	assign S_AXI_BRESP = bresp_m;
	assign S_AXI_BVALID = bvalid_m;
	assign bready_s = S_AXI_BREADY;
	assign S_AXI_ARID = arid_s;
	assign S_AXI_ARADDR = araddr_s;
	assign S_AXI_ARLEN = arlen_s;
	assign S_AXI_ARSIZE = arsize_s;
	assign S_AXI_ARBURST = arburst_s;
	assign S_AXI_ARLOCK = arlock_s;
	assign S_AXI_ARCACHE = arcache_s;
	assign S_AXI_ARPROT = arprot_s;
	assign S_AXI_ARQOS = arqos_s;
	assign S_AXI_ARVALID = arvalid_s;
	assign arready_s = S_AXI_ARREADY;
	assign S_AXI_RID = rid_m;
	assign S_AXI_RDATA = rdata_m;
	assign S_AXI_RRESP = rresp_m;
	assign S_AXI_RLAST = rlast_m;
	assign S_AXI_RVALID = rvalid_m;
	assign rready_s = S_AXI_RREADY;

	// M_AXI interface to AXI crossbar
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
	assign awready_m = M_AXI_AWREADY;
	assign M_AXI_WDATA = wdata_m;
	assign M_AXI_WSTRB = wstrb_m;
	assign M_AXI_WLAST = wlast_m;
	assign M_AXI_WVALID = wvalid_m;
	assign wready_m = M_AXI_WREADY;
	assign M_AXI_BID = bid_s;
	assign M_AXI_BRESP = bresp_s;
	assign M_AXI_BVALID = bvalid_s;
	assign bready_m = M_AXI_BREADY;
	assign M_AXI_ARID = arid_m;
	assign M_AXI_ARADDR = araddr_m;
	assign M_AXI_ARLEN = arlen_m;
	assign M_AXI_ARSIZE = arsize_m;
	assign M_AXI_ARBURST = arburst_m;
	assign M_AXI_ARLOCK = arlock_m;
	assign M_AXI_ARCACHE = arcache_m;
	assign M_AXI_ARPROT = arprot_m;
	assign M_AXI_ARQOS = arqos_m;
	assign M_AXI_ARVALID = arvalid_m;
	assign arready_m = M_AXI_ARREADY;
	assign M_AXI_RID = rid_s;
	assign M_AXI_RDATA = rdata_s;
	assign M_AXI_RRESP = rresp_s;
	assign M_AXI_RLAST = rlast_s;
	assign M_AXI_RVALID = rvalid_m;
	assign rready_m = M_AXI_RREADY;

endmodule
