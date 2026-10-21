```verilog
`timescale 1ns/1ps

module axis_async_fifo #
(
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
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam FULL_THRESHOLD = DEPTH - 2;
    localparam EMPTY_THRESHOLD = 0;

    // Cross Clock Domain Signals
    wire s_valid_sync;
    wire s_last_sync;
    wire s_tid_sync;
    wire s_tdest_sync;
    wire s_tuser_sync;
    wire s_keep_sync;
    wire s_pause_req_sync;
    wire s_rst_sync;
    wire s_overflow_sync;
    wire s_bad_frame_sync;
    wire s_good_frame_sync;
    wire s_depth_sync;
    wire s_depth_commit_sync;

    wire m_valid_sync;
    wire m_last_sync;
    wire m_tid_sync;
    wire m_tdest_sync;
    wire m_tuser_sync;
    wire m_keep_sync;
    wire m_pause_req_sync;
    wire m_rst_sync;
    wire m_overflow_sync;
    wire m_bad_frame_sync;
    wire m_good_frame_sync;
    wire m_depth_sync;
    wire m_depth_commit_sync;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s_bad_frame_synced;
    wire s_good_frame_synced;
    wire s_depth_synced;
    wire s_depth_commit_synced;

    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced;
    wire m_tdest_synced;
    wire m_tuser_synced;
    wire m_keep_synced;
    wire m_pause_req_synced;
    wire m_rst_synced;
    wire m_overflow_synced;
    wire m_bad_frame_synced;
    wire m_good_frame_synced;
    wire m_depth_synced;
    wire m_depth_commit_synced;

    // Generate FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;

    // Generate Cross Clock Domain FIFOs
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced;
    wire s_tdest_synced;
    wire s_tuser_synced;
    wire s_keep_synced;
    wire s_pause_req_synced;
    wire s_rst_synced;
    wire s_overflow_synced;
    wire s