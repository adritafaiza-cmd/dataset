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

	wire	[DW/8-1:0]	wb_fifo_empty;
	wire	[DW/8-1:0]	wb_fifo_full;
	wire	[DW/8-1:0]	wb_fifo_almost_full;
	wire			wb_fifo_almost_empty;
	wire			wb_fifo_rd;
	wire			wb_fifo_wr;
	wire	[(AW+DW+DW/8+1-1):0]	wb_fifo_in;
	wire	[(AW+DW+DW/8+1-1):0]	wb_fifo_out;

	wire	[DW/8-1:0]	xclk_fifo_empty;
	wire	[DW/8-1:0]	xclk_fifo_full;
	wire	[DW/8-1:0]	xclk_fifo_almost_full;
	wire			xclk_fifo_almost_empty;
	wire			xclk_fifo_rd;
	wire			xclk_fifo_wr;
	wire	[(DW+DW/8+1-1):0]	xclk_fifo_in;
	wire	[(DW+DW/8+1-1):0]	xclk_fifo_out;

	reg	[DW/8-1:0]	wb_fifo_count;
	reg	[DW/8-1:0]	xclk_fifo_count;

	assign wb_fifo_in = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
	assign wb_fifo_wr = i_wb_cyc && i_wb_stb && !wb_fifo_almost_full[0];
	assign wb_fifo_rd = o_xclk_cyc && !i_xclk_stall && !wb_fifo_empty[0];
	assign o_wb_stall = wb_fifo_almost_full[0];

	assign xclk_fifo_in = {i_xclk_data, i_xclk_err};
	assign xclk_fifo_wr = i_xclk_ack && !xclk_fifo_almost_full[0];
	assign xclk_fifo_rd = o_wb_ack && !xclk_fifo_empty[0];

	assign o_xclk_cyc = !wb_fifo_empty[0];
	assign o_xclk_stb = !wb_fifo_empty[0];
	assign o_xclk_we = wb_fifo_out[DW+DW/8];
	assign o_xclk_addr = wb_fifo_out[(DW+DW/8-1):(DW/8)];
	assign o_xclk_data = wb_fifo_out[(DW-1):0];
	assign o_xclk_sel = wb_fifo_out[(DW/8-1):0];

	assign o_wb_ack = !xclk_fifo_empty[0];
	assign o_wb_data = xclk_fifo_out[(DW-1):0];
	assign o_wb_err = xclk_fifo_out[DW];

	fifo #(
		.DW(AW+DW+DW/8+1),
		.LGFIFO(LGFIFO)
	) wb_fifo (
		.i_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_in),
		.o_data(wb_fifo_out),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_empty(wb_fifo_almost_empty),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(DW+DW/8+1),
		.LGFIFO(LGFIFO)
	) xclk_fifo (
		.i_clk(i_xclk_clk),
		.i_reset(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_in),
		.o_data(xclk_fifo_out),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_empty(xclk_fifo_almost_empty),
		.o_almost_full(xclk_fifo_almost_full)
	);

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_count <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (wb_fifo_wr && !wb_fifo_rd) begin
				wb_fifo_count <= wb_fifo_count + 1;
			end else if (!wb_fifo_wr && wb_fifo_rd) begin
				wb_fifo_count <= wb_fifo_count - 1;
			end
			if (xclk_fifo_rd) begin
				o_wb_ack <= 1;
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_count <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (xclk_fifo_wr && !xclk_fifo_rd) begin
				xclk_fifo_count <= xclk_fifo_count + 1;
			end else if (!xclk_fifo_wr && xclk_fifo_rd) begin
				xclk_fifo_count <= xclk_fifo_count - 1;
			end
			if (wb_fifo_rd) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= wb_fifo_out[DW+DW/8];
				o_xclk_addr <= wb_fifo_out[(DW+DW/8-1):(DW/8)];
				o_xclk_data <= wb_fifo_out[(DW-1):0];
				o_xclk_sel <= wb_fifo_out[(DW/8-1):0];
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

endmodule

module fifo #(
	parameter	DW = 32,
				LGFIFO = 5
) (
	input	wire	i_clk,
	input	wire	i_reset,
	input	wire	i_wr,
	input	wire	i_rd,
	input	wire	[(DW-1):0]	i_data,
	output	wire	[(DW-1):0]	o_data,
	output	wire	o_empty,
	output	wire	o_full,
	output	wire	o_almost_empty,
	output	wire	o_almost_full
);

	reg	[(DW-1):0]	fifo [2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]	fifo_wr_ptr;
	reg	[LGFIFO-1:0]	fifo_rd_ptr;
	reg	[LGFIFO:0]	fifo_count;

	assign o_data = fifo[fifo_rd_ptr];
	assign o_empty = (fifo_count == 0);
	assign o_full = (fifo_count == 2**LGFIFO);
	assign o_almost_empty = (fifo_count == 1);
	assign o_almost_full = (fifo_count == 2**LGFIFO-1);

	always @(posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wr_ptr <= 0;
			fifo_rd_ptr <= 0;
			fifo_count <= 0;
		end else begin
			if (i_wr && !o_full) begin
				fifo[fifo_wr_ptr] <= i_data;
				fifo_wr_ptr <= fifo_wr_ptr + 1;
				fifo_count <= fifo_count + 1;
			end
			if (i_rd && !o_empty) begin
				fifo_rd_ptr <= fifo_rd_ptr + 1;
				fifo_count <= fifo_count - 1;
			end
		end
	end

endmodule
