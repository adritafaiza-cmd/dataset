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

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    wire s_axis_tvalid_reg;
    wire s_axis_tlast_reg;
    wire [ID_WIDTH-1:0] s_axis_tid_reg;
    wire [DEST_WIDTH-1:0] s_axis_tdest_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg;
    wire s_axis_tready_reg;

    wire [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tlast_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;
    wire m_axis_tready_reg;

    wire s_pause_req_reg;
    wire s_pause_ack_reg;
    wire m_pause_req_reg;
    wire m_pause_ack_reg;

    wire s_status_depth_reg;
    wire s_status_depth_commit_reg;
    wire s_status_overflow_reg;
    wire s_status_bad_frame_reg;
    wire s_status_good_frame_reg;

    wire m_status_depth_reg;
    wire m_status_depth_commit_reg;
    wire m_status_overflow_reg;
    wire m_status_bad_frame_reg;
    wire m_status_good_frame_reg;

    // AXI input handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 1'b0;
        end else begin
            s_axis_tready_reg <= m_axis_tready;
        end
    end

    // AXI output handling
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            m_axis_tvalid_reg <= s_axis_tvalid_reg;
        end
    end

    // Pause handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else begin
            s_pause_ack_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end

    // Status handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
        end else begin
            s_status_depth_reg <= s_status_depth;
            s_status_depth_commit_reg <= s_status_depth_commit;
            s_status_overflow_reg <= s_status_overflow;
            s_status_bad_frame_reg <= s_status_bad_frame;
            s_status_good_frame_reg <= s_status_good_frame;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
        end else begin
            m_status_depth_reg <= m_status_depth;
            m_status_depth_commit_reg <= m_status_depth_commit;
            m_status_overflow_reg <= m_status_overflow;
            m_status_bad_frame_reg <= m_status_bad_frame;
            m_status_good_frame_reg <= m_status_good_frame;
        end
    end

    // Data width conversion
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 1'b0;
            s_axis_tlast_reg <= 1'b0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tdata_reg <= s_axis_tdata_reg;
                m_axis_tkeep_reg <= s_axis_tkeep_reg;
                m_axis_tvalid_reg <= s_axis_tvalid_reg;
                m_axis_tlast_reg <= s_axis_tlast_reg;
                m_axis_tid_reg <= s_axis_tid_reg;
                m_axis_tdest_reg <= s_axis_tdest_reg;
                m_axis_tuser_reg <= s_axis_tuser_reg;
            end
        end
    end

endmodule
