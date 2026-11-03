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
	localparam integer AW_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_FIFO_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_FIFO_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer R_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

	// Reset synchronization
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end
	assign M_AXI_ARESETN = m_reset_sync[1];

	// AW channel: S to M
	reg [AW_FIFO_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr, aw_rd_ptr;
	reg aw_wr_en, aw_rd_en;
	wire aw_full, aw_empty;
	wire [AW_FIFO_WIDTH-1:0] aw_wr_data;
	wire [AW_FIFO_WIDTH-1:0] aw_rd_data;

	assign aw_wr_data = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
	assign aw_full = (aw_wr_ptr[FIFO_ADDR_WIDTH] != aw_rd_ptr[FIFO_ADDR_WIDTH]) && (aw_wr_ptr[FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign aw_empty = (aw_wr_ptr == aw_rd_ptr);
	assign aw_rd_data = aw_fifo_mem[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];

	assign S_AXI_AWREADY = !aw_full;
	assign aw_wr_en = S_AXI_AWVALID && !aw_full;

	always @(posedge S_AXI_ACLK) begin
		if (aw_wr_en) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= aw_wr_data;
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
		end
	end

	// AW read side in M clock
	reg [AW_FIFO_WIDTH-1:0] aw_m_reg;
	reg aw_m_valid;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_m_valid <= 1'b0;
			aw_rd_en <= 1'b0;
		end else begin
			aw_rd_en <= aw_m_valid && M_AXI_AWREADY;
			if (aw_rd_en) begin
				aw_m_valid <= 1'b0;
			end else if (!aw_m_valid && !aw_empty) begin
				aw_m_reg <= aw_rd_data;
				aw_m_valid <= 1'b1;
			end
		end
	end

	assign M_AXI_AWID = aw_m_reg[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_AWADDR = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_AWLEN = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 7:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWSIZE = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 10:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8];
	assign M_AXI_AWBURST = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 12:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11];
	assign M_AXI_AWLOCK = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 13];
	assign M_AXI_AWCACHE = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 17:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 14];
	assign M_AXI_AWPROT = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 20:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18];
	assign M_AXI_AWQOS = aw_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 24:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 21];
	assign M_AXI_AWVALID = aw_m_valid;

	// W channel: S to M
	reg [W_FIFO_WIDTH-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] w_wr_ptr, w_rd_ptr;
	reg w_wr_en, w_rd_en;
	wire w_full, w_empty;
	wire [W_FIFO_WIDTH-1:0] w_wr_data;
	wire [W_FIFO_WIDTH-1:0] w_rd_data;

	assign w_wr_data = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
	assign w_full = (w_wr_ptr[FIFO_ADDR_WIDTH] != w_rd_ptr[FIFO_ADDR_WIDTH]) && (w_wr_ptr[FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign w_empty = (w_wr_ptr == w_rd_ptr);
	assign w_rd_data = w_fifo_mem[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];

	assign S_AXI_WREADY = !w_full;
	assign w_wr_en = S_AXI_WVALID && !w_full;

	always @(posedge S_AXI_ACLK) begin
		if (w_wr_en) begin
			w_fifo_mem[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= w_wr_data;
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// W read side in M clock - with extra register stage
	reg [W_FIFO_WIDTH-1:0] w_m_reg1, w_m_reg2;
	reg w_m_valid1, w_m_valid2;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_m_valid1 <= 1'b0;
			w_m_valid2 <= 1'b0;
			w_rd_en <= 1'b0;
		end else begin
			w_rd_en <= w_m_valid1 && M_AXI_WREADY;
			if (w_rd_en) begin
				w_m_valid1 <= 1'b0;
				w_m_valid2 <= 1'b0;
			end else begin
				if (!w_m_valid1 && !w_empty) begin
					w_m_reg1 <= w_rd_data;
					w_m_valid1 <= 1'b1;
				end
				if (w_m_valid1 && !w_m_valid2) begin
					w_m_reg2 <= w_m_reg1;
					w_m_valid2 <= 1'b1;
				end
			end
		end
	end

	assign M_AXI_WDATA = w_m_reg2[C_S_AXI_DATA_WIDTH-1:0];
	assign M_AXI_WSTRB = w_m_reg2[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8)-1:C_S_AXI_DATA_WIDTH];
	assign M_AXI_WLAST = w_m_reg2[C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WVALID = w_m_valid2;

	// B channel: M to S
	reg [B_FIFO_WIDTH-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] b_wr_ptr, b_rd_ptr;
	reg b_wr_en, b_rd_en;
	wire b_full, b_empty;
	wire [B_FIFO_WIDTH-1:0] b_wr_data;
	wire [B_FIFO_WIDTH-1:0] b_rd_data;

	assign b_wr_data = {M_AXI_BID, M_AXI_BRESP};
	assign b_full = (b_wr_ptr[FIFO_ADDR_WIDTH] != b_rd_ptr[FIFO_ADDR_WIDTH]) && (b_wr_ptr[FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign b_empty = (b_wr_ptr == b_rd_ptr);
	assign b_rd_data = b_fifo_mem[b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];

	assign M_AXI_BREADY = !b_full;
	assign b_wr_en = M_AXI_BVALID && !b_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (b_wr_en) begin
			b_fifo_mem[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= b_wr_data;
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// B read side in S clock
	reg [B_FIFO_WIDTH-1:0] b_s_reg;
	reg b_s_valid;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_s_valid <= 1'b0;
			b_rd_en <= 1'b0;
		end else begin
			b_rd_en <= b_s_valid && S_AXI_BREADY;
			if (b_rd_en) begin
				b_s_valid <= 1'b0;
			end else if (!b_s_valid && !b_empty) begin
				b_s_reg <= b_rd_data;
				b_s_valid <= 1'b1;
			end
		end
	end

	assign S_AXI_BID = b_s_reg[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_BRESP = b_s_reg[C_S_AXI_ID_WIDTH + 1:C_S_AXI_ID_WIDTH];
	assign S_AXI_BVALID = b_s_valid;

	// AR channel: S to M
	reg [AR_FIFO_WIDTH-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] ar_wr_ptr, ar_rd_ptr;
	reg ar_wr_en, ar_rd_en;
	wire ar_full, ar_empty;
	wire [AR_FIFO_WIDTH-1:0] ar_wr_data;
	wire [AR_FIFO_WIDTH-1:0] ar_rd_data;

	assign ar_wr_data = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
	assign ar_full = (ar_wr_ptr[FIFO_ADDR_WIDTH] != ar_rd_ptr[FIFO_ADDR_WIDTH]) && (ar_wr_ptr[FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign ar_empty = (ar_wr_ptr == ar_rd_ptr);
	assign ar_rd_data = ar_fifo_mem[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];

	assign S_AXI_ARREADY = !ar_full;
	assign ar_wr_en = S_AXI_ARVALID && !ar_full;

	always @(posedge S_AXI_ACLK) begin
		if (ar_wr_en) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= ar_wr_data;
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
		end
	end

	// AR read side in M clock
	reg [AR_FIFO_WIDTH-1:0] ar_m_reg;
	reg ar_m_valid;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_m_valid <= 1'b0;
			ar_rd_en <= 1'b0;
		end else begin
			ar_rd_en <= ar_m_valid && M_AXI_ARREADY;
			if (ar_rd_en) begin
				ar_m_valid <= 1'b0;
			end else if (!ar_m_valid && !ar_empty) begin
				ar_m_reg <= ar_rd_data;
				ar_m_valid <= 1'b1;
			end
		end
	end

	assign M_AXI_ARID = ar_m_reg[C_S_AXI_ID_WIDTH-1:0];
	assign M_AXI_ARADDR = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign M_AXI_ARLEN = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 7:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARSIZE = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 10:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8];
	assign M_AXI_ARBURST = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 12:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 11];
	assign M_AXI_ARLOCK = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 13];
	assign M_AXI_ARCACHE = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 17:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 14];
	assign M_AXI_ARPROT = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 20:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18];
	assign M_AXI_ARQOS = ar_m_reg[C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 24:C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 21];
	assign M_AXI_ARVALID = ar_m_valid;

	// R channel: M to S
	reg [R_FIFO_WIDTH-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] r_wr_ptr, r_rd_ptr;
	reg r_wr_en, r_rd_en;
	wire r_full, r_empty;
	wire [R_FIFO_WIDTH-1:0] r_wr_data;
	wire [R_FIFO_WIDTH-1:0] r_rd_data;

	assign r_wr_data = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};
	assign r_full = (r_wr_ptr[FIFO_ADDR_WIDTH] != r_rd_ptr[FIFO_ADDR_WIDTH]) && (r_wr_ptr[FIFO_ADDR_WIDTH-1:0] == r_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign r_empty = (r_wr_ptr == r_rd_ptr);
	assign r_rd_data = r_fifo_mem[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];

	assign M_AXI_RREADY = !r_full;
	assign r_wr_en = M_AXI_RVALID && !r_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (r_wr_en) begin
			r_fifo_mem[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= r_wr_data;
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	// R read side in S clock
	reg [R_FIFO_WIDTH-1:0] r_s_reg;
	reg r_s_valid;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_s_valid <= 1'b0;
			r_rd_en <= 1'b0;
		end else begin
			r_rd_en <= r_s_valid && S_AXI_RREADY;
			if (r_rd_en) begin
				r_s_valid <= 1'b0;
			end else if (!r_s_valid && !r_empty) begin
				r_s_reg <= r_rd_data;
				r_s_valid <= 1'b1;
			end
		end
	end

	assign S_AXI_RID = r_s_reg[C_S_AXI_ID_WIDTH-1:0];
	assign S_AXI_RDATA = r_s_reg[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH-1:C_S_AXI_ID_WIDTH];
	assign S_AXI_RRESP = r_s_reg[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 1:C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH];
	assign S_AXI_RLAST = r_s_reg[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2];
	assign S_AXI_RVALID = r_s_valid;

endmodule
