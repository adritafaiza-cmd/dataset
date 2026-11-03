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

    wire [S_DATA_WIDTH-1:0] s_to_m_fifo_m_data;
    wire s_to_m_fifo_m_valid;
    wire s_to_m_fifo_m_ready;

    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH + S_KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH)
    ) s_to_m_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .s_data({s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .s_valid(s_axis_tvalid),
        .s_ready(s_axis_tready),
        .m_data({s_to_m_fifo_m_data, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .m_valid(s_to_m_fifo_m_valid),
        .m_ready(s_to_m_fifo_m_ready),
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

    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH)
    ) data_width_adapter (
        .clk(m_clk),
        .rst(m_rst),
        .s_data(s_to_m_fifo_m_data),
        .s_valid(s_to_m_fifo_m_valid),
        .s_ready(s_to_m_fifo_m_ready),
        .m_data(m_axis_tdata),
        .m_valid(m_axis_tvalid),
        .m_ready(m_axis_tready),
        .s_keep(s_axis_tkeep),
        .s_last(s_axis_tlast),
        .s_tid(s_axis_tid),
        .s_dest(s_axis_tdest),
        .s_user(s_axis_tuser),
        .m_keep(m_axis_tkeep),
        .m_last(m_axis_tlast),
        .m_tid(m_axis_tid),
        .m_dest(m_axis_tdest),
        .m_user(m_axis_tuser)
    );

    assign s_pause_ack = 1'b0; // Pause is not implemented in this design
    assign m_pause_ack = 1'b0; // Pause is not implemented in this design

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 32
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire                     m_clk,
    input  wire                     m_rst,
    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire                     s_valid,
    output wire                     s_ready,
    output wire [DATA_WIDTH-1:0]  m_data,
    output wire                     m_valid,
    input  wire                     m_ready,
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

    reg [$clog2(DEPTH)-1:0] s_wr_ptr;
    reg [$clog2(DEPTH)-1:0] s_wr_ptr_gray;
    reg [$clog2(DEPTH)-1:0] m_rd_ptr;
    reg [$clog2(DEPTH)-1:0] m_rd_ptr_gray;

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [DATA_WIDTH-1:0] m_data_reg;

    reg s_full;
    reg m_empty;

    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;

    assign s_depth = s_full ? DEPTH : (s_wr_ptr > m_rd_ptr_gray) ? (s_wr_ptr - m_rd_ptr_gray) : (DEPTH + s_wr_ptr - m_rd_ptr_gray);
    assign m_depth = m_empty ? 0 : (m_rd_ptr > s_wr_ptr_gray) ? (DEPTH + s_wr_ptr_gray - m_rd_ptr) : (s_wr_ptr_gray - m_rd_ptr);

    assign s_ready = ~s_full;
    assign m_valid = ~m_empty;
    assign m_data = m_data_reg;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_full;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_full;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_full <= 0;
        end else begin
            if (s_valid && s_ready) begin
                mem[s_wr_ptr] <= s_data;
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
                s_full <= (s_wr_ptr + 1) == m_rd_ptr_gray;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_empty <= 1;
        end else begin
            if (m_valid && m_ready) begin
                m_data_reg <= mem[m_rd_ptr];
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= (m_rd_ptr + 1) ^ ((m_rd_ptr + 1) >> 1);
                m_empty <= (m_rd_ptr + 1) == s_wr_ptr_gray;
            end
        end
    end

endmodule

module width_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [S_DATA_WIDTH-1:0]  s_data,
    input  wire                     s_valid,
    output wire                     s_ready,
    output wire [M_DATA_WIDTH-1:0]  m_data,
    output wire                     m_valid,
    input  wire                     m_ready,
    input  wire [S_KEEP_WIDTH-1:0]  s_keep,
    input  wire                     s_last,
    input  wire [7:0]               s_tid,
    input  wire [7:0]               s_dest,
    input  wire [0:0]               s_user,
    output wire [M_KEEP_WIDTH-1:0]  m_keep,
    output wire                     m_last,
    output wire [7:0]               m_tid,
    output wire [7:0]               m_dest,
    output wire [0:0]               m_user
);

    reg [S_DATA_WIDTH-1:0] data_reg;
    reg valid_reg;
    reg [S_KEEP_WIDTH-1:0] keep_reg;
    reg last_reg;
    reg [7:0] tid_reg;
    reg [7:0] dest_reg;
    reg [0:0] user_reg;

    wire [M_DATA_WIDTH-1:0] data_out;
    wire [M_KEEP_WIDTH-1:0] keep_out;

    assign s_ready = ~valid_reg;
    assign m_valid = valid_reg;
    assign m_data = data_out;
    assign m_keep = keep_out;
    assign m_last = last_reg;
    assign m_tid = tid_reg;
    assign m_dest = dest_reg;
    assign m_user = user_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_reg <= 0;
        end else begin
            if (s_valid && s_ready) begin
                data_reg <= s_data;
                keep_reg <= s_keep;
                last_reg <= s_last;
                tid_reg <= s_tid;
                dest_reg <= s_dest;
                user_reg <= s_user;
                valid_reg <= 1;
            end else if (m_valid && m_ready) begin
                valid_reg <= 0;
            end
        end
    end

    assign data_out = data_reg;
    assign keep_out = keep_reg;

endmodule
