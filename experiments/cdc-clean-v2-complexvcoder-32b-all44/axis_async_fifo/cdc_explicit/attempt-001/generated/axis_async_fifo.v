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
    wire s_fifo_wr_en;
    wire s_fifo_full;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] s_fifo_data_out;
    wire s_fifo_valid_out;
    wire m_fifo_rd_en;
    wire m_fifo_empty;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] m_fifo_data_in;
    wire m_fifo_valid_in;
    wire [$clog2(DEPTH):0] s_fifo_depth;
    wire [$clog2(DEPTH):0] m_fifo_depth;
    wire s_frame_commit;
    wire m_frame_commit;
    wire s_pause_ack_int;
    wire m_pause_ack_int;
    wire [$clog2(DEPTH):0] s_status_depth_int;
    wire [$clog2(DEPTH):0] s_status_depth_commit_int;
    wire s_status_overflow_int;
    wire s_status_bad_frame_int;
    wire s_status_good_frame_int;
    wire [$clog2(DEPTH):0] m_status_depth_int;
    wire [$clog2(DEPTH):0] m_status_depth_commit_int;
    wire m_status_overflow_int;
    wire m_status_bad_frame_int;
    wire m_status_good_frame_int;

    // Data FIFO from s_clk to m_clk
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH),
        .DEPTH(DEPTH)
    ) s_to_m_fifo (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .wr_en(s_fifo_wr_en),
        .full(s_fifo_full),
        .din(m_fifo_data_in),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .rd_en(m_fifo_rd_en),
        .empty(m_fifo_empty),
        .dout(s_fifo_data_out),
        .valid(s_fifo_valid_out)
    );

    // Control FIFO from m_clk to s_clk
    async_fifo #(
        .DATA_WIDTH(1),
        .DEPTH(DEPTH)
    ) m_to_s_fifo (
        .clk_w(m_clk),
        .rst_w(m_rst),
        .wr_en(m_fifo_valid_in),
        .full(),
        .din(1'b1),
        .clk_r(s_clk),
        .rst_r(s_rst),
        .rd_en(s_frame_commit),
        .empty(),
        .dout(),
        .valid()
    );

    // Depth counters
    cdc_counter #(
        .DEPTH(DEPTH)
    ) s_depth_counter (
        .clk(s_clk),
        .rst(s_rst),
        .wr_en(s_fifo_wr_en),
        .rd_en(m_fifo_valid_in),
        .depth(s_fifo_depth)
    );

    cdc_counter #(
        .DEPTH(DEPTH)
    ) m_depth_counter (
        .clk(m_clk),
        .rst(m_rst),
        .wr_en(m_fifo_valid_in),
        .rd_en(m_fifo_rd_en),
        .depth(m_fifo_depth)
    );

    // FIFO write enable logic
    assign s_fifo_wr_en = s_axis_tvalid & s_axis_tready & ~s_fifo_full;

    // FIFO read enable logic
    assign m_fifo_rd_en = m_axis_tready & s_fifo_valid_out;

    // FIFO data input
    assign m_fifo_data_in = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};

    // FIFO data output
    assign {m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser} = s_fifo_data_out;

    // Handshake signals
    assign s_axis_tready = ~s_fifo_full;
    assign m_axis_tvalid = s_fifo_valid_out;

    // Frame commit
    assign s_frame_commit = s_axis_tlast & s_axis_tvalid & s_axis_tready;
    assign m_frame_commit = m_axis_tlast & m_axis_tvalid & m_axis_tready;

    // Pause signals
    assign s_pause_ack = s_pause_ack_int;
    assign m_pause_ack = m_pause_ack_int;

    // Status signals
    assign s_status_depth = s_status_depth_int;
    assign s_status_depth_commit = s_status_depth_commit_int;
    assign s_status_overflow = s_status_overflow_int;
    assign s_status_bad_frame = s_status_bad_frame_int;
    assign s_status_good_frame = s_status_good_frame_int;
    assign m_status_depth = m_status_depth_int;
    assign m_status_depth_commit = m_status_depth_commit_int;
    assign m_status_overflow = m_status_overflow_int;
    assign m_status_bad_frame = m_status_bad_frame_int;
    assign m_status_good_frame = m_status_good_frame_int;

    // Status logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_depth_int <= 0;
            s_status_depth_commit_int <= 0;
            s_status_overflow_int <= 0;
            s_status_bad_frame_int <= 0;
            s_status_good_frame_int <= 0;
        end else begin
            s_status_depth_int <= s_fifo_depth;
            if (s_frame_commit) begin
                s_status_depth_commit_int <= s_fifo_depth;
            end
            if (s_fifo_full & s_axis_tvalid & s_axis_tready) begin
                s_status_overflow_int <= 1;
            end else begin
                s_status_overflow_int <= 0;
            end
            // Additional status logic can be added here
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_depth_int <= 0;
            m_status_depth_commit_int <= 0;
            m_status_overflow_int <= 0;
            m_status_bad_frame_int <= 0;
            m_status_good_frame_int <= 0;
        end else begin
            m_status_depth_int <= m_fifo_depth;
            if (m_frame_commit) begin
                m_status_depth_commit_int <= m_fifo_depth;
            end
            // Additional status logic can be added here
        end
    end

    // Pause acknowledgment logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_int <= 0;
        end else begin
            if (s_pause_req) begin
                s_pause_ack_int <= 1;
            end else if (s_pause_ack_int) begin
                s_pause_ack_int <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_int <= 0;
        end else begin
            if (m_pause_req) begin
                m_pause_ack_int <= 1;
            end else if (m_pause_ack_int) begin
                m_pause_ack_int <= 0;
            end
        end
    end

endmodule

// Asynchronous FIFO module
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024
)
(
    input wire clk_w,
    input wire rst_w,
    input wire wr_en,
    output wire full,
    input wire [DATA_WIDTH-1:0] din,
    input wire clk_r,
    input wire rst_r,
    input wire rd_en,
    output wire empty,
    output wire [DATA_WIDTH-1:0] dout,
    output wire valid
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] wr_ptr_w, wr_ptr_r;
    reg [ADDR_WIDTH-1:0] rd_ptr_w, rd_ptr_r;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_w, wr_ptr_gray_r;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_w, rd_ptr_gray_r;

    // Write pointer logic
    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            wr_ptr_w <= 0;
        end else if (wr_en & ~full) begin
            wr_ptr_w <= wr_ptr_w + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            rd_ptr_w <= 0;
        end else if (rd_en & ~empty) begin
            rd_ptr_w <= rd_ptr_w + 1;
        end
    end

    // Memory write
    always @(posedge clk_w) begin
        if (wr_en & ~full) begin
            mem[wr_ptr_w] <= din;
        end
    end

    // Memory read
    always @(posedge clk_r) begin
        if (rd_en & ~empty) begin
            dout <= mem[rd_ptr_r];
        end
    end

    // Gray code conversion
    always @(*) begin
        wr_ptr_gray_w = wr_ptr_w ^ (wr_ptr_w >> 1);
        rd_ptr_gray_w = rd_ptr_w ^ (rd_ptr_w >> 1);
    end

    // Gray code synchronization
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            wr_ptr_gray_r <= 0;
            wr_ptr_r <= 0;
        end else begin
            wr_ptr_gray_r <= wr_ptr_gray_w;
            wr_ptr_r <= (wr_ptr_gray_r ^ (wr_ptr_gray_r >> 1));
        end
    end

    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            rd_ptr_gray_r <= 0;
            rd_ptr_r <= 0;
        end else begin
            rd_ptr_gray_r <= rd_ptr_gray_w;
            rd_ptr_r <= (rd_ptr_gray_r ^ (rd_ptr_gray_r >> 1));
        end
    end

    // Full flag
    assign full = (wr_ptr_gray_w == (rd_ptr_gray_r ^ (1 << ADDR_WIDTH)));

    // Empty flag
    assign empty = (wr_ptr_gray_r == rd_ptr_gray_w);

    // Valid flag
    assign valid = ~empty;

endmodule

// CDC counter module
module cdc_counter #(
    parameter DEPTH = 1024
)
(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    output reg [$clog2(DEPTH):0] depth
);

    reg [$clog2(DEPTH):0] wr_cnt;
    reg [$clog2(DEPTH):0] rd_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_cnt <= 0;
            rd_cnt <= 0;
        end else begin
            if (wr_en) begin
                wr_cnt <= wr_cnt + 1;
            end
            if (rd_en) begin
                rd_cnt <= rd_cnt + 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth <= 0;
        end else begin
            depth <= wr_cnt - rd_cnt;
        end
    end

endmodule
