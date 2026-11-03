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

reg [C_S_AXI_ID_WIDTH-1 : 0]	awid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_reg;
reg [7 : 0]			awlen_reg;
reg [2 : 0]			awsize_reg;
reg [1 : 0]			awburst_reg;
reg				awlock_reg;
reg [3 : 0]			awcache_reg;
reg [2 : 0]			awprot_reg;
reg [3 : 0]			awqos_reg;
reg				awvalid_reg;
reg				awready_reg;

reg [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_reg;
reg				wlast_reg;
reg				wvalid_reg;
reg				wready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	bid_reg;
reg [1 : 0]			bresp_reg;
reg				bvalid_reg;
reg				bready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	arid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_reg;
reg [7 : 0]			arlen_reg;
reg [2 : 0]			arsize_reg;
reg [1 : 0]			arburst_reg;
reg				arlock_reg;
reg [3 : 0]			arcache_reg;
reg [2 : 0]			arprot_reg;
reg [3 : 0]			arqos_reg;
reg				arvalid_reg;
reg				arready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	rid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_reg;
reg [1 : 0]			rresp_reg;
reg				rlast_reg;
reg				rvalid_reg;
reg				rready_reg;

reg				m_axi_aresetn_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_awid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_awaddr_reg;
reg [7 : 0]			m_axi_awlen_reg;
reg [2 : 0]			m_axi_awsize_reg;
reg [1 : 0]			m_axi_awburst_reg;
reg				m_axi_awlock_reg;
reg [3 : 0]			m_axi_awcache_reg;
reg [2 : 0]			m_axi_awprot_reg;
reg [3 : 0]			m_axi_awqos_reg;
reg				m_axi_awvalid_reg;
reg				m_axi_awready_reg;

reg [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	m_axi_wstrb_reg;
reg				m_axi_wlast_reg;
reg				m_axi_wvalid_reg;
reg				m_axi_wready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_reg;
reg [1 : 0]			m_axi_bresp_reg;
reg				m_axi_bvalid_reg;
reg				m_axi_bready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_arid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_araddr_reg;
reg [7 : 0]			m_axi_arlen_reg;
reg [2 : 0]			m_axi_arsize_reg;
reg [1 : 0]			m_axi_arburst_reg;
reg				m_axi_arlock_reg;
reg [3 : 0]			m_axi_arcache_reg;
reg [2 : 0]			m_axi_arprot_reg;
reg [3 : 0]			m_axi_arqos_reg;
reg				m_axi_arvalid_reg;
reg				m_axi_arready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_reg;
reg [1 : 0]			m_axi_rresp_reg;
reg				m_axi_rlast_reg;
reg				m_axi_rvalid_reg;
reg				m_axi_rready_reg;

wire				awfifo_empty;
wire				awfifo_full;
wire				wfifo_empty;
wire				wfifo_full;
wire				bfifo_empty;
wire				bfifo_full;
wire				arfifo_empty;
wire				arfifo_full;
wire				rfifo_empty;
wire				rfifo_full;

// AW Channel
always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		awid_reg <= 0;
		awaddr_reg <= 0;
		awlen_reg <= 0;
		awsize_reg <= 0;
		awburst_reg <= 0;
		awlock_reg <= 0;
		awcache_reg <= 0;
		awprot_reg <= 0;
		awqos_reg <= 0;
		awvalid_reg <= 0;
		awready_reg <= 0;
	end else if (S_AXI_AWVALID && awready_reg) begin
		awid_reg <= S_AXI_AWID;
		awaddr_reg <= S_AXI_AWADDR;
		awlen_reg <= S_AXI_AWLEN;
		awsize_reg <= S_AXI_AWSIZE;
		awburst_reg <= S_AXI_AWBURST;
		awlock_reg <= S_AXI_AWLOCK;
		awcache_reg <= S_AXI_AWCACHE;
		awprot_reg <= S_AXI_AWPROT;
		awqos_reg <= S_AXI_AWQOS;
		awvalid_reg <= 1;
	end else if (awfifo_full) begin
		awvalid_reg <= 0;
	end
end

always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		m_axi_awid_reg <= 0;
		m_axi_awaddr_reg <= 0;
		m_axi_awlen_reg <= 0;
		m_axi_awsize_reg <= 0;
		m_axi_awburst_reg <= 0;
		m_axi_awlock_reg <= 0;
		m_axi_awcache_reg <= 0;
		m_axi_awprot_reg <= 0;
		m_axi_awqos_reg <= 0;
		m_axi_awvalid_reg <= 0;
	end else if (awvalid_reg && !awfifo_full) begin
		m_axi_awid_reg <= awid_reg;
		m_axi_awaddr_reg <= awaddr_reg;
		m_axi_awlen_reg <= awlen_reg;
		m_axi_awsize_reg <= awsize_reg;
		m_axi_awburst_reg <= awburst_reg;
		m_axi_awlock_reg <= awlock_reg;
		m_axi_awcache_reg <= awcache_reg;
		m_axi_awprot_reg <= awprot_reg;
		m_axi_awqos_reg <= awqos_reg;
		m_axi_awvalid_reg <= 1;
	end else if (M_AXI_AWREADY && m_axi_awvalid_reg) begin
		m_axi_awvalid_reg <= 0;
	end
end

// W Channel
always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		wdata_reg <= 0;
		wstrb_reg <= 0;
		wlast_reg <= 0;
		wvalid_reg <= 0;
		wready_reg <= 0;
	end else if (S_AXI_WVALID && wready_reg) begin
		wdata_reg <= S_AXI_WDATA;
		wstrb_reg <= S_AXI_WSTRB;
		wlast_reg <= S_AXI_WLAST;
		wvalid_reg <= 1;
	end else if (wfifo_full) begin
		wvalid_reg <= 0;
	end
end

always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		m_axi_wdata_reg <= 0;
		m_axi_wstrb_reg <= 0;
		m_axi_wlast_reg <= 0;
		m_axi_wvalid_reg <= 0;
	end else if (wvalid_reg && !wfifo_full) begin
		m_axi_wdata_reg <= wdata_reg;
		m_axi_wstrb_reg <= wstrb_reg;
		m_axi_wlast_reg <= wlast_reg;
		m_axi_wvalid_reg <= 1;
	end else if (M_AXI_WREADY && m_axi_wvalid_reg) begin
		m_axi_wvalid_reg <= 0;
	end
end

// B Channel
always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		m_axi_bid_reg <= 0;
		m_axi_bresp_reg <= 0;
		m_axi_bvalid_reg <= 0;
	end else if (M_AXI_BVALID && !bfifo_full) begin
		m_axi_bid_reg <= M_AXI_BID;
		m_axi_bresp_reg <= M_AXI_BRESP;
		m_axi_bvalid_reg <= 1;
	end else if (m_axi_bvalid_reg && M_AXI_BREADY) begin
		m_axi_bvalid_reg <= 0;
	end
end

always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		bid_reg <= 0;
		bresp_reg <= 0;
		bvalid_reg <= 0;
		bready_reg <= 0;
	end else if (m_axi_bvalid_reg && !bfifo_empty) begin
		bid_reg <= m_axi_bid_reg;
		bresp_reg <= m_axi_bresp_reg;
		bvalid_reg <= 1;
	end else if (bvalid_reg && S_AXI_BREADY) begin
		bvalid_reg <= 0;
	end
end

// AR Channel
always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		arid_reg <= 0;
		araddr_reg <= 0;
		arlen_reg <= 0;
		arsize_reg <= 0;
		arburst_reg <= 0;
		arlock_reg <= 0;
		arcache_reg <= 0;
		arprot_reg <= 0;
		arqos_reg <= 0;
		arvalid_reg <= 0;
		arready_reg <= 0;
	end else if (S_AXI_ARVALID && arready_reg) begin
		arid_reg <= S_AXI_ARID;
		araddr_reg <= S_AXI_ARADDR;
		arlen_reg <= S_AXI_ARLEN;
		arsize_reg <= S_AXI_ARSIZE;
		arburst_reg <= S_AXI_ARBURST;
		arlock_reg <= S_AXI_ARLOCK;
		arcache_reg <= S_AXI_ARCACHE;
		arprot_reg <= S_AXI_ARPROT;
		arqos_reg <= S_AXI_ARQOS;
		arvalid_reg <= 1;
	end else if (arfifo_full) begin
		arvalid_reg <= 0;
	end
end

always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		m_axi_arid_reg <= 0;
		m_axi_araddr_reg <= 0;
		m_axi_arlen_reg <= 0;
		m_axi_arsize_reg <= 0;
		m_axi_arburst_reg <= 0;
		m_axi_arlock_reg <= 0;
		m_axi_arcache_reg <= 0;
		m_axi_arprot_reg <= 0;
		m_axi_arqos_reg <= 0;
		m_axi_arvalid_reg <= 0;
	end else if (arvalid_reg && !arfifo_full) begin
		m_axi_arid_reg <= arid_reg;
		m_axi_araddr_reg <= araddr_reg;
		m_axi_arlen_reg <= arlen_reg;
		m_axi_arsize_reg <= arsize_reg;
		m_axi_arburst_reg <= arburst_reg;
		m_axi_arlock_reg <= arlock_reg;
		m_axi_arcache_reg <= arcache_reg;
		m_axi_arprot_reg <= arprot_reg;
		m_axi_arqos_reg <= arqos_reg;
		m_axi_arvalid_reg <= 1;
	end else if (M_AXI_ARREADY && m_axi_arvalid_reg) begin
		m_axi_arvalid_reg <= 0;
	end
end

// R Channel
always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		m_axi_rid_reg <= 0;
		m_axi_rdata_reg <= 0;
		m_axi_rresp_reg <= 0;
		m_axi_rlast_reg <= 0;
		m_axi_rvalid_reg <= 0;
	end else if (M_AXI_RVALID && !rfifo_full) begin
		m_axi_rid_reg <= M_AXI_RID;
		m_axi_rdata_reg <= M_AXI_RDATA;
		m_axi_rresp_reg <= M_AXI_RRESP;
		m_axi_rlast_reg <= M_AXI_RLAST;
		m_axi_rvalid_reg <= 1;
	end else if (m_axi_rvalid_reg && M_AXI_RREADY) begin
		m_axi_rvalid_reg <= 0;
	end
end

always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		rid_reg <= 0;
		rdata_reg <= 0;
		rresp_reg <= 0;
		rlast_reg <= 0;
		rvalid_reg <= 0;
		rready_reg <= 0;
	end else if (m_axi_rvalid_reg && !rfifo_empty) begin
		rid_reg <= m_axi_rid_reg;
		rdata_reg <= m_axi_rdata_reg;
		rresp_reg <= m_axi_rresp_reg;
		rlast_reg <= m_axi_rlast_reg;
		rvalid_reg <= 1;
	end else if (rvalid_reg && S_AXI_RREADY) begin
		rvalid_reg <= 0;
	end
end

// FIFOs
fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.LGFIFO(LGFIFO)
	) awfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wen(awvalid_reg),
		.wdata({awid_reg, awaddr_reg, awlen_reg, awsize_reg, awburst_reg, awlock_reg, awcache_reg, awprot_reg, awqos_reg}),
		.full(awfifo_full),
		.empty(awfifo_empty),
		.ren(1'b1),
		.rdata()
	);

fifo #(
		.DWIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.LGFIFO(LGFIFO)
	) wfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wen(wvalid_reg),
		.wdata({wdata_reg, wstrb_reg, wlast_reg}),
		.full(wfifo_full),
		.empty(wfifo_empty),
		.ren(1'b1),
		.rdata()
	);

fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + 2),
		.LGFIFO(LGFIFO)
	) bfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wen(m_axi_bvalid_reg),
		.wdata({m_axi_bid_reg, m_axi_bresp_reg}),
		.full(bfifo_full),
		.empty(bfifo_empty),
		.ren(1'b1),
		.rdata()
	);

fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.LGFIFO(LGFIFO)
	) arfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wen(arvalid_reg),
		.wdata({arid_reg, araddr_reg, arlen_reg, arsize_reg, arburst_reg, arlock_reg, arcache_reg, arprot_reg, arqos_reg}),
		.full(arfifo_full),
		.empty(arfifo_empty),
		.ren(1'b1),
		.rdata()
	);

fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.LGFIFO(LGFIFO)
	) rfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wen(m_axi_rvalid_reg),
		.wdata({m_axi_rid_reg, m_axi_rdata_reg, m_axi_rresp_reg, m_axi_rlast_reg}),
		.full(rfifo_full),
		.empty(rfifo_empty),
		.ren(1'b1),
		.rdata()
	);

// Outputs
assign S_AXI_AWREADY = awready_reg;
assign S_AXI_WREADY = wready_reg;
assign S_AXI_BID = bid_reg;
assign S_AXI_BRESP = bresp_reg;
assign S_AXI_BVALID = bvalid_reg;
assign S_AXI_ARREADY = arready_reg;
assign S_AXI_RID = rid_reg;
assign S_AXI_RDATA = rdata_reg;
assign S_AXI_RRESP = rresp_reg;
assign S_AXI_RLAST = rlast_reg;
assign S_AXI_RVALID = rvalid_reg;

assign M_AXI_ARESETN = m_axi_aresetn_reg;
assign M_AXI_AWID = m_axi_awid_reg;
assign M_AXI_AWADDR = m_axi_awaddr_reg;
assign M_AXI_AWLEN = m_axi_awlen_reg;
assign M_AXI_AWSIZE = m_axi_awsize_reg;
assign M_AXI_AWBURST = m_axi_awburst_reg;
assign M_AXI_AWLOCK = m_axi_awlock_reg;
assign M_AXI_AWCACHE = m_axi_awcache_reg;
assign M_AXI_AWPROT = m_axi_awprot_reg;
assign M_AXI_AWQOS = m_axi_awqos_reg;
assign M_AXI_AWVALID = m_axi_awvalid_reg;
assign M_AXI_WDATA = m_axi_wdata_reg;
assign M_AXI_WSTRB = m_axi_wstrb_reg;
assign M_AXI_WLAST = m_axi_wlast_reg;
assign M_AXI_WVALID = m_axi_wvalid_reg;
assign M_AXI_BREADY = m_axi_bready_reg;
assign M_AXI_ARID = m_axi_arid_reg;
assign M_AXI_ARADDR = m_axi_araddr_reg;
assign M_AXI_ARLEN = m_axi_arlen_reg;
assign M_AXI_ARSIZE = m_axi_arsize_reg;
assign M_AXI_ARBURST = m_axi_arburst_reg;
assign M_AXI_ARLOCK = m_axi_arlock_reg;
assign M_AXI_ARCACHE = m_axi_arcache_reg;
assign M_AXI_ARPROT = m_axi_arprot_reg;
assign M_AXI_ARQOS = m_axi_arqos_reg;
assign M_AXI_ARVALID = m_axi_arvalid_reg;
assign M_AXI_RREADY = m_axi_rready_reg;

// Reset
always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		m_axi_aresetn_reg <= 0;
	end else begin
		m_axi_aresetn_reg <= 1;
	end
end

endmodule

module fifo #(
	parameter integer DWIDTH = 32,
	parameter integer LGFIFO = 5
) (
	input	wire				clk,
	input	wire				rst_n,
	input	wire				wen,
	input	wire [DWIDTH-1 : 0]	wdata,
	output	wire				full,
	output	wire				empty,
	input	wire				ren,
	output	wire [DWIDTH-1 : 0]	rdata
);

reg [DWIDTH-1 : 0]	fifo_reg [2**LGFIFO-1 : 0];
reg [LGFIFO-1 : 0]	wptr_reg;
reg [LGFIFO-1 : 0]	rptr_reg;
reg [LGFIFO : 0]		count_reg;

always @(posedge clk) begin
	if (!rst_n) begin
		wptr_reg <= 0;
		rptr_reg <= 0;
		count_reg <= 0;
	end else if (wen && !full) begin
		fifo_reg[wptr_reg] <= wdata;
		wptr_reg <= wptr_reg + 1;
		count_reg <= count_reg + 1;
	end else if (ren && !empty) begin
		rptr_reg <= rptr_reg + 1;
		count_reg <= count_reg - 1;
	end
end

assign full = (count_reg == 2**LGFIFO);
assign empty = (count_reg == 0);
assign rdata = fifo_reg[rptr_reg];

endmodule
