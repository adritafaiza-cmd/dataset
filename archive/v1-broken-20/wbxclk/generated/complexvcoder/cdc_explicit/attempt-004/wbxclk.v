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
	reg [AW-1:0] wb_addr_reg;
	reg [DW-1:0] wb_data_reg;
	reg [DW/8-1:0] wb_sel_reg;
	reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
	reg wb_ack_reg, wb_err_reg;
	reg xclk_cyc_reg, xclk_stb_reg, xclk_we_reg;
	wire xclk_data_reg;
	wire xclk_err_reg;

	// FIFO for data transfer
	fifo #(.WIDTH(DW), .DEPTH(1 << LGFIFO)) wb_xclk_fifo (
		.clk(i_wb_clk),
		.rst(i_reset),
		.wen(wb_cyc_reg && !i_xclk_stall),
		.wdata(wb_data_reg),
		.full(o_wb_stall),
		.ren(xclk_cyc_reg && !i_xclk_stall),
		.rdata(xclk_data_reg),
		.empty(wb_ack_reg)
	);

	// Mux for data selection
	assign o_xclk_data = wb_we_reg ? wb_data_reg : xclk_data_reg;

	// Mux for error indication
	assign o_xclk_err = wb_we_reg ? wb_err_reg : xclk_err_reg;

	// Logic to handle Wishbone to XCLK forwarding
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_cyc_reg <= 0;
			wb_stb_reg <= 0;
			wb_we_reg <= 0;
			wb_addr_reg <= 0;
			wb_data_reg <= 0;
			wb_sel_reg <= 0;
			wb_ack_reg <= 0;
			wb_err_reg <= 0;
			xclk_cyc_reg <= 0;
			xclk_stb_reg <= 0;
			xclk_we_reg <= 0;
		end else begin
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg <= i_wb_we;
			wb_addr_reg <= i_wb_addr;
			wb_data_reg <= i_wb_data;
			wb_sel_reg <= i_wb_sel;
			wb_ack_reg <= i_xclk_ack;
			wb_err_reg <= i_xclk_err;

			if (i_wb_cyc && i_wb_stb && !i_xclk_stall) begin
				xclk_cyc_reg <= 1;
				xclk_stb_reg <= 1;
				xclk_we_reg <= i_wb_we;
			end else begin
				xclk_cyc_reg <= 0;
				xclk_stb_reg <= 0;
				xclk_we_reg <= 0;
			end
		end
	end

	// Logic to handle XCLK to Wishbone forwarding
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
		end else begin
			o_wb_ack <= xclk_ack_reg;
		end
	end

endmodule
