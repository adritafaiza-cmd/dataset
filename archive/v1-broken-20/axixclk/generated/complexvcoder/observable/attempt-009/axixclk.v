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

	// AXI slave interface
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] slave_awaddr;
	wire [7 : 0] slave_awlen;
	wire [2 : 0] slave_awsize;
	wire [1 : 0] slave_awburst;
	wire slave_awlock;
	wire [3 : 0] slave_awcache;
	wire [2 : 0] slave_awprot;
	wire [3 : 0] slave_awqos;
	wire slave_awvalid;
	wire slave_awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] slave_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] slave_wstrb;
	wire slave_wlast;
	wire slave_wvalid;
	wire slave_wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_bid;
	wire [1 : 0] slave_bresp;
	wire slave_bvalid;
	wire slave_bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] slave_araddr;
	wire [7 : 0] slave_arlen;
	wire [2 : 0] slave_arsize;
	wire [1 : 0] slave_arburst;
	wire slave_arlock;
	wire [3 : 0] slave_arcache;
	wire [2 : 0] slave_arprot;
	wire [3 : 0] slave_arqos;
	wire slave_arvalid;
	wire slave_arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] slave_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] slave_rdata;
	wire [1 : 0] slave_rresp;
	wire slave_rlast;
	wire slave_rvalid;
	wire slave_rready;

	// AXI master interface
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] master_awaddr;
	wire [7 : 0] master_awlen;
	wire [2 : 0] master_awsize;
	wire [1 : 0] master_awburst;
	wire master_awlock;
	wire [3 : 0] master_awcache;
	wire [2 : 0] master_awprot;
	wire [3 : 0] master_awqos;
	wire master_awvalid;
	wire master_awready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] master_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] master_wstrb;
	wire master_wlast;
	wire master_wvalid;
	wire master_wready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_bid;
	wire [1 : 0] master_bresp;
	wire master_bvalid;
	wire master_bready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] master_araddr;
	wire [7 : 0] master_arlen;
	wire [2 : 0] master_arsize;
	wire [1 : 0] master_arburst;
	wire master_arlock;
	wire [3 : 0] master_arcache;
	wire [2 : 0] master_arprot;
	wire [3 : 0] master_arqos;
	wire master_arvalid;
	wire master_arready;
	wire [C_S_AXI_ID_WIDTH-1 : 0] master_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] master_rdata;
	wire [1 : 0] master_rresp;
	wire master_rlast;
	wire master_rvalid;
	wire master_rready;

	// Clock domain crossing for AXI slave interface
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			slave_awid <= 0;
			slave_awaddr <= 0;
			slave_awlen <= 0;
			slave_awsize <= 0;
			slave_awburst <= 0;
			slave_awlock <= 0;
			slave_awcache <= 0;
			slave_awprot <= 0;
			slave_awqos <= 0;
			slave_awvalid <= 0;
			slave_wdata <= 0;
			slave_wstrb <= 0;
			slave_wlast <= 0;
			slave_wvalid <= 0;
			slave_bid <= 0;
			slave_bresp <= 0;
			slave_bvalid <= 0;
			slave_arid <= 0;
			slave_araddr <= 0;
			slave_arlen <= 0;
			slave_arsize <= 0;
			slave_arburst <= 0;
			slave_arlock <= 0;
			slave_arcache <= 0;
			slave_arprot <= 0;
			slave_arqos <= 0;
			slave_arvalid <= 0;
			slave_rid <= 0;
			slave_rdata <= 0;
			slave_rresp <= 0;
			slave_rlast <= 0;
			slave_rvalid <= 0;
		end else begin
			slave_awid <= S_AXI_AWID;
			slave_awaddr <= S_AXI_AWADDR;
			slave_awlen <= S_AXI_AWLEN;
			slave_awsize <= S_AXI_AWSIZE;
			slave_awburst <= S_AXI_AWBURST;
			slave_awlock <= S_AXI_AWLOCK;
			slave_awcache <= S_AXI_AWCACHE;
			slave_awprot <= S_AXI_AWPROT;
			slave_awqos <= S_AXI_AWQOS;
			slave_awvalid <= S_AXI_AWVALID;
			slave_wdata <= S_AXI_WDATA;
			slave_wstrb <= S_AXI_WSTRB;
			slave_wlast <= S_AXI_WLAST;
			slave_wvalid <= S_AXI_WVALID;
			slave_bid <= 0;
			slave_bresp <= 0;
			slave_bvalid <= 0;
			slave_arid <= S_AXI_ARID;
			slave_araddr <= S_AXI_ARADDR;
			slave_arlen <= S_AXI_ARLEN;
			slave_arsize <= S_AXI_ARSIZE;
			slave_arburst <= S_AXI_ARBURST;
			slave_arlock <= S_AXI_ARLOCK;
			slave_arcache <= S_AXI_ARCACHE;
			slave_arprot <= S_AXI_ARPROT;
			slave_arqos <= S_AXI_ARQOS;
			slave_arvalid <= S_AXI_ARVALID;
			slave_rid <= 0;
			slave_rdata <= 0;
			slave_rresp <= 0;
			slave_rlast <= 0;
			slave_rvalid <= 0;
		end
	end

	// Clock domain crossing for AXI master interface
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ARESETN <= 0;
			M_AXI_AWID <= 0;
			M_AXI_AWADDR <= 0;
			M_AXI_AWLEN <= 0;
			M_AXI_AWSIZE <= 0;
			M_AXI_AWBURST <= 0;
			M_AXI_AWLOCK <= 0;
			M_AXI_AWCACHE <= 0;
			M_AXI_AWPROT <= 0;
			M_AXI_AWQOS <= 0;
			M_AXI_AWVALID <= 0;
			M_AXI_WDATA <= 0;
			M_AXI_WSTRB <= 0;
			M_AXI_WLAST <= 0;
			M_AXI_WVALID <= 0;
			M_AXI_BID <= 0;
			M_AXI_BRESP <= 0;
			M_AXI_BVALID <= 0;
			M_AXI_ARID <= 0;
			M_AXI_ARADDR <= 0;
			M_AXI_ARLEN <= 0;
			M_AXI_ARSIZE <= 0;
			M_AXI_ARBURST <= 0;
			M_AXI_ARLOCK <= 0;
			M_AXI_ARCACHE <= 0;
			M_AXI_ARPROT <= 0;
			M_AXI_ARQOS <= 0;
			M_AXI_ARVALID <= 0;
			M_AXI_RID <= 0;
			M_AXI_RDATA <= 0;
			M_AXI_RRESP <= 0;
			M_AXI_RLAST <= 0;
			M_AXI_RVALID <= 0;
		end else begin
			M_AXI_ARESETN <= 1;
			M_AXI_AWID <= master_awid;
			M_AXI_AWADDR <= master_awaddr;
			M_AXI_AWLEN <= master_awlen;
			M_AXI_AWSIZE <= master_awsize;
			M_AXI_AWBURST <= master_awburst;
			M_AXI_AWLOCK <= master_awlock;
			M_AXI_AWCACHE <= master_awcache;
			M_AXI_AWPROT <= master_awprot;
			M_AXI_AWQOS <= master_awqos;
			M_AXI_AWVALID <= master_awvalid;
			M_AXI_WDATA <= master_wdata;
			M_AXI_WSTRB <= master_wstrb;
			M_AXI_WLAST <= master_wlast;
			M_AXI_WVALID <= master_wvalid;
			M_AXI_BID <= master_bid;
			M_AXI_BRESP <= master_bresp;
			M_AXI_BVALID <= master_bvalid;
			M_AXI_ARID <= master_arid;
			M_AXI_ARADDR <= master_araddr;
			M_AXI_ARLEN <= master_arlen;
			M_AXI_ARSIZE <= master_arsize;
			M_AXI_ARBURST <= master_arburst;
			M_AXI_ARLOCK <= master_arlock;
			M_AXI_ARCACHE <= master_arcache;
			M_AXI_ARPROT <= master_arprot;
			M_AXI_ARQOS <= master_arqos;
			M_AXI_ARVALID <= master_arvalid;
			M_AXI_RID <= master_rid;
			M_AXI_RDATA <= master_rdata;
			M_AXI_RRESP <= master_rresp;
			M_AXI_RLAST <= master_rlast;
			M_AXI_RVALID <= master_rvalid;
		end
	end

	// Instantiate AXI slave and master modules
	axi_slave #(
		.C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.OPT_READ_ONLY(OPT_READ_ONLY)
	) slave_inst (
		.S_AXI_ACLK(S_AXI_ACLK),
		.S_AXI_ARESETN(S_AXI_ARESETN),
		.S_AXI_AWID(slave_awid),
		.S_AXI_AWADDR(slave_awaddr),
		.S_AXI_AWLEN(slave_awlen),
		.S_AXI_AWSIZE(slave_awsize),
		.S_AXI_AWBURST(slave_awburst),
		.S_AXI_AWLOCK(slave_awlock),
		.S_AXI_AWCACHE(slave_awcache),
		.S_AXI_AWPROT(slave_awprot),
		.S_AXI_AWQOS(slave_awqos),
		.S_AXI_AWVALID(slave_awvalid),
		.S_AXI_AWREADY(slave_awready),
		.S_AXI_WDATA(slave_wdata),
		.S_AXI_WSTRB(slave_wstrb),
		.S_AXI_WLAST(slave_wlast),
		.S_AXI_WVALID(slave_wvalid),
		.S_AXI_WREADY(slave_wready),
		.S_AXI_BID(slave_bid),
		.S_AXI_BRESP(slave_bresp),
		.S_AXI_BVALID(slave_bvalid),
		.S_AXI_BREADY(slave_bready),
		.S_AXI_ARID(slave_arid),
		.S_AXI_ARADDR(slave_araddr),
		.S_AXI_ARLEN(slave_arlen),
		.S_AXI_ARSIZE(slave_arsize),
		.S_AXI_ARBURST(slave_arburst),
		.S_AXI_ARLOCK(slave_arlock),
		.S_AXI_ARCACHE(slave_arcache),
		.S_AXI_ARPROT(slave_arprot),
		.S_AXI_ARQOS(slave_arqos),
		.S_AXI_ARVALID(slave_arvalid),
		.S_AXI_ARREADY(slave_arready),
		.S_AXI_RID(slave_rid),
		.S_AXI_RDATA(slave_rdata),
		.S_AXI_RRESP(slave_rresp),
		.S_AXI_RLAST(slave_rlast),
		.S_AXI_RVALID(slave_rvalid),
		.S_AXI_RREADY(slave_rready)
	);

	axi_master #(
		.C_M_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_WRITE_ONLY(OPT_WRITE_ONLY),
		.OPT_READ_ONLY(OPT_READ_ONLY)
	) master_inst (
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_AWID(master_awid),
		.M_AXI_AWADDR(master_awaddr),
		.M_AXI_AWLEN(master_awlen),
		.M_AXI_AWSIZE(master_awsize),
		.M_AXI_AWBURST(master_awburst),
		.M_AXI_AWLOCK(master_awlock),
		.M_AXI_AWCACHE(master_awcache),
		.M_AXI_AWPROT(master_awprot),
		.M_AXI_AWQOS(master_awqos),
		.M_AXI_AWVALID(master_awvalid),
		.M_AXI_AWREADY(master_awready),
		.M_AXI_WDATA(master_wdata),
		.M_AXI_WSTRB(master_wstrb),
		.M_AXI_WLAST(master_wlast),
		.M_AXI_WVALID(master_wvalid),
		.M_AXI_WREADY(master_wready),
		.M_AXI_BID(master_bid),
		.M_AXI_BRESP(master_bresp),
		.M_AXI_BVALID(master_bvalid),
		.M_AXI_BREADY(master_bready),
		.M_AXI_ARID(master_arid),
		.M_AXI_ARADDR(master_araddr),
		.M_AXI_ARLEN(master_arlen),
		.M_AXI_ARSIZE(master_arsize),
		.M_AXI_ARBURST(master_arburst),
		.M_AXI_ARLOCK(master_arlock),
		.M_AXI_ARCACHE(master_arcache),
		.M_AXI_ARPROT(master_arprot),
		.M_AXI_ARQOS(master_arqos),
		.M_AXI_ARVALID(master_arvalid),
		.M_AXI_ARREADY(master_arready),
		.M_AXI_RID(master_rid),
		.M_AXI_RDATA(master_rdata),
		.M_AXI_RRESP(master_rresp),
		.M_AXI_RLAST(master_rlast),
		.M_AXI_RVALID(master_rvalid),
		.M_AXI_RREADY(master_rready)
	);

	// Connect AXI slave to AXI master
	assign S_AXI_AWREADY = master_awready;
	assign S_AXI_WREADY = master_wready;
	assign S_AXI_BID = master_bid;
	assign S_AXI_BRESP = master_bresp;
	assign S_AXI_BVALID = master_bvalid;
	assign S_AXI_ARREADY = master_arready;
	assign S_AXI_RID = master_rid;
	assign S_AXI_RDATA = master_rdata;
	assign S_AXI_RRESP = master_rresp;
	assign S_AXI_RLAST = master_rlast;
	assign S_AXI_RVALID = master_rvalid;

endmodule
