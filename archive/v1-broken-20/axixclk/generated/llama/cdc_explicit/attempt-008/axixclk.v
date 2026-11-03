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

	wire				awready_ff;
	wire				wready_ff;
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

	wire				m_axi_aresetn_ff;

	wire				awvalid_m;
	wire				wvalid_m;
	wire				arvalid_m;
	wire				bready_m;
	wire				rready_m;

	wire				awready_m;
	wire				wready_m;
	wire				arready_m;

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
	wire				bvalid_m;

	wire [C_S_AXI_ID_WIDTH-1 : 0]	rid_m;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_m;
	wire [1 : 0]			rresp_m;
	wire				rlast_m;
	wire				rvalid_m;

	assign M_AXI_ARESETN = m_axi_aresetn_ff;

	assign M_AXI_AWID = awid_m;
	assign M_AXI_AWADDR = awaddr_m;
	assign M_AXI_AWLEN = awlen_m;
	assign M_AXI_AWSIZE = awsize_m;
	assign M_AXI_AWBURST = awburst_m;
	assign M_AXI_AWLOCK = awlock_m;
	assign M_AXI_AWCACHE = awcache_m;
	assign M_AXI_AWPROT = awprot_m;
	assign M_AXI_AWQOS = awqos_m;
	assign M_AXI_AWVALID = awvalid_m;

	assign M_AXI_WDATA = wdata_m;
	assign M_AXI_WSTRB = wstrb_m;
	assign M_AXI_WLAST = wlast_m;
	assign M_AXI_WVALID = wvalid_m;

	assign M_AXI_BREADY = bready_m;

	assign M_AXI_ARID = arid_m;
	assign M_AXI_ARADDR = araddr_m;
	assign M_AXI_ARLEN = arlen_m;
	assign M_AXI_ARSIZE = arsize_m;
	assign M_AXI_ARBURST = arburst_m;
	assign M_AXI_ARLOCK = arlock_m;
	assign M_AXI_ARCACHE = arcache_m;
	assign M_AXI_ARPROT = arprot_m;
	assign M_AXI_ARQOS = arqos_m;
	assign M_AXI_ARVALID = arvalid_m;

	assign M_AXI_RREADY = rready_m;

	assign S_AXI_AWREADY = awready_ff;
	assign S_AXI_WREADY = wready_ff;
	assign S_AXI_ARREADY = arready_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;
	assign S_AXI_BVALID = bvalid_ff;

	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;
	assign S_AXI_RVALID = rvalid_ff;

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
			awready_ff <= 0;
			wready_ff <= 0;
			arready_ff <= 0;
			bid_ff <= 0;
			bresp_ff <= 0;
			bvalid_ff <= 0;
			bready_ff <= 0;
			rid_ff <= 0;
			rdata_ff <= 0;
			rresp_ff <= 0;
			rlast_ff <= 0;
			rvalid_ff <= 0;
			rready_ff <= 0;
		end else begin
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
			awready_ff <= M_AXI_AWREADY;
			wready_ff <= M_AXI_WREADY;
			arready_ff <= M_AXI_ARREADY;
			bid_ff <= M_AXI_BID;
			bresp_ff <= M_AXI_BRESP;
			bvalid_ff <= M_AXI_BVALID;
			bready_ff <= S_AXI_BREADY;
			rid_ff <= M_AXI_RID;
			rdata_ff <= M_AXI_RDATA;
			rresp_ff <= M_AXI_RRESP;
			rlast_ff <= M_AXI_RLAST;
			rvalid_ff <= M_AXI_RVALID;
			rready_ff <= S_AXI_RREADY;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_axi_aresetn_ff <= 1'b1;
			awvalid_m <= 1'b0;
			wvalid_m <= 1'b0;
			arvalid_m <= 1'b0;
			bready_m <= 1'b0;
			rready_m <= 1'b0;
			awid_m <= 0;
			awaddr_m <= 0;
			awlen_m <= 0;
			awsize_m <= 0;
			awburst_m <= 0;
			awlock_m <= 0;
			awcache_m <= 0;
			awprot_m <= 0;
			awqos_m <= 0;
			wdata_m <= 0;
			wstrb_m <= 0;
			wlast_m <= 0;
			arid_m <= 0;
			araddr_m <= 0;
			arlen_m <= 0;
			arsize_m <= 0;
			arburst_m <= 0;
			arlock_m <= 0;
			arcache_m <= 0;
			arprot_m <= 0;
			arqos_m <= 0;
			bid_m <= 0;
			bresp_m <= 0;
			bvalid_m <= 1'b0;
			rid_m <= 0;
			rdata_m <= 0;
			rresp_m <= 0;
			rlast_m <= 0;
			rvalid_m <= 1'b0;
		end else begin
			m_axi_aresetn_ff <= 1'b1;
			awvalid_m <= awvalid_ff;
			wvalid_m <= wvalid_ff;
			arvalid_m <= arvalid_ff;
			bready_m <= bready_ff;
			rready_m <= rready_ff;
			awid_m <= awid_ff;
			awaddr_m <= awaddr_ff;
			awlen_m <= awlen_ff;
			awsize_m <= awsize_ff;
			awburst_m <= awburst_ff;
			awlock_m <= awlock_ff;
			awcache_m <= awcache_ff;
			awprot_m <= awprot_ff;
			awqos_m <= awqos_ff;
			wdata_m <= wdata_ff;
			wstrb_m <= wstrb_ff;
			wlast_m <= wlast_ff;
			arid_m <= arid_ff;
			araddr_m <= araddr_ff;
			arlen_m <= arlen_ff;
			arsize_m <= arsize_ff;
			arburst_m <= arburst_ff;
			arlock_m <= arlock_ff;
			arcache_m <= arcache_ff;
			arprot_m <= arprot_ff;
			arqos_m <= arqos_ff;
			bid_m <= bid_ff;
			bresp_m <= bresp_ff;
			bvalid_m <= bvalid_ff;
			rid_m <= rid_ff;
			rdata_m <= rdata_ff;
			rresp_m <= rresp_ff;
			rlast_m <= rlast_ff;
			rvalid_m <= rvalid_ff;
		end
	end

endmodule
