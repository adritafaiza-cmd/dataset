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
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	reg m_reset_sync_ff;
	reg m_reset_sync_ff2;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign M_AXI_ARESETN = m_reset_sync[1];

	// Write Address Channel (AW)
	// S-side: capture AW when valid and ready
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

	// AW FIFO
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

	// AW write to FIFO (S clock)
	wire aw_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	wire aw_fifo_full = (aw_fifo_wr_ptr == aw_fifo_rd_ptr) && aw_fifo_valid[aw_fifo_wr_ptr];
	assign S_AXI_AWREADY = !aw_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_fifo_valid <= {FIFO_DEPTH{1'b0}};
		end else begin
			if (aw_wr_en) begin
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

	// AW read from FIFO (M clock)
	wire aw_fifo_empty = !aw_fifo_valid[aw_fifo_rd_ptr];
	wire aw_rd_en = M_AXI_AWVALID && M_AXI_AWREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			M_AXI_AWVALID <= 1'b0;
			M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_AWLEN <= 8'b0;
			M_AXI_AWSIZE <= 3'b0;
			M_AXI_AWBURST <= 2'b0;
			M_AXI_AWLOCK <= 1'b0;
			M_AXI_AWCACHE <= 4'b0;
			M_AXI_AWPROT <= 3'b0;
			M_AXI_AWQOS <= 4'b0;
		end else begin
			if (aw_rd_en) begin
				aw_fifo_valid[aw_fifo_rd_ptr] <= 1'b0;
				aw_fifo_rd_ptr <= aw_fifo_rd_ptr + 1'b1;
				M_AXI_AWVALID <= 1'b0;
			end else if (!aw_fifo_empty && !M_AXI_AWVALID) begin
				M_AXI_AWVALID <= 1'b1;
				M_AXI_AWID <= aw_fifo_id[aw_fifo_rd_ptr];
				M_AXI_AWADDR <= aw_fifo_addr[aw_fifo_rd_ptr];
				M_AXI_AWLEN <= aw_fifo_len[aw_fifo_rd_ptr];
				M_AXI_AWSIZE <= aw_fifo_size[aw_fifo_rd_ptr];
				M_AXI_AWBURST <= aw_fifo_burst[aw_fifo_rd_ptr];
				M_AXI_AWLOCK <= aw_fifo_lock[aw_fifo_rd_ptr];
				M_AXI_AWCACHE <= aw_fifo_cache[aw_fifo_rd_ptr];
				M_AXI_AWPROT <= aw_fifo_prot[aw_fifo_rd_ptr];
				M_AXI_AWQOS <= aw_fifo_qos[aw_fifo_rd_ptr];
			end
		end
	end

	// Write Data Channel (W)
	// W FIFO
	reg [FIFO_DEPTH-1:0] w_fifo_valid;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] w_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] w_fifo_rd_ptr;

	// W write to FIFO (S clock)
	wire w_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	wire w_fifo_full = (w_fifo_wr_ptr == w_fifo_rd_ptr) && w_fifo_valid[w_fifo_wr_ptr];
	assign S_AXI_WREADY = !w_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_fifo_valid <= {FIFO_DEPTH{1'b0}};
		end else begin
			if (w_wr_en) begin
				w_fifo_valid[w_fifo_wr_ptr] <= 1'b1;
				w_fifo_data[w_fifo_wr_ptr] <= S_AXI_WDATA;
				w_fifo_strb[w_fifo_wr_ptr] <= S_AXI_WSTRB;
				w_fifo_last[w_fifo_wr_ptr] <= S_AXI_WLAST;
				w_fifo_wr_ptr <= w_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// W read from FIFO (M clock)
	wire w_fifo_empty = !w_fifo_valid[w_fifo_rd_ptr];
	wire w_rd_en = M_AXI_WVALID && M_AXI_WREADY;

	// M_AXI_WVALID is held one extra M_AXI clock before M_AXI_WVALID per spec
	// We use a staging register
	reg w_stage_valid;
	reg [C_S_AXI_DATA_WIDTH-1:0] w_stage_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_stage_strb;
	reg w_stage_last;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			M_AXI_WVALID <= 1'b0;
			M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			M_AXI_WSTRB <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			M_AXI_WLAST <= 1'b0;
			w_stage_valid <= 1'b0;
			w_stage_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
			w_stage_strb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			w_stage_last <= 1'b0;
		end else begin
			// Stage from FIFO
			if (!w_stage_valid && !w_fifo_empty) begin
				w_stage_valid <= 1'b1;
				w_stage_data <= w_fifo_data[w_fifo_rd_ptr];
				w_stage_strb <= w_fifo_strb[w_fifo_rd_ptr];
				w_stage_last <= w_fifo_last[w_fifo_rd_ptr];
			end else if (w_rd_en) begin
				w_fifo_valid[w_fifo_rd_ptr] <= 1'b0;
				w_fifo_rd_ptr <= w_fifo_rd_ptr + 1'b1;
				w_stage_valid <= 1'b0;
			end

			// Drive M side from stage
			if (w_rd_en) begin
				M_AXI_WVALID <= 1'b0;
			end else if (w_stage_valid && !M_AXI_WVALID) begin
				M_AXI_WVALID <= 1'b1;
				M_AXI_WDATA <= w_stage_data;
				M_AXI_WSTRB <= w_stage_strb;
				M_AXI_WLAST <= w_stage_last;
			end
		end
	end

	// Write Response Channel (B)
	// B FIFO (M to S)
	reg [FIFO_DEPTH-1:0] b_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] b_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] b_fifo_rd_ptr;

	// B write to FIFO (M clock)
	wire b_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	wire b_fifo_full = (b_fifo_wr_ptr == b_fifo_rd_ptr) && b_fifo_valid[b_fifo_wr_ptr];
	assign M_AXI_BREADY = !b_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_fifo_valid <= {FIFO_DEPTH{1'b0}};
		end else begin
			if (b_wr_en) begin
				b_fifo_valid[b_fifo_wr_ptr] <= 1'b1;
				b_fifo_id[b_fifo_wr_ptr] <= M_AXI_BID;
				b_fifo_resp[b_fifo_wr_ptr] <= M_AXI_BRESP;
				b_fifo_wr_ptr <= b_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// B read from FIFO (S clock)
	wire b_fifo_empty = !b_fifo_valid[b_fifo_rd_ptr];
	wire b_rd_en = S_AXI_BVALID && S_AXI_BREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			S_AXI_BVALID <= 1'b0;
			S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_BRESP <= 2'b0;
		end else begin
			if (b_rd_en) begin
				b_fifo_valid[b_fifo_rd_ptr] <= 1'b0;
				b_fifo_rd_ptr <= b_fifo_rd_ptr + 1'b1;
				S_AXI_BVALID <= 1'b0;
			end else if (!b_fifo_empty && !S_AXI_BVALID) begin
				S_AXI_BVALID <= 1'b1;
				S_AXI_BID <= b_fifo_id[b_fifo_rd_ptr];
				S_AXI_BRESP <= b_fifo_resp[b_fifo_rd_ptr];
			end
		end
	end

	// Read Address Channel (AR)
	// AR FIFO
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

	// AR write to FIFO (S clock)
	wire ar_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	wire ar_fifo_full = (ar_fifo_wr_ptr == ar_fifo_rd_ptr) && ar_fifo_valid[ar_fifo_wr_ptr];
	assign S_AXI_ARREADY = !ar_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_fifo_valid <= {FIFO_DEPTH{1'b0}};
		end else begin
			if (ar_wr_en) begin
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

	// AR read from FIFO (M clock)
	wire ar_fifo_empty = !ar_fifo_valid[ar_fifo_rd_ptr];
	wire ar_rd_en = M_AXI_ARVALID && M_AXI_ARREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			M_AXI_ARVALID <= 1'b0;
			M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
			M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			M_AXI_ARLEN <= 8'b0;
			M_AXI_ARSIZE <= 3'b0;
			M_AXI_ARBURST <= 2'b0;
			M_AXI_ARLOCK <= 1'b0;
			M_AXI_ARCACHE <= 4'b0;
			M_AXI_ARPROT <= 3'b0;
			M_AXI_ARQOS <= 4'b0;
		end else begin
			if (ar_rd_en) begin
				ar_fifo_valid[ar_fifo_rd_ptr] <= 1'b0;
				ar_fifo_rd_ptr <= ar_fifo_rd_ptr + 1'b1;
				M_AXI_ARVALID <= 1'b0;
			end else if (!ar_fifo_empty && !M_AXI_ARVALID) begin
				M_AXI_ARVALID <= 1'b1;
				M_AXI_ARID <= ar_fifo_id[ar_fifo_rd_ptr];
				M_AXI_ARADDR <= ar_fifo_addr[ar_fifo_rd_ptr];
				M_AXI_ARLEN <= ar_fifo_len[ar_fifo_rd_ptr];
				M_AXI_ARSIZE <= ar_fifo_size[ar_fifo_rd_ptr];
				M_AXI_ARBURST <= ar_fifo_burst[ar_fifo_rd_ptr];
				M_AXI_ARLOCK <= ar_fifo_lock[ar_fifo_rd_ptr];
				M_AXI_ARCACHE <= ar_fifo_cache[ar_fifo_rd_ptr];
				M_AXI_ARPROT <= ar_fifo_prot[ar_fifo_rd_ptr];
				M_AXI_ARQOS <= ar_fifo_qos[ar_fifo_rd_ptr];
			end
		end
	end

	// Read Data Channel (R)
	// R FIFO (M to S)
	reg [FIFO_DEPTH-1:0] r_fifo_valid;
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg r_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] r_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] r_fifo_rd_ptr;

	// R write to FIFO (M clock)
	wire r_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	wire r_fifo_full = (r_fifo_wr_ptr == r_fifo_rd_ptr) && r_fifo_valid[r_fifo_wr_ptr];
	assign M_AXI_RREADY = !r_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_fifo_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_fifo_valid <= {FIFO_DEPTH{1'b0}};
		end else begin
			if (r_wr_en) begin
				r_fifo_valid[r_fifo_wr_ptr] <= 1'b1;
				r_fifo_id[r_fifo_wr_ptr] <= M_AXI_RID;
				r_fifo_data[r_fifo_wr_ptr] <= M_AXI_RDATA;
				r_fifo_resp[r_fifo_wr_ptr] <= M_AXI_RRESP;
				r_fifo_last[r_fifo_wr_ptr] <= M_AXI_RLAST;
				r_fifo_wr_ptr <= r_fifo_wr_ptr + 1'b1;
			end
		end
	end

	// R read from FIFO (S clock)
	wire r_fifo_empty = !r_fifo_valid[r_fifo_rd_ptr];
	wire r_rd_en = S_AXI_RVALID && S_AXI_RREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_fifo_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			S_AXI_RVALID <= 1'b0;
			S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
			S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
			S_AXI_RRESP <= 2'b0;
			S_AXI_RLAST <= 1'b0;
		end else begin
			if (r_rd_en) begin
				r_fifo_valid[r_fifo_rd_ptr] <= 1'b0;
				r_fifo_rd_ptr <= r_fifo_rd_ptr + 1'b1;
				S_AXI_RVALID <= 1'b0;
			end else if (!r_fifo_empty && !S_AXI_RVALID) begin
				S_AXI_RVALID <= 1'b1;
				S_AXI_RID <= r_fifo_id[r_fifo_rd_ptr];
				S_AXI_RDATA <= r_fifo_data[r_fifo_rd_ptr];
				S_AXI_RRESP <= r_fifo_resp[r_fifo_rd_ptr];
				S_AXI_RLAST <= r_fifo_last[r_fifo_rd_ptr];
			end
		end
	end

endmodule
