// SPDX-License-Identifier: MIT
// Copyright (C) 2025  Alex Forencich
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

`timescale 1ns / 1ps

module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
)
(
    /*
     * AXI input
     */
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH+1;

    localparam S_KEEP_WIDTH_PAD = (S_KEEP_WIDTH==0) ? 1 : S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_PAD = (M_KEEP_WIDTH==0) ? 1 : M_KEEP_WIDTH;

    localparam ID_WIDTH_PAD = (ID_ENABLE==0) ? 1 : ID_WIDTH;
    localparam DEST_WIDTH_PAD = (DEST_ENABLE==0) ? 1 : DEST_WIDTH;
    localparam USER_WIDTH_PAD = (USER_ENABLE==0) ? 1 : USER_WIDTH;

    localparam S_DATA_WIDTH_PAD = (S_DATA_WIDTH==0) ? 1 : S_DATA_WIDTH;
    localparam M_DATA_WIDTH_PAD = (M_DATA_WIDTH==0) ? 1 : M_DATA_WIDTH;

    localparam S_DATA_WIDTH_PAD_LOG2 = $clog2(S_DATA_WIDTH_PAD);
    localparam M_DATA_WIDTH_PAD_LOG2 = $clog2(M_DATA_WIDTH_PAD);

    localparam S_DATA_WIDTH_PAD_MULT = (S_DATA_WIDTH_PAD_LOG2==0) ? 1 : S_DATA_WIDTH_PAD_LOG2;
    localparam M_DATA_WIDTH_PAD_MULT = (M_DATA_WIDTH_PAD_LOG2==0) ? 1 : M_DATA_WIDTH_PAD_LOG2;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2 = $clog2(S_DATA_WIDTH_PAD_MULT);
    localparam M_DATA_WIDTH_PAD_MULT_LOG2 = $clog2(M_DATA_WIDTH_PAD_MULT);

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD = (S_DATA_WIDTH_PAD_MULT_LOG2==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD = (M_DATA_WIDTH_PAD_MULT_LOG2==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT);
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT);

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT);
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT);

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT);
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2 = $clog2(M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT);

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2;
    localparam M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD = (M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2==0) ? 1 : M_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2;

    localparam S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT = (S_DATA_WIDTH_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD_MULT_LOG2_PAD==0) ? 1