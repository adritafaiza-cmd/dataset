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

    // FIFO signals
    reg [S_DATA_WIDTH-1:0] fifo_data;
    reg [S_KEEP_WIDTH-1:0] fifo_keep;
    reg [ID_WIDTH-1:0] fifo_id;
    reg [DEST_WIDTH-1:0] fifo_dest;
    reg [USER_WIDTH-1:0] fifo_user;
    reg fifo_last;
    reg fifo_valid;
    wire fifo_ready;

    // FIFO control signals
    reg [31:0] fifo_count;
    reg [31:0] fifo_commit_count;
    reg fifo_overflow;
    reg fifo_bad_frame;
    reg fifo_good_frame;

    // Clock domain crossing signals
    reg [31:0] s_count;
    reg [31:0] m_count;
    reg s_overflow;
    reg m_overflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;

    // Pause signals
    reg s_pause;
    reg m_pause;

    // FIFO implementation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_data <= {S_DATA_WIDTH{1'b0}};
            fifo_keep <= {S_KEEP_WIDTH{1'b0}};
            fifo_id <= {ID_WIDTH{1'b0}};
            fifo_dest <= {DEST_WIDTH{1'b0}};
            fifo_user <= {USER_WIDTH{1'b0}};
            fifo_last <= 1'b0;
            fifo_valid <= 1'b0;
            fifo_count <= 32'd0;
            fifo_commit_count <= 32'd0;
            fifo_overflow <= 1'b0;
            fifo_bad_frame <= 1'b0;
            fifo_good_frame <= 1'b0;
            s_count <= 32'd0;
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
            s_pause <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            fifo_data <= s_axis_tdata;
            fifo_keep <= s_axis_tkeep;
            fifo_id <= s_axis_tid;
            fifo_dest <= s_axis_tdest;
            fifo_user <= s_axis_tuser;
            fifo_last <= s_axis_tlast;
            fifo_valid <= 1'b1;
            if (fifo_last) begin
                if (fifo_count == DEPTH - 1) begin
                    fifo_overflow <= 1'b1;
                end else begin
                    fifo_count <= fifo_count + 1;
                end
                if (s_axis_tuser == USER_BAD_FRAME_VALUE) begin
                    fifo_bad_frame <= 1'b1;
                end else begin
                    fifo_good_frame <= 1'b1;
                end
            end
        end else if (fifo_valid && fifo_ready) begin
            fifo_valid <= 1'b0;
            if (fifo_last) begin
                fifo_commit_count <= fifo_commit_count + 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tid <= {ID_WIDTH{1'b0}};
            m_axis_tdest <= {DEST_WIDTH{1'b0}};
            m_axis_tuser <= {USER_WIDTH{1'b0}};
            m_count <= 32'd0;
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
            m_pause <= 1'b0;
        end else if (fifo_valid && fifo_ready) begin
            m_axis_tdata <= fifo_data;
            m_axis_tkeep <= fifo_keep;
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= fifo_last;
            m_axis_tid <= fifo_id;
            m_axis_tdest <= fifo_dest;
            m_axis_tuser <= fifo_user;
            if (fifo_last) begin
                if (m_count == DEPTH - 1) begin
                    m_overflow <= 1'b1;
                end else begin
                    m_count <= m_count + 1;
                end
                if (fifo_user == USER_BAD_FRAME_VALUE) begin
                    m_bad_frame <= 1'b1;
                end else begin
                    m_good_frame <= 1'b1;
                end
            end
        end else if (m_axis_tready && m_axis_tvalid) begin
            m_axis_tvalid <= 1'b0;
        end
    end

    // Clock domain crossing
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_count <= 32'd0;
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            s_count <= fifo_count;
            s_overflow <= fifo_overflow;
            s_bad_frame <= fifo_bad_frame;
            s_good_frame <= fifo_good_frame;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_count <= 32'd0;
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            m_count <= fifo_commit_count;
            m_overflow <= fifo_overflow;
            m_bad_frame <= fifo_bad_frame;
            m_good_frame <= fifo_good_frame;
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause <= 1'b0;
        end else if (s_pause_req) begin
            s_pause <= 1'b1;
        end else if (fifo_valid && fifo_ready) begin
            s_pause <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause <= 1'b0;
        end else if (m_pause_req) begin
            m_pause <= 1'b1;
        end else if (m_axis_tready && m_axis_tvalid) begin
            m_pause <= 1'b0;
        end
    end

    // Assign outputs
    assign s_axis_tready = ~s_pause && ~fifo_overflow;
    assign m_axis_tready = ~m_pause && ~m_overflow;
    assign s_pause_ack = s_pause;
    assign m_pause_ack = m_pause;
    assign s_status_depth = s_count;
    assign s_status_depth_commit = fifo_commit_count;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_depth = m_count;
    assign m_status_depth_commit = fifo_commit_count;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // FIFO ready logic
    assign fifo_ready = ~m_pause && ~m_overflow;

endmodule
