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

	// Reset logic
	assign M_AXI_ARESETN = S_AXI_ARESETN;

	// Write channel
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

	// Write channel FIFO
	wire [LGFIFO-1 : 0] awfifo_cnt;
	wire awfifo_empty;
	wire awfifo_full;
	wire awfifo_rden;
	wire awfifo_wren;

	// Write channel handshake
	assign S_AXI_AWREADY = ~awfifo_full;
	assign M_AXI_AWVALID = ~awfifo_empty;
	assign awfifo_wren = S_AXI_AWVALID & ~awfifo_full;
	assign awfifo_rden = M_AXI_AWREADY & ~awfifo_empty;

	// Write channel data
	assign M_AXI_AWID = awid_ff;
	assign M_AXI_AWADDR = awaddr_ff;
	assign M_AXI_AWLEN = awlen_ff;
	assign M_AXI_AWSIZE = awsize_ff;
	assign M_AXI_AWBURST = awburst_ff;
	assign M_AXI_AWLOCK = awlock_ff;
	assign M_AXI_AWCACHE = awcache_ff;
	assign M_AXI_AWPROT = awprot_ff;
	assign M_AXI_AWQOS = awqos_ff;
	assign M_AXI_WDATA = wdata_ff;
	assign M_AXI_WSTRB = wstrb_ff;
	assign M_AXI_WLAST = wlast_ff;
	assign M_AXI_WVALID = wvalid_ff;

	// Write channel FIFO logic
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
			wdata_ff <= 0;
			wstrb_ff <= 0;
			wlast_ff <= 0;
			wvalid_ff <= 0;
		end else if (awfifo_wren) begin
			awid_ff <= S_AXI_AWID;
			awaddr_ff <= S_AXI_AWADDR;
			awlen_ff <= S_AXI_AWLEN;
			awsize_ff <= S_AXI_AWSIZE;
			awburst_ff <= S_AXI_AWBURST;
			awlock_ff <= S_AXI_AWLOCK;
			awcache_ff <= S_AXI_AWCACHE;
			awprot_ff <= S_AXI_AWPROT;
			awqos_ff <= S_AXI_AWQOS;
			awvalid_ff <= S_AXI_AWVALID;
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= S_AXI_WVALID;
		end
	end

	// Write channel FIFO counter
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			awfifo_cnt <= 0;
		end else if (awfifo_wren & ~awfifo_rden) begin
			awfifo_cnt <= awfifo_cnt + 1;
		end else if (~awfifo_wren & awfifo_rden) begin
			awfifo_cnt <= awfifo_cnt - 1;
		end
	end

	assign awfifo_empty = (awfifo_cnt == 0);
	assign awfifo_full = (awfifo_cnt == (1 << LGFIFO));

	// Read channel
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

	// Read channel FIFO
	wire [LGFIFO-1 : 0] arfifo_cnt;
	wire arfifo_empty;
	wire arfifo_full;
	wire arfifo_rden;
	wire arfifo_wren;

	// Read channel handshake
	assign S_AXI_ARREADY = ~arfifo_full;
	assign M_AXI_ARVALID = ~arfifo_empty;
	assign arfifo_wren = S_AXI_ARVALID & ~arfifo_full;
	assign arfifo_rden = M_AXI_ARREADY & ~arfifo_empty;

	// Read channel data
	assign M_AXI_ARID = arid_ff;
	assign M_AXI_ARADDR = araddr_ff;
	assign M_AXI_ARLEN = arlen_ff;
	assign M_AXI_ARSIZE = arsize_ff;
	assign M_AXI_ARBURST = arburst_ff;
	assign M_AXI_ARLOCK = arlock_ff;
	assign M_AXI_ARCACHE = arcache_ff;
	assign M_AXI_ARPROT = arprot_ff;
	assign M_AXI_ARQOS = arqos_ff;

	// Read channel FIFO logic
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
		end else if (arfifo_wren) begin
			arid_ff <= S_AXI_ARID;
			araddr_ff <= S_AXI_ARADDR;
			arlen_ff <= S_AXI_ARLEN;
			arsize_ff <= S_AXI_ARSIZE;
			arburst_ff <= S_AXI_ARBURST;
			arlock_ff <= S_AXI_ARLOCK;
			arcache_ff <= S_AXI_ARCACHE;
			arprot_ff <= S_AXI_ARPROT;
			arqos_ff <= S_AXI_ARQOS;
			arvalid_ff <= S_AXI_ARVALID;
		end
	end

	// Read channel FIFO counter
	always @(posedge S_AXI_ACLK) begin
		if (~S_AXI_ARESETN) begin
			arfifo_cnt <= 0;
		end else if (arfifo_wren & ~arfifo_rden) begin
			arfifo_cnt <= arfifo_cnt + 1;
		end else if (~arfifo_wren & arfifo_rden) begin
			arfifo_cnt <= arfifo_cnt - 1;
		end
	end

	assign arfifo_empty = (arfifo_cnt == 0);
	assign arfifo_full = (arfifo_cnt == (1 << LGFIFO));

	// Response channel
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_ff;
	wire [1 : 0] bresp_ff;
	wire bvalid_ff;

	// Response channel FIFO
	wire [LGFIFO-1 : 0] bfifo_cnt;
	wire bfifo_empty;
	wire bfifo_full;
	wire bfifo_rden;
	wire bfifo_wren;

	// Response channel handshake
	assign S_AXI_BVALID = ~bfifo_empty;
	assign M_AXI_BREADY = ~bfifo_full;
	assign bfifo_wren = M_AXI_BVALID & ~bfifo_full;
	assign bfifo_rden = S_AXI_BREADY & ~bfifo_empty;

	// Response channel data
	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;

	// Response channel FIFO logic
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bid_ff <= 0;
			bresp_ff <= 0;
			bvalid_ff <= 0;
		end else if (bfifo_wren) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= M_AXI_BVALID;
		end
	end

	// Response channel FIFO counter
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			bfifo_cnt <= 0;
		end else if (bfifo_wren & ~bfifo_rden) begin
			bfifo_cnt <= bfifo_cnt + 1;
		end else if (~bfifo_wren & bfifo_rden) begin
			bfifo_cnt <= bfifo_cnt - 1;
		end
	end

	assign bfifo_empty = (bfifo_cnt == 0);
	assign bfifo_full = (bfifo_cnt == (1 << LGFIFO));

	// Read data channel
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_ff;
	wire [1 : 0] rresp_ff;
	wire rlast_ff;
	wire rvalid_ff;

	// Read data channel FIFO
	wire [LGFIFO-1 : 0] rfifo_cnt;
	wire rfifo_empty;
	wire rfifo_full;
	wire rfifo_rden;
	wire rfifo_wren;

	// Read data channel handshake
	assign S_AXI_RVALID = ~rfifo_empty;
	assign M_AXI_RREADY = ~rfifo_full;
	assign rfifo_wren = M_AXI_RVALID & ~rfifo_full;
	assign rfifo_rden = S_AXI_RREADY & ~rfifo_empty;

	// Read data channel data
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;

	// Read data channel FIFO logic
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			rid_ff <= 0;
			rdata_ff <= 0;
			rresp_ff <= 0;
			rlast_ff <= 0;
			rvalid_ff <= 0;
		end else if (rfifo_wren) begin
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= M_AXI_RVALID;
		end
	end

	// Read data channel FIFO counter
	always @(posedge M_AXI_ACLK) begin
		if (~M_AXI_ARESETN) begin
			rfifo_cnt <= 0;
		end else if (rfifo_wren & ~rfifo_rden) begin
			rfifo_cnt <= rfifo_cnt + 1;
		end else if (~rfifo_wren & rfifo_rden) begin
			rfifo_cnt <= rfifo_cnt - 1;
		end
	end

	assign rfifo_empty = (rfifo_cnt == 0);
	assign rfifo_full = (rfifo_cnt == (1 << LGFIFO));

endmodule
