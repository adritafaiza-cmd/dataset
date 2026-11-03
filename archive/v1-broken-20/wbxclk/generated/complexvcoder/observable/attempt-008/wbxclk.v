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

	// Internal signals for wb_to_xclk_fifo
	reg	[AW-1:0]		wb_to_xclk_fifo_dout_addr;
	reg	[(DW-1):0]	wb_to_xclk_fifo_dout_data;
	reg	[(DW/8-1):0]	wb_to_xclk_fifo_dout_sel;
	reg					wb_to_xclk_fifo_dout_cyc;
	reg					wb_to_xclk_fifo_dout_stb;
	reg					wb_to_xclk_fifo_dout_we;
	reg					wb_to_xclk_fifo_dout_ack;
	reg					wb_to_xclk_fifo_dout_err;

	// Internal signals for xclk_to_wb_fifo
	reg	[AW-1:0]		xclk_to_wb_fifo_dout_addr;
	reg	[(DW-1):0]	xclk_to_wb_fifo_dout_data;
	reg	[(DW/8-1):0]	xclk_to_wb_fifo_dout_sel;
	reg					xclk_to_wb_fifo_dout_cyc;
	reg					xclk_to_wb_fifo_dout_stb;
	reg					xclk_to_wb_fifo_dout_we;
	reg					xclk_to_wb_fifo_dout_ack;
	reg					xclk_to_wb_fifo_dout_err;

	// FIFO instances
	wb_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.din_cyc(i_wb_cyc),
		.din_stb(i_wb_stb),
		.din_we(i_wb_we),
		.din_addr(i_wb_addr),
		.din_data(i_wb_data),
		.din_sel(i_wb_sel),
		.dout_cyc(wb_to_xclk_fifo_dout_cyc),
		.dout_stb(wb_to_xclk_fifo_dout_stb),
		.dout_we(wb_to_xclk_fifo_dout_we),
		.dout_addr(wb_to_xclk_fifo_dout_addr),
		.dout_data(wb_to_xclk_fifo_dout_data),
		.dout_sel(wb_to_xclk_fifo_dout_sel),
		.dout_ack(wb_to_xclk_fifo_dout_ack),
		.dout_err(wb_to_xclk_fifo_dout_err)
	);

	wb_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.din_cyc(i_xclk_cyc),
		.din_stb(i_xclk_stb),
		.din_we(i_xclk_we),
		.din_addr(i_xclk_addr),
		.din_data(i_xclk_data),
		.din_sel(i_xclk_sel),
		.dout_cyc(xclk_to_wb_fifo_dout_cyc),
		.dout_stb(xclk_to_wb_fifo_dout_stb),
		.dout_we(xclk_to_wb_fifo_dout_we),
		.dout_addr(xclk_to_wb_fifo_dout_addr),
		.dout_data(xclk_to_wb_fifo_dout_data),
		.dout_sel(xclk_to_wb_fifo_dout_sel),
		.dout_ack(xclk_to_wb_fifo_dout_ack),
		.dout_err(xclk_to_wb_fifo_dout_err)
	);

	// Logic to handle Wishbone requests from wb_clk domain and enqueue them in a FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_stall <= 0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !i_wb_we) begin
				wb_to_xclk_fifo_din_stb <= 1;
				wb_to_xclk_fifo_din_cyc <= 1;
				wb_to_xclk_fifo_din_we <= 0;
				wb_to_xclk_fifo_din_addr <= i_wb_addr;
				wb_to_xclk_fifo_din_data <= i_wb_data;
				wb_to_xclk_fifo_din_sel <= i_wb_sel;
				o_wb_stall <= wb_to_xclk_fifo_dout_stb;
			end else begin
				wb_to_xclk_fifo_din_stb <= 0;
				wb_to_xclk_fifo_din_cyc <= 0;
				o_wb_stall <= 0;
			end
			if (wb_to_xclk_fifo_dout_ack) begin
				o_wb_ack <= 1;
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	// Logic to handle Wishbone responses from xclk_clk domain and enqueue them in a FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end else begin
			if (xclk_to_wb_fifo_dout_cyc && xclk_to_wb_fifo_dout_stb) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= xclk_to_wb_fifo_dout_we;
				o_xclk_addr <= xclk_to_wb_fifo_dout_addr;
				o_xclk_data <= xclk_to_wb_fifo_dout_data;
				o_xclk_sel <= xclk_to_wb_fifo_dout_sel;
				o_xclk_err <= xclk_to_wb_fifo_dout_err;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
				o_xclk_err <= 0;
			end
			if (i_xclk_stall || i_xclk_err) begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end
		end
	end

endmodule
