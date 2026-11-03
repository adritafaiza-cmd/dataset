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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_ff;
	wire [7 : 0]			awlen_ff;
	wire [2 : 0]			awsize_ff;
	wire [1 : 0]			awburst_ff;
	wire				awlock_ff;
	wire [3 : 0]			awcache_ff;
	wire [2 : 0]			awprot_ff;
	wire [3 : 0]			awqos_ff;
	wire				awvalid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff;
	wire				wlast_ff;
	wire				wvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_ff;
	wire [7 : 0]			arlen_ff;
	wire [2 : 0]			arsize_ff;
	wire [1 : 0]			arburst_ff;
	wire				arlock_ff;
	wire [3 : 0]			arcache_ff;
	wire [2 : 0]			arprot_ff;
	wire [3 : 0]			arqos_ff;
	wire				arvalid_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;

	wire				m_axi_aresetn_ff;

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;
	wire				rready_ff;

	wire				m_axi_awready_ff;
	wire				m_axi_wready_ff;
	wire				m_axi_arready_ff;
	wire				m_axi_rready_ff;

	wire				m_axi_bvalid_ff;
	wire				m_axi_bready_ff;

	wire				m_axi_awvalid_ff;
	wire				m_axi_wvalid_ff;
	wire				m_axi_arvalid_ff;
	wire				m_axi_rvalid_ff;

	wire				m_axi_awid_ff;
	wire				m_axi_awaddr_ff;
	wire				m_axi_awlen_ff;
	wire				m_axi_awsize_ff;
	wire				m_axi_awburst_ff;
	wire				m_axi_awlock_ff;
	wire				m_axi_awcache_ff;
	wire				m_axi_awprot_ff;
	wire				m_axi_awqos_ff;

	wire				m_axi_wdata_ff;
	wire				m_axi_wstrb_ff;
	wire				m_axi_wlast_ff;

	wire				m_axi_arid_ff;
	wire				m_axi_araddr_ff;
	wire				m_axi_arlen_ff;
	wire				m_axi_arsize_ff;
	wire				m_axi_arburst_ff;
	wire				m_axi_arlock_ff;
	wire				m_axi_arcache_ff;
	wire				m_axi_arprot_ff;
	wire				m_axi_arqos_ff;

	wire				m_axi_bid_ff;
	wire				m_axi_bresp_ff;

	wire				m_axi_rid_ff;
	wire				m_axi_rdata_ff;
	wire				m_axi_rresp_ff;
	wire				m_axi_rlast_ff;

	reg [XCLOCK_FFS-1 : 0]	clk_ff;
	reg [XCLOCK_FFS-1 : 0]	clk_sync;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			clk_ff <= 0;
			clk_sync <= 0;
		end else begin
			clk_ff <= clk_ff + 1;
			clk_sync <= clk_ff;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_ff) begin
			m_axi_aresetn_ff <= 1'b0;
		end else begin
			m_axi_aresetn_ff <= 1'b1;
		end
	end

	assign M_AXI_ARESETN = m_axi_aresetn_ff;

	wire [LGFIFO-1 : 0]	awfifo_cnt;
	wire				awfifo_empty;
	wire				awfifo_full;

	wire [LGFIFO-1 : 0]	wfifo_cnt;
	wire				wfifo_empty;
	wire				wfifo_full;

	wire [LGFIFO-1 : 0]	arfifo_cnt;
	wire				arfifo_empty;
	wire				arfifo_full;

	wire [LGFIFO-1 : 0]	bfifo_cnt;
	wire				bfifo_empty;
	wire				bfifo_full;

	wire [LGFIFO-1 : 0]	rfifo_cnt;
	wire				rfifo_empty;
	wire				rfifo_full;

	assign awready_ff =!awfifo_full;
	assign wready_ff =!wfifo_full;
	assign arready_ff =!arfifo_full;
	assign rready_ff =!rfifo_empty;

	assign m_axi_awready_ff =!awfifo_empty;
	assign m_axi_wready_ff =!wfifo_empty;
	assign m_axi_arready_ff =!arfifo_empty;
	assign m_axi_rready_ff =!rfifo_full;

	assign m_axi_awvalid_ff =!awfifo_empty;
	assign m_axi_wvalid_ff =!wfifo_empty;
	assign m_axi_arvalid_ff =!arfifo_empty;
	assign m_axi_rvalid_ff =!rfifo_empty;

	assign m_axi_awid_ff = awid_ff;
	assign m_axi_awaddr_ff = awaddr_ff;
	assign m_axi_awlen_ff = awlen_ff;
	assign m_axi_awsize_ff = awsize_ff;
	assign m_axi_awburst_ff = awburst_ff;
	assign m_axi_awlock_ff = awlock_ff;
	assign m_axi_awcache_ff = awcache_ff;
	assign m_axi_awprot_ff = awprot_ff;
	assign m_axi_awqos_ff = awqos_ff;

	assign m_axi_wdata_ff = wdata_ff;
	assign m_axi_wstrb_ff = wstrb_ff;
	assign m_axi_wlast_ff = wlast_ff;

	assign m_axi_arid_ff = arid_ff;
	assign m_axi_araddr_ff = araddr_ff;
	assign m_axi_arlen_ff = arlen_ff;
	assign m_axi_arsize_ff = arsize_ff;
	assign m_axi_arburst_ff = arburst_ff;
	assign m_axi_arlock_ff = arlock_ff;
	assign m_axi_arcache_ff = arcache_ff;
	assign m_axi_arprot_ff = arprot_ff;
	assign m_axi_arqos_ff = arqos_ff;

	assign m_axi_bid_ff = bid_ff;
	assign m_axi_bresp_ff = bresp_ff;

	assign m_axi_rid_ff = rid_ff;
	assign m_axi_rdata_ff = rdata_ff;
	assign m_axi_rresp_ff = rresp_ff;
	assign m_axi_rlast_ff = rlast_ff;

	assign S_AXI_AWREADY = awready_ff;
	assign S_AXI_WREADY = wready_ff;
	assign S_AXI_ARREADY = arready_ff;
	assign S_AXI_RREADY = rready_ff;

	assign M_AXI_AWID = m_axi_awid_ff;
	assign M_AXI_AWADDR = m_axi_awaddr_ff;
	assign M_AXI_AWLEN = m_axi_awlen_ff;
	assign M_AXI_AWSIZE = m_axi_awsize_ff;
	assign M_AXI_AWBURST = m_axi_awburst_ff;
	assign M_AXI_AWLOCK = m_axi_awlock_ff;
	assign M_AXI_AWCACHE = m_axi_awcache_ff;
	assign M_AXI_AWPROT = m_axi_awprot_ff;
	assign M_AXI_AWQOS = m_axi_awqos_ff;
	assign M_AXI_AWVALID = m_axi_awvalid_ff;

	assign M_AXI_WDATA = m_axi_wdata_ff;
	assign M_AXI_WSTRB = m_axi_wstrb_ff;
	assign M_AXI_WLAST = m_axi_wlast_ff;
	assign M_AXI_WVALID = m_axi_wvalid_ff;

	assign M_AXI_BREADY = m_axi_bready_ff;

	assign M_AXI_ARID = m_axi_arid_ff;
	assign M_AXI_ARADDR = m_axi_araddr_ff;
	assign M_AXI_ARLEN = m_axi_arlen_ff;
	assign M_AXI_ARSIZE = m_axi_arsize_ff;
	assign M_AXI_ARBURST = m_axi_arburst_ff;
	assign M_AXI_ARLOCK = m_axi_arlock_ff;
	assign M_AXI_ARCACHE = m_axi_arcache_ff;
	assign M_AXI_ARPROT = m_axi_arprot_ff;
	assign M_AXI_ARQOS = m_axi_arqos_ff;
	assign M_AXI_ARVALID = m_axi_arvalid_ff;

	assign M_AXI_RREADY = m_axi_rready_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;

	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
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
			wdata_ff <= 0;
			wstrb_ff <= 0;
			wlast_ff <= 0;
			wvalid_ff <= 0;
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
			bid_ff <= 0;
			bresp_ff <= 0;
			bvalid_ff <= 0;
			rid_ff <= 0;
			rdata_ff <= 0;
			rresp_ff <= 0;
			rlast_ff <= 0;
			rvalid_ff <= 0;
		end else begin
			if (S_AXI_AWVALID && awready_ff) begin
				awid_ff <= S_AXI_AWID;
				awaddr_ff <= S_AXI_AWADDR;
				awlen_ff <= S_AXI_AWLEN;
				awsize_ff <= S_AXI_AWSIZE;
				awburst_ff <= S_AXI_AWBURST;
				awlock_ff <= S_AXI_AWLOCK;
				awcache_ff <= S_AXI_AWCACHE;
				awprot_ff <= S_AXI_AWPROT;
				awqos_ff <= S_AXI_AWQOS;
				awvalid_ff <= 1'b1;
			end else if (m_axi_awready_ff) begin
				awvalid_ff <= 1'b0;
			end

			if (S_AXI_WVALID && wready_ff) begin
				wdata_ff <= S_AXI_WDATA;
				wstrb_ff <= S_AXI_WSTRB;
				wlast_ff <= S_AXI_WLAST;
				wvalid_ff <= 1'b1;
			end else if (m_axi_wready_ff) begin
				wvalid_ff <= 1'b0;
			end

			if (S_AXI_ARVALID && arready_ff) begin
				arid_ff <= S_AXI_ARID;
				araddr_ff <= S_AXI_ARADDR;
				arlen_ff <= S_AXI_ARLEN;
				arsize_ff <= S_AXI_ARSIZE;
				arburst_ff <= S_AXI_ARBURST;
				arlock_ff <= S_AXI_ARLOCK;
				arcache_ff <= S_AXI_ARCACHE;
				arprot_ff <= S_AXI_ARPROT;
				arqos_ff <= S_AXI_ARQOS;
				arvalid_ff <= 1'b1;
			end else if (m_axi_arready_ff) begin
				arvalid_ff <= 1'b0;
			end

			if (M_AXI_BVALID && m_axi_bready_ff) begin
				bid_ff <= M_AXI_BID;
				bresp_ff <= M_AXI_BRESP;
				bvalid_ff <= 1'b1;
			end else if (S_AXI_BREADY) begin
				bvalid_ff <= 1'b0;
			end

			if (M_AXI_RVALID && m_axi_rready_ff) begin
				rid_ff <= M_AXI_RID;
				rdata_ff <= M_AXI_RDATA;
				rresp_ff <= M_AXI_RRESP;
				rlast_ff <= M_AXI_RLAST;
				rvalid_ff <= 1'b1;
			end else if (S_AXI_RREADY) begin
				rvalid_ff <= 1'b0;
			end
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn_ff) begin
			m_axi_awid_ff <= 0;
			m_axi_awaddr_ff <= 0;
			m_axi_awlen_ff <= 0;
			m_axi_awsize_ff <= 0;
			m_axi_awburst_ff <= 0;
			m_axi_awlock_ff <= 0;
			m_axi_awcache_ff <= 0;
			m_axi_awprot_ff <= 0;
			m_axi_awqos_ff <= 0;
			m_axi_awvalid_ff <= 0;
			m_axi_wdata_ff <= 0;
			m_axi_wstrb_ff <= 0;
			m_axi_wlast_ff <= 0;
			m_axi_wvalid_ff <= 0;
			m_axi_arid_ff <= 0;
			m_axi_araddr_ff <= 0;
			m_axi_arlen_ff <= 0;
			m_axi_arsize_ff <= 0;
			m_axi_arburst_ff <= 0;
			m_axi_arlock_ff <= 0;
			m_axi_arcache_ff <= 0;
			m_axi_arprot_ff <= 0;
			m_axi_arqos_ff <= 0;
			m_axi_arvalid_ff <= 0;
			m_axi_bid_ff <= 0;
			m_axi_bresp_ff <= 0;
			m_axi_bvalid_ff <= 0;
			m_axi_rid_ff <= 0;
			m_axi_rdata_ff <= 0;
			m_axi_rresp_ff <= 0;
			m_axi_rlast_ff <= 0;
			m_axi_rvalid_ff <= 0;
		end else begin
			if (awvalid_ff && m_axi_awready_ff) begin
				m_axi_awid_ff <= awid_ff;
				m_axi_awaddr_ff <= awaddr_ff;
				m_axi_awlen_ff <= awlen_ff;
				m_axi_awsize_ff <= awsize_ff;
				m_axi_awburst_ff <= awburst_ff;
				m_axi_awlock_ff <= awlock_ff;
				m_axi_awcache_ff <= awcache_ff;
				m_axi_awprot_ff <= awprot_ff;
				m_axi_awqos_ff <= awqos_ff;
				m_axi_awvalid_ff <= 1'b1;
			end else if (M_AXI_AWREADY) begin
				m_axi_awvalid_ff <= 1'b0;
			end

			if (wvalid_ff && m_axi_wready_ff) begin
				m_axi_wdata_ff <= wdata_ff;
				m_axi_wstrb_ff <= wstrb_ff;
				m_axi_wlast_ff <= wlast_ff;
				m_axi_wvalid_ff <= 1'b1;
			end else if (M_AXI_WREADY) begin
				m_axi_wvalid_ff <= 1'b0;
			end

			if (arvalid_ff && m_axi_arready_ff) begin
				m_axi_arid_ff <= arid_ff;
				m_axi_araddr_ff <= araddr_ff;
				m_axi_arlen_ff <= arlen_ff;
				m_axi_arsize_ff <= arsize_ff;
				m_axi_arburst_ff <= arburst_ff;
				m_axi_arlock_ff <= arlock_ff;
				m_axi_arcache_ff <= arcache_ff;
				m_axi_arprot_ff <= arprot_ff;
				m_axi_arqos_ff <= arqos_ff;
				m_axi_arvalid_ff <= 1'b1;
			end else if (M_AXI_ARREADY) begin
				m_axi_arvalid_ff <= 1'b0;
			end

			if (M_AXI_BVALID && m_axi_bready_ff) begin
				m_axi_bid_ff <= M_AXI_BID;
				m_axi_bresp_ff <= M_AXI_BRESP;
				m_axi_bvalid_ff <= 1'b1;
			end else if (M_AXI_BREADY) begin
				m_axi_bvalid_ff <= 1'b0;
			end

			if (M_AXI_RVALID && m_axi_rready_ff) begin
				m_axi_rid_ff <= M_AXI_RID;
				m_axi_rdata_ff <= M_AXI_RDATA;
				m_axi_rresp_ff <= M_AXI_RRESP;
				m_axi_rlast_ff <= M_AXI_RLAST;
				m_axi_rvalid_ff <= 1'b1;
			end else if (M_AXI_RREADY) begin
				m_axi_rvalid_ff <= 1'b0;
			end
		end
	end

endmodule
