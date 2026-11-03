module wbxclk #(
	parameter AW = 32,
			 DW = 32,
			 LGFIFO = 5
) (
		input wire			i_wb_clk, i_reset,
		input wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input wire	[(AW-1):0]	i_wb_addr,
		input wire	[(DW-1):0]	i_wb_data,
		input wire	[(DW/8-1):0]	i_wb_sel,
		output wire			o_wb_stall,
		output reg			o_wb_ack,
		output reg	[(DW-1):0]	o_wb_data,
		output reg			o_wb_err,
		input wire			i_xclk_clk,
		output reg			o_xclk_cyc,
		output reg			o_xclk_stb,
		output reg			o_xclk_we,
		output reg	[(AW-1):0]	o_xclk_addr,
		output reg	[(DW-1):0]	o_xclk_data,
		output reg	[(DW/8-1):0]	o_xclk_sel,
		input wire			i_xclk_stall,
		input wire			i_xclk_ack,
		input wire	[(DW-1):0]	i_xclk_data,
		input wire			i_xclk_err
	);

	// Internal signals
	reg wb_to_xclk_fifo_wr_en, wb_to_xclk_fifo_rd_en;
	reg wb_to_xclk_fifo_full, wb_to_xclk_fifo_empty;
	reg xclk_to_wb_fifo_wr_en, xclk_to_wb_fifo_rd_en;
	reg xclk_to_wb_fifo_full, xclk_to_wb_fifo_empty;

	// FIFO instances
	fifo #(
		.WIDTH(DW),
		.DEPTH(LGFIFO)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.rst(i_reset),
		.wr_en(wb_to_xclk_fifo_wr_en),
		.rd_en(wb_to_xclk_fifo_rd_en),
		.din(i_wb_data),
		.dout(o_xclk_data),
		.full(wb_to_xclk_fifo_full),
		.empty(wb_to_xclk_fifo_empty)
	);

	fifo #(
		.WIDTH(DW),
		.DEPTH(LGFIFO)
	) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.rst(i_reset),
		.wr_en(xclk_to_wb_fifo_wr_en),
		.rd_en(xclk_to_wb_fifo_rd_en),
		.din(i_xclk_data),
		.dout(o_wb_data),
		.full(xclk_to_wb_fifo_full),
		.empty(xclk_to_wb_fifo_empty)
	);

	// Wishbone to Xclk FIFO control
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			o_wb_ack <= (wb_to_xclk_fifo_empty && !wb_to_xclk_fifo_full);
			o_wb_err <= (i_xclk_err || (wb_to_xclk_fifo_empty && i_wb_we));
			o_xclk_cyc <= (i_wb_cyc && !wb_to_xclk_fifo_full);
			o_xclk_stb <= (o_xclk_cyc && !i_xclk_stall);
			o_xclk_we <= (i_wb_we && o_xclk_stb);
			o_xclk_addr <= (i_wb_addr & ~i_xclk_stall);
			o_xclk_data <= (i_wb_data & ~i_xclk_stall);
			o_xclk_sel <= (i_wb_sel & ~i_xclk_stall);
		end
	end

	// Xclk to Wishbone FIFO control
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 0;
		end else begin
			o_wb_stall <= (xclk_to_wb_fifo_full);
		end
	end

	// Connect FIFO control signals
	assign wb_to_xclk_fifo_wr_en = (i_wb_cyc && !i_wb_stall);
	assign wb_to_xclk_fifo_rd_en = (i_xclk_stb && !i_xclk_stall);
	assign xclk_to_wb_fifo_wr_en = (i_xclk_cyc && !i_xclk_stall);
	assign xclk_to_wb_fifo_rd_en = (i_wb_stb && !i_wb_stall);

endmodule
