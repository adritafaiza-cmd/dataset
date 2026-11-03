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
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_reg, m_wstrb_reg;
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

	// Clock domain crossing for AW channel
	reg [XCLOCK_FFS-1:0] s_awvalid_ffs, m_awready_ffs;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awvalid_ffs <= 0;
			m_awready_ffs <= 0;
		end else begin
			s_awvalid_ffs <= {s_awvalid_ffs[XCLOCK_FFS-2:0], S_AXI_AWVALID};
			m_awready_ffs <= {m_awready_ffs[XCLOCK_FFS-2:0], m_awready_reg};
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_awready_reg <= 0;
			m_awvalid_reg <= 0;
		end else begin
			s_awready_reg <= m_awready_ffs[XCLOCK_FFS-1];
			m_awvalid_reg <= s_awvalid_ffs[XCLOCK_FFS-1];
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_awid_reg <= 0;
			m_awaddr_reg <= 0;
			m_awlen_reg <= 0;
			m_awsize_reg <= 0;
			m_awburst_reg <= 0;
			m_awlock_reg <= 0;
			m_awcache_reg <= 0;
			m_awprot_reg <= 0;
			m_awqos_reg <= 0;
		end else if (m_awvalid_reg && m_awready_reg) begin
			m_awid_reg <= S_AXI_AWID;
			m_awaddr_reg <= S_AXI_AWADDR;
			m_awlen_reg <= S_AXI_AWLEN;
			m_awsize_reg <= S_AXI_AWSIZE;
			m_awburst_reg <= S_AXI_AWBURST;
			m_awlock_reg <= S_AXI_AWLOCK;
			m_awcache_reg <= S_AXI_AWCACHE;
			m_awprot_reg <= S_AXI_AWPROT;
			m_awqos_reg <= S_AXI_AWQOS;
		end
	end

	assign S_AXI_AWREADY = s_awready_reg;
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

	// Clock domain crossing for W channel
	reg [XCLOCK_FFS-1:0] s_wvalid_ffs, m_wready_ffs;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wvalid_ffs <= 0;
			m_wready_ffs <= 0;
		end else begin
			s_wvalid_ffs <= {s_wvalid_ffs[XCLOCK_FFS-2:0], S_AXI_WVALID};
			m_wready_ffs <= {m_wready_ffs[XCLOCK_FFS-2:0], m_wready_reg};
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_wready_reg <= 0;
			m_wvalid_reg <= 0;
		end else begin
			s_wready_reg <= m_wready_ffs[XCLOCK_FFS-1];
			m_wvalid_reg <= s_wvalid_ffs[XCLOCK_FFS-1];
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_wdata_reg <= 0;
			m_wstrb_reg <= 0;
			m_wlast_reg <= 0;
		end else if (m_wvalid_reg && m_wready_reg) begin
			m_wdata_reg <= S_AXI_WDATA;
			m_wstrb_reg <= S_AXI_WSTRB;
			m_wlast_reg <= S_AXI_WLAST;
		end
	end

	assign S_AXI_WREADY = s_wready_reg;
	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;

	// Clock domain crossing for B channel
	reg [XCLOCK_FFS-1:0] m_bvalid_ffs, s_bready_ffs;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_bvalid_ffs <= 0;
			s_bready_ffs <= 0;
		end else begin
			m_bvalid_ffs <= {m_bvalid_ffs[XCLOCK_FFS-2:0], M_AXI_BVALID};
			s_bready_ffs <= {s_bready_ffs[XCLOCK_FFS-2:0], s_bready_reg};
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bvalid_reg <= 0;
			m_bready_reg <= 0;
		end else begin
			s_bvalid_reg <= m_bvalid_ffs[XCLOCK_FFS-1];
			m_bready_reg <= s_bready_ffs[XCLOCK_FFS-1];
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid_reg <= 0;
			s_bresp_reg <= 0;
		end else if (s_bvalid_reg && s_bready_reg) begin
			s_bid_reg <= M_AXI_BID;
			s_bresp_reg <= M_AXI_BRESP;
		end
	end

	assign M_AXI_BREADY = m_bready_reg;
	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = s_bvalid_reg;

	// Clock domain crossing for AR channel
	reg [XCLOCK_FFS-1:0] s_arvalid_ffs, m_arready_ffs;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arvalid_ffs <= 0;
			m_arready_ffs <= 0;
		end else begin
			s_arvalid_ffs <= {s_arvalid_ffs[XCLOCK_FFS-2:0], S_AXI_ARVALID};
			m_arready_ffs <= {m_arready_ffs[XCLOCK_FFS-2:0], m_arready_reg};
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			s_arready_reg <= 0;
			m_arvalid_reg <= 0;
		end else begin
			s_arready_reg <= m_arready_ffs[XCLOCK_FFS-1];
			m_arvalid_reg <= s_arvalid_ffs[XCLOCK_FFS-1];
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_arid_reg <= 0;
			m_araddr_reg <= 0;
			m_arlen_reg <= 0;
			m_arsize_reg <= 0;
			m_arburst_reg <= 0;
			m_arlock_reg <= 0;
			m_arcache_reg <= 0;
			m_arprot_reg <= 0;
			m_arqos_reg <= 0;
		end else if (m_arvalid_reg && m_arready_reg) begin
			m_arid_reg <= S_AXI_ARID;
			m_araddr_reg <= S_AXI_ARADDR;
			m_arlen_reg <= S_AXI_ARLEN;
			m_arsize_reg <= S_AXI_ARSIZE;
			m_arburst_reg <= S_AXI_ARBURST;
			m_arlock_reg <= S_AXI_ARLOCK;
			m_arcache_reg <= S_AXI_ARCACHE;
			m_arprot_reg <= S_AXI_ARPROT;
			m_arqos_reg <= S_AXI_ARQOS;
		end
	end

	assign S_AXI_ARREADY = s_arready_reg;
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

	// Clock domain crossing for R channel
	reg [XCLOCK_FFS-1:0] m_rvalid_ffs, s_rready_ffs;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_rvalid_ffs <= 0;
			s_rready_ffs <= 0;
		end else begin
			m_rvalid_ffs <= {m_rvalid_ffs[XCLOCK_FFS-2:0], M_AXI_RVALID};
			s_rready_ffs <= {s_rready_ffs[XCLOCK_FFS-2:0], s_rready_reg};
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rvalid_reg <= 0;
			m_rready_reg <= 0;
		end else begin
			s_rvalid_reg <= m_rvalid_ffs[XCLOCK_FFS-1];
			m_rready_reg <= s_rready_ffs[XCLOCK_FFS-1];
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rid_reg <= 0;
			s_rdata_reg <= 0;
			s_rresp_reg <= 0;
			s_rlast_reg <= 0;
		end else if (s_rvalid_reg && s_rready_reg) begin
			s_rid_reg <= M_AXI_RID;
			s_rdata_reg <= M_AXI_RDATA;
			s_rresp_reg <= M_AXI_RRESP;
			s_rlast_reg <= M_AXI_RLAST;
		end
	end

	assign M_AXI_RREADY = m_rready_reg;
	assign S_AXI_RID = s_rid_reg;
	assign S_AXI_RDATA = s_rdata_reg;
	assign S_AXI_RRESP = s_rresp_reg;
	assign S_AXI_RLAST = s_rlast_reg;
	assign S_AXI_RVALID = s_rvalid_reg;

	// Reset handling
	assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule
