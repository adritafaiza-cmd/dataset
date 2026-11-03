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

reg [C_S_AXI_ID_WIDTH-1 : 0] awid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_reg;
reg [7 : 0] awlen_reg;
reg [2 : 0] awsize_reg;
reg [1 : 0] awburst_reg;
reg awlock_reg;
reg [3 : 0] awcache_reg;
reg [2 : 0] awprot_reg;
reg [3 : 0] awqos_reg;
reg awvalid_reg;
wire awready_reg;

reg [C_S_AXI_DATA_WIDTH-1 : 0] wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_reg;
reg wlast_reg;
reg wvalid_reg;
wire wready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0] bid_reg;
reg [1 : 0] bresp_reg;
wire bvalid_reg;
reg bready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0] arid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_reg;
reg [7 : 0] arlen_reg;
reg [2 : 0] arsize_reg;
reg [1 : 0] arburst_reg;
reg arlock_reg;
reg [3 : 0] arcache_reg;
reg [2 : 0] arprot_reg;
reg [3 : 0] arqos_reg;
reg arvalid_reg;
wire arready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0] rid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0] rdata_reg;
reg [1 : 0] rresp_reg;
wire rlast_reg;
wire rvalid_reg;
reg rready_reg;

wire m_axi_awready;
wire m_axi_wready;
wire m_axi_bvalid;
wire m_axi_arready;
wire m_axi_rvalid;

assign S_AXI_AWREADY = m_axi_awready;
assign S_AXI_WREADY = m_axi_wready;
assign S_AXI_BID = bid_reg;
assign S_AXI_BRESP = bresp_reg;
assign S_AXI_BVALID = bvalid_reg;
assign S_AXI_ARREADY = m_axi_arready;
assign S_AXI_RID = rid_reg;
assign S_AXI_RDATA = rdata_reg;
assign S_AXI_RRESP = rresp_reg;
assign S_AXI_RLAST = rlast_reg;
assign S_AXI_RVALID = rvalid_reg;
assign M_AXI_ARESETN = S_AXI_ARESETN;

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
		bid_reg <= 0;
		bresp_reg <= 0;
		bvalid_reg <= 0;
		bready_reg <= 0;
		arid_reg <= 0;
		araddr_reg <= 0;
		arlen_reg <= 0;
		arsize_reg <= 0;
		arsburst_reg <= 0;
		arlock_reg <= 0;
		arcache_reg <= 0;
		arprot_reg <= 0;
		arqos_reg <= 0;
		arvalid_reg <= 0;
		rid_reg <= 0;
		rdata_reg <= 0;
		rresp_reg <= 0;
		rlast_reg <= 0;
		rvalid_reg <= 0;
		rready_reg <= 0;
	end else begin
		awid_reg <= S_AXI_AWID;
		awaddr_reg <= S_AXI_AWADDR;
		awlen_reg <= S_AXI_AWLEN;
		awsize_reg <= S_AXI_AWSIZE;
		awburst_reg <= S_AXI_AWBURST;
		awlock_reg <= S_AXI_AWLOCK;
		awcache_reg <= S_AXI_AWCACHE;
		awprot_reg <= S_AXI_AWPROT;
		awqos_reg <= S_AXI_AWQOS;
		awvalid_reg <= S_AXI_AWVALID;
		wdata_reg <= S_AXI_WDATA;
		wstrb_reg <= S_AXI_WSTRB;
		wlast_reg <= S_AXI_WLAST;
		wvalid_reg <= S_AXI_WVALID;
		bid_reg <= M_AXI_BID;
		bresp_reg <= M_AXI_BRESP;
		bvalid_reg <= M_AXI_BVALID;
		bready_reg <= S_AXI_BREADY;
		arid_reg <= S_AXI_ARID;
		araddr_reg <= S_AXI_ARADDR;
		arlen_reg <= S_AXI_ARLEN;
		arsize_reg <= S_AXI_ARSIZE;
		arsburst_reg <= S_AXI_ARBURST;
		arlock_reg <= S_AXI_ARLOCK;
		arcache_reg <= S_AXI_ARCACHE;
		arprot_reg <= S_AXI_ARPROT;
		arqos_reg <= S_AXI_ARQOS;
		arvalid_reg <= S_AXI_ARVALID;
		rid_reg <= M_AXI_RID;
		rdata_reg <= M_AXI_RDATA;
		rresp_reg <= M_AXI_RRESP;
		rlast_reg <= M_AXI_RLAST;
		rvalid_reg <= M_AXI_RVALID;
		rready_reg <= S_AXI_RREADY;
	end
end

assign M_AXI_AWID = awid_reg;
assign M_AXI_AWADDR = awaddr_reg;
assign M_AXI_AWLEN = awlen_reg;
assign M_AXI_AWSIZE = awsize_reg;
assign M_AXI_AWBURST = awburst_reg;
assign M_AXI_AWLOCK = awlock_reg;
assign M_AXI_AWCACHE = awcache_reg;
assign M_AXI_AWPROT = awprot_reg;
assign M_AXI_AWQOS = awqos_reg;
assign M_AXI_AWVALID = awvalid_reg;
assign M_AXI_WDATA = wdata_reg;
assign M_AXI_WSTRB = wstrb_reg;
assign M_AXI_WLAST = wlast_reg;
assign M_AXI_WVALID = wvalid_reg;
assign M_AXI_BREADY = bready_reg;
assign M_AXI_ARID = arid_reg;
assign M_AXI_ARADDR = araddr_reg;
assign M_AXI_ARLEN = arlen_reg;
assign M_AXI_ARSIZE = arsize_reg;
assign M_AXI_ARBURST = arburst_reg;
assign M_AXI_ARLOCK = arlock_reg;
assign M_AXI_ARCACHE = arcache_reg;
assign M_AXI_ARPROT = arprot_reg;
assign M_AXI_ARQOS = arqos_reg;
assign M_AXI_ARVALID = arvalid_reg;
assign M_AXI_RREADY = rready_reg;

endmodule
