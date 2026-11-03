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

// CDC-safe asynchronous FIFO
reg [S_DATA_WIDTH-1:0] fifo_data [DEPTH-1:0];
reg [S_KEEP_WIDTH-1:0] fifo_keep [DEPTH-1:0];
reg [ID_WIDTH-1:0] fifo_id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] fifo_dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] fifo_user [DEPTH-1:0];
reg [DEPTH-1:0] fifo_valid;
reg [DEPTH-1:0] fifo_last;
reg [$clog2(DEPTH):0] fifo_depth;
reg [$clog2(DEPTH):0] fifo_depth_commit;
reg s_fifo_empty;
reg s_fifo_full;
reg m_fifo_empty;
reg m_fifo_full;

// Gray-coded pointers for CDC safety
reg [$clog2(DEPTH):0] s_ptr_gray;
reg [$clog2(DEPTH):0] m_ptr_gray;
reg [$clog2(DEPTH):0] s_ptr_bin;
reg [$clog2(DEPTH):0] m_ptr_bin;

// Width adapter
reg [M_DATA_WIDTH-1:0] adapter_data;
reg [M_KEEP_WIDTH-1:0] adapter_keep;
reg [ID_WIDTH-1:0] adapter_id;
reg [DEST_WIDTH-1:0] adapter_dest;
reg [USER_WIDTH-1:0] adapter_user;
reg adapter_last;
reg adapter_valid;

// Status signals
reg s_overflow;
reg s_bad_frame;
reg s_good_frame;
reg m_overflow;
reg m_bad_frame;
reg m_good_frame;

// Pause signals
reg s_pause;
reg m_pause;

// Clock-domain crossing logic
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_ptr_gray <= 0;
        s_ptr_bin <= 0;
    end else begin
        if (s_axis_tvalid && !s_fifo_full) begin
            s_ptr_gray <= s_ptr_gray + 1;
            s_ptr_bin <= s_ptr_bin + 1;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_ptr_gray <= 0;
        m_ptr_bin <= 0;
    end else begin
        if (m_axis_tready && !m_fifo_empty) begin
            m_ptr_gray <= m_ptr_gray + 1;
            m_ptr_bin <= m_ptr_bin + 1;
        end
    end
end

// FIFO logic
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        fifo_data <= {DEPTH{S_DATA_WIDTH{1'b0}}};
        fifo_keep <= {DEPTH{S_KEEP_WIDTH{1'b0}}};
        fifo_id <= {DEPTH{ID_WIDTH{1'b0}}};
        fifo_dest <= {DEPTH{DEST_WIDTH{1'b0}}};
        fifo_user <= {DEPTH{USER_WIDTH{1'b0}}};
        fifo_valid <= {DEPTH{1'b0}};
        fifo_last <= {DEPTH{1'b0}};
        fifo_depth <= 0;
        fifo_depth_commit <= 0;
        s_fifo_empty <= 1;
        s_fifo_full <= 0;
    end else begin
        if (s_axis_tvalid && !s_fifo_full) begin
            fifo_data[s_ptr_bin] <= s_axis_tdata;
            fifo_keep[s_ptr_bin] <= s_axis_tkeep;
            fifo_id[s_ptr_bin] <= s_axis_tid;
            fifo_dest[s_ptr_bin] <= s_axis_tdest;
            fifo_user[s_ptr_bin] <= s_axis_tuser;
            fifo_valid[s_ptr_bin] <= 1;
            fifo_last[s_ptr_bin] <= s_axis_tlast;
            fifo_depth <= fifo_depth + 1;
            fifo_depth_commit <= fifo_depth_commit + 1;
            s_fifo_empty <= 0;
            if (fifo_depth == DEPTH - 1) begin
                s_fifo_full <= 1;
            end
        end
        if (m_axis_tready && !m_fifo_empty) begin
            fifo_valid[m_ptr_bin] <= 0;
            fifo_depth <= fifo_depth - 1;
            fifo_depth_commit <= fifo_depth_commit - 1;
            m_fifo_empty <= 0;
            if (fifo_depth == 0) begin
                s_fifo_empty <= 1;
            end
        end
    end
end

// Width adapter logic
always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        adapter_data <= {M_DATA_WIDTH{1'b0}};
        adapter_keep <= {M_KEEP_WIDTH{1'b0}};
        adapter_id <= {ID_WIDTH{1'b0}};
        adapter_dest <= {DEST_WIDTH{1'b0}};
        adapter_user <= {USER_WIDTH{1'b0}};
        adapter_last <= 0;
        adapter_valid <= 0;
    end else begin
        if (!m_fifo_empty) begin
            adapter_data <= fifo_data[m_ptr_bin];
            adapter_keep <= fifo_keep[m_ptr_bin];
            adapter_id <= fifo_id[m_ptr_bin];
            adapter_dest <= fifo_dest[m_ptr_bin];
            adapter_user <= fifo_user[m_ptr_bin];
            adapter_last <= fifo_last[m_ptr_bin];
            adapter_valid <= 1;
        end
    end
end

// Output logic
assign m_axis_tdata = adapter_data;
assign m_axis_tkeep = adapter_keep;
assign m_axis_tvalid = adapter_valid;
assign m_axis_tlast = adapter_last;
assign m_axis_tid = adapter_id;
assign m_axis_tdest = adapter_dest;
assign m_axis_tuser = adapter_user;

// Input logic
assign s_axis_tready = !s_fifo_full;

// Status logic
assign s_status_depth = fifo_depth;
assign s_status_depth_commit = fifo_depth_commit;
assign s_status_overflow = s_overflow;
assign s_status_bad_frame = s_bad_frame;
assign s_status_good_frame = s_good_frame;
assign m_status_depth = fifo_depth;
assign m_status_depth_commit = fifo_depth_commit;
assign m_status_overflow = m_overflow;
assign m_status_bad_frame = m_bad_frame;
assign m_status_good_frame = m_good_frame;

// Pause logic
assign s_pause_ack = s_pause;
assign m_pause_ack = m_pause;

endmodule
