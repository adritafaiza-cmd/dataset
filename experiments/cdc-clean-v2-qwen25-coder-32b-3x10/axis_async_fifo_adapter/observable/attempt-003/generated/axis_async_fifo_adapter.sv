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
    localparam S_BEAT_WIDTH = S_DATA_WIDTH + (S_KEEP_ENABLE ? S_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);
    localparam M_BEAT_WIDTH = M_DATA_WIDTH + (M_KEEP_ENABLE ? M_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt;

    reg [S_BEAT_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] s_depth, s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth, m_depth_commit;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;
    reg s_pause_ack_reg, m_pause_ack_reg;
    reg s_axis_tready_reg;
    reg [M_BEAT_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

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
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray2bin = bin;
    endfunction

    // Write side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_nxt <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            s_wr_ptr_gray_nxt <= bin2gray(s_wr_ptr + 1);
            if (s_axis_tvalid && s_axis_tready_reg && !s_pause_ack_reg) begin
                mem[s_wr_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tdata, s_axis_tkeep, s_axis_tid, s_axis_tdest, s_axis_tuser};
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= s_wr_ptr_gray_nxt;
                s_depth <= s_depth + 1;
                if (s_axis_tlast) begin
                    s_depth_commit <= s_depth + 1;
                    s_good_frame <= 1;
                end
            end else begin
                s_good_frame <= 0;
            end
            if (s_depth == DEPTH) begin
                s_overflow <= 1;
            end else begin
                s_overflow <= 0;
            end
            if (s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                s_bad_frame <= 1;
            end else begin
                s_bad_frame <= 0;
            end
        end
    end

    // Read side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_nxt <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
        end else begin
            m_rd_ptr_gray_nxt <= bin2gray(m_rd_ptr + 1);
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= m_rd_ptr_gray_nxt;
                m_depth <= m_depth - 1;
                if (m_axis_tlast_reg) begin
                    m_depth_commit <= m_depth - 1;
                    m_good_frame <= 1;
                end
            end else begin
                m_good_frame <= 0;
            end
            if (m_depth == DEPTH) begin
                m_overflow <= 1;
            end else begin
                m_overflow <= 0;
            end
            if (m_axis_tvalid_reg && m_axis_tready && m_axis_tlast_reg && (m_axis_tuser_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                m_bad_frame <= 1;
            end else begin
                m_bad_frame <= 0;
            end
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 0;
            end else if (m_depth > 0) begin
                m_axis_tdata_reg <= mem[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_axis_tvalid_reg <= 1;
                m_axis_tlast_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1];
                m_axis_tid_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1-ID_WIDTH-DEST_WIDTH-USER_WIDTH-1 -: ID_WIDTH];
                m_axis_tdest_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1-DEST_WIDTH-USER_WIDTH-1 -: DEST_WIDTH];
                m_axis_tuser_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1-USER_WIDTH-1 -: USER_WIDTH];
                m_axis_tkeep_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1-M_DATA_WIDTH-1 -: M_KEEP_WIDTH];
                m_axis_tdata_reg <= m_axis_tdata_reg[M_BEAT_WIDTH-1-M_DATA_WIDTH-1 -: M_DATA_WIDTH];
            end
        end
    end

    // Cross-domain synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr_gray <= 0;
        end else begin
            s_rd_ptr_gray <= m_rd_ptr_gray_nxt;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr_gray <= 0;
        end else begin
            m_wr_ptr_gray <= s_wr_ptr_gray_nxt;
        end
    end

    // Status
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

    // Ready signals
    assign s_axis_tready = (s_depth < DEPTH) && !s_pause_ack_reg;
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

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
        end else if (s_pause_req) begin
            s_pause_ack_reg <= 1;
        end else if (s_axis_tready && s_axis_tvalid) begin
            s_pause_ack_reg <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else if (m_pause_req) begin
            m_pause_ack_reg <= 1;
        end else if (m_axis_tready && m_axis_tvalid) begin
            m_pause_ack_reg <= 0;
        end
    end

endmodule
