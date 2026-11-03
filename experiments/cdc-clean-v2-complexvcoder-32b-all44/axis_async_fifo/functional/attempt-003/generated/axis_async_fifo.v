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

    /*
     * FIFO write and read pointers
     */
    reg [ADDR_WIDTH:0] s_wr_ptr;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray;
    reg [ADDR_WIDTH:0] m_rd_ptr;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray;

    /*
     * FIFO memory
     */
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [LAST_ENABLE:0]  mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    /*
     * FIFO control
     */
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    /*
     * FIFO depth counters
     */
    reg [$clog2(DEPTH):0] s_status_depth_reg;
    reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
    reg [$clog2(DEPTH):0] m_status_depth_reg;
    reg [$clog2(DEPTH):0] m_status_depth_commit_reg;

    /*
     * Binary to Gray converter
     */
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    /*
     * Gray to Binary converter
     */
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

    /*
     * Write pointer logic (s_clk domain)
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready_reg) begin
            s_wr_ptr <= s_wr_ptr + 1;
            s_wr_ptr_gray <= bin_to_gray(s_wr_ptr + 1);
        end
    end

    /*
     * Read pointer logic (m_clk domain)
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
        end else if (m_axis_tvalid_reg && m_axis_tready) begin
            m_rd_ptr <= m_rd_ptr + 1;
            m_rd_ptr_gray <= bin_to_gray(m_rd_ptr + 1);
        end
    end

    /*
     * FIFO write logic (s_clk domain)
     */
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem_data[s_wr_ptr] <= s_axis_tdata;
            mem_keep[s_wr_ptr] <= s_axis_tkeep;
            mem_last[s_wr_ptr] <= s_axis_tlast;
            mem_id[s_wr_ptr] <= s_axis_tid;
            mem_dest[s_wr_ptr] <= s_axis_tdest;
            mem_user[s_wr_ptr] <= s_axis_tuser;
        end
    end

    /*
     * FIFO read logic (m_clk domain)
     */
    always @(posedge m_clk) begin
        if (m_axis_tvalid_reg && m_axis_tready) begin
            m_axis_tdata <= mem_data[m_rd_ptr];
            m_axis_tkeep <= mem_keep[m_rd_ptr];
            m_axis_tlast <= mem_last[m_rd_ptr];
            m_axis_tid <= mem_id[m_rd_ptr];
            m_axis_tdest <= mem_dest[m_rd_ptr];
            m_axis_tuser <= mem_user[m_rd_ptr];
        end
    end

    /*
     * FIFO status logic (s_clk domain)
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            s_status_depth_reg <= gray_to_bin(s_wr_ptr_gray) - gray_to_bin(m_rd_ptr_gray);
            s_status_depth_commit_reg <= s_status_depth_reg;
            s_status_overflow_reg <= (s_status_depth_reg >= DEPTH);
            s_status_bad_frame_reg <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
            s_status_good_frame_reg <= !s_status_bad_frame_reg;
        end
    end

    /*
     * FIFO status logic (m_clk domain)
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            m_status_depth_reg <= gray_to_bin(s_wr_ptr_gray) - gray_to_bin(m_rd_ptr_gray);
            m_status_depth_commit_reg <= m_status_depth_reg;
            m_status_overflow_reg <= (m_status_depth_reg >= DEPTH);
            m_status_bad_frame_reg <= (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
            m_status_good_frame_reg <= !m_status_bad_frame_reg;
        end
    end

    /*
     * s_axis_tready logic (s_clk domain)
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 1'b0;
        end else begin
            s_axis_tready_reg <= (s_status_depth_reg < DEPTH) && !DROP_WHEN_FULL;
        end
    end

    /*
     * m_axis_tvalid logic (m_clk domain)
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            m_axis_tvalid_reg <= (gray_to_bin(s_wr_ptr_gray) != gray_to_bin(m_rd_ptr_gray));
        end
    end

    /*
     * Pause logic (s_clk domain)
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 1'b0;
        end else if (s_pause_req) begin
            s_pause_ack <= 1'b1;
        end else begin
            s_pause_ack <= 1'b0;
        end
    end

    /*
     * Pause logic (m_clk domain)
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 1'b0;
        end else if (m_pause_req) begin
            m_pause_ack <= 1'b1;
        end else begin
            m_pause_ack <= 1'b0;
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
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
