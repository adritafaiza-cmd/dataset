```verilog
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
    localparam S_WORD_WIDTH = S_DATA_WIDTH + (S_KEEP_ENABLE ? S_KEEP_WIDTH : 0) + 1 + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);
    localparam M_WORD_WIDTH = M_DATA_WIDTH + (M_KEEP_ENABLE ? M_KEEP_WIDTH : 0) + 1 + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync;

    reg [S_WORD_WIDTH-1:0] mem [DEPTH-1:0];
    reg [M_WORD_WIDTH-1:0] m_axis_word;

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    reg [ADDR_WIDTH:0] s_status_depth_reg;
    reg [ADDR_WIDTH:0] s_status_depth_commit_reg;
    reg [ADDR_WIDTH:0] m_status_depth_reg;
    reg [ADDR_WIDTH:0] m_status_depth_commit_reg;

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

    // Source side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_axis_tready_reg <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            reg [ADDR_WIDTH:0] s_wr_ptr_next;
            reg [ADDR_WIDTH:0] s_wr_ptr_gray_next;
            reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_next;
            reg [ADDR_WIDTH:0] s_status_depth_next;
            reg [ADDR_WIDTH:0] s_status_depth_commit_next;
            reg s_axis_tready_next;
            reg s_status_overflow_next;
            reg s_status_bad_frame_next;
            reg s_status_good_frame_next;

            s_wr_ptr_next = s_wr_ptr;
            s_wr_ptr_gray_next = s_wr_ptr_gray;
            s_wr_ptr_gray_sync_next = s_wr_ptr_gray_sync;
            s_status_depth_next = s_status_depth_reg;
            s_status_depth_commit_next = s_status_depth_commit_reg;
            s_axis_tready_next = s_axis_tready_reg;
            s_status_overflow_next = s_status_overflow_reg;
            s_status_bad_frame_next = s_status_bad_frame_reg;
            s_status_good_frame_next = s_status_good_frame_reg;

            if (s_axis_tvalid && s_axis_tready_reg) begin
                mem[s_wr_ptr[ADDR_WIDTH-1:0]] = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
                s_wr_ptr_next = s_wr_ptr + 1;
                s_wr_ptr_gray_next = bin_to_gray(s_wr_ptr_next);
                s_status_depth_next = s_status_depth_reg + 1;
                s_status_depth_commit_next = s_status_depth_commit_reg + 1;

                if (s_axis_tlast) begin
                    s_status_good_frame_next = 1;
                end
            end

            if (s_status_depth_next > DEPTH) begin
                s_status_overflow_next = 1;
            end

            if (s_status_depth_commit_next > DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == 0) begin
                s_status_depth_commit_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast) begin
                s_status_depth_commit_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH) begin
                s_status_depth_commit_next = DEPTH;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_good_frame_next) begin
                s_status_good_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_bad_frame_next) begin
                s_status_bad_frame_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_overflow_next) begin
                s_status_overflow_next = 0;
            end

            if (s_status_depth_commit_next == DEPTH && s_axis_tvalid && s_axis_tready_reg && s_axis_tlast && s_status_depth_next == DEPTH && s_status_depth_commit_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth_next == DEPTH && s_status_depth