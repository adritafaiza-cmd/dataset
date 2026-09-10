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

	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_sync;
	wire [7 : 0] awlen_sync;
	wire [2 : 0] awsize_sync;
	wire [1 : 0] awburst_sync;
	wire awlock_sync;
	wire [3 : 0] awcache_sync;
	wire [2 : 0] awprot_sync;
	wire [3 : 0] awqos_sync;
	wire awvalid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_sync;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_sync;
	wire wlast_sync;
	wire wvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_sync;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_sync;
	wire [7 : 0] arlen_sync;
	wire [2 : 0] arsize_sync;
	wire [1 : 0] arburst_sync;
	wire arlock_sync;
	wire [3 : 0] arcache_sync;
	wire [2 : 0] arprot_sync;
	wire [3 : 0] arqos_sync;
	wire arvalid_sync;

	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_sync;
	wire [1 : 0] bresp_sync;
	wire bvalid_sync;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_sync;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_sync;
	wire [1 : 0] rresp_sync;
	wire rlast_sync;
	wire rvalid_sync;

	wire awready_sync;
	wire wready_sync;
	wire arready_sync;
	wire bready_sync;
	wire rready_sync;

	wire [XCLOCK_FFS-1 : 0] awclk_ff;
	wire [XCLOCK_FFS-1 : 0] arclk_ff;

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Synchronous reset
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (~S_AXI_ARESETN) begin
			awclk_ff <= {XCLOCK_FFS{1'b0}};
			arclk_ff <= {XCLOCK_FFS{1'b0}};
		end else begin
			awclk_ff <= {awclk_ff[XCLOCK_FFS-2:0], 1'b1};
			arclk_ff <= {arclk_ff[XCLOCK_FFS-2:0], 1'b1};
		end
	end

	// Write channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awid_sync <= {C_S_AXI_ID_WIDTH{1'b0}};
			awaddr_sync <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			awlen_sync <= {8{1'b0}};
			awsize_sync <= {3{1'b0}};
			awburst_sync <= {2{1'b0}};
			awlock_sync <= 1'b0;
			awcache_sync <= {4{1'b0}};
			awprot_sync <= {3{1'b0}};
			awqos_sync <= {4{1'b0}};
			awvalid_sync <= 1'b0;
			wdata_sync <= {C_S_AXI_DATA_WIDTH{1'b0}};
			wstrb_sync <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			wlast_sync <= 1'b0;
			wvalid_sync <= 1'b0;
		end else if (S_AXI_AWVALID && S_AXI_WVALID && S_AXI_WLAST) begin
			awid_sync <= S_AXI_AWID;
			awaddr_sync <= S_AXI_AWADDR;
			awlen_sync <= S_AXI_AWLEN;
			awsize_sync <= S_AXI_AWSIZE;
			awburst_sync <= S_AXI_AWBURST;
			awlock_sync <= S_AXI_AWLOCK;
			awcache_sync <= S_AXI_AWCACHE;
			awprot_sync <= S_AXI_AWPROT;
			awqos_sync <= S_AXI_AWQOS;
			awvalid_sync <= 1'b1;
			wdata_sync <= S_AXI_WDATA;
			wstrb_sync <= S_AXI_WSTRB;
			wlast_sync <= S_AXI_WLAST;
			wvalid_sync <= 1'b1;
		end else begin
			awvalid_sync <= 1'b0;
			wvalid_sync <= 1'b0;
		end
	end

	// Read channel
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arid_sync <= {C_S_AXI_ID_WIDTH{1'b0}};
			araddr_sync <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			arlen_sync <= {8{1'b0}};
			arsize_sync <= {3{1'b0}};
			arburst_sync <= {2{1'b0}};
			arlock_sync <= 1'b0;
			arcache_sync <= {4{1'b0}};
			arprot_sync <= {3{1'b0}};
			arqos_sync <= {4{1'b0}};
			arvalid_sync <= 1'b0;
		end else if (S_AXI_ARVALID) begin
			arid_sync <= S_AXI_ARID;
			araddr_sync <= S_AXI_ARADDR;
			arlen_sync <= S_AXI_ARLEN;
			arsize_sync <= S_AXI_ARSIZE;
			arburst_sync <= S_AXI_ARBURST;
			arlock_sync <= S_AXI_ARLOCK;
			arcache_sync <= S_AXI_ARCACHE;
			arprot_sync <= S_AXI_ARPROT;
			arqos_sync <= S_AXI_ARQOS;
			arvalid_sync <= 1'b1;
		end else begin
			arvalid_sync <= 1'b0;
		end
	end

	// Response channel
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bid_sync <= {C_S_AXI_ID_WIDTH{1'b0}};
			bresp_sync <= {2{1'b0}};
			bvalid_sync <= 1'b0;
			rid_sync <= {C_S_AXI_ID_WIDTH{1'b0}};
			rdata_sync <= {C_S_AXI_DATA_WIDTH{1'b0}};
			rresp_sync <= {2{1'b0}};
			rlast_sync <= 1'b0;
			rvalid_sync <= 1'b0;
		end else if (M_AXI_BVALID) begin
			bid_sync <= M_AXI_BID;
			bresp_sync <= M_AXI_BRESP;
			bvalid_sync <= 1'b1;
		end else if (M_AXI_RVALID && M_AXI_RLAST) begin
			rid_sync <= M_AXI_RID;
			rdata_sync <= M_AXI_RDATA;
			rresp_sync <= M_AXI_RRESP;
			rlast_sync <= M_AXI_RLAST;
			rvalid_sync <= 1'b1;
		end else begin
			bvalid_sync <= 1'b0;
			rvalid_sync <= 1'b0;
		end
	end

	// Handshake signals
	assign S_AXI_AWREADY = awready_sync;
	assign S_AXI_WREADY = wready_sync;
	assign S_AXI_ARREADY = arready_sync;
	assign S_AXI_BREADY = bready_sync;
	assign S_AXI_RREADY = rready_sync;

	assign M_AXI_AWID = awid_sync;
	assign M_AXI_AWADDR = awaddr_sync;
	assign M_AXI_AWLEN = awlen_sync;
	assign M_AXI_AWSIZE = awsize_sync;
	assign M_AXI_AWBURST = awburst_sync;
	assign M_AXI_AWLOCK = awlock_sync;
	assign M_AXI_AWCACHE = awcache_sync;
	assign M_AXI_AWPROT = awprot_sync;
	assign M_AXI_AWQOS = awqos_sync;
	assign M_AXI_AWVALID = awvalid_sync;
	assign M_AXI_WDATA = wdata_sync;
	assign M_AXI_WSTRB = wstrb_sync;
	assign M_AXI_WLAST = wlast_sync;
	assign M_AXI_WVALID = wvalid_sync;

	assign M_AXI_BREADY = bready_sync;
	assign M_AXI_ARID = arid_sync;
	assign M_AXI_ARADDR = araddr_sync;
	assign M_AXI_ARLEN = arlen_sync;
	assign M_AXI_ARSIZE = arsize_sync;
	assign M_AXI_ARBURST = arburst_sync;
	assign M_AXI_ARLOCK = arlock_sync;
	assign M_AXI_ARCACHE = arcache_sync;
	assign M_AXI_ARPROT = arprot_sync;
	assign M_AXI_ARQOS = arqos_sync;
	assign M_AXI_ARVALID = arvalid_sync;
	assign M_AXI_RREADY = rready_sync;

	assign S_AXI_BID = bid_sync;
	assign S_AXI_BRESP = bresp_sync;
	assign S_AXI_BVALID = bvalid_sync;
	assign S_AXI_RID = rid_sync;
	assign S_AXI_RDATA = rdata_sync;
	assign S_AXI_RRESP = rresp_sync;
	assign S_AXI_RLAST = rlast_sync;
	assign S_AXI_RVALID = rvalid_sync;

	// FIFOs
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
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_fifo_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_fifo_out;
	wire wlast_fifo_out;
	wire wvalid_fifo_out;

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

	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_fifo_out;
	wire [1 : 0] bresp_fifo_out;
	wire bvalid_fifo_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_fifo_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_fifo_out;
	wire [1 : 0] rresp_fifo_out;
	wire rlast_fifo_out;
	wire rvalid_fifo_out;

	// Write channel FIFO
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awid_fifo_out <= {C_S_AXI_ID_WIDTH{1'b0}};
			awaddr_fifo_out <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			awlen_fifo_out <= {8{1'b0}};
			awsize_fifo_out <= {3{1'b0}};
			awburst_fifo_out <= {2{1'b0}};
			awlock_fifo_out <= 1'b0;
			awcache_fifo_out <= {4{1'b0}};
			awprot_fifo_out <= {3{1'b0}};
			awqos_fifo_out <= {4{1'b0}};
			awvalid_fifo_out <= 1'b0;
			wdata_fifo_out <= {C_S_AXI_DATA_WIDTH{1'b0}};
			wstrb_fifo_out <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			wlast_fifo_out <= 1'b0;
			wvalid_fifo_out <= 1'b0;
		end else if (awvalid_sync && awready_sync) begin
			awid_fifo_out <= awid_sync;
			awaddr_fifo_out <= awaddr_sync;
			awlen_fifo_out <= awlen_sync;
			awsize_fifo_out <= awsize_sync;
			awburst_fifo_out <= awburst_sync;
			awlock_fifo_out <= awlock_sync;
			awcache_fifo_out <= awcache_sync;
			awprot_fifo_out <= awprot_sync;
			awqos_fifo_out <= awqos_sync;
			awvalid_fifo_out <= 1'b1;
			wdata_fifo_out <= wdata_sync;
			wstrb_fifo_out <= wstrb_sync;
			wlast_fifo_out <= wlast_sync;
			wvalid_fifo_out <= 1'b1;
		end else begin
			awvalid_fifo_out <= 1'b0;
			wvalid_fifo_out <= 1'b0;
		end
	end

	// Read channel FIFO
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arid_fifo_out <= {C_S_AXI_ID_WIDTH{1'b0}};
			araddr_fifo_out <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			arlen_fifo_out <= {8{1'b0}};
			arsize_fifo_out <= {3{1'b0}};
			arburst_fifo_out <= {2{1'b0}};
			arlock_fifo_out <= 1'b0;
			arcache_fifo_out <= {4{1'b0}};
			arprot_fifo_out <= {3{1'b0}};
			arqos_fifo_out <= {4{1'b0}};
			arvalid_fifo_out <= 1'b0;
		end else if (arvalid_sync && arready_sync) begin
			arid_fifo_out <= arid_sync;
			araddr_fifo_out <= araddr_sync;
			arlen_fifo_out <= arlen_sync;
			arsize_fifo_out <= arsize_sync;
			arburst_fifo_out <= arburst_sync;
			arlock_fifo_out <= arlock_sync;
			arcache_fifo_out <= arcache_sync;
			arprot_fifo_out <= arprot_sync;
			arqos_fifo_out <= arqos_sync;
			arvalid_fifo_out <= 1'b1;
		end else begin
			arvalid_fifo_out <= 1'b0;
		end
	end

	// Response channel FIFO
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bid_fifo_out <= {C_S_AXI_ID_WIDTH{1'b0}};
			bresp_fifo_out <= {2{1'b0}};
			bvalid_fifo_out <= 1'b0;
			rid_fifo_out <= {C_S_AXI_ID_WIDTH{1'b0}};
			rdata_fifo_out <= {C_S_AXI_DATA_WIDTH{1'b0}};
			rresp_fifo_out <= {2{1'b0}};
			rlast_fifo_out <= 1'b0;
			rvalid_fifo_out <= 1'b0;
		end else if (bvalid_sync && bready_sync) begin
			bid_fifo_out <= bid_sync;
			bresp_fifo_out <= bresp_sync;
			bvalid_fifo_out <= 1'b1;
		end else if (rvalid_sync && rready_sync) begin
			rid_fifo_out <= rid_sync;
			rdata_fifo_out <= rdata_sync;
			rresp_fifo_out <= rresp_sync;
			rlast_fifo_out <= rlast_sync;
			rvalid_fifo_out <= 1'b1;
		end else begin
			bvalid_fifo_out <= 1'b0;
			rvalid_fifo_out <= 1'b0;
		end
	end

	// FIFOs to master ports
	assign M_AXI_AWID = awid_fifo_out;
	assign M_AXI_AWADDR = awaddr_fifo_out;
	assign M_AXI_AWLEN = awlen_fifo_out;
	assign M_AXI_AWSIZE = awsize_fifo_out;
	assign M_AXI_AWBURST = awburst_fifo_out;
	assign M_AXI_AWLOCK = awlock_fifo_out;
	assign M_AXI_AWCACHE = awcache_fifo_out;
	assign M_AXI_AWPROT = awprot_fifo_out;
	assign M_AXI_AWQOS = awqos_fifo_out;
	assign M_AXI_AWVALID = awvalid_fifo_out;
	assign M_AXI_WDATA = wdata_fifo_out;
	assign M_AXI_WSTRB = wstrb_fifo_out;
	assign M_AXI_WLAST = wlast_fifo_out;
	assign M_AXI_WVALID = wvalid_fifo_out;

	assign M_AXI_BREADY = bvalid_fifo_out;
	assign M_AXI_ARID = arid_fifo_out;
	assign M_AXI_ARADDR = araddr_fifo_out;
	assign M_AXI_ARLEN = arlen_fifo_out;
	assign M_AXI_ARSIZE = arsize_fifo_out;
	assign M_AXI_ARBURST = arburst_fifo_out;
	assign M_AXI_ARLOCK = arlock_fifo_out;
	assign M_AXI_ARCACHE = arcache_fifo_out;
	assign M_AXI_ARPROT = arprot_fifo_out;
	assign M_AXI_ARQOS = arqos_fifo_out;
	assign M_AXI_ARVALID = arvalid_fifo_out;
	assign M_AXI_RREADY = rvalid_fifo_out;

	// Response channel to slave ports
	assign S_AXI_BID = bid_fifo_out;
	assign S_AXI_BRESP = bresp_fifo_out;
	assign S_AXI_BVALID = bvalid_fifo_out;
	assign S_AXI_RID = rid_fifo_out;
	assign S_AXI_RDATA = rdata_fifo_out;
	assign S_AXI_RRESP = rresp_fifo_out;
	assign S_AXI_RLAST = rlast_fifo_out;
	assign S_AXI_RVALID = rvalid_fifo_out;

endmodule
