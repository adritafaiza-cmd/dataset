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

    wire [S_DATA_WIDTH-1:0] s_axis_tdata_r;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_r;
    wire s_axis_tvalid_r;
    wire s_axis_tlast_r;
    wire [ID_WIDTH-1:0] s_axis_tid_r;
    wire [DEST_WIDTH-1:0] s_axis_tdest_r;
    wire [USER_WIDTH-1:0] s_axis_tuser_r;
    wire s_axis_tready_r;

    wire [M_DATA_WIDTH-1:0] m_axis_tdata_r;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_r;
    wire m_axis_tvalid_r;
    wire m_axis_tlast_r;
    wire [ID_WIDTH-1:0] m_axis_tid_r;
    wire [DEST_WIDTH-1:0] m_axis_tdest_r;
    wire [USER_WIDTH-1:0] m_axis_tuser_r;
    wire m_axis_tready_r;

    wire s_pause_ack_r;
    wire m_pause_ack_r;

    wire [S_DATA_WIDTH-1:0] m_axis_tdata_c;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_c;
    wire m_axis_tvalid_c;
    wire m_axis_tlast_c;
    wire [ID_WIDTH-1:0] m_axis_tid_c;
    wire [DEST_WIDTH-1:0] m_axis_tdest_c;
    wire [USER_WIDTH-1:0] m_axis_tuser_c;

    wire [S_DATA_WIDTH-1:0] s_axis_tdata_c;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_c;
    wire s_axis_tvalid_c;
    wire s_axis_tlast_c;
    wire [ID_WIDTH-1:0] s_axis_tid_c;
    wire [DEST_WIDTH-1:0] s_axis_tdest_c;
    wire [USER_WIDTH-1:0] s_axis_tuser_c;

    wire s_axis_tready_c;
    wire m_axis_tready_c;

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH)
    ) s_axis_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din(s_axis_tdata),
        .din_keep(s_axis_tkeep),
        .din_valid(s_axis_tvalid),
        .din_last(s_axis_tlast),
        .din_id(s_axis_tid),
        .din_dest(s_axis_tdest),
        .din_user(s_axis_tuser),
        . dout(m_axis_tdata_c),
        .dout_keep(m_axis_tkeep_c),
        .dout_valid(m_axis_tvalid_c),
        .dout_last(m_axis_tlast_c),
        .dout_id(m_axis_tid_c),
        .dout_dest(m_axis_tdest_c),
        .dout_user(m_axis_tuser_c),
        .full(s_status_overflow),
        .empty(s_status_underflow),
        .almost_full(s_status_almost_full),
        .almost_empty(s_status_almost_empty)
    );

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH)
    ) m_axis_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .din(m_axis_tdata_c),
        .din_keep(m_axis_tkeep_c),
        .din_valid(m_axis_tvalid_c),
        .din_last(m_axis_tlast_c),
        .din_id(m_axis_tid_c),
        .din_dest(m_axis_tdest_c),
        .din_user(m_axis_tuser_c),
        . dout(s_axis_tdata_c),
        .dout_keep(s_axis_tkeep_c),
        .dout_valid(s_axis_tvalid_c),
        .dout_last(s_axis_tlast_c),
        .dout_id(s_axis_tid_c),
        .dout_dest(s_axis_tdest_c),
        .dout_user(s_axis_tuser_c),
        .full(m_status_overflow),
        .empty(m_status_underflow),
        .almost_full(m_status_almost_full),
        .almost_empty(m_status_almost_empty)
    );

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_r <= 0;
        end else begin
            s_axis_tready_r <= s_axis_tready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tready_r <= 0;
        end else begin
            m_axis_tready_r <= m_axis_tready;
        end
    end

    assign s_axis_tready = s_axis_tready_r;
    assign m_axis_tready = m_axis_tready_r;

    assign s_pause_ack = s_pause_ack_r;
    assign m_pause_ack = m_pause_ack_r;

endmodule
