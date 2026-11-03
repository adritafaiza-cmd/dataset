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

    reg [DATA_WIDTH-1:0]  data_fifo_out;
    reg [KEEP_WIDTH-1:0]  keep_fifo_out;
    reg                   last_fifo_out;
    reg [ID_WIDTH-1:0]    id_fifo_out;
    reg [DEST_WIDTH-1:0]  dest_fifo_out;
    reg [USER_WIDTH-1:0]  user_fifo_out;
    reg                   commit_fifo_out;

    reg                   write_enable;
    reg                   read_enable;
    reg                   frame_start;
    reg                   frame_end;
    reg                   frame_valid;
    reg                   frame_bad;
    reg                   frame_good;
    reg [$clog2(DEPTH):0] frame_size;
    reg                   fifo_full;
    reg                   fifo_empty;
    reg [$clog2(DEPTH):0] fifo_depth;
    reg [$clog2(DEPTH):0] fifo_depth_commit;

    reg                   status_overflow_reg;
    reg                   status_bad_frame_reg;
    reg                   status_good_frame_reg;

    // FIFOs
    fifo #(.WIDTH(DATA_WIDTH), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    data_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdata),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(data_fifo_out),
        .full(fifo_full),
        .empty(fifo_empty),
        .depth(fifo_depth)
    );

    fifo #(.WIDTH(KEEP_WIDTH), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    keep_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tkeep),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(keep_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    fifo #(.WIDTH(1), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    last_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tlast),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(last_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    fifo #(.WIDTH(ID_WIDTH), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    id_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tid),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(id_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    fifo #(.WIDTH(DEST_WIDTH), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    dest_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tdest),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(dest_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    fifo #(.WIDTH(USER_WIDTH), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    user_fifo (
        .clk(clk),
        .rst(rst),
        .din(s_axis_tuser),
        .wr_en(write_enable),
        .rd_en(read_enable),
        .dout(user_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    fifo #(.WIDTH(1), .DEPTH(DEPTH), .RAM_PIPELINE(RAM_PIPELINE))
    commit_fifo (
        .clk(clk),
        .rst(rst),
        .din(frame_valid),
        .wr_en(frame_end),
        .rd_en(read_enable & last_fifo_out),
        .dout(commit_fifo_out),
        .full(),
        .empty(),
        .depth()
    );

    // Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_start <= 0;
            frame_end <= 0;
            frame_valid <= 0;
            frame_bad <= 0;
            frame_good <= 0;
            frame_size <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            frame_start <= s_axis_tvalid & ~s_axis_tlast & ~frame_valid;
            frame_end <= s_axis_tvalid & s_axis_tlast;
            frame_size <= frame_start ? 1 : (frame_valid ? frame_size + 1 : 0);

            frame_bad <= USER_ENABLE & (user_fifo_out & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

            frame_valid <= frame_valid | frame_start;
            frame_good <= frame_valid & ~frame_bad & frame_end;

            if (frame_end) begin
                frame_valid <= 0;
            end

            if (fifo_full & (s_axis_tvalid & ~frame_bad)) begin
                status_overflow_reg <= 1;
            end

            if (frame_bad & frame_end) begin
                status_bad_frame_reg <= 1;
            end

            if (frame_good & frame_end) begin
                status_good_frame_reg <= 1;
            end
        end
    end

    // Write Enable Logic
    assign write_enable = s_axis_tvalid & ~fifo_full & ~(DROP_OVERSIZE_FRAME & frame_size >= DEPTH) & ~(DROP_BAD_FRAME & frame_bad);

    // Read Enable Logic
    assign read_enable = m_axis_tready & ~fifo_empty;

    // AXI Stream Output
    assign m_axis_tdata = data_fifo_out;
    assign m_axis_tkeep = keep_fifo_out;
    assign m_axis_tvalid = ~fifo_empty;
    assign m_axis_tlast = last_fifo_out;
    assign m_axis_tid = id_fifo_out;
    assign m_axis_tdest = dest_fifo_out;
    assign m_axis_tuser = user_fifo_out;

    // Pause Control
    assign pause_ack = PAUSE_ENABLE & pause_req;

    // Status Outputs
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Clear Status Flags
    always @(posedge clk) begin
        if (status_overflow_reg & s_axis_tvalid) begin
            status_overflow_reg <= 0;
        end

        if (status_bad_frame_reg & frame_end) begin
            status_bad_frame_reg <= 0;
        end

        if (status_good_frame_reg & frame_end) begin
            status_good_frame_reg <= 0;
        end
    end

endmodule

// FIFO module
module fifo #
(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter RAM_PIPELINE = 1
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [WIDTH-1:0]   din,
    input  wire                 wr_en,
    input  wire                 rd_en,
    output reg [WIDTH-1:0]    dout,
    output reg                full,
    output reg                empty,
    output reg [$clog2(DEPTH):0] depth
);

    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
            depth <= 0;
        end else begin
            if (wr_en & ~full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                depth <= depth + 1;
                if (wr_ptr == DEPTH - 1)
                    full <= 1;
                empty <= 0;
            end

            if (rd_en & ~empty) begin
                rd_ptr <= rd_ptr + 1;
                depth <= depth - 1;
                if (rd_ptr == DEPTH - 1)
                    empty <= 1;
                full <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (RAM_PIPELINE) begin
            dout <= mem[rd_ptr];
        end else begin
            dout <= mem[rd_ptr - 1];
        end
    end

endmodule
