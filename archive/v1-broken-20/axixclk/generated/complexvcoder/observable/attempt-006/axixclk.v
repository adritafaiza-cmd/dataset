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

	// Instantiate the clock domain crossing modules
	wire slave_to_master_awvalid, slave_to_master_awready, slave_to_master_awvalid_out, slave_to_master_awready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_to_master_awid, slave_to_master_awid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] slave_to_master_awaddr, slave_to_master_awaddr_out;
	wire [7 : 0] slave_to_master_awlen, slave_to_master_awlen_out;
	wire [2 : 0] slave_to_master_awsize, slave_to_master_awsize_out;
	wire [1 : 0] slave_to_master_awburst, slave_to_master_awburst_out;
	wire slave_to_master_awlock, slave_to_master_awlock_out;
	wire [3 : 0] slave_to_master_awcache, slave_to_master_awcache_out;
	wire [2 : 0] slave_to_master_awprot, slave_to_master_awprot_out;
	wire [3 : 0] slave_to_master_awqos, slave_to_master_awqos_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] slave_to_master_wdata, slave_to_master_wdata_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] slave_to_master_wstrb, slave_to_master_wstrb_out;
	wire slave_to_master_wlast, slave_to_master_wlast_out;
	wire slave_to_master_wvalid, slave_to_master_wvalid_out;
	wire slave_to_master_wready, slave_to_master_wready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_to_master_bid, slave_to_master_bid_out;
	wire [1 : 0] slave_to_master_bresp, slave_to_master_bresp_out;
	wire slave_to_master_bvalid, slave_to_master_bvalid_out;
	wire slave_to_master_bready, slave_to_master_bready_out;

	wire master_to_slave_awvalid, master_to_slave_awready, master_to_slave_awvalid_out, master_to_slave_awready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_to_slave_awid, master_to_slave_awid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] master_to_slave_awaddr, master_to_slave_awaddr_out;
	wire [7 : 0] master_to_slave_awlen, master_to_slave_awlen_out;
	wire [2 : 0] master_to_slave_awsize, master_to_slave_awsize_out;
	wire [1 : 0] master_to_slave_awburst, master_to_slave_awburst_out;
	wire master_to_slave_awlock, master_to_slave_awlock_out;
	wire [3 : 0] master_to_slave_awcache, master_to_slave_awcache_out;
	wire [2 : 0] master_to_slave_awprot, master_to_slave_awprot_out;
	wire [3 : 0] master_to_slave_awqos, master_to_slave_awqos_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] master_to_slave_wdata, master_to_slave_wdata_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] master_to_slave_wstrb, master_to_slave_wstrb_out;
	wire master_to_slave_wlast, master_to_slave_wlast_out;
	wire master_to_slave_wvalid, master_to_slave_wvalid_out;
	wire master_to_slave_wready, master_to_slave_wready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_to_slave_bid, master_to_slave_bid_out;
	wire [1 : 0] master_to_slave_bresp, master_to_slave_bresp_out;
	wire master_to_slave_bvalid, master_to_slave_bvalid_out;
	wire master_to_slave_bready, master_to_slave_bready_out;

	wire slave_to_master_arvalid, slave_to_master_arready, slave_to_master_arvalid_out, slave_to_master_arready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_to_master_arid, slave_to_master_arid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] slave_to_master_araddr, slave_to_master_araddr_out;
	wire [7 : 0] slave_to_master_arlen, slave_to_master_arlen_out;
	wire [2 : 0] slave_to_master_arsize, slave_to_master_arsize_out;
	wire [1 : 0] slave_to_master_arburst, slave_to_master_arburst_out;
	wire slave_to_master_arlock, slave_to_master_arlock_out;
	wire [3 : 0] slave_to_master_arcache, slave_to_master_arcache_out;
	wire [2 : 0] slave_to_master_arprot, slave_to_master_arprot_out;
	wire [3 : 0] slave_to_master_arqos, slave_to_master_arqos_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] slave_to_master_rdata, slave_to_master_rdata_out;
	wire [1 : 0] slave_to_master_rresp, slave_to_master_rresp_out;
	wire slave_to_master_rlast, slave_to_master_rlast_out;
	wire slave_to_master_rvalid, slave_to_master_rvalid_out;
	wire slave_to_master_rready, slave_to_master_rready_out;

	wire master_to_slave_arvalid, master_to_slave_arready, master_to_slave_arvalid_out, master_to_slave_arready_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_to_slave_arid, master_to_slave_arid_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] master_to_slave_araddr, master_to_slave_araddr_out;
	wire [7 : 0] master_to_slave_arlen, master_to_slave_arlen_out;
	wire [2 : 0] master_to_slave_arsize, master_to_slave_arsize_out;
	wire [1 : 0] master_to_slave_arburst, master_to_slave_arburst_out;
	wire master_to_slave_arlock, master_to_slave_arlock_out;
	wire [3 : 0] master_to_slave_arcache, master_to_slave_arcache_out;
	wire [2 : 0] master_to_slave_arprot, master_to_slave_arprot_out;
	wire [3 : 0] master_to_slave_arqos, master_to_slave_arqos_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] master_to_slave_rdata, master_to_slave_rdata_out;
	wire [1 : 0] master_to_slave_rresp, master_to_slave_rresp_out;
	wire master_to_slave_rlast, master_to_slave_rlast_out;
	wire master_to_slave_rvalid, master_to_slave_rvalid_out;
	wire master_to_slave_rready, master_to_slave_rready_out;

	// Instantiate the AXI clock domain crossing modules
	assign M_AXI_ACLK = S_AXI_ACLK;
	assign M_AXI_ARESETN = S_AXI_ARESETN;

	assign M_AXI_AWID = slave_to_master_awid_out;
	assign M_AXI_AWADDR = slave_to_master_awaddr_out;
	assign M_AXI_AWLEN = slave_to_master_awlen_out;
	assign M_AXI_AWSIZE = slave_to_master_awsize_out;
	assign M_AXI_AWBURST = slave_to_master_awburst_out;
	assign M_AXI_AWLOCK = slave_to_master_awlock_out;
	assign M_AXI_AWCACHE = slave_to_master_awcache_out;
	assign M_AXI_AWPROT = slave_to_master_awprot_out;
	assign M_AXI_AWQOS = slave_to_master_awqos_out;
	assign M_AXI_AWVALID = slave_to_master_awvalid_out;
	assign slave_to_master_awready = M_AXI_AWREADY;

	assign M_AXI_WDATA = slave_to_master_wdata_out;
	assign M_AXI_WSTRB = slave_to_master_wstrb_out;
	assign M_AXI_WLAST = slave_to_master_wlast_out;
	assign M_AXI_WVALID = slave_to_master_wvalid_out;
	assign slave_to_master_wready = M_AXI_WREADY;

	assign M_AXI_BID = slave_to_master_bid_out;
	assign M_AXI_BRESP = slave_to_master_bresp_out;
	assign M_AXI_BVALID = slave_to_master_bvalid_out;
	assign slave_to_master_bready = M_AXI_BREADY;

	assign M_AXI_ARID = master_to_slave_arid_out;
	assign M_AXI_ARADDR = master_to_slave_araddr_out;
	assign M_AXI_ARLEN = master_to_slave_arlen_out;
	assign M_AXI_ARSIZE = master_to_slave_arsize_out;
	assign M_AXI_ARBURST = master_to_slave_arburst_out;
	assign M_AXI_ARLOCK = master_to_slave_arlock_out;
	assign M_AXI_ARCACHE = master_to_slave_arcache_out;
	assign M_AXI_ARPROT = master_to_slave_arprot_out;
	assign M_AXI_ARQOS = master_to_slave_arqos_out;
	assign M_AXI_ARVALID = master_to_slave_arvalid_out;
	assign master_to_slave_arready = M_AXI_ARREADY;

	assign M_AXI_RID = master_to_slave_rid_out;
	assign M_AXI_RDATA = master_to_slave_rdata_out;
	assign M_AXI_RRESP = master_to_slave_rresp_out;
	assign M_AXI_RLAST = master_to_slave_rlast_out;
	assign M_AXI_RVALID = master_to_slave_rvalid_out;
	assign master_to_slave_rready = M_AXI_RREADY;

	// Instantiate the AXI clock domain crossing modules
	assign S_AXI_AWID = master_to_slave_awid_out;
	assign S_AXI_AWADDR = master_to_slave_awaddr_out;
	assign S_AXI_AWLEN = master_to_slave_awlen_out;
	assign S_AXI_AWSIZE = master_to_slave_awsize_out;
	assign S_AXI_AWBURST = master_to_slave_awburst_out;
	assign S_AXI_AWLOCK = master_to_slave_awlock_out;
	assign S_AXI_AWCACHE = master_to_slave_awcache_out;
	assign S_AXI_AWPROT = master_to_slave_awprot_out;
	assign S_AXI_AWQOS = master_to_slave_awqos_out;
	assign S_AXI_AWVALID = master_to_slave_awvalid_out;
	assign master_to_slave_awready = S_AXI_AWREADY;

	assign S_AXI_WDATA = master_to_slave_wdata_out;
	assign S_AXI_WSTRB = master_to_slave_wstrb_out;
	assign S_AXI_WLAST = master_to_slave_wlast_out;
	assign S_AXI_WVALID = master_to_slave_wvalid_out;
	assign master_to_slave_wready = S_AXI_WREADY;

	assign S_AXI_BID = master_to_slave_bid_out;
	assign S_AXI_BRESP = master_to_slave_bresp_out;
	assign S_AXI_BVALID = master_to_slave_bvalid_out;
	assign master_to_slave_bready = S_AXI_BREADY;

	assign S_AXI_ARID = slave_to_master_arid_out;
	assign S_AXI_ARADDR = slave_to_master_araddr_out;
	assign S_AXI_ARLEN = slave_to_master_arlen_out;
	assign S_AXI_ARSIZE = slave_to_master_arsize_out;
	assign S_AXI_ARBURST = slave_to_master_arburst_out;
	assign S_AXI_ARLOCK = slave_to_master_arlock_out;
	assign S_AXI_ARCACHE = slave_to_master_arcache_out;
	assign S_AXI_ARPROT = slave_to_master_arprot_out;
	assign S_AXI_ARQOS = slave_to_master_arqos_out;
	assign S_AXI_ARVALID = slave_to_master_arvalid_out;
	assign slave_to_master_arready = S_AXI_ARREADY;

	assign S_AXI_RID = slave_to_master_rid_out;
	assign S_AXI_RDATA = slave_to_master_rdata_out;
	assign S_AXI_RRESP = slave_to_master_rresp_out;
	assign S_AXI_RLAST = slave_to_master_rlast_out;
	assign S_AXI_RVALID = slave_to_master_rvalid_out;
	assign slave_to_master_rready = S_AXI_RREADY;

	// Instantiate the AXI clock domain crossing modules
	assign slave_to_master_awvalid_out = S_AXI_AWVALID;
	assign slave_to_master_awready_out = M_AXI_AWREADY;

	assign slave_to_master_awid_out = S_AXI_AWID;
	assign slave_to_master_awaddr_out = S_AXI_AWADDR;
	assign slave_to_master_awlen_out = S_AXI_AWLEN;
	assign slave_to_master_awsize_out = S_AXI_AWSIZE;
	assign slave_to_master_awburst_out = S_AXI_AWBURST;
	assign slave_to_master_awlock_out = S_AXI_AWLOCK;
	assign slave_to_master_awcache_out = S_AXI_AWCACHE;
	assign slave_to_master_awprot_out = S_AXI_AWPROT;
	assign slave_to_master_awqos_out = S_AXI_AWQOS;

	assign slave_to_master_wvalid_out = S_AXI_WVALID;
	assign slave_to_master_wready_out = M_AXI_WREADY;

	assign slave_to_master_wdata_out = S_AXI_WDATA;
	assign slave_to_master_wstrb_out = S_AXI_WSTRB;
	assign slave_to_master_wlast_out = S_AXI_WLAST;

	assign slave_to_master_bvalid_out = M_AXI_BVALID;
	assign slave_to_master_bready_out = S_AXI_BREADY;

	assign slave_to_master_bid_out = M_AXI_BID;
	assign slave_to_master_bresp_out = M_AXI_BRESP;

	assign master_to_slave_awvalid_out = M_AXI_AWVALID;
	assign master_to_slave_awready_out = S_AXI_AWREADY;

	assign master_to_slave_awid_out = M_AXI_AWID;
	assign master_to_slave_awaddr_out = M_AXI_AWADDR;
	assign master_to_slave_awlen_out = M_AXI_AWLEN;
	assign master_to_slave_awsize_out = M_AXI_AWSIZE;
	assign master_to_slave_awburst_out = M_AXI_AWBURST;
	assign master_to_slave_awlock_out = M_AXI_AWLOCK;
	assign master_to_slave_awcache_out = M_AXI_AWCACHE;
	assign master_to_slave_awprot_out = M_AXI_AWPROT;
	assign master_to_slave_awqos_out = M_AXI_AWQOS;

	assign master_to_slave_wvalid_out = M_AXI_WVALID;
	assign master_to_slave_wready_out = S_AXI_WREADY;

	assign master_to_slave_wdata_out = M_AXI_WDATA;
	assign master_to_slave_wstrb_out = M_AXI_WSTRB;
	assign master_to_slave_wlast_out = M_AXI_WLAST;

	assign master_to_slave_bvalid_out = S_AXI_BVALID;
	assign master_to_slave_bready_out = M_AXI_BREADY;

	assign master_to_slave_bid_out = S_AXI_BID;
	assign master_to_slave_bresp_out = S_AXI_BRESP;

	assign slave_to_master_arvalid_out = S_AXI_ARVALID;
	assign slave_to_master_arready_out = M_AXI_ARREADY;

	assign slave_to_master_arid_out = S_AXI_ARID;
	assign slave_to_master_araddr_out = S_AXI_ARADDR;
	assign slave_to_master_arlen_out = S_AXI_ARLEN;
	assign slave_to_master_arsize_out = S_AXI_ARSIZE;
	assign slave_to_master_arburst_out = S_AXI_ARBURST;
	assign slave_to_master_arlock_out = S_AXI_ARLOCK;
	assign slave_to_master_arcache_out = S_AXI_ARCACHE;
	assign slave_to_master_arprot_out = S_AXI_ARPROT;
	assign slave_to_master_arqos_out = S_AXI_ARQOS;

	assign slave_to_master_rvalid_out = M_AXI_RVALID;
	assign slave_to_master_rready_out = S_AXI_RREADY;

	assign slave_to_master_rid_out = M_AXI_RID;
	assign slave_to_master_rdata_out = M_AXI_RDATA;
	assign slave_to_master_rresp_out = M_AXI_RRESP;
	assign slave_to_master_rlast_out = M_AXI_RLAST;

	assign master_to_slave_arvalid_out = M_AXI_ARVALID;
	assign master_to_slave_arready_out = S_AXI_ARREADY;

	assign master_to_slave_arid_out = M_AXI_ARID;
	assign master_to_slave_araddr_out = M_AXI_ARADDR;
	assign master_to_slave_arlen_out = M_AXI_ARLEN;
	assign master_to_slave_arsize_out = M_AXI_ARSIZE;
	assign master_to_slave_arburst_out = M_AXI_ARBURST;
	assign master_to_slave_arlock_out = M_AXI_ARLOCK;
	assign master_to_slave_arcache_out = M_AXI_ARCACHE;
	assign master_to_slave_arprot_out = M_AXI_ARPROT;
	assign master_to_slave_arqos_out = M_AXI_ARQOS;

	assign master_to_slave_rvalid_out = S_AXI_RVALID;
	assign master_to_slave_rready_out = M_AXI_RREADY;

	assign master_to_slave_rid_out = S_AXI_RID;
	assign master_to_slave_rdata_out = S_AXI_RDATA;
	assign master_to_slave_rresp_out = S_AXI_RRESP;
	assign master_to_slave_rlast_out = S_AXI_RLAST;

endmodule
