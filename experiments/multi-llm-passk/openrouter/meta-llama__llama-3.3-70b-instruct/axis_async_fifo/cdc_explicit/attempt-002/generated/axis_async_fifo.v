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

    reg [DATA_WIDTH-1:0]          fifo_data[DEPTH-1:0];
    reg [KEEP_WIDTH-1:0]          fifo_keep[DEPTH-1:0];
    reg [ID_WIDTH-1:0]           fifo_id[DEPTH-1:0];
    reg [DEST_WIDTH-1:0]         fifo_dest[DEPTH-1:0];
    reg [USER_WIDTH-1:0]         fifo_user[DEPTH-1:0];
    reg                         fifo_last[DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0]      wr_ptr;
    reg [$clog2(DEPTH)-1:0]      rd_ptr;
    reg [$clog2(DEPTH)-1:0]      commit_ptr;
    reg                         full;
    reg                         empty;
    reg                         overflow;
    reg                         bad_frame;
    reg                         good_frame;
    reg                         s_pause;
    reg                         m_pause;

    assign s_axis_tready = !full && !s_pause;
    assign m_axis_tvalid = !empty && !m_pause;
    assign s_pause_ack = s_pause;
    assign m_pause_ack = m_pause;

    assign s_status_depth = wr_ptr - rd_ptr;
    assign s_status_depth_commit = commit_ptr - rd_ptr;
    assign s_status_overflow = overflow;
    assign s_status_bad_frame = bad_frame;
    assign s_status_good_frame = good_frame;
    assign m_status_depth = wr_ptr - rd_ptr;
    assign m_status_depth_commit = commit_ptr - rd_ptr;
    assign m_status_overflow = overflow;
    assign m_status_bad_frame = bad_frame;
    assign m_status_good_frame = good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            full <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
            s_pause <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            fifo_data[wr_ptr] <= s_axis_tdata;
            fifo_keep[wr_ptr] <= s_axis_tkeep;
            fifo_id[wr_ptr] <= s_axis_tid;
            fifo_dest[wr_ptr] <= s_axis_tdest;
            fifo_user[wr_ptr] <= s_axis_tuser;
            fifo_last[wr_ptr] <= s_axis_tlast;
            if (wr_ptr == DEPTH-1) begin
                wr_ptr <= 0;
                full <= 1;
            end else begin
                wr_ptr <= wr_ptr + 1;
            end
            if (s_axis_tlast) begin
                if (s_axis_tuser == USER_BAD_FRAME_VALUE) begin
                    bad_frame <= 1;
                end else begin
                    good_frame <= 1;
                end
            end
        end else if (s_pause_req) begin
            s_pause <= 1;
        end else if (!s_pause_req) begin
            s_pause <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            empty <= 1;
            m_pause <= 0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            if (rd_ptr == DEPTH-1) begin
                rd_ptr <= 0;
                empty <= 1;
            end else begin
                rd_ptr <= rd_ptr + 1;
            end
        end else if (m_pause_req) begin
            m_pause <= 1;
        end else if (!m_pause_req) begin
            m_pause <= 0;
        end
    end

    always @(posedge m_clk) begin
        if (!empty && !m_pause) begin
            m_axis_tdata <= fifo_data[rd_ptr];
            m_axis_tkeep <= fifo_keep[rd_ptr];
            m_axis_tlast <= fifo_last[rd_ptr];
            m_axis_tid <= fifo_id[rd_ptr];
            m_axis_tdest <= fifo_dest[rd_ptr];
            m_axis_tuser <= fifo_user[rd_ptr];
        end
    end

endmodule
