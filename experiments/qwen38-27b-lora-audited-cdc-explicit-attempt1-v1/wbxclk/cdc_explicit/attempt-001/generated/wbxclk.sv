// SPDX-License-Identifier: MIT
// Copyright (c) 2025, The Regents of the University of Colorado,
//                        Denver, CO USa.
// All rights reserved.
//
// Author: Steven K. Reinhardt <steven.reinhardt@colorado.edu>

`include "wbxclk.vh"

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

	// Wishbone request FIFO
	wbreqfifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) u_wbreqfifo (
		.i_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.i_wb_sel(i_wb_sel),
		.o_wb_stall(o_wb_stall),
		.o_xclk_clk(i_xclk_clk),
		.o_xclk_cyc(o_xclk_cyc),
		.o_xclk_stb(o_xclk_stb),
		.o_xclk_we(o_xclk_we),
		.o_xclk_addr(o_xclk_addr),
		.o_xclk_data(o_xclk_data),
		.o_xclk_sel(o_xclk_sel),
		.i_xclk_stall(i_xclk_stall)
	);

	// Wishbone response FIFO
	wbrespfifo #(
		.DW(DW),
		.LGFIFO(LGFIFO)
	) u_wbrespfifo (
		.i_clk(i_wb_clk),
		.i_reset(i_reset),
		.o_wb_ack(o_wb_ack),
		.o_wb_data(o_wb_data),
		.o_wb_err(o_wb_err),
		.i_xclk_clk(i_xclk_clk),
		.i_xclk_ack(i_xclk_ack),
		.i_xclk_data(i_xclk_data),
		.i_xclk_err(i_xclk_err)
	);

endmodule