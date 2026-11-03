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

    // Internal signals for AXI-Stream FIFO
    reg [S_DATA_WIDTH-1:0]  s_axis_fifo_tdata;
    reg [S_KEEP_WIDTH-1:0]  s_axis_fifo_tkeep;
    reg                     s_axis_fifo_tvalid;
    wire                    s_axis_fifo_tready;
    reg                     s_axis_fifo_tlast;
    reg [ID_WIDTH-1:0]      s_axis_fifo_tid;
    reg [DEST_WIDTH-1:0]    s_axis_fifo_tdest;
    reg [USER_WIDTH-1:0]    s_axis_fifo_tuser;

    // Internal signals for width adapter
    reg [M_DATA_WIDTH-1:0]  m_axis_fifo_tdata;
    reg [M_KEEP_WIDTH-1:0]  m_axis_fifo_tkeep;
    reg                     m_axis_fifo_tvalid;
    wire                    m_axis_fifo_tready;
    reg                     m_axis_fifo_tlast;
    reg [ID_WIDTH-1:0]      m_axis_fifo_tid;
    reg [DEST_WIDTH-1:0]    m_axis_fifo_tdest;
    reg [USER_WIDTH-1:0]    m_axis_fifo_tuser;

    // AXI-Stream FIFO instance
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) s_axis_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_tdata),
        .tkeep(s_axis_tkeep),
        .tvalid(s_axis_tvalid),
        .tready(s_axis_tready),
        .tlast(s_axis_tlast),
        .tid(s_axis_tid),
        .tdest(s_axis_tdest),
        .tuser(s_axis_tuser),
        .tdata_out(s_axis_fifo_tdata),
        .tkeep_out(s_axis_fifo_tkeep),
        .tvalid_out(s_axis_fifo_tvalid),
        .tready_out(s_axis_fifo_tready),
        .tlast_out(s_axis_fifo_tlast),
        .tid_out(s_axis_fifo_tid),
        .tdest_out(s_axis_fifo_tdest),
        .tuser_out(s_axis_fifo_tuser),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_overflow(s_status_overflow),
        .status_bad_frame(s_status_bad_frame),
        .status_good_frame(s_status_good_frame)
    );

    // Width adapter instance
    axis_width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH)
    ) width_adapter (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_fifo_tdata),
        .tkeep(s_axis_fifo_tkeep),
        .tvalid(s_axis_fifo_tvalid),
        .tready(s_axis_fifo_tready),
        .tlast(s_axis_fifo_tlast),
        .tid(s_axis_fifo_tid),
        .tdest(s_axis_fifo_tdest),
        .tuser(s_axis_fifo_tuser),
        .tdata_out(m_axis_fifo_tdata),
        .tkeep_out(m_axis_fifo_tkeep),
        .tvalid_out(m_axis_fifo_tvalid),
        .tready_out(m_axis_fifo_tready),
        .tlast_out(m_axis_fifo_tlast),
        .tid_out(m_axis_fifo_tid),
        .tdest_out(m_axis_fifo_tdest),
        .tuser_out(m_axis_fifo_tuser)
    );

    // AXI-Stream FIFO instance
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) m_axis_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(m_axis_fifo_tdata),
        .tkeep(m_axis_fifo_tkeep),
        .tvalid(m_axis_fifo_tvalid),
        .tready(m_axis_fifo_tready),
        .tlast(m_axis_fifo_tlast),
        .tid(m_axis_fifo_tid),
        .tdest(m_axis_fifo_tdest),
        .tuser(m_axis_fifo_tuser),
        .tdata_out(m_axis_tdata),
        .tkeep_out(m_axis_tkeep),
        .tvalid_out(m_axis_tvalid),
        .tready_out(m_axis_tready),
        .tlast_out(m_axis_tlast),
        .tid_out(m_axis_tid),
        .tdest_out(m_axis_tdest),
        .tuser_out(m_axis_tuser),
        .status_depth(m_status_depth),
        .status_depth_commit(m_status_depth_commit),
        .status_overflow(m_status_overflow),
        .status_bad_frame(m_status_bad_frame),
        .status_good_frame(m_status_good_frame)
    );

    // Pause handling
    wire s_pause_ack_int;
    wire m_pause_ack_int;

    assign s_pause_ack = s_pause_ack_int;
    assign m_pause_ack = m_pause_ack_int;

    // Instantiate pause controller
    axis_pause_controller #(
        .DATA_WIDTH(M_DATA_WIDTH)
    ) s_pause_controller (
        .clk(s_clk),
        .rst(s_rst),
        .req(s_pause_req),
        .ack(s_pause_ack_int)
    );

    axis_pause_controller #(
        .DATA_WIDTH(S_DATA_WIDTH)
    ) m_pause_controller (
        .clk(m_clk),
        .rst(m_rst),
        .req(m_pause_req),
        .ack(m_pause_ack_int)
    );

endmodule
