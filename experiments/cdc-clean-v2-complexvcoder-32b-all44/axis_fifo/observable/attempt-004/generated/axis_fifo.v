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

    reg  [DATA_WIDTH-1:0]  m_axis_tdata_reg;
    reg  [KEEP_WIDTH-1:0]  m_axis_tkeep_reg;
    reg                    m_axis_tvalid_reg;
    reg                    m_axis_tlast_reg;
    reg  [ID_WIDTH-1:0]    m_axis_tid_reg;
    reg  [DEST_WIDTH-1:0]  m_axis_tdest_reg;
    reg  [USER_WIDTH-1:0]  m_axis_tuser_reg;

    reg                    wr_en;
    reg                    rd_en;
    reg                    fifo_full;
    reg                    fifo_empty;
    reg  [$clog2(DEPTH):0] data_count;

    reg                    frame_in_progress;
    reg                    frame_valid;
    reg                    frame_bad;
    reg  [$clog2(DEPTH):0] frame_size;
    reg  [$clog2(DEPTH):0] frame_size_commit;

    assign s_axis_tready = ~fifo_full;
    assign pause_ack = PAUSE_ENABLE ? (pause_req & FRAME_PAUSE) : 1'b0;

    assign status_depth = data_count;
    assign status_depth_commit = frame_size_commit;
    assign status_overflow = fifo_full & wr_en;
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_en <= 1'b0;
            rd_en <= 1'b0;
            frame_in_progress <= 1'b0;
            frame_valid <= 1'b0;
            frame_bad <= 1'b0;
            frame_size <= {$clog2(DEPTH){1'b0}};
            frame_size_commit <= {$clog2(DEPTH){1'b0}};
        end else begin
            wr_en <= s_axis_tvalid & ~fifo_full;
            rd_en <= m_axis_tready & ~fifo_empty;

            if (s_axis_tvalid && s_axis_tlast) begin
                frame_in_progress <= 1'b0;
                if (DROP_BAD_FRAME && frame_bad) begin
                    frame_size <= {$clog2(DEPTH){1'b0}};
                end else begin
                    frame_size_commit <= frame_size + 1;
                    frame_valid <= ~frame_bad;
                end
            end else if (s_axis_tvalid) begin
                if (!frame_in_progress) begin
                    frame_in_progress <= 1'b1;
                    frame_size <= 1;
                    frame_bad <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end else begin
                    frame_size <= frame_size + 1;
                    frame_bad <= frame_bad | ((s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
                end
            end

            if (m_axis_tready && m_axis_tvalid_reg) begin
                m_axis_tdata_reg <= m_axis_tdata;
                m_axis_tkeep_reg <= m_axis_tkeep;
                m_axis_tvalid_reg <= m_axis_tvalid;
                m_axis_tlast_reg <= m_axis_tlast;
                m_axis_tid_reg <= m_axis_tid;
                m_axis_tdest_reg <= m_axis_tdest;
                m_axis_tuser_reg <= m_axis_tuser;
            end
        end
    end

    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) data_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdata),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tdata),
        .full(fifo_full),
        .empty(fifo_empty),
        .data_count(data_count)
    );

    fifo #(
        .WIDTH(KEEP_WIDTH),
        .DEPTH(DEPTH)
    ) keep_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tkeep),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tkeep),
        .full(),
        .empty(),
        .data_count()
    );

    fifo #(
        .WIDTH(1),
        .DEPTH(DEPTH)
    ) valid_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tvalid),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tvalid),
        .full(),
        .empty(),
        .data_count()
    );

    fifo #(
        .WIDTH(1),
        .DEPTH(DEPTH)
    ) last_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tlast),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tlast),
        .full(),
        .empty(),
        .data_count()
    );

    fifo #(
        .WIDTH(ID_WIDTH),
        .DEPTH(DEPTH)
    ) id_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tid),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tid),
        .full(),
        .empty(),
        .data_count()
    );

    fifo #(
        .WIDTH(DEST_WIDTH),
        .DEPTH(DEPTH)
    ) dest_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdest),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tdest),
        .full(),
        .empty(),
        .data_count()
    );

    fifo #(
        .WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) user_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tuser),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(m_axis_tuser),
        .full(),
        .empty(),
        .data_count()
    );

endmodule

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [WIDTH-1:0]       din,
    input  wire                   wr_en,
    input  wire                   rd_en,
    output wire [WIDTH-1:0]       dout,
    output wire                   full,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] data_count
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] count;

    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign data_count = count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {$clog2(DEPTH){1'b0}};
            rd_ptr <= {$clog2(DEPTH){1'b0}};
            count <= {$clog2(DEPTH){1'b0}};
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

endmodule
