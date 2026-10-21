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

	// Cross Clock FIFO Parameters
	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer WRITE_DEPTH = FIFO_DEPTH;
	localparam integer READ_DEPTH = FIFO_DEPTH;
	localparam integer WRITE_ADDR_WIDTH = LGFIFO;
	localparam integer READ_ADDR_WIDTH = LGFIFO;
	localparam integer WRITE_DATA_WIDTH = C_S_AXI_DATA_WIDTH;
	localparam integer READ_DATA_WIDTH = C_S_AXI_DATA_WIDTH;
	localparam integer WRITE_STRB_WIDTH = (C_S_AXI_DATA_WIDTH/8);
	localparam integer READ_STRB_WIDTH = (C_S_AXI_DATA_WIDTH/8);

	// Cross Clock FIFO Instantiation
	// Using a generic cross-clock FIFO structure compliant with Verilog-2001
	// The XCLOCK_FFS parameter is used to determine the number of flip-flops in the pipeline
	// for the write side to ensure proper timing before the read clock domain.
	
	// Write FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(WRITE_DATA_WIDTH),
		.STRB_WIDTH(WRITE_STRB_WIDTH),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_AWVALID),
		.WR_DATA({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.WR_STRB({S_AXI_AWVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_AWREADY),
		.RD_DATA({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.RD_STRB({M_AXI_AWREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_AWREADY),
		.EMPTY(M_AXI_AWREADY)
	);

	// Read FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(READ_DATA_WIDTH),
		.STRB_WIDTH(READ_STRB_WIDTH),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Data FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(WRITE_DATA_WIDTH),
		.STRB_WIDTH(WRITE_STRB_WIDTH),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_data (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_WVALID),
		.WR_DATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WR_STRB({S_AXI_WVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_WREADY),
		.RD_DATA({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.RD_STRB({M_AXI_WREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_WREADY),
		.EMPTY(M_AXI_WREADY)
	);

	// Write Response FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2), // ID + BRESP
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_response (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_BVALID),
		.WR_DATA({M_AXI_BID, M_AXI_BRESP}),
		.WR_STRB({M_AXI_BVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_BREADY),
		.RD_DATA({S_AXI_BID, S_AXI_BRESP}),
		.RD_STRB({S_AXI_BREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_BREADY),
		.EMPTY(S_AXI_BREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Address FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8), // ID + ADDR + LEN + SIZE + BURST + LOCK + CACHE + PROT + QOS
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_address (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_AWVALID),
		.WR_DATA({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.WR_STRB({S_AXI_AWVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_AWREADY),
		.RD_DATA({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.RD_STRB({M_AXI_AWREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_AWREADY),
		.EMPTY(M_AXI_AWREADY)
	);

	// Read Address FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8), // ID + ADDR + LEN + SIZE + BURST + LOCK + CACHE + PROT + QOS
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_address (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_ARVALID),
		.WR_DATA({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.WR_STRB({M_AXI_ARVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_ARREADY),
		.RD_DATA({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.RD_STRB({S_AXI_ARREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_ARREADY),
		.EMPTY(S_AXI_ARREADY)
	);

	// Write Data FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + WRITE_STRB_WIDTH + 1), // DATA + STRB + LAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_data (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_WVALID),
		.WR_DATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WR_STRB({S_AXI_WVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_WREADY),
		.RD_DATA({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.RD_STRB({M_AXI_WREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_WREADY),
		.EMPTY(M_AXI_WREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Response FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2), // ID + BRESP
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_response (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_BVALID),
		.WR_DATA({M_AXI_BID, M_AXI_BRESP}),
		.WR_STRB({M_AXI_BVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_BREADY),
		.RD_DATA({S_AXI_BID, S_AXI_BRESP}),
		.RD_STRB({S_AXI_BREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_BREADY),
		.EMPTY(S_AXI_BREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Data FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + WRITE_STRB_WIDTH + 1), // DATA + STRB + LAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_data (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_WVALID),
		.WR_DATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WR_STRB({S_AXI_WVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_WREADY),
		.RD_DATA({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.RD_STRB({M_AXI_WREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_WREADY),
		.EMPTY(M_AXI_WREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Response FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2), // ID + BRESP
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_response (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_BVALID),
		.WR_DATA({M_AXI_BID, M_AXI_BRESP}),
		.WR_STRB({M_AXI_BVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_BREADY),
		.RD_DATA({S_AXI_BID, S_AXI_BRESP}),
		.RD_STRB({S_AXI_BREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_BREADY),
		.EMPTY(S_AXI_BREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Data FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + WRITE_STRB_WIDTH + 1), // DATA + STRB + LAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_data (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_WVALID),
		.WR_DATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WR_STRB({S_AXI_WVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_WREADY),
		.RD_DATA({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.RD_STRB({M_AXI_WREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_WREADY),
		.EMPTY(M_AXI_WREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Response FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2), // ID + BRESP
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_response (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_BVALID),
		.WR_DATA({M_AXI_BID, M_AXI_BRESP}),
		.WR_STRB({M_AXI_BVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_BREADY),
		.RD_DATA({S_AXI_BID, S_AXI_BRESP}),
		.RD_STRB({S_AXI_BREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_BREADY),
		.EMPTY(S_AXI_BREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Data FIFO (Slave to Master)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(WRITE_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + WRITE_STRB_WIDTH + 1), // DATA + STRB + LAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_data (
		.CLK_S(S_AXI_ACLK),
		.CLK_M(M_AXI_ACLK),
		.RST_S(S_AXI_ARESETN),
		.RST_M(M_AXI_ARESETN),
		.WR_EN(S_AXI_WVALID),
		.WR_DATA({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.WR_STRB({S_AXI_WVALID}), // Dummy strobe for write enable
		.RD_EN(M_AXI_WREADY),
		.RD_DATA({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.RD_STRB({M_AXI_WREADY}), // Dummy strobe for read enable
		.FULL(S_AXI_WREADY),
		.EMPTY(M_AXI_WREADY)
	);

	// Read Data FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), // ID + RDATA + RRESP + RLAST
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_read_data (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_RVALID),
		.WR_DATA({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.WR_STRB({M_AXI_RVALID}), // Dummy strobe for write enable
		.RD_EN(S_AXI_RREADY),
		.RD_DATA({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.RD_STRB({S_AXI_RREADY}), // Dummy strobe for read enable
		.FULL(M_AXI_RREADY),
		.EMPTY(S_AXI_RREADY)
	);

	// Write Response FIFO (Master to Slave)
	cross_clock_fifo #(
		.DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(READ_ADDR_WIDTH),
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2), // ID + BRESP
		.STRB_WIDTH(1),
		.PIPELINE_STAGES(XCLOCK_FFS)
	) u_cross_clock_fifo_write_response (
		.CLK_S(M_AXI_ACLK),
		.CLK_M(S_AXI_ACLK),
		.RST_S(M_AXI_ARESETN),
		.RST_M(S_AXI_ARESETN),
		.WR_EN(M_AXI_BVALID),
		.WR_DATA({M_AXI_BID, M_AXI_BRESP}),