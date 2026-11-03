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

    localparam TOTAL_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH;

    reg wr_en;
    reg rd_en;
    reg [TOTAL_WIDTH-1:0] din;
    wire [TOTAL_WIDTH-1:0] dout;
    wire mem_full;
    wire mem_empty;

    reg frame_start;
    reg frame_end;
    reg frame_err;
    reg [12:0] frame_cnt;
    reg good_frame;
    reg bad_frame;
    reg overflow;
    reg pause_ack_int;

    reg [$clog2(DEPTH):0] depth_cnt;
    reg [$clog2(DEPTH):0] depth_commit;

    fifo_memory #(
        .DATA_WIDTH(TOTAL_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_mem (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .din(din),
        .rd_en(rd_en),
        .dout(dout),
        .full(mem_full),
        .empty(mem_empty)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_en <= 0;
            rd_en <= 0;
            frame_start <= 0;
            frame_end <= 0;
            frame_err <= 0;
            frame_cnt <= 0;
            good_frame <= 0;
            bad_frame <= 0;
            overflow <= 0;
            depth_cnt <= 0;
            depth_commit <= 0;
            pause_ack_int <= 0;
        end else begin
            // Write enable logic
            if (s_axis_tvalid && s_axis_tready) begin
                if (frame_start && frame_cnt == DEPTH) begin
                    if (DROP_OVERSIZE_FRAME) begin
                        wr_en <= 0;
                        frame_err <= 1;
                    end else begin
                        wr_en <= 1;
                        frame_cnt <= frame_cnt + 1;
                    end
                end else begin
                    wr_en <= 1;
                    frame_cnt <= frame_cnt + 1;
                end
            end else begin
                wr_en <= 0;
            end

            // Read enable logic
            if (m_axis_tready && !mem_empty) begin
                rd_en <= 1;
                if (frame_end) begin
                    if (frame_err) begin
                        bad_frame <= 1;
                    end else begin
                        good_frame <= 1;
                    end
                    frame_err <= 0;
                end
            end else begin
                rd_en <= 0;
            end

            // Frame start/end detection
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                frame_end <= 1;
                frame_start <= 0;
            end else if (s_axis_tvalid && s_axis_tready && !frame_start) begin
                frame_start <= 1;
                frame_end <= 0;
            end

            // Frame error handling
            if (frame_start && frame_cnt == DEPTH) begin
                frame_err <= 1;
            end

            // Depth counter
            if (wr_en && !rd_en) begin
                if (depth_cnt == DEPTH) begin
                    overflow <= 1;
                    depth_cnt <= DEPTH;
                end else begin
                    depth_cnt <= depth_cnt + 1;
                end
            end else if (!wr_en && rd_en) begin
                depth_cnt <= depth_cnt - 1;
            end

            // Depth commit
            if (rd_en) begin
                depth_commit <= depth_cnt;
            end

            // Pause control
            if (PAUSE_ENABLE) begin
                if (pause_req && !mem_full) begin
                    pause_ack_int <= 1;
                    rd_en <= 0;
                end else begin
                    pause_ack_int <= 0;
                end
            end
        end
    end

    assign s_axis_tready = !mem_full && !frame_err;
    assign m_axis_tdata = dout[DATA_WIDTH-1:0];
    assign m_axis_tkeep = dout[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH];
    assign m_axis_tid = dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE];
    assign m_axis_tdest = dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH];
    assign m_axis_tuser = dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH];
    assign m_axis_tvalid = !mem_empty && !pause_ack_int;
    assign pause_ack = pause_ack_int;
    assign status_depth = depth_cnt;
    assign status_depth_commit = depth_commit;
    assign status_overflow = overflow;
    assign status_bad_frame = bad_frame;
    assign status_good_frame = good_frame;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bad_frame <= 0;
            good_frame <= 0;
            overflow <= 0;
        end else begin
            if (bad_frame) begin
                bad_frame <= 0;
            end
            if (good_frame) begin
                good_frame <= 0;
            end
            if (overflow) begin
                overflow <= 0;
            end
        end
    end

endmodule

module fifo_memory #
(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024
)
(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH-1:0] depth;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            depth <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                depth <= depth + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                depth <= depth - 1;
            end
        end
    end

    assign dout = mem[rd_ptr];
    assign full = (depth == DEPTH);
    assign empty = (depth == 0);

endmodule
