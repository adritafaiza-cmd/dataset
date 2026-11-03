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

reg [DW-1:0] wb_to_xclk_data;
reg wb_to_xclk_we;
reg [AW-1:0] wb_to_xclk_addr;
reg wb_to_xclk_stb;
reg wb_to_xclk_cyc;
reg wb_to_xclk_sel;
wire wb_to_xclk_stall;
wire wb_to_xclk_ack;
wire wb_to_xclk_err;

reg xclk_to_wb_data;
reg xclk_to_wb_we;
reg [AW-1:0] xclk_to_wb_addr;
reg xclk_to_wb_stb;
reg xclk_to_wb_cyc;
reg xclk_to_wb_sel;
wire xclk_to_wb_stall;
wire xclk_to_wb_ack;
wire xclk_to_wb_err;

wire wb_to_xclk_full;
wire wb_to_xclk_empty;

fifo #(
	.AW(AW),
	.DW(DW),
	.LGFIFO(LGFIFO)
) wb_to_xclk_fifo (
	.clk(i_wb_clk),
	.rst(i_reset),
	.din(i_wb_data),
	.wr_en(i_wb_cyc & i_wb_stb & ~i_wb_stall),
	.rd_en(i_xclk_ack),
	.dout(wb_to_xclk_data),
	.full(wb_to_xclk_full),
	.empty(wb_to_xclk_empty)
);

assign o_wb_stall = wb_to_xclk_full;

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_ack <= 0;
		o_wb_data <= 0;
		o_wb_err <= 0;
	end else begin
		if (wb_to_xclk_ack) begin
			o_wb_ack <= 1;
			o_wb_data <= wb_to_xclk_data;
			o_wb_err <= wb_to_xclk_err;
		end else begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end
	end
end

wb_to_xclk_bridge wb_to_xclk_bridge_inst (
	.wb_cyc(i_wb_cyc),
	.wb_stb(i_wb_stb),
	.wb_we(i_wb_we),
	.wb_addr(i_wb_addr),
	.wb_data(i_wb_data),
	.wb_sel(i_wb_sel),
	.xclk_cyc(o_xclk_cyc),
	.xclk_stb(o_xclk_stb),
	.xclk_we(o_xclk_we),
	.xclk_addr(o_xclk_addr),
	.xclk_data(o_xclk_data),
	.xclk_sel(o_xclk_sel)
);

xclk_to_wb_bridge xclk_to_wb_bridge_inst (
	.xclk_cyc(i_xclk_cyc),
	.xclk_stb(i_xclk_stb),
	.xclk_we(i_xclk_we),
	.xclk_addr(i_xclk_addr),
	.xclk_data(i_xclk_data),
	.xclk_sel(i_xclk_sel),
	.wb_cyc(wb_to_xclk_cyc),
	.wb_stb(wb_to_xclk_stb),
	.wb_we(wb_to_xclk_we),
	.wb_addr(wb_to_xclk_addr),
	.wb_data(wb_to_xclk_data),
	.wb_sel(wb_to_xclk_sel),
	.wb_ack(wb_to_xclk_ack),
	.wb_err(wb_to_xclk_err)
);

endmodule
