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
	wire				bready_ff;
	wire				rready_ff;

	wire				awvalid_m;
	wire				wvalid_m;
	wire				arvalid_m;
	wire				bready_m;
	wire				rready_m;

	wire				awready_s;
	wire				wready_s;
	wire				arready_s;
	wire				bvalid_s;
	wire				rvalid_s;

	wire				awvalid_ff_sync;
	wire				wvalid_ff_sync;
	wire				arvalid_ff_sync;
	wire				bvalid_ff_sync;
	wire				rvalid_ff_sync;

	wire				awready_ff_sync;
	wire				wready_ff_sync;
	wire				arready_ff_sync;
	wire				bready_ff_sync;
	wire				rready_ff_sync;

	wire				awvalid_m_sync;
	wire				wvalid_m_sync;
	wire				arvalid_m_sync;
	wire				bready_m_sync;
	wire				rready_m_sync;

	wire				awready_m_sync;
	wire				wready_m_sync;
	wire				arready_m_sync;
	wire				bvalid_m_sync;
	wire				rvalid_m_sync;

	wire [LGFIFO-1 : 0]	awfifo_cnt;
	wire [LGFIFO-1 : 0]	wfifo_cnt;
	wire [LGFIFO-1 : 0]	arfifo_cnt;
	wire [LGFIFO-1 : 0]	bfifo_cnt;
	wire [LGFIFO-1 : 0]	rfifo_cnt;

	wire				awfifo_empty;
	wire				wfifo_empty;
	wire				arfifo_empty;
	wire				bfifo_empty;
	wire				rfifo_empty;

	wire				awfifo_full;
	wire				wfifo_full;
	wire				arfifo_full;
	wire				bfifo_full;
	wire				rfifo_full;

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Write channel
	assign awvalid_m = awvalid_ff_sync;
	assign wvalid_m = wvalid_ff_sync;
	assign bready_m = bready_ff_sync;

	assign awready_s = awready_ff_sync;
	assign wready_s = wready_ff_sync;
	assign bvalid_s = bvalid_ff_sync;

	assign M_AXI_AWID = awid_ff;
	assign M_AXI_AWADDR = awaddr_ff;
	assign M_AXI_AWLEN = awlen_ff;
	assign M_AXI_AWSIZE = awsize_ff;
	assign M_AXI_AWBURST = awburst_ff;
	assign M_AXI_AWLOCK = awlock_ff;
	assign M_AXI_AWCACHE = awcache_ff;
	assign M_AXI_AWPROT = awprot_ff;
	assign M_AXI_AWQOS = awqos_ff;
	assign M_AXI_AWVALID = awvalid_m;
	assign M_AXI_WDATA = wdata_ff;
	assign M_AXI_WSTRB = wstrb_ff;
	assign M_AXI_WLAST = wlast_ff;
	assign M_AXI_WVALID = wvalid_m;
	assign M_AXI_BREADY = bready_m;

	assign S_AXI_AWREADY = awready_s;
	assign S_AXI_WREADY = wready_s;
	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_s;

	// Read channel
	assign arvalid_m = arvalid_ff_sync;
	assign rready_m = rready_ff_sync;

	assign arready_s = arready_ff_sync;
	assign rvalid_s = rvalid_ff_sync;

	assign M_AXI_ARID = arid_ff;
	assign M_AXI_ARADDR = araddr_ff;
	assign M_AXI_ARLEN = arlen_ff;
	assign M_AXI_ARSIZE = arsize_ff;
	assign M_AXI_ARBURST = arburst_ff;
	assign M_AXI_ARLOCK = arlock_ff;
	assign M_AXI_ARCACHE = arcache_ff;
	assign M_AXI_ARPROT = arprot_ff;
	assign M_AXI_ARQOS = arqos_ff;
	assign M_AXI_ARVALID = arvalid_m;
	assign M_AXI_RREADY = rready_m;

	assign S_AXI_ARREADY = arready_s;
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_s;

	// FIFOs
	awfifo #(
		.LGFIFO(LGFIFO),
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
	) awfifo_inst (
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
		.S_AXI_AWREADY(awready_s),
		.M_AXI_AWID(awid_ff),
		.M_AXI_AWADDR(awaddr_ff),
		.M_AXI_AWLEN(awlen_ff),
		.M_AXI_AWSIZE(awsize_ff),
		.M_AXI_AWBURST(awburst_ff),
		.M_AXI_AWLOCK(awlock_ff),
		.M_AXI_AWCACHE(awcache_ff),
		.M_AXI_AWPROT(awprot_ff),
		.M_AXI_AWQOS(awqos_ff),
		.M_AXI_AWVALID(awvalid_ff),
		.M_AXI_AWREADY(awready_ff_sync),
		.awfifo_cnt(awfifo_cnt),
		.awfifo_empty(awfifo_empty),
		.awfifo_full(awfifo_full)
	);

	wfifo #(
		.LGFIFO(LGFIFO),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
	) wfifo_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_WDATA(S_AXI_WDATA),
		.S_AXI_WSTRB(S_AXI_WSTRB),
		.S_AXI_WLAST(S_AXI_WLAST),
		.S_AXI_WVALID(S_AXI_WVALID),
		.S_AXI_WREADY(wready_s),
		.M_AXI_WDATA(wdata_ff),
		.M_AXI_WSTRB(wstrb_ff),
		.M_AXI_WLAST(wlast_ff),
		.M_AXI_WVALID(wvalid_ff),
		.M_AXI_WREADY(wready_ff_sync),
		.wfifo_cnt(wfifo_cnt),
		.wfifo_empty(wfifo_empty),
		.wfifo_full(wfifo_full)
	);

	arfifo #(
		.LGFIFO(LGFIFO),
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) arfifo_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
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
		.S_AXI_ARREADY(arready_s),
		.M_AXI_ARID(arid_ff),
		.M_AXI_ARADDR(araddr_ff),
		.M_AXI_ARLEN(arlen_ff),
		.M_AXI_ARSIZE(arsize_ff),
		.M_AXI_ARBURST(arburst_ff),
		.M_AXI_ARLOCK(arlock_ff),
		.M_AXI_ARCACHE(arcache_ff),
		.M_AXI_ARPROT(arprot_ff),
		.M_AXI_ARQOS(arqos_ff),
		.M_AXI_ARVALID(arvalid_ff),
		.M_AXI_ARREADY(arready_ff_sync),
		.arfifo_cnt(arfifo_cnt),
		.arfifo_empty(arfifo_empty),
		.arfifo_full(arfifo_full)
	);

	bfifo #(
		.LGFIFO(LGFIFO),
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH)
	) bfifo_inst (
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_BID(M_AXI_BID),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(bready_m),
		.S_AXI_BID(bid_ff),
		.S_AXI_BRESP(bresp_ff),
		.S_AXI_BVALID(bvalid_ff),
		.S_AXI_BREADY(bready_ff_sync),
		.bfifo_cnt(bfifo_cnt),
		.bfifo_empty(bfifo_empty),
		.bfifo_full(bfifo_full)
	);

	rfifo #(
		.LGFIFO(LGFIFO),
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
	) rfifo_inst (
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_RID(M_AXI_RID),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RRESP(M_AXI_RRESP),
		.M_AXI_RLAST(M_AXI_RLAST),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(rready_m),
		.S_AXI_RID(rid_ff),
		.S_AXI_RDATA(rdata_ff),
		.S_AXI_RRESP(rresp_ff),
		.S_AXI_RLAST(rlast_ff),
		.S_AXI_RVALID(rvalid_ff),
		.S_AXI_RREADY(rready_ff_sync),
		.rfifo_cnt(rfifo_cnt),
		.rfifo_empty(rfifo_empty),
		.rfifo_full(rfifo_full)
	);

	// Clock domain crossing
	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) awvalid_xfer (
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.signal_in(awvalid_ff),
		.signal_out(awvalid_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) wvalid_xfer (
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.signal_in(wvalid_ff),
		.signal_out(wvalid_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) arvalid_xfer (
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.signal_in(arvalid_ff),
		.signal_out(arvalid_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) bvalid_xfer (
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.signal_in(bvalid_ff),
		.signal_out(bvalid_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) rvalid_xfer (
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.signal_in(rvalid_ff),
		.signal_out(rvalid_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) awready_xfer (
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.signal_in(awready_ff),
		.signal_out(awready_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) wready_xfer (
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.signal_in(wready_ff),
		.signal_out(wready_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) arready_xfer (
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.signal_in(arready_ff),
		.signal_out(arready_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) bready_xfer (
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.signal_in(bready_ff),
		.signal_out(bready_ff_sync)
	);

	xclock_xfer #(
		.XCLOCK_FFS(XCLOCK_FFS)
	) rready_xfer (
		.S_AXI_ACLK(S_AXI_ACLK),
		.M_AXI_ACLK(M_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.signal_in(rready_ff),
		.signal_out(rready_ff_sync)
	);

endmodule

module awfifo #(
		parameter integer LGFIFO = 5,
		parameter integer C_S_AXI_ID_WIDTH = 2,
		parameter integer C_S_AXI_ADDR_WIDTH = 6,
		parameter integer C_S_AXI_DATA_WIDTH = 32
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
		output	wire [LGFIFO-1 : 0]	awfifo_cnt,
		output	wire				awfifo_empty,
		output	wire				awfifo_full
	);

	reg [C_S_AXI_ID_WIDTH-1 : 0]	awid_reg [2**LGFIFO-1 : 0];
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_reg [2**LGFIFO-1 : 0];
	reg [7 : 0]			awlen_reg [2**LGFIFO-1 : 0];
	reg [2 : 0]			awsize_reg [2**LGFIFO-1 : 0];
	reg [1 : 0]			awburst_reg [2**LGFIFO-1 : 0];
	reg				awlock_reg [2**LGFIFO-1 : 0];
	reg [3 : 0]			awcache_reg [2**LGFIFO-1 : 0];
	reg [2 : 0]			awprot_reg [2**LGFIFO-1 : 0];
	reg [3 : 0]			awqos_reg [2**LGFIFO-1 : 0];
	reg				awvalid_reg [2**LGFIFO-1 : 0];

	reg [LGFIFO-1 : 0]	awfifo_ptr;
	reg [LGFIFO-1 : 0]	awfifo_cnt_reg;

	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awfifo_ptr <= 0;
			awfifo_cnt_reg <= 0;
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			awid_reg[awfifo_ptr] <= S_AXI_AWID;
			awaddr_reg[awfifo_ptr] <= S_AXI_AWADDR;
			awlen_reg[awfifo_ptr] <= S_AXI_AWLEN;
			awsize_reg[awfifo_ptr] <= S_AXI_AWSIZE;
			awburst_reg[awfifo_ptr] <= S_AXI_AWBURST;
			awlock_reg[awfifo_ptr] <= S_AXI_AWLOCK;
			awcache_reg[awfifo_ptr] <= S_AXI_AWCACHE;
			awprot_reg[awfifo_ptr] <= S_AXI_AWPROT;
			awqos_reg[awfifo_ptr] <= S_AXI_AWQOS;
			awvalid_reg[awfifo_ptr] <= 1'b1;
			awfifo_ptr <= awfifo_ptr + 1;
			awfifo_cnt_reg <= awfifo_cnt_reg + 1;
		end else if (M_AXI_AWREADY && M_AXI_AWVALID) begin
			awvalid_reg[awfifo_ptr - 1] <= 1'b0;
			awfifo_cnt_reg <= awfifo_cnt_reg - 1;
		end
	end

	assign M_AXI_AWID = awid_reg[awfifo_ptr - 1];
	assign M_AXI_AWADDR = awaddr_reg[awfifo_ptr - 1];
	assign M_AXI_AWLEN = awlen_reg[awfifo_ptr - 1];
	assign M_AXI_AWSIZE = awsize_reg[awfifo_ptr - 1];
	assign M_AXI_AWBURST = awburst_reg[awfifo_ptr - 1];
	assign M_AXI_AWLOCK = awlock_reg[awfifo_ptr - 1];
	assign M_AXI_AWCACHE = awcache_reg[awfifo_ptr - 1];
	assign M_AXI_AWPROT = awprot_reg[awfifo_ptr - 1];
	assign M_AXI_AWQOS = awqos_reg[awfifo_ptr - 1];
	assign M_AXI_AWVALID = awvalid_reg[awfifo_ptr - 1];
	assign S_AXI_AWREADY = (awfifo_cnt_reg < (2**LGFIFO - 1)) && M_AXI_AWREADY;
	assign awfifo_cnt = awfifo_cnt_reg;
	assign awfifo_empty = (awfifo_cnt_reg == 0);
	assign awfifo_full = (awfifo_cnt_reg == (2**LGFIFO - 1));

endmodule

module wfifo #(
		parameter integer LGFIFO = 5,
		parameter integer C_S_AXI_DATA_WIDTH = 32
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		output	wire [LGFIFO-1 : 0]	wfifo_cnt,
		output	wire				wfifo_empty,
		output	wire				wfifo_full
	);

	reg [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_reg [2**LGFIFO-1 : 0];
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_reg [2**LGFIFO-1 : 0];
	reg				wlast_reg [2**LGFIFO-1 : 0];
	reg				wvalid_reg [2**LGFIFO-1 : 0];

	reg [LGFIFO-1 : 0]	wfifo_ptr;
	reg [LGFIFO-1 : 0]	wfifo_cnt_reg;

	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wfifo_ptr <= 0;
			wfifo_cnt_reg <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			wdata_reg[wfifo_ptr] <= S_AXI_WDATA;
			wstrb_reg[wfifo_ptr] <= S_AXI_WSTRB;
			wlast_reg[wfifo_ptr] <= S_AXI_WLAST;
			wvalid_reg[wfifo_ptr] <= 1'b1;
			wfifo_ptr <= wfifo_ptr + 1;
			wfifo_cnt_reg <= wfifo_cnt_reg + 1;
		end else if (M_AXI_WREADY && M_AXI_WVALID) begin
			wvalid_reg[wfifo_ptr - 1] <= 1'b0;
			wfifo_cnt_reg <= wfifo_cnt_reg - 1;
		end
	end

	assign M_AXI_WDATA = wdata_reg[wfifo_ptr - 1];
	assign M_AXI_WSTRB = wstrb_reg[wfifo_ptr - 1];
	assign M_AXI_WLAST = wlast_reg[wfifo_ptr - 1];
	assign M_AXI_WVALID = wvalid_reg[wfifo_ptr - 1];
	assign S_AXI_WREADY = (wfifo_cnt_reg < (2**LGFIFO - 1)) && M_AXI_WREADY;
	assign wfifo_cnt = wfifo_cnt_reg;
	assign wfifo_empty = (wfifo_cnt_reg == 0);
	assign wfifo_full = (wfifo_cnt_reg == (2**LGFIFO - 1));

endmodule

module arfifo #(
		parameter integer LGFIFO = 5,
		parameter integer C_S_AXI_ID_WIDTH = 2,
		parameter integer C_S_AXI_ADDR_WIDTH = 6
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
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
		output	wire [LGFIFO-1 : 0]	arfifo_cnt,
		output	wire				arfifo_empty,
		output	wire				arfifo_full
	);

	reg [C_S_AXI_ID_WIDTH-1 : 0]	arid_reg [2**LGFIFO-1 : 0];
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_reg [2**LGFIFO-1 : 0];
	reg [7 : 0]			arlen_reg [2**LGFIFO-1 : 0];
	reg [2 : 0]			arsize_reg [2**LGFIFO-1 : 0];
	reg [1 : 0]			arburst_reg [2**LGFIFO-1 : 0];
	reg				arlock_reg [2**LGFIFO-1 : 0];
	reg [3 : 0]			arcache_reg [2**LGFIFO-1 : 0];
	reg [2 : 0]			arprot_reg [2**LGFIFO-1 : 0];
	reg [3 : 0]			arqos_reg [2**LGFIFO-1 : 0];
	reg				arvalid_reg [2**LGFIFO-1 : 0];

	reg [LGFIFO-1 : 0]	arfifo_ptr;
	reg [LGFIFO-1 : 0]	arfifo_cnt_reg;

	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arfifo_ptr <= 0;
			arfifo_cnt_reg <= 0;
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			arid_reg[arfifo_ptr
