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

	// Local parameters
	localparam integer AW_FIFO_DEPTH = 2**LGFIFO;
	localparam integer AW_FIFO_PTR_W = LGFIFO;
	localparam integer W_FIFO_DEPTH = 2**LGFIFO;
	localparam integer W_FIFO_PTR_W = LGFIFO;
	localparam integer B_FIFO_DEPTH = 2**LGFIFO;
	localparam integer B_FIFO_PTR_W = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 2**LGFIFO;
	localparam integer AR_FIFO_PTR_W = LGFIFO;
	localparam integer R_FIFO_DEPTH = 2**LGFIFO;
	localparam integer R_FIFO_PTR_W = LGFIFO;

	// AW channel: S to M
	wire [C_S_AXI_ID_WIDTH-1:0] aw_id_s;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_s;
	wire [7:0] aw_len_s;
	wire [2:0] aw_size_s;
	wire [1:0] aw_burst_s;
	wire aw_lock_s;
	wire [3:0] aw_cache_s;
	wire [2:0] aw_prot_s;
	wire [3:0] aw_qos_s;
	wire aw_valid_s;
	wire aw_ready_s;

	wire [C_S_AXI_ID_WIDTH-1:0] aw_id_m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_m;
	wire [7:0] aw_len_m;
	wire [2:0] aw_size_m;
	wire [1:0] aw_burst_m;
	wire aw_lock_m;
	wire [3:0] aw_cache_m;
	wire [2:0] aw_prot_m;
	wire [3:0] aw_qos_m;
	wire aw_valid_m;
	wire aw_ready_m;

	// W channel: S to M
	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_s;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s;
	wire w_last_s;
	wire w_valid_s;
	wire w_ready_s;

	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_m;
	wire w_last_m;
	wire w_valid_m;
	wire w_ready_m;

	// B channel: M to S
	wire [C_S_AXI_ID_WIDTH-1:0] b_id_m;
	wire [1:0] b_resp_m;
	wire b_valid_m;
	wire b_ready_m;

	wire [C_S_AXI_ID_WIDTH-1:0] b_id_s;
	wire [1:0] b_resp_s;
	wire b_valid_s;
	wire b_ready_s;

	// AR channel: S to M
	wire [C_S_AXI_ID_WIDTH-1:0] ar_id_s;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_s;
	wire [7:0] ar_len_s;
	wire [2:0] ar_size_s;
	wire [1:0] ar_burst_s;
	wire ar_lock_s;
	wire [3:0] ar_cache_s;
	wire [2:0] ar_prot_s;
	wire [3:0] ar_qos_s;
	wire ar_valid_s;
	wire ar_ready_s;

	wire [C_S_AXI_ID_WIDTH-1:0] ar_id_m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_m;
	wire [7:0] ar_len_m;
	wire [2:0] ar_size_m;
	wire [1:0] ar_burst_m;
	wire ar_lock_m;
	wire [3:0] ar_cache_m;
	wire [2:0] ar_prot_m;
	wire [3:0] ar_qos_m;
	wire ar_valid_m;
	wire ar_ready_m;

	// R channel: M to S
	wire [C_S_AXI_ID_WIDTH-1:0] r_id_m;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_m;
	wire [1:0] r_resp_m;
	wire r_last_m;
	wire r_valid_m;
	wire r_ready_m;

	wire [C_S_AXI_ID_WIDTH-1:0] r_id_s;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_s;
	wire [1:0] r_resp_s;
	wire r_last_s;
	wire r_valid_s;
	wire r_ready_s;

	// Connect S side
	assign S_AXI_AWREADY = aw_ready_s;
	assign aw_id_s = S_AXI_AWID;
	assign aw_addr_s = S_AXI_AWADDR;
	assign aw_len_s = S_AXI_AWLEN;
	assign aw_size_s = S_AXI_AWSIZE;
	assign aw_burst_s = S_AXI_AWBURST;
	assign aw_lock_s = S_AXI_AWLOCK;
	assign aw_cache_s = S_AXI_AWCACHE;
	assign aw_prot_s = S_AXI_AWPROT;
	assign aw_qos_s = S_AXI_AWQOS;
	assign aw_valid_s = S_AXI_AWVALID;

	assign S_AXI_WREADY = w_ready_s;
	assign w_data_s = S_AXI_WDATA;
	assign w_strb_s = S_AXI_WSTRB;
	assign w_last_s = S_AXI_WLAST;
	assign w_valid_s = S_AXI_WVALID;

	assign S_AXI_BID = b_id_s;
	assign S_AXI_BRESP = b_resp_s;
	assign S_AXI_BVALID = b_valid_s;
	assign b_ready_s = S_AXI_BREADY;

	assign S_AXI_ARREADY = ar_ready_s;
	assign ar_id_s = S_AXI_ARID;
	assign ar_addr_s = S_AXI_ARADDR;
	assign ar_len_s = S_AXI_ARLEN;
	assign ar_size_s = S_AXI_ARSIZE;
	assign ar_burst_s = S_AXI_ARBURST;
	assign ar_lock_s = S_AXI_ARLOCK;
	assign ar_cache_s = S_AXI_ARCACHE;
	assign ar_prot_s = S_AXI_ARPROT;
	assign ar_qos_s = S_AXI_ARQOS;
	assign ar_valid_s = S_AXI_ARVALID;

	assign S_AXI_RID = r_id_s;
	assign S_AXI_RDATA = r_data_s;
	assign S_AXI_RRESP = r_resp_s;
	assign S_AXI_RLAST = r_last_s;
	assign S_AXI_RVALID = r_valid_s;
	assign r_ready_s = S_AXI_RREADY;

	// Connect M side
	assign M_AXI_AWID = aw_id_m;
	assign M_AXI_AWADDR = aw_addr_m;
	assign M_AXI_AWLEN = aw_len_m;
	assign M_AXI_AWSIZE = aw_size_m;
	assign M_AXI_AWBURST = aw_burst_m;
	assign M_AXI_AWLOCK = aw_lock_m;
	assign M_AXI_AWCACHE = aw_cache_m;
	assign M_AXI_AWPROT = aw_prot_m;
	assign M_AXI_AWQOS = aw_qos_m;
	assign M_AXI_AWVALID = aw_valid_m;
	assign aw_ready_m = M_AXI_AWREADY;

	assign M_AXI_WDATA = w_data_m;
	assign M_AXI_WSTRB = w_strb_m;
	assign M_AXI_WLAST = w_last_m;
	assign M_AXI_WVALID = w_valid_m;
	assign w_ready_m = M_AXI_WREADY;

	assign b_id_m = M_AXI_BID;
	assign b_resp_m = M_AXI_BRESP;
	assign b_valid_m = M_AXI_BVALID;
	assign M_AXI_BREADY = b_ready_m;

	assign M_AXI_ARID = ar_id_m;
	assign M_AXI_ARADDR = ar_addr_m;
	assign M_AXI_ARLEN = ar_len_m;
	assign M_AXI_ARSIZE = ar_size_m;
	assign M_AXI_ARBURST = ar_burst_m;
	assign M_AXI_ARLOCK = ar_lock_m;
	assign M_AXI_ARCACHE = ar_cache_m;
	assign M_AXI_ARPROT = ar_prot_m;
	assign M_AXI_ARQOS = ar_qos_m;
	assign M_AXI_ARVALID = ar_valid_m;
	assign ar_ready_m = M_AXI_ARREADY;

	assign r_id_m = M_AXI_RID;
	assign r_data_m = M_AXI_RDATA;
	assign r_resp_m = M_AXI_RRESP;
	assign r_last_m = M_AXI_RLAST;
	assign r_valid_m = M_AXI_RVALID;
	assign M_AXI_RREADY = r_ready_m;

	// AW FIFO: S to M
	aw_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.FIFO_DEPTH(AW_FIFO_DEPTH),
		.PTR_WIDTH(AW_FIFO_PTR_W)
	) u_aw_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.wr_en(aw_valid_s & aw_ready_s),
		.wr_data({aw_id_s, aw_addr_s, aw_len_s, aw_size_s, aw_burst_s, aw_lock_s, aw_cache_s, aw_prot_s, aw_qos_s}),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.rd_en(aw_valid_m & aw_ready_m),
		.rd_data({aw_id_m, aw_addr_m, aw_len_m, aw_size_m, aw_burst_m, aw_lock_m, aw_cache_m, aw_prot_m, aw_qos_m}),
		.full(aw_full_s),
		.empty(aw_empty_m)
	);

	wire aw_full_s;
	wire aw_empty_m;

	assign aw_ready_s = ~aw_full_s;
	assign aw_valid_m = ~aw_empty_m;

	// W FIFO: S to M
	w_fifo #(
		.DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.FIFO_DEPTH(W_FIFO_DEPTH),
		.PTR_WIDTH(W_FIFO_PTR_W)
	) u_w_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.wr_en(w_valid_s & w_ready_s),
		.wr_data({w_data_s, w_strb_s, w_last_s}),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.rd_en(w_valid_m & w_ready_m),
		.rd_data({w_data_m, w_strb_m, w_last_m}),
		.full(w_full_s),
		.empty(w_empty_m)
	);

	wire w_full_s;
	wire w_empty_m;

	assign w_ready_s = ~w_full_s;
	assign w_valid_m = ~w_empty_m;

	// B FIFO: M to S
	b_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
		.FIFO_DEPTH(B_FIFO_DEPTH),
		.PTR_WIDTH(B_FIFO_PTR_W)
	) u_b_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst_n(M_AXI_ARESETN),
		.wr_en(b_valid_m & b_ready_m),
		.wr_data({b_id_m, b_resp_m}),
		.rd_clk(S_AXI_ACLK),
		.rd_rst_n(S_AXI_ARESETN),
		.rd_en(b_valid_s & b_ready_s),
		.rd_data({b_id_s, b_resp_s}),
		.full(b_full_m),
		.empty(b_empty_s)
	);

	wire b_full_m;
	wire b_empty_s;

	assign b_ready_m = ~b_full_m;
	assign b_valid_s = ~b_empty_s;

	// AR FIFO: S to M
	ar_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.FIFO_DEPTH(AR_FIFO_DEPTH),
		.PTR_WIDTH(AR_FIFO_PTR_W)
	) u_ar_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.wr_en(ar_valid_s & ar_ready_s),
		.wr_data({ar_id_s, ar_addr_s, ar_len_s, ar_size_s, ar_burst_s, ar_lock_s, ar_cache_s, ar_prot_s, ar_qos_s}),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.rd_en(ar_valid_m & ar_ready_m),
		.rd_data({ar_id_m, ar_addr_m, ar_len_m, ar_size_m, ar_burst_m, ar_lock_m, ar_cache_m, ar_prot_m, ar_qos_m}),
		.full(ar_full_s),
		.empty(ar_empty_m)
	);

	wire ar_full_s;
	wire ar_empty_m;

	assign ar_ready_s = ~ar_full_s;
	assign ar_valid_m = ~ar_empty_m;

	// R FIFO: M to S
	r_fifo #(
		.DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.FIFO_DEPTH(R_FIFO_DEPTH),
		.PTR_WIDTH(R_FIFO_PTR_W)
	) u_r_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst_n(M_AXI_ARESETN),
		.wr_en(r_valid_m & r_ready_m),
		.wr_data({r_id_m, r_data_m, r_resp_m, r_last_m}),
		.rd_clk(S_AXI_ACLK),
		.rd_rst_n(S_AXI_ARESETN),
		.rd_en(r_valid_s & r_ready_s),
		.rd_data({r_id_s, r_data_s, r_resp_s, r_last_s}),
		.full(r_full_m),
		.empty(r_empty_s)
	);

	wire r_full_m;
	wire r_empty_s;

	assign r_ready_m = ~r_full_m;
	assign r_valid_s = ~r_empty_s;

	// Reset synchronization for M_AXI_ARESETN
	reg [1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= 2'b00;
		else
			m_reset_sync <= {m_reset_sync[0], 1'b1};
	end
	assign M_AXI_ARESETN = m_reset_sync[1];

	// FIFO module
	module aw_fifo #(
		parameter DATA_WIDTH = 32,
		parameter FIFO_DEPTH = 16,
		parameter PTR_WIDTH = 4
	) (
		input wr_clk,
		input wr_rst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		input rd_clk,
		input rd_rst_n,
		input rd_en,
		output [DATA_WIDTH-1:0] rd_data,
		output full,
		output empty
	);
		reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
		reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
		reg [PTR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
		reg [PTR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

		// Gray code conversion
		function [PTR_WIDTH:0] bin2gray;
			input [PTR_WIDTH:0] bin;
			begin
				bin2gray = bin ^ (bin >> 1);
			end
		endfunction

		// Write pointer
		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				wr_ptr <= 0;
			else if (wr_en && !full)
				wr_ptr <= wr_ptr + 1;
		end

		// Read pointer
		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				rd_ptr <= 0;
			else if (rd_en && !empty)
				rd_ptr <= rd_ptr + 1;
		end

		// Gray code pointers
		always @(*) begin
			wr_ptr_gray = bin2gray(wr_ptr);
			rd_ptr_gray = bin2gray(rd_ptr);
		end

		// Synchronize write pointer gray to read clock
		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				wr_ptr_gray_sync <= 0;
			else
				wr_ptr_gray_sync <= wr_ptr_gray;
		end

		// Synchronize read pointer gray to write clock
		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				rd_ptr_gray_sync <= 0;
			else
				rd_ptr_gray_sync <= rd_ptr_gray;
		end

		// Full and empty detection
		assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[PTR_WIDTH:1], rd_ptr_gray[0]}) &&
		              (wr_ptr_gray_sync[PTR_WIDTH] == rd_ptr_gray_sync[PTR_WIDTH]);
		assign empty = (rd_ptr_gray_sync == wr_ptr_gray_sync);

		// Write data
		always @(posedge wr_clk) begin
			if (wr_en && !full)
				mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
		end

		// Read data
		always @(posedge rd_clk) begin
			if (rd_en && !empty)
				rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
		end
	endmodule

	module w_fifo #(
		parameter DATA_WIDTH = 32,
		parameter FIFO_DEPTH = 16,
		parameter PTR_WIDTH = 4
	) (
		input wr_clk,
		input wr_rst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		input rd_clk,
		input rd_rst_n,
		input rd_en,
		output [DATA_WIDTH-1:0] rd_data,
		output full,
		output empty
	);
		reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
		reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
		reg [PTR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
		reg [PTR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

		function [PTR_WIDTH:0] bin2gray;
			input [PTR_WIDTH:0] bin;
			begin
				bin2gray = bin ^ (bin >> 1);
			end
		endfunction

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				wr_ptr <= 0;
			else if (wr_en && !full)
				wr_ptr <= wr_ptr + 1;
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				rd_ptr <= 0;
			else if (rd_en && !empty)
				rd_ptr <= rd_ptr + 1;
		end

		always @(*) begin
			wr_ptr_gray = bin2gray(wr_ptr);
			rd_ptr_gray = bin2gray(rd_ptr);
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				wr_ptr_gray_sync <= 0;
			else
				wr_ptr_gray_sync <= wr_ptr_gray;
		end

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				rd_ptr_gray_sync <= 0;
			else
				rd_ptr_gray_sync <= rd_ptr_gray;
		end

		assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[PTR_WIDTH:1], rd_ptr_gray[0]}) &&
		              (wr_ptr_gray_sync[PTR_WIDTH] == rd_ptr_gray_sync[PTR_WIDTH]);
		assign empty = (rd_ptr_gray_sync == wr_ptr_gray_sync);

		always @(posedge wr_clk) begin
			if (wr_en && !full)
				mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
		end

		always @(posedge rd_clk) begin
			if (rd_en && !empty)
				rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
		end
	endmodule

	module b_fifo #(
		parameter DATA_WIDTH = 32,
		parameter FIFO_DEPTH = 16,
		parameter PTR_WIDTH = 4
	) (
		input wr_clk,
		input wr_rst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		input rd_clk,
		input rd_rst_n,
		input rd_en,
		output [DATA_WIDTH-1:0] rd_data,
		output full,
		output empty
	);
		reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
		reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
		reg [PTR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
		reg [PTR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

		function [PTR_WIDTH:0] bin2gray;
			input [PTR_WIDTH:0] bin;
			begin
				bin2gray = bin ^ (bin >> 1);
			end
		endfunction

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				wr_ptr <= 0;
			else if (wr_en && !full)
				wr_ptr <= wr_ptr + 1;
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				rd_ptr <= 0;
			else if (rd_en && !empty)
				rd_ptr <= rd_ptr + 1;
		end

		always @(*) begin
			wr_ptr_gray = bin2gray(wr_ptr);
			rd_ptr_gray = bin2gray(rd_ptr);
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				wr_ptr_gray_sync <= 0;
			else
				wr_ptr_gray_sync <= wr_ptr_gray;
		end

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				rd_ptr_gray_sync <= 0;
			else
				rd_ptr_gray_sync <= rd_ptr_gray;
		end

		assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[PTR_WIDTH:1], rd_ptr_gray[0]}) &&
		              (wr_ptr_gray_sync[PTR_WIDTH] == rd_ptr_gray_sync[PTR_WIDTH]);
		assign empty = (rd_ptr_gray_sync == wr_ptr_gray_sync);

		always @(posedge wr_clk) begin
			if (wr_en && !full)
				mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
		end

		always @(posedge rd_clk) begin
			if (rd_en && !empty)
				rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
		end
	endmodule

	module ar_fifo #(
		parameter DATA_WIDTH = 32,
		parameter FIFO_DEPTH = 16,
		parameter PTR_WIDTH = 4
	) (
		input wr_clk,
		input wr_rst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		input rd_clk,
		input rd_rst_n,
		input rd_en,
		output [DATA_WIDTH-1:0] rd_data,
		output full,
		output empty
	);
		reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
		reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
		reg [PTR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
		reg [PTR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

		function [PTR_WIDTH:0] bin2gray;
			input [PTR_WIDTH:0] bin;
			begin
				bin2gray = bin ^ (bin >> 1);
			end
		endfunction

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				wr_ptr <= 0;
			else if (wr_en && !full)
				wr_ptr <= wr_ptr + 1;
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				rd_ptr <= 0;
			else if (rd_en && !empty)
				rd_ptr <= rd_ptr + 1;
		end

		always @(*) begin
			wr_ptr_gray = bin2gray(wr_ptr);
			rd_ptr_gray = bin2gray(rd_ptr);
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				wr_ptr_gray_sync <= 0;
			else
				wr_ptr_gray_sync <= wr_ptr_gray;
		end

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				rd_ptr_gray_sync <= 0;
			else
				rd_ptr_gray_sync <= rd_ptr_gray;
		end

		assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[PTR_WIDTH:1], rd_ptr_gray[0]}) &&
		              (wr_ptr_gray_sync[PTR_WIDTH] == rd_ptr_gray_sync[PTR_WIDTH]);
		assign empty = (rd_ptr_gray_sync == wr_ptr_gray_sync);

		always @(posedge wr_clk) begin
			if (wr_en && !full)
				mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
		end

		always @(posedge rd_clk) begin
			if (rd_en && !empty)
				rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
		end
	endmodule

	module r_fifo #(
		parameter DATA_WIDTH = 32,
		parameter FIFO_DEPTH = 16,
		parameter PTR_WIDTH = 4
	) (
		input wr_clk,
		input wr_rst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		input rd_clk,
		input rd_rst_n,
		input rd_en,
		output [DATA_WIDTH-1:0] rd_data,
		output full,
		output empty
	);
		reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
		reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
		reg [PTR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
		reg [PTR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

		function [PTR_WIDTH:0] bin2gray;
			input [PTR_WIDTH:0] bin;
			begin
				bin2gray = bin ^ (bin >> 1);
			end
		endfunction

		always @(posedge wr_clk or negedge wr_rst_n) begin
			if (!wr_rst_n)
				wr_ptr <= 0;
			else if (wr_en && !full)
				wr_ptr <= wr_ptr + 1;
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				rd_ptr <= 0;
			else if (rd_en && !empty)
				rd_ptr <= rd_ptr + 1;
		end

		always @(*) begin
			wr_ptr_gray = bin2gray(wr_ptr);
			rd_ptr_gray = bin2gray(rd_ptr);
		end

		always @(posedge rd_clk or negedge rd_rst_n) begin
			if (!rd_rst_n)
				wr_ptr_gray_sync <= 0;
			else
				wr_ptr_gray_sync <= wr_ptr_gray;
		end

		always @(posedge wr_clk or negedge wr_rst_n