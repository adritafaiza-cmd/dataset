```verilog
`timescale 1ns/1ps

module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   pause_req,
    output wire                   pause_ack,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal signals for frame tracking
    reg [LOG2_DEPTH-1:0] frame_count;
    reg frame_in_frame;
    reg frame_valid;
    reg frame_bad;
    reg frame_oversize;
    reg frame_drop;
    reg frame_mark;
    reg frame_pause;
    reg frame_done;
    reg frame_last_seen;
    reg frame_first_seen;
    reg frame_start;

    // State for frame processing
    reg frame_state; // 0: Idle, 1: Collecting, 2: Done, 3: Bad/Oversize
    reg frame_data_valid;
    reg frame_data_last;
    reg frame_data_id;
    reg frame_data_dest;
    reg frame_data_user;
    reg frame_data_keep;
    reg frame_data_tdata;
    reg frame_data_tlast;
    reg frame_data_tvalid;
    reg frame_data_tready;

    // Output FIFO depth tracking
    reg [$clog2(DEPTH):0] write_ptr;
    reg [$clog2(DEPTH):0] read_ptr;
    reg [$clog2(DEPTH):0] commit_ptr;
    reg [$clog2(DEPTH):0] write_ptr_commit;
    reg [$clog2(DEPTH):0] read_ptr_commit;
    reg [$clog2(DEPTH):0] commit_depth;
    reg [$clog2(DEPTH):0] write_depth;
    reg [$clog2(DEPTH):0] read_depth;
    reg [$clog2(DEPTH):0] commit_depth_reg;
    reg [$clog2(DEPTH):0] write_depth_reg;
    reg [$clog2(DEPTH):0] read_depth_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] read_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] commit_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$clog2(DEPTH):0] write_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [$