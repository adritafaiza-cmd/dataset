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
	wire				bvalid_sync;
	wire				bready_sync;
	wire				arready_sync;
	wire				rvalid_sync;
	wire				rready_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_sync;
	wire [1 : 0]			bresp_sync;
	wire				bvalid_sync;
	wire				bready_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_sync;
	wire [1 : 0]			rresp_sync;
	wire				rlast_sync;
	wire				rvalid_sync;
	wire				rready_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_ff_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_ff_sync;
	wire [7 : 0]			awlen_ff_sync;
	wire [2 : 0]			awsize_ff_sync;
	wire [1 : 0]			awburst_ff_sync;
	wire				awlock_ff_sync;
	wire [3 : 0]			awcache_ff_sync;
	wire [2 : 0]			awprot_ff_sync;
	wire [3 : 0]			awqos_ff_sync;
	wire				awvalid_ff_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_ff_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_ff_sync;
	wire				wlast_ff_sync;
	wire				wvalid_ff_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_ff_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_ff_sync;
	wire [7 : 0]			arlen_ff_sync;
	wire [2 : 0]			arsize_ff_sync;
	wire [1 : 0]			arburst_ff_sync;
	wire				arlock_ff_sync;
	wire [3 : 0]			arcache_ff_sync;
	wire [2 : 0]			arprot_ff_sync;
	wire [3 : 0]			arqos_ff_sync;
	wire				arvalid_ff_sync;

	wire				awready_ff_sync;
	wire				wready_ff_sync;
	wire				bvalid_ff_sync;
	wire				bready_ff_sync;
	wire				arready_ff_sync;
	wire				rvalid_ff_sync;
	wire				rready_ff_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff_sync;
	wire [1 : 0]			bresp_ff_sync;
	wire				bvalid_ff_sync;
	wire				bready_ff_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff_sync;
	wire [1 : 0]			rresp_ff_sync;
	wire				rlast_ff_sync;
	wire				rvalid_ff_sync;
	wire				rready_ff_sync;

	wire				awvalid_ff_sync_d1;
	wire				wvalid_ff_sync_d1;

	wire				awready_ff_sync_d1;
	wire				wready_ff_sync_d1;

	wire				bvalid_ff_sync_d1;
	wire				bready_ff_sync_d1;

	wire				arvalid_ff_sync_d1;
	wire				arready_ff_sync_d1;

	wire				rvalid_ff_sync_d1;
	wire				rready_ff_sync_d1;

	wire				m_axi_awvalid_d1;
	wire				m_axi_wvalid_d1;

	wire				m_axi_awready_d1;
	wire				m_axi_wready_d1;

	wire				m_axi_bvalid_d1;
	wire				m_axi_bready_d1;

	wire				m_axi_arvalid_d1;
	wire				m_axi_arready_d1;

	wire				m_axi_rvalid_d1;
	wire				m_axi_rready_d1;

	wire				m_axi_awvalid_d2;
	wire				m_axi_wvalid_d2;

	wire				m_axi_awready_d2;
	wire				m_axi_wready_d2;

	wire				m_axi_bvalid_d2;
	wire				m_axi_bready_d2;

	wire				m_axi_arvalid_d2;
	wire				m_axi_arready_d2;

	wire				m_axi_rvalid_d2;
	wire				m_axi_rready_d2;

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	assign S_AXI_AWREADY = awready_sync;
	assign S_AXI_WREADY = wready_sync;
	assign S_AXI_BID = bid_sync;
	assign S_AXI_BRESP = bresp_sync;
	assign S_AXI_BVALID = bvalid_sync;
	assign S_AXI_ARREADY = arready_sync;
	assign S_AXI_RID = rid_sync;
	assign S_AXI_RDATA = rdata_sync;
	assign S_AXI_RRESP = rresp_sync;
	assign S_AXI_RLAST = rlast_sync;
	assign S_AXI_RVALID = rvalid_sync;

	assign M_AXI_AWID = awid_ff_sync;
	assign M_AXI_AWADDR = awaddr_ff_sync;
	assign M_AXI_AWLEN = awlen_ff_sync;
	assign M_AXI_AWSIZE = awsize_ff_sync;
	assign M_AXI_AWBURST = awburst_ff_sync;
	assign M_AXI_AWLOCK = awlock_ff_sync;
	assign M_AXI_AWCACHE = awcache_ff_sync;
	assign M_AXI_AWPROT = awprot_ff_sync;
	assign M_AXI_AWQOS = awqos_ff_sync;
	assign M_AXI_AWVALID = awvalid_ff_sync_d1;
	assign M_AXI_WDATA = wdata_ff_sync;
	assign M_AXI_WSTRB = wstrb_ff_sync;
	assign M_AXI_WLAST = wlast_ff_sync;
	assign M_AXI_WVALID = wvalid_ff_sync_d1;
	assign M_AXI_BREADY = bready_ff_sync_d1;
	assign M_AXI_ARID = arid_ff_sync;
	assign M_AXI_ARADDR = araddr_ff_sync;
	assign M_AXI_ARLEN = arlen_ff_sync;
	assign M_AXI_ARSIZE = arsize_ff_sync;
	assign M_AXI_ARBURST = arburst_ff_sync;
	assign M_AXI_ARLOCK = arlock_ff_sync;
	assign M_AXI_ARCACHE = arcache_ff_sync;
	assign M_AXI_ARPROT = arprot_ff_sync;
	assign M_AXI_ARQOS = arqos_ff_sync;
	assign M_AXI_ARVALID = arvalid_ff_sync_d1;
	assign M_AXI_RREADY = rready_ff_sync_d1;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
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
		end else begin
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
			end else if (!S_AXI_AWVALID) begin
				awvalid_ff <= 1'b0;
			end

			if (S_AXI_WVALID && S_AXI_WREADY) begin
				wdata_ff <= S_AXI_WDATA;
				wstrb_ff <= S_AXI_WSTRB;
				wlast_ff <= S_AXI_WLAST;
				wvalid_ff <= 1'b1;
			end else if (!S_AXI_WVALID) begin
				wvalid_ff <= 1'b0;
			end

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
			end else if (!S_AXI_ARVALID) begin
				arvalid_ff <= 1'b0;
			end
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awid_ff_sync <= 0;
			awaddr_ff_sync <= 0;
			awlen_ff_sync <= 0;
			awsize_ff_sync <= 0;
			awburst_ff_sync <= 0;
			awlock_ff_sync <= 0;
			awcache_ff_sync <= 0;
			awprot_ff_sync <= 0;
			awqos_ff_sync <= 0;
			awvalid_ff_sync <= 0;
			wdata_ff_sync <= 0;
			wstrb_ff_sync <= 0;
			wlast_ff_sync <= 0;
			wvalid_ff_sync <= 0;
			arid_ff_sync <= 0;
			araddr_ff_sync <= 0;
			arlen_ff_sync <= 0;
			arsize_ff_sync <= 0;
			arburst_ff_sync <= 0;
			arlock_ff_sync <= 0;
			arcache_ff_sync <= 0;
			arprot_ff_sync <= 0;
			arqos_ff_sync <= 0;
			arvalid_ff_sync <= 0;
		end else begin
			awid_ff_sync <= awid_ff;
			awaddr_ff_sync <= awaddr_ff;
			awlen_ff_sync <= awlen_ff;
			awsize_ff_sync <= awsize_ff;
			awburst_ff_sync <= awburst_ff;
			awlock_ff_sync <= awlock_ff;
			awcache_ff_sync <= awcache_ff;
			awprot_ff_sync <= awprot_ff;
			awqos_ff_sync <= awqos_ff;
			awvalid_ff_sync <= awvalid_ff;
			wdata_ff_sync <= wdata_ff;
			wstrb_ff_sync <= wstrb_ff;
			wlast_ff_sync <= wlast_ff;
			wvalid_ff_sync <= wvalid_ff;
			arid_ff_sync <= arid_ff;
			araddr_ff_sync <= araddr_ff;
			arlen_ff_sync <= arlen_ff;
			arsize_ff_sync <= arsize_ff;
			arburst_ff_sync <= arburst_ff;
			arlock_ff_sync <= arlock_ff;
			arcache_ff_sync <= arcache_ff;
			arprot_ff_sync <= arprot_ff;
			arqos_ff_sync <= arqos_ff;
			arvalid_ff_sync <= arvalid_ff;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awready_sync <= 0;
			wready_sync <= 0;
			bid_sync <= 0;
			bresp_sync <= 0;
			bvalid_sync <= 0;
			arready_sync <= 0;
			rid_sync <= 0;
			rdata_sync <= 0;
			rresp_sync <= 0;
			rlast_sync <= 0;
			rvalid_sync <= 0;
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				bid_sync <= M_AXI_BID;
				bresp_sync <= M_AXI_BRESP;
				bvalid_sync <= 1'b1;
			end else if (!M_AXI_BVALID) begin
				bvalid_sync <= 1'b0;
			end

			if (M_AXI_RVALID && M_AXI_RREADY) begin
				rid_sync <= M_AXI_RID;
				rdata_sync <= M_AXI_RDATA;
				rresp_sync <= M_AXI_RRESP;
				rlast_sync <= M_AXI_RLAST;
				rvalid_sync <= 1'b1;
			end else if (!M_AXI_RVALID) begin
				rvalid_sync <= 1'b0;
			end

			if (awvalid_ff && M_AXI_AWREADY) begin
				awready_sync <= 1'b1;
			end else if (!awvalid_ff) begin
				awready_sync <= 1'b0;
			end

			if (wvalid_ff && M_AXI_WREADY) begin
				wready_sync <= 1'b1;
			end else if (!wvalid_ff) begin
				wready_sync <= 1'b0;
			end

			if (arvalid_ff && M_AXI_ARREADY) begin
				arready_sync <= 1'b1;
			end else if (!arvalid_ff) begin
				arready_sync <= 1'b0;
			end
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awvalid_ff_sync_d1 <= 0;
			wvalid_ff_sync_d1 <= 0;
			bready_ff_sync_d1 <= 0;
			arvalid_ff_sync_d1 <= 0;
			rready_ff_sync_d1 <= 0;
		end else begin
			awvalid_ff_sync_d1 <= awvalid_ff_sync;
			wvalid_ff_sync_d1 <= wvalid_ff_sync;
			bready_ff_sync_d1 <= M_AXI_BVALID ? 1'b1 : 1'b0;
			arvalid_ff_sync_d1 <= arvalid_ff_sync;
			rready_ff_sync_d1 <= M_AXI_RVALID ? 1'b1 : 1'b0;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			awready_ff_sync_d1 <= 0;
			wready_ff_sync_d1 <= 0;
			bvalid_ff_sync_d1 <= 0;
			bready_ff_sync_d1 <= 0;
			arready_ff_sync_d1 <= 0;
			arvalid_ff_sync_d1 <= 0;
			rvalid_ff_sync_d1 <= 0;
			rready_ff_sync_d1 <= 0;
		end else begin
			awready_ff_sync_d1 <= M_AXI_AWREADY ? 1'b1 : 1'b0;
			wready_ff_sync_d1 <= M_AXI_WREADY ? 1'b1 : 1'b0;
			bvalid_ff_sync_d1 <= M_AXI_BVALID ? 1'b1 : 1'b0;
			bready_ff_sync_d1 <= M_AXI_BREADY ? 1'b1 : 1'b0;
			arready_ff_sync_d1 <= M_AXI_ARREADY ? 1'b1 : 1'b0;
			arvalid_ff_sync_d1 <= M_AXI_ARVALID ? 1'b1 : 1'b0;
			rvalid_ff_sync_d1 <= M_AXI_RVALID ? 1'b1 : 1'b0;
			rready_ff_sync_d1 <= M_AXI_RREADY ? 1'b1 : 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_awvalid_d1 <= 0;
			m_axi_wvalid_d1 <= 0;
			m_axi_awready_d1 <= 0;
			m_axi_wready_d1 <= 0;
			m_axi_bvalid_d1 <= 0;
			m_axi_bready_d1 <= 0;
			m_axi_arvalid_d1 <= 0;
			m_axi_arready_d1 <= 0;
			m_axi_rvalid_d1 <= 0;
			m_axi_rready_d1 <= 0;
		end else begin
			m_axi_awvalid_d1 <= M_AXI_AWVALID;
			m_axi_wvalid_d1 <= M_AXI_WVALID;
			m_axi_awready_d1 <= M_AXI_AWREADY;
			m_axi_wready_d1 <= M_AXI_WREADY;
			m_axi_bvalid_d1 <= M_AXI_BVALID;
			m_axi_bready_d1 <= M_AXI_BREADY;
			m_axi_arvalid_d1 <= M_AXI_ARVALID;
			m_axi_arready_d1 <= M_AXI_ARREADY;
			m_axi_rvalid_d1 <= M_AXI_RVALID;
			m_axi_rready_d1 <= M_AXI_RREADY;
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_awvalid_d2 <= 0;
			m_axi_wvalid_d2 <= 0;
			m_axi_awready_d2 <= 0;
			m_axi_wready_d2 <= 0;
			m_axi_bvalid_d2 <= 0;
			m_axi_bready_d2 <= 0;
			m_axi_arvalid_d2 <= 0;
			m_axi_arready_d2 <= 0;
			m_axi_rvalid_d2 <= 0;
			m_axi_rready_d2 <= 0;
		end else begin
			m_axi_awvalid_d2 <= m_axi_awvalid_d1;
			m_axi_wvalid_d2 <= m_axi_wvalid_d1;
			m_axi_awready_d2 <= m_axi_awready_d1;
			m_axi_wready_d2 <= m_axi_wready_d1;
			m_axi_bvalid_d2 <= m_axi_bvalid_d1;
			m_axi_bready_d2 <= m_axi_bready_d1;
			m_axi_arvalid_d2 <= m_axi_arvalid_d1;
			m_axi_arready_d2 <= m_axi_arready_d1;
			m_axi_rvalid_d2 <= m_axi_rvalid_d1;
			m_axi_rready_d2 <= m_axi_rready_d1;
		end
	end

endmodule
