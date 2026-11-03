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

	// Internal signals for write address channel
	reg [C_S_AXI_ID_WIDTH-1:0]	s_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0]	s_awaddr_reg;
	reg [7:0]			s_awlen_reg;
	reg [2:0]			s_awsize_reg;
	reg [1:0]			s_awburst_reg;
	reg				s_awlock_reg;
	reg [3:0]			s_awcache_reg;
	reg [2:0]			s_awprot_reg;
	reg [3:0]			s_awqos_reg;
	reg				s_awvalid_reg;
	reg				s_awready_reg;
	reg				s_awready_d1;

	// Internal signals for write data channel
	reg [C_S_AXI_DATA_WIDTH-1:0]	s_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0]	s_wstrb_reg;
	reg				s_wlast_reg;
	reg				s_wvalid_reg;
	reg				s_wready_reg;
	reg				s_wready_d1;

	// Internal signals for write response channel
	reg [C_S_AXI_ID_WIDTH-1:0]	s_bid_reg;
	reg [1:0]			s_bresp_reg;
	reg				s_bvalid_reg;
	reg				s_bready_reg;

	// Internal signals for read address channel
	reg [C_S_AXI_ID_WIDTH-1:0]	s_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0]	s_araddr_reg;
	reg [7:0]			s_arlen_reg;
	reg [2:0]			s_arsize_reg;
	reg [1:0]			s_arburst_reg;
	reg				s_arlock_reg;
	reg [3:0]			s_arcache_reg;
	reg [2:0]			s_arprot_reg;
	reg [3:0]			s_arqos_reg;
	reg				s_arvalid_reg;
	reg				s_arready_reg;
	reg				s_arready_d1;

	// Internal signals for read data channel
	reg [C_S_AXI_ID_WIDTH-1:0]	s_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0]	s_rdata_reg;
	reg [1:0]			s_rresp_reg;
	reg				s_rlast_reg;
	reg				s_rvalid_reg;
	reg				s_rready_reg;

	// Internal signals for master reset
	reg				m_aresetn_reg;

	// FIFOs for write address channel
	wire				awfifo_full;
	wire				awfifo_empty;
	wire				awfifo_rdack;
	wire				awfifo_wrack;
	reg [C_S_AXI_ID_WIDTH-1:0]	awfifo_awid;
	reg [C_S_AXI_ADDR_WIDTH-1:0]	awfifo_awaddr;
	reg [7:0]			awfifo_awlen;
	reg [2:0]			awfifo_awsize;
	reg [1:0]			awfifo_awburst;
	reg				awfifo_awlock;
	reg [3:0]			awfifo_awcache;
	reg [2:0]			awfifo_awprot;
	reg [3:0]			awfifo_awqos;

	// FIFOs for write data channel
	wire				wfifo_full;
	wire				wfifo_empty;
	wire				wfifo_rdack;
	wire				wfifo_wrack;
	reg [C_S_AXI_DATA_WIDTH-1:0]	wfifo_wdata;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0]	wfifo_wstrb;
	reg				wfifo_wlast;

	// FIFOs for read address channel
	wire				arfifo_full;
	wire				arfifo_empty;
	wire				arfifo_rdack;
	wire				arfifo_wrack;
	reg [C_S_AXI_ID_WIDTH-1:0]	arfifo_arid;
	reg [C_S_AXI_ADDR_WIDTH-1:0]	arfifo_araddr;
	reg [7:0]			arfifo_arlen;
	reg [2:0]			arfifo_arsize;
	reg [1:0]			arfifo_arburst;
	reg				arfifo_arlock;
	reg [3:0]			arfifo_arcache;
	reg [2:0]			arfifo_arprot;
	reg [3:0]			arfifo_arqos;

	// FIFOs for write address channel
	sync_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH (2**LGFIFO)
	) awfifo (
		.clk_wr (S_AXI_ACLK),
		.rst_wr (!S_AXI_ARESETN),
		.wr_en  (s_awvalid_reg & s_awready_reg),
		.wr_data({s_awid_reg, s_awaddr_reg, s_awlen_reg, s_awsize_reg, s_awburst_reg, s_awlock_reg, s_awcache_reg, s_awprot_reg, s_awqos_reg}),
		.full   (awfifo_full),
		.clk_rd (M_AXI_ACLK),
		.rst_rd (!m_aresetn_reg),
		.rd_en  (M_AXI_AWREADY & M_AXI_AWVALID),
		.rd_data({awfifo_awid, awfifo_awaddr, awfifo_awlen, awfifo_awsize, awfifo_awburst, awfifo_awlock, awfifo_awcache, awfifo_awprot, awfifo_awqos}),
		.empty  (awfifo_empty),
		.rd_ack (awfifo_rdack),
		.wr_ack (awfifo_wrack)
	);

	// FIFOs for write data channel
	sync_fifo #(
		.WIDTH (C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH (2**LGFIFO)
	) wfifo (
		.clk_wr (S_AXI_ACLK),
		.rst_wr (!S_AXI_ARESETN),
		.wr_en  (s_wvalid_reg & s_wready_reg),
		.wr_data({s_wdata_reg, s_wstrb_reg, s_wlast_reg}),
		.full   (wfifo_full),
		.clk_rd (M_AXI_ACLK),
		.rst_rd (!m_aresetn_reg),
		.rd_en  (M_AXI_WREADY & M_AXI_WVALID),
		.rd_data({wfifo_wdata, wfifo_wstrb, wfifo_wlast}),
		.empty  (wfifo_empty),
		.rd_ack (wfifo_rdack),
		.wr_ack (wfifo_wrack)
	);

	// FIFOs for read address channel
	sync_fifo #(
		.WIDTH (C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH (2**LGFIFO)
	) arfifo (
		.clk_wr (S_AXI_ACLK),
		.rst_wr (!S_AXI_ARESETN),
		.wr_en  (s_arvalid_reg & s_arready_reg),
		.wr_data({s_arid_reg, s_araddr_reg, s_arlen_reg, s_arsize_reg, s_arburst_reg, s_arlock_reg, s_arcache_reg, s_arprot_reg, s_arqos_reg}),
		.full   (arfifo_full),
		.clk_rd (M_AXI_ACLK),
		.rst_rd (!m_aresetn_reg),
		.rd_en  (M_AXI_ARREADY & M_AXI_ARVALID),
		.rd_data({arfifo_arid, arfifo_araddr, arfifo_arlen, arfifo_arsize, arfifo_arburst, arfifo_arlock, arfifo_arcache, arfifo_arprot, arfifo_arqos}),
		.empty  (arfifo_empty),
		.rd_ack (arfifo_rdack),
		.wr_ack (arfifo_wrack)
	);

	// Write address channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awvalid_reg <= 1'b0;
		end else begin
			if (S_AXI_AWVALID && s_awready_reg) begin
				s_awvalid_reg <= 1'b0;
			end else if (S_AXI_AWVALID && !awfifo_full) begin
				s_awid_reg <= S_AXI_AWID;
				s_awaddr_reg <= S_AXI_AWADDR;
				s_awlen_reg <= S_AXI_AWLEN;
				s_awsize_reg <= S_AXI_AWSIZE;
				s_awburst_reg <= S_AXI_AWBURST;
				s_awlock_reg <= S_AXI_AWLOCK;
				s_awcache_reg <= S_AXI_AWCACHE;
				s_awprot_reg <= S_AXI_AWPROT;
				s_awqos_reg <= S_AXI_AWQOS;
				s_awvalid_reg <= 1'b1;
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_awready_reg <= 1'b0;
		end else begin
			s_awready_reg <= !s_awvalid_reg & !awfifo_full;
		end
	end

	assign S_AXI_AWREADY = s_awready_reg;

	// Write data channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wvalid_reg <= 1'b0;
		end else begin
			if (S_AXI_WVALID && s_wready_reg) begin
				s_wvalid_reg <= 1'b0;
			end else if (S_AXI_WVALID && !wfifo_full) begin
				s_wdata_reg <= S_AXI_WDATA;
				s_wstrb_reg <= S_AXI_WSTRB;
				s_wlast_reg <= S_AXI_WLAST;
				s_wvalid_reg <= 1'b1;
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_wready_reg <= 1'b0;
		end else begin
			s_wready_reg <= !s_wvalid_reg & !wfifo_full;
		end
	end

	assign S_AXI_WREADY = s_wready_reg;

	// Write response channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_bid_reg <= 0;
			s_bresp_reg <= 0;
			s_bvalid_reg <= 0;
		end else begin
			if (S_AXI_BREADY && s_bvalid_reg) begin
				s_bvalid_reg <= 0;
			end else if (M_AXI_BVALID && !s_bvalid_reg) begin
				s_bid_reg <= M_AXI_BID;
				s_bresp_reg <= M_AXI_BRESP;
				s_bvalid_reg <= 1;
			end
		end
	end

	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = s_bvalid_reg;
	assign M_AXI_BREADY = S_AXI_BREADY;

	// Read address channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arvalid_reg <= 1'b0;
		end else begin
			if (S_AXI_ARVALID && s_arready_reg) begin
				s_arvalid_reg <= 1'b0;
			end else if (S_AXI_ARVALID && !arfifo_full) begin
				s_arid_reg <= S_AXI_ARID;
				s_araddr_reg <= S_AXI_ARADDR;
				s_arlen_reg <= S_AXI_ARLEN;
				s_arsize_reg <= S_AXI_ARSIZE;
				s_arburst_reg <= S_AXI_ARBURST;
				s_arlock_reg <= S_AXI_ARLOCK;
				s_arcache_reg <= S_AXI_ARCACHE;
				s_arprot_reg <= S_AXI_ARPROT;
				s_arqos_reg <= S_AXI_ARQOS;
				s_arvalid_reg <= 1'b1;
			end
		end
	end

	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_arready_reg <= 1'b0;
		end else begin
			s_arready_reg <= !s_arvalid_reg & !arfifo_full;
		end
	end

	assign S_AXI_ARREADY = s_arready_reg;

	// Read data channel logic
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_rid_reg <= 0;
			s_rdata_reg <= 0;
			s_rresp_reg <= 0;
			s_rlast_reg <= 0;
			s_rvalid_reg <= 0;
		end else begin
			if (S_AXI_RREADY && s_rvalid_reg) begin
				s_rvalid_reg <= 0;
			end else if (M_AXI_RVALID && !s_rvalid_reg) begin
				s_rid_reg <= M_AXI_RID;
				s_rdata_reg <= M_AXI_RDATA;
				s_rresp_reg <= M_AXI_RRESP;
				s_rlast_reg <= M_AXI_RLAST;
				s_rvalid_reg <= 1;
			end
		end
	end

	assign S_AXI_RID = s_rid_reg;
	assign S_AXI_RDATA = s_rdata_reg;
	assign S_AXI_RRESP = s_rresp_reg;
	assign S_AXI_RLAST = s_rlast_reg;
	assign S_AXI_RVALID = s_rvalid_reg;
	assign M_AXI_RREADY = S_AXI_RREADY;

	// Master reset logic
	always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_aresetn_reg <= 1'b0;
		end else begin
			m_aresetn_reg <= 1'b1;
		end
	end

	assign M_AXI_ARESETN = m_aresetn_reg;

	// Master write address channel logic
	always @(posedge M_AXI_ACLK or negedge m_aresetn_reg) begin
		if (!m_aresetn_reg) begin
			M_AXI_AWID <= 0;
			M_AXI_AWADDR <= 0;
			M_AXI_AWLEN <= 0;
			M_AXI_AWSIZE <= 0;
			M_AXI_AWBURST <= 0;
			M_AXI_AWLOCK <= 0;
			M_AXI_AWCACHE <= 0;
			M_AXI_AWPROT <= 0;
			M_AXI_AWQOS <= 0;
			M_AXI_AWVALID <= 0;
		end else begin
			if (M_AXI_AWREADY && M_AXI_AWVALID) begin
				M_AXI_AWVALID <= 0;
			end else if (!awfifo_empty) begin
				M_AXI_AWID <= awfifo_awid;
				M_AXI_AWADDR <= awfifo_awaddr;
				M_AXI_AWLEN <= awfifo_awlen;
				M_AXI_AWSIZE <= awfifo_awsize;
				M_AXI_AWBURST <= awfifo_awburst;
				M_AXI_AWLOCK <= awfifo_awlock;
				M_AXI_AWCACHE <= awfifo_awcache;
				M_AXI_AWPROT <= awfifo_awprot;
				M_AXI_AWQOS <= awfifo_awqos;
				M_AXI_AWVALID <= 1;
			end
		end
	end

	// Master write data channel logic
	always @(posedge M_AXI_ACLK or negedge m_aresetn_reg) begin
		if (!m_aresetn_reg) begin
			M_AXI_WDATA <= 0;
			M_AXI_WSTRB <= 0;
			M_AXI_WLAST <= 0;
			M_AXI_WVALID <= 0;
		end else begin
			if (M_AXI_WREADY && M_AXI_WVALID) begin
				M_AXI_WVALID <= 0;
			end else if (!wfifo_empty) begin
				M_AXI_WDATA <= wfifo_wdata;
				M_AXI_WSTRB <= wfifo_wstrb;
				M_AXI_WLAST <= wfifo_wlast;
				M_AXI_WVALID <= 1;
			end
		end
	end

	// Master read address channel logic
	always @(posedge M_AXI_ACLK or negedge m_aresetn_reg) begin
		if (!m_aresetn_reg) begin
			M_AXI_ARID <= 0;
			M_AXI_ARADDR <= 0;
			M_AXI_ARLEN <= 0;
			M_AXI_ARSIZE <= 0;
			M_AXI_ARBURST <= 0;
			M_AXI_ARLOCK <= 0;
			M_AXI_ARCACHE <= 0;
			M_AXI_ARPROT <= 0;
			M_AXI_ARQOS <= 0;
			M_AXI_ARVALID <= 0;
		end else begin
			if (M_AXI_ARREADY && M_AXI_ARVALID) begin
				M_AXI_ARVALID <= 0;
			end else if (!arfifo_empty) begin
				M_AXI_ARID <= arfifo_arid;
				M_AXI_ARADDR <= arfifo_araddr;
				M_AXI_ARLEN <= arfifo_arlen;
				M_AXI_ARSIZE <= arfifo_arsize;
				M_AXI_ARBURST <= arfifo_arburst;
				M_AXI_ARLOCK <= arfifo_arlock;
				M_AXI_ARCACHE <= arfifo_arcache;
				M_AXI_ARPROT <= arfifo_arprot;
				M_AXI_ARQOS <= arfifo_arqos;
				M_AXI_ARVALID <= 1;
			end
		end
	end

endmodule

// Synchronous FIFO module
module sync_fifo #(
	parameter WIDTH = 8,
	parameter DEPTH = 16
) (
	input	wire				clk_wr,
	input	wire				rst_wr,
	input	wire				wr_en,
	input	wire [WIDTH-1 : 0]		wr_data,
	output	reg					full,
	input	wire				clk_rd,
	input	wire				rst_rd,
	input	wire				rd_en,
	output	reg [WIDTH-1 : 0]		rd_data,
	output	reg					empty,
	output	reg					rd_ack,
	output	reg					wr_ack
);

	// FIFO memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write and read pointers
	reg [$clog2(DEPTH)-1:0] wr_ptr;
	reg [$clog2(DEPTH)-1:0] rd_ptr;

	// FIFO status flags
	reg [XCLOCK_FFS-1:0] full_flags;
	reg [XCLOCK_FFS-1:0] empty_flags;

	// Write pointer update
	always @(posedge clk_wr or posedge rst_wr) begin
		if (rst_wr) begin
			wr_ptr <= 0;
			full_flags <= 0;
			wr_ack <= 0;
		end else begin
			if (wr_en && !full) begin
				mem[wr_ptr] <= wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ack <= 1;
			end else begin
				wr_ack <= 0;
			end
			full_flags[0] <= (wr_ptr == rd_ptr - 1) || (wr_ptr == DEPTH - 1 && rd_ptr == 0);
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1) begin
				full_flags[i] <= full_flags[i-1];
			end
			full <= full_flags[XCLOCK_FFS-1];
		end
	end

	// Read pointer update
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			rd_ptr <= 0;
			empty_flags <= 0;
			rd_ack <= 0;
		end else begin
			if (rd_en && !empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_ack <= 1;
			end else begin
				rd_ack <= 0;
			end
			empty_flags[0] <= (wr_ptr == rd_ptr);
			for (integer i = 1; i < XCLOCK_FFS; i = i + 1) begin
				empty_flags[i] <= empty_flags[i-1];
			end
			empty <= empty_flags[XCLOCK_FFS-1];
		end
	end

	// Read data output
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			rd_data <= 0;
		end else begin
			if (rd_ack) begin
				rd_data <= mem[rd_ptr];
			end
		end
	end

endmodule
