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
	wire wb_req_valid;
	wire wb_req_ready;
	wire [(AW + DW + DW/8 + 1 - 1):0] wb_req_data;
	wire xclk_req_valid;
	wire xclk_req_ready;
	wire [(AW + DW + DW/8 + 1 - 1):0] xclk_req_data;
	wire xclk_resp_valid;
	wire xclk_resp_ready;
	wire [(DW + 1 - 1):0] xclk_resp_data;
	wire wb_resp_valid;
	wire wb_resp_ready;
	wire [(DW + 1 - 1):0] wb_resp_data;

	// FIFO connections
	wire wb_to_xclk_fifo_full;
	wire wb_to_xclk_fifo_empty;
	wire xclk_to_wb_fifo_full;
	wire xclk_to_wb_fifo_empty;

	// FIFOs
	fifo_sync #(
		.WIDTH(AW + DW + DW/8 + 1),
		.DEPTH(1 << LGFIFO)
	) wb_to_xclk_fifo (
		.clk_wr(i_wb_clk),
		.rst_wr(i_reset),
		.data_in(wb_req_data),
		.data_in_valid(wb_req_valid),
		.data_in_ready(wb_req_ready),
		.clk_rd(i_xclk_clk),
		.rst_rd(i_reset),
		.data_out(xclk_req_data),
		.data_out_valid(xclk_req_valid),
		.data_out_ready(xclk_req_ready),
		.full(wb_to_xclk_fifo_full),
		.empty(wb_to_xclk_fifo_empty)
	);

	fifo_sync #(
		.WIDTH(DW + 1),
		.DEPTH(1 << LGFIFO)
	) xclk_to_wb_fifo (
		.clk_wr(i_xclk_clk),
		.rst_wr(i_reset),
		.data_in(xclk_resp_data),
		.data_in_valid(xclk_resp_valid),
		.data_in_ready(xclk_resp_ready),
		.clk_rd(i_wb_clk),
		.rst_rd(i_reset),
		.data_out(wb_resp_data),
		.data_out_valid(wb_resp_valid),
		.data_out_ready(wb_resp_ready),
		.full(xclk_to_wb_fifo_full),
		.empty(xclk_to_wb_fifo_empty)
	);

	// Wishbone request handling
	assign wb_req_valid = i_wb_cyc & i_wb_stb & wb_req_ready;
	assign wb_req_ready = !wb_to_xclk_fifo_full;
	assign wb_req_data = {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we};

	// Output stall signal
	assign o_wb_stall = wb_to_xclk_fifo_full;

	// xclk request handling
	assign xclk_req_ready = !i_xclk_stall & !wb_to_xclk_fifo_empty;

	// xclk response handling
	assign xclk_resp_valid = i_xclk_ack | i_xclk_err;
	assign xclk_resp_ready = !xclk_to_wb_fifo_full;
	assign xclk_resp_data = {i_xclk_data, i_xclk_err};

	// Wishbone response handling
	assign wb_resp_ready = !xclk_to_wb_fifo_empty;

	// Output Wishbone signals
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (wb_resp_valid && wb_resp_ready) begin
			o_wb_ack <= 1;
			o_wb_data <= wb_resp_data[(DW-1):0];
			o_wb_err <= wb_resp_data[DW];
		end else begin
			o_wb_ack <= 0;
		end
	end

	// Output xclk signals
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else if (xclk_req_valid && xclk_req_ready) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= xclk_req_data[(AW + DW + DW/8 + 1 - 1)];
			o_xclk_addr <= xclk_req_data[(AW + DW + DW/8 + 1 - 2) : (DW + DW/8 + 1 - 1)];
			o_xclk_data <= xclk_req_data[(DW + DW/8 + 1 - 2) : (DW/8 + 1 - 1)];
			o_xclk_sel <= xclk_req_data[(DW/8 + 1 - 2) : 0];
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end
	end
endmodule

module fifo_sync #(
	parameter WIDTH = 32,
	parameter DEPTH = 32
) (
	input wire clk_wr,
	input wire rst_wr,
	input wire [WIDTH-1:0] data_in,
	input wire data_in_valid,
	output reg data_in_ready,
	input wire clk_rd,
	input wire rst_rd,
	output reg [WIDTH-1:0] data_out,
	output reg data_out_valid,
	input wire data_out_ready,
	output reg full,
	output reg empty
);

	// FIFO memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [$clog2(DEPTH)-1:0] wr_ptr;
	reg [$clog2(DEPTH)-1:0] rd_ptr;
	reg [$clog2(DEPTH):0] count;

	// Write side
	always @(posedge clk_wr or posedge rst_wr) begin
		if (rst_wr) begin
			wr_ptr <= 0;
			count <= 0;
			data_in_ready <= 1;
			full <= 0;
		end else if (data_in_valid && data_in_ready) begin
			mem[wr_ptr] <= data_in;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
			full <= (count == DEPTH);
			data_in_ready <= (count < DEPTH);
		end
	end

	// Read side
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			rd_ptr <= 0;
			count <= 0;
			data_out_valid <= 0;
			empty <= 1;
		end else if (data_out_valid && data_out_ready) begin
			data_out <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
			empty <= (count == 0);
			data_out_valid <= (count > 0);
		end
	end

endmodule
