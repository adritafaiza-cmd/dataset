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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
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

// FIFO signals
reg [S_DATA_WIDTH-1:0] fifo_data;
reg [S_KEEP_WIDTH-1:0] fifo_keep;
reg fifo_valid;
reg fifo_last;
reg [ID_WIDTH-1:0] fifo_id;
reg [DEST_WIDTH-1:0] fifo_dest;
reg [USER_WIDTH-1:0] fifo_user;
reg fifo_ready;
reg fifo_empty;
reg fifo_full;
reg [$clog2(DEPTH):0] fifo_depth;
reg [$clog2(DEPTH):0] fifo_depth_commit;

// Width adapter signals
reg [M_DATA_WIDTH-1:0] adapter_data;
reg [M_KEEP_WIDTH-1:0] adapter_keep;
reg adapter_valid;
reg adapter_last;
reg [ID_WIDTH-1:0] adapter_id;
reg [DEST_WIDTH-1:0] adapter_dest;
reg [USER_WIDTH-1:0] adapter_user;
reg adapter_ready;
reg adapter_empty;
reg adapter_full;

// Status signals
reg s_status_overflow_reg;
reg s_status_bad_frame_reg;
reg s_status_good_frame_reg;
reg m_status_overflow_reg;
reg m_status_bad_frame_reg;
reg m_status_good_frame_reg;

// Pause signals
reg s_pause_ack_reg;
reg m_pause_ack_reg;

// FIFO logic
always @(posedge s_clk) begin
    if (s_rst) begin
        fifo_valid <= 1'b0;
        fifo_ready <= 1'b1;
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
        fifo_depth <= 0;
        fifo_depth_commit <= 0;
    end else begin
        if (s_axis_tvalid && fifo_ready) begin
            fifo_data <= s_axis_tdata;
            fifo_keep <= s_axis_tkeep;
            fifo_valid <= 1'b1;
            fifo_last <= s_axis_tlast;
            fifo_id <= s_axis_tid;
            fifo_dest <= s_axis_tdest;
            fifo_user <= s_axis_tuser;
            fifo_ready <= 1'b0;
            fifo_empty <= 1'b0;
            fifo_depth <= fifo_depth + 1;
            fifo_depth_commit <= fifo_depth_commit + 1;
        end else if (fifo_valid && fifo_ready) begin
            fifo_valid <= 1'b0;
            fifo_ready <= 1'b1;
            fifo_empty <= 1'b1;
            fifo_depth <= fifo_depth - 1;
            fifo_depth_commit <= fifo_depth_commit - 1;
        end
    end
end

// Width adapter logic
always @(posedge m_clk) begin
    if (m_rst) begin
        adapter_valid <= 1'b0;
        adapter_ready <= 1'b1;
        adapter_empty <= 1'b1;
        adapter_full <= 1'b0;
    end else begin
        if (fifo_valid && adapter_ready) begin
            adapter_data <= fifo_data;
            adapter_keep <= fifo_keep;
            adapter_valid <= 1'b1;
            adapter_last <= fifo_last;
            adapter_id <= fifo_id;
            adapter_dest <= fifo_dest;
            adapter_user <= fifo_user;
            adapter_ready <= 1'b0;
            adapter_empty <= 1'b0;
        end else if (adapter_valid && adapter_ready) begin
            adapter_valid <= 1'b0;
            adapter_ready <= 1'b1;
            adapter_empty <= 1'b1;
        end
    end
end

// Output logic
always @(posedge m_clk) begin
    if (m_rst) begin
        m_axis_tdata <= {M_DATA_WIDTH{1'b0}};
        m_axis_tkeep <= {M_KEEP_WIDTH{1'b0}};
        m_axis_tvalid <= 1'b0;
        m_axis_tlast <= 1'b0;
        m_axis_tid <= {ID_WIDTH{1'b0}};
        m_axis_tdest <= {DEST_WIDTH{1'b0}};
        m_axis_tuser <= {USER_WIDTH{1'b0}};
    end else begin
        if (adapter_valid && m_axis_tready) begin
            m_axis_tdata <= adapter_data;
            m_axis_tkeep <= adapter_keep;
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= adapter_last;
            m_axis_tid <= adapter_id;
            m_axis_tdest <= adapter_dest;
            m_axis_tuser <= adapter_user;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end
end

// Status logic
always @(posedge s_clk) begin
    if (s_rst) begin
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
    end else begin
        if (fifo_full && s_axis_tvalid) begin
            s_status_overflow_reg <= 1'b1;
        end else begin
            s_status_overflow_reg <= 1'b0;
        end
        if (fifo_valid && fifo_last) begin
            s_status_good_frame_reg <= 1'b1;
        end else begin
            s_status_good_frame_reg <= 1'b0;
        end
        if (fifo_valid &&!fifo_last) begin
            s_status_bad_frame_reg <= 1'b1;
        end else begin
            s_status_bad_frame_reg <= 1'b0;
        end
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_status_overflow_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
    end else begin
        if (adapter_full && adapter_valid) begin
            m_status_overflow_reg <= 1'b1;
        end else begin
            m_status_overflow_reg <= 1'b0;
        end
        if (adapter_valid && adapter_last) begin
            m_status_good_frame_reg <= 1'b1;
        end else begin
            m_status_good_frame_reg <= 1'b0;
        end
        if (adapter_valid &&!adapter_last) begin
            m_status_bad_frame_reg <= 1'b1;
        end else begin
            m_status_bad_frame_reg <= 1'b0;
        end
    end
end

// Pause logic
always @(posedge s_clk) begin
    if (s_rst) begin
        s_pause_ack_reg <= 1'b0;
    end else begin
        if (s_pause_req) begin
            s_pause_ack_reg <= 1'b1;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_pause_ack_reg <= 1'b0;
    end else begin
        if (m_pause_req) begin
            m_pause_ack_reg <= 1'b1;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end
end

// Assign outputs
assign s_axis_tready = fifo_ready;
assign m_axis_tready = adapter_ready;
assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
assign s_status_depth = fifo_depth;
assign s_status_depth_commit = fifo_depth_commit;
assign s_status_overflow = s_status_overflow_reg;
assign s_status_bad_frame = s_status_bad_frame_reg;
assign s_status_good_frame = s_status_good_frame_reg;
assign m_status_depth = adapter_depth;
assign m_status_depth_commit = adapter_depth_commit;
assign m_status_overflow = m_status_overflow_reg;
assign m_status_bad_frame = m_status_bad_frame_reg;
assign m_status_good_frame = m_status_good_frame_reg;

// Width adapter depth
reg [$clog2(DEPTH):0] adapter_depth;
reg [$clog2(DEPTH):0] adapter_depth_commit;

always @(posedge m_clk) begin
    if (m_rst) begin
        adapter_depth <= 0;
        adapter_depth_commit <= 0;
    end else begin
        if (adapter_valid && adapter_ready) begin
            adapter_depth <= adapter_depth + 1;
            adapter_depth_commit <= adapter_depth_commit + 1;
        end else if (adapter_valid &&!adapter_ready) begin
            adapter_depth <= adapter_depth - 1;
            adapter_depth_commit <= adapter_depth_commit - 1;
        end
    end
end

endmodule
