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

reg [S_DATA_WIDTH-1:0] s_data;
reg [S_KEEP_WIDTH-1:0] s_keep;
reg s_valid;
reg s_last;
reg [ID_WIDTH-1:0] s_id;
reg [DEST_WIDTH-1:0] s_dest;
reg [USER_WIDTH-1:0] s_user;

reg [M_DATA_WIDTH-1:0] m_data;
reg [M_KEEP_WIDTH-1:0] m_keep;
reg m_valid;
reg m_last;
reg [ID_WIDTH-1:0] m_id;
reg [DEST_WIDTH-1:0] m_dest;
reg [USER_WIDTH-1:0] m_user;

reg [$clog2(DEPTH)-1:0] s_ptr;
reg [$clog2(DEPTH)-1:0] m_ptr;
reg [$clog2(DEPTH)-1:0] s_ptr_gray;
reg [$clog2(DEPTH)-1:0] m_ptr_gray;

reg [S_DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [S_KEEP_WIDTH-1:0] keep [DEPTH-1:0];
reg [ID_WIDTH-1:0] id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] user [DEPTH-1:0];
reg last [DEPTH-1:0];

reg s_pause;
reg m_pause;

always @(posedge s_clk or posedge s_rst)
begin
    if (s_rst)
    begin
        s_ptr <= 0;
        s_ptr_gray <= 0;
        s_pause <= 0;
    end
    else
    begin
        if (s_axis_tvalid && s_axis_tready)
        begin
            mem[s_ptr] <= s_axis_tdata;
            keep[s_ptr] <= s_axis_tkeep;
            id[s_ptr] <= s_axis_tid;
            dest[s_ptr] <= s_axis_tdest;
            user[s_ptr] <= s_axis_tuser;
            last[s_ptr] <= s_axis_tlast;
            s_ptr <= s_ptr + 1;
            s_ptr_gray <= s_ptr_gray + 1;
        end
        if (s_pause_req)
        begin
            s_pause <= 1;
        end
        else if (s_pause_ack)
        begin
            s_pause <= 0;
        end
    end
end

always @(posedge m_clk or posedge m_rst)
begin
    if (m_rst)
    begin
        m_ptr <= 0;
        m_ptr_gray <= 0;
        m_pause <= 0;
    end
    else
    begin
        if (m_axis_tvalid && m_axis_tready)
        begin
            m_ptr <= m_ptr + 1;
            m_ptr_gray <= m_ptr_gray + 1;
        end
        if (m_pause_req)
        begin
            m_pause <= 1;
        end
        else if (m_pause_ack)
        begin
            m_pause <= 0;
        end
    end
end

always @(posedge s_clk)
begin
    if (s_axis_tvalid && s_axis_tready)
    begin
        s_data <= s_axis_tdata;
        s_keep <= s_axis_tkeep;
        s_valid <= 1;
        s_last <= s_axis_tlast;
        s_id <= s_axis_tid;
        s_dest <= s_axis_tdest;
        s_user <= s_axis_tuser;
    end
    else
    begin
        s_valid <= 0;
    end
end

always @(posedge m_clk)
begin
    if (m_axis_tvalid && m_axis_tready)
    begin
        m_data <= mem[m_ptr];
        m_keep <= keep[m_ptr];
        m_valid <= 1;
        m_last <= last[m_ptr];
        m_id <= id[m_ptr];
        m_dest <= dest[m_ptr];
        m_user <= user[m_ptr];
    end
    else
    begin
        m_valid <= 0;
    end
end

assign s_axis_tready = ~s_pause && (s_ptr!= DEPTH-1);
assign m_axis_tvalid = ~m_pause && (m_ptr!= DEPTH-1);
assign s_pause_ack = s_axis_tready;
assign m_pause_ack = m_axis_tvalid;

assign s_status_depth = s_ptr;
assign s_status_depth_commit = s_ptr_gray;
assign s_status_overflow = (s_ptr == DEPTH-1);
assign s_status_bad_frame = (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
assign s_status_good_frame = ~s_status_bad_frame;

assign m_status_depth = m_ptr;
assign m_status_depth_commit = m_ptr_gray;
assign m_status_overflow = (m_ptr == DEPTH-1);
assign m_status_bad_frame = (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
assign m_status_good_frame = ~m_status_bad_frame;

assign m_axis_tdata = m_data;
assign m_axis_tkeep = m_keep;
assign m_axis_tlast = m_last;
assign m_axis_tid = m_id;
assign m_axis_tdest = m_dest;
assign m_axis_tuser = m_user;

endmodule
