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
	wire wb_to_xclk_fifo_in_valid;
	wire wb_to_xclk_fifo_out_valid;
	wire [AW-1:0] wb_to_xclk_fifo_out_addr;
	wire [DW-1:0] wb_to_xclk_fifo_out_data;
	wire [DW/8-1:0] wb_to_xclk_fifo_out_sel;
	wire wb_to_xclk_fifo_out_ready;

	wire xclk_to_wb_fifo_in_valid;
	wire xclk_to_wb_fifo_out_valid;
	wire [AW-1:0] xclk_to_wb_fifo_out_addr;
	wire [DW-1:0] xclk_to_wb_fifo_out_data;
	wire [DW/8-1:0] xclk_to_wb_fifo_out_sel;
	wire xclk_to_wb_fifo_out_ready;

	// FIFOs
	wishbone_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.rst(i_reset),
		.din_valid(wb_to_xclk_fifo_in_valid),
		.din_addr(i_wb_addr),
		.din_data(i_wb_data),
		.din_sel(i_wb_sel),
		.din_ready(wb_to_xclk_fifo_out_ready),
		.out_valid(wb_to_xclk_fifo_out_valid),
		.out_addr(wb_to_xclk_fifo_out_addr),
		.out_data(wb_to_xclk_fifo_out_data),
		.out_sel(wb_to_xclk_fifo_out_sel)
	);

	wishbone_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) xclk_to_wb_fifo (
		.clk(i_xclk_clk),
		.rst(i_reset),
		.din_valid(xclk_to_wb_fifo_in_valid),
		.din_addr(xclk_to_wb_fifo_out_addr),
		.din_data(xclk_to_wb_fifo_out_data),
		.din_sel(xclk_to_wb_fifo_out_sel),
		.din_ready(xclk_to_wb_fifo_out_ready),
		.out_valid(xclk_to_wb_fifo_out_valid),
		.out_addr(xclk_to_wb_fifo_out_addr),
		.out_data(xclk_to_wb_fifo_out_data),
		.out_sel(xclk_to_wb_fifo_out_sel)
	);

	// Logic to forward transactions
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b0;
			o_wb_ack <= 1'b0;
			o_wb_data <= 0;
			o_wb_err <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
				wb_to_xclk_fifo_in_valid <= 1'b1;
				o_wb_stall <= 1'b1;
			end else begin
				wb_to_xclk_fifo_in_valid <= 1'b0;
				o_wb_stall <= 1'b0;
			end

			if (wb_to_xclk_fifo_out_valid && !i_xclk_stall) begin
				xclk_to_wb_fifo_in_valid <= 1'b1;
			end else begin
				xclk_to_wb_fifo_in_valid <= 1'b0;
			end

			if (xclk_to_wb_fifo_out_valid && i_xclk_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= xclk_to_wb_fifo_out_data;
				o_wb_err <= xclk_to_wb_fifo_out_data[DW-1];
			end else begin
				o_wb_ack <= 1'b0;
				o_wb_data <= 0;
				o_wb_err <= 1'b0;
			end

			if (wb_to_xclk_fifo_out_valid && !i_xclk_stall) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_wb_we;
				o_xclk_addr <= wb_to_xclk_fifo_out_addr;
				o_xclk_data <= wb_to_xclk_fifo_out_data;
				o_xclk_sel <= wb_to_xclk_fifo_out_sel;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Acknowledge and error handling
	assign wb_to_xclk_fifo_out_ready = !i_xclk_stall && i_xclk_ack;
	assign xclk_to_wb_fifo_out_ready = !o_wb_stall && o_wb_ack;

endmodule
