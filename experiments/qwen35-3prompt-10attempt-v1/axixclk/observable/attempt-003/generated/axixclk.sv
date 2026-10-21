```verilog
module axixclk #(
	parameter integer C_S_AXI_ID_WIDTH	= 2,
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 6,
	parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
	parameter [0:0]	OPT_READ_ONLY = 1'b0,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
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

	// Clock generation
	wire S_AXI_ACLK_INT = S_AXI_ACLK;
	wire M_AXI_ACLK_INT = M_AXI_ACLK;
	wire S_AXI_ARESETN_INT = S_AXI_ARESETN;
	wire M_AXI_ARESETN_INT = M_AXI_ARESETN;

	// Cross-clock domain signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID_C2M;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR_C2M;
	wire [7 : 0] S_AXI_AWLEN_C2M;
	wire [2 : 0] S_AXI_AWSIZE_C2M;
	wire [1 : 0] S_AXI_AWBURST_C2M;
	wire S_AXI_AWLOCK_C2M;
	wire [3 : 0] S_AXI_AWCACHE_C2M;
	wire [2 : 0] S_AXI_AWPROT_C2M;
	wire [3 : 0] S_AXI_AWQOS_C2M;
	wire S_AXI_AWVALID_C2M;
	wire S_AXI_AWREADY_C2M;

	wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_WDATA_C2M;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB_C2M;
	wire S_AXI_WLAST_C2M;
	wire S_AXI_WVALID_C2M;
	wire S_AXI_WREADY_C2M;

	wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID_C2M;
	wire [1 : 0] S_AXI_BRESP_C2M;
	wire S_AXI_BVALID_C2M;
	wire S_AXI_BREADY_C2M;

	wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID_C2M;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR_C2M;
	wire [7 : 0] S_AXI_ARLEN_C2M;
	wire [2 : 0] S_AXI_ARSIZE_C2M;
	wire [1 : 0] S_AXI_ARBURST_C2M;
	wire S_AXI_ARLOCK_C2M;
	wire [3 : 0] S_AXI_ARCACHE_C2M;
	wire [2 : 0] S_AXI_ARPROT_C2M;
	wire [3 : 0] S_AXI_ARQOS_C2M;
	wire S_AXI_ARVALID_C2M;
	wire S_AXI_ARREADY_C2M;

	wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID_C2M;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA_C2M;
	wire [1 : 0] S_AXI_RRESP_C2M;
	wire S_AXI_RLAST_C2M;
	wire S_AXI_RVALID_C2M;
	wire S_AXI_RREADY_C2M;

	wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID_M2S;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR_M2S;
	wire [7 : 0] M_AXI_AWLEN_M2S;
	wire [2 : 0] M_AXI_AWSIZE_M2S;
	wire [1 : 0] M_AXI_AWBURST_M2S;
	wire M_AXI_AWLOCK_M2S;
	wire [3 : 0] M_AXI_AWCACHE_M2S;
	wire [2 : 0] M_AXI_AWPROT_M2S;
	wire [3 : 0] M_AXI_AWQOS_M2S;
	wire M_AXI_AWVALID_M2S;
	wire M_AXI_AWREADY_M2S;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA_M2S;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_M2S;
	wire M_AXI_WLAST_M2S;
	wire M_AXI_WVALID_M2S;
	wire M_AXI_WREADY_M2S;

	wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID_M2S;
	wire [1 : 0] M_AXI_BRESP_M2S;
	wire M_AXI_BVALID_M2S;
	wire M_AXI_BREADY_M2S;

	wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID_M2S;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR_M2S;
	wire [7 : 0] M_AXI_ARLEN_M2S;
	wire [2 : 0] M_AXI_ARSIZE_M2S;
	wire [1 : 0] M_AXI_ARBURST_M2S;
	wire M_AXI_ARLOCK_M2S;
	wire [3 : 0] M_AXI_ARCACHE_M2S;
	wire [2 : 0] M_AXI_ARPROT_M2S;
	wire [3 : 0] M_AXI_ARQOS_M2S;
	wire M_AXI_ARVALID_M2S;
	wire M_AXI_ARREADY_M2S;

	wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID_M2S;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA_M2S;
	wire [1 : 0] M_AXI_RRESP_M2S;
	wire M_AXI_RLAST_M2S;
	wire M_AXI_RVALID_M2S;
	wire M_AXI_RREADY_M2S;

	// Cross-clock domain FIFOs
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awid (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWID),
		.data_out(M_AXI_AWID),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awaddr (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWADDR),
		.data_out(M_AXI_AWADDR),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(8),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awlen (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWLEN),
		.data_out(M_AXI_AWLEN),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awsize (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWSIZE),
		.data_out(M_AXI_AWSIZE),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awburst (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWBURST),
		.data_out(M_AXI_AWBURST),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awlock (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWLOCK),
		.data_out(M_AXI_AWLOCK),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awcache (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWCACHE),
		.data_out(M_AXI_AWCACHE),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awprot (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWPROT),
		.data_out(M_AXI_AWPROT),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_awqos (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_AWQOS),
		.data_out(M_AXI_AWQOS),
		.valid_in(S_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY),
		.ready_in(M_AXI_AWREADY_M2S)
	);

	// Write Data FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_wdata (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_WDATA),
		.data_out(M_AXI_WDATA),
		.valid_in(S_AXI_WVALID),
		.ready_out(M_AXI_WREADY),
		.ready_in(M_AXI_WREADY_M2S)
	);

	// Write Strb FIFO
	axi_fifo #(
		.C_DATA_WIDTH((C_S_AXI_DATA_WIDTH/8)),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_wstrb (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_WSTRB),
		.data_out(M_AXI_WSTRB),
		.valid_in(S_AXI_WVALID),
		.ready_out(M_AXI_WREADY),
		.ready_in(M_AXI_WREADY_M2S)
	);

	// Write Last FIFO
	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_wlast (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_WLAST),
		.data_out(M_AXI_WLAST),
		.valid_in(S_AXI_WVALID),
		.ready_out(M_AXI_WREADY),
		.ready_in(M_AXI_WREADY_M2S)
	);

	// Write Response FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_bid (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_BID),
		.data_out(M_AXI_BID),
		.valid_in(S_AXI_BVALID),
		.ready_out(M_AXI_BREADY),
		.ready_in(M_AXI_BREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_bresp (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_BRESP),
		.data_out(M_AXI_BRESP),
		.valid_in(S_AXI_BVALID),
		.ready_out(M_AXI_BREADY),
		.ready_in(M_AXI_BREADY_M2S)
	);

	// Read Address FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arid (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARID),
		.data_out(M_AXI_ARID),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_araddr (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARADDR),
		.data_out(M_AXI_ARADDR),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(8),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arlen (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARLEN),
		.data_out(M_AXI_ARLEN),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arsize (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARSIZE),
		.data_out(M_AXI_ARSIZE),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arburst (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARBURST),
		.data_out(M_AXI_ARBURST),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arlock (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARLOCK),
		.data_out(M_AXI_ARLOCK),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arcache (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARCACHE),
		.data_out(M_AXI_ARCACHE),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arprot (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARPROT),
		.data_out(M_AXI_ARPROT),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_arqos (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_ARQOS),
		.data_out(M_AXI_ARQOS),
		.valid_in(S_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_M2S)
	);

	// Read Data FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_rid (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_RID),
		.data_out(M_AXI_RID),
		.valid_in(S_AXI_RVALID),
		.ready_out(M_AXI_RREADY),
		.ready_in(M_AXI_RREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_rdata (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_RDATA),
		.data_out(M_AXI_RDATA),
		.valid_in(S_AXI_RVALID),
		.ready_out(M_AXI_RREADY),
		.ready_in(M_AXI_RREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_rresp (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_RRESP),
		.data_out(M_AXI_RRESP),
		.valid_in(S_AXI_RVALID),
		.ready_out(M_AXI_RREADY),
		.ready_in(M_AXI_RREADY_M2S)
	);

	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_rlast (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.data_in(S_AXI_RLAST),
		.data_out(M_AXI_RLAST),
		.valid_in(S_AXI_RVALID),
		.ready_out(M_AXI_RREADY),
		.ready_in(M_AXI_RREADY_M2S)
	);

	// Cross-clock domain FIFOs for M to S
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawid (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWID),
		.data_out(S_AXI_AWID),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawaddr (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWADDR),
		.data_out(S_AXI_AWADDR),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(8),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawlen (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWLEN),
		.data_out(S_AXI_AWLEN),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawsize (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWSIZE),
		.data_out(S_AXI_AWSIZE),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawburst (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWBURST),
		.data_out(S_AXI_AWBURST),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawlock (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWLOCK),
		.data_out(S_AXI_AWLOCK),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawcache (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWCACHE),
		.data_out(S_AXI_AWCACHE),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(3),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawprot (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWPROT),
		.data_out(S_AXI_AWPROT),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(4),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mawqos (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_AWQOS),
		.data_out(S_AXI_AWQOS),
		.valid_in(M_AXI_AWVALID),
		.ready_out(S_AXI_AWREADY),
		.ready_in(S_AXI_AWREADY_C2M)
	);

	// Write Data FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mwdata (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_WDATA),
		.data_out(S_AXI_WDATA),
		.valid_in(M_AXI_WVALID),
		.ready_out(S_AXI_WREADY),
		.ready_in(S_AXI_WREADY_C2M)
	);

	// Write Strb FIFO
	axi_fifo #(
		.C_DATA_WIDTH((C_S_AXI_DATA_WIDTH/8)),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mwstrb (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_WSTRB),
		.data_out(S_AXI_WSTRB),
		.valid_in(M_AXI_WVALID),
		.ready_out(S_AXI_WREADY),
		.ready_in(S_AXI_WREADY_C2M)
	);

	// Write Last FIFO
	axi_fifo #(
		.C_DATA_WIDTH(1),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mwlast (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_WLAST),
		.data_out(S_AXI_WLAST),
		.valid_in(M_AXI_WVALID),
		.ready_out(S_AXI_WREADY),
		.ready_in(S_AXI_WREADY_C2M)
	);

	// Write Response FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mbidi (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_BID),
		.data_out(S_AXI_BID),
		.valid_in(M_AXI_BVALID),
		.ready_out(S_AXI_BREADY),
		.ready_in(S_AXI_BREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(2),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_mbresp (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_BRESP),
		.data_out(S_AXI_BRESP),
		.valid_in(M_AXI_BVALID),
		.ready_out(S_AXI_BREADY),
		.ready_in(S_AXI_BREADY_C2M)
	);

	// Read Address FIFO
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_marid (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_ARID),
		.data_out(S_AXI_ARID),
		.valid_in(M_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
		.C_DEPTH(2**LGFIFO)
	) u_fifo_maraddr (
		.clk(S_AXI_ACLK),
		.resetn(S_AXI_ARESETN),
		.data_in(M_AXI_ARADDR),
		.data_out(S_AXI_ARADDR),
		.valid_in(M_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY),
		.ready_in(M_AXI_ARREADY_C2M)
	);

	axi_fifo #(
		.C_DATA_WIDTH(8),
	