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
	wire				M_AXI_ARESETN_d;
	wire				S_AXI_ARESETN_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR_d;
	wire [7 : 0]			M_AXI_AWLEN_d;
	wire [2 : 0]			M_AXI_AWSIZE_d;
	wire [1 : 0]			M_AXI_AWBURST_d;
	wire				M_AXI_AWLOCK_d;
	wire [3 : 0]			M_AXI_AWCACHE_d;
	wire [2 : 0]			M_AXI_AWPROT_d;
	wire [3 : 0]			M_AXI_AWQOS_d;
	wire				M_AXI_AWVALID_d;
	wire				M_AXI_WVALID_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA_d;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_d;
	wire				M_AXI_WLAST_d;
	wire				M_AXI_BREADY_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID_d;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR_d;
	wire [7 : 0]			M_AXI_ARLEN_d;
	wire [2 : 0]			M_AXI_ARSIZE_d;
	wire [1 : 0]			M_AXI_ARBURST_d;
	wire				M_AXI_ARLOCK_d;
	wire [3 : 0]			M_AXI_ARCACHE_d;
	wire [2 : 0]			M_AXI_ARPROT_d;
	wire [3 : 0]			M_AXI_ARQOS_d;
	wire				M_AXI_ARVALID_d;
	wire				M_AXI_RREADY_d;

	// AXI4 master signals
	wire				S_AXI_AWREADY_d;
	wire				S_AXI_WREADY_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID_d;
	wire [1 : 0]			S_AXI_BRESP_d;
	wire				S_AXI_BVALID_d;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID_d;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA_d;
	wire [1 : 0]			S_AXI_RRESP_d;
	wire				S_AXI_RLAST_d;
	wire				S_AXI_RVALID_d;

	// AXI4 slave signals
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR_out;
	wire [7 : 0]			M_AXI_AWLEN_out;
	wire [2 : 0]			M_AXI_AWSIZE_out;
	wire [1 : 0]			M_AXI_AWBURST_out;
	wire				M_AXI_AWLOCK_out;
	wire [3 : 0]			M_AXI_AWCACHE_out;
	wire [2 : 0]			M_AXI_AWPROT_out;
	wire [3 : 0]			M_AXI_AWQOS_out;
	wire				M_AXI_AWVALID_out;
	wire				M_AXI_WVALID_out;
	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_out;
	wire				M_AXI_WLAST_out;
	wire				M_AXI_BREADY_out;
	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID_out;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR_out;
	wire [7 : 0]			M_AXI_ARLEN_out;
	wire [2 : 0]			M_AXI_ARSIZE_out;
	wire [1 : 0]			M_AXI_ARBURST_out;
	wire				M_AXI_ARLOCK_out;
	wire [3 : 0]			M_AXI_ARCACHE_out;
	wire [2 : 0]			M_AXI_ARPROT_out;
	wire [3 : 0]			M_AXI_ARQOS_out;
	wire				M_AXI_ARVALID_out;
	wire				M_AXI_RREADY_out;

	// Clock domain crossing for reset
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ARESETN_d <= 0;
		end else begin
			M_AXI_ARESETN_d <= 1;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			S_AXI_ARESETN_d <= 0;
		end else begin
			S_AXI_ARESETN_d <= 1;
		end
	end

	// Clock domain crossing for signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_AWID_d <= 0;
			M_AXI_AWADDR_d <= 0;
			M_AXI_AWLEN_d <= 0;
			M_AXI_AWSIZE_d <= 0;
			M_AXI_AWBURST_d <= 0;
			M_AXI_AWLOCK_d <= 0;
			M_AXI_AWCACHE_d <= 0;
			M_AXI_AWPROT_d <= 0;
			M_AXI_AWQOS_d <= 0;
			M_AXI_AWVALID_d <= 0;
			M_AXI_WVALID_d <= 0;
			M_AXI_WDATA_d <= 0;
			M_AXI_WSTRB_d <= 0;
			M_AXI_WLAST_d <= 0;
			M_AXI_BREADY_d <= 0;
			M_AXI_ARID_d <= 0;
			M_AXI_ARADDR_d <= 0;
			M_AXI_ARLEN_d <= 0;
			M_AXI_ARSIZE_d <= 0;
			M_AXI_ARBURST_d <= 0;
			M_AXI_ARLOCK_d <= 0;
			M_AXI_ARCACHE_d <= 0;
			M_AXI_ARPROT_d <= 0;
			M_AXI_ARQOS_d <= 0;
			M_AXI_ARVALID_d <= 0;
			M_AXI_RREADY_d <= 0;
		end else begin
			M_AXI_AWID_d <= S_AXI_AWID;
			M_AXI_AWADDR_d <= S_AXI_AWADDR;
			M_AXI_AWLEN_d <= S_AXI_AWLEN;
			M_AXI_AWSIZE_d <= S_AXI_AWSIZE;
			M_AXI_AWBURST_d <= S_AXI_AWBURST;
			M_AXI_AWLOCK_d <= S_AXI_AWLOCK;
			M_AXI_AWCACHE_d <= S_AXI_AWCACHE;
			M_AXI_AWPROT_d <= S_AXI_AWPROT;
			M_AXI_AWQOS_d <= S_AXI_AWQOS;
			M_AXI_AWVALID_d <= S_AXI_AWVALID;
			M_AXI_WVALID_d <= S_AXI_WVALID;
			M_AXI_WDATA_d <= S_AXI_WDATA;
			M_AXI_WSTRB_d <= S_AXI_WSTRB;
			M_AXI_WLAST_d <= S_AXI_WLAST;
			M_AXI_BREADY_d <= S_AXI_BREADY;
			M_AXI_ARID_d <= S_AXI_ARID;
			M_AXI_ARADDR_d <= S_AXI_ARADDR;
			M_AXI_ARLEN_d <= S_AXI_ARLEN;
			M_AXI_ARSIZE_d <= S_AXI_ARSIZE;
			M_AXI_ARBURST_d <= S_AXI_ARBURST;
			M_AXI_ARLOCK_d <= S_AXI_ARLOCK;
			M_AXI_ARCACHE_d <= S_AXI_ARCACHE;
			M_AXI_ARPROT_d <= S_AXI_ARPROT;
			M_AXI_ARQOS_d <= S_AXI_ARQOS;
			M_AXI_ARVALID_d <= S_AXI_ARVALID;
			M_AXI_RREADY_d <= S_AXI_RREADY;
		end
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			S_AXI_AWREADY_d <= 0;
			S_AXI_WREADY_d <= 0;
			S_AXI_BID_d <= 0;
			S_AXI_BRESP_d <= 0;
			S_AXI_BVALID_d <= 0;
			S_AXI_RID_d <= 0;
			S_AXI_RDATA_d <= 0;
			S_AXI_RRESP_d <= 0;
			S_AXI_RLAST_d <= 0;
			S_AXI_RVALID_d <= 0;
		end else begin
			S_AXI_AWREADY_d <= M_AXI_AWREADY;
			S_AXI_WREADY_d <= M_AXI_WREADY;
			S_AXI_BID_d <= M_AXI_BID;
			S_AXI_BRESP_d <= M_AXI_BRESP;
			S_AXI_BVALID_d <= M_AXI_BVALID;
			S_AXI_RID_d <= M_AXI_RID;
			S_AXI_RDATA_d <= M_AXI_RDATA;
			S_AXI_RRESP_d <= M_AXI_RRESP;
			S_AXI_RLAST_d <= M_AXI_RLAST;
			S_AXI_RVALID_d <= M_AXI_RVALID;
		end
	end

	// Clock domain crossing for output signals
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_AWID_out <= 0;
			M_AXI_AWADDR_out <= 0;
			M_AXI_AWLEN_out <= 0;
			M_AXI_AWSIZE_out <= 0;
			M_AXI_AWBURST_out <= 0;
			M_AXI_AWLOCK_out <= 0;
			M_AXI_AWCACHE_out <= 0;
			M_AXI_AWPROT_out <= 0;
			M_AXI_AWQOS_out <= 0;
			M_AXI_AWVALID_out <= 0;
			M_AXI_WVALID_out <= 0;
			M_AXI_WDATA_out <= 0;
			M_AXI_WSTRB_out <= 0;
			M_AXI_WLAST_out <= 0;
			M_AXI_BREADY_out <= 0;
			M_AXI_ARID_out <= 0;
			M_AXI_ARADDR_out <= 0;
			M_AXI_ARLEN_out <= 0;
			M_AXI_ARSIZE_out <= 0;
			M_AXI_ARBURST_out <= 0;
			M_AXI_ARLOCK_out <= 0;
			M_AXI_ARCACHE_out <= 0;
			M_AXI_ARPROT_out <= 0;
			M_AXI_ARQOS_out <= 0;
			M_AXI_ARVALID_out <= 0;
			M_AXI_RREADY_out <= 0;
		end else begin
			M_AXI_AWID_out <= M_AXI_AWID_d;
			M_AXI_AWADDR_out <= M_AXI_AWADDR_d;
			M_AXI_AWLEN_out <= M_AXI_AWLEN_d;
			M_AXI_AWSIZE_out <= M_AXI_AWSIZE_d;
			M_AXI_AWBURST_out <= M_AXI_AWBURST_d;
			M_AXI_AWLOCK_out <= M_AXI_AWLOCK_d;
			M_AXI_AWCACHE_out <= M_AXI_AWCACHE_d;
			M_AXI_AWPROT_out <= M_AXI_AWPROT_d;
			M_AXI_AWQOS_out <= M_AXI_AWQOS_d;
			M_AXI_AWVALID_out <= M_AXI_AWVALID_d;
			M_AXI_WVALID_out <= M_AXI_WVALID_d;
			M_AXI_WDATA_out <= M_AXI_WDATA_d;
			M_AXI_WSTRB_out <= M_AXI_WSTRB_d;
			M_AXI_WLAST_out <= M_AXI_WLAST_d;
			M_AXI_BREADY_out <= M_AXI_BREADY_d;
			M_AXI_ARID_out <= M_AXI_ARID_d;
			M_AXI_ARADDR_out <= M_AXI_ARADDR_d;
			M_AXI_ARLEN_out <= M_AXI_ARLEN_d;
			M_AXI_ARSIZE_out <= M_AXI_ARSIZE_d;
			M_AXI_ARBURST_out <= M_AXI_ARBURST_d;
			M_AXI_ARLOCK_out <= M_AXI_ARLOCK_d;
			M_AXI_ARCACHE_out <= M_AXI_ARCACHE_d;
			M_AXI_ARPROT_out <= M_AXI_ARPROT_d;
			M_AXI_ARQOS_out <= M_AXI_ARQOS_d;
			M_AXI_ARVALID_out <= M_AXI_ARVALID_d;
			M_AXI_RREADY_out <= M_AXI_RREADY_d;
		end
	end

	// Clock domain crossing for input signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_AWREADY <= 0;
			S_AXI_WREADY <= 0;
			S_AXI_BID <= 0;
			S_AXI_BRESP <= 0;
			S_AXI_BVALID <= 0;
			S_AXI_RID <= 0;
			S_AXI_RDATA <= 0;
			S_AXI_RRESP <= 0;
			S_AXI_RLAST <= 0;
			S_AXI_RVALID <= 0;
		end else begin
			S_AXI_AWREADY <= S_AXI_AWREADY_d;
			S_AXI_WREADY <= S_AXI_WREADY_d;
			S_AXI_BID <= S_AXI_BID_d;
			S_AXI_BRESP <= S_AXI_BRESP_d;
			S_AXI_BVALID <= S_AXI_BVALID_d;
			S_AXI_RID <= S_AXI_RID_d;
			S_AXI_RDATA <= S_AXI_RDATA_d;
			S_AXI_RRESP <= S_AXI_RRESP_d;
			S_AXI_RLAST <= S_AXI_RLAST_d;
			S_AXI_RVALID <= S_AXI_RVALID_d;
		end
	end

	// Clock domain crossing for output signals
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			M_AXI_ACLK <= 0;
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
			M_AXI_BREADY <= 0;
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
			M_AXI_RREADY <= 0;
		end else begin
			M_AXI_ACLK <= M_AXI_ACLK;
			M_AXI_ARESETN <= M_AXI_ARESETN;
			M_AXI_AWID <= M_AXI_AWID_out;
			M_AXI_AWADDR <= M_AXI_AWADDR_out;
			M_AXI_AWLEN <= M_AXI_AWLEN_out;
			M_AXI_AWSIZE <= M_AXI_AWSIZE_out;
			M_AXI_AWBURST <= M_AXI_AWBURST_out;
			M_AXI_AWLOCK <= M_AXI_AWLOCK_out;
			M_AXI_AWCACHE <= M_AXI_AWCACHE_out;
			M_AXI_AWPROT <= M_AXI_AWPROT_out;
			M_AXI_AWQOS <= M_AXI_AWQOS_out;
			M_AXI_AWVALID <= M_AXI_AWVALID_out;
			M_AXI_WDATA <= M_AXI_WDATA_out;
			M_AXI_WSTRB <= M_AXI_WSTRB_out;
			M_AXI_WLAST <= M_AXI_WLAST_out;
			M_AXI_WVALID <= M_AXI_WVALID_out;
			M_AXI_BREADY <= M_AXI_BREADY_out;
			M_AXI_ARID <= M_AXI_ARID_out;
			M_AXI_ARADDR <= M_AXI_ARADDR_out;
			M_AXI_ARLEN <= M_AXI_ARLEN_out;
			M_AXI_ARSIZE <= M_AXI_ARSIZE_out;
			M_AXI_ARBURST <= M_AXI_ARBURST_out;
			M_AXI_ARLOCK <= M_AXI_ARLOCK_out;
			M_AXI_ARCACHE <= M_AXI_ARCACHE_out;
			M_AXI_ARPROT <= M_AXI_ARPROT_out;
			M_AXI_ARQOS <= M_AXI_ARQOS_out;
			M_AXI_ARVALID <= M_AXI_ARVALID_out;
			M_AXI_RREADY <= M_AXI_RREADY_out;
		end
	end

	// Clock domain crossing for input signals
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			S_AXI_ACLK <= 0;
			S_AXI_ARESETN <= 0;
		end else begin
			S_AXI_ACLK <= S_AXI_ACLK;
			S_AXI_ARESETN <= S_AXI_ARESETN;
		end
	end

endmodule
