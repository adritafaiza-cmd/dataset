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

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] s_rd_ptr, s_rd_ptr_gray, s_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_wr_ptr, m_wr_ptr_gray, m_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync;

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg [ADDR_WIDTH:0] s_depth, s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth, m_depth_commit;
    reg s_overflow, s_bad_frame, s_good_frame;
    reg m_overflow, m_bad_frame, m_good_frame;

    reg s_pause_ack_reg, m_pause_ack_reg;

    reg [S_DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

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
        for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1)
            bin[i] = bin[i] ^ bin[i + 1];
        gray_to_bin = bin;
    endfunction

    // Synchronous FIFO Write Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_wr_ptr <= s_wr_ptr + 1;
            s_wr_ptr_gray <= bin_to_gray(s_wr_ptr + 1);
        end
    end

    // Synchronous FIFO Read Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr <= 0;
            s_rd_ptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_rd_ptr <= s_rd_ptr + 1;
            s_rd_ptr_gray <= bin_to_gray(s_rd_ptr + 1);
        end
    end

    // Gray Code Synchronization
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

    // Depth Calculation
    assign s_depth = gray_to_bin(s_wr_ptr_gray_sync) - gray_to_bin(s_rd_ptr_gray);
    assign s_depth_commit = gray_to_bin(s_wr_ptr_gray) - gray_to_bin(s_rd_ptr_gray_sync);

    // Overflow Detection
    assign s_overflow = (s_depth_commit >= DEPTH);

    // Write Data to Memory
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem_data[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tdata;
            mem_keep[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tkeep;
            mem_last[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tlast;
            mem_id[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tid;
            mem_dest[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tdest;
            mem_user[gray_to_bin(s_wr_ptr_gray)] <= s_axis_tuser;
        end
    end

    // Read Data from Memory
    always @(posedge m_clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tdata_reg <= mem_data[gray_to_bin(m_rd_ptr_gray)];
            m_axis_tkeep_reg <= mem_keep[gray_to_bin(m_rd_ptr_gray)];
            m_axis_tlast_reg <= mem_last[gray_to_bin(m_rd_ptr_gray)];
            m_axis_tid_reg <= mem_id[gray_to_bin(m_rd_ptr_gray)];
            m_axis_tdest_reg <= mem_dest[gray_to_bin(m_rd_ptr_gray)];
            m_axis_tuser_reg <= mem_user[gray_to_bin(m_rd_ptr_gray)];
        end
    end

    // M FIFO Write Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr <= 0;
            m_wr_ptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_wr_ptr <= m_wr_ptr + 1;
            m_wr_ptr_gray <= bin_to_gray(m_wr_ptr + 1);
        end
    end

    // M FIFO Read Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_rd_ptr <= m_rd_ptr + 1;
            m_rd_ptr_gray <= bin_to_gray(m_rd_ptr + 1);
        end
    end

    // Gray Code Synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_wr_ptr_gray_sync <= 0;
        end else begin
            m_wr_ptr_gray_sync <= m_wr_ptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rd_ptr_gray_sync <= 0;
        end else begin
            s_rd_ptr_gray_sync <= s_rd_ptr_gray;
        end
    end

    // Depth Calculation
    assign m_depth = gray_to_bin(m_wr_ptr_gray_sync) - gray_to_bin(m_rd_ptr_gray);
    assign m_depth_commit = gray_to_bin(m_wr_ptr_gray) - gray_to_bin(m_rd_ptr_gray_sync);

    // Overflow Detection
    assign m_overflow = (m_depth_commit >= DEPTH);

    // Width Conversion
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_shift;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_shift;
    reg s_axis_tlast_shift;
    reg [ID_WIDTH-1:0] s_axis_tid_shift;
    reg [DEST_WIDTH-1:0] s_axis_tdest_shift;
    reg [USER_WIDTH-1:0] s_axis_tuser_shift;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_shift;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_shift;
    reg m_axis_tlast_shift;
    reg [ID_WIDTH-1:0] m_axis_tid_shift;
    reg [DEST_WIDTH-1:0] m_axis_tdest_shift;
    reg [USER_WIDTH-1:0] m_axis_tuser_shift;

    reg [S_BEATS-1:0] s_axis_tdata_beat;
    reg [S_BEATS-1:0] s_axis_tkeep_beat;
    reg s_axis_tlast_beat;
    reg [ID_WIDTH-1:0] s_axis_tid_beat;
    reg [DEST_WIDTH-1:0] s_axis_tdest_beat;
    reg [USER_WIDTH-1:0] s_axis_tuser_beat;

    reg [M_BEATS-1:0] m_axis_tdata_beat;
    reg [M_BEATS-1:0] m_axis_tkeep_beat;
    reg m_axis_tlast_beat;
    reg [ID_WIDTH-1:0] m_axis_tid_beat;
    reg [DEST_WIDTH-1:0] m_axis_tdest_beat;
    reg [USER_WIDTH-1:0] m_axis_tuser_beat;

    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_shift <= s_axis_tdata;
            s_axis_tkeep_shift <= s_axis_tkeep;
            s_axis_tlast_shift <= s_axis_tlast;
            s_axis_tid_shift <= s_axis_tid;
            s_axis_tdest_shift <= s_axis_tdest;
            s_axis_tuser_shift <= s_axis_tuser;
        end
    end

    always @(posedge m_clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tdata_shift <= m_axis_tdata_reg;
            m_axis_tkeep_shift <= m_axis_tkeep_reg;
            m_axis_tlast_shift <= m_axis_tlast_reg;
            m_axis_tid_shift <= m_axis_tid_reg;
            m_axis_tdest_shift <= m_axis_tdest_reg;
            m_axis_tuser_shift <= m_axis_tuser_reg;
        end
    end

    // Shift Register for Width Conversion
    genvar i;
    generate
        if (S_DATA_WIDTH > M_DATA_WIDTH) begin
            for (i = 0; i < S_BEATS; i = i + 1) begin
                always @(posedge s_clk) begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        s_axis_tdata_beat[i] <= s_axis_tdata_shift[(i+1)*M_DATA_WIDTH-1:i*M_DATA_WIDTH];
                        s_axis_tkeep_beat[i] <= s_axis_tkeep_shift[(i+1)*M_KEEP_WIDTH-1:i*M_KEEP_WIDTH];
                    end
                end
            end
        end else begin
            always @(posedge s_clk) begin
                if (s_axis_tvalid && s_axis_tready) begin
                    s_axis_tdata_beat[0] <= s_axis_tdata_shift;
                    s_axis_tkeep_beat[0] <= s_axis_tkeep_shift;
                end
            end
        end
    endgenerate

    generate
        if (M_DATA_WIDTH > S_DATA_WIDTH) begin
            for (i = 0; i < M_BEATS; i = i + 1) begin
                always @(posedge m_clk) begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tdata_beat[i] <= m_axis_tdata_shift[(i+1)*S_DATA_WIDTH-1:i*S_DATA_WIDTH];
                        m_axis_tkeep_beat[i] <= m_axis_tkeep_shift[(i+1)*S_KEEP_WIDTH-1:i*S_KEEP_WIDTH];
                    end
                end
            end
        end else begin
            always @(posedge m_clk) begin
                if (m_axis_tvalid && m_axis_tready) begin
                    m_axis_tdata_beat[0] <= m_axis_tdata_shift;
                    m_axis_tkeep_beat[0] <= m_axis_tkeep_shift;
                end
            end
        end
    endgenerate

    // AXI Stream Ready Signals
    assign s_axis_tready = (s_depth_commit < DEPTH) && !s_pause_req;
    assign m_axis_tvalid = (m_depth > 0) && !m_pause_req;

    // AXI Stream Output Signals
    assign m_axis_tdata = m_axis_tdata_beat[0];
    assign m_axis_tkeep = m_axis_tkeep_beat[0];
    assign m_axis_tlast = m_axis_tlast_shift;
    assign m_axis_tid = m_axis_tid_shift;
    assign m_axis_tdest = m_axis_tdest_shift;
    assign m_axis_tuser = m_axis_tuser_shift;

    // Pause Acknowledgment
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status Signals
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
