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

	localparam INTEGER C_S_AXI_ADDR_WIDTH_LOG2 = $clog2(C_S_AXI_ADDR_WIDTH);
	localparam INTEGER C_S_AXI_DATA_WIDTH_LOG2 = $clog2(C_S_AXI_DATA_WIDTH);
	localparam INTEGER C_S_AXI_ID_WIDTH_LOG2 = $clog2(C_S_AXI_ID_WIDTH + 1);
	localparam INTEGER C_S_AXI_WSTRB_WIDTH = (C_S_AXI_DATA_WIDTH / 8);
	localparam INTEGER C_S_AXI_BURST_LEN_WIDTH = 8;
	localparam INTEGER C_S_AXI_SIZE_WIDTH = 3;
	localparam INTEGER C_S_AXI_BURST_WIDTH = 2;
	localparam INTEGER C_S_AXI_LOCK_WIDTH = 1;
	localparam INTEGER C_S_AXI_CACHE_WIDTH = 4;
	localparam INTEGER C_S_AXI_PROT_WIDTH = 3;
	localparam INTEGER C_S_AXI_QOS_WIDTH = 4;
	localparam INTEGER C_S_AXI_FFS = XCLOCK_FFS;
	localparam INTEGER C_S_AXI_FFS_LOG2 = $clog2(C_S_AXI_FFS);
	localparam INTEGER C_S_AXI_FFS_MASK = (1 << C_S_AXI_FFS_LOG2) - 1;

	// Cross Clock FIFO Parameters
	localparam INTEGER C_S_AXI_AW_FIFO_DEPTH = (1 << LGFIFO);
	localparam INTEGER C_S_AXI_W_FIFO_DEPTH = (1 << LGFIFO);
	localparam INTEGER C_S_AXI_B_FIFO_DEPTH = (1 << LGFIFO);
	localparam INTEGER C_S_AXI_AR_FIFO_DEPTH = (1 << LGFIFO);
	localparam INTEGER C_S_AXI_R_FIFO_DEPTH = (1 << LGFIFO);

	// Internal Signals
	wire [C_S_AXI_FFS_LOG2-1 : 0] S_AXI_ACLK_FFS;
	wire [C_S_AXI_FFS_LOG2-1 : 0] M_AXI_ACLK_FFS;
	wire S_AXI_ARESETN_FFS;
	wire M_AXI_ARESETN_FFS;

	// Generate Clocks and Resets
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			S_AXI_ACLK_FFS <= {C_S_AXI_FFS_LOG2{1'b0}};
		else
			S_AXI_ACLK_FFS <= S_AXI_ACLK_FFS + 1'b1;
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			M_AXI_ACLK_FFS <= {C_S_AXI_FFS_LOG2{1'b0}};
		else
			M_AXI_ACLK_FFS <= M_AXI_ACLK_FFS + 1'b1;
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			S_AXI_ARESETN_FFS <= 1'b1;
		else
			S_AXI_ARESETN_FFS <= S_AXI_ARESETN;
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			M_AXI_ARESETN_FFS <= 1'b1;
		else
			M_AXI_ARESETN_FFS <= S_AXI_ARESETN;
	end

	// Write Address FIFO
	axi4_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH + C_S_AXI_ID_WIDTH + C_S_AXI_BURST_LEN_WIDTH + C_S_AXI_SIZE_WIDTH + C_S_AXI_BURST_WIDTH + C_S_AXI_LOCK_WIDTH + C_S_AXI_CACHE_WIDTH + C_S_AXI_PROT_WIDTH + C_S_AXI_QOS_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH_LOG2),
		.C_DEPTH(C_S_AXI_AW_FIFO_DEPTH),
		.C_USER_WIDTH(0)
	) u_aw_fifo (
		.clk(M_AXI_ACLK_FFS),
		.reset(!M_AXI_ARESETN_FFS),
		.write_en(S_AXI_AWVALID & S_AXI_ARESETN),
		.write_data({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.write_ready(S_AXI_AWREADY),
		.read_en(M_AXI_AWVALID),
		.read_data({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.read_ready(M_AXI_AWREADY)
	);

	// Write Data FIFO
	axi4_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_DATA_WIDTH_LOG2),
		.C_DEPTH(C_S_AXI_W_FIFO_DEPTH),
		.C_USER_WIDTH(0)
	) u_w_fifo (
		.clk(M_AXI_ACLK_FFS),
		.reset(!M_AXI_ARESETN_FFS),
		.write_en(S_AXI_WVALID & S_AXI_WLAST & S_AXI_ARESETN),
		.write_data(S_AXI_WDATA),
		.write_ready(S_AXI_WREADY),
		.read_en(M_AXI_WVALID),
		.read_data(M_AXI_WDATA),
		.read_ready(M_AXI_WREADY)
	);

	// Write Response FIFO
	axi4_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.C_ADDR_WIDTH(C_S_AXI_ID_WIDTH_LOG2),
		.C_DEPTH(C_S_AXI_B_FIFO_DEPTH),
		.C_USER_WIDTH(0)
	) u_b_fifo (
		.clk(S_AXI_ACLK_FFS),
		.reset(!S_AXI_ARESETN_FFS),
		.write_en(M_AXI_BVALID & M_AXI_BREADY),
		.write_data({M_AXI_BID, M_AXI_BRESP}),
		.write_ready(M_AXI_BREADY),
		.read_en(S_AXI_BVALID),
		.read_data({S_AXI_BID, S_AXI_BRESP}),
		.read_ready(S_AXI_BREADY)
	);

	// Read Address FIFO
	axi4_fifo #(
		.C_DATA_WIDTH(C_S_AXI_ADDR_WIDTH + C_S_AXI_ID_WIDTH + C_S_AXI_BURST_LEN_WIDTH + C_S_AXI_SIZE_WIDTH + C_S_AXI_BURST_WIDTH + C_S_AXI_LOCK_WIDTH + C_S_AXI_CACHE_WIDTH + C_S_AXI_PROT_WIDTH + C_S_AXI_QOS_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH_LOG2),
		.C_DEPTH(C_S_AXI_AR_FIFO_DEPTH),
		.C_USER_WIDTH(0)
	) u_ar_fifo (
		.clk(M_AXI_ACLK_FFS),
		.reset(!M_AXI_ARESETN_FFS),
		.write_en(S_AXI_ARVALID & S_AXI_ARESETN),
		.write_data({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.write_ready(S_AXI_ARREADY),
		.read_en(M_AXI_ARVALID),
		.read_data({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.read_ready(M_AXI_ARREADY)
	);

	// Read Data FIFO
	axi4_fifo #(
		.C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_ADDR_WIDTH(C_S_AXI_DATA_WIDTH_LOG2),
		.C_DEPTH(C_S_AXI_R_FIFO_DEPTH),
		.C_USER_WIDTH(0)
	) u_r_fifo (
		.clk(S_AXI_ACLK_FFS),
		.reset(!S_AXI_ARESETN_FFS),
		.write_en(M_AXI_RVALID & M_AXI_RLAST & M_AXI_RREADY),
		.write_data(M_AXI_RDATA),
		.write_ready(M_AXI_RREADY),
		.read_en(S_AXI_RVALID),
		.read_data(S_AXI_RDATA),
		.read_ready(S_AXI_RREADY)
	);

	// Write Response Generator
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_BRESP <= 2'b00;
			S_AXI_BVALID <= 1'b0;
		end
		else begin
			if (S_AXI_BREADY) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
			else if (S_AXI_BVALID) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
		end
	end

	// Read Data Generator
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			S_AXI_RRESP <= 2'b00;
			S_AXI_RLAST <= 1'b0;
			S_AXI_RVALID <= 1'b0;
		end
		else begin
			if (S_AXI_RREADY) begin
				S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				S_AXI_RRESP <= 2'b00;
				S_AXI_RLAST <= 1'b0;
				S_AXI_RVALID <= 1'b0;
			end
			else if (S_AXI_RVALID) begin
				S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				S_AXI_RRESP <= 2'b00;
				S_AXI_RLAST <= 1'b0;
				S_AXI_RVALID <= 1'b0;
			end
		end
	end

	// Write Address Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWLEN <= 8'd0;
			M_AXI_AWSIZE <= 3'd0;
			M_AXI_AWBURST <= 2'd0;
			M_AXI_AWLOCK <= 1'b0;
			M_AXI_AWCACHE <= 4'd0;
			M_AXI_AWPROT <= 3'd0;
			M_AXI_AWQOS <= 4'd0;
			M_AXI_AWVALID <= 1'b0;
		end
		else begin
			if (M_AXI_AWREADY) begin
				M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_AWLEN <= 8'd0;
				M_AXI_AWSIZE <= 3'd0;
				M_AXI_AWBURST <= 2'd0;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'd0;
				M_AXI_AWPROT <= 3'd0;
				M_AXI_AWQOS <= 4'd0;
				M_AXI_AWVALID <= 1'b0;
			end
			else if (M_AXI_AWVALID) begin
				M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_AWLEN <= 8'd0;
				M_AXI_AWSIZE <= 3'd0;
				M_AXI_AWBURST <= 2'd0;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'd0;
				M_AXI_AWPROT <= 3'd0;
				M_AXI_AWQOS <= 4'd0;
				M_AXI_AWVALID <= 1'b0;
			end
		end
	end

	// Write Data Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
			M_AXI_WLAST <= 1'b0;
			M_AXI_WVALID <= 1'b0;
		end
		else begin
			if (M_AXI_WREADY) begin
				M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
				M_AXI_WLAST <= 1'b0;
				M_AXI_WVALID <= 1'b0;
			end
			else if (M_AXI_WVALID) begin
				M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
				M_AXI_WLAST <= 1'b0;
				M_AXI_WVALID <= 1'b0;
			end
		end
	end

	// Read Address Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_ARLEN <= 8'd0;
			M_AXI_ARSIZE <= 3'd0;
			M_AXI_ARBURST <= 2'd0;
			M_AXI_ARLOCK <= 1'b0;
			M_AXI_ARCACHE <= 4'd0;
			M_AXI_ARPROT <= 3'd0;
			M_AXI_ARQOS <= 4'd0;
			M_AXI_ARVALID <= 1'b0;
		end
		else begin
			if (M_AXI_ARREADY) begin
				M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_ARLEN <= 8'd0;
				M_AXI_ARSIZE <= 3'd0;
				M_AXI_ARBURST <= 2'd0;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'd0;
				M_AXI_ARPROT <= 3'd0;
				M_AXI_ARQOS <= 4'd0;
				M_AXI_ARVALID <= 1'b0;
			end
			else if (M_AXI_ARVALID) begin
				M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_ARLEN <= 8'd0;
				M_AXI_ARSIZE <= 3'd0;
				M_AXI_ARBURST <= 2'd0;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'd0;
				M_AXI_ARPROT <= 3'd0;
				M_AXI_ARQOS <= 4'd0;
				M_AXI_ARVALID <= 1'b0;
			end
		end
	end

	// Read Data Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_RRESP <= 2'b00;
			M_AXI_RLAST <= 1'b0;
			M_AXI_RVALID <= 1'b0;
		end
		else begin
			if (M_AXI_RREADY) begin
				M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_RRESP <= 2'b00;
				M_AXI_RLAST <= 1'b0;
				M_AXI_RVALID <= 1'b0;
			end
			else if (M_AXI_RVALID) begin
				M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_RRESP <= 2'b00;
				M_AXI_RLAST <= 1'b0;
				M_AXI_RVALID <= 1'b0;
			end
		end
	end

	// Write Response Generation
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_BRESP <= 2'b00;
			S_AXI_BVALID <= 1'b0;
		end
		else begin
			if (S_AXI_BREADY) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
			else if (S_AXI_BVALID) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
		end
	end

	// Read Data Generation
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			S_AXI_RRESP <= 2'b00;
			S_AXI_RLAST <= 1'b0;
			S_AXI_RVALID <= 1'b0;
		end
		else begin
			if (S_AXI_RREADY) begin
				S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				S_AXI_RRESP <= 2'b00;
				S_AXI_RLAST <= 1'b0;
				S_AXI_RVALID <= 1'b0;
			end
			else if (S_AXI_RVALID) begin
				S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				S_AXI_RRESP <= 2'b00;
				S_AXI_RLAST <= 1'b0;
				S_AXI_RVALID <= 1'b0;
			end
		end
	end

	// Write Address Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWLEN <= 8'd0;
			M_AXI_AWSIZE <= 3'd0;
			M_AXI_AWBURST <= 2'd0;
			M_AXI_AWLOCK <= 1'b0;
			M_AXI_AWCACHE <= 4'd0;
			M_AXI_AWPROT <= 3'd0;
			M_AXI_AWQOS <= 4'd0;
			M_AXI_AWVALID <= 1'b0;
		end
		else begin
			if (M_AXI_AWREADY) begin
				M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_AWLEN <= 8'd0;
				M_AXI_AWSIZE <= 3'd0;
				M_AXI_AWBURST <= 2'd0;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'd0;
				M_AXI_AWPROT <= 3'd0;
				M_AXI_AWQOS <= 4'd0;
				M_AXI_AWVALID <= 1'b0;
			end
			else if (M_AXI_AWVALID) begin
				M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_AWLEN <= 8'd0;
				M_AXI_AWSIZE <= 3'd0;
				M_AXI_AWBURST <= 2'd0;
				M_AXI_AWLOCK <= 1'b0;
				M_AXI_AWCACHE <= 4'd0;
				M_AXI_AWPROT <= 3'd0;
				M_AXI_AWQOS <= 4'd0;
				M_AXI_AWVALID <= 1'b0;
			end
		end
	end

	// Write Data Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
			M_AXI_WLAST <= 1'b0;
			M_AXI_WVALID <= 1'b0;
		end
		else begin
			if (M_AXI_WREADY) begin
				M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
				M_AXI_WLAST <= 1'b0;
				M_AXI_WVALID <= 1'b0;
			end
			else if (M_AXI_WVALID) begin
				M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_WSTRB <= {C_S_AXI_WSTRB_WIDTH{1'b0}};
				M_AXI_WLAST <= 1'b0;
				M_AXI_WVALID <= 1'b0;
			end
		end
	end

	// Read Address Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_ARLEN <= 8'd0;
			M_AXI_ARSIZE <= 3'd0;
			M_AXI_ARBURST <= 2'd0;
			M_AXI_ARLOCK <= 1'b0;
			M_AXI_ARCACHE <= 4'd0;
			M_AXI_ARPROT <= 3'd0;
			M_AXI_ARQOS <= 4'd0;
			M_AXI_ARVALID <= 1'b0;
		end
		else begin
			if (M_AXI_ARREADY) begin
				M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_ARLEN <= 8'd0;
				M_AXI_ARSIZE <= 3'd0;
				M_AXI_ARBURST <= 2'd0;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'd0;
				M_AXI_ARPROT <= 3'd0;
				M_AXI_ARQOS <= 4'd0;
				M_AXI_ARVALID <= 1'b0;
			end
			else if (M_AXI_ARVALID) begin
				M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
				M_AXI_ARLEN <= 8'd0;
				M_AXI_ARSIZE <= 3'd0;
				M_AXI_ARBURST <= 2'd0;
				M_AXI_ARLOCK <= 1'b0;
				M_AXI_ARCACHE <= 4'd0;
				M_AXI_ARPROT <= 3'd0;
				M_AXI_ARQOS <= 4'd0;
				M_AXI_ARVALID <= 1'b0;
			end
		end
	end

	// Read Data Forwarding
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_RRESP <= 2'b00;
			M_AXI_RLAST <= 1'b0;
			M_AXI_RVALID <= 1'b0;
		end
		else begin
			if (M_AXI_RREADY) begin
				M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_RRESP <= 2'b00;
				M_AXI_RLAST <= 1'b0;
				M_AXI_RVALID <= 1'b0;
			end
			else if (M_AXI_RVALID) begin
				M_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
				M_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
				M_AXI_RRESP <= 2'b00;
				M_AXI_RLAST <= 1'b0;
				M_AXI_RVALID <= 1'b0;
			end
		end
	end

	// Write Response Generation
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_BRESP <= 2'b00;
			S_AXI_BVALID <= 1'b0;
		end
		else begin
			if (S_AXI_BREADY) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
			else if (S_AXI_BVALID) begin
				S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
				S_AXI_BRESP <= 2'b00;
				S_AXI_BVALID <= 1'b0;
			end
		end
	end

	//