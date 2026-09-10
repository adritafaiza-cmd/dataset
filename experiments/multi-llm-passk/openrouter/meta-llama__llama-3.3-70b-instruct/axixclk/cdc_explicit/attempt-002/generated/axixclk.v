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

	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_ff;
	wire [7 : 0] awlen_ff;
	wire [2 : 0] awsize_ff;
	wire [1 : 0] awburst_ff;
	wire awlock_ff;
	wire [3 : 0] awcache_ff;
	wire [2 : 0] awprot_ff;
	wire [3 : 0] awqos_ff;
	wire awvalid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_ff;
	wire wlast_ff;
	wire wvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_ff;
	wire [1 : 0] bresp_ff;
	wire bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_ff;
	wire [7 : 0] arlen_ff;
	wire [2 : 0] arsize_ff;
	wire [1 : 0] arburst_ff;
	wire arlock_ff;
	wire [3 : 0] arcache_ff;
	wire [2 : 0] arprot_ff;
	wire [3 : 0] arqos_ff;
	wire arvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_ff;
	wire [1 : 0] rresp_ff;
	wire rlast_ff;
	wire rvalid_ff;

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	wire [XCLOCK_FFS-1 : 0] s_axi_aresetn_ff;
	wire [XCLOCK_FFS-1 : 0] m_axi_aresetn_ff;

	always @(posedge S_AXI_ACLK) begin
		s_axi_aresetn_ff[0] <= S_AXI_ARESETN;
		for (int i = 1; i < XCLOCK_FFS; i++) begin
			s_axi_aresetn_ff[i] <= s_axi_aresetn_ff[i-1];
		end
	end

	always @(posedge M_AXI_ACLK) begin
		m_axi_aresetn_ff[0] <= M_AXI_ARESETN;
		for (int i = 1; i < XCLOCK_FFS; i++) begin
			m_axi_aresetn_ff[i] <= m_axi_aresetn_ff[i-1];
		end
	end

	wire s_axi_aresetn_sync = s_axi_aresetn_ff[XCLOCK_FFS-1];
	wire m_axi_aresetn_sync = m_axi_aresetn_ff[XCLOCK_FFS-1];

	wire [LGFIFO-1 : 0] awfifo_empty;
	wire [LGFIFO-1 : 0] awfifo_full;
	wire awfifo_wr;
	wire awfifo_rd;

	wire [LGFIFO-1 : 0] wfifo_empty;
	wire [LGFIFO-1 : 0] wfifo_full;
	wire wfifo_wr;
	wire wfifo_rd;

	wire [LGFIFO-1 : 0] arfifo_empty;
	wire [LGFIFO-1 : 0] arfifo_full;
	wire arfifo_wr;
	wire arfifo_rd;

	wire [LGFIFO-1 : 0] rfifo_empty;
	wire [LGFIFO-1 : 0] rfifo_full;
	wire rfifo_wr;
	wire rfifo_rd;

	wire [LGFIFO-1 : 0] bfifo_empty;
	wire [LGFIFO-1 : 0] bfifo_full;
	wire bfifo_wr;
	wire bfifo_rd;

	always @(posedge S_AXI_ACLK) begin
		if (!s_axi_aresetn_sync) begin
			awid_ff <= 0;
			awaddr_ff <= 0;
			awlen_ff <= 0;
			awsize_ff <= 0;
			awburst_ff <= 0;
			awlock_ff <= 0;
			awcache_ff <= 0;
			awprot_ff <= 0;
			awqos_ff <= 0;
			awvalid_ff <= 0;
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			awid_ff <= S_AXI_AWID;
			awaddr_ff <= S_AXI_AWADDR;
			awlen_ff <= S_AXI_AWLEN;
			awsize_ff <= S_AXI_AWSIZE;
			awburst_ff <= S_AXI_AWBURST;
			awlock_ff <= S_AXI_AWLOCK;
			awcache_ff <= S_AXI_AWCACHE;
			awprot_ff <= S_AXI_AWPROT;
			awqos_ff <= S_AXI_AWQOS;
			awvalid_ff <= 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!s_axi_aresetn_sync) begin
			wdata_ff <= 0;
			wstrb_ff <= 0;
			wlast_ff <= 0;
			wvalid_ff <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!s_axi_aresetn_sync) begin
			bid_ff <= 0;
			bresp_ff <= 0;
			bvalid_ff <= 0;
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!s_axi_aresetn_sync) begin
			arid_ff <= 0;
			araddr_ff <= 0;
			arlen_ff <= 0;
			arsize_ff <= 0;
			arburst_ff <= 0;
			arlock_ff <= 0;
			arcache_ff <= 0;
			arprot_ff <= 0;
			arqos_ff <= 0;
			arvalid_ff <= 0;
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			arid_ff <= S_AXI_ARID;
			araddr_ff <= S_AXI_ARADDR;
			arlen_ff <= S_AXI_ARLEN;
			arsize_ff <= S_AXI_ARSIZE;
			arburst_ff <= S_AXI_ARBURST;
			arlock_ff <= S_AXI_ARLOCK;
			arcache_ff <= S_AXI_ARCACHE;
			arprot_ff <= S_AXI_ARPROT;
			arqos_ff <= S_AXI_ARQOS;
			arvalid_ff <= 1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!s_axi_aresetn_sync) begin
			rid_ff <= 0;
			rdata_ff <= 0;
			rresp_ff <= 0;
			rlast_ff <= 0;
			rvalid_ff <= 0;
		end else if (M_AXI_RVALID && M_AXI_RREADY) begin
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_sync) begin
			M_AXI_AWID <= 0;
			M_AXI_AWADDR <= 0;
			M_AXI_AWLEN <= 0;
			M_AXI_AWSIZE <= 0;
			M_AXI_AWBURST <= 0;
			M_AXI_AWLOCK <= 0;
			M_AXI_AWCACHE <= 0;
			M_AXI_AWPROT <= 0;
			M_AXI_AWQOS <= 0;
			M_AXI_AWVALID <= 0;
		end else if (awvalid_ff &&!awfifo_full) begin
			M_AXI_AWID <= awid_ff;
			M_AXI_AWADDR <= awaddr_ff;
			M_AXI_AWLEN <= awlen_ff;
			M_AXI_AWSIZE <= awsize_ff;
			M_AXI_AWBURST <= awburst_ff;
			M_AXI_AWLOCK <= awlock_ff;
			M_AXI_AWCACHE <= awcache_ff;
			M_AXI_AWPROT <= awprot_ff;
			M_AXI_AWQOS <= awqos_ff;
			M_AXI_AWVALID <= 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_sync) begin
			M_AXI_WDATA <= 0;
			M_AXI_WSTRB <= 0;
			M_AXI_WLAST <= 0;
			M_AXI_WVALID <= 0;
		end else if (wvalid_ff &&!wfifo_full) begin
			M_AXI_WDATA <= wdata_ff;
			M_AXI_WSTRB <= wstrb_ff;
			M_AXI_WLAST <= wlast_ff;
			M_AXI_WVALID <= 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_sync) begin
			M_AXI_BREADY <= 0;
		end else if (bfifo_empty) begin
			M_AXI_BREADY <= 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_sync) begin
			M_AXI_ARID <= 0;
			M_AXI_ARADDR <= 0;
			M_AXI_ARLEN <= 0;
			M_AXI_ARSIZE <= 0;
			M_AXI_ARBURST <= 0;
			M_AXI_ARLOCK <= 0;
			M_AXI_ARCACHE <= 0;
			M_AXI_ARPROT <= 0;
			M_AXI_ARQOS <= 0;
			M_AXI_ARVALID <= 0;
		end else if (arvalid_ff &&!arfifo_full) begin
			M_AXI_ARID <= arid_ff;
			M_AXI_ARADDR <= araddr_ff;
			M_AXI_ARLEN <= arlen_ff;
			M_AXI_ARSIZE <= arsize_ff;
			M_AXI_ARBURST <= arburst_ff;
			M_AXI_ARLOCK <= arlock_ff;
			M_AXI_ARCACHE <= arcache_ff;
			M_AXI_ARPROT <= arprot_ff;
			M_AXI_ARQOS <= arqos_ff;
			M_AXI_ARVALID <= 1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_sync) begin
			M_AXI_RREADY <= 0;
		end else if (rfifo_empty) begin
			M_AXI_RREADY <= 1;
		end
	end

	assign S_AXI_AWREADY =!awfifo_full;
	assign S_AXI_WREADY =!wfifo_full;
	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;
	assign S_AXI_ARREADY =!arfifo_full;
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

	assign awfifo_wr = S_AXI_AWVALID && S_AXI_AWREADY;
	assign awfifo_rd = M_AXI_AWREADY && M_AXI_AWVALID;
	assign wfifo_wr = S_AXI_WVALID && S_AXI_WREADY;
	assign wfifo_rd = M_AXI_WREADY && M_AXI_WVALID;
	assign arfifo_wr = S_AXI_ARVALID && S_AXI_ARREADY;
	assign arfifo_rd = M_AXI_ARREADY && M_AXI_ARVALID;
	assign rfifo_wr = M_AXI_RVALID && M_AXI_RREADY;
	assign rfifo_rd = S_AXI_RREADY && S_AXI_RVALID;
	assign bfifo_wr = M_AXI_BVALID && M_AXI_BREADY;
	assign bfifo_rd = S_AXI_BREADY && S_AXI_BVALID;

endmodule
