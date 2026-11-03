module	wbxclk #(
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

	wire	[DW-1:0]	fifo_wb_data;
	wire	[(DW/8-1):0]	fifo_wb_sel;
	wire	[AW-1:0]	fifo_wb_addr;
	wire			fifo_wb_we;
	wire			fifo_wb_empty, fifo_wb_full, fifo_wb_almost_full;
	wire			fifo_xclk_empty, fifo_xclk_full, fifo_xclk_almost_full;
	wire	[DW-1:0]	fifo_xclk_data;
	wire			fifo_xclk_err;
	wire			o_wb_stall_comb;

	assign	o_wb_stall = o_wb_stall_comb;

	wishbone_fifo #(
		.DW(DW),
		.AW(AW),
		.LGFIFO(LGFIFO)
	) wb_fifo (
		.i_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_we(i_wb_cyc && i_wb_stb && !o_wb_stall_comb),
		.i_data(i_wb_data),
		.i_addr(i_wb_addr),
		.i_sel(i_wb_sel),
		.i_we_bit(i_wb_we),
		.o_empty(fifo_wb_empty),
		.o_full(fifo_wb_full),
		.o_almost_full(fifo_wb_almost_full),
		.o_data(fifo_wb_data),
		.o_addr(fifo_wb_addr),
		.o_sel(fifo_wb_sel),
		.o_we_bit(fifo_wb_we)
	);

	assign	o_wb_stall_comb = fifo_wb_almost_full;

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else if (i_wb_cyc && !o_wb_stall_comb && !fifo_wb_empty) begin
			o_wb_ack <= 1'b1;
			o_wb_data <= fifo_xclk_data;
			o_wb_err <= fifo_xclk_err;
		end else begin
			o_wb_ack <= 1'b0;
		end
	end

	wishbone_fifo #(
		.DW(DW),
		.AW(1),
		.LGFIFO(LGFIFO)
	) xclk_fifo (
		.i_clk(i_xclk_clk),
		.i_reset(i_reset),
		.i_we(i_xclk_ack),
		.i_data({DW{1'b0}}),
		.i_addr({AW{1'b0}}),
		.i_sel({DW/8{1'b0}}),
		.i_we_bit(1'b0),
		.o_empty(fifo_xclk_empty),
		.o_full(fifo_xclk_full),
		.o_almost_full(fifo_xclk_almost_full),
		.o_data(fifo_xclk_data),
		.o_addr(),
		.o_sel(),
		.o_we_bit(fifo_xclk_err)
	);

	assign	o_xclk_cyc = !fifo_wb_empty && !i_xclk_stall;
	assign	o_xclk_stb = !fifo_wb_empty && !i_xclk_stall;
	assign	o_xclk_we = fifo_wb_we;
	assign	o_xclk_addr = fifo_wb_addr;
	assign	o_xclk_data = fifo_wb_data;
	assign	o_xclk_sel = fifo_wb_sel;

endmodule

module wishbone_fifo #(
		parameter	DW=32,
		parameter	AW=1,
		parameter	LGFIFO = 5
	) (
		input	wire			i_clk,
		input	wire			i_reset,
		input	wire			i_we,
		input	wire	[(DW-1):0]	i_data,
		input	wire	[(AW-1):0]	i_addr,
		input	wire	[(DW/8-1):0]	i_sel,
		input	wire			i_we_bit,
		output	wire			o_empty,
		output	wire			o_full,
		output	wire			o_almost_full,
		output	wire	[(DW-1):0]	o_data,
		output	wire	[(AW-1):0]	o_addr,
		output	wire	[(DW/8-1):0]	o_sel,
		output	wire			o_we_bit
	);

	wire	[(DW+AW+DW/8+1-1):0]	fifo_out;
	wire	[(DW+AW+DW/8+1-1):0]	fifo_in;
	wire			fifo_empty, fifo_full, fifo_almost_full;

	assign	fifo_in = {i_we_bit, i_sel, i_data, i_addr};
	assign	{o_we_bit, o_sel, o_data, o_addr} = fifo_out;

	assign	o_empty = fifo_empty;
	assign	o_full = fifo_full;
	assign	o_almost_full = fifo_almost_full;

	fifo #(
		.DW(DW+AW+DW/8+1),
		.LGFIFO(LGFIFO)
	) u_fifo (
		.i_clk(i_clk),
		.i_reset(i_reset),
		.i_we(i_we),
		.i_data(fifo_in),
		.o_empty(fifo_empty),
		.o_full(fifo_full),
		.o_almost_full(fifo_almost_full),
		.o_data(fifo_out)
	);

endmodule

module fifo #(
		parameter	DW=32,
		parameter	LGFIFO = 5
	) (
		input	wire			i_clk,
		input	wire			i_reset,
		input	wire			i_we,
		input	wire	[(DW-1):0]	i_data,
		output	wire			o_empty,
		output	wire			o_full,
		output	wire			o_almost_full,
		output	wire	[(DW-1):0]	o_data
	);

	reg	[(DW-1):0]	ram [2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]	wptr, rptr;
	wire	[LGFIFO:0]	wcnt, rcnt;
	wire			wfull, wempty, rempty, rfull;

	assign	wcnt = {1'b0, wptr} + 1'b1;
	assign	rcnt = {1'b0, rptr} + 1'b1;
	assign	wfull = (wcnt == {LGFIFO{1'b1}});
	assign	wempty = (wcnt == {LGFIFO+1{1'b0}});
	assign	rempty = (rcnt == {LGFIFO+1{1'b0}});
	assign	rfull = (rcnt == {LGFIFO{1'b1}});

	assign	o_empty = rempty;
	assign	o_full = wfull;
	assign	o_almost_full = (wcnt == {LGFIFO{1'b1}} - 1'b1);

	always @(posedge i_clk or posedge i_reset)
	begin
		if (i_reset) begin
			wptr <= {LGFIFO{1'b0}};
			rptr <= {LGFIFO{1'b0}};
		end else if (i_we && !wfull) begin
			ram[wptr] <= i_data;
			wptr <= wptr + 1'b1;
		end
	end

	always @(posedge i_clk)
	begin
		if (!rempty && !rfull) begin
			o_data <= ram[rptr];
			rptr <= rptr + 1'b1;
		end
	end

endmodule
