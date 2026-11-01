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

	// Internal signals
	wire [C_S_AXI_ID_WIDTH-1 : 0] s_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr;
	wire [7 : 0] s_awlen;
	wire [2 : 0] s_awsize;
	wire [1 : 0] s_awburst;
	wire s_awlock;
	wire [3 : 0] s_awcache;
	wire [2 : 0] s_awprot;
	wire [3 : 0] s_awqos;
	wire s_awvalid;
	wire s_awready;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb;
	wire s_wlast;
	wire s_wvalid;
	wire s_wready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] s_bid;
	wire [1 : 0] s_bresp;
	wire s_bvalid;
	wire s_bready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] s_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr;
	wire [7 : 0] s_arlen;
	wire [2 : 0] s_arsize;
	wire [1 : 0] s_arburst;
	wire s_arlock;
	wire [3 : 0] s_arcache;
	wire [2 : 0] s_arprot;
	wire [3 : 0] s_arqos;
	wire s_arvalid;
	wire s_arready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] s_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata;
	wire [1 : 0] s_rresp;
	wire s_rlast;
	wire s_rvalid;
	wire s_rready;

	wire m_awid;
	wire m_awaddr;
	wire m_awlen;
	wire m_awsize;
	wire m_awburst;
	wire m_awlock;
	wire m_awcache;
	wire m_awprot;
	wire m_awqos;
	wire m_awvalid;
	wire m_awready;

	wire m_wdata;
	wire m_wstrb;
	wire m_wlast;
	wire m_wvalid;
	wire m_wready;

	wire m_bid;
	wire m_bresp;
	wire m_bvalid;
	wire m_bready;

	wire m_arid;
	wire m_araddr;
	wire m_arlen;
	wire m_arsize;
	wire m_arburst;
	wire m_arlock;
	wire m_arcache;
	wire m_arprot;
	wire m_arqos;
	wire m_arvalid;
	wire m_arready;

	wire m_rid;
	wire m_rdata;
	wire m_rresp;
	wire m_rlast;
	wire m_rvalid;
	wire m_rready;

	// Reset synchronization for M_AXI_ACLK domain
	reg [FFS_STAGES-1 : 0] m_reset_sync;
	reg m_reset_sync_next;

	always @(posedge M_AXI_ACLK) begin
		m_reset_sync_next <= S_AXI_ARESETN;
		m_reset_sync <= {m_reset_sync[FFS_STAGES-2 : 0], m_reset_sync_next};
	end

	assign M_AXI_ARESETN = m_reset_sync[FFS_STAGES-1];

	// AW Channel: S to M
	// FIFO for AW channel
	reg [C_S_AXI_ID_WIDTH-1 : 0] aw_fifo_mem [0 : FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] aw_fifo_addr_mem [0 : FIFO_DEPTH-1];
	reg [7 : 0] aw_fifo_len_mem [0 : FIFO_DEPTH-1];
	reg [2 : 0] aw_fifo_size_mem [0 : FIFO_DEPTH-1];
	reg [1 : 0] aw_fifo_burst_mem [0 : FIFO_DEPTH-1];
	reg aw_fifo_lock_mem [0 : FIFO_DEPTH-1];
	reg [3 : 0] aw_fifo_cache_mem [0 : FIFO_DEPTH-1];
	reg [2 : 0] aw_fifo_prot_mem [0 : FIFO_DEPTH-1];
	reg [3 : 0] aw_fifo_qos_mem [0 : FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH : 0] aw_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] aw_fifo_rd_ptr;

	wire aw_fifo_full = (aw_fifo_wr_ptr[FIFO_ADDR_WIDTH] != aw_fifo_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                     (aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0] == aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]);
	wire aw_fifo_empty = (aw_fifo_wr_ptr == aw_fifo_rd_ptr);

	// Write to AW FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_fifo_wr_ptr <= 0;
		end else if (s_awvalid && s_awready) begin
			aw_fifo_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWID;
			aw_fifo_addr_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWADDR;
			aw_fifo_len_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWLEN;
			aw_fifo_size_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWSIZE;
			aw_fifo_burst_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWBURST;
			aw_fifo_lock_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWLOCK;
			aw_fifo_cache_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWCACHE;
			aw_fifo_prot_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWPROT;
			aw_fifo_qos_mem[aw_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_AWQOS;
			aw_fifo_wr_ptr <= aw_fifo_wr_ptr + 1;
		end
	end

	assign s_awready = !aw_fifo_full;

	// Read from AW FIFO in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			aw_fifo_rd_ptr <= 0;
			m_awid <= 0;
			m_awaddr <= 0;
			m_awlen <= 0;
			m_awsize <= 0;
			m_awburst <= 0;
			m_awlock <= 0;
			m_awcache <= 0;
			m_awprot <= 0;
			m_awqos <= 0;
			m_awvalid <= 0;
		end else begin
			if (m_awvalid && m_awready) begin
				m_awvalid <= 0;
				aw_fifo_rd_ptr <= aw_fifo_rd_ptr + 1;
			end else if (!m_awvalid && !aw_fifo_empty) begin
				m_awid <= aw_fifo_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awaddr <= aw_fifo_addr_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awlen <= aw_fifo_len_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awsize <= aw_fifo_size_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awburst <= aw_fifo_burst_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awlock <= aw_fifo_lock_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awcache <= aw_fifo_cache_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awprot <= aw_fifo_prot_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awqos <= aw_fifo_qos_mem[aw_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_awvalid <= 1;
			end
		end
	end

	// W Channel: S to M
	// FIFO for W channel
	reg [C_S_AXI_DATA_WIDTH-1 : 0] w_fifo_mem [0 : FIFO_DEPTH-1];
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_fifo_strb_mem [0 : FIFO_DEPTH-1];
	reg w_fifo_last_mem [0 : FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH : 0] w_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] w_fifo_rd_ptr;

	wire w_fifo_full = (w_fifo_wr_ptr[FIFO_ADDR_WIDTH] != w_fifo_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                   (w_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0] == w_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]);
	wire w_fifo_empty = (w_fifo_wr_ptr == w_fifo_rd_ptr);

	// Write to W FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_fifo_wr_ptr <= 0;
		end else if (s_wvalid && s_wready) begin
			w_fifo_mem[w_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_WDATA;
			w_fifo_strb_mem[w_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_WSTRB;
			w_fifo_last_mem[w_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_WLAST;
			w_fifo_wr_ptr <= w_fifo_wr_ptr + 1;
		end
	end

	assign s_wready = !w_fifo_full;

	// Read from W FIFO in M_AXI_ACLK domain
	// Master write data is held one extra M_AXI clock before M_AXI_WVALID
	reg w_data_hold;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] w_data_hold_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] w_strb_hold_reg;
	reg w_last_hold_reg;

	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			w_fifo_rd_ptr <= 0;
			m_wdata <= 0;
			m_wstrb <= 0;
			m_wlast <= 0;
			m_wvalid <= 0;
			w_data_hold <= 0;
			w_data_hold_reg <= 0;
			w_strb_hold_reg <= 0;
			w_last_hold_reg <= 0;
		end else begin
			if (m_wvalid && m_wready) begin
				m_wvalid <= 0;
				w_fifo_rd_ptr <= w_fifo_rd_ptr + 1;
			end else if (!m_wvalid && !w_fifo_empty) begin
				m_wdata <= w_fifo_mem[w_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_wstrb <= w_fifo_strb_mem[w_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_wlast <= w_fifo_last_mem[w_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_wvalid <= 1;
			end
		end
	end

	// B Channel: M to S
	// FIFO for B channel
	reg [C_S_AXI_ID_WIDTH-1 : 0] b_fifo_mem [0 : FIFO_DEPTH-1];
	reg [1 : 0] b_fifo_resp_mem [0 : FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH : 0] b_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] b_fifo_rd_ptr;

	wire b_fifo_full = (b_fifo_wr_ptr[FIFO_ADDR_WIDTH] != b_fifo_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                   (b_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0] == b_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]);
	wire b_fifo_empty = (b_fifo_wr_ptr == b_fifo_rd_ptr);

	// Write to B FIFO in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			b_fifo_wr_ptr <= 0;
		end else if (m_bvalid && m_bready) begin
			b_fifo_mem[b_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_BID;
			b_fifo_resp_mem[b_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_BRESP;
			b_fifo_wr_ptr <= b_fifo_wr_ptr + 1;
		end
	end

	assign m_bready = !b_fifo_full;

	// Read from B FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_fifo_rd_ptr <= 0;
			s_bid <= 0;
			s_bresp <= 0;
			s_bvalid <= 0;
		end else begin
			if (s_bvalid && s_bready) begin
				s_bvalid <= 0;
				b_fifo_rd_ptr <= b_fifo_rd_ptr + 1;
			end else if (!s_bvalid && !b_fifo_empty) begin
				s_bid <= b_fifo_mem[b_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_bresp <= b_fifo_resp_mem[b_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_bvalid <= 1;
			end
		end
	end

	// AR Channel: S to M
	// FIFO for AR channel
	reg [C_S_AXI_ID_WIDTH-1 : 0] ar_fifo_mem [0 : FIFO_DEPTH-1];
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] ar_fifo_addr_mem [0 : FIFO_DEPTH-1];
	reg [7 : 0] ar_fifo_len_mem [0 : FIFO_DEPTH-1];
	reg [2 : 0] ar_fifo_size_mem [0 : FIFO_DEPTH-1];
	reg [1 : 0] ar_fifo_burst_mem [0 : FIFO_DEPTH-1];
	reg ar_fifo_lock_mem [0 : FIFO_DEPTH-1];
	reg [3 : 0] ar_fifo_cache_mem [0 : FIFO_DEPTH-1];
	reg [2 : 0] ar_fifo_prot_mem [0 : FIFO_DEPTH-1];
	reg [3 : 0] ar_fifo_qos_mem [0 : FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH : 0] ar_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] ar_fifo_rd_ptr;

	wire ar_fifo_full = (ar_fifo_wr_ptr[FIFO_ADDR_WIDTH] != ar_fifo_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                     (ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0] == ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]);
	wire ar_fifo_empty = (ar_fifo_wr_ptr == ar_fifo_rd_ptr);

	// Write to AR FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_fifo_wr_ptr <= 0;
		end else if (s_arvalid && s_arready) begin
			ar_fifo_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARID;
			ar_fifo_addr_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARADDR;
			ar_fifo_len_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARLEN;
			ar_fifo_size_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARSIZE;
			ar_fifo_burst_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARBURST;
			ar_fifo_lock_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARLOCK;
			ar_fifo_cache_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARCACHE;
			ar_fifo_prot_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARPROT;
			ar_fifo_qos_mem[ar_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= S_AXI_ARQOS;
			ar_fifo_wr_ptr <= ar_fifo_wr_ptr + 1;
		end
	end

	assign s_arready = !ar_fifo_full;

	// Read from AR FIFO in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			ar_fifo_rd_ptr <= 0;
			m_arid <= 0;
			m_araddr <= 0;
			m_arlen <= 0;
			m_arsize <= 0;
			m_arburst <= 0;
			m_arlock <= 0;
			m_arcache <= 0;
			m_arprot <= 0;
			m_arqos <= 0;
			m_arvalid <= 0;
		end else begin
			if (m_arvalid && m_arready) begin
				m_arvalid <= 0;
				ar_fifo_rd_ptr <= ar_fifo_rd_ptr + 1;
			end else if (!m_arvalid && !ar_fifo_empty) begin
				m_arid <= ar_fifo_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_araddr <= ar_fifo_addr_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arlen <= ar_fifo_len_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arsize <= ar_fifo_size_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arburst <= ar_fifo_burst_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arlock <= ar_fifo_lock_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arcache <= ar_fifo_cache_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arprot <= ar_fifo_prot_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arqos <= ar_fifo_qos_mem[ar_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				m_arvalid <= 1;
			end
		end
	end

	// R Channel: M to S
	// FIFO for R channel
	reg [C_S_AXI_ID_WIDTH-1 : 0] r_fifo_mem [0 : FIFO_DEPTH-1];
	reg [C_S_AXI_DATA_WIDTH-1 : 0] r_fifo_data_mem [0 : FIFO_DEPTH-1];
	reg [1 : 0] r_fifo_resp_mem [0 : FIFO_DEPTH-1];
	reg r_fifo_last_mem [0 : FIFO_DEPTH-1];

	reg [FIFO_ADDR_WIDTH : 0] r_fifo_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] r_fifo_rd_ptr;

	wire r_fifo_full = (r_fifo_wr_ptr[FIFO_ADDR_WIDTH] != r_fifo_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                   (r_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0] == r_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]);
	wire r_fifo_empty = (r_fifo_wr_ptr == r_fifo_rd_ptr);

	// Write to R FIFO in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
		if (!M_AXI_ARESETN) begin
			r_fifo_wr_ptr <= 0;
		end else if (m_rvalid && m_rready) begin
			r_fifo_mem[r_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_RID;
			r_fifo_data_mem[r_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_RDATA;
			r_fifo_resp_mem[r_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_RRESP;
			r_fifo_last_mem[r_fifo_wr_ptr[FIFO_ADDR_WIDTH-1 : 0]] <= M_AXI_RLAST;
			r_fifo_wr_ptr <= r_fifo_wr_ptr + 1;
		end
	end

	assign m_rready = !r_fifo_full;

	// Read from R FIFO in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			r_fifo_rd_ptr <= 0;
			s_rid <= 0;
			s_rdata <= 0;
			s_rresp <= 0;
			s_rlast <= 0;
			s_rvalid <= 0;
		end else begin
			if (s_rvalid && s_rready) begin
				s_rvalid <= 0;
				r_fifo_rd_ptr <= r_fifo_rd_ptr + 1;
			end else if (!s_rvalid && !r_fifo_empty) begin
				s_rid <= r_fifo_mem[r_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_rdata <= r_fifo_data_mem[r_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_rresp <= r_fifo_resp_mem[r_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_rlast <= r_fifo_last_mem[r_fifo_rd_ptr[FIFO_ADDR_WIDTH-1 : 0]];
				s_rvalid <= 1;
			end
		end
	end

	// Assign outputs
	assign S_AXI_AWREADY = s_awready;
	assign S_AXI_WREADY = s_wready;
	assign S_AXI_BID = s_bid;
	assign S_AXI_BRESP = s_bresp;
	assign S_AXI_BVALID = s_bvalid;
	assign S_AXI_ARREADY = s_arready;
	assign S_AXI_RID = s_rid;
	assign S_AXI_RDATA = s_rdata;
	assign S_AXI_RRESP = s_rresp;
	assign S_AXI_RLAST = s_rlast;
	assign S_AXI_RVALID = s_rvalid;

	assign M_AXI_AWID = m_awid;
	assign M_AXI_AWADDR = m_awaddr;
	assign M_AXI_AWLEN = m_awlen;
	assign M_AXI_AWSIZE = m_awsize;
	assign M_AXI_AWBURST = m_awburst;
	assign M_AXI_AWLOCK = m_awlock;
	assign M_AXI_AWCACHE = m_awcache;
	assign M_AXI_AWPROT = m_awprot;
	assign M_AXI_AWQOS = m_awqos;
	assign M_AXI_AWVALID = m_awvalid;
	assign M_AXI_WDATA = m_wdata;
	assign M_AXI_WSTRB = m_wstrb;
	assign M_AXI_WLAST = m_wlast;
	assign M_AXI_WVALID = m_wvalid;
	assign M_AXI_BREADY = m_bready;
	assign M_AXI_ARID = m_arid;
	assign M_AXI_ARADDR = m_araddr;
	assign M_AXI_ARLEN = m_arlen;
	assign M_AXI_ARSIZE = m_arsize;
	assign M_AXI_ARBURST = m_arburst;
	assign M_AXI_ARLOCK = m_arlock;
	assign M_AXI_ARCACHE = m_arcache;
	assign M_AXI_ARPROT = m_arprot;
	assign M_AXI_ARQOS = m_arqos;
	assign M_AXI_ARVALID = m_arvalid;
	assign M_AXI_RREADY = m_rready;

	// Assign internal signals to input ports
	assign s_awid = S_AXI_AWID;
	assign s_awaddr = S_AXI_AWADDR;
	assign s_awlen = S_AXI_AWLEN;
	assign s_awsize = S_AXI_AWSIZE;
	assign s_awburst = S_AXI_AWBURST;
	assign s_awlock = S_AXI_AWLOCK;
	assign s_awcache = S_AXI_AWCACHE;
	assign s_awprot = S_AXI_AWPROT;
	assign s_awqos = S_AXI_AWQOS;
	assign s_awvalid = S_AXI_AWVALID;

	assign s_wdata = S_AXI_WDATA;
	assign s_wstrb = S_AXI_WSTRB;
	assign s_wlast = S_AXI_WLAST;
	assign s_wvalid = S_AXI_WVALID;

	assign s_bready = S_AXI_BREADY;

	assign s_arid = S_AXI_ARID;
	assign s_araddr = S_AXI_ARADDR;
	assign s_arlen = S_AXI_ARLEN;
	assign s_arsize = S_AXI_ARSIZE;
	assign s_arburst = S_AXI_ARBURST;
	assign s_arlock = S_AXI_ARLOCK;
	assign s_arcache = S_AXI_ARCACHE;
	assign s_arprot = S_AXI_ARPROT;
	assign s_arqos = S_AXI_ARQOS;
	assign s_arvalid = S_AXI_ARVALID;

	assign s_rready = S_AXI_RREADY;

	assign m_awready = M_AXI_AWREADY;
	assign m_wready = M_AXI_WREADY;
	assign m_bvalid = M_AXI_BVALID;
	assign m_arready = M_AXI_ARREADY;
	assign m_rvalid = M_AXI_RVALID;

endmodule
