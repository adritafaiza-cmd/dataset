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

	// Internal signals
	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_axi_bid_reg;
	reg [1 : 0]				s_axi_bresp_reg;
	reg					s_axi_bvalid_reg;
	reg [C_S_AXI_ID_WIDTH-1 : 0]	s_axi_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	s_axi_rdata_reg;
	reg [1 : 0]				s_axi_rresp_reg;
	reg					s_axi_rlast_reg;
	reg					s_axi_rvalid_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_awaddr_reg;
	reg [7 : 0]				m_axi_awlen_reg;
	reg [2 : 0]				m_axi_awsize_reg;
	reg [1 : 0]				m_axi_awburst_reg;
	reg					m_axi_awlock_reg;
	reg [3 : 0]				m_axi_awcache_reg;
	reg [2 : 0]				m_axi_awprot_reg;
	reg [3 : 0]				m_axi_awqos_reg;
	reg					m_axi_awvalid_reg;

	reg [C_S_AXI_DATA_WIDTH-1 : 0]	m_axi_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb_reg;
	reg					m_axi_wlast_reg;
	reg					m_axi_wvalid_reg;

	reg [C_S_AXI_ID_WIDTH-1 : 0]	m_axi_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0]	m_axi_araddr_reg;
	reg [7 : 0]				m_axi_arlen_reg;
	reg [2 : 0]				m_axi_arsize_reg;
	reg [1 : 0]				m_axi_arburst_reg;
	reg					m_axi_arlock_reg;
	reg [3 : 0]				m_axi_arcache_reg;
	reg [2 : 0]				m_axi_arprot_reg;
	reg [3 : 0]				m_axi_arqos_reg;
	reg					m_axi_arvalid_reg;

	// FIFOs for write address channel
	fifo_async #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) write_addr_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst(~S_AXI_ARESETN),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.wr_en(S_AXI_AWVALID && S_AXI_AWREADY),
		.rd_clk(M_AXI_ACLK),
		.rd_rst(~M_AXI_ARESETN),
		.dout({m_axi_awid_reg, m_axi_awaddr_reg, m_axi_awlen_reg, m_axi_awsize_reg, m_axi_awburst_reg, m_axi_awlock_reg, m_axi_awcache_reg, m_axi_awprot_reg, m_axi_awqos_reg}),
		.rd_en(M_AXI_AWREADY && M_AXI_AWVALID)
	);

	// FIFOs for write data channel
	fifo_async #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) write_data_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst(~S_AXI_ARESETN),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.wr_en(S_AXI_WVALID && S_AXI_WREADY),
		.rd_clk(M_AXI_ACLK),
		.rd_rst(~M_AXI_ARESETN),
		.dout({m_axi_wdata_reg, m_axi_wstrb_reg, m_axi_wlast_reg}),
		.rd_en(M_AXI_WREADY && M_AXI_WVALID)
	);

	// FIFOs for read address channel
	fifo_async #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) read_addr_fifo (
		.wr_clk(S_AXI_ACLK),
		.wr_rst(~S_AXI_ARESETN),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.wr_en(S_AXI_ARVALID && S_AXI_ARREADY),
		.rd_clk(M_AXI_ACLK),
		.rd_rst(~M_AXI_ARESETN),
		.dout({m_axi_arid_reg, m_axi_araddr_reg, m_axi_arlen_reg, m_axi_arsize_reg, m_axi_arburst_reg, m_axi_arlock_reg, m_axi_arcache_reg, m_axi_arprot_reg, m_axi_arqos_reg}),
		.rd_en(M_AXI_ARREADY && M_AXI_ARVALID)
	);

	// FIFOs for read data channel
	fifo_async #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 + 1),
		.DEPTH(1 << LGFIFO)
	) read_data_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst(~M_AXI_ARESETN),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST, M_AXI_RVALID}),
		.wr_en(M_AXI_RVALID && M_AXI_RREADY),
		.rd_clk(S_AXI_ACLK),
		.rd_rst(~S_AXI_ARESETN),
		.dout({s_axi_rid_reg, s_axi_rdata_reg, s_axi_rresp_reg, s_axi_rlast_reg, s_axi_rvalid_reg}),
		.rd_en(S_AXI_RREADY && S_AXI_RVALID)
	);

	// FIFOs for write response channel
	fifo_async #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) write_response_fifo (
		.wr_clk(M_AXI_ACLK),
		.wr_rst(~M_AXI_ARESETN),
		.din({M_AXI_BID, M_AXI_BRESP, M_AXI_BVALID}),
		.wr_en(M_AXI_BVALID && M_AXI_BREADY),
		.rd_clk(S_AXI_ACLK),
		.rd_rst(~S_AXI_ARESETN),
		.dout({s_axi_bid_reg, s_axi_bresp_reg, s_axi_bvalid_reg}),
		.rd_en(S_AXI_BREADY && S_AXI_BVALID)
	);

	// Handshake signals
	assign S_AXI_AWREADY = write_addr_fifo.wr_full ? 1'b0 : 1'b1;
	assign S_AXI_WREADY = write_data_fifo.wr_full ? 1'b0 : 1'b1;
	assign S_AXI_ARREADY = read_addr_fifo.wr_full ? 1'b0 : 1'b1;
	assign M_AXI_AWVALID = write_addr_fifo.rd_empty ? 1'b0 : 1'b1;
	assign M_AXI_WVALID = write_data_fifo.rd_empty ? 1'b0 : 1'b1;
	assign M_AXI_ARVALID = read_addr_fifo.rd_empty ? 1'b0 : 1'b1;
	assign M_AXI_BREADY = write_response_fifo.wr_full ? 1'b0 : 1'b1;
	assign M_AXI_RREADY = read_data_fifo.wr_full ? 1'b0 : 1'b1;
	assign S_AXI_BREADY = write_response_fifo.rd_empty ? 1'b0 : 1'b1;
	assign S_AXI_RREADY = read_data_fifo.rd_empty ? 1'b0 : 1'b1;

	// Output assignments
	assign S_AXI_BID = s_axi_bid_reg;
	assign S_AXI_BRESP = s_axi_bresp_reg;
	assign S_AXI_BVALID = s_axi_bvalid_reg;
	assign S_AXI_RID = s_axi_rid_reg;
	assign S_AXI_RDATA = s_axi_rdata_reg;
	assign S_AXI_RRESP = s_axi_rresp_reg;
	assign S_AXI_RLAST = s_axi_rlast_reg;
	assign S_AXI_RVALID = s_axi_rvalid_reg;

	assign M_AXI_ARESETN = S_AXI_ARESETN;
	assign M_AXI_AWID = m_axi_awid_reg;
	assign M_AXI_AWADDR = m_axi_awaddr_reg;
	assign M_AXI_AWLEN = m_axi_awlen_reg;
	assign M_AXI_AWSIZE = m_axi_awsize_reg;
	assign M_AXI_AWBURST = m_axi_awburst_reg;
	assign M_AXI_AWLOCK = m_axi_awlock_reg;
	assign M_AXI_AWCACHE = m_axi_awcache_reg;
	assign M_AXI_AWPROT = m_axi_awprot_reg;
	assign M_AXI_AWQOS = m_axi_awqos_reg;

	assign M_AXI_WDATA = m_axi_wdata_reg;
	assign M_AXI_WSTRB = m_axi_wstrb_reg;
	assign M_AXI_WLAST = m_axi_wlast_reg;

	assign M_AXI_ARID = m_axi_arid_reg;
	assign M_AXI_ARADDR = m_axi_araddr_reg;
	assign M_AXI_ARLEN = m_axi_arlen_reg;
	assign M_AXI_ARSIZE = m_axi_arsize_reg;
	assign M_AXI_ARBURST = m_axi_arburst_reg;
	assign M_AXI_ARLOCK = m_axi_arlock_reg;
	assign M_AXI_ARCACHE = m_axi_arcache_reg;
	assign M_AXI_ARPROT = m_axi_arprot_reg;
	assign M_AXI_ARQOS = m_axi_arqos_reg;

endmodule

// Asynchronous FIFO module
module fifo_async #(
	parameter WIDTH = 32,
	parameter DEPTH = 16
) (
	input wire wr_clk,
	input wire wr_rst,
	input wire [WIDTH-1:0] din,
	input wire wr_en,
	input wire rd_clk,
	input wire rd_rst,
	output reg [WIDTH-1:0] dout,
	input wire rd_en,
	output reg wr_full,
	output reg rd_empty
);

	// Internal signals
	reg [$clog2(DEPTH)-1:0] wr_ptr;
	reg [$clog2(DEPTH)-1:0] rd_ptr;
	reg [$clog2(DEPTH):0] diff;
	reg [WIDTH-1:0] mem [DEPTH-1:0];

	// Write pointer logic
	always @(posedge wr_clk or posedge wr_rst) begin
		if (wr_rst) begin
			wr_ptr <= 0;
		end else if (wr_en && !wr_full) begin
			wr_ptr <= wr_ptr + 1;
			mem[wr_ptr] <= din;
		end
	end

	// Read pointer logic
	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			rd_ptr <= 0;
		end else if (rd_en && !rd_empty) begin
			rd_ptr <= rd_ptr + 1;
		end
	end

	// Difference calculation
	always @(posedge wr_clk or posedge wr_rst) begin
		if (wr_rst) begin
			diff <= 0;
		end else begin
			if (wr_en && !wr_full)
				diff <= diff + 1;
			else if (rd_en && !rd_empty)
				diff <= diff - 1;
		end
	end

	// Output data
	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			dout <= 0;
		end else if (rd_en && !rd_empty) begin
			dout <= mem[rd_ptr];
		end
	end

	// Full and empty flags
	always @(posedge wr_clk or posedge wr_rst) begin
		if (wr_rst) begin
			wr_full <= 0;
		end else begin
			if (diff == DEPTH)
				wr_full <= 1;
			else
				wr_full <= 0;
		end
	end

	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			rd_empty <= 1;
		end else begin
			if (diff == 0)
				rd_empty <= 1;
			else
				rd_empty <= 0;
		end
	end

endmodule
