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
	reg [XCLOCK_FFS-1:0] s_reset_sync;
	reg [XCLOCK_FFS-1:0] m_reset_sync;
	reg s_reset_n;
	reg m_reset_n;

	// Reset synchronization
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_reset_sync <= {XCLOCK_FFS{1'b0}};
			s_reset_n <= 1'b0;
		end else begin
			s_reset_sync <= {s_reset_sync[XCLOCK_FFS-2:0], 1'b1};
			s_reset_n <= s_reset_sync[XCLOCK_FFS-1];
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= {XCLOCK_FFS{1'b0}};
			m_reset_n <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[XCLOCK_FFS-2:0], 1'b1};
			m_reset_n <= m_reset_sync[XCLOCK_FFS-1];
		end
	end

	assign M_AXI_ARESETN = m_reset_n;

	// FIFOs for AW, W, B, AR, R channels
	wire aw_full, aw_empty, aw_almost_full, aw_almost_empty;
	wire w_full, w_empty, w_almost_full, w_almost_empty;
	wire b_full, b_empty, b_almost_full, b_almost_empty;
	wire ar_full, ar_empty, ar_almost_full, ar_almost_empty;
	wire r_full, r_empty, r_almost_full, r_almost_empty;

	// AW FIFO
	wire [C_S_AXI_ID_WIDTH-1:0] aw_fifo_dout_id;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_dout_addr;
	wire [7:0] aw_fifo_dout_len;
	wire [2:0] aw_fifo_dout_size;
	wire [1:0] aw_fifo_dout_burst;
	wire aw_fifo_dout_lock;
	wire [3:0] aw_fifo_dout_cache;
	wire [2:0] aw_fifo_dout_prot;
	wire [3:0] aw_fifo_dout_qos;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.rst(!s_reset_n),
		.wr_en(S_AXI_AWVALID && !aw_full),
		.rd_en(M_AXI_AWREADY && !aw_empty),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.dout({aw_fifo_dout_id, aw_fifo_dout_addr, aw_fifo_dout_len, aw_fifo_dout_size, aw_fifo_dout_burst, aw_fifo_dout_lock, aw_fifo_dout_cache, aw_fifo_dout_prot, aw_fifo_dout_qos}),
		.full(aw_full),
		.empty(aw_empty),
		.almost_full(aw_almost_full),
		.almost_empty(aw_almost_empty)
	);

	assign S_AXI_AWREADY = !aw_full;
	assign M_AXI_AWID = aw_fifo_dout_id;
	assign M_AXI_AWADDR = aw_fifo_dout_addr;
	assign M_AXI_AWLEN = aw_fifo_dout_len;
	assign M_AXI_AWSIZE = aw_fifo_dout_size;
	assign M_AXI_AWBURST = aw_fifo_dout_burst;
	assign M_AXI_AWLOCK = aw_fifo_dout_lock;
	assign M_AXI_AWCACHE = aw_fifo_dout_cache;
	assign M_AXI_AWPROT = aw_fifo_dout_prot;
	assign M_AXI_AWQOS = aw_fifo_dout_qos;
	assign M_AXI_AWVALID = !aw_empty;

	// W FIFO
	wire [C_S_AXI_DATA_WIDTH-1:0] w_fifo_dout_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_dout_strb;
	wire w_fifo_dout_last;

	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.rst(!s_reset_n),
		.wr_en(S_AXI_WVALID && !w_full),
		.rd_en(M_AXI_WREADY && !w_empty),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.dout({w_fifo_dout_data, w_fifo_dout_strb, w_fifo_dout_last}),
		.full(w_full),
		.empty(w_empty),
		.almost_full(w_almost_full),
		.almost_empty(w_almost_empty)
	);

	assign S_AXI_WREADY = !w_full;
	assign M_AXI_WDATA = w_fifo_dout_data;
	assign M_AXI_WSTRB = w_fifo_dout_strb;
	assign M_AXI_WLAST = w_fifo_dout_last;
	assign M_AXI_WVALID = !w_empty;

	// B FIFO
	wire [C_S_AXI_ID_WIDTH-1:0] b_fifo_dout_id;
	wire [1:0] b_fifo_dout_resp;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(1 << LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.rst(!m_reset_n),
		.wr_en(M_AXI_BVALID && !b_full),
		.rd_en(S_AXI_BREADY && !b_empty),
		.din({M_AXI_BID, M_AXI_BRESP}),
		.dout({b_fifo_dout_id, b_fifo_dout_resp}),
		.full(b_full),
		.empty(b_empty),
		.almost_full(b_almost_full),
		.almost_empty(b_almost_empty)
	);

	assign M_AXI_BREADY = !b_full;
	assign S_AXI_BID = b_fifo_dout_id;
	assign S_AXI_BRESP = b_fifo_dout_resp;
	assign S_AXI_BVALID = !b_empty;

	// AR FIFO
	wire [C_S_AXI_ID_WIDTH-1:0] ar_fifo_dout_id;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_dout_addr;
	wire [7:0] ar_fifo_dout_len;
	wire [2:0] ar_fifo_dout_size;
	wire [1:0] ar_fifo_dout_burst;
	wire ar_fifo_dout_lock;
	wire [3:0] ar_fifo_dout_cache;
	wire [2:0] ar_fifo_dout_prot;
	wire [3:0] ar_fifo_dout_qos;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.rst(!s_reset_n),
		.wr_en(S_AXI_ARVALID && !ar_full),
		.rd_en(M_AXI_ARREADY && !ar_empty),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.dout({ar_fifo_dout_id, ar_fifo_dout_addr, ar_fifo_dout_len, ar_fifo_dout_size, ar_fifo_dout_burst, ar_fifo_dout_lock, ar_fifo_dout_cache, ar_fifo_dout_prot, ar_fifo_dout_qos}),
		.full(ar_full),
		.empty(ar_empty),
		.almost_full(ar_almost_full),
		.almost_empty(ar_almost_empty)
	);

	assign S_AXI_ARREADY = !ar_full;
	assign M_AXI_ARID = ar_fifo_dout_id;
	assign M_AXI_ARADDR = ar_fifo_dout_addr;
	assign M_AXI_ARLEN = ar_fifo_dout_len;
	assign M_AXI_ARSIZE = ar_fifo_dout_size;
	assign M_AXI_ARBURST = ar_fifo_dout_burst;
	assign M_AXI_ARLOCK = ar_fifo_dout_lock;
	assign M_AXI_ARCACHE = ar_fifo_dout_cache;
	assign M_AXI_ARPROT = ar_fifo_dout_prot;
	assign M_AXI_ARQOS = ar_fifo_dout_qos;
	assign M_AXI_ARVALID = !ar_empty;

	// R FIFO
	wire [C_S_AXI_ID_WIDTH-1:0] r_fifo_dout_id;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_fifo_dout_data;
	wire [1:0] r_fifo_dout_resp;
	wire r_fifo_dout_last;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.rst(!m_reset_n),
		.wr_en(M_AXI_RVALID && !r_full),
		.rd_en(S_AXI_RREADY && !r_empty),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.dout({r_fifo_dout_id, r_fifo_dout_data, r_fifo_dout_resp, r_fifo_dout_last}),
		.full(r_full),
		.empty(r_empty),
		.almost_full(r_almost_full),
		.almost_empty(r_almost_empty)
	);

	assign M_AXI_RREADY = !r_full;
	assign S_AXI_RID = r_fifo_dout_id;
	assign S_AXI_RDATA = r_fifo_dout_data;
	assign S_AXI_RRESP = r_fifo_dout_resp;
	assign S_AXI_RLAST = r_fifo_dout_last;
	assign S_AXI_RVALID = !r_empty;

endmodule

// FIFO module
module fifo #(
		parameter WIDTH = 32,
		parameter DEPTH = 16
	) (
		input wire clk,
		input wire rst,
		input wire wr_en,
		input wire rd_en,
		input wire [WIDTH-1:0] din,
		output reg [WIDTH-1:0] dout,
		output reg full,
		output reg empty,
		output reg almost_full,
		output reg almost_empty
	);

	localparam ADDR_WIDTH = $clog2(DEPTH);
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] count;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			count <= 0;
			full <= 0;
			empty <= 1;
			almost_full <= 0;
			almost_empty <= 1;
		end else begin
			if (wr_en && !full) begin
				mem[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				count <= count + 1;
			end
			if (rd_en && !empty) begin
				rd_ptr <= rd_ptr + 1;
				count <= count - 1;
			end

			full <= (count == DEPTH);
			empty <= (count == 0);
			almost_full <= (count == DEPTH - 1);
			almost_empty <= (count == 1);
		end
	end

	always @(posedge clk or posedge rst) begin
		if (rst)
			dout <= 0;
		else if (rd_en && !empty)
			dout <= mem[rd_ptr];
	end

endmodule
