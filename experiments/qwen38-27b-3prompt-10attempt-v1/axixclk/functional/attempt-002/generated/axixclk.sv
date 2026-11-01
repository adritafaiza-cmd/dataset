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
	localparam integer AW_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Internal signals
	wire [AW_FIFO_WIDTH-1:0] aw_fifo_data;
	wire aw_fifo_full;
	wire aw_fifo_empty;
	wire aw_fifo_wr_en;
	wire aw_fifo_rd_en;
	wire [FIFO_ADDR_WIDTH-1:0] aw_fifo_wr_ptr;
	wire [FIFO_ADDR_WIDTH-1:0] aw_fifo_rd_ptr;

	wire [AR_FIFO_WIDTH-1:0] ar_fifo_data;
	wire ar_fifo_full;
	wire ar_fifo_empty;
	wire ar_fifo_wr_en;
	wire ar_fifo_rd_en;
	wire [FIFO_ADDR_WIDTH-1:0] ar_fifo_wr_ptr;
	wire [FIFO_ADDR_WIDTH-1:0] ar_fifo_rd_ptr;

	wire [W_FIFO_WIDTH-1:0] w_fifo_data;
	wire w_fifo_full;
	wire w_fifo_empty;
	wire w_fifo_wr_en;
	wire w_fifo_rd_en;
	wire [FIFO_ADDR_WIDTH-1:0] w_fifo_wr_ptr;
	wire [FIFO_ADDR_WIDTH-1:0] w_fifo_rd_ptr;

	wire [B_FIFO_WIDTH-1:0] b_fifo_data;
	wire b_fifo_full;
	wire b_fifo_empty;
	wire b_fifo_wr_en;
	wire b_fifo_rd_en;
	wire [FIFO_ADDR_WIDTH-1:0] b_fifo_wr_ptr;
	wire [FIFO_ADDR_WIDTH-1:0] b_fifo_rd_ptr;

	wire [R_FIFO_WIDTH-1:0] r_fifo_data;
	wire r_fifo_full;
	wire r_fifo_empty;
	wire r_fifo_wr_en;
	wire r_fifo_rd_en;
	wire [FIFO_ADDR_WIDTH-1:0] r_fifo_wr_ptr;
	wire [FIFO_ADDR_WIDTH-1:0] r_fifo_rd_ptr;

	// AW channel: S to M
	assign aw_fifo_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	assign S_AXI_AWREADY = !aw_fifo_full;

	// AW FIFO write data
	assign aw_fifo_data = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};

	// AW FIFO read data
	wire [C_S_AXI_ID_WIDTH-1:0] aw_id;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr;
	wire [7:0] aw_len;
	wire [2:0] aw_size;
	wire [1:0] aw_burst;
	wire aw_lock;
	wire [3:0] aw_cache;
	wire [2:0] aw_prot;
	wire [3:0] aw_qos;

	assign aw_id = aw_fifo_data[AW_FIFO_WIDTH-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH];
	assign aw_addr = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign aw_len = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign aw_size = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign aw_burst = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign aw_lock = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign aw_cache = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign aw_prot = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign aw_qos = aw_fifo_data[AW_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : 0];

	// AW channel: M side
	assign M_AXI_AWID = aw_id;
	assign M_AXI_AWADDR = aw_addr;
	assign M_AXI_AWLEN = aw_len;
	assign M_AXI_AWSIZE = aw_size;
	assign M_AXI_AWBURST = aw_burst;
	assign M_AXI_AWLOCK = aw_lock;
	assign M_AXI_AWCACHE = aw_cache;
	assign M_AXI_AWPROT = aw_prot;
	assign M_AXI_AWQOS = aw_qos;
	assign M_AXI_AWVALID = !aw_fifo_empty;
	assign aw_fifo_rd_en = M_AXI_AWVALID && M_AXI_AWREADY;

	// AR channel: S to M
	assign ar_fifo_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	assign S_AXI_ARREADY = !ar_fifo_full;

	// AR FIFO write data
	assign ar_fifo_data = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};

	// AR FIFO read data
	wire [C_S_AXI_ID_WIDTH-1:0] ar_id;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr;
	wire [7:0] ar_len;
	wire [2:0] ar_size;
	wire [1:0] ar_burst;
	wire ar_lock;
	wire [3:0] ar_cache;
	wire [2:0] ar_prot;
	wire [3:0] ar_qos;

	assign ar_id = ar_fifo_data[AR_FIFO_WIDTH-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH];
	assign ar_addr = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
	assign ar_len = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
	assign ar_size = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3];
	assign ar_burst = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2];
	assign ar_lock = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign ar_cache = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4];
	assign ar_prot = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-1 : AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3];
	assign ar_qos = ar_fifo_data[AR_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3-1 : 0];

	// AR channel: M side
	assign M_AXI_ARID = ar_id;
	assign M_AXI_ARADDR = ar_addr;
	assign M_AXI_ARLEN = ar_len;
	assign M_AXI_ARSIZE = ar_size;
	assign M_AXI_ARBURST = ar_burst;
	assign M_AXI_ARLOCK = ar_lock;
	assign M_AXI_ARCACHE = ar_cache;
	assign M_AXI_ARPROT = ar_prot;
	assign M_AXI_ARQOS = ar_qos;
	assign M_AXI_ARVALID = !ar_fifo_empty;
	assign ar_fifo_rd_en = M_AXI_ARVALID && M_AXI_ARREADY;

	// W channel: S to M
	assign w_fifo_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	assign S_AXI_WREADY = !w_fifo_full;

	// W FIFO write data
	assign w_fifo_data = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};

	// W FIFO read data
	wire [C_S_AXI_DATA_WIDTH-1:0] w_data;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb;
	wire w_last;

	assign w_data = w_fifo_data[W_FIFO_WIDTH-1 : W_FIFO_WIDTH-C_S_AXI_DATA_WIDTH];
	assign w_strb = w_fifo_data[W_FIFO_WIDTH-C_S_AXI_DATA_WIDTH-1 : W_FIFO_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)];
	assign w_last = w_fifo_data[W_FIFO_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)-1];

	// W channel: M side
	// Master write data is held one extra M_AXI clock before M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1:0] m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_wvalid_reg;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_reg <= 1'b0;
			m_wvalid_reg <= 1'b0;
		end else begin
			if (!w_fifo_empty) begin
				m_wdata_reg <= w_data;
				m_wstrb_reg <= w_strb;
				m_wlast_reg <= w_last;
				m_wvalid_reg <= 1'b1;
			end else if (m_wvalid_reg && M_AXI_WREADY) begin
				m_wvalid_reg <= 1'b0;
			end
		end
	end

	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;
	assign w_fifo_rd_en = m_wvalid_reg && M_AXI_WREADY;

	// B channel: M to S
	assign b_fifo_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	assign M_AXI_BREADY = !b_fifo_full;

	// B FIFO write data
	assign b_fifo_data = {M_AXI_BID, M_AXI_BRESP};

	// B FIFO read data
	wire [C_S_AXI_ID_WIDTH-1:0] b_id;
	wire [1:0] b_resp;

	assign b_id = b_fifo_data[B_FIFO_WIDTH-1 : B_FIFO_WIDTH-C_S_AXI_ID_WIDTH];
	assign b_resp = b_fifo_data[B_FIFO_WIDTH-C_S_AXI_ID_WIDTH-1 : B_FIFO_WIDTH-C_S_AXI_ID_WIDTH-2];

	// B channel: S side
	assign S_AXI_BID = b_id;
	assign S_AXI_BRESP = b_resp;
	assign S_AXI_BVALID = !b_fifo_empty;
	assign b_fifo_rd_en = S_AXI_BVALID && S_AXI_BREADY;

	// R channel: M to S
	assign r_fifo_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	assign M_AXI_RREADY = !r_fifo_full;

	// R FIFO write data
	assign r_fifo_data = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};

	// R FIFO read data
	wire [C_S_AXI_ID_WIDTH-1:0] r_id;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data;
	wire [1:0] r_resp;
	wire r_last;

	assign r_id = r_fifo_data[R_FIFO_WIDTH-1 : R_FIFO_WIDTH-C_S_AXI_ID_WIDTH];
	assign r_data = r_fifo_data[R_FIFO_WIDTH-C_S_AXI_ID_WIDTH-1 : R_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH];
	assign r_resp = r_fifo_data[R_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-1 : R_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2];
	assign r_last = r_fifo_data[R_FIFO_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2-1];

	// R channel: S side
	assign S_AXI_RID = r_id;
	assign S_AXI_RDATA = r_data;
	assign S_AXI_RRESP = r_resp;
	assign S_AXI_RLAST = r_last;
	assign S_AXI_RVALID = !r_fifo_empty;
	assign r_fifo_rd_en = S_AXI_RVALID && S_AXI_RREADY;

	// Reset synchronization for M_AXI_ARESETN
	reg [XCLOCK_FFS-1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= {XCLOCK_FFS{1'b0}};
		end else begin
			m_reset_sync <= {m_reset_sync[XCLOCK_FFS-2:0], 1'b1};
		end
	end
	assign M_AXI_ARESETN = m_reset_sync[XCLOCK_FFS-1];

	// AW FIFO
	aw_sync_fifo #(
		.DATAPATH_WIDTH(AW_FIFO_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(FIFO_ADDR_WIDTH)
	) u_aw_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.wr_en(aw_fifo_wr_en),
		.rd_en(aw_fifo_rd_en),
		.wr_data(aw_fifo_data),
		.rd_data(aw_fifo_data),
		.full(aw_fifo_full),
		.empty(aw_fifo_empty),
		.wr_ptr(aw_fifo_wr_ptr),
		.rd_ptr(aw_fifo_rd_ptr)
	);

	// AR FIFO
	aw_sync_fifo #(
		.DATAPATH_WIDTH(AR_FIFO_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(FIFO_ADDR_WIDTH)
	) u_ar_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.wr_en(ar_fifo_wr_en),
		.rd_en(ar_fifo_rd_en),
		.wr_data(ar_fifo_data),
		.rd_data(ar_fifo_data),
		.full(ar_fifo_full),
		.empty(ar_fifo_empty),
		.wr_ptr(ar_fifo_wr_ptr),
		.rd_ptr(ar_fifo_rd_ptr)
	);

	// W FIFO
	aw_sync_fifo #(
		.DATAPATH_WIDTH(W_FIFO_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(FIFO_ADDR_WIDTH)
	) u_w_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst_n(S_AXI_ARESETN),
		.rd_clk(M_AXI_ACLK),
		.rd_rst_n(M_AXI_ARESETN),
		.wr_en(w_fifo_wr_en),
		.rd_en(w_fifo_rd_en),
		.wr_data(w_fifo_data),
		.rd_data(w_fifo_data),
		.full(w_fifo_full),
		.empty(w_fifo_empty),
		.wr_ptr(w_fifo_wr_ptr),
		.rd_ptr(w_fifo_rd_ptr)
	);

	// B FIFO
	aw_sync_fifo #(
		.DATAPATH_WIDTH(B_FIFO_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(FIFO_ADDR_WIDTH)
	) u_b_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst_n(M_AXI_ARESETN),
		.rd_clk(S_AXI_ACLK),
		.rd_rst_n(S_AXI_ARESETN),
		.wr_en(b_fifo_wr_en),
		.rd_en(b_fifo_rd_en),
		.wr_data(b_fifo_data),
		.rd_data(b_fifo_data),
		.full(b_fifo_full),
		.empty(b_fifo_empty),
		.wr_ptr(b_fifo_wr_ptr),
		.rd_ptr(b_fifo_rd_ptr)
	);

	// R FIFO
	aw_sync_fifo #(
		.DATAPATH_WIDTH(R_FIFO_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(FIFO_ADDR_WIDTH)
	) u_r_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst_n(M_AXI_ARESETN),
		.rd_clk(S_AXI_ACLK),
		.rd_rst_n(S_AXI_ARESETN),
		.wr_en(r_fifo_wr_en),
		.rd_en(r_fifo_rd_en),
		.wr_data(r_fifo_data),
		.rd_data(r_fifo_data),
		.full(r_fifo_full),
		.empty(r_fifo_empty),
		.wr_ptr(r_fifo_wr_ptr),
		.rd_ptr(r_fifo_rd_ptr)
	);

endmodule

// Asynchronous FIFO module
module aw_sync_fifo #(
	parameter DATAPATH_WIDTH = 32,
	parameter FIFO_DEPTH = 32,
	parameter ADDR_WIDTH = 5
) (
	input wire wr_clk,
	input wire wr_rst_n,
	input wire rd_clk,
	input wire rd_rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [DATAPATH_WIDTH-1:0] wr_data,
	output wire [DATAPATH_WIDTH-1:0] rd_data,
	output wire full,
	output wire empty,
	output wire [ADDR_WIDTH-1:0] wr_ptr,
	output wire [ADDR_WIDTH-1:0] rd_ptr
);

	// Memory
	reg [DATAPATH_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

	// Write pointer
	reg [ADDR_WIDTH:0] wr_ptr_reg;
	always @(posedge wr_clk or negedge wr_rst_n) begin
		if (!wr_rst_n) begin
			wr_ptr_reg <= 0;
		end else if (wr_en && !full) begin
			wr_ptr_reg <= wr_ptr_reg + 1;
		end
	end

	// Read pointer
	reg [ADDR_WIDTH:0] rd_ptr_reg;
	always @(posedge rd_clk or negedge rd_rst_n) begin
		if (!rd_rst_n) begin
			rd_ptr_reg <= 0;
		end else if (rd_en && !empty) begin
			rd_ptr_reg <= rd_ptr_reg + 1;
		end
	end

	// Write to memory
	always @(posedge wr_clk) begin
		if (wr_en && !full) begin
			mem[wr_ptr_reg[ADDR_WIDTH-1:0]] <= wr_data;
		end
	end

	// Read from memory
	always @(posedge rd_clk) begin
		if (rd_en && !empty) begin
			rd_data <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]];
		end
	end

	// Gray code conversion
	function [ADDR_WIDTH:0] bin2gray;
		input [ADDR_WIDTH:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	wire [ADDR_WIDTH:0] wr_ptr_gray = bin2gray(wr_ptr_reg);
	wire [ADDR_WIDTH:0] rd_ptr_gray = bin2gray(rd_ptr_reg);

	// Synchronize write pointer to read clock domain
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;
	always @(posedge rd_clk or negedge rd_rst_n) begin
		if (!rd_rst_n) begin
			wr_ptr_gray_sync1 <= 0;
			wr_ptr_gray_sync2 <= 0;
		end else begin
			wr_ptr_gray_sync1 <= wr_ptr_gray;
			wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
		end
	end

	// Synchronize read pointer to write clock domain
	reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
	reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;
	always @(posedge wr_clk or negedge wr_rst_n) begin
		if (!wr_rst_n) begin
			rd_ptr_gray_sync1 <= 0;
			rd_ptr_gray_sync2 <= 0;
		end else begin
			rd_ptr_gray_sync1 <= rd_ptr_gray;
			rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
		end
	end

	// Full and empty detection
	assign full = (wr_ptr_gray_sync2[ADDR_WIDTH] != rd_ptr_gray[ADDR_WIDTH]) && 
	               (wr_ptr_gray_sync2[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);
	assign empty = (rd_ptr_gray_sync2 == rd_ptr_gray);

	// Output pointers
	assign wr_ptr = wr_ptr_reg[ADDR_WIDTH-1:0];
	assign rd_ptr = rd_ptr_reg[ADDR_WIDTH-1:0];

endmodule
