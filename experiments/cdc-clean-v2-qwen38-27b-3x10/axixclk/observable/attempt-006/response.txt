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

	// FIFO depth
	localparam integer FIFO_DEPTH = (1 << LGFIFO);
	localparam integer FIFO_ADDR_WIDTH = LGFIFO;
	localparam integer MAX_BURST = 256;

	// AW channel: S clock domain
	reg [C_S_AXI_ID_WIDTH-1:0] s_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] s_awaddr_reg;
	reg [7:0] s_awlen_reg;
	reg [2:0] s_awsize_reg;
	reg [1:0] s_awburst_reg;
	reg s_awlock_reg;
	reg [3:0] s_awcache_reg;
	reg [2:0] s_awprot_reg;
	reg [3:0] s_awqos_reg;
	reg s_awvalid_reg;
	reg s_awready_reg;

	// AW FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] aw_fifo_data [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] aw_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] aw_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] aw_fifo_burst [0:FIFO_DEPTH-1];
	reg aw_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] aw_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] aw_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] aw_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] aw_count;

	// AW FIFO write (S clock)
	wire aw_fifo_full = (aw_count == FIFO_DEPTH);
	wire aw_fifo_empty = (aw_count == 0);
	wire s_aw_write = s_awvalid_reg && s_awready_reg && !aw_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_awaddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			s_awlen_reg <= 8'b0;
			s_awsize_reg <= 3'b0;
			s_awburst_reg <= 2'b0;
			s_awlock_reg <= 1'b0;
			s_awcache_reg <= 4'b0;
			s_awprot_reg <= 3'b0;
			s_awqos_reg <= 4'b0;
			s_awvalid_reg <= 1'b0;
			s_awready_reg <= 1'b0;
			aw_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			aw_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			// Register S_AXI_AW inputs
			s_awid_reg <= S_AXI_AWID;
			s_awaddr_reg <= S_AXI_AWADDR;
			s_awlen_reg <= S_AXI_AWLEN;
			s_awsize_reg <= S_AXI_AWSIZE;
			s_awburst_reg <= S_AXI_AWBURST;
			s_awlock_reg <= S_AXI_AWLOCK;
			s_awcache_reg <= S_AXI_AWCACHE;
			s_awprot_reg <= S_AXI_AWPROT;
			s_awqos_reg <= S_AXI_AWQOS;
			s_awvalid_reg <= S_AXI_AWVALID;
			s_awready_reg <= !aw_fifo_full;

			if (s_aw_write) begin
				aw_fifo_data[aw_wr_ptr] <= s_awid_reg;
				aw_fifo_addr[aw_wr_ptr] <= s_awaddr_reg;
				aw_fifo_len[aw_wr_ptr] <= s_awlen_reg;
				aw_fifo_size[aw_wr_ptr] <= s_awsize_reg;
				aw_fifo_burst[aw_wr_ptr] <= s_awburst_reg;
				aw_fifo_lock[aw_wr_ptr] <= s_awlock_reg;
				aw_fifo_cache[aw_wr_ptr] <= s_awcache_reg;
				aw_fifo_prot[aw_wr_ptr] <= s_awprot_reg;
				aw_fifo_qos[aw_wr_ptr] <= s_awqos_reg;
				aw_wr_ptr <= aw_wr_ptr + 1'b1;
				aw_count <= aw_count + 1'b1;
			end
		end
	end

	// AW FIFO read (M clock)
	reg [C_S_AXI_ID_WIDTH-1:0] m_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] m_awaddr_reg;
	reg [7:0] m_awlen_reg;
	reg [2:0] m_awsize_reg;
	reg [1:0] m_awburst_reg;
	reg m_awlock_reg;
	reg [3:0] m_awcache_reg;
	reg [2:0] m_awprot_reg;
	reg [3:0] m_awqos_reg;
	reg m_awvalid_reg;
	reg m_awready_reg;

	wire m_aw_read = m_awvalid_reg && m_awready_reg && !aw_fifo_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_awid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_awaddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_awlen_reg <= 8'b0;
			m_awsize_reg <= 3'b0;
			m_awburst_reg <= 2'b0;
			m_awlock_reg <= 1'b0;
			m_awcache_reg <= 4'b0;
			m_awprot_reg <= 3'b0;
			m_awqos_reg <= 4'b0;
			m_awvalid_reg <= 1'b0;
			m_awready_reg <= 1'b0;
			aw_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			m_awvalid_reg <= !aw_fifo_empty;
			m_awready_reg <= M_AXI_AWREADY;

			if (m_aw_read) begin
				m_awid_reg <= aw_fifo_data[aw_rd_ptr];
				m_awaddr_reg <= aw_fifo_addr[aw_rd_ptr];
				m_awlen_reg <= aw_fifo_len[aw_rd_ptr];
				m_awsize_reg <= aw_fifo_size[aw_rd_ptr];
				m_awburst_reg <= aw_fifo_burst[aw_rd_ptr];
				m_awlock_reg <= aw_fifo_lock[aw_rd_ptr];
				m_awcache_reg <= aw_fifo_cache[aw_rd_ptr];
				m_awprot_reg <= aw_fifo_prot[aw_rd_ptr];
				m_awqos_reg <= aw_fifo_qos[aw_rd_ptr];
				aw_rd_ptr <= aw_rd_ptr + 1'b1;
			end
		end
	end

	// AW count update (M clock for read side)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled in S clock block
		end else begin
			if (m_aw_read) begin
				aw_count <= aw_count - 1'b1;
			end
		end
	end

	assign M_AXI_AWID = m_awid_reg;
	assign M_AXI_AWADDR = m_awaddr_reg;
	assign M_AXI_AWLEN = m_awlen_reg;
	assign M_AXI_AWSIZE = m_awsize_reg;
	assign M_AXI_AWBURST = m_awburst_reg;
	assign M_AXI_AWLOCK = m_awlock_reg;
	assign M_AXI_AWCACHE = m_awcache_reg;
	assign M_AXI_AWPROT = m_awprot_reg;
	assign M_AXI_AWQOS = m_awqos_reg;
	assign M_AXI_AWVALID = m_awvalid_reg;
	assign S_AXI_AWREADY = s_awready_reg;

	// W channel: S clock domain
	reg [C_S_AXI_DATA_WIDTH-1:0] s_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] s_wstrb_reg;
	reg s_wlast_reg;
	reg s_wvalid_reg;
	reg s_wready_reg;

	// W FIFO
	reg [C_S_AXI_DATA_WIDTH-1:0] w_fifo_data [0:FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_fifo_strb [0:FIFO_DEPTH-1];
	reg w_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] w_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] w_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] w_count;

	wire w_fifo_full = (w_count == FIFO_DEPTH);
	wire w_fifo_empty = (w_count == 0);
	wire s_w_write = s_wvalid_reg && s_wready_reg && !w_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			s_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			s_wlast_reg <= 1'b0;
			s_wvalid_reg <= 1'b0;
			s_wready_reg <= 1'b0;
			w_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			w_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_wdata_reg <= S_AXI_WDATA;
			s_wstrb_reg <= S_AXI_WSTRB;
			s_wlast_reg <= S_AXI_WLAST;
			s_wvalid_reg <= S_AXI_WVALID;
			s_wready_reg <= !w_fifo_full;

			if (s_w_write) begin
				w_fifo_data[w_wr_ptr] <= s_wdata_reg;
				w_fifo_strb[w_wr_ptr] <= s_wstrb_reg;
				w_fifo_last[w_wr_ptr] <= s_wlast_reg;
				w_wr_ptr <= w_wr_ptr + 1'b1;
				w_count <= w_count + 1'b1;
			end
		end
	end

	// W FIFO read (M clock) - with extra register for M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1:0] m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_wvalid_reg;
	reg m_wready_reg;
	reg m_wdata_next_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] m_wstrb_next_reg;
	reg m_wlast_next_reg;
	reg m_wvalid_next_reg;

	wire m_w_read = m_wvalid_next_reg && m_wready_reg && !w_fifo_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_reg <= 1'b0;
			m_wvalid_reg <= 1'b0;
			m_wready_reg <= 1'b0;
			m_wdata_next_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_next_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_next_reg <= 1'b0;
			m_wvalid_next_reg <= 1'b0;
			w_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			// First stage: read from FIFO
			m_wvalid_next_reg <= !w_fifo_empty;
			m_wready_reg <= M_AXI_WREADY;

			if (m_w_read) begin
				m_wdata_next_reg <= w_fifo_data[w_rd_ptr];
				m_wstrb_next_reg <= w_fifo_strb[w_rd_ptr];
				m_wlast_next_reg <= w_fifo_last[w_rd_ptr];
				w_rd_ptr <= w_rd_ptr + 1'b1;
			end

			// Second stage: hold one extra M_AXI clock before M_AXI_WVALID
			if (m_wvalid_next_reg) begin
				m_wdata_reg <= m_wdata_next_reg;
				m_wstrb_reg <= m_wstrb_next_reg;
				m_wlast_reg <= m_wlast_next_reg;
				m_wvalid_reg <= 1'b1;
			end else begin
				m_wvalid_reg <= 1'b0;
			end
		end
	end

	// W count update (M clock for read side)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled in S clock block
		end else begin
			if (m_w_read) begin
				w_count <= w_count - 1'b1;
			end
		end
	end

	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = m_wvalid_reg;
	assign S_AXI_WREADY = s_wready_reg;

	// B channel: M clock domain
	reg [C_S_AXI_ID_WIDTH-1:0] m_bid_reg;
	reg [1:0] m_bresp_reg;
	reg m_bvalid_reg;
	reg m_bready_reg;

	// B FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] b_fifo_id [0:FIFO_DEPTH-1];
	reg [1:0] b_fifo_resp [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] b_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] b_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] b_count;

	wire b_fifo_full = (b_count == FIFO_DEPTH);
	wire b_fifo_empty = (b_count == 0);
	wire m_b_write = m_bvalid_reg && m_bready_reg && !b_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_bid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_bresp_reg <= 2'b0;
			m_bvalid_reg <= 1'b0;
			m_bready_reg <= 1'b0;
			b_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			b_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_bid_reg <= M_AXI_BID;
			m_bresp_reg <= M_AXI_BRESP;
			m_bvalid_reg <= M_AXI_BVALID;
			m_bready_reg <= !b_fifo_full;

			if (m_b_write) begin
				b_fifo_id[b_wr_ptr] <= m_bid_reg;
				b_fifo_resp[b_wr_ptr] <= m_bresp_reg;
				b_wr_ptr <= b_wr_ptr + 1'b1;
				b_count <= b_count + 1'b1;
			end
		end
	end

	// B FIFO read (S clock)
	reg [C_S_AXI_ID_WIDTH-1:0] s_bid_reg;
	reg [1:0] s_bresp_reg;
	reg s_bvalid_reg;
	reg s_bready_reg;

	wire s_b_read = s_bvalid_reg && s_bready_reg && !b_fifo_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_bresp_reg <= 2'b0;
			s_bvalid_reg <= 1'b0;
			s_bready_reg <= 1'b0;
			b_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			s_bvalid_reg <= !b_fifo_empty;
			s_bready_reg <= S_AXI_BREADY;

			if (s_b_read) begin
				s_bid_reg <= b_fifo_id[b_rd_ptr];
				s_bresp_reg <= b_fifo_resp[b_rd_ptr];
				b_rd_ptr <= b_rd_ptr + 1'b1;
			end
		end
	end

	// B count update (S clock for read side)
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			// handled in M clock block
		end else begin
			if (s_b_read) begin
				b_count <= b_count - 1'b1;
			end
		end
	end

	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = s_bvalid_reg;
	assign M_AXI_BREADY = m_bready_reg;

	// AR channel: S clock domain
	reg [C_S_AXI_ID_WIDTH-1:0] s_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] s_araddr_reg;
	reg [7:0] s_arlen_reg;
	reg [2:0] s_arsize_reg;
	reg [1:0] s_arburst_reg;
	reg s_arlock_reg;
	reg [3:0] s_arcache_reg;
	reg [2:0] s_arprot_reg;
	reg [3:0] s_arqos_reg;
	reg s_arvalid_reg;
	reg s_arready_reg;

	// AR FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] ar_fifo_data [0:FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1:0] ar_fifo_addr [0:FIFO_DEPTH-1];
	reg [7:0] ar_fifo_len [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_size [0:FIFO_DEPTH-1];
	reg [1:0] ar_fifo_burst [0:FIFO_DEPTH-1];
	reg ar_fifo_lock [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_cache [0:FIFO_DEPTH-1];
	reg [2:0] ar_fifo_prot [0:FIFO_DEPTH-1];
	reg [3:0] ar_fifo_qos [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] ar_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] ar_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] ar_count;

	wire ar_fifo_full = (ar_count == FIFO_DEPTH);
	wire ar_fifo_empty = (ar_count == 0);
	wire s_ar_write = s_arvalid_reg && s_arready_reg && !ar_fifo_full;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_araddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			s_arlen_reg <= 8'b0;
			s_arsize_reg <= 3'b0;
			s_arburst_reg <= 2'b0;
			s_arlock_reg <= 1'b0;
			s_arcache_reg <= 4'b0;
			s_arprot_reg <= 3'b0;
			s_arqos_reg <= 4'b0;
			s_arvalid_reg <= 1'b0;
			s_arready_reg <= 1'b0;
			ar_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			ar_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			s_arid_reg <= S_AXI_ARID;
			s_araddr_reg <= S_AXI_ARADDR;
			s_arlen_reg <= S_AXI_ARLEN;
			s_arsize_reg <= S_AXI_ARSIZE;
			s_arburst_reg <= S_AXI_ARBURST;
			s_arlock_reg <= S_AXI_ARLOCK;
			s_arcache_reg <= S_AXI_ARCACHE;
			s_arprot_reg <= S_AXI_ARPROT;
			s_arqos_reg <= S_AXI_ARQOS;
			s_arvalid_reg <= S_AXI_ARVALID;
			s_arready_reg <= !ar_fifo_full;

			if (s_ar_write) begin
				ar_fifo_data[ar_wr_ptr] <= s_arid_reg;
				ar_fifo_addr[ar_wr_ptr] <= s_araddr_reg;
				ar_fifo_len[ar_wr_ptr] <= s_arlen_reg;
				ar_fifo_size[ar_wr_ptr] <= s_arsize_reg;
				ar_fifo_burst[ar_wr_ptr] <= s_arburst_reg;
				ar_fifo_lock[ar_wr_ptr] <= s_arlock_reg;
				ar_fifo_cache[ar_wr_ptr] <= s_arcache_reg;
				ar_fifo_prot[ar_wr_ptr] <= s_arprot_reg;
				ar_fifo_qos[ar_wr_ptr] <= s_arqos_reg;
				ar_wr_ptr <= ar_wr_ptr + 1'b1;
				ar_count <= ar_count + 1'b1;
			end
		end
	end

	// AR FIFO read (M clock)
	reg [C_S_AXI_ID_WIDTH-1:0] m_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] m_araddr_reg;
	reg [7:0] m_arlen_reg;
	reg [2:0] m_arsize_reg;
	reg [1:0] m_arburst_reg;
	reg m_arlock_reg;
	reg [3:0] m_arcache_reg;
	reg [2:0] m_arprot_reg;
	reg [3:0] m_arqos_reg;
	reg m_arvalid_reg;
	reg m_arready_reg;

	wire m_ar_read = m_arvalid_reg && m_arready_reg && !ar_fifo_empty;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_arid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_araddr_reg <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_arlen_reg <= 8'b0;
			m_arsize_reg <= 3'b0;
			m_arburst_reg <= 2'b0;
			m_arlock_reg <= 1'b0;
			m_arcache_reg <= 4'b0;
			m_arprot_reg <= 3'b0;
			m_arqos_reg <= 4'b0;
			m_arvalid_reg <= 1'b0;
			m_arready_reg <= 1'b0;
			ar_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			m_arvalid_reg <= !ar_fifo_empty;
			m_arready_reg <= M_AXI_ARREADY;

			if (m_ar_read) begin
				m_arid_reg <= ar_fifo_data[ar_rd_ptr];
				m_araddr_reg <= ar_fifo_addr[ar_rd_ptr];
				m_arlen_reg <= ar_fifo_len[ar_rd_ptr];
				m_arsize_reg <= ar_fifo_size[ar_rd_ptr];
				m_arburst_reg <= ar_fifo_burst[ar_rd_ptr];
				m_arlock_reg <= ar_fifo_lock[ar_rd_ptr];
				m_arcache_reg <= ar_fifo_cache[ar_rd_ptr];
				m_arprot_reg <= ar_fifo_prot[ar_rd_ptr];
				m_arqos_reg <= ar_fifo_qos[ar_rd_ptr];
				ar_rd_ptr <= ar_rd_ptr + 1'b1;
			end
		end
	end

	// AR count update (M clock for read side)
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			// handled in S clock block
		end else begin
			if (m_ar_read) begin
				ar_count <= ar_count - 1'b1;
			end
		end
	end

	assign M_AXI_ARID = m_arid_reg;
	assign M_AXI_ARADDR = m_araddr_reg;
	assign M_AXI_ARLEN = m_arlen_reg;
	assign M_AXI_ARSIZE = m_arsize_reg;
	assign M_AXI_ARBURST = m_arburst_reg;
	assign M_AXI_ARLOCK = m_arlock_reg;
	assign M_AXI_ARCACHE = m_arcache_reg;
	assign M_AXI_ARPROT = m_arprot_reg;
	assign M_AXI_ARQOS = m_arqos_reg;
	assign M_AXI_ARVALID = m_arvalid_reg;
	assign S_AXI_ARREADY = s_arready_reg;

	// R channel: M clock domain
	reg [C_S_AXI_ID_WIDTH-1:0] m_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0] m_rdata_reg;
	reg [1:0] m_rresp_reg;
	reg m_rlast_reg;
	reg m_rvalid_reg;
	reg m_rready_reg;

	// R FIFO
	reg [C_S_AXI_ID_WIDTH-1:0] r_fifo_id [0:FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_data [0:FIFO_DEPTH-1];
	reg [1:0] r_fifo_resp [0:FIFO_DEPTH-1];
	reg r_fifo_last [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] r_wr_ptr;
	reg [FIFO_ADDR_WIDTH-1:0] r_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] r_count;

	wire r_fifo_full = (r_count == FIFO_DEPTH);
	wire r_fifo_empty = (r_count == 0);
	wire m_r_write = m_rvalid_reg && m_rready_reg && !r_fifo_full;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			m_rid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_rdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_rresp_reg <= 2'b0;
			m_rlast_reg <= 1'b0;
			m_rvalid_reg <= 1'b0;
			m_rready_reg <= 1'b0;
			r_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			r_count <= {FIFO_ADDR_WIDTH+1{1'b0}};
		end else begin
			m_rid_reg <= M_AXI_RID;
			m_rdata_reg <= M_AXI_RDATA;
			m_rresp_reg <= M_AXI_RRESP;
			m_rlast_reg <= M_AXI_RLAST;
			m_rvalid_reg <= M_AXI_RVALID;
			m_rready_reg <= !r_fifo_full;

			if (m_r_write) begin
				r_fifo_id[r_wr_ptr] <= m_rid_reg;
				r_fifo_data[r_wr_ptr] <= m_rdata_reg;
				r_fifo_resp[r_wr_ptr] <= m_rresp_reg;
				r_fifo_last[r_wr_ptr] <= m_rlast_reg;
				r_wr_ptr <= r_wr_ptr + 1'b1;
				r_count <= r_count + 1'b1;
			end
		end
	end

	// R FIFO read (S clock)
	reg [C_S_AXI_ID_WIDTH-1:0] s_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0] s_rdata_reg;
	reg [1:0] s_rresp_reg;
	reg s_rlast_reg;
	reg s_rvalid_reg;
	reg s_rready_reg;

	wire s_r_read = s_rvalid_reg && s_rready_reg && !r_fifo_empty;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rid_reg <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_rdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			s_rresp_reg <= 2'b0;
			s_rlast_reg <= 1'b0;
			s_rvalid_reg <= 1'b0;
			s_rready_reg <= 1'b0;
			r_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			s_rvalid_reg <= !r_fifo_empty;
