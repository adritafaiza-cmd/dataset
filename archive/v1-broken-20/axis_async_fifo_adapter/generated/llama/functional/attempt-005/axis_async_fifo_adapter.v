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

    reg [S_DATA_WIDTH-1:0] s_fifo_data;
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep;
    reg [ID_WIDTH-1:0] s_fifo_id;
    reg [DEST_WIDTH-1:0] s_fifo_dest;
    reg [USER_WIDTH-1:0] s_fifo_user;
    reg s_fifo_last;
    reg s_fifo_valid;
    reg [M_DATA_WIDTH-1:0] m_fifo_data;
    reg [M_KEEP_WIDTH-1:0] m_fifo_keep;
    reg [ID_WIDTH-1:0] m_fifo_id;
    reg [DEST_WIDTH-1:0] m_fifo_dest;
    reg [USER_WIDTH-1:0] m_fifo_user;
    reg m_fifo_last;
    reg m_fifo_valid;
    reg [S_DATA_WIDTH-1:0] s_shift_reg;
    reg [S_KEEP_WIDTH-1:0] s_shift_keep;
    reg [ID_WIDTH-1:0] s_shift_id;
    reg [DEST_WIDTH-1:0] s_shift_dest;
    reg [USER_WIDTH-1:0] s_shift_user;
    reg s_shift_last;
    reg s_shift_valid;
    reg [M_DATA_WIDTH-1:0] m_shift_reg;
    reg [M_KEEP_WIDTH-1:0] m_shift_keep;
    reg [ID_WIDTH-1:0] m_shift_id;
    reg [DEST_WIDTH-1:0] m_shift_dest;
    reg [USER_WIDTH-1:0] m_shift_user;
    reg m_shift_last;
    reg m_shift_valid;
    reg [DEPTH-1:0] s_fifo_ptr;
    reg [DEPTH-1:0] m_fifo_ptr;
    reg [DEPTH-1:0] s_fifo_commit_ptr;
    reg [DEPTH-1:0] m_fifo_commit_ptr;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    reg s_status_overflow_reg;
    reg m_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg m_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_good_frame_reg;

    assign s_axis_tready = (s_fifo_ptr != DEPTH-1) && !s_pause_req;
    assign m_axis_tvalid = m_fifo_valid;
    assign m_axis_tdata = m_fifo_data;
    assign m_axis_tkeep = m_fifo_keep;
    assign m_axis_tlast = m_fifo_last;
    assign m_axis_tid = m_fifo_id;
    assign m_axis_tdest = m_fifo_dest;
    assign m_axis_tuser = m_fifo_user;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_fifo_ptr;
    assign s_status_depth_commit = s_fifo_commit_ptr;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = m_fifo_ptr;
    assign m_status_depth_commit = m_fifo_commit_ptr;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_ptr <= 0;
            s_fifo_commit_ptr <= 0;
            s_fifo_valid <= 0;
            s_fifo_data <= 0;
            s_fifo_keep <= 0;
            s_fifo_id <= 0;
            s_fifo_dest <= 0;
            s_fifo_user <= 0;
            s_fifo_last <= 0;
            s_shift_reg <= 0;
            s_shift_keep <= 0;
            s_shift_id <= 0;
            s_shift_dest <= 0;
            s_shift_user <= 0;
            s_shift_last <= 0;
            s_shift_valid <= 0;
            s_pause_ack_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            if (s_fifo_ptr == DEPTH-1) begin
                s_status_overflow_reg <= 1;
            end else begin
                s_fifo_ptr <= s_fifo_ptr + 1;
                s_fifo_commit_ptr <= s_fifo_commit_ptr + 1;
                s_fifo_valid <= 1;
                s_fifo_data <= s_axis_tdata;
                s_fifo_keep <= s_axis_tkeep;
                s_fifo_id <= s_axis_tid;
                s_fifo_dest <= s_axis_tdest;
                s_fifo_user <= s_axis_tuser;
                s_fifo_last <= s_axis_tlast;
                s_shift_reg <= s_axis_tdata;
                s_shift_keep <= s_axis_tkeep;
                s_shift_id <= s_axis_tid;
                s_shift_dest <= s_axis_tdest;
                s_shift_user <= s_axis_tuser;
                s_shift_last <= s_axis_tlast;
                s_shift_valid <= 1;
            end
        end else if (s_pause_req) begin
            s_pause_ack_reg <= 1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_fifo_ptr <= 0;
            m_fifo_commit_ptr <= 0;
            m_fifo_valid <= 0;
            m_fifo_data <= 0;
            m_fifo_keep <= 0;
            m_fifo_id <= 0;
            m_fifo_dest <= 0;
            m_fifo_user <= 0;
            m_fifo_last <= 0;
            m_shift_reg <= 0;
            m_shift_keep <= 0;
            m_shift_id <= 0;
            m_shift_dest <= 0;
            m_shift_user <= 0;
            m_shift_last <= 0;
            m_shift_valid <= 0;
            m_pause_ack_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else if (m_axis_tready && m_fifo_valid) begin
            if (m_fifo_ptr == DEPTH-1) begin
                m_status_overflow_reg <= 1;
            end else begin
                m_fifo_ptr <= m_fifo_ptr + 1;
                m_fifo_commit_ptr <= m_fifo_commit_ptr + 1;
                m_fifo_valid <= 0;
                m_fifo_data <= m_shift_reg;
                m_fifo_keep <= m_shift_keep;
                m_fifo_id <= m_shift_id;
                m_fifo_dest <= m_shift_dest;
                m_fifo_user <= m_shift_user;
                m_fifo_last <= m_shift_last;
                m_shift_reg <= {m_shift_reg[M_DATA_WIDTH-1:0], m_shift_reg[M_DATA_WIDTH-1]};
                m_shift_keep <= {m_shift_keep[M_KEEP_WIDTH-1:0], m_shift_keep[M_KEEP_WIDTH-1]};
                m_shift_id <= {m_shift_id[ID_WIDTH-1:0], m_shift_id[ID_WIDTH-1]};
                m_shift_dest <= {m_shift_dest[DEST_WIDTH-1:0], m_shift_dest[DEST_WIDTH-1]};
                m_shift_user <= {m_shift_user[USER_WIDTH-1:0], m_shift_user[USER_WIDTH-1]};
                m_shift_last <= m_shift_last;
                m_shift_valid <= m_shift_valid;
            end
        end else if (m_pause_req) begin
            m_pause_ack_reg <= 1;
        end
    end

endmodule
