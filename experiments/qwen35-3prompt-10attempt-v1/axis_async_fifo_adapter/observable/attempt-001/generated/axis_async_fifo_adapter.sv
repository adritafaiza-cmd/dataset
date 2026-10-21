```verilog
`timescale 1ns/1ps

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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam S_KEEP_WIDTH_LOG = S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_WIDTH;
    localparam MAX_KEEP_WIDTH = (S_KEEP_WIDTH > M_KEEP_WIDTH) ? S_KEEP_WIDTH : M_KEEP_WIDTH;
    localparam MAX_DATA_WIDTH = (S_DATA_WIDTH > M_DATA_WIDTH) ? S_DATA_WIDTH : M_DATA_WIDTH;

    // Internal signals for cross-clock domain
    wire s_valid_sync;
    wire s_last_sync;
    wire s_tid_sync;
    wire s_tdest_sync;
    wire s_tuser_sync;
    wire s_pause_req_sync;
    wire s_pause_ack_sync;
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
    wire m_pause_req_sync;
    wire m_pause_ack_sync;
    wire m_overflow_sync;
    wire m_bad_frame_sync;
    wire m_good_frame_sync;
    wire m_depth_sync;
    wire m_depth_commit_sync;

    // Generate clock domain crossing logic
    generate
        if (ID_ENABLE) begin : gen_id_cross
            sync_wires s_axis_tid, m_axis_tid;
        end else begin : gen_id_no_cross
            assign s_tid_sync = 1'b0;
            assign m_tid_sync = 1'b0;
        end

        if (DEST_ENABLE) begin : gen_dest_cross
            sync_wires s_axis_tdest, m_axis_tdest;
        end else begin : gen_dest_no_cross
            assign s_tdest_sync = 1'b0;
            assign m_tdest_sync = 1'b0;
        end

        if (USER_ENABLE) begin : gen_user_cross
            sync_wires s_axis_tuser, m_axis_tuser;
        end else begin : gen_user_no_cross
            assign s_tuser_sync = 1'b0;
            assign m_tuser_sync = 1'b0;
        end

        if (PAUSE_ENABLE) begin : gen_pause_cross
            sync_wires s_pause_req, s_pause_ack;
            sync_wires m_pause_req, m_pause_ack;
        end else begin : gen_pause_no_cross
            assign s_pause_req_sync = 1'b0;
            assign s_pause_ack_sync = 1'b0;
            assign m_pause_req_sync = 1'b0;
            assign m_pause_ack_sync = 1'b0;
        end

        if (OUTPUT_FIFO_ENABLE) begin : gen_status_cross
            sync_wires s_status_depth, s_status_depth_commit, s_status_overflow, s_status_bad_frame, s_status_good_frame;
            sync_wires m_status_depth, m_status_depth_commit, m_status_overflow, m_status_bad_frame, m_status_good_frame;
        end else begin : gen_status_no_cross
            assign s_status_depth = 0;
            assign s_status_depth_commit = 0;
            assign s_status_overflow = 0;
            assign s_status_bad_frame = 0;
            assign s_status_good_frame = 0;
            assign m_status_depth = 0;
            assign m_status_depth_commit = 0;
            assign m_status_overflow = 0;
            assign m_status_bad_frame = 0;
            assign m_status_good_frame = 0;
        end
    endgenerate

    // Define sync_wires structure
    typedef struct packed {
        wire valid;
        wire last;
        wire [ID_WIDTH-1:0] tid;
        wire [DEST_WIDTH-1:0] tdest;
        wire [USER_WIDTH-1:0] tuser;
        wire pause_req;
        wire pause_ack;
        wire overflow;
        wire bad_frame;
        wire good_frame;
        wire [$clog2(DEPTH):0] depth;
        wire [$clog2(DEPTH):0] depth_commit;
    } sync_wires;

    // Generate sync_wires instances
    generate
        if (ID_ENABLE || DEST_ENABLE || USER_ENABLE || PAUSE_ENABLE || OUTPUT_FIFO_ENABLE) begin : gen_sync_wires
            sync_wires s_axis_tid, m_axis_tid;
            sync_wires s_axis_tdest, m_axis_tdest;
            sync_wires s_axis_tuser, m_axis_tuser;
            sync_wires s_pause_req, s_pause_ack;
            sync_wires m_pause_req, m_pause_ack;
            sync_wires s_status_depth, s_status_depth_commit, s_status_overflow, s_status_bad_frame, s_status_good_frame;
            sync_wires m_status_depth, m_status_depth_commit, m_status_overflow, m_status_bad_frame, m_status_good_frame;

            // Source side sync
            assign s_valid_sync = s_axis_tvalid;
            assign s_last_sync = s_axis_tlast;
            assign s_tid_sync = s_axis_tid;
            assign s_tdest_sync = s_axis_tdest;
            assign s_tuser_sync = s_axis_tuser;
            assign s_pause_req_sync = s_pause_req;
            assign s_pause_ack_sync = s_pause_ack;
            assign s_overflow_sync = s_status_overflow;
            assign s_bad_frame_sync = s_status_bad_frame;
            assign s_good_frame_sync = s_status_good_frame;
            assign s_depth_sync = s_status_depth;
            assign s_depth_commit_sync = s_status_depth_commit;

            // Sink side sync
            assign m_valid_sync = m_axis_tvalid;
            assign m_last_sync = m_axis_tlast;
            assign m_tid_sync = m_axis_tid;
            assign m_tdest_sync = m_axis_tdest;
            assign m_tuser_sync = m_axis_tuser;
            assign m_pause_req_sync = m_pause_req;
            assign m_pause_ack_sync = m_pause_ack;
            assign m_overflow_sync = m_status_overflow;
            assign m_bad_frame_sync = m_status_bad_frame;
            assign m_good_frame_sync = m_status_good_frame;
            assign m_depth_sync = m_status_depth;
            assign m_depth_commit_sync = m_status_depth_commit;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s_status_bad_frame;
            sync_wires s_status_good_frame_inst = s_status_good_frame;
            sync_wires m_status_depth_inst = m_status_depth;
            sync_wires m_status_depth_commit_inst = m_status_depth_commit;
            sync_wires m_status_overflow_inst = m_status_overflow;
            sync_wires m_status_bad_frame_inst = m_status_bad_frame;
            sync_wires m_status_good_frame_inst = m_status_good_frame;

            // Generate sync_wires instances
            sync_wires s_axis_tid_inst = s_axis_tid;
            sync_wires m_axis_tid_inst = m_axis_tid;
            sync_wires s_axis_tdest_inst = s_axis_tdest;
            sync_wires m_axis_tdest_inst = m_axis_tdest;
            sync_wires s_axis_tuser_inst = s_axis_tuser;
            sync_wires m_axis_tuser_inst = m_axis_tuser;
            sync_wires s_pause_req_inst = s_pause_req;
            sync_wires s_pause_ack_inst = s_pause_ack;
            sync_wires m_pause_req_inst = m_pause_req;
            sync_wires m_pause_ack_inst = m_pause_ack;
            sync_wires s_status_depth_inst = s_status_depth;
            sync_wires s_status_depth_commit_inst = s_status_depth_commit;
            sync_wires s_status_overflow_inst = s_status_overflow;
            sync_wires s_status_bad_frame_inst = s