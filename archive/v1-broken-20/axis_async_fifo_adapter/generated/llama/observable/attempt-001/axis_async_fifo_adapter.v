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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
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

reg [S_DATA_WIDTH-1:0] s_fifo_tdata;
reg [S_KEEP_WIDTH-1:0] s_fifo_tkeep;
reg s_fifo_tvalid;
reg s_fifo_tlast;
reg [ID_WIDTH-1:0] s_fifo_tid;
reg [DEST_WIDTH-1:0] s_fifo_tdest;
reg [USER_WIDTH-1:0] s_fifo_tuser;

reg [M_DATA_WIDTH-1:0] m_fifo_tdata;
reg [M_KEEP_WIDTH-1:0] m_fifo_tkeep;
reg m_fifo_tvalid;
reg m_fifo_tlast;
reg [ID_WIDTH-1:0] m_fifo_tid;
reg [DEST_WIDTH-1:0] m_fifo_tdest;
reg [USER_WIDTH-1:0] m_fifo_tuser;

reg [$clog2(DEPTH)-1:0] s_fifo_ptr;
reg [$clog2(DEPTH)-1:0] m_fifo_ptr;

reg s_fifo_full;
reg m_fifo_empty;

reg s_pause;
reg m_pause;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_fifo_tvalid <= 1'b0;
        s_fifo_tlast <= 1'b0;
        s_fifo_ptr <= 'd0;
        s_fifo_full <= 1'b0;
        s_pause <= 1'b0;
    end else begin
        if (s_axis_tvalid && !s_fifo_full) begin
            s_fifo_tdata <= s_axis_tdata;
            s_fifo_tkeep <= s_axis_tkeep;
            s_fifo_tvalid <= 1'b1;
            s_fifo_tlast <= s_axis_tlast;
            s_fifo_tid <= s_axis_tid;
            s_fifo_tdest <= s_axis_tdest;
            s_fifo_tuser <= s_axis_tuser;
            s_fifo_ptr <= s_fifo_ptr + 1;
            if (s_fifo_ptr == DEPTH - 1) begin
                s_fifo_full <= 1'b1;
            end
        end
        if (s_axis_tready && s_fifo_tvalid) begin
            s_fifo_tvalid <= 1'b0;
            s_fifo_tlast <= 1'b0;
            s_fifo_ptr <= s_fifo_ptr - 1;
            if (s_fifo_ptr == 'd0) begin
                s_fifo_full <= 1'b0;
            end
        end
        if (s_pause_req) begin
            s_pause <= 1'b1;
        end
        if (s_axis_tready && s_fifo_tvalid && s_pause) begin
            s_pause <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_fifo_tvalid <= 1'b0;
        m_fifo_tlast <= 1'b0;
        m_fifo_ptr <= 'd0;
        m_fifo_empty <= 1'b1;
        m_pause <= 1'b0;
    end else begin
        if (m_fifo_empty && s_fifo_tvalid) begin
            m_fifo_tdata <= s_fifo_tdata;
            m_fifo_tkeep <= s_fifo_tkeep;
            m_fifo_tvalid <= 1'b1;
            m_fifo_tlast <= s_fifo_tlast;
            m_fifo_tid <= s_fifo_tid;
            m_fifo_tdest <= s_fifo_tdest;
            m_fifo_tuser <= s_fifo_tuser;
            m_fifo_ptr <= m_fifo_ptr + 1;
            if (m_fifo_ptr == DEPTH - 1) begin
                m_fifo_empty <= 1'b0;
            end
        end
        if (m_axis_tready && m_fifo_tvalid) begin
            m_fifo_tvalid <= 1'b0;
            m_fifo_tlast <= 1'b0;
            m_fifo_ptr <= m_fifo_ptr - 1;
            if (m_fifo_ptr == 'd0) begin
                m_fifo_empty <= 1'b1;
            end
        end
        if (m_pause_req) begin
            m_pause <= 1'b1;
        end
        if (m_axis_tready && m_fifo_tvalid && m_pause) begin
            m_pause <= 1'b0;
        end
    end
end

assign s_axis_tready = !s_fifo_full && !s_pause;
assign m_axis_tdata = m_fifo_tdata;
assign m_axis_tkeep = m_fifo_tkeep;
assign m_axis_tvalid = m_fifo_tvalid;
assign m_axis_tlast = m_fifo_tlast;
assign m_axis_tid = m_fifo_tid;
assign m_axis_tdest = m_fifo_tdest;
assign m_axis_tuser = m_fifo_tuser;
assign s_pause_ack = s_pause;
assign m_pause_ack = m_pause;
assign s_status_depth = s_fifo_ptr;
assign s_status_depth_commit = s_fifo_ptr;
assign s_status_overflow = s_fifo_full;
assign s_status_bad_frame = 1'b0;
assign s_status_good_frame = 1'b0;
assign m_status_depth = m_fifo_ptr;
assign m_status_depth_commit = m_fifo_ptr;
assign m_status_overflow = 1'b0;
assign m_status_bad_frame = 1'b0;
assign m_status_good_frame = 1'b0;

endmodule
