// =============================================================================
// Copyright (C) 2018-2022 Xilinx, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
// =============================================================================

`timescale 1ns / 1ps

(* ASYNC_RESETS = "S_AXI_ARESETN" *)
module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// Local Parameters
	// =============================================================================

	localparam integer C_S_AXI_FIFO_DEPTH = 2**LGFIFO;
	localparam integer C_S_AXI_FIFO_PTR_WIDTH = LGFIFO;
	localparam integer C_S_AXI_FIFO_FULL_THRESHOLD = C_S_AXI_FIFO_DEPTH-1;
	localparam integer C_S_AXI_FIFO_ALMOST_FULL_THRESHOLD = C_S_AXI_FIFO_DEPTH-2;
	localparam integer C_S_AXI_FIFO_EMPTY_THRESHOLD = 0;
	localparam integer C_S_AXI_FIFO_ALMOST_EMPTY_THRESHOLD = 1;
	localparam integer C_S_AXI_FIFO_DATA_WIDTH = C_S_AXI_DATA_WIDTH + 1;
	localparam integer C_S_AXI_FIFO_ADDR_WIDTH = C_S_AXI_FIFO_PTR_WIDTH;

	// =============================================================================
	// Signals
	// =============================================================================

	wire [C_S_AXI_FIFO_DATA_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_DIN;
	wire [C_S_AXI_FIFO_DATA_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_DOUT;
	wire [C_S_AXI_FIFO_DATA_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_DIN;
	wire [C_S_AXI_FIFO_DATA_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_DOUT;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RDEN;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RDADDR;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WRADDR;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RDEN;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RDADDR;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WRADDR;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_COUNT;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_COUNT;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_COUNT;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_COUNT;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_ALMOST_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_ALMOST_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_ALMOST_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_ALMOST_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_ALMOST_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_ALMOST_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_ALMOST_EMPTY;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_ALMOST_FULL;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_EN;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_EN;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_CLK;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_WR_RST;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_CLK;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_WR_RST;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_CLK;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_WDATA_FIFO_RD_RST;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_CLK;
	wire [C_S_AXI_FIFO_ADDR_WIDTH-1 : 0]	S_AXI_RDATA_FIFO_RD_RST;

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock Converter
	// =============================================================================

	// =============================================================================
	// AXI Clock