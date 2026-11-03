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

// Internal signals
reg [DATA_WIDTH-1:0] data_reg;
reg [KEEP_WIDTH-1:0] keep_reg;
reg [ID_WIDTH-1:0] id_reg;
reg [DEST_WIDTH-1:0] dest_reg;
reg [USER_WIDTH-1:0] user_reg;
reg last_reg;
reg valid_reg;
reg ready_reg;
reg [DATA_WIDTH-1:0] m_data_reg;
reg [KEEP_WIDTH-1:0] m_keep_reg;
reg [ID_WIDTH-1:0] m_id_reg;
reg [DEST_WIDTH-1:0] m_dest_reg;
reg [USER_WIDTH-1:0] m_user_reg;
reg m_last_reg;
reg m_valid_reg;
reg m_ready_reg;
reg [$clog2(DEPTH):0] s_depth_reg;
reg [$clog2(DEPTH):0] s_depth_commit_reg;
reg s_overflow_reg;
reg s_bad_frame_reg;
reg s_good_frame_reg;
reg [$clog2(DEPTH):0] m_depth_reg;
reg [$clog2(DEPTH):0] m_depth_commit_reg;
reg m_overflow_reg;
reg m_bad_frame_reg;
reg m_good_frame_reg;
reg s_pause_ack_reg;
reg m_pause_ack_reg;

// CDC for s_axis_tvalid and s_axis_tready
reg s_axis_tvalid_sync;
reg s_axis_tready_sync;
reg [1:0] s_axis_tvalid_sync_reg;
reg [1:0] s_axis_tready_sync_reg;

// CDC for m_axis_tvalid and m_axis_tready
reg m_axis_tvalid_sync;
reg m_axis_tready_sync;
reg [1:0] m_axis_tvalid_sync_reg;
reg [1:0] m_axis_tready_sync_reg;

// FIFO logic
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        data_reg <= 0;
        keep_reg <= 0;
        id_reg <= 0;
        dest_reg <= 0;
        user_reg <= 0;
        last_reg <= 0;
        valid_reg <= 0;
        ready_reg <= 0;
        s_depth_reg <= 0;
        s_depth_commit_reg <= 0;
        s_overflow_reg <= 0;
        s_bad_frame_reg <= 0;
        s_good_frame_reg <= 0;
        s_axis_tvalid_sync_reg <= 0;
        s_axis_tready_sync_reg <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            data_reg <= s_axis_tdata;
            keep_reg <= s_axis_tkeep;
            id_reg <= s_axis_tid;
            dest_reg <= s_axis_tdest;
            user_reg <= s_axis_tuser;
            last_reg <= s_axis_tlast;
            valid_reg <= 1;
            s_depth_reg <= s_depth_reg + 1;
            if (s_axis_tlast) begin
                s_depth_commit_reg <= s_depth_commit_reg + 1;
            end
        end
        if (s_axis_tvalid_sync && s_axis_tready_sync) begin
            ready_reg <= 1;
        end
        if (s_axis_tvalid_sync_reg[1] && !s_axis_tvalid_sync_reg[0]) begin
            s_overflow_reg <= 1;
        end
        if (s_axis_tlast && s_axis_tuser == USER_BAD_FRAME_VALUE) begin
            s_bad_frame_reg <= 1;
        end else if (s_axis_tlast) begin
            s_good_frame_reg <= 1;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_data_reg <= 0;
        m_keep_reg <= 0;
        m_id_reg <= 0;
        m_dest_reg <= 0;
        m_user_reg <= 0;
        m_last_reg <= 0;
        m_valid_reg <= 0;
        m_ready_reg <= 0;
        m_depth_reg <= 0;
        m_depth_commit_reg <= 0;
        m_overflow_reg <= 0;
        m_bad_frame_reg <= 0;
        m_good_frame_reg <= 0;
        m_axis_tvalid_sync_reg <= 0;
        m_axis_tready_sync_reg <= 0;
    end else begin
        if (m_axis_tvalid && m_axis_tready) begin
            m_data_reg <= data_reg;
            m_keep_reg <= keep_reg;
            m_id_reg <= id_reg;
            m_dest_reg <= dest_reg;
            m_user_reg <= user_reg;
            m_last_reg <= last_reg;
            m_valid_reg <= 1;
            m_depth_reg <= m_depth_reg - 1;
            if (m_last_reg) begin
                m_depth_commit_reg <= m_depth_commit_reg - 1;
            end
        end
        if (m_axis_tvalid_sync && m_axis_tready_sync) begin
            m_ready_reg <= 1;
        end
        if (m_axis_tvalid_sync_reg[1] && !m_axis_tvalid_sync_reg[0]) begin
            m_overflow_reg <= 1;
        end
        if (m_last_reg && m_user_reg == USER_BAD_FRAME_VALUE) begin
            m_bad_frame_reg <= 1;
        end else if (m_last_reg) begin
            m_good_frame_reg <= 1;
        end
    end
end

// CDC for s_axis_tvalid and s_axis_tready
always @(posedge s_clk) begin
    s_axis_tvalid_sync_reg[0] <= s_axis_tvalid;
    s_axis_tvalid_sync_reg[1] <= s_axis_tvalid_sync_reg[0];
    s_axis_tvalid_sync <= s_axis_tvalid_sync_reg[1];
    s_axis_tready_sync_reg[0] <= s_axis_tready;
    s_axis_tready_sync_reg[1] <= s_axis_tready_sync_reg[0];
    s_axis_tready_sync <= s_axis_tready_sync_reg[1];
end

// CDC for m_axis_tvalid and m_axis_tready
always @(posedge m_clk) begin
    m_axis_tvalid_sync_reg[0] <= m_axis_tvalid;
    m_axis_tvalid_sync_reg[1] <= m_axis_tvalid_sync_reg[0];
    m_axis_tvalid_sync <= m_axis_tvalid_sync_reg[1];
    m_axis_tready_sync_reg[0] <= m_axis_tready;
    m_axis_tready_sync_reg[1] <= m_axis_tready_sync_reg[0];
    m_axis_tready_sync <= m_axis_tready_sync_reg[1];
end

// Output assignments
assign s_axis_tready = ready_reg;
assign m_axis_tdata = m_data_reg;
assign m_axis_tkeep = m_keep_reg;
assign m_axis_tvalid = m_valid_reg;
assign m_axis_tlast = m_last_reg;
assign m_axis_tid = m_id_reg;
assign m_axis_tdest = m_dest_reg;
assign m_axis_tuser = m_user_reg;
assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
assign s_status_depth = s_depth_reg;
assign s_status_depth_commit = s_depth_commit_reg;
assign s_status_overflow = s_overflow_reg;
assign s_status_bad_frame = s_bad_frame_reg;
assign s_status_good_frame = s_good_frame_reg;
assign m_status_depth = m_depth_reg;
assign m_status_depth_commit = m_depth_commit_reg;
assign m_status_overflow = m_overflow_reg;
assign m_status_bad_frame = m_bad_frame_reg;
assign m_status_good_frame = m_good_frame_reg;

endmodule
