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

	wire				bready_ff;
	wire				arready_m;
	wire				rready_m;

	wire				awvalid_m;
	wire				wvalid_m;
	wire				arvalid_m;
	wire				bready_m;
	wire				rready_m;

	wire				awready_m;
	wire				wready_m;
	wire				bvalid_m;
	wire				rvalid_m;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	awid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_m;
	wire [7 : 0]			awlen_m;
	wire [2 : 0]			awsize_m;
	wire [1 : 0]			awburst_m;
	wire				awlock_m;
	wire [3 : 0]			awcache_m;
	wire [2 : 0]			awprot_m;
	wire [3 : 0]			awqos_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_m;
	wire				wlast_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	arid_m;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_m;
	wire [7 : 0]			arlen_m;
	wire [2 : 0]			arsize_m;
	wire [1 : 0]			arburst_m;
	wire				arlock_m;
	wire [3 : 0]			arcache_m;
	wire [2 : 0]			arprot_m;
	wire [3 : 0]			arqos_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	bid_m;
	wire [1 : 0]			bresp_m;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m;
	wire [1 : 0]			rresp_m;
	wire				rlast_m;

	wire				aresetn_m;

	reg [XCLOCK_FFS-1 : 0]	clk_ff;
	reg [XCLOCK_FFS-1 : 0]	clk_m;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			clk_ff <= {XCLOCK_FFS{1'b0}};
		end else begin
			clk_ff <= {clk_ff[XCLOCK_FFS-2 : 0], 1'b1};
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!aresetn_m) begin
			clk_m <= {XCLOCK_FFS{1'b0}};
		end else begin
			clk_m <= {clk_m[XCLOCK_FFS-2 : 0], 1'b1};
		end
	end

	assign M_AXI_ARESETN = aresetn_m;

	assign awid_m = awid_ff;
	assign awaddr_m = awaddr_ff;
	assign awlen_m = awlen_ff;
	assign awsize_m = awsize_ff;
	assign awburst_m = awburst_ff;
	assign awlock_m = awlock_ff;
	assign awcache_m = awcache_ff;
	assign awprot_m = awprot_ff;
	assign awqos_m = awqos_ff;
	assign wdata_m = wdata_ff;
	assign wstrb_m = wstrb_ff;
	assign wlast_m = wlast_ff;
	assign arid_m = arid_ff;
	assign araddr_m = araddr_ff;
	assign arlen_m = arlen_ff;
	assign arsize_m = arsize_ff;
	assign arburst_m = arburst_ff;
	assign arlock_m = arlock_ff;
	assign arcache_m = arcache_ff;
	assign arprot_m = arprot_ff;
	assign arqos_m = arqos_ff;
	assign bid_m = bid_ff;
	assign bresp_m = bresp_ff;
	assign rid_m = rid_ff;
	assign rdata_m = rdata_ff;
	assign rresp_m = rresp_ff;
	assign rlast_m = rlast_ff;

	assign awready_m = awready_ff;
	assign wready_m = wready_ff;
	assign arready_m = arready_ff;
	assign rready_m = rready_ff;
	assign bready_m = bready_ff;

	assign awvalid_m = awvalid_ff;
	assign wvalid_m = wvalid_ff;
	assign arvalid_m = arvalid_ff;
	assign bvalid_m = bvalid_ff;
	assign rvalid_m = rvalid_ff;

	assign M_AXI_AWID = awid_m;
	assign M_AXI_AWADDR = awaddr_m;
	assign M_AXI_AWLEN = awlen_m;
	assign M_AXI_AWSIZE = awsize_m;
	assign M_AXI_AWBURST = awburst_m;
	assign M_AXI_AWLOCK = awlock_m;
	assign M_AXI_AWCACHE = awcache_m;
	assign M_AXI_AWPROT = awprot_m;
	assign M_AXI_AWQOS = awqos_m;
	assign M_AXI_WDATA = wdata_m;
	assign M_AXI_WSTRB = wstrb_m;
	assign M_AXI_WLAST = wlast_m;
	assign M_AXI_ARID = arid_m;
	assign M_AXI_ARADDR = araddr_m;
	assign M_AXI_ARLEN = arlen_m;
	assign M_AXI_ARSIZE = arsize_m;
	assign M_AXI_ARBURST = arburst_m;
	assign M_AXI_ARLOCK = arlock_m;
	assign M_AXI_ARCACHE = arcache_m;
	assign M_AXI_ARPROT = arprot_m;
	assign M_AXI_ARQOS = arqos_m;
	assign M_AXI_BID = bid_m;
	assign M_AXI_BRESP = bresp_m;
	assign M_AXI_RID = rid_m;
	assign M_AXI_RDATA = rdata_m;
	assign M_AXI_RRESP = rresp_m;
	assign M_AXI_RLAST = rlast_m;

	assign S_AXI_AWREADY = awready_ff;
	assign S_AXI_WREADY = wready_ff;
	assign S_AXI_ARREADY = arready_ff;
	assign S_AXI_RREADY = rready_ff;
	assign S_AXI_BREADY = bready_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;

	assign M_AXI_AWVALID = awvalid_m;
	assign M_AXI_WVALID = wvalid_m;
	assign M_AXI_ARVALID = arvalid_m;
	assign M_AXI_BREADY = bready_m;
	assign M_AXI_RREADY = rready_m;

	assign S_AXI_BVALID = bvalid_ff;
	assign S_AXI_RVALID = rvalid_ff;

	assign awvalid_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? S_AXI_AWVALID : 1'b0;
	assign awready_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? M_AXI_AWREADY : 1'b0;
	assign wvalid_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? S_AXI_WVALID : 1'b0;
	assign wready_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? M_AXI_WREADY : 1'b0;
	assign arvalid_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? S_AXI_ARVALID : 1'b0;
	assign arready_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? M_AXI_ARREADY : 1'b0;
	assign rvalid_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? M_AXI_RVALID : 1'b0;
	assign rready_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? S_AXI_RREADY : 1'b0;
	assign bvalid_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? M_AXI_BVALID : 1'b0;
	assign bready_ff = (clk_ff == {XCLOCK_FFS{1'b1}})? S_AXI_BREADY : 1'b0;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			awid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			awaddr_ff <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			awlen_ff <= {8{1'b0}};
			awsize_ff <= {3{1'b0}};
			awburst_ff <= {2{1'b0}};
			awlock_ff <= 1'b0;
			awcache_ff <= {4{1'b0}};
			awprot_ff <= {3{1'b0}};
			awqos_ff <= {4{1'b0}};
			awvalid_ff <= 1'b0;
			wdata_ff <= {C_S_AXI_DATA_WIDTH{1'b0}};
			wstrb_ff <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			wlast_ff <= 1'b0;
			wvalid_ff <= 1'b0;
			arid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			araddr_ff <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			arlen_ff <= {8{1'b0}};
			arsize_ff <= {3{1'b0}};
			arburst_ff <= {2{1'b0}};
			arlock_ff <= 1'b0;
			arcache_ff <= {4{1'b0}};
			arprot_ff <= {3{1'b0}};
			arqos_ff <= {4{1'b0}};
			arvalid_ff <= 1'b0;
			bid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			bresp_ff <= {2{1'b0}};
			bvalid_ff <= 1'b0;
			rid_ff <= {C_S_AXI_ID_WIDTH{1'b0}};
			rdata_ff <= {C_S_AXI_DATA_WIDTH{1'b0}};
			rresp_ff <= {2{1'b0}};
			rlast_ff <= 1'b0;
			rvalid_ff <= 1'b0;
			awready_ff <= 1'b0;
			wready_ff <= 1'b0;
			arready_ff <= 1'b0;
			rready_ff <= 1'b0;
			bready_ff <= 1'b0;
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
		end else if (M_AXI_AWREADY && awvalid_ff) begin
			awvalid_ff <= 1'b0;
		end

		if (S_AXI_WVALID && S_AXI_WREADY) begin
			wdata_ff <= S_AXI_WDATA;
			wstrb_ff <= S_AXI_WSTRB;
			wlast_ff <= S_AXI_WLAST;
			wvalid_ff <= 1'b1;
		end else if (M_AXI_WREADY && wvalid_ff) begin
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
		end else if (M_AXI_ARREADY && arvalid_ff) begin
			arvalid_ff <= 1'b0;
		end

		if (M_AXI_BVALID && M_AXI_BREADY) begin
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= 1'b1;
		end else if (S_AXI_BREADY && bvalid_ff) begin
			bvalid_ff <= 1'b0;
		end

		if (M_AXI_RVALID && M_AXI_RREADY) begin
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= 1'b1;
		end else if (S_AXI_RREADY && rvalid_ff) begin
			rvalid_ff <= 1'b0;
		end

		if (S_AXI_AWVALID &&!S_AXI_AWREADY) begin
			awready_ff <= 1'b1;
		end else if (!S_AXI_AWVALID && S_AXI_AWREADY) begin
			awready_ff <= 1'b0;
		end

		if (S_AXI_WVALID &&!S_AXI_WREADY) begin
			wready_ff <= 1'b1;
		end else if (!S_AXI_WVALID && S_AXI_WREADY) begin
			wready_ff <= 1'b0;
		end

		if (S_AXI_ARVALID &&!S_AXI_ARREADY) begin
			arready_ff <= 1'b1;
		end else if (!S_AXI_ARVALID && S_AXI_ARREADY) begin
			arready_ff <= 1'b0;
		end

		if (M_AXI_RVALID &&!S_AXI_RREADY) begin
			rready_ff <= 1'b1;
		end else if (!M_AXI_RVALID && S_AXI_RREADY) begin
			rready_ff <= 1'b0;
		end

		if (M_AXI_BVALID &&!S_AXI_BREADY) begin
			bready_ff <= 1'b1;
		end else if (!M_AXI_BVALID && S_AXI_BREADY) begin
			bready_ff <= 1'b0;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		if (!aresetn_m) begin
			awvalid_m <= 1'b0;
			wvalid_m <= 1'b0;
			arvalid_m <= 1'b0;
			bready_m <= 1'b0;
			rready_m <= 1'b0;
			awready_m <= 1'b0;
			wready_m <= 1'b0;
			arready_m <= 1'b0;
			bvalid_m <= 1'b0;
			rvalid_m <= 1'b0;
		end else begin
			if (awvalid_ff &&!M_AXI_AWREADY) begin
				awvalid_m <= 1'b1;
			end else if (!awvalid_ff && M_AXI_AWREADY) begin
				awvalid_m <= 1'b0;
			end

			if (wvalid_ff &&!M_AXI_WREADY) begin
				wvalid_m <= 1'b1;
			end else if (!wvalid_ff && M_AXI_WREADY) begin
				wvalid_m <= 1'b0;
			end

			if (arvalid_ff &&!M_AXI_ARREADY) begin
				arvalid_m <= 1'b1;
			end else if (!arvalid_ff && M_AXI_ARREADY) begin
				arvalid_m <= 1'b0;
			end

			if (bvalid_ff &&!M_AXI_BREADY) begin
				bvalid_m <= 1'b1;
			end else if (!bvalid_ff && M_AXI_BREADY) begin
				bvalid_m <= 1'b0;
			end

			if (rvalid_ff &&!M_AXI_RREADY) begin
				rvalid_m <= 1'b1;
			end else if (!rvalid_ff && M_AXI_RREADY) begin
				rvalid_m <= 1'b0;
			end

			if (awready_ff &&!M_AXI_AWVALID) begin
				awready_m <= 1'b1;
			end else if (!awready_ff && M_AXI_AWVALID) begin
				awready_m <= 1'b0;
			end

			if (wready_ff &&!M_AXI_WVALID) begin
				wready_m <= 1'b1;
			end else if (!wready_ff && M_AXI_WVALID) begin
				wready_m <= 1'b0;
			end

			if (arready_ff &&!M_AXI_ARVALID) begin
				arready_m <= 1'b1;
			end else if (!arready_ff && M_AXI_ARVALID) begin
				arready_m <= 1'b0;
			end

			if (bready_ff &&!M_AXI_BVALID) begin
				bready_m <= 1'b1;
			end else if (!bready_ff && M_AXI_BVALID) begin
				bready_m <= 1'b0;
			end

			if (rready_ff &&!M_AXI_RVALID) begin
				rready_m <= 1'b1;
			end else if (!rready_ff && M_AXI_RVALID) begin
				rready_m <= 1'b0;
			end
		end
	end

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			aresetn_m <= 1'b0;
		end else if (clk_ff == {XCLOCK_FFS{1'b1}}) begin
			aresetn_m <= 1'b1;
		end
	end

endmodule
