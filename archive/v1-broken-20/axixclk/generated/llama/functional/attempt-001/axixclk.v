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

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;
	wire				rready_ff;

	wire				m_axi_awvalid_ff;
	wire				m_axi_wvalid_ff;
	wire				m_axi_arvalid_ff;
	wire				m_axi_rready_ff;
	wire				m_axi_bready_ff;

	wire				s_axi_awready_ff;
	wire				s_axi_wready_ff;
	wire				s_axi_arready_ff;
	wire				s_axi_rready_ff;

	wire				m_axi_awready_ff;
	wire				m_axi_wready_ff;
	wire				m_axi_arready_ff;
	wire				m_axi_rvalid_ff;
	wire				m_axi_bvalid_ff;

	reg [XCLOCK_FFS-1 : 0]	clk_ff;
	reg [XCLOCK_FFS-1 : 0]	clk_ar_ff;
	reg [XCLOCK_FFS-1 : 0]	clk_aw_ff;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			clk_ff <= 0;
			clk_ar_ff <= 0;
			clk_aw_ff <= 0;
		end else begin
			clk_ff <= clk_ff + 1;
			clk_ar_ff <= clk_ar_ff + 1;
			clk_aw_ff <= clk_aw_ff + 1;
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ARESETN <= 1'b1;
		end else begin
			M_AXI_ARESETN <= 1'b1;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_AWVALID && S_AXI_AWREADY) begin
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
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_WVALID && S_AXI_WREADY) begin
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= 1'b1;
		end else if (m_axi_wready_ff) begin
			wvalid_ff <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARVALID && S_AXI_ARREADY) begin
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
	end

	always @(posedge M_AXI_ACLK) begin
		if (m_axi_awvalid_ff) begin
			M_AXI_AWID <= awid_ff;
			M_AXI_AWADDR <= awaddr_ff;
			M_AXI_AWLEN <= awlen_ff;
			M_AXI_AWSIZE <= awsize_ff;
			M_AXI_AWBURST <= awburst_ff;
			M_AXI_AWLOCK <= awlock_ff;
			M_AXI_AWCACHE <= awcache_ff;
			M_AXI_AWPROT <= awprot_ff;
			M_AXI_AWQOS <= awqos_ff;
			M_AXI_AWVALID <= 1'b1;
		end else begin
			M_AXI_AWVALID <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (m_axi_wvalid_ff) begin
			M_AXI_WDATA <= wdata_ff;
			M_AXI_WSTRB <= wstrb_ff;
			M_AXI_WLAST <= wlast_ff;
			M_AXI_WVALID <= 1'b1;
		end else begin
			M_AXI_WVALID <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (m_axi_arvalid_ff) begin
			M_AXI_ARID <= arid_ff;
			M_AXI_ARADDR <= araddr_ff;
			M_AXI_ARLEN <= arlen_ff;
			M_AXI_ARSIZE <= arsize_ff;
			M_AXI_ARBURST <= arburst_ff;
			M_AXI_ARLOCK <= arlock_ff;
			M_AXI_ARCACHE <= arcache_ff;
			M_AXI_ARPROT <= arprot_ff;
			M_AXI_ARQOS <= arqos_ff;
			M_AXI_ARVALID <= 1'b1;
		end else begin
			M_AXI_ARVALID <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_BVALID) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= 1'b1;
		end else if (S_AXI_BREADY) begin
			bvalid_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_RVALID) begin
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= 1'b1;
		end else if (S_AXI_RREADY) begin
			rvalid_ff <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (bvalid_ff) begin
			S_AXI_BID <= bid_ff;
			S_AXI_BRESP <= bresp_ff;
			S_AXI_BVALID <= 1'b1;
		end else begin
			S_AXI_BVALID <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (rvalid_ff) begin
			S_AXI_RID <= rid_ff;
			S_AXI_RDATA <= rdata_ff;
			S_AXI_RRESP <= rresp_ff;
			S_AXI_RLAST <= rlast_ff;
			S_AXI_RVALID <= 1'b1;
		end else begin
			S_AXI_RVALID <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
			s_axi_awready_ff <= 1'b1;
		end else if (S_AXI_AWREADY) begin
			s_axi_awready_ff <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_WVALID && !S_AXI_WREADY) begin
			s_axi_wready_ff <= 1'b1;
		end else if (S_AXI_WREADY) begin
			s_axi_wready_ff <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
			s_axi_arready_ff <= 1'b1;
		end else if (S_AXI_ARREADY) begin
			s_axi_arready_ff <= 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_RVALID && !S_AXI_RREADY) begin
			s_axi_rready_ff <= 1'b1;
		end else if (S_AXI_RREADY) begin
			s_axi_rready_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_AWREADY && !M_AXI_AWVALID) begin
			m_axi_awready_ff <= 1'b1;
		end else if (M_AXI_AWVALID) begin
			m_axi_awready_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_WREADY && !M_AXI_WVALID) begin
			m_axi_wready_ff <= 1'b1;
		end else if (M_AXI_WVALID) begin
			m_axi_wready_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARREADY && !M_AXI_ARVALID) begin
			m_axi_arready_ff <= 1'b1;
		end else if (M_AXI_ARVALID) begin
			m_axi_arready_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_RVALID && !M_AXI_RREADY) begin
			m_axi_rvalid_ff <= 1'b1;
		end else if (M_AXI_RREADY) begin
			m_axi_rvalid_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_BVALID && !M_AXI_BREADY) begin
			m_axi_bvalid_ff <= 1'b1;
		end else if (M_AXI_BREADY) begin
			m_axi_bvalid_ff <= 1'b0;
		end
	end

	assign S_AXI_AWREADY = s_axi_awready_ff;
	assign S_AXI_WREADY = s_axi_wready_ff;
	assign S_AXI_ARREADY = s_axi_arready_ff;
	assign S_AXI_RREADY = s_axi_rready_ff;

	assign M_AXI_BREADY = m_axi_bvalid_ff;
	assign M_AXI_RREADY = m_axi_rvalid_ff;

	assign m_axi_awvalid_ff = awvalid_ff && m_axi_awready_ff;
	assign m_axi_wvalid_ff = wvalid_ff && m_axi_wready_ff;
	assign m_axi_arvalid_ff = arvalid_ff && m_axi_arready_ff;

endmodule
