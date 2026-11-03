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

	wire	[1:0]	wb_fifo_empty;
	wire	[1:0]	wb_fifo_full;
	wire	[1:0]	wb_fifo_almost_full;
	wire	[1:0]	xclk_fifo_empty;
	wire	[1:0]	xclk_fifo_full;
	wire	[1:0]	xclk_fifo_almost_full;

	wire	wb_fifo_wr;
	wire	wb_fifo_rd;
	wire	xclk_fifo_wr;
	wire	xclk_fifo_rd;

	wire	[AW-1:0]	wb_fifo_addr;
	wire	[DW-1:0]	wb_fifo_data;
	wire	[DW/8-1:0]	wb_fifo_sel;
	wire	wb_fifo_we;
	wire	wb_fifo_cyc;

	wire	[AW-1:0]	xclk_fifo_addr;
	wire	[DW-1:0]	xclk_fifo_data;
	wire	[DW/8-1:0]	xclk_fifo_sel;
	wire	xclk_fifo_we;
	wire	xclk_fifo_cyc;

	wire	wb_fifo_valid;
	wire	xclk_fifo_valid;

	wire	wb_fifo_rst;
	wire	xclk_fifo_rst;

	wire	wb_fifo_empty_sync;
	wire	xclk_fifo_empty_sync;

	wire	wb_fifo_full_sync;
	wire	xclk_fifo_full_sync;

	wire	wb_fifo_almost_full_sync;
	wire	xclk_fifo_almost_full_sync;

	wire	wb_fifo_valid_sync;
	wire	xclk_fifo_valid_sync;

	wire	wb_fifo_rst_sync;
	wire	xclk_fifo_rst_sync;

	wire	wb_fifo_wr_sync;
	wire	xclk_fifo_wr_sync;

	wire	wb_fifo_rd_sync;
	wire	xclk_fifo_rd_sync;

	wire	wb_fifo_addr_sync;
	wire	[AW-1:0]	wb_fifo_addr_sync;
	wire	wb_fifo_data_sync;
	wire	[DW-1):0]	wb_fifo_data_sync;
	wire	wb_fifo_sel_sync;
	wire	[DW/8-1:0]	wb_fifo_sel_sync;
	wire	wb_fifo_we_sync;
	wire	wb_fifo_cyc_sync;

	wire	xclk_fifo_addr_sync;
	wire	[AW-1:0]	xclk_fifo_addr_sync;
	wire	xclk_fifo_data_sync;
	wire	[DW-1:0]	xclk_fifo_data_sync;
	wire	xclk_fifo_sel_sync;
	wire	[DW/8-1:0]	xclk_fifo_sel_sync;
	wire	xclk_fifo_we_sync;
	wire	xclk_fifo_cyc_sync;

	assign	wb_fifo_empty_sync = wb_fifo_empty[0];
	assign	xclk_fifo_empty_sync = xclk_fifo_empty[0];

	assign	wb_fifo_full_sync = wb_fifo_full[0];
	assign	xclk_fifo_full_sync = xclk_fifo_full[0];

	assign	wb_fifo_almost_full_sync = wb_fifo_almost_full[0];
	assign	xclk_fifo_almost_full_sync = xclk_fifo_almost_full[0];

	assign	wb_fifo_valid_sync = wb_fifo_valid;
	assign	xclk_fifo_valid_sync = xclk_fifo_valid;

	assign	wb_fifo_rst_sync = wb_fifo_rst;
	assign	xclk_fifo_rst_sync = xclk_fifo_rst;

	assign	wb_fifo_wr_sync = wb_fifo_wr;
	assign	xclk_fifo_wr_sync = xclk_fifo_wr;

	assign	wb_fifo_rd_sync = wb_fifo_rd;
	assign	xclk_fifo_rd_sync = xclk_fifo_rd;

	assign	wb_fifo_addr_sync = wb_fifo_addr;
	assign	wb_fifo_addr_sync = wb_fifo_addr;

	assign	wb_fifo_data_sync = wb_fifo_data;
	assign	wb_fifo_data_sync = wb_fifo_data;

	assign	wb_fifo_sel_sync = wb_fifo_sel;
	assign	wb_fifo_sel_sync = wb_fifo_sel;

	assign	wb_fifo_we_sync = wb_fifo_we;
	assign	wb_fifo_we_sync = wb_fifo_we;

	assign	wb_fifo_cyc_sync = wb_fifo_cyc;
	assign	wb_fifo_cyc_sync = wb_fifo_cyc;

	assign	xclk_fifo_addr_sync = xclk_fifo_addr;
	assign	xclk_fifo_addr_sync = xclk_fifo_addr;

	assign	xclk_fifo_data_sync = xclk_fifo_data;
	assign	xclk_fifo_data_sync = xclk_fifo_data;

	assign	xclk_fifo_sel_sync = xclk_fifo_sel;
	assign	xclk_fifo_sel_sync = xclk_fifo_sel;

	assign	xclk_fifo_we_sync = xclk_fifo_we;
	assign	xclk_fifo_we_sync = xclk_fifo_we;

	assign	xclk_fifo_cyc_sync = xclk_fifo_cyc;
	assign	xclk_fifo_cyc_sync = xclk_fifo_cyc;

	assign	wb_fifo_wr = i_wb_cyc && i_wb_stb &&!wb_fifo_almost_full_sync;
	assign	wb_fifo_rd =!wb_fifo_empty_sync &&!i_xclk_stall;

	assign	xclk_fifo_wr =!xclk_fifo_full_sync &&!i_xclk_stall;
	assign	xclk_fifo_rd =!xclk_fifo_empty_sync && i_xclk_ack;

	assign	wb_fifo_addr = i_wb_addr;
	assign	wb_fifo_data = i_wb_data;
	assign	wb_fifo_sel = i_wb_sel;
	assign	wb_fifo_we = i_wb_we;
	assign	wb_fifo_cyc = i_wb_cyc;

	assign	xclk_fifo_addr = wb_fifo_addr_sync;
	assign	xclk_fifo_data = wb_fifo_data_sync;
	assign	xclk_fifo_sel = wb_fifo_sel_sync;
	assign	xclk_fifo_we = wb_fifo_we_sync;
	assign	xclk_fifo_cyc = wb_fifo_cyc_sync;

	assign	o_wb_stall = wb_fifo_almost_full_sync;
	assign	o_wb_ack = xclk_fifo_valid_sync;
	assign	o_wb_data = xclk_fifo_data_sync;
	assign	o_wb_err = xclk_fifo_err_sync;

	assign	o_xclk_cyc = xclk_fifo_cyc_sync;
	assign	o_xclk_stb = xclk_fifo_stb_sync;
	assign	o_xclk_we = xclk_fifo_we_sync;
	assign	o_xclk_addr = xclk_fifo_addr_sync;
	assign	o_xclk_data = xclk_fifo_data_sync;
	assign	o_xclk_sel = xclk_fifo_sel_sync;

	fifo #(
		.DW(AW),
		.LGFIFO(LGFIFO)
	) wb_fifo_addr_inst (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_addr),
		.o_data(wb_fifo_addr_sync),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_fifo_data_inst (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_data),
		.o_data(wb_fifo_data_sync),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(DW/8),
		.LGFIFO(LGFIFO)
	) wb_fifo_sel_inst (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_sel),
		.o_data(wb_fifo_sel_sync),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(1),
		.LGFIFO(LGFIFO)
	) wb_fifo_we_inst (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_we),
		.o_data(wb_fifo_we_sync),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(1),
		.LGFIFO(LGFIFO)
	) wb_fifo_cyc_inst (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_wr(wb_fifo_wr),
		.i_rd(wb_fifo_rd),
		.i_data(wb_fifo_cyc),
		.o_data(wb_fifo_cyc_sync),
		.o_empty(wb_fifo_empty),
		.o_full(wb_fifo_full),
		.o_almost_full(wb_fifo_almost_full)
	);

	fifo #(
		.DW(AW),
		.LGFIFO(LGFIFO)
	) xclk_fifo_addr_inst (
		.i_clk(i_xclk_clk),
		.i_rst(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_addr),
		.o_data(xclk_fifo_addr_sync),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_full(xclk_fifo_almost_full)
	);

	fifo #(
		.DW(DW),
		.LGFIFO(LGFIFO)
	) xclk_fifo_data_inst (
		.i_clk(i_xclk_clk),
		.i_rst(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_data),
		.o_data(xclk_fifo_data_sync),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_full(xclk_fifo_almost_full)
	);

	fifo #(
		.DW(DW/8),
		.LGFIFO(LGFIFO)
	) xclk_fifo_sel_inst (
		.i_clk(i_xclk_clk),
		.i_rst(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_sel),
		.o_data(xclk_fifo_sel_sync),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_full(xclk_fifo_almost_full)
	);

	fifo #(
		.DW(1),
		.LGFIFO(LGFIFO)
	) xclk_fifo_we_inst (
		.i_clk(i_xclk_clk),
		.i_rst(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_we),
		.o_data(xclk_fifo_we_sync),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_full(xclk_fifo_almost_full)
	);

	fifo #(
		.DW(1),
		.LGFIFO(LGFIFO)
	) xclk_fifo_cyc_inst (
		.i_clk(i_xclk_clk),
		.i_rst(i_reset),
		.i_wr(xclk_fifo_wr),
		.i_rd(xclk_fifo_rd),
		.i_data(xclk_fifo_cyc),
		.o_data(xclk_fifo_cyc_sync),
		.o_empty(xclk_fifo_empty),
		.o_full(xclk_fifo_full),
		.o_almost_full(xclk_fifo_almost_full)
	);

endmodule

module fifo #(
	parameter	DW = 32,
				LGFIFO = 5
	) (
		input	wire			i_clk,
		input	wire			i_rst,
		input	wire			i_wr,
		input	wire			i_rd,
		input	wire	[(DW-1):0]	i_data,
		output	wire	[(DW-1):0]	o_data,
		output	wire			o_empty,
		output	wire			o_full,
		output	wire			o_almost_full
	);

	reg	[(DW-1):0]	fifo_data	[2**LGFIFO-1:0];
	reg	[LGFFIFO-1:0]	fifo_wr_ptr;
	reg	[LGFFIFO-1:0]	fifo_rd_ptr;
	reg	[LGFFIFO:0]	fifo_count;

	always @(posedge i_clk) begin
		if (i_rst) begin
			fifo_wr_ptr <= 0;
			fifo_rd_ptr <= 0;
			fifo_count <= 0;
		end else begin
			if (i_wr &&!o_full) begin
				fifo_data[fifo_wr_ptr] <= i_data;
				fifo_wr_ptr <= fifo_wr_ptr + 1;
				fifo_count <= fifo_count + 1;
			end
			if (i_rd &&!o_empty) begin
				o_data <= fifo_data[fifo_rd_ptr];
				fifo_rd_ptr <= fifo_rd_ptr + 1;
				fifo_count <= fifo_count - 1;
			end
		end
	end

	assign	o_empty = (fifo_count == 0);
	assign	o_full = (fifo_count == 2**LGFIFO);
	assign	o_almost_full = (fifo_count == 2**LGFIFO - 1);

endmodule
