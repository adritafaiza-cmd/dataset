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
     * Internal signals
     */
    wire                          s_fifo_full;
    wire                          s_fifo_empty;
    wire                          m_fifo_full;
    wire                          m_fifo_empty;

    /*
     * FIFO buffer instances
     */
    fifo_buffer #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) s_fifo_buffer (
        .clk(s_clk),
        .rst(s_rst),
        .data_in(s_axis_tdata),
        .keep_in(s_axis_tkeep),
        .valid_in(s_axis_tvalid),
        .ready_out(s_axis_tready),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .data_out(),
        .keep_out(),
        .valid_out(),
        .ready_in(),
        .last_out(),
        .id_out(),
        .dest_out(),
        .user_out(),
        .full(s_fifo_full),
        .empty(s_fifo_empty)
    );

    fifo_buffer #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) m_fifo_buffer (
        .clk(m_clk),
        .rst(m_rst),
        .data_in(),
        .keep_in(),
        .valid_in(),
        .ready_out(),
        .last_in(),
        .id_in(),
        .dest_in(),
        .user_in(),
        .data_out(m_axis_tdata),
        .keep_out(m_axis_tkeep),
        .valid_out(m_axis_tvalid),
        .ready_in(m_axis_tready),
        .last_out(m_axis_tlast),
        .id_out(m_axis_tid),
        .dest_out(m_axis_tdest),
        .user_out(m_axis_tuser),
        .full(m_fifo_full),
        .empty(m_fifo_empty)
    );

    /*
     * Cross-domain synchronization instances
     */
    cross_domain_sync s_sync (
        .clk_src(s_clk),
        .clk_dst(m_clk),
        .src_signal(s_fifo_buffer.valid_out),
        .dst_signal(m_fifo_buffer.valid_in)
    );

    cross_domain_sync m_sync (
        .clk_src(m_clk),
        .clk_dst(s_clk),
        .src_signal(m_fifo_buffer.ready_out),
        .dst_signal(s_fifo_buffer.ready_in)
    );

    /*
     * Status counter instances
     */
    status_counter #(
        .DEPTH(DEPTH)
    ) s_status_counter (
        .clk(s_clk),
        .rst(s_rst),
        .valid_in(s_fifo_buffer.valid_out),
        .ready_in(s_fifo_buffer.ready_in),
        .depth(s_status_depth),
        .depth_commit(s_status_depth_commit),
        .overflow(s_status_overflow),
        .bad_frame(s_status_bad_frame),
        .good_frame(s_status_good_frame)
    );

    status_counter #(
        .DEPTH(DEPTH)
    ) m_status_counter (
        .clk(m_clk),
        .rst(m_rst),
        .valid_in(m_fifo_buffer.valid_out),
        .ready_in(m_fifo_buffer.ready_in),
        .depth(m_status_depth),
        .depth_commit(m_status_depth_commit),
        .overflow(m_status_overflow),
        .bad_frame(m_status_bad_frame),
        .good_frame(m_status_good_frame)
    );

    /*
     * Pause signals
     */
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

endmodule

module fifo_buffer #
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
    parameter RAM_PIPELINE = 1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [KEEP_WIDTH-1:0]  keep_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    input  wire                   last_in,
    input  wire [ID_WIDTH-1:0]    id_in,
    input  wire [DEST_WIDTH-1:0]  dest_in,
    input  wire [USER_WIDTH-1:0]  user_in,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire [KEEP_WIDTH-1:0]  keep_out,
    output wire                   valid_out,
    input  wire                   ready_in,
    output wire                   last_out,
    output wire [ID_WIDTH-1:0]    id_out,
    output wire [DEST_WIDTH-1:0]  dest_out,
    output wire [USER_WIDTH-1:0]  user_out,
    output wire                   full,
    output wire                   empty
);

    /*
     * Internal signals
     */
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    reg [$clog2(DEPTH):0]   count;

    /*
     * Memory arrays
     */
    reg [DATA_WIDTH-1:0]  mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  mem_keep [0:DEPTH-1];
    reg                   mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  mem_user [0:DEPTH-1];

    /*
     * Write pointer and read pointer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            if (valid_in && !full && ready_in) begin
                mem_data[wr_ptr] <= data_in;
                mem_keep[wr_ptr] <= keep_in;
                mem_last[wr_ptr] <= last_in;
                mem_id[wr_ptr]   <= id_in;
                mem_dest[wr_ptr] <= dest_in;
                mem_user[wr_ptr] <= user_in;
                wr_ptr           <= wr_ptr + 1;
                count            <= count + 1;
            end
            if (valid_out && !empty && ready_out) begin
                rd_ptr <= rd_ptr + 1;
                count  <= count - 1;
            end
        end
    end

    /*
     * Output signals
     */
    assign data_out  = mem_data[rd_ptr];
    assign keep_out  = mem_keep[rd_ptr];
    assign last_out  = mem_last[rd_ptr];
    assign id_out    = mem_id[rd_ptr];
    assign dest_out  = mem_dest[rd_ptr];
    assign user_out  = mem_user[rd_ptr];
    assign valid_out = !empty;
    assign ready_out = !full;
    assign full      = (count == DEPTH);
    assign empty     = (count == 0);

endmodule

module cross_domain_sync (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire src_signal,
    output wire dst_signal
);

    /*
     * Internal signals
     */
    reg [1:0] sync_reg;

    /*
     * Synchronization logic
     */
    always @(posedge clk_dst or posedge rst) begin
        if (rst) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= src_signal;
            sync_reg[1] <= sync_reg[0];
        end
    end

    assign dst_signal = sync_reg[1];

endmodule

module status_counter #
(
    parameter DEPTH = 4096
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   valid_in,
    input  wire                   ready_in,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit,
    output wire                   overflow,
    output wire                   bad_frame,
    output wire                   good_frame
);

    /*
     * Internal signals
     */
    reg [$clog2(DEPTH):0] count;
    reg                   last_valid;
    reg                   last_ready;

    /*
     * Depth counter logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
        end else begin
            if (valid_in && ready_in) begin
                if (valid_in && !last_valid && last_ready) begin
                    count <= count + 1;
                end else if (!valid_in && last_valid && !ready_in) begin
                    count <= count - 1;
                end
            end
        end
    end

    /*
     * Output signals
     */
    assign depth         = count;
    assign depth_commit  = count;
    assign overflow      = 0; // Placeholder, actual overflow logic needs to be implemented
    assign bad_frame     = 0; // Placeholder, actual bad frame logic needs to be implemented
    assign good_frame    = 0; // Placeholder, actual good frame logic needs to be implemented

    /*
     * Last valid and ready signals
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_valid <= 0;
            last_ready <= 0;
        end else begin
            last_valid <= valid_in;
            last_ready <= ready_in;
        end
    end

endmodule
