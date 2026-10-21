```verilog
module axixclk #(
	parameter integer C_S_AXI_ID_WIDTH	= 2,
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 6,
	parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
	parameter [0:0]	OPT_READ_ONLY = 1'b0,
	parameter XCLOCK_FFS = 2,
	parameter LGFIFO = 5
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

	// Clock domain crossing signals
	reg S_AXI_ACLK;
	reg M_AXI_ACLK;
	reg S_AXI_ARESETN;
	reg M_AXI_ARESETN;
	
	// Cross clock domain signals for AW
	reg [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID_X;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR_X;
	reg [7 : 0] S_AXI_AWLEN_X;
	reg [2 : 0] S_AXI_AWSIZE_X;
	reg [1 : 0] S_AXI_AWBURST_X;
	reg S_AXI_AWLOCK_X;
	reg [3 : 0] S_AXI_AWCACHE_X;
	reg [2 : 0] S_AXI_AWPROT_X;
	reg [3 : 0] S_AXI_AWQOS_X;
	reg S_AXI_AWVALID_X;
	reg S_AXI_AWREADY_X;
	
	// Cross clock domain signals for W
	reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA_X;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB_X;
	reg S_AXI_WLAST_X;
	reg S_AXI_WVALID_X;
	reg S_AXI_WREADY_X;
	
	// Cross clock domain signals for B
	reg [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID_X;
	reg [1 : 0] S_AXI_BRESP_X;
	reg S_AXI_BVALID_X;
	reg S_AXI_BREADY_X;
	
	// Cross clock domain signals for AR
	reg [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID_X;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR_X;
	reg [7 : 0] S_AXI_ARLEN_X;
	reg [2 : 0] S_AXI_ARSIZE_X;
	reg [1 : 0] S_AXI_ARBURST_X;
	reg S_AXI_ARLOCK_X;
	reg [3 : 0] S_AXI_ARCACHE_X;
	reg [2 : 0] S_AXI_ARPROT_X;
	reg [3 : 0] S_AXI_ARQOS_X;
	reg S_AXI_ARVALID_X;
	reg S_AXI_ARREADY_X;
	
	// Cross clock domain signals for R
	reg [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID_X;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA_X;
	reg [1 : 0] S_AXI_RRESP_X;
	reg S_AXI_RLAST_X;
	reg S_AXI_RVALID_X;
	reg S_AXI_RREADY_X;
	
	// Cross clock domain signals for M side to S side
	reg [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID_X;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR_X;
	reg [7 : 0] M_AXI_AWLEN_X;
	reg [2 : 0] M_AXI_AWSIZE_X;
	reg [1 : 0] M_AXI_AWBURST_X;
	reg M_AXI_AWLOCK_X;
	reg [3 : 0] M_AXI_AWCACHE_X;
	reg [2 : 0] M_AXI_AWPROT_X;
	reg [3 : 0] M_AXI_AWQOS_X;
	reg M_AXI_AWVALID_X;
	reg M_AXI_AWREADY_X;
	
	reg [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA_X;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB_X;
	reg M_AXI_WLAST_X;
	reg M_AXI_WVALID_X;
	reg M_AXI_WREADY_X;
	
	reg [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID_X;
	reg [1 : 0] M_AXI_BRESP_X;
	reg M_AXI_BVALID_X;
	reg M_AXI_BREADY_X;
	
	reg [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID_X;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR_X;
	reg [7 : 0] M_AXI_ARLEN_X;
	reg [2 : 0] M_AXI_ARSIZE_X;
	reg [1 : 0] M_AXI_ARBURST_X;
	reg M_AXI_ARLOCK_X;
	reg [3 : 0] M_AXI_ARCACHE_X;
	reg [2 : 0] M_AXI_ARPROT_X;
	reg [3 : 0] M_AXI_ARQOS_X;
	reg M_AXI_ARVALID_X;
	reg M_AXI_ARREADY_X;
	
	reg [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID_X;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA_X;
	reg [1 : 0] M_AXI_RRESP_X;
	reg M_AXI_RLAST_X;
	reg M_AXI_RVALID_X;
	reg M_AXI_RREADY_X;

	// Clock domain crossing logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_ACLK <= 1'b0;
			M_AXI_ACLK <= 1'b0;
			S_AXI_ARESETN <= 1'b0;
			M_AXI_ARESETN <= 1'b0;
		end
		else begin
			S_AXI_ACLK <= S_AXI_ACLK;
			M_AXI_ACLK <= M_AXI_ACLK;
			S_AXI_ARESETN <= S_AXI_ARESETN;
			M_AXI_ARESETN <= M_AXI_ARESETN;
		end
	end

	// Cross clock domain logic for AW
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_AWID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_AWADDR_X <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			S_AXI_AWLEN_X <= 8'd0;
			S_AXI_AWSIZE_X <= 3'd0;
			S_AXI_AWBURST_X <= 2'd0;
			S_AXI_AWLOCK_X <= 1'b0;
			S_AXI_AWCACHE_X <= 4'd0;
			S_AXI_AWPROT_X <= 3'd0;
			S_AXI_AWQOS_X <= 4'd0;
			S_AXI_AWVALID_X <= 1'b0;
			S_AXI_AWREADY_X <= 1'b1;
		end
		else begin
			S_AXI_AWID_X <= S_AXI_AWID;
			S_AXI_AWADDR_X <= S_AXI_AWADDR;
			S_AXI_AWLEN_X <= S_AXI_AWLEN;
			S_AXI_AWSIZE_X <= S_AXI_AWSIZE;
			S_AXI_AWBURST_X <= S_AXI_AWBURST;
			S_AXI_AWLOCK_X <= S_AXI_AWLOCK;
			S_AXI_AWCACHE_X <= S_AXI_AWCACHE;
			S_AXI_AWPROT_X <= S_AXI_AWPROT;
			S_AXI_AWQOS_X <= S_AXI_AWQOS;
			S_AXI_AWVALID_X <= S_AXI_AWVALID;
			S_AXI_AWREADY_X <= S_AXI_AWREADY;
		end
	end

	// Cross clock domain logic for W
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_WDATA_X <= {C_S_AXI_DATA_WIDTH{1'b0}};
			S_AXI_WSTRB_X <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			S_AXI_WLAST_X <= 1'b0;
			S_AXI_WVALID_X <= 1'b0;
			S_AXI_WREADY_X <= 1'b1;
		end
		else begin
			S_AXI_WDATA_X <= S_AXI_WDATA;
			S_AXI_WSTRB_X <= S_AXI_WSTRB;
			S_AXI_WLAST_X <= S_AXI_WLAST;
			S_AXI_WVALID_X <= S_AXI_WVALID;
			S_AXI_WREADY_X <= S_AXI_WREADY;
		end
	end

	// Cross clock domain logic for B
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_BRESP_X <= 2'd0;
			S_AXI_BVALID_X <= 1'b0;
			S_AXI_BREADY_X <= 1'b1;
		end
		else begin
			S_AXI_BID_X <= S_AXI_BID;
			S_AXI_BRESP_X <= S_AXI_BRESP;
			S_AXI_BVALID_X <= S_AXI_BVALID;
			S_AXI_BREADY_X <= S_AXI_BREADY;
		end
	end

	// Cross clock domain logic for AR
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_ARID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_ARADDR_X <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			S_AXI_ARLEN_X <= 8'd0;
			S_AXI_ARSIZE_X <= 3'd0;
			S_AXI_ARBURST_X <= 2'd0;
			S_AXI_ARLOCK_X <= 1'b0;
			S_AXI_ARCACHE_X <= 4'd0;
			S_AXI_ARPROT_X <= 3'd0;
			S_AXI_ARQOS_X <= 4'd0;
			S_AXI_ARVALID_X <= 1'b0;
			S_AXI_ARREADY_X <= 1'b1;
		end
		else begin
			S_AXI_ARID_X <= S_AXI_ARID;
			S_AXI_ARADDR_X <= S_AXI_ARADDR;
			S_AXI_ARLEN_X <= S_AXI_ARLEN;
			S_AXI_ARSIZE_X <= S_AXI_ARSIZE;
			S_AXI_ARBURST_X <= S_AXI_ARBURST;
			S_AXI_ARLOCK_X <= S_AXI_ARLOCK;
			S_AXI_ARCACHE_X <= S_AXI_ARCACHE;
			S_AXI_ARPROT_X <= S_AXI_ARPROT;
			S_AXI_ARQOS_X <= S_AXI_ARQOS;
			S_AXI_ARVALID_X <= S_AXI_ARVALID;
			S_AXI_ARREADY_X <= S_AXI_ARREADY;
		end
	end

	// Cross clock domain logic for R
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_RID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_RDATA_X <= {C_S_AXI_DATA_WIDTH{1'b0}};
			S_AXI_RRESP_X <= 2'd0;
			S_AXI_RLAST_X <= 1'b0;
			S_AXI_RVALID_X <= 1'b0;
			S_AXI_RREADY_X <= 1'b1;
		end
		else begin
			S_AXI_RID_X <= S_AXI_RID;
			S_AXI_RDATA_X <= S_AXI_RDATA;
			S_AXI_RRESP_X <= S_AXI_RRESP;
			S_AXI_RLAST_X <= S_AXI_RLAST;
			S_AXI_RVALID_X <= S_AXI_RVALID;
			S_AXI_RREADY_X <= S_AXI_RREADY;
		end
	end

	// Cross clock domain logic for M side to S side
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_AWID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_AWADDR_X <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWLEN_X <= 8'd0;
			M_AXI_AWSIZE_X <= 3'd0;
			M_AXI_AWBURST_X <= 2'd0;
			M_AXI_AWLOCK_X <= 1'b0;
			M_AXI_AWCACHE_X <= 4'd0;
			M_AXI_AWPROT_X <= 3'd0;
			M_AXI_AWQOS_X <= 4'd0;
			M_AXI_AWVALID_X <= 1'b0;
			M_AXI_AWREADY_X <= 1'b1;
		end
		else begin
			M_AXI_AWID_X <= M_AXI_AWID;
			M_AXI_AWADDR_X <= M_AXI_AWADDR;
			M_AXI_AWLEN_X <= M_AXI_AWLEN;
			M_AXI_AWSIZE_X <= M_AXI_AWSIZE;
			M_AXI_AWBURST_X <= M_AXI_AWBURST;
			M_AXI_AWLOCK_X <= M_AXI_AWLOCK;
			M_AXI_AWCACHE_X <= M_AXI_AWCACHE;
			M_AXI_AWPROT_X <= M_AXI_AWPROT;
			M_AXI_AWQOS_X <= M_AXI_AWQOS;
			M_AXI_AWVALID_X <= M_AXI_AWVALID;
			M_AXI_AWREADY_X <= M_AXI_AWREADY;
		end
	end

	// Cross clock domain logic for M side to S side (W)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_WDATA_X <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB_X <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			M_AXI_WLAST_X <= 1'b0;
			M_AXI_WVALID_X <= 1'b0;
			M_AXI_WREADY_X <= 1'b1;
		end
		else begin
			M_AXI_WDATA_X <= M_AXI_WDATA;
			M_AXI_WSTRB_X <= M_AXI_WSTRB;
			M_AXI_WLAST_X <= M_AXI_WLAST;
			M_AXI_WVALID_X <= M_AXI_WVALID;
			M_AXI_WREADY_X <= M_AXI_WREADY;
		end
	end

	// Cross clock domain logic for M side to S side (B)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_BID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_BRESP_X <= 2'd0;
			M_AXI_BVALID_X <= 1'b0;
			M_AXI_BREADY_X <= 1'b1;
		end
		else begin
			M_AXI_BID_X <= M_AXI_BID;
			M_AXI_BRESP_X <= M_AXI_BRESP;
			M_AXI_BVALID_X <= M_AXI_BVALID;
			M_AXI_BREADY_X <= M_AXI_BREADY;
		end
	end

	// Cross clock domain logic for M side to S side (AR)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_ARID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_ARADDR_X <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_ARLEN_X <= 8'd0;
			M_AXI_ARSIZE_X <= 3'd0;
			M_AXI_ARBURST_X <= 2'd0;
			M_AXI_ARLOCK_X <= 1'b0;
			M_AXI_ARCACHE_X <= 4'd0;
			M_AXI_ARPROT_X <= 3'd0;
			M_AXI_ARQOS_X <= 4'd0;
			M_AXI_ARVALID_X <= 1'b0;
			M_AXI_ARREADY_X <= 1'b1;
		end
		else begin
			M_AXI_ARID_X <= M_AXI_ARID;
			M_AXI_ARADDR_X <= M_AXI_ARADDR;
			M_AXI_ARLEN_X <= M_AXI_ARLEN;
			M_AXI_ARSIZE_X <= M_AXI_ARSIZE;
			M_AXI_ARBURST_X <= M_AXI_ARBURST;
			M_AXI_ARLOCK_X <= M_AXI_ARLOCK;
			M_AXI_ARCACHE_X <= M_AXI_ARCACHE;
			M_AXI_ARPROT_X <= M_AXI_ARPROT;
			M_AXI_ARQOS_X <= M_AXI_ARQOS;
			M_AXI_ARVALID_X <= M_AXI_ARVALID;
			M_AXI_ARREADY_X <= M_AXI_ARREADY;
		end
	end

	// Cross clock domain logic for M side to S side (R)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_RID_X <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_RDATA_X <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_RRESP_X <= 2'd0;
			M_AXI_RLAST_X <= 1'b0;
			M_AXI_RVALID_X <= 1'b0;
			M_AXI_RREADY_X <= 1'b1;
		end
		else begin
			M_AXI_RID_X <= M_AXI_RID;
			M_AXI_RDATA_X <= M_AXI_RDATA;
			M_AXI_RRESP_X <= M_AXI_RRESP;
			M_AXI_RLAST_X <= M_AXI_RLAST;
			M_AXI_RVALID_X <= M_AXI_RVALID;
			M_AXI_RREADY_X <= M_AXI_RREADY;
		end
	end

	// Write FIFO for AW channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(2**LGFIFO)
	) u_aw_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.write_en(S_AXI_AWVALID),
		.write_data({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.write_valid(S_AXI_AWVALID),
		.write_ready(S_AXI_AWREADY),
		.read_en(M_AXI_AWREADY),
		.read_data({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.read_valid(M_AXI_AWVALID),
		.read_ready(M_AXI_AWREADY)
	);

	// Write FIFO for W channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.C_DEPTH(2**LGFIFO)
	) u_w_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.write_en(S_AXI_WVALID),
		.write_data({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.write_valid(S_AXI_WVALID),
		.write_ready(S_AXI_WREADY),
		.read_en(M_AXI_WREADY),
		.read_data({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.read_valid(M_AXI_WVALID),
		.read_ready(M_AXI_WREADY)
	);

	// Write FIFO for B channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.C_DEPTH(2**LGFIFO)
	) u_b_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.write_en(S_AXI_BVALID),
		.write_data({S_AXI_BID, S_AXI_BRESP}),
		.write_valid(S_AXI_BVALID),
		.write_ready(S_AXI_BREADY),
		.read_en(M_AXI_BREADY),
		.read_data({M_AXI_BID, M_AXI_BRESP}),
		.read_valid(M_AXI_BVALID),
		.read_ready(M_AXI_BREADY)
	);

	// Write FIFO for AR channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(2**LGFIFO)
	) u_ar_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.write_en(S_AXI_ARVALID),
		.write_data({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.write_valid(S_AXI_ARVALID),
		.write_ready(S_AXI_ARREADY),
		.read_en(M_AXI_ARREADY),
		.read_data({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.read_valid(M_AXI_ARVALID),
		.read_ready(M_AXI_ARREADY)
	);

	// Write FIFO for R channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.C_DEPTH(2**LGFIFO)
	) u_r_fifo (
		.clk(S_AXI_ACLK),
		.reset(!S_AXI_ARESETN),
		.write_en(S_AXI_RVALID),
		.write_data({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.write_valid(S_AXI_RVALID),
		.write_ready(S_AXI_RREADY),
		.read_en(M_AXI_RREADY),
		.read_data({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.read_valid(M_AXI_RVALID),
		.read_ready(M_AXI_RREADY)
	);

	// Read FIFO for AW channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(2**LGFIFO)
	) u_aw_r_fifo (
		.clk(M_AXI_ACLK),
		.reset(!M_AXI_ARESETN),
		.write_en(M_AXI_AWVALID),
		.write_data({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.write_valid(M_AXI_AWVALID),
		.write_ready(M_AXI_AWREADY),
		.read_en(S_AXI_AWREADY),
		.read_data({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.read_valid(S_AXI_AWVALID),
		.read_ready(S_AXI_AWREADY)
	);

	// Read FIFO for W channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.C_DEPTH(2**LGFIFO)
	) u_w_r_fifo (
		.clk(M_AXI_ACLK),
		.reset(!M_AXI_ARESETN),
		.write_en(M_AXI_WVALID),
		.write_data({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.write_valid(M_AXI_WVALID),
		.write_ready(M_AXI_WREADY),
		.read_en(S_AXI_WREADY),
		.read_data({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.read_valid(S_AXI_WVALID),
		.read_ready(S_AXI_WREADY)
	);

	// Read FIFO for B channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.C_DEPTH(2**LGFIFO)
	) u_b_r_fifo (
		.clk(M_AXI_ACLK),
		.reset(!M_AXI_ARESETN),
		.write_en(M_AXI_BVALID),
		.write_data({M_AXI_BID, M_AXI_BRESP}),
		.write_valid(M_AXI_BVALID),
		.write_ready(M_AXI_BREADY),
		.read_en(S_AXI_BREADY),
		.read_data({S_AXI_BID, S_AXI_BRESP}),
		.read_valid(S_AXI_BVALID),
		.read_ready(S_AXI_BREADY)
	);

	// Read FIFO for AR channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.C_DEPTH(2**LGFIFO)
	) u_ar_r_fifo (
		.clk(M_AXI_ACLK),
		.reset(!M_AXI_ARESETN),
		.write_en(M_AXI_ARVALID),
		.write_data({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.write_valid(M_AXI_ARVALID),
		.write_ready(M_AXI_ARREADY),
		.read_en(S_AXI_ARREADY),
		.read_data({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.read_valid(S_AXI_ARVALID),
		.read_ready(S_AXI_ARREADY)
	);

	// Read FIFO for R channel
	axi_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.C_DEPTH(2**LGFIFO)
	) u_r_r_fifo (
		.clk(M_AXI_ACLK),
		.reset(!M_AXI_ARESETN),
		.write_en(M_AXI_RVALID),
		.write_data({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.write_valid(M_AXI_RVALID),
		.write_ready(M_AXI_RREADY),
		.read_en(S_AXI_RREADY),
		.read_data({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.read_valid(S_AXI_RVALID),
		.read_ready(S_AXI_RREADY)
	);

	// Clock domain crossing logic for M side to S side (AW)
	always @(