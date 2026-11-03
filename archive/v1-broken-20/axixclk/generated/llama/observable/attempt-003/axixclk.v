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
wire				awfifo_almost_empty;
wire				awfifo_almost_full;
wire				wfifo_empty;
wire				wfifo_full;
wire				wfifo_almost_empty;
wire				wfifo_almost_full;
wire				bfifo_empty;
wire				bfifo_full;
wire				bfifo_almost_empty;
wire				bfifo_almost_full;
wire				arfifo_empty;
wire				arfifo_full;
wire				arfifo_almost_empty;
wire				arfifo_almost_full;
wire				rfifo_empty;
wire				rfifo_full;
wire				rfifo_almost_empty;
wire				rfifo_almost_full;

// AXI Write Channel
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		awvalid_reg <= 1'b0;
		awready_reg <= 1'b0;
	end else begin
		if (S_AXI_AWVALID && awready_reg) begin
			awid_reg <= S_AXI_AWID;
			awaddr_reg <= S_AXI_AWADDR;
			awlen_reg <= S_AXI_AWLEN;
			awsize_reg <= S_AXI_AWSIZE;
			awburst_reg <= S_AXI_AWBURST;
			awlock_reg <= S_AXI_AWLOCK;
			awcache_reg <= S_AXI_AWCACHE;
			awprot_reg <= S_AXI_AWPROT;
			awqos_reg <= S_AXI_AWQOS;
			awvalid_reg <= 1'b1;
		end
		if (awvalid_reg && awfifo_almost_full) begin
			awready_reg <= 1'b0;
		end else if (!awvalid_reg) begin
			awready_reg <= 1'b1;
		end
	end
end

// AXI Write Data Channel
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		wvalid_reg <= 1'b0;
		wready_reg <= 1'b0;
	end else begin
		if (S_AXI_WVALID && wready_reg) begin
			wdata_reg <= S_AXI_WDATA;
			wstrb_reg <= S_AXI_WSTRB;
			wlast_reg <= S_AXI_WLAST;
			wvalid_reg <= 1'b1;
		end
		if (wvalid_reg && wfifo_almost_full) begin
			wready_reg <= 1'b0;
		end else if (!wvalid_reg) begin
			wready_reg <= 1'b1;
		end
	end
end

// AXI Write Response Channel
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		bvalid_reg <= 1'b0;
		bready_reg <= 1'b0;
	end else begin
		if (M_AXI_BVALID && bready_reg) begin
			bid_reg <= M_AXI_BID;
			bresp_reg <= M_AXI_BRESP;
			bvalid_reg <= 1'b1;
		end
		if (bvalid_reg && bfifo_almost_full) begin
			bready_reg <= 1'b0;
		end else if (!bvalid_reg) begin
			bready_reg <= 1'b1;
		end
	end
end

// AXI Read Channel
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		arvalid_reg <= 1'b0;
		arready_reg <= 1'b0;
	end else begin
		if (S_AXI_ARVALID && arready_reg) begin
			arid_reg <= S_AXI_ARID;
			araddr_reg <= S_AXI_ARADDR;
			arlen_reg <= S_AXI_ARLEN;
			arsize_reg <= S_AXI_ARSIZE;
			arburst_reg <= S_AXI_ARBURST;
			arlock_reg <= S_AXI_ARLOCK;
			arcache_reg <= S_AXI_ARCACHE;
			arprot_reg <= S_AXI_ARPROT;
			arqos_reg <= S_AXI_ARQOS;
			arvalid_reg <= 1'b1;
		end
		if (arvalid_reg && arfifo_almost_full) begin
			arready_reg <= 1'b0;
		end else if (!arvalid_reg) begin
			arready_reg <= 1'b1;
		end
	end
end

// AXI Read Data Channel
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		rvalid_reg <= 1'b0;
		rready_reg <= 1'b0;
	end else begin
		if (M_AXI_RVALID && rready_reg) begin
			rid_reg <= M_AXI_RID;
			rdata_reg <= M_AXI_RDATA;
			rresp_reg <= M_AXI_RRESP;
			rlast_reg <= M_AXI_RLAST;
			rvalid_reg <= 1'b1;
		end
		if (rvalid_reg && rfifo_almost_full) begin
			rready_reg <= 1'b0;
		end else if (!rvalid_reg) begin
			rready_reg <= 1'b1;
		end
	end
end

// AXI Master Write Channel
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
	if (!M_AXI_ARESETN) begin
		m_axi_awvalid_reg <= 1'b0;
		m_axi_awready_reg <= 1'b0;
	end else begin
		if (awvalid_reg && awfifo_empty) begin
			m_axi_awid_reg <= awid_reg;
			m_axi_awaddr_reg <= awaddr_reg;
			m_axi_awlen_reg <= awlen_reg;
			m_axi_awsize_reg <= awsize_reg;
			m_axi_awburst_reg <= awburst_reg;
			m_axi_awlock_reg <= awlock_reg;
			m_axi_awcache_reg <= awcache_reg;
			m_axi_awprot_reg <= awprot_reg;
			m_axi_awqos_reg <= awqos_reg;
			m_axi_awvalid_reg <= 1'b1;
		end
		if (m_axi_awvalid_reg && M_AXI_AWREADY) begin
			m_axi_awvalid_reg <= 1'b0;
		end
	end
end

// AXI Master Write Data Channel
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
	if (!M_AXI_ARESETN) begin
		m_axi_wvalid_reg <= 1'b0;
		m_axi_wready_reg <= 1'b0;
	end else begin
		if (wvalid_reg && wfifo_empty) begin
			m_axi_wdata_reg <= wdata_reg;
			m_axi_wstrb_reg <= wstrb_reg;
			m_axi_wlast_reg <= wlast_reg;
			m_axi_wvalid_reg <= 1'b1;
		end
		if (m_axi_wvalid_reg && M_AXI_WREADY) begin
			m_axi_wvalid_reg <= 1'b0;
		end
	end
end

// AXI Master Write Response Channel
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
	if (!M_AXI_ARESETN) begin
		m_axi_bready_reg <= 1'b0;
	end else begin
		if (M_AXI_BVALID && bfifo_empty) begin
			m_axi_bid_reg <= M_AXI_BID;
			m_axi_bresp_reg <= M_AXI_BRESP;
			m_axi_bready_reg <= 1'b1;
		end
		if (m_axi_bready_reg && M_AXI_BVALID) begin
			m_axi_bready_reg <= 1'b0;
		end
	end
end

// AXI Master Read Channel
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
	if (!M_AXI_ARESETN) begin
		m_axi_arvalid_reg <= 1'b0;
		m_axi_arready_reg <= 1'b0;
	end else begin
		if (arvalid_reg && arfifo_empty) begin
			m_axi_arid_reg <= arid_reg;
			m_axi_araddr_reg <= araddr_reg;
			m_axi_arlen_reg <= arlen_reg;
			m_axi_arsize_reg <= arsize_reg;
			m_axi_arburst_reg <= arburst_reg;
			m_axi_arlock_reg <= arlock_reg;
			m_axi_arcache_reg <= arcache_reg;
			m_axi_arprot_reg <= arprot_reg;
			m_axi_arqos_reg <= arqos_reg;
			m_axi_arvalid_reg <= 1'b1;
		end
		if (m_axi_arvalid_reg && M_AXI_ARREADY) begin
			m_axi_arvalid_reg <= 1'b0;
		end
	end
end

// AXI Master Read Data Channel
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
	if (!M_AXI_ARESETN) begin
		m_axi_rready_reg <= 1'b0;
	end else begin
		if (M_AXI_RVALID && rfifo_empty) begin
			m_axi_rid_reg <= M_AXI_RID;
			m_axi_rdata_reg <= M_AXI_RDATA;
			m_axi_rresp_reg <= M_AXI_RRESP;
			m_axi_rlast_reg <= M_AXI_RLAST;
			m_axi_rready_reg <= 1'b1;
		end
		if (m_axi_rready_reg && M_AXI_RVALID) begin
			m_axi_rready_reg <= 1'b0;
		end
	end
end

// AXI Reset
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
begin
	if (!S_AXI_ARESETN) begin
		m_axi_aresetn_reg <= 1'b0;
	end else begin
		m_axi_aresetn_reg <= 1'b1;
	end
end

// AXI Write Channel FIFO
fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DDEPTH(2**LGFIFO)
	) awfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.we(awvalid_reg && awfifo_empty),
		.wdata({awid_reg, awaddr_reg, awlen_reg, awsize_reg, awburst_reg, awlock_reg, awcache_reg, awprot_reg, awqos_reg}),
		.re(m_axi_awvalid_reg && M_AXI_AWREADY),
		.rdata(),
		.empty(awfifo_empty),
		.full(awfifo_full),
		.almost_empty(awfifo_almost_empty),
		.almost_full(awfifo_almost_full)
	);

// AXI Write Data Channel FIFO
fifo #(
		.DWIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DDEPTH(2**LGFIFO)
	) wfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.we(wvalid_reg && wfifo_empty),
		.wdata({wdata_reg, wstrb_reg, wlast_reg}),
		.re(m_axi_wvalid_reg && M_AXI_WREADY),
		.rdata(),
		.empty(wfifo_empty),
		.full(wfifo_full),
		.almost_empty(wfifo_almost_empty),
		.almost_full(wfifo_almost_full)
	);

// AXI Write Response Channel FIFO
fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + 2),
		.DDEPTH(2**LGFIFO)
	) bfifo (
		.clk(M_AXI_ACLK),
		.rst_n(M_AXI_ARESETN),
		.we(M_AXI_BVALID && bfifo_empty),
		.wdata({M_AXI_BID, M_AXI_BRESP}),
		.re(bvalid_reg && S_AXI_BREADY),
		.rdata(),
		.empty(bfifo_empty),
		.full(bfifo_full),
		.almost_empty(bfifo_almost_empty),
		.almost_full(bfifo_almost_full)
	);

// AXI Read Channel FIFO
fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DDEPTH(2**LGFIFO)
	) arfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.we(arvalid_reg && arfifo_empty),
		.wdata({arid_reg, araddr_reg, arlen_reg, arsize_reg, arburst_reg, arlock_reg, arcache_reg, arprot_reg, arqos_reg}),
		.re(m_axi_arvalid_reg && M_AXI_ARREADY),
		.rdata(),
		.empty(arfifo_empty),
		.full(arfifo_full),
		.almost_empty(arfifo_almost_empty),
		.almost_full(arfifo_almost_full)
	);

// AXI Read Data Channel FIFO
fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DDEPTH(2**LGFIFO)
	) rfifo (
		.clk(M_AXI_ACLK),
		.rst_n(M_AXI_ARESETN),
		.we(M_AXI_RVALID && rfifo_empty),
		.wdata({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.re(rvalid_reg && S_AXI_RREADY),
		.rdata(),
		.empty(rfifo_empty),
		.full(rfifo_full),
		.almost_empty(rfifo_almost_empty),
		.almost_full(rfifo_almost_full)
	);

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
assign M_AXI_ARESETN = m_axi_aresetn_reg;

endmodule

module fifo #(
	parameter integer DWIDTH = 32,
	parameter integer DDEPTH = 16
) (
	input	wire	clk,
	input	wire	rst_n,
	input	wire	we,
	input	wire [DWIDTH-1 : 0]	wdata,
	input	wire	re,
	output	wire [DWIDTH-1 : 0]	rdata,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [DWIDTH-1 : 0]	fifo_reg [DDEPTH-1 : 0];
reg [DDEPTH-1 : 0]	fifo_ptr;
reg [DDEPTH-1 : 0]	fifo_cnt;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		fifo_ptr <= {DDEPTH{1'b0}};
		fifo_cnt <= {DDEPTH{1'b0}};
	end else begin
		if (we && !full) begin
			fifo_reg[fifo_ptr] <= wdata;
			fifo_ptr <= fifo_ptr + 1'b1;
			fifo_cnt <= fifo_cnt + 1'b1;
		end
		if (re && !empty) begin
			fifo_cnt <= fifo_cnt - 1'b1;
			fifo_ptr <= fifo_ptr - 1'b1;
		end
	end
end

assign rdata = fifo_reg[fifo_ptr - 1'b1];
assign empty = (fifo_cnt == {DDEPTH{1'b0}});
assign full = (fifo_cnt == {DDEPTH{1'b1}});
assign almost_empty = (fifo_cnt == {DDEPTH{1'b0}} + 1'b1);
assign almost_full = (fifo_cnt == {DDEPTH{1'b1}} - 1'b1);

endmodule
