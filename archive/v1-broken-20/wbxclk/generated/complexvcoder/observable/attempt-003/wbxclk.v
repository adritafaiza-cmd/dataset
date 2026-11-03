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

	// Internal signals for state management
	reg			wb_to_xclk_cyc_reg;
	reg			wb_to_xclk_stb_reg;
	reg			wb_to_xclk_we_reg;
	reg	[(AW-1):0]	wb_to_xclk_addr_reg;
	reg	[(DW-1):0]	wb_to_xclk_data_reg;
	reg	[(DW/8-1):0]	wb_to_xclk_sel_reg;
	wire			wb_to_xclk_stall;
	wire			wb_to_xclk_ack;
	wire	[(DW-1):0]	wb_to_xclk_data_out;

	reg			xclk_to_wb_cyc_reg;
	reg			xclk_to_wb_stb_reg;
	reg			xclk_to_wb_we_reg;
	reg	[(AW-1):0]	xclk_to_wb_addr_reg;
	reg	[(DW-1):0]	xclk_to_wb_data_reg;
	reg	[(DW/8-1):0]	xclk_to_wb_sel_reg;
	wire			xclk_to_wb_stall;
	wire			xclk_to_wb_ack;
	wire	[(DW-1):0]	xclk_to_wb_data_out;

	// Instantiate submodules
	wb_to_xclk wb_to_xclk_inst (
		.clk(i_wb_clk),
		.reset(i_reset),
		.cyc(i_wb_cyc),
		.stb(i_wb_stb),
		.we(i_wb_we),
		.addr(i_wb_addr),
		.data(i_wb_data),
		.sel(i_wb_sel),
		.stall(wb_to_xclk_stall),
		.ack(wb_to_xclk_ack),
		.data_out(wb_to_xclk_data_out)
	);

	xclk_to_wb xclk_to_wb_inst (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.cyc(i_xclk_cyc),
		.stb(i_xclk_stb),
		.we(i_xclk_we),
		.addr(i_xclk_addr),
		.data(i_xclk_data),
		.sel(i_xclk_sel),
		.stall(i_xclk_stall),
		.ack(i_xclk_ack),
		.data_out(i_xclk_data_out)
	);

	// Clock domain crossing for outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b0;
			o_wb_ack <= 1'b0;
			o_wb_data <= 0;
			o_wb_err <= 1'b0;
		end else begin
			o_wb_stall <= wb_to_xclk_stall;
			o_wb_ack <= wb_to_xclk_ack;
			o_wb_data <= wb_to_xclk_data_out;
			o_wb_err <= wb_to_xclk_err;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			o_xclk_cyc <= xclk_to_wb_cyc_reg;
			o_xclk_stb <= xclk_to_wb_stb_reg;
			o_xclk_we <= xclk_to_wb_we_reg;
			o_xclk_addr <= xclk_to_wb_addr_reg;
			o_xclk_data <= xclk_to_wb_data_reg;
			o_xclk_sel <= xclk_to_wb_sel_reg;
		end
	end

	// Pipelining logic for Wishbone to Xclk
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_to_xclk_cyc_reg <= 1'b0;
			wb_to_xclk_stb_reg <= 1'b0;
			wb_to_xclk_we_reg <= 1'b0;
			wb_to_xclk_addr_reg <= 0;
			wb_to_xclk_data_reg <= 0;
			wb_to_xclk_sel_reg <= 0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !wb_to_xclk_stall) begin
				wb_to_xclk_cyc_reg <= i_wb_cyc;
				wb_to_xclk_stb_reg <= i_wb_stb;
				wb_to_xclk_we_reg <= i_wb_we;
				wb_to_xclk_addr_reg <= i_wb_addr;
				wb_to_xclk_data_reg <= i_wb_data;
				wb_to_xclk_sel_reg <= i_wb_sel;
			end
		end
	end

	// Pipelining logic for Xclk to Wishbone
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_to_wb_cyc_reg <= 1'b0;
			xclk_to_wb_stb_reg <= 1'b0;
			xclk_to_wb_we_reg <= 1'b0;
			xclk_to_wb_addr_reg <= 0;
			xclk_to_wb_data_reg <= 0;
			xclk_to_wb_sel_reg <= 0;
		end else begin
			if (i_xclk_cyc && i_xclk_stb && !xclk_to_wb_stall) begin
				xclk_to_wb_cyc_reg <= i_xclk_cyc;
				xclk_to_wb_stb_reg <= i_xclk_stb;
				xclk_to_wb_we_reg <= i_xclk_we;
				xclk_to_wb_addr_reg <= i_xclk_addr;
				xclk_to_wb_data_reg <= i_xclk_data;
				xclk_to_wb_sel_reg <= i_xclk_sel;
			end
		end
	end

endmodule
