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

    /*
     * Internal signals
     */
    wire                          write_en;
    wire                          read_en;
    wire                          fifo_full;
    wire                          fifo_empty;
    wire [$clog2(DEPTH):0]        fifo_count;
    wire [$clog2(DEPTH):0]        commit_count;
    wire                          frame_error;
    wire                          frame_good;
    wire                          frame_started;
    wire                          frame_ended;
    wire                          frame_valid;
    wire [$clog2(DEPTH):0]        frame_size;
    reg  [DATA_WIDTH-1:0]         frame_data;
    reg  [KEEP_WIDTH-1:0]         frame_keep;
    reg                           frame_last;
    reg  [ID_WIDTH-1:0]           frame_id;
    reg  [DEST_WIDTH-1:0]         frame_dest;
    reg  [USER_WIDTH-1:0]         frame_user;

    /*
     * FIFO instances
     */
    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(DATA_WIDTH)
    ) data_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdata),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tdata),
        .full(fifo_full),
        .empty(fifo_empty),
        .count(fifo_count)
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(KEEP_WIDTH)
    ) keep_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tkeep),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tkeep),
        .full(),
        .empty(),
        .count()
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(1)
    ) valid_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tvalid),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tvalid),
        .full(),
        .empty(),
        .count(commit_count)
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(1)
    ) last_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tlast),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tlast),
        .full(),
        .empty(),
        .count()
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(ID_WIDTH)
    ) id_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tid),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tid),
        .full(),
        .empty(),
        .count()
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(DEST_WIDTH)
    ) dest_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdest),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tdest),
        .full(),
        .empty(),
        .count()
    );

    fifo #(
        .DEPTH(DEPTH),
        .WIDTH(USER_WIDTH)
    ) user_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tuser),
        .wr_en(write_en),
        .rd_en(read_en),
        .dout(m_axis_tuser),
        .full(),
        .empty(),
        .count()
    );

    /*
     * Write enable logic
     */
    always @(*) begin
        write_en = s_axis_tvalid && !fifo_full;
        if (DROP_WHEN_FULL && fifo_full) begin
            write_en = 1'b0;
        end
    end

    /*
     * Read enable logic
     */
    always @(*) begin
        read_en = m_axis_tready && !fifo_empty;
        if (PAUSE_ENABLE && pause_req) begin
            read_en = 1'b0;
        end
    end

    /*
     * Frame tracking logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_started <= 1'b0;
            frame_ended <= 1'b0;
            frame_valid <= 1'b0;
            frame_size <= {$clog2(DEPTH){1'b0}};
            frame_error <= 1'b0;
            frame_good <= 1'b0;
        end else begin
            frame_started <= s_axis_tvalid && !frame_started;
            frame_ended <= s_axis_tvalid && s_axis_tlast;
            frame_valid <= frame_started && !frame_ended;

            if (frame_started) begin
                frame_size <= 1;
                frame_data <= s_axis_tdata;
                frame_keep <= s_axis_tkeep;
                frame_last <= s_axis_tlast;
                frame_id <= s_axis_tid;
                frame_dest <= s_axis_tdest;
                frame_user <= s_axis_tuser;
            end else if (frame_valid) begin
                frame_size <= frame_size + 1;
            end

            if (frame_ended) begin
                if (DROP_OVERSIZE_FRAME && frame_size > DEPTH) begin
                    frame_error <= 1'b1;
                end else if (DROP_BAD_FRAME && (frame_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    frame_error <= 1'b1;
                end else begin
                    frame_good <= 1'b1;
                end
            end
        end
    end

    /*
     * Status signals
     */
    assign s_axis_tready = write_en;
    assign pause_ack = PAUSE_ENABLE ? pause_req : 1'b0;
    assign status_depth = fifo_count;
    assign status_depth_commit = commit_count;
    assign status_overflow = fifo_full && write_en;
    assign status_bad_frame = frame_error;
    assign status_good_frame = frame_good;

endmodule

module fifo #
(
    parameter DEPTH = 1024,
    parameter WIDTH = 8
)
(
    input  wire               clk,
    input  wire               rst,
    input  wire [WIDTH-1:0] din,
    input  wire               wr_en,
    input  wire               rd_en,
    output wire [WIDTH-1:0] dout,
    output wire               full,
    output wire               empty,
    output wire [$clog2(DEPTH):0] count
);

    reg [$clog2(DEPTH):0]     wr_ptr;
    reg [$clog2(DEPTH):0]     rd_ptr;
    reg [WIDTH-1:0]           mem [DEPTH-1:0];

    assign full = (wr_ptr == {~rd_ptr[$clog2(DEPTH)-1:0], rd_ptr[$clog2(DEPTH)-1]});
    assign empty = (wr_ptr == rd_ptr);
    assign count = wr_ptr - rd_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {$clog2(DEPTH){1'b0}};
            rd_ptr <= {$clog2(DEPTH){1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    assign dout = mem[rd_ptr[$clog2(DEPTH)-1:0]];

endmodule
