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

reg [C_S_AXI_ID_WIDTH-1 : 0]	awid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	awaddr_reg;
reg [7 : 0]			awlen_reg;
reg [2 : 0]			awsize_reg;
reg [1 : 0]			awburst_reg;
reg				awlock_reg;
reg [3 : 0]			awcache_reg;
reg [2 : 0]			awprot_reg;
reg [3 : 0]			awqos_reg;
reg				awvalid_reg;
reg				awready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	arid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]	araddr_reg;
reg [7 : 0]			arlen_reg;
reg [2 : 0]			arsize_reg;
reg [1 : 0]			arburst_reg;
reg				arlock_reg;
reg [3 : 0]			arcache_reg;
reg [2 : 0]			arprot_reg;
reg [3 : 0]			arqos_reg;
reg				arvalid_reg;
reg				arready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	bid_reg;
reg [1 : 0]			bresp_reg;
reg				bvalid_reg;
reg				bready_reg;

reg [C_S_AXI_ID_WIDTH-1 : 0]	rid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0]	rdata_reg;
reg [1 : 0]			rresp_reg;
reg				rlast_reg;
reg				rvalid_reg;
reg				rready_reg;

reg [C_S_AXI_DATA_WIDTH-1 : 0]	wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	wstrb_reg;
reg				wlast_reg;
reg				wvalid_reg;
reg				wready_reg;

reg				m_axi_aresetn_reg;

wire				awfifo_empty;
wire				awfifo_full;
wire				awfifo_almost_empty;
wire				awfifo_almost_full;
wire				arfifo_empty;
wire				arfifo_full;
wire				arfifo_almost_empty;
wire				arfifo_almost_full;
wire				wfifo_empty;
wire				wfifo_full;
wire				wfifo_almost_empty;
wire				wfifo_almost_full;
wire				bfifo_empty;
wire				bfifo_full;
wire				bfifo_almost_empty;
wire				bfifo_almost_full;
wire				rfifo_empty;
wire				rfifo_full;
wire				rfifo_almost_empty;
wire				rfifo_almost_full;

awfifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.C_DEPTH(1 << LGFIFO)
) awfifo_inst (
	.clk(S_AXI_ACLK),
	.rst(!S_AXI_ARESETN),
	.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
	.dout({awid_reg, awaddr_reg, awlen_reg, awsize_reg, awburst_reg, awlock_reg, awcache_reg, awprot_reg, awqos_reg}),
	.wr(S_AXI_AWVALID && !awfifo_full),
	.rd(awvalid_reg && M_AXI_AWREADY),
	.empty(awfifo_empty),
	.full(awfifo_full),
	.almost_empty(awfifo_almost_empty),
	.almost_full(awfifo_almost_full)
);

arfifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.C_DEPTH(1 << LGFIFO)
) arfifo_inst (
	.clk(S_AXI_ACLK),
	.rst(!S_AXI_ARESETN),
	.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
	.dout({arid_reg, araddr_reg, arlen_reg, arsize_reg, arburst_reg, arlock_reg, arcache_reg, arprot_reg, arqos_reg}),
	.wr(S_AXI_ARVALID && !arfifo_full),
	.rd(arvalid_reg && M_AXI_ARREADY),
	.empty(arfifo_empty),
	.full(arfifo_full),
	.almost_empty(arfifo_almost_empty),
	.almost_full(arfifo_almost_full)
);

wfifo #(
	.C_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
	.C_DEPTH(1 << LGFIFO)
) wfifo_inst (
	.clk(S_AXI_ACLK),
	.rst(!S_AXI_ARESETN),
	.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
	.dout({wdata_reg, wstrb_reg, wlast_reg}),
	.wr(S_AXI_WVALID && !wfifo_full),
	.rd(wvalid_reg && M_AXI_WREADY),
	.empty(wfifo_empty),
	.full(wfifo_full),
	.almost_empty(wfifo_almost_empty),
	.almost_full(wfifo_almost_full)
);

bfifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + 2),
	.C_DEPTH(1 << LGFIFO)
) bfifo_inst (
	.clk(M_AXI_ACLK),
	.rst(!m_axi_aresetn_reg),
	.din({M_AXI_BID, M_AXI_BRESP}),
	.dout({bid_reg, bresp_reg}),
	.wr(M_AXI_BVALID && !bfifo_full),
	.rd(bvalid_reg && S_AXI_BREADY),
	.empty(bfifo_empty),
	.full(bfifo_full),
	.almost_empty(bfifo_almost_empty),
	.almost_full(bfifo_almost_full)
);

rfifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
	.C_DEPTH(1 << LGFIFO)
) rfifo_inst (
	.clk(M_AXI_ACLK),
	.rst(!m_axi_aresetn_reg),
	.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
	.dout({rid_reg, rdata_reg, rresp_reg, rlast_reg}),
	.wr(M_AXI_RVALID && !rfifo_full),
	.rd(rvalid_reg && S_AXI_RREADY),
	.empty(rfifo_empty),
	.full(rfifo_full),
	.almost_empty(rfifo_almost_empty),
	.almost_full(rfifo_almost_full)
);

always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		S_AXI_AWREADY <= 1'b0;
		S_AXI_WREADY <= 1'b0;
		S_AXI_ARREADY <= 1'b0;
		S_AXI_BID <= {C_S_AXI_ID_WIDTH{1'b0}};
		S_AXI_BRESP <= 2'b0;
		S_AXI_BVALID <= 1'b0;
		S_AXI_RID <= {C_S_AXI_ID_WIDTH{1'b0}};
		S_AXI_RDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
		S_AXI_RRESP <= 2'b0;
		S_AXI_RLAST <= 1'b0;
		S_AXI_RVALID <= 1'b0;
	end else begin
		S_AXI_AWREADY <= awfifo_almost_empty && !awfifo_full;
		S_AXI_WREADY <= wfifo_almost_empty && !wfifo_full;
		S_AXI_ARREADY <= arfifo_almost_empty && !arfifo_full;
		S_AXI_BID <= bid_reg;
		S_AXI_BRESP <= bresp_reg;
		S_AXI_BVALID <= bvalid_reg;
		S_AXI_RID <= rid_reg;
		S_AXI_RDATA <= rdata_reg;
		S_AXI_RRESP <= rresp_reg;
		S_AXI_RLAST <= rlast_reg;
		S_AXI_RVALID <= rvalid_reg;
	end
end

always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		M_AXI_AWID <= {C_S_AXI_ID_WIDTH{1'b0}};
		M_AXI_AWADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
		M_AXI_AWLEN <= 8'b0;
		M_AXI_AWSIZE <= 3'b0;
		M_AXI_AWBURST <= 2'b0;
		M_AXI_AWLOCK <= 1'b0;
		M_AXI_AWCACHE <= 4'b0;
		M_AXI_AWPROT <= 3'b0;
		M_AXI_AWQOS <= 4'b0;
		M_AXI_AWVALID <= 1'b0;
		M_AXI_WDATA <= {C_S_AXI_DATA_WIDTH{1'b0}};
		M_AXI_WSTRB <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
		M_AXI_WLAST <= 1'b0;
		M_AXI_WVALID <= 1'b0;
		M_AXI_BREADY <= 1'b0;
		M_AXI_ARID <= {C_S_AXI_ID_WIDTH{1'b0}};
		M_AXI_ARADDR <= {C_S_AXI_ADDR_WIDTH{1'b0}};
		M_AXI_ARLEN <= 8'b0;
		M_AXI_ARSIZE <= 3'b0;
		M_AXI_ARBURST <= 2'b0;
		M_AXI_ARLOCK <= 1'b0;
		M_AXI_ARCACHE <= 4'b0;
		M_AXI_ARPROT <= 3'b0;
		M_AXI_ARQOS <= 4'b0;
		M_AXI_ARVALID <= 1'b0;
		M_AXI_RREADY <= 1'b0;
	end else begin
		M_AXI_AWID <= awid_reg;
		M_AXI_AWADDR <= awaddr_reg;
		M_AXI_AWLEN <= awlen_reg;
		M_AXI_AWSIZE <= awsize_reg;
		M_AXI_AWBURST <= awburst_reg;
		M_AXI_AWLOCK <= awlock_reg;
		M_AXI_AWCACHE <= awcache_reg;
		M_AXI_AWPROT <= awprot_reg;
		M_AXI_AWQOS <= awqos_reg;
		M_AXI_AWVALID <= awvalid_reg;
		M_AXI_WDATA <= wdata_reg;
		M_AXI_WSTRB <= wstrb_reg;
		M_AXI_WLAST <= wlast_reg;
		M_AXI_WVALID <= wvalid_reg;
		M_AXI_BREADY <= bready_reg;
		M_AXI_ARID <= arid_reg;
		M_AXI_ARADDR <= araddr_reg;
		M_AXI_ARLEN <= arlen_reg;
		M_AXI_ARSIZE <= arsize_reg;
		M_AXI_ARBURST <= arburst_reg;
		M_AXI_ARLOCK <= arlock_reg;
		M_AXI_ARCACHE <= arcache_reg;
		M_AXI_ARPROT <= arprot_reg;
		M_AXI_ARQOS <= arqos_reg;
		M_AXI_ARVALID <= arvalid_reg;
		M_AXI_RREADY <= rready_reg;
	end
end

always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		awvalid_reg <= 1'b0;
		arvalid_reg <= 1'b0;
		wvalid_reg <= 1'b0;
		bready_reg <= 1'b0;
		rready_reg <= 1'b0;
	end else begin
		awvalid_reg <= awfifo_almost_empty && !awfifo_full;
		arvalid_reg <= arfifo_almost_empty && !arfifo_full;
		wvalid_reg <= wfifo_almost_empty && !wfifo_full;
		bready_reg <= bfifo_almost_empty && !bfifo_full;
		rready_reg <= rfifo_almost_empty && !rfifo_full;
	end
end

always @(posedge M_AXI_ACLK) begin
	if (!m_axi_aresetn_reg) begin
		bvalid_reg <= 1'b0;
		rvalid_reg <= 1'b0;
	end else begin
		bvalid_reg <= bfifo_almost_empty && !bfifo_full;
		rvalid_reg <= rfifo_almost_empty && !rfifo_full;
	end
end

always @(posedge S_AXI_ACLK) begin
	if (!S_AXI_ARESETN) begin
		m_axi_aresetn_reg <= 1'b0;
	end else begin
		m_axi_aresetn_reg <= S_AXI_ARESETN;
	end
end

assign M_AXI_ARESETN = m_axi_aresetn_reg;

endmodule

module awfifo #(
	parameter C_WIDTH = 32,
	parameter C_DEPTH = 32
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [C_WIDTH-1 : 0]	din,
	output	wire [C_WIDTH-1 : 0]	dout,
	input	wire	wr,
	input	wire	rd,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [C_WIDTH-1 : 0]	ram [C_DEPTH-1 : 0];
reg [XCLOCK_FFS-1 : 0]	wr_ptr;
reg [XCLOCK_FFS-1 : 0]	rd_ptr;
reg [XCLOCK_FFS-1 : 0]	count;

always @(posedge clk) begin
	if (!rst) begin
		wr_ptr <= {XCLOCK_FFS{1'b0}};
		rd_ptr <= {XCLOCK_FFS{1'b0}};
		count <= {XCLOCK_FFS{1'b0}};
	end else if (wr && !full) begin
		ram[wr_ptr] <= din;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
	end
end

always @(posedge clk) begin
	if (!rst) begin
		dout <= {C_WIDTH{1'b0}};
	end else if (rd && !empty) begin
		dout <= ram[rd_ptr];
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
	end
end

assign empty = (count == {XCLOCK_FFS{1'b0}});
assign full = (count == C_DEPTH);
assign almost_empty = (count == 1);
assign almost_full = (count == C_DEPTH - 1);

endmodule

module arfifo #(
	parameter C_WIDTH = 32,
	parameter C_DEPTH = 32
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [C_WIDTH-1 : 0]	din,
	output	wire [C_WIDTH-1 : 0]	dout,
	input	wire	wr,
	input	wire	rd,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [C_WIDTH-1 : 0]	ram [C_DEPTH-1 : 0];
reg [XCLOCK_FFS-1 : 0]	wr_ptr;
reg [XCLOCK_FFS-1 : 0]	rd_ptr;
reg [XCLOCK_FFS-1 : 0]	count;

always @(posedge clk) begin
	if (!rst) begin
		wr_ptr <= {XCLOCK_FFS{1'b0}};
		rd_ptr <= {XCLOCK_FFS{1'b0}};
		count <= {XCLOCK_FFS{1'b0}};
	end else if (wr && !full) begin
		ram[wr_ptr] <= din;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
	end
end

always @(posedge clk) begin
	if (!rst) begin
		dout <= {C_WIDTH{1'b0}};
	end else if (rd && !empty) begin
		dout <= ram[rd_ptr];
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
	end
end

assign empty = (count == {XCLOCK_FFS{1'b0}});
assign full = (count == C_DEPTH);
assign almost_empty = (count == 1);
assign almost_full = (count == C_DEPTH - 1);

endmodule

module wfifo #(
	parameter C_WIDTH = 32,
	parameter C_DEPTH = 32
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [C_WIDTH-1 : 0]	din,
	output	wire [C_WIDTH-1 : 0]	dout,
	input	wire	wr,
	input	wire	rd,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [C_WIDTH-1 : 0]	ram [C_DEPTH-1 : 0];
reg [XCLOCK_FFS-1 : 0]	wr_ptr;
reg [XCLOCK_FFS-1 : 0]	rd_ptr;
reg [XCLOCK_FFS-1 : 0]	count;

always @(posedge clk) begin
	if (!rst) begin
		wr_ptr <= {XCLOCK_FFS{1'b0}};
		rd_ptr <= {XCLOCK_FFS{1'b0}};
		count <= {XCLOCK_FFS{1'b0}};
	end else if (wr && !full) begin
		ram[wr_ptr] <= din;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
	end
end

always @(posedge clk) begin
	if (!rst) begin
		dout <= {C_WIDTH{1'b0}};
	end else if (rd && !empty) begin
		dout <= ram[rd_ptr];
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
	end
end

assign empty = (count == {XCLOCK_FFS{1'b0}});
assign full = (count == C_DEPTH);
assign almost_empty = (count == 1);
assign almost_full = (count == C_DEPTH - 1);

endmodule

module bfifo #(
	parameter C_WIDTH = 32,
	parameter C_DEPTH = 32
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [C_WIDTH-1 : 0]	din,
	output	wire [C_WIDTH-1 : 0]	dout,
	input	wire	wr,
	input	wire	rd,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [C_WIDTH-1 : 0]	ram [C_DEPTH-1 : 0];
reg [XCLOCK_FFS-1 : 0]	wr_ptr;
reg [XCLOCK_FFS-1 : 0]	rd_ptr;
reg [XCLOCK_FFS-1 : 0]	count;

always @(posedge clk) begin
	if (!rst) begin
		wr_ptr <= {XCLOCK_FFS{1'b0}};
		rd_ptr <= {XCLOCK_FFS{1'b0}};
		count <= {XCLOCK_FFS{1'b0}};
	end else if (wr && !full) begin
		ram[wr_ptr] <= din;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
	end
end

always @(posedge clk) begin
	if (!rst) begin
		dout <= {C_WIDTH{1'b0}};
	end else if (rd && !empty) begin
		dout <= ram[rd_ptr];
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
	end
end

assign empty = (count == {XCLOCK_FFS{1'b0}});
assign full = (count == C_DEPTH);
assign almost_empty = (count == 1);
assign almost_full = (count == C_DEPTH - 1);

endmodule

module rfifo #(
	parameter C_WIDTH = 32,
	parameter C_DEPTH = 32
) (
	input	wire	clk,
	input	wire	rst,
	input	wire [C_WIDTH-1 : 0]	din,
	output	wire [C_WIDTH-1 : 0]	dout,
	input	wire	wr,
	input	wire	rd,
	output	wire	empty,
	output	wire	full,
	output	wire	almost_empty,
	output	wire	almost_full
);

reg [C_WIDTH-1 : 0]	ram [C_DEPTH-1 : 0];
reg [XCLOCK_FFS-1 : 0]	wr_ptr;
reg [XCLOCK_FFS-1 : 0]	rd_ptr;
reg [XCLOCK_FFS-1 : 0]	count;

always @(posedge clk) begin
	if (!rst) begin
		wr_ptr <= {XCLOCK_FFS{1'b0}};
		rd_ptr <= {XCLOCK_FFS{1'b0}};
		count <= {XCLOCK_FFS{1'b0}};
	end else if (wr && !full) begin
		ram[wr_ptr] <= din;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
	end
end

always @(posedge clk) begin
	if (!rst) begin
		dout <= {C_WIDTH{1'b0}};
	end else if (rd && !empty) begin
		dout <= ram[rd_ptr];
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
	end
end

assign empty = (count == {XCLOCK_FFS{1'b0}});
assign full = (count == C_DEPTH);
assign almost_empty = (count == 1);
assign almost_full = (count == C_DEPTH - 1);

endmodule
