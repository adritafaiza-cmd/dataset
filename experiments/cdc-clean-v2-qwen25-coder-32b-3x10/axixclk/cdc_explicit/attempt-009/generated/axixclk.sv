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
	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_awid_reg, m_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	s_awaddr_reg, m_awaddr_reg;
	reg [7 : 0]				s_awlen_reg, m_awlen_reg;
	reg [2 : 0]				s_awsize_reg, m_awsize_reg;
	reg [1 : 0]				s_awburst_reg, m_awburst_reg;
	reg					s_awlock_reg, m_awlock_reg;
	reg [3 : 0]				s_awcache_reg, m_awcache_reg;
	reg [2 : 0]				s_awprot_reg, m_awprot_reg;
	reg [3 : 0]				s_awqos_reg, m_awqos_reg;
	reg					s_awvalid_reg, m_awvalid_reg;
	reg					s_awready_reg, m_awready_reg;

	reg [C_S_AXI_DATA_WIDTH-1 : 0]	s_wdata_reg, m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	s_wstrb_reg, m_wstrb_reg;
	reg					s_wlast_reg, m_wlast_reg;
	reg					s_wvalid_reg, m_wvalid_reg;
	reg					s_wready_reg, m_wready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_bid_reg, m_bid_reg;
	reg [1 : 0]				s_bresp_reg, m_bresp_reg;
	reg					s_bvalid_reg, m_bvalid_reg;
	reg					s_bready_reg, m_bready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_arid_reg, m_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	s_araddr_reg, m_araddr_reg;
	reg [7 : 0]				s_arlen_reg, m_arlen_reg;
	reg [2 : 0]				s_arsize_reg, m_arsize_reg;
	reg [1 : 0]				s_arburst_reg, m_arburst_reg;
	reg					s_arlock_reg, m_arlock_reg;
	reg [3 : 0]				s_arcache_reg, m_arcache_reg;
	reg [2 : 0]				s_arprot_reg, m_arprot_reg;
	reg [3 : 0]				s_arqos_reg, m_arqos_reg;
	reg					s_arvalid_reg, m_arvalid_reg;
	reg					s_arready_reg, m_arready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_rid_reg, m_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	s_rdata_reg, m_rdata_reg;
	reg [1 : 0]				s_rresp_reg, m_rresp_reg;
	reg					s_rlast_reg, m_rlast_reg;
	reg					s_rvalid_reg, m_rvalid_reg;
	reg					s_rready_reg, m_rready_reg;

	// FIFOs for AW, W, B, AR, R channels
	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_fifo_out;
	wire [7 : 0]			awlen_fifo_out;
	wire [2 : 0]			awsize_fifo_out;
	wire [1 : 0]			awburst_fifo_out;
	wire				awlock_fifo_out;
	wire [3 : 0]			awcache_fifo_out;
	wire [2 : 0]			awprot_fifo_out;
	wire [3 : 0]			awqos_fifo_out;
	wire				awvalid_fifo_out;
	wire				awready_fifo_out;

	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_fifo_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_fifo_out;
	wire				wlast_fifo_out;
	wire				wvalid_fifo_out;
	wire				wready_fifo_out;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_fifo_out;
	wire [1 : 0]			bresp_fifo_out;
	wire				bvalid_fifo_out;
	wire				bready_fifo_out;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_fifo_out;
	wire [7 : 0]			arlen_fifo_out;
	wire [2 : 0]			arsize_fifo_out;
	wire [1 : 0]			arburst_fifo_out;
	wire				arlock_fifo_out;
	wire [3 : 0]			arcache_fifo_out;
	wire [2 : 0]			arprot_fifo_out;
	wire [3 : 0]			arqos_fifo_out;
	wire				arvalid_fifo_out;
	wire				arready_fifo_out;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_fifo_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_fifo_out;
	wire [1 : 0]			rresp_fifo_out;
	wire				rlast_fifo_out;
	wire				rvalid_fifo_out;
	wire				rready_fifo_out;

	// FIFOs instantiation
	fifo #(.WIDTH(C_S_AXI_ID_WIDTH), .DEPTH(1<<LGFIFO)) awid_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWID),
		.dout(awid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_ADDR_WIDTH), .DEPTH(1<<LGFIFO)) awaddr_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWADDR),
		.dout(awaddr_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(8), .DEPTH(1<<LGFIFO)) awlen_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWLEN),
		.dout(awlen_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(3), .DEPTH(1<<LGFIFO)) awsize_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWSIZE),
		.dout(awsize_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(2), .DEPTH(1<<LGFIFO)) awburst_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWBURST),
		.dout(awburst_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) awlock_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWLOCK),
		.dout(awlock_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(4), .DEPTH(1<<LGFIFO)) awcache_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWCACHE),
		.dout(awcache_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(3), .DEPTH(1<<LGFIFO)) awprot_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWPROT),
		.dout(awprot_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(4), .DEPTH(1<<LGFIFO)) awqos_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWQOS),
		.dout(awqos_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) awvalid_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY & m_awvalid_reg),
		.din(S_AXI_AWVALID),
		.dout(awvalid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_DATA_WIDTH), .DEPTH(1<<LGFIFO)) wdata_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_WVALID & S_AXI_WREADY),
		.rd_en(M_AXI_WREADY & m_wvalid_reg),
		.din(S_AXI_WDATA),
		.dout(wdata_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_DATA_WIDTH/8), .DEPTH(1<<LGFIFO)) wstrb_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_WVALID & S_AXI_WREADY),
		.rd_en(M_AXI_WREADY & m_wvalid_reg),
		.din(S_AXI_WSTRB),
		.dout(wstrb_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) wlast_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_WVALID & S_AXI_WREADY),
		.rd_en(M_AXI_WREADY & m_wvalid_reg),
		.din(S_AXI_WLAST),
		.dout(wlast_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) wvalid_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_WVALID & S_AXI_WREADY),
		.rd_en(M_AXI_WREADY & m_wvalid_reg),
		.din(S_AXI_WVALID),
		.dout(wvalid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_ID_WIDTH), .DEPTH(1<<LGFIFO)) bid_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_BVALID & M_AXI_BREADY),
		.rd_en(S_AXI_BREADY & s_bvalid_reg),
		.din(M_AXI_BID),
		.dout(bid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(2), .DEPTH(1<<LGFIFO)) bresp_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_BVALID & M_AXI_BREADY),
		.rd_en(S_AXI_BREADY & s_bvalid_reg),
		.din(M_AXI_BRESP),
		.dout(bresp_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) bvalid_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_BVALID & M_AXI_BREADY),
		.rd_en(S_AXI_BREADY & s_bvalid_reg),
		.din(M_AXI_BVALID),
		.dout(bvalid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_ID_WIDTH), .DEPTH(1<<LGFIFO)) arid_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARID),
		.dout(arid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_ADDR_WIDTH), .DEPTH(1<<LGFIFO)) araddr_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARADDR),
		.dout(araddr_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(8), .DEPTH(1<<LGFIFO)) arlen_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARLEN),
		.dout(arlen_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(3), .DEPTH(1<<LGFIFO)) arsize_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARSIZE),
		.dout(arsize_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(2), .DEPTH(1<<LGFIFO)) arburst_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARBURST),
		.dout(arburst_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) arlock_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARLOCK),
		.dout(arlock_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(4), .DEPTH(1<<LGFIFO)) arcache_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARCACHE),
		.dout(arcache_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(3), .DEPTH(1<<LGFIFO)) arprot_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARPROT),
		.dout(arprot_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(4), .DEPTH(1<<LGFIFO)) arqos_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARQOS),
		.dout(arqos_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) arvalid_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY & m_arvalid_reg),
		.din(S_AXI_ARVALID),
		.dout(arvalid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_ID_WIDTH), .DEPTH(1<<LGFIFO)) rid_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.rd_en(S_AXI_RREADY & s_rvalid_reg),
		.din(M_AXI_RID),
		.dout(rid_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(C_S_AXI_DATA_WIDTH), .DEPTH(1<<LGFIFO)) rdata_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.rd_en(S_AXI_RREADY & s_rvalid_reg),
		.din(M_AXI_RDATA),
		.dout(rdata_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(2), .DEPTH(1<<LGFIFO)) rresp_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.rd_en(S_AXI_RREADY & s_rvalid_reg),
		.din(M_AXI_RRESP),
		.dout(rresp_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) rlast_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.rd_en(S_AXI_RREADY & s_rvalid_reg),
		.din(M_AXI_RLAST),
		.dout(rlast_fifo_out),
		.full(),
		.empty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) rvalid_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.rd_en(S_AXI_RREADY & s_rvalid_reg),
		.din(M_AXI_RVALID),
		.dout(rvalid_fifo_out),
		.full(),
		.empty()
	);

	// AW channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awready_reg <= 1'b0;
		end else begin
			s_awready_reg <= awready_fifo_out;
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_awid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_awaddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_awlen_reg <= 8'b0;
			m_awsize_reg <= 3'b0;
			m_awburst_reg <= 2'b0;
			m_awlock_reg <= 1'b0;
			m_awcache_reg <= 4'b0;
			m_awprot_reg <= 3'b0;
			m_awqos_reg <= 4'b0;
			m_awvalid_reg <= 1'b0;
		end else begin
			if (M_AXI_AWREADY & m_awvalid_reg) begin
				m_awvalid_reg <= 1'b0;
			end else if (awvalid_fifo_out) begin
				m_awid_reg <= awid_fifo_out;
				m_awaddr_reg <= awaddr_fifo_out;
				m_awlen_reg <= awlen_fifo_out;
				m_awsize_reg <= awsize_fifo_out;
				m_awburst_reg <= awburst_fifo_out;
				m_awlock_reg <= awlock_fifo_out;
				m_awcache_reg <= awcache_fifo_out;
				m_awprot_reg <= awprot_fifo_out;
				m_awqos_reg <= awqos_fifo_out;
				m_awvalid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_AWID = m_awid_reg;
	assign M_AXI_AWADDR = m_awaddr_reg;
	assign M_AXI_AWLEN = m_awlen_reg;
	assign M_AXI_AWSIZE = m_awsize_reg;
	assign M_AXI_AWBURST = m_awburst_reg;
	assign M_AXI_AWLOCK = m_awlock_reg;
	assign M_AXI_AWCACHE = m_awcache_reg;
	assign M_AXI_AWPROT = m_awprot_reg;
	assign M_AXI_AWQOS = m_awqos_reg;
	assign M_AXI_AWVALID = m_awvalid_reg;
	assign awready_fifo_out = !m_awvalid_reg;

	// W channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wready_reg <= 1'b0;
		end else begin
			s_wready_reg <= wready_fifo_out;
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_reg <= 1'b0;
			m_wvalid_reg <= 1'b0;
		end else begin
			if (M_AXI_WREADY & m_wvalid_reg) begin
				m_wvalid_reg <= 1'b0;
			end else if (wvalid_fifo_out) begin
				m_wdata_reg <= wdata_fifo_out;
				m_wstrb_reg <= wstrb_fifo_out;
				m_wlast_reg <= wlast_fifo_out;
				m_wvalid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;
	assign wready_fifo_out = !m_wvalid_reg;

	// B channel
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_bready_reg <= 1'b0;
		end else begin
			m_bready_reg <= s_bready_reg;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_bresp_reg <= 2'b0;
			s_bvalid_reg <= 1'b0;
		end else begin
			if (S_AXI_BREADY & s_bvalid_reg) begin
				s_bvalid_reg <= 1'b0;
			end else if (bvalid_fifo_out) begin
				s_bid_reg <= bid_fifo_out;
				s_bresp_reg <= bresp_fifo_out;
				s_bvalid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_BREADY = m_bready_reg;
	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = s_bvalid_reg;
	assign bready_fifo_out = !s_bvalid_reg;

	// AR channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arready_reg <= 1'b0;
		end else begin
			s_arready_reg <= arready_fifo_out;
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_arid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_araddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_arlen_reg <= 8'b0;
			m_arsize_reg <= 3'b0;
			m_arburst_reg <= 2'b0;
			m_arlock_reg <= 1'b0;
			m_arcache_reg <= 4'b0;
			m_arprot_reg <= 3'b0;
			m_arqos_reg <= 4'b0;
			m_arvalid_reg <= 1'b0;
		end else begin
			if (M_AXI_ARREADY & m_arvalid_reg) begin
				m_arvalid_reg <= 1'b0;
			end else if (arvalid_fifo_out) begin
				m_arid_reg <= arid_fifo_out;
				m_araddr_reg <= araddr_fifo_out;
				m_arlen_reg <= arlen_fifo_out;
				m_arsize_reg <= arsize_fifo_out;
				m_arburst_reg <= arburst_fifo_out;
				m_arlock_reg <= arlock_fifo_out;
				m_arcache_reg <= arcache_fifo_out;
				m_arprot_reg <= arprot_fifo_out;
				m_arqos_reg <= arqos_fifo_out;
				m_arvalid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_ARID = m_arid_reg;
	assign M_AXI_ARADDR = m_araddr_reg;
	assign M_AXI_ARLEN = m_arlen_reg;
	assign M_AXI_ARSIZE = m_arsize_reg;
	assign M_AXI_ARBURST = m_arburst_reg;
	assign M_AXI_ARLOCK = m_arlock_reg;
	assign M_AXI_ARCACHE = m_arcache_reg;
	assign M_AXI_ARPROT = m_arprot_reg;
	assign M_AXI_ARQOS = m_arqos_reg;
	assign M_AXI_ARVALID = m_arvalid_reg;
	assign arready_fifo_out = !m_arvalid_reg;

	// R channel
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_rready_reg <= 1'b0;
		end else begin
			m_rready_reg <= s_rready_reg;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_rdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			s_rresp_reg <= 2'b0;
			s_rlast_reg <= 1'b0;
			s_rvalid_reg <= 1'b0;
		end else begin
			if (S_AXI_RREADY & s_rvalid_reg) begin
				s_rvalid_reg <= 1'b0;
			end else if (rvalid_fifo_out) begin
				s_rid_reg <= rid_fifo_out;
				s_rdata_reg <= rdata_fifo_out;
				s_rresp_reg <= rresp_fifo_out;
				s_rlast_reg <= rlast_fifo_out;
				s_rvalid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_RREADY = m_rready_reg;
	assign S_AXI_RID = s_rid_reg;
	assign S_AXI_RDATA = s_rdata_reg;
	assign S_AXI_RRESP = s_rresp_reg;
	assign S_AXI_RLAST = s_rlast_reg;
	assign S_AXI_RVALID = s_rvalid_reg;
	assign rready_fifo_out = !s_rvalid_reg;

	// Assignments for unused directions
	assign S_AXI_AWREADY = OPT_READ_ONLY ? 1'b0 : s_awready_reg;
	assign S_AXI_WREADY = OPT_READ_ONLY ? 1'b0 : s_wready_reg;
	assign S_AXI_BID = OPT_READ_ONLY ? {C_S_AXI_ID_WIDTH{1'b0}} : s_bid_reg;
	assign S_AXI_BRESP = OPT_READ_ONLY ? 2'b0 : s_bresp_reg;
	assign S_AXI_BVALID = OPT_READ_ONLY ? 1'b0 :