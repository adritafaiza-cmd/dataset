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

    wire [S_DATA_WIDTH-1:0] fifo_s_axis_tdata;
    wire [S_KEEP_WIDTH-1:0] fifo_s_axis_tkeep;
    wire                    fifo_s_axis_tvalid;
    wire                    fifo_s_axis_tready;
    wire                    fifo_s_axis_tlast;
    wire [ID_WIDTH-1:0]     fifo_s_axis_tid;
    wire [DEST_WIDTH-1:0]   fifo_s_axis_tdest;
    wire [USER_WIDTH-1:0]   fifo_s_axis_tuser;

    wire [M_DATA_WIDTH-1:0] fifo_m_axis_tdata;
    wire [M_KEEP_WIDTH-1:0] fifo_m_axis_tkeep;
    wire                    fifo_m_axis_tvalid;
    wire                    fifo_m_axis_tready;
    wire                    fifo_m_axis_tlast;
    wire [ID_WIDTH-1:0]     fifo_m_axis_tid;
    wire [DEST_WIDTH-1:0]   fifo_m_axis_tdest;
    wire [USER_WIDTH-1:0]   fifo_m_axis_tuser;

    wire [$clog2(DEPTH):0]  fifo_s_status_depth;
    wire [$clog2(DEPTH):0]  fifo_s_status_depth_commit;
    wire                    fifo_s_status_overflow;
    wire                    fifo_s_status_bad_frame;
    wire                    fifo_s_status_good_frame;
    wire [$clog2(DEPTH):0]  fifo_m_status_depth;
    wire [$clog2(DEPTH):0]  fifo_m_status_depth_commit;
    wire                    fifo_m_status_overflow;
    wire                    fifo_m_status_bad_frame;
    wire                    fifo_m_status_good_frame;

    wire                    fifo_s_pause_req;
    wire                    fifo_s_pause_ack;
    wire                    fifo_m_pause_req;
    wire                    fifo_m_pause_ack;

    // FIFO instantiation
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
    ) fifo_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(fifo_m_axis_tdata),
        .m_axis_tkeep(fifo_m_axis_tkeep),
        .m_axis_tvalid(fifo_m_axis_tvalid),
        .m_axis_tready(fifo_m_axis_tready),
        .m_axis_tlast(fifo_m_axis_tlast),
        .m_axis_tid(fifo_m_axis_tid),
        .m_axis_tdest(fifo_m_axis_tdest),
        .m_axis_tuser(fifo_m_axis_tuser),
        .s_pause_req(fifo_s_pause_req),
        .s_pause_ack(fifo_s_pause_ack),
        .m_pause_req(fifo_m_pause_req),
        .m_pause_ack(fifo_m_pause_ack),
        .s_status_depth(fifo_s_status_depth),
        .s_status_depth_commit(fifo_s_status_depth_commit),
        .s_status_overflow(fifo_s_status_overflow),
        .s_status_bad_frame(fifo_s_status_bad_frame),
        .s_status_good_frame(fifo_s_status_good_frame),
        .m_status_depth(fifo_m_status_depth),
        .m_status_depth_commit(fifo_m_status_depth_commit),
        .m_status_overflow(fifo_m_status_overflow),
        .m_status_bad_frame(fifo_m_status_bad_frame),
        .m_status_good_frame(fifo_m_status_good_frame)
    );

    // Width adaptation
    reg [M_DATA_WIDTH-1:0] adapted_tdata;
    reg [M_KEEP_WIDTH-1:0] adapted_tkeep;
    reg                    adapted_tvalid;
    reg                    adapted_tlast;
    reg [ID_WIDTH-1:0]     adapted_tid;
    reg [DEST_WIDTH-1:0]   adapted_tdest;
    reg [USER_WIDTH-1:0]   adapted_tuser;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            adapted_tdata  <= 0;
            adapted_tkeep  <= 0;
            adapted_tvalid <= 0;
            adapted_tlast  <= 0;
            adapted_tid    <= 0;
            adapted_tdest  <= 0;
            adapted_tuser  <= 0;
        end else if (fifo_m_axis_tvalid && m_axis_tready) begin
            adapted_tdata  <= fifo_m_axis_tdata;
            adapted_tkeep  <= fifo_m_axis_tkeep;
            adapted_tvalid <= fifo_m_axis_tvalid;
            adapted_tlast  <= fifo_m_axis_tlast;
            adapted_tid    <= fifo_m_axis_tid;
            adapted_tdest  <= fifo_m_axis_tdest;
            adapted_tuser  <= fifo_m_axis_tuser;
        end
    end

    assign m_axis_tdata  = adapted_tdata;
    assign m_axis_tkeep  = adapted_tkeep;
    assign m_axis_tvalid = adapted_tvalid;
    assign m_axis_tlast  = adapted_tlast;
    assign m_axis_tid    = adapted_tid;
    assign m_axis_tdest  = adapted_tdest;
    assign m_axis_tuser  = adapted_tuser;
    assign fifo_m_axis_tready = m_axis_tready;

    // Status signals
    assign s_status_depth         = fifo_s_status_depth;
    assign s_status_depth_commit  = fifo_s_status_depth_commit;
    assign s_status_overflow      = fifo_s_status_overflow;
    assign s_status_bad_frame     = fifo_s_status_bad_frame;
    assign s_status_good_frame    = fifo_s_status_good_frame;
    assign m_status_depth         = fifo_m_status_depth;
    assign m_status_depth_commit  = fifo_m_status_depth_commit;
    assign m_status_overflow      = fifo_m_status_overflow;
    assign m_status_bad_frame     = fifo_m_status_bad_frame;
    assign m_status_good_frame    = fifo_m_status_good_frame;

    // Pause signals
    assign fifo_s_pause_req = s_pause_req;
    assign s_pause_ack      = fifo_s_pause_ack;
    assign fifo_m_pause_req = m_pause_req;
    assign m_pause_ack      = fifo_m_pause_ack;

endmodule

module async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
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
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray;

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];
    reg                  mem_tlast [DEPTH-1:0];

    reg [ADDR_WIDTH:0] wptr_gray_sync;
    reg [ADDR_WIDTH:0] rptr_gray_sync;

    reg [ADDR_WIDTH:0] wptr_gray_sync2;
    reg [ADDR_WIDTH:0] rptr_gray_sync2;

    reg [ADDR_WIDTH:0] s_depth;
    reg [ADDR_WIDTH:0] m_depth;
    reg [ADDR_WIDTH:0] s_depth_commit;
    reg [ADDR_WIDTH:0] m_depth_commit;

    reg s_full;
    reg m_full;

    reg s_overflow;
    reg m_overflow;

    reg s_good_frame;
    reg s_bad_frame;
    reg m_good_frame;
    reg m_bad_frame;

    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_gray_sync <= 0;
            wptr_gray_sync2 <= 0;
            s_depth <= 0;
            s_depth_commit <= 0;
            s_full <= 0;
            s_overflow <= 0;
            s_good_frame <= 0;
            s_bad_frame <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_keep[wptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_tid[wptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                mem_tdest[wptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                mem_tuser[wptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                mem_tlast[wptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;

                wptr <= wptr + 1;
                wptr_gray <= wptr ^ (wptr >> 1);
                s_depth <= s_depth + 1;
                s_full <= (s_depth == DEPTH);
                s_good_frame <= s_axis_tlast;
                s_bad_frame <= (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            end

            if (s_full) begin
                s_depth_commit <= s_depth_commit;
                s_overflow <= 1;
            end else begin
                s_depth_commit <= s_depth;
                s_overflow <= 0;
            end

            if (s_pause_req) begin
                s_pause_ack_reg <= 1;
            end else begin
                s_pause_ack_reg <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_sync <= 0;
            rptr_gray_sync2 <= 0;
            m_depth <= 0;
            m_depth_commit <= 0;
            m_full <= 0;
            m_overflow <= 0;
            m_good_frame <= 0;
            m_bad_frame <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                rptr <= rptr + 1;
                rptr_gray <= rptr ^ (rptr >> 1);
                m_depth <= m_depth - 1;
                m_good_frame <= mem_tlast[rptr[ADDR_WIDTH-1:0]];
                m_bad_frame <= (USER_ENABLE && (mem_tuser[rptr[ADDR_WIDTH-1:0]] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
            end

            if (m_full) begin
                m_depth_commit <= m_depth_commit;
                m_overflow <= 1;
            end else begin
                m_depth_commit <= m_depth;
                m_overflow <= 0;
            end

            if (m_pause_req) begin
                m_pause_ack_reg <= 1;
            end else begin
                m_pause_ack_reg <= 0;
            end
        end
    end

    always @(posedge s_clk) begin
        wptr_gray_sync <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync;
    end

    always @(posedge m_clk) begin
        rptr_gray_sync <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync;
    end

    assign s_axis_tready = !s_full;
    assign m_axis_tvalid = (m_depth > 0) && !m_pause_req;

    assign m_axis_tdata = mem[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = mem_keep[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tlast = mem_tlast[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tid = mem_tid[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tdest = mem_tdest[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tuser = mem_tuser[rptr[ADDR_WIDTH-1:0]];

    assign s_status_depth = s_depth_commit;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth_commit;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

endmodule
