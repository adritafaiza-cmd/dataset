module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    /*
     * FIFO signals
     */
    wire [S_DATA_WIDTH-1:0]         fifo_inst_read_data;
    wire [S_KEEP_WIDTH-1:0]         fifo_inst_read_keep;
    wire                            fifo_inst_read_valid;
    wire                            fifo_inst_read_ready;
    wire                            fifo_inst_read_last;
    wire [ID_WIDTH-1:0]             fifo_inst_read_id;
    wire [DEST_WIDTH-1:0]           fifo_inst_read_dest;
    wire [USER_WIDTH-1:0]           fifo_inst_read_user;

    /*
     * Adapter signals
     */
    wire [S_DATA_WIDTH-1:0]         adapter_inst_s_data;
    wire [S_KEEP_WIDTH-1:0]         adapter_inst_s_keep;
    wire                            adapter_inst_s_valid;
    wire                            adapter_inst_s_ready;
    wire                            adapter_inst_s_last;
    wire [ID_WIDTH-1:0]             adapter_inst_s_id;
    wire [DEST_WIDTH-1:0]           adapter_inst_s_dest;
    wire [USER_WIDTH-1:0]           adapter_inst_s_user;
    wire [M_DATA_WIDTH-1:0]         adapter_inst_m_data;
    wire [M_KEEP_WIDTH-1:0]         adapter_inst_m_keep;
    wire                            adapter_inst_m_valid;
    wire                            adapter_inst_m_ready;
    wire                            adapter_inst_m_last;
    wire [ID_WIDTH-1:0]             adapter_inst_m_id;
    wire [DEST_WIDTH-1:0]           adapter_inst_m_dest;
    wire [USER_WIDTH-1:0]           adapter_inst_m_user;

    /*
     * Status signals
     */
    wire [$clog2(DEPTH):0]          s_status_inst_depth;
    wire [$clog2(DEPTH):0]          s_status_inst_depth_commit;
    wire                            s_status_inst_overflow;
    wire                            s_status_inst_bad_frame;
    wire                            s_status_inst_good_frame;
    wire [$clog2(DEPTH):0]          m_status_inst_depth;
    wire [$clog2(DEPTH):0]          m_status_inst_depth_commit;
    wire                            m_status_inst_overflow;
    wire                            m_status_inst_bad_frame;
    wire                            m_status_inst_good_frame;

    /*
     * Pause control signals
     */
    wire                            pause_inst_s_ack;
    wire                            pause_inst_m_ack;

    /*
     * FIFO instance
     */
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) fifo_inst (
        .write_clk(s_clk),
        .write_rst(s_rst),
        .read_clk(m_clk),
        .read_rst(m_rst),
        .write_data(s_axis_tdata),
        .write_keep(s_axis_tkeep),
        .write_valid(s_axis_tvalid),
        .write_ready(s_axis_tready),
        .write_last(s_axis_tlast),
        .write_id(s_axis_tid),
        .write_dest(s_axis_tdest),
        .write_user(s_axis_tuser),
        .read_data(fifo_inst_read_data),
        .read_keep(fifo_inst_read_keep),
        .read_valid(fifo_inst_read_valid),
        .read_ready(fifo_inst_read_ready),
        .read_last(fifo_inst_read_last),
        .read_id(fifo_inst_read_id),
        .read_dest(fifo_inst_read_dest),
        .read_user(fifo_inst_read_user)
    );

    /*
     * Width adapter instance
     */
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) adapter_inst (
        .s_data(fifo_inst_read_data),
        .s_keep(fifo_inst_read_keep),
        .s_valid(fifo_inst_read_valid),
        .s_ready(fifo_inst_read_ready),
        .s_last(fifo_inst_read_last),
        .s_id(fifo_inst_read_id),
        .s_dest(fifo_inst_read_dest),
        .s_user(fifo_inst_read_user),
        .m_data(adapter_inst_m_data),
        .m_keep(adapter_inst_m_keep),
        .m_valid(adapter_inst_m_valid),
        .m_ready(adapter_inst_m_ready),
        .m_last(adapter_inst_m_last),
        .m_id(adapter_inst_m_id),
        .m_dest(adapter_inst_m_dest),
        .m_user(adapter_inst_m_user)
    );

    /*
     * Status monitor instances
     */
    status_monitor #(
        .DEPTH(DEPTH)
    ) s_status_inst (
        .clk(s_clk),
        .rst(s_rst),
        .valid(s_axis_tvalid),
        .ready(s_axis_tready),
        .last(s_axis_tlast),
        .user(s_axis_tuser),
        .depth(s_status_inst_depth),
        .depth_commit(s_status_inst_depth_commit),
        .overflow(s_status_inst_overflow),
        .bad_frame(s_status_inst_bad_frame),
        .good_frame(s_status_inst_good_frame)
    );

    status_monitor #(
        .DEPTH(DEPTH)
    ) m_status_inst (
        .clk(m_clk),
        .rst(m_rst),
        .valid(adapter_inst_m_valid),
        .ready(adapter_inst_m_ready),
        .last(adapter_inst_m_last),
        .user(adapter_inst_m_user),
        .depth(m_status_inst_depth),
        .depth_commit(m_status_inst_depth_commit),
        .overflow(m_status_inst_overflow),
        .bad_frame(m_status_inst_bad_frame),
        .good_frame(m_status_inst_good_frame)
    );

    /*
     * Pause control instance
     */
    pause_control pause_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .s_req(s_pause_req),
        .s_ack(pause_inst_s_ack),
        .m_req(m_pause_req),
        .m_ack(pause_inst_m_ack)
    );

    /*
     * Output assignments
     */
    assign m_axis_tdata  = adapter_inst_m_data;
    assign m_axis_tkeep  = adapter_inst_m_keep;
    assign m_axis_tvalid = adapter_inst_m_valid;
    assign m_axis_tlast  = adapter_inst_m_last;
    assign m_axis_tid    = adapter_inst_m_id;
    assign m_axis_tdest  = adapter_inst_m_dest;
    assign m_axis_tuser  = adapter_inst_m_user;

    assign s_pause_ack   = pause_inst_s_ack;
    assign m_pause_ack   = pause_inst_m_ack;

    assign s_status_depth          = s_status_inst_depth;
    assign s_status_depth_commit   = s_status_inst_depth_commit;
    assign s_status_overflow       = s_status_inst_overflow;
    assign s_status_bad_frame      = s_status_inst_bad_frame;
    assign s_status_good_frame     = s_status_inst_good_frame;

    assign m_status_depth          = m_status_inst_depth;
    assign m_status_depth_commit   = m_status_inst_depth_commit;
    assign m_status_overflow       = m_status_inst_overflow;
    assign m_status_bad_frame      = m_status_inst_bad_frame;
    assign m_status_good_frame     = m_status_inst_good_frame;

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
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
    input  wire                     write_clk,
    input  wire                     write_rst,
    input  wire                     read_clk,
    input  wire                     read_rst,
    input  wire [DATA_WIDTH-1:0]    write_data,
    input  wire [KEEP_WIDTH-1:0]    write_keep,
    input  wire                     write_valid,
    output wire                     write_ready,
    input  wire                     write_last,
    input  wire [ID_WIDTH-1:0]      write_id,
    input  wire [DEST_WIDTH-1:0]    write_dest,
    input  wire [USER_WIDTH-1:0]    write_user,
    output wire [DATA_WIDTH-1:0]    read_data,
    output wire [KEEP_WIDTH-1:0]    read_keep,
    output wire                     read_valid,
    input  wire                     read_ready,
    output wire                     read_last,
    output wire [ID_WIDTH-1:0]      read_id,
    output wire [DEST_WIDTH-1:0]    read_dest,
    output wire [USER_WIDTH-1:0]    read_user
);

    reg [$clog2(DEPTH)-1:0] wr_ptr, wr_ptr_gray;
    reg [$clog2(DEPTH)-1:0] rd_ptr, rd_ptr_gray;
    reg [$clog2(DEPTH):0]   wr_gray_synced, rd_gray_synced;

    reg [DATA_WIDTH-1:0]    mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0]    keep_mem [DEPTH-1:0];
    reg [ID_WIDTH-1:0]      id_mem [DEPTH-1:0];
    reg [DEST_WIDTH-1:0]    dest_mem [DEPTH-1:0];
    reg [USER_WIDTH-1:0]    user_mem [DEPTH-1:0];
    reg                     last_mem [DEPTH-1:0];

    /*
     * Write logic
     */
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst) begin
            wr_ptr <= 0;
        end else if (write_ready && write_valid) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    always @(posedge read_clk) begin
        wr_gray_synced <= wr_ptr_gray;
    end

    assign write_ready = (wr_gray_synced[$clog2(DEPTH)-1:0] != rd_ptr) || (wr_gray_synced[$clog2(DEPTH)] == 1'b1);

    always @(posedge write_clk) begin
        if (write_ready && write_valid) begin
            mem[wr_ptr] <= write_data;
            keep_mem[wr_ptr] <= write_keep;
            last_mem[wr_ptr] <= write_last;
            id_mem[wr_ptr] <= write_id;
            dest_mem[wr_ptr] <= write_dest;
            user_mem[wr_ptr] <= write_user;
        end
    end

    /*
     * Read logic
     */
    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            rd_ptr <= 0;
        end else if (read_ready && read_valid) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    always @(posedge write_clk) begin
        rd_gray_synced <= rd_ptr_gray;
    end

    assign read_valid = (rd_gray_synced[$clog2(DEPTH)-1:0] != wr_ptr) || (rd_gray_synced[$clog2(DEPTH)] == 1'b1);

    assign read_data = mem[rd_ptr];
    assign read_keep = keep_mem[rd_ptr];
    assign read_last = last_mem[rd_ptr];
    assign read_id = id_mem[rd_ptr];
    assign read_dest = dest_mem[rd_ptr];
    assign read_user = user_mem[rd_ptr];

endmodule

module width_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire [S_DATA_WIDTH-1:0]  s_data,
    input  wire [S_KEEP_WIDTH-1:0]  s_keep,
    input  wire                     s_valid,
    output wire                     s_ready,
    input  wire                     s_last,
    input  wire [ID_WIDTH-1:0]      s_id,
    input  wire [DEST_WIDTH-1:0]    s_dest,
    input  wire [USER_WIDTH-1:0]    s_user,
    output wire [M_DATA_WIDTH-1:0]  m_data,
    output wire [M_KEEP_WIDTH-1:0]  m_keep,
    output wire                     m_valid,
    input  wire                     m_ready,
    output wire                     m_last,
    output wire [ID_WIDTH-1:0]      m_id,
    output wire [DEST_WIDTH-1:0]    m_dest,
    output wire [USER_WIDTH-1:0]    m_user
);

    /*
     * Register the input data and control signals
     */
    reg [S_DATA_WIDTH-1:0]  s_data_reg;
    reg [S_KEEP_WIDTH-1:0]  s_keep_reg;
    reg                     s_valid_reg;
    reg                     s_last_reg;
    reg [ID_WIDTH-1:0]      s_id_reg;
    reg [DEST_WIDTH-1:0]    s_dest_reg;
    reg [USER_WIDTH-1:0]    s_user_reg;

    always @(posedge m_clk) begin
        if (s_valid && m_ready) begin
            s_data_reg  <= s_data;
            s_keep_reg  <= s_keep;
            s_valid_reg <= s_valid;
            s_last_reg  <= s_last;
            s_id_reg    <= s_id;
            s_dest_reg  <= s_dest;
            s_user_reg  <= s_user;
        end
    end

    /*
     * Output the registered data and control signals
     */
    assign m_data  = s_data_reg;
    assign m_keep  = s_keep_reg;
    assign m_valid = s_valid_reg;
    assign m_last  = s_last_reg;
    assign m_id    = s_id_reg;
    assign m_dest  = s_dest_reg;
    assign m_user  = s_user_reg;

    /*
     * Ready signal
     */
    assign s_ready = m_ready;

endmodule

module status_monitor #
(
    parameter DEPTH = 4096
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     valid,
    input  wire                     ready,
    input  wire                     last,
    input  wire [USER_WIDTH-1:0]    user,
    output wire [$clog2(DEPTH):0]   depth,
    output wire [$clog2(DEPTH):0]   depth_commit,
    output wire                     overflow,
    output wire                     bad_frame,
    output wire                     good_frame
);

    reg [$clog2(DEPTH):0]   depth_reg;
    reg [$clog2(DEPTH):0]   depth_commit_reg;
    reg                     overflow_reg;
    reg                     bad_frame_reg;
    reg                     good_frame_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth_reg <= 0;
            depth_commit_reg <= 0;
            overflow_reg <= 0;
            bad_frame_reg <= 0;
            good_frame_reg <= 0;
        end else begin
            if (valid && ready) begin
                depth_reg <= depth_reg + 1;
                depth_commit_reg <= depth_commit_reg + 1;
            end else if (valid && !ready) begin
                depth_reg <= depth_reg + 1;
            end else if (!valid && ready) begin
                depth_reg <= depth_reg - 1;
                depth_commit_reg <= depth_commit_reg - 1;
            end

            if (depth_reg > DEPTH) begin
                overflow_reg <= 1;
            end

            if (last && user == USER_BAD_FRAME_VALUE) begin
                bad_frame_reg <= 1;
            end else if (last) begin
                good_frame_reg <= 1;
            end
        end
    end

    assign depth = depth_reg;
    assign depth_commit = depth_commit_reg;
    assign overflow = overflow_reg;
    assign bad_frame = bad_frame_reg;
    assign good_frame = good_frame_reg;

endmodule

module pause_control (
    input  wire s_clk,
    input  wire s_rst,
    input  wire m_clk,
    input  wire m_rst,
    input  wire s_req,
    output wire s_ack,
    input  wire m_req,
    output wire m_ack
);

    reg s_ack_reg;
    reg m_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ack_reg <= 0;
        end else begin
            s_ack_reg <= s_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ack_reg <= 0;
        end else begin
            m_ack_reg <= m_req;
        end
    end

    assign s_ack = s_ack_reg;
    assign m_ack = m_ack_reg;

endmodule
