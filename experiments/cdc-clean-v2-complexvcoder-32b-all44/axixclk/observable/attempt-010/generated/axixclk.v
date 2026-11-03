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

	// Clock domain crossing FIFOs
	crossover_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(LGFIFO)
	) aw_crossover_fifo (
		.clk_in(S_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.clk_out(M_AXI_ACLK),
		.data_in({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.valid_in(S_AXI_AWVALID),
		.ready_in(S_AXI_AWREADY),
		.data_out({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
		.valid_out(M_AXI_AWVALID),
		.ready_out(M_AXI_AWREADY)
	);

	crossover_fifo #(
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(LGFIFO)
	) w_crossover_fifo (
		.clk_in(S_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.clk_out(M_AXI_ACLK),
		.data_in({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.valid_in(S_AXI_WVALID),
		.ready_in(S_AXI_WREADY),
		.data_out({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
		.valid_out(M_AXI_WVALID),
		.ready_out(M_AXI_WREADY)
	);

	crossover_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(LGFIFO)
	) b_crossover_fifo (
		.clk_in(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.clk_out(S_AXI_ACLK),
		.data_in({M_AXI_BID, M_AXI_BRESP}),
		.valid_in(M_AXI_BVALID),
		.ready_in(M_AXI_BREADY),
		.data_out({S_AXI_BID, S_AXI_BRESP}),
		.valid_out(S_AXI_BVALID),
		.ready_out(S_AXI_BREADY)
	);

	crossover_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(LGFIFO)
	) ar_crossover_fifo (
		.clk_in(S_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.clk_out(M_AXI_ACLK),
		.data_in({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.valid_in(S_AXI_ARVALID),
		.ready_in(S_AXI_ARREADY),
		.data_out({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
		.valid_out(M_AXI_ARVALID),
		.ready_out(M_AXI_ARREADY)
	);

	crossover_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(LGFIFO)
	) r_crossover_fifo (
		.clk_in(M_AXI_ACLK),
		.resetn_in(S_AXI_ARESETN),
		.clk_out(S_AXI_ACLK),
		.data_in({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.valid_in(M_AXI_RVALID),
		.ready_in(M_AXI_RREADY),
		.data_out({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
		.valid_out(S_AXI_RVALID),
		.ready_out(S_AXI_RREADY)
	);

	// Reset handling
	reg [XCLOCK_FFS-1:0] sreset_reg;
	reg [XCLOCK_FFS-1:0] mreset_reg;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			sreset_reg <= {XCLOCK_FFS{1'b1}};
		else
			sreset_reg <= {sreset_reg[XCLOCK_FFS-2:0], 1'b0};
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			mreset_reg <= {XCLOCK_FFS{1'b1}};
		else
			mreset_reg <= {mreset_reg[XCLOCK_FFS-2:0], 1'b0};
	end

	assign M_AXI_ARESETN = ~|mreset_reg;

endmodule

module crossover_fifo #(
		parameter DATA_WIDTH = 32,
		parameter DEPTH = 5
	) (
		input wire clk_in,
		input wire resetn_in,
		input wire clk_out,
		input wire [DATA_WIDTH-1:0] data_in,
		input wire valid_in,
		output wire ready_in,
		output wire [DATA_WIDTH-1:0] data_out,
		output wire valid_out,
		input wire ready_out
	);

	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
	reg [$clog2(DEPTH)-1:0] wr_ptr;
	reg [$clog2(DEPTH)-1:0] rd_ptr;
	reg [$clog2(DEPTH)-1:0] wr_ptr_gray;
	reg [$clog2(DEPTH)-1:0] rd_ptr_gray;
	reg [$clog2(DEPTH)-1:0] wr_ptr_gray_sync;
	reg [$clog2(DEPTH)-1:0] rd_ptr_gray_sync;
	reg full;
	reg empty;

	always @(posedge clk_in or negedge resetn_in) begin
		if (!resetn_in) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (valid_in && !full) begin
			mem[wr_ptr] <= data_in;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
		end
	end

	always @(posedge clk_out or negedge resetn_in) begin
		if (!resetn_in) begin
			rd_ptr_gray_sync <= 0;
			wr_ptr_gray_sync <= 0;
		end else begin
			rd_ptr_gray_sync <= rd_ptr_gray;
			wr_ptr_gray_sync <= wr_ptr_gray;
		end
	end

	always @(*) begin
		rd_ptr = rd_ptr_gray ^ (rd_ptr_gray >> 1);
		full = (wr_ptr_gray_sync ^ rd_ptr_gray) & ~(wr_ptr_gray_sync ^ (wr_ptr_gray_sync >> 1));
		empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);
	end

	always @(posedge clk_out or negedge resetn_in) begin
		if (!resetn_in)
			rd_ptr <= 0;
		else if (ready_out && !empty)
			rd_ptr <= rd_ptr + 1;
	end

	assign data_out = mem[rd_ptr];
	assign valid_out = !empty;
	assign ready_in = !full;

endmodule
