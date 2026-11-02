// SPDX-License-Identifier: MIT
// Copyright (C) 2025  Alex Forencich

// verilog-lint off

`include "config.vh"

`include "axis.vh"

module axis_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
) (
    input  wire                   clk,
    input  wire                   rst,

    // AXI input
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,

    // AXI output
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,

    // pause
    input  wire                   pause_req,
    output wire                   pause_ack,

    // status
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam DEPTH_LOG2 = $clog2(DEPTH);

    localparam DATA_FIFO_DEPTH = DEPTH;
    localparam DATA_FIFO_DEPTH_LOG2 = $clog2(DATA_FIFO_DEPTH);

    localparam FRAME_FIFO_DEPTH = (OUTPUT_FIFO_ENABLE ? 2 : 1);
    localparam FRAME_FIFO_DEPTH_LOG2 = $clog2(FRAME_FIFO_DEPTH);

    localparam FRAME_FIFO_ENABLE = (FRAME_FIFO || DROP_OVERSIZE_FRAME || DROP_BAD_FRAME || DROP_WHEN_FULL || MARK_WHEN_FULL || FRAME_PAUSE);

    localparam FRAME_FIFO_DATA_WIDTH = (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);

    localparam FRAME_FIFO_DATA_WIDTH_LOG2 = $clog2(FRAME_FIFO_DATA_WIDTH);

    localparam FRAME_FIFO_DATA_WIDTH_PADDED = (FRAME_FIFO_DATA_WIDTH_LOG2 == 0 ? 1 : FRAME_FIFO_DATA_WIDTH_LOG2);

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK = (1 << FRAME_FIFO_DATA_WIDTH_PADDED) - 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO_HI = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO >> 1;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO_LO = FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO & FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO_HI;

    localparam FRAME_FIFO_DATA_WIDTH_PADDED_MASK_LO_LO_LO_LO_LO_LO_LO_LO_LO_HI