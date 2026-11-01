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
	localparam integer FIFO_PTR_W = LGFIFO;
	localparam integer AW_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_W = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_W = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_W = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Reset synchronization
	reg [1:0] m_reset_sync;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN)
			m_reset_sync <= 2'b00;
		else
			m_reset_sync <= {m_reset_sync[0], 1'b1};
	end
	assign M_AXI_ARESETN = m_reset_sync[1];

	// AW channel: S to M
	reg [AW_FIFO_W-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] aw_wr_ptr, aw_rd_ptr;
	wire aw_wr_en, aw_rd_en;
	wire aw_full, aw_empty;
	wire [AW_FIFO_W-1:0] aw_wr_data;
	wire [AW_FIFO_W-1:0] aw_rd_data;

	assign aw_wr_data = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
	assign aw_full = (aw_wr_ptr[FIFO_PTR_W] != aw_rd_ptr[FIFO_PTR_W]) && (aw_wr_ptr[FIFO_PTR_W-1:0] == aw_rd_ptr[FIFO_PTR_W-1:0]);
	assign aw_empty = (aw_wr_ptr == aw_rd_ptr);
	assign aw_wr_en = S_AXI_AWVALID && !aw_full;
	assign S_AXI_AWREADY = !aw_full;

	always @(posedge S_AXI_ACLK) begin
		if (aw_wr_en) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_PTR_W-1:0]] <= aw_wr_data;
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
		end
	end

	// AW read side in M clock domain
	reg [AW_FIFO_W-1:0] aw_rd_data_reg;
	always @(posedge M_AXI_ACLK) begin
		if (aw_rd_en) begin
			aw_rd_data_reg <= aw_fifo_mem[aw_rd_ptr[FIFO_PTR_W-1:0]];
			aw_rd_ptr <= aw_rd_ptr + 1'b1;
		end
	end
	assign aw_rd_data = aw_rd_data_reg;

	// AW output in M domain
	reg [C_S_AXI_ID_WIDTH-1:0] m_awid;
	reg [C_S_AXI_ADDR_WIDTH-1:0] m_awaddr;
	reg [7:0] m_awlen;
	reg [2:0] m_awsize;
	reg [1:0] m_awburst;
	reg m_awlock;
	reg [3:0] m_awcache;
	reg [2:0] m_awprot;
	reg [3:0] m_awqos;
	reg m_awvalid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_awvalid <= 1'b0;
		end else begin
			if (m_awvalid && M_AXI_AWREADY) begin
				m_awvalid <= 1'b0;
			end else if (!m_awvalid && !aw_empty) begin
				m_awid    <= aw_rd_data[C_S_AXI_ID_WIDTH-1:0];
				m_awaddr  <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
				m_awlen   <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH];
				m_awsize  <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+8];
				m_awburst <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+11];
				m_awlock  <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+13];
				m_awcache <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+14];
				m_awprot  <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+20:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+18];
				m_awqos   <= aw_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+24:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+21];
				m_awvalid <= 1'b1;
			end
		end
	end

	assign M_AXI_AWID    = m_awid;
	assign M_AXI_AWADDR  = m_awaddr;
	assign M_AXI_AWLEN   = m_awlen;
	assign M_AXI_AWSIZE  = m_awsize;
	assign M_AXI_AWBURST = m_awburst;
	assign M_AXI_AWLOCK  = m_awlock;
	assign M_AXI_AWCACHE = m_awcache;
	assign M_AXI_AWPROT  = m_awprot;
	assign M_AXI_AWQOS   = m_awqos;
	assign M_AXI_AWVALID = m_awvalid;

	assign aw_rd_en = m_awvalid && M_AXI_AWREADY;

	// W channel: S to M
	reg [W_FIFO_W-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] w_wr_ptr, w_rd_ptr;
	wire w_wr_en, w_rd_en;
	wire w_full, w_empty;
	wire [W_FIFO_W-1:0] w_wr_data;
	wire [W_FIFO_W-1:0] w_rd_data;

	assign w_wr_data = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
	assign w_full = (w_wr_ptr[FIFO_PTR_W] != w_rd_ptr[FIFO_PTR_W]) && (w_wr_ptr[FIFO_PTR_W-1:0] == w_rd_ptr[FIFO_PTR_W-1:0]);
	assign w_empty = (w_wr_ptr == w_rd_ptr);
	assign w_wr_en = S_AXI_WVALID && !w_full;
	assign S_AXI_WREADY = !w_full;

	always @(posedge S_AXI_ACLK) begin
		if (w_wr_en) begin
			w_fifo_mem[w_wr_ptr[FIFO_PTR_W-1:0]] <= w_wr_data;
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// W read side in M clock domain
	reg [W_FIFO_W-1:0] w_rd_data_reg;
	always @(posedge M_AXI_ACLK) begin
		if (w_rd_en) begin
			w_rd_data_reg <= w_fifo_mem[w_rd_ptr[FIFO_PTR_W-1:0]];
			w_rd_ptr <= w_rd_ptr + 1'b1;
		end
	end
	assign w_rd_data = w_rd_data_reg;

	// W output in M domain - hold one extra clock
	reg [C_S_AXI_DATA_WIDTH-1:0] m_wdata;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] m_wstrb;
	reg m_wlast;
	reg m_wvalid;
	reg w_hold;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_wvalid <= 1'b0;
			w_hold   <= 1'b0;
		end else begin
			if (m_wvalid && M_AXI_WREADY) begin
				m_wvalid <= 1'b0;
				w_hold   <= 1'b0;
			end else if (!m_wvalid && !w_empty) begin
				m_wdata <= w_rd_data[C_S_AXI_DATA_WIDTH-1:0];
				m_wstrb <= w_rd_data[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8)-1:C_S_AXI_DATA_WIDTH];
				m_wlast <= w_rd_data[W_FIFO_W-1];
				m_wvalid <= 1'b1;
				w_hold   <= 1'b1;
			end
		end
	end

	assign M_AXI_WDATA  = m_wdata;
	assign M_AXI_WSTRB  = m_wstrb;
	assign M_AXI_WLAST  = m_wlast;
	assign M_AXI_WVALID = m_wvalid;

	assign w_rd_en = m_wvalid && M_AXI_WREADY;

	// B channel: M to S
	reg [B_FIFO_W-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] b_wr_ptr, b_rd_ptr;
	wire b_wr_en, b_rd_en;
	wire b_full, b_empty;
	wire [B_FIFO_W-1:0] b_wr_data;
	wire [B_FIFO_W-1:0] b_rd_data;

	assign b_wr_data = {M_AXI_BID, M_AXI_BRESP};
	assign b_full = (b_wr_ptr[FIFO_PTR_W] != b_rd_ptr[FIFO_PTR_W]) && (b_wr_ptr[FIFO_PTR_W-1:0] == b_rd_ptr[FIFO_PTR_W-1:0]);
	assign b_empty = (b_wr_ptr == b_rd_ptr);
	assign b_wr_en = M_AXI_BVALID && !b_full;
	assign M_AXI_BREADY = !b_full;

	always @(posedge M_AXI_ACLK) begin
		if (b_wr_en) begin
			b_fifo_mem[b_wr_ptr[FIFO_PTR_W-1:0]] <= b_wr_data;
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// B read side in S clock domain
	reg [B_FIFO_W-1:0] b_rd_data_reg;
	always @(posedge S_AXI_ACLK) begin
		if (b_rd_en) begin
			b_rd_data_reg <= b_fifo_mem[b_rd_ptr[FIFO_PTR_W-1:0]];
			b_rd_ptr <= b_rd_ptr + 1'b1;
		end
	end
	assign b_rd_data = b_rd_data_reg;

	// B output in S domain
	reg [C_S_AXI_ID_WIDTH-1:0] s_bid;
	reg [1:0] s_bresp;
	reg s_bvalid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bvalid <= 1'b0;
		end else begin
			if (s_bvalid && S_AXI_BREADY) begin
				s_bvalid <= 1'b0;
			end else if (!s_bvalid && !b_empty) begin
				s_bid    <= b_rd_data[C_S_AXI_ID_WIDTH-1:0];
				s_bresp  <= b_rd_data[C_S_AXI_ID_WIDTH+1:C_S_AXI_ID_WIDTH];
				s_bvalid <= 1'b1;
			end
		end
	end

	assign S_AXI_BID    = s_bid;
	assign S_AXI_BRESP  = s_bresp;
	assign S_AXI_BVALID = s_bvalid;

	assign b_rd_en = s_bvalid && S_AXI_BREADY;

	// AR channel: S to M
	reg [AR_FIFO_W-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] ar_wr_ptr, ar_rd_ptr;
	wire ar_wr_en, ar_rd_en;
	wire ar_full, ar_empty;
	wire [AR_FIFO_W-1:0] ar_wr_data;
	wire [AR_FIFO_W-1:0] ar_rd_data;

	assign ar_wr_data = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
	assign ar_full = (ar_wr_ptr[FIFO_PTR_W] != ar_rd_ptr[FIFO_PTR_W]) && (ar_wr_ptr[FIFO_PTR_W-1:0] == ar_rd_ptr[FIFO_PTR_W-1:0]);
	assign ar_empty = (ar_wr_ptr == ar_rd_ptr);
	assign ar_wr_en = S_AXI_ARVALID && !ar_full;
	assign S_AXI_ARREADY = !ar_full;

	always @(posedge S_AXI_ACLK) begin
		if (ar_wr_en) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_PTR_W-1:0]] <= ar_wr_data;
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
		end
	end

	// AR read side in M clock domain
	reg [AR_FIFO_W-1:0] ar_rd_data_reg;
	always @(posedge M_AXI_ACLK) begin
		if (ar_rd_en) begin
			ar_rd_data_reg <= ar_fifo_mem[ar_rd_ptr[FIFO_PTR_W-1:0]];
			ar_rd_ptr <= ar_rd_ptr + 1'b1;
		end
	end
	assign ar_rd_data = ar_rd_data_reg;

	// AR output in M domain
	reg [C_S_AXI_ID_WIDTH-1:0] m_arid;
	reg [C_S_AXI_ADDR_WIDTH-1:0] m_araddr;
	reg [7:0] m_arlen;
	reg [2:0] m_arsize;
	reg [1:0] m_arburst;
	reg m_arlock;
	reg [3:0] m_arcache;
	reg [2:0] m_arprot;
	reg [3:0] m_arqos;
	reg m_arvalid;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_arvalid <= 1'b0;
		end else begin
			if (m_arvalid && M_AXI_ARREADY) begin
				m_arvalid <= 1'b0;
			end else if (!m_arvalid && !ar_empty) begin
				m_arid    <= ar_rd_data[C_S_AXI_ID_WIDTH-1:0];
				m_araddr  <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
				m_arlen   <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH];
				m_arsize  <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+10:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+8];
				m_arburst <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+12:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+11];
				m_arlock  <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+13];
				m_arcache <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+17:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+14];
				m_arprot  <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+20:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+18];
				m_arqos   <= ar_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+24:C_S_AXI_ID_WIDTH+C_S_AXI_ADDR_WIDTH+21];
				m_arvalid <= 1'b1;
			end
		end
	end

	assign M_AXI_ARID    = m_arid;
	assign M_AXI_ARADDR  = m_araddr;
	assign M_AXI_ARLEN   = m_arlen;
	assign M_AXI_ARSIZE  = m_arsize;
	assign M_AXI_ARBURST = m_arburst;
	assign M_AXI_ARLOCK  = m_arlock;
	assign M_AXI_ARCACHE = m_arcache;
	assign M_AXI_ARPROT  = m_arprot;
	assign M_AXI_ARQOS   = m_arqos;
	assign M_AXI_ARVALID = m_arvalid;

	assign ar_rd_en = m_arvalid && M_AXI_ARREADY;

	// R channel: M to S
	reg [R_FIFO_W-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] r_wr_ptr, r_rd_ptr;
	wire r_wr_en, r_rd_en;
	wire r_full, r_empty;
	wire [R_FIFO_W-1:0] r_wr_data;
	wire [R_FIFO_W-1:0] r_rd_data;

	assign r_wr_data = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};
	assign r_full = (r_wr_ptr[FIFO_PTR_W] != r_rd_ptr[FIFO_PTR_W]) && (r_wr_ptr[FIFO_PTR_W-1:0] == r_rd_ptr[FIFO_PTR_W-1:0]);
	assign r_empty = (r_wr_ptr == r_rd_ptr);
	assign r_wr_en = M_AXI_RVALID && !r_full;
	assign M_AXI_RREADY = !r_full;

	always @(posedge M_AXI_ACLK) begin
		if (r_wr_en) begin
			r_fifo_mem[r_wr_ptr[FIFO_PTR_W-1:0]] <= r_wr_data;
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	// R read side in S clock domain
	reg [R_FIFO_W-1:0] r_rd_data_reg;
	always @(posedge S_AXI_ACLK) begin
		if (r_rd_en) begin
			r_rd_data_reg <= r_fifo_mem[r_rd_ptr[FIFO_PTR_W-1:0]];
			r_rd_ptr <= r_rd_ptr + 1'b1;
		end
	end
	assign r_rd_data = r_rd_data_reg;

	// R output in S domain
	reg [C_S_AXI_ID_WIDTH-1:0] s_rid;
	reg [C_S_AXI_DATA_WIDTH-1:0] s_rdata;
	reg [1:0] s_rresp;
	reg s_rlast;
	reg s_rvalid;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rvalid <= 1'b0;
		end else begin
			if (s_rvalid && S_AXI_RREADY) begin
				s_rvalid <= 1'b0;
			end else if (!s_rvalid && !r_empty) begin
				s_rid    <= r_rd_data[C_S_AXI_ID_WIDTH-1:0];
				s_rdata  <= r_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH-1:C_S_AXI_ID_WIDTH];
				s_rresp  <= r_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH+1:C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH];
				s_rlast  <= r_rd_data[R_FIFO_W-1];
				s_rvalid <= 1'b1;
			end
		end
	end

	assign S_AXI_RID    = s_rid;
	assign S_AXI_RDATA  = s_rdata;
	assign S_AXI_RRESP  = s_rresp;
	assign S_AXI_RLAST  = s_rlast;
	assign S_AXI_RVALID = s_rvalid;

	assign r_rd_en = s_rvalid && S_AXI_RREADY;

endmodule
