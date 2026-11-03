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

// FIFO signals
reg [S_DATA_WIDTH-1:0] fifo_data;
reg [S_KEEP_WIDTH-1:0] fifo_keep;
reg fifo_valid;
reg fifo_last;
reg [ID_WIDTH-1:0] fifo_id;
reg [DEST_WIDTH-1:0] fifo_dest;
reg [USER_WIDTH-1:0] fifo_user;
reg fifo_ready;
reg fifo_empty;
reg fifo_full;

// Width adapter signals
reg [M_DATA_WIDTH-1:0] adapter_data;
reg [M_KEEP_WIDTH-1:0] adapter_keep;
reg adapter_valid;
reg adapter_last;
reg [ID_WIDTH-1:0] adapter_id;
reg [DEST_WIDTH-1:0] adapter_dest;
reg [USER_WIDTH-1:0] adapter_user;
reg adapter_ready;

// CDC signals
reg s_rst_sync;
reg m_rst_sync;
reg s_axis_tvalid_sync;
reg m_axis_tready_sync;

// Status signals
reg [$clog2(DEPTH):0] s_status_depth_reg;
reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
reg s_status_overflow_reg;
reg s_status_bad_frame_reg;
reg s_status_good_frame_reg;
reg [$clog2(DEPTH):0] m_status_depth_reg;
reg [$clog2(DEPTH):0] m_status_depth_commit_reg;
reg m_status_overflow_reg;
reg m_status_bad_frame_reg;
reg m_status_good_frame_reg;

// CDC
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_rst_sync <= 1'b1;
    end else begin
        s_rst_sync <= 1'b0;
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_rst_sync <= 1'b1;
    end else begin
        m_rst_sync <= 1'b0;
    end
end

always @(posedge s_clk) begin
    s_axis_tvalid_sync <= s_axis_tvalid;
end

always @(posedge m_clk) begin
    m_axis_tready_sync <= m_axis_tready;
end

// FIFO
always @(posedge s_clk) begin
    if (s_rst_sync) begin
        fifo_data <= {S_DATA_WIDTH{1'b0}};
        fifo_keep <= {S_KEEP_WIDTH{1'b0}};
        fifo_valid <= 1'b0;
        fifo_last <= 1'b0;
        fifo_id <= {ID_WIDTH{1'b0}};
        fifo_dest <= {DEST_WIDTH{1'b0}};
        fifo_user <= {USER_WIDTH{1'b0}};
        fifo_ready <= 1'b0;
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
    end else if (s_axis_tvalid && !fifo_full) begin
        fifo_data <= s_axis_tdata;
        fifo_keep <= s_axis_tkeep;
        fifo_valid <= 1'b1;
        fifo_last <= s_axis_tlast;
        fifo_id <= s_axis_tid;
        fifo_dest <= s_axis_tdest;
        fifo_user <= s_axis_tuser;
        fifo_ready <= 1'b1;
        fifo_empty <= 1'b0;
    end else if (!s_axis_tvalid && fifo_valid) begin
        fifo_valid <= 1'b0;
        fifo_ready <= 1'b0;
    end
end

// Width adapter
always @(posedge m_clk) begin
    if (m_rst_sync) begin
        adapter_data <= {M_DATA_WIDTH{1'b0}};
        adapter_keep <= {M_KEEP_WIDTH{1'b0}};
        adapter_valid <= 1'b0;
        adapter_last <= 1'b0;
        adapter_id <= {ID_WIDTH{1'b0}};
        adapter_dest <= {DEST_WIDTH{1'b0}};
        adapter_user <= {USER_WIDTH{1'b0}};
        adapter_ready <= 1'b0;
    end else if (fifo_valid && !adapter_valid) begin
        adapter_data <= fifo_data;
        adapter_keep <= fifo_keep;
        adapter_valid <= 1'b1;
        adapter_last <= fifo_last;
        adapter_id <= fifo_id;
        adapter_dest <= fifo_dest;
        adapter_user <= fifo_user;
        adapter_ready <= 1'b1;
    end else if (!fifo_valid && adapter_valid) begin
        adapter_valid <= 1'b0;
        adapter_ready <= 1'b0;
    end
end

// Output
assign m_axis_tdata = adapter_data;
assign m_axis_tkeep = adapter_keep;
assign m_axis_tvalid = adapter_valid;
assign m_axis_tlast = adapter_last;
assign m_axis_tid = adapter_id;
assign m_axis_tdest = adapter_dest;
assign m_axis_tuser = adapter_user;

// Input
assign s_axis_tready = fifo_ready;

// Pause
assign s_pause_ack = 1'b0;
assign m_pause_ack = 1'b0;

// Status
always @(posedge s_clk) begin
    s_status_depth_reg <= $clog2(DEPTH);
    s_status_depth_commit_reg <= $clog2(DEPTH);
    s_status_overflow_reg <= 1'b0;
    s_status_bad_frame_reg <= 1'b0;
    s_status_good_frame_reg <= 1'b0;
end

always @(posedge m_clk) begin
    m_status_depth_reg <= $clog2(DEPTH);
    m_status_depth_commit_reg <= $clog2(DEPTH);
    m_status_overflow_reg <= 1'b0;
    m_status_bad_frame_reg <= 1'b0;
    m_status_good_frame_reg <= 1'b0;
end

assign s_status_depth = s_status_depth_reg;
assign s_status_depth_commit = s_status_depth_commit_reg;
assign s_status_overflow = s_status_overflow_reg;
assign s_status_bad_frame = s_status_bad_frame_reg;
assign s_status_good_frame = s_status_good_frame_reg;
assign m_status_depth = m_status_depth_reg;
assign m_status_depth_commit = m_status_depth_commit_reg;
assign m_status_overflow = m_status_overflow_reg;
assign m_status_bad_frame = m_status_bad_frame_reg;
assign m_status_good_frame = m_status_good_frame_reg;

endmodule
