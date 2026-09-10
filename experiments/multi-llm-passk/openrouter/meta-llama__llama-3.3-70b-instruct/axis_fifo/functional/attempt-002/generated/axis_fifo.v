module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
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
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    reg [$clog2(DEPTH):0] depth;
    reg [$clog2(DEPTH):0] depth_commit;
    reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] keep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] user [DEPTH-1:0];
    reg [DEPTH-1:0] last;
    reg [DEPTH-1:0] valid;
    reg [DEPTH-1:0] pause;
    reg [DEPTH-1:0] bad_frame;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            depth <= 0;
            depth_commit <= 0;
            for (i = 0; i < DEPTH; i++) begin
                fifo[i] <= 0;
                keep[i] <= 0;
                id[i] <= 0;
                dest[i] <= 0;
                user[i] <= 0;
                last[i] <= 0;
                valid[i] <= 0;
                pause[i] <= 0;
                bad_frame[i] <= 0;
            end
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (depth < DEPTH) begin
                    fifo[depth] <= s_axis_tdata;
                    keep[depth] <= s_axis_tkeep;
                    id[depth] <= s_axis_tid;
                    dest[depth] <= s_axis_tdest;
                    user[depth] <= s_axis_tuser;
                    last[depth] <= s_axis_tlast;
                    valid[depth] <= 1;
                    pause[depth] <= pause_req;
                    bad_frame[depth] <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                    depth <= depth + 1;
                end else if (DROP_WHEN_FULL) begin
                    if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        s_axis_tready <= 0;
                    end else if (MARK_WHEN_FULL) begin
                        fifo[0] <= s_axis_tdata;
                        keep[0] <= s_axis_tkeep;
                        id[0] <= s_axis_tid;
                        dest[0] <= s_axis_tdest;
                        user[0] <= s_axis_tuser;
                        last[0] <= s_axis_tlast;
                        pause[0] <= pause_req;
                        bad_frame[0] <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                    end
                end
            end

            if (m_axis_tready && m_axis_tvalid) begin
                if (depth > 0) begin
                    depth_commit <= depth_commit - 1;
                    for (i = 0; i < DEPTH - 1; i++) begin
                        fifo[i] <= fifo[i + 1];
                        keep[i] <= keep[i + 1];
                        id[i] <= id[i + 1];
                        dest[i] <= dest[i + 1];
                        user[i] <= user[i + 1];
                        last[i] <= last[i + 1];
                        valid[i] <= valid[i + 1];
                        pause[i] <= pause[i + 1];
                        bad_frame[i] <= bad_frame[i + 1];
                    end
                    fifo[DEPTH - 1] <= 0;
                    keep[DEPTH - 1] <= 0;
                    id[DEPTH - 1] <= 0;
                    dest[DEPTH - 1] <= 0;
                    user[DEPTH - 1] <= 0;
                    last[DEPTH - 1] <= 0;
                    valid[DEPTH - 1] <= 0;
                    pause[DEPTH - 1] <= 0;
                    bad_frame[DEPTH - 1] <= 0;
                    depth <= depth - 1;
                end
            end

            if (pause_req && PAUSE_ENABLE) begin
                for (i = 0; i < DEPTH; i++) begin
                    pause[i] <= 1;
                end
            end
        end
    end

    assign s_axis_tready = (depth < DEPTH) && (!PAUSE_ENABLE || !pause_req);
    assign m_axis_tdata = fifo[0];
    assign m_axis_tkeep = keep[0];
    assign m_axis_tvalid = valid[0];
    assign m_axis_tlast = last[0];
    assign m_axis_tid = id[0];
    assign m_axis_tdest = dest[0];
    assign m_axis_tuser = user[0];
    assign pause_ack = PAUSE_ENABLE && pause_req;
    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = (depth == DEPTH);
    assign status_bad_frame = bad_frame[0];
    assign status_good_frame = !bad_frame[0];

endmodule
