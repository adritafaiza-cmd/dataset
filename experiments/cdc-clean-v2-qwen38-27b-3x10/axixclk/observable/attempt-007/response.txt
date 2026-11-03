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
	localparam integer AW_FIFO_DEPTH = (1 << LGFIFO);
	localparam integer AW_FIFO_PTR_W = LGFIFO;
	localparam integer W_FIFO_DEPTH = (1 << LGFIFO);
	localparam integer W_FIFO_PTR_W = LGFIFO;
	localparam integer B_FIFO_DEPTH = (1 << LGFIFO);
	localparam integer B_FIFO_PTR_W = LGFIFO;
	localparam integer AR_FIFO_DEPTH = (1 << LGFIFO);
	localparam integer AR_FIFO_PTR_W = LGFIFO;
	localparam integer R_FIFO_DEPTH = (1 << LGFIFO);
	localparam integer R_FIFO_PTR_W = LGFIFO;

	localparam integer AW_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_DATA_W = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_DATA_W = C_S_AXI_ID_WIDTH + 2;
	localparam integer AR_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer R_DATA_W = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

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

	// AW channel: S side
	reg [AW_FIFO_DEPTH-1:0][AW_DATA_W-1:0] aw_fifo_mem;
	reg [AW_FIFO_PTR_W:0] aw_wr_ptr, aw_rd_ptr;
	wire aw_full = (aw_wr_ptr[AW_FIFO_PTR_W] != aw_rd_ptr[AW_FIFO_PTR_W]) && 
	               (aw_wr_ptr[AW_FIFO_PTR_W-1:0] == aw_rd_ptr[AW_FIFO_PTR_W-1:0]);
	wire aw_empty = (aw_wr_ptr == aw_rd_ptr);

	wire aw_write = S_AXI_AWVALID && S_AXI_AWREADY;
	assign S_AXI_AWREADY = !aw_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= 0;
		end else if (aw_write) begin
			aw_fifo_mem[aw_wr_ptr[AW_FIFO_PTR_W-1:0]] <= {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
			aw_wr_ptr <= aw_wr_ptr + 1;
		end
	end

	// AW channel: M side
	reg [AW_FIFO_PTR_W:0] aw_m_wr_ptr, aw_m_rd_ptr;
	wire aw_m_full = (aw_m_wr_ptr[AW_FIFO_PTR_W] != aw_m_rd_ptr[AW_FIFO_PTR_W]) && 
	               (aw_m_wr_ptr[AW_FIFO_PTR_W-1:0] == aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]);
	wire aw_m_empty = (aw_m_wr_ptr == aw_m_rd_ptr);

	// Synchronizers for AW pointers
	reg [AW_FIFO_PTR_W:0] aw_wr_ptr_sync1, aw_wr_ptr_sync2;
	reg [AW_FIFO_PTR_W:0] aw_rd_ptr_sync1, aw_rd_ptr_sync2;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_wr_ptr_sync1 <= 0;
			aw_wr_ptr_sync2 <= 0;
			aw_rd_ptr_sync1 <= 0;
			aw_rd_ptr_sync2 <= 0;
		end else begin
			aw_wr_ptr_sync1 <= aw_wr_ptr;
			aw_wr_ptr_sync2 <= aw_wr_ptr_sync1;
			aw_rd_ptr_sync1 <= aw_rd_ptr;
			aw_rd_ptr_sync2 <= aw_rd_ptr_sync1;
		end
	end

	wire aw_m_full_sync = (aw_wr_ptr_sync2[AW_FIFO_PTR_W] != aw_rd_ptr_sync2[AW_FIFO_PTR_W]) && 
	                      (aw_wr_ptr_sync2[AW_FIFO_PTR_W-1:0] == aw_rd_ptr_sync2[AW_FIFO_PTR_W-1:0]);

	// Synchronizers for AW M-side pointers back to S
	reg [AW_FIFO_PTR_W:0] aw_m_wr_ptr_sync1, aw_m_wr_ptr_sync2;
	reg [AW_FIFO_PTR_W:0] aw_m_rd_ptr_sync1, aw_m_rd_ptr_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_m_wr_ptr_sync1 <= 0;
			aw_m_wr_ptr_sync2 <= 0;
			aw_m_rd_ptr_sync1 <= 0;
			aw_m_rd_ptr_sync2 <= 0;
		end else begin
			aw_m_wr_ptr_sync1 <= aw_m_wr_ptr;
			aw_m_wr_ptr_sync2 <= aw_m_wr_ptr_sync1;
			aw_m_rd_ptr_sync1 <= aw_m_rd_ptr;
			aw_m_rd_ptr_sync2 <= aw_m_rd_ptr_sync1;
		end
	end

	wire aw_m_empty_sync = (aw_m_wr_ptr_sync2 == aw_m_rd_ptr_sync2);

	// AW M-side read
	wire aw_m_read = !aw_m_empty && M_AXI_AWREADY;
	assign M_AXI_AWVALID = !aw_m_empty;
	assign M_AXI_AWID = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][AW_DATA_W-1:C_S_AXI_ADDR_WIDTH+8+3+2+1+4+3+4];
	assign M_AXI_AWADDR = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH+8];
	assign M_AXI_AWSIZE = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+8:C_S_AXI_ADDR_WIDTH+10];
	assign M_AXI_AWBURST = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_AWLOCK = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_AWCACHE = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ADDR_WIDTH+15];
	assign M_AXI_AWPROT = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+15:C_S_AXI_ADDR_WIDTH+17];
	assign M_AXI_AWQOS = aw_fifo_mem[aw_m_rd_ptr[AW_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ADDR_WIDTH+20];

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			aw_m_rd_ptr <= 0;
		end else if (aw_m_read) begin
			aw_m_rd_ptr <= aw_m_rd_ptr + 1;
		end
	end

	// W channel: S side
	reg [W_FIFO_DEPTH-1:0][W_DATA_W-1:0] w_fifo_mem;
	reg [W_FIFO_PTR_W:0] w_wr_ptr, w_rd_ptr;
	wire w_full = (w_wr_ptr[W_FIFO_PTR_W] != w_rd_ptr[W_FIFO_PTR_W]) && 
	               (w_wr_ptr[W_FIFO_PTR_W-1:0] == w_rd_ptr[W_FIFO_PTR_W-1:0]);
	wire w_empty = (w_wr_ptr == w_rd_ptr);

	wire w_write = S_AXI_WVALID && S_AXI_WREADY;
	assign S_AXI_WREADY = !w_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= 0;
		end else if (w_write) begin
			w_fifo_mem[w_wr_ptr[W_FIFO_PTR_W-1:0]] <= {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
			w_wr_ptr <= w_wr_ptr + 1;
		end
	end

	// W channel: M side
	reg [W_FIFO_PTR_W:0] w_m_wr_ptr, w_m_rd_ptr;
	wire w_m_full = (w_m_wr_ptr[W_FIFO_PTR_W] != w_m_rd_ptr[W_FIFO_PTR_W]) && 
	               (w_m_wr_ptr[W_FIFO_PTR_W-1:0] == w_m_rd_ptr[W_FIFO_PTR_W-1:0]);
	wire w_m_empty = (w_m_wr_ptr == w_m_rd_ptr);

	// Synchronizers for W pointers
	reg [W_FIFO_PTR_W:0] w_wr_ptr_sync1, w_wr_ptr_sync2;
	reg [W_FIFO_PTR_W:0] w_rd_ptr_sync1, w_rd_ptr_sync2;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_wr_ptr_sync1 <= 0;
			w_wr_ptr_sync2 <= 0;
			w_rd_ptr_sync1 <= 0;
			w_rd_ptr_sync2 <= 0;
		end else begin
			w_wr_ptr_sync1 <= w_wr_ptr;
			w_wr_ptr_sync2 <= w_wr_ptr_sync1;
			w_rd_ptr_sync1 <= w_rd_ptr;
			w_rd_ptr_sync2 <= w_rd_ptr_sync1;
		end
	end

	wire w_m_full_sync = (w_wr_ptr_sync2[W_FIFO_PTR_W] != w_rd_ptr_sync2[W_FIFO_PTR_W]) && 
	                      (w_wr_ptr_sync2[W_FIFO_PTR_W-1:0] == w_rd_ptr_sync2[W_FIFO_PTR_W-1:0]);

	// Synchronizers for W M-side pointers back to S
	reg [W_FIFO_PTR_W:0] w_m_wr_ptr_sync1, w_m_wr_ptr_sync2;
	reg [W_FIFO_PTR_W:0] w_m_rd_ptr_sync1, w_m_rd_ptr_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_m_wr_ptr_sync1 <= 0;
			w_m_wr_ptr_sync2 <= 0;
			w_m_rd_ptr_sync1 <= 0;
			w_m_rd_ptr_sync2 <= 0;
		end else begin
			w_m_wr_ptr_sync1 <= w_m_wr_ptr;
			w_m_wr_ptr_sync2 <= w_m_wr_ptr_sync1;
			w_m_rd_ptr_sync1 <= w_m_rd_ptr;
			w_m_rd_ptr_sync2 <= w_m_rd_ptr_sync1;
		end
	end

	wire w_m_empty_sync = (w_m_wr_ptr_sync2 == w_m_rd_ptr_sync2);

	// W M-side: hold one extra M_AXI clock before M_AXI_WVALID
	reg w_m_valid_reg;
	reg [W_DATA_W-1:0] w_m_data_reg;
	reg w_m_last_reg;

	wire w_m_read = !w_m_empty && M_AXI_WREADY;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			w_m_wr_ptr <= 0;
			w_m_rd_ptr <= 0;
			w_m_valid_reg <= 1'b0;
			w_m_data_reg <= 0;
			w_m_last_reg <= 1'b0;
		end else begin
			// Write to M-side FIFO from S-side FIFO
			if (!w_m_full_sync && !w_empty_sync) begin
				w_fifo_mem[w_m_wr_ptr[W_FIFO_PTR_W-1:0]] <= w_fifo_mem[w_rd_ptr[W_FIFO_PTR_W-1:0]];
				w_m_wr_ptr <= w_m_wr_ptr + 1;
				w_rd_ptr <= w_rd_ptr + 1;
			end

			// Read from M-side FIFO
			if (w_m_read) begin
				w_m_rd_ptr <= w_m_rd_ptr + 1;
			end

			// Hold one extra clock
			if (w_m_read) begin
				w_m_valid_reg <= 1'b0;
			end else if (!w_m_empty) begin
				w_m_valid_reg <= 1'b1;
				w_m_data_reg <= w_fifo_mem[w_m_rd_ptr[W_FIFO_PTR_W-1:0]];
				w_m_last_reg <= w_fifo_mem[w_m_rd_ptr[W_FIFO_PTR_W-1:0]][0];
			end
		end
	end

	assign M_AXI_WVALID = w_m_valid_reg;
	assign M_AXI_WDATA = w_m_data_reg[C_S_AXI_DATA_WIDTH-1:0];
	assign M_AXI_WSTRB = w_m_data_reg[C_S_AXI_DATA_WIDTH:C_S_AXI_DATA_WIDTH+(C_S_AXI_DATA_WIDTH/8)-1];
	assign M_AXI_WLAST = w_m_last_reg;

	// B channel: M side
	reg [B_FIFO_DEPTH-1:0][B_DATA_W-1:0] b_fifo_mem;
	reg [B_FIFO_PTR_W:0] b_wr_ptr, b_rd_ptr;
	wire b_full = (b_wr_ptr[B_FIFO_PTR_W] != b_rd_ptr[B_FIFO_PTR_W]) && 
	               (b_wr_ptr[B_FIFO_PTR_W-1:0] == b_rd_ptr[B_FIFO_PTR_W-1:0]);
	wire b_empty = (b_wr_ptr == b_rd_ptr);

	wire b_write = M_AXI_BVALID && M_AXI_BREADY;
	assign M_AXI_BREADY = !b_full;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_wr_ptr <= 0;
		end else if (b_write) begin
			b_fifo_mem[b_wr_ptr[B_FIFO_PTR_W-1:0]] <= {M_AXI_BID, M_AXI_BRESP};
			b_wr_ptr <= b_wr_ptr + 1;
		end
	end

	// B channel: S side
	reg [B_FIFO_PTR_W:0] b_m_wr_ptr, b_m_rd_ptr;
	wire b_m_full = (b_m_wr_ptr[B_FIFO_PTR_W] != b_m_rd_ptr[B_FIFO_PTR_W]) && 
	               (b_m_wr_ptr[B_FIFO_PTR_W-1:0] == b_m_rd_ptr[B_FIFO_PTR_W-1:0]);
	wire b_m_empty = (b_m_wr_ptr == b_m_rd_ptr);

	// Synchronizers for B pointers
	reg [B_FIFO_PTR_W:0] b_wr_ptr_sync1, b_wr_ptr_sync2;
	reg [B_FIFO_PTR_W:0] b_rd_ptr_sync1, b_rd_ptr_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_wr_ptr_sync1 <= 0;
			b_wr_ptr_sync2 <= 0;
			b_rd_ptr_sync1 <= 0;
			b_rd_ptr_sync2 <= 0;
		end else begin
			b_wr_ptr_sync1 <= b_wr_ptr;
			b_wr_ptr_sync2 <= b_wr_ptr_sync1;
			b_rd_ptr_sync1 <= b_rd_ptr;
			b_rd_ptr_sync2 <= b_rd_ptr_sync1;
		end
	end

	wire b_m_full_sync = (b_wr_ptr_sync2[B_FIFO_PTR_W] != b_rd_ptr_sync2[B_FIFO_PTR_W]) && 
	                      (b_wr_ptr_sync2[B_FIFO_PTR_W-1:0] == b_rd_ptr_sync2[B_FIFO_PTR_W-1:0]);

	// Synchronizers for B S-side pointers back to M
	reg [B_FIFO_PTR_W:0] b_m_wr_ptr_sync1, b_m_wr_ptr_sync2;
	reg [B_FIFO_PTR_W:0] b_m_rd_ptr_sync1, b_m_rd_ptr_sync2;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			b_m_wr_ptr_sync1 <= 0;
			b_m_wr_ptr_sync2 <= 0;
			b_m_rd_ptr_sync1 <= 0;
			b_m_rd_ptr_sync2 <= 0;
		end else begin
			b_m_wr_ptr_sync1 <= b_m_wr_ptr;
			b_m_wr_ptr_sync2 <= b_m_wr_ptr_sync1;
			b_m_rd_ptr_sync1 <= b_m_rd_ptr;
			b_m_rd_ptr_sync2 <= b_m_rd_ptr_sync1;
		end
	end

	wire b_m_empty_sync = (b_m_wr_ptr_sync2 == b_m_rd_ptr_sync2);

	// B S-side read
	wire b_m_read = !b_m_empty && S_AXI_BREADY;
	assign S_AXI_BVALID = !b_m_empty;
	assign S_AXI_BID = b_fifo_mem[b_m_rd_ptr[B_FIFO_PTR_W-1:0]][B_DATA_W-1:2];
	assign S_AXI_BRESP = b_fifo_mem[b_m_rd_ptr[B_FIFO_PTR_W-1:0]][1:0];

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_m_rd_ptr <= 0;
		end else if (b_m_read) begin
			b_m_rd_ptr <= b_m_rd_ptr + 1;
		end
	end

	// AR channel: S side
	reg [AR_FIFO_DEPTH-1:0][AR_DATA_W-1:0] ar_fifo_mem;
	reg [AR_FIFO_PTR_W:0] ar_wr_ptr, ar_rd_ptr;
	wire ar_full = (ar_wr_ptr[AR_FIFO_PTR_W] != ar_rd_ptr[AR_FIFO_PTR_W]) && 
	               (ar_wr_ptr[AR_FIFO_PTR_W-1:0] == ar_rd_ptr[AR_FIFO_PTR_W-1:0]);
	wire ar_empty = (ar_wr_ptr == ar_rd_ptr);

	wire ar_write = S_AXI_ARVALID && S_AXI_ARREADY;
	assign S_AXI_ARREADY = !ar_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= 0;
		end else if (ar_write) begin
			ar_fifo_mem[ar_wr_ptr[AR_FIFO_PTR_W-1:0]] <= {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
			ar_wr_ptr <= ar_wr_ptr + 1;
		end
	end

	// AR channel: M side
	reg [AR_FIFO_PTR_W:0] ar_m_wr_ptr, ar_m_rd_ptr;
	wire ar_m_full = (ar_m_wr_ptr[AR_FIFO_PTR_W] != ar_m_rd_ptr[AR_FIFO_PTR_W]) && 
	               (ar_m_wr_ptr[AR_FIFO_PTR_W-1:0] == ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]);
	wire ar_m_empty = (ar_m_wr_ptr == ar_m_rd_ptr);

	// Synchronizers for AR pointers
	reg [AR_FIFO_PTR_W:0] ar_wr_ptr_sync1, ar_wr_ptr_sync2;
	reg [AR_FIFO_PTR_W:0] ar_rd_ptr_sync1, ar_rd_ptr_sync2;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_wr_ptr_sync1 <= 0;
			ar_wr_ptr_sync2 <= 0;
			ar_rd_ptr_sync1 <= 0;
			ar_rd_ptr_sync2 <= 0;
		end else begin
			ar_wr_ptr_sync1 <= ar_wr_ptr;
			ar_wr_ptr_sync2 <= ar_wr_ptr_sync1;
			ar_rd_ptr_sync1 <= ar_rd_ptr;
			ar_rd_ptr_sync2 <= ar_rd_ptr_sync1;
		end
	end

	wire ar_m_full_sync = (ar_wr_ptr_sync2[AR_FIFO_PTR_W] != ar_rd_ptr_sync2[AR_FIFO_PTR_W]) && 
	                      (ar_wr_ptr_sync2[AR_FIFO_PTR_W-1:0] == ar_rd_ptr_sync2[AR_FIFO_PTR_W-1:0]);

	// Synchronizers for AR M-side pointers back to S
	reg [AR_FIFO_PTR_W:0] ar_m_wr_ptr_sync1, ar_m_wr_ptr_sync2;
	reg [AR_FIFO_PTR_W:0] ar_m_rd_ptr_sync1, ar_m_rd_ptr_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_m_wr_ptr_sync1 <= 0;
			ar_m_wr_ptr_sync2 <= 0;
			ar_m_rd_ptr_sync1 <= 0;
			ar_m_rd_ptr_sync2 <= 0;
		end else begin
			ar_m_wr_ptr_sync1 <= ar_m_wr_ptr;
			ar_m_wr_ptr_sync2 <= ar_m_wr_ptr_sync1;
			ar_m_rd_ptr_sync1 <= ar_m_rd_ptr;
			ar_m_rd_ptr_sync2 <= ar_m_rd_ptr_sync1;
		end
	end

	wire ar_m_empty_sync = (ar_m_wr_ptr_sync2 == ar_m_rd_ptr_sync2);

	// AR M-side read
	wire ar_m_read = !ar_m_empty && M_AXI_ARREADY;
	assign M_AXI_ARVALID = !ar_m_empty;
	assign M_AXI_ARID = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][AR_DATA_W-1:C_S_AXI_ADDR_WIDTH+8+3+2+1+4+3+4];
	assign M_AXI_ARADDR = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH+8];
	assign M_AXI_ARSIZE = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+8:C_S_AXI_ADDR_WIDTH+10];
	assign M_AXI_ARBURST = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_ARLOCK = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+11];
	assign M_AXI_ARCACHE = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ADDR_WIDTH+15];
	assign M_AXI_ARPROT = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+15:C_S_AXI_ADDR_WIDTH+17];
	assign M_AXI_ARQOS = ar_fifo_mem[ar_m_rd_ptr[AR_FIFO_PTR_W-1:0]][C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ADDR_WIDTH+20];

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			ar_m_rd_ptr <= 0;
		end else if (ar_m_read) begin
			ar_m_rd_ptr <= ar_m_rd_ptr + 1;
		end
	end

	// R channel: M side
	reg [R_FIFO_DEPTH-1:0][R_DATA_W-1:0] r_fifo_mem;
	reg [R_FIFO_PTR_W:0] r_wr_ptr, r_rd_ptr;
	wire r_full = (r_wr_ptr[R_FIFO_PTR_W] != r_rd_ptr[R_FIFO_PTR_W]) && 
	               (r_wr_ptr[R_FIFO_PTR_W-1:0] == r_rd_ptr[R_FIFO_PTR_W-1:0]);
	wire r_empty = (r_wr_ptr == r_rd_ptr);

	wire r_write = M_AXI_RVALID && M_AXI_RREADY;
	assign M_AXI_RREADY = !r_full;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			r_wr_ptr <= 0;
		end else if (r_write) begin
			r_fifo_mem[r_wr_ptr[R_FIFO_PTR_W-1:0]] <= {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};
			r_wr_ptr <= r_wr_ptr + 1;
		end
	end

	// R channel: S side
	reg [R_FIFO_PTR_W:0] r_m_wr_ptr, r_m_rd_ptr;
	wire r_m_full = (r_m_wr_ptr[R_FIFO_PTR_W] != r_m_rd_ptr[R_FIFO_PTR_W]) && 
	               (r_m_wr_ptr[R_FIFO_PTR_W-1:0] == r_m_rd_ptr[R_FIFO_PTR_W-1:0]);
	wire r_m_empty = (r_m_wr_ptr == r_m_rd_ptr);

	// Synchronizers for R pointers
	reg [R_FIFO_PTR_W:0] r_wr_ptr_sync1, r_wr_ptr_sync2;
	reg [R_FIFO_PTR_W:0] r_rd_ptr_sync1, r_rd_ptr_sync2;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_wr_ptr_sync1 <= 0;
			r_wr_ptr_sync2 <= 0;
			r_rd_ptr_sync1 <= 0;
			r_rd_ptr_sync2 <= 0;
		end else begin
			r_wr_ptr_sync1 <= r_wr_ptr;
			r_wr_ptr_sync2 <= r_wr_ptr_sync1;
			r_rd_ptr_sync1 <= r_rd_ptr;
			r_rd_ptr_sync2 <= r_rd_ptr_sync1;
		end
	end

	wire r_m_full_sync = (r_wr_ptr_sync2[R_FIFO_PTR_W] != r_rd_ptr_sync2[R_FIFO_PTR_W]) && 
	                      (r_wr_ptr_sync2[R_FIFO_PTR_W-1:0] == r_rd_ptr_sync2[R_FIFO_PTR_W-1:0]);

	// Synchronizers for R S-side pointers back to M
	reg [R_FIFO_PTR_W:0] r_m_wr_ptr_sync1, r_m_wr_ptr_sync2;
	reg [R_FIFO_PTR_W:0] r_m_rd_ptr_sync1, r_m_rd_ptr_sync2;

	always @(posedge M_AXI_ACLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			r_m_wr_ptr_sync1 <= 0;
			r_m_wr_ptr_sync2 <= 0;
			r_m_rd_ptr_sync1 <= 0;
			r_m_rd_ptr_sync2 <= 0;
		end else begin
			r_m_wr_ptr_sync1 <= r_m_wr_ptr;
			r_m_wr_ptr_sync2 <= r_m_wr_ptr_sync1;
			r_m_rd_ptr_sync1 <= r_m_rd_ptr;
			r_m_rd_ptr_sync2 <= r_m_rd_ptr_sync1;
		end
	end

	wire r_m_empty_sync = (r_m_wr_ptr_sync2 == r_m_rd_ptr_sync2);

	// R S-side read
	wire r_m_read = !r_m_empty && S_AXI_RREADY;
	assign S_AXI_RVALID = !r_m_empty;
	assign S_AXI_RID = r_fifo_mem[r_m_rd_ptr[R_FIFO_PTR_W-1:0]][R_DATA_W-1:C_S_AXI_DATA_WIDTH+2+1];
	assign S_AXI_RDATA = r_fifo_mem[r_m_rd_ptr[R_FIFO_PTR_W-1:0]][C_S_AXI_DATA_WIDTH+1:C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP = r_fifo_mem[r_m_rd_ptr[R_FIFO_PTR_W-1:0]][C_S_AXI_DATA_WIDTH-1:C_S_AXI_DATA_WIDTH-2];
	assign S_AXI_RLAST = r_fifo_mem[r_m_rd_ptr[R_FIFO_PTR_W-1:0]][0];

	always @(