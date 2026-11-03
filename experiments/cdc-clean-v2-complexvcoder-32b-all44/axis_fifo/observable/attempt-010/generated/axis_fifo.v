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

wire fifo_full;
wire fifo_empty;
wire frame_start;
wire frame_end;
wire frame_bad;

fifo_memory #(
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH)
) fifo_mem (
    .clk(clk),
    .rst(rst),
    .data_in(s_axis_tdata),
    .keep_in(s_axis_tkeep),
    .valid_in(s_axis_tvalid),
    .ready_in(s_axis_tready),
    .data_out(m_axis_tdata),
    .keep_out(m_axis_tkeep),
    .valid_out(m_axis_tvalid),
    .ready_out(m_axis_tready),
    .id_in(s_axis_tid),
    .dest_in(s_axis_tdest),
    .user_in(s_axis_tuser),
    .id_out(m_axis_tid),
    .dest_out(m_axis_tdest),
    .user_out(m_axis_tuser),
    .status_depth(status_depth),
    .status_depth_commit(status_depth_commit),
    .status_overflow(status_overflow),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty)
);

frame_detector #(
    .LAST_ENABLE(LAST_ENABLE),
    .USER_ENABLE(USER_ENABLE),
    .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK)
) frame_det (
    .clk(clk),
    .rst(rst),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .s_axis_tuser(s_axis_tuser),
    .status_bad_frame(status_bad_frame),
    .status_good_frame(status_good_frame),
    .frame_start(frame_start),
    .frame_end(frame_end),
    .frame_bad(frame_bad)
);

control_logic #(
    .DEPTH(DEPTH),
    .LAST_ENABLE(LAST_ENABLE),
    .KEEP_ENABLE(KEEP_ENABLE),
    .ID_ENABLE(ID_ENABLE),
    .DEST_ENABLE(DEST_ENABLE),
    .USER_ENABLE(USER_ENABLE),
    .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(DROP_BAD_FRAME),
    .DROP_WHEN_FULL(DROP_WHEN_FULL),
    .MARK_WHEN_FULL(MARK_WHEN_FULL),
    .PAUSE_ENABLE(PAUSE_ENABLE),
    .FRAME_PAUSE(FRAME_PAUSE)
) ctrl_logic (
    .clk(clk),
    .rst(rst),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .m_axis_tready(m_axis_tready),
    .m_axis_tvalid(m_axis_tvalid),
    .pause_req(pause_req),
    .pause_ack(pause_ack),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .frame_start(frame_start),
    .frame_end(frame_end),
    .frame_bad(frame_bad),
    .status_overflow(status_overflow)
);

endmodule

module fifo_memory #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [KEEP_WIDTH-1:0]  keep_in,
    input  wire                   valid_in,
    output wire                   ready_in,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire [KEEP_WIDTH-1:0]  keep_out,
    output wire                   valid_out,
    input  wire                   ready_out,
    input  wire [ID_WIDTH-1:0]    id_in,
    input  wire [DEST_WIDTH-1:0]  dest_in,
    input  wire [USER_WIDTH-1:0]  user_in,
    output wire [ID_WIDTH-1:0]    id_out,
    output wire [DEST_WIDTH-1:0]  dest_out,
    output wire [USER_WIDTH-1:0]  user_out,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   fifo_full,
    output wire                   fifo_empty
);

reg [$clog2(DEPTH)-1:0] write_ptr;
reg [$clog2(DEPTH)-1:0] read_ptr;
reg [$clog2(DEPTH):0] depth_count;
reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

assign ready_in = ~fifo_full;
assign valid_out = ~fifo_empty;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        write_ptr <= 0;
        read_ptr <= 0;
        depth_count <= 0;
        status_overflow <= 0;
    end else begin
        if (valid_in && ready_in && !valid_out) begin
            mem_data[write_ptr] <= data_in;
            mem_keep[write_ptr] <= keep_in;
            mem_id[write_ptr] <= id_in;
            mem_dest[write_ptr] <= dest_in;
            mem_user[write_ptr] <= user_in;
            write_ptr <= (write_ptr + 1) % DEPTH;
            depth_count <= depth_count + 1;
            if (depth_count == DEPTH - 1)
                status_overflow <= 1;
        end else if (valid_out && ready_out && !valid_in) begin
            read_ptr <= (read_ptr + 1) % DEPTH;
            depth_count <= depth_count - 1;
            status_overflow <= 0;
        end else if (valid_in && ready_in && valid_out && ready_out) begin
            mem_data[write_ptr] <= data_in;
            mem_keep[write_ptr] <= keep_in;
            mem_id[write_ptr] <= id_in;
            mem_dest[write_ptr] <= dest_in;
            mem_user[write_ptr] <= user_in;
            write_ptr <= (write_ptr + 1) % DEPTH;
            read_ptr <= (read_ptr + 1) % DEPTH;
        end
    end
end

assign data_out = mem_data[read_ptr];
assign keep_out = mem_keep[read_ptr];
assign id_out = mem_id[read_ptr];
assign dest_out = mem_dest[read_ptr];
assign user_out = mem_user[read_ptr];

assign fifo_full = (depth_count == DEPTH);
assign fifo_empty = (depth_count == 0);
assign status_depth = depth_count;
assign status_depth_commit = depth_count;

endmodule

module frame_detector #(
    parameter LAST_ENABLE = 1,
    parameter USER_ENABLE = 1,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   s_axis_tlast,
    input  wire                   s_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    output wire                   status_bad_frame,
    output wire                   status_good_frame,
    output wire                   frame_start,
    output wire                   frame_end,
    output wire                   frame_bad
);

reg frame_started;
reg frame_good_reg;
reg frame_bad_reg;

assign m_axis_tlast = frame_end;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        frame_started <= 0;
        frame_good_reg <= 0;
        frame_bad_reg <= 0;
        frame_start <= 0;
        frame_end <= 0;
        frame_bad <= 0;
        status_good_frame <= 0;
        status_bad_frame <= 0;
    end else begin
        frame_start <= s_axis_tvalid && !frame_started;
        frame_end <= s_axis_tvalid && s_axis_tlast;
        if (s_axis_tvalid && !frame_started) begin
            frame_started <= 1;
            frame_good_reg <= 1;
            frame_bad_reg <= 0;
        end
        if (s_axis_tvalid && s_axis_tlast) begin
            frame_started <= 0;
            status_good_frame <= frame_good_reg;
            status_bad_frame <= frame_bad_reg;
        end
        if (USER_ENABLE && s_axis_tvalid) begin
            if ((s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                frame_good_reg <= 0;
                frame_bad_reg <= 1;
            end
        end
        frame_bad <= frame_bad_reg;
    end
end

endmodule

module control_logic #(
    parameter DEPTH = 4096,
    parameter LAST_ENABLE = 1,
    parameter KEEP_ENABLE = 1,
    parameter ID_ENABLE = 1,
    parameter DEST_ENABLE = 1,
    parameter USER_ENABLE = 1,
    parameter DROP_OVERSIZE_FRAME = 0,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = 0
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tvalid,
    input  wire                   pause_req,
    output wire                   pause_ack,
    input  wire                   fifo_full,
    input  wire                   fifo_empty,
    input  wire                   frame_start,
    input  wire                   frame_end,
    input  wire                   frame_bad,
    input  wire                   status_overflow
);

reg write_enable;
reg read_enable;
reg frame_dropped;
reg frame_marked;

assign s_axis_tready = write_enable && !frame_dropped;
assign m_axis_tvalid = read_enable && !frame_marked;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        write_enable <= 0;
        read_enable <= 0;
        frame_dropped <= 0;
        frame_marked <= 0;
        pause_ack <= 0;
    end else begin
        frame_dropped <= 0;
        frame_marked <= 0;
        if (DROP_WHEN_FULL && fifo_full && s_axis_tvalid) begin
            frame_dropped <= 1;
        end else if (DROP_BAD_FRAME && frame_bad) begin
            frame_dropped <= 1;
        end else if (DROP_OVERSIZE_FRAME && frame_end && status_overflow) begin
            frame_dropped <= 1;
        end else if (MARK_WHEN_FULL && fifo_full && s_axis_tvalid) begin
            frame_marked <= 1;
        end else begin
            write_enable <= s_axis_tvalid && (!fifo_full || (MARK_WHEN_FULL && fifo_full));
            read_enable <= m_axis_tready && !fifo_empty;
        end

        if (PAUSE_ENABLE && pause_req && !fifo_empty) begin
            pause_ack <= 1;
            write_enable <= 0;
            read_enable <= 0;
        end else begin
            pause_ack <= 0;
        end
    end
end

endmodule
