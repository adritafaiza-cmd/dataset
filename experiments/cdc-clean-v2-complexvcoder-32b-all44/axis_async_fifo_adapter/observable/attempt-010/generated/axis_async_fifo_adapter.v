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

    wire [S_DATA_WIDTH-1:0] s_to_m_fifo_s_axis_tdata;
    wire [S_KEEP_WIDTH-1:0] s_to_m_fifo_s_axis_tkeep;
    wire                    s_to_m_fifo_s_axis_tvalid;
    wire                    s_to_m_fifo_s_axis_tready;
    wire                    s_to_m_fifo_s_axis_tlast;
    wire [ID_WIDTH-1:0]     s_to_m_fifo_s_axis_tid;
    wire [DEST_WIDTH-1:0]   s_to_m_fifo_s_axis_tdest;
    wire [USER_WIDTH-1:0]   s_to_m_fifo_s_axis_tuser;

    wire [M_DATA_WIDTH-1:0] s_to_m_fifo_m_axis_tdata;
    wire [M_KEEP_WIDTH-1:0] s_to_m_fifo_m_axis_tkeep;
    wire                    s_to_m_fifo_m_axis_tvalid;
    wire                    s_to_m_fifo_m_axis_tready;
    wire                    s_to_m_fifo_m_axis_tlast;
    wire [ID_WIDTH-1:0]     s_to_m_fifo_m_axis_tid;
    wire [DEST_WIDTH-1:0]   s_to_m_fifo_m_axis_tdest;
    wire [USER_WIDTH-1:0]   s_to_m_fifo_m_axis_tuser;

    wire [$clog2(DEPTH):0]  s_to_m_fifo_s_status_depth;
    wire [$clog2(DEPTH):0]  s_to_m_fifo_s_status_depth_commit;
    wire                    s_to_m_fifo_s_status_overflow;
    wire                    s_to_m_fifo_s_status_bad_frame;
    wire                    s_to_m_fifo_s_status_good_frame;

    wire [$clog2(DEPTH):0]  s_to_m_fifo_m_status_depth;
    wire [$clog2(DEPTH):0]  s_to_m_fifo_m_status_depth_commit;
    wire                    s_to_m_fifo_m_status_overflow;
    wire                    s_to_m_fifo_m_status_bad_frame;
    wire                    s_to_m_fifo_m_status_good_frame;

    assign s_to_m_fifo_s_axis_tdata = s_axis_tdata;
    assign s_to_m_fifo_s_axis_tkeep = s_axis_tkeep;
    assign s_to_m_fifo_s_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = s_to_m_fifo_s_axis_tready;
    assign s_to_m_fifo_s_axis_tlast = s_axis_tlast;
    assign s_to_m_fifo_s_axis_tid = s_axis_tid;
    assign s_to_m_fifo_s_axis_tdest = s_axis_tdest;
    assign s_to_m_fifo_s_axis_tuser = s_axis_tuser;

    assign m_axis_tdata = s_to_m_fifo_m_axis_tdata;
    assign m_axis_tkeep = s_to_m_fifo_m_axis_tkeep;
    assign m_axis_tvalid = s_to_m_fifo_m_axis_tvalid;
    assign s_to_m_fifo_m_axis_tready = m_axis_tready;
    assign m_axis_tlast = s_to_m_fifo_m_axis_tlast;
    assign m_axis_tid = s_to_m_fifo_m_axis_tid;
    assign m_axis_tdest = s_to_m_fifo_m_axis_tdest;
    assign m_axis_tuser = s_to_m_fifo_m_axis_tuser;

    assign s_status_depth = s_to_m_fifo_s_status_depth;
    assign s_status_depth_commit = s_to_m_fifo_s_status_depth_commit;
    assign s_status_overflow = s_to_m_fifo_s_status_overflow;
    assign s_status_bad_frame = s_to_m_fifo_s_status_bad_frame;
    assign s_status_good_frame = s_to_m_fifo_s_status_good_frame;

    assign m_status_depth = s_to_m_fifo_m_status_depth;
    assign m_status_depth_commit = s_to_m_fifo_m_status_depth_commit;
    assign m_status_overflow = s_to_m_fifo_m_status_overflow;
    assign m_status_bad_frame = s_to_m_fifo_m_status_bad_frame;
    assign m_status_good_frame = s_to_m_fifo_m_status_good_frame;

    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

    async_fifo #(
        .DEPTH(DEPTH),
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
        .s_axis_tdata(s_to_m_fifo_s_axis_tdata),
        .s_axis_tkeep(s_to_m_fifo_s_axis_tkeep),
        .s_axis_tvalid(s_to_m_fifo_s_axis_tvalid),
        .s_axis_tready(s_to_m_fifo_s_axis_tready),
        .s_axis_tlast(s_to_m_fifo_s_axis_tlast),
        .s_axis_tid(s_to_m_fifo_s_axis_tid),
        .s_axis_tdest(s_to_m_fifo_s_axis_tdest),
        .s_axis_tuser(s_to_m_fifo_s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(s_to_m_fifo_m_axis_tdata),
        .m_axis_tkeep(s_to_m_fifo_m_axis_tkeep),
        .m_axis_tvalid(s_to_m_fifo_m_axis_tvalid),
        .m_axis_tready(s_to_m_fifo_m_axis_tready),
        .m_axis_tlast(s_to_m_fifo_m_axis_tlast),
        .m_axis_tid(s_to_m_fifo_m_axis_tid),
        .m_axis_tdest(s_to_m_fifo_m_axis_tdest),
        .m_axis_tuser(s_to_m_fifo_m_axis_tuser),
        .s_status_depth(s_to_m_fifo_s_status_depth),
        .s_status_depth_commit(s_to_m_fifo_s_status_depth_commit),
        .s_status_overflow(s_to_m_fifo_s_status_overflow),
        .s_status_bad_frame(s_to_m_fifo_s_status_bad_frame),
        .s_status_good_frame(s_to_m_fifo_s_status_good_frame),
        .m_status_depth(s_to_m_fifo_m_status_depth),
        .m_status_depth_commit(s_to_m_fifo_m_status_depth_commit),
        .m_status_overflow(s_to_m_fifo_m_status_overflow),
        .m_status_bad_frame(s_to_m_fifo_m_status_bad_frame),
        .m_status_good_frame(s_to_m_fifo_m_status_good_frame)
    );

endmodule

module async_fifo #
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
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
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
    localparam MEM_DEPTH = DEPTH;

    reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_sync;

    reg [S_DATA_WIDTH-1:0] mem_data [0:MEM_DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:MEM_DEPTH-1];
    reg [ID_WIDTH-1:0] mem_tid [0:MEM_DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest [0:MEM_DEPTH-1];
    reg [USER_WIDTH-1:0] mem_tuser [0:MEM_DEPTH-1];
    reg mem_tlast [0:MEM_DEPTH-1];

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_next;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_next;
    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_next;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_next;

    reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync_reg;
    reg [ADDR_WIDTH:0] m_rd_ptr_gray_sync_reg;

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    reg [ADDR_WIDTH:0] s_status_depth_reg;
    reg [ADDR_WIDTH:0] s_status_depth_commit_reg;
    reg [ADDR_WIDTH:0] m_status_depth_reg;
    reg [ADDR_WIDTH:0] m_status_depth_commit_reg;

    reg s_axis_tready_sync;
    reg m_axis_tvalid_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_next;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_next;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_next;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_next;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray;

    wire [ADDR_WIDTH:0] s_wr_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync_bin_gray_sync