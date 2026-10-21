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

    localparam S_KEEP_WIDTH_LOG = $clog2(S_KEEP_WIDTH);
    localparam M_KEEP_WIDTH_LOG = $clog2(M_KEEP_WIDTH);
    localparam S_DATA_LOG = $clog2(S_DATA_WIDTH);
    localparam M_DATA_LOG = $clog2(M_DATA_WIDTH);

    // Internal signals for the core FIFO
    wire [DEPTH-1:0] s_axis_tdata_in;
    wire [DEPTH-1:0] s_axis_tkeep_in;
    wire [DEPTH-1:0] s_axis_tlast_in;
    wire [DEPTH-1:0] s_axis_tid_in;
    wire [DEPTH-1:0] s_axis_tdest_in;
    wire [DEPTH-1:0] s_axis_tuser_in;
    wire [DEPTH-1:0] s_axis_tvalid_in;
    wire [DEPTH-1:0] s_axis_tready_in;
    wire [DEPTH-1:0] s_axis_tpause_in;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
    wire [DEPTH-1:0] s_axis_tpause_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tdata_in_commit;
    wire [DEPTH-1:0] s_axis_tkeep_in_commit;
    wire [DEPTH-1:0] s_axis_tid_in_commit;
    wire [DEPTH-1:0] s_axis_tdest_in_commit;
    wire [DEPTH-1:0] s_axis_tuser_in_commit;
    wire [DEPTH-1:0] s_axis_tlast_in_commit;
    wire [DEPTH-1:0] s_axis_tvalid_in_commit;
    wire [DEPTH-1:0] s_axis_tready_in_commit;
