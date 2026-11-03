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

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Synchronous reset
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
		if (!S_AXI_ARESETN)
			s_axi_aresetn_sync <= 1'b0;
		else
			s_axi_aresetn_sync <= 1'b1;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN)
		if (!S_AXI_ARESETN)
			m_axi_aresetn_sync <= 1'b0;
		else
			m_axi_aresetn_sync <= 1'b1;

	// AW Channel
	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awid <= {C_S_AXI_ID_WIDTH{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awid <= S_AXI_AWID;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awaddr <= S_AXI_AWADDR;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awlen <= {8{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awlen <= S_AXI_AWLEN;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awsize <= {3{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awsize <= S_AXI_AWSIZE;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awburst <= {2{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awburst <= S_AXI_AWBURST;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awlock <= 1'b0;
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awlock <= S_AXI_AWLOCK;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awcache <= {4{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awcache <= S_AXI_AWCACHE;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awprot <= {3{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awprot <= S_AXI_AWPROT;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awqos <= {4{1'b0}};
		else if (S_AXI_AWVALID && S_AXI_AWREADY)
			awqos <= S_AXI_AWQOS;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			awvalid <= 1'b0;
		else if (S_AXI_AWVALID &&!awvalid)
			awvalid <= 1'b1;
		else if (M_AXI_AWREADY && awvalid)
			awvalid <= 1'b0;

	assign S_AXI_AWREADY = awvalid && M_AXI_AWREADY;

	// W Channel
	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			wdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
		else if (S_AXI_WVALID && S_AXI_WREADY)
			wdata <= S_AXI_WDATA;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			wstrb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
		else if (S_AXI_WVALID && S_AXI_WREADY)
			wstrb <= S_AXI_WSTRB;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			wlast <= 1'b0;
		else if (S_AXI_WVALID && S_AXI_WREADY)
			wlast <= S_AXI_WLAST;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			wvalid <= 1'b0;
		else if (S_AXI_WVALID &&!wvalid)
			wvalid <= 1'b1;
		else if (M_AXI_WREADY && wvalid)
			wvalid <= 1'b0;

	assign S_AXI_WREADY = wvalid && M_AXI_WREADY;

	// B Channel
	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_bid <= {C_S_AXI_ID_WIDTH{1'b0}};
		else if (M_AXI_BVALID && M_AXI_BREADY)
			m_bid <= M_AXI_BID;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_bresp <= {2{1'b0}};
		else if (M_AXI_BVALID && M_AXI_BREADY)
			m_bresp <= M_AXI_BRESP;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			bvalid <= 1'b0;
		else if (M_AXI_BVALID &&!bvalid)
			bvalid <= 1'b1;
		else if (S_AXI_BREADY && bvalid)
			bvalid <= 1'b0;

	assign M_AXI_BREADY = bvalid && S_AXI_BREADY;

	assign S_AXI_BID = m_bid;
	assign S_AXI_BRESP = m_bresp;
	assign S_AXI_BVALID = bvalid;
	assign S_AXI_BREADY = M_AXI_BREADY;

	// AR Channel
	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arid <= {C_S_AXI_ID_WIDTH{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arid <= S_AXI_ARID;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			araddr <= S_AXI_ARADDR;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arlen <= {8{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arlen <= S_AXI_ARLEN;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arsize <= {3{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arsize <= S_AXI_ARSIZE;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arburst <= {2{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arburst <= S_AXI_ARBURST;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arlock <= 1'b0;
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arlock <= S_AXI_ARLOCK;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arcache <= {4{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arcache <= S_AXI_ARCACHE;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arprot <= {3{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arprot <= S_AXI_ARPROT;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arqos <= {4{1'b0}};
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			arqos <= S_AXI_ARQOS;

	always @(posedge S_AXI_ACLK)
		if (!s_axi_aresetn_sync)
			arvalid <= 1'b0;
		else if (S_AXI_ARVALID &&!arvalid)
			arvalid <= 1'b1;
		else if (M_AXI_ARREADY && arvalid)
			arvalid <= 1'b0;

	assign S_AXI_ARREADY = arvalid && M_AXI_ARREADY;

	// R Channel
	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_rid <= {C_S_AXI_ID_WIDTH{1'b0}};
		else if (M_AXI_RVALID && M_AXI_RREADY)
			m_rid <= M_AXI_RID;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
		else if (M_AXI_RVALID && M_AXI_RREADY)
			m_rdata <= M_AXI_RDATA;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_rresp <= {2{1'b0}};
		else if (M_AXI_RVALID && M_AXI_RREADY)
			m_rresp <= M_AXI_RRESP;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			m_rlast <= 1'b0;
		else if (M_AXI_RVALID && M_AXI_RREADY)
			m_rlast <= M_AXI_RLAST;

	always @(posedge M_AXI_ACLK)
		if (!m_axi_aresetn_sync)
			rvalid <= 1'b0;
		else if (M_AXI_RVALID &&!rvalid)
			rvalid <= 1'b1;
		else if (S_AXI_RREADY && rvalid)
			rvalid <= 1'b0;

	assign M_AXI_RREADY = rvalid && S_AXI_RREADY;

	assign S_AXI_RID = m_rid;
	assign S_AXI_RDATA = m_rdata;
	assign S_AXI_RRESP = m_rresp;
	assign S_AXI_RLAST = m_rlast;
	assign S_AXI_RVALID = rvalid;
	assign S_AXI_RREADY = M_AXI_RREADY;

	// AXI4 Master
	assign M_AXI_AWID = awid;
	assign M_AXI_AWADDR = awaddr;
	assign M_AXI_AWLEN = awlen;
	assign M_AXI_AWSIZE = awsize;
	assign M_AXI_AWBURST = awburst;
	assign M_AXI_AWLOCK = awlock;
	assign M_AXI_AWCACHE = awcache;
	assign M_AXI_AWPROT = awprot;
	assign M_AXI_AWQOS = awqos;
	assign M_AXI_AWVALID = awvalid;
	assign M_AXI_WDATA = wdata;
	assign M_AXI_WSTRB = wstrb;
	assign M_AXI_WLAST = wlast;
	assign M_AXI_WVALID = wvalid;
	assign M_AXI_BREADY = bvalid;
	assign M_AXI_ARID = arid;
	assign M_AXI_ARADDR = araddr;
	assign M_AXI_ARLEN = arlen;
	assign M_AXI_ARSIZE = arsize;
	assign M_AXI_ARBURST = arburst;
	assign M_AXI_ARLOCK = arlock;
	assign M_AXI_ARCACHE = arcache;
	assign M_AXI_ARPROT = arprot;
	assign M_AXI_ARQOS = arqos;
	assign M_AXI_ARVALID = arvalid;
	assign M_AXI_RREADY = rvalid;

endmodule
