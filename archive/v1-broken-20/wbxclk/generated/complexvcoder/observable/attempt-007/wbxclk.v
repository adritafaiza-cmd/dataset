module wbxclk #(
	parameter AW = 32,
				DW = 32,
				LGFIFO = 5
) (
		input wire i_wb_clk, i_reset,
		input wire i_wb_cyc, i_wb_stb, i_wb_we,
		input wire [(AW-1):0] i_wb_addr,
		input wire [(DW-1):0] i_wb_data,
		input wire [(DW/8-1):0] i_wb_sel,
		output wire o_wb_stall,
		output reg o_wb_ack,
		output reg [(DW-1):0] o_wb_data,
		output reg o_wb_err,
		input wire i_xclk_clk,
		output reg o_xclk_cyc,
		output reg o_xclk_stb,
		output reg o_xclk_we,
		output reg [(AW-1):0] o_xclk_addr,
		output reg [(DW-1):0] o_xclk_data,
		output reg [(DW/8-1):0] o_xclk_sel,
		input wire i_xclk_stall,
		input wire i_xclk_ack,
		input wire [(DW-1):0] i_xclk_data,
		input wire i_xclk_err
);

// Internal signals for pipelining and cross-clock domain communication
reg wb_cyc, wb_stb, wb_we;
reg [(AW-1):0] wb_addr;
reg [(DW-1):0] wb_data;
reg [(DW/8-1):0] wb_sel;
wire wb_ack, wb_err;

reg xclk_cyc, xclk_stb, xclk_we;
reg [(AW-1):0] xclk_addr;
reg [(DW-1):0] xclk_data;
reg [(DW/8-1):0] xclk_sel;
wire xclk_stall;

// Instantiate Wishbone bridge
wire wb_bridge_o_xclk_cyc, wb_bridge_o_xclk_stb, wb_bridge_o_xclk_we;
wire [(AW-1):0] wb_bridge_o_xclk_addr;
wire [(DW-1):0] wb_bridge_o_xclk_data;
wire [(DW/8-1):0] wb_bridge_o_xclk_sel;
wire wb_bridge_o_wb_stall, wb_bridge_o_wb_ack, wb_bridge_o_wb_err;

wishbone_bridge #(
	.AW(AW),
	.DW(DW),
	.LGFIFO(LGFIFO)
) wb_bridge (
	.i_wb_clk(i_wb_clk),
	.i_reset(i_reset),
	.i_wb_cyc(wb_cyc),
	.i_wb_stb(wb_stb),
	.i_wb_we(wb_we),
	.i_wb_addr(wb_addr),
	.i_wb_data(wb_data),
	.i_wb_sel(wb_sel),
	.o_wb_stall(wb_bridge_o_wb_stall),
	.o_wb_ack(wb_bridge_o_wb_ack),
	.o_wb_data(wb_bridge_o_wb_data),
	.o_wb_err(wb_bridge_o_wb_err),
	.o_xclk_cyc(wb_bridge_o_xclk_cyc),
	.o_xclk_stb(wb_bridge_o_xclk_stb),
	.o_xclk_we(wb_bridge_o_xclk_we),
	.o_xclk_addr(wb_bridge_o_xclk_addr),
	.o_xclk_data(wb_bridge_o_xclk_data),
	.o_xclk_sel(wb_bridge_o_xclk_sel),
	.i_xclk_stall(wb_bridge_i_xclk_stall),
	.i_xclk_ack(wb_bridge_i_xclk_ack),
	.i_xclk_data(wb_bridge_i_xclk_data),
	.i_xclk_err(wb_bridge_i_xclk_err)
);

// Instantiate cross-clock domain bridge
wire xclk_bridge_o_wb_cyc, xclk_bridge_o_wb_stb, xclk_bridge_o_wb_we;
wire [(AW-1):0] xclk_bridge_o_wb_addr;
wire [(DW-1):0] xclk_bridge_o_wb_data;
wire [(DW/8-1):0] xclk_bridge_o_wb_sel;
wire xclk_bridge_o_wb_stall, xclk_bridge_o_wb_ack, xclk_bridge_o_wb_err;

xclk_bridge #(
	.AW(AW),
	.DW(DW),
	.LGFIFO(LGFIFO)
) xclk_bridge (
	.i_xclk_clk(i_xclk_clk),
	.i_xclk_stall(i_xclk_stall),
	.i_xclk_ack(i_xclk_ack),
	.i_xclk_data(i_xclk_data),
	.i_xclk_err(i_xclk_err),
	.o_wb_cyc(xclk_bridge_o_wb_cyc),
	.o_wb_stb(xclk_bridge_o_wb_stb),
	.o_wb_we(xclk_bridge_o_wb_we),
	.o_wb_addr(xclk_bridge_o_wb_addr),
	.o_wb_data(xclk_bridge_o_wb_data),
	.o_wb_sel(xclk_bridge_o_wb_sel),
	.o_wb_stall(xclk_bridge_o_wb_stall),
	.o_wb_ack(xclk_bridge_o_wb_ack),
	.o_wb_err(xclk_bridge_o_wb_err)
);

// Clock domain crossing for Wishbone signals
always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_cyc <= 0;
	else
		wb_cyc <= i_wb_cyc;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_stb <= 0;
	else
		wb_stb <= i_wb_stb;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_we <= 0;
	else
		wb_we <= i_wb_we;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_addr <= 0;
	else
		wb_addr <= i_wb_addr;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_data <= 0;
	else
		wb_data <= i_wb_data;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_sel <= 0;
	else
		wb_sel <= i_wb_sel;
end

// Clock domain crossing for Wishbone response signals
always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_ack <= 0;
	else
		o_wb_ack <= wb_bridge_o_wb_ack;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_data <= 0;
	else
		o_wb_data <= wb_bridge_o_wb_data;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_err <= 0;
	else
		o_wb_err <= wb_bridge_o_wb_err;
end

// Clock domain crossing for cross-clock domain signals
always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_cyc <= 0;
	else
		o_xclk_cyc <= xclk_bridge_o_wb_cyc;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_stb <= 0;
	else
		o_xclk_stb <= xclk_bridge_o_wb_stb;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_we <= 0;
	else
		o_xclk_we <= xclk_bridge_o_wb_we;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_addr <= 0;
	else
		o_xclk_addr <= xclk_bridge_o_wb_addr;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_data <= 0;
	else
		o_xclk_data <= xclk_bridge_o_wb_data;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_xclk_sel <= 0;
	else
		o_xclk_sel <= xclk_bridge_o_wb_sel;
end

// Clock domain crossing for cross-clock domain response signals
always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_bridge_i_xclk_stall <= 0;
	else
		wb_bridge_i_xclk_stall <= xclk_bridge_o_wb_stall;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_bridge_i_xclk_ack <= 0;
	else
		wb_bridge_i_xclk_ack <= xclk_bridge_o_wb_ack;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_bridge_i_xclk_data <= 0;
	else
		wb_bridge_i_xclk_data <= xclk_bridge_o_wb_data;
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset)
		wb_bridge_i_xclk_err <= 0;
	else
		wb_bridge_i_xclk_err <= xclk_bridge_o_wb_err;
end

// Output stall signal
assign o_wb_stall = wb_bridge_o_wb_stall;

endmodule

module wishbone_bridge #(
	parameter AW = 32,
				DW = 32,
				LGFIFO = 5
) (
	.input wire i_wb_clk, i_reset,
	.input wire i_wb_cyc, i_wb_stb, i_wb_we,
	.input wire [(AW-1):0] i_wb_addr,
	.input wire [(DW-1):0] i_wb_data,
	.input wire [(DW/8-1):0] i_wb_sel,
	.output wire o_wb_stall,
	.output wire o_wb_ack,
	.output wire [(DW-1):0] o_wb_data,
	.output wire o_wb_err,
	.output wire o_xclk_cyc,
	.output wire o_xclk_stb,
	.output wire o_xclk_we,
	.output wire [(AW-1):0] o_xclk_addr,
	.output wire [(DW-1):0] o_xclk_data,
	.output wire [(DW/8-1):0] o_xclk_sel,
	.input wire i_xclk_stall,
	.input wire i_xclk_ack,
	.input wire [(DW-1):0] i_xclk_data,
	.input wire i_xclk_err
);

// Internal signals
reg wb_cyc, wb_stb, wb_we;
reg [(AW-1):0] wb_addr;
reg [(DW-1):0] wb_data;
reg [(DW/8-1):0] wb_sel;
wire wb_ack, wb_err;

reg xclk_cyc, xclk_stb, xclk_we;
reg [(AW-1):0] xclk_addr;
reg [(DW-1):0] xclk_data;
reg [(DW/8-1):0] xclk_sel;
wire xclk_stall;

// Instantiate FIFO for pipelining
fifo #(
	.AW(AW),
	.DW(DW),
	.LGFIFO(LGFIFO)
) wb_fifo (
	.clk(i_wb_clk),
	.reset(i_reset),
	.wren(i_wb_cyc & i_wb_stb & ~wb_stall),
	.din({i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
	.full(wb_stall),
	.q(wb_fifo_out)
);

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_cyc <= 0;
	else
		xclk_cyc <= i_xclk_cyc;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_stb <= 0;
	else
		xclk_stb <= i_xclk_stb;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_we <= 0;
	else
		xclk_we <= i_xclk_we;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_addr <= 0;
	else
		xclk_addr <= i_xclk_addr;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_data <= 0;
	else
		xclk_data <= i_xclk_data;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		xclk_sel <= 0;
	else
		xclk_sel <= i_xclk_sel;
end

// Output stall signal
assign o_wb_stall = wb_stall;

endmodule

module xclk_bridge #(
	.parameter AW = 32,
				DW = 32,
				LGFIFO = 5
) (
	.input wire i_xclk_clk,
	.input wire i_xclk_stall,
	.input wire i_xclk_ack,
	.input wire [(DW-1):0] i_xclk_data,
	.input wire i_xclk_err,
	.output wire o_wb_cyc,
	.output wire o_wb_stb,
	.output wire o_wb_we,
	.output wire [(AW-1):0] o_wb_addr,
	.output wire [(DW-1):0] o_wb_data,
	.output wire [(DW/8-1):0] o_wb_sel,
	.output wire o_wb_stall,
	.output wire o_wb_ack,
	.output wire o_wb_err
);

// Internal signals
reg wb_cyc, wb_stb, wb_we;
reg [(AW-1):0] wb_addr;
reg [(DW-1):0] wb_data;
reg [(DW/8-1):0] wb_sel;
wire wb_ack, wb_err;

reg xclk_cyc, xclk_stb, xclk_we;
reg [(AW-1):0] xclk_addr;
reg [(DW-1):0] xclk_data;
reg [(DW/8-1):0] xclk_sel;
wire xclk_stall;

// Instantiate FIFO for pipelining
fifo #(
	.AW(AW),
	.DW(DW),
	.LGFIFO(LGFIFO)
) xclk_fifo (
	.clk(i_xclk_clk),
	.reset(0),
	.wren(i_xclk_cyc & i_xclk_stb & ~xclk_stall),
	.din({i_xclk_we, i_xclk_addr, i_xclk_data, i_xclk_sel}),
	.full(xclk_stall),
	.q(xclk_fifo_out)
);

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_cyc <= 0;
	else
		o_wb_cyc <= xclk_cyc;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_stb <= 0;
	else
		o_wb_stb <= xclk_stb;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_we <= 0;
	else
		o_wb_we <= xclk_we;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_addr <= 0;
	else
		o_wb_addr <= xclk_addr;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_data <= 0;
	else
		o_wb_data <= xclk_data;
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset)
		o_wb_sel <= 0;
	else
		o_wb_sel <= xclk_sel;
end

// Output stall signal
assign o_wb_stall = xclk_stall;

endmodule

module fifo #(
	.parameter AW = 32,
				DW = 32,
				LGFIFO = 5
) (
	.input wire clk,
	.input wire reset,
	.input wire wren,
	.input wire [(DW-1):0] din,
	.output wire full,
	.output wire [(DW-1):0] q
);

// Internal signals
reg [(DW-1):0] mem [0:(2**LGFIFO)-1];
reg [(LGFIFO-1):0] wr_ptr, rd_ptr;
reg full_flag;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		wr_ptr <= 0;
		rd_ptr <= 0;
		full_flag <= 0;
	end else begin
		if (wren && !full_flag) begin
			mem[wr_ptr] <= din;
			wr_ptr <= wr_ptr + 1;
			full_flag <= (wr_ptr == rd_ptr);
		end else if (full_flag) begin
			full_flag <= 0;
		end
	end
end

assign full = full_flag;
assign q = mem[rd_ptr];

always @(posedge clk) begin
	if (!full_flag)
		rd_ptr <= rd_ptr + 1;
end

endmodule
