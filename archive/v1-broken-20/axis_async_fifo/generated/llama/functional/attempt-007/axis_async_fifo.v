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

reg [DATA_WIDTH-1:0] fifo_data [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] fifo_keep [DEPTH-1:0];
reg [ID_WIDTH-1:0] fifo_id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] fifo_dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] fifo_user [DEPTH-1:0];
reg [DEPTH-1:0] fifo_last;

reg [$clog2(DEPTH)-1:0] wr_ptr;
reg [$clog2(DEPTH)-1:0] rd_ptr;
reg [$clog2(DEPTH)-1:0] wr_ptr_gray;
reg [$clog2(DEPTH)-1:0] rd_ptr_gray;

reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
reg [ID_WIDTH-1:0] m_axis_tid_reg;
reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
reg [USER_WIDTH-1:0] m_axis_tuser_reg;
reg m_axis_tlast_reg;

reg s_axis_tready_reg;
reg m_axis_tvalid_reg;

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

reg s_pause_ack_reg;
reg m_pause_ack_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        wr_ptr <= 0;
        s_axis_tready_reg <= 1'b1;
        s_status_depth_reg <= 0;
        s_status_depth_commit_reg <= 0;
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
        s_pause_ack_reg <= 1'b0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            fifo_data[wr_ptr] <= s_axis_tdata;
            fifo_keep[wr_ptr] <= s_axis_tkeep;
            fifo_id[wr_ptr] <= s_axis_tid;
            fifo_dest[wr_ptr] <= s_axis_tdest;
            fifo_user[wr_ptr] <= s_axis_tuser;
            fifo_last[wr_ptr] <= s_axis_tlast;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH - 1) begin
                s_axis_tready_reg <= 1'b0;
            end
            if (s_axis_tlast) begin
                s_status_good_frame_reg <= 1'b1;
            end
        end
        if (s_pause_req) begin
            s_pause_ack_reg <= 1'b1;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        rd_ptr <= 0;
        m_axis_tvalid_reg <= 1'b0;
        m_status_depth_reg <= 0;
        m_status_depth_commit_reg <= 0;
        m_status_overflow_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
        m_pause_ack_reg <= 1'b0;
    end else begin
        if (m_axis_tready && m_axis_tvalid_reg) begin
            rd_ptr <= rd_ptr + 1;
            m_axis_tvalid_reg <= 1'b0;
        end
        if (m_pause_req) begin
            m_pause_ack_reg <= 1'b1;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end
end

always @(posedge m_clk) begin
    if (wr_ptr != rd_ptr) begin
        m_axis_tdata_reg <= fifo_data[rd_ptr];
        m_axis_tkeep_reg <= fifo_keep[rd_ptr];
        m_axis_tid_reg <= fifo_id[rd_ptr];
        m_axis_tdest_reg <= fifo_dest[rd_ptr];
        m_axis_tuser_reg <= fifo_user[rd_ptr];
        m_axis_tlast_reg <= fifo_last[rd_ptr];
        m_axis_tvalid_reg <= 1'b1;
    end
end

always @(posedge s_clk) begin
    s_status_depth_reg <= wr_ptr;
    s_status_depth_commit_reg <= wr_ptr;
end

always @(posedge m_clk) begin
    m_status_depth_reg <= rd_ptr;
    m_status_depth_commit_reg <= rd_ptr;
end

assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
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
