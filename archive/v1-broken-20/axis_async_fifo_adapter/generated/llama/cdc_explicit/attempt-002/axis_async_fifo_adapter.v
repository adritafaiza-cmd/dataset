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

// FIFO parameters
localparam FIFO_WIDTH = S_DATA_WIDTH + (S_KEEP_ENABLE ? S_KEEP_WIDTH : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0) + 1;

// FIFO signals
reg [FIFO_WIDTH-1:0] fifo_data [DEPTH-1:0];
reg [DEPTH-1:0] fifo_valid;
reg [DEPTH-1:0] fifo_ready;
reg [$clog2(DEPTH):0] fifo_depth;
reg [$clog2(DEPTH):0] fifo_depth_commit;
reg fifo_overflow;
reg fifo_bad_frame;
reg fifo_good_frame;

// CDC signals
reg s_rst_sync;
reg m_rst_sync;
reg [1:0] s_axis_tvalid_sync;
reg [1:0] s_axis_tlast_sync;
reg [1:0] s_axis_tkeep_sync [S_KEEP_WIDTH-1:0];
reg [1:0] s_axis_tid_sync [ID_WIDTH-1:0];
reg [1:0] s_axis_tdest_sync [DEST_WIDTH-1:0];
reg [1:0] s_axis_tuser_sync [USER_WIDTH-1:0];
reg [1:0] m_axis_tready_sync;

// FIFO control signals
reg s_axis_tready_int;
reg m_axis_tvalid_int;
reg [S_DATA_WIDTH-1:0] s_axis_tdata_int;
reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_int;
reg s_axis_tlast_int;
reg [ID_WIDTH-1:0] s_axis_tid_int;
reg [DEST_WIDTH-1:0] s_axis_tdest_int;
reg [USER_WIDTH-1:0] s_axis_tuser_int;
reg [M_DATA_WIDTH-1:0] m_axis_tdata_int;
reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_int;
reg m_axis_tlast_int;
reg [ID_WIDTH-1:0] m_axis_tid_int;
reg [DEST_WIDTH-1:0] m_axis_tdest_int;
reg [USER_WIDTH-1:0] m_axis_tuser_int;

// Pause signals
reg s_pause_ack_int;
reg m_pause_ack_int;

// Status signals
reg [$clog2(DEPTH):0] s_status_depth_int;
reg [$clog2(DEPTH):0] s_status_depth_commit_int;
reg s_status_overflow_int;
reg s_status_bad_frame_int;
reg s_status_good_frame_int;
reg [$clog2(DEPTH):0] m_status_depth_int;
reg [$clog2(DEPTH):0] m_status_depth_commit_int;
reg m_status_overflow_int;
reg m_status_bad_frame_int;
reg m_status_good_frame_int;

// CDC logic
always @(posedge s_clk) begin
    s_rst_sync <= s_rst;
    s_axis_tvalid_sync[0] <= s_axis_tvalid;
    s_axis_tvalid_sync[1] <= s_axis_tvalid_sync[0];
    s_axis_tlast_sync[0] <= s_axis_tlast;
    s_axis_tlast_sync[1] <= s_axis_tlast_sync[0];
    for (int i = 0; i < S_KEEP_WIDTH; i++) begin
        s_axis_tkeep_sync[i][0] <= s_axis_tkeep[i];
        s_axis_tkeep_sync[i][1] <= s_axis_tkeep_sync[i][0];
    end
    for (int i = 0; i < ID_WIDTH; i++) begin
        s_axis_tid_sync[i][0] <= s_axis_tid[i];
        s_axis_tid_sync[i][1] <= s_axis_tid_sync[i][0];
    end
    for (int i = 0; i < DEST_WIDTH; i++) begin
        s_axis_tdest_sync[i][0] <= s_axis_tdest[i];
        s_axis_tdest_sync[i][1] <= s_axis_tdest_sync[i][0];
    end
    for (int i = 0; i < USER_WIDTH; i++) begin
        s_axis_tuser_sync[i][0] <= s_axis_tuser[i];
        s_axis_tuser_sync[i][1] <= s_axis_tuser_sync[i][0];
    end
end

always @(posedge m_clk) begin
    m_rst_sync <= m_rst;
    m_axis_tready_sync[0] <= m_axis_tready;
    m_axis_tready_sync[1] <= m_axis_tready_sync[0];
end

// FIFO logic
always @(posedge s_clk) begin
    if (s_rst_sync) begin
        fifo_depth <= 0;
        fifo_depth_commit <= 0;
        fifo_overflow <= 0;
        fifo_bad_frame <= 0;
        fifo_good_frame <= 0;
    end else if (s_axis_tvalid_sync[1] && s_axis_tready_int) begin
        if (fifo_depth == DEPTH) begin
            fifo_overflow <= 1;
        end else begin
            fifo_data[fifo_depth] <= {s_axis_tdata, s_axis_tkeep_sync[0], s_axis_tid_sync[0], s_axis_tdest_sync[0], s_axis_tuser_sync[0], s_axis_tlast_sync[0]};
            fifo_depth <= fifo_depth + 1;
        end
    end
end

always @(posedge m_clk) begin
    if (m_rst_sync) begin
        fifo_depth_commit <= 0;
    end else if (m_axis_tready_sync[1] && m_axis_tvalid_int) begin
        if (fifo_depth_commit == 0) begin
            fifo_bad_frame <= 0;
            fifo_good_frame <= 0;
        end else begin
            fifo_depth_commit <= fifo_depth_commit - 1;
        end
    end
end

// FIFO control logic
always @(posedge s_clk) begin
    if (s_rst_sync) begin
        s_axis_tready_int <= 0;
    end else if (fifo_depth < DEPTH) begin
        s_axis_tready_int <= 1;
    end else begin
        s_axis_tready_int <= 0;
    end
end

always @(posedge m_clk) begin
    if (m_rst_sync) begin
        m_axis_tvalid_int <= 0;
    end else if (fifo_depth_commit > 0) begin
        m_axis_tvalid_int <= 1;
    end else begin
        m_axis_tvalid_int <= 0;
    end
end

// Data path logic
always @(posedge s_clk) begin
    if (s_axis_tvalid_sync[1] && s_axis_tready_int) begin
        s_axis_tdata_int <= s_axis_tdata;
        s_axis_tkeep_int <= s_axis_tkeep_sync[0];
        s_axis_tlast_int <= s_axis_tlast_sync[0];
        s_axis_tid_int <= s_axis_tid_sync[0];
        s_axis_tdest_int <= s_axis_tdest_sync[0];
        s_axis_tuser_int <= s_axis_tuser_sync[0];
    end
end

always @(posedge m_clk) begin
    if (m_axis_tready_sync[1] && m_axis_tvalid_int) begin
        m_axis_tdata_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH-1:0];
        m_axis_tkeep_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH+S_KEEP_WIDTH-1:S_DATA_WIDTH];
        m_axis_tlast_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH+S_KEEP_WIDTH];
        m_axis_tid_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH];
        m_axis_tdest_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH];
        m_axis_tuser_int <= fifo_data[fifo_depth_commit-1][S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH];
    end
end

// Pause logic
always @(posedge s_clk) begin
    if (s_rst_sync) begin
        s_pause_ack_int <= 0;
    end else if (s_pause_req) begin
        s_pause_ack_int <= 1;
    end else begin
        s_pause_ack_int <= 0;
    end
end

always @(posedge m_clk) begin
    if (m_rst_sync) begin
        m_pause_ack_int <= 0;
    end else if (m_pause_req) begin
        m_pause_ack_int <= 1;
    end else begin
        m_pause_ack_int <= 0;
    end
end

// Status logic
always @(posedge s_clk) begin
    s_status_depth_int <= fifo_depth;
    s_status_depth_commit_int <= fifo_depth_commit;
    s_status_overflow_int <= fifo_overflow;
    s_status_bad_frame_int <= fifo_bad_frame;
    s_status_good_frame_int <= fifo_good_frame;
end

always @(posedge m_clk) begin
    m_status_depth_int <= fifo_depth;
    m_status_depth_commit_int <= fifo_depth_commit;
    m_status_overflow_int <= fifo_overflow;
    m_status_bad_frame_int <= fifo_bad_frame;
    m_status_good_frame_int <= fifo_good_frame;
end

// Output assignments
assign s_axis_tready = s_axis_tready_int;
assign m_axis_tdata = m_axis_tdata_int;
assign m_axis_tkeep = m_axis_tkeep_int;
assign m_axis_tvalid = m_axis_tvalid_int;
assign m_axis_tlast = m_axis_tlast_int;
assign m_axis_tid = m_axis_tid_int;
assign m_axis_tdest = m_axis_tdest_int;
assign m_axis_tuser = m_axis_tuser_int;
assign s_pause_ack = s_pause_ack_int;
assign m_pause_ack = m_pause_ack_int;
assign s_status_depth = s_status_depth_int;
assign s_status_depth_commit = s_status_depth_commit_int;
assign s_status_overflow = s_status_overflow_int;
assign s_status_bad_frame = s_status_bad_frame_int;
assign s_status_good_frame = s_status_good_frame_int;
assign m_status_depth = m_status_depth_int;
assign m_status_depth_commit = m_status_depth_commit_int;
assign m_status_overflow = m_status_overflow_int;
assign m_status_bad_frame = m_status_bad_frame_int;
assign m_status_good_frame = m_status_good_frame_int;

endmodule
