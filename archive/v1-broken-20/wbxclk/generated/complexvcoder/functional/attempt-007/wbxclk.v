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

	wire			wb_crossbar_i_wb_clk, wb_crossbar_i_reset;
	wire			wb_crossbar_i_wb_cyc, wb_crossbar_i_wb_stb, wb_crossbar_i_wb_we;
	wire	[(AW-1):0]	wb_crossbar_i_wb_addr;
	wire	[(DW-1):0]	wb_crossbar_i_wb_data;
	wire	[(DW/8-1):0]	wb_crossbar_i_wb_sel;
	wire			wb_crossbar_o_wb_stall, wb_crossbar_o_wb_ack;
	wire	[(DW-1):0]	wb_crossbar_o_wb_data;
	wire			wb_crossbar_o_wb_err;
	wire			wb_crossbar_o_xclk_cyc, wb_crossbar_o_xclk_stb, wb_crossbar_o_xclk_we;
	wire	[(AW-1):0]	wb_crossbar_o_xclk_addr;
	wire	[(DW-1):0]	wb_crossbar_o_xclk_data;
	wire	[(DW/8-1):0]	wb_crossbar_o_xclk_sel;
	wire			wb_crossbar_i_xclk_stall, wb_crossbar_i_xclk_ack;
	wire	[(DW-1):0]	wb_crossbar_i_xclk_data;
	wire			wb_crossbar_i_xclk_err;

	wb_crossbar wb_crossbar_inst (
		.i_wb_clk(wb_crossbar_i_wb_clk),
		.i_reset(wb_crossbar_i_reset),
		.i_wb_cyc(wb_crossbar_i_wb_cyc),
		.i_wb_stb(wb_crossbar_i_wb_stb),
		.i_wb_we(wb_crossbar_i_wb_we),
		.i_wb_addr(wb_crossbar_i_wb_addr),
		.i_wb_data(wb_crossbar_i_wb_data),
		.i_wb_sel(wb_crossbar_i_wb_sel),
		.o_wb_stall(wb_crossbar_o_wb_stall),
		.o_wb_ack(wb_crossbar_o_wb_ack),
		.o_wb_data(wb_crossbar_o_wb_data),
		.o_wb_err(wb_crossbar_o_wb_err),
		.o_xclk_cyc(wb_crossbar_o_xclk_cyc),
		.o_xclk_stb(wb_crossbar_o_xclk_stb),
		.o_xclk_we(wb_crossbar_o_xclk_we),
		.o_xclk_addr(wb_crossbar_o_xclk_addr),
		.o_xclk_data(wb_crossbar_o_xclk_data),
		.o_xclk_sel(wb_crossbar_o_xclk_sel),
		.i_xclk_stall(wb_crossbar_i_xclk_stall),
		.i_xclk_ack(wb_crossbar_i_xclk_ack),
		.i_xclk_data(wb_crossbar_i_xclk_data),
		.i_xclk_err(wb_crossbar_i_xclk_err)
	);

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b0;
			o_wb_ack <= 1'b0;
			o_wb_data <= 32'b0;
			o_wb_err <= 1'b0;
		end else begin
			o_wb_stall <= wb_crossbar_o_wb_stall;
			o_wb_ack <= wb_crossbar_o_wb_ack;
			o_wb_data <= wb_crossbar_o_wb_data;
			o_wb_err <= wb_crossbar_o_wb_err;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 32'b0;
			o_xclk_data <= 32'b0;
			o_xclk_sel <= 4'b0;
		end else begin
			o_xclk_cyc <= wb_crossbar_o_xclk_cyc;
			o_xclk_stb <= wb_crossbar_o_xclk_stb;
			o_xclk_we <= wb_crossbar_o_xclk_we;
			o_xclk_addr <= wb_crossbar_o_xclk_addr;
			o_xclk_data <= wb_crossbar_o_xclk_data;
			o_xclk_sel <= wb_crossbar_o_xclk_sel;
		end
	end

endmodule
