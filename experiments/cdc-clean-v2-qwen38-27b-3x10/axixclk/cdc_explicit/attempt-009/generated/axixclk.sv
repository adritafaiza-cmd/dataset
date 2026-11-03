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

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_awid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr;
	wire [7 : 0] m_awlen;
	wire [2 : 0] m_awsize;
	wire [1 : 0] m_awburst;
	wire m_awlock;
	wire [3 : 0] m_awcache;
	wire [2 : 0] m_awprot;
	wire [3 : 0] m_awqos;
	wire m_awvalid;
	wire m_awready;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb;
	wire m_wlast;
	wire m_wvalid;
	wire m_wready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_bid;
	wire [1 : 0] m_bresp;
	wire m_bvalid;
	wire m_bready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_arid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr;
	wire [7 : 0] m_arlen;
	wire [2 : 0] m_arsize;
	wire [1 : 0] m_arburst;
	wire m_arlock;
	wire [3 : 0] m_arcache;
	wire [2 : 0] m_arprot;
	wire [3 : 0] m_arqos;
	wire m_arvalid;
	wire m_arready;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_rid;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata;
	wire [1 : 0] m_rresp;
	wire m_rlast;
	wire m_rvalid;
	wire m_rready;

	wire m_axi_aresetn;

	// Connect slave inputs to internal signals
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

	// Connect internal signals to slave outputs
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

	// Connect internal signals to master outputs
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

	// Connect master inputs to internal signals
	assign m_awready = M_AXI_AWREADY;
	assign m_wready = M_AXI_WREADY;
	assign m_bid = M_AXI_BID;
	assign m_bresp = M_AXI_BRESP;
	assign m_bvalid = M_AXI_BVALID;
	assign m_arready = M_AXI_ARREADY;
	assign m_rid = M_AXI_RID;
	assign m_rdata = M_AXI_RDATA;
	assign m_rresp = M_AXI_RRESP;
	assign m_rlast = M_AXI_RLAST;
	assign m_rvalid = M_AXI_RVALID;

	// Reset synchronization
	// Synchronize S_AXI_ARESETN to M_AXI_ACLK domain
	reg [FFS_STAGES-1 : 0] s_reset_sync;
	reg m_axi_aresetn_reg;

	always @(posedge M_AXI_ACLK or negedge s_reset_sync[0]) begin
		if (!s_reset_sync[0]) begin
			m_axi_aresetn_reg <= 1'b0;
		end else begin
			m_axi_aresetn_reg <= 1'b1;
		end
	end

	always @(posedge M_AXI_ACLK) begin
		s_reset_sync <= {s_reset_sync[FFS_STAGES-2:0], S_AXI_ARESETN};
	end

	assign M_AXI_ARESETN = m_axi_aresetn_reg;

	// AW channel CDC: S_AXI_ACLK -> M_AXI_ACLK
	// Use FIFO-based CDC for multi-bit data
	// AW channel: ID, ADDR, LEN, SIZE, BURST, LOCK, CACHE, PROT, QOS
	localparam integer AW_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AW_FIFO_DEPTH = FIFO_DEPTH;

	// AW FIFO in S_AXI_ACLK domain
	reg [AW_DATA_WIDTH-1 : 0] aw_fifo_mem [0 : AW_FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH : 0] aw_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] aw_rd_ptr;
	wire aw_fifo_full;
	wire aw_fifo_empty;

	assign aw_fifo_full = (aw_wr_ptr[FIFO_ADDR_WIDTH] != aw_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                      (aw_wr_ptr[FIFO_ADDR_WIDTH-1:0] == aw_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign aw_fifo_empty = (aw_wr_ptr == aw_rd_ptr);

	// AW write in S_AXI_ACLK domain
	wire aw_write_en = s_awvalid && s_awready;
	wire [AW_DATA_WIDTH-1 : 0] aw_data_in;
	assign aw_data_in = {s_awid, s_awaddr, s_awlen, s_awsize, s_awburst, s_awlock, s_awcache, s_awprot, s_awqos};

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			aw_wr_ptr <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else if (aw_write_en) begin
			aw_fifo_mem[aw_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= aw_data_in;
			aw_wr_ptr <= aw_wr_ptr + 1'b1;
		end
	end

	// AW read in M_AXI_ACLK domain
	reg [AW_DATA_WIDTH-1 : 0] aw_data_out;
	reg [FIFO_ADDR_WIDTH : 0] aw_rd_ptr_m;
	wire aw_read_en = m_awvalid && m_awready;

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			aw_rd_ptr_m <= {(FIFO_ADDR_WIDTH+1){1'b0}};
			aw_data_out <= {AW_DATA_WIDTH{1'b0}};
		end else if (aw_read_en) begin
			aw_rd_ptr_m <= aw_rd_ptr_m + 1'b1;
		end
	end

	// Synchronize read pointer to S_AXI_ACLK domain
	reg [FIFO_ADDR_WIDTH : 0] aw_rd_ptr_sync [0 : FFS_STAGES-1];
	always @(posedge S_AXI_ACLK) begin
		aw_rd_ptr_sync[0] <= aw_rd_ptr_m;
		for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
			aw_rd_ptr_sync[i] <= aw_rd_ptr_sync[i-1];
		end
	end

	assign s_awready = !aw_fifo_full;

	// AW output in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			m_awid <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_awlen <= 8'b0;
			m_awsize <= 3'b0;
			m_awburst <= 2'b0;
			m_awlock <= 1'b0;
			m_awcache <= 4'b0;
			m_awprot <= 3'b0;
			m_awqos <= 4'b0;
			m_awvalid <= 1'b0;
		end else begin
			if (aw_read_en) begin
				m_awvalid <= 1'b0;
			end else if (!aw_fifo_empty && !m_awvalid) begin
				// Read from FIFO
				aw_data_out <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]];
				m_awid <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-1 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH];
				m_awaddr <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH];
				m_awlen <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-1 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-8];
				m_awsize <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-9 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-11];
				m_awburst <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-12 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-13];
				m_awlock <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-14];
				m_awcache <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-15 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-18];
				m_awprot <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-19 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-21];
				m_awqos <= aw_fifo_mem[aw_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-22 : AW_DATA_WIDTH-C_S_AXI_ID_WIDTH-C_S_AXI_ADDR_WIDTH-25];
				m_awvalid <= 1'b1;
			end
		end
	end

	// W channel CDC: S_AXI_ACLK -> M_AXI_ACLK
	localparam integer W_DATA_WIDTH = C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1;
	localparam integer W_FIFO_DEPTH = FIFO_DEPTH;

	// W FIFO in S_AXI_ACLK domain
	reg [W_DATA_WIDTH-1 : 0] w_fifo_mem [0 : W_FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH : 0] w_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] w_rd_ptr;
	wire w_fifo_full;
	wire w_fifo_empty;

	assign w_fifo_full = (w_wr_ptr[FIFO_ADDR_WIDTH] != w_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                     (w_wr_ptr[FIFO_ADDR_WIDTH-1:0] == w_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign w_fifo_empty = (w_wr_ptr == w_rd_ptr);

	// W write in S_AXI_ACLK domain
	wire w_write_en = s_wvalid && s_wready;
	wire [W_DATA_WIDTH-1 : 0] w_data_in;
	assign w_data_in = {s_wdata, s_wstrb, s_wlast};

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			w_wr_ptr <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else if (w_write_en) begin
			w_fifo_mem[w_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= w_data_in;
			w_wr_ptr <= w_wr_ptr + 1'b1;
		end
	end

	// W read in M_AXI_ACLK domain
	reg [W_DATA_WIDTH-1 : 0] w_data_out;
	reg [FIFO_ADDR_WIDTH : 0] w_rd_ptr_m;
	wire w_read_en = m_wvalid && m_wready;

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			w_rd_ptr_m <= {(FIFO_ADDR_WIDTH+1){1'b0}};
			w_data_out <= {W_DATA_WIDTH{1'b0}};
		end else if (w_read_en) begin
			w_rd_ptr_m <= w_rd_ptr_m + 1'b1;
		end
	end

	// Synchronize read pointer to S_AXI_ACLK domain
	reg [FIFO_ADDR_WIDTH : 0] w_rd_ptr_sync [0 : FFS_STAGES-1];
	always @(posedge S_AXI_ACLK) begin
		w_rd_ptr_sync[0] <= w_rd_ptr_m;
		for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
			w_rd_ptr_sync[i] <= w_rd_ptr_sync[i-1];
		end
	end

	assign s_wready = !w_fifo_full;

	// W output in M_AXI_ACLK domain - hold one extra M_AXI clock before M_AXI_WVALID
	reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_reg;
	reg m_wlast_reg;
	reg m_wvalid_reg;
	reg w_data_loaded;

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			m_wdata_reg <= {C_S_AXI_DATA_WIDTH{1'b0}};
			m_wstrb_reg <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
			m_wlast_reg <= 1'b0;
			m_wvalid_reg <= 1'b0;
			w_data_loaded <= 1'b0;
		end else begin
			if (w_read_en) begin
				m_wvalid_reg <= 1'b0;
				w_data_loaded <= 1'b0;
			end else if (!w_fifo_empty && !m_wvalid_reg && !w_data_loaded) begin
				// Load data from FIFO
				m_wdata_reg <= w_fifo_mem[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][W_DATA_WIDTH-1 : W_DATA_WIDTH-C_S_AXI_DATA_WIDTH];
				m_wstrb_reg <= w_fifo_mem[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][W_DATA_WIDTH-C_S_AXI_DATA_WIDTH-1 : W_DATA_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)];
				m_wlast_reg <= w_fifo_mem[w_rd_ptr_m[FIFO_ADDR_WIDTH-1:0]][W_DATA_WIDTH-C_S_AXI_DATA_WIDTH-(C_S_AXI_DATA_WIDTH/8)-1];
				w_data_loaded <= 1'b1;
			end else if (w_data_loaded && !m_wvalid_reg) begin
				// Hold one extra clock, then assert valid
				m_wvalid_reg <= 1'b1;
			end
		end
	end

	assign m_wdata = m_wdata_reg;
	assign m_wstrb = m_wstrb_reg;
	assign m_wlast = m_wlast_reg;
	assign m_wvalid = m_wvalid_reg;

	// B channel CDC: M_AXI_ACLK -> S_AXI_ACLK
	localparam integer B_DATA_WIDTH = C_S_AXI_ID_WIDTH + 2;
	localparam integer B_FIFO_DEPTH = FIFO_DEPTH;

	// B FIFO in M_AXI_ACLK domain
	reg [B_DATA_WIDTH-1 : 0] b_fifo_mem [0 : B_FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH : 0] b_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] b_rd_ptr;
	wire b_fifo_full;
	wire b_fifo_empty;

	assign b_fifo_full = (b_wr_ptr[FIFO_ADDR_WIDTH] != b_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                     (b_wr_ptr[FIFO_ADDR_WIDTH-1:0] == b_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign b_fifo_empty = (b_wr_ptr == b_rd_ptr);

	// B write in M_AXI_ACLK domain
	wire b_write_en = m_bvalid && m_bready;
	wire [B_DATA_WIDTH-1 : 0] b_data_in;
	assign b_data_in = {m_bid, m_bresp};

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			b_wr_ptr <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else if (b_write_en) begin
			b_fifo_mem[b_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= b_data_in;
			b_wr_ptr <= b_wr_ptr + 1'b1;
		end
	end

	// B read in S_AXI_ACLK domain
	reg [B_DATA_WIDTH-1 : 0] b_data_out;
	reg [FIFO_ADDR_WIDTH : 0] b_rd_ptr_s;
	wire b_read_en = s_bvalid && s_bready;

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			b_rd_ptr_s <= {(FIFO_ADDR_WIDTH+1){1'b0}};
			b_data_out <= {B_DATA_WIDTH{1'b0}};
		end else if (b_read_en) begin
			b_rd_ptr_s <= b_rd_ptr_s + 1'b1;
		end
	end

	// Synchronize read pointer to M_AXI_ACLK domain
	reg [FIFO_ADDR_WIDTH : 0] b_rd_ptr_sync [0 : FFS_STAGES-1];
	always @(posedge M_AXI_ACLK) begin
		b_rd_ptr_sync[0] <= b_rd_ptr_s;
		for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
			b_rd_ptr_sync[i] <= b_rd_ptr_sync[i-1];
		end
	end

	assign m_bready = !b_fifo_full;

	// B output in S_AXI_ACLK domain
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid <= {C_S_AXI_ID_WIDTH{1'b0}};
			s_bresp <= 2'b0;
			s_bvalid <= 1'b0;
		end else begin
			if (b_read_en) begin
				s_bvalid <= 1'b0;
			end else if (!b_fifo_empty && !s_bvalid) begin
				s_bid <= b_fifo_mem[b_rd_ptr_s[FIFO_ADDR_WIDTH-1:0]][B_DATA_WIDTH-1 : B_DATA_WIDTH-C_S_AXI_ID_WIDTH];
				s_bresp <= b_fifo_mem[b_rd_ptr_s[FIFO_ADDR_WIDTH-1:0]][B_DATA_WIDTH-C_S_AXI_ID_WIDTH-1 : B_DATA_WIDTH-C_S_AXI_ID_WIDTH-2];
				s_bvalid <= 1'b1;
			end
		end
	end

	// AR channel CDC: S_AXI_ACLK -> M_AXI_ACLK
	localparam integer AR_DATA_WIDTH = C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4;
	localparam integer AR_FIFO_DEPTH = FIFO_DEPTH;

	// AR FIFO in S_AXI_ACLK domain
	reg [AR_DATA_WIDTH-1 : 0] ar_fifo_mem [0 : AR_FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH : 0] ar_wr_ptr;
	reg [FIFO_ADDR_WIDTH : 0] ar_rd_ptr;
	wire ar_fifo_full;
	wire ar_fifo_empty;

	assign ar_fifo_full = (ar_wr_ptr[FIFO_ADDR_WIDTH] != ar_rd_ptr[FIFO_ADDR_WIDTH]) && 
	                      (ar_wr_ptr[FIFO_ADDR_WIDTH-1:0] == ar_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	assign ar_fifo_empty = (ar_wr_ptr == ar_rd_ptr);

	// AR write in S_AXI_ACLK domain
	wire ar_write_en = s_arvalid && s_arready;
	wire [AR_DATA_WIDTH-1 : 0] ar_data_in;
	assign ar_data_in = {s_arid, s_araddr, s_arlen, s_arsize, s_arburst, s_arlock, s_arcache, s_arprot, s_arqos};

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			ar_wr_ptr <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else if (ar_write_en) begin
			ar_fifo_mem[ar_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= ar_data_in;
			ar_wr_ptr <= ar_wr_ptr + 1'b1;
		end
	end

	// AR read in M_AXI_ACLK domain
	reg [AR_DATA_WIDTH-1 : 0] ar_data_out;
	reg [FIFO_ADDR_WIDTH : 0] ar_rd_ptr_m;
	wire ar_read_en = m_arvalid && m_arready;

	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			ar_rd_ptr_m <= {(FIFO_ADDR_WIDTH+1){1'b0}};
			ar_data_out <= {AR_DATA_WIDTH{1'b0}};
		end else if (ar_read_en) begin
			ar_rd_ptr_m <= ar_rd_ptr_m + 1'b1;
		end
	end

	// Synchronize read pointer to S_AXI_ACLK domain
	reg [FIFO_ADDR_WIDTH : 0] ar_rd_ptr_sync [0 : FFS_STAGES-1];
	always @(posedge S_AXI_ACLK) begin
		ar_rd_ptr_sync[0] <= ar_rd_ptr_m;
		for (integer i = 1; i < FFS_STAGES; i = i + 1) begin
			ar_rd_ptr_sync[i] <= ar_rd_ptr_sync[i-1];
		end
	end

	assign s_arready = !ar_fifo_full;

	// AR output in M_AXI_ACLK domain
	always @(posedge M_AXI_ACLK or negedge m_axi_aresetn_reg) begin
		if (!m_axi_aresetn_reg) begin
			m_arid <= {C_S_AXI_ID_WIDTH{1'b0}};
			m_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
			m_arlen <= 8'b0;
			m_arsize <= 3'b0;
			m_arburst <= 2'b0;
			m_arlock <= 1'b0;
			m_arcache <= 4'b0;
			m_arprot <= 3'b0;
			m_arqos <= 4'b0;
			m_arvalid <= 1'b0