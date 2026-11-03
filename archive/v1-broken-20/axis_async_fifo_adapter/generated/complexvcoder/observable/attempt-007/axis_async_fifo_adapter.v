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

    // Clock-domain crossing for input signals
    wire [S_DATA_WIDTH-1:0] s_axis_tdata_sync;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_sync;
    wire s_axis_tvalid_sync;
    wire s_axis_tlast_sync;
    wire [ID_WIDTH-1:0] s_axis_tid_sync;
    wire [DEST_WIDTH-1:0] s_axis_tdest_sync;
    wire [USER_WIDTH-1:0] s_axis_tuser_sync;
    wire s_axis_tready_out;

    wire s_pause_req_sync;
    wire s_pause_ack_out;

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axis_tdata_sync <= 0;
            s_axis_tkeep_sync <= 0;
            s_axis_tvalid_sync <= 0;
            s_axis_tlast_sync <= 0;
            s_axis_tid_sync <= 0;
            s_axis_tdest_sync <= 0;
            s_axis_tuser_sync <= 0;
            s_axis_tready_out <= 0;
            s_pause_req_sync <= 0;
            s_pause_ack_out <= 0;
        end else begin
            s_axis_tdata_sync <= s_axis_tdata;
            s_axis_tkeep_sync <= s_axis_tkeep;
            s_axis_tvalid_sync <= s_axis_tvalid;
            s_axis_tlast_sync <= s_axis_tlast;
            s_axis_tid_sync <= s_axis_tid;
            s_axis_tdest_sync <= s_axis_tdest;
            s_axis_tuser_sync <= s_axis_tuser;
            s_axis_tready_out <= s_axis_tready;
            s_pause_req_sync <= s_pause_req;
            s_pause_ack_out <= s_pause_ack;
        end
    end

    // Clock-domain crossing for output signals
    wire [M_DATA_WIDTH-1:0] m_axis_tdata_out;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_out;
    wire m_axis_tvalid_out;
    wire m_axis_tlast_out;
    wire [ID_WIDTH-1:0] m_axis_tid_out;
    wire [DEST_WIDTH-1:0] m_axis_tdest_out;
    wire [USER_WIDTH-1:0] m_axis_tuser_out;
    wire m_axis_tready_sync;

    wire m_pause_req_sync;
    wire m_pause_ack_out;

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axis_tdata_out <= 0;
            m_axis_tkeep_out <= 0;
            m_axis_tvalid_out <= 0;
            m_axis_tlast_out <= 0;
            m_axis_tid_out <= 0;
            m_axis_tdest_out <= 0;
            m_axis_tuser_out <= 0;
            m_axis_tready_sync <= 0;
            m_pause_req_sync <= 0;
            m_pause_ack_out <= 0;
        end else begin
            m_axis_tdata_out <= m_axis_tdata;
            m_axis_tkeep_out <= m_axis_tkeep;
            m_axis_tvalid_out <= m_axis_tvalid;
            m_axis_tlast_out <= m_axis_tlast;
            m_axis_tid_out <= m_axis_tid;
            m_axis_tdest_out <= m_axis_tdest;
            m_axis_tuser_out <= m_axis_tuser;
            m_axis_tready_sync <= m_axis_tready;
            m_pause_req_sync <= m_pause_req;
            m_pause_ack_out <= m_pause_ack;
        end
    end

    // FIFO for input side
    axis_async_fifo #(
        .WIDTH(S_DATA_WIDTH),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_in (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_tdata_sync),
        .tkeep(s_axis_tkeep_sync),
        .tvalid(s_axis_tvalid_sync),
        .tready(s_axis_tready_out),
        .tlast(s_axis_tlast_sync),
        .tid(s_axis_tid_sync),
        .tdest(s_axis_tdest_sync),
        .tuser(s_axis_tuser_sync),
        .depth(s_status_depth),
        .depth_commit(s_status_depth_commit),
        .overflow(s_status_overflow),
        .bad_frame(s_status_bad_frame),
        .good_frame(s_status_good_frame)
    );

    // FIFO for output side
    axis_async_fifo #(
        .WIDTH(M_DATA_WIDTH),
        .KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_out (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(m_axis_tdata_out),
        .tkeep(m_axis_tkeep_out),
        .tvalid(m_axis_tvalid_out),
        .tready(m_axis_tready_sync),
        .tlast(m_axis_tlast_out),
        .tid(m_axis_tid_out),
        .tdest(m_axis_tdest_out),
        .tuser(m_axis_tuser_out),
        .depth(m_status_depth),
        .depth_commit(m_status_depth_commit),
        .overflow(m_status_overflow),
        .bad_frame(m_status_bad_frame),
        .good_frame(m_status_good_frame)
    );

    // Pause handling
    assign s_pause_ack = s_pause_ack_out;
    assign m_pause_ack = m_pause_ack_out;

endmodule
