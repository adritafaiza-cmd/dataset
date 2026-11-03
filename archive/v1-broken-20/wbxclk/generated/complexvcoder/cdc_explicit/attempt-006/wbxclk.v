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

	// FIFO instances
	wire wb_to_xclk_fifo_valid, wb_to_xclk_fifo_ready;
	wire xclk_to_wb_fifo_valid, xclk_to_wb_fifo_ready;

	fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.in_valid(i_wb_cyc && i_wb_stb),
		.in_addr(i_wb_addr),
		.in_data(i_wb_data),
		.in_sel(i_wb_sel),
		.in_ready(wb_to_xclk_fifo_ready),
		.out_valid(wb_to_xclk_fifo_valid),
		.out_addr(o_xclk_addr),
		.out_data(o_xclk_data),
		.out_sel(o_xclk_sel),
		.out_ready(i_xclk_ack),
		.rst(i_reset)
	);

	fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.in_valid(i_xclk_cyc && i_xclk_stb),
		.in_addr(i_xclk_addr),
		.in_data(i_xclk_data),
		.in_sel(i_xclk_data[(DW/8-1):0]),
		.in_ready(xclk_to_wb_fifo_ready),
		.out_valid(xclk_to_wb_fifo_valid),
		.out_addr(o_wb_addr),
		.out_data(o_wb_data),
		.out_sel(o_wb_sel),
		.out_ready(i_wb_ack),
		.rst(i_reset)
	);

	// Stall logic
	assign o_wb_stall = wb_to_xclk_fifo_valid && !i_xclk_ack;

	// Ack and error handling
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (wb_to_xclk_fifo_valid && i_xclk_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= i_xclk_err;
			end else begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end
		end
	end

	// Ready signals
	assign wb_to_xclk_fifo_ready = !i_xclk_stall;
	assign xclk_to_wb_fifo_ready = !i_wb_stall;

endmodule
