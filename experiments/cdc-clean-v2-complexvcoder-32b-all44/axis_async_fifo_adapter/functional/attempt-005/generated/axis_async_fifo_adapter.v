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

    // Internal signals for width adaptation
    wire [M_DATA_WIDTH-1:0]         s_axis_tdata_resized;
    wire [M_KEEP_WIDTH-1:0]         s_axis_tkeep_resized;

    // Instantiate the asynchronous FIFO
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH),
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
    ) s_to_m_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata_resized),
        .s_axis_tkeep(s_axis_tkeep_resized),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
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

    // Width adaptation logic
    always @(*) begin
        s_axis_tdata_resized = {M_DATA_WIDTH{1'b0}};
        s_axis_tdata_resized[S_DATA_WIDTH-1:0] = s_axis_tdata;

        s_axis_tkeep_resized = {M_KEEP_WIDTH{1'b1}};
        if (S_KEEP_ENABLE) begin
            s_axis_tkeep_resized[S_KEEP_WIDTH-1:0] = s_axis_tkeep;
        end
    end

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    input  wire                     m_clk,
    input  wire                     m_rst,
    input  wire                     m_axis_tready,
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire                     m_axis_tvalid,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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
    reg  [$clog2(DEPTH):0]          s_wr_ptr;
    reg  [$clog2(DEPTH):0]          s_wr_ptr_gray;
    reg  [$clog2(DEPTH):0]          m_rd_ptr;
    reg  [$clog2(DEPTH):0]          m_rd_ptr_gray;
    reg  [$clog2(DEPTH):0]          s_depth;
    reg  [$clog2(DEPTH):0]          m_depth;
    reg  [DATA_WIDTH-1:0]           mem [0:DEPTH-1];
    reg  [KEEP_WIDTH-1:0]           keep_mem [0:DEPTH-1];
    reg  [ID_WIDTH-1:0]             id_mem [0:DEPTH-1];
    reg  [DEST_WIDTH-1:0]           dest_mem [0:DEPTH-1];
    reg  [USER_WIDTH-1:0]           user_mem [0:DEPTH-1];
    reg                             mem_wr_en;
    reg                             mem_rd_en;
    reg                             s_axis_tready_reg;
    reg                             m_axis_tvalid_reg;
    reg                             s_pause_ack_reg;
    reg                             m_pause_ack_reg;
    reg                             s_status_overflow_reg;
    reg                             s_status_bad_frame_reg;
    reg                             s_status_good_frame_reg;
    reg                             m_status_overflow_reg;
    reg                             m_status_bad_frame_reg;
    reg                             m_status_good_frame_reg;

    // FIFO depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_gray <= 0;
            s_depth <= 0;
        end else begin
            if (mem_wr_en && !s_pause_req) begin
                s_wr_ptr <= s_wr_ptr + 1;
                s_wr_ptr_gray <= (s_wr_ptr + 1) ^ ((s_wr_ptr + 1) >> 1);
                s_depth <= s_depth + 1;
            end else if (mem_rd_en) begin
                s_depth <= s_depth - 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_gray <= 0;
            m_depth <= 0;
        end else begin
            if (mem_rd_en) begin
                m_rd_ptr <= m_rd_ptr + 1;
                m_rd_ptr_gray <= (m_rd_ptr + 1) ^ ((m_rd_ptr + 1) >> 1);
                m_depth <= m_depth - 1;
            end else if (mem_wr_en && !m_pause_req) begin
                m_depth <= m_depth + 1;
            end
        end
    end

    // FIFO write and read enable logic
    assign mem_wr_en = s_axis_tvalid && s_axis_tready_reg;
    assign mem_rd_en = m_axis_tvalid_reg && m_axis_tready;

    // FIFO memory
    always @(posedge s_clk) begin
        if (mem_wr_en && !s_pause_req) begin
            mem[s_wr_ptr] <= s_axis_tdata;
            keep_mem[s_wr_ptr] <= s_axis_tkeep;
            id_mem[s_wr_ptr] <= s_axis_tid;
            dest_mem[s_wr_ptr] <= s_axis_tdest;
            user_mem[s_wr_ptr] <= s_axis_tuser;
        end
    end

    always @(posedge m_clk) begin
        if (mem_rd_en) begin
            m_axis_tdata <= mem[m_rd_ptr];
            m_axis_tkeep <= keep_mem[m_rd_ptr];
            m_axis_tid <= id_mem[m_rd_ptr];
            m_axis_tdest <= dest_mem[m_rd_ptr];
            m_axis_tuser <= user_mem[m_rd_ptr];
        end
    end

    // FIFO status
    assign s_axis_tready_reg = (s_depth < DEPTH) && !s_pause_req;
    assign m_axis_tvalid_reg = (m_depth > 0) && !m_pause_req;

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    assign s_pause_ack_reg = s_pause_req;
    assign m_pause_ack_reg = m_pause_req;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow_reg = (s_depth == DEPTH) && s_axis_tvalid && !s_axis_tready_reg;
    assign s_status_bad_frame_reg = 1'b0; // Placeholder for actual bad frame detection
    assign s_status_good_frame_reg = 1'b0; // Placeholder for actual good frame detection

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow_reg = 1'b0; // Overflow not possible on read side
    assign m_status_bad_frame_reg = 1'b0; // Placeholder for actual bad frame detection
    assign m_status_good_frame_reg = 1'b0; // Placeholder for actual good frame detection

    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    assign m_axis_tlast = mem[m_rd_ptr] & s_axis_tlast; // Placeholder for actual tlast handling

endmodule
