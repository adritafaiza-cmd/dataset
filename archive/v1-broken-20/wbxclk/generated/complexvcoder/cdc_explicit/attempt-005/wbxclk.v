module wbxclk #(
	parameter AW=32,
				DW=32,
				LGFIFO = 5
) (
		input wire			i_wb_clk, i_reset,
		input wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input wire	[(AW-1):0]	i_wb_addr,
		input wire	[(DW-1):0]	i_wb_data,
		input wire	[(DW/8-1):0]	i_wb_sel,
		output wire			o_wb_stall,
		output reg			o_wb_ack,
		output reg	[(DW-1):0]	o_wb_data,
		output reg			o_wb_err,
		input wire			i_xclk_clk,
		output reg			o_xclk_cyc,
		output reg			o_xclk_stb,
		output reg			o_xclk_we,
		output reg	[(AW-1):0]	o_xclk_addr,
		output reg	[(DW-1):0]	o_xclk_data,
		output reg	[(DW/8-1):0]	o_xclk_sel,
		input wire			i_xclk_stall,
		input wire			i_xclk_ack,
		input wire	[(DW-1):0]	i_xclk_data,
		input wire			i_xclk_err
	);

	// Internal signals
	wire wb_fifo_cyc;
	wire wb_fifo_stb;
	wire wb_fifo_we;
	wire [(AW-1):0] wb_fifo_addr;
	wire [(DW-1):0] wb_fifo_data;
	wire [(DW/8-1):0] wb_fifo_sel;
	wire wb_fifo_stall;
	wire wb_fifo_ack;
	wire [(DW-1):0] wb_fifo_data_out;
	wire wb_fifo_err;

	// Instantiate FIFO
	fifo_wishbone #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_fifo (
		.clk(i_wb_clk),
		.rst(i_reset),
		.i_cyc(i_wb_cyc),
		.i_stb(i_wb_stb),
		.i_we(i_wb_we),
		.i_addr(i_wb_addr),
		.i_data(i_wb_data),
		.i_sel(i_wb_sel),
		.o_stall(wb_fifo_stall),
		.o_ack(wb_fifo_ack),
		.o_data(wb_fifo_data_out),
		.o_err(wb_fifo_err)
	);

	// Internal signals for cross-domain communication
	wire wb_clk_domain_ack;
	wire [(DW-1):0] wb_clk_domain_data;
	wire wb_clk_domain_err;
	wire xclk_clk_domain_clk;
	wire xclk_clk_domain_stall;
	wire xclk_clk_domain_ack;
	wire [(DW-1):0] xclk_clk_domain_data;
	wire xclk_clk_domain_err;

	// Instantiate cross-domain communication logic
	cdc_cross_domain #(
		.DW(DW)
	) wb_cdc (
		.clk_wb(i_wb_clk),
		.clk_xclk(i_xclk_clk),
		.data_in(wb_fifo_ack),
		.data_out(wb_clk_domain_ack)
	);

	cdc_cross_domain #(
		.DW(DW)
	) wb_data_cdc (
		.clk_wb(i_wb_clk),
		.clk_xclk(i_xclk_clk),
		.data_in(wb_fifo_data_out),
		.data_out(wb_clk_domain_data)
	);

	cdc_cross_domain #(
		.DW(DW)
	) wb_err_cdc (
		.clk_wb(i_wb_clk),
		.clk_xclk(i_xclk_clk),
		.data_in(wb_fifo_err),
		.data_out(wb_clk_domain_err)
	);

	cdc_cross_domain #(
		.DW(AW)
	) xclk_addr_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_addr),
		.data_out(i_wb_addr)
	);

	cdc_cross_domain #(
		.DW(DW)
	) xclk_data_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_data),
		.data_out(i_xclk_data)
	);

	cdc_cross_domain #(
		.DW(DW/8)
	) xclk_sel_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_sel),
		.data_out(i_wb_sel)
	);

	// Instantiate cross-domain communication logic for xclk outputs
	cdc_cross_domain #(
		.DW(1)
	) xclk_cyc_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_cyc),
		.data_out(wb_clk_domain_ack)
	);

	cdc_cross_domain #(
		.DW(1)
	) xclk_stb_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_stb),
		.data_out(wb_clk_domain_ack)
	);

	cdc_cross_domain #(
		.DW(1)
	) xclk_we_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(o_xclk_we),
		.data_out(wb_clk_domain_ack)
	);

	cdc_cross_domain #(
		.DW(1)
	) xclk_stall_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(i_xclk_stall),
		.data_out(wb_clk_domain_stall)
	);

	cdc_cross_domain #(
		.DW(1)
	) xclk_ack_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(i_xclk_ack),
		.data_out(wb_clk_domain_stall)
	);

	cdc_cross_domain #(
		.DW(1)
	) xclk_err_cdc (
		.clk_wb(i_xclk_clk),
		.clk_xclk(i_wb_clk),
		.data_in(i_xclk_err),
		.data_out(wb_clk_domain_stall)
	);

	// Logic for handling wb_clk_domain_ack and wb_clk_domain_stall
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_stall <= 0;
		end else begin
			o_wb_ack <= wb_clk_domain_ack;
			o_wb_stall <= wb_clk_domain_stall;
		end
	end

	// Logic for handling xclk_clk_domain_clk
	always @(posedge i_xclk_clk) begin
		o_xclk_cyc <= wb_clk_domain_ack;
		o_xclk_stb <= wb_clk_domain_ack;
		o_xclk_we <= wb_clk_domain_ack;
		o_xclk_addr <= wb_clk_domain_data;
		o_xclk_data <= wb_clk_domain_data;
		o_xclk_sel <= wb_clk_domain_data;
		o_xclk_err <= wb_clk_domain_err;
	end

endmodule
