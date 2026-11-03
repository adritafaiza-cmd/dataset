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
	localparam integer AW_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer AW_FIFO_ADDR_W = LGFIFO;
	localparam integer W_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer W_FIFO_ADDR_W = LGFIFO;
	localparam integer B_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer B_FIFO_ADDR_W = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer AR_FIFO_ADDR_W = LGFIFO;
	localparam integer R_FIFO_DEPTH = 2 ** LGFIFO;
	localparam integer R_FIFO_ADDR_W = LGFIFO;

	// AW channel: S -> M
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

	// W channel: S -> M
	wire [C_S_AXI_DATA_WIDTH-1:0] w_data_s2m;
	wire [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s2m;
	wire w_last_s2m;
	wire w_valid_s2m;
	wire w_ready_m2s;

	// B channel: M -> S
	wire [C_S_AXI_ID_WIDTH-1:0] b_id_m2s;
	wire [1:0] b_resp_m2s;
	wire b_valid_m2s;
	wire b_ready_s2m;

	// AR channel: S -> M
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

	// R channel: M -> S
	wire [C_S_AXI_ID_WIDTH-1:0] r_id_m2s;
	wire [C_S_AXI_DATA_WIDTH-1:0] r_data_m2s;
	wire [1:0] r_resp_m2s;
	wire r_last_m2s;
	wire r_valid_m2s;
	wire r_ready_s2m;

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

	// AW FIFO: S_AXI_ACLK domain
	reg [AW_FIFO_DEPTH-1:0] aw_fifo_valid;
	reg [AW_FIFO_ADDR_W-1:0] aw_fifo_wr_ptr;
	reg [AW_FIFO_ADDR_W-1:0] aw_fifo_rd_ptr;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:AW_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:AW_FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:AW_FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:AW_FIFO_DEPTH-1];
	reg aw_fifo_lock [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:AW_FIFO_DEPTH-1];

	wire aw_fifo_full = (aw_fifo_wr_ptr == aw_fifo_rd_ptr) && aw_fifo_valid[aw_fifo_wr_ptr];
	wire aw_fifo_empty = !aw_fifo_valid[aw_fifo_rd_ptr];

	assign S_AXI_AWREADY = !aw_fifo_full;
	assign aw_valid_s2m = !aw_fifo_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_valid <= {AW_FIFO_DEPTH{1'b0}};
			aw_fifo_wr_ptr <= {AW_FIFO_ADDR_W{1'b0}};
			aw_fifo_rd_ptr <= {AW_FIFO_ADDR_W{1'b0}};
		end else begin
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				aw_fifo_id[aw_fifo_wr_ptr] <= S_AXI_AWID;
				aw_fifo_addr[aw_fifo_wr_ptr] <= S_AXI_AWADDR;
				aw_fifo_len[aw_fifo_wr_ptr] <= S_AXI_AWLEN;
				aw_fifo_size[aw_fifo_wr_ptr] <= S_AXI_AWSIZE;
				aw_fifo_burst[aw_fifo_wr_ptr] <= S_AXI_AWBURST;
				aw_fifo_lock[aw_fifo_wr_ptr] <= S_AXI_AWLOCK;
				aw_fifo_cache[aw_fifo_wr_ptr] <= S_AXI_AWCACHE;
				aw_fifo_prot[aw_fifo_wr_ptr] <= S_AXI_AWPROT;
				aw_fifo_qos[aw_fifo_wr_ptr] <= S_AXI_AWQOS;
				aw_fifo_valid[aw_fifo_wr_ptr] <= 1'b1;
				aw_fifo_wr_ptr <= aw_fifo_wr_ptr + 1'b1;
			end
			if (aw_valid_s2m && aw_ready_m2s) begin
				aw_fifo_valid[aw_fifo_rd_ptr] <= 1'b0;
				aw_fifo_rd_ptr <= aw_fifo_rd_ptr + 1'b1;
			end
		end
	end

	assign aw_id_s2m = aw_fifo_id[aw_fifo_rd_ptr];
	assign aw_addr_s2m = aw_fifo_addr[aw_fifo_rd_ptr];
	assign aw_len_s2m = aw_fifo_len[aw_fifo_rd_ptr];
	assign aw_size_s2m = aw_fifo_size[aw_fifo_rd_ptr];
	assign aw_burst_s2m = aw_fifo_burst[aw_fifo_rd_ptr];
	assign aw_lock_s2m = aw_fifo_lock[aw_fifo_rd_ptr];
	assign aw_cache_s2m = aw_fifo_cache[aw_fifo_rd_ptr];
	assign aw_prot_s2m = aw_fifo_prot[aw_fifo_rd_ptr];
	assign aw_qos_s2m = aw_fifo_qos[aw_fifo_rd_ptr];

	// AW FIFO: M_AXI_ACLK domain
	reg [AW_FIFO_ADDR_W-1:0] aw_fifo_rd_ptr_m;
	reg [AW_FIFO_ADDR_W-1:0] aw_fifo_wr_ptr_m;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id_m [0:AW_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr_m [0:AW_FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len_m [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size_m [0:AW_FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst_m [0:AW_FIFO_DEPTH-1];
	reg aw_fifo_lock_m [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache_m [0:AW_FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot_m [0:AW_FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos_m [0:AW_FIFO_DEPTH-1];
	reg [AW_FIFO_DEPTH-1:0] aw_fifo_valid_m;

	wire aw_fifo_full_m = (aw_fifo_wr_ptr_m == aw_fifo_rd_ptr_m) && aw_fifo_valid_m[aw_fifo_wr_ptr_m];
	wire aw_fifo_empty_m = !aw_fifo_valid_m[aw_fifo_rd_ptr_m];

	assign M_AXI_AWID = aw_fifo_id_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWADDR = aw_fifo_addr_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWLEN = aw_fifo_len_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWSIZE = aw_fifo_size_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWBURST = aw_fifo_burst_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWLOCK = aw_fifo_lock_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWCACHE = aw_fifo_cache_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWPROT = aw_fifo_prot_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWQOS = aw_fifo_qos_m[aw_fifo_rd_ptr_m];
	assign M_AXI_AWVALID = !aw_fifo_empty_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_valid_m <= {AW_FIFO_DEPTH{1'b0}};
			aw_fifo_wr_ptr_m <= {AW_FIFO_ADDR_W{1'b0}};
			aw_fifo_rd_ptr_m <= {AW_FIFO_ADDR_W{1'b0}};
		end else begin
			if (aw_valid_s2m && !aw_fifo_full_m) begin
				aw_fifo_id_m[aw_fifo_wr_ptr_m] <= aw_id_s2m;
				aw_fifo_addr_m[aw_fifo_wr_ptr_m] <= aw_addr_s2m;
				aw_fifo_len_m[aw_fifo_wr_ptr_m] <= aw_len_s2m;
				aw_fifo_size_m[aw_fifo_wr_ptr_m] <= aw_size_s2m;
				aw_fifo_burst_m[aw_fifo_wr_ptr_m] <= aw_burst_s2m;
				aw_fifo_lock_m[aw_fifo_wr_ptr_m] <= aw_lock_s2m;
				aw_fifo_cache_m[aw_fifo_wr_ptr_m] <= aw_cache_s2m;
				aw_fifo_prot_m[aw_fifo_wr_ptr_m] <= aw_prot_s2m;
				aw_fifo_qos_m[aw_fifo_wr_ptr_m] <= aw_qos_s2m;
				aw_fifo_valid_m[aw_fifo_wr_ptr_m] <= 1'b1;
				aw_fifo_wr_ptr_m <= aw_fifo_wr_ptr_m + 1'b1;
			end
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				aw_fifo_valid_m[aw_fifo_rd_ptr_m] <= 1'b0;
				aw_fifo_rd_ptr_m <= aw_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	assign aw_ready_m2s = !aw_fifo_full_m;

	// W FIFO: S_AXI_ACLK domain
	reg [W_FIFO_DEPTH-1:0] w_fifo_valid;
	reg [W_FIFO_ADDR_W-1:0] w_fifo_wr_ptr;
	reg [W_FIFO_ADDR_W-1:0] w_fifo_rd_ptr;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:W_FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:W_FIFO_DEPTH-1];
	reg w_fifo_last [0:W_FIFO_DEPTH-1];

	wire w_fifo_full = (w_fifo_wr_ptr == w_fifo_rd_ptr) && w_fifo_valid[w_fifo_wr_ptr];
	wire w_fifo_empty = !w_fifo_valid[w_fifo_rd_ptr];

	assign S_AXI_WREADY = !w_fifo_full;
	assign w_valid_s2m = !w_fifo_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_valid <= {W_FIFO_DEPTH{1'b0}};
			w_fifo_wr_ptr <= {W_FIFO_ADDR_W{1'b0}};
			w_fifo_rd_ptr <= {W_FIFO_ADDR_W{1'b0}};
		end else begin
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_fifo_data[w_fifo_wr_ptr] <= S_AXI_WDATA;
				w_fifo_strb[w_fifo_wr_ptr] <= S_AXI_WSTRB;
				w_fifo_last[w_fifo_wr_ptr] <= S_AXI_WLAST;
				w_fifo_valid[w_fifo_wr_ptr] <= 1'b1;
				w_fifo_wr_ptr <= w_fifo_wr_ptr + 1'b1;
			end
			if (w_valid_s2m && w_ready_m2s) begin
				w_fifo_valid[w_fifo_rd_ptr] <= 1'b0;
				w_fifo_rd_ptr <= w_fifo_rd_ptr + 1'b1;
			end
		end
	end

	assign w_data_s2m = w_fifo_data[w_fifo_rd_ptr];
	assign w_strb_s2m = w_fifo_strb[w_fifo_rd_ptr];
	assign w_last_s2m = w_fifo_last[w_fifo_rd_ptr];

	// W FIFO: M_AXI_ACLK domain
	reg [W_FIFO_ADDR_W-1:0] w_fifo_rd_ptr_m;
	reg [W_FIFO_ADDR_W-1:0] w_fifo_wr_ptr_m;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data_m [0:W_FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb_m [0:W_FIFO_DEPTH-1];
	reg w_fifo_last_m [0:W_FIFO_DEPTH-1];
	reg [W_FIFO_DEPTH-1:0] w_fifo_valid_m;

	wire w_fifo_full_m = (w_fifo_wr_ptr_m == w_fifo_rd_ptr_m) && w_fifo_valid_m[w_fifo_wr_ptr_m];
	wire w_fifo_empty_m = !w_fifo_valid_m[w_fifo_rd_ptr_m];

	// Hold one extra M_AXI clock before M_AXI_WVALID
	reg w_hold_valid;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_hold_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_hold_strb;
	reg w_hold_last;

	assign M_AXI_WDATA = w_hold_data;
	assign M_AXI_WSTRB = w_hold_strb;
	assign M_AXI_WLAST = w_hold_last;
	assign M_AXI_WVALID = w_hold_valid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_valid_m <= {W_FIFO_DEPTH{1'b0}};
			w_fifo_wr_ptr_m <= {W_FIFO_ADDR_W{1'b0}};
			w_fifo_rd_ptr_m <= {W_FIFO_ADDR_W{1'b0}};
			w_hold_valid <= 1'b0;
			w_hold_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
			w_hold_strb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			w_hold_last <= 1'b0;
		end else begin
			if (w_valid_s2m && !w_fifo_full_m) begin
				w_fifo_data_m[w_fifo_wr_ptr_m] <= w_data_s2m;
				w_fifo_strb_m[w_fifo_wr_ptr_m] <= w_strb_s2m;
				w_fifo_last_m[w_fifo_wr_ptr_m] <= w_last_s2m;
				w_fifo_valid_m[w_fifo_wr_ptr_m] <= 1'b1;
				w_fifo_wr_ptr_m <= w_fifo_wr_ptr_m + 1'b1;
			end
			if (M_AXI_WVALID && M_AXI_WREADY) begin
				w_hold_valid <= 1'b0;
			end
			if (!w_hold_valid && !w_fifo_empty_m) begin
				w_hold_valid <= 1'b1;
				w_hold_data <= w_fifo_data_m[w_fifo_rd_ptr_m];
				w_hold_strb <= w_fifo_strb_m[w_fifo_rd_ptr_m];
				w_hold_last <= w_fifo_last_m[w_fifo_rd_ptr_m];
				w_fifo_valid_m[w_fifo_rd_ptr_m] <= 1'b0;
				w_fifo_rd_ptr_m <= w_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	assign w_ready_m2s = !w_fifo_full_m;

	// B FIFO: M_AXI_ACLK domain
	reg [B_FIFO_DEPTH-1:0] b_fifo_valid;
	reg [B_FIFO_ADDR_W-1:0] b_fifo_wr_ptr;
	reg [B_FIFO_ADDR_W-1:0] b_fifo_rd_ptr;
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:B_FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:B_FIFO_DEPTH-1];

	wire b_fifo_full = (b_fifo_wr_ptr == b_fifo_rd_ptr) && b_fifo_valid[b_fifo_wr_ptr];
	wire b_fifo_empty = !b_fifo_valid[b_fifo_rd_ptr];

	assign M_AXI_BREADY = !b_fifo_full;
	assign b_valid_m2s = !b_fifo_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_valid <= {B_FIFO_DEPTH{1'b0}};
			b_fifo_wr_ptr <= {B_FIFO_ADDR_W{1'b0}};
			b_fifo_rd_ptr <= {B_FIFO_ADDR_W{1'b0}};
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_fifo_id[b_fifo_wr_ptr] <= M_AXI_BID;
				b_fifo_resp[b_fifo_wr_ptr] <= M_AXI_BRESP;
				b_fifo_valid[b_fifo_wr_ptr] <= 1'b1;
				b_fifo_wr_ptr <= b_fifo_wr_ptr + 1'b1;
			end
			if (b_valid_m2s && b_ready_s2m) begin
				b_fifo_valid[b_fifo_rd_ptr] <= 1'b0;
				b_fifo_rd_ptr <= b_fifo_rd_ptr + 1'b1;
			end
		end
	end

	assign b_id_m2s = b_fifo_id[b_fifo_rd_ptr];
	assign b_resp_m2s = b_fifo_resp[b_fifo_rd_ptr];

	// B FIFO: S_AXI_ACLK domain
	reg [B_FIFO_ADDR_W-1:0] b_fifo_rd_ptr_s;
	reg [B_FIFO_ADDR_W-1:0] b_fifo_wr_ptr_s;
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id_s [0:B_FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp_s [0:B_FIFO_DEPTH-1];
	reg [B_FIFO_DEPTH-1:0] b_fifo_valid_s;

	wire b_fifo_full_s = (b_fifo_wr_ptr_s == b_fifo_rd_ptr_s) && b_fifo_valid_s[b_fifo_wr_ptr_s];
	wire b_fifo_empty_s = !b_fifo_valid_s[b_fifo_rd_ptr_s];

	assign S_AXI_BID = b_fifo_id_s[b_fifo_rd_ptr_s];
	assign S_AXI_BRESP = b_fifo_resp_s[b_fifo_rd_ptr_s];
	assign S_AXI_BVALID = !b_fifo_empty_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_valid_s <= {B_FIFO_DEPTH{1'b0}};
			b_fifo_wr_ptr_s <= {B_FIFO_ADDR_W{1'b0}};
			b_fifo_rd_ptr_s <= {B_FIFO_ADDR_W{1'b0}};
		end else begin
			if (b_valid_m2s && !b_fifo_full_s) begin
				b_fifo_id_s[b_fifo_wr_ptr_s] <= b_id_m2s;
				b_fifo_resp_s[b_fifo_wr_ptr_s] <= b_resp_m2s;
				b_fifo_valid_s[b_fifo_wr_ptr_s] <= 1'b1;
				b_fifo_wr_ptr_s <= b_fifo_wr_ptr_s + 1'b1;
			end
			if (S_AXI_BVALID && S_AXI_BREADY) begin
				b_fifo_valid_s[b_fifo_rd_ptr_s] <= 1'b0;
				b_fifo_rd_ptr_s <= b_fifo_rd_ptr_s + 1'b1;
			end
		end
	end

	assign b_ready_s2m = !b_fifo_full_s;

	// AR FIFO: S_AXI_ACLK domain
	reg [AR_FIFO_DEPTH-1:0] ar_fifo_valid;
	reg [AR_FIFO_ADDR_W-1:0] ar_fifo_wr_ptr;
	reg [AR_FIFO_ADDR_W-1:0] ar_fifo_rd_ptr;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:AR_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:AR_FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:AR_FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:AR_FIFO_DEPTH-1];
	reg ar_fifo_lock [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:AR_FIFO_DEPTH-1];

	wire ar_fifo_full = (ar_fifo_wr_ptr == ar_fifo_rd_ptr) && ar_fifo_valid[ar_fifo_wr_ptr];
	wire ar_fifo_empty = !ar_fifo_valid[ar_fifo_rd_ptr];

	assign S_AXI_ARREADY = !ar_fifo_full;
	assign ar_valid_s2m = !ar_fifo_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_valid <= {AR_FIFO_DEPTH{1'b0}};
			ar_fifo_wr_ptr <= {AR_FIFO_ADDR_W{1'b0}};
			ar_fifo_rd_ptr <= {AR_FIFO_ADDR_W{1'b0}};
		end else begin
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				ar_fifo_id[ar_fifo_wr_ptr] <= S_AXI_ARID;
				ar_fifo_addr[ar_fifo_wr_ptr] <= S_AXI_ARADDR;
				ar_fifo_len[ar_fifo_wr_ptr] <= S_AXI_ARLEN;
				ar_fifo_size[ar_fifo_wr_ptr] <= S_AXI_ARSIZE;
				ar_fifo_burst[ar_fifo_wr_ptr] <= S_AXI_ARBURST;
				ar_fifo_lock[ar_fifo_wr_ptr] <= S_AXI_ARLOCK;
				ar_fifo_cache[ar_fifo_wr_ptr] <= S_AXI_ARCACHE;
				ar_fifo_prot[ar_fifo_wr_ptr] <= S_AXI_ARPROT;
				ar_fifo_qos[ar_fifo_wr_ptr] <= S_AXI_ARQOS;
				ar_fifo_valid[ar_fifo_wr_ptr] <= 1'b1;
				ar_fifo_wr_ptr <= ar_fifo_wr_ptr + 1'b1;
			end
			if (ar_valid_s2m && ar_ready_m2s) begin
				ar_fifo_valid[ar_fifo_rd_ptr] <= 1'b0;
				ar_fifo_rd_ptr <= ar_fifo_rd_ptr + 1'b1;
			end
		end
	end

	assign ar_id_s2m = ar_fifo_id[ar_fifo_rd_ptr];
	assign ar_addr_s2m = ar_fifo_addr[ar_fifo_rd_ptr];
	assign ar_len_s2m = ar_fifo_len[ar_fifo_rd_ptr];
	assign ar_size_s2m = ar_fifo_size[ar_fifo_rd_ptr];
	assign ar_burst_s2m = ar_fifo_burst[ar_fifo_rd_ptr];
	assign ar_lock_s2m = ar_fifo_lock[ar_fifo_rd_ptr];
	assign ar_cache_s2m = ar_fifo_cache[ar_fifo_rd_ptr];
	assign ar_prot_s2m = ar_fifo_prot[ar_fifo_rd_ptr];
	assign ar_qos_s2m = ar_fifo_qos[ar_fifo_rd_ptr];

	// AR FIFO: M_AXI_ACLK domain
	reg [AR_FIFO_ADDR_W-1:0] ar_fifo_rd_ptr_m;
	reg [AR_FIFO_ADDR_W-1:0] ar_fifo_wr_ptr_m;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id_m [0:AR_FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr_m [0:AR_FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len_m [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size_m [0:AR_FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst_m [0:AR_FIFO_DEPTH-1];
	reg ar_fifo_lock_m [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache_m [0:AR_FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot_m [0:AR_FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos_m [0:AR_FIFO_DEPTH-1];
	reg [AR_FIFO_DEPTH-1:0] ar_fifo_valid_m;

	wire ar_fifo_full_m = (ar_fifo_wr_ptr_m == ar_fifo_rd_ptr_m) && ar_fifo_valid_m[ar_fifo_wr_ptr_m];
	wire ar_fifo_empty_m = !ar_fifo_valid_m[ar_fifo_rd_ptr_m];

	assign M_AXI_ARID = ar_fifo_id_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARADDR = ar_fifo_addr_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARLEN = ar_fifo_len_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARSIZE = ar_fifo_size_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARBURST = ar_fifo_burst_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARLOCK = ar_fifo_lock_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARCACHE = ar_fifo_cache_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARPROT = ar_fifo_prot_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARQOS = ar_fifo_qos_m[ar_fifo_rd_ptr_m];
	assign M_AXI_ARVALID = !ar_fifo_empty_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_valid_m <= {AR_FIFO_DEPTH{1'b0}};
			ar_fifo_wr_ptr_m <= {AR_FIFO_ADDR_W{1'b0}};
			ar_fifo_rd_ptr_m <= {AR_FIFO_ADDR_W{1'b0}};
		end else begin
			if (ar_valid_s2m && !ar_fifo_full_m) begin
				ar_fifo_id_m[ar_fifo_wr_ptr_m] <= ar_id_s2m;
				ar_fifo_addr_m[ar_fifo_wr_ptr_m] <= ar_addr_s2m;
				ar_fifo_len_m[ar_fifo_wr_ptr_m] <= ar_len_s2m;
				ar_fifo_size_m[ar_fifo_wr_ptr_m] <= ar_size_s2m;
				ar_fifo_burst_m[ar_fifo_wr_ptr_m] <= ar_burst_s2m;
				ar_fifo_lock_m[ar_fifo_wr_ptr_m] <= ar_lock_s2m;
				ar_fifo_cache_m[ar_fifo_wr_ptr_m] <= ar_cache_s2m;
				ar_fifo_prot_m[ar_fifo_wr_ptr_m] <= ar_prot_s2m;
				ar_fifo_qos_m[ar_fifo_wr_ptr_m] <= ar_qos_s2m;
				ar_fifo_valid_m[ar_fifo_wr_ptr_m] <= 1'b1;
				ar_fifo_wr_ptr_m <= ar_fifo_wr_ptr_m + 1'b1;
			end
			if (M_AXI_ARVALID && M_AXI_ARREADY) begin
				ar_fifo_valid_m[ar_fifo_rd_ptr_m] <= 1'b0;
				ar_fifo_rd_ptr_m <= ar_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	assign ar_ready_m2s = !ar_fifo_full_m;

	// R FIFO: M_AXI_ACLK domain
	reg [R_FIFO_DEPTH-1:0] r_fifo_valid;
	reg [R_FIFO_ADDR_W-1:0] r_fifo_wr_ptr;
	reg [R_FIFO_ADDR_W-1:0] r_fifo_rd_ptr;
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:R_FIFO_DEPTH-1];
	reg [C