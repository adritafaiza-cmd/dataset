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
	localparam integer AW_FIFO_DEPTH = 2**LGFIFO;
	localparam integer AW_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer W_FIFO_DEPTH = 2**LGFIFO;
	localparam integer W_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer B_FIFO_DEPTH = 2**LGFIFO;
	localparam integer B_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer AR_FIFO_DEPTH = 2**LGFIFO;
	localparam integer AR_FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer R_FIFO_DEPTH = 2**LGFIFO;
	localparam integer R_FIFO_ADDR_WIDTH = LGFIFO;

	localparam integer AW_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer W_DATA_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer B_DATA_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer AR_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer R_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;

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

	// AW channel: S to M
	reg [AW_DATA_WIDTH-1:0] aw_fifo_mem [0:AW_FIFO_DEPTH-1];
	reg [AW_FIFO_ADDR_WIDTH:0] aw_wr_ptr, aw_rd_ptr;
	reg aw_wr_en, aw_rd_en;
	wire aw_empty = (aw_wr_ptr == aw_rd_ptr);
	wire aw_full = (aw_wr_ptr[AW_FIFO_ADDR_WIDTH] != aw_rd_ptr[AW_FIFO_ADDR_WIDTH]) && 
	               (aw_wr_ptr[AW_FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[AW_FIFO_ADDR_WIDTH-1:0]);

	assign S_AXI_AWREADY = !aw_full;
	assign aw_wr_en = S_AXI_AWVALID && S_AXI_AWREADY;

	always @(posedge S_AXI_ACLK) begin
		if (aw_wr_en) begin
			aw_fifo_mem[aw_wr_ptr[AW_FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_AWID,
				S_AXI_AWADDR,
				S_AXI_AWLEN,
				S_AXI_AWSIZE,
				S_AXI_AWBURST,
				S_AXI_AWLOCK,
				S_AXI_AWCACHE,
				S_AXI_AWPROT,
				S_AXI_AWQOS
			};
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
		end
	end

	// AW read side in M clock
	reg [AW_DATA_WIDTH-1:0] aw_data_m;
	reg aw_valid_m;
	assign aw_rd_en = aw_valid_m && M_AXI_AWREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_valid_m <= 1'b0;
			aw_data_m <= {AW_DATA_WIDTH{1'b0}};
		end else begin
			if (aw_rd_en) begin
				aw_valid_m <= 1'b0;
			end else if (!aw_empty) begin
				aw_data_m <= aw_fifo_mem[aw_rd_ptr[AW_FIFO_ADDR_WIDTH-1:0]];
				aw_valid_m <= 1'b1;
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
			end
		end
	end

	assign M_AXI_AWVALID = aw_valid_m;
	assign M_AXI_AWID = aw_data_m[AW_DATA_WIDTH-1:C_S_AXI_ADDR_WIDTH+8+3+2+1+4+3+4];
	assign M_AXI_AWADDR = aw_data_m[C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH+7-C_S_AXI_ADDR_WIDTH+1];
	assign M_AXI_AWLEN = aw_data_m[C_S_AXI_ADDR_WIDTH+6:C_S_AXI_ADDR_WIDTH-1];
	assign M_AXI_AWSIZE = aw_data_m[C_S_AXI_ADDR_WIDTH-2:C_S_AXI_ADDR_WIDTH-4];
	assign M_AXI_AWBURST = aw_data_m[C_S_AXI_ADDR_WIDTH-5:C_S_AXI_ADDR_WIDTH-6];
	assign M_AXI_AWLOCK = aw_data_m[C_S_AXI_ADDR_WIDTH-7];
	assign M_AXI_AWCACHE = aw_data_m[C_S_AXI_ADDR_WIDTH-8:C_S_AXI_ADDR_WIDTH-11];
	assign M_AXI_AWPROT = aw_data_m[C_S_AXI_ADDR_WIDTH-12:C_S_AXI_ADDR_WIDTH-14];
	assign M_AXI_AWQOS = aw_data_m[C_S_AXI_ADDR_WIDTH-15:C_S_AXI_ADDR_WIDTH-18];

	// W channel: S to M
	reg [W_DATA_WIDTH-1:0] w_fifo_mem [0:W_FIFO_DEPTH-1];
	reg [W_FIFO_ADDR_WIDTH:0] w_wr_ptr, w_rd_ptr;
	reg w_wr_en, w_rd_en;
	wire w_empty = (w_wr_ptr == w_rd_ptr);
	wire w_full = (w_wr_ptr[W_FIFO_ADDR_WIDTH] != w_rd_ptr[W_FIFO_ADDR_WIDTH]) && 
	               (w_wr_ptr[W_FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[W_FIFO_ADDR_WIDTH-1:0]);

	assign S_AXI_WREADY = !w_full;
	assign w_wr_en = S_AXI_WVALID && S_AXI_WREADY;

	always @(posedge S_AXI_ACLK) begin
		if (w_wr_en) begin
			w_fifo_mem[w_wr_ptr[W_FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_WDATA,
				S_AXI_WSTRB,
				S_AXI_WLAST
			};
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// W read side in M clock with extra register
	reg [W_DATA_WIDTH-1:0] w_data_m;
	reg w_valid_m;
	reg w_valid_m_next;
	assign w_rd_en = w_valid_m && M_AXI_WREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_valid_m <= 1'b0;
			w_valid_m_next <= 1'b0;
			w_data_m <= {W_DATA_WIDTH{1'b0}};
		end else begin
			if (w_rd_en) begin
				w_valid_m <= 1'b0;
				w_valid_m_next <= 1'b0;
			end else if (w_valid_m_next) begin
				w_valid_m <= 1'b1;
				w_valid_m_next <= 1'b0;
			end else if (!w_empty) begin
				w_data_m <= w_fifo_mem[w_rd_ptr[W_FIFO_ADDR_WIDTH-1:0]];
				w_valid_m_next <= 1'b1;
				w_rd_ptr <= w_rd_ptr + 1'b1;
			end
		end
	end

	assign M_AXI_WVALID = w_valid_m;
	assign M_AXI_WDATA = w_data_m[W_DATA_WIDTH-1:C_S_AXI_DATA_WIDTH/8+1];
	assign M_AXI_WSTRB = w_data_m[C_S_AXI_DATA_WIDTH/8:C_S_AXI_DATA_WIDTH/8-(C_S_AXI_DATA_WIDTH/8)+1];
	assign M_AXI_WLAST = w_data_m[0];

	// B channel: M to S
	reg [B_DATA_WIDTH-1:0] b_fifo_mem [0:B_FIFO_DEPTH-1];
	reg [B_FIFO_ADDR_WIDTH:0] b_wr_ptr, b_rd_ptr;
	reg b_wr_en, b_rd_en;
	wire b_empty = (b_wr_ptr == b_rd_ptr);
	wire b_full = (b_wr_ptr[B_FIFO_ADDR_WIDTH] != b_rd_ptr[B_FIFO_ADDR_WIDTH]) && 
	               (b_wr_ptr[B_FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[B_FIFO_ADDR_WIDTH-1:0]);

	assign M_AXI_BREADY = !b_full;
	assign b_wr_en = M_AXI_BVALID && M_AXI_BREADY;

	always @(posedge M_AXI_ACLK) begin
		if (b_wr_en) begin
			b_fifo_mem[b_wr_ptr[B_FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_BID,
				M_AXI_BRESP
			};
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// B read side in S clock
	reg [B_DATA_WIDTH-1:0] b_data_s;
	reg b_valid_s;
	assign b_rd_en = b_valid_s && S_AXI_BREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_valid_s <= 1'b0;
			b_data_s <= {B_DATA_WIDTH{1'b0}};
		end else begin
			if (b_rd_en) begin
				b_valid_s <= 1'b0;
			end else if (!b_empty) begin
				b_data_s <= b_fifo_mem[b_rd_ptr[B_FIFO_ADDR_WIDTH-1:0]];
				b_valid_s <= 1'b1;
				b_rd_ptr <= b_rd_ptr + 1'b1;
			end
		end
	end

	assign S_AXI_BVALID = b_valid_s;
	assign S_AXI_BID = b_data_s[B_DATA_WIDTH-1:2];
	assign S_AXI_BRESP = b_data_s[1:0];

	// AR channel: S to M
	reg [AR_DATA_WIDTH-1:0] ar_fifo_mem [0:AR_FIFO_DEPTH-1];
	reg [AR_FIFO_ADDR_WIDTH:0] ar_wr_ptr, ar_rd_ptr;
	reg ar_wr_en, ar_rd_en;
	wire ar_empty = (ar_wr_ptr == ar_rd_ptr);
	wire ar_full = (ar_wr_ptr[AR_FIFO_ADDR_WIDTH] != ar_rd_ptr[AR_FIFO_ADDR_WIDTH]) && 
	               (ar_wr_ptr[AR_FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[AR_FIFO_ADDR_WIDTH-1:0]);

	assign S_AXI_ARREADY = !ar_full;
	assign ar_wr_en = S_AXI_ARVALID && S_AXI_ARREADY;

	always @(posedge S_AXI_ACLK) begin
		if (ar_wr_en) begin
			ar_fifo_mem[ar_wr_ptr[AR_FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_ARID,
				S_AXI_ARADDR,
				S_AXI_ARLEN,
				S_AXI_ARSIZE,
				S_AXI_ARBURST,
				S_AXI_ARLOCK,
				S_AXI_ARCACHE,
				S_AXI_ARPROT,
				S_AXI_ARQOS
			};
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
		end
	end

	// AR read side in M clock
	reg [AR_DATA_WIDTH-1:0] ar_data_m;
	reg ar_valid_m;
	assign ar_rd_en = ar_valid_m && M_AXI_ARREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_valid_m <= 1'b0;
			ar_data_m <= {AR_DATA_WIDTH{1'b0}};
		end else begin
			if (ar_rd_en) begin
				ar_valid_m <= 1'b0;
			end else if (!ar_empty) begin
				ar_data_m <= ar_fifo_mem[ar_rd_ptr[AR_FIFO_ADDR_WIDTH-1:0]];
				ar_valid_m <= 1'b1;
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
			end
		end
	end

	assign M_AXI_ARVALID = ar_valid_m;
	assign M_AXI_ARID = ar_data_m[AR_DATA_WIDTH-1:C_S_AXI_ADDR_WIDTH+8+3+2+1+4+3+4];
	assign M_AXI_ARADDR = ar_data_m[C_S_AXI_ADDR_WIDTH+7:C_S_AXI_ADDR_WIDTH+7-C_S_AXI_ADDR_WIDTH+1];
	assign M_AXI_ARLEN = ar_data_m[C_S_AXI_ADDR_WIDTH+6:C_S_AXI_ADDR_WIDTH-1];
	assign M_AXI_ARSIZE = ar_data_m[C_S_AXI_ADDR_WIDTH-2:C_S_AXI_ADDR_WIDTH-4];
	assign M_AXI_ARBURST = ar_data_m[C_S_AXI_ADDR_WIDTH-5:C_S_AXI_ADDR_WIDTH-6];
	assign M_AXI_ARLOCK = ar_data_m[C_S_AXI_ADDR_WIDTH-7];
	assign M_AXI_ARCACHE = ar_data_m[C_S_AXI_ADDR_WIDTH-8:C_S_AXI_ADDR_WIDTH-11];
	assign M_AXI_ARPROT = ar_data_m[C_S_AXI_ADDR_WIDTH-12:C_S_AXI_ADDR_WIDTH-14];
	assign M_AXI_ARQOS = ar_data_m[C_S_AXI_ADDR_WIDTH-15:C_S_AXI_ADDR_WIDTH-18];

	// R channel: M to S
	reg [R_DATA_WIDTH-1:0] r_fifo_mem [0:R_FIFO_DEPTH-1];
	reg [R_FIFO_ADDR_WIDTH:0] r_wr_ptr, r_rd_ptr;
	reg r_wr_en, r_rd_en;
	wire r_empty = (r_wr_ptr == r_rd_ptr);
	wire r_full = (r_wr_ptr[R_FIFO_ADDR_WIDTH] != r_rd_ptr[R_FIFO_ADDR_WIDTH]) && 
	               (r_wr_ptr[R_FIFO_ADDR_WIDTH-1:0] == r_rd_ptr[R_FIFO_ADDR_WIDTH-1:0]);

	assign M_AXI_RREADY = !r_full;
	assign r_wr_en = M_AXI_RVALID && M_AXI_RREADY;

	always @(posedge M_AXI_ACLK) begin
		if (r_wr_en) begin
			r_fifo_mem[r_wr_ptr[R_FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_RID,
				M_AXI_RDATA,
				M_AXI_RRESP,
				M_AXI_RLAST
			};
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	// R read side in S clock
	reg [R_DATA_WIDTH-1:0] r_data_s;
	reg r_valid_s;
	assign r_rd_en = r_valid_s && S_AXI_RREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_valid_s <= 1'b0;
			r_data_s <= {R_DATA_WIDTH{1'b0}};
		end else begin
			if (r_rd_en) begin
				r_valid_s <= 1'b0;
			end else if (!r_empty) begin
				r_data_s <= r_fifo_mem[r_rd_ptr[R_FIFO_ADDR_WIDTH-1:0]];
				r_valid_s <= 1'b1;
				r_rd_ptr <= r_rd_ptr + 1'b1;
			end
		end
	end

	assign S_AXI_RVALID = r_valid_s;
	assign S_AXI_RID = r_data_s[R_DATA_WIDTH-1:C_S_AXI_DATA_WIDTH+3];
	assign S_AXI_RDATA = r_data_s[C_S_AXI_DATA_WIDTH+2:C_S_AXI_DATA_WIDTH+2-C_S_AXI_DATA_WIDTH+1];
	assign S_AXI_RRESP = r_data_s[C_S_AXI_DATA_WIDTH+1:C_S_AXI_DATA_WIDTH];
	assign S_AXI_RLAST = r_data_s[C_S_AXI_DATA_WIDTH-1];

endmodule
