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

reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
reg [KEEP_WIDTH-1:0] keep [DEPTH-1:0];
reg [ID_WIDTH-1:0] id [DEPTH-1:0];
reg [DEST_WIDTH-1:0] dest [DEPTH-1:0];
reg [USER_WIDTH-1:0] user [DEPTH-1:0];
reg [DEPTH-1:0] full;
reg [DEPTH-1:0] empty;
reg [$clog2(DEPTH):0] depth;
reg [$clog2(DEPTH):0] depth_commit;
reg [DEPTH-1:0] write_ptr;
reg [DEPTH-1:0] read_ptr;
reg [DEPTH-1:0] next_write_ptr;
reg [DEPTH-1:0] next_read_ptr;
reg s_axis_tready_reg;
reg m_axis_tvalid_reg;
reg s_pause_ack_reg;
reg m_pause_ack_reg;
reg s_status_overflow_reg;
reg m_status_overflow_reg;
reg s_status_bad_frame_reg;
reg m_status_bad_frame_reg;
reg s_status_good_frame_reg;
reg m_status_good_frame_reg;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_axis_tready_reg <= 1'b1;
        s_pause_ack_reg <= 1'b0;
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
        write_ptr <= 0;
        next_write_ptr <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem[write_ptr] <= s_axis_tdata;
            keep[write_ptr] <= s_axis_tkeep;
            id[write_ptr] <= s_axis_tid;
            dest[write_ptr] <= s_axis_tdest;
            user[write_ptr] <= s_axis_tuser;
            next_write_ptr <= write_ptr + 1;
            if (next_write_ptr == DEPTH) begin
                next_write_ptr <= 0;
            end
            if (s_axis_tlast) begin
                s_status_good_frame_reg <= 1'b1;
            end
        end
        if (s_pause_req) begin
            s_pause_ack_reg <= 1'b1;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
        if (next_write_ptr == read_ptr) begin
            s_axis_tready_reg <= 1'b0;
        end else begin
            s_axis_tready_reg <= 1'b1;
        end
        if (next_write_ptr == write_ptr + 1) begin
            s_status_overflow_reg <= 1'b1;
        end else begin
            s_status_overflow_reg <= 1'b0;
        end
        if (s_axis_tlast && s_axis_tuser == USER_BAD_FRAME_VALUE) begin
            s_status_bad_frame_reg <= 1'b1;
        end else begin
            s_status_bad_frame_reg <= 1'b0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_axis_tvalid_reg <= 1'b0;
        m_pause_ack_reg <= 1'b0;
        m_status_overflow_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
        read_ptr <= 0;
        next_read_ptr <= 0;
    end else begin
        if (m_axis_tready && m_axis_tvalid_reg) begin
            m_axis_tdata <= mem[read_ptr];
            m_axis_tkeep <= keep[read_ptr];
            m_axis_tlast <= (read_ptr == next_write_ptr - 1);
            m_axis_tid <= id[read_ptr];
            m_axis_tdest <= dest[read_ptr];
            m_axis_tuser <= user[read_ptr];
            next_read_ptr <= read_ptr + 1;
            if (next_read_ptr == DEPTH) begin
                next_read_ptr <= 0;
            end
        end
        if (m_pause_req) begin
            m_pause_ack_reg <= 1'b1;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
        if (read_ptr == next_write_ptr) begin
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            m_axis_tvalid_reg <= 1'b1;
        end
        if (read_ptr == next_write_ptr - 1) begin
            m_status_overflow_reg <= 1'b1;
        end else begin
            m_status_overflow_reg <= 1'b0;
        end
        if (m_axis_tlast && m_axis_tuser == USER_BAD_FRAME_VALUE) begin
            m_status_bad_frame_reg <= 1'b1;
        end else begin
            m_status_bad_frame_reg <= 1'b0;
        end
    end
end

always @(posedge s_clk) begin
    write_ptr <= next_write_ptr;
end

always @(posedge m_clk) begin
    read_ptr <= next_read_ptr;
end

always @(posedge s_clk) begin
    depth <= next_write_ptr - read_ptr;
    if (depth < 0) begin
        depth <= depth + DEPTH;
    end
end

always @(posedge m_clk) begin
    depth_commit <= next_read_ptr - write_ptr;
    if (depth_commit < 0) begin
        depth_commit <= depth_commit + DEPTH;
    end
end

assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign s_pause_ack = s_pause_ack_reg;
assign m_pause_ack = m_pause_ack_reg;
assign s_status_overflow = s_status_overflow_reg;
assign m_status_overflow = m_status_overflow_reg;
assign s_status_bad_frame = s_status_bad_frame_reg;
assign m_status_bad_frame = m_status_bad_frame_reg;
assign s_status_good_frame = s_status_good_frame_reg;
assign m_status_good_frame = m_status_good_frame_reg;
assign s_status_depth = depth;
assign s_status_depth_commit = depth_commit;
assign m_status_depth = depth;
assign m_status_depth_commit = depth_commit;

endmodule
