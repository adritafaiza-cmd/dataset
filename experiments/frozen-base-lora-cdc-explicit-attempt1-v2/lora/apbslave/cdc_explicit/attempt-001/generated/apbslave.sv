// =============================================================================
// Copyright (c) 2019-2020 Xilinx, Inc.  All rights reserved.
// SPDX-License-Identifier: MIT
// =============================================================================

`default_nettype none

`include "apbslave.vh"

module	apbslave #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH,
		localparam	APBLSB = $clog2(C_APB_DATA_WIDTH)-3
	) (
		input	wire			PCLK, PRESETn,
		input	wire			PSEL,
		input	wire			PENABLE,
		output	reg			PREADY,
		input	wire	[AW-1:0]	PADDR,
		input	wire			PWRITE,
		input	wire	[DW-1:0]	PWDATA,
		input	wire	[DW/8-1:0]	PWSTRB,
		input	wire	[2:0]		PPROT,
		output	reg	[DW-1:0]	PRDATA,
		output	wire			PSLVERR
	);

	// =============================================================================
	// Registers
	// =============================================================================

	reg	[DW-1:0]		regs [0:3];

	// =============================================================================
	// Combinational logic
	// =============================================================================

	wire	[AW-APBLSB-1:0]	addr = PADDR[AW-1:APBLSB];

	// =============================================================================
	// Sequential logic
	// =============================================================================

	initial begin
		PREADY = 1'b0;
		PRDATA = {DW{1'b0}};
		regs[0] = {DW{1'b0}};
		regs[1] = {DW{1'b0}};
		regs[2] = {DW{1'b0}};
		regs[3] = {DW{1'b0}};
	end

	always @(posedge PCLK, negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 1'b0;
		end else begin
			if (PSEL && !PENABLE) begin
				PREADY <= 1'b1;
			end else begin
				PREADY <= 1'b0;
			end
		end
	end

	always @(posedge PCLK) begin
		if (PSEL && PENABLE && PWRITE) begin
			regs[addr] <= PWDATA;
		end
	end

	always @(posedge PCLK) begin
		if (PSEL && !PENABLE) begin
			PRDATA <= regs[addr];
		end
	end

	assign PSLVERR = 1'b0;

endmodule

`default_nettype wire