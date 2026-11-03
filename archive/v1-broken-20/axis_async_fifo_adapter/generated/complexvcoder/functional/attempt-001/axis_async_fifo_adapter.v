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

    // FIFO for S interface
    fifo_async #(
        .WIDTH(S_DATA_WIDTH + S_KEEP_WIDTH + ID_WIDTH + DEST_WIDTH + USER_WIDTH),
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) s_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({s_axis_tdata, s_axis_tkeep, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .wr_en(s_axis_tvalid),
        .rd_en(m_axis_tready),
        .dout(s_fifo_dout),
        .full(s_status_overflow),
        .empty(s_status_good_frame),
        .almost_full(s_status_depth_commit),
        .almost_empty(s_status_depth)
    );

    // FIFO for M interface
    fifo_async #(
        .WIDTH(M_DATA_WIDTH + M_KEEP_WIDTH + ID_WIDTH + DEST_WIDTH + USER_WIDTH),
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) m_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .din(m_fifo_din),
        .wr_en(m_axis_tvalid),
        .rd_en(s_axis_tready),
        .dout(m_axis_tdata),
        .full(m_status_overflow),
        .empty(m_status_good_frame),
        .almost_full(m_status_depth_commit),
        .almost_empty(m_status_depth)
    );

    // Width adapter from S to M
    wire [M_DATA_WIDTH-1:0] s_axis_tdata_adapted;
    wire [M_KEEP_WIDTH-1:0] s_axis_tkeep_adapted;
    wire [M_USER_WIDTH-1:0] s_axis_tuser_adapted;

    assign s_axis_tdata_adapted = s_fifo_dout[S_DATA_WIDTH-1:0];
    assign s_axis_tkeep_adapted = s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH-1:S_DATA_WIDTH];
    assign s_axis_tuser_adapted = s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH];

    // Width adapter from M to S
    wire [S_DATA_WIDTH-1:0] m_axis_tdata_adapted;
    wire [S_KEEP_WIDTH-1:0] m_axis_tkeep_adapted;
    wire [S_USER_WIDTH-1:0] m_axis_tuser_adapted;

    assign m_axis_tdata_adapted = m_fifo_din[M_DATA_WIDTH-1:0];
    assign m_axis_tkeep_adapted = m_fifo_din[M_DATA_WIDTH+M_KEEP_WIDTH-1:M_DATA_WIDTH];
    assign m_axis_tuser_adapted = m_fifo_din[M_DATA_WIDTH+M_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:M_DATA_WIDTH+M_KEEP_WIDTH];

    // Output ready handling
    assign s_axis_tready = s_fifo.wr_en;

    // Pause handling
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

endmodule
