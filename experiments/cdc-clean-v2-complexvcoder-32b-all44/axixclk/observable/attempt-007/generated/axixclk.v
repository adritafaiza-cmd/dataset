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

	// Reset synchronization
	reg [XCLOCK_FFS-1:0] s_reset_sync, m_reset_sync;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			s_reset_sync <= {XCLOCK_FFS{1'b1}};
		else
			s_reset_sync <= {s_reset_sync[XCLOCK_FFS-2:0], 1'b0};
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= {XCLOCK_FFS{1'b1}};
		else
			m_reset_sync <= {m_reset_sync[XCLOCK_FFS-2:0], 1'b0};
	end

	assign M_AXI_ARESETN = s_reset_sync[XCLOCK_FFS-1];

	// FIFO for AW channel
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] aw_fifo_din, aw_fifo_dout;
	wire aw_fifo_valid_in, aw_fifo_ready_in, aw_fifo_valid_out, aw_fifo_ready_out;
	fifo_sync #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18),
		.DEPTH(LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.reset_n(S_AXI_ARESETN),
		.din_valid(S_AXI_AWVALID),
		.din_ready(S_AXI_AWREADY),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.clk_out(M_AXI_ACLK),
		.reset_n_out(S_AXI_ARESETN),
		.dout_valid(M_AXI_AWVALID),
		.dout_ready(M_AXI_AWREADY),
		.dout(aw_fifo_dout)
	);

	assign M_AXI_AWID = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 3 -: 8];
	assign M_AXI_AWSIZE = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH -: 3];
	assign M_AXI_AWBURST = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 5 -: 2];
	assign M_AXI_AWLOCK = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 6];
	assign M_AXI_AWCACHE = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 10 -: 4];
	assign M_AXI_AWPROT = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 13 -: 3];
	assign M_AXI_AWQOS = aw_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 16 -: 4];

	// FIFO for W channel
	wire [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1:0] w_fifo_din, w_fifo_dout;
	wire w_fifo_valid_in, w_fifo_ready_in, w_fifo_valid_out, w_fifo_ready_out;
	fifo_sync #(
		.WIDTH(C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1),
		.DEPTH(LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.reset_n(S_AXI_ARESETN),
		.din_valid(S_AXI_WVALID),
		.din_ready(S_AXI_WREADY),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.clk_out(M_AXI_ACLK),
		.reset_n_out(S_AXI_ARESETN),
		.dout_valid(w_fifo_valid_out),
		.dout_ready(w_fifo_ready_out),
		.dout(w_fifo_dout)
	);

	reg [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1:0] w_fifo_dout_reg;
	reg w_fifo_valid_out_reg;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_dout_reg <= 0;
			w_fifo_valid_out_reg <= 0;
		end else begin
			if (w_fifo_ready_out) begin
				w_fifo_dout_reg <= w_fifo_dout;
				w_fifo_valid_out_reg <= w_fifo_valid_out;
			end
		end
	end

	assign M_AXI_WDATA = w_fifo_dout_reg[C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB = w_fifo_dout_reg[C_S_AXI_DATA_WIDTH/8 -: C_S_AXI_DATA_WIDTH/8];
	assign M_AXI_WLAST = w_fifo_dout_reg[0];
	assign M_AXI_WVALID = w_fifo_valid_out_reg;

	// FIFO for B channel
	wire [C_S_AXI_ID_WIDTH + 1:0] b_fifo_din, b_fifo_dout;
	wire b_fifo_valid_in, b_fifo_ready_in, b_fifo_valid_out, b_fifo_ready_out;
	fifo_sync #(
		.WIDTH(C_S_AXI_ID_WIDTH + 1),
		.DEPTH(LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.reset_n(S_AXI_ARESETN),
		.din_valid(M_AXI_BVALID),
		.din_ready(M_AXI_BREADY),
		.din({M_AXI_BID, M_AXI_BRESP}),
		.clk_out(S_AXI_ACLK),
		.reset_n_out(S_AXI_ARESETN),
		.dout_valid(S_AXI_BVALID),
		.dout_ready(S_AXI_BREADY),
		.dout(b_fifo_dout)
	);

	assign S_AXI_BID = b_fifo_dout[C_S_AXI_ID_WIDTH + 1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP = b_fifo_dout[1:0];

	// FIFO for AR channel
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] ar_fifo_din, ar_fifo_dout;
	wire ar_fifo_valid_in, ar_fifo_ready_in, ar_fifo_valid_out, ar_fifo_ready_out;
	fifo_sync #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18),
		.DEPTH(LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.reset_n(S_AXI_ARESETN),
		.din_valid(S_AXI_ARVALID),
		.din_ready(S_AXI_ARREADY),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.clk_out(M_AXI_ACLK),
		.reset_n_out(S_AXI_ARESETN),
		.dout_valid(M_AXI_ARVALID),
		.dout_ready(M_AXI_ARREADY),
		.dout(ar_fifo_dout)
	);

	assign M_AXI_ARID = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 3 -: 8];
	assign M_AXI_ARSIZE = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH -: 3];
	assign M_AXI_ARBURST = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 5 -: 2];
	assign M_AXI_ARLOCK = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 6];
	assign M_AXI_ARCACHE = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 10 -: 4];
	assign M_AXI_ARPROT = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 13 -: 3];
	assign M_AXI_ARQOS = ar_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH - 16 -: 4];

	// FIFO for R channel
	wire [C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 3:0] r_fifo_din, r_fifo_dout;
	wire r_fifo_valid_in, r_fifo_ready_in, r_fifo_valid_out, r_fifo_ready_out;
	fifo_sync #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 3),
		.DEPTH(LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.reset_n(S_AXI_ARESETN),
		.din_valid(M_AXI_RVALID),
		.din_ready(M_AXI_RREADY),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.clk_out(S_AXI_ACLK),
		.reset_n_out(S_AXI_ARESETN),
		.dout_valid(S_AXI_RVALID),
		.dout_ready(S_AXI_RREADY),
		.dout(r_fifo_dout)
	);

	assign S_AXI_RID = r_fifo_dout[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 3 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_RDATA = r_fifo_dout[C_S_AXI_DATA_WIDTH + 3 -: C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP = r_fifo_dout[3:2];
	assign S_AXI_RLAST = r_fifo_dout[1];
	assign S_AXI_RVALID = r_fifo_valid_out;

endmodule

module fifo_sync #(
		parameter WIDTH = 8,
		parameter DEPTH = 4
	) (
		input wire clk,
		input wire reset_n,
		input wire din_valid,
		output wire din_ready,
		input wire [WIDTH-1:0] din,
		input wire clk_out,
		input wire reset_n_out,
		output wire dout_valid,
		input wire dout_ready,
		output wire [WIDTH-1:0] dout
	);

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
	reg [$clog2(DEPTH):0] wr_ptr_gray_out, rd_ptr_gray_out;

	assign din_ready = (wr_ptr_gray != rd_ptr_gray_out);
	assign dout_valid = (wr_ptr_gray_out != rd_ptr_gray);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (din_valid && din_ready) begin
			mem[wr_ptr] <= din;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
		end
	end

	always @(posedge clk_out or negedge reset_n_out) begin
		if (!reset_n_out) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
		end else if (dout_valid && dout_ready) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
		end
	end

	always @(posedge clk_out or negedge reset_n_out) begin
		if (!reset_n_out)
			wr_ptr_gray_out <= 0;
		else
			wr_ptr_gray_out <= wr_ptr_gray;
	end

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n)
			rd_ptr_gray_out <= 0;
		else
			rd_ptr_gray_out <= rd_ptr_gray;
	end

	assign dout = mem[rd_ptr];

endmodule
