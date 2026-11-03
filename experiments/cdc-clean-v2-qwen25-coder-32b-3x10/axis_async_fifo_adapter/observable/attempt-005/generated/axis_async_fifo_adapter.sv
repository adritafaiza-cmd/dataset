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
    localparam S_BEAT_WIDTH = S_DATA_WIDTH + (S_KEEP_ENABLE ? S_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) + 1;
    localparam M_BEAT_WIDTH = M_DATA_WIDTH + (M_KEEP_ENABLE ? M_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) + 1;

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync, s_wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_sync, s_rd_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_sync, m_wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync, m_rd_ptr_gray_sync2;

    reg [S_BEAT_WIDTH-1:0] mem [DEPTH-1:0];
    reg [M_BEAT_WIDTH-1:0] m_axis_tdata_reg, m_axis_tkeep_reg, m_axis_tlast_reg, m_axis_tid_reg, m_axis_tdest_reg, m_axis_tuser_reg;
    reg s_axis_tready_reg, m_axis_tvalid_reg, s_pause_ack_reg, m_pause_ack_reg;
    reg s_status_overflow_reg, s_status_bad_frame_reg, s_status_good_frame_reg;
    reg m_status_overflow_reg, m_status_bad_frame_reg, m_status_good_frame_reg;

    reg [ADDR_WIDTH:0] s_status_depth_reg, s_status_depth_commit_reg;
    reg [ADDR_WIDTH:0] m_status_depth_reg, m_status_depth_commit_reg;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1)
            bin[i-1] = bin[i] ^ bin[i-1];
        gray2bin = bin;
    endfunction

    // Synchronous FIFO Write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_wr_ptr_gray_sync2 <= 0;
            s_axis_tready_reg <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_wr_ptr;
            reg [ADDR_WIDTH:0] next_wr_ptr_gray;
            reg [ADDR_WIDTH:0] next_wr_ptr_gray_sync;
            reg [ADDR_WIDTH:0] next_wr_ptr_gray_sync2;
            reg [ADDR_WIDTH:0] next_depth;
            reg [ADDR_WIDTH:0] next_depth_commit;
            reg s_axis_tready_next;
            reg s_status_overflow_next;
            reg s_status_bad_frame_next;
            reg s_status_good_frame_next;

            next_wr_ptr = s_wr_ptr;
            next_wr_ptr_gray = s_wr_ptr_gray;
            next_wr_ptr_gray_sync = s_wr_ptr_gray_sync;
            next_wr_ptr_gray_sync2 = s_wr_ptr_gray_sync2;
            next_depth = s_status_depth_reg;
            next_depth_commit = s_status_depth_commit_reg;
            s_axis_tready_next = s_axis_tready_reg;
            s_status_overflow_next = s_status_overflow_reg;
            s_status_bad_frame_next = s_status_bad_frame_reg;
            s_status_good_frame_next = s_status_good_frame_reg;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                next_wr_ptr = s_wr_ptr + 1;
                next_wr_ptr_gray = bin2gray(next_wr_ptr);
                next_depth = next_depth + 1;
                next_depth_commit = next_depth_commit + 1;
            end

            if (next_depth == DEPTH) begin
                s_status_overflow_next = 1;
            end else begin
                s_status_overflow_next = 0;
            end

            if (s_axis_tvalid && s_axis_tready_reg && s_axis_tlast) begin
                if (s_status_bad_frame_reg) begin
                    s_status_bad_frame_next = 0;
                end else begin
                    s_status_good_frame_next = 1;
                end
            end

            if (s_axis_tvalid && s_axis_tready_reg && s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                s_status_bad_frame_next = 1;
            end

            s_wr_ptr <= next_wr_ptr;
            s_wr_ptr_gray <= next_wr_ptr_gray;
            s_wr_ptr_gray_sync <= next_wr_ptr_gray;
            s_wr_ptr_gray_sync2 <= s_wr_ptr_gray_sync;
            s_status_depth_reg <= next_depth;
            s_status_depth_commit_reg <= next_depth_commit;
            s_status_overflow_reg <= s_status_overflow_next;
            s_status_bad_frame_reg <= s_status_bad_frame_next;
            s_status_good_frame_reg <= s_status_good_frame_next;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                reg [S_BEAT_WIDTH-1:0] beat;
                beat = s_axis_tdata;
                if (S_KEEP_ENABLE) beat = {beat, s_axis_tkeep};
                if (ID_ENABLE) beat = {beat, s_axis_tid};
                if (DEST_ENABLE) beat = {beat, s_axis_tdest};
                if (USER_ENABLE) beat = {beat, s_axis_tuser};
                beat = {beat, s_axis_tlast};
                mem[s_wr_ptr[ADDR_WIDTH-1:0]] <= beat;
            end

            if (s_status_depth_reg < DEPTH && !s_pause_req) begin
                s_axis_tready_next = 1;
            end else begin
                s_axis_tready_next = 0;
            end

            s_axis_tready_reg <= s_axis_tready_next;
        end
    end

    // Synchronous FIFO Read
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_sync <= 0;
            m_rd_ptr_gray_sync2 <= 0;
            m_axis_tvalid_reg <= 0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            reg [ADDR_WIDTH:0] next_rd_ptr;
            reg [ADDR_WIDTH:0] next_rd_ptr_gray;
            reg [ADDR_WIDTH:0] next_rd_ptr_gray_sync;
            reg [ADDR_WIDTH:0] next_rd_ptr_gray_sync2;
            reg [ADDR_WIDTH:0] next_depth;
            reg [ADDR_WIDTH:0] next_depth_commit;
            reg m_axis_tvalid_next;

            next_rd_ptr = m_rd_ptr;
            next_rd_ptr_gray = m_rd_ptr_gray;
            next_rd_ptr_gray_sync = m_rd_ptr_gray_sync;
            next_rd_ptr_gray_sync2 = m_rd_ptr_gray_sync2;
            next_depth = m_status_depth_reg;
            next_depth_commit = m_status_depth_commit_reg;
            m_axis_tvalid_next = m_axis_tvalid_reg;

            if (m_axis_tvalid_reg && m_axis_tready) begin
                next_rd_ptr = m_rd_ptr + 1;
                next_rd_ptr_gray = bin2gray(next_rd_ptr);
                next_depth = next_depth - 1;
                next_depth_commit = next_depth_commit - 1;
            end

            m_rd_ptr <= next_rd_ptr;
            m_rd_ptr_gray <= next_rd_ptr_gray;
            m_rd_ptr_gray_sync <= next_rd_ptr_gray;
            m_rd_ptr_gray_sync2 <= m_rd_ptr_gray_sync;
            m_status_depth_reg <= next_depth;
            m_status_depth_commit_reg <= next_depth_commit;

            if (m_axis_tvalid_reg && m_axis_tready) begin
                reg [M_BEAT_WIDTH-1:0] beat;
                beat = mem[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_axis_tdata_reg <= beat[S_DATA_WIDTH-1:0];
                if (M_KEEP_ENABLE) m_axis_tkeep_reg <= beat[S_DATA_WIDTH+S_KEEP_WIDTH-1:S_DATA_WIDTH];
                if (ID_ENABLE) m_axis_tid_reg <= beat[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH];
                if (DEST_ENABLE) m_axis_tdest_reg <= beat[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH];
                if (USER_ENABLE) m_axis_tuser_reg <= beat[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH];
                m_axis_tlast_reg <= beat[S_BEAT_WIDTH-1];
            end

            if (m_status_depth_reg > 0 && !m_pause_req) begin
                m_axis_tvalid_next = 1;
            end else begin
                m_axis_tvalid_next = 0;
            end

            m_axis_tvalid_reg <= m_axis_tvalid_next;
        end
    end

    // Cross-clock domain synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr_gray_sync <= 0;
            s_rd_ptr_gray_sync2 <= 0;
        end else begin
            s_rd_ptr_gray_sync <= m_rd_ptr_gray;
            s_rd_ptr_gray_sync2 <= s_rd_ptr_gray_sync;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr_gray_sync <= 0;
            m_wr_ptr_gray_sync2 <= 0;
        end else begin
            m_wr_ptr_gray_sync <= s_wr_ptr_gray;
            m_wr_ptr_gray_sync2 <= m_wr_ptr_gray_sync;
        end
    end

    // FIFO depth calculation
    assign s_status_depth = s_wr_ptr - gray2bin(s_rd_ptr_gray_sync2);
    assign m_status_depth = m_wr_ptr - gray2bin(m_rd_ptr_gray_sync2);

    // FIFO depth commit calculation
    assign s_status_depth_commit = s_wr_ptr - gray2bin(s_rd_ptr_gray_sync2);
    assign m_status_depth_commit = m_wr_ptr - gray2bin(m_rd_ptr_gray_sync2);

    // FIFO status
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // AXI output
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // AXI input
    assign s_axis_tready = s_axis_tready_reg;

    // Pause signals
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule
