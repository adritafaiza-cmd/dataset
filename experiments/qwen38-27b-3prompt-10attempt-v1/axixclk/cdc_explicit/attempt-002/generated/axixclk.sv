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
	localparam integer FIFO_PTR_WIDTH = LGFIFO;
	localparam integer AW_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Reset synchronization for M_AXI domain
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	wire m_reset_active;

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign M_AXI_ARESETN = m_reset_sync[1];
	assign m_reset_active = ~M_AXI_ARESETN;

	// AW channel: S to M
	reg [AW_FIFO_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_WIDTH:0] aw_wr_ptr;
	reg [FIFO_PTR_WIDTH:0] aw_rd_ptr;
	reg aw_wr_ptr_m;
	reg aw_rd_ptr_s;
	reg [1:0] aw_wr_ptr_sync_m;
	reg [1:0] aw_rd_ptr_sync_s;
	reg aw_wr_ptr_sync_m_next;
	reg aw_rd_ptr_sync_s_next;

	// AW write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			aw_wr_ptr_m <= 1'b0;
			aw_wr_ptr_sync_m <= 2'b00;
		end else begin
			aw_wr_ptr_m <= aw_wr_ptr[FIFO_PTR_WIDTH];
			aw_wr_ptr_sync_m <= {aw_wr_ptr_sync_m[0], aw_wr_ptr_m};
			if (S_AXI_AWVALID && S_AXI_AWREADY) begin
				aw_wr_ptr <= aw_wr_ptr + 1'b1;
			end
		end
	end

	// AW read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			aw_rd_ptr_s <= 1'b0;
			aw_rd_ptr_sync_s <= 2'b00;
		end else begin
			aw_rd_ptr_s <= aw_rd_ptr[FIFO_PTR_WIDTH];
			aw_rd_ptr_sync_s <= {aw_rd_ptr_sync_s[0], aw_rd_ptr_s};
			if (M_AXI_AWVALID && M_AXI_AWREADY) begin
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
			end
		end
	end

	// AW FIFO write in S domain
	wire aw_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;
	wire [AW_FIFO_WIDTH-1:0] aw_wr_data = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};

	always @(posedge S_AXI_ACLK) begin
		if (aw_wr_en) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_PTR_WIDTH-1:0]] <= aw_wr_data;
		end
	end

	// AW FIFO read in M domain
	wire aw_rd_en = M_AXI_AWVALID && M_AXI_AWREADY;
	wire [AW_FIFO_WIDTH-1:0] aw_rd_data = aw_fifo_mem[aw_rd_ptr[FIFO_PTR_WIDTH-1:0]];

	// AW FIFO full/empty
	wire aw_full = (aw_wr_ptr[FIFO_PTR_WIDTH] != aw_rd_ptr_sync_s[FIFO_PTR_WIDTH]) && 
	               (aw_wr_ptr[FIFO_PTR_WIDTH-1:0] == aw_rd_ptr_sync_s[FIFO_PTR_WIDTH-1:0]);
	wire aw_empty = (aw_wr_ptr_sync_m[FIFO_PTR_WIDTH] == aw_rd_ptr[FIFO_PTR_WIDTH]) && 
	               (aw_wr_ptr_sync_m[FIFO_PTR_WIDTH-1:0] == aw_rd_ptr[FIFO_PTR_WIDTH-1:0]);

	assign S_AXI_AWREADY = !aw_full;
	assign M_AXI_AWVALID = !aw_empty;
	assign M_AXI_AWID = aw_rd_data[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_AWADDR = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_AWLEN = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 7:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWSIZE = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 10:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8];
	assign M_AXI_AWBURST = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 12:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11];
	assign M_AXI_AWLOCK = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 13];
	assign M_AXI_AWCACHE = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 17:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 14];
	assign M_AXI_AWPROT = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 20:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18];
	assign M_AXI_AWQOS = aw_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 24:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 21];

	// W channel: S to M
	reg [W_FIFO_WIDTH-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_WIDTH:0] w_wr_ptr;
	reg [FIFO_PTR_WIDTH:0] w_rd_ptr;
	reg w_wr_ptr_m;
	reg w_rd_ptr_s;
	reg [1:0] w_wr_ptr_sync_m;
	reg [1:0] w_rd_ptr_sync_s;

	// W write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			w_wr_ptr_m <= 1'b0;
			w_wr_ptr_sync_m <= 2'b00;
		end else begin
			w_wr_ptr_m <= w_wr_ptr[FIFO_PTR_WIDTH];
			w_wr_ptr_sync_m <= {w_wr_ptr_sync_m[0], w_wr_ptr_m};
			if (S_AXI_WVALID && S_AXI_WREADY) begin
				w_wr_ptr <= w_wr_ptr + 1'b1;
			end
		end
	end

	// W read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			w_rd_ptr_s <= 1'b0;
			w_rd_ptr_sync_s <= 2'b00;
		end else begin
			w_rd_ptr_s <= w_rd_ptr[FIFO_PTR_WIDTH];
			w_rd_ptr_sync_s <= {w_rd_ptr_sync_s[0], w_rd_ptr_s};
			if (M_AXI_WVALID && M_AXI_WREADY) begin
				w_rd_ptr <= w_rd_ptr + 1'b1;
			end
		end
	end

	// W FIFO write in S domain
	wire w_wr_en = S_AXI_WVALID && S_AXI_WREADY;
	wire [W_FIFO_WIDTH-1:0] w_wr_data = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};

	always @(posedge S_AXI_ACLK) begin
		if (w_wr_en) begin
			w_fifo_mem[w_wr_ptr[FIFO_PTR_WIDTH-1:0]] <= w_wr_data;
		end
	end

	// W FIFO read in M domain
	wire w_rd_en = M_AXI_WVALID && M_AXI_WREADY;
	wire [W_FIFO_WIDTH-1:0] w_rd_data = w_fifo_mem[w_rd_ptr[FIFO_PTR_WIDTH-1:0]];

	// W FIFO full/empty
	wire w_full = (w_wr_ptr[FIFO_PTR_WIDTH] != w_rd_ptr_sync_s[FIFO_PTR_WIDTH]) && 
	               (w_wr_ptr[FIFO_PTR_WIDTH-1:0] == w_rd_ptr_sync_s[FIFO_PTR_WIDTH-1:0]);
	wire w_empty = (w_wr_ptr_sync_m[FIFO_PTR_WIDTH] == w_rd_ptr[FIFO_PTR_WIDTH]) && 
	               (w_wr_ptr_sync_m[FIFO_PTR_WIDTH-1:0] == w_rd_ptr[FIFO_PTR_WIDTH-1:0]);

	assign S_AXI_WREADY = !w_full;
	assign M_AXI_WVALID = !w_empty;
	assign M_AXI_WDATA = w_rd_data[C_S_AXI_DATA_WIDTH-1:0];
	assign M_AXI_WSTRB = w_rd_data[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8)-1:C_S_AXI_DATA_WIDTH];
	assign M_AXI_WLAST = w_rd_data[W_FIFO_WIDTH-1];

	// B channel: M to S
	reg [B_FIFO_WIDTH-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_WIDTH:0] b_wr_ptr;
	reg [FIFO_PTR_WIDTH:0] b_rd_ptr;
	reg b_wr_ptr_s;
	reg b_rd_ptr_m;
	reg [1:0] b_wr_ptr_sync_s;
	reg [1:0] b_rd_ptr_sync_m;

	// B write pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			b_wr_ptr_s <= 1'b0;
			b_wr_ptr_sync_s <= 2'b00;
		end else begin
			b_wr_ptr_s <= b_wr_ptr[FIFO_PTR_WIDTH];
			b_wr_ptr_sync_s <= {b_wr_ptr_sync_s[0], b_wr_ptr_s};
			if (M_AXI_BVALID && M_AXI_BREADY) begin
				b_wr_ptr <= b_wr_ptr + 1'b1;
			end
		end
	end

	// B read pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			b_rd_ptr_m <= 1'b0;
			b_rd_ptr_sync_m <= 2'b00;
		end else begin
			b_rd_ptr_m <= b_rd_ptr[FIFO_PTR_WIDTH];
			b_rd_ptr_sync_m <= {b_rd_ptr_sync_m[0], b_rd_ptr_m};
			if (S_AXI_BVALID && S_AXI_BREADY) begin
				b_rd_ptr <= b_rd_ptr + 1'b1;
			end
		end
	end

	// B FIFO write in M domain
	wire b_wr_en = M_AXI_BVALID && M_AXI_BREADY;
	wire [B_FIFO_WIDTH-1:0] b_wr_data = {M_AXI_BID, M_AXI_BRESP};

	always @(posedge M_AXI_ACLK) begin
		if (b_wr_en) begin
			b_fifo_mem[b_wr_ptr[FIFO_PTR_WIDTH-1:0]] <= b_wr_data;
		end
	end

	// B FIFO read in S domain
	wire b_rd_en = S_AXI_BVALID && S_AXI_BREADY;
	wire [B_FIFO_WIDTH-1:0] b_rd_data = b_fifo_mem[b_rd_ptr[FIFO_PTR_WIDTH-1:0]];

	// B FIFO full/empty
	wire b_full = (b_wr_ptr[FIFO_PTR_WIDTH] != b_rd_ptr_sync_m[FIFO_PTR_WIDTH]) && 
	               (b_wr_ptr[FIFO_PTR_WIDTH-1:0] == b_rd_ptr_sync_m[FIFO_PTR_WIDTH-1:0]);
	wire b_empty = (b_wr_ptr_sync_s[FIFO_PTR_WIDTH] == b_rd_ptr[FIFO_PTR_WIDTH]) && 
	               (b_wr_ptr_sync_s[FIFO_PTR_WIDTH-1:0] == b_rd_ptr[FIFO_PTR_WIDTH-1:0]);

	assign M_AXI_BREADY = !b_full;
	assign S_AXI_BVALID = !b_empty;
	assign S_AXI_BID = b_rd_data[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_BRESP = b_rd_data[B_FIFO_WIDTH-1:2];

	// AR channel: S to M
	reg [AR_FIFO_WIDTH-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_WIDTH:0] ar_wr_ptr;
	reg [FIFO_PTR_WIDTH:0] ar_rd_ptr;
	reg ar_wr_ptr_m;
	reg ar_rd_ptr_s;
	reg [1:0] ar_wr_ptr_sync_m;
	reg [1:0] ar_rd_ptr_sync_s;

	// AR write pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			ar_wr_ptr_m <= 1'b0;
			ar_wr_ptr_sync_m <= 2'b00;
		end else begin
			ar_wr_ptr_m <= ar_wr_ptr[FIFO_PTR_WIDTH];
			ar_wr_ptr_sync_m <= {ar_wr_ptr_sync_m[0], ar_wr_ptr_m};
			if (S_AXI_ARVALID && S_AXI_ARREADY) begin
				ar_wr_ptr <= ar_wr_ptr + 1'b1;
			end
		end
	end

	// AR read pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			ar_rd_ptr_s <= 1'b0;
			ar_rd_ptr_sync_s <= 2'b00;
		end else begin
			ar_rd_ptr_s <= ar_rd_ptr[FIFO_PTR_WIDTH];
			ar_rd_ptr_sync_s <= {ar_rd_ptr_sync_s[0], ar_rd_ptr_s};
			if (M_AXI_ARVALID && M_AXI_ARREADY) begin
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
			end
		end
	end

	// AR FIFO write in S domain
	wire ar_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;
	wire [AR_FIFO_WIDTH-1:0] ar_wr_data = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};

	always @(posedge S_AXI_ACLK) begin
		if (ar_wr_en) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_PTR_WIDTH-1:0]] <= ar_wr_data;
		end
	end

	// AR FIFO read in M domain
	wire ar_rd_en = M_AXI_ARVALID && M_AXI_ARREADY;
	wire [AR_FIFO_WIDTH-1:0] ar_rd_data = ar_fifo_mem[ar_rd_ptr[FIFO_PTR_WIDTH-1:0]];

	// AR FIFO full/empty
	wire ar_full = (ar_wr_ptr[FIFO_PTR_WIDTH] != ar_rd_ptr_sync_s[FIFO_PTR_WIDTH]) && 
	               (ar_wr_ptr[FIFO_PTR_WIDTH-1:0] == ar_rd_ptr_sync_s[FIFO_PTR_WIDTH-1:0]);
	wire ar_empty = (ar_wr_ptr_sync_m[FIFO_PTR_WIDTH] == ar_rd_ptr[FIFO_PTR_WIDTH]) && 
	               (ar_wr_ptr_sync_m[FIFO_PTR_WIDTH-1:0] == ar_rd_ptr[FIFO_PTR_WIDTH-1:0]);

	assign S_AXI_ARREADY = !ar_full;
	assign M_AXI_ARVALID = !ar_empty;
	assign M_AXI_ARID = ar_rd_data[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_ARADDR = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_ARLEN = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 7:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARSIZE = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 10:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8];
	assign M_AXI_ARBURST = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 12:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11];
	assign M_AXI_ARLOCK = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 13];
	assign M_AXI_ARCACHE = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 17:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 14];
	assign M_AXI_ARPROT = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 20:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18];
	assign M_AXI_ARQOS = ar_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 24:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 21];

	// R channel: M to S
	reg [R_FIFO_WIDTH-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_WIDTH:0] r_wr_ptr;
	reg [FIFO_PTR_WIDTH:0] r_rd_ptr;
	reg r_wr_ptr_s;
	reg r_rd_ptr_m;
	reg [1:0] r_wr_ptr_sync_s;
	reg [1:0] r_rd_ptr_sync_m;

	// R write pointer in M domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			r_wr_ptr_s <= 1'b0;
			r_wr_ptr_sync_s <= 2'b00;
		end else begin
			r_wr_ptr_s <= r_wr_ptr[FIFO_PTR_WIDTH];
			r_wr_ptr_sync_s <= {r_wr_ptr_sync_s[0], r_wr_ptr_s};
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				r_wr_ptr <= r_wr_ptr + 1'b1;
			end
		end
	end

	// R read pointer in S domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= {(FIFO_PTR_WIDTH+1){1'b0}};
			r_rd_ptr_m <= 1'b0;
			r_rd_ptr_sync_m <= 2'b00;
		end else begin
			r_rd_ptr_m <= r_rd_ptr[FIFO_PTR_WIDTH];
			r_rd_ptr_sync_m <= {r_rd_ptr_sync_m[0], r_rd_ptr_m};
			if (S_AXI_RVALID && S_AXI_RREADY) begin
				r_rd_ptr <= r_rd_ptr + 1'b1;
			end
		end
	end

	// R FIFO write in M domain
	wire r_wr_en = M_AXI_RVALID && M_AXI_RREADY;
	wire [R_FIFO_WIDTH-1:0] r_wr_data = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};

	always @(posedge M_AXI_ACLK) begin
		if (r_wr_en) begin
			r_fifo_mem[r_wr_ptr[FIFO_PTR_WIDTH-1:0]] <= r_wr_data;
		end
	end

	// R FIFO read in S domain
	wire r_rd_en = S_AXI_RVALID && S_AXI_RREADY;
	wire [R_FIFO_WIDTH-1:0] r_rd_data = r_fifo_mem[r_rd_ptr[FIFO_PTR_WIDTH-1:0]];

	// R FIFO full/empty
	wire r_full = (r_wr_ptr[FIFO_PTR_WIDTH] != r_rd_ptr_sync_m[FIFO_PTR_WIDTH]) && 
	               (r_wr_ptr[FIFO_PTR_WIDTH-1:0] == r_rd_ptr_sync_m[FIFO_PTR_WIDTH-1:0]);
	wire r_empty = (r_wr_ptr_sync_s[FIFO_PTR_WIDTH] == r_rd_ptr[FIFO_PTR_WIDTH]) && 
	               (r_wr_ptr_sync_s[FIFO_PTR_WIDTH-1:0] == r_rd_ptr[FIFO_PTR_WIDTH-1:0]);

	assign M_AXI_RREADY = !r_full;
	assign S_AXI_RVALID = !r_empty;
	assign S_AXI_RID = r_rd_data[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_RDATA = r_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign S_AXI_RRESP = r_rd_data[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 1:C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH];
	assign S_AXI_RLAST = r_rd_data[R_FIFO_WIDTH-1];

endmodule
