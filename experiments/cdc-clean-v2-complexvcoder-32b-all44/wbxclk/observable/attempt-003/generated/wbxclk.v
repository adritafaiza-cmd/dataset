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

	// Internal FIFO signals
	wire [70:0] xclk_fifo_data_out;
	wire xclk_fifo_empty;
	wire [34:0] wb_fifo_data_out;
	wire wb_fifo_empty;

	// FIFO instances
	fifo_sync #(
		.WIDTH(71),
		.DEPTH(1<<LGFIFO)
	) wb_to_xclk_fifo (
		.clk_wr(i_wb_clk),
		.clk_rd(i_xclk_clk),
		.rst(i_reset),
		.data_in({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
		.full(o_wb_stall),
		.empty(xclk_fifo_empty),
		.data_out(xclk_fifo_data_out)
	);

	fifo_sync #(
		.WIDTH(35),
		.DEPTH(1<<LGFIFO)
	) xclk_to_wb_fifo (
		.clk_wr(i_xclk_clk),
		.clk_rd(i_wb_clk),
		.rst(i_reset),
		.data_in({i_xclk_ack, i_xclk_err, i_xclk_data}),
		.full(),
		.empty(wb_fifo_empty),
		.data_out(wb_fifo_data_out)
	);

	// Assign outputs from FIFOs
	assign o_xclk_cyc = xclk_fifo_data_out[70];
	assign o_xclk_stb = xclk_fifo_data_out[69];
	assign o_xclk_we = xclk_fifo_data_out[68];
	assign o_xclk_addr = xclk_fifo_data_out[67:36];
	assign o_xclk_data = xclk_fifo_data_out[35:4];
	assign o_xclk_sel = xclk_fifo_data_out[3:0];

	assign o_wb_ack = wb_fifo_data_out[34];
	assign o_wb_err = wb_fifo_data_out[33];
	assign o_wb_data = wb_fifo_data_out[32:1];

	// Control logic for FIFOs
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (!xclk_fifo_empty && !i_xclk_stall) begin
				o_xclk_cyc <= xclk_fifo_data_out[70];
				o_xclk_stb <= xclk_fifo_data_out[69];
				o_xclk_we <= xclk_fifo_data_out[68];
				o_xclk_addr <= xclk_fifo_data_out[67:36];
				o_xclk_data <= xclk_fifo_data_out[35:4];
				o_xclk_sel <= xclk_fifo_data_out[3:0];
			end else if (i_xclk_stall) begin
				o_xclk_cyc <= o_xclk_cyc;
				o_xclk_stb <= o_xclk_stb;
				o_xclk_we <= o_xclk_we;
				o_xclk_addr <= o_xclk_addr;
				o_xclk_data <= o_xclk_data;
				o_xclk_sel <= o_xclk_sel;
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

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end else begin
			if (!wb_fifo_empty) begin
				o_wb_ack <= wb_fifo_data_out[34];
				o_wb_err <= wb_fifo_data_out[33];
				o_wb_data <= wb_fifo_data_out[32:1];
			end else begin
				o_wb_ack <= 0;
				o_wb_err <= 0;
				o_wb_data <= 0;
			end
		end
	end

endmodule

module fifo_sync #(
		parameter WIDTH=8,
				DEPTH=32
	) (
		input wire clk_wr,
		input wire clk_rd,
		input wire rst,
		input wire [WIDTH-1:0] data_in,
		output wire full,
		output wire empty,
		output reg [WIDTH-1:0] data_out
	);

	localparam ADDR_WIDTH = $clog2(DEPTH);
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] count;

	// Write pointer and memory write
	always @(posedge clk_wr or posedge rst) begin
		if (rst) begin
			wr_ptr <= 0;
			count <= 0;
		end else if (count < DEPTH) begin
			mem[wr_ptr] <= data_in;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
		end
	end

	// Read pointer and memory read
	always @(posedge clk_rd or posedge rst) begin
		if (rst) begin
			rd_ptr <= 0;
			count <= 0;
		end else if (count > 0) begin
			data_out <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
		end
	end

	assign full = (count == DEPTH);
	assign empty = (count == 0);

endmodule
