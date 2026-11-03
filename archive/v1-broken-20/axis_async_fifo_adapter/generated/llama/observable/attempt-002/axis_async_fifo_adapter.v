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

reg [S_DATA_WIDTH-1:0] s_data_reg;
reg [S_KEEP_WIDTH-1:0] s_keep_reg;
reg s_valid_reg;
reg s_last_reg;
reg [ID_WIDTH-1:0] s_id_reg;
reg [DEST_WIDTH-1:0] s_dest_reg;
reg [USER_WIDTH-1:0] s_user_reg;

reg [M_DATA_WIDTH-1:0] m_data_reg;
reg [M_KEEP_WIDTH-1:0] m_keep_reg;
reg m_valid_reg;
reg m_last_reg;
reg [ID_WIDTH-1:0] m_id_reg;
reg [DEST_WIDTH-1:0] m_dest_reg;
reg [USER_WIDTH-1:0] m_user_reg;

reg [$clog2(DEPTH)-1:0] s_ptr;
reg [$clog2(DEPTH)-1:0] m_ptr;
reg [$clog2(DEPTH)-1:0] s_ptr_gray;
reg [$clog2(DEPTH)-1:0] m_ptr_gray;

reg [S_DATA_WIDTH-1:0] fifo_data [DEPTH-1:0];
reg [S_KEEP_WIDTH-1:0] fifo_keep [DEPTH-1:0];
reg fifo_valid [DEPTH-1:0];
reg fifo_last [DEPTH-1:0];
reg [ID_WIDTH-1:0] fifo_id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] fifo_dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] fifo_user [DEPTH-1:0];

reg s_pause_ack_reg;
reg m_pause_ack_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_ptr <= 0;
        s_ptr_gray <= 0;
        s_pause_ack_reg <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            s_ptr <= s_ptr + 1;
            s_ptr_gray <= s_ptr_gray + 1;
        end
        s_pause_ack_reg <= s_pause_req;
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_ptr <= 0;
        m_ptr_gray <= 0;
        m_pause_ack_reg <= 0;
    end else begin
        if (m_axis_tvalid && m_axis_tready) begin
            m_ptr <= m_ptr + 1;
            m_ptr_gray <= m_ptr_gray + 1;
        end
        m_pause_ack_reg <= m_pause_req;
    end
end

always @(posedge s_clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
        fifo_data[s_ptr] <= s_axis_tdata;
        fifo_keep[s_ptr] <= s_axis_tkeep;
        fifo_valid[s_ptr] <= 1'b1;
        fifo_last[s_ptr] <= s_axis_tlast;
        fifo_id[s_ptr] <= s_axis_tid;
        fifo_dest[s_ptr] <= s_axis_tdest;
        fifo_user[s_ptr] <= s_axis_tuser;
    end
end

always @(posedge m_clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
        m_data_reg <= fifo_data[m_ptr];
        m_keep_reg <= fifo_keep[m_ptr];
        m_valid_reg <= fifo_valid[m_ptr];
        m_last_reg <= fifo_last[m_ptr];
        m_id_reg <= fifo_id[m_ptr];
        m_dest_reg <= fifo_dest[m_ptr];
        m_user_reg <= fifo_user[m_ptr];
    end
end

assign s_axis_tready = (s_ptr!= DEPTH-1) &&!s_pause_req;
assign m_axis_tvalid = (m_ptr!= 0) &&!m_pause_req;

assign m_axis_tdata = m_data_reg;
assign m_axis_tkeep = m_keep_reg;
assign m_axis_tlast = m_last_reg;
assign m_axis_tid = m_id_reg;
assign m_axis_tdest = m_dest_reg;
assign m_axis_tuser = m_user_reg;

assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;

assign s_status_depth = s_ptr;
assign s_status_depth_commit = s_ptr_gray;
assign s_status_overflow = (s_ptr == DEPTH-1);
assign s_status_bad_frame = (fifo_user[s_ptr] == USER_BAD_FRAME_VALUE);
assign s_status_good_frame = (fifo_user[s_ptr]!= USER_BAD_FRAME_VALUE);

assign m_status_depth = m_ptr;
assign m_status_depth_commit = m_ptr_gray;
assign m_status_overflow = (m_ptr == 0);
assign m_status_bad_frame = (fifo_user[m_ptr] == USER_BAD_FRAME_VALUE);
assign m_status_good_frame = (fifo_user[m_ptr]!= USER_BAD_FRAME_VALUE);

endmodule
