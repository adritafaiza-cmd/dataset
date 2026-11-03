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

    wire wr_en;
    wire rd_en;
    wire [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH - 1:0] din;
    wire [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH - 1:0] dout;
    wire status_full;
    wire status_empty;
    wire frame_start;
    wire frame_end;
    wire bad_frame;
    wire pause_active;

    assign din = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
    assign {m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser} = dout;

    assign wr_en = s_axis_tvalid & s_axis_tready;
    assign rd_en = m_axis_tready & m_axis_tvalid;

    assign m_axis_tvalid = ~status_empty;
    assign s_axis_tready = ~status_full & ~pause_active;

    assign status_overflow = status_full;
    assign status_depth_commit = status_depth;

    fifo #(
        .WIDTH (DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH),
        .DEPTH (DEPTH)
    ) data_fifo (
        .clk (clk),
        .rst (rst),
        .wr_en (wr_en),
        .din (din),
        .rd_en (rd_en),
        .dout (dout),
        .full (status_full),
        .empty (status_empty),
        .data_count (status_depth)
    );

    frame_detector frame_det (
        .clk (clk),
        .rst (rst),
        .tvalid (s_axis_tvalid),
        .tlast (s_axis_tlast),
        .tuser (s_axis_tuser),
        .frame_start (frame_start),
        .frame_end (frame_end),
        .bad_frame (bad_frame)
    );

    pause_handler pause_hnd (
        .clk (clk),
        .rst (rst),
        .pause_req (pause_req),
        .pause_ack (pause_ack),
        .pause_active (pause_active)
    );

    assign status_bad_frame = bad_frame;
    assign status_good_frame = frame_end;

endmodule

module fifo #
(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire [WIDTH-1:0]       din,
    input  wire                   rd_en,
    output wire [WIDTH-1:0]       dout,
    output wire                   full,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] data_count
);

    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    assign dout = mem[rd_ptr];
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign data_count = count;

endmodule

module frame_detector (
    input  wire clk,
    input  wire rst,
    input  wire tvalid,
    input  wire tlast,
    input  wire [USER_WIDTH-1:0] tuser,
    output reg frame_start,
    output reg frame_end,
    output reg bad_frame
);

    reg in_frame;
    reg [USER_WIDTH-1:0] frame_user;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 0;
            frame_user <= 0;
            frame_start <= 0;
            frame_end <= 0;
            bad_frame <= 0;
        end else begin
            frame_start <= 0;
            frame_end <= 0;
            bad_frame <= 0;

            if (tvalid) begin
                if (!in_frame) begin
                    in_frame <= 1;
                    frame_user <= tuser;
                    frame_start <= 1;
                end

                if (tlast) begin
                    in_frame <= 0;
                    frame_end <= 1;
                    bad_frame <= (frame_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end
            end
        end
    end

endmodule

module pause_handler (
    input  wire clk,
    input  wire rst,
    input  wire pause_req,
    output reg pause_ack,
    output reg pause_active
);

    reg pause_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_state <= 0;
            pause_ack <= 0;
            pause_active <= 0;
        end else begin
            if (pause_req && !pause_state) begin
                pause_state <= 1;
                pause_ack <= 1;
                pause_active <= 1;
            end else if (!pause_req && pause_state) begin
                pause_state <= 0;
                pause_ack <= 0;
                pause_active <= 0;
            end
        end
    end

endmodule
