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

	// Internal signals
	wire wb_fifo_stall, wb_fifo_ack, wb_fifo_err;

	// Instantiate the FIFO
	wishbone_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_fifo (
		.wb_clk(i_wb_clk),
		.wb_reset(i_reset),
		.wb_cyc(i_wb_cyc),
		.wb_stb(i_wb_stb),
		.wb_we(i_wb_we),
		.wb_addr(i_wb_addr),
		.wb_data(i_wb_data),
		.wb_sel(i_wb_sel),
		.wb_stall(wb_fifo_stall),
		.wb_ack(wb_fifo_ack),
		.wb_err(wb_fifo_err),
		.o_wb_cyc(wb_fifo.o_wb_cyc),
		.o_wb_stb(wb_fifo.o_wb_stb),
		.o_wb_we(wb_fifo.o_wb_we),
		.o_wb_addr(wb_fifo.o_wb_addr),
		.o_wb_data(wb_fifo.o_wb_data),
		.o_wb_sel(wb_fifo.o_wb_sel)
	);

	// Instantiate the clock-domain crossing
	xclk_crossing #(
		.AW(AW),
		.DW(DW)
	) xclk_crossing (
		.xclk_clk(i_xclk_clk),
		.xclk_stall(i_xclk_stall),
		.xclk_ack(i_xclk_ack),
		.xclk_data(i_xclk_data),
		.xclk_err(i_xclk_err),
		.o_xclk_cyc(xclk_crossing.o_xclk_cyc),
		.o_xclk_stb(xclk_crossing.o_xclk_stb),
		.o_xclk_we(xclk_crossing.o_xclk_we),
		.o_xclk_addr(xclk_crossing.o_xclk_addr),
		.o_xclk_data(xclk_crossing.o_xclk_data),
		.o_xclk_sel(xclk_crossing.o_xclk_sel)
	);

	// Connect the FIFO to the crossing
	assign o_xclk_cyc = wb_fifo.o_wb_cyc;
	assign o_xclk_stb = wb_fifo.o_wb_stb;
	assign o_xclk_we = wb_fifo.o_wb_we;
	assign o_xclk_addr = wb_fifo.o_wb_addr;
	assign o_xclk_data = wb_fifo.o_wb_data;
	assign o_xclk_sel = wb_fifo.o_wb_sel;

	// Connect the crossing to the FIFO
	assign wb_fifo.i_wb_cyc = xclk_crossing.o_xclk_cyc;
	assign wb_fifo.i_wb_stb = xclk_crossing.o_xclk_stb;
	assign wb_fifo.i_wb_we = xclk_crossing.o_xclk_we;
	assign wb_fifo.i_wb_addr = xclk_crossing.o_xclk_addr;
	assign wb_fifo.i_wb_data = xclk_crossing.o_xclk_data;
	assign wb_fifo.i_wb_sel = xclk_crossing.o_xclk_sel;
	assign o_wb_stall = wb_fifo_stall;
	assign o_wb_ack = wb_fifo_ack;
	assign o_wb_data = wb_fifo.o_wb_data;
	assign o_wb_err = wb_fifo_err;

endmodule
