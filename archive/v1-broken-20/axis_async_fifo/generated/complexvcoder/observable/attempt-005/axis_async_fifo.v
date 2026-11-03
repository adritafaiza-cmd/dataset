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

    localparam FIFO_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    wire [FIFO_WIDTH-1:0] s_axis_tdata_fifo_in;
    wire [FIFO_WIDTH-1:0] m_axis_tdata_fifo_out;

    assign s_axis_tdata_fifo_in = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};

    axis_async_fifo #(FIFO_WIDTH, DEPTH, KEEP_ENABLE, LAST_ENABLE, ID_ENABLE, DEST_ENABLE, USER_ENABLE, USER_BAD_FRAME_VALUE, USER_BAD_FRAME_MASK, DROP_OVERSIZE_FRAME, DROP_BAD_FRAME, DROP_WHEN_FULL, MARK_WHEN_FULL, FRAME_FIFO) s_to_m_fifo
    (
        .clk(s_clk),
        .rst(s_rst),
        .data_in(s_axis_tdata_fifo_in),
        .valid_in(s_axis_tvalid),
        .ready_out(s_axis_tready),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .data_out(m_axis_tdata_fifo_out),
        .valid_out(m_axis_tvalid),
        .ready_in(m_axis_tready),
        .last_out(m_axis_tlast),
        .id_out(m_axis_tid),
        .dest_out(m_axis_tdest),
        .user_out(m_axis_tuser),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .s_status_depth(s_status_depth),
        .s_status_depth_commit(s_status_depth_commit),
        .s_status_overflow(s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_status_depth(m_status_depth),
        .m_status_depth_commit(m_status_depth_commit),
        .m_status_overflow(m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

endmodule

module axis_async_fifo #(
    parameter WIDTH = 64,
    parameter DEPTH = 4096,
    parameter KEEP_ENABLE = 1,
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 1,
    parameter DEST_ENABLE = 1,
    parameter USER_ENABLE = 1,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = 0,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter FRAME_FIFO = 0
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [WIDTH-1:0]       data_in,
    input  wire [WIDTH/8-1:0]     keep_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    input  wire                   last_in,
    input  wire [7:0]             id_in,
    input  wire [7:0]             dest_in,
    input  wire [7:0]             user_in,
    output wire [WIDTH-1:0]       data_out,
    output wire [WIDTH/8-1:0]     keep_out,
    output wire                   valid_out,
    input  wire                   ready_in,
    output wire                   last_out,
    output wire [7:0]             id_out,
    output wire [7:0]             dest_out,
    output wire [7:0]             user_out,
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

    // FIFO for s_clk to m_clk conversion
    axis_async_fifo_core #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .DEST_ENABLE(DEST_ENABLE),
        .USER_ENABLE(USER_ENABLE),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .FRAME_FIFO(FRAME_FIFO)
    ) s_to_m_fifo (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .keep_in(keep_in),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .last_in(last_in),
        .id_in(id_in),
        .dest_in(dest_in),
        .user_in(user_in),
        .m_clk(clk),
        .m_rst(rst),
        .data_out(data_out),
        .keep_out(keep_out),
        .valid_out(valid_out),
        .ready_in(ready_in),
        .last_out(last_out),
        .id_out(id_out),
        .dest_out(dest_out),
        .user_out(user_out),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .s_status_depth(s_status_depth),
        .s_status_depth_commit(s_status_depth_commit),
        .s_status_overflow(s_status_overflow),
        .s_status_bad_frame(s_status_bad_frame),
        .s_status_good_frame(s_status_good_frame),
        .m_status_depth(m_status_depth),
        .m_status_depth_commit(m_status_depth_commit),
        .m_status_overflow(m_status_overflow),
        .m_status_bad_frame(m_status_bad_frame),
        .m_status_good_frame(m_status_good_frame)
    );

endmodule

module axis_async_fifo_core #(
    parameter WIDTH = 64,
    parameter DEPTH = 4096,
    parameter KEEP_ENABLE = 1,
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 1,
    parameter DEST_ENABLE = 1,
    parameter USER_ENABLE = 1,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = 0,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter FRAME_FIFO = 0
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [WIDTH-1:0]       data_in,
    input  wire [WIDTH/8-1:0]     keep_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    input  wire                   last_in,
    input  wire [7:0]             id_in,
    input  wire [7:0]             dest_in,
    input  wire [7:0]             user_in,
    output wire [WIDTH-1:0]       data_out,
    output wire [WIDTH/8-1:0]     keep_out,
    output wire                   valid_out,
    input  wire                   ready_in,
    output wire                   last_out,
    output wire [7:0]             id_out,
    output wire [7:0]             dest_out,
    output wire [7:0]             user_out,
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

    reg [$clog2(DEPTH)-1:0] s_read_pointer;
    reg [$clog2(DEPTH)-1:0] s_write_pointer;
    reg [$clog2(DEPTH)-1:0] m_read_pointer;
    reg [$clog2(DEPTH)-1:0] m_write_pointer;
    reg [WIDTH-1:0] s_fifo [0:DEPTH-1];
    reg [WIDTH-1:0] m_fifo [0:DEPTH-1];
    reg [WIDTH/8-1:0] s_fifo_keep [0:DEPTH-1];
    reg [WIDTH/8-1:0] m_fifo_keep [0:DEPTH-1];
    reg s_fifo_last [0:DEPTH-1];
    reg m_fifo_last [0:DEPTH-1];
    reg [7:0] s_fifo_id [0:DEPTH-1];
    reg [7:0] m_fifo_id [0:DEPTH-1];
    reg [7:0] s_fifo_dest [0:DEPTH-1];
    reg [7:0] m_fifo_dest [0:DEPTH-1];
    reg [7:0] s_fifo_user [0:DEPTH-1];
    reg [7:0] m_fifo_user [0:DEPTH-1];
    reg s_fifo_valid [0:DEPTH-1];
    reg m_fifo_valid [0:DEPTH-1];
    reg s_fifo_ready;
    reg m_fifo_ready;

    assign s_pause_ack = !s_pause_req;
    assign m_pause_ack = !m_pause_req;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_read_pointer <= 0;
            s_write_pointer <= 0;
            m_read_pointer <= 0;
            m_write_pointer <= 0;
        end else begin
            if (valid_in && ready_out) begin
                s_fifo[s_write_pointer] <= data_in;
                s_fifo_keep[s_write_pointer] <= keep_in;
                s_fifo_last[s_write_pointer] <= last_in;
                s_fifo_id[s_write_pointer] <= id_in;
                s_fifo_dest[s_write_pointer] <= dest_in;
                s_fifo_user[s_write_pointer] <= user_in;
                s_fifo_valid[s_write_pointer] <= 1;
                s_write_pointer <= (s_write_pointer + 1) % DEPTH;
            end

            if (ready_in && valid_out) begin
                m_fifo[m_read_pointer] <= data_out;
                m_fifo_keep[m_read_pointer] <= keep_out;
                m_fifo_last[m_read_pointer] <= last_out;
                m_fifo_id[m_read_pointer] <= id_out;
                m_fifo_dest[m_read_pointer] <= dest_out;
                m_fifo_user[m_read_pointer] <= user_out;
                m_fifo_valid[m_read_pointer] <= 1;
                m_read_pointer <= (m_read_pointer + 1) % DEPTH;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            s_fifo_ready <= 0;
            m_fifo_ready <= 0;
        end else begin
            if (s_write_pointer == s_read_pointer) begin
                s_fifo_ready <= 0;
            end else begin
                s_fifo_ready <= 1;
            end

            if (m_read_pointer == m_write_pointer) begin
                m_fifo_ready <= 0;
            end else begin
                m_fifo_ready <= 1;
            end
        end
    end

    assign s_axis_tready = s_fifo_ready;
    assign m_axis_tvalid = m_fifo_valid[m_read_pointer];

    always @(posedge clk) begin
        if (rst) begin
            s_status_depth <= 0;
            s_status_depth_commit <= 0;
            s_status_overflow <= 0;
            s_status_bad_frame <= 0;
            s_status_good_frame <= 0;
            m_status_depth <= 0;
            m_status_depth_commit <= 0;
            m_status_overflow <= 0;
            m_status_bad_frame <= 0;
            m_status_good_frame <= 0;
        end else begin
            s_status_depth <= s_write_pointer - s_read_pointer;
            s_status_depth_commit <= s_write_pointer - s_read_pointer;
            m_status_depth <= m_write_pointer - m_read_pointer;
            m_status_depth_commit <= m_write_pointer - m_read_pointer;
        end
    end

endmodule
