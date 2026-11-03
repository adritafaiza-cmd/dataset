module axis_async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] keep_mem [DEPTH-1:0];
reg [LAST_ENABLE ? 1 : 0 -1:0] last_mem [DEPTH-1:0];
reg [ID_ENABLE ? ID_WIDTH : 0 -1:0] id_mem [DEPTH-1:0];
reg [DEST_ENABLE ? DEST_WIDTH : 0 -1:0] dest_mem [DEPTH-1:0];
reg [USER_ENABLE ? USER_WIDTH : 0 -1:0] user_mem [DEPTH-1:0];

reg [$clog2(DEPTH)-1:0] wr_ptr;
reg [$clog2(DEPTH)-1:0] rd_ptr;
reg [$clog2(DEPTH)-1:0] wr_ptr_gray;
reg [$clog2(DEPTH)-1:0] rd_ptr_gray;

reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
reg [LAST_ENABLE ? 1 : 0 -1:0] s_axis_tlast_reg;
reg [ID_ENABLE ? ID_WIDTH : 0 -1:0] s_axis_tid_reg;
reg [DEST_ENABLE ? DEST_WIDTH : 0 -1:0] s_axis_tdest_reg;
reg [USER_ENABLE ? USER_WIDTH : 0 -1:0] s_axis_tuser_reg;

reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg [LAST_ENABLE ? 1 : 0 -1:0] m_axis_tlast_reg;
reg [ID_ENABLE ? ID_WIDTH : 0 -1:0] m_axis_tid_reg;
reg [DEST_ENABLE ? DEST_WIDTH : 0 -1:0] m_axis_tdest_reg;
reg [USER_ENABLE ? USER_WIDTH : 0 -1:0] m_axis_tuser_reg;

reg s_axis_tvalid_reg;
reg m_axis_tvalid_reg;

reg s_pause_ack_reg;
reg m_pause_ack_reg;

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

assign s_axis_tready = (wr_ptr != rd_ptr + DEPTH - 1) && !s_pause_req;
assign m_axis_tvalid = m_axis_tvalid_reg;

always @(posedge s_clk or posedge s_rst)
begin
    if (s_rst)
    begin
        wr_ptr <= 0;
        s_axis_tdata_reg <= 0;
        s_axis_tkeep_reg <= 0;
        s_axis_tlast_reg <= 0;
        s_axis_tid_reg <= 0;
        s_axis_tdest_reg <= 0;
        s_axis_tuser_reg <= 0;
        s_axis_tvalid_reg <= 0;
        s_pause_ack_reg <= 0;
        s_status_depth_reg <= 0;
        s_status_depth_commit_reg <= 0;
        s_status_overflow_reg <= 0;
        s_status_bad_frame_reg <= 0;
        s_status_good_frame_reg <= 0;
    end
    else
    begin
        if (s_axis_tvalid && s_axis_tready)
        begin
            mem[wr_ptr] <= s_axis_tdata;
            keep_mem[wr_ptr] <= s_axis_tkeep;
            last_mem[wr_ptr] <= s_axis_tlast;
            id_mem[wr_ptr] <= s_axis_tid;
            dest_mem[wr_ptr] <= s_axis_tdest;
            user_mem[wr_ptr] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
            s_axis_tvalid_reg <= 1;
        end
        else if (!s_axis_tvalid || !s_axis_tready)
        begin
            s_axis_tvalid_reg <= 0;
        end

        if (s_pause_req)
        begin
            s_pause_ack_reg <= 1;
        end
        else
        begin
            s_pause_ack_reg <= 0;
        end

        if (wr_ptr == rd_ptr + DEPTH - 1)
        begin
            s_status_overflow_reg <= 1;
        end
        else
        begin
            s_status_overflow_reg <= 0;
        end

        s_status_depth_reg <= wr_ptr - rd_ptr;
        s_status_depth_commit_reg <= wr_ptr - rd_ptr;
        s_status_bad_frame_reg <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
        s_status_good_frame_reg <= !(s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    end
end

always @(posedge m_clk or posedge m_rst)
begin
    if (m_rst)
    begin
        rd_ptr <= 0;
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tlast_reg <= 0;
        m_axis_tid_reg <= 0;
        m_axis_tdest_reg <= 0;
        m_axis_tuser_reg <= 0;
        m_axis_tvalid_reg <= 0;
        m_pause_ack_reg <= 0;
        m_status_depth_reg <= 0;
        m_status_depth_commit_reg <= 0;
        m_status_overflow_reg <= 0;
        m_status_bad_frame_reg <= 0;
        m_status_good_frame_reg <= 0;
    end
    else
    begin
        if (m_axis_tready && m_axis_tvalid)
        begin
            rd_ptr <= rd_ptr + 1;
            m_axis_tdata_reg <= mem[rd_ptr];
            m_axis_tkeep_reg <= keep_mem[rd_ptr];
            m_axis_tlast_reg <= last_mem[rd_ptr];
            m_axis_tid_reg <= id_mem[rd_ptr];
            m_axis_tdest_reg <= dest_mem[rd_ptr];
            m_axis_tuser_reg <= user_mem[rd_ptr];
            m_axis_tvalid_reg <= 0;
        end
        else if (!m_axis_tready || !m_axis_tvalid)
        begin
            m_axis_tvalid_reg <= 1;
        end

        if (m_pause_req)
        begin
            m_pause_ack_reg <= 1;
        end
        else
        begin
            m_pause_ack_reg <= 0;
        end

        m_status_depth_reg <= wr_ptr - rd_ptr;
        m_status_depth_commit_reg <= wr_ptr - rd_ptr;
        m_status_overflow_reg <= (wr_ptr == rd_ptr + DEPTH - 1);
        m_status_bad_frame_reg <= (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
        m_status_good_frame_reg <= !(m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    end
end

assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tid = m_axis_tid_reg;
assign m_axis_tdest = m_axis_tdest_reg;
assign m_axis_tuser = m_axis_tuser_reg;

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
