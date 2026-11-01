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

	// Reset synchronization for M_AXI domain
	reg [FFS_STAGES-1:0] m_reset_sync;
	wire m_reset_n;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
	end

	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// AW Channel: S -> M
	// FIFO in S domain, read in M domain
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_rd_ptr;
	reg aw_wr_en;
	reg aw_rd_en;
	wire aw_empty;
	wire aw_full;

	assign aw_empty = (aw_wr_ptr == aw_rd_ptr);
	assign aw_full = (aw_wr_ptr[FIFO_ADDR_WIDTH] != aw_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                 (aw_wr_ptr[FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]);

	// AW write in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			aw_wr_ptr <= 0;
		else if (aw_wr_en)
			aw_wr_ptr <= aw_wr_ptr + 1;
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_id[0] <= 0;
			aw_fifo_addr[0] <= 0;
			aw_fifo_len[0] <= 0;
			aw_fifo_size[0] <= 0;
			aw_fifo_burst[0] <= 0;
			aw_fifo_lock[0] <= 0;
			aw_fifo_cache[0] <= 0;
			aw_fifo_prot[0] <= 0;
			aw_fifo_qos[0] <= 0;
		end else if (aw_wr_en) begin
			aw_fifo_id[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWID;
			aw_fifo_addr[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWADDR;
			aw_fifo_len[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWLEN;
			aw_fifo_size[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWSIZE;
			aw_fifo_burst[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWBURST;
			aw_fifo_lock[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWLOCK;
			aw_fifo_cache[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWCACHE;
			aw_fifo_prot[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWPROT;
			aw_fifo_qos[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_AWQOS;
		end
	end

	// AW read in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			aw_rd_ptr <= 0;
		else if (aw_rd_en)
			aw_rd_ptr <= aw_rd_ptr + 1;
	end

	// AW handshake
	assign S_AXI_AWREADY = !aw_full;
	assign aw_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;

	// AW output in M domain
	reg aw_out_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] aw_out_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_out_addr;
	reg [7:0] aw_out_len;
	reg [2:0] aw_out_size;
	reg [1:0] aw_out_burst;
	reg aw_out_lock;
	reg [3:0] aw_out_cache;
	reg [2:0] aw_out_prot;
	reg [3:0] aw_out_qos;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_out_valid <= 0;
			aw_out_id <= 0;
			aw_out_addr <= 0;
			aw_out_len <= 0;
			aw_out_size <= 0;
			aw_out_burst <= 0;
			aw_out_lock <= 0;
			aw_out_cache <= 0;
			aw_out_prot <= 0;
			aw_out_qos <= 0;
		end else begin
			if (aw_rd_en) begin
				aw_out_valid <= 0;
			end else if (!aw_out_valid && !aw_empty) begin
				aw_out_valid <= 1;
				aw_out_id <= aw_fifo_id[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_addr <= aw_fifo_addr[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_len <= aw_fifo_len[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_size <= aw_fifo_size[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_burst <= aw_fifo_burst[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_lock <= aw_fifo_lock[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_cache <= aw_fifo_cache[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_prot <= aw_fifo_prot[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				aw_out_qos <= aw_fifo_qos[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign M_AXI_AWID = aw_out_id;
	assign M_AXI_AWADDR = aw_out_addr;
	assign M_AXI_AWLEN = aw_out_len;
	assign M_AXI_AWSIZE = aw_out_size;
	assign M_AXI_AWBURST = aw_out_burst;
	assign M_AXI_AWLOCK = aw_out_lock;
	assign M_AXI_AWCACHE = aw_out_cache;
	assign M_AXI_AWPROT = aw_out_prot;
	assign M_AXI_AWQOS = aw_out_qos;
	assign M_AXI_AWVALID = aw_out_valid;

	assign aw_rd_en = aw_out_valid && M_AXI_AWREADY;

	// W Channel: S -> M
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] w_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] w_rd_ptr;
	reg w_wr_en;
	reg w_rd_en;
	wire w_empty;
	wire w_full;

	assign w_empty = (w_wr_ptr == w_rd_ptr);
	assign w_full = (w_wr_ptr[FIFO_ADDR_WIDTH] != w_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                 (w_wr_ptr[FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[FIFO_ADDR_WIDTH-1:0]);

	// W write in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			w_wr_ptr <= 0;
		else if (w_wr_en)
			w_wr_ptr <= w_wr_ptr + 1;
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_data[0] <= 0;
			w_fifo_strb[0] <= 0;
			w_fifo_last[0] <= 0;
		end else if (w_wr_en) begin
			w_fifo_data[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WDATA;
			w_fifo_strb[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WSTRB;
			w_fifo_last[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_WLAST;
		end
	end

	// W read in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			w_rd_ptr <= 0;
		else if (w_rd_en)
			w_rd_ptr <= w_rd_ptr + 1;
	end

	// W handshake
	assign S_AXI_WREADY = !w_full;
	assign w_wr_en = S_AXI_WVALID && S_AXI_WREADY;

	// W output in M domain with one extra clock delay
	reg w_out_valid;
	reg w_out_valid_d1;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_out_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_out_strb;
	reg w_out_last;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_out_valid <= 0;
			w_out_valid_d1 <= 0;
			w_out_data <= 0;
			w_out_strb <= 0;
			w_out_last <= 0;
		end else begin
			w_out_valid_d1 <= w_out_valid;
			if (w_rd_en) begin
				w_out_valid <= 0;
			end else if (!w_out_valid && !w_empty) begin
				w_out_valid <= 1;
				w_out_data <= w_fifo_data[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				w_out_strb <= w_fifo_strb[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				w_out_last <= w_fifo_last[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign M_AXI_WDATA = w_out_data;
	assign M_AXI_WSTRB = w_out_strb;
	assign M_AXI_WLAST = w_out_last;
	assign M_AXI_WVALID = w_out_valid_d1;

	assign w_rd_en = w_out_valid && M_AXI_WREADY;

	// B Channel: M -> S
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] b_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] b_rd_ptr;
	reg b_wr_en;
	reg b_rd_en;
	wire b_empty;
	wire b_full;

	assign b_empty = (b_wr_ptr == b_rd_ptr);
	assign b_full = (b_wr_ptr[FIFO_ADDR_WIDTH] != b_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                 (b_wr_ptr[FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[FIFO_ADDR_WIDTH-1:0]);

	// B write in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			b_wr_ptr <= 0;
		else if (b_wr_en)
			b_wr_ptr <= b_wr_ptr + 1;
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_id[0] <= 0;
			b_fifo_resp[0] <= 0;
		end else if (b_wr_en) begin
			b_fifo_id[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_BID;
			b_fifo_resp[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_BRESP;
		end
	end

	// B read in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			b_rd_ptr <= 0;
		else if (b_rd_en)
			b_rd_ptr <= b_rd_ptr + 1;
	end

	// B handshake
	assign M_AXI_BREADY = !b_full;
	assign b_wr_en = M_AXI_BVALID && M_AXI_BREADY;

	// B output in S domain
	reg b_out_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] b_out_id;
	reg [1:0] b_out_resp;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_out_valid <= 0;
			b_out_id <= 0;
			b_out_resp <= 0;
		end else begin
			if (b_rd_en) begin
				b_out_valid <= 0;
			end else if (!b_out_valid && !b_empty) begin
				b_out_valid <= 1;
				b_out_id <= b_fifo_id[b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				b_out_resp <= b_fifo_resp[b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign S_AXI_BID = b_out_id;
	assign S_AXI_BRESP = b_out_resp;
	assign S_AXI_BVALID = b_out_valid;

	assign b_rd_en = b_out_valid && S_AXI_BREADY;

	// AR Channel: S -> M
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] ar_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] ar_rd_ptr;
	reg ar_wr_en;
	reg ar_rd_en;
	wire ar_empty;
	wire ar_full;

	assign ar_empty = (ar_wr_ptr == ar_rd_ptr);
	assign ar_full = (ar_wr_ptr[FIFO_ADDR_WIDTH] != ar_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                 (ar_wr_ptr[FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]);

	// AR write in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			ar_wr_ptr <= 0;
		else if (ar_wr_en)
			ar_wr_ptr <= ar_wr_ptr + 1;
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_id[0] <= 0;
			ar_fifo_addr[0] <= 0;
			ar_fifo_len[0] <= 0;
			ar_fifo_size[0] <= 0;
			ar_fifo_burst[0] <= 0;
			ar_fifo_lock[0] <= 0;
			ar_fifo_cache[0] <= 0;
			ar_fifo_prot[0] <= 0;
			ar_fifo_qos[0] <= 0;
		end else if (ar_wr_en) begin
			ar_fifo_id[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARID;
			ar_fifo_addr[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARADDR;
			ar_fifo_len[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARLEN;
			ar_fifo_size[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARSIZE;
			ar_fifo_burst[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARBURST;
			ar_fifo_lock[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARLOCK;
			ar_fifo_cache[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARCACHE;
			ar_fifo_prot[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARPROT;
			ar_fifo_qos[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= S_AXI_ARQOS;
		end
	end

	// AR read in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			ar_rd_ptr <= 0;
		else if (ar_rd_en)
			ar_rd_ptr <= ar_rd_ptr + 1;
	end

	// AR handshake
	assign S_AXI_ARREADY = !ar_full;
	assign ar_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;

	// AR output in M domain
	reg ar_out_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] ar_out_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_out_addr;
	reg [7:0] ar_out_len;
	reg [2:0] ar_out_size;
	reg [1:0] ar_out_burst;
	reg ar_out_lock;
	reg [3:0] ar_out_cache;
	reg [2:0] ar_out_prot;
	reg [3:0] ar_out_qos;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_out_valid <= 0;
			ar_out_id <= 0;
			ar_out_addr <= 0;
			ar_out_len <= 0;
			ar_out_size <= 0;
			ar_out_burst <= 0;
			ar_out_lock <= 0;
			ar_out_cache <= 0;
			ar_out_prot <= 0;
			ar_out_qos <= 0;
		end else begin
			if (ar_rd_en) begin
				ar_out_valid <= 0;
			end else if (!ar_out_valid && !ar_empty) begin
				ar_out_valid <= 1;
				ar_out_id <= ar_fifo_id[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_addr <= ar_fifo_addr[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_len <= ar_fifo_len[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_size <= ar_fifo_size[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_burst <= ar_fifo_burst[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_lock <= ar_fifo_lock[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_cache <= ar_fifo_cache[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_prot <= ar_fifo_prot[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				ar_out_qos <= ar_fifo_qos[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign M_AXI_ARID = ar_out_id;
	assign M_AXI_ARADDR = ar_out_addr;
	assign M_AXI_ARLEN = ar_out_len;
	assign M_AXI_ARSIZE = ar_out_size;
	assign M_AXI_ARBURST = ar_out_burst;
	assign M_AXI_ARLOCK = ar_out_lock;
	assign M_AXI_ARCACHE = ar_out_cache;
	assign M_AXI_ARPROT = ar_out_prot;
	assign M_AXI_ARQOS = ar_out_qos;
	assign M_AXI_ARVALID = ar_out_valid;

	assign ar_rd_en = ar_out_valid && M_AXI_ARREADY;

	// R Channel: M -> S
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg r_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] r_wr_ptr;
	reg [FIFO_ADDR_WIDTH:0] r_rd_ptr;
	reg r_wr_en;
	reg r_rd_en;
	wire r_empty;
	wire r_full;

	assign r_empty = (r_wr_ptr == r_rd_ptr);
	assign r_full = (r_wr_ptr[FIFO_ADDR_WIDTH] != r_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                 (r_wr_ptr[FIFO_ADDR_WIDTH-1:0] == r_rd_ptr[FIFO_ADDR_WIDTH-1:0]);

	// R write in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			r_wr_ptr <= 0;
		else if (r_wr_en)
			r_wr_ptr <= r_wr_ptr + 1;
	end

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_fifo_id[0] <= 0;
			r_fifo_data[0] <= 0;
			r_fifo_resp[0] <= 0;
			r_fifo_last[0] <= 0;
		end else if (r_wr_en) begin
			r_fifo_id[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_RID;
			r_fifo_data[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_RDATA;
			r_fifo_resp[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_RRESP;
			r_fifo_last[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= M_AXI_RLAST;
		end
	end

	// R read in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			r_rd_ptr <= 0;
		else if (r_rd_en)
			r_rd_ptr <= r_rd_ptr + 1;
	end

	// R handshake
	assign M_AXI_RREADY = !r_full;
	assign r_wr_en = M_AXI_RVALID && M_AXI_RREADY;

	// R output in S domain
	reg r_out_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] r_out_id;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_out_data;
	reg [1:0] r_out_resp;
	reg r_out_last;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_out_valid <= 0;
			r_out_id <= 0;
			r_out_data <= 0;
			r_out_resp <= 0;
			r_out_last <= 0;
		end else begin
			if (r_rd_en) begin
				r_out_valid <= 0;
			end else if (!r_out_valid && !r_empty) begin
				r_out_valid <= 1;
				r_out_id <= r_fifo_id[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				r_out_data <= r_fifo_data[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				r_out_resp <= r_fifo_resp[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				r_out_last <= r_fifo_last[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			end
		end
	end

	assign S_AXI_RID = r_out_id;
	assign S_AXI_RDATA = r_out_data;
	assign S_AXI_RRESP = r_out_resp;
	assign S_AXI_RLAST = r_out_last;
	assign S_AXI_RVALID = r_out_valid;

	assign r_rd_en = r_out_valid && S_AXI_RREADY;

endmodule
