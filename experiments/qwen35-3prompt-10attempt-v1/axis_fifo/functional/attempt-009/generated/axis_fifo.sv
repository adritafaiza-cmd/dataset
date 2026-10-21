```verilog
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
    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal signals for AXI-Stream
    reg [DATA_WIDTH-1:0] s_axis_tdata_int;
    reg [KEEP_WIDTH-1:0] s_axis_tkeep_int;
    reg s_axis_tlast_int;
    reg [ID_WIDTH-1:0] s_axis_tid_int;
    reg [DEST_WIDTH-1:0] s_axis_tdest_int;
    reg [USER_WIDTH-1:0] s_axis_tuser_int;

    // Internal signals for AXI-Stream Output
    reg [DATA_WIDTH-1:0] m_axis_tdata_int;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_int;
    reg m_axis_tlast_int;
    reg [ID_WIDTH-1:0] m_axis_tid_int;
    reg [DEST_WIDTH-1:0] m_axis_tdest_int;
    reg [USER_WIDTH-1:0] m_axis_tuser_int;

    // FIFO Control Signals
    reg [LOG2_DEPTH-1:0] write_ptr;
    reg [LOG2_DEPTH-1:0] read_ptr;
    reg [LOG2_DEPTH-1:0] write_ptr_commit;
    reg [LOG2_DEPTH-1:0] read_ptr_commit;
    reg [LOG2_DEPTH-1:0] write_ptr_pause;
    reg [LOG2_DEPTH-1:0] read_ptr_pause;
    reg [LOG2_DEPTH-1:0] write_ptr_mark;
    reg [LOG2_DEPTH-1:0] read_ptr_mark;
    reg [LOG2_DEPTH-1:0] write_ptr_drop;
    reg [LOG2_DEPTH-1:0] read_ptr_drop;
    reg [LOG2_DEPTH-1:0] write_ptr_frame;
    reg [LOG2_DEPTH-1:0] read_ptr_frame;
    reg [LOG2_DEPTH-1:0] write_ptr_bad;
    reg [LOG2_DEPTH-1:0] read_ptr_bad;
    reg [LOG2_DEPTH-1:0] write_ptr_good;
    reg [LOG2_DEPTH-1:0] read_ptr_good;
    reg [LOG2_DEPTH-1:0] write_ptr_last;
    reg [LOG2_DEPTH-1:0] read_ptr_last;
    reg [LOG2_DEPTH-1:0] write_ptr_user;
    reg [LOG2_DEPTH-1:0] read_ptr_user;
    reg [LOG2_DEPTH-1:0] write_ptr_dest;
    reg [LOG2_DEPTH-1:0] read_ptr_dest;
    reg [LOG2_DEPTH-1:0] write_ptr_id;
    reg [LOG2_DEPTH-1:0] read_ptr_id;
    reg [LOG2_DEPTH-1:0] write_ptr_keep;
    reg [LOG2_DEPTH-1:0] read_ptr_keep;
    reg [LOG2_DEPTH-1:0] write_ptr_data;
    reg [LOG2_DEPTH-1:0] read_ptr_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next;
    reg [LOG2_DEPTH-1:0] read_ptr_next;
    reg [LOG2_DEPTH-1:0] write_ptr_next_commit;
    reg [LOG2_DEPTH-1:0] read_ptr_next_commit;
    reg [LOG2_DEPTH-1:0] write_ptr_next_pause;
    reg [LOG2_DEPTH-1:0] read_ptr_next_pause;
    reg [LOG2_DEPTH-1:0] write_ptr_next_mark;
    reg [LOG2_DEPTH-1:0] read_ptr_next_mark;
    reg [LOG2_DEPTH-1:0] write_ptr_next_drop;
    reg [LOG2_DEPTH-1:0] read_ptr_next_drop;
    reg [LOG2_DEPTH-1:0] write_ptr_next_frame;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_user_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_dest_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_id_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_keep_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;

    reg [LOG2_DEPTH-1:0] write_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_frame_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_bad_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] read_ptr_next_good_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1:0] write_ptr_next_last_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data;
    reg [LOG2_DEPTH-1: