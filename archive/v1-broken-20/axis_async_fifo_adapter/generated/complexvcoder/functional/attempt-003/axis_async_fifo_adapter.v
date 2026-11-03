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

    // Internal signals
    wire [S_DATA_WIDTH-1:0]  s_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep_reg;
    wire                     s_axis_tvalid_reg;
    wire                     s_axis_tlast_reg;
    wire [ID_WIDTH-1:0]      s_axis_tid_reg;
    wire [DEST_WIDTH-1:0]    s_axis_tdest_reg;
    wire [USER_WIDTH-1:0]    s_axis_tuser_reg;
    wire                     s_axis_tready_out;
    wire [M_DATA_WIDTH-1:0]  m_axis_tdata_reg;
    wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep_reg;
    wire                     m_axis_tvalid_reg;
    wire                     m_axis_tlast_reg;
    wire [ID_WIDTH-1:0]      m_axis_tid_reg;
    wire [DEST_WIDTH-1:0]    m_axis_tdest_reg;
    wire [USER_WIDTH-1:0]    m_axis_tuser_reg;
    wire                     m_axis_tready_out;

    // FIFO for input stream
    axis_async_fifo #(
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) fifo_s (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_tdata),
        .tkeep(s_axis_tkeep),
        .tvalid(s_axis_tvalid),
        .tready(s_axis_tready_out),
        .tlast(s_axis_tlast),
        .tid(s_axis_tid),
        .tdest(s_axis_tdest),
        .tuser(s_axis_tuser),
        .depth_commit(s_status_depth_commit),
        .overflow(s_status_overflow),
        .bad_frame(s_status_bad_frame),
        .good_frame(s_status_good_frame)
    );

    // FIFO for output stream
    axis_async_fifo #(
        .DATA_WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) fifo_m (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(m_axis_tdata),
        .tkeep(m_axis_tkeep),
        .tvalid(m_axis_tvalid),
        .tready(m_axis_tready_out),
        .tlast(m_axis_tlast),
        .tid(m_axis_tid),
        .tdest(m_axis_tdest),
        .tuser(m_axis_tuser),
        .depth_commit(m_status_depth_commit),
        .overflow(m_status_overflow),
        .bad_frame(m_status_bad_frame),
        .good_frame(m_status_good_frame)
    );

    // Width adapter
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready <= 1'b0;
            s_pause_ack <= 1'b0;
        end else begin
            s_axis_tready <= s_axis_tready_out;
            s_pause_ack <= ~s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tready <= 1'b0;
            m_pause_ack <= 1'b0;
        end else begin
            m_axis_tready <= m_axis_tready_out;
            m_pause_ack <= ~m_pause_req;
        end
    end

    assign s_status_depth = $clog2(DEPTH) ? fifo_s.depth : 1'b0;
    assign m_status_depth = $clog2(DEPTH) ? fifo_m.depth : 1'b0;

endmodule

module axis_async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1,
    parameter DEPTH = 4096,
    parameter RAM_PIPELINE = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [DATA_WIDTH-1:0]  tdata,
    input  wire [KEEP_WIDTH-1:0]  tkeep,
    input  wire                     tvalid,
    output wire                     tready,
    input  wire                     tlast,
    input  wire [ID_WIDTH-1:0]      tid,
    input  wire [DEST_WIDTH-1:0]    tdest,
    input  wire [USER_WIDTH-1:0]    tuser,
    output wire [$clog2(DEPTH):0]   depth_commit,
    output wire                     overflow,
    output wire                     bad_frame,
    output wire                     good_frame
);

    // Internal signals
    reg [DATA_WIDTH-1:0]  fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  fifo_keep [0:DEPTH-1];
    reg                     fifo_valid [0:DEPTH-1];
    reg                     fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]      fifo_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]    fifo_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]    fifo_tuser [0:DEPTH-1];
    reg                     wr_ptr;
    reg                     rd_ptr;
    reg                     wr_en;
    reg                     rd_en;
    reg                     full;
    reg                     empty;

    // Write process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else if (wr_en && ~full) begin
            fifo_data[wr_ptr] <= tdata;
            fifo_keep[wr_ptr] <= tkeep;
            fifo_valid[wr_ptr] <= tvalid;
            fifo_last[wr_ptr] <= tlast;
            fifo_tid[wr_ptr] <= tid;
            fifo_tdest[wr_ptr] <= tdest;
            fifo_tuser[wr_ptr] <= tuser;
            wr_ptr <= wr_ptr + 1;
            full <= wr_ptr == rd_ptr;
            empty <= 0;
        end
    end

    // Read process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else if (rd_en && ~empty) begin
            rd_ptr <= rd_ptr + 1;
            full <= wr_ptr == rd_ptr;
            empty <= wr_ptr == rd_ptr;
        end
    end

    // Read enable logic
    assign rd_en = tready && ~empty;

    // Write enable logic
    assign wr_en = tvalid && ~full;

    // FIFO status
    assign depth_commit = wr_ptr - rd_ptr;
    assign overflow = full;
    assign bad_frame = 1'b0;
    assign good_frame = 1'b0;

endmodule
