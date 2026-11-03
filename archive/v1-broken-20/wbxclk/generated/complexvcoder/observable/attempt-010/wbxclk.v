module wbxclk #(
	parameter AW = 32,
	parameter DW = 32,
	parameter LGFIFO = 5
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

// Internal signals for WB2X bridge
reg wb2x_cyc, wb2x_stb, wb2x_we, wb2x_ack, wb2x_err;
wire wb2x_data, wb2x_addr, wb2x_sel;

// Internal signals for X2WB bridge
reg x2wb_cyc, x2wb_stb, x2wb_we, x2wb_ack, x2wb_err;
wire x2wb_data, x2wb_addr, x2wb_sel;

// WB2X Bridge instance
wb2x wb2x_inst (
	.i_clk(i_wb_clk),
	.i_reset(i_reset),
	.i_cyc(i_wb_cyc),
	.i_stb(i_wb_stb),
	.i_we(i_wb_we),
	.i_addr(i_wb_addr),
	.i_data(i_wb_data),
	.i_sel(i_wb_sel),
	.o_stall(o_wb_stall),
	.o_ack(o_wb_ack),
	.o_data(o_wb_data),
	.o_err(o_wb_err),
	.o_cyc(o_xclk_cyc),
	.o_stb(o_xclk_stb),
	.o_we(o_xclk_we),
	.o_addr(o_xclk_addr),
	.o_data(o_xclk_data),
	.o_sel(o_xclk_sel),
	.i_stall(i_xclk_stall),
	.i_ack(i_xclk_ack),
	.i_data(i_xclk_data),
	.i_err(i_xclk_err)
);

// X2WB Bridge instance
x2wb x2wb_inst (
	.i_clk(i_xclk_clk),
	.i_reset(i_reset),
	.i_cyc(i_xclk_cyc),
	.i_stb(i_xclk_stb),
	.i_we(i_xclk_we),
	.i_addr(i_xclk_addr),
	.i_data(i_xclk_data),
	.i_sel(i_xclk_sel),
	.o_stall(o_xclk_stall),
	.o_ack(o_xclk_ack),
	.o_data(o_xclk_data),
	.o_err(o_xclk_err),
	.o_cyc(o_wb_cyc),
	.o_stb(o_wb_stb),
	.o_we(o_wb_we),
	.o_addr(o_wb_addr),
	.o_data(o_wb_data),
	.o_sel(o_wb_sel),
	.i_stall(i_wb_stall),
	.i_ack(i_wb_ack),
	.i_data(i_wb_data),
	.i_err(i_wb_err)
);

endmodule
