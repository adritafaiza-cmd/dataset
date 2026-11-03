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
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_tuser [0:DEPTH-1];
    reg [1:0] head, tail;
    reg [1:0] head_reg, tail_reg;
    reg full, empty;
    reg [1:0] cnt, cnt_reg;
    reg [1:0] cnt_commit;
    reg pause_s, pause_m;
    reg pause_ack_s, pause_ack_m;
    reg [USER_WIDTH-1:0] user_bad_frame;

    // Clock domain crossing for pause signals
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            pause_ack_s <= 0;
        end else begin
            pause_ack_s <= s_pause_req;
        end
    end
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            pause_ack_m <= 0;
        end else begin
            pause_ack_m <= m_pause_req;
        end
    end

    // Clock domain crossing for status signals
    assign s_status_depth = cnt_reg;
    assign s_status_depth_commit = cnt_commit;
    assign s_status_overflow = full;
    assign s_status_bad_frame = user_bad_frame;
    assign s_status_good_frame = ~user_bad_frame;
    assign m_status_depth = cnt_reg;
    assign m_status_depth_commit = cnt_commit;
    assign m_status_overflow = full;
    assign m_status_bad_frame = user_bad_frame;
    assign m_status_good_frame = ~user_bad_frame;

    // Clock domain crossing for FIFO data
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            head_reg <= 0;
            tail_reg <= 0;
            cnt_reg <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            head_reg <= head;
            tail_reg <= tail;
            cnt_reg <= cnt;
            full <= full;
            empty <= empty;
        end
    end

    // Clock domain crossing for AXI data
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_axis_tready <= 0;
        end else begin
            s_axis_tready <= s_axis_tready;
        end
    end

    // FIFO logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            head <= 0;
            tail <= 0;
            cnt <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (!full && s_axis_tvalid && s_axis_tready && !pause_s) begin
                mem[head] <= s_axis_tdata;
                mem_keep[head] <= s_axis_tkeep;
                mem_tid[head] <= s_axis_tid;
                mem_tdest[head] <= s_axis_tdest;
                mem_tuser[head] <= s_axis_tuser;
                head <= (head + 1) % DEPTH;
                cnt <= cnt + 1;
                full <= cnt == DEPTH;
                empty <= 0;
            end else if (!empty && m_axis_tready && !pause_m) begin
                m_axis_tdata <= mem[tail];
                m_axis_tkeep <= mem_keep[tail];
                m_axis_tlast <= s_axis_tlast;
                m_axis_tid <= mem_tid[tail];
                m_axis_tdest <= mem_tdest[tail];
                m_axis_tuser <= mem_tuser[tail];
                tail <= (tail + 1) % DEPTH;
                cnt <= cnt - 1;
                full <= 0;
                empty <= cnt == 0;
            end
        end
    end

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            pause_s <= 0;
        end else begin
            if (s_pause_req && !pause_s) begin
                pause_s <= 1;
            end else if (s_axis_tready && !pause_s) begin
                pause_s <= 0;
            end
        end
    end
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            pause_m <= 0;
        end else begin
            if (m_pause_req && !pause_m) begin
                pause_m <= 1;
            end else if (m_axis_tready && !pause_m) begin
                pause_m <= 0;
            end
        end
    end

endmodule
