module axis_async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    // Internal signals
    wire [$clog2(DEPTH)-1:0] s_wr_ptr, s_wr_ptr_gray;
    wire [$clog2(DEPTH)-1:0] s_rd_ptr, s_rd_ptr_gray;
    wire [$clog2(DEPTH)-1:0] m_wr_ptr, m_wr_ptr_gray;
    wire [$clog2(DEPTH)-1:0] m_rd_ptr, m_rd_ptr_gray;
    wire s_full, s_empty, s_almost_full;
    wire m_full, m_empty, m_almost_full;
    reg [$clog2(DEPTH):0] s_status_depth_reg;
    reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
    reg [$clog2(DEPTH):0] m_status_depth_reg;
    reg [$clog2(DEPTH):0] m_status_depth_commit_reg;
    reg s_status_overflow_reg;
    reg m_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // FIFO memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] fifo_user [0:DEPTH-1];
    reg fifo_tlast [0:DEPTH-1];

    // Gray code conversion
    function [$clog2(DEPTH)-1:0] bin2gray;
        input [$clog2(DEPTH)-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
    function [$clog2(DEPTH)-1:0] gray2bin;
        input [$clog2(DEPTH)-1:0] gray;
        integer i;
        reg [$clog2(DEPTH)-1:0] bin;
        bin = gray;
        for (i = $clog2(DEPTH)-2; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray2bin = bin;
    endfunction

    // Synchronous write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= 0;
        else if (s_axis_tvalid && s_axis_tready)
            s_wr_ptr <= s_wr_ptr + 1;
    end

    // Synchronous read pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rd_ptr <= 0;
        else if (m_axis_tvalid && m_axis_tready)
            s_rd_ptr <= s_rd_ptr + 1;
    end

    // Asynchronous write pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_wr_ptr <= 0;
        else if (s_axis_tvalid && s_axis_tready)
            m_wr_ptr <= m_wr_ptr + 1;
    end

    // Asynchronous read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= 0;
        else if (m_axis_tvalid && m_axis_tready)
            m_rd_ptr <= m_rd_ptr + 1;
    end

    // Gray code conversion
    assign s_wr_ptr_gray = bin2gray(s_wr_ptr);
    assign s_rd_ptr_gray = bin2gray(s_rd_ptr);
    assign m_wr_ptr_gray = bin2gray(m_wr_ptr);
    assign m_rd_ptr_gray = bin2gray(m_rd_ptr);

    // FIFO full and empty flags
    assign s_full = (s_wr_ptr_gray == {~s_rd_ptr_gray[$clog2(DEPTH)-1:1], s_rd_ptr_gray[$clog2(DEPTH)-2:0]});
    assign s_empty = (s_wr_ptr_gray == s_rd_ptr_gray);
    assign m_full = (m_wr_ptr_gray == {~m_rd_ptr_gray[$clog2(DEPTH)-1:1], m_rd_ptr_gray[$clog2(DEPTH)-2:0]});
    assign m_empty = (m_wr_ptr_gray == m_rd_ptr_gray);

    // Almost full flag
    assign s_almost_full = (s_wr_ptr_gray == {~s_rd_ptr_gray[$clog2(DEPTH)-2:0], s_rd_ptr_gray[$clog2(DEPTH)-3:0], 1'b1});
    assign m_almost_full = (m_wr_ptr_gray == {~m_rd_ptr_gray[$clog2(DEPTH)-2:0], m_rd_ptr_gray[$clog2(DEPTH)-3:0], 1'b1});

    // FIFO write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst);
            fifo_mem <= '{default:0};
            fifo_keep <= '{default:0};
            fifo_id <= '{default:0};
            fifo_dest <= '{default:0};
            fifo_user <= '{default:0};
            fifo_tlast <= '{default:0};
        else if (s_axis_tvalid && s_axis_tready) begin
            fifo_mem[s_wr_ptr] <= s_axis_tdata;
            fifo_keep[s_wr_ptr] <= s_axis_tkeep;
            fifo_id[s_wr_ptr] <= s_axis_tid;
            fifo_dest[s_wr_ptr] <= s_axis_tdest;
            fifo_user[s_wr_ptr] <= s_axis_tuser;
            fifo_tlast[s_wr_ptr] <= s_axis_tlast;
        end
    end

    // FIFO read
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;
    reg m_axis_tlast_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_axis_tlast_reg <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tdata_reg <= fifo_mem[m_rd_ptr];
            m_axis_tkeep_reg <= fifo_keep[m_rd_ptr];
            m_axis_tid_reg <= fifo_id[m_rd_ptr];
            m_axis_tdest_reg <= fifo_dest[m_rd_ptr];
            m_axis_tuser_reg <= fifo_user[m_rd_ptr];
            m_axis_tlast_reg <= fifo_tlast[m_rd_ptr];
        end
    end

    // Status signals
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            s_status_depth_reg <= s_full ? DEPTH : s_wr_ptr - s_rd_ptr;
            s_status_depth_commit_reg <= s_status_depth_reg;
            s_status_overflow_reg <= s_full;
            // Frame status handling (simplified)
            s_status_bad_frame_reg <= 0; // Placeholder for actual logic
            s_status_good_frame_reg <= 0; // Placeholder for actual logic
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
            m_status_depth_reg <= m_full ? DEPTH : m_wr_ptr - m_rd_ptr;
            m_status_depth_commit_reg <= m_status_depth_reg;
            m_status_overflow_reg <= m_full;
            // Frame status handling (simplified)
            m_status_bad_frame_reg <= 0; // Placeholder for actual logic
            m_status_good_frame_reg <= 0; // Placeholder for actual logic
        end
    end

    // Handshake signals
    assign s_axis_tready = ~s_full;
    assign m_axis_tvalid = ~m_empty;

    // Pause signals (simplified)
    assign s_pause_ack_reg = 0; // Placeholder for actual logic
    assign m_pause_ack_reg = 0; // Placeholder for actual logic

    // Output assignments
    assign s_axis_tready = s_axis_tready;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
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

endmodule
