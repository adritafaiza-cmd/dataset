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

    // FIFO instance
    fifo_async #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
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
    ) fifo_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data_in(s_axis_tdata),
        .s_keep_in(s_axis_tkeep),
        .s_valid_in(s_axis_tvalid),
        .s_ready_out(s_axis_tready),
        .s_last_in(s_axis_tlast),
        .s_id_in(s_axis_tid),
        .s_dest_in(s_axis_tdest),
        .s_user_in(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data_out(m_axis_tdata),
        .m_keep_out(m_axis_tkeep),
        .m_valid_out(m_axis_tvalid),
        .m_ready_in(m_axis_tready),
        .m_last_out(m_axis_tlast),
        .m_id_out(m_axis_tid),
        .m_dest_out(m_axis_tdest),
        .m_user_out(m_axis_tuser),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .s_status_depth(s_status_depth),
        .s_status_depth_commit(s_status_depth_commit),
        .s_status_overflow(s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_status_depth(m_status_depth),
        .m_status_depth_commit(m_status_depth_commit),
        .m_status_overflow(m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

endmodule

module fifo_async #
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_data_in,
    input  wire [KEEP_WIDTH-1:0]  s_keep_in,
    input  wire                   s_valid_in,
    output wire                   s_ready_out,
    input  wire                   s_last_in,
    input  wire [ID_WIDTH-1:0]    s_id_in,
    input  wire [DEST_WIDTH-1:0]  s_dest_in,
    input  wire [USER_WIDTH-1:0]  s_user_in,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_data_out,
    output wire [KEEP_WIDTH-1:0]  m_keep_out,
    output wire                   m_valid_out,
    input  wire                   m_ready_in,
    output wire                   m_last_out,
    output wire [ID_WIDTH-1:0]    m_id_out,
    output wire [DEST_WIDTH-1:0]  m_dest_out,
    output wire [USER_WIDTH-1:0]  m_user_out,
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    // FIFO control signals
    reg [$clog2(DEPTH):0] wptr_s, rptr_s, wptr_m, rptr_m;
    reg [$clog2(DEPTH):0] wptr_gray_s, rptr_gray_s, wptr_gray_m, rptr_gray_m;
    reg [$clog2(DEPTH):0] depth_s, depth_m;
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg s_ready, m_valid;

    // Binary to Gray conversion
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        bin = gray;
        for (i = $clog2(DEPTH); i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray2bin = bin;
    endfunction

    // FIFO write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr_s <= 0;
            wptr_gray_s <= 0;
        end else if (s_ready && s_valid_in) begin
            wptr_s <= wptr_s + 1;
            wptr_gray_s <= bin2gray(wptr_s + 1);
        end
    end

    // FIFO read logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr_m <= 0;
            rptr_gray_m <= 0;
        end else if (m_valid && m_ready_in) begin
            rptr_m <= rptr_m + 1;
            rptr_gray_m <= bin2gray(rptr_m + 1);
        end
    end

    // FIFO depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            depth_s <= 0;
        end else begin
            depth_s <= gray2bin(wptr_gray_s) - gray2bin(rptr_gray_s);
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            depth_m <= 0;
        end else begin
            depth_m <= gray2bin(wptr_gray_m) - gray2bin(rptr_gray_m);
        end
    end

    // FIFO write enable
    assign s_ready = (depth_s < DEPTH) ? 1'b1 : 1'b0;

    // FIFO read enable
    assign m_valid = (depth_m > 0) ? 1'b1 : 1'b0;

    // FIFO write data
    always @(posedge s_clk) begin
        if (s_ready && s_valid_in) begin
            mem_data[wptr_s] <= s_data_in;
            mem_keep[wptr_s] <= s_keep_in;
            mem_last[wptr_s] <= s_last_in;
            mem_user[wptr_s] <= s_user_in;
            if (ID_ENABLE) mem_id[wptr_s] <= s_id_in;
            if (DEST_ENABLE) mem_dest[wptr_s] <= s_dest_in;
        end
    end

    // FIFO read data
    always @(posedge m_clk) begin
        if (m_valid && m_ready_in) begin
            m_data_out <= mem_data[rptr_m];
            m_keep_out <= mem_keep[rptr_m];
            m_last_out <= mem_last[rptr_m];
            m_user_out <= mem_user[rptr_m];
            if (ID_ENABLE) m_id_out <= mem_id[rptr_m];
            if (DEST_ENABLE) m_dest_out <= mem_dest[rptr_m];
        end
    end

    // FIFO status
    assign s_axis_tready = s_ready;
    assign m_axis_tvalid = m_valid;
    assign s_status_depth = depth_s;
    assign s_status_depth_commit = depth_s;
    assign s_status_overflow = (depth_s == DEPTH);
    assign s_status_bad_frame = 1'b0; // Not implemented
    assign s_status_good_frame = 1'b0; // Not implemented
    assign m_status_depth = depth_m;
    assign m_status_depth_commit = depth_m;
    assign m_status_overflow = (depth_m == DEPTH);
    assign m_status_bad_frame = 1'b0; // Not implemented
    assign m_status_good_frame = 1'b0; // Not implemented

    // Pause signals
    assign s_pause_ack = 1'b0; // Not implemented
    assign m_pause_ack = 1'b0; // Not implemented

endmodule
