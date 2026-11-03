```verilog
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
	wire m_axi_awready_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_ff;
	wire wlast_ff;
	wire wvalid_ff;
	wire m_axi_wready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_ff;
	wire [1 : 0] bresp_ff;
	wire bvalid_ff;
	wire m_axi_bready_ff;
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
	wire m_axi_arready_ff;
	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_ff;
	wire [1 : 0] rresp_ff;
	wire rlast_ff;
	wire rvalid_ff;
	wire m_axi_rready_ff;

	// AXI4 master signals
	wire m_axi_awvalid;
	wire [C_S_AXI_ID_WIDTH-1 : 0] m_axi_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr;
	wire [7 : 0] m_axi_awlen;
	wire [2 : 0] m_axi_awsize;
	wire [1 : 0] m_axi_awburst;
	wire m_axi_awlock;
	wire [3 : 0] m_axi_awcache;
	wire [2 : 0] m_axi_awprot;
	wire [3 : 0] m_axi_awqos;
	wire m_axi_wvalid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_axi_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb;
	wire m_axi_wlast;
	wire m_axi_bready;

	// AXI4 slave signals
	wire s_axi_awready;
	wire s_axi_wready;
	wire s_axi_bvalid;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid;
	wire [1 : 0] s_axi_bresp;
	wire s_axi_arready;
	wire s_axi_rvalid;
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata;
	wire [1 : 0] s_axi_rresp;
	wire s_axi_rlast;

	// AXI4 master reset
	wire m_axi_aresetn_ff;

	// Clock domain crossing for AXI4 master reset
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_axi_aresetn_ff <= 1'b0;
		end else begin
			m_axi_aresetn_ff <= 1'b1;
		end
	end

	// AXI4 master interface
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_arvalid = arvalid_ff & m_axi_arready_ff;
	assign m_axi_arid = arid_ff;
	assign m_axi_araddr = araddr_ff;
	assign m_axi_arlen = arlen_ff;
	assign m_axi_arsize = arsize_ff;
	assign m_axi_arburst = arburst_ff;
	assign m_axi_arlock = arlock_ff;
	assign m_axi_arcache = arcache_ff;
	assign m_axi_arprot = arprot_ff;
	assign m_axi_arqos = arqos_ff;

	// AXI4 slave interface signals
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_axi_bvalid = m_axi_bvalid_ff;
	assign s_axi_bid = bid_ff;
	assign s_axi_bresp = bresp_ff;
	assign s_axi_arready = m_axi_arready_ff;
	assign s_axi_rvalid = m_axi_rvalid_ff;
	assign s_axi_rid = rid_ff;
	assign s_axi_rdata = rdata_ff;
	assign s_axi_rresp = rresp_ff;
	assign s_axi_rlast = rlast_ff;

	// AXI4 master interface signals
	assign m_axi_awvalid = awvalid_ff & m_axi_awready_ff;
	assign m_axi_awid = awid_ff;
	assign m_axi_awaddr = awaddr_ff;
	assign m_axi_awlen = awlen_ff;
	assign m_axi_awsize = awsize_ff;
	assign m_axi_awburst = awburst_ff;
	assign m_axi_awlock = awlock_ff;
	assign m_axi_awcache = awcache_ff;
	assign m_axi_awprot = awprot_ff;
	assign m_axi_awqos = awqos_ff;
	assign m_axi_wvalid = wvalid_ff & m_axi_wready_ff;
	assign m_axi_wdata = wdata_ff;
	assign m_axi_wstrb = wstrb_ff;
	assign m_axi_wlast = wlast_ff;
	assign m_axi_bready = bvalid_ff;

	// AXI4 slave interface signals
	assign s_axi_awready = m_axi_awready_ff;
	assign s_axi_wready = m_axi_wready_ff;
	assign s_ax