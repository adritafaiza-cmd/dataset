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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync, m_rd_ptr_gray_sync;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [LAST_ENABLE:0]  mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

    reg [ADDR_WIDTH:0] s_depth, m_depth;
    reg [ADDR_WIDTH:0] s_depth_commit, m_depth_commit;

    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    reg s_pause_ack_reg, m_pause_ack_reg;
    reg s_pause, m_pause;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg;

    reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg [LAST_ENABLE:0]  s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]   s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [LAST_ENABLE:0]  m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]   m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg s_axis_tvalid_reg;
    reg m_axis_tvalid_reg;

    reg s_axis_tready_reg;
    reg m_axis_tready_reg;

    reg [ADDR_WIDTH:0] s_wr_ptr_next;
    reg [ADDR_WIDTH:0] m_rd_ptr_next;

    reg [ADDR_WIDTH:0] s_depth_next;
    reg [ADDR_WIDTH:0] m_depth_next;

    reg s_overflow_next;
    reg m_overflow_next;

    reg s_bad_frame_next;
    reg m_bad_frame_next;

    reg s_good_frame_next;
    reg m_good_frame_next;

    reg s_pause_next;
    reg m_pause_next;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_next;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_next;

    reg [DATA_WIDTH-1:0] s_axis_tdata_next;
    reg [KEEP_WIDTH-1:0] s_axis_tkeep_next;
    reg [LAST_ENABLE:0]  s_axis_tlast_next;
    reg [ID_WIDTH-1:0]   s_axis_tid_next;
    reg [DEST_WIDTH-1:0] s_axis_tdest_next;
    reg [USER_WIDTH-1:0] s_axis_tuser_next;

    reg [DATA_WIDTH-1:0] m_axis_tdata_next;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_next;
    reg [LAST_ENABLE:0]  m_axis_tlast_next;
    reg [ID_WIDTH-1:0]   m_axis_tid_next;
    reg [DEST_WIDTH-1:0] m_axis_tdest_next;
    reg [USER_WIDTH-1:0] m_axis_tuser_next;

    reg s_axis_tvalid_next;
    reg m_axis_tvalid_next;

    reg s_axis_tready_next;
    reg m_axis_tready_next;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = (bin >> 1) ^ bin;
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

    // Write side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_axis_tready_reg <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
            s_pause <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            s_wr_ptr <= s_wr_ptr_next;
            s_wr_ptr_gray <= bin2gray(s_wr_ptr_next);
            s_wr_ptr_gray_sync <= s_wr_ptr_gray_sync_next;
            s_axis_tready_reg <= s_axis_tready_next;
            s_axis_tdata_reg <= s_axis_tdata_next;
            s_axis_tkeep_reg <= s_axis_tkeep_next;
            s_axis_tlast_reg <= s_axis_tlast_next;
            s_axis_tid_reg <= s_axis_tid_next;
            s_axis_tdest_reg <= s_axis_tdest_next;
            s_axis_tuser_reg <= s_axis_tuser_next;
            s_axis_tvalid_reg <= s_axis_tvalid_next;
            s_depth <= s_depth_next;
            s_depth_commit <= s_depth_commit;
            s_overflow <= s_overflow_next;
            s_bad_frame <= s_bad_frame_next;
            s_good_frame <= s_good_frame_next;
            s_pause <= s_pause_next;
            s_pause_ack_reg <= s_pause_ack_next;
        end
    end

    always @(*) begin
        s_wr_ptr_next = s_wr_ptr;
        s_wr_ptr_gray_sync_next = s_wr_ptr_gray_sync;
        s_axis_tready_next = s_axis_tready_reg;
        s_axis_tdata_next = s_axis_tdata_reg;
        s_axis_tkeep_next = s_axis_tkeep_reg;
        s_axis_tlast_next = s_axis_tlast_reg;
        s_axis_tid_next = s_axis_tid_reg;
        s_axis_tdest_next = s_axis_tdest_reg;
        s_axis_tuser_next = s_axis_tuser_reg;
        s_axis_tvalid_next = s_axis_tvalid_reg;
        s_depth_next = s_depth;
        s_depth_commit = s_depth_commit;
        s_overflow_next = s_overflow;
        s_bad_frame_next = s_bad_frame;
        s_good_frame_next = s_good_frame;
        s_pause_next = s_pause;
        s_pause_ack_next = s_pause_ack_reg;

        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem_data[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tdata;
            mem_keep[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tkeep;
            mem_last[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tlast;
            mem_id[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tid;
            mem_dest[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tdest;
            mem_user[s_wr_ptr[ADDR_WIDTH-1:0]] = s_axis_tuser;
            s_wr_ptr_next = s_wr_ptr + 1;
            s_wr_ptr_gray_sync_next = bin2gray(s_wr_ptr_next);
            s_axis_tready_next = (s_depth < DEPTH);
            s_axis_tdata_next = s_axis_tdata;
            s_axis_tkeep_next = s_axis_tkeep;
            s_axis_tlast_next = s_axis_tlast;
            s_axis_tid_next = s_axis_tid;
            s_axis_tdest_next = s_axis_tdest;
            s_axis_tuser_next = s_axis_tuser;
            s_axis_tvalid_next = 1;
            s_depth_next = s_depth + 1;
            s_depth_commit = s_depth + 1;
            s_overflow_next = (s_depth == DEPTH);
            s_bad_frame_next = (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            s_good_frame_next = (s_axis_tlast && !(s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            s_pause_next = (PAUSE_ENABLE && s_pause_req);
            s_pause_ack_next = s_pause;
        end else begin
            s_axis_tready_next = (s_depth < DEPTH);
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_sync <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
            m_pause <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            m_rd_ptr <= m_rd_ptr_next;
            m_rd_ptr_gray <= bin2gray(m_rd_ptr_next);
            m_rd_ptr_gray_sync <= m_rd_ptr_gray_sync_next;
            m_axis_tvalid_reg <= m_axis_tvalid_next;
            m_axis_tdata_reg <= m_axis_tdata_next;
            m_axis_tkeep_reg <= m_axis_tkeep_next;
            m_axis_tlast_reg <= m_axis_tlast_next;
            m_axis_tid_reg <= m_axis_tid_next;
            m_axis_tdest_reg <= m_axis_tdest_next;
            m_axis_tuser_reg <= m_axis_tuser_next;
            m_depth <= m_depth_next;
            m_depth_commit <= m_depth_commit;
            m_overflow <= m_overflow_next;
            m_bad_frame <= m_bad_frame_next;
            m_good_frame <= m_good_frame_next;
            m_pause <= m_pause_next;
            m_pause_ack_reg <= m_pause_ack_next;
        end
    end

    always @(*) begin
        m_rd_ptr_next = m_rd_ptr;
        m_rd_ptr_gray_sync_next = m_rd_ptr_gray_sync;
        m_axis_tvalid_next = m_axis_tvalid_reg;
        m_axis_tdata_next = m_axis_tdata_reg;
        m_axis_tkeep_next = m_axis_tkeep_reg;
        m_axis_tlast_next = m_axis_tlast_reg;
        m_axis_tid_next = m_axis_tid_reg;
        m_axis_tdest_next = m_axis_tdest_reg;
        m_axis_tuser_next = m_axis_tuser_reg;
        m_depth_next = m_depth;
        m_depth_commit = m_depth_commit;
        m_overflow_next = m_overflow;
        m_bad_frame_next = m_bad_frame;
        m_good_frame_next = m_good_frame;
        m_pause_next = m_pause;
        m_pause_ack_next = m_pause_ack_reg;

        if (m_axis_tvalid_reg && m_axis_tready) begin
            m_rd_ptr_next = m_rd_ptr + 1;
            m_rd_ptr_gray_sync_next = bin2gray(m_rd_ptr_next);
            m_axis_tvalid_next = (m_depth > 0);
            m_axis_tdata_next = mem_data[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tkeep_next = mem_keep[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tlast_next = mem_last[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tid_next = mem_id[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tdest_next = mem_dest[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_axis_tuser_next = mem_user[m_rd_ptr[ADDR_WIDTH-1:0]];
            m_depth_next = m_depth - 1;
            m_depth_commit = m_depth - 1;
            m_overflow_next = 0;
            m_bad_frame_next = 0;
            m_good_frame_next = 0;
            m_pause_next = (PAUSE_ENABLE && m_pause_req);
            m_pause_ack_next = m_pause;
        end else begin
            m_axis_tvalid_next = (m_depth > 0);
        end
    end

    // Cross-domain synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_gray_sync <= 0;
        end else begin
            m_rd_ptr_gray_sync <= m_rd_ptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_gray_sync <= 0;
        end else begin
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;
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

    // AXI outputs
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // Pause outputs
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule
