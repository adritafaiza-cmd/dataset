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

reg [(AW-1):0] wb_addr;
reg [(DW-1):0] wb_data;
reg [(DW/8-1):0] wb_sel;
reg wb_we;
reg [LGFIFO-1:0] wb_cnt;
reg [LGFIFO-1:0] xclk_cnt;
reg xclk_cyc;
reg xclk_stb;
reg xclk_we;
reg [(AW-1):0] xclk_addr;
reg [(DW-1):0] xclk_data;
reg [(DW/8-1):0] xclk_sel;
reg xclk_ack;
reg [(DW-1):0] xclk_rdata;
reg xclk_err;

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_ack <= 1'b0;
		o_wb_data <= {(DW){1'b0}};
		o_wb_err <= 1'b0;
		wb_cnt <= {(LGFIFO){1'b0}};
	end else if (i_wb_cyc && i_wb_stb &&!o_wb_stall) begin
		wb_addr <= i_wb_addr;
		wb_data <= i_wb_data;
		wb_sel <= i_wb_sel;
		wb_we <= i_wb_we;
		wb_cnt <= wb_cnt + 1'b1;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		o_xclk_cyc <= 1'b0;
		o_xclk_stb <= 1'b0;
		o_xclk_we <= 1'b0;
		o_xclk_addr <= {(AW){1'b0}};
		o_xclk_data <= {(DW){1'b0}};
		o_xclk_sel <= {(DW/8){1'b0}};
		xclk_cnt <= {(LGFIFO){1'b0}};
		xclk_ack <= 1'b0;
		xclk_rdata <= {(DW){1'b0}};
		xclk_err <= 1'b0;
	end else if (wb_cnt > xclk_cnt &&!i_xclk_stall) begin
		o_xclk_cyc <= 1'b1;
		o_xclk_stb <= 1'b1;
		o_xclk_we <= wb_we;
		o_xclk_addr <= wb_addr;
		o_xclk_data <= wb_data;
		o_xclk_sel <= wb_sel;
		xclk_cnt <= xclk_cnt + 1'b1;
	end else if (i_xclk_ack) begin
		xclk_ack <= 1'b1;
		xclk_rdata <= i_xclk_data;
		xclk_err <= i_xclk_err;
		wb_cnt <= wb_cnt - 1'b1;
	end
end

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_stall <= 1'b0;
		o_wb_ack <= 1'b0;
		o_wb_data <= {(DW){1'b0}};
		o_wb_err <= 1'b0;
	end else if (xclk_ack) begin
		o_wb_ack <= 1'b1;
		o_wb_data <= xclk_rdata;
		o_wb_err <= xclk_err;
		xclk_ack <= 1'b0;
	end else if (wb_cnt == {(LGFIFO){1'b1}}) begin
		o_wb_stall <= 1'b1;
	end else begin
		o_wb_stall <= 1'b0;
	end
end

assign o_wb_stall = (wb_cnt == {(LGFIFO){1'b1}});

endmodule
