```verilog
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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
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
    localparam KEEP_WIDTH_LOG = $clog2(KEEP_WIDTH + 1);

    // Internal signals
    wire [LOG2_DEPTH:0] s_ptr, s_ptr_commit;
    wire [LOG2_DEPTH:0] m_ptr, m_ptr_commit;
    wire s_wr_en, s_wr_grant;
    wire m_rd_en, m_rd_grant;
    wire s_full, s_empty, s_full_commit, s_empty_commit;
    wire m_full, m_empty, m_full_commit, m_empty_commit;
    wire s_pause, m_pause;
    wire s_pause_req_ack, m_pause_req_ack;
    wire s_bad_frame, m_bad_frame;
    wire s_oversize, m_oversize;
    wire s_mark_full, m_mark_full;
    wire s_drop, m_drop;
    wire s_frame_valid, m_frame_valid;
    wire s_frame_commit, m_frame_commit;
    wire s_frame_pause, m_frame_pause;
    wire [DATA_WIDTH-1:0] s_tdata, m_tdata;
    wire [KEEP_WIDTH-1:0] s_tkeep, m_tkeep;
    wire s_tlast, m_tlast;
    wire [ID_WIDTH-1:0] s_tid, m_tid;
    wire [DEST_WIDTH-1:0] s_tdest, m_tdest;
    wire [USER_WIDTH-1:0] s_tuser, m_tuser;
    wire s_user_bad_frame, m_user_bad_frame;

    // Cross-clock pointers and pointers
    wire [LOG2_DEPTH:0] s_ptr_next, s_ptr_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_next, m_ptr_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in, s_ptr_in_commit;
    wire [LOG2_DEPTH:0] m_ptr_in, m_ptr_in_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out, s_ptr_out_commit;
    wire [LOG2_DEPTH:0] m_ptr_out, m_ptr_out_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next, s_ptr_in_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next, m_ptr_in_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next, s_ptr_out_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next, m_ptr_out_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next, s_ptr_in_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next, m_ptr_in_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next, s_ptr_out_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next, m_ptr_out_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next, s_ptr_in_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next, m_ptr_in_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next, s_ptr_out_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next, m_ptr_out_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next, s_ptr_in_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next, m_ptr_in_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next, s_ptr_out_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next, m_ptr_out_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next, s_ptr_in_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next, m_ptr_in_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next, s_ptr_out_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next, m_ptr_out_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, m_ptr_in_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;

    // Cross-clock pointers
    wire [LOG2_DEPTH:0] s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next, s_ptr_out_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_commit;
    wire [LOG2_DEPTH:0] m_ptr_out_next_next_next_next_next_next