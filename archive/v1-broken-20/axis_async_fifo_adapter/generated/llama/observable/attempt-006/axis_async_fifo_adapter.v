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

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg                     s_axis_tvalid_reg;
    reg                     s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]      s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]    s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]    s_axis_tuser_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg                     m_axis_tvalid_reg;
    reg                     m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]      m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]    m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]    m_axis_tuser_reg;

    reg [$clog2(DEPTH):0] s_status_depth_reg;
    reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
    reg                     s_status_overflow_reg;
    reg                     s_status_bad_frame_reg;
    reg                     s_status_good_frame_reg;

    reg [$clog2(DEPTH):0] m_status_depth_reg;
    reg [$clog2(DEPTH):0] m_status_depth_commit_reg;
    reg                     m_status_overflow_reg;
    reg                     m_status_bad_frame_reg;
    reg                     m_status_good_frame_reg;

    reg                     s_pause_ack_reg;
    reg                     m_pause_ack_reg;

    reg [S_DATA_WIDTH-1:0] fifo_data[S_DATA_WIDTH/8-1:0];
    reg [S_KEEP_WIDTH-1:0] fifo_keep[S_DATA_WIDTH/8-1:0];
    reg                     fifo_valid[S_DATA_WIDTH/8-1:0];
    reg                     fifo_last[S_DATA_WIDTH/8-1:0];
    reg [ID_WIDTH-1:0]      fifo_id[S_DATA_WIDTH/8-1:0];
    reg [DEST_WIDTH-1:0]    fifo_dest[S_DATA_WIDTH/8-1:0];
    reg [USER_WIDTH-1:0]    fifo_user[S_DATA_WIDTH/8-1:0];

    reg [M_DATA_WIDTH-1:0] m_fifo_data[M_DATA_WIDTH/8-1:0];
    reg [M_KEEP_WIDTH-1:0] m_fifo_keep[M_DATA_WIDTH/8-1:0];
    reg                     m_fifo_valid[M_DATA_WIDTH/8-1:0];
    reg                     m_fifo_last[M_DATA_WIDTH/8-1:0];
    reg [ID_WIDTH-1:0]      m_fifo_id[M_DATA_WIDTH/8-1:0];
    reg [DEST_WIDTH-1:0]    m_fifo_dest[M_DATA_WIDTH/8-1:0];
    reg [USER_WIDTH-1:0]    m_fifo_user[M_DATA_WIDTH/8-1:0];

    reg [S_DATA_WIDTH-1:0] s_fifo_data[S_DATA_WIDTH/8-1:0];
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep[S_DATA_WIDTH/8-1:0];
    reg                     s_fifo_valid[S_DATA_WIDTH/8-1:0];
    reg                     s_fifo_last[S_DATA_WIDTH/8-1:0];
    reg [ID_WIDTH-1:0]      s_fifo_id[S_DATA_WIDTH/8-1:0];
    reg [DEST_WIDTH-1:0]    s_fifo_dest[S_DATA_WIDTH/8-1:0];
    reg [USER_WIDTH-1:0]    s_fifo_user[S_DATA_WIDTH/8-1:0];

    reg                     s_fifo_empty;
    reg                     s_fifo_full;
    reg                     m_fifo_empty;
    reg                     m_fifo_full;

    reg                     s_fifo_read;
    reg                     s_fifo_write;
    reg                     m_fifo_read;
    reg                     m_fifo_write;

    reg [S_DATA_WIDTH-1:0] s_fifo_out_data;
    reg [S_KEEP_WIDTH-1:0] s_fifo_out_keep;
    reg                     s_fifo_out_valid;
    reg                     s_fifo_out_last;
    reg [ID_WIDTH-1:0]      s_fifo_out_id;
    reg [DEST_WIDTH-1:0]    s_fifo_out_dest;
    reg [USER_WIDTH-1:0]    s_fifo_out_user;

    reg [M_DATA_WIDTH-1:0] m_fifo_out_data;
    reg [M_KEEP_WIDTH-1:0] m_fifo_out_keep;
    reg                     m_fifo_out_valid;
    reg                     m_fifo_out_last;
    reg [ID_WIDTH-1:0]      m_fifo_out_id;
    reg [DEST_WIDTH-1:0]    m_fifo_out_dest;
    reg [USER_WIDTH-1:0]    m_fifo_out_user;

    reg                     s_pause_req_reg;
    reg                     m_pause_req_reg;

    integer i;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_pause_ack_reg <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
            s_fifo_empty <= 1;
            s_fifo_full <= 0;
            s_fifo_read <= 0;
            s_fifo_write <= 0;
            s_fifo_out_data <= 0;
            s_fifo_out_keep <= 0;
            s_fifo_out_valid <= 0;
            s_fifo_out_last <= 0;
            s_fifo_out_id <= 0;
            s_fifo_out_dest <= 0;
            s_fifo_out_user <= 0;
            s_pause_req_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
            if (s_pause_req) begin
                s_pause_ack_reg <= 1;
            end else begin
                s_pause_ack_reg <= 0;
            end
            if (s_fifo_full) begin
                s_status_overflow_reg <= 1;
            end else begin
                s_status_overflow_reg <= 0;
            end
            if (s_fifo_empty) begin
                s_status_depth_reg <= 0;
                s_status_depth_commit_reg <= 0;
            end else begin
                s_status_depth_reg <= s_status_depth_reg + 1;
                s_status_depth_commit_reg <= s_status_depth_commit_reg + 1;
            end
            if (s_axis_tlast) begin
                s_status_good_frame_reg <= 1;
            end else begin
                s_status_good_frame_reg <= 0;
            end
            if (s_axis_tuser == USER_BAD_FRAME_VALUE) begin
                s_status_bad_frame_reg <= 1;
            end else begin
                s_status_bad_frame_reg <= 0;
            end
            if (s_fifo_empty) begin
                s_fifo_read <= 0;
            end else begin
                s_fifo_read <= 1;
            end
            if (s_fifo_full) begin
                s_fifo_write <= 0;
            end else begin
                s_fifo_write <= 1;
            end
            if (s_fifo_read) begin
                s_fifo_out_data <= s_fifo_data[0];
                s_fifo_out_keep <= s_fifo_keep[0];
                s_fifo_out_valid <= s_fifo_valid[0];
                s_fifo_out_last <= s_fifo_last[0];
                s_fifo_out_id <= s_fifo_id[0];
                s_fifo_out_dest <= s_fifo_dest[0];
                s_fifo_out_user <= s_fifo_user[0];
                for (i = 0; i < S_DATA_WIDTH/8-1; i = i + 1) begin
                    s_fifo_data[i] <= s_fifo_data[i+1];
                    s_fifo_keep[i] <= s_fifo_keep[i+1];
                    s_fifo_valid[i] <= s_fifo_valid[i+1];
                    s_fifo_last[i] <= s_fifo_last[i+1];
                    s_fifo_id[i] <= s_fifo_id[i+1];
                    s_fifo_dest[i] <= s_fifo_dest[i+1];
                    s_fifo_user[i] <= s_fifo_user[i+1];
                end
                s_fifo_empty <= 0;
            end else begin
                s_fifo_out_data <= 0;
                s_fifo_out_keep <= 0;
                s_fifo_out_valid <= 0;
                s_fifo_out_last <= 0;
                s_fifo_out_id <= 0;
                s_fifo_out_dest <= 0;
                s_fifo_out_user <= 0;
            end
            if (s_fifo_write) begin
                s_fifo_data[S_DATA_WIDTH/8-1] <= s_axis_tdata;
                s_fifo_keep[S_DATA_WIDTH/8-1] <= s_axis_tkeep;
                s_fifo_valid[S_DATA_WIDTH/8-1] <= s_axis_tvalid;
                s_fifo_last[S_DATA_WIDTH/8-1] <= s_axis_tlast;
                s_fifo_id[S_DATA_WIDTH/8-1] <= s_axis_tid;
                s_fifo_dest[S_DATA_WIDTH/8-1] <= s_axis_tdest;
                s_fifo_user[S_DATA_WIDTH/8-1] <= s_axis_tuser;
                s_fifo_full <= 0;
            end else begin
                s_fifo_data[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_keep[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_valid[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_last[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_id[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_dest[S_DATA_WIDTH/8-1] <= 0;
                s_fifo_user[S_DATA_WIDTH/8-1] <= 0;
            end
        end else begin
            s_axis_tdata_reg <= s_axis_tdata_reg;
            s_axis_tkeep_reg <= s_axis_tkeep_reg;
            s_axis_tvalid_reg <= s_axis_tvalid_reg;
            s_axis_tlast_reg <= s_axis_tlast_reg;
            s_axis_tid_reg <= s_axis_tid_reg;
            s_axis_tdest_reg <= s_axis_tdest_reg;
            s_axis_tuser_reg <= s_axis_tuser_reg;
            s_pause_ack_reg <= s_pause_ack_reg;
            s_status_depth_reg <= s_status_depth_reg;
            s_status_depth_commit_reg <= s_status_depth_commit_reg;
            s_status_overflow_reg <= s_status_overflow_reg;
            s_status_bad_frame_reg <= s_status_bad_frame_reg;
            s_status_good_frame_reg <= s_status_good_frame_reg;
            s_fifo_empty <= s_fifo_empty;
            s_fifo_full <= s_fifo_full;
            s_fifo_read <= s_fifo_read;
            s_fifo_write <= s_fifo_write;
            s_fifo_out_data <= s_fifo_out_data;
            s_fifo_out_keep <= s_fifo_out_keep;
            s_fifo_out_valid <= s_fifo_out_valid;
            s_fifo_out_last <= s_fifo_out_last;
            s_fifo_out_id <= s_fifo_out_id;
            s_fifo_out_dest <= s_fifo_out_dest;
            s_fifo_out_user <= s_fifo_out_user;
            s_pause_req_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_pause_ack_reg <= 0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
            m_fifo_empty <= 1;
            m_fifo_full <= 0;
            m_fifo_read <= 0;
            m_fifo_write <= 0;
            m_fifo_out_data <= 0;
            m_fifo_out_keep <= 0;
            m_fifo_out_valid <= 0;
            m_fifo_out_last <= 0;
            m_fifo_out_id <= 0;
            m_fifo_out_dest <= 0;
            m_fifo_out_user <= 0;
            m_pause_req_reg <= 0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            m_axis_tdata_reg <= m_axis_tdata;
            m_axis_tkeep_reg <= m_axis_tkeep;
            m_axis_tvalid_reg <= m_axis_tvalid;
            m_axis_tlast_reg <= m_axis_tlast;
            m_axis_tid_reg <= m_axis_tid;
            m_axis_tdest_reg <= m_axis_tdest;
            m_axis_tuser_reg <= m_axis_tuser;
            if (m_pause_req) begin
                m_pause_ack_reg <= 1;
            end else begin
                m_pause_ack_reg <= 0;
            end
            if (m_fifo_full) begin
                m_status_overflow_reg <= 1;
            end else begin
                m_status_overflow_reg <= 0;
            end
            if (m_fifo_empty) begin
                m_status_depth_reg <= 0;
                m_status_depth_commit_reg <= 0;
            end else begin
                m_status_depth_reg <= m_status_depth_reg + 1;
                m_status_depth_commit_reg <= m_status_depth_commit_reg + 1;
            end
            if (m_axis_tlast) begin
                m_status_good_frame_reg <= 1;
            end else begin
                m_status_good_frame_reg <= 0;
            end
            if (m_axis_tuser == USER_BAD_FRAME_VALUE) begin
                m_status_bad_frame_reg <= 1;
            end else begin
                m_status_bad_frame_reg <= 0;
            end
            if (m_fifo_empty) begin
                m_fifo_read <= 0;
            end else begin
                m_fifo_read <= 1;
            end
            if (m_fifo_full) begin
                m_fifo_write <= 0;
            end else begin
                m_fifo_write <= 1;
            end
            if (m_fifo_read) begin
                m_fifo_out_data <= m_fifo_data[0];
                m_fifo_out_keep <= m_fifo_keep[0];
                m_fifo_out_valid <= m_fifo_valid[0];
                m_fifo_out_last <= m_fifo_last[0];
                m_fifo_out_id <= m_fifo_id[0];
                m_fifo_out_dest <= m_fifo_dest[0];
                m_fifo_out_user <= m_fifo_user[0];
                for (i = 0; i < M_DATA_WIDTH/8-1; i = i + 1) begin
                    m_fifo_data[i] <= m_fifo_data[i+1];
                    m_fifo_keep[i] <= m_fifo_keep[i+1];
                    m_fifo_valid[i] <= m_fifo_valid[i+1];
                    m_fifo_last[i] <= m_fifo_last[i+1];
                    m_fifo_id[i] <= m_fifo_id[i+1];
                    m_fifo_dest[i] <= m_fifo_dest[i+1];
                    m_fifo_user[i] <= m_fifo_user[i+1];
                end
                m_fifo_empty <= 0;
            end else begin
                m_fifo_out_data <= 0;
                m_fifo_out_keep <= 0;
                m_fifo_out_valid <= 0;
                m_fifo_out_last <= 0;
                m_fifo_out_id <= 0;
                m_fifo_out_dest <= 0;
                m_fifo_out_user <= 0;
            end
            if (m_fifo_write) begin
                m_fifo_data[M_DATA_WIDTH/8-1] <= m_axis_tdata;
                m_fifo_keep[M_DATA_WIDTH/8-1] <= m_axis_tkeep;
                m_fifo_valid[M_DATA_WIDTH/8-1] <= m_axis_tvalid;
                m_fifo_last[M_DATA_WIDTH/8-1] <= m_axis_tlast;
                m_fifo_id[M_DATA_WIDTH/8-1] <= m_axis_tid;
                m_fifo_dest[M_DATA_WIDTH/8-1] <= m_axis_tdest;
                m_fifo_user[M_DATA_WIDTH/8-1] <= m_axis_tuser;
                m_fifo_full <= 0;
            end else begin
                m_fifo_data[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_keep[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_valid[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_last[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_id[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_dest[M_DATA_WIDTH/8-1] <= 0;
                m_fifo_user[M_DATA_WIDTH/8-1] <= 0;
            end
        end else begin
            m_axis_tdata_reg <= m_axis_tdata_reg;
            m_axis_tkeep_reg <= m_axis_tkeep_reg;
            m_axis_tvalid_reg <= m_axis_tvalid_reg;
            m_axis_tlast_reg <= m_axis_tlast_reg;
            m_axis_tid_reg <= m_axis_tid_reg;
            m_axis_tdest_reg <= m_axis_tdest_reg;
            m_axis_tuser_reg <= m_axis_tuser_reg;
            m_pause_ack_reg <= m_pause_ack_reg;
            m_status_depth_reg <= m_status_depth_reg;
            m_status_depth_commit_reg <= m_status_depth_commit_reg;
            m_status_overflow_reg <= m_status_overflow_reg;
            m_status_bad_frame_reg <= m_status_bad_frame_reg;
            m_status_good_frame_reg <= m_status_good_frame_reg;
            m_fifo_empty <= m_fifo_empty;
            m_fifo_full <= m_fifo_full;
            m_fifo_read <= m_fifo_read;
            m_fifo_write <= m_fifo_write;
            m_fifo_out_data <= m_fifo_out_data;
            m_fifo_out_keep <= m_fifo_out_keep;
            m_fifo_out_valid <= m_fifo_out_valid;
            m_fifo_out_last <= m_fifo_out_last;
            m_fifo_out_id <= m_fifo_out_id;
            m_fifo_out_dest <= m_fifo_out_dest;
            m_fifo_out_user <= m_fifo_out_user;
            m_pause_req_reg <= m_pause_req;
        end
    end

    assign s_axis_tready = ~s_fifo_full;
    assign m_axis_tdata = m_fifo_out_data;
    assign m_axis_tkeep = m_fifo_out_keep;
    assign m_axis_tvalid = m_fifo_out_valid;
    assign m_axis_tlast = m_fifo_out_last;
    assign m_axis_tid = m_fifo_out_id;
    assign m_axis_tdest = m_fifo_out_dest;
    assign m_axis_tuser = m_fifo_out_user;
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
