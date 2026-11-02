// =============================================================================
// Copyright (C) 2019-2024  Synopsys, Inc.
//
// This program is the confidential and proprietary property of Synopsys Inc.
// ("Synopsys") and is protected under copyright laws and international treaty
// provisions. The program may not be downloaded, copied, distributed,
// displayed, modified, transmitted or used in any way without the express
// written permission of Synopsys.
// =============================================================================

`include "async_bidir_ramif_fifo.vh"

`ifdef SYNTHESIS
`else
`include "async_bidir_ramif_fifo.vh"
`endif

module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,

       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir,

       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,

       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  localparam RAM_DEPTH = 1 << ASIZE;
  localparam RAM_WIDTH = DSIZE;

  localparam RAM_A_FULL = ASIZE + 1;
  localparam RAM_A_EMPTY = ASIZE + 1;
  localparam RAM_B_FULL = ASIZE + 1;
  localparam RAM_B_EMPTY = ASIZE + 1;

  localparam RAM_A_AFULL = ASIZE + 1;
  localparam RAM_A_AEMPTY = ASIZE + 1;
  localparam RAM_B_AFULL = ASIZE + 1;
  localparam RAM_B_AEMPTY = ASIZE + 1;

  localparam RAM_A_AFULL_THR = RAM_DEPTH - 2;
  localparam RAM_A_AEMPTY_THR = 2;
  localparam RAM_B_AFULL_THR = RAM_DEPTH - 2;
  localparam RAM_B_AEMPTY_THR = 2;

  localparam RAM_A_FULL_THR = RAM_DEPTH;
  localparam RAM_A_EMPTY_THR = 0;
  localparam RAM_B_FULL_THR = RAM_DEPTH;
  localparam RAM_B_EMPTY_THR = 0;

  localparam RAM_A_AFULL_THR_REG = RAM_A_AFULL_THR;
  localparam RAM_A_AEMPTY_THR_REG = RAM_A_AEMPTY_THR;
  localparam RAM_B_AFULL_THR_REG = RAM_B_AFULL_THR;
  localparam RAM_B_AEMPTY_THR_REG = RAM_B_AEMPTY_THR;

  localparam RAM_A_FULL_THR_REG = RAM_A_FULL_THR;
  localparam RAM_A_EMPTY_THR_REG = RAM_A_EMPTY_THR;
  localparam RAM_B_FULL_THR_REG = RAM_B_FULL_THR;
  localparam RAM_B_EMPTY_THR_REG = RAM_B_EMPTY_THR;

  localparam RAM_A_AFULL_THR_REG_WIDTH = $clog2(RAM_A_AFULL_THR_REG + 1);
  localparam RAM_A_AEMPTY_THR_REG_WIDTH = $clog2(RAM_A_AEMPTY_THR_REG + 1);
  localparam RAM_B_AFULL_THR_REG_WIDTH = $clog2(RAM_B_AFULL_THR_REG + 1);
  localparam RAM_B_AEMPTY_THR_REG_WIDTH = $clog2(RAM_B_AEMPTY_THR_REG + 1);

  localparam RAM_A_FULL_THR_REG_WIDTH = $clog2(RAM_A_FULL_THR_REG + 1);
  localparam RAM_A_EMPTY_THR_REG_WIDTH = $clog2(RAM_A_EMPTY_THR_REG + 1);
  localparam RAM_B_FULL_THR_REG_WIDTH = $clog2(RAM_B_FULL_THR_REG + 1);
  localparam RAM_B_EMPTY_THR_REG_WIDTH = $clog2(RAM_B_EMPTY_THR_REG + 1);

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX = RAM_A_AFULL_THR_REG_WIDTH > RAM_A_AEMPTY_THR_REG_WIDTH ? RAM_A_AFULL_THR_REG_WIDTH : RAM_A_AEMPTY_THR_REG_WIDTH;
  localparam RAM_B_AFULL_THR_REG_WIDTH_MAX = RAM_B_AFULL_THR_REG_WIDTH > RAM_B_AEMPTY_THR_REG_WIDTH ? RAM_B_AFULL_THR_REG_WIDTH : RAM_B_AEMPTY_THR_REG_WIDTH;

  localparam RAM_A_FULL_THR_REG_WIDTH_MAX = RAM_A_FULL_THR_REG_WIDTH > RAM_A_EMPTY_THR_REG_WIDTH ? RAM_A_FULL_THR_REG_WIDTH : RAM_A_EMPTY_THR_REG_WIDTH;
  localparam RAM_B_FULL_THR_REG_WIDTH_MAX = RAM_B_FULL_THR_REG_WIDTH > RAM_B_EMPTY_THR_REG_WIDTH ? RAM_B_FULL_THR_REG_WIDTH : RAM_B_EMPTY_THR_REG_WIDTH;

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX = RAM_A_AFULL_THR_REG_WIDTH_MAX > RAM_A_FULL_THR_REG_WIDTH_MAX ? RAM_A_AFULL_THR_REG_WIDTH_MAX : RAM_A_FULL_THR_REG_WIDTH_MAX;
  localparam RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX = RAM_B_AFULL_THR_REG_WIDTH_MAX > RAM_B_FULL_THR_REG_WIDTH_MAX ? RAM_B_AFULL_THR_REG_WIDTH_MAX : RAM_B_FULL_THR_REG_WIDTH_MAX;

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX = RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX > RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX ? RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX : RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX;

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH = $clog2(RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX + 1);

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX = RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH > RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH ? RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH : RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH;

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH = $clog2(RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX + 1);

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH_MAX = RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH > RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH ? RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH : RAM_B_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH;

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH_MAX_WIDTH = $clog2(RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH_MAX + 1);

  localparam RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH_MAX_WIDTH_MAX = RAM_A_AFULL_THR_REG_WIDTH_MAX_MAX_MAX_WIDTH_MAX_WIDTH_MAX_WIDTH > RAM_B_AFULL