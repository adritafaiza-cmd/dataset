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
	wire				arready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_ff;
	wire [1 : 0]			bresp_ff;
	wire				bvalid_ff;
	wire				bready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_ff;
	wire [1 : 0]			rresp_ff;
	wire				rlast_ff;
	wire				rvalid_ff;
	wire				rready_ff;

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
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_reg;
	reg				wlast_reg;
	reg				wvalid_reg;
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
	reg [C_S_AXI_ID_WIDTH-1 : 0]	bid_reg;
	reg [1 : 0]			bresp_reg;
	reg				bvalid_reg;
	reg				bready_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_reg;
	reg [1 : 0]			rresp_reg;
	reg				rlast_reg;
	reg				rvalid_reg;
	reg				rready_reg;

	wire [LGFIFO-1 : 0]	awfifo_empty;
	wire [LGFIFO-1 : 0]	awfifo_full;
	wire [LGFIFO-1 : 0]	wfifo_empty;
	wire [LGFIFO-1 : 0]	wfifo_full;
	wire [LGFIFO-1 : 0]	arfifo_empty;
	wire [LGFIFO-1 : 0]	arfifo_full;
	wire [LGFIFO-1 : 0]	rfifo_empty;
	wire [LGFIFO-1 : 0]	rfifo_full;
	wire [LGFIFO-1 : 0]	bfifo_empty;
	wire [LGFIFO-1 : 0]	bfifo_full;

	wire				awfifo_wr;
	wire				awfifo_rd;
	wire				wfifo_wr;
	wire				wfifo_rd;
	wire				arfifo_wr;
	wire				arfifo_rd;
	wire				rfifo_wr;
	wire				rfifo_rd;
	wire				bfifo_wr;
	wire				bfifo_rd;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awfifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awfifo_addr_out;
	wire [7 : 0]			awfifo_len_out;
	wire [2 : 0]			awfifo_size_out;
	wire [1 : 0]			awfifo_burst_out;
	wire				awfifo_lock_out;
	wire [3 : 0]			awfifo_cache_out;
	wire [2 : 0]			awfifo_prot_out;
	wire [3 : 0]			awfifo_qos_out;
	wire				awfifo_valid_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wfifo_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wfifo_strb_out;
	wire				wfifo_last_out;
	wire				wfifo_valid_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arfifo_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	arfifo_addr_out;
	wire [7 : 0]			arfifo_len_out;
	wire [2 : 0]			arfifo_size_out;
	wire [1 : 0]			arfifo_burst_out;
	wire				arfifo_lock_out;
	wire [3 : 0]			arfifo_cache_out;
	wire [2 : 0]			arfifo_prot_out;
	wire [3 : 0]			arfifo_qos_out;
	wire				arfifo_valid_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rfifo_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rfifo_data_out;
	wire [1 : 0]			rfifo_resp_out;
	wire				rfifo_last_out;
	wire				rfifo_valid_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bfifo_out;
	wire [1 : 0]			bfifo_resp_out;
	wire				bfifo_valid_out;

	assign M_AXI_ARESETN = S_AXI_ARESETN;

	assign awfifo_wr = S_AXI_AWVALID && S_AXI_AWREADY;
	assign awfifo_rd = M_AXI_AWREADY && M_AXI_AWVALID;
	assign wfifo_wr = S_AXI_WVALID && S_AXI_WREADY;
	assign wfifo_rd = M_AXI_WREADY && M_AXI_WVALID;
	assign arfifo_wr = S_AXI_ARVALID && S_AXI_ARREADY;
	assign arfifo_rd = M_AXI_ARREADY && M_AXI_ARVALID;
	assign rfifo_wr = M_AXI_RVALID && M_AXI_RREADY;
	assign rfifo_rd = S_AXI_RVALID && S_AXI_RREADY;
	assign bfifo_wr = M_AXI_BVALID && M_AXI_BREADY;
	assign bfifo_rd = S_AXI_BVALID && S_AXI_BREADY;

	assign awfifo_out = awid_reg;
	assign awfifo_addr_out = awaddr_reg;
	assign awfifo_len_out = awlen_reg;
	assign awfifo_size_out = awsize_reg;
	assign awfifo_burst_out = awburst_reg;
	assign awfifo_lock_out = awlock_reg;
	assign awfifo_cache_out = awcache_reg;
	assign awfifo_prot_out = awprot_reg;
	assign awfifo_qos_out = awqos_reg;
	assign awfifo_valid_out = awvalid_reg;

	assign wfifo_out = wdata_reg;
	assign wfifo_strb_out = wstrb_reg;
	assign wfifo_last_out = wlast_reg;
	assign wfifo_valid_out = wvalid_reg;

	assign arfifo_out = arid_reg;
	assign arfifo_addr_out = araddr_reg;
	assign arfifo_len_out = arlen_reg;
	assign arfifo_size_out = arsize_reg;
	assign arfifo_burst_out = arburst_reg;
	assign arfifo_lock_out = arlock_reg;
	assign arfifo_cache_out = arcache_reg;
	assign arfifo_prot_out = arprot_reg;
	assign arfifo_qos_out = arqos_reg;
	assign arfifo_valid_out = arvalid_reg;

	assign rfifo_out = rid_reg;
	assign rfifo_data_out = rdata_reg;
	assign rfifo_resp_out = rresp_reg;
	assign rfifo_last_out = rlast_reg;
	assign rfifo_valid_out = rvalid_reg;

	assign bfifo_out = bid_reg;
	assign bfifo_resp_out = bresp_reg;
	assign bfifo_valid_out = bvalid_reg;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
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
			wdata_reg <= 0;
			wstrb_reg <= 0;
			wlast_reg <= 0;
			wvalid_reg <= 0;
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
			bid_reg <= 0;
			bresp_reg <= 0;
			bvalid_reg <= 0;
			rid_reg <= 0;
			rdata_reg <= 0;
			rresp_reg <= 0;
			rlast_reg <= 0;
			rvalid_reg <= 0;
		end else begin
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
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
			end else if (!awfifo_wr &&!awfifo_rd) begin
				awvalid_reg <= 1'b0;
			end

			if (S_AXI_WVALID && S_AXI_WREADY) begin
				wdata_reg <= S_AXI_WDATA;
				wstrb_reg <= S_AXI_WSTRB;
				wlast_reg <= S_AXI_WLAST;
				wvalid_reg <= 1'b1;
			end else if (!wfifo_wr &&!wfifo_rd) begin
				wvalid_reg <= 1'b0;
			end

			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
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
			end else if (!arfifo_wr &&!arfifo_rd) begin
				arvalid_reg <= 1'b0;
			end

			if (M_AXI_BVALID && M_AXI_BREADY) begin
				bid_reg <= M_AXI_BID;
				bresp_reg <= M_AXI_BRESP;
				bvalid_reg <= 1'b1;
			end else if (!bfifo_wr &&!bfifo_rd) begin
				bvalid_reg <= 1'b0;
			end

			if (M_AXI_RVALID && M_AXI_RREADY) begin
				rid_reg <= M_AXI_RID;
				rdata_reg <= M_AXI_RDATA;
				rresp_reg <= M_AXI_RRESP;
				rlast_reg <= M_AXI_RLAST;
				rvalid_reg <= 1'b1;
			end else if (!rfifo_wr &&!rfifo_rd) begin
				rvalid_reg <= 1'b0;
			end
		end
	end

	assign S_AXI_AWREADY = awfifo_empty &&!awfifo_wr;
	assign S_AXI_WREADY = wfifo_empty &&!wfifo_wr;
	assign S_AXI_ARREADY = arfifo_empty &&!arfifo_wr;
	assign S_AXI_BID = bfifo_out;
	assign S_AXI_BRESP = bfifo_resp_out;
	assign S_AXI_BVALID = bfifo_valid_out;
	assign S_AXI_RID = rfifo_out;
	assign S_AXI_RDATA = rfifo_data_out;
	assign S_AXI_RRESP = rfifo_resp_out;
	assign S_AXI_RLAST = rfifo_last_out;
	assign S_AXI_RVALID = rfifo_valid_out;

	assign M_AXI_AWID = awfifo_out;
	assign M_AXI_AWADDR = awfifo_addr_out;
	assign M_AXI_AWLEN = awfifo_len_out;
	assign M_AXI_AWSIZE = awfifo_size_out;
	assign M_AXI_AWBURST = awfifo_burst_out;
	assign M_AXI_AWLOCK = awfifo_lock_out;
	assign M_AXI_AWCACHE = awfifo_cache_out;
	assign M_AXI_AWPROT = awfifo_prot_out;
	assign M_AXI_AWQOS = awfifo_qos_out;
	assign M_AXI_AWVALID = awfifo_valid_out;
	assign M_AXI_WDATA = wfifo_out;
	assign M_AXI_WSTRB = wfifo_strb_out;
	assign M_AXI_WLAST = wfifo_last_out;
	assign M_AXI_WVALID = wfifo_valid_out;
	assign M_AXI_BREADY = bfifo_empty &&!bfifo_wr;
	assign M_AXI_ARID = arfifo_out;
	assign M_AXI_ARADDR = arfifo_addr_out;
	assign M_AXI_ARLEN = arfifo_len_out;
	assign M_AXI_ARSIZE = arfifo_size_out;
	assign M_AXI_ARBURST = arfifo_burst_out;
	assign M_AXI_ARLOCK = arfifo_lock_out;
	assign M_AXI_ARCACHE = arfifo_cache_out;
	assign M_AXI_ARPROT = arfifo_prot_out;
	assign M_AXI_ARQOS = arfifo_qos_out;
	assign M_AXI_ARVALID = arfifo_valid_out;
	assign M_AXI_RREADY = rfifo_empty &&!rfifo_wr;

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 2 + 4 + 1),
		.C_DEPTH(1 << LGFIFO)
	) awfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wr(awfifo_wr),
		.rd(awfifo_rd),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.dout({awid_ff, awaddr_ff, awlen_ff, awsize_ff, awburst_ff, awlock_ff, awcache_ff, awprot_ff, awqos_ff}),
		.empty(awfifo_empty),
		.full(awfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 + 1),
		.C_DEPTH(1 << LGFIFO)
	) wfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wr(wfifo_wr),
		.rd(wfifo_rd),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST, S_AXI_WVALID}),
		.dout({wdata_ff, wstrb_ff, wlast_ff, wvalid_ff}),
		.empty(wfifo_empty),
		.full(wfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 2 + 4 + 1),
		.C_DEPTH(1 << LGFIFO)
	) arfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wr(arfifo_wr),
		.rd(arfifo_rd),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.dout({arid_ff, araddr_ff, arlen_ff, arsize_ff, arburst_ff, arlock_ff, arcache_ff, arprot_ff, arqos_ff}),
		.empty(arfifo_empty),
		.full(arfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 + 1),
		.C_DEPTH(1 << LGFIFO)
	) rfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wr(rfifo_wr),
		.rd(rfifo_rd),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST, M_AXI_RVALID}),
		.dout({rid_ff, rdata_ff, rresp_ff, rlast_ff, rvalid_ff}),
		.empty(rfifo_empty),
		.full(rfifo_full)
	);

	fifo #(
		.C_WIDTH(C_S_AXI_ID_WIDTH + 2 + 1),
		.C_DEPTH(1 << LGFIFO)
	) bfifo (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.wr(bfifo_wr),
		.rd(bfifo_rd),
		.din({M_AXI_BID, M_AXI_BRESP, M_AXI_BVALID}),
		.dout({bid_ff, bresp_ff, bvalid_ff}),
		.empty(bfifo_empty),
		.full(bfifo_full)
	);

endmodule
