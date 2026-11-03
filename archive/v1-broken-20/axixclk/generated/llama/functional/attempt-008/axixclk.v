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
	wire				bready_ff;
	wire				rready_ff;

	wire				awvalid_m;
	wire				wvalid_m;
	wire				arvalid_m;
	wire				bvalid_m;
	wire				rvalid_m;

	wire				awready_m;
	wire				wready_m;
	wire				arready_m;
	wire				bready_m;
	wire				rready_m;

	wire				m_axi_aresetn_ff;

	assign M_AXI_ARESETN = m_axi_aresetn_ff;

	assign M_AXI_AWID = awid_ff;
	assign M_AXI_AWADDR = awaddr_ff;
	assign M_AXI_AWLEN = awlen_ff;
	assign M_AXI_AWSIZE = awsize_ff;
	assign M_AXI_AWBURST = awburst_ff;
	assign M_AXI_AWLOCK = awlock_ff;
	assign M_AXI_AWCACHE = awcache_ff;
	assign M_AXI_AWPROT = awprot_ff;
	assign M_AXI_AWQOS = awqos_ff;
	assign M_AXI_AWVALID = awvalid_m;
	assign M_AXI_WDATA = wdata_ff;
	assign M_AXI_WSTRB = wstrb_ff;
	assign M_AXI_WLAST = wlast_ff;
	assign M_AXI_WVALID = wvalid_m;
	assign M_AXI_BREADY = bready_m;
	assign M_AXI_ARID = arid_ff;
	assign M_AXI_ARADDR = araddr_ff;
	assign M_AXI_ARLEN = arlen_ff;
	assign M_AXI_ARSIZE = arsize_ff;
	assign M_AXI_ARBURST = arburst_ff;
	assign M_AXI_ARLOCK = arlock_ff;
	assign M_AXI_ARCACHE = arcache_ff;
	assign M_AXI_ARPROT = arprot_ff;
	assign M_AXI_ARQOS = arqos_ff;
	assign M_AXI_ARVALID = arvalid_m;
	assign M_AXI_RREADY = rready_m;

	assign S_AXI_AWREADY = awready_ff;
	assign S_AXI_WREADY = wready_ff;
	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;
	assign S_AXI_ARREADY = arready_ff;
	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
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
			awready_ff <= 0;
			wready_ff <= 0;
			arready_ff <= 0;
			bready_ff <= 0;
			rready_ff <= 0;
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
			end else if (M_AXI_AWREADY && M_AXI_AWVALID) begin
				awvalid_ff <= 1'b0;
			end

			if (S_AXI_WVALID && S_AXI_WREADY) begin
				wdata_ff <= S_AXI_WDATA;
				wstrb_ff <= S_AXI_WSTRB;
				wlast_ff <= S_AXI_WLAST;
				wvalid_ff <= 1'b1;
			end else if (M_AXI_WREADY && M_AXI_WVALID) begin
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
			end else if (M_AXI_ARREADY && M_AXI_ARVALID) begin
				arvalid_ff <= 1'b0;
			end

			if (M_AXI_BVALID && M_AXI_BREADY) begin
				bid_ff <= M_AXI_BID;
				bresp_ff <= M_AXI_BRESP;
				bvalid_ff <= 1'b1;
			end else if (S_AXI_BREADY && S_AXI_BVALID) begin
				bvalid_ff <= 1'b0;
			end

			if (M_AXI_RVALID && M_AXI_RREADY) begin
				rid_ff <= M_AXI_RID;
				rdata_ff <= M_AXI_RDATA;
				rresp_ff <= M_AXI_RRESP;
				rlast_ff <= M_AXI_RLAST;
				rvalid_ff <= 1'b1;
			end else if (S_AXI_RREADY && S_AXI_RVALID) begin
				rvalid_ff <= 1'b0;
			end

			if (S_AXI_AWVALID && ~awvalid_ff) begin
				awready_ff <= 1'b1;
			end else if (M_AXI_AWREADY && M_AXI_AWVALID) begin
				awready_ff <= 1'b0;
			end

			if (S_AXI_WVALID && ~wvalid_ff) begin
				wready_ff <= 1'b1;
			end else if (M_AXI_WREADY && M_AXI_WVALID) begin
				wready_ff <= 1'b0;
			end

			if (S_AXI_ARVALID && ~arvalid_ff) begin
				arready_ff <= 1'b1;
			end else if (M_AXI_ARREADY && M_AXI_ARVALID) begin
				arready_ff <= 1'b0;
			end

			if (M_AXI_BVALID && ~bvalid_ff) begin
				bready_ff <= 1'b1;
			end else if (S_AXI_BREADY && S_AXI_BVALID) begin
				bready_ff <= 1'b0;
			end

			if (M_AXI_RVALID && ~rvalid_ff) begin
				rready_ff <= 1'b1;
			end else if (S_AXI_RREADY && S_AXI_RVALID) begin
				rready_ff <= 1'b0;
			end
		end
	end

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_ff) begin
		if (~m_axi_aresetn_ff) begin
			awvalid_m <= 0;
			wvalid_m <= 0;
			arvalid_m <= 0;
			bvalid_m <= 0;
			rvalid_m <= 0;
			awready_m <= 0;
			wready_m <= 0;
			arready_m <= 0;
			bready_m <= 0;
			rready_m <= 0;
		end else begin
			if (awvalid_ff && ~awvalid_m) begin
				awvalid_m <= 1'b1;
			end else if (M_AXI_AWREADY && M_AXI_AWVALID) begin
				awvalid_m <= 1'b0;
			end

			if (wvalid_ff && ~wvalid_m) begin
				wvalid_m <= 1'b1;
			end else if (M_AXI_WREADY && M_AXI_WVALID) begin
				wvalid_m <= 1'b0;
			end

			if (arvalid_ff && ~arvalid_m) begin
				arvalid_m <= 1'b1;
			end else if (M_AXI_ARREADY && M_AXI_ARVALID) begin
				arvalid_m <= 1'b0;
			end

			if (bvalid_ff && ~bvalid_m) begin
				bvalid_m <= 1'b1;
			end else if (S_AXI_BREADY && S_AXI_BVALID) begin
				bvalid_m <= 1'b0;
			end

			if (rvalid_ff && ~rvalid_m) begin
				rvalid_m <= 1'b1;
			end else if (S_AXI_RREADY && S_AXI_RVALID) begin
				rvalid_m <= 1'b0;
			end

			if (M_AXI_AWVALID && ~awready_m) begin
				awready_m <= 1'b1;
			end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				awready_m <= 1'b0;
			end

			if (M_AXI_WVALID && ~wready_m) begin
				wready_m <= 1'b1;
			end else if (S_AXI_WVALID && S_AXI_WREADY) begin
				wready_m <= 1'b0;
			end

			if (M_AXI_ARVALID && ~arready_m) begin
				arready_m <= 1'b1;
			end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				arready_m <= 1'b0;
			end

			if (M_AXI_BVALID && ~bready_m) begin
				bready_m <= 1'b1;
			end else if (S_AXI_BREADY && S_AXI_BVALID) begin
				bready_m <= 1'b0;
			end

			if (M_AXI_RVALID && ~rready_m) begin
				rready_m <= 1'b1;
			end else if (S_AXI_RREADY && S_AXI_RVALID) begin
				rready_m <= 1'b0;
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (~S_AXI_ARESETN) begin
			m_axi_aresetn_ff <= 1'b1;
		end else begin
			m_axi_aresetn_ff <= ~S_AXI_ARESETN;
		end
	end
endmodule
