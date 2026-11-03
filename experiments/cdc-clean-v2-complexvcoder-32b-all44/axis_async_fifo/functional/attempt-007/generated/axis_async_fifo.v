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

    // FIFO pointers and flags
    reg [ADDR_WIDTH:0] s_wr_ptr, s_rd_ptr_gray, s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] m_wr_ptr_gray, m_rd_ptr, m_rd_ptr_gray;
    reg [ADDR_WIDTH:0] s_wr_ptr_sync, m_wr_ptr_sync;

    // FIFO memory
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg                  fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   fifo_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] fifo_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] fifo_tuser [0:DEPTH-1];

    // FIFO status
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg s_full, s_empty, m_full, m_empty;
    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    // Binary to gray conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = 1; i <= ADDR_WIDTH; i = i + 1)
            bin = bin ^ (gray >> i);
        gray_to_bin = bin;
    endfunction

    // Synchronous FIFO write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_sync <= 0;
            s_depth <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            s_wr_ptr_gray <= bin_to_gray(s_wr_ptr);
            if (s_axis_tvalid && s_axis_tready && !s_full) begin
                fifo_data[s_wr_ptr] <= s_axis_tdata;
                fifo_keep[s_wr_ptr] <= s_axis_tkeep;
                fifo_last[s_wr_ptr] <= s_axis_tlast;
                fifo_tid[s_wr_ptr] <= s_axis_tid;
                fifo_tdest[s_wr_ptr] <= s_axis_tdest;
                fifo_tuser[s_wr_ptr] <= s_axis_tuser;
                s_wr_ptr <= s_wr_ptr + 1;
                s_depth <= s_depth + 1;
                s_empty <= 0;
                if (s_depth == DEPTH-1)
                    s_full <= 1;
            end else if (s_axis_tvalid && s_axis_tready && s_full) begin
                s_overflow <= 1;
            end
        end
    end

    // Synchronous FIFO read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_sync <= 0;
            m_depth <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            m_rd_ptr_gray <= bin_to_gray(m_rd_ptr);
            if (m_axis_tready && m_axis_tvalid && !m_empty) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_depth <= m_depth - 1;
                m_full <= 0;
                if (m_depth == 1)
                    m_empty <= 1;
            end
        end
    end

    // Gray code synchronization
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_wr_ptr_sync <= 0;
        else
            s_wr_ptr_sync <= s_wr_ptr_gray;
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_wr_ptr_sync <= 0;
        else
            m_wr_ptr_sync <= m_wr_ptr_gray;
    end

    // FIFO status
    assign s_axis_tready = !s_full;
    assign m_axis_tvalid = !m_empty;

    assign m_axis_tdata = fifo_data[m_rd_ptr];
    assign m_axis_tkeep = fifo_keep[m_rd_ptr];
    assign m_axis_tlast = fifo_last[m_rd_ptr];
    assign m_axis_tid = fifo_tid[m_rd_ptr];
    assign m_axis_tdest = fifo_tdest[m_rd_ptr];
    assign m_axis_tuser = fifo_tuser[m_rd_ptr];

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Pause signals (not implemented in this version)
    assign s_pause_ack = 0;
    assign m_pause_ack = 0;

endmodule
