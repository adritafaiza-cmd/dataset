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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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
reg [KEEP_WIDTH-1:0] keep [DEPTH-1:0];
reg [LAST_ENABLE ? 1 : 0-1:0] last [DEPTH-1:0];
reg [ID_ENABLE ? ID_WIDTH : 0-1:0] id [DEPTH-1:0];
reg [DEST_ENABLE ? DEST_WIDTH : 0-1:0] dest [DEPTH-1:0];
reg [USER_ENABLE ? USER_WIDTH : 0-1:0] user [DEPTH-1:0];

reg [$clog2(DEPTH)-1:0] wr_ptr;
reg [$clog2(DEPTH)-1:0] rd_ptr;
reg [$clog2(DEPTH)-1:0] wr_ptr_gray;
reg [$clog2(DEPTH)-1:0] rd_ptr_gray;
reg [$clog2(DEPTH)-1:0] wr_ptr_sync;
reg [$clog2(DEPTH)-1:0] rd_ptr_sync;

reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
reg [LAST_ENABLE ? 1 : 0-1:0] s_axis_tlast_reg;
reg [ID_ENABLE ? ID_WIDTH : 0-1:0] s_axis_tid_reg;
reg [DEST_ENABLE ? DEST_WIDTH : 0-1:0] s_axis_tdest_reg;
reg [USER_ENABLE ? USER_WIDTH : 0-1:0] s_axis_tuser_reg;

reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg [LAST_ENABLE ? 1 : 0-1:0] m_axis_tlast_reg;
reg [ID_ENABLE ? ID_WIDTH : 0-1:0] m_axis_tid_reg;
reg [DEST_ENABLE ? DEST_WIDTH : 0-1:0] m_axis_tdest_reg;
reg [USER_ENABLE ? USER_WIDTH : 0-1:0] m_axis_tuser_reg;

reg s_axis_tvalid_reg;
reg m_axis_tvalid_reg;
reg s_axis_tready_reg;
reg m_axis_tready_reg;

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

integer i;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        wr_ptr <= 0;
        s_axis_tdata_reg <= 0;
        s_axis_tkeep_reg <= 0;
        s_axis_tlast_reg <= 0;
        s_axis_tid_reg <= 0;
        s_axis_tdest_reg <= 0;
        s_axis_tuser_reg <= 0;
        s_axis_tvalid_reg <= 0;
        s_axis_tready_reg <= 0;
        s_pause_ack_reg <= 0;
        s_status_depth_reg <= 0;
        s_status_depth_commit_reg <= 0;
        s_status_overflow_reg <= 0;
        s_status_bad_frame_reg <= 0;
        s_status_good_frame_reg <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem[wr_ptr] <= s_axis_tdata;
            keep[wr_ptr] <= s_axis_tkeep;
            last[wr_ptr] <= s_axis_tlast;
            id[wr_ptr] <= s_axis_tid;
            dest[wr_ptr] <= s_axis_tdest;
            user[wr_ptr] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
        end
        s_axis_tdata_reg <= s_axis_tdata;
        s_axis_tkeep_reg <= s_axis_tkeep;
        s_axis_tlast_reg <= s_axis_tlast;
        s_axis_tid_reg <= s_axis_tid;
        s_axis_tdest_reg <= s_axis_tdest;
        s_axis_tuser_reg <= s_axis_tuser;
        s_axis_tvalid_reg <= s_axis_tvalid;
        s_axis_tready_reg <= (wr_ptr != DEPTH-1) && !s_pause_ack_reg;
        s_pause_ack_reg <= s_pause_req && (wr_ptr != DEPTH-1);
        s_status_depth_reg <= wr_ptr;
        s_status_depth_commit_reg <= wr_ptr;
        s_status_overflow_reg <= (wr_ptr == DEPTH-1) && s_axis_tvalid;
        s_status_bad_frame_reg <= (s_axis_tlast && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
        s_status_good_frame_reg <= s_axis_tlast && !(s_axis_tuser & USER_BAD_FRAME_MASK);
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        rd_ptr <= 0;
        m_axis_tdata_reg <= 0;
        m_axis_tkeep_reg <= 0;
        m_axis_tlast_reg <= 0;
        m_axis_tid_reg <= 0;
        m_axis_tdest_reg <= 0;
        m_axis_tuser_reg <= 0;
        m_axis_tvalid_reg <= 0;
        m_axis_tready_reg <= 0;
        m_pause_ack_reg <= 0;
        m_status_depth_reg <= 0;
        m_status_depth_commit_reg <= 0;
        m_status_overflow_reg <= 0;
        m_status_bad_frame_reg <= 0;
        m_status_good_frame_reg <= 0;
    end else begin
        if (m_axis_tvalid_reg && m_axis_tready) begin
            rd_ptr <= rd_ptr + 1;
        end
        m_axis_tdata_reg <= mem[rd_ptr];
        m_axis_tkeep_reg <= keep[rd_ptr];
        m_axis_tlast_reg <= last[rd_ptr];
        m_axis_tid_reg <= id[rd_ptr];
        m_axis_tdest_reg <= dest[rd_ptr];
        m_axis_tuser_reg <= user[rd_ptr];
        m_axis_tvalid_reg <= (rd_ptr != wr_ptr_sync);
        m_axis_tready_reg <= 1;
        m_pause_ack_reg <= m_pause_req && (rd_ptr != wr_ptr_sync);
        m_status_depth_reg <= wr_ptr_sync - rd_ptr;
        m_status_depth_commit_reg <= wr_ptr_sync - rd_ptr;
        m_status_overflow_reg <= 0;
        m_status_bad_frame_reg <= 0;
        m_status_good_frame_reg <= 0;
    end
end

always @(posedge s_clk) begin
    wr_ptr_gray <= wr_ptr;
    for (i = 0; i < $clog2(DEPTH); i++) begin
        wr_ptr_gray[i] <= wr_ptr[i] ^ wr_ptr[i+1];
    end
end

always @(posedge m_clk) begin
    rd_ptr_gray <= rd_ptr;
    for (i = 0; i < $clog2(DEPTH); i++) begin
        rd_ptr_gray[i] <= rd_ptr[i] ^ rd_ptr[i+1];
    end
end

always @(posedge m_clk) begin
    wr_ptr_sync <= wr_ptr_gray;
end

always @(posedge s_clk) begin
    rd_ptr_sync <= rd_ptr_gray;
end

assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tid = m_axis_tid_reg;
assign m_axis_tdest = m_axis_tdest_reg;
assign m_axis_tuser = m_axis_tuser_reg;
assign s_axis_tready = s_axis_tready_reg;
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
