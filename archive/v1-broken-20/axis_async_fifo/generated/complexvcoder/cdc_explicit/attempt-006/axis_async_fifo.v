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

    // Internal signals
    wire [DATA_WIDTH-1:0] s_axis_tdata_reg;
    wire [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    wire s_axis_tvalid_reg;
    wire s_axis_tlast_reg;
    wire [ID_WIDTH-1:0] s_axis_tid_reg;
    wire [DEST_WIDTH-1:0] s_axis_tdest_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg;
    wire s_axis_tready_reg;

    wire [DATA_WIDTH-1:0] m_axis_tdata_reg;
    wire [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tlast_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;
    wire m_axis_tready_reg;

    wire s_pause_ack_reg;
    wire m_pause_ack_reg;

    wire [$clog2(DEPTH):0] s_status_depth_reg;
    wire [$clog2(DEPTH):0] s_status_depth_commit_reg;
    wire s_status_overflow_reg;
    wire s_status_bad_frame_reg;
    wire s_status_good_frame_reg;

    wire [$clog2(DEPTH):0] m_status_depth_reg;
    wire [$clog2(DEPTH):0] m_status_depth_commit_reg;
    wire m_status_overflow_reg;
    wire m_status_bad_frame_reg;
    wire m_status_good_frame_reg;

    // FIFO for AXI input
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
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
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_axis_tdata(s_axis_tdata_reg),
        .m_axis_tkeep(s_axis_tkeep_reg),
        .m_axis_tvalid(s_axis_tvalid_reg),
        .m_axis_tready(s_axis_tready_reg),
        .m_axis_tlast(s_axis_tlast_reg),
        .m_axis_tid(s_axis_tid_reg),
        .m_axis_tdest(s_axis_tdest_reg),
        .m_axis_tuser(s_axis_tuser_reg),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack_reg),
        .m_pause_req(s_pause_req),
        .m_pause_ack(s_pause_ack_reg),
        .s_status_depth(s_status_depth_reg),
        .s_status_depth_commit(s_status_depth_commit_reg),
        .s_status_overflow(s_status_overflow_reg),
        .s_status_bad_frame(s_status_bad_frame_reg),
        .s_status_good_frame(s_status_good_frame_reg),
        .m_status_depth(s_status_depth_reg),
        .m_status_depth_commit(s_status_depth_commit_reg),
        .m_status_overflow(s_status_overflow_reg),
        .m_status_bad_frame(s_status_bad_frame_reg),
        .m_status_good_frame(s_status_good_frame_reg)
    );

    // FIFO for AXI output
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
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
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_axis_tdata(m_axis_tdata_reg),
        .s_axis_tkeep(m_axis_tkeep_reg),
        .s_axis_tvalid(m_axis_tvalid_reg),
        .s_axis_tready(m_axis_tready_reg),
        .s_axis_tlast(m_axis_tlast_reg),
        .s_axis_tid(m_axis_tid_reg),
        .s_axis_tdest(m_axis_tdest_reg),
        .s_axis_tuser(m_axis_tuser_reg),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
        .s_pause_req(m_pause_req),
        .s_pause_ack(m_pause_ack_reg),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack_reg),
        .s_status_depth(m_status_depth_reg),
        .s_status_depth_commit(m_status_depth_commit_reg),
        .s_status_overflow(m_status_overflow_reg),
        .s_status_bad_frame(m_status_bad_frame_reg),
        .s_status_good_frame(m_status_good_frame_reg),
        .m_status_depth(m_status_depth_reg),
        .m_status_depth_commit(m_status_depth_commit_reg),
        .m_status_overflow(m_status_overflow_reg),
        .m_status_bad_frame(m_status_bad_frame_reg),
        .m_status_good_frame(m_status_good_frame_reg)
    );

    // Assign outputs
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_status_depth_reg;
    assign s_status_depth_commit = s_status_depth_commit_reg;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = m_status_depth_reg;
    assign m_status_depth_commit = m_status_depth_commit_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule
