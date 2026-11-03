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

    // Internal signals for S side
    reg [S_DATA_WIDTH-1:0] s_fifo_data_out;
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep_out;
    reg s_fifo_valid_out;
    reg s_fifo_last_out;
    reg [ID_WIDTH-1:0] s_fifo_tid_out;
    reg [DEST_WIDTH-1:0] s_fifo_tdest_out;
    reg [USER_WIDTH-1:0] s_fifo_tuser_out;
    wire s_fifo_empty;
    wire s_fifo_full;
    wire s_fifo_overflow;
    wire s_fifo_underflow;
    wire s_fifo_bad_frame;
    wire s_fifo_good_frame;

    // Internal signals for M side
    reg [M_DATA_WIDTH-1:0] m_fifo_data_out;
    reg [M_KEEP_WIDTH-1:0] m_fifo_keep_out;
    reg m_fifo_valid_out;
    reg m_fifo_last_out;
    reg [ID_WIDTH-1:0] m_fifo_tid_out;
    reg [DEST_WIDTH-1:0] m_fifo_tdest_out;
    reg [USER_WIDTH-1:0] m_fifo_tuser_out;
    wire m_fifo_empty;
    wire m_fifo_full;
    wire m_fifo_overflow;
    wire m_fifo_underflow;
    wire m_fifo_bad_frame;
    wire m_fifo_good_frame;

    // FIFO for S side
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
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
    ) s_fifo (
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
        .data_out(s_fifo_data_out),
        .keep_out(s_fifo_keep_out),
        .valid_out(s_fifo_valid_out),
        .last_out(s_fifo_last_out),
        .tid_out(s_fifo_tid_out),
        .tdest_out(s_fifo_tdest_out),
        .tuser_out(s_fifo_tuser_out),
        .empty(s_fifo_empty),
        .full(s_fifo_full),
        .overflow(s_fifo_overflow),
        .underflow(s_fifo_underflow),
        .bad_frame(s_fifo_bad_frame),
        .good_frame(s_fifo_good_frame)
    );

    // FIFO for M side
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(M_DATA_WIDTH),
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
    ) m_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(s_fifo_data_out),
        .tkeep(s_fifo_keep_out),
        .tvalid(s_fifo_valid_out),
        .tready(m_axis_tready),
        .tlast(s_fifo_last_out),
        .tid(s_fifo_tid_out),
        .tdest(s_fifo_tdest_out),
        .tuser(s_fifo_tuser_out),
        .data_out(m_fifo_data_out),
        .keep_out(m_fifo_keep_out),
        .valid_out(m_fifo_valid_out),
        .last_out(m_fifo_last_out),
        .tid_out(m_fifo_tid_out),
        .tdest_out(m_fifo_tdest_out),
        .tuser_out(m_fifo_tuser_out),
        .empty(m_fifo_empty),
        .full(m_fifo_full),
        .overflow(m_fifo_overflow),
        .underflow(m_fifo_underflow),
        .bad_frame(m_fifo_bad_frame),
        .good_frame(m_fifo_good_frame)
    );

    // Pause handling
    reg s_pause;
    reg m_pause;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause <= 0;
        end else begin
            s_pause <= s_pause_req & ~s_pause_ack;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause <= 0;
        end else begin
            m_pause <= m_pause_req & ~m_pause_ack;
        end
    end

    assign s_pause_ack = s_pause;
    assign m_pause_ack = m_pause;

    // Status signals
    assign s_status_depth = $clog2(DEPTH) - 1;
    assign s_status_depth_commit = $clog2(DEPTH) - 1;
    assign s_status_overflow = s_fifo_overflow;
    assign s_status_bad_frame = s_fifo_bad_frame;
    assign s_status_good_frame = s_fifo_good_frame;

    assign m_status_depth = $clog2(DEPTH) - 1;
    assign m_status_depth_commit = $clog2(DEPTH) - 1;
    assign m_status_overflow = m_fifo_overflow;
    assign m_status_bad_frame = m_fifo_bad_frame;
    assign m_status_good_frame = m_fifo_good_frame;

endmodule
