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

wire s_axi_aresetn_sync;
wire m_axi_aresetn_sync;

// Synchronize reset from S_AXI to M_AXI domain
sync_reset sync_reset_s2m (
	.clk_dest(M_AXI_ACLK),
	.rst_src(~S_AXI_ARESETN),
	.rst_dest(~m_axi_aresetn_sync)
);

// Synchronize reset from M_AXI to S_AXI domain
sync_reset sync_reset_m2s (
	.clk_dest(S_AXI_ACLK),
	.rst_src(~m_axi_aresetn_sync),
	.rst_dest(~s_axi_aresetn_sync)
);

assign M_AXI_ARESETN = m_axi_aresetn_sync;

// AW channel asynchronous FIFO
async_fifo #(
	.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.DEPTH(1<<LGFIFO)
) aw_fifo (
	.wr_clk(S_AXI_ACLK),
	.wr_rst(~s_axi_aresetn_sync),
	.wr_en(S_AXI_AWVALID & S_AXI_AWREADY),
	.din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
	.full(),
	.wr_data_count(),
	.rd_clk(M_AXI_ACLK),
	.rd_rst(~m_axi_aresetn_sync),
	.rd_en(M_AXI_AWREADY & M_AXI_AWVALID),
	.dout({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
	.empty(),
	.rd_data_count(),
	.valid(M_AXI_AWVALID),
	.rdy(M_AXI_AWREADY)
);

assign S_AXI_AWREADY = ~aw_fifo.full;

// W channel asynchronous FIFO
async_fifo #(
	.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1),
	.DEPTH(1<<LGFIFO)
) w_fifo (
	.wr_clk(S_AXI_ACLK),
	.wr_rst(~s_axi_aresetn_sync),
	.wr_en(S_AXI_WVALID & S_AXI_WREADY),
	.din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}),
	.full(),
	.wr_data_count(),
	.rd_clk(M_AXI_ACLK),
	.rd_rst(~m_axi_aresetn_sync),
	.rd_en(M_AXI_WREADY & M_AXI_WVALID),
	.dout({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}),
	.empty(),
	.rd_data_count(),
	.valid(M_AXI_WVALID),
	.rdy(M_AXI_WREADY)
);

assign S_AXI_WREADY = ~w_fifo.full;

// B channel asynchronous FIFO
async_fifo #(
	.WIDTH(C_S_AXI_ID_WIDTH + 2),
	.DEPTH(1<<LGFIFO)
) b_fifo (
	.wr_clk(M_AXI_ACLK),
	.wr_rst(~m_axi_aresetn_sync),
	.wr_en(M_AXI_BVALID & M_AXI_BREADY),
	.din({M_AXI_BID, M_AXI_BRESP}),
	.full(),
	.wr_data_count(),
	.rd_clk(S_AXI_ACLK),
	.rd_rst(~s_axi_aresetn_sync),
	.rd_en(S_AXI_BREADY & S_AXI_BVALID),
	.dout({S_AXI_BID, S_AXI_BRESP}),
	.empty(),
	.rd_data_count(),
	.valid(S_AXI_BVALID),
	.rdy(S_AXI_BREADY)
);

assign M_AXI_BREADY = ~b_fifo.full;

// AR channel asynchronous FIFO
async_fifo #(
	.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
	.DEPTH(1<<LGFIFO)
) ar_fifo (
	.wr_clk(S_AXI_ACLK),
	.wr_rst(~s_axi_aresetn_sync),
	.wr_en(S_AXI_ARVALID & S_AXI_ARREADY),
	.din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
	.full(),
	.wr_data_count(),
	.rd_clk(M_AXI_ACLK),
	.rd_rst(~m_axi_aresetn_sync),
	.rd_en(M_AXI_ARREADY & M_AXI_ARVALID),
	.dout({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS}),
	.empty(),
	.rd_data_count(),
	.valid(M_AXI_ARVALID),
	.rdy(M_AXI_ARREADY)
);

assign S_AXI_ARREADY = ~ar_fifo.full;

// R channel asynchronous FIFO
async_fifo #(
	.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1),
	.DEPTH(1<<LGFIFO)
) r_fifo (
	.wr_clk(M_AXI_ACLK),
	.wr_rst(~m_axi_aresetn_sync),
	.wr_en(M_AXI_RVALID & M_AXI_RREADY),
	.din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
	.full(),
	.wr_data_count(),
	.rd_clk(S_AXI_ACLK),
	.rd_rst(~s_axi_aresetn_sync),
	.rd_en(S_AXI_RREADY & S_AXI_RVALID),
	.dout({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}),
	.empty(),
	.rd_data_count(),
	.valid(S_AXI_RVALID),
	.rdy(S_AXI_RREADY)
);

assign M_AXI_RREADY = ~r_fifo.full;

endmodule

module sync_reset (
	input wire clk_dest,
	input wire rst_src,
	output reg rst_dest
);

reg [XCLOCK_FFS-1:0] sync_chain;

always @(posedge clk_dest) begin
	sync_chain <= {sync_chain[XCLOCK_FFS-2:0], rst_src};
end

always @(posedge clk_dest) begin
	rst_dest <= sync_chain[XCLOCK_FFS-1];
end

endmodule

module async_fifo #(
	parameter WIDTH = 32,
	parameter DEPTH = 32
)(
	input wire wr_clk,
	input wire wr_rst,
	input wire wr_en,
	input wire [WIDTH-1:0] din,
	output reg full,
	output reg [15:0] wr_data_count,
	input wire rd_clk,
	input wire rd_rst,
	input wire rd_en,
	output reg [WIDTH-1:0] dout,
	output reg empty,
	output reg [15:0] rd_data_count,
	output reg valid,
	output reg rdy
);

reg [WIDTH-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;

wire [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

gray_counter #(.WIDTH($clog2(DEPTH)+1)) wr_gray_counter (
	.clk(wr_clk),
	.rst(wr_rst),
	.en(wr_en),
	.gray(wr_ptr_gray),
	.bin(wr_ptr)
);

gray_counter #(.WIDTH($clog2(DEPTH)+1)) rd_gray_counter (
	.clk(rd_clk),
	.rst(rd_rst),
	.en(rd_en),
	.gray(rd_ptr_gray),
	.bin(rd_ptr)
);

sync_gray_counter sync_wr_ptr (
	.clk_dest(rd_clk),
	.rst_dest(rd_rst),
	.gray_src(wr_ptr_gray),
	.gray_dest(wr_ptr_gray_sync)
);

sync_gray_counter sync_rd_ptr (
	.clk_dest(wr_clk),
	.rst_dest(wr_rst),
	.gray_src(rd_ptr_gray),
	.gray_dest(rd_ptr_gray_sync)
);

always @(posedge wr_clk or posedge wr_rst) begin
	if (wr_rst) begin
		full <= 1'b0;
		wr_data_count <= 16'b0;
	end else if (wr_en & ~full) begin
		mem[wr_ptr] <= din;
		wr_data_count <= wr_data_count + 1;
		if (wr_ptr_gray_sync == {rd_ptr_gray[$clog2(DEPTH)], ~rd_ptr_gray[$clog2(DEPTH)-1:0]})
			full <= 1'b1;
	end
end

always @(posedge rd_clk or posedge rd_rst) begin
	if (rd_rst) begin
		empty <= 1'b1;
		rd_data_count <= 16'b0;
	end else if (rd_en & ~empty) begin
		dout <= mem[rd_ptr];
		rd_data_count <= rd_data_count - 1;
		if (rd_ptr_gray_sync == {wr_ptr_gray[$clog2(DEPTH)], ~wr_ptr_gray[$clog2(DEPTH)-1:0]})
			empty <= 1'b1;
	end
end

assign valid = ~empty;
assign rdy = ~full;

endmodule

module gray_counter #(
	parameter WIDTH = 4
)(
	input wire clk,
	input wire rst,
	input wire en,
	output reg [WIDTH-1:0] gray,
	output reg [WIDTH-1:0] bin
);

always @(posedge clk or posedge rst) begin
	if (rst) begin
		gray <= {WIDTH{1'b0}};
		bin <= {WIDTH{1'b0}};
	end else if (en) begin
		gray <= bin ^ (bin >> 1);
		bin <= bin + 1;
	end
end

endmodule

module sync_gray_counter (
	input wire clk_dest,
	input wire rst_dest,
	input wire [WIDTH-1:0] gray_src,
	output reg [WIDTH-1:0] gray_dest
);

reg [WIDTH-1:0] sync_chain [0:1];

always @(posedge clk_dest or posedge rst_dest) begin
	if (rst_dest) begin
		sync_chain[0] <= {WIDTH{1'b0}};
		sync_chain[1] <= {WIDTH{1'b0}};
		gray_dest <= {WIDTH{1'b0}};
	end else begin
		sync_chain[0] <= gray_src;
		sync_chain[1] <= sync_chain[0];
		gray_dest <= sync_chain[1];
	end
end

endmodule
