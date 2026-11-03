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
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg [1:0] head;
    reg [1:0] tail;
    reg [1:0] count;
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg [1:0] s_pause_req_reg;
    reg [1:0] m_pause_req_reg;

    // Clock domain crossing for s_clk to m_clk
    wire s_axis_tready_cross;
    wire m_axis_tvalid_cross;

    // Clock domain crossing for s_clk
    always @(posedge s_clk) begin
        if (s_rst) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            s_axis_tready_reg <= 1;
            m_axis_tvalid_reg <= 0;
            s_pause_req_reg <= 0;
            m_pause_req_reg <= 0;
        end else begin
            if (s_pause_req && !s_pause_ack) begin
                s_pause_req_reg <= s_pause_req;
            end
            if (m_pause_req && !m_pause_ack) begin
                m_pause_req_reg <= m_pause_req;
            end
            if (s_axis_tvalid && s_axis_tready) begin
                mem[head] <= s_axis_tdata;
                keep_mem[head] <= s_axis_tkeep;
                id_mem[head] <= s_axis_tid;
                dest_mem[head] <= s_axis_tdest;
                user_mem[head] <= s_axis_tuser;
                head <= (head + 1) % DEPTH;
                count <= count + 1;
                s_axis_tready_reg <= (count == DEPTH - 1) ? 0 : 1;
                m_axis_tvalid_reg <= 1;
            end
            if (m_axis_tready && m_axis_tvalid) begin
                tail <= (tail + 1) % DEPTH;
                count <= count - 1;
                m_axis_tvalid_reg <= 0;
            end
        end
    end

    // Clock domain crossing for m_clk to s_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            s_axis_tready <= 1;
        end else begin
            s_axis_tready <= s_axis_tready_reg;
        end
    end

    // Clock domain crossing for s_clk to m_clk
    assign m_axis_tdata = mem[tail];
    assign m_axis_tkeep = keep_mem[tail];
    assign m_axis_tlast = (count == 1) ? 1 : 0;
    assign m_axis_tid = id_mem[tail];
    assign m_axis_tdest = dest_mem[tail];
    assign m_axis_tuser = user_mem[tail];

    // Clock domain crossing for m_clk to s_clk
    assign s_pause_ack = (s_pause_req_reg == m_pause_req_reg) ? 1 : 0;

    // Clock domain crossing for s_clk to m_clk
    assign m_pause_ack = (s_pause_req_reg == m_pause_req_reg) ? 1 : 0;

    // Status signals
    assign s_status_depth = count;
    assign s_status_depth_commit = count;
    assign s_status_overflow = (count == DEPTH) ? 1 : 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 1;
    assign m_status_depth = count;
    assign m_status_depth_commit = count;
    assign m_status_overflow = (count == DEPTH) ? 1 : 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 1;

endmodule
