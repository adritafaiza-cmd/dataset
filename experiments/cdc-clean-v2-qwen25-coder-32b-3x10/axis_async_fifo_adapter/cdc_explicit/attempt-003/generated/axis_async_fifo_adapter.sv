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

    // FIFO signals
    reg [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync, s_wr_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_sync, s_rd_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_sync, m_wr_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync, m_rd_ptr_gray_sync2;

    // FIFO memory
    reg [S_DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_tuser [0:DEPTH-1];
    reg mem_tlast [0:DEPTH-1];

    // FIFO flags
    reg [DEPTH-1:0] mem_tlast_flag;

    // FIFO status
    reg [$clog2(DEPTH):0] s_depth, s_depth_commit;
    reg [$clog2(DEPTH):0] m_depth, m_depth_commit;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    // Pause control
    reg s_pause_ack_reg, m_pause_ack_reg;

    // FIFO write and read enable
    reg s_wr_en, s_rd_en;
    reg m_wr_en, m_rd_en;

    // FIFO data
    reg [S_DATA_WIDTH-1:0] s_wr_data, s_rd_data;
    reg [S_KEEP_WIDTH-1:0] s_wr_keep, s_rd_keep;
    reg [ID_WIDTH-1:0] s_wr_tid, s_rd_tid;
    reg [DEST_WIDTH-1:0] s_wr_tdest, s_rd_tdest;
    reg [USER_WIDTH-1:0] s_wr_tuser, s_rd_tuser;
    reg s_wr_tlast, s_rd_tlast;

    // FIFO data width conversion
    reg [M_DATA_WIDTH-1:0] m_wr_data, m_rd_data;
    reg [M_KEEP_WIDTH-1:0] m_wr_keep, m_rd_keep;
    reg [ID_WIDTH-1:0] m_wr_tid, m_rd_tid;
    reg [DEST_WIDTH-1:0] m_wr_tdest, m_rd_tdest;
    reg [USER_WIDTH-1:0] m_wr_tuser, m_rd_tuser;
    reg m_wr_tlast, m_rd_tlast;

    // FIFO control
    reg s_fifo_full, s_fifo_empty, s_fifo_almost_full, s_fifo_almost_empty;
    reg m_fifo_full, m_fifo_empty, m_fifo_almost_full, m_fifo_almost_empty;

    // FIFO depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_wr_ptr_gray_sync <= 0;
            s_wr_ptr_gray_sync2 <= 0;
        end else begin
            if (s_wr_en && !s_fifo_full) begin
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 0;
            m_wr_ptr_gray_sync <= 0;
            m_wr_ptr_gray_sync2 <= 0;
        end else begin
            if (m_wr_en && !m_fifo_full) begin
                m_wr_ptr <= m_wr_ptr + 1;
                m_wr_ptr_gray <= (m_wr_ptr + 1) ^ ((m_wr_ptr + 1) >> 1);
            end
        end
    end

    // Gray code synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_gray_sync <= 0;
            s_wr_ptr_gray_sync2 <= 0;
        end else begin
            s_wr_ptr_gray_sync <= s_wr_ptr_gray;
            s_wr_ptr_gray_sync2 <= s_wr_ptr_gray_sync;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr_gray_sync <= 0;
            m_wr_ptr_gray_sync2 <= 0;
        end else begin
            m_wr_ptr_gray_sync <= m_wr_ptr_gray;
            m_wr_ptr_gray_sync2 <= m_wr_ptr_gray_sync;
        end
    end

    // FIFO read pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr <= 0;
            s_rd_ptr_gray <= 0;
        end else begin
            if (s_rd_en && !s_fifo_empty) begin
                s_rd_ptr <= s_rd_ptr + 1;
                s_rd_ptr_gray <= (s_rd_ptr + 1) ^ ((s_rd_ptr + 1) >> 1);
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
        end else begin
            if (m_rd_en && !m_fifo_empty) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= (m_rd_ptr + 1) ^ ((m_rd_ptr + 1) >> 1);
            end
        end
    end

    // FIFO depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
            s_depth_commit <= 0;
        end else begin
            if (s_wr_en && !s_fifo_full) begin
                s_depth <= s_depth + 1;
            end
            if (s_rd_en && !s_fifo_empty) begin
                s_depth <= s_depth - 1;
            end
            s_depth_commit <= s_depth;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= 0;
            m_depth_commit <= 0;
        end else begin
            if (m_wr_en && !m_fifo_full) begin
                m_depth <= m_depth + 1;
            end
            if (m_rd_en && !m_fifo_empty) begin
                m_depth <= m_depth - 1;
            end
            m_depth_commit <= m_depth;
        end
    end

    // FIFO flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            if (s_wr_en && s_fifo_full) begin
                s_overflow <= 1;
            end else begin
                s_overflow <= 0;
            end
            if (s_wr_tlast && s_wr_en) begin
                if (s_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    s_bad_frame <= 1;
                end else begin
                    s_good_frame <= 1;
                end
            end else begin
                s_bad_frame <= 0;
                s_good_frame <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            if (m_wr_en && m_fifo_full) begin
                m_overflow <= 1;
            end else begin
                m_overflow <= 0;
            end
            if (m_wr_tlast && m_wr_en) begin
                if (m_axis_tuser & USER_BAD_FRAME_MASK == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame <= 1;
                end else begin
                    m_good_frame <= 1;
                end
            end else begin
                m_bad_frame <= 0;
                m_good_frame <= 0;
            end
        end
    end

    // FIFO write enable
    assign s_wr_en = s_axis_tvalid && s_axis_tready && !s_fifo_full;
    assign m_wr_en = m_axis_tready && m_axis_tvalid && !m_fifo_full;

    // FIFO read enable
    assign s_rd_en = s_fifo_full ? 0 : (s_axis_tready && s_axis_tvalid && s_fifo_empty ? 0 : 1);
    assign m_rd_en = m_fifo_full ? 0 : (m_axis_tready && m_axis_tvalid && m_fifo_empty ? 0 : 1);

    // FIFO write data
    assign s_wr_data = s_axis_tdata;
    assign s_wr_keep = s_axis_tkeep;
    assign s_wr_tid = s_axis_tid;
    assign s_wr_tdest = s_axis_tdest;
    assign s_wr_tuser = s_axis_tuser;
    assign s_wr_tlast = s_axis_tlast;

    // FIFO read data
    assign s_rd_data = mem_data[s_rd_ptr];
    assign s_rd_keep = mem_keep[s_rd_ptr];
    assign s_rd_tid = mem_tid[s_rd_ptr];
    assign s_rd_tdest = mem_tdest[s_rd_ptr];
    assign s_rd_tuser = mem_tuser[s_rd_ptr];
    assign s_rd_tlast = mem_tlast[s_rd_ptr];

    // FIFO write data
    assign m_wr_data = s_rd_data;
    assign m_wr_keep = s_rd_keep;
    assign m_wr_tid = s_rd_tid;
    assign m_wr_tdest = s_rd_tdest;
    assign m_wr_tuser = s_rd_tuser;
    assign m_wr_tlast = s_rd_tlast;

    // FIFO read data
    assign m_rd_data = mem_data[m_rd_ptr];
    assign m_rd_keep = mem_keep[m_rd_ptr];
    assign m_rd_tid = mem_tid[m_rd_ptr];
    assign m_rd_tdest = mem_tdest[m_rd_ptr];
    assign m_rd_tuser = mem_tuser[m_rd_ptr];
    assign m_rd_tlast = mem_tlast[m_rd_ptr];

    // FIFO memory write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            mem_data[s_wr_ptr] <= s_wr_data;
            mem_keep[s_wr_ptr] <= s_wr_keep;
            mem_tid[s_wr_ptr] <= s_wr_tid;
            mem_tdest[s_wr_ptr] <= s_wr_tdest;
            mem_tuser[s_wr_ptr] <= s_wr_tuser;
            mem_tlast[s_wr_ptr] <= s_wr_tlast;
        end
    end

    // FIFO memory read
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            mem_data[m_wr_ptr] <= m_wr_data;
            mem_keep[m_wr_ptr] <= m_wr_keep;
            mem_tid[m_wr_ptr] <= m_wr_tid;
            mem_tdest[m_wr_ptr] <= m_wr_tdest;
            mem_tuser[m_wr_ptr] <= m_wr_tuser;
            mem_tlast[m_wr_ptr] <= m_wr_tlast;
        end
    end

    // FIFO flags
    always @(posedge s_clk) begin
        if (s_wr_en && s_wr_tlast) begin
            mem_tlast_flag[s_wr_ptr] <= 1;
        end
        if (s_rd_en && s_rd_tlast) begin
            mem_tlast_flag[s_rd_ptr] <= 0;
        end
    end

    always @(posedge m_clk) begin
        if (m_wr_en && m_wr_tlast) begin
            mem_tlast_flag[m_wr_ptr] <= 1;
        end
        if (m_rd_en && m_rd_tlast) begin
            mem_tlast_flag[m_rd_ptr] <= 0;
        end
    end

    // FIFO status
    assign s_fifo_full = (s_wr_ptr_gray_sync2 == {~s_rd_ptr_gray[0], s_rd_ptr_gray[$clog2(DEPTH):1]});
    assign s_fifo_empty = (s_wr_ptr_gray_sync2 == s_rd_ptr_gray);
    assign s_fifo_almost_full = (s_wr_ptr_gray_sync2 == {~s_rd_ptr_gray[0], s_rd_ptr_gray[$clog2(DEPTH):1] - 1});
    assign s_fifo_almost_empty = (s_wr_ptr_gray_sync2 == {s_rd_ptr_gray[0], s_rd_ptr_gray[$clog2(DEPTH):1] + 1});

    assign m_fifo_full = (m_wr_ptr_gray_sync2 == {~m_rd_ptr_gray[0], m_rd_ptr_gray[$clog2(DEPTH):1]});
    assign m_fifo_empty = (m_wr_ptr_gray_sync2 == m_rd_ptr_gray);
    assign m_fifo_almost_full = (m_wr_ptr_gray_sync2 == {~m_rd_ptr_gray[0], m_rd_ptr_gray[$clog2(DEPTH):1] - 1});
    assign m_fifo_almost_empty = (m_wr_ptr_gray_sync2 == {m_rd_ptr_gray[0], m_rd_ptr_gray[$clog2(DEPTH):1] + 1});

    // FIFO handshake
    assign s_axis_tready = !s_fifo_full;
    assign m_axis_tvalid = !m_fifo_empty;

    // FIFO pause
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // FIFO status
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

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            m_rd_data <= m_rd_data;
            m_rd_keep <= m_rd_keep;
            m_rd_tid <= m_rd_tid;
            m_rd_tdest <= m_rd_tdest;
            m_rd_tuser <= m_rd_tuser;
            m_rd_tlast <= m_rd_tlast;
        end
    end

    // FIFO data width conversion
    always @(posedge m_clk) begin
        if (m_wr_en) begin
            m_wr_data <= m_wr_data;
            m_wr_keep <= m_wr_keep;
            m_wr_tid <= m_wr_tid;
            m_wr_tdest <= m_wr_tdest;
            m_wr_tuser <= m_wr_tuser;
            m_wr_tlast <= m_wr_tlast;
        end
    end

    // FIFO data width