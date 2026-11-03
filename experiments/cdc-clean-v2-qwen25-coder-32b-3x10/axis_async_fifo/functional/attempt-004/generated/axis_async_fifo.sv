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
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [LAST_ENABLE:0]  mem_last [DEPTH-1:0];
    reg [ID_ENABLE:0]    mem_id [DEPTH-1:0];
    reg [DEST_ENABLE:0]  mem_dest [DEPTH-1:0];
    reg [USER_ENABLE:0]  mem_user [DEPTH-1:0];

    reg [ADDR_WIDTH:0] s_depth, s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth, m_depth_commit;

    reg s_full, s_empty, s_overflow;
    reg m_full, m_empty, m_overflow;

    reg s_pause_ack_reg, m_pause_ack_reg;
    reg s_pause, m_pause;

    reg s_good_frame, s_bad_frame;
    reg m_good_frame, m_bad_frame;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray code conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
            bin[i] = bin[i] ^ bin[i+1];
        gray2bin = bin;
    endfunction

    // Write side logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_overflow <= 0;
            s_good_frame <= 0;
            s_bad_frame <= 0;
        end else begin
            s_wr_ptr_gray <= bin2gray(s_wr_ptr);
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;

            if (s_axis_tvalid && s_axis_tready && !s_full) begin
                mem_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                if (KEEP_ENABLE)
                    mem_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                if (LAST_ENABLE)
                    mem_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE)
                    mem_id[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE)
                    mem_dest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE)
                    mem_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;

                s_wr_ptr <= s_wr_ptr + 1;
                s_depth <= s_depth + 1;
                s_empty <= 0;
                if (s_axis_tlast) begin
                    s_depth_commit <= s_depth + 1;
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                        s_bad_frame <= 1;
                    else
                        s_good_frame <= 1;
                end
            end

            if (s_depth == DEPTH) begin
                s_full <= 1;
                if (s_axis_tvalid && s_axis_tready)
                    s_overflow <= 1;
            end else begin
                s_full <= 0;
                s_overflow <= 0;
            end
        end
    end

    // Read side logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_rd_ptr_gray_sync <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_overflow <= 0;
            m_good_frame <= 0;
            m_bad_frame <= 0;
        end else begin
            m_rd_ptr_gray <= bin2gray(m_rd_ptr);
            m_rd_ptr_gray_sync <= m_rd_ptr_gray;

            if (m_axis_tvalid && m_axis_tready && !m_empty) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_depth <= m_depth - 1;
                if (m_axis_tlast) begin
                    m_depth_commit <= m_depth - 1;
                    if (USER_ENABLE && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                        m_bad_frame <= 1;
                    else
                        m_good_frame <= 1;
                end
            end

            if (m_depth == DEPTH) begin
                m_full <= 1;
                if (m_axis_tvalid && m_axis_tready)
                    m_overflow <= 1;
            end else begin
                m_full <= 0;
                m_overflow <= 0;
            end
        end
    end

    // Cross-clock domain synchronization
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_gray_sync <= 0;
        end else begin
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_gray_sync <= 0;
        end else begin
            m_rd_ptr_gray_sync <= m_rd_ptr_gray;
        end
    end

    // Depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_full)
                s_depth <= s_depth + 1;
            if (m_axis_tvalid && m_axis_tready && !m_empty)
                s_depth <= s_depth - 1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_full)
                m_depth <= m_depth + 1;
            if (m_axis_tvalid && m_axis_tready && !m_empty)
                m_depth <= m_depth - 1;
        end
    end

    // Handshake signals
    assign s_axis_tready = !s_full && !s_pause;
    assign m_axis_tvalid = !m_empty && !m_pause;

    // Data output
    assign m_axis_tdata = mem_data[m_rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = KEEP_ENABLE ? mem_keep[m_rd_ptr[ADDR_WIDTH-1:0]] : {KEEP_WIDTH{1'b1}};
    assign m_axis_tlast = LAST_ENABLE ? mem_last[m_rd_ptr[ADDR_WIDTH-1:0]] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? mem_id[m_rd_ptr[ADDR_WIDTH-1:0]] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? mem_dest[m_rd_ptr[ADDR_WIDTH-1:0]] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? mem_user[m_rd_ptr[ADDR_WIDTH-1:0]] : {USER_WIDTH{1'b0}};

    // Pause signals
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
            s_pause <= 0;
        end else begin
            if (PAUSE_ENABLE && s_pause_req) begin
                s_pause_ack_reg <= 1;
                s_pause <= 1;
            end else begin
                s_pause_ack_reg <= 0;
                s_pause <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
            m_pause <= 0;
        end else begin
            if (PAUSE_ENABLE && m_pause_req) begin
                m_pause_ack_reg <= 1;
                m_pause <= 1;
            end else begin
                m_pause_ack_reg <= 0;
                m_pause <= 0;
            end
        end
    end

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
