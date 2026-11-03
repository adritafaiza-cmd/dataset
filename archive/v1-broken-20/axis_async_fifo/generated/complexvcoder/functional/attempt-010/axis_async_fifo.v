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

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [LAST_ENABLE:0] last_mem [0:DEPTH-1];
    reg [ID_ENABLE:0] id_mem [0:DEPTH-1];
    reg [DEST_ENABLE:0] dest_mem [0:DEPTH-1];
    reg [USER_ENABLE:0] user_mem [0:DEPTH-1];
    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;
    reg [1:0] wr_ptr_next;
    reg [1:0] rd_ptr_next;
    reg full;
    reg empty;
    reg [1:0] count;
    reg [1:0] count_next;
    reg [USER_WIDTH-1:0] user_bad_frame;

    // Clock domain crossing for write pointers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 2'b00;
        end else begin
            wr_ptr <= wr_ptr_next;
        end
    end

    // Clock domain crossing for read pointers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 2'b00;
        end else begin
            rd_ptr <= rd_ptr_next;
        end
    end

    // Write pointer logic
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready && !full) begin
            mem[wr_ptr] <= s_axis_tdata;
            keep_mem[wr_ptr] <= s_axis_tkeep;
            last_mem[wr_ptr] <= s_axis_tlast;
            id_mem[wr_ptr] <= s_axis_tid;
            dest_mem[wr_ptr] <= s_axis_tdest;
            user_mem[wr_ptr] <= s_axis_tuser;
            wr_ptr_next <= wr_ptr + 2'b01;
            if (wr_ptr_next == DEPTH) begin
                wr_ptr_next <= 2'b00;
            end
        end
    end

    // Read pointer logic
    always @(posedge m_clk) begin
        if (m_axis_tready && !empty) begin
            rd_ptr_next <= rd_ptr + 2'b01;
            if (rd_ptr_next == DEPTH) begin
                rd_ptr_next <= 2'b00;
            end
        end
    end

    // Full and empty flags
    always @(*) begin
        full = (wr_ptr_next == rd_ptr);
        empty = (wr_ptr == rd_ptr);
    end

    // Count of elements in FIFO
    always @(posedge s_clk or posedge m_clk) begin
        if (s_rst || m_rst) begin
            count <= 2'b00;
        end else if (s_axis_tvalid && s_axis_tready && !full) begin
            count_next <= count + 2'b01;
        end else if (m_axis_tready && !empty) begin
            count_next <= count - 2'b01;
        end else begin
            count_next <= count;
        end
    end

    // Status signals
    assign s_status_depth = count;
    assign s_status_depth_commit = count;
    assign s_status_overflow = full;
    assign s_status_bad_frame = user_bad_frame;
    assign s_status_good_frame = ~user_bad_frame;

    assign m_status_depth = count;
    assign m_status_depth_commit = count;
    assign m_status_overflow = full;
    assign m_status_bad_frame = user_bad_frame;
    assign m_status_good_frame = ~user_bad_frame;

    // Handshake signals
    assign s_axis_tready = !full || (DROP_OVERSIZE_FRAME && full);
    assign m_axis_tvalid = !empty;

    // Pause signals
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

endmodule
