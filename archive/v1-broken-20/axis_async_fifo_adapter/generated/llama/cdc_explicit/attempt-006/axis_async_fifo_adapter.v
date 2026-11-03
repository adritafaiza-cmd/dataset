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
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;
    reg s_axis_tlast_reg;
    reg s_axis_tvalid_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg m_axis_tlast_reg;
    reg m_axis_tvalid_reg;

    reg [$clog2(DEPTH):0] s_status_depth_reg;
    reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;

    reg [$clog2(DEPTH):0] m_status_depth_reg;
    reg [$clog2(DEPTH):0] m_status_depth_commit_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    reg [S_DATA_WIDTH-1:0] fifo_data[S_DATA_WIDTH-1:0];
    reg [S_KEEP_WIDTH-1:0] fifo_keep[S_KEEP_WIDTH-1:0];
    reg [ID_WIDTH-1:0] fifo_id[ID_WIDTH-1:0];
    reg [DEST_WIDTH-1:0] fifo_dest[DEST_WIDTH-1:0];
    reg [USER_WIDTH-1:0] fifo_user[USER_WIDTH-1:0];
    reg fifo_last;
    reg fifo_valid;
    reg fifo_empty;
    reg fifo_full;

    reg [M_DATA_WIDTH-1:0] output_fifo_data[M_DATA_WIDTH-1:0];
    reg [M_KEEP_WIDTH-1:0] output_fifo_keep[M_KEEP_WIDTH-1:0];
    reg [ID_WIDTH-1:0] output_fifo_id[ID_WIDTH-1:0];
    reg [DEST_WIDTH-1:0] output_fifo_dest[DEST_WIDTH-1:0];
    reg [USER_WIDTH-1:0] output_fifo_user[USER_WIDTH-1:0];
    reg output_fifo_last;
    reg output_fifo_valid;
    reg output_fifo_empty;
    reg output_fifo_full;

    integer i;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 1'b0;
            s_axis_tdata_reg <= {S_DATA_WIDTH{1'b0}};
            s_axis_tkeep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_axis_tlast_reg <= 1'b0;
            s_axis_tvalid_reg <= 1'b0;
            s_axis_tid_reg <= {ID_WIDTH{1'b0}};
            s_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            s_axis_tuser_reg <= {USER_WIDTH{1'b0}};
            s_status_depth_reg <= {($clog2(DEPTH)+1){1'b0}};
            s_status_depth_commit_reg <= {($clog2(DEPTH)+1){1'b0}};
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tvalid_reg <= 1'b1;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end
            if (fifo_empty) begin
                s_axis_tready <= 1'b1;
            end else if (fifo_full) begin
                s_axis_tready <= 1'b0;
            end
            if (s_axis_tvalid && !s_axis_tready) begin
                s_status_overflow_reg <= 1'b1;
            end
            if (s_axis_tlast && s_axis_tvalid && s_axis_tready) begin
                s_status_good_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata_reg <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tlast_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tid_reg <= {ID_WIDTH{1'b0}};
            m_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            m_axis_tuser_reg <= {USER_WIDTH{1'b0}};
            m_status_depth_reg <= {($clog2(DEPTH)+1){1'b0}};
            m_status_depth_commit_reg <= {($clog2(DEPTH)+1){1'b0}};
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            if (m_axis_tready && m_axis_tvalid) begin
                m_axis_tdata_reg <= m_axis_tdata;
                m_axis_tkeep_reg <= m_axis_tkeep;
                m_axis_tlast_reg <= m_axis_tlast;
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tid_reg <= m_axis_tid;
                m_axis_tdest_reg <= m_axis_tdest;
                m_axis_tuser_reg <= m_axis_tuser;
            end
            if (output_fifo_empty) begin
                m_axis_tvalid <= 1'b0;
            end else if (output_fifo_full) begin
                m_axis_tvalid <= 1'b1;
            end
            if (m_axis_tready && !m_axis_tvalid) begin
                m_status_overflow_reg <= 1'b1;
            end
            if (m_axis_tlast && m_axis_tvalid && m_axis_tready) begin
                m_status_good_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            fifo_data <= s_axis_tdata;
            fifo_keep <= s_axis_tkeep;
            fifo_last <= s_axis_tlast;
            fifo_valid <= 1'b1;
            fifo_id <= s_axis_tid;
            fifo_dest <= s_axis_tdest;
            fifo_user <= s_axis_tuser;
        end
    end

    always @(posedge m_clk) begin
        if (m_axis_tready && m_axis_tvalid) begin
            output_fifo_data <= m_axis_tdata;
            output_fifo_keep <= m_axis_tkeep;
            output_fifo_last <= m_axis_tlast;
            output_fifo_valid <= 1'b1;
            output_fifo_id <= m_axis_tid;
            output_fifo_dest <= m_axis_tdest;
            output_fifo_user <= m_axis_tuser;
        end
    end

    always @(posedge s_clk) begin
        if (fifo_valid && !fifo_empty) begin
            fifo_valid <= 1'b0;
            fifo_empty <= 1'b0;
            fifo_full <= 1'b1;
        end
    end

    always @(posedge m_clk) begin
        if (output_fifo_valid && !output_fifo_empty) begin
            output_fifo_valid <= 1'b0;
            output_fifo_empty <= 1'b0;
            output_fifo_full <= 1'b1;
        end
    end

    assign s_axis_tready = !fifo_full;
    assign m_axis_tvalid = !output_fifo_empty;

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

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    assign m_axis_tdata = output_fifo_data;
    assign m_axis_tkeep = output_fifo_keep;
    assign m_axis_tlast = output_fifo_last;
    assign m_axis_tid = output_fifo_id;
    assign m_axis_tdest = output_fifo_dest;
    assign m_axis_tuser = output_fifo_user;

endmodule
