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
	reg	wb_to_xclk_fifo_push, wb_to_xclk_fifo_full, wb_to_xclk_fifo_empty;
	wire	[(AW+DW+5):0] wb_to_xclk_fifo_din, wb_to_xclk_fifo_dout;
	reg	xclk_to_wb_fifo_push, xclk_to_wb_fifo_full, xclk_to_wb_fifo_empty;
	wire	[(DW+2):0] xclk_to_wb_fifo_din, xclk_to_wb_fifo_dout;
	reg	wb_to_xclk_fifo_pop, xclk_to_wb_fifo_pop;

	// FIFO for crossing from i_wb_clk to i_xclk_clk
	fifo #(
		.WIDTH(AW+DW+5),
		.LGDEPTH(LGFIFO)
	) wb_to_xclk_fifo_inst (
		.clk(i_wb_clk),
		.rst(i_reset),
		.push(wb_to_xclk_fifo_push),
		.full(wb_to_xclk_fifo_full),
		.din(wb_to_xclk_fifo_din),
		.rd_clk(i_xclk_clk),
		.pop(wb_to_xclk_fifo_pop),
		.empty(wb_to_xclk_fifo_empty),
		.dout(wb_to_xclk_fifo_dout)
	);

	// FIFO for crossing from i_xclk_clk to i_wb_clk
	fifo #(
		.WIDTH(DW+2),
		.LGDEPTH(LGFIFO)
	) xclk_to_wb_fifo_inst (
		.clk(i_xclk_clk),
		.rst(i_reset),
		.push(xclk_to_wb_fifo_push),
		.full(xclk_to_wb_fifo_full),
		.din(xclk_to_wb_fifo_din),
		.rd_clk(i_wb_clk),
		.pop(xclk_to_wb_fifo_pop),
		.empty(xclk_to_wb_fifo_empty),
		.dout(xclk_to_wb_fifo_dout)
	);

	// wb_to_xclk_fifo control
	assign wb_to_xclk_fifo_din = {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
	assign wb_to_xclk_fifo_push = i_wb_cyc & i_wb_stb & !wb_to_xclk_fifo_full;

	// xclk_to_wb_fifo control
	assign xclk_to_wb_fifo_din = {i_xclk_ack, i_xclk_err, i_xclk_data};
	assign xclk_to_wb_fifo_push = i_xclk_ack | i_xclk_err;

	// Wishbone side outputs
	assign o_wb_stall = wb_to_xclk_fifo_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			xclk_to_wb_fifo_pop <= 0;
		end else begin
			xclk_to_wb_fifo_pop <= 0;
			if (!xclk_to_wb_fifo_empty) begin
				xclk_to_wb_fifo_pop <= 1;
				o_wb_ack <= xclk_to_wb_fifo_dout[DW+1];
				o_wb_err <= xclk_to_wb_fifo_dout[DW];
				o_wb_data <= xclk_to_wb_fifo_dout[DW-1:0];
			end
		end
	end

	// Cross-clock side outputs
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			wb_to_xclk_fifo_pop <= 0;
		end else begin
			wb_to_xclk_fifo_pop <= 0;
			if (!wb_to_xclk_fifo_empty && !i_xclk_stall) begin
				wb_to_xclk_fifo_pop <= 1;
				o_xclk_cyc <= wb_to_xclk_fifo_dout[AW+DW+4];
				o_xclk_stb <= wb_to_xclk_fifo_dout[AW+DW+3];
				o_xclk_we <= wb_to_xclk_fifo_dout[AW+DW+2];
				o_xclk_addr <= wb_to_xclk_fifo_dout[AW+DW+1:DW+2];
				o_xclk_data <= wb_to_xclk_fifo_dout[DW+1:2];
				o_xclk_sel <= wb_to_xclk_fifo_dout[1:0];
			end
		end
	end

endmodule

module fifo #(
		parameter WIDTH = 1,
				LGDEPTH = 1
	) (
		input	wire clk, rst, push,
		output reg full,
		input wire [WIDTH-1:0] din,
		input wire rd_clk, pop,
		output reg empty,
		output reg [WIDTH-1:0] dout
	);

	localparam DEPTH = 1 << LGDEPTH;
	reg [WIDTH-1:0] mem [DEPTH-1:0];
	reg [$clog2(DEPTH):0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync, wr_ptr_gray_sync;
	wire wr_en = push & ~full;
	wire rd_en = pop & ~empty;

	// Gray code conversion
	assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
	assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

	// Write pointer logic
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			full <= 0;
		end else if (wr_en) begin
			wr_ptr <= wr_ptr + 1;
			full <= (wr_ptr_gray_sync == rd_ptr_gray + 1);
		end
	end

	// Read pointer logic
	always @(posedge rd_clk or posedge rst) begin
		if (rst) begin
			rd_ptr <= 0;
			empty <= 1;
		end else if (rd_en) begin
			rd_ptr <= rd_ptr + 1;
			empty <= (wr_ptr_gray_sync == rd_ptr_gray + 1);
		end
	end

	// Synchronize gray pointers
	sync_gray #(LGDEPTH) sync_wr_ptr (
		.clk(rd_clk),
		.rst(rst),
		.d(wr_ptr_gray),
		.q(wr_ptr_gray_sync)
	);

	sync_gray #(LGDEPTH) sync_rd_ptr (
		.clk(clk),
		.rst(rst),
		.d(rd_ptr_gray),
		.q(rd_ptr_gray_sync)
	);

	// Memory write
	always @(posedge clk) begin
		if (wr_en)
			mem[wr_ptr] <= din;
	end

	// Memory read
	always @(posedge rd_clk) begin
		if (rd_en)
			dout <= mem[rd_ptr];
	end

endmodule

module sync_gray #(
		parameter LGDEPTH = 1
	) (
		input wire clk, rst,
		input wire [$clog2(1<<LGDEPTH):0] d,
		output reg [$clog2(1<<LGDEPTH):0] q
	);

	reg [$clog2(1<<LGDEPTH):0] q1, q2;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			q <= 0;
			q1 <= 0;
			q2 <= 0;
		end else begin
			q1 <= d;
			q2 <= q1;
			q <= q2;
		end
	end

endmodule
