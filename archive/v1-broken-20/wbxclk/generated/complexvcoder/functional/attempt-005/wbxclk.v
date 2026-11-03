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
	reg			i_wb_cyc_reg, i_wb_stb_reg, i_wb_we_reg;
	reg	[(AW-1):0]	i_wb_addr_reg;
	reg	[(DW-1):0]	i_wb_data_reg;
	reg	[(DW/8-1):0]	i_wb_sel_reg;
	wire			o_xclk_cyc_reg, o_xclk_stb_reg, o_xclk_we_reg;
	wire	[(AW-1):0]	o_xclk_addr_reg;
	wire	[(DW-1):0]	o_xclk_data_reg;
	wire	[(DW/8-1):0]	o_xclk_sel_reg;

	// FIFOs
	wire			fifo_wb_cyc, fifo_wb_stb, fifo_wb_we, fifo_xclk_cyc, fifo_xclk_stb, fifo_xclk_we;
	wire	[(AW-1):0]	fifo_wb_addr, fifo_xclk_addr;
	wire	[(DW-1):0]	fifo_wb_data, fifo_xclk_data;
	wire	[(DW/8-1):0]	fifo_wb_sel, fifo_xclk_sel;
	wire			fifo_wb_full, fifo_xclk_full;

	fifo #(.WIDTH(1+AW+DW+(DW/8)), .DEPTH(1<<LGFIFO)) wb_fifo (
		.clk(i_wb_clk),
		.we(i_wb_cyc_reg & i_wb_stb_reg & ~fifo_wb_full),
		.din({i_wb_cyc_reg, i_wb_addr_reg, i_wb_data_reg, i_wb_sel_reg}),
		.full(fifo_wb_full),
		.out(fifo_wb_cyc)
	);

	fifo #(.WIDTH(1+AW+DW+(DW/8)), .DEPTH(1<<LGFIFO)) xclk_fifo (
		.clk(i_xclk_clk),
		.we(i_xclk_cyc_reg & i_xclk_stb_reg & ~fifo_xclk_full),
		.din({i_xclk_cyc_reg, i_xclk_addr_reg, i_xclk_data_reg, i_xclk_sel_reg}),
		.full(fifo_xclk_full),
		.out(fifo_xclk_cyc)
	);

	// Process i_wb_clk domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
			i_wb_cyc_reg <= 0;
			i_wb_stb_reg <= 0;
			i_wb_we_reg <= 0;
			i_wb_addr_reg <= 0;
			i_wb_data_reg <= 0;
			i_wb_sel_reg <= 0;
		end else begin
			i_wb_cyc_reg <= i_wb_cyc;
			i_wb_stb_reg <= i_wb_stb;
			i_wb_we_reg <= i_wb_we;
			i_wb_addr_reg <= i_wb_addr;
			i_wb_data_reg <= i_wb_data;
			i_wb_sel_reg <= i_wb_sel;
			o_wb_stall <= fifo_wb_full;
			if (i_wb_cyc_reg & i_wb_stb_reg & ~fifo_wb_full) begin
				o_wb_ack <= 1;
				o_wb_err <= 0;
			end else begin
				o_wb_ack <= 0;
				o_wb_err <= 0;
			end
		end
	end

	// Process i_xclk_clk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			o_xclk_cyc <= fifo_xclk_cyc;
			o_xclk_stb <= fifo_xclk_stb;
			o_xclk_we <= fifo_xclk_we;
			o_xclk_addr <= fifo_xclk_addr;
			o_xclk_data <= fifo_xclk_data;
			o_xclk_sel <= fifo_xclk_sel;
			if (i_xclk_cyc_reg & i_xclk_stb_reg & ~fifo_xclk_full) begin
				fifo_wb_cyc <= 1;
				fifo_wb_stb <= 1;
				fifo_wb_we <= i_xclk_we_reg;
				fifo_wb_addr <= i_xclk_addr_reg;
				fifo_wb_data <= i_xclk_data_reg;
				fifo_wb_sel <= i_xclk_sel_reg;
			end else begin
				fifo_wb_cyc <= 0;
				fifo_wb_stb <= 0;
				fifo_wb_we <= 0;
				fifo_wb_addr <= 0;
				fifo_wb_data <= 0;
				fifo_wb_sel <= 0;
			end
		end
	end

endmodule
