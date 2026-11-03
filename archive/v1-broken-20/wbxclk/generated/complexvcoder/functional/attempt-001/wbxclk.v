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

reg [AW-1:0] wb_addr_reg, xclk_addr_reg;
reg [DW-1:0] wb_data_reg, xclk_data_reg;
reg [DW/8-1:0] wb_sel_reg, xclk_sel_reg;
reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
reg xclk_cyc_reg, xclk_stb_reg, xclk_we_reg;
reg o_wb_stall_reg;
reg o_xclk_cyc_reg, o_xclk_stb_reg, o_xclk_we_reg;
reg o_wb_ack_reg, o_xclk_ack_reg;
reg o_wb_err_reg, o_xclk_err_reg;

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		wb_addr_reg <= 0;
		wb_data_reg <= 0;
		wb_sel_reg <= 0;
		wb_cyc_reg <= 0;
		wb_stb_reg <= 0;
		wb_we_reg <= 0;
		xclk_cyc_reg <= 0;
		xclk_stb_reg <= 0;
		xclk_we_reg <= 0;
		o_wb_stall_reg <= 0;
		o_xclk_cyc_reg <= 0;
		o_xclk_stb_reg <= 0;
		o_xclk_we_reg <= 0;
		o_wb_ack_reg <= 0;
		o_xclk_ack_reg <= 0;
		o_wb_err_reg <= 0;
	end else begin
		if (i_wb_cyc && i_wb_stb && !i_wb_we) begin
			wb_addr_reg <= i_wb_addr;
			wb_data_reg <= i_wb_data;
			wb_sel_reg <= i_wb_sel;
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg <= i_wb_we;
		end

		if (i_wb_cyc && i_wb_stb && i_wb_we) begin
			wb_addr_reg <= i_wb_addr;
			wb_data_reg <= i_wb_data;
			wb_sel_reg <= i_wb_sel;
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg <= i_wb_we;
		end

		if (i_xclk_ack) begin
			o_wb_ack_reg <= 1;
			o_wb_err_reg <= i_xclk_err;
			o_wb_data_reg <= i_xclk_data;
		end else begin
			o_wb_ack_reg <= 0;
			o_wb_err_reg <= 0;
			o_wb_data_reg <= 0;
		end

		if (i_xclk_stall) begin
			o_wb_stall_reg <= 1;
		end else begin
			o_wb_stall_reg <= 0;
		end

		if (!i_xclk_stall) begin
			o_xclk_cyc_reg <= wb_cyc_reg;
			o_xclk_stb_reg <= wb_stb_reg;
			o_xclk_we_reg <= wb_we_reg;
			o_xclk_addr_reg <= wb_addr_reg;
			o_xclk_data_reg <= wb_data_reg;
			o_xclk_sel_reg <= wb_sel_reg;
		end
	end
end

assign o_wb_stall = o_wb_stall_reg;
assign o_wb_ack = o_wb_ack_reg;
assign o_wb_data = o_wb_data_reg;
assign o_wb_err = o_wb_err_reg;
assign o_xclk_cyc = o_xclk_cyc_reg;
assign o_xclk_stb = o_xclk_stb_reg;
assign o_xclk_we = o_xclk_we_reg;
assign o_xclk_addr = o_xclk_addr_reg;
assign o_xclk_data = o_xclk_data_reg;
assign o_xclk_sel = o_xclk_sel_reg;

endmodule
