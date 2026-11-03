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
	// S-domain: capture AW when valid and ready
	reg aw_valid_s;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_id_s;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_s;
	reg [7:0] aw_len_s;
	reg [2:0] aw_size_s;
	reg [1:0] aw_burst_s;
	reg aw_lock_s;
	reg [3:0] aw_cache_s;
	reg [2:0] aw_prot_s;
	reg [3:0] aw_qos_s;

	// FIFO for AW channel
	reg [FIFO_DEPTH-1:0] aw_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_rd_ptr;

	// AW FIFO full/empty
	wire aw_fifo_full = (aw_fifo_wr_ptr == aw_fifo_rd_ptr) && aw_fifo_valid[aw_fifo_wr_ptr];
	wire aw_fifo_empty = !aw_fifo_valid[aw_fifo_rd_ptr];

	// S-domain: accept AW
	assign S_AXI_AWREADY = !aw_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_valid_s <= 1'b0;
			aw_fifo_valid <= {FIFO_DEPTH{1'b0}};
			aw_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				aw_fifo_valid[aw_fifo_wr_ptr] <= 1'b1;
				aw_fifo_id[aw_fifo_wr_ptr] <= S_AXI_AWID;
				aw_fifo_addr[aw_fifo_wr_ptr] <= S_AXI_AWADDR;
				aw_fifo_len[aw_fifo_wr_ptr] <= S_AXI_AWLEN;
				aw_fifo_size[aw_fifo_wr_ptr] <= S_AXI_AWSIZE;
				aw_fifo_burst[aw_fifo_wr_ptr] <= S_AXI_AWBURST;
				aw_fifo_lock[aw_fifo_wr_ptr] <= S_AXI_AWLOCK;
				aw_fifo_cache[aw_fifo_wr_ptr] <= S_AXI_AWCACHE;
				aw_fifo_prot[aw_fifo_wr_ptr] <= S_AXI_AWPROT;
				aw_fifo_qos[aw_fifo_wr_ptr] <= S_AXI_AWQOS;
				aw_fifo_wr_ptr <= aw_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// M-domain: read AW from FIFO
	reg [FIFO_ADDR_WIDTH-1:0] aw_fifo_rd_ptr_m;
	reg aw_m_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_m_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_m_addr;
	reg [7:0] aw_m_len;
	reg [2:0] aw_m_size;
	reg [1:0] aw_m_burst;
	reg aw_m_lock;
	reg [3:0] aw_m_cache;
	reg [2:0] aw_m_prot;
	reg [3:0] aw_m_qos;

	// Synchronize rd_ptr back to S-domain
	reg [FFS_STAGES-1:0] aw_rd_ptr_sync_s;
	wire [FIFO_ADDR_WIDTH-1:0] aw_rd_ptr_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			aw_rd_ptr_sync_s <= {FFS_STAGES{1'b0}};
		else
			aw_rd_ptr_sync_s <= {aw_rd_ptr_sync_s[FFS_STAGES-2:0], aw_fifo_rd_ptr_m};
	end

	assign aw_rd_ptr_s = aw_rd_ptr_sync_s[FFS_STAGES-1];

	// M-domain: process AW FIFO
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_rd_ptr_m <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_m_valid <= 1'b0;
		end else begin
			if (aw_m_valid && M_AXI_AWREADY) begin
				aw_m_valid <= 1'b0;
			end
			if (!aw_m_valid && !aw_fifo_empty) begin
				aw_m_valid <= 1'b1;
				aw_m_id <= aw_fifo_id[aw_fifo_rd_ptr_m];
				aw_m_addr <= aw_fifo_addr[aw_fifo_rd_ptr_m];
				aw_m_len <= aw_fifo_len[aw_fifo_rd_ptr_m];
				aw_m_size <= aw_fifo_size[aw_fifo_rd_ptr_m];
				aw_m_burst <= aw_fifo_burst[aw_fifo_rd_ptr_m];
				aw_m_lock <= aw_fifo_lock[aw_fifo_rd_ptr_m];
				aw_m_cache <= aw_fifo_cache[aw_fifo_rd_ptr_m];
				aw_m_prot <= aw_fifo_prot[aw_fifo_rd_ptr_m];
				aw_m_qos <= aw_fifo_qos[aw_fifo_rd_ptr_m];
				aw_fifo_rd_ptr_m <= aw_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	// Clear FIFO valid bit in M-domain when read
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled above
		end else begin
			if (!aw_m_valid && !aw_fifo_empty) begin
				aw_fifo_valid[aw_fifo_rd_ptr_m] <= 1'b0;
			end
		end
	end

	assign M_AXI_AWVALID = aw_m_valid;
	assign M_AXI_AWID = aw_m_id;
	assign M_AXI_AWADDR = aw_m_addr;
	assign M_AXI_AWLEN = aw_m_len;
	assign M_AXI_AWSIZE = aw_m_size;
	assign M_AXI_AWBURST = aw_m_burst;
	assign M_AXI_AWLOCK = aw_m_lock;
	assign M_AXI_AWCACHE = aw_m_cache;
	assign M_AXI_AWPROT = aw_m_prot;
	assign M_AXI_AWQOS = aw_m_qos;

	// ============================================================
	// W Channel: S -> M
	// ============================================================
	// S-domain: capture W when valid and ready
	// W channel is independent of AW, but we need to track burst context
	// For simplicity, we buffer W beats in a FIFO

	reg [FIFO_DEPTH-1:0] w_fifo_valid;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] w_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] w_fifo_rd_ptr;

	wire w_fifo_full = (w_fifo_wr_ptr == w_fifo_rd_ptr) && w_fifo_valid[w_fifo_wr_ptr];
	wire w_fifo_empty = !w_fifo_valid[w_fifo_rd_ptr];

	assign S_AXI_WREADY = !w_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_valid <= {FIFO_DEPTH{1'b0}};
			w_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_fifo_valid[w_fifo_wr_ptr] <= 1'b1;
				w_fifo_data[w_fifo_wr_ptr] <= S_AXI_WDATA;
				w_fifo_strb[w_fifo_wr_ptr] <= S_AXI_WSTRB;
				w_fifo_last[w_fifo_wr_ptr] <= S_AXI_WLAST;
				w_fifo_wr_ptr <= w_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// M-domain: read W from FIFO
	reg [FIFO_ADDR_WIDTH-1:0] w_fifo_rd_ptr_m;
	reg w_m_valid;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_m_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_m_strb;
	reg w_m_last;

	// Synchronize rd_ptr back to S-domain
	reg [FFS_STAGES-1:0] w_rd_ptr_sync_s;
	wire [FIFO_ADDR_WIDTH-1:0] w_rd_ptr_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			w_rd_ptr_sync_s <= {FFS_STAGES{1'b0}};
		else
			w_rd_ptr_sync_s <= {w_rd_ptr_sync_s[FFS_STAGES-2:0], w_fifo_rd_ptr_m};
	end

	assign w_rd_ptr_s = w_rd_ptr_sync_s[FFS_STAGES-1];

	// M-domain: process W FIFO
	// "Master write data is held one extra M_AXI clock before M_AXI_WVALID"
	reg w_m_valid_next;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_rd_ptr_m <= {FIFO_ADDR_WIDTH{1'b0}};
			w_m_valid <= 1'b0;
			w_m_valid_next <= 1'b0;
		end else begin
			// Hold one extra clock: w_m_valid_next becomes w_m_valid
			w_m_valid <= w_m_valid_next;

			if (w_m_valid && M_AXI_WREADY) begin
				w_m_valid_next <= 1'b0;
			end
			if (!w_m_valid_next && !w_fifo_empty) begin
				w_m_valid_next <= 1'b1;
				w_m_data <= w_fifo_data[w_fifo_rd_ptr_m];
				w_m_strb <= w_fifo_strb[w_fifo_rd_ptr_m];
				w_m_last <= w_fifo_last[w_fifo_rd_ptr_m];
				w_fifo_rd_ptr_m <= w_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	// Clear FIFO valid bit in M-domain when read
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled above
		end else begin
			if (!w_m_valid_next && !w_fifo_empty) begin
				w_fifo_valid[w_fifo_rd_ptr_m] <= 1'b0;
			end
		end
	end

	assign M_AXI_WVALID = w_m_valid;
	assign M_AXI_WDATA = w_m_data;
	assign M_AXI_WSTRB = w_m_strb;
	assign M_AXI_WLAST = w_m_last;

	// ============================================================
	// B Channel: M -> S
	// ============================================================
	// M-domain: capture B when valid and ready
	reg b_valid_m;
	reg [C_S_AXI_ID_WIDTH-1:0] b_id_m;
	reg [1:0] b_resp_m;

	// FIFO for B channel
	reg [FIFO_DEPTH-1:0] b_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] b_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] b_fifo_rd_ptr;

	wire b_fifo_full = (b_fifo_wr_ptr == b_fifo_rd_ptr) && b_fifo_valid[b_fifo_wr_ptr];
	wire b_fifo_empty = !b_fifo_valid[b_fifo_rd_ptr];

	assign M_AXI_BREADY = !b_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_valid <= {FIFO_DEPTH{1'b0}};
			b_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_fifo_valid[b_fifo_wr_ptr] <= 1'b1;
				b_fifo_id[b_fifo_wr_ptr] <= M_AXI_BID;
				b_fifo_resp[b_fifo_wr_ptr] <= M_AXI_BRESP;
				b_fifo_wr_ptr <= b_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// S-domain: read B from FIFO
	reg [FIFO_ADDR_WIDTH-1:0] b_fifo_rd_ptr_s;
	reg b_s_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] b_s_id;
	reg [1:0] b_s_resp;

	// Synchronize rd_ptr back to M-domain
	reg [FFS_STAGES-1:0] b_rd_ptr_sync_m;
	wire [FIFO_ADDR_WIDTH-1:0] b_rd_ptr_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			b_rd_ptr_sync_m <= {FFS_STAGES{1'b0}};
		else
			b_rd_ptr_sync_m <= {b_rd_ptr_sync_m[FFS_STAGES-2:0], b_fifo_rd_ptr_s};
	end

	assign b_rd_ptr_m = b_rd_ptr_sync_m[FFS_STAGES-1];

	// S-domain: process B FIFO
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_rd_ptr_s <= {FIFO_ADDR_WIDTH{1'b0}};
			b_s_valid <= 1'b0;
		end else begin
			if (b_s_valid && S_AXI_BREADY) begin
				b_s_valid <= 1'b0;
			end
			if (!b_s_valid && !b_fifo_empty) begin
				b_s_valid <= 1'b1;
				b_s_id <= b_fifo_id[b_fifo_rd_ptr_s];
				b_s_resp <= b_fifo_resp[b_fifo_rd_ptr_s];
				b_fifo_rd_ptr_s <= b_fifo_rd_ptr_s + 1'b1;
			end
		end
	end

	// Clear FIFO valid bit in S-domain when read
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// handled above
		end else begin
			if (!b_s_valid && !b_fifo_empty) begin
				b_fifo_valid[b_fifo_rd_ptr_s] <= 1'b0;
			end
		end
	end

	assign S_AXI_BVALID = b_s_valid;
	assign S_AXI_BID = b_s_id;
	assign S_AXI_BRESP = b_s_resp;

	// ============================================================
	// AR Channel: S -> M
	// ============================================================
	// S-domain: capture AR when valid and ready
	reg [FIFO_DEPTH-1:0] ar_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] ar_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] ar_fifo_rd_ptr;

	wire ar_fifo_full = (ar_fifo_wr_ptr == ar_fifo_rd_ptr) && ar_fifo_valid[ar_fifo_wr_ptr];
	wire ar_fifo_empty = !ar_fifo_valid[ar_fifo_rd_ptr];

	assign S_AXI_ARREADY = !ar_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_valid <= {FIFO_DEPTH{1'b0}};
			ar_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				ar_fifo_valid[ar_fifo_wr_ptr] <= 1'b1;
				ar_fifo_id[ar_fifo_wr_ptr] <= S_AXI_ARID;
				ar_fifo_addr[ar_fifo_wr_ptr] <= S_AXI_ARADDR;
				ar_fifo_len[ar_fifo_wr_ptr] <= S_AXI_ARLEN;
				ar_fifo_size[ar_fifo_wr_ptr] <= S_AXI_ARSIZE;
				ar_fifo_burst[ar_fifo_wr_ptr] <= S_AXI_ARBURST;
				ar_fifo_lock[ar_fifo_wr_ptr] <= S_AXI_ARLOCK;
				ar_fifo_cache[ar_fifo_wr_ptr] <= S_AXI_ARCACHE;
				ar_fifo_prot[ar_fifo_wr_ptr] <= S_AXI_ARPROT;
				ar_fifo_qos[ar_fifo_wr_ptr] <= S_AXI_ARQOS;
				ar_fifo_wr_ptr <= ar_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// M-domain: read AR from FIFO
	reg [FIFO_ADDR_WIDTH-1:0] ar_fifo_rd_ptr_m;
	reg ar_m_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_m_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_m_addr;
	reg [7:0] ar_m_len;
	reg [2:0] ar_m_size;
	reg [1:0] ar_m_burst;
	reg ar_m_lock;
	reg [3:0] ar_m_cache;
	reg [2:0] ar_m_prot;
	reg [3:0] ar_m_qos;

	// Synchronize rd_ptr back to S-domain
	reg [FFS_STAGES-1:0] ar_rd_ptr_sync_s;
	wire [FIFO_ADDR_WIDTH-1:0] ar_rd_ptr_s;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			ar_rd_ptr_sync_s <= {FFS_STAGES{1'b0}};
		else
			ar_rd_ptr_sync_s <= {ar_rd_ptr_sync_s[FFS_STAGES-2:0], ar_fifo_rd_ptr_m};
	end

	assign ar_rd_ptr_s = ar_rd_ptr_sync_s[FFS_STAGES-1];

	// M-domain: process AR FIFO
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_rd_ptr_m <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_m_valid <= 1'b0;
		end else begin
			if (ar_m_valid && M_AXI_ARREADY) begin
				ar_m_valid <= 1'b0;
			end
			if (!ar_m_valid && !ar_fifo_empty) begin
				ar_m_valid <= 1'b1;
				ar_m_id <= ar_fifo_id[ar_fifo_rd_ptr_m];
				ar_m_addr <= ar_fifo_addr[ar_fifo_rd_ptr_m];
				ar_m_len <= ar_fifo_len[ar_fifo_rd_ptr_m];
				ar_m_size <= ar_fifo_size[ar_fifo_rd_ptr_m];
				ar_m_burst <= ar_fifo_burst[ar_fifo_rd_ptr_m];
				ar_m_lock <= ar_fifo_lock[ar_fifo_rd_ptr_m];
				ar_m_cache <= ar_fifo_cache[ar_fifo_rd_ptr_m];
				ar_m_prot <= ar_fifo_prot[ar_fifo_rd_ptr_m];
				ar_m_qos <= ar_fifo_qos[ar_fifo_rd_ptr_m];
				ar_fifo_rd_ptr_m <= ar_fifo_rd_ptr_m + 1'b1;
			end
		end
	end

	// Clear FIFO valid bit in M-domain when read
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled above
		end else begin
			if (!ar_m_valid && !ar_fifo_empty) begin
				ar_fifo_valid[ar_fifo_rd_ptr_m] <= 1'b0;
			end
		end
	end

	assign M_AXI_ARVALID = ar_m_valid;
	assign M_AXI_ARID = ar_m_id;
	assign M_AXI_ARADDR = ar_m_addr;
	assign M_AXI_ARLEN = ar_m_len;
	assign M_AXI_ARSIZE = ar_m_size;
	assign M_AXI_ARBURST = ar_m_burst;
	assign M_AXI_ARLOCK = ar_m_lock;
	assign M_AXI_ARCACHE = ar_m_cache;
	assign M_AXI_ARPROT = ar_m_prot;
	assign M_AXI_ARQOS = ar_m_qos;

	// ============================================================
	// R Channel: M -> S
	// ============================================================
	// M-domain: capture R when valid and ready
	reg [FIFO_DEPTH-1:0] r_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg r_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] r_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] r_fifo_rd_ptr;

	wire r_fifo_full = (r_fifo_wr_ptr == r_fifo_rd_ptr) && r_fifo_valid[r_fifo_wr_ptr];
	wire r_fifo_empty = !r_fifo_valid[r_fifo_rd_ptr];

	assign M_AXI_RREADY = !r_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_fifo_valid <= {FIFO_DEPTH{1'b0}};
			r_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				r_fifo_valid[r_fifo_wr_ptr] <= 1'b1;
				r_fifo_id[r_fifo_wr_ptr] <= M_AXI_RID;
				r_fifo_data[r_fifo_wr_ptr] <= M_AXI_RDATA;
				r_fifo_resp[r_fifo_wr_ptr] <= M_AXI_RRESP;
				r_fifo_last[r_fifo_wr_ptr] <= M_AXI_RLAST;
				r_fifo_wr_ptr <= r_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// S-domain: read R from FIFO
	reg [FIFO_ADDR_WIDTH-1:0] r_fifo_rd_ptr_s;
	reg r_s_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] r_s_id;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_s_data;
	reg [1:0] r_s_resp;
	reg r_s_last;

	// Synchronize rd_ptr back to M-domain
	reg [FFS_STAGES-1:0] r_rd_ptr_sync_m;
	wire [FIFO_ADDR_WIDTH-1:0] r_rd_ptr_m;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			r_rd_ptr_sync_m <= {FFS_STAGES{1'b0}};
		else
			r_rd_ptr_sync_m <= {r_rd_ptr_sync_m[FFS_STAGES-2:0], r_fifo_rd_ptr_s};
	end

	assign r_rd_ptr_m = r_rd_ptr_sync_m[FFS_STAGES-1];

	// S-domain: process R FIFO
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_fifo_rd_ptr_s <= {FIFO_ADDR_WIDTH{1'b0}};
			r_s_valid <= 1'b0;
		end else begin
			if (r_s_valid && S_AXI_RREADY) begin
				r_s_valid <= 1'b0;
			end
			if (!r_s_valid && !r_fifo_empty) begin
				r_s_valid <= 1'b1;
				r_s_id <= r_fifo_id[r_fifo_rd_ptr_s];
				r_s_data <= r_fifo_data[r_fifo_rd_ptr_s];
				r_s_resp <= r_fifo_resp[r_fifo_rd_ptr_s];
				r_s_last <= r_fifo_last[r_fifo_rd_ptr_s];
				r_fifo_rd_ptr_s <= r_fifo_rd_ptr_s + 1'b1;
			end
		end
	end

	// Clear FIFO valid bit in S-domain when read
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// handled above
		end else begin
			if (!r_s_valid && !r_fifo_empty) begin
				r_fifo_valid[r_fifo_rd_ptr_s] <= 1'b0;
			end
		end
	end

	assign S_AXI_RVALID = r_s_valid;
	assign S_AXI_RID = r_s_id;
	assign S_AXI_RDATA = r_s_data;
	assign S_AXI_RRESP = r_s_resp;
	assign S_AXI_RLAST = r_s_last;

endmodule
