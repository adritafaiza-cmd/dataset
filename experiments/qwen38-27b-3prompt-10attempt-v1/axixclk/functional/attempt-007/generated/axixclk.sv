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

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_m;
	wire [7 : 0] awlen_m;
	wire [2 : 0] awsize_m;
	wire [1 : 0] awburst_m;
	wire awlock_m;
	wire [3 : 0] awcache_m;
	wire [2 : 0] awprot_m;
	wire [3 : 0] awqos_m;
	wire awvalid_m;
	wire awready_s;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_m;
	wire wlast_m;
	wire wvalid_m;
	wire wready_s;

	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_s;
	wire [1 : 0] bresp_s;
	wire bvalid_s;
	wire bready_m;

	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_m;
	wire [7 : 0] arlen_m;
	wire [2 : 0] arsize_m;
	wire [1 : 0] arburst_m;
	wire arlock_m;
	wire [3 : 0] arcache_m;
	wire [2 : 0] arprot_m;
	wire [3 : 0] arqos_m;
	wire arvalid_m;
	wire arready_s;

	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_s;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_s;
	wire [1 : 0] rresp_s;
	wire rlast_s;
	wire rvalid_s;
	wire rready_m;

	// AW channel: S to M
	awxclk_aw #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) u_awxclk_aw (
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
		.S_AXI_AWREADY(S_AXI_AWREADY),
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
		.M_AXI_AWREADY(M_AXI_AWREADY)
	);

	// W channel: S to M
	awxclk_w #(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) u_awxclk_w (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_WDATA(S_AXI_WDATA),
		.S_AXI_WSTRB(S_AXI_WSTRB),
		.S_AXI_WLAST(S_AXI_WLAST),
		.S_AXI_WVALID(S_AXI_WVALID),
		.S_AXI_WREADY(S_AXI_WREADY),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_WDATA(wdata_m),
		.M_AXI_WSTRB(wstrb_m),
		.M_AXI_WLAST(wlast_m),
		.M_AXI_WVALID(wvalid_m),
		.M_AXI_WREADY(M_AXI_WREADY)
	);

	// B channel: M to S
	awxclk_b #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) u_awxclk_b (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_BID(S_AXI_BID),
		.S_AXI_BRESP(S_AXI_BRESP),
		.S_AXI_BVALID(S_AXI_BVALID),
		.S_AXI_BREADY(S_AXI_BREADY),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_BID(M_AXI_BID),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(M_AXI_BREADY)
	);

	// AR channel: S to M
	awxclk_ar #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) u_awxclk_ar (
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
		.S_AXI_ARREADY(S_AXI_ARREADY),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_ARID(arid_m),
		.M_AXI_ARADDR(araddr_m),
		.M_AXI_ARLEN(arlen_m),
		.M_AXI_ARSIZE(arsize_m),
		.M_AXI_ARBURST(arburst_m),
		.M_AXI_ARLOCK(arlock_m),
		.M_AXI_ARCACHE(arcache_m),
		.M_AXI_ARPROT(arprot_m),
		.M_AXI_ARQOS(arqos_m),
		.M_AXI_ARVALID(arvalid_m),
		.M_AXI_ARREADY(M_AXI_ARREADY)
	);

	// R channel: M to S
	awxclk_r #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) u_awxclk_r (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_RID(S_AXI_RID),
		.S_AXI_RDATA(S_AXI_RDATA),
		.S_AXI_RRESP(S_AXI_RRESP),
		.S_AXI_RLAST(S_AXI_RLAST),
		.S_AXI_RVALID(S_AXI_RVALID),
		.S_AXI_RREADY(S_AXI_RREADY),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_RID(M_AXI_RID),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RRESP(M_AXI_RRESP),
		.M_AXI_RLAST(M_AXI_RLAST),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(M_AXI_RREADY)
	);

	// Assign master outputs
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

	assign M_AXI_WDATA = wdata_m;
	assign M_AXI_WSTRB = wstrb_m;
	assign M_AXI_WLAST = wlast_m;
	assign M_AXI_WVALID = wvalid_m;

	assign M_AXI_BREADY = bready_m;

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

	assign M_AXI_RREADY = rready_m;

endmodule

// AW channel clock crossing
module awxclk_aw #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
) (
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	input wire [7 : 0] S_AXI_AWLEN,
	input wire [2 : 0] S_AXI_AWSIZE,
	input wire [1 : 0] S_AXI_AWBURST,
	input wire S_AXI_AWLOCK,
	input wire [3 : 0] S_AXI_AWCACHE,
	input wire [2 : 0] S_AXI_AWPROT,
	input wire [3 : 0] S_AXI_AWQOS,
	input wire S_AXI_AWVALID,
	output wire S_AXI_AWREADY,
	input wire M_AXI_ACLK,
	output wire M_AXI_ARESETN,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
	output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
	output wire [7 : 0] M_AXI_AWLEN,
	output wire [2 : 0] M_AXI_AWSIZE,
	output wire [1 : 0] M_AXI_AWBURST,
	output wire M_AXI_AWLOCK,
	output wire [3 : 0] M_AXI_AWCACHE,
	output wire [2 : 0] M_AXI_AWPROT,
	output wire [3 : 0] M_AXI_AWQOS,
	output wire M_AXI_AWVALID,
	input wire M_AXI_AWREADY
);

	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;

	// S-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr;
	wire [7 : 0] s_awlen;
	wire [2 : 0] s_awsize;
	wire [1 : 0] s_awburst;
	wire s_awlock;
	wire [3 : 0] s_awcache;
	wire [2 : 0] s_awprot;
	wire [3 : 0] s_awqos;
	wire s_awvalid;
	wire s_awready;

	// M-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr;
	wire [7 : 0] m_awlen;
	wire [2 : 0] m_awsize;
	wire [1 : 0] m_awburst;
	wire m_awlock;
	wire [3 : 0] m_awcache;
	wire [2 : 0] m_awprot;
	wire [3 : 0] m_awqos;
	wire m_awvalid;
	wire m_awready;

	// S-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.LGFIFO(LGFIFO)
	) u_s_fifo (
		.CLK(S_AXI_ACLK),
		.RSTN(S_AXI_ARESETN),
		.WDATA({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.WEN(S_AXI_AWVALID),
		.WFULL(s_awready),
		.RDATA({s_awid, s_awaddr, s_awlen, s_awsize, s_awburst, s_awlock, s_awcache, s_awprot, s_awqos}),
		.REN(m_awready),
		.REMPTY(s_awvalid)
	);

	assign S_AXI_AWREADY = s_awready;

	// M-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.LGFIFO(LGFIFO)
	) u_m_fifo (
		.CLK(M_AXI_ACLK),
		.RSTN(M_AXI_ARESETN),
		.WDATA({s_awid, s_awaddr, s_awlen, s_awsize, s_awburst, s_awlock, s_awcache, s_awprot, s_awqos}),
		.WEN(s_awvalid),
		.WFULL(m_awready),
		.RDATA({m_awid, m_awaddr, m_awlen, m_awsize, m_awburst, m_awlock, m_awcache, m_awprot, m_awqos}),
		.REN(M_AXI_AWREADY),
		.REMPTY(m_awvalid)
	);

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

	// Reset synchronization
	reg [XCLOCK_FFS-1 : 0] rst_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			rst_sync <= {XCLOCK_FFS{1'b0}};
		else
			rst_sync <= {rst_sync[XCLOCK_FFS-2 : 0], 1'b1};
	end
	assign M_AXI_ARESETN = rst_sync[XCLOCK_FFS-1];

endmodule

// W channel clock crossing
module awxclk_w #(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
) (
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	input wire S_AXI_WLAST,
	input wire S_AXI_WVALID,
	output wire S_AXI_WREADY,
	input wire M_AXI_ACLK,
	output wire M_AXI_ARESETN,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
	output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
	output wire M_AXI_WLAST,
	output wire M_AXI_WVALID,
	input wire M_AXI_WREADY
);

	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;

	// S-side FIFO
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb;
	wire s_wlast;
	wire s_wvalid;
	wire s_wready;

	// M-side FIFO
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb;
	wire m_wlast;
	wire m_wvalid;
	wire m_wready;

	// S-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.LGFIFO(LGFIFO)
	) u_s_fifo (
		.CLK(S_AXI_ACLK),
		.RSTN(S_AXI_ARESETN),
		.WDATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WEN(S_AXI_WVALID),
		.WFULL(s_wready),
		.RDATA({s_wdata, s_wstrb, s_wlast}),
		.REN(m_wready),
		.REMPTY(s_wvalid)
	);

	assign S_AXI_WREADY = s_wready;

	// M-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.LGFIFO(LGFIFO)
	) u_m_fifo (
		.CLK(M_AXI_ACLK),
		.RSTN(M_AXI_ARESETN),
		.WDATA({s_wdata, s_wstrb, s_wlast}),
		.WEN(s_wvalid),
		.WFULL(m_wready),
		.RDATA({m_wdata, m_wstrb, m_wlast}),
		.REN(M_AXI_WREADY),
		.REMPTY(m_wvalid)
	);

	assign M_AXI_WDATA = m_wdata;
	assign M_AXI_WSTRB = m_wstrb;
	assign M_AXI_WLAST = m_wlast;
	assign M_AXI_WVALID = m_wvalid;

	// Reset synchronization
	reg [XCLOCK_FFS-1 : 0] rst_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			rst_sync <= {XCLOCK_FFS{1'b0}};
		else
			rst_sync <= {rst_sync[XCLOCK_FFS-2 : 0], 1'b1};
	end
	assign M_AXI_ARESETN = rst_sync[XCLOCK_FFS-1];

endmodule

// B channel clock crossing
module awxclk_b #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
) (
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
	output wire [1 : 0] S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input wire S_AXI_BREADY,
	input wire M_AXI_ACLK,
	output wire M_AXI_ARESETN,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
	input wire [1 : 0] M_AXI_BRESP,
	input wire M_AXI_BVALID,
	output wire M_AXI_BREADY
);

	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;

	// M-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_bid;
	wire [1 : 0] m_bresp;
	wire m_bvalid;
	wire m_bready;

	// S-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_bid;
	wire [1 : 0] s_bresp;
	wire s_bvalid;
	wire s_bready;

	// M-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.LGFIFO(LGFIFO)
	) u_m_fifo (
		.CLK(M_AXI_ACLK),
		.RSTN(M_AXI_ARESETN),
		.WDATA({M_AXI_BID, M_AXI_BRESP}),
		.WEN(M_AXI_BVALID),
		.WFULL(m_bready),
		.RDATA({m_bid, m_bresp}),
		.REN(s_bready),
		.REMPTY(m_bvalid)
	);

	assign M_AXI_BREADY = m_bready;

	// S-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.LGFIFO(LGFIFO)
	) u_s_fifo (
		.CLK(S_AXI_ACLK),
		.RSTN(S_AXI_ARESETN),
		.WDATA({m_bid, m_bresp}),
		.WEN(m_bvalid),
		.WFULL(s_bready),
		.RDATA({s_bid, s_bresp}),
		.REN(S_AXI_BREADY),
		.REMPTY(s_bvalid)
	);

	assign S_AXI_BID = s_bid;
	assign S_AXI_BRESP = s_bresp;
	assign S_AXI_BVALID = s_bvalid;

	// Reset synchronization
	reg [XCLOCK_FFS-1 : 0] rst_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			rst_sync <= {XCLOCK_FFS{1'b0}};
		else
			rst_sync <= {rst_sync[XCLOCK_FFS-2 : 0], 1'b1};
	end
	assign M_AXI_ARESETN = rst_sync[XCLOCK_FFS-1];

endmodule

// AR channel clock crossing
module awxclk_ar #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
) (
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	input wire [7 : 0] S_AXI_ARLEN,
	input wire [2 : 0] S_AXI_ARSIZE,
	input wire [1 : 0] S_AXI_ARBURST,
	input wire S_AXI_ARLOCK,
	input wire [3 : 0] S_AXI_ARCACHE,
	input wire [2 : 0] S_AXI_ARPROT,
	input wire [3 : 0] S_AXI_ARQOS,
	input wire S_AXI_ARVALID,
	output wire S_AXI_ARREADY,
	input wire M_AXI_ACLK,
	output wire M_AXI_ARESETN,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
	output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
	output wire [7 : 0] M_AXI_ARLEN,
	output wire [2 : 0] M_AXI_ARSIZE,
	output wire [1 : 0] M_AXI_ARBURST,
	output wire M_AXI_ARLOCK,
	output wire [3 : 0] M_AXI_ARCACHE,
	output wire [2 : 0] M_AXI_ARPROT,
	output wire [3 : 0] M_AXI_ARQOS,
	output wire M_AXI_ARVALID,
	input wire M_AXI_ARREADY
);

	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;

	// S-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr;
	wire [7 : 0] s_arlen;
	wire [2 : 0] s_arsize;
	wire [1 : 0] s_arburst;
	wire s_arlock;
	wire [3 : 0] s_arcache;
	wire [2 : 0] s_arprot;
	wire [3 : 0] s_arqos;
	wire s_arvalid;
	wire s_arready;

	// M-side FIFO
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr;
	wire [7 : 0] m_arlen;
	wire [2 : 0] m_arsize;
	wire [1 : 0] m_arburst;
	wire m_arlock;
	wire [3 : 0] m_arcache;
	wire [2 : 0] m_arprot;
	wire [3 : 0] m_arqos;
	wire m_arvalid;
	wire m_arready;

	// S-side FIFO
	awxclk_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.LGFIFO(LGFIFO)
	) u_s_fifo (
		.CLK(S_AXI_ACLK),
		.RSTN(S_AXI_ARESETN),
		.WDATA({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S