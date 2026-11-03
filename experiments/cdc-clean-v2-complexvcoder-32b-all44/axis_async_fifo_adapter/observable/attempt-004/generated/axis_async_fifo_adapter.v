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
     * FIFO instance
     */
    fifo_cross_clk #(
        .DEPTH(DEPTH),
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) fifo_inst (
        .clk_wr(s_clk),
        .clk_rd(m_clk),
        .rst_wr(s_rst),
        .rst_rd(m_rst),
        .data_in(s_axis_tdata),
        .keep_in(s_axis_tkeep),
        .valid_in(s_axis_tvalid),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .data_out(m_axis_tdata),
        .keep_out(m_axis_tkeep),
        .valid_out(m_axis_tvalid),
        .last_out(m_axis_tlast),
        .id_out(m_axis_tid),
        .dest_out(m_axis_tdest),
        .user_out(m_axis_tuser),
        .ready_in(s_axis_tready),
        .ready_out(m_axis_tready),
        .status_depth_wr(s_status_depth),
        .status_depth_commit_wr(s_status_depth_commit),
        .status_overflow_wr(s_status_overflow),
        .status_bad_frame_wr(s_status_bad_frame),
        .status_good_frame_wr(s_status_good_frame),
        .status_depth_rd(m_status_depth),
        .status_depth_commit_rd(m_status_depth_commit),
        .status_overflow_rd(m_status_overflow),
        .status_bad_frame_rd(m_status_bad_frame),
        .status_good_frame_rd(m_status_good_frame)
    );

    /*
     * Pause signals (currently not used as per the parameters)
     */
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

endmodule

module fifo_cross_clk #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk_wr,
    input  wire                     clk_rd,
    input  wire                     rst_wr,
    input  wire                     rst_rd,
    input  wire [S_DATA_WIDTH-1:0]  data_in,
    input  wire [S_KEEP_WIDTH-1:0]  keep_in,
    input  wire                     valid_in,
    input  wire                     last_in,
    input  wire [ID_WIDTH-1:0]      id_in,
    input  wire [DEST_WIDTH-1:0]    dest_in,
    input  wire [USER_WIDTH-1:0]    user_in,
    output wire [M_DATA_WIDTH-1:0]  data_out,
    output wire [M_KEEP_WIDTH-1:0]  keep_out,
    output wire                     valid_out,
    output wire                     last_out,
    output wire [ID_WIDTH-1:0]      id_out,
    output wire [DEST_WIDTH-1:0]    dest_out,
    output wire [USER_WIDTH-1:0]    user_out,
    output wire                     ready_in,
    input  wire                     ready_out,
    output wire [$clog2(DEPTH):0]   status_depth_wr,
    output wire [$clog2(DEPTH):0]   status_depth_commit_wr,
    output wire                     status_overflow_wr,
    output wire                     status_bad_frame_wr,
    output wire                     status_good_frame_wr,
    output wire [$clog2(DEPTH):0]   status_depth_rd,
    output wire [$clog2(DEPTH):0]   status_depth_commit_rd,
    output wire                     status_overflow_rd,
    output wire                     status_bad_frame_rd,
    output wire                     status_good_frame_rd
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync;

    reg [S_DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg [ADDR_WIDTH:0] mem_last [0:DEPTH-1];

    reg [ADDR_WIDTH:0] wr_ptr_gray_next;
    reg [ADDR_WIDTH:0] rd_ptr_gray_next;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_next;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_next;

    reg [ADDR_WIDTH:0] wr_depth;
    reg [ADDR_WIDTH:0] rd_depth;

    reg [ADDR_WIDTH:0] wr_depth_commit;
    reg [ADDR_WIDTH:0] rd_depth_commit;

    reg wr_full;
    reg rd_empty;

    reg wr_bad_frame;
    reg wr_good_frame;

    reg rd_bad_frame;
    reg rd_good_frame;

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            wr_depth <= 0;
            wr_depth_commit <= 0;
            wr_full <= 0;
            wr_bad_frame <= 0;
            wr_good_frame <= 0;
        end else begin
            wr_ptr_gray_next = wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray_next;
            wr_ptr <= wr_ptr_gray_next ^ (wr_ptr_gray_next >> 1);

            if (valid_in && !wr_full) begin
                mem_data[wr_ptr] <= data_in;
                mem_keep[wr_ptr] <= keep_in;
                mem_last[wr_ptr] <= {last_in, wr_ptr_gray_next};
                mem_id[wr_ptr] <= id_in;
                mem_dest[wr_ptr] <= dest_in;
                mem_user[wr_ptr] <= user_in;
                wr_depth <= wr_depth + 1;
                if (last_in) begin
                    wr_good_frame <= 1;
                    wr_bad_frame <= (user_in & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end
            end else if (wr_depth > 0) begin
                wr_depth_commit <= wr_depth_commit + 1;
            end

            if (wr_depth == DEPTH) begin
                wr_full <= 1;
            end else if (wr_depth_commit > 0) begin
                wr_depth_commit <= wr_depth_commit - 1;
                wr_full <= 0;
            end
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_depth <= 0;
            rd_depth_commit <= 0;
            rd_empty <= 1;
            rd_bad_frame <= 0;
            rd_good_frame <= 0;
        end else begin
            rd_ptr_gray_next = rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray_next;
            rd_ptr <= rd_ptr_gray_next ^ (rd_ptr_gray_next >> 1);

            if (ready_out && !rd_empty) begin
                rd_depth <= rd_depth - 1;
                if (mem_last[rd_ptr][ADDR_WIDTH]) begin
                    rd_good_frame <= 1;
                    rd_bad_frame <= (mem_user[rd_ptr] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end
            end else if (rd_depth_commit < wr_depth_commit) begin
                rd_depth_commit <= rd_depth_commit + 1;
            end

            if (rd_depth_commit == wr_depth_commit) begin
                rd_empty <= 1;
            end else if (rd_depth > 0) begin
                rd_depth_commit <= rd_depth_commit - 1;
                rd_empty <= 0;
            end
        end
    end

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync_next = rd_ptr_gray_sync;
            wr_ptr_gray_sync <= wr_ptr_gray_sync_next;
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync_next = wr_ptr_gray_sync;
            rd_ptr_gray_sync <= rd_ptr_gray_sync_next;
        end
    end

    assign wr_depth_commit = wr_depth - (wr_ptr - rd_ptr_gray_sync);
    assign rd_depth_commit = rd_depth - (rd_ptr - wr_ptr_gray_sync);

    assign ready_in = !wr_full;
    assign valid_out = !rd_empty;

    assign data_out = mem_data[rd_ptr];
    assign keep_out = mem_keep[rd_ptr];
    assign last_out = mem_last[rd_ptr][0];
    assign id_out = mem_id[rd_ptr];
    assign dest_out = mem_dest[rd_ptr];
    assign user_out = mem_user[rd_ptr];

    assign status_depth_wr = wr_depth;
    assign status_depth_commit_wr = wr_depth_commit;
    assign status_overflow_wr = wr_full;
    assign status_bad_frame_wr = wr_bad_frame;
    assign status_good_frame_wr = wr_good_frame;

    assign status_depth_rd = rd_depth;
    assign status_depth_commit_rd = rd_depth_commit;
    assign status_overflow_rd = rd_empty;
    assign status_bad_frame_rd = rd_bad_frame;
    assign status_good_frame_rd = rd_good_frame;

endmodule
