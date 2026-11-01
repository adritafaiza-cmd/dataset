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
	localparam integer AW_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer W_FIFO_DEPTH = 2**LGFIFO;
	localparam integer W_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer B_FIFO_DEPTH = 2**LGFIFO;
	localparam integer B_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 2**LGFIFO;
	localparam integer AR_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer R_FIFO_DEPTH = 2**LGFIFO;
	localparam integer R_FIFO_ADDR_WIDTH = LGFIFO;

	// Reset synchronization
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end
	assign M_AXI_ARESETN = m_reset_sync[1];

	// AW Channel: S to M
	reg [AW_FIFO_DEPTH-1:0] aw_valid_s;
	reg [AW_FIFO_DEPTH-1:0] aw_valid_m;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_id_s [AW_FIFO_DEPTH-1:0];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_s [AW_FIFO_DEPTH-1:0];
	reg [7:0] aw_len_s [AW_FIFO_DEPTH-1:0];
	reg [2:0] aw_size_s [AW_FIFO_DEPTH-1:0];
	reg [1:0] aw_burst_s [AW_FIFO_DEPTH-1:0];
	reg aw_lock_s [AW_FIFO_DEPTH-1:0];
	reg [3:0] aw_cache_s [AW_FIFO_DEPTH-1:0];
	reg [2:0] aw_prot_s [AW_FIFO_DEPTH-1:0];
	reg [3:0] aw_qos_s [AW_FIFO_DEPTH-1:0];

	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_wr_ptr_s;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_m;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_s;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_wr_ptr_m;

	// AW write pointer sync to M clock
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_wr_ptr_m_sync1;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_wr_ptr_m_sync2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_wr_ptr_m_sync1 <= {AW_FIFO_ADDR_WIDTH{1'b0}};
			aw_wr_ptr_m_sync2 <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			aw_wr_ptr_m_sync1 <= aw_wr_ptr_m;
			aw_wr_ptr_m_sync2 <= aw_wr_ptr_m_sync1;
		end
	end

	// AW read pointer sync to S clock
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_s_sync1;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_s_sync2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_rd_ptr_s_sync1 <= {AW_FIFO_ADDR_WIDTH{1'b0}};
			aw_rd_ptr_s_sync2 <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			aw_rd_ptr_s_sync1 <= aw_rd_ptr_s;
			aw_rd_ptr_s_sync2 <= aw_rd_ptr_s_sync1;
		end
	end

	// AW FIFO full/empty
	wire aw_full_s = (aw_wr_ptr_s == aw_rd_ptr_s_sync2);
	wire aw_empty_m = (aw_rd_ptr_m == aw_wr_ptr_m_sync2);

	assign S_AXI_AWREADY = !aw_full_s;

	// AW write in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_valid_s <= {AW_FIFO_DEPTH{1'b0}};
			aw_wr_ptr_s <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_AWVALID && !aw_full_s) begin
			aw_valid_s[aw_wr_ptr_s] <= 1'b1;
			aw_id_s[aw_wr_ptr_s] <= S_AXI_AWID;
			aw_addr_s[aw_wr_ptr_s] <= S_AXI_AWADDR;
			aw_len_s[aw_wr_ptr_s] <= S_AXI_AWLEN;
			aw_size_s[aw_wr_ptr_s] <= S_AXI_AWSIZE;
			aw_burst_s[aw_wr_ptr_s] <= S_AXI_AWBURST;
			aw_lock_s[aw_wr_ptr_s] <= S_AXI_AWLOCK;
			aw_cache_s[aw_wr_ptr_s] <= S_AXI_AWCACHE;
			aw_prot_s[aw_wr_ptr_s] <= S_AXI_AWPROT;
			aw_qos_s[aw_wr_ptr_s] <= S_AXI_AWQOS;
			aw_wr_ptr_s <= aw_wr_ptr_s + 1'b1;
		end
	end

	// AW read in M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_valid_m <= {AW_FIFO_DEPTH{1'b0}};
			aw_rd_ptr_m <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else if (!aw_empty_m && M_AXI_AWREADY) begin
			aw_valid_m[aw_rd_ptr_m] <= 1'b0;
			aw_rd_ptr_m <= aw_rd_ptr_m + 1'b1;
		end
	end

	// AW output in M clock
	assign M_AXI_AWVALID = !aw_empty_m;
	assign M_AXI_AWID = aw_id_s[aw_rd_ptr_m];
	assign M_AXI_AWADDR = aw_addr_s[aw_rd_ptr_m];
	assign M_AXI_AWLEN = aw_len_s[aw_rd_ptr_m];
	assign M_AXI_AWSIZE = aw_size_s[aw_rd_ptr_m];
	assign M_AXI_AWBURST = aw_burst_s[aw_rd_ptr_m];
	assign M_AXI_AWLOCK = aw_lock_s[aw_rd_ptr_m];
	assign M_AXI_AWCACHE = aw_cache_s[aw_rd_ptr_m];
	assign M_AXI_AWPROT = aw_prot_s[aw_rd_ptr_m];
	assign M_AXI_AWQOS = aw_qos_s[aw_rd_ptr_m];

	// W Channel: S to M
	reg [W_FIFO_DEPTH-1:0] w_valid_s;
	reg [W_FIFO_DEPTH-1:0] w_valid_m;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_s [W_FIFO_DEPTH-1:0];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s [W_FIFO_DEPTH-1:0];
	reg w_last_s [W_FIFO_DEPTH-1:0];

	reg [W_FIFO_ADDR_WIDTH-1:0] w_wr_ptr_s;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_m;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_s;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_wr_ptr_m;

	// W write pointer sync to M clock
	reg [W_FIFO_ADDR_WIDTH-1:0] w_wr_ptr_m_sync1;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_wr_ptr_m_sync2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_wr_ptr_m_sync1 <= {W_FIFO_ADDR_WIDTH{1'b0}};
			w_wr_ptr_m_sync2 <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			w_wr_ptr_m_sync1 <= w_wr_ptr_m;
			w_wr_ptr_m_sync2 <= w_wr_ptr_m_sync1;
		end
	end

	// W read pointer sync to S clock
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_s_sync1;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_s_sync2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_rd_ptr_s_sync1 <= {W_FIFO_ADDR_WIDTH{1'b0}};
			w_rd_ptr_s_sync2 <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			w_rd_ptr_s_sync1 <= w_rd_ptr_s;
			w_rd_ptr_s_sync2 <= w_rd_ptr_s_sync1;
		end
	end

	// W FIFO full/empty
	wire w_full_s = (w_wr_ptr_s == w_rd_ptr_s_sync2);
	wire w_empty_m = (w_rd_ptr_m == w_wr_ptr_m_sync2);

	assign S_AXI_WREADY = !w_full_s;

	// W write in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_valid_s <= {W_FIFO_DEPTH{1'b0}};
			w_wr_ptr_s <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_WVALID && !w_full_s) begin
			w_valid_s[w_wr_ptr_s] <= 1'b1;
			w_data_s[w_wr_ptr_s] <= S_AXI_WDATA;
			w_strb_s[w_wr_ptr_s] <= S_AXI_WSTRB;
			w_last_s[w_wr_ptr_s] <= S_AXI_WLAST;
			w_wr_ptr_s <= w_wr_ptr_s + 1'b1;
		end
	end

	// W read in M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_valid_m <= {W_FIFO_DEPTH{1'b0}};
			w_rd_ptr_m <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else if (!w_empty_m && M_AXI_WREADY) begin
			w_valid_m[w_rd_ptr_m] <= 1'b0;
			w_rd_ptr_m <= w_rd_ptr_m + 1'b1;
		end
	end

	// W output in M clock - hold one extra clock before M_AXI_WVALID
	reg w_valid_out;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_out;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_out;
	reg w_last_out;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_valid_out <= 1'b0;
			w_data_out <= {C_S_AXI_DATA_WIDTH{1'b0}};
			w_strb_out <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			w_last_out <= 1'b0;
		end else begin
			if (!w_empty_m) begin
				w_valid_out <= 1'b1;
				w_data_out <= w_data_s[w_rd_ptr_m];
				w_strb_out <= w_strb_s[w_rd_ptr_m];
				w_last_out <= w_last_s[w_rd_ptr_m];
			end else if (w_valid_out && M_AXI_WREADY) begin
				w_valid_out <= 1'b0;
			end
		end
	end

	assign M_AXI_WVALID = w_valid_out;
	assign M_AXI_WDATA = w_data_out;
	assign M_AXI_WSTRB = w_strb_out;
	assign M_AXI_WLAST = w_last_out;

	// B Channel: M to S
	reg [B_FIFO_DEPTH-1:0] b_valid_m;
	reg [B_FIFO_DEPTH-1:0] b_valid_s;
	reg [C_S_AXI_ID_WIDTH-1:0] b_id_m [B_FIFO_DEPTH-1:0];
	reg [1:0] b_resp_m [B_FIFO_DEPTH-1:0];

	reg [B_FIFO_ADDR_WIDTH-1:0] b_wr_ptr_m;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_s;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_m;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_wr_ptr_s;

	// B write pointer sync to S clock
	reg [B_FIFO_ADDR_WIDTH-1:0] b_wr_ptr_s_sync1;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_wr_ptr_s_sync2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_wr_ptr_s_sync1 <= {B_FIFO_ADDR_WIDTH{1'b0}};
			b_wr_ptr_s_sync2 <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			b_wr_ptr_s_sync1 <= b_wr_ptr_s;
			b_wr_ptr_s_sync2 <= b_wr_ptr_s_sync1;
		end
	end

	// B read pointer sync to M clock
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_m_sync1;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_m_sync2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_rd_ptr_m_sync1 <= {B_FIFO_ADDR_WIDTH{1'b0}};
			b_rd_ptr_m_sync2 <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			b_rd_ptr_m_sync1 <= b_rd_ptr_m;
			b_rd_ptr_m_sync2 <= b_rd_ptr_m_sync1;
		end
	end

	// B FIFO full/empty
	wire b_full_m = (b_wr_ptr_m == b_rd_ptr_m_sync2);
	wire b_empty_s = (b_rd_ptr_s == b_wr_ptr_s_sync2);

	assign M_AXI_BREADY = !b_full_m;

	// B write in M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_valid_m <= {B_FIFO_DEPTH{1'b0}};
			b_wr_ptr_m <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_BVALID && !b_full_m) begin
			b_valid_m[b_wr_ptr_m] <= 1'b1;
			b_id_m[b_wr_ptr_m] <= M_AXI_BID;
			b_resp_m[b_wr_ptr_m] <= M_AXI_BRESP;
			b_wr_ptr_m <= b_wr_ptr_m + 1'b1;
		end
	end

	// B read in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_valid_s <= {B_FIFO_DEPTH{1'b0}};
			b_rd_ptr_s <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else if (!b_empty_s && S_AXI_BREADY) begin
			b_valid_s[b_rd_ptr_s] <= 1'b0;
			b_rd_ptr_s <= b_rd_ptr_s + 1'b1;
		end
	end

	// B output in S clock
	assign S_AXI_BVALID = !b_empty_s;
	assign S_AXI_BID = b_id_m[b_rd_ptr_s];
	assign S_AXI_BRESP = b_resp_m[b_rd_ptr_s];

	// AR Channel: S to M
	reg [AR_FIFO_DEPTH-1:0] ar_valid_s;
	reg [AR_FIFO_DEPTH-1:0] ar_valid_m;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_id_s [AR_FIFO_DEPTH-1:0];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_s [AR_FIFO_DEPTH-1:0];
	reg [7:0] ar_len_s [AR_FIFO_DEPTH-1:0];
	reg [2:0] ar_size_s [AR_FIFO_DEPTH-1:0];
	reg [1:0] ar_burst_s [AR_FIFO_DEPTH-1:0];
	reg ar_lock_s [AR_FIFO_DEPTH-1:0];
	reg [3:0] ar_cache_s [AR_FIFO_DEPTH-1:0];
	reg [2:0] ar_prot_s [AR_FIFO_DEPTH-1:0];
	reg [3:0] ar_qos_s [AR_FIFO_DEPTH-1:0];

	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_wr_ptr_s;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_m;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_s;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_wr_ptr_m;

	// AR write pointer sync to M clock
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_wr_ptr_m_sync1;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_wr_ptr_m_sync2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_wr_ptr_m_sync1 <= {AR_FIFO_ADDR_WIDTH{1'b0}};
			ar_wr_ptr_m_sync2 <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			ar_wr_ptr_m_sync1 <= ar_wr_ptr_m;
			ar_wr_ptr_m_sync2 <= ar_wr_ptr_m_sync1;
		end
	end

	// AR read pointer sync to S clock
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_s_sync1;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_s_sync2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_rd_ptr_s_sync1 <= {AR_FIFO_ADDR_WIDTH{1'b0}};
			ar_rd_ptr_s_sync2 <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			ar_rd_ptr_s_sync1 <= ar_rd_ptr_s;
			ar_rd_ptr_s_sync2 <= ar_rd_ptr_s_sync1;
		end
	end

	// AR FIFO full/empty
	wire ar_full_s = (ar_wr_ptr_s == ar_rd_ptr_s_sync2);
	wire ar_empty_m = (ar_rd_ptr_m == ar_wr_ptr_m_sync2);

	assign S_AXI_ARREADY = !ar_full_s;

	// AR write in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_valid_s <= {AR_FIFO_DEPTH{1'b0}};
			ar_wr_ptr_s <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_ARVALID && !ar_full_s) begin
			ar_valid_s[ar_wr_ptr_s] <= 1'b1;
			ar_id_s[ar_wr_ptr_s] <= S_AXI_ARID;
			ar_addr_s[ar_wr_ptr_s] <= S_AXI_ARADDR;
			ar_len_s[ar_wr_ptr_s] <= S_AXI_ARLEN;
			ar_size_s[ar_wr_ptr_s] <= S_AXI_ARSIZE;
			ar_burst_s[ar_wr_ptr_s] <= S_AXI_ARBURST;
			ar_lock_s[ar_wr_ptr_s] <= S_AXI_ARLOCK;
			ar_cache_s[ar_wr_ptr_s] <= S_AXI_ARCACHE;
			ar_prot_s[ar_wr_ptr_s] <= S_AXI_ARPROT;
			ar_qos_s[ar_wr_ptr_s] <= S_AXI_ARQOS;
			ar_wr_ptr_s <= ar_wr_ptr_s + 1'b1;
		end
	end

	// AR read in M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_valid_m <= {AR_FIFO_DEPTH{1'b0}};
			ar_rd_ptr_m <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else if (!ar_empty_m && M_AXI_ARREADY) begin
			ar_valid_m[ar_rd_ptr_m] <= 1'b0;
			ar_rd_ptr_m <= ar_rd_ptr_m + 1'b1;
		end
	end

	// AR output in M clock
	assign M_AXI_ARVALID = !ar_empty_m;
	assign M_AXI_ARID = ar_id_s[ar_rd_ptr_m];
	assign M_AXI_ARADDR = ar_addr_s[ar_rd_ptr_m];
	assign M_AXI_ARLEN = ar_len_s[ar_rd_ptr_m];
	assign M_AXI_ARSIZE = ar_size_s[ar_rd_ptr_m];
	assign M_AXI_ARBURST = ar_burst_s[ar_rd_ptr_m];
	assign M_AXI_ARLOCK = ar_lock_s[ar_rd_ptr_m];
	assign M_AXI_ARCACHE = ar_cache_s[ar_rd_ptr_m];
	assign M_AXI_ARPROT = ar_prot_s[ar_rd_ptr_m];
	assign M_AXI_ARQOS = ar_qos_s[ar_rd_ptr_m];

	// R Channel: M to S
	reg [R_FIFO_DEPTH-1:0] r_valid_m;
	reg [R_FIFO_DEPTH-1:0] r_valid_s;
	reg [C_S_AXI_ID_WIDTH-1:0] r_id_m [R_FIFO_DEPTH-1:0];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_data_m [R_FIFO_DEPTH-1:0];
	reg [1:0] r_resp_m [R_FIFO_DEPTH-1:0];
	reg r_last_m [R_FIFO_DEPTH-1:0];

	reg [R_FIFO_ADDR_WIDTH-1:0] r_wr_ptr_m;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_s;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_m;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_wr_ptr_s;

	// R write pointer sync to S clock
	reg [R_FIFO_ADDR_WIDTH-1:0] r_wr_ptr_s_sync1;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_wr_ptr_s_sync2;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_wr_ptr_s_sync1 <= {R_FIFO_ADDR_WIDTH{1'b0}};
			r_wr_ptr_s_sync2 <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			r_wr_ptr_s_sync1 <= r_wr_ptr_s;
			r_wr_ptr_s_sync2 <= r_wr_ptr_s_sync1;
		end
	end

	// R read pointer sync to M clock
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_m_sync1;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_m_sync2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_rd_ptr_m_sync1 <= {R_FIFO_ADDR_WIDTH{1'b0}};
			r_rd_ptr_m_sync2 <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			r_rd_ptr_m_sync1 <= r_rd_ptr_m;
			r_rd_ptr_m_sync2 <= r_rd_ptr_m_sync1;
		end
	end

	// R FIFO full/empty
	wire r_full_m = (r_wr_ptr_m == r_rd_ptr_m_sync2);
	wire r_empty_s = (r_rd_ptr_s == r_wr_ptr_s_sync2);

	assign M_AXI_RREADY = !r_full_m;

	// R write in M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_valid_m <= {R_FIFO_DEPTH{1'b0}};
			r_wr_ptr_m <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_RVALID && !r_full_m) begin
			r_valid_m[r_wr_ptr_m] <= 1'b1;
			r_id_m[r_wr_ptr_m] <= M_AXI_RID;
			r_data_m[r_wr_ptr_m] <= M_AXI_RDATA;
			r_resp_m[r_wr_ptr_m] <= M_AXI_RRESP;
			r_last_m[r_wr_ptr_m] <= M_AXI_RLAST;
			r_wr_ptr_m <= r_wr_ptr_m + 1'b1;
		end
	end

	// R read in S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_valid_s <= {R_FIFO_DEPTH{1'b0}};
			r_rd_ptr_s <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else if (!r_empty_s && S_AXI_RREADY) begin
			r_valid_s[r_rd_ptr_s] <= 1'b0;
			r_rd_ptr_s <= r_rd_ptr_s + 1'b1;
		end
	end

	// R output in S clock
	assign S_AXI_RVALID = !r_empty_s;
	assign S_AXI_RID = r_id_m[r_rd_ptr_s];
	assign S_AXI_RDATA = r_data_m[r_rd_ptr_s];
	assign S_AXI_RRESP = r_resp_m[r_rd_ptr_s];
	assign S_AXI_RLAST = r_last_m[r_rd_ptr_s];

endmodule
