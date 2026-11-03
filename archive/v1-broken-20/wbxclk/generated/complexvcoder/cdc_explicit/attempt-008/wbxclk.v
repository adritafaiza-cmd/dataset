module wbxclk #(
	parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);

	// Internal signals
	wire wb_to_xclk_fifo_full;
	wire wb_to_xclk_fifo_ready;
	wire wb_to_xclk_cdc_src_valid;
	wire wb_to_xclk_cdc_dst_valid;
	wire wb_to_xclk_cdc_dst_ready;

	// FIFO to buffer Wishbone cycles
	fifo #(
		.WIDTH(DW + AW + 2 + 4),  // cyc, stb, we, addr, data, sel
		.DEPTH(1 << LGFIFO)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.rst(i_reset),
		.din({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
		.full(wb_to_xclk_fifo_full),
		.ack(o_wb_ack),
		.err(o_wb_err),
		.dout(o_xclk_cyc, o_xclk_stb, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel)
	);

	// Cross-clock-domain for Wishbone signals
	cdc #(
		.WIDTH(1 + 1 + DW + AW + 2 + 4)  // cyc, stb, we, addr, data, sel
	) wb_to_xclk_cdc (
		.src_clk(i_wb_clk),
		.src_rst(i_reset),
		.dst_clk(i_xclk_clk),
		.dst_stall(i_xclk_stall),
		.dst_ack(i_xclk_ack),
		.dst_data(i_xclk_data),
		.dst_err(i_xclk_err),
		.src_valid(wb_to_xclk_fifo_ready),
		.dst_valid(wb_to_xclk_cdc_dst_valid),
		.dst_ready(wb_to_xclk_cdc_dst_ready)
	);

	// Connect CDC outputs to FIFO inputs
	assign wb_to_xclk_fifo_ready = wb_to_xclk_cdc_dst_ready;

	// Output stall signal
	assign o_wb_stall = wb_to_xclk_fifo_full;

endmodule
