```verilog
`timescale 1ns/1ps

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

	// Clock Generation
	wire M_AXI_ACLK_INT = M_AXI_ACLK;
	wire S_AXI_ACLK_INT = S_AXI_ACLK;

	// Reset Generation
	wire S_AXI_ARESETN_INT = S_AXI_ARESETN;
	wire M_AXI_ARESETN_INT = S_AXI_ARESETN;

	// Cross Clock Domain Generation
	wire S_AXI_ACLK_M = S_AXI_ACLK;
	wire M_AXI_ACLK_S = M_AXI_ACLK;

	// FIFO Parameters
	localparam INTEGER FIFO_DEPTH = (1 << LGFIFO);
	localparam INTEGER FIFO_MASK = (FIFO_DEPTH - 1);

	// Write Channel FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(FIFO_DEPTH),
		.C_OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.C_OPT_READ_ONLY(OPT_READ_ONLY),
		.C_XCLOCK_FFS(XCLOCK_FFS)
	) u_axi_fifo_write (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.awid(M_AXI_AWID),
		.awaddr(M_AXI_AWADDR),
		.awlen(M_AXI_AWLEN),
		.awsize(M_AXI_AWSIZE),
		.awburst(M_AXI_AWBURST),
		.awlock(M_AXI_AWLOCK),
		.awcache(M_AXI_AWCACHE),
		.awprot(M_AXI_AWPROT),
		.awqos(M_AXI_AWQOS),
		.awvalid(M_AXI_AWVALID),
		.awready(S_AXI_AWREADY),
		.wdata(M_AXI_WDATA),
		.wstrb(M_AXI_WSTRB),
		.wlast(M_AXI_WLAST),
		.wvalid(M_AXI_WVALID),
		.wready(S_AXI_WREADY),
		.bid(S_AXI_BID),
		.bresp(S_AXI_BRESP),
		bvalid(S_AXI_BVALID),
		bready(S_AXI_BREADY),
		.arid(M_AXI_ARID),
		.araddr(M_AXI_ARADDR),
		.arlen(M_AXI_ARLEN),
		.arsize(M_AXI_ARSIZE),
		.arburst(M_AXI_ARBURST),
		.arlock(M_AXI_ARLOCK),
		.arcache(M_AXI_ARCACHE),
		.arprot(M_AXI_ARPROT),
		.arqos(M_AXI_ARQOS),
		arvalid(M_AXI_ARVALID),
		arready(S_AXI_ARREADY),
		.rid(S_AXI_RID),
		.rdata(S_AXI_RDATA),
		.rresp(S_AXI_RRESP),
		.rlast(S_AXI_RLAST),
		rvalid(S_AXI_RVALID),
		rready(S_AXI_RREADY)
	);

	// Read Channel FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(FIFO_DEPTH),
		.C_OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.C_OPT_READ_ONLY(OPT_READ_ONLY),
		.C_XCLOCK_FFS(XCLOCK_FFS)
	) u_axi_fifo_read (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.awid(S_AXI_AWID),
		.awaddr(S_AXI_AWADDR),
		.awlen(S_AXI_AWLEN),
		.awsize(S_AXI_AWSIZE),
		.awburst(S_AXI_AWBURST),
		.awlock(S_AXI_AWLOCK),
		.awcache(S_AXI_AWCACHE),
		.awprot(S_AXI_AWPROT),
		.awqos(S_AXI_AWQOS),
		.awvalid(S_AXI_AWVALID),
		.awready(M_AXI_AWREADY),
		.wdata(S_AXI_WDATA),
		.wstrb(S_AXI_WSTRB),
		.wlast(S_AXI_WLAST),
		.wvalid(S_AXI_WVALID),
		.wready(M_AXI_WREADY),
		.bid(M_AXI_BID),
		.bresp(M_AXI_BRESP),
		bvalid(M_AXI_BVALID),
		bready(M_AXI_BREADY),
		.arid(S_AXI_ARID),
		.araddr(S_AXI_ARADDR),
		.arlen(S_AXI_ARLEN),
		.arsize(S_AXI_ARSIZE),
		.arburst(S_AXI_ARBURST),
		.arlock(S_AXI_ARLOCK),
		.arcache(S_AXI_ARCACHE),
		.arprot(S_AXI_ARPROT),
		.arqos(S_AXI_ARQOS),
		arvalid(S_AXI_ARVALID),
		arready(M_AXI_ARREADY),
		.rid(M_AXI_RID),
		.rdata(M_AXI_RDATA),
		.rresp(M_AXI_RRESP),
		.rlast(M_AXI_RLAST),
		rvalid(M_AXI_RVALID),
		rready(M_AXI_RREADY)
	);

	// Cross Clock Domain Generation
	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWID),
		.data_out(S_AXI_AWID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awaddr (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWADDR),
		.data_out(S_AXI_AWADDR)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awlen (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWLEN),
		.data_out(S_AXI_AWLEN)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awsize (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWSIZE),
		.data_out(S_AXI_AWSIZE)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awburst (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWBURST),
		.data_out(S_AXI_AWBURST)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awlock (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWLOCK),
		.data_out(S_AXI_AWLOCK)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awcache (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWCACHE),
		.data_out(S_AXI_AWCACHE)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awprot (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWPROT),
		.data_out(S_AXI_AWPROT)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awqos (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWQOS),
		.data_out(S_AXI_AWQOS)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awvalid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_AWVALID),
		.data_out(S_AXI_AWVALID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_awready (
		.clk_in(S_AXI_ACLK),
		.clk_out(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.resetn_out(M_AXI_ARESETN),
		.data_in(S_AXI_AWREADY),
		.data_out(M_AXI_AWREADY)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_wdata (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_WDATA),
		.data_out(S_AXI_WDATA)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_wstrb (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_WSTRB),
		.data_out(S_AXI_WSTRB)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_wlast (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_WLAST),
		.data_out(S_AXI_WLAST)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_wvalid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_WVALID),
		.data_out(S_AXI_WVALID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_wready (
		.clk_in(S_AXI_ACLK),
		.clk_out(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.resetn_out(M_AXI_ARESETN),
		.data_in(S_AXI_WREADY),
		.data_out(M_AXI_WREADY)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_bid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_BID),
		.data_out(S_AXI_BID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_bresp (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_BRESP),
		.data_out(S_AXI_BRESP)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_bvalid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_BVALID),
		.data_out(S_AXI_BVALID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_bready (
		.clk_in(S_AXI_ACLK),
		.clk_out(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.resetn_out(M_AXI_ARESETN),
		.data_in(S_AXI_BREADY),
		.data_out(M_AXI_BREADY)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARID),
		.data_out(S_AXI_ARID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_araddr (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARADDR),
		.data_out(S_AXI_ARADDR)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arlen (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARLEN),
		.data_out(S_AXI_ARLEN)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arsize (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARSIZE),
		.data_out(S_AXI_ARSIZE)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arburst (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARBURST),
		.data_out(S_AXI_ARBURST)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arlock (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARLOCK),
		.data_out(S_AXI_ARLOCK)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arcache (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARCACHE),
		.data_out(S_AXI_ARCACHE)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arprot (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARPROT),
		.data_out(S_AXI_ARPROT)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arqos (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARQOS),
		.data_out(S_AXI_ARQOS)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arvalid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_ARVALID),
		.data_out(S_AXI_ARVALID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_arready (
		.clk_in(S_AXI_ACLK),
		.clk_out(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.resetn_out(M_AXI_ARESETN),
		.data_in(S_AXI_ARREADY),
		.data_out(M_AXI_ARREADY)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_RID),
		.data_out(S_AXI_RID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rdata (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_RDATA),
		.data_out(S_AXI_RDATA)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rresp (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_RRESP),
		.data_out(S_AXI_RRESP)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rlast (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_RLAST),
		.data_out(S_AXI_RLAST)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rvalid (
		.clk_in(M_AXI_ACLK),
		.clk_out(S_AXI_ACLK),
		.resetn_in(M_AXI_ARESETN),
		.resetn_out(S_AXI_ARESETN),
		.data_in(M_AXI_RVALID),
		.data_out(S_AXI_RVALID)
	);

	cdc_sync #(
		.C_SYNC_STAGES(2)
	) u_cdc_sync_rready (
		.clk_in(S_AXI_ACLK),
		.clk_out(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.resetn_out(M_AXI_ARESETN),
		.data_in(S_AXI_RREADY),
		.data_out(M_AXI_RREADY)
	);

endmodule
```<|im_end|>
