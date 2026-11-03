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

	wire [C_S_AXI_ID_WIDTH-1 : 0] awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_ff;
	wire [7 : 0] awlen_ff;
	wire [2 : 0] awsize_ff;
	wire [1 : 0] awburst_ff;
	wire awlock_ff;
	wire [3 : 0] awcache_ff;
	wire [2 : 0] awprot_ff;
	wire [3 : 0] awqos_ff;
	wire awvalid_ff;
	wire awready_ff;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_ff;
	wire wlast_ff;
	wire wvalid_ff;
	wire wready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] bid_ff;
	wire [1 : 0] bresp_ff;
	wire bvalid_ff;
	wire bready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_ff;
	wire [7 : 0] arlen_ff;
	wire [2 : 0] arsize_ff;
	wire [1 : 0] arburst_ff;
	wire arlock_ff;
	wire [3 : 0] arcache_ff;
	wire [2 : 0] arprot_ff;
	wire [3 : 0] arqos_ff;
	wire arvalid_ff;
	wire arready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_ff;
	wire [1 : 0] rresp_ff;
	wire rlast_ff;
	wire rvalid_ff;
	wire rready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_awid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr_ff;
	wire [7 : 0] m_awlen_ff;
	wire [2 : 0] m_awsize_ff;
	wire [1 : 0] m_awburst_ff;
	wire m_awlock_ff;
	wire [3 : 0] m_awcache_ff;
	wire [2 : 0] m_awprot_ff;
	wire [3 : 0] m_awqos_ff;
	wire m_awvalid_ff;
	wire m_awready_ff;

	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_ff;
	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_ff;
	wire m_wlast_ff;
	wire m_wvalid_ff;
	wire m_wready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_bid_ff;
	wire [1 : 0] m_bresp_ff;
	wire m_bvalid_ff;
	wire m_bready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_arid_ff;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr_ff;
	wire [7 : 0] m_arlen_ff;
	wire [2 : 0] m_arsize_ff;
	wire [1 : 0] m_arburst_ff;
	wire m_arlock_ff;
	wire [3 : 0] m_arcache_ff;
	wire [2 : 0] m_arprot_ff;
	wire [3 : 0] m_arqos_ff;
	wire m_arvalid_ff;
	wire m_arready_ff;

	wire [C_S_AXI_ID_WIDTH-1 : 0] m_rid_ff;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata_ff;
	wire [1 : 0] m_rresp_ff;
	wire m_rlast_ff;
	wire m_rvalid_ff;
	wire m_rready_ff;

	reg [XCLOCK_FFS-1 : 0] s_axi_aresetn_ff;
	reg [XCLOCK_FFS-1 : 0] m_axi_aresetn_ff;

	always @(posedge S_AXI_ACLK) begin
		s_axi_aresetn_ff <= {s_axi_aresetn_ff[XCLOCK_FFS-2 : 0], S_AXI_ARESETN};
	end

	always @(posedge M_AXI_ACLK) begin
		m_axi_aresetn_ff <= {m_axi_aresetn_ff[XCLOCK_FFS-2 : 0], 1'b1};
	end

	assign M_AXI_ARESETN = m_axi_aresetn_ff[XCLOCK_FFS-1];

	wire s_axi_aresetn_sync = s_axi_aresetn_ff[XCLOCK_FFS-1];

	wire [LGFIFO-1 : 0] awfifo_cnt;
	wire [LGFIFO-1 : 0] wfifo_cnt;
	wire [LGFIFO-1 : 0] bfifo_cnt;
	wire [LGFIFO-1 : 0] arfifo_cnt;
	wire [LGFIFO-1 : 0] rfifo_cnt;

	wire awfifo_empty;
	wire wfifo_empty;
	wire bfifo_empty;
	wire arfifo_empty;
	wire rfifo_empty;

	wire awfifo_full;
	wire wfifo_full;
	wire bfifo_full;
	wire arfifo_full;
	wire rfifo_full;

	wire awfifo_rden;
	wire wfifo_rden;
	wire bfifo_rden;
	wire arfifo_rden;
	wire rfifo_rden;

	wire awfifo_wren;
	wire wfifo_wren;
	wire bfifo_wren;
	wire arfifo_wren;
	wire rfifo_wren;

	assign awfifo_rden = (awfifo_empty == 1'b0) && (M_AXI_AWREADY == 1'b1);
	assign wfifo_rden = (wfifo_empty == 1'b0) && (M_AXI_WREADY == 1'b1);
	assign bfifo_rden = (bfifo_empty == 1'b0) && (S_AXI_BREADY == 1'b1);
	assign arfifo_rden = (arfifo_empty == 1'b0) && (M_AXI_ARREADY == 1'b1);
	assign rfifo_rden = (rfifo_empty == 1'b0) && (S_AXI_RREADY == 1'b1);

	assign awfifo_wren = (awfifo_full == 1'b0) && (S_AXI_AWVALID == 1'b1) && (S_AXI_AWREADY == 1'b1);
	assign wfifo_wren = (wfifo_full == 1'b0) && (S_AXI_WVALID == 1'b1) && (S_AXI_WREADY == 1'b1);
	assign bfifo_wren = (bfifo_full == 1'b0) && (M_AXI_BVALID == 1'b1) && (M_AXI_BREADY == 1'b1);
	assign arfifo_wren = (arfifo_full == 1'b0) && (S_AXI_ARVALID == 1'b1) && (S_AXI_ARREADY == 1'b1);
	assign rfifo_wren = (rfifo_full == 1'b0) && (M_AXI_RVALID == 1'b1) && (M_AXI_RREADY == 1'b1);

	assign S_AXI_AWREADY = (awfifo_full == 1'b0) && (wfifo_full == 1'b0);
	assign S_AXI_WREADY = (wfifo_full == 1'b0);
	assign S_AXI_BVALID = (bfifo_empty == 1'b0);
	assign S_AXI_ARREADY = (arfifo_full == 1'b0) && (rfifo_full == 1'b0);
	assign S_AXI_RVALID = (rfifo_empty == 1'b0);

	assign M_AXI_AWVALID = (awfifo_empty == 1'b0);
	assign M_AXI_WVALID = (wfifo_empty == 1'b0);
	assign M_AXI_BREADY = (bfifo_empty == 1'b0);
	assign M_AXI_ARVALID = (arfifo_empty == 1'b0);
	assign M_AXI_RREADY = (rfifo_empty == 1'b0);

	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 1 + 4 + 3 + 4),
		.DDEPTH(1 << LGFIFO)
	) awfifo (
		.clk(S_AXI_ACLK),
		.rst(~s_axi_aresetn_sync),
		.wren(awfifo_wren),
		.wdata({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
		.rden(awfifo_rden),
		.rdata({awid_ff, awaddr_ff, awlen_ff, awsize_ff, awburst_ff, awlock_ff, awcache_ff, awprot_ff, awqos_ff}),
		.empty(awfifo_empty),
		.full(awfifo_full),
		.cnt(awfifo_cnt)
	);

	fifo #(
		.DWIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
		.DDEPTH(1 << LGFIFO)
	) wfifo (
		.clk(S_AXI_ACLK),
		.rst(~s_axi_aresetn_sync),
		.wren(wfifo_wren),
		.wdata({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
		.rden(wfifo_rden),
		.rdata({wdata_ff, wstrb_ff, wlast_ff}),
		.empty(wfifo_empty),
		.full(wfifo_full),
		.cnt(wfifo_cnt)
	);

	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + 2),
		.DDEPTH(1 << LGFIFO)
	) bfifo (
		.clk(M_AXI_ACLK),
		.rst(~m_axi_aresetn_ff[XCLOCK_FFS-1]),
		.wren(bfifo_wren),
		.wdata({M_AXI_BID, M_AXI_BRESP}),
		.rden(bfifo_rden),
		.rdata({bid_ff, bresp_ff}),
		.empty(bfifo_empty),
		.full(bfifo_full),
		.cnt(bfifo_cnt)
	);

	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 1 + 4 + 3 + 4),
		.DDEPTH(1 << LGFIFO)
	) arfifo (
		.clk(S_AXI_ACLK),
		.rst(~s_axi_aresetn_sync),
		.wren(arfifo_wren),
		.wdata({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
		.rden(arfifo_rden),
		.rdata({arid_ff, araddr_ff, arlen_ff, arsize_ff, arburst_ff, arlock_ff, arcache_ff, arprot_ff, arqos_ff}),
		.empty(arfifo_empty),
		.full(arfifo_full),
		.cnt(arfifo_cnt)
	);

	fifo #(
		.DWIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
		.DDEPTH(1 << LGFIFO)
	) rfifo (
		.clk(M_AXI_ACLK),
		.rst(~m_axi_aresetn_ff[XCLOCK_FFS-1]),
		.wren(rfifo_wren),
		.wdata({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
		.rden(rfifo_rden),
		.rdata({rid_ff, rdata_ff, rresp_ff, rlast_ff}),
		.empty(rfifo_empty),
		.full(rfifo_full),
		.cnt(rfifo_cnt)
	);

	assign M_AXI_AWID = awid_ff;
	assign M_AXI_AWADDR = awaddr_ff;
	assign M_AXI_AWLEN = awlen_ff;
	assign M_AXI_AWSIZE = awsize_ff;
	assign M_AXI_AWBURST = awburst_ff;
	assign M_AXI_AWLOCK = awlock_ff;
	assign M_AXI_AWCACHE = awcache_ff;
	assign M_AXI_AWPROT = awprot_ff;
	assign M_AXI_AWQOS = awqos_ff;

	assign M_AXI_WDATA = wdata_ff;
	assign M_AXI_WSTRB = wstrb_ff;
	assign M_AXI_WLAST = wlast_ff;

	assign S_AXI_BID = bid_ff;
	assign S_AXI_BRESP = bresp_ff;

	assign M_AXI_ARID = arid_ff;
	assign M_AXI_ARADDR = araddr_ff;
	assign M_AXI_ARLEN = arlen_ff;
	assign M_AXI_ARSIZE = arsize_ff;
	assign M_AXI_ARBURST = arburst_ff;
	assign M_AXI_ARLOCK = arlock_ff;
	assign M_AXI_ARCACHE = arcache_ff;
	assign M_AXI_ARPROT = arprot_ff;
	assign M_AXI_ARQOS = arqos_ff;

	assign S_AXI_RID = rid_ff;
	assign S_AXI_RDATA = rdata_ff;
	assign S_AXI_RRESP = rresp_ff;
	assign S_AXI_RLAST = rlast_ff;

endmodule

module fifo #(
	parameter integer DWIDTH = 32,
	parameter integer DDEPTH = 16
) (
	input	wire	clk,
	input	wire	rst,
	input	wire	wren,
	input	wire	[C_S_AXI_DATA_WIDTH-1 : 0] wdata,
	input	wire	rden,
	output	wire	[C_S_AXI_DATA_WIDTH-1 : 0] rdata,
	output	wire	empty,
	output	wire	full,
	output	wire	[DDEPTH-1 : 0] cnt
);

	reg [DWIDTH-1 : 0] fifo_reg [DDEPTH-1 : 0];
	reg [DDEPTH-1 : 0] cnt_reg;
	reg empty_reg;
	reg full_reg;

	always @(posedge clk) begin
		if (~rst) begin
			cnt_reg <= 0;
			empty_reg <= 1'b1;
			full_reg <= 1'b0;
		end else begin
			if (wren && ~full_reg) begin
				fifo_reg[cnt_reg] <= wdata;
				cnt_reg <= cnt_reg + 1;
				empty_reg <= 1'b0;
				if (cnt_reg == DDEPTH - 1) begin
					full_reg <= 1'b1;
				end
			end

			if (rden && ~empty_reg) begin
				rdata <= fifo_reg[0];
				cnt_reg <= cnt_reg - 1;
				full_reg <= 1'b0;
				if (cnt_reg == 0) begin
					empty_reg <= 1'b1;
				end
			end
		end
	end

	assign rdata = fifo_reg[0];
	assign empty = empty_reg;
	assign full = full_reg;
	assign cnt = cnt_reg;

endmodule
