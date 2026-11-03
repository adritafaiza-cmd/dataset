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

    // Internal signals
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_next, s_rd_ptr, s_rd_ptr_next;
    reg [$clog2(DEPTH):0] m_wr_ptr, m_wr_ptr_next, m_rd_ptr, m_rd_ptr_next;
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg [S_DATA_WIDTH-1:0] s_fifo_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep [0:DEPTH-1];
    reg s_fifo_tlast [0:DEPTH-1];
    reg [ID_WIDTH-1:0] s_fifo_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] s_fifo_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] s_fifo_tuser [0:DEPTH-1];
    reg s_fifo_valid [0:DEPTH-1];
    reg s_fifo_full, s_fifo_empty, m_fifo_full, m_fifo_empty;
    reg s_axis_tready_int, m_axis_tvalid_int;
    reg s_pause_ack_int, m_pause_ack_int;
    reg s_status_overflow_int, s_status_bad_frame_int, s_status_good_frame_int;
    reg m_status_overflow_int, m_status_bad_frame_int, m_status_good_frame_int;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_next;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_next;
    reg s_axis_tlast_next;
    reg [ID_WIDTH-1:0] s_axis_tid_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_next;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_next;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_next;
    reg m_axis_tlast_next;
    reg [ID_WIDTH-1:0] m_axis_tid_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_next;
    reg s_fifo_commit, m_fifo_commit;
    reg s_fifo_commit_next, m_fifo_commit_next;
    reg s_fifo_bad_frame, m_fifo_bad_frame;
    reg s_fifo_good_frame, m_fifo_good_frame;
    reg s_fifo_bad_frame_next, m_fifo_bad_frame_next;
    reg s_fifo_good_frame_next, m_fifo_good_frame_next;

    // FIFO write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_next <= 0;
            s_depth <= 0;
            s_fifo_full <= 0;
            s_fifo_empty <= 1;
            s_fifo_commit <= 0;
            s_fifo_bad_frame <= 0;
            s_fifo_good_frame <= 0;
        end else begin
            s_wr_ptr <= s_wr_ptr_next;
            s_depth <= s_depth + s_fifo_commit_next - m_fifo_commit;
            s_fifo_full <= (s_depth == DEPTH);
            s_fifo_empty <= (s_depth == 0);
            s_fifo_commit <= s_fifo_commit_next;
            s_fifo_bad_frame <= s_fifo_bad_frame_next;
            s_fifo_good_frame <= s_fifo_good_frame_next;
            if (s_axis_tvalid && s_axis_tready_int && !s_fifo_full) begin
                s_fifo_data[s_wr_ptr_next] <= s_axis_tdata_reg;
                s_fifo_keep[s_wr_ptr_next] <= s_axis_tkeep_reg;
                s_fifo_tlast[s_wr_ptr_next] <= s_axis_tlast_reg;
                s_fifo_tid[s_wr_ptr_next] <= s_axis_tid_reg;
                s_fifo_tdest[s_wr_ptr_next] <= s_axis_tdest_reg;
                s_fifo_tuser[s_wr_ptr_next] <= s_axis_tuser_reg;
                s_fifo_valid[s_wr_ptr_next] <= 1;
            end
        end
    end

    // FIFO read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_depth <= 0;
            m_fifo_full <= 0;
            m_fifo_empty <= 1;
            m_fifo_commit <= 0;
            m_fifo_bad_frame <= 0;
            m_fifo_good_frame <= 0;
        end else begin
            m_rd_ptr <= m_rd_ptr_next;
            m_depth <= m_depth + s_fifo_commit - m_fifo_commit_next;
            m_fifo_full <= (m_depth == DEPTH);
            m_fifo_empty <= (m_depth == 0);
            m_fifo_commit <= m_fifo_commit_next;
            m_fifo_bad_frame <= m_fifo_bad_frame_next;
            m_fifo_good_frame <= m_fifo_good_frame_next;
            if (m_axis_tvalid_int && m_axis_tready && !m_fifo_empty) begin
                s_fifo_valid[m_rd_ptr_next] <= 0;
            end
        end
    end

    // FIFO pointers
    always @(*) begin
        s_wr_ptr_next = s_wr_ptr;
        m_rd_ptr_next = m_rd_ptr;
        if (s_axis_tvalid && s_axis_tready_int && !s_fifo_full) begin
            s_wr_ptr_next = s_wr_ptr + 1;
        end
        if (m_axis_tvalid_int && m_axis_tready && !m_fifo_empty) begin
            m_rd_ptr_next = m_rd_ptr + 1;
        end
    end

    // FIFO commit logic
    always @(*) begin
        s_fifo_commit_next = 0;
        m_fifo_commit_next = 0;
        if (s_axis_tvalid && s_axis_tready_int && !s_fifo_full) begin
            s_fifo_commit_next = 1;
        end
        if (m_axis_tvalid_int && m_axis_tready && !m_fifo_empty) begin
            m_fifo_commit_next = 1;
        end
    end

    // FIFO bad/good frame logic
    always @(*) begin
        s_fifo_bad_frame_next = s_fifo_bad_frame;
        s_fifo_good_frame_next = s_fifo_good_frame;
        m_fifo_bad_frame_next = m_fifo_bad_frame;
        m_fifo_good_frame_next = m_fifo_good_frame;
        if (s_axis_tvalid && s_axis_tready_int && !s_fifo_full) begin
            if (s_axis_tlast_reg) begin
                if (s_axis_tuser_reg & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    s_fifo_bad_frame_next = 1;
                end else begin
                    s_fifo_good_frame_next = 1;
                end
            end
        end
        if (m_axis_tvalid_int && m_axis_tready && !m_fifo_empty) begin
            if (s_fifo_tlast[m_rd_ptr]) begin
                if (s_fifo_tuser[m_rd_ptr] & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    m_fifo_bad_frame_next = 1;
                end else begin
                    m_fifo_good_frame_next = 1;
                end
            end
        end
    end

    // FIFO read data
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (m_axis_tvalid_int && m_axis_tready && !m_fifo_empty) begin
                m_axis_tdata_reg <= s_fifo_data[m_rd_ptr];
                m_axis_tkeep_reg <= s_fifo_keep[m_rd_ptr];
                m_axis_tlast_reg <= s_fifo_tlast[m_rd_ptr];
                m_axis_tid_reg <= s_fifo_tid[m_rd_ptr];
                m_axis_tdest_reg <= s_fifo_tdest[m_rd_ptr];
                m_axis_tuser_reg <= s_fifo_tuser[m_rd_ptr];
            end
        end
    end

    // FIFO write data
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_int && !s_fifo_full) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end
        end
    end

    // FIFO status
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_fifo_commit ? s_depth + 1 : s_depth;
    assign s_status_overflow = s_status_overflow_int;
    assign s_status_bad_frame = s_status_bad_frame_int;
    assign s_status_good_frame = s_status_good_frame_int;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_fifo_commit ? m_depth - 1 : m_depth;
    assign m_status_overflow = m_status_overflow_int;
    assign m_status_bad_frame = m_status_bad_frame_int;
    assign m_status_good_frame = m_status_good_frame_int;

    // FIFO overflow logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow_int <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_int && s_fifo_full) begin
                s_status_overflow_int <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow_int <= 0;
        end else begin
            if (m_axis_tvalid_int && m_axis_tready && m_fifo_full) begin
                m_status_overflow_int <= 1;
            end
        end
    end

    // FIFO bad frame logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame_int <= 0;
        end else begin
            if (s_fifo_bad_frame) begin
                s_status_bad_frame_int <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame_int <= 0;
        end else begin
            if (m_fifo_bad_frame) begin
                m_status_bad_frame_int <= 1;
            end
        end
    end

    // FIFO good frame logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_good_frame_int <= 0;
        end else begin
            if (s_fifo_good_frame) begin
                s_status_good_frame_int <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_good_frame_int <= 0;
        end else begin
            if (m_fifo_good_frame) begin
                m_status_good_frame_int <= 1;
            end
        end
    end

    // FIFO pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_int <= 0;
        end else begin
            if (s_pause_req) begin
                s_pause_ack_int <= 1;
            end else begin
                s_pause_ack_int <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_int <= 0;
        end else begin
            if (m_pause_req) begin
                m_pause_ack_int <= 1;
            end else begin
                m_pause_ack_int <= 0;
            end
        end
    end

    // FIFO ready/valid logic
    assign s_axis_tready_int = !s_fifo_full && !s_pause_req;
    assign m_axis_tvalid_int = !m_fifo_empty && !m_pause_req;

    // Width adaptation
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
        end else begin
            if (m_axis_tvalid_int && m_axis_tready) begin
                if (M_DATA_WIDTH > S_DATA_WIDTH) begin
                    m_axis_tdata <= {m_axis_tdata[M_DATA_WIDTH-1:S_DATA_WIDTH], m_axis_tdata_reg};
                    m_axis_tkeep <= {m_axis_tkeep[M_KEEP_WIDTH-1:S_KEEP_WIDTH], m_axis_tkeep_reg};
                end else begin
                    m_axis_tdata <= m_axis_tdata_reg[M_DATA_WIDTH-1:0];
                    m_axis_tkeep <= m_axis_tkeep_reg[M_KEEP_WIDTH-1:0];
                end
            end
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign s_pause_ack = s_pause_ack_int;
    assign m_pause_ack = m_pause_ack_int;

endmodule
