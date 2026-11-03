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
	reg	[(AW-1):0] wb_fifo_addr;
	reg	[(DW-1):0] wb_fifo_data;
	reg	[(DW/8-1):0] wb_fifo_sel;
	reg	wb_fifo_cyc;
	reg	wb_fifo_stb;
	reg	wb_fifo_we;
	reg	wb_fifo_err;
	wire	wb_fifo_ack;

	reg	[(AW-1):0] xclk_fifo_addr;
	reg	[(DW-1):0] xclk_fifo_data;
	reg	[(DW/8-1):0] xclk_fifo_sel;
	reg	xclk_fifo_cyc;
	reg	xclk_fifo_stb;
	reg	xclk_fifo_we;
	reg	xclk_fifo_err;
	wire	xclk_fifo_ack;

	// Instantiate Wishbone FIFOs
	wb_fifo wb_fifo_inst (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wbs_cyc(wb_fifo_cyc),
		.wbs_stb(wb_fifo_stb),
		.wbs_we(wb_fifo_we),
		.wbs_addr(wb_fifo_addr),
		.wbs_data(wb_fifo_data),
		.wbs_sel(wb_fifo_sel),
		.wbs_ack(wb_fifo_ack),
		.wbs_err(wb_fifo_err),
		.xbs_cyc(xclk_fifo_cyc),
		.xbs_stb(xclk_fifo_stb),
		.xbs_we(xclk_fifo_we),
		.xbs_addr(xclk_fifo_addr),
		.xbs_data(xclk_fifo_data),
		.xbs_sel(xclk_fifo_sel),
		.xbs_ack(xclk_fifo_ack),
		.xbs_err(xclk_fifo_err)
	);

	wb_fifo xclk_fifo_inst (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wbs_cyc(xclk_fifo_cyc),
		.wbs_stb(xclk_fifo_stb),
		.wbs_we(xclk_fifo_we),
		.wbs_addr(xclk_fifo_addr),
		.wbs_data(xclk_fifo_data),
		.wbs_sel(xclk_fifo_sel),
		.wbs_ack(xclk_fifo_ack),
		.wbs_err(xclk_fifo_err),
		.xbs_cyc(wb_fifo_cyc),
		.xbs_stb(wb_fifo_stb),
		.xbs_we(wb_fifo_we),
		.xbs_addr(wb_fifo_addr),
		.xbs_data(wb_fifo_data),
		.xbs_sel(wb_fifo_sel),
		.xbs_ack(wb_fifo_ack),
		.xbs_err(wb_fifo_err)
	);

	// Output logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			o_wb_stall <= wb_fifo_stall;
			o_wb_ack <= wb_fifo_ack;
			o_wb_data <= wb_fifo_data;
			o_wb_err <= wb_fifo_err;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			o_xclk_cyc <= xclk_fifo_cyc;
			o_xclk_stb <= xclk_fifo_stb;
			o_xclk_we <= xclk_fifo_we;
			o_xclk_addr <= xclk_fifo_addr;
			o_xclk_data <= xclk_fifo_data;
			o_xclk_sel <= xclk_fifo_sel;
		end
	end

endmodule
