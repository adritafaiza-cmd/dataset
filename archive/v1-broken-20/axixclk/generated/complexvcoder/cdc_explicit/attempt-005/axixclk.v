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
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_reg;
	wire [7 : 0] awlen_reg;
	wire [2 : 0] awsize_reg;
	wire [1 : 0] awburst_reg;
	wire awlock_reg;
	wire [3 : 0] awcache_reg;
	wire [2 : 0] awprot_reg;
	wire [3 : 0] awqos_reg;
	wire awvalid_reg;
	wire m_axi_awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_reg;
	wire wlast_reg;
	wire wvalid_reg;
	wire m_axi_wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_reg;
	wire [1 : 0] bresp_reg;
	wire bvalid_reg;
	wire s_axi_bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_reg;
	wire [7 : 0] arlen_reg;
	wire [2 : 0] arsize_reg;
	wire [1 : 0] arburst_reg;
	wire arlock_reg;
	wire [3 : 0] arcache_reg;
	wire [2 : 0] arprot_reg;
	wire [3 : 0] arqos_reg;
	wire arvalid_reg;
	wire m_axi_arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_reg;
	wire [1 : 0] rresp_reg;
	wire rlast_reg;
	wire rvalid_reg;
	wire s_axi_rready;

	// AXI4 Slave
	AXI4_Slave #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.OPT_READ_ONLY(OPT_READ_ONLY),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) slave (
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
		.awready(S_AXI_AWREADY),
		.wdata(S_AXI_WDATA),
		.wstrb(S_AXI_WSTRB),
		.wlast(S_AXI_WLAST),
		.wvalid(S_AXI_WVALID),
		.wready(S_AXI_WREADY),
		.bid(S_AXI_BID),
		.bresp(S_AXI_BRESP),
		.bvalid(S_AXI_BVALID),
		.bready(S_AXI_BREADY),
		.arid(S_AXI_ARID),
		.araddr(S_AXI_ARADDR),
		.arlen(S_AXI_ARLEN),
		.arsize(S_AXI_ARSIZE),
		.arburst(S_AXI_ARBURST),
		.arlock(S_AXI_ARLOCK),
		.arcache(S_AXI_ARCACHE),
		.arprot(S_AXI_ARPROT),
		.arqos(S_AXI_ARQOS),
		.arvalid(S_AXI_ARVALID),
		.arready(S_AXI_ARREADY),
		.rid(S_AXI_RID),
		.rdata(S_AXI_RDATA),
		.rresp(S_AXI_RRESP),
		.rlast(S_AXI_RLAST),
		.rvalid(S_AXI_RVALID),
		.rready(S_AXI_RREADY)
	);

	// AXI4 Master
	AXI4_Master #(
		.C_M_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.OPT_READ_ONLY(OPT_READ_ONLY),
		.XCLOCK_FFS(XCLOCK_FFS),
		.LGFIFO(LGFIFO)
	) master (
		.clk(M_AXI_ACLK),
		.resetn(M_AXI_ARESETN),
		.awid(awid_reg),
		.awaddr(awaddr_reg),
		.awlen(awlen_reg),
		.awsize(awsize_reg),
		.awburst(awburst_reg),
		.awlock(awlock_reg),
		.awcache(awcache_reg),
		.awprot(awprot_reg),
		.awqos(awqos_reg),
		.awvalid(awvalid_reg),
		.awready(m_axi_awready),
		.wdata(wdata_reg),
		.wstrb(wstrb_reg),
		.wlast(wlast_reg),
		.wvalid(wvalid_reg),
		.wready(m_axi_wready),
		.bid(bid_reg),
		.bresp(bresp_reg),
		.bvalid(bvalid_reg),
		.bready(S_AXI_BREADY),
		.arid(arid_reg),
		.araddr(araddr_reg),
		.arlen(arlen_reg),
		.arsize(arsize_reg),
		.arburst(arburst_reg),
		.arlock(arlock_reg),
		.arcache(arcache_reg),
		.arprot(arprot_reg),
		.arqos(arqos_reg),
		.arvalid(arvalid_reg),
		.arready(m_axi_arready),
		.rid(rid_reg),
		.rdata(rdata_reg),
		.rresp(rresp_reg),
		.rlast(rlast_reg),
		.rvalid(rvalid_reg),
		.rready(S_AXI_RREADY)
	);

	// AXI4 Slave to AXI4 Master handshake
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awid_reg <= 0;
			awaddr_reg <= 0;
			awlen_reg <= 0;
			awsz

