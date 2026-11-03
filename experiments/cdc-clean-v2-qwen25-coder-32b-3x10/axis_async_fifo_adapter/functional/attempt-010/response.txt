```verilog
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
    localparam S_BEAT_WIDTH = S_DATA_WIDTH + (S_KEEP_ENABLE ? S_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) + 1;
    localparam M_BEAT_WIDTH = M_DATA_WIDTH + (M_KEEP_ENABLE ? M_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) + 1;

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt, s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt, m_rd_ptr_gray_sync;

    reg [S_BEAT_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] s_depth, m_depth;
    reg [ADDR_WIDTH:0] s_depth_commit, m_depth_commit;

    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    reg s_pause_ack_reg, m_pause_ack_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg;

    reg [ADDR_WIDTH:0] s_depth_reg;
    reg [ADDR_WIDTH:0] m_depth_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg;

    reg s_overflow_reg;
    reg m_overflow_reg;

    reg s_bad_frame_reg;
    reg m_bad_frame_reg;

    reg s_good_frame_reg;
    reg m_good_frame_reg;

    reg s_pause_ack_reg_reg;
    reg m_pause_ack_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg;
    reg s_axis_tvalid_reg_reg;
    reg s_axis_tlast_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg;
    reg m_axis_tvalid_reg_reg;
    reg m_axis_tlast_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg;

    reg s_overflow_reg_reg;
    reg m_overflow_reg_reg;

    reg s_bad_frame_reg_reg;
    reg m_bad_frame_reg_reg;

    reg s_good_frame_reg_reg;
    reg m_good_frame_reg_reg;

    reg s_pause_ack_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg;

    reg s_overflow_reg_reg_reg;
    reg m_overflow_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg;

    reg s_good_frame_reg_reg_reg;
    reg m_good_frame_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tvalid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [ADDR_WIDTH:0] s_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ADDR_WIDTH:0] m_depth_commit_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_overflow_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_bad_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_good_frame_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg s_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_pause_ack_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_BEAT_WIDTH-1:0] s_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_beat_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s