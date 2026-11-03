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
    localparam S_BEATS = (S_DATA_WIDTH + M_DATA_WIDTH - 1) / M_DATA_WIDTH;
    localparam M_BEATS = (M_DATA_WIDTH + S_DATA_WIDTH - 1) / S_DATA_WIDTH;

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt;

    reg [S_DATA_WIDTH-1:0] s_fifo [DEPTH-1:0];
    reg [S_KEEP_WIDTH-1:0] s_keep_fifo [DEPTH-1:0];
    reg [ID_WIDTH-1:0] s_id_fifo [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] s_dest_fifo [DEPTH-1:0];
    reg [USER_WIDTH-1:0] s_user_fifo [DEPTH-1:0];
    reg [ADDR_WIDTH:0] s_last_ptr;
    reg s_last_valid;

    reg [M_DATA_WIDTH-1:0] m_fifo [DEPTH-1:0];
    reg [M_KEEP_WIDTH-1:0] m_keep_fifo [DEPTH-1:0];
    reg [ID_WIDTH-1:0] m_id_fifo [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] m_dest_fifo [DEPTH-1:0];
    reg [USER_WIDTH-1:0] m_user_fifo [DEPTH-1:0];
    reg [ADDR_WIDTH:0] m_last_ptr;
    reg m_last_valid;

    reg [ADDR_WIDTH:0] s_depth, s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth, m_depth_commit;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    reg s_pause_ack_reg, m_pause_ack_reg;

    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ bin[i];
        end
        gray_to_bin = bin;
    endfunction

    // Synchronous FIFO Write Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_nxt <= 0;
            s_last_ptr <= 0;
            s_last_valid <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            s_wr_ptr_gray_nxt <= bin_to_gray(s_wr_ptr + 1);
            if (s_axis_tvalid && s_axis_tready) begin
                s_fifo[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                s_keep_fifo[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (ID_ENABLE) s_id_fifo[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) s_dest_fifo[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) s_user_fifo[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                if (s_axis_tlast) begin
                    s_last_ptr <= s_wr_ptr;
                    s_last_valid <= 1;
                end
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= s_wr_ptr_gray_nxt;
                s_depth <= s_depth + 1;
                if (s_depth == DEPTH) begin
                    s_overflow <= 1;
                    if (DROP_WHEN_FULL) s_axis_tready <= 0;
                end else begin
                    s_overflow <= 0;
                end
            end
            if (s_axis_tlast && s_axis_tready) begin
                s_good_frame <= 1;
            end else if (s_axis_tvalid && s_axis_tready && s_last_valid && s_wr_ptr == s_last_ptr + 1) begin
                s_bad_frame <= 1;
            end else begin
                s_good_frame <= 0;
                s_bad_frame <= 0;
            end
            s_depth_commit <= s_depth;
        end
    end

    // Synchronous FIFO Read Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_nxt <= 0;
            m_last_ptr <= 0;
            m_last_valid <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            m_rd_ptr_gray_nxt <= bin_to_gray(m_rd_ptr + 1);
            if (m_axis_tvalid && m_axis_tready) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= m_rd_ptr_gray_nxt;
                m_depth <= m_depth - 1;
                if (m_last_valid && m_rd_ptr == m_last_ptr) begin
                    m_last_valid <= 0;
                    m_good_frame <= 1;
                end
            end else if (m_last_valid && m_rd_ptr == m_last_ptr + 1) begin
                m_bad_frame <= 1;
            end else begin
                m_good_frame <= 0;
                m_bad_frame <= 0;
            end
            m_depth_commit <= m_depth;
        end
    end

    // Cross-domain FIFO Write Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 0;
            m_wr_ptr_gray_nxt <= 0;
        end else begin
            m_wr_ptr_gray_nxt <= bin_to_gray(m_wr_ptr + 1);
            if (s_axis_tvalid && s_axis_tready && !s_overflow) begin
                m_fifo[m_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                m_keep_fifo[m_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (ID_ENABLE) m_id_fifo[m_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) m_dest_fifo[m_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) m_user_fifo[m_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                if (s_axis_tlast) begin
                    m_last_ptr <= m_wr_ptr;
                    m_last_valid <= 1;
                end
                m_wr_ptr <= m_wr_ptr + 1;
                m_wr_ptr_gray <= m_wr_ptr_gray_nxt;
            end
        end
    end

    // Cross-domain FIFO Read Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr <= 0;
            s_rd_ptr_gray <= 0;
            s_rd_ptr_gray_nxt <= 0;
        end else begin
            s_rd_ptr_gray_nxt <= bin_to_gray(s_rd_ptr + 1);
            if (m_axis_tvalid && m_axis_tready) begin
                s_rd_ptr <= s_rd_ptr + 1;
                s_rd_ptr_gray <= s_rd_ptr_gray_nxt;
            end
        end
    end

    // Cross-domain FIFO Read Data
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tdata_reg <= m_fifo[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_axis_tkeep_reg <= m_keep_fifo[m_rd_ptr[ADDR_WIDTH-1:0]];
                m_axis_tlast_reg <= (m_last_valid && m_rd_ptr == m_last_ptr);
                if (ID_ENABLE) m_axis_tid_reg <= m_id_fifo[m_rd_ptr[ADDR_WIDTH-1:0]];
                if (DEST_ENABLE) m_axis_tdest_reg <= m_dest_fifo[m_rd_ptr[ADDR_WIDTH-1:0]];
                if (USER_ENABLE) m_axis_tuser_reg <= m_user_fifo[m_rd_ptr[ADDR_WIDTH-1:0]];
            end
        end
    end

    // Width Conversion Logic
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                if (ID_ENABLE) s_axis_tid_reg <= s_axis_tid;
                if (DEST_ENABLE) s_axis_tdest_reg <= s_axis_tdest;
                if (USER_ENABLE) s_axis_tuser_reg <= s_axis_tuser;
            end
        end
    end

    // Width Conversion Logic
    reg [M_BEATS-1:0][S_DATA_WIDTH-1:0] s_axis_tdata_beats;
    reg [M_BEATS-1:0][S_KEEP_WIDTH-1:0] s_axis_tkeep_beats;
    reg [M_BEATS-1:0] s_axis_tlast_beats;

    always @(*) begin
        integer i;
        for (i = 0; i < M_BEATS; i = i + 1) begin
            s_axis_tdata_beats[i] = s_axis_tdata_reg[(i+1)*S_DATA_WIDTH-1:i*S_DATA_WIDTH];
            s_axis_tkeep_beats[i] = s_axis_tkeep_reg[(i+1)*S_KEEP_WIDTH-1:i*S_KEEP_WIDTH];
            s_axis_tlast_beats[i] = (i == M_BEATS-1) ? s_axis_tlast_reg : 0;
        end
    end

    reg [S_BEATS-1:0][M_DATA_WIDTH-1:0] m_axis_tdata_beats;
    reg [S_BEATS-1:0][M_KEEP_WIDTH-1:0] m_axis_tkeep_beats;
    reg [S_BEATS-1:0] m_axis_tlast_beats;

    always @(*) begin
        integer i;
        for (i = 0; i < S_BEATS; i = i + 1) begin
            m_axis_tdata_beats[i] = m_axis_tdata_reg[(i+1)*M_DATA_WIDTH-1:i*M_DATA_WIDTH];
            m_axis_tkeep_beats[i] = m_axis_tkeep_reg[(i+1)*M_KEEP_WIDTH-1:i*M_KEEP_WIDTH];
            m_axis_tlast_beats[i] = (i == S_BEATS-1) ? m_axis_tlast_reg : 0;
        end
    end

    // AXI Stream Ready Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 0;
        end else begin
            if (s_axis_tvalid && !s_axis_tready && s_axis_tready) begin
                s_axis_tready <= 1;
            end else if (s_axis_tvalid && s_axis_tready && !m_axis_tready) begin
                s_axis_tready <= 0;
            end else if (s_axis_tvalid && !s_axis_tready && !m_axis_tready) begin
                s_axis_tready <= 0;
            end else if (!s_axis_tvalid && s_axis_tready) begin
                s_axis_tready <= 1;
            end else if (!s_axis_tvalid && !s_axis_tready) begin
                s_axis_tready <= 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 0;
            end else if (!m_axis_tvalid && !m_axis_tready) begin
                m_axis_tvalid <= 1;
            end else if (!m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1;
            end else if (m_axis_tvalid && !m_axis_tready) begin
                m_axis_tvalid <= 1;
            end
        end
    end

    // Pause Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
        end else begin
            if (s_pause_req) begin
                s_pause_ack_reg <= 1;
            end else begin
                s_pause_ack_reg <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else begin
            if (m_pause_req) begin
                m_pause_ack_reg <= 1;
            end else begin
                m_pause_ack_reg <= 0;
            end
        end
    end

    // Status Outputs
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

    // AXI Stream Outputs
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // AXI Stream Inputs
    assign s_axis_tready = s_axis_tready;

    // Pause Outputs
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule
