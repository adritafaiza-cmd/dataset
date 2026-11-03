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
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync, s_wr_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync, m_rd_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg [$clog2(DEPTH):0] s_depth_commit, m_depth_commit;
    reg s_full, m_full;
    reg s_empty, m_empty;
    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];
    reg mem_tlast [DEPTH-1:0];

    // Write side
    reg s_axis_tready_reg;
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    // Read side
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    // Pause signals
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Gray code conversion
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray code conversion
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = $clog2(DEPTH); i > 0; i = i - 1)
            bin[i-1] = bin[i] ^ bin[i-1];
        return bin;
    endfunction

    // Write side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_wr_ptr_gray_sync2 <= 0;
            s_axis_tready_reg <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_full <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            s_wr_ptr_gray <= bin2gray(s_wr_ptr);
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;
            s_wr_ptr_gray_sync2 <= s_wr_ptr_gray_sync;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                mem_data[s_wr_ptr] <= s_axis_tdata;
                mem_keep[s_wr_ptr] <= s_axis_tkeep;
                mem_tid[s_wr_ptr] <= s_axis_tid;
                mem_tdest[s_wr_ptr] <= s_axis_tdest;
                mem_tuser[s_wr_ptr] <= s_axis_tuser;
                mem_tlast[s_wr_ptr] <= s_axis_tlast;
                s_wr_ptr <= s_wr_ptr + 1;
            end

            s_full <= (s_wr_ptr_gray_sync2 == {~m_rd_ptr_gray[$clog2(DEPTH)], m_rd_ptr_gray[$clog2(DEPTH)-1:0]});
            s_axis_tready_reg <= ~s_full;

            if (s_axis_tvalid && s_axis_tready_reg && s_axis_tlast)
                s_good_frame <= 1;
            else
                s_good_frame <= 0;

            if (s_axis_tvalid && s_axis_tready_reg && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                s_bad_frame <= 1;
            else
                s_bad_frame <= 0;

            if (s_full && s_axis_tvalid && s_axis_tready_reg)
                s_overflow <= 1;
            else
                s_overflow <= 0;
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_sync <= 0;
            m_rd_ptr_gray_sync2 <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_empty <= 1;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            m_rd_ptr_gray <= bin2gray(m_rd_ptr);
            m_rd_ptr_gray_sync <= m_rd_ptr_gray;
            m_rd_ptr_gray_sync2 <= m_rd_ptr_gray_sync;

            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
            end

            m_empty <= (m_rd_ptr_gray_sync2 == s_wr_ptr_gray);

            if (!m_empty) begin
                m_axis_tdata_reg <= mem_data[m_rd_ptr];
                m_axis_tkeep_reg <= mem_keep[m_rd_ptr];
                m_axis_tid_reg <= mem_tid[m_rd_ptr];
                m_axis_tdest_reg <= mem_tdest[m_rd_ptr];
                m_axis_tuser_reg <= mem_tuser[m_rd_ptr];
                m_axis_tlast_reg <= mem_tlast[m_rd_ptr];
                m_axis_tvalid_reg <= 1;
            end else begin
                m_axis_tvalid_reg <= 0;
            end

            if (m_axis_tvalid_reg && m_axis_tready && m_axis_tlast_reg)
                m_good_frame <= 1;
            else
                m_good_frame <= 0;

            if (m_axis_tvalid_reg && m_axis_tready && (m_axis_tuser_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                m_bad_frame <= 1;
            else
                m_bad_frame <= 0;
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // Pause signals
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status signals
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
