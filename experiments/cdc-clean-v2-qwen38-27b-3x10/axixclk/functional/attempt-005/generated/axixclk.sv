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

	// Reset synchronization for M_AXI_ACLK domain
	reg [FFS_STAGES-1:0] m_reset_sync;
	wire m_reset_n;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
	end

	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// ============================================================
	// AW Channel: S -> M
	// ============================================================
	// S-side: capture AW when valid and ready
	// M-side: FIFO-based transfer

	// AW FIFO: store AW transaction
	// AW data width: ID + ADDR + LEN + SIZE + BURST + LOCK + CACHE + PROT + QOS
	localparam integer AW_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	reg [AW_DATA_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr, aw_rd_ptr;
	wire aw_fifo_full, aw_fifo_empty;

	assign aw_fifo_full  = (aw_wr_ptr[FIFO_ADDR_WIDTH] != aw_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                       (aw_wr_ptr[FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign aw_fifo_empty = (aw_wr_ptr == aw_rd_ptr);

	// S-side AW write
	wire aw_s_valid = S_AXI_AWVALID;
	wire aw_s_ready = !aw_fifo_full;
	assign S_AXI_AWREADY = aw_s_ready;

	wire aw_s_fire = aw_s_valid && aw_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			aw_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (aw_s_fire)
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
	end

	always @(posedge S_AXI_ACLK) begin
		if (aw_s_fire) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_AWID,
				S_AXI_AWADDR,
				S_AXI_AWLEN,
				S_AXI_AWSIZE,
				S_AXI_AWBURST,
				S_AXI_AWLOCK,
				S_AXI_AWCACHE,
				S_AXI_AWPROT,
				S_AXI_AWQOS
			};
		end
	end

	// M-side AW read
	wire aw_m_ready = M_AXI_AWREADY;
	wire aw_m_fire = !aw_fifo_empty && aw_m_ready;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			aw_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (aw_m_fire)
			aw_rd_ptr <= aw_rd_ptr + 1'b1;
	end

	// AW output from FIFO
	reg [AW_DATA_WIDTH-1:0] aw_out;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			aw_out <= {AW_DATA_WIDTH{1'b0}};
		else
			aw_out <= aw_fifo_mem[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
	end

	assign M_AXI_AWVALID = !aw_fifo_empty;
	assign M_AXI_AWID    = aw_out[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_AWADDR  = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_AWLEN   = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWSIZE  = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+8];
	assign M_AXI_AWBURST = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_AWLOCK  = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+13];
	assign M_AXI_AWCACHE = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+14];
	assign M_AXI_AWPROT  = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+20:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+18];
	assign M_AXI_AWQOS   = aw_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+24:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+21];

	// ============================================================
	// W Channel: S -> M
	// ============================================================
	// W data width: DATA + STRB + LAST
	localparam integer W_DATA_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;

	reg [W_DATA_WIDTH-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] w_wr_ptr, w_rd_ptr;
	wire w_fifo_full, w_fifo_empty;

	assign w_fifo_full  = (w_wr_ptr[FIFO_ADDR_WIDTH] != w_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                      (w_wr_ptr[FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign w_fifo_empty = (w_wr_ptr == w_rd_ptr);

	// S-side W write
	wire w_s_valid = S_AXI_WVALID;
	wire w_s_ready = !w_fifo_full;
	assign S_AXI_WREADY = w_s_ready;

	wire w_s_fire = w_s_valid && w_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			w_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (w_s_fire)
			w_wr_ptr <= w_wr_ptr + 1'b1;
	end

	always @(posedge S_AXI_ACLK) begin
		if (w_s_fire) begin
			w_fifo_mem[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_WDATA,
				S_AXI_WSTRB,
				S_AXI_WLAST
			};
		end
	end

	// M-side W read
	wire w_m_ready = M_AXI_WREADY;
	wire w_m_fire = !w_fifo_empty && w_m_ready;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			w_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (w_m_fire)
			w_rd_ptr <= w_rd_ptr + 1'b1;
	end

	// W output from FIFO - hold one extra M_AXI clock before M_AXI_WVALID
	reg [W_DATA_WIDTH-1:0] w_out;
	reg w_valid_reg;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_out <= {W_DATA_WIDTH{1'b0}};
			w_valid_reg <= 1'b0;
		end else begin
			if (!w_fifo_empty) begin
				w_out <= w_fifo_mem[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				w_valid_reg <= 1'b1;
			end else if (w_m_fire) begin
				w_valid_reg <= 1'b0;
			end
		end
	end

	assign M_AXI_WVALID = w_valid_reg;
	assign M_AXI_WDATA  = w_out[C_S_AXI_DATA_WIDTH-1:0];
	assign M_AXI_WSTRB  = w_out[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8)-1:C_S_AXI_DATA_WIDTH];
	assign M_AXI_WLAST  = w_out[W_DATA_WIDTH-1];

	// ============================================================
	// B Channel: M -> S
	// ============================================================
	// B data width: BID + BRESP
	localparam integer B_DATA_WIDTH = C_S_AXI_ID_WIDTH + 2;

	reg [B_DATA_WIDTH-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] b_wr_ptr, b_rd_ptr;
	wire b_fifo_full, b_fifo_empty;

	assign b_fifo_full  = (b_wr_ptr[FIFO_ADDR_WIDTH] != b_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                      (b_wr_ptr[FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign b_fifo_empty = (b_wr_ptr == b_rd_ptr);

	// M-side B write
	wire b_m_valid = M_AXI_BVALID;
	wire b_m_ready = !b_fifo_full;
	assign M_AXI_BREADY = b_m_ready;

	wire b_m_fire = b_m_valid && b_m_ready;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			b_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (b_m_fire)
			b_wr_ptr <= b_wr_ptr + 1'b1;
	end

	always @(posedge M_AXI_ACLK) begin
		if (b_m_fire) begin
			b_fifo_mem[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_BID,
				M_AXI_BRESP
			};
		end
	end

	// S-side B read
	wire b_s_ready = S_AXI_BREADY;
	wire b_s_fire = !b_fifo_empty && b_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			b_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (b_s_fire)
			b_rd_ptr <= b_rd_ptr + 1'b1;
	end

	// B output from FIFO
	reg [B_DATA_WIDTH-1:0] b_out;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			b_out <= {B_DATA_WIDTH{1'b0}};
		else
			b_out <= b_fifo_mem[b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
	end

	assign S_AXI_BVALID = !b_fifo_empty;
	assign S_AXI_BID    = b_out[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_BRESP  = b_out[B_DATA_WIDTH-1:B_DATA_WIDTH-2];

	// ============================================================
	// AR Channel: S -> M
	// ============================================================
	// AR data width: ID + ADDR + LEN + SIZE + BURST + LOCK + CACHE + PROT + QOS
	localparam integer AR_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;

	reg [AR_DATA_WIDTH-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] ar_wr_ptr, ar_rd_ptr;
	wire ar_fifo_full, ar_fifo_empty;

	assign ar_fifo_full  = (ar_wr_ptr[FIFO_ADDR_WIDTH] != ar_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                       (ar_wr_ptr[FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign ar_fifo_empty = (ar_wr_ptr == ar_rd_ptr);

	// S-side AR write
	wire ar_s_valid = S_AXI_ARVALID;
	wire ar_s_ready = !ar_fifo_full;
	assign S_AXI_ARREADY = ar_s_ready;

	wire ar_s_fire = ar_s_valid && ar_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			ar_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (ar_s_fire)
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
	end

	always @(posedge S_AXI_ACLK) begin
		if (ar_s_fire) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_ARID,
				S_AXI_ARADDR,
				S_AXI_ARLEN,
				S_AXI_ARSIZE,
				S_AXI_ARBURST,
				S_AXI_ARLOCK,
				S_AXI_ARCACHE,
				S_AXI_ARPROT,
				S_AXI_ARQOS
			};
		end
	end

	// M-side AR read
	wire ar_m_ready = M_AXI_ARREADY;
	wire ar_m_fire = !ar_fifo_empty && ar_m_ready;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			ar_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (ar_m_fire)
			ar_rd_ptr <= ar_rd_ptr + 1'b1;
	end

	// AR output from FIFO
	reg [AR_DATA_WIDTH-1:0] ar_out;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			ar_out <= {AR_DATA_WIDTH{1'b0}};
		else
			ar_out <= ar_fifo_mem[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
	end

	assign M_AXI_ARVALID = !ar_fifo_empty;
	assign M_AXI_ARID    = ar_out[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_ARADDR  = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_ARLEN   = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARSIZE  = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+8];
	assign M_AXI_ARBURST = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_ARLOCK  = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+13];
	assign M_AXI_ARCACHE = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+14];
	assign M_AXI_ARPROT  = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+20:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+18];
	assign M_AXI_ARQOS   = ar_out[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+24:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+21];

	// ============================================================
	// R Channel: M -> S
	// ============================================================
	// R data width: RID + RDATA + RRESP + RLAST
	localparam integer R_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	reg [R_DATA_WIDTH-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] r_wr_ptr, r_rd_ptr;
	wire r_fifo_full, r_fifo_empty;

	assign r_fifo_full  = (r_wr_ptr[FIFO_ADDR_WIDTH] != r_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                      (r_wr_ptr[FIFO_ADDR_WIDTH-1:0] == r_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign r_fifo_empty = (r_wr_ptr == r_rd_ptr);

	// M-side R write
	wire r_m_valid = M_AXI_RVALID;
	wire r_m_ready = !r_fifo_full;
	assign M_AXI_RREADY = r_m_ready;

	wire r_m_fire = r_m_valid && r_m_ready;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			r_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (r_m_fire)
			r_wr_ptr <= r_wr_ptr + 1'b1;
	end

	always @(posedge M_AXI_ACLK) begin
		if (r_m_fire) begin
			r_fifo_mem[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_RID,
				M_AXI_RDATA,
				M_AXI_RRESP,
				M_AXI_RLAST
			};
		end
	end

	// S-side R read
	wire r_s_ready = S_AXI_RREADY;
	wire r_s_fire = !r_fifo_empty && r_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			r_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		else if (r_s_fire)
			r_rd_ptr <= r_rd_ptr + 1'b1;
	end

	// R output from FIFO
	reg [R_DATA_WIDTH-1:0] r_out;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			r_out <= {R_DATA_WIDTH{1'b0}};
		else
			r_out <= r_fifo_mem[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
	end

	assign S_AXI_RVALID = !r_fifo_empty;
	assign S_AXI_RID    = r_out[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_RDATA  = r_out[C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign S_AXI_RRESP  = r_out[C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH+1:C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH];
	assign S_AXI_RLAST  = r_out[R_DATA_WIDTH-1];

endmodule
