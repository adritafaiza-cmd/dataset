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
    localparam WORDS_PER_BEAT = (S_DATA_WIDTH > M_DATA_WIDTH) ? (S_DATA_WIDTH / M_DATA_WIDTH) : (M_DATA_WIDTH / S_DATA_WIDTH);

    // FIFO signals
    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt, s_wr_ptr_gray_synced, s_wr_ptr_synced;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt, m_rd_ptr_gray_synced, m_rd_ptr_synced;
    reg [ADDR_WIDTH:0] s_depth, m_depth;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg [1:0] fifo_sideband [0:DEPTH-1];
    reg [USER_WIDTH-1:0] fifo_user [0:DEPTH-1];

    // FIFO flags
    reg s_full, m_empty, s_overflow, m_overflow;
    reg s_tlast_fifo, s_tlast_fifo_d;
    reg [USER_WIDTH-1:0] s_tuser_fifo, s_tuser_fifo_d;

    // Status signals
    reg [$clog2(DEPTH):0] s_status_depth_reg, s_status_depth_commit_reg;
    reg [$clog2(DEPTH):0] m_status_depth_reg, m_status_depth_commit_reg;
    reg s_status_bad_frame_reg, s_status_good_frame_reg;
    reg m_status_bad_frame_reg, m_status_good_frame_reg;

    // Handshake signals
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;

    // Pause signals
    reg s_pause_ack_reg, m_pause_ack_reg;

    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
            bin[i] = bin[i + 1] ^ bin[i];
        end
        gray2bin = bin;
    endfunction

    // Write side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_synced <= 0;
            s_wr_ptr_synced <= 0;
            s_depth <= 0;
            s_full <= 0;
            s_overflow <= 0;
            s_tlast_fifo <= 0;
            s_tuser_fifo <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
            s_axis_tready_reg <= 0;
        end else begin
            s_wr_ptr_gray_nxt = bin2gray(s_wr_ptr + 1);
            s_wr_ptr_gray_synced <= m_rd_ptr_gray;
            s_wr_ptr_synced <= gray2bin(s_wr_ptr_gray_synced);
            s_depth <= s_wr_ptr - s_rd_ptr_synced;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                fifo_mem[s_wr_ptr] <= s_axis_tdata;
                fifo_keep[s_wr_ptr] <= s_axis_tkeep;
                fifo_sideband[s_wr_ptr] <= {s_axis_tlast, s_axis_tuser};
                fifo_user[s_wr_ptr] <= s_axis_tuser;
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= s_wr_ptr_gray_nxt;
            end

            s_full <= (s_depth == DEPTH - 1);
            s_overflow <= (s_full && s_axis_tvalid && s_axis_tready_reg);
            s_tlast_fifo <= s_axis_tlast;
            s_tuser_fifo <= s_axis_tuser;

            s_status_depth_reg <= s_depth;
            s_status_depth_commit_reg <= s_depth;
            s_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            s_status_good_frame_reg <= s_axis_tlast && s_axis_tvalid && s_axis_tready_reg;

            s_axis_tready_reg <= !s_full;
        end
    end

    // Read side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_synced <= 0;
            m_rd_ptr_synced <= 0;
            m_depth <= 0;
            m_empty <= 1;
            m_tlast_fifo <= 0;
            m_tuser_fifo <= 0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
            m_axis_tvalid_reg <= 0;
        end else begin
            m_rd_ptr_gray_nxt = bin2gray(m_rd_ptr + 1);
            m_rd_ptr_gray_synced <= s_wr_ptr_gray;
            m_rd_ptr_synced <= gray2bin(m_rd_ptr_gray_synced);
            m_depth <= s_wr_ptr_synced - m_rd_ptr;

            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= m_rd_ptr_gray_nxt;
            end

            m_empty <= (m_depth == 0);
            m_tlast_fifo <= fifo_sideband[m_rd_ptr][1];
            m_tuser_fifo <= fifo_user[m_rd_ptr];

            m_status_depth_reg <= m_depth;
            m_status_depth_commit_reg <= m_depth;
            m_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            m_status_good_frame_reg <= m_tlast_fifo && m_axis_tvalid_reg && m_axis_tready;

            m_axis_tvalid_reg <= !m_empty;
        end
    end

    // Output assignment
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = fifo_mem[m_rd_ptr];
    assign m_axis_tkeep = fifo_keep[m_rd_ptr];
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = fifo_sideband[m_rd_ptr][1];
    assign m_axis_tid = ID_ENABLE ? fifo_sideband[m_rd_ptr][0] : 0;
    assign m_axis_tdest = DEST_ENABLE ? fifo_sideband[m_rd_ptr][0] : 0;
    assign m_axis_tuser = fifo_user[m_rd_ptr];

    // Pause assignment
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status assignment
    assign s_status_depth = s_status_depth_reg;
    assign s_status_depth_commit = s_status_depth_commit_reg;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = m_status_depth_reg;
    assign m_status_depth_commit = m_status_depth_commit_reg;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule
