The following Verilog code implements a pipelined Wishbone clock-domain bridge:

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

	reg [1:0] wb_state, xclk_state;
	reg [LGFIFO:0] wb_fifo_count, xclk_fifo_count;
	reg [DW-1:0] wb_fifo_data, xclk_fifo_data;
	reg wb_fifo_we, xclk_fifo_we;
	reg wb_fifo_re, xclk_fifo_re;

	// Wishbone to Xilinx clock domain bridge
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_state <= 2'b00;
			wb_fifo_count <= 0;
			wb_fifo_we <= 0;
			wb_fifo_re <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end else begin
			case (wb_state)
				2'b00: begin // Idle
					if (i_wb_cyc && i_wb_stb) begin
						wb_fifo_data <= i_wb_data;
						wb_fifo_we <= 1;
						wb_fifo_count <= wb_fifo_count + 1;
						wb_state <= 2'b01;
					end
				end
				2'b01: begin // Write
					if (i_wb_cyc && i_wb_stb) begin
						wb_fifo_data <= i_wb_data;
						wb_fifo_we <= 1;
						wb_fifo_count <= wb_fifo_count + 1;
					end else begin
						wb_fifo_we <= 0;
						wb_fifo_re <= 1;
						wb_state <= 2'b10;
					end
				end
				2'b10: begin // Read
					if (i_wb_cyc && i_wb_stb) begin
						wb_fifo_data <= i_wb_data;
						wb_fifo_we <= 1;
						wb_fifo_count <= wb_fifo_count + 1;
					end else begin
						wb_fifo_re <= 0;
						wb_state <= 2'b00;
					end
				end
			endcase
		end
	end

	// Xilinx clock domain to Wishbone bridge
	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			xclk_state <= 2'b00;
			xclk_fifo_count <= 0;
			xclk_fifo_we <= 0;
			xclk_fifo_re <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			case (xclk_state)
				2'b00: begin // Idle
					if (wb_fifo_count > 0 && !i_xclk_stall) begin
						xclk_fifo_data <= wb_fifo_data;
						xclk_fifo_we <= 1;
						xclk_fifo_count <= xclk_fifo_count + 1;
						xclk_state <= 2'b01;
					end
				end
				2'b01: begin // Write
					if (wb_fifo_count > 0 && !i_xclk_stall) begin
						xclk_fifo_data <= wb_fifo_data;
						xclk_fifo_we <= 1;
						xclk_fifo_count <= xclk_fifo_count + 1;
					end else begin
						xclk_fifo_we <= 0;
						xclk_fifo_re <= 1;
						xclk_state <= 2'b10;
					end
				end
				2'b10: begin // Read
					if (wb_fifo_count > 0 && !i_xclk_stall) begin
						xclk_fifo_data <= wb_fifo_data;
						xclk_fifo_we <= 1;
						xclk_fifo_count <= xclk_fifo_count + 1;
					end else begin
						xclk_fifo_re <= 0;
						xclk_state <= 2'b00;
					end
				end
			endcase

			if (xclk_fifo_count > 0 && !i_xclk_stall) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= i_wb_we;
				o_xclk_addr <= i_wb_addr;
				o_xclk_data <= xclk_fifo_data;
				o_xclk_sel <= i_wb_sel;
				xclk_fifo_re <= 1;
				xclk_fifo_count <= xclk_fifo_count - 1;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Acknowledge and error signals
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end else begin
			if (o_xclk_cyc && o_xclk_stb) begin
				o_wb_ack <= i_xclk_ack;
				o_wb_err <= i_xclk_err;
				o_wb_data <= i_xclk_data;
			end
		end
	end

	// Stall signal
	assign o_wb_stall = (wb_fifo_count == (1 << LGFIFO));

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

module testbench();
    reg clk;
    reg reset;

    wire [31:0] instruction_out;
    wire [31:0] instruction_addr;
    wire [31:0] data_addr;
    wire [31:0] data_out;
    wire [31:0] data_in;
    wire [3:0] data_mask;
    wire data_write;
    wire [31:0] interrupt_vector;
    wire interrupt_pending;

    wire [31:0] debug_instruction_addr;
    wire [31:0] debug_instruction_out;
    wire [31:0] debug_data_addr;
    wire [31:0] debug_data_out;
    wire [31:0] debug_data_in;
    wire [3:0] debug_data_mask;
    wire debug_data_write;

    wire [31:0] debug_registers[0:31];
    wire [31:0] debug_pc;
    wire debug_interrupt_pending;
    wire debug_interrupt_vector;

    wire [31:0] debug_watch_addr;
    wire [31:0] debug_watch_value;
    wire debug_watch_read;
    wire debug_watch_write;

    wire [31:0] debug_breakpoint_addr;
    wire debug_breakpoint_hit;

    wire [31:0] debug_watch_count;
    wire [31:0] debug_breakpoint_count;

    wire [31:0] debug_watch_addr_in;
    wire [31:0] debug_watch_value_in;
    wire debug_watch_read_in;
    wire debug_watch_write_in;

    wire [31:0] debug_breakpoint_addr_in;

    wire [31:0] debug_instruction_count;
    wire [31:0] debug_cycle_count;

    wire [31:0] debug_watch_count_in;
    wire [31:0] debug_breakpoint_count_in;

    wire [31:0] debug_watch_addr_in_in;
    wire [31:0] debug_watch_value_in_in;
    wire debug_watch_read_in_in;
    wire debug_watch_write_in_in;

    wire [31:0] debug_breakpoint_addr_in_in;

    wire [31:0] debug_instruction_count_in;
    wire [31:0] debug_cycle_count_in;

    wire [31:0] debug_watch_count_in_in;
    wire [31:0] debug_breakpoint_count_in_in;

    wire [31:0] debug_watch_addr_out;
    wire [31:0] debug_watch_value_out;
    wire debug_watch_read_out;
    wire debug_watch_write_out;

    wire [31:0] debug_breakpoint_addr_out;

    wire [31:0] debug_instruction_count_out;
    wire [31:0] debug_cycle_count_out;

    wire [31:0] debug_watch_count_out;
    wire [31:0] debug_breakpoint_count_out;

    wire [31:0] debug_watch_addr_out_out;
    wire [31:0] debug_watch_value_out_out;
    wire debug_watch_read_out_out;
    wire debug_watch_write_out_out;

    wire [31:0] debug_breakpoint_addr_out_out;

    wire [31:0] debug_instruction_count_out_out;
    wire [31:0] debug_cycle_count_out_out;

    wire [31:0] debug_watch_count_out_out;
    wire [31:0] debug_breakpoint_count_out_out;

    wire [31:0] debug_watch_addr_out_out_out;
    wire [31:0] debug_watch_value_out_out_out;
    wire debug_watch_read_out_out_out;
    wire debug_watch_write_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out;

    wire [31:0] debug_watch_count_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out;
    wire debug_watch_read_out_out_out_out;
    wire debug_watch_write_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_write_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_breakpoint_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_instruction_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_cycle_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_breakpoint_count_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;

    wire [31:0] debug_watch_addr_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire [31:0] debug_watch_value_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out;
    wire debug_watch_read_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out_out