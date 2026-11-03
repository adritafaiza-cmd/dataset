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
	reg [C_S_AXI_ID_WIDTH-1 : 0] s_awid_reg, m_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr_reg, m_awaddr_reg;
	reg [7 : 0] s_awlen_reg, m_awlen_reg;
	reg [2 : 0] s_awsize_reg, m_awsize_reg;
	reg [1 : 0] s_awburst_reg, m_awburst_reg;
	reg s_awlock_reg, m_awlock_reg;
	reg [3 : 0] s_awcache_reg, m_awcache_reg;
	reg [2 : 0] s_awprot_reg, m_awprot_reg;
	reg [3 : 0] s_awqos_reg, m_awqos_reg;
	reg s_awvalid_reg, m_awvalid_reg;
	reg s_awready_reg, m_awready_reg;

	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata_reg, m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_reg, m_wstrb_reg;
	reg s_wlast_reg, m_wlast_reg;
	reg s_wvalid_reg, m_wvalid_reg;
	reg s_wready_reg, m_wready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_reg, m_bid_reg;
	reg [1 : 0] s_bresp_reg, m_bresp_reg;
	reg s_bvalid_reg, m_bvalid_reg;
	reg s_bready_reg, m_bready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_arid_reg, m_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr_reg, m_araddr_reg;
	reg [7 : 0] s_arlen_reg, m_arlen_reg;
	reg [2 : 0] s_arsize_reg, m_arsize_reg;
	reg [1 : 0] s_arburst_reg, m_arburst_reg;
	reg s_arlock_reg, m_arlock_reg;
	reg [3 : 0] s_arcache_reg, m_arcache_reg;
	reg [2 : 0] s_arprot_reg, m_arprot_reg;
	reg [3 : 0] s_arqos_reg, m_arqos_reg;
	reg s_arvalid_reg, m_arvalid_reg;
	reg s_arready_reg, m_arready_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_reg, m_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_reg, m_rdata_reg;
	reg [1 : 0] s_rresp_reg, m_rresp_reg;
	reg s_rlast_reg, m_rlast_reg;
	reg s_rvalid_reg, m_rvalid_reg;
	reg s_rready_reg, m_rready_reg;

	// FIFOs for AW, W, B, AR, R channels
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_fifo_out;
	wire [7 : 0] awlen_fifo_out;
	wire [2 : 0] awsize_fifo_out;
	wire [1 : 0] awburst_fifo_out;
	wire awlock_fifo_out;
	wire [3 : 0] awcache_fifo_out;
	wire [2 : 0] awprot_fifo_out;
	wire [3 : 0] awqos_fifo_out;
	wire awvalid_fifo_out;
	wire awready_fifo_in;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_fifo_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_fifo_out;
	wire wlast_fifo_out;
	wire wvalid_fifo_out;
	wire wready_fifo_in;

	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_fifo_out;
	wire [1 : 0] bresp_fifo_out;
	wire bvalid_fifo_out;
	wire bready_fifo_in;

	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_fifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_fifo_out;
	wire [7 : 0] arlen_fifo_out;
	wire [2 : 0] arsize_fifo_out;
	wire [1 : 0] arburst_fifo_out;
	wire arlock_fifo_out;
	wire [3 : 0] arcache_fifo_out;
	wire [2 : 0] arprot_fifo_out;
	wire [3 : 0] arqos_fifo_out;
	wire arvalid_fifo_out;
	wire arready_fifo_in;

	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_fifo_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_fifo_out;
	wire [1 : 0] rresp_fifo_out;
	wire rlast_fifo_out;
	wire rvalid_fifo_out;
	wire rready_fifo_in;

	// AW Channel FIFO
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(s_awvalid_reg & s_awready_reg),
		.rd_en(m_awready_reg & m_awvalid_reg),
		.din({s_awid_reg, s_awaddr_reg, s_awlen_reg, s_awsize_reg, s_awburst_reg, s_awlock_reg, s_awcache_reg, s_awprot_reg, s_awqos_reg}),
		.dout({awid_fifo_out, awaddr_fifo_out, awlen_fifo_out, awsize_fifo_out, awburst_fifo_out, awlock_fifo_out, awcache_fifo_out, awprot_fifo_out, awqos_fifo_out}),
		.full(),
		.empty(m_awvalid_reg),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(s_awready_reg),
		.rd_ack(m_awready_reg)
	);

	// W Channel FIFO
	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 + 1),
		.DEPTH(1 << LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(s_wvalid_reg & s_wready_reg),
		.rd_en(m_wready_reg & m_wvalid_reg),
		.din({s_wdata_reg, s_wstrb_reg, s_wlast_reg, s_wvalid_reg}),
		.dout({wdata_fifo_out, wstrb_fifo_out, wlast_fifo_out, wvalid_fifo_out}),
		.full(),
		.empty(m_wvalid_reg),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(s_wready_reg),
		.rd_ack(m_wready_reg)
	);

	// B Channel FIFO
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(m_bvalid_reg & m_bready_reg),
		.rd_en(s_bready_reg & s_bvalid_reg),
		.din({m_bid_reg, m_bresp_reg, m_bvalid_reg}),
		.dout({bid_fifo_out, bresp_fifo_out, bvalid_fifo_out}),
		.full(),
		.empty(s_bvalid_reg),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(m_bready_reg),
		.rd_ack(s_bready_reg)
	);

	// AR Channel FIFO
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(s_arvalid_reg & s_arready_reg),
		.rd_en(m_arready_reg & m_arvalid_reg),
		.din({s_arid_reg, s_araddr_reg, s_arlen_reg, s_arsize_reg, s_arburst_reg, s_arlock_reg, s_arcache_reg, s_arprot_reg, s_arqos_reg}),
		.dout({arid_fifo_out, araddr_fifo_out, arlen_fifo_out, arsize_fifo_out, arburst_fifo_out, arlock_fifo_out, arcache_fifo_out, arprot_fifo_out, arqos_fifo_out}),
		.full(),
		.empty(m_arvalid_reg),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(s_arready_reg),
		.rd_ack(m_arready_reg)
	);

	// R Channel FIFO
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 + 1),
		.DEPTH(1 << LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.rst(!S_AXI_ARESETN),
		.wr_en(m_rvalid_reg & m_rready_reg),
		.rd_en(s_rready_reg & s_rvalid_reg),
		.din({m_rid_reg, m_rdata_reg, m_rresp_reg, m_rlast_reg, m_rvalid_reg}),
		.dout({rid_fifo_out, rdata_fifo_out, rresp_fifo_out, rlast_fifo_out, rvalid_fifo_out}),
		.full(),
		.empty(s_rvalid_reg),
		.wr_rst_busy(),
		.rd_rst_busy(),
		.wr_ack(m_rready_reg),
		.rd_ack(s_rready_reg)
	);

	// AW Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awid_reg <= 0;
			s_awaddr_reg <= 0;
			s_awlen_reg <= 0;
			s_awsize_reg <= 0;
			s_awburst_reg <= 0;
			s_awlock_reg <= 0;
			s_awcache_reg <= 0;
			s_awprot_reg <= 0;
			s_awqos_reg <= 0;
			s_awvalid_reg <= 0;
		end else begin
			if (s_awready_reg) begin
				s_awid_reg <= S_AXI_AWID;
				s_awaddr_reg <= S_AXI_AWADDR;
				s_awlen_reg <= S_AXI_AWLEN;
				s_awsize_reg <= S_AXI_AWSIZE;
				s_awburst_reg <= S_AXI_AWBURST;
				s_awlock_reg <= S_AXI_AWLOCK;
				s_awcache_reg <= S_AXI_AWCACHE;
				s_awprot_reg <= S_AXI_AWPROT;
				s_awqos_reg <= S_AXI_AWQOS;
				s_awvalid_reg <= S_AXI_AWVALID;
			end
		end
	end

	assign S_AXI_AWREADY = awready_fifo_in;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_awid_reg <= 0;
			m_awaddr_reg <= 0;
			m_awlen_reg <= 0;
			m_awsize_reg <= 0;
			m_awburst_reg <= 0;
			m_awlock_reg <= 0;
			m_awcache_reg <= 0;
			m_awprot_reg <= 0;
			m_awqos_reg <= 0;
			m_awvalid_reg <= 0;
		end else begin
			if (m_awready_reg) begin
				m_awid_reg <= awid_fifo_out;
				m_awaddr_reg <= awaddr_fifo_out;
				m_awlen_reg <= awlen_fifo_out;
				m_awsize_reg <= awsize_fifo_out;
				m_awburst_reg <= awburst_fifo_out;
				m_awlock_reg <= awlock_fifo_out;
				m_awcache_reg <= awcache_fifo_out;
				m_awprot_reg <= awprot_fifo_out;
				m_awqos_reg <= awqos_fifo_out;
				m_awvalid_reg <= awvalid_fifo_out;
			end
		end
	end

	assign m_awready_reg = M_AXI_AWREADY;

	// W Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wdata_reg <= 0;
			s_wstrb_reg <= 0;
			s_wlast_reg <= 0;
			s_wvalid_reg <= 0;
		end else begin
			if (s_wready_reg) begin
				s_wdata_reg <= S_AXI_WDATA;
				s_wstrb_reg <= S_AXI_WSTRB;
				s_wlast_reg <= S_AXI_WLAST;
				s_wvalid_reg <= S_AXI_WVALID;
			end
		end
	end

	assign S_AXI_WREADY = wready_fifo_in;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_wdata_reg <= 0;
			m_wstrb_reg <= 0;
			m_wlast_reg <= 0;
			m_wvalid_reg <= 0;
		end else begin
			if (m_wready_reg) begin
				m_wdata_reg <= wdata_fifo_out;
				m_wstrb_reg <= wstrb_fifo_out;
				m_wlast_reg <= wlast_fifo_out;
				m_wvalid_reg <= wvalid_fifo_out;
			end
		end
	end

	assign m_wready_reg = M_AXI_WREADY;

	// B Channel
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_bid_reg <= 0;
			m_bresp_reg <= 0;
			m_bvalid_reg <= 0;
		end else begin
			if (m_bready_reg) begin
				m_bid_reg <= M_AXI_BID;
				m_bresp_reg <= M_AXI_BRESP;
				m_bvalid_reg <= M_AXI_BVALID;
			end
		end
	end

	assign M_AXI_BREADY = bready_fifo_in;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid_reg <= 0;
			s_bresp_reg <= 0;
			s_bvalid_reg <= 0;
		end else begin
			if (s_bready_reg) begin
				s_bid_reg <= bid_fifo_out;
				s_bresp_reg <= bresp_fifo_out;
				s_bvalid_reg <= bvalid_fifo_out;
			end
		end
	end

	assign s_bready_reg = S_AXI_BREADY;

	// AR Channel
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arid_reg <= 0;
			s_araddr_reg <= 0;
			s_arlen_reg <= 0;
			s_arsize_reg <= 0;
			s_arburst_reg <= 0;
			s_arlock_reg <= 0;
			s_arcache_reg <= 0;
			s_arprot_reg <= 0;
			s_arqos_reg <= 0;
			s_arvalid_reg <= 0;
		end else begin
			if (s_arready_reg) begin
				s_arid_reg <= S_AXI_ARID;
				s_araddr_reg <= S_AXI_ARADDR;
				s_arlen_reg <= S_AXI_ARLEN;
				s_arsize_reg <= S_AXI_ARSIZE;
				s_arburst_reg <= S_AXI_ARBURST;
				s_arlock_reg <= S_AXI_ARLOCK;
				s_arcache_reg <= S_AXI_ARCACHE;
				s_arprot_reg <= S_AXI_ARPROT;
				s_arqos_reg <= S_AXI_ARQOS;
				s_arvalid_reg <= S_AXI_ARVALID;
			end
		end
	end

	assign S_AXI_ARREADY = arready_fifo_in;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_arid_reg <= 0;
			m_araddr_reg <= 0;
			m_arlen_reg <= 0;
			m_arsize_reg <= 0;
			m_arburst_reg <= 0;
			m_arlock_reg <= 0;
			m_arcache_reg <= 0;
			m_arprot_reg <= 0;
			m_arqos_reg <= 0;
			m_arvalid_reg <= 0;
		end else begin
			if (m_arready_reg) begin
				m_arid_reg <= arid_fifo_out;
				m_araddr_reg <= araddr_fifo_out;
				m_arlen_reg <= arlen_fifo_out;
				m_arsize_reg <= arsize_fifo_out;
				m_arburst_reg <= arburst_fifo_out;
				m_arlock_reg <= arlock_fifo_out;
				m_arcache_reg <= arcache_fifo_out;
				m_arprot_reg <= arprot_fifo_out;
				m_arqos_reg <= arqos_fifo_out;
				m_arvalid_reg <= arvalid_fifo_out;
			end
		end
	end

	assign m_arready_reg = M_AXI_ARREADY;

	// R Channel
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_rid_reg <= 0;
			m_rdata_reg <= 0;
			m_rresp_reg <= 0;
			m_rlast_reg <= 0;
			m_rvalid_reg <= 0;
		end else begin
			if (m_rready_reg) begin
				m_rid_reg <= M_AXI_RID;
				m_rdata_reg <= M_AXI_RDATA;
				m_rresp_reg <= M_AXI_RRESP;
				m_rlast_reg <= M_AXI_RLAST;
				m_rvalid_reg <= M_AXI_RVALID;
			end
		end
	end

	assign M_AXI_RREADY = rready_fifo_in;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rid_reg <= 0;
			s_rdata_reg <= 0;
			s_rresp_reg <= 0;
			s_rlast_reg <= 0;
			s_rvalid_reg <= 0;
		end else begin
			if (s_rready_reg) begin
				s_rid_reg <= rid_fifo_out;
				s_rdata_reg <= rdata_fifo_out;
				s_rresp_reg <= rresp_fifo_out;
				s_rlast_reg <= rlast_fifo_out;
				s_rvalid_reg <= rvalid_fifo_out;
			end
		end
	end

	assign s_rready_reg = S_AXI_RREADY;

	// Output assignments
	assign S_AXI_AWREADY = awready_fifo_in;
	assign S_AXI_WREADY = wready_fifo_in;
	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = s_bvalid_reg;
	assign S_AXI_ARREADY = arready_fifo_in;
	assign S_AXI_RID = s_rid_reg;
	assign S_AXI_RDATA = s_rdata_reg;
	assign S_AXI_RRESP = s_rresp_reg;
	assign S_AXI_RLAST = s_rlast_reg;
	assign S_AXI_RVALID = s_rvalid_reg;

	assign M_AXI_ARESETN = S_AXI_ARESETN;
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
	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;
	assign M_AXI_BREADY = bready_fifo_in;
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
	assign M_AXI_RREADY = rready_fifo_in;

endmodule

// FIFO module
module fifo #(
	parameter WIDTH = 8,
	parameter DEPTH = 16
) (
	input wire clk,
	input wire rst,
	input wire wr_en,
	input wire rd_en,
	input wire [WIDTH-1:0] din,
	output reg [WIDTH-1:0] dout,
	output reg full,
	output reg empty,
	output reg wr_rst_busy,
	output reg rd_rst_busy,
	output reg wr_ack,
	output reg rd_ack
);

	localparam ADDR_WIDTH = $clog2(DEPTH);
	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			full <= 0;
			empty <= 1;
			wr_rst_busy <= 1;
			rd_rst_busy <= 1;
			wr_ack <= 0;
			rd_ack <= 0;
		end else begin
			wr_rst_busy <= 0;
			rd_rst_busy <= 0;

			if (wr_en && !full) begin
				mem[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				wr_ack <= 1;
				if (wr_ptr == rd_ptr - 1) begin
					full <= 1;
				end
				empty <= 0;
			end else begin
				wr_ack <= 0;
			end

			if (rd_en && !empty) begin
				dout <= mem[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				rd_ack <= 1;
				if (rd_ptr == wr_ptr) begin
					empty <= 1;
				end
				full <= 0;
			end else begin
				rd_ack <= 0;
			end
		end
	end

	assign awready_fifo_in = !full;
	assign arready_fifo_in = !empty;

endmodule
