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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_sync;
	wire [7 : 0]			awlen_sync;
	wire [2 : 0]			awsize_sync;
	wire [1 : 0]			awburst_sync;
	wire				awlock_sync;
	wire [3 : 0]			awcache_sync;
	wire [2 : 0]			awprot_sync;
	wire [3 : 0]			awqos_sync;
	wire				awvalid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_sync;
	wire				wlast_sync;
	wire				wvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_sync;
	wire [7 : 0]			arlen_sync;
	wire [2 : 0]			arsize_sync;
	wire [1 : 0]			arburst_sync;
	wire				arlock_sync;
	wire [3 : 0]			arcache_sync;
	wire [2 : 0]			arprot_sync;
	wire [3 : 0]			arqos_sync;
	wire				arvalid_sync;

	wire				awready_sync;
	wire				wready_sync;
	wire				arready_sync;
	wire				rready_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire				bvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync;
	wire [1 : 0]			rresp_sync;
	wire				rlast_sync;
	wire				rvalid_sync;

	wire				bready_sync;

	wire				awready_ff;
	wire				wready_ff;
	wire				arready_ff;
	wire				rready_ff;

	wire				bready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;

	wire				m_axi_aresetn_ff;

	wire				m_axi_awvalid_ff;
	wire				m_axi_wvalid_ff;
	wire				m_axi_arvalid_ff;
	wire				m_axi_rready_ff;
	wire				m_axi_bready_ff;

	wire				m_axi_awready_sync;
	wire				m_axi_wready_sync;
	wire				m_axi_arready_sync;
	wire				m_axi_rvalid_sync;
	wire				m_axi_bvalid_sync;

	wire				m_axi_awready_ff;
	wire				m_axi_wready_ff;
	wire				m_axi_arready_ff;
	wire				m_axi_rvalid_ff;
	wire				m_axi_bvalid_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_awaddr_ff;
	wire [7 : 0]			m_axi_awlen_ff;
	wire [2 : 0]			m_axi_awsize_ff;
	wire [1 : 0]			m_axi_awburst_ff;
	wire				m_axi_awlock_ff;
	wire [3 : 0]			m_axi_awcache_ff;
	wire [2 : 0]			m_axi_awprot_ff;
	wire [3 : 0]			m_axi_awqos_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_araddr_ff;
	wire [7 : 0]			m_axi_arlen_ff;
	wire [2 : 0]			m_axi_arsize_ff;
	wire [1 : 0]			m_axi_arburst_ff;
	wire				m_axi_arlock_ff;
	wire [3 : 0]			m_axi_arcache_ff;
	wire [2 : 0]			m_axi_arprot_ff;
	wire [3 : 0]			m_axi_arqos_ff;

	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	m_axi_wstrb_ff;
	wire				m_axi_wlast_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_bid_ff;
	wire [1 : 0]			m_axi_bresp_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_rdata_ff;
	wire [1 : 0]			m_axi_rresp_ff;
	wire				m_axi_rlast_ff;

	// CDC for aw channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
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
			awvalid_ff <= 1'b1;
		end else if (M_AXI_AWREADY && M_AXI_AWVALID) begin
			awvalid_ff <= 1'b0;
		end
	end

	// CDC for w channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wdata_ff <= 0;
			wstrb_ff <= 0;
			wlast_ff <= 0;
			wvalid_ff <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= 1'b1;
		end else if (M_AXI_WREADY && M_AXI_WVALID) begin
			wvalid_ff <= 1'b0;
		end
	end

	// CDC for ar channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
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
			arvalid_ff <= 1'b1;
		end else if (M_AXI_ARREADY && M_AXI_ARVALID) begin
			arvalid_ff <= 1'b0;
		end
	end

	// CDC for b channel
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bid_ff <= 0;
			bresp_ff <= 0;
			bvalid_ff <= 0;
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= 1'b1;
		end else if (S_AXI_BREADY && S_AXI_BVALID) begin
			bvalid_ff <= 1'b0;
		end
	end

	// CDC for r channel
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
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
			rvalid_ff <= 1'b1;
		end else if (S_AXI_RREADY && S_AXI_RVALID) begin
			rvalid_ff <= 1'b0;
		end
	end

	// CDC for awready
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awready_ff <= 0;
		end else if (M_AXI_AWREADY) begin
			awready_ff <= 1'b1;
		end else if (S_AXI_AWVALID) begin
			awready_ff <= 1'b0;
		end
	end

	// CDC for wready
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			wready_ff <= 0;
		end else if (M_AXI_WREADY) begin
			wready_ff <= 1'b1;
		end else if (S_AXI_WVALID) begin
			wready_ff <= 1'b0;
		end
	end

	// CDC for arready
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arready_ff <= 0;
		end else if (M_AXI_ARREADY) begin
			arready_ff <= 1'b1;
		end else if (S_AXI_ARVALID) begin
			arready_ff <= 1'b0;
		end
	end

	// CDC for rready
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			rready_ff <= 0;
		end else if (M_AXI_RREADY) begin
			rready_ff <= 1'b1;
		end else if (S_AXI_RVALID) begin
			rready_ff <= 1'b0;
		end
	end

	// CDC for bready
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			bready_ff <= 0;
		end else if (M_AXI_BREADY) begin
			bready_ff <= 1'b1;
		end else if (S_AXI_BVALID) begin
			bready_ff <= 1'b0;
		end
	end

	// CDC for m_axi_aresetn
	always @(posedge M_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			m_axi_aresetn_ff <= 0;
		end else begin
			m_axi_aresetn_ff <= 1'b1;
		end
	end

	// CDC for m_axi_awvalid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awvalid_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awvalid_ff <= 1'b1;
		end else if (M_AXI_AWREADY) begin
			m_axi_awvalid_ff <= 1'b0;
		end
	end

	// CDC for m_axi_wvalid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_wvalid_ff <= 0;
		end else if (wvalid_ff) begin
			m_axi_wvalid_ff <= 1'b1;
		end else if (M_AXI_WREADY) begin
			m_axi_wvalid_ff <= 1'b0;
		end
	end

	// CDC for m_axi_arvalid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arvalid_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arvalid_ff <= 1'b1;
		end else if (M_AXI_ARREADY) begin
			m_axi_arvalid_ff <= 1'b0;
		end
	end

	// CDC for m_axi_rready
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_rready_ff <= 0;
		end else if (rready_ff) begin
			m_axi_rready_ff <= 1'b1;
		end else if (M_AXI_RVALID) begin
			m_axi_rready_ff <= 1'b0;
		end
	end

	// CDC for m_axi_bready
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_bready_ff <= 0;
		end else if (bready_ff) begin
			m_axi_bready_ff <= 1'b1;
		end else if (M_AXI_BVALID) begin
			m_axi_bready_ff <= 1'b0;
		end
	end

	// CDC for m_axi_awid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awid_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awid_ff <= awid_ff;
		end
	end

	// CDC for m_axi_awaddr
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awaddr_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awaddr_ff <= awaddr_ff;
		end
	end

	// CDC for m_axi_awlen
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awlen_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awlen_ff <= awlen_ff;
		end
	end

	// CDC for m_axi_awsize
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awsize_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awsize_ff <= awsize_ff;
		end
	end

	// CDC for m_axi_awburst
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awburst_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awburst_ff <= awburst_ff;
		end
	end

	// CDC for m_axi_awlock
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awlock_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awlock_ff <= awlock_ff;
		end
	end

	// CDC for m_axi_awcache
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awcache_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awcache_ff <= awcache_ff;
		end
	end

	// CDC for m_axi_awprot
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awprot_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awprot_ff <= awprot_ff;
		end
	end

	// CDC for m_axi_awqos
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_awqos_ff <= 0;
		end else if (awvalid_ff) begin
			m_axi_awqos_ff <= awqos_ff;
		end
	end

	// CDC for m_axi_arid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arid_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arid_ff <= arid_ff;
		end
	end

	// CDC for m_axi_araddr
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_araddr_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_araddr_ff <= araddr_ff;
		end
	end

	// CDC for m_axi_arlen
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arlen_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arlen_ff <= arlen_ff;
		end
	end

	// CDC for m_axi_arsize
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arsize_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arsize_ff <= arsize_ff;
		end
	end

	// CDC for m_axi_arburst
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arburst_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arburst_ff <= arburst_ff;
		end
	end

	// CDC for m_axi_arlock
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arlock_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arlock_ff <= arlock_ff;
		end
	end

	// CDC for m_axi_arcache
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arcache_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arcache_ff <= arcache_ff;
		end
	end

	// CDC for m_axi_arprot
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arprot_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arprot_ff <= arprot_ff;
		end
	end

	// CDC for m_axi_arqos
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_arqos_ff <= 0;
		end else if (arvalid_ff) begin
			m_axi_arqos_ff <= arqos_ff;
		end
	end

	// CDC for m_axi_wdata
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_wdata_ff <= 0;
		end else if (wvalid_ff) begin
			m_axi_wdata_ff <= wdata_ff;
		end
	end

	// CDC for m_axi_wstrb
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_wstrb_ff <= 0;
		end else if (wvalid_ff) begin
			m_axi_wstrb_ff <= wstrb_ff;
		end
	end

	// CDC for m_axi_wlast
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_wlast_ff <= 0;
		end else if (wvalid_ff) begin
			m_axi_wlast_ff <= wlast_ff;
		end
	end

	// CDC for m_axi_bid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_bid_ff <= 0;
		end else if (bvalid_ff) begin
			m_axi_bid_ff <= bid_ff;
		end
	end

	// CDC for m_axi_bresp
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_bresp_ff <= 0;
		end else if (bvalid_ff) begin
			m_axi_bresp_ff <= bresp_ff;
		end
	end

	// CDC for m_axi_rid
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_rid_ff <= 0;
		end else if (rvalid_ff) begin
			m_axi_rid_ff <= rid_ff;
		end
	end

	// CDC for m_axi_rdata
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_rdata_ff <= 0;
		end else if (rvalid_ff) begin
			m_axi_rdata_ff <= rdata_ff;
		end
	end

	// CDC for m_axi_rresp
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_rresp_ff <= 0;
		end else if (rvalid_ff) begin
			m_axi_rresp_ff <= rresp_ff;
		end
	end

	// CDC for m_axi_rlast
	always @(posedge M_AXI_ACLK) begin
		if (~m_axi_aresetn_ff) begin
			m_axi_rlast_ff <= 0;
		end else if (rvalid_ff) begin
			m_axi_rlast_ff <= rlast_ff;
		end
	end

	assign S_AXI_AWREADY = awready_ff;
	assign S_AXI_WREADY = wready_ff;
	assign S_AXI_ARREADY = arready_ff;
	assign S_AXI_RREADY = rready_ff;
	assign S_AXI_BREADY = bready_ff;

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

	assign M_AXI_BID = m_axi_bid_ff;
	assign M_AXI_BRESP = m_axi_bresp_ff;
	assign M_AXI_BVALID = bvalid_ff;

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

	assign M_AXI_RID = m_axi_rid_ff;
	assign M_AXI_RDATA = m_axi_rdata_ff;
	assign M_AXI_RRESP = m_axi_rresp_ff;
	assign M_AXI_RLAST = m_axi_rlast_ff;
	assign M_AXI_RVALID = rvalid_ff;

	assign M_AXI_ARESETN = m_axi_aresetn_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;

	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

endmodule
