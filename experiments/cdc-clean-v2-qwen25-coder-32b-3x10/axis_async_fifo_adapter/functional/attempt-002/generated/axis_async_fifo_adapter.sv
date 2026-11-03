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

    // FIFO control signals
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_next, s_rd_ptr, s_rd_ptr_next;
    reg [$clog2(DEPTH):0] m_wr_ptr, m_wr_ptr_next, m_rd_ptr, m_rd_ptr_next;
    reg [$clog2(DEPTH):0] s_depth, s_depth_commit, m_depth, m_depth_commit;
    reg s_full, s_empty, m_full, m_empty;
    reg s_overflow, m_overflow;
    reg s_good_frame, s_bad_frame, m_good_frame, m_bad_frame;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];

    // FIFO read/write control
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    // Width adapter control
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift;
    reg s_axis_tlast_shift;
    reg [ID_WIDTH-1:0] s_axis_tid_shift;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift;
    reg [M_DATA_WIDTH/S_DATA_WIDTH-1:0] shift_cnt;

    // Pause control
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Status control
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

    // FIFO write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_overflow <= 0;
            s_good_frame <= 0;
            s_bad_frame <= 0;
        end else begin
            s_wr_ptr <= s_wr_ptr_next;
            s_depth <= s_depth_commit;
            s_depth_commit <= s_depth_commit + (s_axis_tvalid & s_axis_tready_reg) - (m_axis_tvalid_reg & m_axis_tready);
            s_full <= (s_depth_commit == DEPTH);
            s_empty <= (s_depth_commit == 0);
            s_overflow <= s_overflow | (s_axis_tvalid & s_axis_tready_reg & s_full);
            if (s_axis_tvalid & s_axis_tready_reg & s_axis_tlast) begin
                if (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    s_bad_frame <= 1;
                end else begin
                    s_good_frame <= 1;
                end
            end
        end
    end

    // FIFO read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_overflow <= 0;
            m_good_frame <= 0;
            m_bad_frame <= 0;
        end else begin
            m_rd_ptr <= m_rd_ptr_next;
            m_depth <= m_depth_commit;
            m_depth_commit <= m_depth_commit + (s_axis_tvalid & s_axis_tready_reg) - (m_axis_tvalid_reg & m_axis_tready);
            m_full <= (m_depth_commit == DEPTH);
            m_empty <= (m_depth_commit == 0);
            m_overflow <= m_overflow | (s_axis_tvalid & s_axis_tready_reg & m_full);
            if (m_axis_tvalid_reg & m_axis_tready & m_axis_tlast_reg) begin
                if (m_axis_tuser_reg & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame <= 1;
                end else begin
                    m_good_frame <= 1;
                end
            end
        end
    end

    // FIFO write pointer logic
    always @(*) begin
        s_wr_ptr_next = s_wr_ptr;
        if (s_axis_tvalid & s_axis_tready_reg & !s_full) begin
            s_wr_ptr_next = s_wr_ptr + 1;
        end
    end

    // FIFO read pointer logic
    always @(*) begin
        m_rd_ptr_next = m_rd_ptr;
        if (m_axis_tvalid_reg & m_axis_tready & !m_empty) begin
            m_rd_ptr_next = m_rd_ptr + 1;
        end
    end

    // FIFO write data
    always @(posedge s_clk) begin
        if (s_axis_tvalid & s_axis_tready_reg & !s_full) begin
            mem_data[s_wr_ptr] <= s_axis_tdata;
            mem_keep[s_wr_ptr] <= s_axis_tkeep;
            mem_last[s_wr_ptr] <= s_axis_tlast;
            mem_tid[s_wr_ptr] <= s_axis_tid;
            mem_tdest[s_wr_ptr] <= s_axis_tdest;
            mem_tuser[s_wr_ptr] <= s_axis_tuser;
        end
    end

    // FIFO read data
    always @(posedge m_clk) begin
        if (m_axis_tvalid_reg & m_axis_tready & !m_empty) begin
            s_axis_tdata_reg <= mem_data[m_rd_ptr];
            s_axis_tkeep_reg <= mem_keep[m_rd_ptr];
            s_axis_tlast_reg <= mem_last[m_rd_ptr];
            s_axis_tid_reg <= mem_tid[m_rd_ptr];
            s_axis_tdest_reg <= mem_tdest[m_rd_ptr];
            s_axis_tuser_reg <= mem_tuser[m_rd_ptr];
        end
    end

    // Width adapter logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_axis_tdata_shift <= 0;
            s_axis_tkeep_shift <= 0;
            s_axis_tlast_shift <= 0;
            s_axis_tid_shift <= 0;
            s_axis_tdest_shift <= 0;
            s_axis_tuser_shift <= 0;
            shift_cnt <= 0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_axis_tvalid_reg <= 0;
        end else begin
            if (m_axis_tvalid_reg & m_axis_tready) begin
                if (shift_cnt == M_DATA_WIDTH/S_DATA_WIDTH - 1) begin
                    shift_cnt <= 0;
                    m_axis_tvalid_reg <= 0;
                end else begin
                    shift_cnt <= shift_cnt + 1;
                end
            end else begin
                if (s_axis_tvalid_reg & s_axis_tready_reg & !m_axis_tvalid_reg) begin
                    s_axis_tdata_shift <= s_axis_tdata_reg;
                    s_axis_tkeep_shift <= s_axis_tkeep_reg;
                    s_axis_tlast_shift <= s_axis_tlast_reg;
                    s_axis_tid_shift <= s_axis_tid_reg;
                    s_axis_tdest_shift <= s_axis_tdest_reg;
                    s_axis_tuser_shift <= s_axis_tuser_reg;
                    shift_cnt <= 0;
                    m_axis_tvalid_reg <= 1;
                end
            end

            if (m_axis_tvalid_reg) begin
                m_axis_tdata_reg[M_DATA_WIDTH-1:S_DATA_WIDTH*shift_cnt] <= s_axis_tdata_shift;
                m_axis_tkeep_reg[M_KEEP_WIDTH-1:S_KEEP_WIDTH*shift_cnt] <= s_axis_tkeep_shift;
                m_axis_tlast_reg <= s_axis_tlast_shift;
                m_axis_tid_reg <= s_axis_tid_shift;
                m_axis_tdest_reg <= s_axis_tdest_shift;
                m_axis_tuser_reg <= s_axis_tuser_shift;
            end
        end
    end

    // AXI input handshake
    always @(*) begin
        s_axis_tready_reg = !s_full & !s_pause_req;
        s_axis_tready = s_axis_tready_reg;
    end

    // AXI output handshake
    always @(*) begin
        m_axis_tvalid_reg = !m_empty & !m_pause_req;
        m_axis_tvalid = m_axis_tvalid_reg;
    end

    // Pause control
    always @(*) begin
        s_pause_ack_reg = s_pause_req & s_axis_tready_reg;
        s_pause_ack = s_pause_ack_reg;
        m_pause_ack_reg = m_pause_req & m_axis_tvalid_reg;
        m_pause_ack = m_pause_ack_reg;
    end

    // Status control
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            s_status_depth_reg <= s_depth;
            s_status_depth_commit_reg <= s_depth_commit;
            s_status_overflow_reg <= s_overflow;
            s_status_bad_frame_reg <= s_bad_frame;
            s_status_good_frame_reg <= s_good_frame;
            if (s_axis_tvalid & s_axis_tready_reg & s_axis_tlast) begin
                s_bad_frame <= 0;
                s_good_frame <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            m_status_depth_reg <= m_depth;
            m_status_depth_commit_reg <= m_depth_commit;
            m_status_overflow_reg <= m_overflow;
            m_status_bad_frame_reg <= m_bad_frame;
            m_status_good_frame_reg <= m_good_frame;
            if (m_axis_tvalid_reg & m_axis_tready & m_axis_tlast_reg) begin
                m_bad_frame <= 0;
                m_good_frame <= 0;
            end
        end
    end

    // Status outputs
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

    // AXI output data
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule
