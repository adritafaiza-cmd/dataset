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

	// Synchronous reset for M domain
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

	// ============================================================
	// AW Channel: S -> M
	// ============================================================
	// S-domain: capture AW when valid and not full
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

	// FIFO for AW
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg aw_fifo_valid [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr_s;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_m;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_s;

	// Write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr_s <= 0;
			aw_valid_s <= 0;
		end else begin
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				aw_wr_ptr_s <= aw_wr_ptr_s + 1;
				aw_valid_s <= 1;
			end else if (aw_wr_ptr_s != aw_rd_ptr_s) begin
				aw_valid_s <= 1;
			end else begin
				aw_valid_s <= 0;
			end
		end
	end

	// Store AW data in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_id_s <= 0;
			aw_addr_s <= 0;
			aw_len_s <= 0;
			aw_size_s <= 0;
			aw_burst_s <= 0;
			aw_lock_s <= 0;
			aw_cache_s <= 0;
			aw_prot_s <= 0;
			aw_qos_s <= 0;
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			aw_id_s <= S_AXI_AWID;
			aw_addr_s <= S_AXI_AWADDR;
			aw_len_s <= S_AXI_AWLEN;
			aw_size_s <= S_AXI_AWSIZE;
			aw_burst_s <= S_AXI_AWBURST;
			aw_lock_s <= S_AXI_AWLOCK;
			aw_cache_s <= S_AXI_AWCACHE;
			aw_prot_s <= S_AXI_AWPROT;
			aw_qos_s <= S_AXI_AWQOS;
		end
	end

	// Write to FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_valid[0] <= 0;
		end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
			aw_fifo_id[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_id_s;
			aw_fifo_addr[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_addr_s;
			aw_fifo_len[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_len_s;
			aw_fifo_size[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_size_s;
			aw_fifo_burst[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_burst_s;
			aw_fifo_lock[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_lock_s;
			aw_fifo_cache[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_cache_s;
			aw_fifo_prot[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_prot_s;
			aw_fifo_qos[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= aw_qos_s;
			aw_fifo_valid[aw_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= 1;
		end
	end

	// S_AXI_AWREADY: not full
	assign S_AXI_AWREADY = (aw_wr_ptr_s != aw_rd_ptr_s);

	// M-domain: read from FIFO
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

	// Read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_rd_ptr_m <= 0;
			aw_valid_m <= 0;
		end else begin
			if (M_AXI_AWREADY && aw_valid_m) begin
				aw_rd_ptr_m <= aw_rd_ptr_m + 1;
				aw_valid_m <= 0;
			end else if (aw_rd_ptr_m != aw_rd_ptr_s) begin
				aw_valid_m <= 1;
			end else begin
				aw_valid_m <= 0;
			end
		end
	end

	// Read data from FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_id_m <= 0;
			aw_addr_m <= 0;
			aw_len_m <= 0;
			aw_size_m <= 0;
			aw_burst_m <= 0;
			aw_lock_m <= 0;
			aw_cache_m <= 0;
			aw_prot_m <= 0;
			aw_qos_m <= 0;
		end else if (M_AXI_AWREADY && aw_valid_m) begin
			aw_id_m <= aw_fifo_id[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_addr_m <= aw_fifo_addr[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_len_m <= aw_fifo_len[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_size_m <= aw_fifo_size[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_burst_m <= aw_fifo_burst[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_lock_m <= aw_fifo_lock[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_cache_m <= aw_fifo_cache[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_prot_m <= aw_fifo_prot[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			aw_qos_m <= aw_fifo_qos[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
		end
	end

	// Synchronize read pointer to S domain
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr_s_sync [0:FFS_STAGES-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_rd_ptr_s_sync[0] <= 0;
			aw_rd_ptr_s <= 0;
		end else begin
			aw_rd_ptr_s_sync[0] <= aw_rd_ptr_m;
			for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
				aw_rd_ptr_s_sync[i] <= aw_rd_ptr_s_sync[i-1];
			end
			aw_rd_ptr_s <= aw_rd_ptr_s_sync[FFS_STAGES-1];
		end
	end

	// M_AXI_AW outputs
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

	// ============================================================
	// W Channel: S -> M
	// ============================================================
	// S-domain: capture W when valid and not full
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_s;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_s;
	reg w_last_s;
	reg w_valid_s;

	// FIFO for W
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg w_fifo_valid [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH:0] w_wr_ptr_s;
	reg [FIFO_ADDR_WIDTH:0] w_rd_ptr_m;
	reg [FIFO_ADDR_WIDTH:0] w_rd_ptr_s;

	// Write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr_s <= 0;
			w_valid_s <= 0;
		end else begin
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_wr_ptr_s <= w_wr_ptr_s + 1;
				w_valid_s <= 1;
			end else if (w_wr_ptr_s != w_rd_ptr_s) begin
				w_valid_s <= 1;
			end else begin
				w_valid_s <= 0;
			end
		end
	end

	// Store W data in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_data_s <= 0;
			w_strb_s <= 0;
			w_last_s <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			w_data_s <= S_AXI_WDATA;
			w_strb_s <= S_AXI_WSTRB;
			w_last_s <= S_AXI_WLAST;
		end
	end

	// Write to FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_valid[0] <= 0;
		end else if (S_AXI_WVALID && S_AXI_WREADY) begin
			w_fifo_data[w_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= w_data_s;
			w_fifo_strb[w_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= w_strb_s;
			w_fifo_last[w_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= w_last_s;
			w_fifo_valid[w_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= 1;
		end
	end

	// S_AXI_WREADY: not full
	assign S_AXI_WREADY = (w_wr_ptr_s != w_rd_ptr_s);

	// M-domain: read from FIFO
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_m;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_m;
	reg w_last_m;
	reg w_valid_m;

	// Read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_rd_ptr_m <= 0;
			w_valid_m <= 0;
		end else begin
			if (M_AXI_WREADY && w_valid_m) begin
				w_rd_ptr_m <= w_rd_ptr_m + 1;
				w_valid_m <= 0;
			end else if (w_rd_ptr_m != w_rd_ptr_s) begin
				w_valid_m <= 1;
			end else begin
				w_valid_m <= 0;
			end
		end
	end

	// Read data from FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_data_m <= 0;
			w_strb_m <= 0;
			w_last_m <= 0;
		end else if (M_AXI_WREADY && w_valid_m) begin
			w_data_m <= w_fifo_data[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			w_strb_m <= w_fifo_strb[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			w_last_m <= w_fifo_last[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
		end
	end

	// Synchronize read pointer to S domain
	reg [FIFO_ADDR_WIDTH:0] w_rd_ptr_s_sync [0:FFS_STAGES-1];
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_rd_ptr_s_sync[0] <= 0;
			w_rd_ptr_s <= 0;
		end else begin
			w_rd_ptr_s_sync[0] <= w_rd_ptr_m;
			for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
				w_rd_ptr_s_sync[i] <= w_rd_ptr_s_sync[i-1];
			end
			w_rd_ptr_s <= w_rd_ptr_s_sync[FFS_STAGES-1];
		end
	end

	// M_AXI_W outputs - hold one extra M_AXI clock before M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1:0] w_data_out;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_out;
	reg w_last_out;
	reg w_valid_out;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_data_out <= 0;
			w_strb_out <= 0;
			w_last_out <= 0;
			w_valid_out <= 0;
		end else begin
			w_data_out <= w_data_m;
			w_strb_out <= w_strb_m;
			w_last_out <= w_last_m;
			w_valid_out <= w_valid_m;
		end
	end

	assign M_AXI_WDATA = w_data_out;
	assign M_AXI_WSTRB = w_strb_out;
	assign M_AXI_WLAST = w_last_out;
	assign M_AXI_WVALID = w_valid_out;

	// ============================================================
	// B Channel: M -> S
	// ============================================================
	// M-domain: capture B when valid and not full
	reg [C_S_AXI_ID_WIDTH-1:0] b_id_m;
	reg [1:0] b_resp_m;
	reg b_valid_m;

	// FIFO for B
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg b_fifo_valid [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH:0] b_wr_ptr_m;
	reg [FIFO_ADDR_WIDTH:0] b_rd_ptr_s;
	reg [FIFO_ADDR_WIDTH:0] b_rd_ptr_m;

	// Write pointer in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_wr_ptr_m <= 0;
			b_valid_m <= 0;
		end else begin
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_wr_ptr_m <= b_wr_ptr_m + 1;
				b_valid_m <= 1;
			end else if (b_wr_ptr_m != b_rd_ptr_m) begin
				b_valid_m <= 1;
			end else begin
				b_valid_m <= 0;
			end
		end
	end

	// Store B data in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_id_m <= 0;
			b_resp_m <= 0;
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			b_id_m <= M_AXI_BID;
			b_resp_m <= M_AXI_BRESP;
		end
	end

	// Write to FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_fifo_valid[0] <= 0;
		end else if (M_AXI_BVALID && M_AXI_BREADY) begin
			b_fifo_id[b_wr_ptr_m[FIFO_ADDR_WIDTH-1:0]] <= b_id_m;
			b_fifo_resp[b_wr_ptr_m[FIFO_ADDR_WIDTH-1:0]] <= b_resp_m;
			b_fifo_valid[b_wr_ptr_m[FIFO_ADDR_WIDTH-1:0]] <= 1;
		end
	end

	// M_AXI_BREADY: not full
	assign M_AXI_BREADY = (b_wr_ptr_m != b_rd_ptr_m);

	// S-domain: read from FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] b_id_s;
	reg [1:0] b_resp_s;
	reg b_valid_s;

	// Read pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr_s <= 0;
			b_valid_s <= 0;
		end else begin
			if (S_AXI_BREADY && b_valid_s) begin
				b_rd_ptr_s <= b_rd_ptr_s + 1;
				b_valid_s <= 0;
			end else if (b_rd_ptr_s != b_wr_ptr_m) begin
				b_valid_s <= 1;
			end else begin
				b_valid_s <= 0;
			end
		end
	end

	// Read data from FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_id_s <= 0;
			b_resp_s <= 0;
		end else if (S_AXI_BREADY && b_valid_s) begin
			b_id_s <= b_fifo_id[b_rd_ptr_s[FIFO_ADDR_WIDTH-1:0]];
			b_resp_s <= b_fifo_resp[b_rd_ptr_s[FIFO_ADDR_WIDTH-1:0]];
		end
	end

	// Synchronize read pointer to M domain
	reg [FIFO_ADDR_WIDTH:0] b_rd_ptr_m_sync [0:FFS_STAGES-1];
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_rd_ptr_m_sync[0] <= 0;
			b_rd_ptr_m <= 0;
		end else begin
			b_rd_ptr_m_sync[0] <= b_rd_ptr_s;
			for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
				b_rd_ptr_m_sync[i] <= b_rd_ptr_m_sync[i-1];
			end
			b_rd_ptr_m <= b_rd_ptr_m_sync[FFS_STAGES-1];
		end
	end

	// S_AXI_B outputs
	assign S_AXI_BID = b_id_s;
	assign S_AXI_BRESP = b_resp_s;
	assign S_AXI_BVALID = b_valid_s;

	// ============================================================
	// AR Channel: S -> M
	// ============================================================
	// S-domain: capture AR when valid and not full
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

	// FIFO for AR
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg ar_fifo_valid [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH:0] ar_wr_ptr_s;
	reg [FIFO_ADDR_WIDTH:0] ar_rd_ptr_m;
	reg [FIFO_ADDR_WIDTH:0] ar_rd_ptr_s;

	// Write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr_s <= 0;
			ar_valid_s <= 0;
		end else begin
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				ar_wr_ptr_s <= ar_wr_ptr_s + 1;
				ar_valid_s <= 1;
			end else if (ar_wr_ptr_s != ar_rd_ptr_s) begin
				ar_valid_s <= 1;
			end else begin
				ar_valid_s <= 0;
			end
		end
	end

	// Store AR data in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_id_s <= 0;
			ar_addr_s <= 0;
			ar_len_s <= 0;
			ar_size_s <= 0;
			ar_burst_s <= 0;
			ar_lock_s <= 0;
			ar_cache_s <= 0;
			ar_prot_s <= 0;
			ar_qos_s <= 0;
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			ar_id_s <= S_AXI_ARID;
			ar_addr_s <= S_AXI_ARADDR;
			ar_len_s <= S_AXI_ARLEN;
			ar_size_s <= S_AXI_ARSIZE;
			ar_burst_s <= S_AXI_ARBURST;
			ar_lock_s <= S_AXI_ARLOCK;
			ar_cache_s <= S_AXI_ARCACHE;
			ar_prot_s <= S_AXI_ARPROT;
			ar_qos_s <= S_AXI_ARQOS;
		end
	end

	// Write to FIFO in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_valid[0] <= 0;
		end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
			ar_fifo_id[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_id_s;
			ar_fifo_addr[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_addr_s;
			ar_fifo_len[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_len_s;
			ar_fifo_size[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_size_s;
			ar_fifo_burst[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_burst_s;
			ar_fifo_lock[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_lock_s;
			ar_fifo_cache[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_cache_s;
			ar_fifo_prot[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_prot_s;
			ar_fifo_qos[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= ar_qos_s;
			ar_fifo_valid[ar_wr_ptr_s[FIFO_ADDR_WIDTH-1:0]] <= 1;
		end
	end

	// S_AXI_ARREADY: not full
	assign S_AXI_ARREADY = (ar_wr_ptr_s != ar_rd_ptr_s);

	// M-domain: read from FIFO
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

	// Read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_rd_ptr_m <= 0;
			ar_valid_m <= 0;
		end else begin
			if (M_AXI_ARREADY && ar_valid_m) begin
				ar_rd_ptr_m <= ar_rd_ptr_m + 1;
				ar_valid_m <= 0;
			end else if (ar_rd_ptr_m != ar_rd_ptr_s) begin
				ar_valid_m <= 1;
			end else begin
				ar_valid_m <= 0;
			end
		end
	end

	// Read data from FIFO in M domain
	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_id_m <= 0;
			ar_addr_m <= 0;
			ar_len_m <= 0;
			ar_size_m <= 0;
			ar_burst_m <= 0;
			ar_lock_m <= 0;
			ar_cache_m <= 0;
			ar_prot_m <= 0;
			ar_qos_m <= 0;
		end else if (M_AXI_ARREADY && ar_valid_m) begin
			ar_id_m <= ar_fifo_id[ar_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			ar_addr_m <= ar_fifo_addr[ar_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			ar_len_m <= ar_fifo_len[ar_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			ar_size_m <= ar_fifo_size[ar_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			ar_burst_m <= ar_fifo_burst[ar_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
			ar_lock