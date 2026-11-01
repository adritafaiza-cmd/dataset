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

	// Reset synchronization for M_AXI domain
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;
	wire m_reset_sync_rst = ~m_reset_sync[1];

	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign M_AXI_ARESETN = ~m_reset_sync_rst;

	// AW channel: S to M
	reg [AW_FIFO_W-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] aw_wr_ptr, aw_rd_ptr;
	wire aw_full = (aw_wr_ptr[FIFO_PTR_W] != aw_rd_ptr[FIFO_PTR_W]) && 
	               (aw_wr_ptr[FIFO_PTR_W-1:0] == aw_rd_ptr[FIFO_PTR_W-1:0]);
	wire aw_empty = (aw_wr_ptr == aw_rd_ptr);

	// AW write in S domain
	wire aw_write_en = S_AXI_AWVALID && S_AXI_AWREADY;
	assign S_AXI_AWREADY = !aw_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (aw_write_en) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_PTR_W-1:0]] <= {
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

	// AW read in M domain
	reg [AW_FIFO_W-1:0] aw_rd_data;
	wire aw_read_en = M_AXI_AWVALID && M_AXI_AWREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			aw_rd_data <= {AW_FIFO_W{1'b0}};
		end else begin
			if (!aw_empty) begin
				aw_rd_data <= aw_fifo_mem[aw_rd_ptr[FIFO_PTR_W-1:0]];
			end
			if (aw_read_en) begin
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
			end
		end
	end

	assign M_AXI_AWVALID = !aw_empty;
	assign M_AXI_AWID = aw_rd_data[AW_FIFO_W-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH -: 8];
	assign M_AXI_AWSIZE = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8 -: 3];
	assign M_AXI_AWBURST = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3 -: 2];
	assign M_AXI_AWLOCK = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2 -: 1];
	assign M_AXI_AWCACHE = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1 -: 4];
	assign M_AXI_AWPROT = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4 -: 3];
	assign M_AXI_AWQOS = aw_rd_data[AW_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3 -: 4];

	// W channel: S to M
	reg [W_FIFO_W-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] w_wr_ptr, w_rd_ptr;
	wire w_full = (w_wr_ptr[FIFO_PTR_W] != w_rd_ptr[FIFO_PTR_W]) && 
	               (w_wr_ptr[FIFO_PTR_W-1:0] == w_rd_ptr[FIFO_PTR_W-1:0]);
	wire w_empty = (w_wr_ptr == w_rd_ptr);

	// W write in S domain
	wire w_write_en = S_AXI_WVALID && S_AXI_WREADY;
	assign S_AXI_WREADY = !w_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (w_write_en) begin
			w_fifo_mem[w_wr_ptr[FIFO_PTR_W-1:0]] <= {
				S_AXI_WDATA,
				S_AXI_WSTRB,
				S_AXI_WLAST
			};
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// W read in M domain
	reg [W_FIFO_W-1:0] w_rd_data;
	wire w_read_en = M_AXI_WVALID && M_AXI_WREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			w_rd_data <= {W_FIFO_W{1'b0}};
		end else begin
			if (!w_empty) begin
				w_rd_data <= w_fifo_mem[w_rd_ptr[FIFO_PTR_W-1:0]];
			end
			if (w_read_en) begin
				w_rd_ptr <= w_rd_ptr + 1'b1;
			end
		end
	end

	// Extra register for M_AXI_WVALID as per requirement
	reg m_w_valid_reg;
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_w_valid_reg <= 1'b0;
		end else begin
			m_w_valid_reg <= !w_empty;
		end
	end

	assign M_AXI_WVALID = m_w_valid_reg;
	assign M_AXI_WDATA = w_rd_data[W_FIFO_W-1 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB = w_rd_data[C_S_AXI_DATA_WIDTH-1 -: (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST = w_rd_data[0];

	// B channel: M to S
	reg [B_FIFO_W-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] b_wr_ptr, b_rd_ptr;
	wire b_full = (b_wr_ptr[FIFO_PTR_W] != b_rd_ptr[FIFO_PTR_W]) && 
	               (b_wr_ptr[FIFO_PTR_W-1:0] == b_rd_ptr[FIFO_PTR_W-1:0]);
	wire b_empty = (b_wr_ptr == b_rd_ptr);

	// B write in M domain
	wire b_write_en = M_AXI_BVALID && M_AXI_BREADY;
	assign M_AXI_BREADY = !b_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (b_write_en) begin
			b_fifo_mem[b_wr_ptr[FIFO_PTR_W-1:0]] <= {
				M_AXI_BID,
				M_AXI_BRESP
			};
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// B read in S domain
	reg [B_FIFO_W-1:0] b_rd_data;
	wire b_read_en = S_AXI_BVALID && S_AXI_BREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			b_rd_data <= {B_FIFO_W{1'b0}};
		end else begin
			if (!b_empty) begin
				b_rd_data <= b_fifo_mem[b_rd_ptr[FIFO_PTR_W-1:0]];
			end
			if (b_read_en) begin
				b_rd_ptr <= b_rd_ptr + 1'b1;
			end
		end
	end

	assign S_AXI_BVALID = !b_empty;
	assign S_AXI_BID = b_rd_data[B_FIFO_W-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP = b_rd_data[C_S_AXI_ID_WIDTH-1 -: 2];

	// AR channel: S to M
	reg [AR_FIFO_W-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] ar_wr_ptr, ar_rd_ptr;
	wire ar_full = (ar_wr_ptr[FIFO_PTR_W] != ar_rd_ptr[FIFO_PTR_W]) && 
	               (ar_wr_ptr[FIFO_PTR_W-1:0] == ar_rd_ptr[FIFO_PTR_W-1:0]);
	wire ar_empty = (ar_wr_ptr == ar_rd_ptr);

	// AR write in S domain
	wire ar_write_en = S_AXI_ARVALID && S_AXI_ARREADY;
	assign S_AXI_ARREADY = !ar_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (ar_write_en) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_PTR_W-1:0]] <= {
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

	// AR read in M domain
	reg [AR_FIFO_W-1:0] ar_rd_data;
	wire ar_read_en = M_AXI_ARVALID && M_AXI_ARREADY;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			ar_rd_data <= {AR_FIFO_W{1'b0}};
		end else begin
			if (!ar_empty) begin
				ar_rd_data <= ar_fifo_mem[ar_rd_ptr[FIFO_PTR_W-1:0]];
			end
			if (ar_read_en) begin
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
			end
		end
	end

	assign M_AXI_ARVALID = !ar_empty;
	assign M_AXI_ARID = ar_rd_data[AR_FIFO_W-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH -: 8];
	assign M_AXI_ARSIZE = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8 -: 3];
	assign M_AXI_ARBURST = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3 -: 2];
	assign M_AXI_ARLOCK = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2 -: 1];
	assign M_AXI_ARCACHE = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1 -: 4];
	assign M_AXI_ARPROT = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4 -: 3];
	assign M_AXI_ARQOS = ar_rd_data[AR_FIFO_W-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3 -: 4];

	// R channel: M to S
	reg [R_FIFO_W-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] r_wr_ptr, r_rd_ptr;
	wire r_full = (r_wr_ptr[FIFO_PTR_W] != r_rd_ptr[FIFO_PTR_W]) && 
	               (r_wr_ptr[FIFO_PTR_W-1:0] == r_rd_ptr[FIFO_PTR_W-1:0]);
	wire r_empty = (r_wr_ptr == r_rd_ptr);

	// R write in M domain
	wire r_write_en = M_AXI_RVALID && M_AXI_RREADY;
	assign M_AXI_RREADY = !r_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (r_write_en) begin
			r_fifo_mem[r_wr_ptr[FIFO_PTR_W-1:0]] <= {
				M_AXI_RID,
				M_AXI_RDATA,
				M_AXI_RRESP,
				M_AXI_RLAST
			};
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	// R read in S domain
	reg [R_FIFO_W-1:0] r_rd_data;
	wire r_read_en = S_AXI_RVALID && S_AXI_RREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			r_rd_data <= {R_FIFO_W{1'b0}};
		end else begin
			if (!r_empty) begin
				r_rd_data <= r_fifo_mem[r_rd_ptr[FIFO_PTR_W-1:0]];
			end
			if (r_read_en) begin
				r_rd_ptr <= r_rd_ptr + 1'b1;
			end
		end
	end

	assign S_AXI_RVALID = !r_empty;
	assign S_AXI_RID = r_rd_data[R_FIFO_W-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_RDATA = r_rd_data[C_S_AXI_ID_WIDTH-1 -: C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP = r_rd_data[C_S_AXI_ID_WIDTH+C_S_AXI_DATA_WIDTH-1 -: 2];
	assign S_AXI_RLAST = r_rd_data[0];

endmodule
