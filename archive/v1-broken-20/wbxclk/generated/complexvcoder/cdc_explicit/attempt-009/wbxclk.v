module wbxclk #(
	parameter AW = 32,
				DW = 32,
				LGFIFO = 5
) (
		input wire i_wb_clk, i_reset,
		input wire i_wb_cyc, i_wb_stb, i_wb_we,
		input wire [(AW-1):0] i_wb_addr,
		input wire [(DW-1):0] i_wb_data,
		input wire [(DW/8-1):0] i_wb_sel,
		output wire o_wb_stall,
		output reg o_wb_ack,
		output reg [(DW-1):0] o_wb_data,
		output reg o_wb_err,
		input wire i_xclk_clk,
		output reg o_xclk_cyc,
		output reg o_xclk_stb,
		output reg o_xclk_we,
		output reg [(AW-1):0] o_xclk_addr,
		output reg [(DW-1):0] o_xclk_data,
		output reg [(DW/8-1):0] o_xclk_sel,
		input wire i_xclk_stall,
		input wire i_xclk_ack,
		input wire [(DW-1):0] i_xclk_data,
		input wire i_xclk_err
	);

	// Internal signals
	wire wb_to_xclk_valid;
	wire wb_to_xclk_ready;
	wire wb_to_xclk_cyc, wb_to_xclk_stb, wb_to_xclk_we;
	wire [(AW-1):0] wb_to_xclk_addr;
	wire [(DW-1):0] wb_to_xclk_data;
	wire [(DW/8-1):0] wb_to_xclk_sel;

	wire xclk_to_wb_valid;
	wire xclk_to_wb_ready;
	wire xclk_to_wb_cyc, xclk_to_wb_stb, xclk_to_wb_we;
	wire [(AW-1):0] xclk_to_wb_addr;
	wire [(DW-1):0] xclk_to_wb_data;
	wire xclk_to_wb_err;

	// FIFO for Wishbone to XCLK
	wire wb_to_xclk_full;
	wire wb_to_xclk_empty;
	wire wb_to_xclk_wren;
	wire wb_to_xclk_rden;
	wire [(AW+DW+2+DW/8):0] wb_to_xclk_fifo_out;

	// FIFO for XCLK to Wishbone
	wire xclk_to_wb_full;
	wire xclk_to_wb_empty;
	wire xclk_to_wb_wren;
	wire xclk_to_wb_rden;
	wire [(AW+DW+2+DW/8):0] xclk_to_wb_fifo_out;

	// State machine for Wishbone to XCLK
	wire wb_to_xclk_start;
	wire wb_to_xclk_done;
	wire wb_to_xclk_error;

	// State machine for XCLK to Wishbone
	wire xclk_to_wb_start;
	wire xclk_to_wb_done;
	wire xclk_to_wb_error;

	// Wishbone to XCLK FIFO
	fifo #(.WIDTH(AW+DW+2+DW/8), .DEPTH(1 << LGFIFO)) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wren(wb_to_xclk_wren),
		.rden(wb_to_xclk_rden),
		.data({wb_to_xclk_valid, wb_to_xclk_cyc, wb_to_xclk_stb, wb_to_xclk_we, wb_to_xclk_addr, wb_to_xclk_data, wb_to_xclk_sel}),
		.full(wb_to_xclk_full),
		.empty(wb_to_xclk_empty),
		.q(wb_to_xclk_fifo_out)
	);

	// XCLK to Wishbone FIFO
	fifo #(.WIDTH(AW+DW+2+DW/8), .DEPTH(1 << LGFIFO)) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wren(xclk_to_wb_wren),
		.rden(xclk_to_wb_rden),
		.data({xclk_to_wb_valid, xclk_to_wb_cyc, xclk_to_wb_stb, xclk_to_wb_we, xclk_to_wb_addr, xclk_to_wb_data, xclk_to_wb_err}),
		.full(xclk_to_wb_full),
		.empty(xclk_to_wb_empty),
		.q(xclk_to_wb_fifo_out)
	);

	// Wishbone to XCLK state machine
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			wb_to_xclk_valid <= 0;
			wb_to_xclk_ready <= 0;
			wb_to_xclk_cyc <= 0;
			wb_to_xclk_stb <= 0;
			wb_to_xclk_we <= 0;
			wb_to_xclk_addr <= 0;
			wb_to_xclk_data <= 0;
			wb_to_xclk_sel <= 0;
		end else begin
			o_wb_stall <= wb_to_xclk_full;
			o_wb_ack <= wb_to_xclk_valid && wb_to_xclk_ready;
			o_wb_data <= wb_to_xclk_fifo_out[(DW+AW+2+DW/8-1):(AW+2)];
			o_wb_err <= wb_to_xclk_fifo_out[(AW+2)];
			wb_to_xclk_valid <= i_wb_cyc && i_wb_stb && !wb_to_xclk_full;
			wb_to_xclk_ready <= !wb_to_xclk_full;
			wb_to_xclk_cyc <= wb_to_xclk_valid;
			wb_to_xclk_stb <= wb_to_xclk_valid;
			wb_to_xclk_we <= wb_to_xclk_valid && i_wb_we;
			wb_to_xclk_addr <= i_wb_addr;
			wb_to_xclk_data <= i_wb_data;
			wb_to_xclk_sel <= i_wb_sel;
		end
	end

	// XCLK to Wishbone state machine
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_to_wb_cyc <= 0;
			xclk_to_wb_stb <= 0;
			xclk_to_wb_we <= 0;
			xclk_to_wb_addr <= 0;
			xclk_to_wb_data <= 0;
			xclk_to_wb_sel <= 0;
			xclk_to_wb_ack <= 0;
			xclk_to_wb_err <= 0;
			xclk_to_wb_valid <= 0;
			xclk_to_wb_ready <= 0;
		end else begin
			xclk_to_wb_cyc <= xclk_to_wb_valid && !xclk_to_wb_full;
			xclk_to_wb_stb <= xclk_to_wb_valid && !xclk_to_wb_full;
			xclk_to_wb_we <= xclk_to_wb_valid && !xclk_to_wb_full;
			xclk_to_wb_addr <= xclk_to_wb_fifo_out[(AW+DW+2+DW/8-1):(AW+2)];
			xclk_to_wb_data <= xclk_to_wb_fifo_out[(DW+AW+1):(AW+2)];
			xclk_to_wb_sel <= xclk_to_wb_fifo_out[(AW+1):AW];
			xclk_to_wb_ack <= i_xclk_ack;
			xclk_to_wb_err <= i_xclk_err;
			xclk_to_wb_valid <= i_xclk_stall && !xclk_to_wb_full;
			xclk_to_wb_ready <= !xclk_to_wb_full;
		end
	end

	// Connect FIFO outputs to state machines
	assign wb_to_xclk_rden = wb_to_xclk_valid && wb_to_xclk_ready;
	assign xclk_to_wb_wren = xclk_to_wb_valid && !xclk_to_wb_full;

endmodule
