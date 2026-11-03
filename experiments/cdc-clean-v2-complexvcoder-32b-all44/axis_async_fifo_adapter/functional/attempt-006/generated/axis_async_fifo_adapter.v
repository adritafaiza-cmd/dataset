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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    /*
     * FIFO control signals
     */
    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync, m_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray_synced, m_rd_ptr_gray_synced;

    reg [ADDR_WIDTH:0] s_depth, m_depth;
    reg [ADDR_WIDTH:0] s_depth_commit, m_depth_commit;

    reg s_full, m_empty;

    reg s_status_overflow_reg, m_status_overflow_reg;
    reg s_status_bad_frame_reg, m_status_bad_frame_reg;
    reg s_status_good_frame_reg, m_status_good_frame_reg;

    /*
     * FIFO memory
     */
    reg [S_DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest [0:DEPTH-1];

    /*
     * AXI input side
     */
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    /*
     * AXI output side
     */
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    /*
     * AXI input side
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_axis_tready <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                mem_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                mem_tid[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                mem_tdest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                s_wr_ptr <= s_wr_ptr + 1;
            end

            s_axis_tready <= !s_full;
            s_status_overflow_reg <= s_status_overflow_reg | (s_axis_tvalid && s_axis_tready && s_full);
        end
    end

    /*
     * AXI output side
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_axis_tvalid_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
            end

            m_axis_tdata_reg <= mem_data[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tkeep_reg <= mem_keep[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tuser_reg <= mem_user[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tlast_reg <= mem_last[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tid_reg <= mem_tid[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tdest_reg <= mem_tdest[m_rd_ptr[ADDR_WIDTH-1:0]];

            m_axis_tvalid_reg <= !m_empty;
            m_status_bad_frame_reg <= m_status_bad_frame_reg | (m_axis_tvalid_reg && m_axis_tready && (m_axis_tuser_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            m_status_good_frame_reg <= m_status_good_frame_reg | (m_axis_tvalid_reg && m_axis_tready && (m_axis_tuser_reg & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE);
        end
    end

    /*
     * Gray code conversion
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_gray <= 0;
        end else begin
            s_wr_ptr_gray <= (s_wr_ptr >> 1) ^ s_wr_ptr;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr_gray <= 0;
        end else begin
            m_rd_ptr_gray <= (m_rd_ptr >> 1) ^ m_rd_ptr;
        end
    end

    /*
     * Gray code synchronization
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_gray_sync <= 0;
            m_rd_ptr_gray_synced <= 0;
        end else begin
            m_rd_ptr_gray_sync <= m_rd_ptr_gray;
            m_rd_ptr_gray_synced <= m_rd_ptr_gray_sync;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_gray_sync <= 0;
            s_wr_ptr_gray_synced <= 0;
        end else begin
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;
            s_wr_ptr_gray_synced <= s_wr_ptr_gray_sync;
        end
    end

    /*
     * Depth calculation
     */
    assign s_depth = s_wr_ptr_gray_synced - m_rd_ptr;
    assign m_depth = s_wr_ptr - m_rd_ptr_gray_synced;

    assign s_depth_commit = s_depth;
    assign m_depth_commit = m_depth;

    assign s_full = (s_depth == DEPTH);
    assign m_empty = (m_depth == 0);

    /*
     * Status outputs
     */
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    /*
     * AXI output signals
     */
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    /*
     * Pause signals
     */
    assign s_pause_ack = 0;
    assign m_pause_ack = 0;

endmodule
