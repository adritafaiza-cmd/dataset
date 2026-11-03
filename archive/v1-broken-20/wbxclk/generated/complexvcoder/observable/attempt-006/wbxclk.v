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

	// FIFO for transferring Wishbone requests from i_wb_clk to i_xclk_clk
	wb_fifo wb_to_xclk_fifo (
		.clk_i(i_wb_clk),
		.rst_i(i_reset),
		.cyc_i(i_wb_cyc),
		.stb_i(i_wb_stb),
		.we_i(i_wb_we),
		.addr_i(i_wb_addr),
		.data_i(i_wb_data),
		.sel_i(i_wb_sel),
		.stall_i(o_wb_stall),
		.ack_i(o_wb_ack),
		.data_o(o_xclk_data),
		.err_o(o_wb_err),
		.cyc_o(o_xclk_cyc),
		.stb_o(o_xclk_stb),
		.we_o(o_xclk_we),
		.addr_o(o_xclk_addr),
		.sel_o(o_xclk_sel),
		.stall_o(),
		.ack_o(),
		.data_i(i_xclk_data),
		.err_i(i_xclk_err)
	);

	// FIFO for transferring Wishbone responses from i_xclk_clk to i_wb_clk
	wb_fifo xclk_to_wb_fifo (
		.clk_i(i_xclk_clk),
		.rst_i(i_reset),
		.cyc_i(o_xclk_cyc),
		.stb_i(o_xclk_stb),
		.we_i(o_xclk_we),
		.addr_i(o_xclk_addr),
		.data_i(o_xclk_data),
		.sel_i(o_xclk_sel),
		.stall_i(i_xclk_stall),
		.ack_i(i_xclk_ack),
		.data_o(i_wb_data),
		.err_o(),
		.cyc_o(),
		.stb_o(),
		.we_o(),
		.addr_o(),
		.sel_o(),
		.stall_o(),
		.ack_o(o_wb_ack)
	);

endmodule
