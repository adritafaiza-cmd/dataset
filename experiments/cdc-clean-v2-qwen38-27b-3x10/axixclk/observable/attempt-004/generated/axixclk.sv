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
	localparam integer AW_FIFO_DEPTH = 1 << LGFIFO;
	localparam integer AW_FIFO_PTR_W = LGFIFO;
	localparam integer W_FIFO_DEPTH = 1 << LGFIFO;
	localparam integer W_FIFO_PTR_W = LGFIFO;
	localparam integer B_FIFO_DEPTH = 1 << LGFIFO;
	localparam integer B_FIFO_PTR_W = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 1 << LGFIFO;
	localparam integer AR_FIFO_PTR_W = LGFIFO;
	localparam integer R_FIFO_DEPTH = 1 << LGFIFO;
	localparam integer R_FIFO_PTR_W = LGFIFO;

	localparam integer AW_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_DATA_W = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_DATA_W = C_S_AXI_ID_WIDTH + 2;
	localparam integer AR_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer R_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Reset synchronization
	reg [1:0] m_reset_sync;
	reg m_reset_n;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
			m_reset_n <= 1'b0;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
			m_reset_n <= m_reset_sync[1];
		end
	end

	assign M_AXI_ARESETN = m_reset_n;

	// AW channel: S to M
	reg [AW_DATA_W-1:0] aw_fifo_mem [0:AW_FIFO_DEPTH-1];
	reg [AW_FIFO_PTR_W:0] aw_wr_ptr;
	reg [AW_FIFO_PTR_W:0] aw_rd_ptr;
	reg [AW_FIFO_PTR_W:0] aw_rd_ptr_s;
	reg [AW_FIFO_PTR_W:0] aw_wr_ptr_m;

	wire aw_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	wire aw_rd_en = M_AXI_AWVALID && M_AXI_AWREADY;

	assign S_AXI_AWREADY = (aw_wr_ptr - aw_rd_ptr_s) < AW_FIFO_DEPTH;

	// Write to FIFO in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= 0;
		end else if (aw_wr_en) begin
			aw_fifo_mem[aw_wr_ptr[AW_FIFO_PTR_W-1:0]] <= {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
			aw_wr_ptr <= aw_wr_ptr + 1;
		end
	end

	// Synchronize write pointer to M clock
	reg [AW_FIFO_PTR_W:0] aw_wr_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_wr_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				aw_wr_ptr_sync[i] <= 0;
		end else begin
			aw_wr_ptr_sync[0] <= aw_wr_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				aw_wr_ptr_sync[i] <= aw_wr_ptr_sync[i-1];
		end
	end
	assign aw_wr_ptr_m = aw_wr_ptr_sync[XCLOCK_FFS-1];

	// Read from FIFO in M clock
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_rd_ptr <= 0;
		end else if (aw_rd_en) begin
			aw_rd_ptr <= aw_rd_ptr + 1;
		end
	end

	// Synchronize read pointer to S clock
	reg [AW_FIFO_PTR_W:0] aw_rd_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_rd_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				aw_rd_ptr_sync[i] <= 0;
		end else begin
			aw_rd_ptr_sync[0] <= aw_rd_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				aw_rd_ptr_sync[i] <= aw_rd_ptr_sync[i-1];
		end
	end
	assign aw_rd_ptr_s = aw_rd_ptr_sync[XCLOCK_FFS-1];

	// AW output in M clock
	reg [AW_DATA_W-1:0] aw_out_reg;
	reg aw_valid_reg;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_out_reg <= 0;
			aw_valid_reg <= 1'b0;
		end else begin
			if (aw_rd_en) begin
				aw_valid_reg <= 1'b0;
			end else if (!aw_valid_reg && (aw_wr_ptr_m - aw_rd_ptr) > 0) begin
				aw_out_reg <= aw_fifo_mem[aw_rd_ptr[AW_FIFO_PTR_W-1:0]];
				aw_valid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_AWVALID = aw_valid_reg;
	assign M_AXI_AWID = aw_out_reg[AW_DATA_W-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 -: 8];
	assign M_AXI_AWSIZE = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 -: 3];
	assign M_AXI_AWBURST = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 -: 2];
	assign M_AXI_AWLOCK = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign M_AXI_AWCACHE = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 -: 4];
	assign M_AXI_AWPROT = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1-4-1 -: 3];
	assign M_AXI_AWQOS = aw_out_reg[AW_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1-4-3-1 -: 4];

	// W channel: S to M
	reg [W_DATA_W-1:0] w_fifo_mem [0:W_FIFO_DEPTH-1];
	reg [W_FIFO_PTR_W:0] w_wr_ptr;
	reg [W_FIFO_PTR_W:0] w_rd_ptr;
	reg [W_FIFO_PTR_W:0] w_rd_ptr_s;
	reg [W_FIFO_PTR_W:0] w_wr_ptr_m;

	wire w_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	wire w_rd_en = M_AXI_WVALID && M_AXI_WREADY;

	assign S_AXI_WREADY = (w_wr_ptr - w_rd_ptr_s) < W_FIFO_DEPTH;

	// Write to FIFO in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= 0;
		end else if (w_wr_en) begin
			w_fifo_mem[w_wr_ptr[W_FIFO_PTR_W-1:0]] <= {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
			w_wr_ptr <= w_wr_ptr + 1;
		end
	end

	// Synchronize write pointer to M clock
	reg [W_FIFO_PTR_W:0] w_wr_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_wr_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				w_wr_ptr_sync[i] <= 0;
		end else begin
			w_wr_ptr_sync[0] <= w_wr_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				w_wr_ptr_sync[i] <= w_wr_ptr_sync[i-1];
		end
	end
	assign w_wr_ptr_m = w_wr_ptr_sync[XCLOCK_FFS-1];

	// Read from FIFO in M clock
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_rd_ptr <= 0;
		end else if (w_rd_en) begin
			w_rd_ptr <= w_rd_ptr + 1;
		end
	end

	// Synchronize read pointer to S clock
	reg [W_FIFO_PTR_W:0] w_rd_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_rd_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				w_rd_ptr_sync[i] <= 0;
		end else begin
			w_rd_ptr_sync[0] <= w_rd_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				w_rd_ptr_sync[i] <= w_rd_ptr_sync[i-1];
		end
	end
	assign w_rd_ptr_s = w_rd_ptr_sync[XCLOCK_FFS-1];

	// W output in M clock with extra register
	reg [W_DATA_W-1:0] w_out_reg;
	reg w_valid_reg;
	reg w_valid_next;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_out_reg <= 0;
			w_valid_reg <= 1'b0;
		end else begin
			if (w_rd_en) begin
				w_valid_reg <= 1'b0;
			end else if (!w_valid_reg && (w_wr_ptr_m - w_rd_ptr) > 0) begin
				w_out_reg <= w_fifo_mem[w_rd_ptr[W_FIFO_PTR_W-1:0]];
				w_valid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_WVALID = w_valid_reg;
	assign M_AXI_WDATA = w_out_reg[W_DATA_W-1 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB = w_out_reg[C_S_AXI_DATA_WIDTH-1 -: (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST = w_out_reg[0];

	// B channel: M to S
	reg [B_DATA_W-1:0] b_fifo_mem [0:B_FIFO_DEPTH-1];
	reg [B_FIFO_PTR_W:0] b_wr_ptr;
	reg [B_FIFO_PTR_W:0] b_rd_ptr;
	reg [B_FIFO_PTR_W:0] b_rd_ptr_m;
	reg [B_FIFO_PTR_W:0] b_wr_ptr_s;

	wire b_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	wire b_rd_en = S_AXI_BVALID && S_AXI_BREADY;

	assign M_AXI_BREADY = (b_wr_ptr - b_rd_ptr_m) < B_FIFO_DEPTH;

	// Write to FIFO in M clock
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_wr_ptr <= 0;
		end else if (b_wr_en) begin
			b_fifo_mem[b_wr_ptr[B_FIFO_PTR_W-1:0]] <= {M_AXI_BID, M_AXI_BRESP};
			b_wr_ptr <= b_wr_ptr + 1;
		end
	end

	// Synchronize write pointer to S clock
	reg [B_FIFO_PTR_W:0] b_wr_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_wr_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				b_wr_ptr_sync[i] <= 0;
		end else begin
			b_wr_ptr_sync[0] <= b_wr_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				b_wr_ptr_sync[i] <= b_wr_ptr_sync[i-1];
		end
	end
	assign b_wr_ptr_s = b_wr_ptr_sync[XCLOCK_FFS-1];

	// Read from FIFO in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= 0;
		end else if (b_rd_en) begin
			b_rd_ptr <= b_rd_ptr + 1;
		end
	end

	// Synchronize read pointer to M clock
	reg [B_FIFO_PTR_W:0] b_rd_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_rd_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				b_rd_ptr_sync[i] <= 0;
		end else begin
			b_rd_ptr_sync[0] <= b_rd_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				b_rd_ptr_sync[i] <= b_rd_ptr_sync[i-1];
		end
	end
	assign b_rd_ptr_m = b_rd_ptr_sync[XCLOCK_FFS-1];

	// B output in S clock
	reg [B_DATA_W-1:0] b_out_reg;
	reg b_valid_reg;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_out_reg <= 0;
			b_valid_reg <= 1'b0;
		end else begin
			if (b_rd_en) begin
				b_valid_reg <= 1'b0;
			end else if (!b_valid_reg && (b_wr_ptr_s - b_rd_ptr) > 0) begin
				b_out_reg <= b_fifo_mem[b_rd_ptr[B_FIFO_PTR_W-1:0]];
				b_valid_reg <= 1'b1;
			end
		end
	end

	assign S_AXI_BVALID = b_valid_reg;
	assign S_AXI_BID = b_out_reg[B_DATA_W-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP = b_out_reg[C_S_AXI_ID_WIDTH-1 -: 2];

	// AR channel: S to M
	reg [AR_DATA_W-1:0] ar_fifo_mem [0:AR_FIFO_DEPTH-1];
	reg [AR_FIFO_PTR_W:0] ar_wr_ptr;
	reg [AR_FIFO_PTR_W:0] ar_rd_ptr;
	reg [AR_FIFO_PTR_W:0] ar_rd_ptr_s;
	reg [AR_FIFO_PTR_W:0] ar_wr_ptr_m;

	wire ar_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	wire ar_rd_en = M_AXI_ARVALID && M_AXI_ARREADY;

	assign S_AXI_ARREADY = (ar_wr_ptr - ar_rd_ptr_s) < AR_FIFO_DEPTH;

	// Write to FIFO in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= 0;
		end else if (ar_wr_en) begin
			ar_fifo_mem[ar_wr_ptr[AR_FIFO_PTR_W-1:0]] <= {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
			ar_wr_ptr <= ar_wr_ptr + 1;
		end
	end

	// Synchronize write pointer to M clock
	reg [AR_FIFO_PTR_W:0] ar_wr_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_wr_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				ar_wr_ptr_sync[i] <= 0;
		end else begin
			ar_wr_ptr_sync[0] <= ar_wr_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				ar_wr_ptr_sync[i] <= ar_wr_ptr_sync[i-1];
		end
	end
	assign ar_wr_ptr_m = ar_wr_ptr_sync[XCLOCK_FFS-1];

	// Read from FIFO in M clock
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_rd_ptr <= 0;
		end else if (ar_rd_en) begin
			ar_rd_ptr <= ar_rd_ptr + 1;
		end
	end

	// Synchronize read pointer to S clock
	reg [AR_FIFO_PTR_W:0] ar_rd_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_rd_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				ar_rd_ptr_sync[i] <= 0;
		end else begin
			ar_rd_ptr_sync[0] <= ar_rd_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				ar_rd_ptr_sync[i] <= ar_rd_ptr_sync[i-1];
		end
	end
	assign ar_rd_ptr_s = ar_rd_ptr_sync[XCLOCK_FFS-1];

	// AR output in M clock
	reg [AR_DATA_W-1:0] ar_out_reg;
	reg ar_valid_reg;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_out_reg <= 0;
			ar_valid_reg <= 1'b0;
		end else begin
			if (ar_rd_en) begin
				ar_valid_reg <= 1'b0;
			end else if (!ar_valid_reg && (ar_wr_ptr_m - ar_rd_ptr) > 0) begin
				ar_out_reg <= ar_fifo_mem[ar_rd_ptr[AR_FIFO_PTR_W-1:0]];
				ar_valid_reg <= 1'b1;
			end
		end
	end

	assign M_AXI_ARVALID = ar_valid_reg;
	assign M_AXI_ARID = ar_out_reg[AR_DATA_W-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-1 -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 -: 8];
	assign M_AXI_ARSIZE = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-1 -: 3];
	assign M_AXI_ARBURST = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-1 -: 2];
	assign M_AXI_ARLOCK = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1];
	assign M_AXI_ARCACHE = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1 -: 4];
	assign M_AXI_ARPROT = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1-4-1 -: 3];
	assign M_AXI_ARQOS = ar_out_reg[AR_DATA_W-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-1-4-3-1 -: 4];

	// R channel: M to S
	reg [R_DATA_W-1:0] r_fifo_mem [0:R_FIFO_DEPTH-1];
	reg [R_FIFO_PTR_W:0] r_wr_ptr;
	reg [R_FIFO_PTR_W:0] r_rd_ptr;
	reg [R_FIFO_PTR_W:0] r_rd_ptr_m;
	reg [R_FIFO_PTR_W:0] r_wr_ptr_s;

	wire r_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	wire r_rd_en = S_AXI_RVALID && S_AXI_RREADY;

	assign M_AXI_RREADY = (r_wr_ptr - r_rd_ptr_m) < R_FIFO_DEPTH;

	// Write to FIFO in M clock
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			r_wr_ptr <= 0;
		end else if (r_wr_en) begin
			r_fifo_mem[r_wr_ptr[R_FIFO_PTR_W-1:0]] <= {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};
			r_wr_ptr <= r_wr_ptr + 1;
		end
	end

	// Synchronize write pointer to S clock
	reg [R_FIFO_PTR_W:0] r_wr_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_wr_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				r_wr_ptr_sync[i] <= 0;
		end else begin
			r_wr_ptr_sync[0] <= r_wr_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				r_wr_ptr_sync[i] <= r_wr_ptr_sync[i-1];
		end
	end
	assign r_wr_ptr_s = r_wr_ptr_sync[XCLOCK_FFS-1];

	// Read from FIFO in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= 0;
		end else if (r_rd_en) begin
			r_rd_ptr <= r_rd_ptr + 1;
		end
	end

	// Synchronize read pointer to M clock
	reg [R_FIFO_PTR_W:0] r_rd_ptr_sync [0:XCLOCK_FFS-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			r_rd_ptr_sync[0] <= 0;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				r_rd_ptr_sync[i] <= 0;
		end else begin
			r_rd_ptr_sync[0] <= r_rd_ptr;
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1)
				r_rd_ptr_sync[i] <= r_rd_ptr_sync[i-1];
		end
	end
	assign r_rd_ptr_m = r_rd_ptr_sync[XCLOCK_FFS-1];

	// R output in S clock
	reg [R_DATA_W-1:0] r_out_reg;
	reg r_valid_reg;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_out_reg <= 0;
			r_valid_reg <= 1'b0;
		end else begin
			if (r_rd_en) begin
				r_valid_reg <= 1'b0;
			end else if (!r_valid_reg && (r_wr_ptr_s - r_rd_ptr) > 0) begin
				r_out_reg <= r_fifo_mem[r_rd_ptr[R_FIFO_PTR_W-1:0]];
				r_valid_reg <= 1'b1;
			end
		end
	end

	assign S_AXI_RVALID = r_valid_reg;
	assign S_AXI_RID = r_out_reg[R_DATA_W-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_RDATA = r_out_reg[R_DATA_W-C_S_AXI_ID_WIDTH-1 -: C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP = r_out_reg[C_S_AXI_DATA_WIDTH-1 -: 2];
	assign S_AXI_RLAST = r_out_reg[0];

endmodule
