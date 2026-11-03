Sure, here is the complete Verilog code for the pipelined Wishbone clock-domain bridge:

```
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

	reg [LGFIFO-1:0] wb_fifo_count;
	reg [LGFIFO-1:0] xclk_fifo_count;
	reg [LGFIFO-1:0] wb_fifo_count_next;
	reg [LGFIFO-1:0] xclk_fifo_count_next;

	reg [DW-1:0] wb_data_reg;
	reg [DW-1:0] xclk_data_reg;
	reg [DW-1:0] wb_data_reg_next;
	reg [DW-1:0] xclk_data_reg_next;

	reg [AW-1:0] wb_addr_reg;
	reg [AW-1:0] xclk_addr_reg;
	reg [AW-1:0] wb_addr_reg_next;
	reg [AW-1:0] xclk_addr_reg_next;

	reg wb_we_reg;
	reg xclk_we_reg;
	reg wb_we_reg_next;
	reg xclk_we_reg_next;

	reg wb_stb_reg;
	reg xclk_stb_reg;
	reg wb_stb_reg_next;
	reg xclk_stb_reg_next;

	reg wb_cyc_reg;
	reg xclk_cyc_reg;
	reg wb_cyc_reg_next;
	reg xclk_cyc_reg_next;

	reg wb_sel_reg;
	reg xclk_sel_reg;
	reg wb_sel_reg_next;
	reg xclk_sel_reg_next;

	reg wb_ack_reg;
	reg xclk_ack_reg;
	reg wb_ack_reg_next;
	reg xclk_ack_reg_next;

	reg wb_err_reg;
	reg xclk_err_reg;
	reg wb_err_reg_next;
	reg xclk_err_reg_next;

	reg wb_stall_reg;
	reg xclk_stall_reg;
	reg wb_stall_reg_next;
	reg xclk_stall_reg_next;

	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_fifo_count <= 0;
			wb_data_reg <= 0;
			wb_addr_reg <= 0;
			wb_we_reg <= 0;
			wb_stb_reg <= 0;
			wb_cyc_reg <= 0;
			wb_sel_reg <= 0;
			wb_ack_reg <= 0;
			wb_err_reg <= 0;
			wb_stall_reg <= 0;
		end else begin
			wb_fifo_count <= wb_fifo_count_next;
			wb_data_reg <= wb_data_reg_next;
			wb_addr_reg <= wb_addr_reg_next;
			wb_we_reg <= wb_we_reg_next;
			wb_stb_reg <= wb_stb_reg_next;
			wb_cyc_reg <= wb_cyc_reg_next;
			wb_sel_reg <= wb_sel_reg_next;
			wb_ack_reg <= wb_ack_reg_next;
			wb_err_reg <= wb_err_reg_next;
			wb_stall_reg <= wb_stall_reg_next;
		end
	end

	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			xclk_fifo_count <= 0;
			xclk_data_reg <= 0;
			xclk_addr_reg <= 0;
			xclk_we_reg <= 0;
			xclk_stb_reg <= 0;
			xclk_cyc_reg <= 0;
			xclk_sel_reg <= 0;
			xclk_ack_reg <= 0;
			xclk_err_reg <= 0;
			xclk_stall_reg <= 0;
		end else begin
			xclk_fifo_count <= xclk_fifo_count_next;
			xclk_data_reg <= xclk_data_reg_next;
			xclk_addr_reg <= xclk_addr_reg_next;
			xclk_we_reg <= xclk_we_reg_next;
			xclk_stb_reg <= xclk_stb_reg_next;
			xclk_cyc_reg <= xclk_cyc_reg_next;
			xclk_sel_reg <= xclk_sel_reg_next;
			xclk_ack_reg <= xclk_ack_reg_next;
			xclk_err_reg <= xclk_err_reg_next;
			xclk_stall_reg <= xclk_stall_reg_next;
		end
	end

	always @(*) begin
		wb_fifo_count_next = wb_fifo_count;
		xclk_fifo_count_next = xclk_fifo_count;

		wb_data_reg_next = wb_data_reg;
		xclk_data_reg_next = xclk_data_reg;

		wb_addr_reg_next = wb_addr_reg;
		xclk_addr_reg_next = xclk_addr_reg;

		wb_we_reg_next = wb_we_reg;
		xclk_we_reg_next = xclk_we_reg;

		wb_stb_reg_next = wb_stb_reg;
		xclk_stb_reg_next = xclk_stb_reg;

		wb_cyc_reg_next = wb_cyc_reg;
		xclk_cyc_reg_next = xclk_cyc_reg;

		wb_sel_reg_next = wb_sel_reg;
		xclk_sel_reg_next = xclk_sel_reg;

		wb_ack_reg_next = wb_ack_reg;
		xclk_ack_reg_next = xclk_ack_reg;

		wb_err_reg_next = wb_err_reg;
		xclk_err_reg_next = xclk_err_reg;

		wb_stall_reg_next = wb_stall_reg;
		xclk_stall_reg_next = xclk_stall_reg;

		if (i_wb_cyc && !wb_stall_reg) begin
			wb_fifo_count_next = wb_fifo_count + 1;
			wb_data_reg_next = i_wb_data;
			wb_addr_reg_next = i_wb_addr;
			wb_we_reg_next = i_wb_we;
			wb_stb_reg_next = 1;
			wb_cyc_reg_next = 1;
			wb_sel_reg_next = i_wb_sel;
			wb_ack_reg_next = 0;
			wb_err_reg_next = 0;
			wb_stall_reg_next = (wb_fifo_count == (1 << LGFIFO));
		end else if (wb_stb_reg && !i_wb_stb) begin
			wb_fifo_count_next = wb_fifo_count - 1;
			wb_stb_reg_next = 0;
			wb_cyc_reg_next = 0;
			wb_ack_reg_next = 1;
			wb_err_reg_next = 0;
			wb_stall_reg_next = 0;
		end else if (wb_stb_reg && i_wb_stb) begin
			wb_stb_reg_next = 1;
			wb_cyc_reg_next = 1;
			wb_ack_reg_next = 0;
			wb_err_reg_next = 0;
			wb_stall_reg_next = 0;
		end

		if (i_xclk_ack && !xclk_stall_reg) begin
			xclk_fifo_count_next = xclk_fifo_count + 1;
			xclk_data_reg_next = i_xclk_data;
			xclk_addr_reg_next = i_xclk_addr;
			xclk_we_reg_next = i_xclk_we;
			xclk_stb_reg_next = 1;
			xclk_cyc_reg_next = 1;
			xclk_sel_reg_next = i_xclk_sel;
			xclk_ack_reg_next = 0;
			xclk_err_reg_next = 0;
			xclk_stall_reg_next = (xclk_fifo_count == (1 << LGFIFO));
		end else if (xclk_stb_reg && !i_xclk_stb) begin
			xclk_fifo_count_next = xclk_fifo_count - 1;
			xclk_stb_reg_next = 0;
			xclk_cyc_reg_next = 0;
			xclk_ack_reg_next = 1;
			xclk_err_reg_next = 0;
			xclk_stall_reg_next = 0;
		end else if (xclk_stb_reg && i_xclk_stb) begin
			xclk_stb_reg_next = 1;
			xclk_cyc_reg_next = 1;
			xclk_ack_reg_next = 0;
			xclk_err_reg_next = 0;
			xclk_stall_reg_next = 0;
		end

		o_wb_stall = wb_stall_reg;
		o_wb_ack = wb_ack_reg;
		o_wb_data = wb_data_reg;
		o_wb_err = wb_err_reg;

		o_xclk_cyc = xclk_cyc_reg;
		o_xclk_stb = xclk_stb_reg;
		o_xclk_we = xclk_we_reg;
		o_xclk_addr = xclk_addr_reg;
		o_xclk_data = xclk_data_reg;
		o_xclk_sel = xclk_sel_reg;
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

`include "defines.sv"

module cpu_tb();
    reg clk = 0;
    reg reset = 1;
    wire [31:0] instruction_out;
    wire [31:0] instruction_addr_out;
    wire [31:0] data_addr_out;
    wire [31:0] data_out;
    wire [31:0] data_in;
    wire [3:0] data_mask;
    wire data_write;
    wire [31:0] data_in_reg;
    wire [31:0] data_out_reg;
    wire [31:0] data_addr_reg;
    wire [3:0] data_mask_reg;
    wire data_write_reg;
    wire [31:0] instruction_addr_reg;
    wire [31:0] instruction_out_reg;
    wire [31:0] data_out_reg_reg;
    wire [31:0] data_in_reg_reg;
    wire [31:0] data_addr_reg_reg;
    wire [3:0] data_mask_reg_reg;
    wire data_write_reg_reg;
    wire [31:0] data_in_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg;
    wire data_write_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_addr_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [3:0] data_mask_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire data_write_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_in_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0] data_out_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    wire [31:0