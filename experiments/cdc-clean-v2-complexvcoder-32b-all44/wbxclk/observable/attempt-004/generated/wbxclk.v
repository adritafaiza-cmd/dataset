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

	// Internal signals for FIFOs
	wire	[(AW+DW+DW/8):0]	fifo_wb_to_xclk_wdata;
	wire			fifo_wb_to_xclk_wen;
	wire			fifo_wb_to_xclk_wfull;
	wire			fifo_wb_to_xclk_wempty;
	wire	[(AW+DW+DW/8):0]	fifo_wb_to_xclk_rdata;
	wire			fifo_wb_to_xclk_ren;

	wire	[(DW):0]		fifo_xclk_to_wb_wdata;
	wire			fifo_xclk_to_wb_wen;
	wire			fifo_xclk_to_wb_wfull;
	wire			fifo_xclk_to_wb_wempty;
	wire	[(DW):0]		fifo_xclk_to_wb_rdata;
	wire			fifo_xclk_to_wb_ren;

	// FIFO instances
	fifo_sync #(.WIDTH(AW+DW+DW/8+1), .DEPTH(1 << LGFIFO))
	fifo_wb_to_xclk (
		.clk_wr(i_wb_clk),
		.rst(i_reset),
		.data_wr(fifo_wb_to_xclk_wdata),
		.full(fifo_wb_to_xclk_wfull),
		.empty(fifo_wb_to_xclk_wempty),
		.wr_en(fifo_wb_to_xclk_wen),
		.clk_rd(i_xclk_clk),
		.data_rd(fifo_wb_to_xclk_rdata),
		.rd_en(fifo_wb_to_xclk_ren)
	);

	fifo_sync #(.WIDTH(DW+1), .DEPTH(1 << LGFIFO))
	fifo_xclk_to_wb (
		.clk_wr(i_xclk_clk),
		.rst(i_reset),
		.data_wr(fifo_xclk_to_wb_wdata),
		.full(fifo_xclk_to_wb_wfull),
		.empty(fifo_xclk_to_wb_wempty),
		.wr_en(fifo_xclk_to_wb_wen),
		.clk_rd(i_wb_clk),
		.data_rd(fifo_xclk_to_wb_rdata),
		.rd_en(fifo_xclk_to_wb_ren)
	);

	// Combinational logic for Wishbone side
	always @(*) begin
		fifo_wb_to_xclk_wdata = {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we};
		fifo_wb_to_xclk_wen = i_wb_cyc & i_wb_stb & ~fifo_wb_to_xclk_wfull;
		o_wb_stall = fifo_wb_to_xclk_wfull;

		if (fifo_xclk_to_wb_wempty) begin
			o_wb_ack = 0;
			o_wb_data = 0;
			o_wb_err = 0;
		end else begin
			o_wb_ack = 1;
			o_wb_data = fifo_xclk_to_wb_rdata[(DW-1):0];
			o_wb_err = fifo_xclk_to_wb_rdata[DW];
		end

		fifo_xclk_to_wb_ren = o_wb_ack;
	end

	// Combinational logic for XCLK side
	always @(*) begin
		if (fifo_wb_to_xclk_wempty) begin
			o_xclk_cyc = 0;
			o_xclk_stb = 0;
			o_xclk_we = 0;
			o_xclk_addr = 0;
			o_xclk_data = 0;
			o_xclk_sel = 0;
		end else begin
			o_xclk_cyc = 1;
			o_xclk_stb = ~i_xclk_stall;
			o_xclk_we = fifo_wb_to_xclk_rdata[AW+DW+DW/8];
			o_xclk_addr = fifo_wb_to_xclk_rdata[(AW+DW+DW/8-1):(DW+DW/8)];
			o_xclk_data = fifo_wb_to_xclk_rdata[(DW+DW/8-1):(DW/8)];
			o_xclk_sel = fifo_wb_to_xclk_rdata[(DW/8-1):0];
		end

		fifo_wb_to_xclk_ren = o_xclk_stb & i_xclk_ack;

		fifo_xclk_to_wb_wdata = {i_xclk_data, i_xclk_err};
		fifo_xclk_to_wb_wen = i_xclk_ack & ~fifo_xclk_to_wb_wfull;
	end

endmodule

// FIFO_SYNC module implementation
module fifo_sync #(
		parameter WIDTH = 33,
				DEPTH = 32
	) (
		input	wire			clk_wr, rst,
		input	wire	[WIDTH-1:0]	data_wr,
		output	wire			full,
		output	wire			empty,
		input	wire			wr_en,
		input	wire			clk_rd,
		output	wire	[WIDTH-1:0]	data_rd,
		input	wire			rd_en
	);

	// FIFO memory and pointers
	reg [WIDTH-1:0] mem [DEPTH-1:0];
	reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH):0] count;

	// Write operation
	always @(posedge clk_wr or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			count <= 0;
		end else if (wr_en & ~full) begin
			mem[wr_ptr] <= data_wr;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
		end
	end

	// Read operation
	always @(posedge clk_rd or posedge rst) begin
		if (rst) begin
			rd_ptr <= 0;
			count <= 0;
		end else if (rd_en & ~empty) begin
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
		end
	end

	// FIFO status flags
	assign full = (count == DEPTH);
	assign empty = (count == 0);

	// Data output
	always @(posedge clk_rd or posedge rst) begin
		if (rst)
			data_rd <= 0;
		else if (rd_en & ~empty)
			data_rd <= mem[rd_ptr];
	end

endmodule
