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
	localparam integer AW_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer AW_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer W_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer W_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer B_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer B_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer AR_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer R_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer R_FIFO_ADDR_WIDTH = LGFIFO;

	// AW channel: S to M
	wire [C_S_AXI_ID_WIDTH-1:0] aw_id_s2m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_s2m;
	wire [7:0] aw_len_s2m;
	wire [2:0] aw_size_s2m;
	wire [1:0] aw_burst_s2m;
	wire aw_lock_s2m;
	wire [3:0] aw_cache_s2m;
	wire [2:0] aw_prot_s2m;
	wire [3:0] aw_qos_s2m;
	wire aw_valid_s2m;
	wire aw_ready_m2s;

	// W channel: S to M
	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_s2m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s2m;
	wire w_last_s2m;
	wire w_valid_s2m;
	wire w_ready_m2s;

	// B channel: M to S
	wire [C_S_AXI_ID_WIDTH-1:0] b_id_m2s;
	wire [1:0] b_resp_m2s;
	wire b_valid_m2s;
	wire b_ready_s2m;

	// AR channel: S to M
	wire [C_S_AXI_ID_WIDTH-1:0] ar_id_s2m;
	wire [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_s2m;
	wire [7:0] ar_len_s2m;
	wire [2:0] ar_size_s2m;
	wire [1:0] ar_burst_s2m;
	wire ar_lock_s2m;
	wire [3:0] ar_cache_s2m;
	wire [2:0] ar_prot_s2m;
	wire [3:0] ar_qos_s2m;
	wire ar_valid_s2m;
	wire ar_ready_m2s;

	// R channel: M to S
	wire [C_S_AXI_ID_WIDTH-1:0] r_id_m2s;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_m2s;
	wire [1:0] r_resp_m2s;
	wire r_last_m2s;
	wire r_valid_m2s;
	wire r_ready_s2m;

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

	// AW FIFO: S side write, M side read
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_wr_ptr;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_s;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_m;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_m_sync;
	reg [AW_FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_m_sync_next;

	// AW FIFO storage
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:AW_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:AW_FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:AW_FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:AW_FIFO_DEPTH-1];
	reg aw_fifo_lock [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:AW_FIFO_DEPTH-1];

	// AW FIFO full/empty
	wire aw_fifo_full = (aw_wr_ptr == aw_rd_ptr_s) && (aw_wr_ptr[AW_FIFO_ADDR_WIDTH-1] != aw_rd_ptr_s[AW_FIFO_ADDR_WIDTH-1]);
	wire aw_fifo_empty = (aw_wr_ptr == aw_rd_ptr_s);

	// AW write on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			aw_fifo_id[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWID;
			aw_fifo_addr[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWADDR;
			aw_fifo_len[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWLEN;
			aw_fifo_size[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWSIZE;
			aw_fifo_burst[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWBURST;
			aw_fifo_lock[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWLOCK;
			aw_fifo_cache[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWCACHE;
			aw_fifo_prot[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWPROT;
			aw_fifo_qos[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_AWQOS;
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
		end
	end

	assign S_AXI_AWREADY = !aw_fifo_full;

	// AW read pointer sync to S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_rd_ptr_s <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			aw_rd_ptr_s <= aw_rd_ptr_m_sync;
		end
	end

	// AW read on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr_m <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_AWVALID && M_AXI_AWREADY) begin
			aw_rd_ptr_m <= aw_rd_ptr_m + 1'b1;
		end
	end

	// AW read pointer sync to M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr_m_sync <= {AW_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			aw_rd_ptr_m_sync <= aw_rd_ptr_m;
		end
	end

	// AW output on M clock
	assign M_AXI_AWID = aw_fifo_id[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWADDR = aw_fifo_addr[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWLEN = aw_fifo_len[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWSIZE = aw_fifo_size[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWBURST = aw_fifo_burst[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWLOCK = aw_fifo_lock[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWCACHE = aw_fifo_cache[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWPROT = aw_fifo_prot[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWQOS = aw_fifo_qos[aw_rd_ptr_m[AW_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_AWVALID = !aw_fifo_empty;

	// W FIFO: S side write, M side read
	reg [W_FIFO_ADDR_WIDTH-1:0] w_wr_ptr;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_s;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_m;
	reg [W_FIFO_ADDR_WIDTH-1:0] w_rd_ptr_m_sync;

	// W FIFO storage
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:W_FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:W_FIFO_DEPTH-1];
	reg w_fifo_last [0:W_FIFO_DEPTH-1];

	// W FIFO full/empty
	wire w_fifo_full = (w_wr_ptr == w_rd_ptr_s) && (w_wr_ptr[W_FIFO_ADDR_WIDTH-1] != w_rd_ptr_s[W_FIFO_ADDR_WIDTH-1]);
	wire w_fifo_empty = (w_wr_ptr == w_rd_ptr_s);

	// W write on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			w_fifo_data[w_wr_ptr[W_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_WDATA;
			w_fifo_strb[w_wr_ptr[W_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_WSTRB;
			w_fifo_last[w_wr_ptr[W_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_WLAST;
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	assign S_AXI_WREADY = !w_fifo_full;

	// W read pointer sync to S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_rd_ptr_s <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			w_rd_ptr_s <= w_rd_ptr_m_sync;
		end
	end

	// W read on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr_m <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_WVALID && M_AXI_WREADY) begin
			w_rd_ptr_m <= w_rd_ptr_m + 1'b1;
		end
	end

	// W read pointer sync to M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr_m_sync <= {W_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			w_rd_ptr_m_sync <= w_rd_ptr_m;
		end
	end

	// W output on M clock - hold one extra clock before M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_reg;
	reg w_last_reg;
	reg w_valid_reg;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_data_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			w_strb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			w_last_reg <= 1'b0;
			w_valid_reg <= 1'b0;
		end else begin
			if (!w_fifo_empty) begin
				w_data_reg <= w_fifo_data[w_rd_ptr_m[W_FIFO_ADDR_WIDTH-2:0]];
				w_strb_reg <= w_fifo_strb[w_rd_ptr_m[W_FIFO_ADDR_WIDTH-2:0]];
				w_last_reg <= w_fifo_last[w_rd_ptr_m[W_FIFO_ADDR_WIDTH-2:0]];
				w_valid_reg <= 1'b1;
			end else if (M_AXI_WVALID && M_AXI_WREADY) begin
				w_valid_reg <= 1'b0;
			end
		end
	end

	assign M_AXI_WDATA = w_data_reg;
	assign M_AXI_WSTRB = w_strb_reg;
	assign M_AXI_WLAST = w_last_reg;
	assign M_AXI_WVALID = w_valid_reg;

	// B FIFO: M side write, S side read
	reg [B_FIFO_ADDR_WIDTH-1:0] b_wr_ptr;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_m;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_s;
	reg [B_FIFO_ADDR_WIDTH-1:0] b_rd_ptr_s_sync;

	// B FIFO storage
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:B_FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:B_FIFO_DEPTH-1];

	// B FIFO full/empty
	wire b_fifo_full = (b_wr_ptr == b_rd_ptr_m) && (b_wr_ptr[B_FIFO_ADDR_WIDTH-1] != b_rd_ptr_m[B_FIFO_ADDR_WIDTH-1]);
	wire b_fifo_empty = (b_wr_ptr == b_rd_ptr_m);

	// B write on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			b_fifo_id[b_wr_ptr[B_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_BID;
			b_fifo_resp[b_wr_ptr[B_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_BRESP;
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	assign M_AXI_BREADY = !b_fifo_full;

	// B read pointer sync to M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_rd_ptr_m <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			b_rd_ptr_m <= b_rd_ptr_s_sync;
		end
	end

	// B read on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr_s <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_BVALID && S_AXI_BREADY) begin
			b_rd_ptr_s <= b_rd_ptr_s + 1'b1;
		end
	end

	// B read pointer sync to S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr_s_sync <= {B_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			b_rd_ptr_s_sync <= b_rd_ptr_s;
		end
	end

	// B output on S clock
	assign S_AXI_BID = b_fifo_id[b_rd_ptr_s[B_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_BRESP = b_fifo_resp[b_rd_ptr_s[B_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_BVALID = !b_fifo_empty;

	// AR FIFO: S side write, M side read
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_wr_ptr;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_s;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_m;
	reg [AR_FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_m_sync;

	// AR FIFO storage
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:AR_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:AR_FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:AR_FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:AR_FIFO_DEPTH-1];
	reg ar_fifo_lock [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:AR_FIFO_DEPTH-1];

	// AR FIFO full/empty
	wire ar_fifo_full = (ar_wr_ptr == ar_rd_ptr_s) && (ar_wr_ptr[AR_FIFO_ADDR_WIDTH-1] != ar_rd_ptr_s[AR_FIFO_ADDR_WIDTH-1]);
	wire ar_fifo_empty = (ar_wr_ptr == ar_rd_ptr_s);

	// AR write on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			ar_fifo_id[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARID;
			ar_fifo_addr[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARADDR;
			ar_fifo_len[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARLEN;
			ar_fifo_size[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARSIZE;
			ar_fifo_burst[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARBURST;
			ar_fifo_lock[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARLOCK;
			ar_fifo_cache[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARCACHE;
			ar_fifo_prot[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARPROT;
			ar_fifo_qos[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-2:0]] <= S_AXI_ARQOS;
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
		end
	end

	assign S_AXI_ARREADY = !ar_fifo_full;

	// AR read pointer sync to S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_rd_ptr_s <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			ar_rd_ptr_s <= ar_rd_ptr_m_sync;
		end
	end

	// AR read on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr_m <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_ARVALID && M_AXI_ARREADY) begin
			ar_rd_ptr_m <= ar_rd_ptr_m + 1'b1;
		end
	end

	// AR read pointer sync to M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr_m_sync <= {AR_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			ar_rd_ptr_m_sync <= ar_rd_ptr_m;
		end
	end

	// AR output on M clock
	assign M_AXI_ARID = ar_fifo_id[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARADDR = ar_fifo_addr[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARLEN = ar_fifo_len[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARSIZE = ar_fifo_size[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARBURST = ar_fifo_burst[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARLOCK = ar_fifo_lock[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARCACHE = ar_fifo_cache[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARPROT = ar_fifo_prot[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARQOS = ar_fifo_qos[ar_rd_ptr_m[AR_FIFO_ADDR_WIDTH-2:0]];
	assign M_AXI_ARVALID = !ar_fifo_empty;

	// R FIFO: M side write, S side read
	reg [R_FIFO_ADDR_WIDTH-1:0] r_wr_ptr;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_m;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_s;
	reg [R_FIFO_ADDR_WIDTH-1:0] r_rd_ptr_s_sync;

	// R FIFO storage
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:R_FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:R_FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:R_FIFO_DEPTH-1];
	reg r_fifo_last [0:R_FIFO_DEPTH-1];

	// R FIFO full/empty
	wire r_fifo_full = (r_wr_ptr == r_rd_ptr_m) && (r_wr_ptr[R_FIFO_ADDR_WIDTH-1] != r_rd_ptr_m[R_FIFO_ADDR_WIDTH-1]);
	wire r_fifo_empty = (r_wr_ptr == r_rd_ptr_m);

	// R write on M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else if (M_AXI_RVALID && M_AXI_RREADY) begin
			r_fifo_id[r_wr_ptr[R_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_RID;
			r_fifo_data[r_wr_ptr[R_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_RDATA;
			r_fifo_resp[r_wr_ptr[R_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_RRESP;
			r_fifo_last[r_wr_ptr[R_FIFO_ADDR_WIDTH-2:0]] <= M_AXI_RLAST;
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	assign M_AXI_RREADY = !r_fifo_full;

	// R read pointer sync to M clock
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_rd_ptr_m <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			r_rd_ptr_m <= r_rd_ptr_s_sync;
		end
	end

	// R read on S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr_s <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else if (S_AXI_RVALID && S_AXI_RREADY) begin
			r_rd_ptr_s <= r_rd_ptr_s + 1'b1;
		end
	end

	// R read pointer sync to S clock
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr_s_sync <= {R_FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			r_rd_ptr_s_sync <= r_rd_ptr_s;
		end
	end

	// R output on S clock
	assign S_AXI_RID = r_fifo_id[r_rd_ptr_s[R_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_RDATA = r_fifo_data[r_rd_ptr_s[R_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_RRESP = r_fifo_resp[r_rd_ptr_s[R_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_RLAST = r_fifo_last[r_rd_ptr_s[R_FIFO_ADDR_WIDTH-2:0]];
	assign S_AXI_RVALID = !r_fifo_empty;

endmodule
