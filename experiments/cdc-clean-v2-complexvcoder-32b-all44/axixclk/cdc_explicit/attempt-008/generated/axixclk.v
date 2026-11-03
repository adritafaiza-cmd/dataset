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

reg [XCLOCK_FFS-1:0] s_reset_sync;
reg [XCLOCK_FFS-1:0] m_reset_sync;

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN)
		s_reset_sync <= {XCLOCK_FFS{1'b1}};
	else
		s_reset_sync <= {s_reset_sync[XCLOCK_FFS-2:0], 1'b0};
end

always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN)
		m_reset_sync <= {XCLOCK_FFS{1'b1}};
	else
		m_reset_sync <= {m_reset_sync[XCLOCK_FFS-2:0], 1'b0};
end

assign M_AXI_ARESETN = s_reset_sync[XCLOCK_FFS-1];

cdc_fifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.C_LOG2DEPTH(LGFIFO)
) aw_cdc_fifo (
	.clk_wr(S_AXI_ACLK),
	.clk_rd(M_AXI_ACLK),
	.rst_n(M_AXI_ARESETN),
	.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
	.rd_en(M_AXI_AWREADY & M_AXI_AWVALID),
	.wr_data({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
	.rd_data({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
	.full(),
	.empty(~M_AXI_AWVALID),
	.almost_full(),
	.almost_empty(M_AXI_AWREADY)
);

cdc_fifo #(
	.C_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
	.C_LOG2DEPTH(LGFIFO)
) w_cdc_fifo (
	.clk_wr(S_AXI_ACLK),
	.clk_rd(M_AXI_ACLK),
	.rst_n(M_AXI_ARESETN),
	.wr_en(S_AXI_WVALID & S_AXI_WREADY),
	.rd_en(M_AXI_WREADY & M_AXI_WVALID),
	.wr_data({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
	.rd_data({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
	.full(),
	.empty(~M_AXI_WVALID),
	.almost_full(),
	.almost_empty(M_AXI_WREADY)
);

cdc_fifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + 2),
	.C_LOG2DEPTH(LGFIFO)
) b_cdc_fifo (
	.clk_wr(M_AXI_ACLK),
	.clk_rd(S_AXI_ACLK),
	.rst_n(S_AXI_ARESETN),
	.wr_en(M_AXI_BVALID & M_AXI_BREADY),
	.rd_en(S_AXI_BREADY & S_AXI_BVALID),
	.wr_data({M_AXI_BID, M_AXI_BRESP}),
	.rd_data({S_AXI_BID, S_AXI_BRESP}),
	.full(),
	.empty(~S_AXI_BVALID),
	.almost_full(),
	.almost_empty(S_AXI_BREADY)
);

cdc_fifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.C_LOG2DEPTH(LGFIFO)
) ar_cdc_fifo (
	.clk_wr(S_AXI_ACLK),
	.clk_rd(M_AXI_ACLK),
	.rst_n(M_AXI_ARESETN),
	.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
	.rd_en(M_AXI_ARREADY & M_AXI_ARVALID),
	.wr_data({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
	.rd_data({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
	.full(),
	.empty(~M_AXI_ARVALID),
	.almost_full(),
	.almost_empty(M_AXI_ARREADY)
);

cdc_fifo #(
	.C_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
	.C_LOG2DEPTH(LGFIFO)
) r_cdc_fifo (
	.clk_wr(M_AXI_ACLK),
	.clk_rd(S_AXI_ACLK),
	.rst_n(S_AXI_ARESETN),
	.wr_en(M_AXI_RVALID & M_AXI_RREADY),
	.rd_en(S_AXI_RREADY & S_AXI_RVALID),
	.wr_data({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
	.rd_data({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
	.full(),
	.empty(~S_AXI_RVALID),
	.almost_full(),
	.almost_empty(S_AXI_RREADY)
);

assign S_AXI_AWREADY = ~aw_cdc_fifo.full;
assign S_AXI_WREADY = ~w_cdc_fifo.full;
assign S_AXI_BVALID = ~b_cdc_fifo.empty;
assign S_AXI_ARREADY = ~ar_cdc_fifo.full;
assign S_AXI_RVALID = ~r_cdc_fifo.empty;
assign M_AXI_AWVALID = ~aw_cdc_fifo.empty;
assign M_AXI_WVALID = ~w_cdc_fifo.empty;
assign M_AXI_BREADY = ~b_cdc_fifo.full;
assign M_AXI_ARVALID = ~ar_cdc_fifo.empty;
assign M_AXI_RREADY = ~r_cdc_fifo.full;

endmodule

module cdc_fifo #(
	parameter integer C_WIDTH = 32,
	parameter integer C_LOG2DEPTH = 4
) (
	input wire clk_wr,
	input wire clk_rd,
	input wire rst_n,
	input wire wr_en,
	input wire rd_en,
	input wire [C_WIDTH-1:0] wr_data,
	output reg [C_WIDTH-1:0] rd_data,
	output reg full,
	output reg empty,
	output reg almost_full,
	output reg almost_empty
);

localparam DEPTH = 1 << C_LOG2DEPTH;
localparam AWIDTH = C_LOG2DEPTH;

reg [C_WIDTH-1:0] mem [0:DEPTH-1];
reg [AWIDTH-1:0] wr_ptr, rd_ptr;
reg [AWIDTH:0] wr_cnt, rd_cnt;

always @(posedge clk_wr or negedge rst_n) begin
	if (!rst_n) begin
		wr_ptr <= 0;
		wr_cnt <= 0;
	end else if (wr_en && !full) begin
		mem[wr_ptr] <= wr_data;
		wr_ptr <= wr_ptr + 1;
		wr_cnt <= wr_cnt + 1;
	end
end

always @(posedge clk_rd or negedge rst_n) begin
	if (!rst_n) begin
		rd_ptr <= 0;
		rd_cnt <= 0;
	end else if (rd_en && !empty) begin
		rd_ptr <= rd_ptr + 1;
		rd_cnt <= rd_cnt + 1;
	end
end

always @(posedge clk_wr or negedge rst_n) begin
	if (!rst_n) begin
		full <= 0;
		almost_full <= 0;
	end else begin
		full <= (wr_cnt == DEPTH);
		almost_full <= (wr_cnt == DEPTH - 1);
	end
end

always @(posedge clk_rd or negedge rst_n) begin
	if (!rst_n) begin
		empty <= 1;
		almost_empty <= 1;
	end else begin
		empty <= (rd_cnt == wr_cnt);
		almost_empty <= (rd_cnt == wr_cnt + 1);
	end
end

always @(posedge clk_rd or negedge rst_n) begin
	if (!rst_n)
		rd_data <= 0;
	else if (rd_en && !empty)
		rd_data <= mem[rd_ptr];
end

endmodule
