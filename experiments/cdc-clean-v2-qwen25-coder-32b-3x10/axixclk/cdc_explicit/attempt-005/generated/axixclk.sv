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
	reg [XCLOCK_FFS-1:0] s_reset_sync;
	reg [XCLOCK_FFS-1:0] m_reset_sync;
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
	reg s_wvalid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0] s_wdata_reg;
	reg [(C_S_AXI_DATA_WIDTH/8)-1:0] s_wstrb_reg;
	reg s_wlast_reg;
	reg s_arvalid_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] s_arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] s_araddr_reg;
	reg [7:0] s_arlen_reg;
	reg [2:0] s_arsize_reg;
	reg [1:0] s_arburst_reg;
	reg s_arlock_reg;
	reg [3:0] s_arcache_reg;
	reg [2:0] s_arprot_reg;
	reg [3:0] s_arqos_reg;
	reg m_awready_reg;
	reg m_wready_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] m_bid_reg;
	reg [1:0] m_bresp_reg;
	reg m_bvalid_reg;
	reg m_arready_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] m_rid_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0] m_rdata_reg;
	reg [1:0] m_rresp_reg;
	reg m_rlast_reg;
	reg m_rvalid_reg;

	// Reset synchronization
	generate
		genvar i;
		for (i = 0; i < XCLOCK_FFS; i = i + 1) begin : gen_reset_sync
			if (i == 0) begin
				ff_sync s_reset_sync_ff (
					.clk(S_AXI_ACLK),
					.d(~S_AXI_ARESETN),
					.q(s_reset_sync[i])
				);
				ff_sync m_reset_sync_ff (
					.clk(M_AXI_ACLK),
					.d(~S_AXI_ARESETN),
					.q(m_reset_sync[i])
				);
			end else begin
				ff_sync s_reset_sync_ff (
					.clk(S_AXI_ACLK),
					.d(s_reset_sync[i-1]),
					.q(s_reset_sync[i])
				);
				ff_sync m_reset_sync_ff (
					.clk(M_AXI_ACLK),
					.d(m_reset_sync[i-1]),
					.q(m_reset_sync[i])
				);
			end
		end
	endgenerate

	assign M_AXI_ARESETN = ~m_reset_sync[XCLOCK_FFS-1];

	// Write Address Channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) aw_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_reset_sync[XCLOCK_FFS-1]),
		.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
		.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.rd_en(M_AXI_AWREADY & M_AXI_AWVALID),
		.dout({m_awid_reg, m_awaddr_reg, m_awlen_reg, m_awsize_reg, m_awburst_reg, m_awlock_reg, m_awcache_reg, m_awprot_reg, m_awqos_reg}),
		.full(),
		.empty(m_awready_reg)
	);

	assign S_AXI_AWREADY = ~m_awready_reg;

	// Write Data Channel
	fifo #(
		.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DEPTH(1 << LGFIFO)
	) w_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_reset_sync[XCLOCK_FFS-1]),
		.wr_en(S_AXI_WVALID & S_AXI_WREADY),
		.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.rd_en(M_AXI_WREADY & M_AXI_WVALID),
		.dout({m_wdata_reg, m_wstrb_reg, m_wlast_reg}),
		.full(),
		.empty(m_wready_reg)
	);

	assign S_AXI_WREADY = ~m_wready_reg;

	// Write Response Channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + 2),
		.DEPTH(1 << LGFIFO)
	) b_fifo (
		.clk(M_AXI_ACLK),
		.rst(m_reset_sync[XCLOCK_FFS-1]),
		.wr_en(M_AXI_BVALID & M_AXI_BREADY),
		.din({M_AXI_BID, M_AXI_BRESP}),
		.rd_en(S_AXI_BREADY & S_AXI_BVALID),
		.dout({s_bid_reg, s_bresp_reg}),
		.full(),
		.empty(s_bvalid_reg)
	);

	assign M_AXI_BREADY = ~s_bvalid_reg;
	assign S_AXI_BID = s_bid_reg;
	assign S_AXI_BRESP = s_bresp_reg;
	assign S_AXI_BVALID = ~s_bvalid_reg;

	// Read Address Channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
		.DEPTH(1 << LGFIFO)
	) ar_fifo (
		.clk(S_AXI_ACLK),
		.rst(s_reset_sync[XCLOCK_FFS-1]),
		.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
		.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.rd_en(M_AXI_ARREADY & M_AXI_ARVALID),
		.dout({m_arid_reg, m_araddr_reg, m_arlen_reg, m_arsize_reg, m_arburst_reg, m_arlock_reg, m_arcache_reg, m_arprot_reg, m_arqos_reg}),
		.full(),
		.empty(m_arready_reg)
	);

	assign S_AXI_ARREADY = ~m_arready_reg;

	// Read Data Channel
	fifo #(
		.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DEPTH(1 << LGFIFO)
	) r_fifo (
		.clk(M_AXI_ACLK),
		.rst(m_reset_sync[XCLOCK_FFS-1]),
		.wr_en(M_AXI_RVALID & M_AXI_RREADY),
		.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.rd_en(S_AXI_RREADY & S_AXI_RVALID),
		.dout({s_rid_reg, s_rdata_reg, s_rresp_reg, s_rlast_reg}),
		.full(),
		.empty(s_rvalid_reg)
	);

	assign M_AXI_RREADY = ~s_rvalid_reg;
	assign S_AXI_RID = s_rid_reg;
	assign S_AXI_RDATA = s_rdata_reg;
	assign S_AXI_RRESP = s_rresp_reg;
	assign S_AXI_RLAST = s_rlast_reg;
	assign S_AXI_RVALID = ~s_rvalid_reg;

	// Master Write Address Channel
	assign M_AXI_AWID = m_awid_reg;
	assign M_AXI_AWADDR = m_awaddr_reg;
	assign M_AXI_AWLEN = m_awlen_reg;
	assign M_AXI_AWSIZE = m_awsize_reg;
	assign M_AXI_AWBURST = m_awburst_reg;
	assign M_AXI_AWLOCK = m_awlock_reg;
	assign M_AXI_AWCACHE = m_awcache_reg;
	assign M_AXI_AWPROT = m_awprot_reg;
	assign M_AXI_AWQOS = m_awqos_reg;
	assign M_AXI_AWVALID = ~m_awready_reg;

	// Master Write Data Channel
	assign M_AXI_WDATA = m_wdata_reg;
	assign M_AXI_WSTRB = m_wstrb_reg;
	assign M_AXI_WLAST = m_wlast_reg;
	assign M_AXI_WVALID = ~m_wready_reg;

	// Master Read Address Channel
	assign M_AXI_ARID = m_arid_reg;
	assign M_AXI_ARADDR = m_araddr_reg;
	assign M_AXI_ARLEN = m_arlen_reg;
	assign M_AXI_ARSIZE = m_arsize_reg;
	assign M_AXI_ARBURST = m_arburst_reg;
	assign M_AXI_ARLOCK = m_arlock_reg;
	assign M_AXI_ARCACHE = m_arcache_reg;
	assign M_AXI_ARPROT = m_arprot_reg;
	assign M_AXI_ARQOS = m_arqos_reg;
	assign M_AXI_ARVALID = ~m_arready_reg;

endmodule

module fifo #(
		parameter WIDTH = 32,
		parameter DEPTH = 16
	) (
		input wire clk,
		input wire rst,
		input wire wr_en,
		input wire [WIDTH-1:0] din,
		input wire rd_en,
		output reg [WIDTH-1:0] dout,
		output reg full,
		output reg empty
	);

	localparam ADDR_WIDTH = $clog2(DEPTH);
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0] wr_ptr;
	reg [ADDR_WIDTH-1:0] rd_ptr;
	reg [ADDR_WIDTH:0] count;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			count <= 0;
			full <= 0;
			empty <= 1;
		end else begin
			if (wr_en && !full) begin
				mem[wr_ptr] <= din;
				wr_ptr <= wr_ptr + 1;
				count <= count + 1;
			end
			if (rd_en && !empty) begin
				dout <= mem[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				count <= count - 1;
			end
			full <= (count == DEPTH);
			empty <= (count == 0);
		end
	end

endmodule

module ff_sync (
		input wire clk,
		input wire d,
		output reg q
	);

	always @(posedge clk) begin
		q <= d;
	end

endmodule
