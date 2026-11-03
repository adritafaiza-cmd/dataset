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

    wire s_axis_tready_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tlast_reg;
    wire [ID_WIDTH-1:0] m_axis_tid_reg;
    wire [DEST_WIDTH-1:0] m_axis_tdest_reg;
    wire [USER_WIDTH-1:0] m_axis_tuser_reg;

    // Internal signals for FIFO
    reg [S_DATA_WIDTH-1:0] s_fifo_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] s_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] s_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] s_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] s_fifo_user [0:DEPTH-1];
    reg s_fifo_valid [0:DEPTH-1];
    reg s_fifo_last [0:DEPTH-1];
    reg [1:0] s_fifo_head;
    reg [1:0] s_fifo_tail;
    reg [1:0] s_fifo_count;

    // Internal signals for width adapter
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;

    // Pause signals
    wire s_pause_ack_reg;
    wire m_pause_ack_reg;

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

    // FIFO operations
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_head <= 0;
            s_fifo_tail <= 0;
            s_fifo_count <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_fifo_data[s_fifo_head] <= s_axis_tdata;
                s_fifo_keep[s_fifo_head] <= s_axis_tkeep;
                s_fifo_id[s_fifo_head] <= s_axis_tid;
                s_fifo_dest[s_fifo_head] <= s_axis_tdest;
                s_fifo_user[s_fifo_head] <= s_axis_tuser;
                s_fifo_valid[s_fifo_head] <= 1;
                s_fifo_last[s_fifo_head] <= s_axis_tlast;
                s_fifo_head <= s_fifo_head + 1;
                s_fifo_count <= s_fifo_count + 1;
            end
            if (m_axis_tready && m_axis_tvalid) begin
                s_fifo_valid[s_fifo_tail] <= 0;
                s_fifo_head <= s_fifo_tail + 1;
                s_fifo_count <= s_fifo_count - 1;
            end
        end
    end

    // Width adapter
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata_reg <= s_axis_tdata;
                m_axis_tkeep_reg <= s_axis_tkeep;
            end
        end
    end

    // Pause handling
    assign s_pause_ack_reg = s_pause_req;
    assign m_pause_ack_reg = m_pause_req;

    // Status signals
    assign s_status_depth_reg = s_fifo_count;
    assign s_status_depth_commit_reg = s_fifo_count;
    assign s_status_overflow_reg = (s_fifo_count == DEPTH);
    assign s_status_bad_frame_reg = 0;
    assign s_status_good_frame_reg = 1;
    assign m_status_depth_reg = s_fifo_count;
    assign m_status_depth_commit_reg = s_fifo_count;
    assign m_status_overflow_reg = (s_fifo_count == DEPTH);
    assign m_status_bad_frame_reg = 0;
    assign m_status_good_frame_reg = 1;

    // Output signals
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
