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

reg [XCLOCK_FFS-1:0] s_axi_reset_reg;
reg [XCLOCK_FFS-1:0] m_axi_reset_reg;
assign M_AXI_ARESETN = m_axi_reset_reg[XCLOCK_FFS-1];

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		s_axi_reset_reg <= {XCLOCK_FFS{1'b0}};
	end else begin
		s_axi_reset_reg <= {s_axi_reset_reg[XCLOCK_FFS-2:0], 1'b1};
	end
end

always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
	if (!S_AXI_ARESETN) begin
		m_axi_reset_reg <= {XCLOCK_FFS{1'b0}};
	end else begin
		m_axi_reset_reg <= {m_axi_reset_reg[XCLOCK_FFS-2:0], 1'b1};
	end
end

wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] aw_data_in;
wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] aw_data_out;
wire aw_valid_in, aw_valid_out, aw_ready_out;

assign aw_data_in = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
assign S_AXI_AWREADY = aw_ready_out;
assign aw_valid_in = S_AXI_AWVALID;
assign {M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS} = aw_data_out;
assign M_AXI_AWVALID = aw_valid_out;

crossover_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18), .DEPTH(LGFIFO))
aw_crossover (
	.clk_in(S_AXI_ACLK),
	.rst_in(!S_AXI_ARESETN),
	.data_in(aw_data_in),
	.valid_in(aw_valid_in),
	.ready_out(aw_ready_out),
	.clk_out(M_AXI_ACLK),
	.rst_out(!M_AXI_ARESETN),
	.data_out(aw_data_out),
	.valid_out(aw_valid_out),
	.ready_in(M_AXI_AWREADY)
);

wire [C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 2:0] w_data_in;
wire [C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 2:0] w_data_out;
wire w_valid_in, w_valid_out, w_ready_out;

assign w_data_in = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
assign S_AXI_WREADY = w_ready_out;
assign w_valid_in = S_AXI_WVALID;
assign {M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST} = w_data_out;
assign M_AXI_WVALID = w_valid_out;

crossover_fifo #(.WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 2), .DEPTH(LGFIFO))
w_crossover (
	.clk_in(S_AXI_ACLK),
	.rst_in(!S_AXI_ARESETN),
	.data_in(w_data_in),
	.valid_in(w_valid_in),
	.ready_out(w_ready_out),
	.clk_out(M_AXI_ACLK),
	.rst_out(!M_AXI_ARESETN),
	.data_out(w_data_out),
	.valid_out(w_valid_out),
	.ready_in(M_AXI_WREADY)
);

wire [C_S_AXI_ID_WIDTH + 1:0] b_data_in;
wire [C_S_AXI_ID_WIDTH + 1:0] b_data_out;
wire b_valid_in, b_valid_out, b_ready_out;

assign b_data_in = {M_AXI_BID, M_AXI_BRESP};
assign M_AXI_BREADY = b_ready_out;
assign b_valid_in = M_AXI_BVALID;
assign {S_AXI_BID, S_AXI_BRESP} = b_data_out;
assign S_AXI_BVALID = b_valid_out;

crossover_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + 1), .DEPTH(LGFIFO))
b_crossover (
	.clk_in(M_AXI_ACLK),
	.rst_in(!M_AXI_ARESETN),
	.data_in(b_data_in),
	.valid_in(b_valid_in),
	.ready_out(b_ready_out),
	.clk_out(S_AXI_ACLK),
	.rst_out(!S_AXI_ARESETN),
	.data_out(b_data_out),
	.valid_out(b_valid_out),
	.ready_in(S_AXI_BREADY)
);

wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] ar_data_in;
wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18:0] ar_data_out;
wire ar_valid_in, ar_valid_out, ar_ready_out;

assign ar_data_in = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
assign S_AXI_ARREADY = ar_ready_out;
assign ar_valid_in = S_AXI_ARVALID;
assign {M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS} = ar_data_out;
assign M_AXI_ARVALID = ar_valid_out;

crossover_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 18), .DEPTH(LGFIFO))
ar_crossover (
	.clk_in(S_AXI_ACLK),
	.rst_in(!S_AXI_ARESETN),
	.data_in(ar_data_in),
	.valid_in(ar_valid_in),
	.ready_out(ar_ready_out),
	.clk_out(M_AXI_ACLK),
	.rst_out(!M_AXI_ARESETN),
	.data_out(ar_data_out),
	.valid_out(ar_valid_out),
	.ready_in(M_AXI_ARREADY)
);

wire [C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2:0] r_data_in;
wire [C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2:0] r_data_out;
wire r_valid_in, r_valid_out, r_ready_out;

assign r_data_in = {M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST};
assign M_AXI_RREADY = r_ready_out;
assign r_valid_in = M_AXI_RVALID;
assign {S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST} = r_data_out;
assign S_AXI_RVALID = r_valid_out;

crossover_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2), .DEPTH(LGFIFO))
r_crossover (
	.clk_in(M_AXI_ACLK),
	.rst_in(!M_AXI_ARESETN),
	.data_in(r_data_in),
	.valid_in(r_valid_in),
	.ready_out(r_ready_out),
	.clk_out(S_AXI_ACLK),
	.rst_out(!S_AXI_ARESETN),
	.data_out(r_data_out),
	.valid_out(r_valid_out),
	.ready_in(S_AXI_RREADY)
);

endmodule

module crossover_fifo #(
	parameter WIDTH = 32,
	parameter DEPTH = 16
) (
	input wire clk_in,
	input wire rst_in,
	input wire [WIDTH-1:0] data_in,
	input wire valid_in,
	output reg ready_out,
	input wire clk_out,
	input wire rst_out,
	output reg [WIDTH-1:0] data_out,
	output reg valid_out,
	input wire ready_in
);

reg [WIDTH-1:0] fifo [0:DEPTH-1];
reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
reg [$clog2(DEPTH):0] count;

always @(posedge clk_in or negedge rst_in) begin
	if (!rst_in) begin
		wr_ptr <= 0;
		count <= 0;
		ready_out <= 1;
	end else if (valid_in && ready_out) begin
		fifo[wr_ptr] <= data_in;
		wr_ptr <= wr_ptr + 1;
		count <= count + 1;
		ready_out <= (count != DEPTH);
	end
end

always @(posedge clk_out or negedge rst_out) begin
	if (!rst_out) begin
		rd_ptr <= 0;
		data_out <= 0;
		valid_out <= 0;
	end else if (valid_out && ready_in) begin
		rd_ptr <= rd_ptr + 1;
		count <= count - 1;
		valid_out <= (count != 0);
	end else if (!valid_out && count != 0) begin
		data_out <= fifo[rd_ptr];
		valid_out <= 1;
	end
end

endmodule
