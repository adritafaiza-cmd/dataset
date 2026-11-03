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

    /*
     * Internal signals
     */
    wire [S_DATA_WIDTH-1:0]         s_to_m_fifo_tdata;
    wire [S_KEEP_WIDTH-1:0]         s_to_m_fifo_tkeep;
    wire                            s_to_m_fifo_tvalid;
    wire                            s_to_m_fifo_tready;
    wire                            s_to_m_fifo_tlast;
    wire [ID_WIDTH-1:0]             s_to_m_fifo_tid;
    wire [DEST_WIDTH-1:0]           s_to_m_fifo_tdest;
    wire [USER_WIDTH-1:0]           s_to_m_fifo_tuser;

    wire [M_DATA_WIDTH-1:0]         width_adaptor_tdata;
    wire [M_KEEP_WIDTH-1:0]         width_adaptor_tkeep;
    wire                            width_adaptor_tvalid;
    wire                            width_adaptor_tready;
    wire                            width_adaptor_tlast;
    wire [ID_WIDTH-1:0]             width_adaptor_tid;
    wire [DEST_WIDTH-1:0]           width_adaptor_tdest;
    wire [USER_WIDTH-1:0]           width_adaptor_tuser;

    /*
     * Instantiate async_fifo
     */
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
    ) s_to_m_fifo (
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
        .m_axis_tdata(s_to_m_fifo_tdata),
        .m_axis_tkeep(s_to_m_fifo_tkeep),
        .m_axis_tvalid(s_to_m_fifo_tvalid),
        .m_axis_tready(s_to_m_fifo_tready),
        .m_axis_tlast(s_to_m_fifo_tlast),
        .m_axis_tid(s_to_m_fifo_tid),
        .m_axis_tdest(s_to_m_fifo_tdest),
        .m_axis_tuser(s_to_m_fifo_tuser),
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

    /*
     * Instantiate width_adapter
     */
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) width_adaptor (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_axis_tdata(s_to_m_fifo_tdata),
        .s_axis_tkeep(s_to_m_fifo_tkeep),
        .s_axis_tvalid(s_to_m_fifo_tvalid),
        .s_axis_tready(s_to_m_fifo_tready),
        .s_axis_tlast(s_to_m_fifo_tlast),
        .s_axis_tid(s_to_m_fifo_tid),
        .s_axis_tdest(s_to_m_fifo_tdest),
        .s_axis_tuser(s_to_m_fifo_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser)
    );

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

    /*
     * Internal signals
     */
    wire [$clog2(DEPTH):0]          wr_ptr_gray;
    wire [$clog2(DEPTH):0]          rd_ptr_gray;
    wire [$clog2(DEPTH):0]          wr_ptr_bin;
    wire [$clog2(DEPTH):0]          rd_ptr_bin;
    wire [$clog2(DEPTH):0]          wr_ptr_bin_next;
    wire [$clog2(DEPTH):0]          rd_ptr_bin_next;
    wire [$clog2(DEPTH):0]          wr_ptr_bin_sync;
    wire [$clog2(DEPTH):0]          rd_ptr_bin_sync;
    wire [$clog2(DEPTH):0]          depth;
    wire [$clog2(DEPTH):0]          depth_sync;
    wire                            fifo_full;
    wire                            fifo_empty;
    wire                            fifo_full_sync;
    wire                            fifo_empty_sync;

    reg [$clog2(DEPTH):0]           wr_ptr_gray_reg;
    reg [$clog2(DEPTH):0]           rd_ptr_gray_reg;
    reg [$clog2(DEPTH):0]           wr_ptr_bin_reg;
    reg [$clog2(DEPTH):0]           rd_ptr_bin_reg;

    /*
     * FIFO RAM
     */
    reg [DATA_WIDTH-1:0]            mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]            mem_keep [0:DEPTH-1];
    reg                             mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]              mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]            mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]            mem_tuser [0:DEPTH-1];

    /*
     * Write pointer logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_bin_reg <= 0;
            wr_ptr_gray_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            wr_ptr_bin_reg <= wr_ptr_bin_next;
            wr_ptr_gray_reg <= wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);
        end
    end

    assign wr_ptr_bin_next = wr_ptr_bin_reg + 1;

    /*
     * Read pointer logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr_bin_reg <= 0;
            rd_ptr_gray_reg <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rd_ptr_bin_reg <= rd_ptr_bin_next;
            rd_ptr_gray_reg <= rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);
        end
    end

    assign rd_ptr_bin_next = rd_ptr_bin_reg + 1;

    /*
     * Binary to Gray conversion for synchronization
     */
    assign wr_ptr_gray = wr_ptr_bin_reg ^ (wr_ptr_bin_reg >> 1);
    assign rd_ptr_gray = rd_ptr_bin_reg ^ (rd_ptr_bin_reg >> 1);

    /*
     * Gray to Binary conversion for synchronization
     */
    wire [$clog2(DEPTH):0]          wr_ptr_bin_sync_reg;
    wire [$clog2(DEPTH):0]          rd_ptr_bin_sync_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_bin_sync_reg <= 0;
        end else begin
            wr_ptr_bin_sync_reg <= wr_ptr_bin_sync;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_bin_sync_reg <= 0;
        end else begin
            rd_ptr_bin_sync_reg <= rd_ptr_bin_sync;
        end
    end

    assign wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_reg);
    assign rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_reg);

    /*
     * Gray to Binary conversion function
     */
    function [$clog2(DEPTH):0] gray_to_bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        begin
            gray_to_bin = gray;
            for (i = 1; i <= $clog2(DEPTH); i = i + 1) begin
                gray_to_bin = gray_to_bin ^ (gray_to_bin >> i);
            end
        end
    endfunction

    /*
     * FIFO flags
     */
    assign fifo_full = (wr_ptr_bin_next == (rd_ptr_bin_sync + DEPTH));
    assign fifo_empty = (wr_ptr_bin_sync == rd_ptr_bin_next);

    /*
     * FIFO status
     */
    assign s_status_depth = wr_ptr_bin_reg - rd_ptr_bin_sync;
    assign m_status_depth = wr_ptr_bin_sync_reg - rd_ptr_bin_reg;
    assign s_status_depth_commit = wr_ptr_bin_reg - rd_ptr_bin_sync;
    assign m_status_depth_commit = wr_ptr_bin_sync_reg - rd_ptr_bin_reg;
    assign s_status_overflow = fifo_full;
    assign m_status_overflow = fifo_full_sync;
    assign s_status_bad_frame = 1'b0; // Placeholder
    assign m_status_bad_frame = 1'b0; // Placeholder
    assign s_status_good_frame = 1'b0; // Placeholder
    assign m_status_good_frame = 1'b0; // Placeholder

    /*
     * FIFO write
     */
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem_data[wr_ptr_bin_reg] <= s_axis_tdata;
            mem_keep[wr_ptr_bin_reg] <= s_axis_tkeep;
            mem_last[wr_ptr_bin_reg] <= s_axis_tlast;
            mem_tid[wr_ptr_bin_reg] <= s_axis_tid;
            mem_tdest[wr_ptr_bin_reg] <= s_axis_tdest;
            mem_tuser[wr_ptr_bin_reg] <= s_axis_tuser;
        end
    end

    /*
     * FIFO read
     */
    assign m_axis_tdata = mem_data[rd_ptr_bin_reg];
    assign m_axis_tkeep = mem_keep[rd_ptr_bin_reg];
    assign m_axis_tlast = mem_last[rd_ptr_bin_reg];
    assign m_axis_tid = mem_tid[rd_ptr_bin_reg];
    assign m_axis_tdest = mem_tdest[rd_ptr_bin_reg];
    assign m_axis_tuser = mem_tuser[rd_ptr_bin_reg];

    /*
     * Handshake
     */
    assign s_axis_tready = !fifo_full && !s_pause_req;
    assign m_axis_tvalid = !fifo_empty && !m_pause_req;

    /*
     * Pause logic
     */
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

endmodule

module width_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = 0,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = 0,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1
)
(
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
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    /*
     * Internal signals
     */
    reg [S_DATA_WIDTH-1:0]          data_reg;
    reg [S_KEEP_WIDTH-1:0]          keep_reg;
    reg                             last_reg;
    reg [ID_WIDTH-1:0]              tid_reg;
    reg [DEST_WIDTH-1:0]            tdest_reg;
    reg [USER_WIDTH-1:0]            tuser_reg;
    reg                             valid_reg;

    /*
     * Register input data
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            data_reg <= 0;
            keep_reg <= 0;
            last_reg <= 0;
            tid_reg <= 0;
            tdest_reg <= 0;
            tuser_reg <= 0;
            valid_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            data_reg <= s_axis_tdata;
            keep_reg <= s_axis_tkeep;
            last_reg <= s_axis_tlast;
            tid_reg <= s_axis_tid;
            tdest_reg <= s_axis_tdest;
            tuser_reg <= s_axis_tuser;
            valid_reg <= 1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            valid_reg <= 0;
        end
    end

    /*
     * Width conversion
     */
    assign m_axis_tdata = data_reg;
    assign m_axis_tkeep = keep_reg;
    assign m_axis_tlast = last_reg;
    assign m_axis_tid = tid_reg;
    assign m_axis_tdest = tdest_reg;
    assign m_axis_tuser = tuser_reg;

    /*
     * Handshake
     */
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = valid_reg;

endmodule
