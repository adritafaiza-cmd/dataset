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
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt;
    reg [$clog2(DEPTH):0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_nxt;
    reg [$clog2(DEPTH):0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_nxt;
    reg [$clog2(DEPTH):0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];
    reg mem_tlast [DEPTH-1:0];

    // FIFO status
    reg [$clog2(DEPTH):0] s_depth, s_depth_commit;
    reg [$clog2(DEPTH):0] m_depth, m_depth_commit;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    // FIFO flags
    reg s_full, s_empty, s_almost_full, s_almost_empty;
    reg m_full, m_empty, m_almost_full, m_almost_empty;

    // Pause control
    reg s_pause_ack_reg, m_pause_ack_reg;
    reg s_pause, m_pause;

    // FIFO write and read enable
    reg s_wr_en, s_rd_en;
    reg m_wr_en, m_rd_en;

    // FIFO data
    reg [S_DATA_WIDTH-1:0] s_fifo_data;
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep;
    reg [ID_WIDTH-1:0] s_fifo_tid;
    reg [DEST_WIDTH-1:0] s_fifo_tdest;
    reg [USER_WIDTH-1:0] s_fifo_tuser;
    reg s_fifo_tlast;

    reg [M_DATA_WIDTH-1:0] m_fifo_data;
    reg [M_KEEP_WIDTH-1:0] m_fifo_keep;
    reg [ID_WIDTH-1:0] m_fifo_tid;
    reg [DEST_WIDTH-1:0] m_fifo_tdest;
    reg [USER_WIDTH-1:0] m_fifo_tuser;
    reg m_fifo_tlast;

    // FIFO control logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_nxt <= 0;
            s_rd_ptr <= 0;
            s_rd_ptr_gray <= 0;
            s_rd_ptr_gray_nxt <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_almost_full <= 0;
            s_almost_empty <= 1;
        end else begin
            s_wr_ptr_gray_nxt <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
            s_rd_ptr_gray_nxt <= s_rd_ptr ^ (s_rd_ptr >> 1);

            if (s_wr_en && !s_full) begin
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= s_wr_ptr_gray_nxt;
                mem_data[s_wr_ptr] <= s_axis_tdata;
                mem_keep[s_wr_ptr] <= s_axis_tkeep;
                mem_tid[s_wr_ptr] <= s_axis_tid;
                mem_tdest[s_wr_ptr] <= s_axis_tdest;
                mem_tuser[s_wr_ptr] <= s_axis_tuser;
                mem_tlast[s_wr_ptr] <= s_axis_tlast;
                s_depth <= s_depth + 1;
                s_full <= (s_depth == DEPTH - 1);
                s_empty <= 0;
                s_almost_full <= (s_depth == DEPTH - 2);
                s_almost_empty <= 0;
            end else if (s_rd_en && !s_empty) begin
                s_rd_ptr <= s_rd_ptr + 1;
                s_rd_ptr_gray <= s_rd_ptr_gray_nxt;
                s_depth <= s_depth - 1;
                s_full <= 0;
                s_empty <= (s_depth == 0);
                s_almost_full <= 0;
                s_almost_empty <= (s_depth == 1);
            end

            s_depth_commit <= s_depth;
            s_overflow <= s_wr_en && s_full;
            s_bad_frame <= 0; // Placeholder for bad frame detection
            s_good_frame <= 0; // Placeholder for good frame detection
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 0;
            m_wr_ptr_gray_nxt <= 0;
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_nxt <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_almost_full <= 0;
            m_almost_empty <= 1;
        end else begin
            m_wr_ptr_gray_nxt <= (m_wr_ptr + 1) ^ ((m_wr_ptr + 1) >> 1);
            m_rd_ptr_gray_nxt <= m_rd_ptr ^ (m_rd_ptr >> 1);

            if (m_wr_en && !m_full) begin
                m_wr_ptr <= m_wr_ptr + 1;
                m_wr_ptr_gray <= m_wr_ptr_gray_nxt;
                m_depth <= m_depth + 1;
                m_full <= (m_depth == DEPTH - 1);
                m_empty <= 0;
                m_almost_full <= (m_depth == DEPTH - 2);
                m_almost_empty <= 0;
            end else if (m_rd_en && !m_empty) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= m_rd_ptr_gray_nxt;
                m_depth <= m_depth - 1;
                m_full <= 0;
                m_empty <= (m_depth == 0);
                m_almost_full <= 0;
                m_almost_empty <= (m_depth == 1);
            end

            m_depth_commit <= m_depth;
            m_overflow <= m_wr_en && m_full;
            m_bad_frame <= 0; // Placeholder for bad frame detection
            m_good_frame <= 0; // Placeholder for good frame detection
        end
    end

    // FIFO read and write enable
    assign s_wr_en = s_axis_tvalid && s_axis_tready;
    assign s_rd_en = !s_empty && m_axis_tready && !m_full;

    assign m_wr_en = !m_empty && s_axis_tready && !s_full;
    assign m_rd_en = m_axis_tvalid && m_axis_tready;

    // FIFO data read
    assign s_fifo_data = mem_data[s_rd_ptr];
    assign s_fifo_keep = mem_keep[s_rd_ptr];
    assign s_fifo_tid = mem_tid[s_rd_ptr];
    assign s_fifo_tdest = mem_tdest[s_rd_ptr];
    assign s_fifo_tuser = mem_tuser[s_rd_ptr];
    assign s_fifo_tlast = mem_tlast[s_rd_ptr];

    // FIFO data write
    assign m_fifo_data = mem_data[m_wr_ptr];
    assign m_fifo_keep = mem_keep[m_wr_ptr];
    assign m_fifo_tid = mem_tid[m_wr_ptr];
    assign m_fifo_tdest = mem_tdest[m_wr_ptr];
    assign m_fifo_tuser = mem_tuser[m_wr_ptr];
    assign m_fifo_tlast = mem_tlast[m_wr_ptr];

    // Width conversion
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else if (m_wr_en) begin
            m_axis_tdata_reg <= m_fifo_data;
            m_axis_tkeep_reg <= m_fifo_keep;
            m_axis_tvalid_reg <= 1;
            m_axis_tlast_reg <= m_fifo_tlast;
            m_axis_tid_reg <= m_fifo_tid;
            m_axis_tdest_reg <= m_fifo_tdest;
            m_axis_tuser_reg <= m_fifo_tuser;
        end else if (m_axis_tready) begin
            m_axis_tvalid_reg <= 0;
        end
    end

    // AXI handshake
    assign s_axis_tready = !s_full && !s_pause;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // Pause control
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
            s_pause <= 0;
        end else begin
            if (s_pause_req && !s_pause) begin
                s_pause_ack_reg <= 1;
                s_pause <= 1;
            end else if (s_pause && !s_pause_req) begin
                s_pause_ack_reg <= 0;
                s_pause <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
            m_pause <= 0;
        end else begin
            if (m_pause_req && !m_pause) begin
                m_pause_ack_reg <= 1;
                m_pause <= 1;
            end else if (m_pause && !m_pause_req) begin
                m_pause_ack_reg <= 0;
                m_pause <= 0;
            end
        end
    end

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
