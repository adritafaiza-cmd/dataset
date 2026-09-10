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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr;
	wire [7 : 0]			awlen;
	wire [2 : 0]			awsize;
	wire [1 : 0]			awburst;
	wire				awlock;
	wire [3 : 0]			awcache;
	wire [2 : 0]			awprot;
	wire [3 : 0]			awqos;
	wire				awvalid;
	wire				awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb;
	wire				wlast;
	wire				wvalid;
	wire				wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid;
	wire [1 : 0]			bresp;
	wire				bvalid;
	wire				bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr;
	wire [7 : 0]			arlen;
	wire [2 : 0]			arsize;
	wire [1 : 0]			arburst;
	wire				arlock;
	wire [3 : 0]			arcache;
	wire [2 : 0]			arprot;
	wire [3 : 0]			arqos;
	wire				arvalid;
	wire				arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata;
	wire [1 : 0]			rresp;
	wire				rlast;
	wire				rvalid;
	wire				rready;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_awaddr;
	wire [7 : 0]			m_awlen;
	wire [2 : 0]			m_awsize;
	wire [1 : 0]			m_awburst;
	wire				m_awlock;
	wire [3 : 0]			m_awcache;
	wire [2 : 0]			m_awprot;
	wire [3 : 0]			m_awqos;
	wire				m_awvalid;
	wire				m_awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	m_wstrb;
	wire				m_wlast;
	wire				m_wvalid;
	wire				m_wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_bid;
	wire [1 : 0]			m_bresp;
	wire				m_bvalid;
	wire				m_bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_araddr;
	wire [7 : 0]			m_arlen;
	wire [2 : 0]			m_arsize;
	wire [1 : 0]			m_arburst;
	wire				m_arlock;
	wire [3 : 0]			m_arcache;
	wire [2 : 0]			m_arprot;
	wire [3 : 0]			m_arqos;
	wire				m_arvalid;
	wire				m_arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_rdata;
	wire [1 : 0]			m_rresp;
	wire				m_rlast;
	wire				m_rvalid;
	wire				m_rready;

	wire				s_axi_aresetn_sync;
	wire				m_axi_aresetn_sync;

	assign M_AXI_ARESETN = m_axi_aresetn_sync;

	// Synchronous reset synchronizers
	synchronizer #(.WIDTH(1)) u_s_axi_aresetn_sync (
		.clk(S_AXI_ACLK),
		.async_rst_n(S_AXI_ARESETN),
		.sync_rst_n(s_axi_aresetn_sync)
	);

	synchronizer #(.WIDTH(1)) u_m_axi_aresetn_sync (
		.clk(M_AXI_ACLK),
		.async_rst_n(S_AXI_ARESETN),
		.sync_rst_n(m_axi_aresetn_sync)
	);

	// Write channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 4 + 3),
		.DEPTH(1 << LGFIFO)
	) u_awfifo (
		.clk(S_AXI_ACLK),
		.rst_n(s_axi_aresetn_sync),
		.we(S_AXI_AWVALID && S_AXI_AWREADY),
		.wdata({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.re(S_AXI_AWREADY),
		.rdata({awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos}),
		.empty(),
		.full()
	);

	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) u_wfifo (
		.clk(S_AXI_ACLK),
		.rst_n(s_axi_aresetn_sync),
		.we(S_AXI_WVALID && S_AXI_WREADY),
		.wdata({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.re(S_AXI_WREADY),
		.rdata({wdata, wstrb, wlast}),
		.empty(),
		.full()
	);

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(1 << LGFIFO)
	) u_bfifo (
		.clk(M_AXI_ACLK),
		.rst_n(m_axi_aresetn_sync),
		.we(M_AXI_BVALID && M_AXI_BREADY),
		.wdata({M_AXI_BID, M_AXI_BRESP}),
		.re(M_AXI_BREADY),
		.rdata({m_bid, m_bresp}),
		.empty(),
		.full()
	);

	assign S_AXI_AWREADY = ~u_awfifo.full;
	assign S_AXI_WREADY = ~u_wfifo.full;
	assign M_AXI_BREADY = ~u_bfifo.empty;

	assign m_awid = awid;
	assign m_awaddr = awaddr;
	assign m_awlen = awlen;
	assign m_awsize = awsize;
	assign m_awburst = awburst;
	assign m_awlock = awlock;
	assign m_awcache = awcache;
	assign m_awprot = awprot;
	assign m_awqos = awqos;
	assign m_awvalid = ~u_awfifo.empty;
	assign M_AXI_AWID = m_awid;
	assign M_AXI_AWADDR = m_awaddr;
	assign M_AXI_AWLEN = m_awlen;
	assign M_AXI_AWSIZE = m_awsize;
	assign M_AXI_AWBURST = m_awburst;
	assign M_AXI_AWLOCK = m_awlock;
	assign M_AXI_AWCACHE = m_awcache;
	assign M_AXI_AWPROT = m_awprot;
	assign M_AXI_AWQOS = m_awqos;
	assign M_AXI_AWVALID = m_awvalid;

	assign m_wdata = wdata;
	assign m_wstrb = wstrb;
	assign m_wlast = wlast;
	assign m_wvalid = ~u_wfifo.empty;
	assign M_AXI_WDATA = m_wdata;
	assign M_AXI_WSTRB = m_wstrb;
	assign M_AXI_WLAST = m_wlast;
	assign M_AXI_WVALID = m_wvalid;

	assign S_AXI_BID = m_bid;
	assign S_AXI_BRESP = m_bresp;
	assign S_AXI_BVALID = ~u_bfifo.empty;

	// Read channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 4 + 3),
		.DEPTH(1 << LGFIFO)
	) u_arfifo (
		.clk(S_AXI_ACLK),
		.rst_n(s_axi_aresetn_sync),
		.we(S_AXI_ARVALID && S_AXI_ARREADY),
		.wdata({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.re(S_AXI_ARREADY),
		.rdata({arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos}),
		.empty(),
		.full()
	);

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) u_rfifo (
		.clk(M_AXI_ACLK),
		.rst_n(m_axi_aresetn_sync),
		.we(M_AXI_RVALID && M_AXI_RREADY),
		.wdata({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.re(M_AXI_RREADY),
		.rdata({m_rid, m_rdata, m_rresp, m_rlast}),
		.empty(),
		.full()
	);

	assign S_AXI_ARREADY = ~u_arfifo.full;
	assign M_AXI_RREADY = ~u_rfifo.empty;

	assign m_arid = arid;
	assign m_araddr = araddr;
	assign m_arlen = arlen;
	assign m_arsize = arsize;
	assign m_arburst = arburst;
	assign m_arlock = arlock;
	assign m_arcache = arcache;
	assign m_arprot = arprot;
	assign m_arqos = arqos;
	assign m_arvalid = ~u_arfifo.empty;
	assign M_AXI_ARID = m_arid;
	assign M_AXI_ARADDR = m_araddr;
	assign M_AXI_ARLEN = m_arlen;
	assign M_AXI_ARSIZE = m_arsize;
	assign M_AXI_ARBURST = m_arburst;
	assign M_AXI_ARLOCK = m_arlock;
	assign M_AXI_ARCACHE = m_arcache;
	assign M_AXI_ARPROT = m_arprot;
	assign M_AXI_ARQOS = m_arqos;
	assign M_AXI_ARVALID = m_arvalid;

	assign S_AXI_RID = m_rid;
	assign S_AXI_RDATA = m_rdata;
	assign S_AXI_RRESP = m_rresp;
	assign S_AXI_RLAST = m_rlast;
	assign S_AXI_RVALID = ~u_rfifo.empty;

endmodule

module synchronizer #(
		parameter WIDTH = 1
	) (
		input	wire	clk,
		input	wire	async_rst_n,
		output	wire	sync_rst_n
	);

	reg [WIDTH-1 : 0]	rst_n;

	always @(posedge clk or negedge async_rst_n) begin
		if (~async_rst_n) begin
			rst_n <= {WIDTH{1'b0}};
		end else begin
			rst_n <= {WIDTH{1'b1}};
		end
	end

	assign sync_rst_n = rst_n[0];

endmodule

module fifo #(
		parameter WIDTH = 8,
		parameter DEPTH = 16
	) (
		input	wire	clk,
		input	wire	rst_n,
		input	wire	we,
		input	wire [WIDTH-1 : 0]	wdata,
		input	wire	re,
		output	wire [WIDTH-1 : 0]	rdata,
		output	wire	empty,
		output	wire	full
	);

	reg [WIDTH-1 : 0]	data [DEPTH-1 : 0];
	reg [DEPTH-1 : 0]	valid;
	reg [$clog2(DEPTH)-1 : 0]	wptr;
	reg [$clog2(DEPTH)-1 : 0]	rptr;

	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			wptr <= {($clog2(DEPTH)){1'b0}};
			rptr <= {($clog2(DEPTH)){1'b0}};
			valid <= {DEPTH{1'b0}};
		end else if (we && ~full) begin
			data[wptr] <= wdata;
			valid[wptr] <= 1'b1;
			wptr <= wptr + 1;
		end

		if (re && ~empty) begin
			valid[rptr] <= 1'b0;
			rptr <= rptr + 1;
		end
	end

	assign full = (wptr == rptr) && valid[wptr];
	assign empty = (wptr == rptr) && ~valid[wptr];
	assign rdata = data[rptr];

endmodule
