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
    reg [DATA_WIDTH-1:0]  s_data_reg;
    reg [KEEP_WIDTH-1:0]  s_keep_reg;
    reg                   s_last_reg;
    reg [ID_WIDTH-1:0]    s_id_reg;
    reg [DEST_WIDTH-1:0]  s_dest_reg;
    reg [USER_WIDTH-1:0]  s_user_reg;
    reg [DATA_WIDTH-1:0]  m_data_reg;
    reg [KEEP_WIDTH-1:0]  m_keep_reg;
    reg                   m_last_reg;
    reg [ID_WIDTH-1:0]    m_id_reg;
    reg [DEST_WIDTH-1:0]  m_dest_reg;
    reg [USER_WIDTH-1:0]  m_user_reg;
    reg                   s_wr_en;
    reg                   s_rd_en;
    reg                   m_wr_en;
    reg                   m_rd_en;
    reg                   s_fifo_full;
    reg                   s_fifo_empty;
    reg                   m_fifo_full;
    reg                   m_fifo_empty;
    reg [$clog2(DEPTH):0] s_fifo_depth;
    reg [$clog2(DEPTH):0] m_fifo_depth;
    reg [$clog2(DEPTH):0] s_fifo_depth_commit;
    reg [$clog2(DEPTH):0] m_fifo_depth_commit;
    reg                   s_pause_state;
    reg                   m_pause_state;
    reg                   s_frame_in_progress;
    reg                   m_frame_in_progress;
    reg                   s_frame_good;
    reg                   m_frame_good;
    reg                   s_frame_bad;
    reg                   m_frame_bad;
    reg                   s_frame_oversize;
    reg                   m_frame_oversize;
    reg                   s_frame_commit;
    reg                   m_frame_commit;
    reg                   s_frame_start;
    reg                   m_frame_start;
    reg                   s_frame_end;
    reg                   m_frame_end;

    // FIFO instantiation
    dual_clock_fifo #(
        .DATA_WIDTH (DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH),
        .DEPTH      (DEPTH)
    ) fifo_inst (
        .rst_s       (s_rst),
        .rst_m       (m_rst),
        .clk_s       (s_clk),
        .clk_m       (m_clk),
        .wr_en       (s_wr_en),
        .rd_en       (m_rd_en),
        .data_in     ({s_axis_tdata, s_axis_tkeep, s_axis_tlast, ID_ENABLE ? s_axis_tid : 0, DEST_ENABLE ? s_axis_tdest : 0, USER_ENABLE ? s_axis_tuser : 0}),
        .data_out    ({m_data_reg, m_keep_reg, m_last_reg, ID_ENABLE ? m_id_reg : 0, DEST_ENABLE ? m_dest_reg : 0, USER_ENABLE ? m_user_reg : 0}),
        .full        (s_fifo_full),
        .empty       (m_fifo_empty),
        .depth_s     (s_fifo_depth),
        .depth_m     (m_fifo_depth)
    );

    // AXI-S Slave Side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 1'b0;
            s_wr_en <= 1'b0;
            s_frame_start <= 1'b0;
            s_frame_end <= 1'b0;
            s_frame_in_progress <= 1'b0;
            s_frame_good <= 1'b0;
            s_frame_bad <= 1'b0;
            s_frame_oversize <= 1'b0;
            s_frame_commit <= 1'b0;
            s_pause_state <= 1'b0;
        end else begin
            s_axis_tready <= ~s_fifo_full;
            s_wr_en <= 1'b0;

            if (s_axis_tvalid && s_axis_tready) begin
                s_data_reg <= s_axis_tdata;
                s_keep_reg <= s_axis_tkeep;
                s_last_reg <= s_axis_tlast;
                if (ID_ENABLE) s_id_reg <= s_axis_tid;
                if (DEST_ENABLE) s_dest_reg <= s_axis_tdest;
                if (USER_ENABLE) s_user_reg <= s_axis_tuser;
                s_wr_en <= 1'b1;

                // Frame detection
                if (s_axis_tlast) begin
                    s_frame_end <= 1'b1;
                    s_frame_in_progress <= 1'b0;
                end else begin
                    s_frame_start <= s_frame_in_progress ? 1'b0 : 1'b1;
                    s_frame_in_progress <= 1'b1;
                end
            end

            // Frame status tracking
            if (s_frame_end) begin
                s_frame_good <= 1'b1;
                s_frame_bad <= 1'b0;
                s_frame_oversize <= 1'b0;
                if (USER_ENABLE && (s_user_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    s_frame_good <= 1'b0;
                    s_frame_bad <= 1'b1;
                end
                s_frame_commit <= 1'b1;
                s_frame_end <= 1'b0;
            end else if (s_frame_commit) begin
                s_frame_commit <= 1'b0;
            end

            // Pause handling
            if (PAUSE_ENABLE) begin
                if (s_pause_req && !s_pause_state) begin
                    s_pause_state <= 1'b1;
                    s_axis_tready <= 1'b0;
                end else if (!s_pause_req && s_pause_state) begin
                    s_pause_state <= 1'b0;
                    s_axis_tready <= ~s_fifo_full;
                end
            end
        end
    end

    // AXI-S Master Side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid <= 1'b0;
            m_rd_en <= 1'b0;
            m_frame_start <= 1'b0;
            m_frame_end <= 1'b0;
            m_frame_in_progress <= 1'b0;
            m_frame_good <= 1'b0;
            m_frame_bad <= 1'b0;
            m_frame_oversize <= 1'b0;
            m_frame_commit <= 1'b0;
            m_pause_state <= 1'b0;
        end else begin
            m_axis_tvalid <= ~m_fifo_empty;
            m_rd_en <= 1'b0;

            if (m_axis_tvalid && m_axis_tready) begin
                m_rd_en <= 1'b1;

                // Frame detection
                if (m_last_reg) begin
                    m_frame_end <= 1'b1;
                    m_frame_in_progress <= 1'b0;
                end else begin
                    m_frame_start <= m_frame_in_progress ? 1'b0 : 1'b1;
                    m_frame_in_progress <= 1'b1;
                end
            end

            // Frame status tracking
            if (m_frame_end) begin
                m_frame_good <= 1'b1;
                m_frame_bad <= 1'b0;
                m_frame_oversize <= 1'b0;
                if (USER_ENABLE && (m_user_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    m_frame_good <= 1'b0;
                    m_frame_bad <= 1'b1;
                end
                m_frame_commit <= 1'b1;
                m_frame_end <= 1'b0;
            end else if (m_frame_commit) begin
                m_frame_commit <= 1'b0;
            end

            // Pause handling
            if (PAUSE_ENABLE) begin
                if (m_pause_req && !m_pause_state) begin
                    m_pause_state <= 1'b1;
                    m_axis_tvalid <= 1'b0;
                end else if (!m_pause_req && m_pause_state) begin
                    m_pause_state <= 1'b0;
                    m_axis_tvalid <= ~m_fifo_empty;
                end
            end
        end
    end

    // Status signals
    assign s_axis_tready = ~s_fifo_full;
    assign m_axis_tvalid = ~m_fifo_empty;

    assign s_status_depth = s_fifo_depth;
    assign s_status_depth_commit = s_fifo_depth_commit;
    assign s_status_overflow = s_fifo_full;
    assign s_status_bad_frame = s_frame_bad;
    assign s_status_good_frame = s_frame_good;

    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_fifo_depth_commit;
    assign m_status_overflow = m_fifo_full;
    assign m_status_bad_frame = m_frame_bad;
    assign m_status_good_frame = m_frame_good;

    assign s_pause_ack = s_pause_state;
    assign m_pause_ack = m_pause_state;
endmodule

// Dual clock FIFO module
module dual_clock_fifo #
(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024
)
(
    input  wire          rst_s,
    input  wire          rst_m,
    input  wire          clk_s,
    input  wire          clk_m,
    input  wire          wr_en,
    input  wire          rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg           full,
    output reg           empty,
    output reg [$clog2(DEPTH):0] depth_s,
    output reg [$clog2(DEPTH):0] depth_m
);

    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Gray code conversion
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronous write pointer update
    always @(posedge clk_s or posedge rst_s) begin
        if (rst_s) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin2gray(wr_ptr + 1);
        end
    end

    // Synchronous read pointer update
    always @(posedge clk_m or posedge rst_m) begin
        if (rst_m) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin2gray(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_m or posedge rst_m) begin
        if (rst_m) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge clk_s or posedge rst_s) begin
        if (rst_s) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Gray code to binary conversion
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = $clog2(DEPTH) - 1; i >= 0; i = i - 1) begin
            bin[i] = bin[i] ^ bin[i + 1];
        end
        gray2bin = bin;
    endfunction

    // FIFO status
    always @(posedge clk_s or posedge rst_s) begin
        if (rst_s) begin
            depth_s <= 0;
            full <= 0;
        end else begin
            depth_s <= gray2bin(wr_ptr_gray_sync) - gray2bin(rd_ptr_gray);
            full <= (gray2bin(wr_ptr_gray_sync) == gray2bin(rd_ptr_gray) + DEPTH);
        end
    end

    always @(posedge clk_m or posedge rst_m) begin
        if (rst_m) begin
            depth_m <= 0;
            empty <= 1'b1;
        end else begin
            depth_m <= gray2bin(wr_ptr_gray) - gray2bin(rd_ptr_gray_sync);
            empty <= (gray2bin(wr_ptr_gray) == gray2bin(rd_ptr_gray_sync));
        end
    end

    // Data output
    always @(posedge clk_m or posedge rst_m) begin
        if (rst_m) begin
            data_out <= 0;
        end else if (rd_en && !empty) begin
            data_out <= mem[rd_ptr];
        end
    end
endmodule
