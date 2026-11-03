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
    reg [DATA_WIDTH-1:0] s_fifo_data;
    reg [KEEP_WIDTH-1:0] s_fifo_keep;
    reg s_fifo_valid;
    reg s_fifo_last;
    reg [ID_WIDTH-1:0] s_fifo_id;
    reg [DEST_WIDTH-1:0] s_fifo_dest;
    reg [USER_WIDTH-1:0] s_fifo_user;
    reg s_fifo_full;
    reg s_fifo_empty;

    reg [DATA_WIDTH-1:0] m_fifo_data;
    reg [KEEP_WIDTH-1:0] m_fifo_keep;
    reg m_fifo_valid;
    reg m_fifo_last;
    reg [ID_WIDTH-1:0] m_fifo_id;
    reg [DEST_WIDTH-1:0] m_fifo_dest;
    reg [USER_WIDTH-1:0] m_fifo_user;
    reg m_fifo_full;
    reg m_fifo_empty;

    reg [7:0] s_count;
    reg [7:0] m_count;

    // FIFOs
    fifo #(.WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) s_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din(s_axis_tdata),
        .wr_en(s_axis_tvalid),
        .rd_en(s_axis_tready),
        .dout(s_fifo_data),
        .full(s_fifo_full),
        .empty(s_fifo_empty)
    );

    fifo #(.WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) m_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .din(m_axis_tdata),
        .wr_en(m_axis_tvalid),
        .rd_en(m_axis_tready),
        .dout(m_fifo_data),
        .full(m_fifo_full),
        .empty(m_fifo_empty)
    );

    // Status outputs
    assign s_status_depth = s_count;
    assign s_status_depth_commit = s_count;
    assign s_status_overflow = s_fifo_full;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b1;

    assign m_status_depth = m_count;
    assign m_status_depth_commit = m_count;
    assign m_status_overflow = m_fifo_full;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b1;

    // Pause handling
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // AXI input ready
    assign s_axis_tready = ~s_fifo_full;

    // AXI output valid
    assign m_axis_tvalid = ~m_fifo_empty;

    // AXI output data
    assign m_axis_tdata = m_fifo_data;
    assign m_axis_tkeep = m_fifo_keep;
    assign m_axis_tlast = m_fifo_last;
    assign m_axis_tid = m_fifo_id;
    assign m_axis_tdest = m_fifo_dest;
    assign m_axis_tuser = m_fifo_user;

    // AXI input data
    assign s_fifo_data = s_axis_tdata;
    assign s_fifo_keep = s_axis_tkeep;
    assign s_fifo_valid = s_axis_tvalid;
    assign s_fifo_last = s_axis_tlast;
    assign s_fifo_id = s_axis_tid;
    assign s_fifo_dest = s_axis_tdest;
    assign s_fifo_user = s_axis_tuser;

    // Counters
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_count <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_count <= s_count + 1;
            end else if (m_axis_tready && m_axis_tvalid) begin
                s_count <= s_count - 1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_count <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_count <= m_count + 1;
            end else if (s_axis_tready && s_axis_tvalid) begin
                m_count <= m_count - 1;
            end
        end
    end

endmodule
