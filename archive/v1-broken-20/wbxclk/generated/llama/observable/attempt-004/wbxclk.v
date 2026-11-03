module wbxclk #(
	parameter AW = 32,
	parameter DW = 32,
	parameter LGFIFO = 5
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

reg [(AW-1):0] wb_addr;
reg [(DW-1):0] wb_data;
reg [(DW/8-1):0] wb_sel;
reg wb_we;

reg [(AW-1):0] xclk_addr;
reg [(DW-1):0] xclk_data;
reg [(DW/8-1):0] xclk_sel;
reg xclk_we;

reg [LGFIFO-1:0] wb_cnt;
reg [LGFIFO-1:0] xclk_cnt;

reg wb_empty;
reg xclk_full;

reg wb_valid;
reg xclk_valid;

reg [LGFIFO-1:0] wb_out_cnt;
reg [LGFIFO-1:0] xclk_in_cnt;

reg wb_stall;
reg xclk_stall;

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_ack <= 0;
		o_wb_data <= 0;
		o_wb_err <= 0;
		wb_cnt <= 0;
		wb_empty <= 1;
		wb_valid <= 0;
		wb_stall <= 0;
	end else if (i_wb_cyc && i_wb_stb &&!wb_stall) begin
		wb_addr <= i_wb_addr;
		wb_data <= i_wb_data;
		wb_sel <= i_wb_sel;
		wb_we <= i_wb_we;
		wb_valid <= 1;
		wb_cnt <= wb_cnt + 1;
		wb_empty <= 0;
	end else if (wb_valid &&!wb_stall) begin
		wb_valid <= 0;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		o_xclk_cyc <= 0;
		o_xclk_stb <= 0;
		o_xclk_we <= 0;
		o_xclk_addr <= 0;
		o_xclk_data <= 0;
		o_xclk_sel <= 0;
		xclk_cnt <= 0;
		xclk_full <= 0;
		xclk_valid <= 0;
		xclk_stall <= 0;
	end else if (xclk_valid &&!xclk_stall) begin
		o_xclk_cyc <= 1;
		o_xclk_stb <= 1;
		o_xclk_we <= xclk_we;
		o_xclk_addr <= xclk_addr;
		o_xclk_data <= xclk_data;
		o_xclk_sel <= xclk_sel;
		xclk_valid <= 0;
		xclk_cnt <= xclk_cnt + 1;
		xclk_full <= 1;
	end else if (i_xclk_ack && xclk_full) begin
		xclk_full <= 0;
		xclk_cnt <= xclk_cnt - 1;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_stall <= 0;
	end else if (wb_cnt == (1 << LGFIFO) - 1) begin
		o_wb_stall <= 1;
	end else if (wb_cnt == 0) begin
		o_wb_stall <= 0;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		xclk_stall <= 0;
	end else if (xclk_cnt == (1 << LGFIFO) - 1) begin
		xclk_stall <= 1;
	end else if (xclk_cnt == 0) begin
		xclk_stall <= 0;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		wb_out_cnt <= 0;
	end else if (wb_valid &&!wb_stall) begin
		wb_out_cnt <= wb_out_cnt + 1;
	end else if (wb_out_cnt > 0 &&!wb_stall) begin
		wb_out_cnt <= wb_out_cnt - 1;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		xclk_in_cnt <= 0;
	end else if (xclk_valid &&!xclk_stall) begin
		xclk_in_cnt <= xclk_in_cnt + 1;
	end else if (xclk_in_cnt > 0 &&!xclk_stall) begin
		xclk_in_cnt <= xclk_in_cnt - 1;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_ack <= 0;
		o_wb_data <= 0;
		o_wb_err <= 0;
	end else if (i_xclk_ack &&!wb_empty) begin
		o_wb_ack <= 1;
		o_wb_data <= i_xclk_data;
		o_wb_err <= i_xclk_err;
		wb_cnt <= wb_cnt - 1;
		wb_empty <= 1;
	end else if (o_wb_ack) begin
		o_wb_ack <= 0;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		wb_stall <= 0;
	end else if (xclk_full) begin
		wb_stall <= 1;
	end else if (!xclk_full) begin
		wb_stall <= 0;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		xclk_stall <= 0;
	end else if (wb_cnt == (1 << LGFIFO) - 1) begin
		xclk_stall <= 1;
	end else if (wb_cnt < (1 << LGFIFO) - 1) begin
		xclk_stall <= 0;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		xclk_addr <= 0;
		xclk_data <= 0;
		xclk_sel <= 0;
		xclk_we <= 0;
	end else if (wb_valid &&!wb_stall) begin
		xclk_addr <= wb_addr;
		xclk_data <= wb_data;
		xclk_sel <= wb_sel;
		xclk_we <= wb_we;
		xclk_valid <= 1;
	end else if (xclk_valid &&!xclk_stall) begin
		xclk_valid <= 0;
	end
end

endmodule
