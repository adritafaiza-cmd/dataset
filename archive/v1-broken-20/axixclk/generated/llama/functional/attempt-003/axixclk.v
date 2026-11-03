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

	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid;
	wire [1 : 0]			bresp;
	wire				bvalid;
	wire				bready;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata;
	wire [1 : 0]			rresp;
	wire				rlast;
	wire				rvalid;
	wire				rready;

	wire				m_axi_aresetn;

	assign M_AXI_ARESETN = m_axi_aresetn;

	assign S_AXI_AWREADY = awready;
	assign S_AXI_WREADY = wready;
	assign S_AXI_ARREADY = arready;
	assign S_AXI_BID = bid;
	assign S_AXI_BRESP = bresp;
	assign S_AXI_BVALID = bvalid;
	assign S_AXI_RID = rid;
	assign S_AXI_RDATA = rdata;
	assign S_AXI_RRESP = rresp;
	assign S_AXI_RLAST = rlast;
	assign S_AXI_RVALID = rvalid;

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
	assign M_AXI_BREADY = bready;
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
	assign M_AXI_RREADY = rready;

	// Clock domain crossing for write channel
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
	wire				awready_sync;

	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_sync;
	wire				wlast_sync;
	wire				wvalid_sync;
	wire				wready_sync;

	// Clock domain crossing for read channel
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
	wire				arready_sync;

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

	// Write channel
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			awid <= 0;
			awaddr <= 0;
			awlen <= 0;
			awsize <= 0;
			awburst <= 0;
			awlock <= 0;
			awcache <= 0;
			awprot <= 0;
			awqos <= 0;
			awvalid <= 0;
			wdata <= 0;
			wstrb <= 0;
			wlast <= 0;
			wvalid <= 0;
		end else if (S_AXI_AWVALID && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_WREADY) begin
			awid <= S_AXI_AWID;
			awaddr <= S_AXI_AWADDR;
			awlen <= S_AXI_AWLEN;
			awsize <= S_AXI_AWSIZE;
			awburst <= S_AXI_AWBURST;
			awlock <= S_AXI_AWLOCK;
			awcache <= S_AXI_AWCACHE;
			awprot <= S_AXI_AWPROT;
			awqos <= S_AXI_AWQOS;
			awvalid <= 1;
			wdata <= S_AXI_WDATA;
			wstrb <= S_AXI_WSTRB;
			wlast <= S_AXI_WLAST;
			wvalid <= 1;
		end else if (S_AXI_AWREADY && S_AXI_WREADY) begin
			awvalid <= 0;
			wvalid <= 0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			awid_sync <= 0;
			awaddr_sync <= 0;
			awlen_sync <= 0;
			awsize_sync <= 0;
			awburst_sync <= 0;
			awlock_sync <= 0;
			awcache_sync <= 0;
			awprot_sync <= 0;
			awqos_sync <= 0;
			awvalid_sync <= 0;
			wdata_sync <= 0;
			wstrb_sync <= 0;
			wlast_sync <= 0;
			wvalid_sync <= 0;
		end else if (awvalid) begin
			awid_sync <= awid;
			awaddr_sync <= awaddr;
			awlen_sync <= awlen;
			awsize_sync <= awsize;
			awburst_sync <= awburst;
			awlock_sync <= awlock;
			awcache_sync <= awcache;
			awprot_sync <= awprot;
			awqos_sync <= awqos;
			awvalid_sync <= 1;
			wdata_sync <= wdata;
			wstrb_sync <= wstrb;
			wlast_sync <= wlast;
			wvalid_sync <= 1;
		end else if (M_AXI_AWREADY && M_AXI_WREADY) begin
			awvalid_sync <= 0;
			wvalid_sync <= 0;
		end
	end

	// Read channel
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			arid <= 0;
			araddr <= 0;
			arlen <= 0;
			arsize <= 0;
			arburst <= 0;
			arlock <= 0;
			arcache <= 0;
			arprot <= 0;
			arqos <= 0;
			arvalid <= 0;
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			arid <= S_AXI_ARID;
			araddr <= S_AXI_ARADDR;
			arlen <= S_AXI_ARLEN;
			arsize <= S_AXI_ARSIZE;
			arburst <= S_AXI_ARBURST;
			arlock <= S_AXI_ARLOCK;
			arcache <= S_AXI_ARCACHE;
			arprot <= S_AXI_ARPROT;
			arqos <= S_AXI_ARQOS;
			arvalid <= 1;
		end else if (S_AXI_ARREADY) begin
			arvalid <= 0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			arid_sync <= 0;
			araddr_sync <= 0;
			arlen_sync <= 0;
			arsize_sync <= 0;
			arburst_sync <= 0;
			arlock_sync <= 0;
			arcache_sync <= 0;
			arprot_sync <= 0;
			arqos_sync <= 0;
			arvalid_sync <= 0;
		end else if (arvalid) begin
			arid_sync <= arid;
			araddr_sync <= araddr;
			arlen_sync <= arlen;
			arsize_sync <= arsize;
			arburst_sync <= arburst;
			arlock_sync <= arlock;
			arcache_sync <= arcache;
			arprot_sync <= arprot;
			arqos_sync <= arqos;
			arvalid_sync <= 1;
		end else if (M_AXI_ARREADY) begin
			arvalid_sync <= 0;
		end
	end

	// Response channel
	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			bid_sync <= 0;
			bresp_sync <= 0;
			bvalid_sync <= 0;
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			bid_sync <= M_AXI_BID;
			bresp_sync <= M_AXI_BRESP;
			bvalid_sync <= 1;
		end else if (M_AXI_BREADY) begin
			bvalid_sync <= 0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			bid <= 0;
			bresp <= 0;
			bvalid <= 0;
		end else if (bvalid_sync) begin
			bid <= bid_sync;
			bresp <= bresp_sync;
			bvalid <= 1;
		end else if (S_AXI_BREADY) begin
			bvalid <= 0;
		end
	end

	// Data channel
	always @(posedge M_AXI_ACLK) begin
		if (!m_axi_aresetn) begin
			rid_sync <= 0;
			rdata_sync <= 0;
			rresp_sync <= 0;
			rlast_sync <= 0;
			rvalid_sync <= 0;
		end else if (M_AXI_RVALID && M_AXI_RREADY) begin
			rid_sync <= M_AXI_RID;
			rdata_sync <= M_AXI_RDATA;
			rresp_sync <= M_AXI_RRESP;
			rlast_sync <= M_AXI_RLAST;
			rvalid_sync <= 1;
		end else if (M_AXI_RREADY) begin
			rvalid_sync <= 0;
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			rid <= 0;
			rdata <= 0;
			rresp <= 0;
			rlast <= 0;
			rvalid <= 0;
		end else if (rvalid_sync) begin
			rid <= rid_sync;
			rdata <= rdata_sync;
			rresp <= rresp_sync;
			rlast <= rlast_sync;
			rvalid <= 1;
		end else if (S_AXI_RREADY) begin
			rvalid <= 0;
		end
	end

	// Reset
	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			m_axi_aresetn <= 1;
		end else begin
			m_axi_aresetn <= 1;
		end
	end

	// Handshake
	assign awready = M_AXI_AWREADY;
	assign wready = M_AXI_WREADY;
	assign arready = M_AXI_ARREADY;
	assign bready = M_AXI_BREADY;
	assign rready = M_AXI_RREADY;

endmodule
