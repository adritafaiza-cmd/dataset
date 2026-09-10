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

    reg [DATA_WIDTH-1:0] fifo_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] fifo_keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] fifo_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] fifo_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] fifo_user [DEPTH-1:0];
    reg [DEPTH-1:0] fifo_last;
    reg [$clog2(DEPTH):0] fifo_count;
    reg [$clog2(DEPTH):0] fifo_commit_count;
    reg s_empty;
    reg s_full;
    reg m_empty;
    reg m_full;
    reg s_overflow;
    reg m_underflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;

    assign s_axis_tready = ~s_full;
    assign m_axis_tvalid = ~m_empty;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_empty <= 1'b1;
            s_full <= 1'b0;
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
            fifo_count <= 0;
            fifo_commit_count <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            if (fifo_count == DEPTH - 1) begin
                s_full <= 1'b1;
                s_overflow <= 1'b1;
            end else begin
                fifo_data[fifo_count] <= s_axis_tdata;
                fifo_keep[fifo_count] <= s_axis_tkeep;
                fifo_id[fifo_count] <= s_axis_tid;
                fifo_dest[fifo_count] <= s_axis_tdest;
                fifo_user[fifo_count] <= s_axis_tuser;
                fifo_last[fifo_count] <= s_axis_tlast;
                fifo_count <= fifo_count + 1;
                s_empty <= 1'b0;
            end
        end else if (s_pause_req) begin
            s_pause_ack <= 1'b1;
        end else begin
            s_pause_ack <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_empty <= 1'b1;
            m_full <= 1'b0;
            m_underflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            if (fifo_commit_count == 0) begin
                m_empty <= 1'b1;
                m_underflow <= 1'b1;
            end else begin
                m_axis_tdata <= fifo_data[fifo_commit_count - 1];
                m_axis_tkeep <= fifo_keep[fifo_commit_count - 1];
                m_axis_tlast <= fifo_last[fifo_commit_count - 1];
                m_axis_tid <= fifo_id[fifo_commit_count - 1];
                m_axis_tdest <= fifo_dest[fifo_commit_count - 1];
                m_axis_tuser <= fifo_user[fifo_commit_count - 1];
                fifo_commit_count <= fifo_commit_count - 1;
                m_full <= 1'b0;
            end
        end else if (m_pause_req) begin
            m_pause_ack <= 1'b1;
        end else begin
            m_pause_ack <= 1'b0;
        end
    end

    assign s_status_depth = fifo_count;
    assign s_status_depth_commit = fifo_commit_count;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = fifo_count;
    assign m_status_depth_commit = fifo_commit_count;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
