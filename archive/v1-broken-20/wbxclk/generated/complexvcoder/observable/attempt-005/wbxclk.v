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

reg [AW-1:0] wb_addr_reg;
reg [DW-1:0] wb_data_reg;
reg [(DW/8-1):0] wb_sel_reg;
reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
wire wb_ack, wb_err;
reg wb_stall;
reg [AW-1:0] xclk_addr_reg;
reg [DW-1:0] xclk_data_reg;
reg [(DW/8-1):0] xclk_sel_reg;
reg xclk_cyc_reg, xclk_stb_reg, xclk_we_reg;
wire xclk_ack, xclk_err;
reg xclk_stall;

wire wb_to_xclk_valid, wb_to_xclk_ready;
wire wb_to_xclk_cyc, wb_to_xclk_stb, wb_to_xclk_we, wb_to_xclk_stall, wb_to_xclk_err;
wire wb_to_xclk_addr [AW-1:0], wb_to_xclk_data [DW-1:0], wb_to_xclk_sel [(DW/8-1):0];
wire xclk_to_wb_valid, xclk_to_wb_ready;
wire xclk_to_wb_cyc, xclk_to_wb_stb, xclk_to_wb_we, xclk_to_wb_stall, xclk_to_wb_err;
wire xclk_to_wb_addr [AW-1:0], xclk_to_wb_data [DW-1:0], xclk_to_wb_sel [(DW/8-1):0];

// FIFO for wb_to_xclk
fifo #(.WIDTH(AW + DW + (DW/8) + 3), .DEPTH(LGFIFO)) wb_to_xclk_fifo (
	.clk(i_wb_clk), .rst(i_reset), .we(wb_to_xclk_valid), .re(wb_to_xclk_ready), .din({wb_to_xclk_addr, wb_to_xclk_data, wb_to_xclk_sel, wb_to_xclk_cyc, wb_to_xclk_stb, wb_to_xclk_we}), .dout({wb_to_xclk_addr, wb_to_xclk_data, wb_to_xclk_sel, wb_to_xclk_cyc, wb_to_xclk_stb, wb_to_xclk_we}), .full(wb_to_xclk_valid), .empty(wb_to_xclk_ready)
);

// FIFO for xclk_to_wb
fifo #(.WIDTH(AW + DW + (DW/8) + 3), .DEPTH(LGFIFO)) xclk_to_wb_fifo (
	.clk(i_xclk_clk), .rst(i_reset), .we(xclk_to_wb_valid), .re(xclk_to_wb_ready), .din({xclk_to_wb_addr, xclk_to_wb_data, xclk_to_wb_sel, xclk_to_wb_cyc, xclk_to_wb_stb, xclk_to_wb_we}), .dout({xclk_to_wb_addr, xclk_to_wb_data, xclk_to_wb_sel, xclk_to_wb_cyc, xclk_to_wb_stb, xclk_to_wb_we}), .full(xclk_to_wb_valid), .empty(xclk_to_wb_ready)
);

// WB to XCLK bridge logic
always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		wb_addr_reg <= 0;
		wb_data_reg <= 0;
		wb_sel_reg <= 0;
		wb_cyc_reg <= 0;
		wb_stb_reg <= 0;
		wb_we_reg <= 0;
		wb_stall <= 0;
		o_wb_ack <= 0;
		o_wb_data <= 0;
		o_wb_err <= 0;
	end else begin
		if (i_wb_cyc && i_wb_stb && !wb_stall) begin
			wb_addr_reg <= i_wb_addr;
			wb_data_reg <= i_wb_data;
			wb_sel_reg <= i_wb_sel;
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg <= i_wb_we;
			wb_stall <= i_xclk_stall;
		end
		if (wb_to_xclk_valid && wb_to_xclk_ready) begin
			o_xclk_cyc <= wb_to_xclk_cyc;
			o_xclk_stb <= wb_to_xclk_stb;
			o_xclk_we <= wb_to_xclk_we;
			o_xclk_addr <= wb_to_xclk_addr;
			o_xclk_data <= wb_to_xclk_data;
			o_xclk_sel <= wb_to_xclk_sel;
			wb_to_xclk_ready <= 0;
		end
		if (xclk_to_wb_valid && xclk_to_wb_ready) begin
			o_wb_ack <= xclk_to_wb_ack;
			o_wb_data <= xclk_to_wb_data;
			o_wb_err <= xclk_to_wb_err;
			xclk_to_wb_ready <= 0;
		end
	end
end

// XCLK to WB bridge logic
always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		xclk_addr_reg <= 0;
		xclk_data_reg <= 0;
		xclk_sel_reg <= 0;
		xclk_cyc_reg <= 0;
		xclk_stb_reg <= 0;
		xclk_we_reg <= 0;
		xclk_stall <= 0;
		o_xclk_ack <= 0;
		o_xclk_data <= 0;
		o_xclk_err <= 0;
	end else begin
		if (i_xclk_cyc && i_xclk_stb && !xclk_stall) begin
			xclk_addr_reg <= i_xclk_addr;
			xclk_data_reg <= i_xclk_data;
			xclk_sel_reg <= i_xclk_sel;
			xclk_cyc_reg <= i_xclk_cyc;
			xclk_stb_reg <= i_xclk_stb;
			xclk_we_reg <= i_xclk_we;
			xclk_stall <= i_wb_stall;
		end
		if (xclk_to_wb_valid && xclk_to_wb_ready) begin
			o_wb_cyc <= xclk_to_wb_cyc;
			o_wb_stb <= xclk_to_wb_stb;
			o_wb_we <= xclk_to_wb_we;
			o_wb_addr <= xclk_to_wb_addr;
			o_wb_data <= xclk_to_wb_data;
			o_wb_sel <= xclk_to_wb_sel;
			xclk_to_wb_ready <= 0;
		end
		if (wb_to_xclk_valid && wb_to_xclk_ready) begin
			o_xclk_ack <= wb_to_xclk_ack;
			o_xclk_data <= wb_to_xclk_data;
			o_xclk_err <= wb_to_xclk_err;
			wb_to_xclk_ready <= 0;
		end
	end
end

// Connect WB to XCLK FIFO
always @(posedge i_wb_clk) begin
	if (i_reset) begin
		wb_to_xclk_valid <= 0;
	end else begin
		wb_to_xclk_valid <= wb_cyc_reg && wb_stb_reg;
		wb_to_xclk_addr <= wb_addr_reg;
		wb_to_xclk_data <= wb_data_reg;
		wb_to_xclk_sel <= wb_sel_reg;
		wb_to_xclk_cyc <= wb_cyc_reg;
		wb_to_xclk_stb <= wb_stb_reg;
		wb_to_xclk_we <= wb_we_reg;
		wb_to_xclk_stall <= wb_stall;
		wb_to_xclk_err <= wb_err;
		wb_to_xclk_ready <= wb_to_xclk_fifo.we;
	end
end

// Connect XCLK to WB FIFO
always @(posedge i_xclk_clk) begin
	if (i_reset) begin
		xclk_to_wb_valid <= 0;
	end else begin
		xclk_to_wb_valid <= i_xclk_cyc && i_xclk_stb;
		xclk_to_wb_addr <= i_xclk_addr;
		xclk_to_wb_data <= i_xclk_data;
		xclk_to_wb_sel <= i_xclk_sel;
		xclk_to_wb_cyc <= i_xclk_cyc;
		xclk_to_wb_stb <= i_xclk_stb;
		xclk_to_wb_we <= i_xclk_we;
		xclk_to_wb_stall <= i_xclk_stall;
		xclk_to_wb_err <= i_xclk_err;
		xclk_to_wb_ready <= xclk_to_wb_fifo.we;
	end
end

endmodule
