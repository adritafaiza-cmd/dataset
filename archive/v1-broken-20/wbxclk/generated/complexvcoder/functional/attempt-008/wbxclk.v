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
	wire wb_cyc_sync, wb_stb_sync, wb_we_sync;
	wire [(AW-1):0] wb_addr_sync;
	wire [(DW-1):0] wb_data_sync;
	wire [(DW/8-1):0] wb_sel_sync;
	wire wb_stall_sync, wb_ack_sync, wb_err_sync;
	wire xclk_cyc_sync, xclk_stb_sync, xclk_we_sync;
	wire [(AW-1):0] xclk_addr_sync;
	wire [(DW-1):0] xclk_data_sync;
	wire [(DW/8-1):0] xclk_sel_sync;
	wire xclk_stall_sync, xclk_ack_sync, xclk_err_sync;

	// Synchronizers
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_cyc_sync <= 1'b0;
			wb_stb_sync <= 1'b0;
			wb_we_sync <= 1'b0;
			wb_addr_sync <= {(AW){1'b0}};
			wb_data_sync <= {(DW){1'b0}};
			wb_sel_sync <= {(DW/8){1'b0}};
			wb_stall_sync <= 1'b0;
			wb_ack_sync <= 1'b0;
			wb_err_sync <= 1'b0;
		end else begin
			wb_cyc_sync <= i_wb_cyc;
			wb_stb_sync <= i_wb_stb;
			wb_we_sync <= i_wb_we;
			wb_addr_sync <= i_wb_addr;
			wb_data_sync <= i_wb_data;
			wb_sel_sync <= i_wb_sel;
			wb_stall_sync <= i_xclk_stall;
			wb_ack_sync <= i_xclk_ack;
			wb_err_sync <= i_xclk_err;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_cyc_sync <= 1'b0;
			xclk_stb_sync <= 1'b0;
			xclk_we_sync <= 1'b0;
			xclk_addr_sync <= {(AW){1'b0}};
			xclk_data_sync <= {(DW){1'b0}};
			xclk_sel_sync <= {(DW/8){1'b0}};
			xclk_stall_sync <= 1'b0;
			xclk_ack_sync <= 1'b0;
			xclk_err_sync <= 1'b0;
		end else begin
			xclk_cyc_sync <= i_xclk_cyc;
			xclk_stb_sync <= i_xclk_stb;
			xclk_we_sync <= i_xclk_we;
			xclk_addr_sync <= i_xclk_addr;
			xclk_data_sync <= i_xclk_data;
			xclk_sel_sync <= i_xclk_sel;
			xclk_stall_sync <= i_wb_stall;
			xclk_ack_sync <= i_wb_ack;
			xclk_err_sync <= i_wb_err;
		end
	end

	// Main logic
	o_wb_stall <= xclk_stall_sync;
	o_wb_ack <= wb_ack_sync;
	o_wb_data <= wb_data_sync;
	o_wb_err <= wb_err_sync;

	o_xclk_cyc <= wb_cyc_sync;
	o_xclk_stb <= wb_stb_sync;
	o_xclk_we <= wb_we_sync;
	o_xclk_addr <= wb_addr_sync;
	o_xclk_data <= wb_data_sync;
	o_xclk_sel <= wb_sel_sync;

endmodule
