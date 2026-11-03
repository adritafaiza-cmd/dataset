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

    wire [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    wire s_axis_tvalid_reg;
    wire s_axis_tlast_reg;
    wire [ID_WIDTH-1:0] s_axis_tid_reg;
    wire [DEST_WIDTH-1:0] s_axis_tdest_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg;
    wire s_axis_tready_reg;

    wire [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tlast_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;
    wire m_axis_tready_reg;

    wire s_axis_tready_out;
    wire m_axis_tvalid_out;

    wire s_pause_ack_out;
    wire m_pause_ack_out;

    wire s_status_depth_out;
    wire s_status_depth_commit_out;
    wire s_status_overflow_out;
    wire s_status_bad_frame_out;
    wire s_status_good_frame_out;

    wire m_status_depth_out;
    wire m_status_depth_commit_out;
    wire m_status_overflow_out;
    wire m_status_bad_frame_out;
    wire m_status_good_frame_out;

    // Synchronous FIFO for AXI input
    fifo_async #(
        .DEPTH(DEPTH),
        .WIDTH(S_DATA_WIDTH + S_KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH),
        .ALMOST_FULL_THRESHOLD(DEPTH - 16)
    ) s_axis_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({s_axis_tdata, s_axis_tkeep, s_axis_tvalid, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .wr_en(s_axis_tvalid),
        .rd_en(m_axis_tready_out),
        .dout({s_axis_tdata_reg, s_axis_tkeep_reg, s_axis_tvalid_reg, s_axis_tlast_reg, s_axis_tid_reg, s_axis_tdest_reg, s_axis_tuser_reg}),
        .full(s_status_overflow_out),
        .empty(s_status_good_frame_out)
    );

    // Synchronous FIFO for AXI output
    fifo_async #(
        .DEPTH(DEPTH),
        .WIDTH(M_DATA_WIDTH + M_KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH),
        .ALMOST_FULL_THRESHOLD(DEPTH - 16)
    ) m_axis_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .din({m_axis_tdata_reg, m_axis_tkeep_reg, m_axis_tvalid_reg, m_axis_tlast_reg, m_axis_tid_reg, m_axis_tdest_reg, m_axis_tuser_reg}),
        .wr_en(m_axis_tvalid_out),
        .rd_en(s_axis_tready_out),
        .dout({m_axis_tdata, m_axis_tkeep, m_axis_tvalid, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser}),
        .full(m_status_overflow_out),
        .empty(m_status_good_frame_out)
    );

    // Width adapter for AXI input
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH)
    ) s_axis_width_adapter (
        .clk(s_clk),
        .din(s_axis_tdata_reg),
        .dout(m_axis_tdata_reg),
        .valid(s_axis_tvalid_reg),
        .ready(m_axis_tready_out)
    );

    // Width adapter for AXI output
    width_adapter #(
        .S_DATA_WIDTH(M_DATA_WIDTH),
        .M_DATA_WIDTH(S_DATA_WIDTH)
    ) m_axis_width_adapter (
        .clk(m_clk),
        .din(m_axis_tdata),
        .dout(s_axis_tdata_reg),
        .valid(m_axis_tvalid_reg),
        .ready(s_axis_tready_out)
    );

    // Pause control
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_out <= 0;
        end else if (s_pause_req) begin
            s_pause_ack_out <= 1;
        end else begin
            s_pause_ack_out <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_out <= 0;
        end else if (m_pause_req) begin
            m_pause_ack_out <= 1;
        end else begin
            m_pause_ack_out <= 0;
        end
    end

    // Status outputs
    assign s_status_depth_out = s_axis_fifo.status_depth;
    assign s_status_depth_commit_out = s_axis_fifo.status_depth_commit;
    assign s_status_overflow_out = s_axis_fifo.status_overflow;
    assign s_status_bad_frame_out = s_axis_fifo.status_bad_frame;
    assign s_status_good_frame_out = s_axis_fifo.status_good_frame;

    assign m_status_depth_out = m_axis_fifo.status_depth;
    assign m_status_depth_commit_out = m_axis_fifo.status_depth_commit;
    assign m_status_overflow_out = m_axis_fifo.status_overflow;
    assign m_status_bad_frame_out = m_axis_fifo.status_bad_frame;
    assign m_status_good_frame_out = m_axis_fifo.status_good_frame;

    // Assign outputs
    assign s_axis_tready = s_axis_tready_out;
    assign m_axis_tready = m_axis_tready_out;
    assign s_pause_ack = s_pause_ack_out;
    assign m_pause_ack = m_pause_ack_out;
    assign s_status_depth = s_status_depth_out;
    assign s_status_depth_commit = s_status_depth_commit_out;
    assign s_status_overflow = s_status_overflow_out;
    assign s_status_bad_frame = s_status_bad_frame_out;
    assign s_status_good_frame = s_status_good_frame_out;
    assign m_status_depth = m_status_depth_out;
    assign m_status_depth_commit = m_status_depth_commit_out;
    assign m_status_overflow = m_status_overflow_out;
    assign m_status_bad_frame = m_status_bad_frame_out;
    assign m_status_good_frame = m_status_good_frame_out;

endmodule
