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

    reg [DATA_WIDTH-1:0] s_fifo [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] s_fifo_keep [0:DEPTH-1];
    reg [LAST_ENABLE:0] s_fifo_last [0:DEPTH-1];
    reg [ID_ENABLE:0] s_fifo_id [0:DEPTH-1];
    reg [DEST_ENABLE:0] s_fifo_dest [0:DEPTH-1];
    reg [USER_ENABLE:0] s_fifo_user [0:DEPTH-1];
    reg [DEPTH-1:0] s_head, s_tail;
    reg s_full, s_empty;
    reg s_overflow, s_bad_frame, s_good_frame;

    reg [DATA_WIDTH-1:0] m_fifo [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] m_fifo_keep [0:DEPTH-1];
    reg [LAST_ENABLE:0] m_fifo_last [0:DEPTH-1];
    reg [ID_ENABLE:0] m_fifo_id [0:DEPTH-1];
    reg [DEST_ENABLE:0] m_fifo_dest [0:DEPTH-1];
    reg [USER_ENABLE:0] m_fifo_user [0:DEPTH-1];
    reg [DEPTH-1:0] m_head, m_tail;
    reg m_full, m_empty;
    reg m_overflow, m_bad_frame, m_good_frame;

    // Synchronous FIFO logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_head <= 0;
            s_tail <= 0;
            s_full <= 0;
            s_empty <= 1;
            s_overflow <= 0;
            s_bad_frame <= 0;
            s_good_frame <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_full) begin
                s_fifo[s_head] <= s_axis_tdata;
                s_fifo_keep[s_head] <= s_axis_tkeep;
                s_fifo_last[s_head] <= s_axis_tlast;
                s_fifo_id[s_head] <= s_axis_tid;
                s_fifo_dest[s_head] <= s_axis_tdest;
                s_fifo_user[s_head] <= s_axis_tuser;
                s_head <= s_head + 1;
                if (s_head == DEPTH - 1) begin
                    s_full <= 1;
                end else begin
                    s_empty <= 0;
                end
            end else if (m_axis_tready && !s_empty) begin
                s_tail <= s_tail + 1;
                if (s_tail == DEPTH - 1) begin
                    s_empty <= 1;
                end else begin
                    s_full <= 0;
                end
            end
        end
    end

    // Asynchronous FIFO logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_head <= 0;
            m_tail <= 0;
            m_full <= 0;
            m_empty <= 1;
            m_overflow <= 0;
            m_bad_frame <= 0;
            m_good_frame <= 0;
        end else begin
            if (m_axis_tready && !m_full) begin
                m_fifo[m_head] <= m_axis_tdata;
                m_fifo_keep[m_head] <= m_axis_tkeep;
                m_fifo_last[m_head] <= m_axis_tlast;
                m_fifo_id[m_head] <= m_axis_tid;
                m_fifo_dest[m_head] <= m_axis_tdest;
                m_fifo_user[m_head] <= m_axis_tuser;
                m_head <= m_head + 1;
                if (m_head == DEPTH - 1) begin
                    m_full <= 1;
                end else begin
                    m_empty <= 0;
                end
            end else if (s_axis_tready && !m_empty) begin
                m_tail <= m_tail + 1;
                if (m_tail == DEPTH - 1) begin
                    m_empty <= 1;
                end else begin
                    m_full <= 0;
                end
            end
        end
    end

    // Status outputs
    assign s_status_depth = s_head - s_tail;
    assign s_status_depth_commit = s_head;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = m_head - m_tail;
    assign m_status_depth_commit = m_head;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Pause signals
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Handshake logic
    assign s_axis_tready = !s_full;
    assign m_axis_tdata = s_fifo[s_tail];
    assign m_axis_tkeep = s_fifo_keep[s_tail];
    assign m_axis_tvalid = !s_empty;
    assign m_axis_tlast = s_fifo_last[s_tail];
    assign m_axis_tid = s_fifo_id[s_tail];
    assign m_axis_tdest = s_fifo_dest[s_tail];
    assign m_axis_tuser = s_fifo_user[s_tail];

endmodule
