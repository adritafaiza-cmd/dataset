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

	localparam	FIFO_DEPTH	= 1 << LGFIFO;
	localparam	FIFO_WIDTH	= AW + DW + (DW/8) + 4;

	wire [FIFO_WIDTH-1:0]	fifo_wb_data;
	wire			fifo_wb_wr_en;
	wire			fifo_wb_full;
	wire			fifo_wb_empty;
	wire			fifo_wb_rd_en;
	wire [FIFO_WIDTH-1:0]	fifo_xclk_data;
	wire			fifo_xclk_wr_en;
	wire			fifo_xclk_full;
	wire			fifo_xclk_empty;
	wire			fifo_xclk_rd_en;

	assign	fifo_wb_data = {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
	assign	fifo_wb_wr_en = i_wb_stb & ~o_wb_stall;
	assign	o_wb_stall = fifo_wb_full;

	assign	fifo_xclk_rd_en = ~fifo_xclk_empty & ~i_xclk_stall;
	assign	o_xclk_cyc = fifo_xclk_data[FIFO_WIDTH-1];
	assign	o_xclk_stb = fifo_xclk_data[FIFO_WIDTH-2];
	assign	o_xclk_we = fifo_xclk_data[FIFO_WIDTH-3];
	assign	o_xclk_addr = fifo_xclk_data[FIFO_WIDTH-4-:AW];
	assign	o_xclk_data = fifo_xclk_data[FIFO_WIDTH-5-AW-:DW];
	assign	o_xclk_sel = fifo_xclk_data[FIFO_WIDTH-6-AW-DW-:DW/8];

	assign	fifo_xclk_wr_en = i_xclk_stb & ~i_xclk_stall;

	assign	fifo_wb_rd_en = ~fifo_wb_empty & i_xclk_ack;

	assign	o_wb_ack = fifo_wb_data[FIFO_WIDTH-1];
	assign	o_wb_data = fifo_wb_data[FIFO_WIDTH-2-:DW];
	assign	o_wb_err = fifo_wb_data[FIFO_WIDTH-3-DW];

	fifo_sync #(
		.WIDTH(FIFO_WIDTH),
		.DEPTH(FIFO_DEPTH)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.din(fifo_wb_data),
		.wr_en(fifo_wb_wr_en),
		.full(fifo_wb_full),
		.rd_clk(i_xclk_clk),
		.dout(fifo_xclk_data),
		.rd_en(fifo_xclk_rd_en),
		.empty(fifo_xclk_empty)
	);

	fifo_sync #(
		.WIDTH(FIFO_WIDTH),
		.DEPTH(FIFO_DEPTH)
	) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.din({i_xclk_cyc, i_xclk_stb, i_xclk_we, i_xclk_addr, i_xclk_data, i_xclk_sel}),
		.wr_en(fifo_xclk_wr_en),
		.full(fifo_xclk_full),
		.rd_clk(i_wb_clk),
		.dout(fifo_wb_data),
		.rd_en(fifo_wb_rd_en),
		.empty(fifo_wb_empty)
	);

endmodule

module fifo_sync #(
		parameter WIDTH = 32,
				DEPTH = 16
	) (
		input	wire			clk,
		input	wire			reset,
		input	wire	[WIDTH-1:0]	din,
		input	wire			wr_en,
		output	reg			full,
		input	wire			rd_clk,
		output	reg	[WIDTH-1:0]	dout,
		input	wire			rd_en,
		output	reg			empty
	);

	localparam	ADDR_WIDTH = $clog2(DEPTH);

	reg [WIDTH-1:0]	memory [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0]	wr_ptr;
	reg [ADDR_WIDTH-1:0]	rd_ptr;
	reg [ADDR_WIDTH:0]	count;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			wr_ptr <= 0;
			full <= 0;
			count <= 0;
		end else if (wr_en && !full) begin
			memory[wr_ptr] <= din;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
			if (count == DEPTH - 1)
				full <= 1;
		end
	end

	always @(posedge rd_clk or posedge reset) begin
		if (reset) begin
			rd_ptr <= 0;
			empty <= 1;
		end else if (rd_en && !empty) begin
			dout <= memory[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
			if (count == 0)
				empty <= 1;
		end
	end

	always @(posedge clk) begin
		if (wr_en && !full && !rd_en && empty)
			full <= 0;
		else if (rd_en && !empty && !wr_en && full)
			empty <= 0;
		else if (wr_en && !full && rd_en && !empty) begin
			if (count == DEPTH - 1)
				full <= 1;
			else if (count == 0)
				empty <= 1;
		end
	end

endmodule
