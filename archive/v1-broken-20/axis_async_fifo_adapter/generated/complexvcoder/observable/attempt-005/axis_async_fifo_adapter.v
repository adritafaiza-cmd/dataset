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

    wire s_axis_tready_reg;
    wire m_axis_tvalid_reg;
    wire [M_DATA_WIDTH-1:0] s_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    wire [ID_WIDTH-1:0] s_axis_tid_reg;
    wire [DEST_WIDTH-1:0] s_axis_tdest_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg;

    wire m_axis_tdata_reg;
    wire m_axis_tkeep_reg;
    wire m_axis_tvalid_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;

    wire s_axis_tlast_reg;
    wire m_axis_tlast_reg;

    wire s_pause_ack_reg;
    wire m_pause_ack_reg;

    wire s_status_overflow_reg;
    wire s_status_bad_frame_reg;
    wire s_status_good_frame_reg;
    wire m_status_overflow_reg;
    wire m_status_bad_frame_reg;
    wire m_status_good_frame_reg;

    wire s_status_depth_reg;
    wire s_status_depth_commit_reg;
    wire m_status_depth_reg;
    wire m_status_depth_commit_reg;

    s_to_m_fifo s_to_m (
        .clk(s_clk),
        .rst(s_rst),
        .din(s_axis_tdata),
        .din_keep(s_axis_tkeep),
        .din_valid(s_axis_tvalid),
        .din_ready(s_axis_tready_reg),
        .din_last(s_axis_tlast),
        .din_id(s_axis_tid),
        .din_dest(s_axis_tdest),
        .din_user(s_axis_tuser)
    );

    m_to_s_fifo m_to_s (
        .clk(m_clk),
        .rst(m_rst),
        .din(m_axis_tdata),
        .din_keep(m_axis_tkeep),
        .din_valid(m_axis_tvalid_reg),
        .din_ready(m_axis_tready),
        .din_last(m_axis_tlast_reg),
        .din_id(m_axis_tid_reg),
        .din_dest(m_axis_tdest_reg),
        .din_user(m_axis_tuser_reg)
    );

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 1'b0;
            s_axis_tlast_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
        end else begin
            s_axis_tready_reg <= s_axis_tready;
            s_axis_tlast_reg <= s_axis_tlast;
            s_pause_ack_reg <= s_pause_ack;
            s_status_overflow_reg <= s_to_m.s_status_overflow;
            s_status_bad_frame_reg <= s_to_m.s_status_bad_frame;
            s_status_good_frame_reg <= s_to_m.s_status_good_frame;
            s_status_depth_reg <= s_to_m.s_status_depth;
            s_status_depth_commit_reg <= s_to_m.s_status_depth_commit;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
        end else begin
            m_axis_tvalid_reg <= m_axis_tvalid;
            m_axis_tlast_reg <= m_axis_tlast;
            m_pause_ack_reg <= m_pause_ack;
            m_status_overflow_reg <= m_to_s.m_status_overflow;
            m_status_bad_frame_reg <= m_to_s.m_status_bad_frame;
            m_status_good_frame_reg <= m_to_s.m_status_good_frame;
            m_status_depth_reg <= m_to_s.m_status_depth;
            m_status_depth_commit_reg <= m_to_s.m_status_depth_commit;
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;
    assign s_status_depth = s_status_depth_reg;
    assign s_status_depth_commit = s_status_depth_commit_reg;
    assign m_status_depth = m_status_depth_reg;
    assign m_status_depth_commit = m_status_depth_commit_reg;

endmodule

module s_to_m_fifo (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [8-1:0]             din,
    input  wire [1-1:0]             din_keep,
    input  wire                     din_valid,
    output wire                     din_ready,
    input  wire                     din_last,
    input  wire [8-1:0]             din_id,
    input  wire [8-1:0]             din_dest,
    input  wire [1-1:0]             din_user
);
    // FIFO implementation here
endmodule

module m_to_s_fifo (
    input  wire                     clk,
    input  wire                     rst,
    input  wire [8-1:0]             din,
    input  wire [1-1:0]             din_keep,
    input  wire                     din_valid,
    output wire                     din_ready,
    input  wire                     din_last,
    input  wire [8-1:0]             din_id,
    input  wire [8-1:0]             din_dest,
    input  wire [1-1:0]             din_user
);
    // FIFO implementation here
endmodule
