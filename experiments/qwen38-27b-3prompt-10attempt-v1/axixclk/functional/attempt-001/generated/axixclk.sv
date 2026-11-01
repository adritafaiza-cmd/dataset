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

	// Reset synchronization
	reg [FFS_STAGES-1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
	end
	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// AW Channel: S -> M
	reg [C_S_AXI_ID_WIDTH-1:0] aw_id_s;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_s;
	reg [7:0] aw_len_s;
	reg [2:0] aw_size_s;
	reg [1:0] aw_burst_s;
	reg aw_lock_s;
	reg [3:0] aw_cache_s;
	reg [2:0] aw_prot_s;
	reg [3:0] aw_qos_s;
	reg aw_valid_s;
	reg aw_ready_s;

	reg [C_S_AXI_ID_WIDTH-1:0] aw_id_m;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_m;
	reg [7:0] aw_len_m;
	reg [2:0] aw_size_m;
	reg [1:0] aw_burst_m;
	reg aw_lock_m;
	reg [3:0] aw_cache_m;
	reg [2:0] aw_prot_m;
	reg [3:0] aw_qos_m;
	reg aw_valid_m;
	reg aw_ready_m;

	// AW FIFO
	reg [FIFO_DEPTH-1:0] aw_fifo_valid;
	reg [FIFO_DEPTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] aw_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_count;

	// AW write side (S clock)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (aw_valid_s && aw_ready_s) begin
				aw_fifo_id[aw_wr_ptr] <= S_AXI_AWID;
				aw_fifo_addr[aw_wr_ptr] <= S_AXI_AWADDR;
				aw_fifo_len[aw_wr_ptr] <= S_AXI_AWLEN;
				aw_fifo_size[aw_wr_ptr] <= S_AXI_AWSIZE;
				aw_fifo_burst[aw_wr_ptr] <= S_AXI_AWBURST;
				aw_fifo_lock[aw_wr_ptr] <= S_AXI_AWLOCK;
				aw_fifo_cache[aw_wr_ptr] <= S_AXI_AWCACHE;
				aw_fifo_prot[aw_wr_ptr] <= S_AXI_AWPROT;
				aw_fifo_qos[aw_wr_ptr] <= S_AXI_AWQOS;
				aw_fifo_valid[aw_wr_ptr] <= 1'b1;
				aw_wr_ptr <= aw_wr_ptr + 1'b1;
				aw_count <= aw_count + 1'b1;
			end else if (aw_ready_m) begin
				aw_count <= aw_count - 1'b1;
			end
		end
	end

	// AW read side (M clock)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_valid_m <= 1'b0;
			aw_ready_m <= 1'b0;
		end else begin
			if (aw_valid_m && M_AXI_AWREADY) begin
				aw_fifo_valid[aw_rd_ptr] <= 1'b0;
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
				aw_valid_m <= 1'b0;
			end else if (!aw_valid_m && aw_fifo_valid[aw_rd_ptr]) begin
				aw_id_m <= aw_fifo_id[aw_rd_ptr];
				aw_addr_m <= aw_fifo_addr[aw_rd_ptr];
				aw_len_m <= aw_fifo_len[aw_rd_ptr];
				aw_size_m <= aw_fifo_size[aw_rd_ptr];
				aw_burst_m <= aw_fifo_burst[aw_rd_ptr];
				aw_lock_m <= aw_fifo_lock[aw_rd_ptr];
				aw_cache_m <= aw_fifo_cache[aw_rd_ptr];
				aw_prot_m <= aw_fifo_prot[aw_rd_ptr];
				aw_qos_m <= aw_fifo_qos[aw_rd_ptr];
				aw_valid_m <= 1'b1;
			end
		end
	end

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

	// AW ready back to S
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			aw_ready_s <= 1'b0;
		else
			aw_ready_s <= (aw_count < FIFO_DEPTH[FFS_STAGES-1:0]) ? 1'b1 : 1'b0;
	end
	assign S_AXI_AWREADY = aw_ready_s;

	// W Channel: S -> M
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_s;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s;
	reg w_last_s;
	reg w_valid_s;
	reg w_ready_s;

	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_m;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_m;
	reg w_last_m;
	reg w_valid_m;
	reg w_ready_m;

	// W FIFO
	reg [FIFO_DEPTH-1:0] w_fifo_valid;
	reg [FIFO_DEPTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] w_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] w_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] w_count;

	// W write side (S clock)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (w_valid_s && w_ready_s) begin
				w_fifo_data[w_wr_ptr] <= S_AXI_WDATA;
				w_fifo_strb[w_wr_ptr] <= S_AXI_WSTRB;
				w_fifo_last[w_wr_ptr] <= S_AXI_WLAST;
				w_fifo_valid[w_wr_ptr] <= 1'b1;
				w_wr_ptr <= w_wr_ptr + 1'b1;
				w_count <= w_count + 1'b1;
			end else if (w_ready_m) begin
				w_count <= w_count - 1'b1;
			end
		end
	end

	// W read side (M clock)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_valid_m <= 1'b0;
			w_ready_m <= 1'b0;
		end else begin
			if (w_valid_m && M_AXI_WREADY) begin
				w_fifo_valid[w_rd_ptr] <= 1'b0;
				w_rd_ptr <= w_rd_ptr + 1'b1;
				w_valid_m <= 1'b0;
			end else if (!w_valid_m && w_fifo_valid[w_rd_ptr]) begin
				w_data_m <= w_fifo_data[w_rd_ptr];
				w_strb_m <= w_fifo_strb[w_rd_ptr];
				w_last_m <= w_fifo_last[w_rd_ptr];
				w_valid_m <= 1'b1;
			end
		end
	end

	assign M_AXI_WDATA = w_data_m;
	assign M_AXI_WSTRB = w_strb_m;
	assign M_AXI_WLAST = w_last_m;
	assign M_AXI_WVALID = w_valid_m;

	// W ready back to S
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			w_ready_s <= 1'b0;
		else
			w_ready_s <= (w_count < FIFO_DEPTH[FFS_STAGES-1:0]) ? 1'b1 : 1'b0;
	end
	assign S_AXI_WREADY = w_ready_s;

	// B Channel: M -> S
	reg [C_S_AXI_ID_WIDTH-1:0] b_id_m;
	reg [1:0] b_resp_m;
	reg b_valid_m;
	reg b_ready_m;

	reg [C_S_AXI_ID_WIDTH-1:0] b_id_s;
	reg [1:0] b_resp_s;
	reg b_valid_s;
	reg b_ready_s;

	// B FIFO
	reg [FIFO_DEPTH-1:0] b_fifo_valid;
	reg [FIFO_DEPTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] b_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] b_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] b_count;

	// B write side (M clock)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (b_valid_m && b_ready_m) begin
				b_fifo_id[b_wr_ptr] <= M_AXI_BID;
				b_fifo_resp[b_wr_ptr] <= M_AXI_BRESP;
				b_fifo_valid[b_wr_ptr] <= 1'b1;
				b_wr_ptr <= b_wr_ptr + 1'b1;
				b_count <= b_count + 1'b1;
			end else if (b_ready_s) begin
				b_count <= b_count - 1'b1;
			end
		end
	end

	// B read side (S clock)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_valid_s <= 1'b0;
			b_ready_s <= 1'b0;
		end else begin
			if (b_valid_s && S_AXI_BREADY) begin
				b_fifo_valid[b_rd_ptr] <= 1'b0;
				b_rd_ptr <= b_rd_ptr + 1'b1;
				b_valid_s <= 1'b0;
			end else if (!b_valid_s && b_fifo_valid[b_rd_ptr]) begin
				b_id_s <= b_fifo_id[b_rd_ptr];
				b_resp_s <= b_fifo_resp[b_rd_ptr];
				b_valid_s <= 1'b1;
			end
		end
	end

	assign S_AXI_BID = b_id_s;
	assign S_AXI_BRESP = b_resp_s;
	assign S_AXI_BVALID = b_valid_s;

	// B ready back to M
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			b_ready_m <= 1'b0;
		else
			b_ready_m <= (b_count < FIFO_DEPTH[FFS_STAGES-1:0]) ? 1'b1 : 1'b0;
	end
	assign M_AXI_BREADY = b_ready_m;

	// AR Channel: S -> M
	reg [C_S_AXI_ID_WIDTH-1:0] ar_id_s;
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_s;
	reg [7:0] ar_len_s;
	reg [2:0] ar_size_s;
	reg [1:0] ar_burst_s;
	reg ar_lock_s;
	reg [3:0] ar_cache_s;
	reg [2:0] ar_prot_s;
	reg [3:0] ar_qos_s;
	reg ar_valid_s;
	reg ar_ready_s;

	reg [C_S_AXI_ID_WIDTH-1:0] ar_id_m;
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_addr_m;
	reg [7:0] ar_len_m;
	reg [2:0] ar_size_m;
	reg [1:0] ar_burst_m;
	reg ar_lock_m;
	reg [3:0] ar_cache_m;
	reg [2:0] ar_prot_m;
	reg [3:0] ar_qos_m;
	reg ar_valid_m;
	reg ar_ready_m;

	// AR FIFO
	reg [FIFO_DEPTH-1:0] ar_fifo_valid;
	reg [FIFO_DEPTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] ar_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] ar_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] ar_count;

	// AR write side (S clock)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (ar_valid_s && ar_ready_s) begin
				ar_fifo_id[ar_wr_ptr] <= S_AXI_ARID;
				ar_fifo_addr[ar_wr_ptr] <= S_AXI_ARADDR;
				ar_fifo_len[ar_wr_ptr] <= S_AXI_ARLEN;
				ar_fifo_size[ar_wr_ptr] <= S_AXI_ARSIZE;
				ar_fifo_burst[ar_wr_ptr] <= S_AXI_ARBURST;
				ar_fifo_lock[ar_wr_ptr] <= S_AXI_ARLOCK;
				ar_fifo_cache[ar_wr_ptr] <= S_AXI_ARCACHE;
				ar_fifo_prot[ar_wr_ptr] <= S_AXI_ARPROT;
				ar_fifo_qos[ar_wr_ptr] <= S_AXI_ARQOS;
				ar_fifo_valid[ar_wr_ptr] <= 1'b1;
				ar_wr_ptr <= ar_wr_ptr + 1'b1;
				ar_count <= ar_count + 1'b1;
			end else if (ar_ready_m) begin
				ar_count <= ar_count - 1'b1;
			end
		end
	end

	// AR read side (M clock)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_valid_m <= 1'b0;
			ar_ready_m <= 1'b0;
		end else begin
			if (ar_valid_m && M_AXI_ARREADY) begin
				ar_fifo_valid[ar_rd_ptr] <= 1'b0;
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
				ar_valid_m <= 1'b0;
			end else if (!ar_valid_m && ar_fifo_valid[ar_rd_ptr]) begin
				ar_id_m <= ar_fifo_id[ar_rd_ptr];
				ar_addr_m <= ar_fifo_addr[ar_rd_ptr];
				ar_len_m <= ar_fifo_len[ar_rd_ptr];
				ar_size_m <= ar_fifo_size[ar_rd_ptr];
				ar_burst_m <= ar_fifo_burst[ar_rd_ptr];
				ar_lock_m <= ar_fifo_lock[ar_rd_ptr];
				ar_cache_m <= ar_fifo_cache[ar_rd_ptr];
				ar_prot_m <= ar_fifo_prot[ar_rd_ptr];
				ar_qos_m <= ar_fifo_qos[ar_rd_ptr];
				ar_valid_m <= 1'b1;
			end
		end
	end

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

	// AR ready back to S
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			ar_ready_s <= 1'b0;
		else
			ar_ready_s <= (ar_count < FIFO_DEPTH[FFS_STAGES-1:0]) ? 1'b1 : 1'b0;
	end
	assign S_AXI_ARREADY = ar_ready_s;

	// R Channel: M -> S
	reg [C_S_AXI_ID_WIDTH-1:0] r_id_m;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_data_m;
	reg [1:0] r_resp_m;
	reg r_last_m;
	reg r_valid_m;
	reg r_ready_m;

	reg [C_S_AXI_ID_WIDTH-1:0] r_id_s;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_data_s;
	reg [1:0] r_resp_s;
	reg r_last_s;
	reg r_valid_s;
	reg r_ready_s;

	// R FIFO
	reg [FIFO_DEPTH-1:0] r_fifo_valid;
	reg [FIFO_DEPTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_DEPTH-1:0] r_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] r_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] r_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] r_count;

	// R write side (M clock)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			if (r_valid_m && r_ready_m) begin
				r_fifo_id[r_wr_ptr] <= M_AXI_RID;
				r_fifo_data[r_wr_ptr] <= M_AXI_RDATA;
				r_fifo_resp[r_wr_ptr] <= M_AXI_RRESP;
				r_fifo_last[r_wr_ptr] <= M_AXI_RLAST;
				r_fifo_valid[r_wr_ptr] <= 1'b1;
				r_wr_ptr <= r_wr_ptr + 1'b1;
				r_count <= r_count + 1'b1;
			end else if (r_ready_s) begin
				r_count <= r_count - 1'b1;
			end
		end
	end

	// R read side (S clock)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_valid_s <= 1'b0;
			r_ready_s <= 1'b0;
		end else begin
			if (r_valid_s && S_AXI_RREADY) begin
				r_fifo_valid[r_rd_ptr] <= 1'b0;
				r_rd_ptr <= r_rd_ptr + 1'b1;
				r_valid_s <= 1'b0;
			end else if (!r_valid_s && r_fifo_valid[r_rd_ptr]) begin
				r_id_s <= r_fifo_id[r_rd_ptr];
				r_data_s <= r_fifo_data[r_rd_ptr];
				r_resp_s <= r_fifo_resp[r_rd_ptr];
				r_last_s <= r_fifo_last[r_rd_ptr];
				r_valid_s <= 1'b1;
			end
		end
	end

	assign S_AXI_RID = r_id_s;
	assign S_AXI_RDATA = r_data_s;
	assign S_AXI_RRESP = r_resp_s;
	assign S_AXI_RLAST = r_last_s;
	assign S_AXI_RVALID = r_valid_s;

	// R ready back to M
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			r_ready_m <= 1'b0;
		else
			r_ready_m <= (r_count < FIFO_DEPTH[FFS_STAGES-1:0]) ? 1'b1 : 1'b0;
	end
	assign M_AXI_RREADY = r_ready_m;

	// Input valid signals (directly from S ports)
	assign aw_valid_s = S_AXI_AWVALID;
	assign w_valid_s = S_AXI_WVALID;
	assign ar_valid_s = S_AXI_ARVALID;

	// Output valid signals (directly to M ports)
	// Already assigned above

endmodule
