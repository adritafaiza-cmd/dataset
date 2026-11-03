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

    /*
     * CDC modules
     */
    reg s_axis_tvalid_sync1, s_axis_tvalid_sync2;
    reg m_axis_tready_sync1, m_axis_tready_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_axis_tvalid_sync1 <= 1'b0;
        else
            s_axis_tvalid_sync1 <= s_axis_tvalid;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_axis_tready_sync1 <= 1'b0;
        else
            m_axis_tready_sync1 <= m_axis_tready;
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_axis_tvalid_sync2 <= 1'b0;
        else
            s_axis_tvalid_sync2 <= s_axis_tvalid_sync1;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_axis_tready_sync2 <= 1'b0;
        else
            m_axis_tready_sync2 <= m_axis_tready_sync1;
    end

    /*
     * FIFO core
     */
    wire [DATA_WIDTH-1:0]  fifo_dout;
    wire [KEEP_WIDTH-1:0]  fifo_keep_out;
    wire                   fifo_valid_out;
    wire                   fifo_ready_in;
    wire                   fifo_last_out;
    wire [ID_WIDTH-1:0]    fifo_id_out;
    wire [DEST_WIDTH-1:0]  fifo_dest_out;
    wire [USER_WIDTH-1:0]  fifo_user_out;

    wire [$clog2(DEPTH):0] fifo_depth_out;
    wire [$clog2(DEPTH):0] fifo_depth_commit_out;
    wire                   fifo_overflow_out;
    wire                   fifo_bad_frame_out;
    wire                   fifo_good_frame_out;

    fifo_sync #(
        .WIDTH(DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_sync_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axis_tdata, s_axis_tkeep, LAST_ENABLE ? s_axis_tlast : 1'b0, ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}, DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}, USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}}),
        .s_valid(s_axis_tvalid_sync2),
        .s_ready(fifo_ready_in),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(fifo_dout),
        .m_valid(fifo_valid_out),
        .m_ready(m_axis_tready_sync2),
        .depth(fifo_depth_out),
        .depth_commit(fifo_depth_commit_out),
        .overflow(fifo_overflow_out)
    );

    assign s_axis_tready = fifo_ready_in;

    /*
     * Output assignments
     */
    assign m_axis_tdata  = fifo_dout[DATA_WIDTH-1:0];
    assign m_axis_tkeep  = fifo_dout[DATA_WIDTH + KEEP_WIDTH - 1:DATA_WIDTH];
    assign m_axis_tlast  = LAST_ENABLE ? fifo_dout[DATA_WIDTH + KEEP_WIDTH] : 1'b0;
    assign m_axis_tid    = ID_ENABLE ? fifo_dout[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest  = DEST_ENABLE ? fifo_dout[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser  = USER_ENABLE ? fifo_dout[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH + USER_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH] : {USER_WIDTH{1'b0}};
    assign m_axis_tvalid = fifo_valid_out;

    /*
     * Status outputs
     */
    assign s_status_depth        = fifo_depth_out;
    assign s_status_depth_commit = fifo_depth_commit_out;
    assign s_status_overflow     = fifo_overflow_out;
    assign s_status_bad_frame    = 1'b0; // Placeholder for actual bad frame logic
    assign s_status_good_frame   = 1'b0; // Placeholder for actual good frame logic

    assign m_status_depth        = fifo_depth_out;
    assign m_status_depth_commit = fifo_depth_commit_out;
    assign m_status_overflow     = fifo_overflow_out;
    assign m_status_bad_frame    = 1'b0; // Placeholder for actual bad frame logic
    assign m_status_good_frame   = 1'b0; // Placeholder for actual good frame logic

    /*
     * Pause outputs
     */
    assign s_pause_ack = 1'b0; // Placeholder for actual pause logic
    assign m_pause_ack = 1'b0; // Placeholder for actual pause logic

endmodule

module fifo_sync #
(
    parameter WIDTH = 32,
    parameter DEPTH = 1024
)
(
    input  wire               s_clk,
    input  wire               s_rst,
    input  wire [WIDTH-1:0] s_data,
    input  wire               s_valid,
    output wire               s_ready,
    input  wire               m_clk,
    input  wire               m_rst,
    output wire [WIDTH-1:0] m_data,
    output wire               m_valid,
    input  wire               m_ready,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit,
    output wire               overflow
);

    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    wire [$clog2(DEPTH):0] wr_ptr_gray_next, rd_ptr_gray_next;
    wire [$clog2(DEPTH):0] depth_raw, depth_commit_raw;
    wire full, empty;

    assign wr_ptr_gray_next = (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
    assign rd_ptr_gray_next = rd_ptr ^ (rd_ptr >> 1);

    assign depth_raw = wr_ptr - rd_ptr;
    assign depth_commit_raw = wr_ptr_gray_sync2 - rd_ptr_gray;

    assign full = (wr_ptr_gray_next == rd_ptr_gray_sync2);
    assign empty = (wr_ptr_gray == rd_ptr_gray_sync2);

    assign s_ready = ~full;
    assign m_valid = ~empty;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (s_valid && s_ready) begin
            mem[wr_ptr] <= s_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (m_valid && m_ready) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    assign m_data = mem[rd_ptr];
    assign depth = depth_raw;
    assign depth_commit = depth_commit_raw;
    assign overflow = full;

endmodule
