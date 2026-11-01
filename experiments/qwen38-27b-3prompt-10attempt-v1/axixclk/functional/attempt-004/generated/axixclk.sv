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
	wire m_reset_active = ~m_reset_sync[FFS_STAGES-1];
	assign M_AXI_ARESETN = ~m_reset_active;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], 1'b1};
	end

	// AW Channel: S -> M
	// FIFO for AW channel
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH-1:0] aw_wr_ptr, aw_rd_ptr;
	reg aw_wr_en, aw_rd_en;
	wire aw_full, aw_empty;

	assign aw_full = (aw_wr_ptr == aw_rd_ptr) && (aw_wr_ptr[FIFO_ADDR_WIDTH-1] != aw_rd_ptr[FIFO_ADDR_WIDTH-1]);
	assign aw_empty = (aw_wr_ptr == aw_rd_ptr);

	// S_AXI_AWREADY is high when FIFO is not full
	assign S_AXI_AWREADY = ~aw_full;

	// Write to FIFO on S_AXI_ACLK
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_wr_en <= 1'b0;
		end else begin
			aw_wr_en <= S_AXI_AWVALID && S_AXI_AWREADY;
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				aw_fifo_id[aw_wr_ptr] <= S_AXI_AWID;
				aw_fifo_addr[aw_wr_ptr] <= S_AXI_AWADDR;
				aw_fifo_len[aw_wr_ptr] <= S_AXI_AWLEN;
				aw_fifo_size[aw_wr_ptr] <= S_AXI_AWSIZE;
				aw_fifo_burst[aw_wr_ptr] <= S_AXI_AWBURST;
				aw_fifo_lock[aw_wr_ptr] <= S_AXI_AWLOCK;
				aw_fifo_cache[aw_wr_ptr] <= S_AXI_AWCACHE;
				aw_fifo_prot[aw_wr_ptr] <= S_AXI_AWPROT;
				aw_fifo_qos[aw_wr_ptr] <= S_AXI_AWQOS;
				aw_wr_ptr <= aw_wr_ptr + 1'b1;
			end
		end
	end

	// Read from FIFO on M_AXI_ACLK
	reg [C_S_AXI_ID_WIDTH-1:0] aw_rd_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_rd_addr;
	reg [7:0] aw_rd_len;
	reg [2:0] aw_rd_size;
	reg [1:0] aw_rd_burst;
	reg aw_rd_lock;
	reg [3:0] aw_rd_cache;
	reg [2:0] aw_rd_prot;
	reg [3:0] aw_rd_qos;
	reg aw_rd_valid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_rd_en <= 1'b0;
			aw_rd_valid <= 1'b0;
			aw_rd_id <= {C_S_AXI_ID_WIDTH{1'b0}};
			aw_rd_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			aw_rd_len <= 8'b0;
			aw_rd_size <= 3'b0;
			aw_rd_burst <= 2'b0;
			aw_rd_lock <= 1'b0;
			aw_rd_cache <= 4'b0;
			aw_rd_prot <= 3'b0;
			aw_rd_qos <= 4'b0;
		end else begin
			aw_rd_en <= aw_rd_valid && M_AXI_AWREADY;
			if (aw_rd_valid && M_AXI_AWREADY) begin
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
			end
			if (!aw_empty) begin
				aw_rd_valid <= 1'b1;
				aw_rd_id <= aw_fifo_id[aw_rd_ptr];
				aw_rd_addr <= aw_fifo_addr[aw_rd_ptr];
				aw_rd_len <= aw_fifo_len[aw_rd_ptr];
				aw_rd_size <= aw_fifo_size[aw_rd_ptr];
				aw_rd_burst <= aw_fifo_burst[aw_rd_ptr];
				aw_rd_lock <= aw_fifo_lock[aw_rd_ptr];
				aw_rd_cache <= aw_fifo_cache[aw_rd_ptr];
				aw_rd_prot <= aw_fifo_prot[aw_rd_ptr];
				aw_rd_qos <= aw_fifo_qos[aw_rd_ptr];
			end else begin
				aw_rd_valid <= 1'b0;
			end
		end
	end

	assign M_AXI_AWID = aw_rd_id;
	assign M_AXI_AWADDR = aw_rd_addr;
	assign M_AXI_AWLEN = aw_rd_len;
	assign M_AXI_AWSIZE = aw_rd_size;
	assign M_AXI_AWBURST = aw_rd_burst;
	assign M_AXI_AWLOCK = aw_rd_lock;
	assign M_AXI_AWCACHE = aw_rd_cache;
	assign M_AXI_AWPROT = aw_rd_prot;
	assign M_AXI_AWQOS = aw_rd_qos;
	assign M_AXI_AWVALID = aw_rd_valid;

	// W Channel: S -> M
	// FIFO for W channel
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH-1:0] w_wr_ptr, w_rd_ptr;
	reg w_wr_en, w_rd_en;
	wire w_full, w_empty;

	assign w_full = (w_wr_ptr == w_rd_ptr) && (w_wr_ptr[FIFO_ADDR_WIDTH-1] != w_rd_ptr[FIFO_ADDR_WIDTH-1]);
	assign w_empty = (w_wr_ptr == w_rd_ptr);

	// S_AXI_WREADY is high when FIFO is not full
	assign S_AXI_WREADY = ~w_full;

	// Write to FIFO on S_AXI_ACLK
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_wr_en <= 1'b0;
		end else begin
			w_wr_en <= S_AXI_WVALID && S_AXI_WREADY;
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_fifo_data[w_wr_ptr] <= S_AXI_WDATA;
				w_fifo_strb[w_wr_ptr] <= S_AXI_WSTRB;
				w_fifo_last[w_wr_ptr] <= S_AXI_WLAST;
				w_wr_ptr <= w_wr_ptr + 1'b1;
			end
		end
	end

	// Read from FIFO on M_AXI_ACLK
	reg [C_S_AXI_DATA_WIDTH-1:0] w_rd_data;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_rd_strb;
	reg w_rd_last;
	reg w_rd_valid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_rd_en <= 1'b0;
			w_rd_valid <= 1'b0;
			w_rd_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
			w_rd_strb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			w_rd_last <= 1'b0;
		end else begin
			w_rd_en <= w_rd_valid && M_AXI_WREADY;
			if (w_rd_valid && M_AXI_WREADY) begin
				w_rd_ptr <= w_rd_ptr + 1'b1;
			end
			if (!w_empty) begin
				w_rd_valid <= 1'b1;
				w_rd_data <= w_fifo_data[w_rd_ptr];
				w_rd_strb <= w_fifo_strb[w_rd_ptr];
				w_rd_last <= w_fifo_last[w_rd_ptr];
			end else begin
				w_rd_valid <= 1'b0;
			end
		end
	end

	// Master write data is held one extra M_AXI clock before M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1:0] m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_wvalid_reg;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_reg <= 1'b0;
			m_wvalid_reg <= 1'b0;
		end else begin
			m_wvalid_reg <= w_rd_valid;
			m_wdata_reg <= w_rd_data;
			m_wstrb_reg <= w_rd_strb;
			m_wlast_reg <= w_rd_last;
		end
	end

	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;

	// B Channel: M -> S
	// FIFO for B channel
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH-1:0] b_wr_ptr, b_rd_ptr;
	reg b_wr_en, b_rd_en;
	wire b_full, b_empty;

	assign b_full = (b_wr_ptr == b_rd_ptr) && (b_wr_ptr[FIFO_ADDR_WIDTH-1] != b_rd_ptr[FIFO_ADDR_WIDTH-1]);
	assign b_empty = (b_wr_ptr == b_rd_ptr);

	// M_AXI_BREADY is high when FIFO is not full
	assign M_AXI_BREADY = ~b_full;

	// Write to FIFO on M_AXI_ACLK
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_wr_en <= 1'b0;
		end else begin
			b_wr_en <= M_AXI_BVALID && M_AXI_BREADY;
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_fifo_id[b_wr_ptr] <= M_AXI_BID;
				b_fifo_resp[b_wr_ptr] <= M_AXI_BRESP;
				b_wr_ptr <= b_wr_ptr + 1'b1;
			end
		end
	end

	// Read from FIFO on S_AXI_ACLK
	reg [C_S_AXI_ID_WIDTH-1:0] b_rd_id;
	reg [1:0] b_rd_resp;
	reg b_rd_valid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_rd_en <= 1'b0;
			b_rd_valid <= 1'b0;
			b_rd_id <= {C_S_AXI_ID_WIDTH{1'b0}};
			b_rd_resp <= 2'b0;
		end else begin
			b_rd_en <= b_rd_valid && S_AXI_BREADY;
			if (b_rd_valid && S_AXI_BREADY) begin
				b_rd_ptr <= b_rd_ptr + 1'b1;
			end
			if (!b_empty) begin
				b_rd_valid <= 1'b1;
				b_rd_id <= b_fifo_id[b_rd_ptr];
				b_rd_resp <= b_fifo_resp[b_rd_ptr];
			end else begin
				b_rd_valid <= 1'b0;
			end
		end
	end

	assign S_AXI_BID = b_rd_id;
	assign S_AXI_BRESP = b_rd_resp;
	assign S_AXI_BVALID = b_rd_valid;

	// AR Channel: S -> M
	// FIFO for AR channel
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH-1:0] ar_wr_ptr, ar_rd_ptr;
	reg ar_wr_en, ar_rd_en;
	wire ar_full, ar_empty;

	assign ar_full = (ar_wr_ptr == ar_rd_ptr) && (ar_wr_ptr[FIFO_ADDR_WIDTH-1] != ar_rd_ptr[FIFO_ADDR_WIDTH-1]);
	assign ar_empty = (ar_wr_ptr == ar_rd_ptr);

	// S_AXI_ARREADY is high when FIFO is not full
	assign S_AXI_ARREADY = ~ar_full;

	// Write to FIFO on S_AXI_ACLK
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_wr_en <= 1'b0;
		end else begin
			ar_wr_en <= S_AXI_ARVALID && S_AXI_ARREADY;
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				ar_fifo_id[ar_wr_ptr] <= S_AXI_ARID;
				ar_fifo_addr[ar_wr_ptr] <= S_AXI_ARADDR;
				ar_fifo_len[ar_wr_ptr] <= S_AXI_ARLEN;
				ar_fifo_size[ar_wr_ptr] <= S_AXI_ARSIZE;
				ar_fifo_burst[ar_wr_ptr] <= S_AXI_ARBURST;
				ar_fifo_lock[ar_wr_ptr] <= S_AXI_ARLOCK;
				ar_fifo_cache[ar_wr_ptr] <= S_AXI_ARCACHE;
				ar_fifo_prot[ar_wr_ptr] <= S_AXI_ARPROT;
				ar_fifo_qos[ar_wr_ptr] <= S_AXI_ARQOS;
				ar_wr_ptr <= ar_wr_ptr + 1'b1;
			end
		end
	end

	// Read from FIFO on M_AXI_ACLK
	reg [C_S_AXI_ID_WIDTH-1:0] ar_rd_id;
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_rd_addr;
	reg [7:0] ar_rd_len;
	reg [2:0] ar_rd_size;
	reg [1:0] ar_rd_burst;
	reg ar_rd_lock;
	reg [3:0] ar_rd_cache;
	reg [2:0] ar_rd_prot;
	reg [3:0] ar_rd_qos;
	reg ar_rd_valid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_rd_en <= 1'b0;
			ar_rd_valid <= 1'b0;
			ar_rd_id <= {C_S_AXI_ID_WIDTH{1'b0}};
			ar_rd_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			ar_rd_len <= 8'b0;
			ar_rd_size <= 3'b0;
			ar_rd_burst <= 2'b0;
			ar_rd_lock <= 1'b0;
			ar_rd_cache <= 4'b0;
			ar_rd_prot <= 3'b0;
			ar_rd_qos <= 4'b0;
		end else begin
			ar_rd_en <= ar_rd_valid && M_AXI_ARREADY;
			if (ar_rd_valid && M_AXI_ARREADY) begin
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
			end
			if (!ar_empty) begin
				ar_rd_valid <= 1'b1;
				ar_rd_id <= ar_fifo_id[ar_rd_ptr];
				ar_rd_addr <= ar_fifo_addr[ar_rd_ptr];
				ar_rd_len <= ar_fifo_len[ar_rd_ptr];
				ar_rd_size <= ar_fifo_size[ar_rd_ptr];
				ar_rd_burst <= ar_fifo_burst[ar_rd_ptr];
				ar_rd_lock <= ar_fifo_lock[ar_rd_ptr];
				ar_rd_cache <= ar_fifo_cache[ar_rd_ptr];
				ar_rd_prot <= ar_fifo_prot[ar_rd_ptr];
				ar_rd_qos <= ar_fifo_qos[ar_rd_ptr];
			end else begin
				ar_rd_valid <= 1'b0;
			end
		end
	end

	assign M_AXI_ARID = ar_rd_id;
	assign M_AXI_ARADDR = ar_rd_addr;
	assign M_AXI_ARLEN = ar_rd_len;
	assign M_AXI_ARSIZE = ar_rd_size;
	assign M_AXI_ARBURST = ar_rd_burst;
	assign M_AXI_ARLOCK = ar_rd_lock;
	assign M_AXI_ARCACHE = ar_rd_cache;
	assign M_AXI_ARPROT = ar_rd_prot;
	assign M_AXI_ARQOS = ar_rd_qos;
	assign M_AXI_ARVALID = ar_rd_valid;

	// R Channel: M -> S
	// FIFO for R channel
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg r_fifo_last [0:FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH-1:0] r_wr_ptr, r_rd_ptr;
	reg r_wr_en, r_rd_en;
	wire r_full, r_empty;

	assign r_full = (r_wr_ptr == r_rd_ptr) && (r_wr_ptr[FIFO_ADDR_WIDTH-1] != r_rd_ptr[FIFO_ADDR_WIDTH-1]);
	assign r_empty = (r_wr_ptr == r_rd_ptr);

	// M_AXI_RREADY is high when FIFO is not full
	assign M_AXI_RREADY = ~r_full;

	// Write to FIFO on M_AXI_ACLK
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_wr_en <= 1'b0;
		end else begin
			r_wr_en <= M_AXI_RVALID && M_AXI_RREADY;
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				r_fifo_id[r_wr_ptr] <= M_AXI_RID;
				r_fifo_data[r_wr_ptr] <= M_AXI_RDATA;
				r_fifo_resp[r_wr_ptr] <= M_AXI_RRESP;
				r_fifo_last[r_wr_ptr] <= M_AXI_RLAST;
				r_wr_ptr <= r_wr_ptr + 1'b1;
			end
		end
	end

	// Read from FIFO on S_AXI_ACLK
	reg [C_S_AXI_ID_WIDTH-1:0] r_rd_id;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_rd_data;
	reg [1:0] r_rd_resp;
	reg r_rd_last;
	reg r_rd_valid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_rd_en <= 1'b0;
			r_rd_valid <= 1'b0;
			r_rd_id <= {C_S_AXI_ID_WIDTH{1'b0}};
			r_rd_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
			r_rd_resp <= 2'b0;
			r_rd_last <= 1'b0;
		end else begin
			r_rd_en <= r_rd_valid && S_AXI_RREADY;
			if (r_rd_valid && S_AXI_RREADY) begin
				r_rd_ptr <= r_rd_ptr + 1'b1;
			end
			if (!r_empty) begin
				r_rd_valid <= 1'b1;
				r_rd_id <= r_fifo_id[r_rd_ptr];
				r_rd_data <= r_fifo_data[r_rd_ptr];
				r_rd_resp <= r_fifo_resp[r_rd_ptr];
				r_rd_last <= r_fifo_last[r_rd_ptr];
			end else begin
				r_rd_valid <= 1'b0;
			end
		end
	end

	assign S_AXI_RID = r_rd_id;
	assign S_AXI_RDATA = r_rd_data;
	assign S_AXI_RRESP = r_rd_resp;
	assign S_AXI_RLAST = r_rd_last;
	assign S_AXI_RVALID = r_rd_valid;

endmodule
