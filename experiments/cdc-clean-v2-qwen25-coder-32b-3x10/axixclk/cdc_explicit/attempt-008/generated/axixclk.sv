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
	reg [XCLOCK_FFS-1:0] s_axi_reset_sync;
	reg [XCLOCK_FFS-1:0] m_axi_reset_sync;
	reg s_axi_reset_synced;
	reg m_axi_reset_synced;

	// Reset synchronization
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_axi_reset_sync <= {XCLOCK_FFS{1'b1}};
		end else begin
			s_axi_reset_sync <= {s_axi_reset_sync[XCLOCK_FFS-2:0], 1'b0};
		end
	end

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_reset_sync <= {XCLOCK_FFS{1'b1}};
		end else begin
			m_axi_reset_sync <= {m_axi_reset_sync[XCLOCK_FFS-2:0], 1'b0};
		end
	end

	assign s_axi_reset_synced = s_axi_reset_sync[XCLOCK_FFS-1];
	assign m_axi_reset_synced = m_axi_reset_sync[XCLOCK_FFS-1];
	assign M_AXI_ARESETN = ~m_axi_reset_synced;

	// FIFOs for AW channel
	wire aw_full, aw_empty;
	wire [C_S_AXI_ID_WIDTH-1:0] aw_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_out;
	wire [7:0] aw_len_out;
	wire [2:0] aw_size_out;
	wire [1:0] aw_burst_out;
	wire aw_lock_out;
	wire [3:0] aw_cache_out;
	wire [2:0] aw_prot_out;
	wire [3:0] aw_qos_out;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_axi_reset_synced),
		.wr_en(S_AXI_AWVALID && S_AXI_AWREADY),
		.rd_en(M_AXI_AWREADY && !aw_empty),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.dout({aw_id_out, aw_addr_out, aw_len_out, aw_size_out, aw_burst_out, aw_lock_out, aw_cache_out, aw_prot_out, aw_qos_out}),
		.full(aw_full),
		.empty(aw_empty)
	);

	assign S_AXI_AWREADY = !aw_full;
	assign M_AXI_AWID = aw_id_out;
	assign M_AXI_AWADDR = aw_addr_out;
	assign M_AXI_AWLEN = aw_len_out;
	assign M_AXI_AWSIZE = aw_size_out;
	assign M_AXI_AWBURST = aw_burst_out;
	assign M_AXI_AWLOCK = aw_lock_out;
	assign M_AXI_AWCACHE = aw_cache_out;
	assign M_AXI_AWPROT = aw_prot_out;
	assign M_AXI_AWQOS = aw_qos_out;
	assign M_AXI_AWVALID = !aw_empty;

	// FIFOs for W channel
	wire w_full, w_empty;
	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_out;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_out;
	wire w_last_out;

	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_axi_reset_synced),
		.wr_en(S_AXI_WVALID && S_AXI_WREADY),
		.rd_en(M_AXI_WREADY && !w_empty),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.dout({w_data_out, w_strb_out, w_last_out}),
		.full(w_full),
		.empty(w_empty)
	);

	assign S_AXI_WREADY = !w_full;
	assign M_AXI_WDATA = w_data_out;
	assign M_AXI_WSTRB = w_strb_out;
	assign M_AXI_WLAST = w_last_out;
	assign M_AXI_WVALID = !w_empty;

	// FIFOs for B channel
	wire b_full, b_empty;
	wire [C_S_AXI_ID_WIDTH-1:0] b_id_out;
	wire [1:0] b_resp_out;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(1 << LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.rst(m_axi_reset_synced),
		.wr_en(M_AXI_BVALID && M_AXI_BREADY),
		.rd_en(S_AXI_BREADY && !b_empty),
		.din({M_AXI_BID, M_AXI_BRESP}),
		.dout({b_id_out, b_resp_out}),
		.full(b_full),
		.empty(b_empty)
	);

	assign M_AXI_BREADY = !b_full;
	assign S_AXI_BID = b_id_out;
	assign S_AXI_BRESP = b_resp_out;
	assign S_AXI_BVALID = !b_empty;

	// FIFOs for AR channel
	wire ar_full, ar_empty;
	wire [C_S_AXI_ID_WIDTH-1:0] ar_id_out;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_out;
	wire [7:0] ar_len_out;
	wire [2:0] ar_size_out;
	wire [1:0] ar_burst_out;
	wire ar_lock_out;
	wire [3:0] ar_cache_out;
	wire [2:0] ar_prot_out;
	wire [3:0] ar_qos_out;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_axi_reset_synced),
		.wr_en(S_AXI_ARVALID && S_AXI_ARREADY),
		.rd_en(M_AXI_ARREADY && !ar_empty),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.dout({ar_id_out, ar_addr_out, ar_len_out, ar_size_out, ar_burst_out, ar_lock_out, ar_cache_out, ar_prot_out, ar_qos_out}),
		.full(ar_full),
		.empty(ar_empty)
	);

	assign S_AXI_ARREADY = !ar_full;
	assign M_AXI_ARID = ar_id_out;
	assign M_AXI_ARADDR = ar_addr_out;
	assign M_AXI_ARLEN = ar_len_out;
	assign M_AXI_ARSIZE = ar_size_out;
	assign M_AXI_ARBURST = ar_burst_out;
	assign M_AXI_ARLOCK = ar_lock_out;
	assign M_AXI_ARCACHE = ar_cache_out;
	assign M_AXI_ARPROT = ar_prot_out;
	assign M_AXI_ARQOS = ar_qos_out;
	assign M_AXI_ARVALID = !ar_empty;

	// FIFOs for R channel
	wire r_full, r_empty;
	wire [C_S_AXI_ID_WIDTH-1:0] r_id_out;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_out;
	wire [1:0] r_resp_out;
	wire r_last_out;

	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.rst(m_axi_reset_synced),
		.wr_en(M_AXI_RVALID && M_AXI_RREADY),
		.rd_en(S_AXI_RREADY && !r_empty),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.dout({r_id_out, r_data_out, r_resp_out, r_last_out}),
		.full(r_full),
		.empty(r_empty)
	);

	assign M_AXI_RREADY = !r_full;
	assign S_AXI_RID = r_id_out;
	assign S_AXI_RDATA = r_data_out;
	assign S_AXI_RRESP = r_resp_out;
	assign S_AXI_RLAST = r_last_out;
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
	output reg empty
);

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH):0] count;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			count <= 0;
			full <= 0;
			empty <= 1;
		end else begin
			if (wr_en && !full) begin
				mem[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				count <= count + 1;
			end
			if (rd_en && !empty) begin
				dout <= mem[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				count <= count - 1;
			end
			full <= (count == DEPTH);
			empty <= (count == 0);
		end
	end

endmodule
