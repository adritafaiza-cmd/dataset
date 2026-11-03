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

    // Internal signals
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_next;
    reg [$clog2(DEPTH):0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_next;
    reg [$clog2(DEPTH):0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_next;
    reg [$clog2(DEPTH):0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_next;
    reg [S_DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];
    reg mem_tlast [DEPTH-1:0];
    reg s_axis_tready_int;
    reg m_axis_tvalid_int;
    reg s_status_overflow_int;
    reg s_status_bad_frame_int;
    reg s_status_good_frame_int;
    reg m_status_overflow_int;
    reg m_status_bad_frame_int;
    reg m_status_good_frame_int;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_next;
    reg s_axis_tvalid_next;
    reg s_axis_tlast_next;
    reg [ID_WIDTH-1:0] s_axis_tid_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_next;
    reg m_axis_tlast_next;
    reg [ID_WIDTH-1:0] m_axis_tid_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_next;
    reg s_pause_ack_int;
    reg m_pause_ack_int;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift;
    reg s_axis_tlast_shift;
    reg [ID_WIDTH-1:0] s_axis_tid_shift;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift;
    reg m_axis_tlast_shift;
    reg [ID_WIDTH-1:0] m_axis_tid_shift;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg;
    reg s_axis_tlast_shift_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg;
    reg m_axis_tlast_shift_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_next;
    reg s_axis_tlast_shift_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_next;
    reg m_axis_tlast_shift_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_next;
    reg s_axis_tlast_shift_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_next;
    reg m_axis_tlast_shift_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg;
    reg s_axis_tlast_shift_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg;
    reg m_axis_tlast_shift_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg s_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] s_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg m_axis_tlast_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [ID_WIDTH-1:0] m_axis_tid_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_next;

    // Gray code conversion
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 