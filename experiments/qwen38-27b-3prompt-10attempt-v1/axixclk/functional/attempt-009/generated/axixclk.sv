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
	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer FFS_STAGES = XCLOCK_FFS;

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] aw_fifo_dout_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] aw_fifo_dout_addr;
	wire [7 : 0] aw_fifo_dout_len;
	wire [2 : 0] aw_fifo_dout_size;
	wire [1 : 0] aw_fifo_dout_burst;
	wire aw_fifo_dout_lock;
	wire [3 : 0] aw_fifo_dout_cache;
	wire [2 : 0] aw_fifo_dout_prot;
	wire [3 : 0] aw_fifo_dout_qos;
	wire aw_fifo_empty;
	wire aw_fifo_full;
	wire aw_fifo_wr_en;
	wire aw_fifo_rd_en;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] w_fifo_dout_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_fifo_dout_strb;
	wire w_fifo_dout_last;
	wire w_fifo_empty;
	wire w_fifo_full;
	wire w_fifo_wr_en;
	wire w_fifo_rd_en;

	wire [C_S_AXI_ID_WIDTH-1 : 0] b_fifo_dout_id;
	wire [1 : 0] b_fifo_dout_resp;
	wire b_fifo_empty;
	wire b_fifo_full;
	wire b_fifo_wr_en;
	wire b_fifo_rd_en;

	wire [C_S_AXI_ID_WIDTH-1 : 0] ar_fifo_dout_id;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] ar_fifo_dout_addr;
	wire [7 : 0] ar_fifo_dout_len;
	wire [2 : 0] ar_fifo_dout_size;
	wire [1 : 0] ar_fifo_dout_burst;
	wire ar_fifo_dout_lock;
	wire [3 : 0] ar_fifo_dout_cache;
	wire [2 : 0] ar_fifo_dout_prot;
	wire [3 : 0] ar_fifo_dout_qos;
	wire ar_fifo_empty;
	wire ar_fifo_full;
	wire ar_fifo_wr_en;
	wire ar_fifo_rd_en;

	wire [C_S_AXI_ID_WIDTH-1 : 0] r_fifo_dout_id;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] r_fifo_dout_data;
	wire [1 : 0] r_fifo_dout_resp;
	wire r_fifo_dout_last;
	wire r_fifo_empty;
	wire r_fifo_full;
	wire r_fifo_wr_en;
	wire r_fifo_rd_en;

	// Reset synchronization for M_AXI_ACLK domain
	reg [FFS_STAGES-1 : 0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= {FFS_STAGES{1'b0}};
		end else begin
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
		end
	end
	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// AW Channel: Slave to Master
	// Write to FIFO in S_AXI_ACLK domain
	assign aw_fifo_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	assign S_AXI_AWREADY = !aw_fifo_full;

	// Read from FIFO in M_AXI_ACLK domain
	assign aw_fifo_rd_en = M_AXI_AWREADY && !aw_fifo_empty;
	assign M_AXI_AWVALID = !aw_fifo_empty;
	assign M_AXI_AWID = aw_fifo_dout_id;
	assign M_AXI_AWADDR = aw_fifo_dout_addr;
	assign M_AXI_AWLEN = aw_fifo_dout_len;
	assign M_AXI_AWSIZE = aw_fifo_dout_size;
	assign M_AXI_AWBURST = aw_fifo_dout_burst;
	assign M_AXI_AWLOCK = aw_fifo_dout_lock;
	assign M_AXI_AWCACHE = aw_fifo_dout_cache;
	assign M_AXI_AWPROT = aw_fifo_dout_prot;
	assign M_AXI_AWQOS = aw_fifo_dout_qos;

	// W Channel: Slave to Master
	// Write to FIFO in S_AXI_ACLK domain
	assign w_fifo_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	assign S_AXI_WREADY = !w_fifo_full;

	// Read from FIFO in M_AXI_ACLK domain
	// Master write data is held one extra M_AXI clock before M_AXI_WVALID
	reg w_valid_reg;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_valid_reg <= 1'b0;
		end else begin
			w_valid_reg <= !w_fifo_empty;
		end
	end
	assign M_AXI_WVALID = w_valid_reg;
	assign w_fifo_rd_en = M_AXI_WREADY && w_valid_reg;
	assign M_AXI_WDATA = w_fifo_dout_data;
	assign M_AXI_WSTRB = w_fifo_dout_strb;
	assign M_AXI_WLAST = w_fifo_dout_last;

	// B Channel: Master to Slave
	// Write to FIFO in M_AXI_ACLK domain
	assign b_fifo_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	assign M_AXI_BREADY = !b_fifo_full;

	// Read from FIFO in S_AXI_ACLK domain
	assign b_fifo_rd_en = S_AXI_BREADY && !b_fifo_empty;
	assign S_AXI_BVALID = !b_fifo_empty;
	assign S_AXI_BID = b_fifo_dout_id;
	assign S_AXI_BRESP = b_fifo_dout_resp;

	// AR Channel: Slave to Master
	// Write to FIFO in S_AXI_ACLK domain
	assign ar_fifo_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	assign S_AXI_ARREADY = !ar_fifo_full;

	// Read from FIFO in M_AXI_ACLK domain
	assign ar_fifo_rd_en = M_AXI_ARREADY && !ar_fifo_empty;
	assign M_AXI_ARVALID = !ar_fifo_empty;
	assign M_AXI_ARID = ar_fifo_dout_id;
	assign M_AXI_ARADDR = ar_fifo_dout_addr;
	assign M_AXI_ARLEN = ar_fifo_dout_len;
	assign M_AXI_ARSIZE = ar_fifo_dout_size;
	assign M_AXI_ARBURST = ar_fifo_dout_burst;
	assign M_AXI_ARLOCK = ar_fifo_dout_lock;
	assign M_AXI_ARCACHE = ar_fifo_dout_cache;
	assign M_AXI_ARPROT = ar_fifo_dout_prot;
	assign M_AXI_ARQOS = ar_fifo_dout_qos;

	// R Channel: Master to Slave
	// Write to FIFO in M_AXI_ACLK domain
	assign r_fifo_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	assign M_AXI_RREADY = !r_fifo_full;

	// Read from FIFO in S_AXI_ACLK domain
	assign r_fifo_rd_en = S_AXI_RREADY && !r_fifo_empty;
	assign S_AXI_RVALID = !r_fifo_empty;
	assign S_AXI_RID = r_fifo_dout_id;
	assign S_AXI_RDATA = r_fifo_dout_data;
	assign S_AXI_RRESP = r_fifo_dout_resp;
	assign S_AXI_RLAST = r_fifo_dout_last;

	// AW FIFO Instance
	aw_fifo_inst u_aw_fifo (
		.clk (M_AXI_ACLK),
		.rst_n (M_AXI_ARESETN),
		.wr_clk (S_AXI_ACLK),
		.wr_rst_n (S_AXI_ARESETN),
		.wr_en (aw_fifo_wr_en),
		.rd_en (aw_fifo_rd_en),
		.din_id (S_AXI_AWID),
		.din_addr (S_AXI_AWADDR),
		.din_len (S_AXI_AWLEN),
		.din_size (S_AXI_AWSIZE),
		.din_burst (S_AXI_AWBURST),
		.din_lock (S_AXI_AWLOCK),
		.din_cache (S_AXI_AWCACHE),
		.din_prot (S_AXI_AWPROT),
		.din_qos (S_AXI_AWQOS),
		.dout_id (aw_fifo_dout_id),
		.dout_addr (aw_fifo_dout_addr),
		.dout_len (aw_fifo_dout_len),
		.dout_size (aw_fifo_dout_size),
		.dout_burst (aw_fifo_dout_burst),
		.dout_lock (aw_fifo_dout_lock),
		.dout_cache (aw_fifo_dout_cache),
		.dout_prot (aw_fifo_dout_prot),
		.dout_qos (aw_fifo_dout_qos),
		.full (aw_fifo_full),
		.empty (aw_fifo_empty)
	);

	// W FIFO Instance
	w_fifo_inst u_w_fifo (
		.clk (M_AXI_ACLK),
		.rst_n (M_AXI_ARESETN),
		.wr_clk (S_AXI_ACLK),
		.wr_rst_n (S_AXI_ARESETN),
		.wr_en (w_fifo_wr_en),
		.rd_en (w_fifo_rd_en),
		.din_data (S_AXI_WDATA),
		.din_strb (S_AXI_WSTRB),
		.din_last (S_AXI_WLAST),
		.dout_data (w_fifo_dout_data),
		.dout_strb (w_fifo_dout_strb),
		.dout_last (w_fifo_dout_last),
		.full (w_fifo_full),
		.empty (w_fifo_empty)
	);

	// B FIFO Instance
	b_fifo_inst u_b_fifo (
		.clk (S_AXI_ACLK),
		.rst_n (S_AXI_ARESETN),
		.wr_clk (M_AXI_ACLK),
		.wr_rst_n (M_AXI_ARESETN),
		.wr_en (b_fifo_wr_en),
		.rd_en (b_fifo_rd_en),
		.din_id (M_AXI_BID),
		.din_resp (M_AXI_BRESP),
		.dout_id (b_fifo_dout_id),
		.dout_resp (b_fifo_dout_resp),
		.full (b_fifo_full),
		.empty (b_fifo_empty)
	);

	// AR FIFO Instance
	ar_fifo_inst u_ar_fifo (
		.clk (M_AXI_ACLK),
		.rst_n (M_AXI_ARESETN),
		.wr_clk (S_AXI_ACLK),
		.wr_rst_n (S_AXI_ARESETN),
		.wr_en (ar_fifo_wr_en),
		.rd_en (ar_fifo_rd_en),
		.din_id (S_AXI_ARID),
		.din_addr (S_AXI_ARADDR),
		.din_len (S_AXI_ARLEN),
		.din_size (S_AXI_ARSIZE),
		.din_burst (S_AXI_ARBURST),
		.din_lock (S_AXI_ARLOCK),
		.din_cache (S_AXI_ARCACHE),
		.din_prot (S_AXI_ARPROT),
		.din_qos (S_AXI_ARQOS),
		.dout_id (ar_fifo_dout_id),
		.dout_addr (ar_fifo_dout_addr),
		.dout_len (ar_fifo_dout_len),
		.dout_size (ar_fifo_dout_size),
		.dout_burst (ar_fifo_dout_burst),
		.dout_lock (ar_fifo_dout_lock),
		.dout_cache (ar_fifo_dout_cache),
		.dout_prot (ar_fifo_dout_prot),
		.dout_qos (ar_fifo_dout_qos),
		.full (ar_fifo_full),
		.empty (ar_fifo_empty)
	);

	// R FIFO Instance
	r_fifo_inst u_r_fifo (
		.clk (S_AXI_ACLK),
		.rst_n (S_AXI_ARESETN),
		.wr_clk (M_AXI_ACLK),
		.wr_rst_n (M_AXI_ARESETN),
		.wr_en (r_fifo_wr_en),
		.rd_en (r_fifo_rd_en),
		.din_id (M_AXI_RID),
		.din_data (M_AXI_RDATA),
		.din_resp (M_AXI_RRESP),
		.din_last (M_AXI_RLAST),
		.dout_id (r_fifo_dout_id),
		.dout_data (r_fifo_dout_data),
		.dout_resp (r_fifo_dout_resp),
		.dout_last (r_fifo_dout_last),
		.full (r_fifo_full),
		.empty (r_fifo_empty)
	);

endmodule

// AW FIFO Module
module aw_fifo_inst #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] din_id,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] din_addr,
	input wire [7 : 0] din_len,
	input wire [2 : 0] din_size,
	input wire [1 : 0] din_burst,
	input wire din_lock,
	input wire [3 : 0] din_cache,
	input wire [2 : 0] din_prot,
	input wire [3 : 0] din_qos,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] dout_id,
	output wire [C_S_AXI_ADDR_WIDTH-1 : 0] dout_addr,
	output wire [7 : 0] dout_len,
	output wire [2 : 0] dout_size,
	output wire [1 : 0] dout_burst,
	output wire dout_lock,
	output wire [3 : 0] dout_cache,
	output wire [2 : 0] dout_prot,
	output wire [3 : 0] dout_qos,
	output wire full,
	output wire empty
);
	localparam integer FIFO_DEPTH = 1 << LGFIFO;
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	wire [DATA_WIDTH-1 : 0] fifo_din;
	wire [DATA_WIDTH-1 : 0] fifo_dout;

	assign fifo_din = {din_id, din_addr, din_len, din_size, din_burst, din_lock, din_cache, din_prot, din_qos};
	assign dout_id = fifo_dout[DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH];
	assign dout_addr = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign dout_len = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign dout_size = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign dout_burst = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign dout_lock = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign dout_cache = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign dout_prot = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign dout_qos = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-4];

	xclk_fifo #(
		.DATA_WIDTH (DATA_WIDTH),
		.LGFIFO (LGFIFO)
	) u_fifo (
		.clk (clk),
		.rst_n (rst_n),
		.wr_clk (wr_clk),
		.wr_rst_n (wr_rst_n),
		.wr_en (wr_en),
		.rd_en (rd_en),
		.din (fifo_din),
		.dout (fifo_dout),
		.full (full),
		.empty (empty)
	);
endmodule

// W FIFO Module
module w_fifo_inst #(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] din_data,
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] din_strb,
	input wire din_last,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] dout_data,
	output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] dout_strb,
	output wire dout_last,
	output wire full,
	output wire empty
);
	localparam integer DATA_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;

	wire [DATA_WIDTH-1 : 0] fifo_din;
	wire [DATA_WIDTH-1 : 0] fifo_dout;

	assign fifo_din = {din_data, din_strb, din_last};
	assign dout_data = fifo_dout[DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_DATA_WIDTH];
	assign dout_strb = fifo_dout[DATA_WIDTH-C_S_AXI_DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)];
	assign dout_last = fifo_dout[DATA_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)-1];

	xclk_fifo #(
		.DATA_WIDTH (DATA_WIDTH),
		.LGFIFO (LGFIFO)
	) u_fifo (
		.clk (clk),
		.rst_n (rst_n),
		.wr_clk (wr_clk),
		.wr_rst_n (wr_rst_n),
		.wr_en (wr_en),
		.rd_en (rd_en),
		.din (fifo_din),
		.dout (fifo_dout),
		.full (full),
		.empty (empty)
	);
endmodule

// B FIFO Module
module b_fifo_inst #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] din_id,
	input wire [1 : 0] din_resp,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] dout_id,
	output wire [1 : 0] dout_resp,
	output wire full,
	output wire empty
);
	localparam integer DATA_WIDTH = C_S_AXI_ID_WIDTH + 2;

	wire [DATA_WIDTH-1 : 0] fifo_din;
	wire [DATA_WIDTH-1 : 0] fifo_dout;

	assign fifo_din = {din_id, din_resp};
	assign dout_id = fifo_dout[DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH];
	assign dout_resp = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-2];

	xclk_fifo #(
		.DATA_WIDTH (DATA_WIDTH),
		.LGFIFO (LGFIFO)
	) u_fifo (
		.clk (clk),
		.rst_n (rst_n),
		.wr_clk (wr_clk),
		.wr_rst_n (wr_rst_n),
		.wr_en (wr_en),
		.rd_en (rd_en),
		.din (fifo_din),
		.dout (fifo_dout),
		.full (full),
		.empty (empty)
	);
endmodule

// AR FIFO Module
module ar_fifo_inst #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] din_id,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] din_addr,
	input wire [7 : 0] din_len,
	input wire [2 : 0] din_size,
	input wire [1 : 0] din_burst,
	input wire din_lock,
	input wire [3 : 0] din_cache,
	input wire [2 : 0] din_prot,
	input wire [3 : 0] din_qos,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] dout_id,
	output wire [C_S_AXI_ADDR_WIDTH-1 : 0] dout_addr,
	output wire [7 : 0] dout_len,
	output wire [2 : 0] dout_size,
	output wire [1 : 0] dout_burst,
	output wire dout_lock,
	output wire [3 : 0] dout_cache,
	output wire [2 : 0] dout_prot,
	output wire [3 : 0] dout_qos,
	output wire full,
	output wire empty
);
	localparam integer DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	wire [DATA_WIDTH-1 : 0] fifo_din;
	wire [DATA_WIDTH-1 : 0] fifo_dout;

	assign fifo_din = {din_id, din_addr, din_len, din_size, din_burst, din_lock, din_cache, din_prot, din_qos};
	assign dout_id = fifo_dout[DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH];
	assign dout_addr = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign dout_len = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign dout_size = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign dout_burst = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign dout_lock = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign dout_cache = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign dout_prot = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign dout_qos = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-4];

	xclk_fifo #(
		.DATA_WIDTH (DATA_WIDTH),
		.LGFIFO (LGFIFO)
	) u_fifo (
		.clk (clk),
		.rst_n (rst_n),
		.wr_clk (wr_clk),
		.wr_rst_n (wr_rst_n),
		.wr_en (wr_en),
		.rd_en (rd_en),
		.din (fifo_din),
		.dout (fifo_dout),
		.full (full),
		.empty (empty)
	);
endmodule

// R FIFO Module
module r_fifo_inst #(
	parameter integer C_S_AXI_ID_WIDTH = 2,
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_S_AXI_ID_WIDTH-1 : 0] din_id,
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] din_data,
	input wire [1 : 0] din_resp,
	input wire din_last,
	output wire [C_S_AXI_ID_WIDTH-1 : 0] dout_id,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] dout_data,
	output wire [1 : 0] dout_resp,
	output wire dout_last,
	output wire full,
	output wire empty
);
	localparam integer DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	wire [DATA_WIDTH-1 : 0] fifo_din;
	wire [DATA_WIDTH-1 : 0] fifo_dout;

	assign fifo_din = {din_id, din_data, din_resp, din_last};
	assign dout_id = fifo_dout[DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH];
	assign dout_data = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH];
	assign dout_resp = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-1 : DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2];
	assign dout_last = fifo_dout[DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2-1];

	xclk_fifo #(
		.DATA_WIDTH (DATA_WIDTH),
		.LGFIFO (LGFIFO)
	) u_fifo (
		.clk (clk),
		.rst_n (rst_n),
		.wr_clk (wr_clk),
		.wr_rst_n (wr_rst_n),
		.wr_en (wr_en),
		.rd_en (rd_en),
		.din (fifo_din),
		.dout (fifo_dout),
		.full (full),
		.empty (empty)
	);
endmodule

// Cross-Clock FIFO Module
module xclk_fifo #(
	parameter integer DATA_WIDTH = 32,
	parameter integer LGFIFO = 5
) (
	input wire clk,
	input wire rst_n,
	input wire wr_clk,
	input wire wr_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [DATA_WIDTH-1 : 0] din,
	output wire [DATA_WIDTH-1 : 0] dout,
	output wire full,
	output wire empty
