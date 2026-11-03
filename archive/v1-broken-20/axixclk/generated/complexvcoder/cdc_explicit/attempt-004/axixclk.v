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

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_reg;
	wire [7 : 0] awlen_reg;
	wire [2 : 0] awsize_reg;
	wire [1 : 0] awburst_reg;
	wire awlock_reg;
	wire [3 : 0] awcache_reg;
	wire [2 : 0] awprot_reg;
	wire [3 : 0] awqos_reg;
	wire awvalid_reg;
	wire awready_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_reg;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_reg;
	wire wlast_reg;
	wire wvalid_reg;
	wire wready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_reg;
	wire [1 : 0] bresp_reg;
	wire bvalid_reg;
	wire bready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_reg;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_reg;
	wire [7 : 0] arlen_reg;
	wire [2 : 0] arsize_reg;
	wire [1 : 0] arburst_reg;
	wire arlock_reg;
	wire [3 : 0] arcache_reg;
	wire [2 : 0] arprot_reg;
	wire [3 : 0] arqos_reg;
	wire arvalid_reg;
	wire arready_reg;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_reg;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_reg;
	wire [1 : 0] rresp_reg;
	wire rlast_reg;
	wire rvalid_reg;
	wire rready_reg;

	// AXI4 master signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr;
	wire [7 : 0] m_awlen;
	wire [2 : 0] m_awsize;
	wire [1 : 0] m_awburst;
	wire m_awlock;
	wire [3 : 0] m_awcache;
	wire [2 : 0] m_awprot;
	wire [3 : 0] m_awqos;
	wire m_awvalid;
	wire m_awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb;
	wire m_wlast;
	wire m_wvalid;
	wire m_wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_bid;
	wire [1 : 0] m_bresp;
	wire m_bvalid;
	wire m_bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr;
	wire [7 : 0] m_arlen;
	wire [2 : 0] m_arsize;
	wire [1 : 0] m_arburst;
	wire m_arlock;
	wire [3 : 0] m_arcache;
	wire [2 : 0] m_arprot;
	wire [3 : 0] m_arqos;
	wire m_arvalid;
	wire m_arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata;
	wire [1 : 0] m_rresp;
	wire m_rlast;
	wire m_rvalid;
	wire m_rready;

	// AXI4 slave to master handshake
	assign m_awid = S_AXI_AWID;
	assign m_awaddr = S_AXI_AWADDR;
	assign m_awlen = S_AXI_AWLEN;
	assign m_awsize = S_AXI_AWSIZE;
	assign m_awburst = S_AXI_AWBURST;
	assign m_awlock = S_AXI_AWLOCK;
	assign m_awcache = S_AXI_AWCACHE;
	assign m_awprot = S_AXI_AWPROT;
	assign m_awqos = S_AXI_AWQOS;
	assign m_awvalid = S_AXI_AWVALID;
	assign S_AXI_AWREADY = m_awready;

	assign m_wdata = S_AXI_WDATA;
	assign m_wstrb = S_AXI_WSTRB;
	assign m_wlast = S_AXI_WLAST;
	assign m_wvalid = S_AXI_WVALID;
	assign S_AXI_WREADY = m_wready;

	assign S_AXI_BID = bid_reg;
	assign S_AXI_BRESP = bresp_reg;
	assign S_AXI_BVALID = bvalid_reg;
	assign m_bready = S_AXI_BREADY;

	assign m_arid = S_AXI_ARID;
	assign m_araddr = S_AXI_ARADDR;
	assign m_arlen = S_AXI_ARLEN;
	assign m_arsize = S_AXI_ARSIZE;
	assign m_arburst = S_AXI_ARBURST;
	assign m_arlock = S_AXI_ARLOCK;
	assign m_arcache = S_AXI_ARCACHE;
	assign m_arprot = S_AXI_ARPROT;
	assign m_arqos = S_AXI_ARQOS;
	assign m_arvalid = S_AXI_ARVALID;
	assign S_AXI_ARREADY = m_arready;

	assign S_AXI_RID = rid_reg;
	assign S_AXI_RDATA = rdata_reg;
	assign S_AXI_RRESP = rresp_reg;
	assign S_AXI_RLAST = rlast_reg;
	assign S_AXI_RVALID = rvalid_reg;
	assign m_rready = S_AXI_RREADY;

	// AXI4 master to slave handshake
	assign S_AXI_ARESETN = m_axi_aresetn;

	assign S_AXI_AWID = m_awid;
	assign S_AXI_AWADDR = m_awaddr;
	assign S_AXI_AWLEN = m_awlen;
	assign S_AXI_AWSIZE = m_awsize;
	assign S_AXI_AWBURST = m_awburst;
	assign S_AXI_AWLOCK = m_awlock;
	assign S_AXI_AWCACHE = m_awcache;
	assign S_AXI_AWPROT = m_awprot;
	assign S_AXI_AWQOS = m_awqos;
	assign S_AXI_AWVALID = m_awvalid;
	assign m_awready = S_AXI_AWREADY;

	assign S_AXI_WDATA = m_wdata;
	assign S_AXI_WSTRB = m_wstrb;
	assign S_AXI_WLAST = m_wlast;
	assign S_AXI_WVALID = m_wvalid;
	assign m_wready = S_AXI_WREADY;

	assign bid_reg = m_bid;
	assign bresp_reg = m_bresp;
	assign bvalid_reg = m_bvalid;
	assign m_bready = S_AXI_BREADY;

	assign S_AXI_ARID = m_arid;
	assign S_AXI_ARADDR = m_araddr;
	assign S_AXI_ARLEN = m_arlen;
	assign S_AXI_ARSIZE = m_arsize;
	assign S_AXI_ARBURST = m_arburst;
	assign S_AXI_ARLOCK = m_arlock;
	assign S_AXI_ARCACHE = m_arcache;
	assign S_AXI_ARPROT = m_arprot;
	assign S_AXI_ARQOS = m_arqos;
	assign S_AXI_ARVALID = m_arvalid;
	assign m_arready = S_AXI_ARREADY;

	assign rid_reg = m_rid;
	assign rdata_reg = m_rdata;
	assign rresp_reg = m_rresp;
	assign rlast_reg = m_rlast;
	assign rvalid_reg = m_rvalid;
	assign m_rready = S_AXI_RREADY;

	// Reset handling
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_aresetn <= 1'b0;
		end else begin
			m_axi_aresetn <= 1'b1;
		end
	end

endmodule
