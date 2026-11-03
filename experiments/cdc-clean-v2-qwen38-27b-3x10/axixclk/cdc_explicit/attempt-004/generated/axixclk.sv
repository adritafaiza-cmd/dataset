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
	wire m_reset_synced = m_reset_sync[FFS_STAGES-1];
	assign M_AXI_ARESETN = m_reset_synced;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced)
			m_reset_sync <= {FFS_STAGES{1'b0}};
		else
			m_reset_sync <= {m_reset_sync[FFS_STAGES-2:0], S_AXI_ARESETN};
	end

	// ============================================================================
	// AW Channel: S -> M
	// ============================================================================
	// S-domain: capture AW when valid, push into FIFO
	// M-domain: pop from FIFO, present to master

	// AW FIFO: stores {AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWQOS}
	localparam integer AW_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	reg [AW_FIFO_WIDTH-1:0] aw_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] aw_wr_ptr, aw_rd_ptr;
	wire aw_full = (aw_wr_ptr[FIFO_ADDR_WIDTH] != aw_rd_ptr[FIFO_ADDR_WIDTH]) && 
	               (aw_wr_ptr[FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire aw_empty = (aw_wr_ptr == aw_rd_ptr);

	// S-domain: write to AW FIFO
	wire aw_s_valid = S_AXI_AWVALID;
	wire aw_s_ready = !aw_full;
	assign S_AXI_AWREADY = aw_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (aw_s_valid && aw_s_ready) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
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

	// M-domain: read from AW FIFO
	reg [AW_FIFO_WIDTH-1:0] aw_m_data;
	wire aw_m_valid = !aw_empty;
	wire aw_m_ready = M_AXI_AWREADY;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced) begin
			aw_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
			aw_m_data <= {AW_FIFO_WIDTH{1'b0}};
		end else begin
			aw_m_data <= aw_fifo_mem[aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			if (aw_m_valid && aw_m_ready)
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
		end
	end

	// M-domain: drive master AW
	assign M_AXI_AWID    = aw_m_data[AW_FIFO_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_AWADDR  = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_AWLEN   = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH -: 8];
	assign M_AXI_AWSIZE  = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8 -: 3];
	assign M_AXI_AWBURST = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3 -: 2];
	assign M_AXI_AWLOCK  = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2 -: 1];
	assign M_AXI_AWCACHE = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1 -: 4];
	assign M_AXI_AWPROT  = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4 -: 3];
	assign M_AXI_AWQOS   = aw_m_data[AW_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3 -: 4];
	assign M_AXI_AWVALID = aw_m_valid;

	// ============================================================================
	// W Channel: S -> M
	// ============================================================================
	// W FIFO: stores {WDATA, WSTRB, WLAST}
	localparam integer W_FIFO_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	reg [W_FIFO_WIDTH-1:0] w_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] w_wr_ptr, w_rd_ptr;
	wire w_full = (w_wr_ptr[FIFO_ADDR_WIDTH] != w_rd_ptr[FIFO_ADDR_WIDTH]) && 
	               (w_wr_ptr[FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire w_empty = (w_wr_ptr == w_rd_ptr);

	// S-domain: write to W FIFO
	wire w_s_valid = S_AXI_WVALID;
	wire w_s_ready = !w_full;
	assign S_AXI_WREADY = w_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (w_s_valid && w_s_ready) begin
			w_fifo_mem[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				S_AXI_WDATA,
				S_AXI_WSTRB,
				S_AXI_WLAST
			};
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// M-domain: read from W FIFO
	reg [W_FIFO_WIDTH-1:0] w_m_data;
	wire w_m_valid = !w_empty;
	wire w_m_ready = M_AXI_WREADY;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced) begin
			w_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
			w_m_data <= {W_FIFO_WIDTH{1'b0}};
		end else begin
			w_m_data <= w_fifo_mem[w_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			if (w_m_valid && w_m_ready)
				w_rd_ptr <= w_rd_ptr + 1'b1;
		end
	end

	// M-domain: drive master W
	assign M_AXI_WDATA = w_m_data[W_FIFO_WIDTH-1 -: C_S_AXI_DATA_WIDTH];
	assign M_AXI_WSTRB = w_m_data[W_FIFO_WIDTH-1-C_S_AXI_DATA_WIDTH -: (C_S_AXI_DATA_WIDTH/8)];
	assign M_AXI_WLAST = w_m_data[W_FIFO_WIDTH-1-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8) -: 1];
	assign M_AXI_WVALID = w_m_valid;

	// ============================================================================
	// B Channel: M -> S
	// ============================================================================
	// B FIFO: stores {BID, BRESP}
	localparam integer B_FIFO_WIDTH = C_S_AXI_ID_WIDTH + 2;
	reg [B_FIFO_WIDTH-1:0] b_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] b_wr_ptr, b_rd_ptr;
	wire b_full = (b_wr_ptr[FIFO_ADDR_WIDTH] != b_rd_ptr[FIFO_ADDR_WIDTH]) && 
	               (b_wr_ptr[FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire b_empty = (b_wr_ptr == b_rd_ptr);

	// M-domain: write to B FIFO
	wire b_m_valid = M_AXI_BVALID;
	wire b_m_ready = !b_full;
	assign M_AXI_BREADY = b_m_ready;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced) begin
			b_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (b_m_valid && b_m_ready) begin
			b_fifo_mem[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_BID,
				M_AXI_BRESP
			};
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// S-domain: read from B FIFO
	reg [B_FIFO_WIDTH-1:0] b_s_data;
	wire b_s_valid = !b_empty;
	wire b_s_ready = S_AXI_BREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
			b_s_data <= {B_FIFO_WIDTH{1'b0}};
		end else begin
			b_s_data <= b_fifo_mem[b_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			if (b_s_valid && b_s_ready)
				b_rd_ptr <= b_rd_ptr + 1'b1;
		end
	end

	// S-domain: drive slave B
	assign S_AXI_BID    = b_s_data[B_FIFO_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_BRESP  = b_s_data[B_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH -: 2];
	assign S_AXI_BVALID = b_s_valid;

	// ============================================================================
	// AR Channel: S -> M
	// ============================================================================
	// AR FIFO: stores {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARQOS}
	localparam integer AR_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	reg [AR_FIFO_WIDTH-1:0] ar_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] ar_wr_ptr, ar_rd_ptr;
	wire ar_full = (ar_wr_ptr[FIFO_ADDR_WIDTH] != ar_rd_ptr[FIFO_ADDR_WIDTH]) && 
	               (ar_wr_ptr[FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire ar_empty = (ar_wr_ptr == ar_rd_ptr);

	// S-domain: write to AR FIFO
	wire ar_s_valid = S_AXI_ARVALID;
	wire ar_s_ready = !ar_full;
	assign S_AXI_ARREADY = ar_s_ready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (ar_s_valid && ar_s_ready) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
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

	// M-domain: read from AR FIFO
	reg [AR_FIFO_WIDTH-1:0] ar_m_data;
	wire ar_m_valid = !ar_empty;
	wire ar_m_ready = M_AXI_ARREADY;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced) begin
			ar_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
			ar_m_data <= {AR_FIFO_WIDTH{1'b0}};
		end else begin
			ar_m_data <= ar_fifo_mem[ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			if (ar_m_valid && ar_m_ready)
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
		end
	end

	// M-domain: drive master AR
	assign M_AXI_ARID    = ar_m_data[AR_FIFO_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign M_AXI_ARADDR  = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH -: C_S_AXI_ADDR_WIDTH];
	assign M_AXI_ARLEN   = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH -: 8];
	assign M_AXI_ARSIZE  = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8 -: 3];
	assign M_AXI_ARBURST = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3 -: 2];
	assign M_AXI_ARLOCK  = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2 -: 1];
	assign M_AXI_ARCACHE = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1 -: 4];
	assign M_AXI_ARPROT  = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4 -: 3];
	assign M_AXI_ARQOS   = ar_m_data[AR_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8-3-2-1-4-3 -: 4];
	assign M_AXI_ARVALID = ar_m_valid;

	// ============================================================================
	// R Channel: M -> S
	// ============================================================================
	// R FIFO: stores {RID, RDATA, RRESP, RLAST}
	localparam integer R_FIFO_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1;
	reg [R_FIFO_WIDTH-1:0] r_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] r_wr_ptr, r_rd_ptr;
	wire r_full = (r_wr_ptr[FIFO_ADDR_WIDTH] != r_rd_ptr[FIFO_ADDR_WIDTH]) && 
	               (r_wr_ptr[FIFO_ADDR_WIDTH-1:0] == r_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire r_empty = (r_wr_ptr == r_rd_ptr);

	// M-domain: write to R FIFO
	wire r_m_valid = M_AXI_RVALID;
	wire r_m_ready = !r_full;
	assign M_AXI_RREADY = r_m_ready;

	always @(posedge M_AXI_ACLK or negedge m_reset_synced) begin
		if (!m_reset_synced) begin
			r_wr_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else if (r_m_valid && r_m_ready) begin
			r_fifo_mem[r_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {
				M_AXI_RID,
				M_AXI_RDATA,
				M_AXI_RRESP,
				M_AXI_RLAST
			};
			r_wr_ptr <= r_wr_ptr + 1'b1;
		end
	end

	// S-domain: read from R FIFO
	reg [R_FIFO_WIDTH-1:0] r_s_data;
	wire r_s_valid = !r_empty;
	wire r_s_ready = S_AXI_RREADY;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_rd_ptr <= {FIFO_ADDR_WIDTH+1{1'b0}};
			r_s_data <= {R_FIFO_WIDTH{1'b0}};
		end else begin
			r_s_data <= r_fifo_mem[r_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
			if (r_s_valid && r_s_ready)
				r_rd_ptr <= r_rd_ptr + 1'b1;
		end
	end

	// S-domain: drive slave R
	assign S_AXI_RID    = r_s_data[R_FIFO_WIDTH-1 -: C_S_AXI_ID_WIDTH];
	assign S_AXI_RDATA  = r_s_data[R_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH -: C_S_AXI_DATA_WIDTH];
	assign S_AXI_RRESP  = r_s_data[R_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH -: 2];
	assign S_AXI_RLAST  = r_s_data[R_FIFO_WIDTH-1-C_S_AXI_ID_WIDTH-C_S_AXI_DATA_WIDTH-2 -: 1];
	assign S_AXI_RVALID = r_s_valid;

endmodule
