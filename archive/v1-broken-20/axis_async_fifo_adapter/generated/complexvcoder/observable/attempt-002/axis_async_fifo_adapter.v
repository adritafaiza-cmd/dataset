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

    wire [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    wire s_axis_tvalid_reg;
    wire s_axis_tready_reg;
    wire s_axis_tlast_reg;
    wire [ID_WIDTH-1:0] s_axis_tid_reg;
    wire [DEST_WIDTH-1:0] s_axis_tdest_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg;

    wire [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tready_reg;
    wire m_axis_tlast_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
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
    ) fifo_s_to_m (
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
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata_reg),
        .m_axis_tkeep(m_axis_tkeep_reg),
        .m_axis_tvalid(m_axis_tvalid_reg),
        .m_axis_tready(m_axis_tready_reg),
        .m_axis_tlast(m_axis_tlast_reg),
        .m_axis_tid(m_axis_tid_reg),
        .m_axis_tdest(m_axis_tdest_reg),
        .m_axis_tuser(m_axis_tuser_reg)
    );

    axis_width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH)
    ) adapter_s_to_m (
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
        .m_axis_tuser(m_axis_tuser)
    );

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .S_DATA_WIDTH(M_DATA_WIDTH),
        .S_KEEP_ENABLE(M_KEEP_ENABLE),
        .S_KEEP_WIDTH(M_KEEP_WIDTH),
        .M_DATA_WIDTH(S_DATA_WIDTH),
        .M_KEEP_ENABLE(S_KEEP_ENABLE),
        .M_KEEP_WIDTH(S_KEEP_WIDTH),
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
    ) fifo_m_to_s (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_axis_tdata(m_axis_tdata),
        .s_axis_tkeep(m_axis_tkeep),
        .s_axis_tvalid(m_axis_tvalid),
        .s_axis_tready(m_axis_tready),
        .s_axis_tlast(m_axis_tlast),
        .s_axis_tid(m_axis_tid),
        .s_axis_tdest(m_axis_tdest),
        .s_axis_tuser(m_axis_tuser),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_axis_tdata(s_axis_tdata_reg),
        .m_axis_tkeep(s_axis_tkeep_reg),
        .m_axis_tvalid(s_axis_tvalid_reg),
        .m_axis_tready(s_axis_tready_reg),
        .m_axis_tlast(s_axis_tlast_reg),
        .m_axis_tid(s_axis_tid_reg),
        .m_axis_tdest(s_axis_tdest_reg),
        .m_axis_tuser(s_axis_tuser_reg)
    );

    axis_width_adapter #(
        .S_DATA_WIDTH(M_DATA_WIDTH),
        .S_KEEP_ENABLE(M_KEEP_ENABLE),
        .S_KEEP_WIDTH(M_KEEP_WIDTH),
        .M_DATA_WIDTH(S_DATA_WIDTH),
        .M_KEEP_ENABLE(S_KEEP_ENABLE),
        .M_KEEP_WIDTH(S_KEEP_WIDTH)
    ) adapter_m_to_s (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata_reg),
        .s_axis_tkeep(s_axis_tkeep_reg),
        .s_axis_tvalid(s_axis_tvalid_reg),
        .s_axis_tready(s_axis_tready_reg),
        .s_axis_tlast(s_axis_tlast_reg),
        .s_axis_tid(s_axis_tid_reg),
        .s_axis_tdest(s_axis_tdest_reg),
        .s_axis_tuser(s_axis_tuser_reg),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_axis_tdata(s_axis_tdata),
        .m_axis_tkeep(s_axis_tkeep),
        .m_axis_tvalid(s_axis_tvalid),
        .m_axis_tready(s_axis_tready),
        .m_axis_tlast(s_axis_tlast),
        .m_axis_tid(s_axis_tid),
        .m_axis_tdest(s_axis_tdest),
        .m_axis_tuser(s_axis_tuser)
    );

endmodule
