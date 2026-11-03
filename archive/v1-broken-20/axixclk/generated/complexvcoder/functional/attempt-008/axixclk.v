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
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_out;
	wire [7 : 0] awlen_out;
	wire [2 : 0] awsize_out;
	wire [1 : 0] awburst_out;
	wire awlock_out;
	wire [3 : 0] awcache_out;
	wire [2 : 0] awprot_out;
	wire [3 : 0] awqos_out;
	wire awvalid_out;
	wire awready_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_out;
	wire wlast_out;
	wire wvalid_out;
	wire wready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_out;
	wire [1 : 0] bresp_out;
	wire bvalid_out;
	wire bready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_out;
	wire [7 : 0] arlen_out;
	wire [2 : 0] arsize_out;
	wire [1 : 0] arburst_out;
	wire arlock_out;
	wire [3 : 0] arcache_out;
	wire [2 : 0] arprot_out;
	wire [3 : 0] arqos_out;
	wire arvalid_out;
	wire arready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_out;
	wire [1 : 0] rresp_out;
	wire rlast_out;
	wire rvalid_out;
	wire rready_out;

	// AXI Bridge instance
	axis_clock_bridge #(
		.S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.OPT_READ_ONLY(OPT_READ_ONLY),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) axi_bridge_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_AWID(S_AXI_AWID),
		.S_AXI_AWADDR(S_AXI_AWADDR),
		.S_AXI_AWLEN(S_AXI_AWLEN),
		.S_AXI_AWSIZE(S_AXI_AWSIZE),
		.S_AXI_AWBURST(S_AXI_AWBURST),
		.S_AXI_AWLOCK(S_AXI_AWLOCK),
		.S_AXI_AWCACHE(S_AXI_AWCACHE),
		.S_AXI_AWPROT(S_AXI_AWPROT),
		.S_AXI_AWQOS(S_AXI_AWQOS),
		.S_AXI_AWVALID(S_AXI_AWVALID),
		.S_AXI_AWREADY(awready_out),
		.S_AXI_WDATA(S_AXI_WDATA),
		.S_AXI_WSTRB(S_AXI_WSTRB),
		.S_AXI_WLAST(S_AXI_WLAST),
		.S_AXI_WVALID(S_AXI_WVALID),
		.S_AXI_WREADY(awready_out),
		.S_AXI_BID(bid_out),
		.S_AXI_BRESP(bresp_out),
		.S_AXI_BVALID(bvalid_out),
		.S_AXI_BREADY(S_AXI_BREADY),
		.S_AXI_ARID(S_AXI_ARID),
		.S_AXI_ARADDR(S_AXI_ARADDR),
		.S_AXI_ARLEN(S_AXI_ARLEN),
		.S_AXI_ARSIZE(S_AXI_ARSIZE),
		.S_AXI_ARBURST(S_AXI_ARBURST),
		.S_AXI_ARLOCK(S_AXI_ARLOCK),
		.S_AXI_ARCACHE(S_AXI_ARCACHE),
		.S_AXI_ARPROT(S_AXI_ARPROT),
		.S_AXI_ARQOS(S_AXI_ARQOS),
		.S_AXI_ARVALID(S_AXI_ARVALID),
		.S_AXI_ARREADY(arready_out),
		.S_AXI_RID(rid_out),
		.S_AXI_RDATA(rdata_out),
		.S_AXI_RRESP(rresp_out),
		.S_AXI_RLAST(rlast_out),
		.S_AXI_RVALID(rvalid_out),
		.S_AXI_RREADY(S_AXI_RREADY),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_AWID(awid_out),
		.M_AXI_AWADDR(awaddr_out),
		.M_AXI_AWLEN(awlen_out),
		.M_AXI_AWSIZE(awsize_out),
		.M_AXI_AWBURST(awburst_out),
		.M_AXI_AWLOCK(awlock_out),
		.M_AXI_AWCACHE(awcache_out),
		.M_AXI_AWPROT(awprot_out),
		.M_AXI_AWQOS(awqos_out),
		.M_AXI_AWVALID(awvalid_out),
		.M_AXI_AWREADY(M_AXI_AWREADY),
		.M_AXI_WDATA(wdata_out),
		.M_AXI_WSTRB(wstrb_out),
		.M_AXI_WLAST(wlast_out),
		.M_AXI_WVALID(wvalid_out),
		.M_AXI_WREADY(M_AXI_WREADY),
		.M_AXI_BID(M_AXI_BID),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(M_AXI_BREADY),
		.M_AXI_ARID(M_AXI_ARID),
		.M_AXI_ARADDR(M_AXI_ARADDR),
		.M_AXI_ARLEN(M_AXI_ARLEN),
		.M_AXI_ARSIZE(M_AXI_ARSIZE),
		.M_AXI_ARBURST(M_AXI_ARBURST),
		.M_AXI_ARLOCK(M_AXI_ARLOCK),
		.M_AXI_ARCACHE(M_AXI_ARCACHE),
		.M_AXI_ARPROT(M_AXI_ARPROT),
		.M_AXI_ARQOS(M_AXI_ARQOS),
		.M_AXI_ARVALID(M_AXI_ARVALID),
		.M_AXI_ARREADY(M_AXI_ARREADY),
		.M_AXI_RID(M_AXI_RID),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RRESP(M_AXI_RRESP),
		.M_AXI_RLAST(M_AXI_RLAST),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(M_AXI_RREADY)
	);

	// Assign output signals
	assign S_AXI_AWREADY = awready_out;
	assign S_AXI_WREADY = awready_out;
	assign S_AXI_BID = bid_out;
	assign S_AXI_BRESP = bresp_out;
	assign S_AXI_BVALID = bvalid_out;
	assign S_AXI_ARREADY = arready_out;
	assign S_AXI_RID = rid_out;
	assign S_AXI_RDATA = rdata_out;
	assign S_AXI_RRESP = rresp_out;
	assign S_AXI_RLAST = rlast_out;
	assign S_AXI_RVALID = rvalid_out;
	assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule
