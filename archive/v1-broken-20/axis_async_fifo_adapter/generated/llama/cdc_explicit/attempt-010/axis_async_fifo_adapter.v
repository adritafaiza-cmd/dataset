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
reg fifo_ready;
reg fifo_last;
reg [ID_WIDTH-1:0] fifo_id;
reg [DEST_WIDTH-1:0] fifo_dest;
reg [USER_WIDTH-1:0] fifo_user;

// FIFO control signals
reg fifo_write;
reg fifo_read;
reg [S_DATA_WIDTH-1:0] fifo_out_data;
reg [S_KEEP_WIDTH-1:0] fifo_out_keep;
reg fifo_out_valid;
reg fifo_out_ready;
reg fifo_out_last;
reg [ID_WIDTH-1:0] fifo_out_id;
reg [DEST_WIDTH-1:0] fifo_out_dest;
reg [USER_WIDTH-1:0] fifo_out_user;

// CDC signals
reg [31:0] s_cdc_cnt;
reg [31:0] m_cdc_cnt;
reg s_cdc_rst;
reg m_cdc_rst;

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

// Pause signals
reg s_pause_ack_reg;
reg m_pause_ack_reg;

// Clock domain crossing
always @(posedge s_clk) begin
    if (s_rst) begin
        s_cdc_cnt <= 0;
        s_cdc_rst <= 1'b1;
    end else begin
        s_cdc_cnt <= s_cdc_cnt + 1;
        s_cdc_rst <= 1'b0;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_cdc_cnt <= 0;
        m_cdc_rst <= 1'b1;
    end else begin
        m_cdc_cnt <= m_cdc_cnt + 1;
        m_cdc_rst <= 1'b0;
    end
end

// FIFO implementation
axis_async_fifo #(
    .DEPTH(DEPTH),
    .DATA_WIDTH(S_DATA_WIDTH),
    .KEEP_ENABLE(S_KEEP_ENABLE),
    .KEEP_WIDTH(S_KEEP_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH)
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
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

// Width adapter
always @(posedge s_clk) begin
    if (s_rst) begin
        fifo_data <= {S_DATA_WIDTH{1'b0}};
        fifo_keep <= {S_KEEP_WIDTH{1'b0}};
        fifo_valid <= 1'b0;
        fifo_ready <= 1'b0;
        fifo_last <= 1'b0;
        fifo_id <= {ID_WIDTH{1'b0}};
        fifo_dest <= {DEST_WIDTH{1'b0}};
        fifo_user <= {USER_WIDTH{1'b0}};
    end else if (s_axis_tvalid && s_axis_tready) begin
        fifo_data <= s_axis_tdata;
        fifo_keep <= s_axis_tkeep;
        fifo_valid <= 1'b1;
        fifo_ready <= 1'b1;
        fifo_last <= s_axis_tlast;
        fifo_id <= s_axis_tid;
        fifo_dest <= s_axis_tdest;
        fifo_user <= s_axis_tuser;
    end else begin
        fifo_valid <= 1'b0;
        fifo_ready <= 1'b0;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_axis_tdata <= {M_DATA_WIDTH{1'b0}};
        m_axis_tkeep <= {M_KEEP_WIDTH{1'b0}};
        m_axis_tvalid <= 1'b0;
        m_axis_tready <= 1'b0;
        m_axis_tlast <= 1'b0;
        m_axis_tid <= {ID_WIDTH{1'b0}};
        m_axis_tdest <= {DEST_WIDTH{1'b0}};
        m_axis_tuser <= {USER_WIDTH{1'b0}};
    end else if (fifo_out_valid && m_axis_tready) begin
        m_axis_tdata <= fifo_out_data;
        m_axis_tkeep <= fifo_out_keep;
        m_axis_tvalid <= 1'b1;
        m_axis_tready <= 1'b1;
        m_axis_tlast <= fifo_out_last;
        m_axis_tid <= fifo_out_id;
        m_axis_tdest <= fifo_out_dest;
        m_axis_tuser <= fifo_out_user;
    end else begin
        m_axis_tvalid <= 1'b0;
        m_axis_tready <= 1'b0;
    end
end

// Status logic
always @(posedge s_clk) begin
    if (s_rst) begin
        s_status_depth_reg <= 0;
        s_status_depth_commit_reg <= 0;
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
    end else begin
        s_status_depth_reg <= s_status_depth_reg + (s_axis_tvalid && s_axis_tready) - (fifo_out_valid && m_axis_tready);
        s_status_depth_commit_reg <= s_status_depth_commit_reg + (s_axis_tvalid && s_axis_tready && s_axis_tlast) - (fifo_out_valid && m_axis_tready && fifo_out_last);
        s_status_overflow_reg <= (s_status_depth_reg == DEPTH) ? 1'b1 : 1'b0;
        s_status_bad_frame_reg <= (s_axis_tvalid && s_axis_tready && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) ? 1'b1 : 1'b0;
        s_status_good_frame_reg <= (s_axis_tvalid && s_axis_tready && s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) ? 1'b1 : 1'b0;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_status_depth_reg <= 0;
        m_status_depth_commit_reg <= 0;
        m_status_overflow_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
    end else begin
        m_status_depth_reg <= m_status_depth_reg + (fifo_out_valid && m_axis_tready) - (s_axis_tvalid && s_axis_tready);
        m_status_depth_commit_reg <= m_status_depth_commit_reg + (fifo_out_valid && m_axis_tready && fifo_out_last) - (s_axis_tvalid && s_axis_tready && s_axis_tlast);
        m_status_overflow_reg <= (m_status_depth_reg == DEPTH) ? 1'b1 : 1'b0;
        m_status_bad_frame_reg <= (fifo_out_valid && m_axis_tready && fifo_out_last && (fifo_out_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) ? 1'b1 : 1'b0;
        m_status_good_frame_reg <= (fifo_out_valid && m_axis_tready && fifo_out_last && (fifo_out_user & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) ? 1'b1 : 1'b0;
    end
end

// Pause logic
always @(posedge s_clk) begin
    if (s_rst) begin
        s_pause_ack_reg <= 1'b0;
    end else if (s_pause_req) begin
        s_pause_ack_reg <= 1'b1;
    end else begin
        s_pause_ack_reg <= 1'b0;
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_pause_ack_reg <= 1'b0;
    end else if (m_pause_req) begin
        m_pause_ack_reg <= 1'b1;
    end else begin
        m_pause_ack_reg <= 1'b0;
    end
end

// Output assignments
assign s_axis_tready = fifo_ready;
assign m_axis_tdata = fifo_out_data;
assign m_axis_tkeep = fifo_out_keep;
assign m_axis_tvalid = fifo_out_valid;
assign m_axis_tlast = fifo_out_last;
assign m_axis_tid = fifo_out_id;
assign m_axis_tdest = fifo_out_dest;
assign m_axis_tuser = fifo_out_user;
assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
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
