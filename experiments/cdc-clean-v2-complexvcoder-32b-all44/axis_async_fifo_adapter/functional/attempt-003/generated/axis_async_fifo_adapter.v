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

    // Asynchronous FIFO instance
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) async_fifo_inst (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .wr_data(s_axis_tdata),
        .wr_keep(s_axis_tkeep),
        .wr_en(s_axis_tvalid),
        .wr_last(s_axis_tlast),
        .wr_id(s_axis_tid),
        .wr_dest(s_axis_tdest),
        .wr_user(s_axis_tuser),
        .wr_tready(s_axis_tready),
        .wr_pause_req(s_pause_req),
        .wr_pause_ack(s_pause_ack),
        .wr_depth(s_status_depth),
        .wr_depth_commit(s_status_depth_commit),
        .wr_overflow(s_status_overflow),
        .wr_bad_frame(s_status_bad_frame),
        .wr_good_frame(s_status_good_frame),
        .rd_data(m_axis_tdata),
        .rd_keep(m_axis_tkeep),
        .rd_valid(m_axis_tvalid),
        .rd_last(m_axis_tlast),
        .rd_id(m_axis_tid),
        .rd_dest(m_axis_tdest),
        .rd_user(m_axis_tuser),
        .rd_en(m_axis_tready),
        .rd_pause_req(m_pause_req),
        .rd_pause_ack(m_pause_ack),
        .rd_depth(m_status_depth),
        .rd_depth_commit(m_status_depth_commit),
        .rd_overflow(m_status_overflow),
        .rd_bad_frame(m_status_bad_frame),
        .rd_good_frame(m_status_good_frame)
    );

endmodule

// Asynchronous FIFO module
module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
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
    input  wire                     clk_wr,
    input  wire                     rst_wr,
    input  wire                     clk_rd,
    input  wire                     rst_rd,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire [KEEP_WIDTH-1:0]    wr_keep,
    input  wire                     wr_en,
    input  wire                     wr_last,
    input  wire [ID_WIDTH-1:0]      wr_id,
    input  wire [DEST_WIDTH-1:0]    wr_dest,
    input  wire [USER_WIDTH-1:0]    wr_user,
    output wire                     wr_tready,
    input  wire                     wr_pause_req,
    output wire                     wr_pause_ack,
    output wire [$clog2(DEPTH):0]   wr_depth,
    output wire [$clog2(DEPTH):0]   wr_depth_commit,
    output wire                     wr_overflow,
    output wire                     wr_bad_frame,
    output wire                     wr_good_frame,
    output wire [DATA_WIDTH-1:0]    rd_data,
    output wire [KEEP_WIDTH-1:0]    rd_keep,
    output wire                     rd_valid,
    output wire                     rd_last,
    output wire [ID_WIDTH-1:0]      rd_id,
    output wire [DEST_WIDTH-1:0]    rd_dest,
    output wire [USER_WIDTH-1:0]    rd_user,
    input  wire                     rd_en,
    input  wire                     rd_pause_req,
    output wire                     rd_pause_ack,
    output wire [$clog2(DEPTH):0]   rd_depth,
    output wire [$clog2(DEPTH):0]   rd_depth_commit,
    output wire                     rd_overflow,
    output wire                     rd_bad_frame,
    output wire                     rd_good_frame
);

    // FIFO signals
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg wr_last_mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] depth, depth_commit;
    reg overflow, bad_frame, good_frame;
    reg wr_pause_ack_reg, rd_pause_ack_reg;

    // Binary to Gray code conversion
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = $clog2(DEPTH)-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        return bin;
    endfunction

    // Write domain
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            wr_pause_ack_reg <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            wr_pause_ack_reg <= wr_pause_req;
            if (wr_en && !wr_tready) begin
                mem[wr_ptr] <= wr_data;
                keep_mem[wr_ptr] <= wr_keep;
                wr_last_mem[wr_ptr] <= wr_last;
                id_mem[wr_ptr] <= wr_id;
                dest_mem[wr_ptr] <= wr_dest;
                user_mem[wr_ptr] <= wr_user;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= bin2gray(wr_ptr + 1);
            end
            if (wr_en && !wr_tready && wr_last)
                good_frame <= 1;
            if (wr_en && !wr_tready && user_mem[wr_ptr] & USER_BAD_FRAME_MASK)
                bad_frame <= 1;
            if (wr_en && !wr_tready && (wr_ptr == rd_ptr_gray_sync))
                overflow <= 1;
        end
    end

    // Read domain
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_pause_ack_reg <= 0;
        end else begin
            rd_pause_ack_reg <= rd_pause_req;
            if (rd_en && rd_valid) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= bin2gray(rd_ptr + 1);
            end
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // FIFO status
    assign depth = gray2bin(wr_ptr_gray) - gray2bin(rd_ptr_gray_sync);
    assign depth_commit = depth;
    assign wr_tready = (depth < DEPTH) && !wr_pause_req;
    assign rd_valid = (depth > 0) && !rd_pause_req;

    // FIFO outputs
    assign rd_data = mem[rd_ptr];
    assign rd_keep = keep_mem[rd_ptr];
    assign rd_last = wr_last_mem[rd_ptr];
    assign rd_id = id_mem[rd_ptr];
    assign rd_dest = dest_mem[rd_ptr];
    assign rd_user = user_mem[rd_ptr];

    // Pause signals
    assign wr_pause_ack = wr_pause_ack_reg;
    assign rd_pause_ack = rd_pause_ack_reg;

    // Status outputs
    assign wr_status_depth = depth;
    assign wr_status_depth_commit = depth_commit;
    assign wr_status_overflow = overflow;
    assign wr_status_bad_frame = bad_frame;
    assign wr_status_good_frame = good_frame;
    assign rd_status_depth = depth;
    assign rd_status_depth_commit = depth_commit;
    assign rd_status_overflow = overflow;
    assign rd_status_bad_frame = bad_frame;
    assign rd_status_good_frame = good_frame;

endmodule
