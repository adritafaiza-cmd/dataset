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
reg [KEEP_WIDTH-1:0] keep_mem [DEPTH-1:0];
reg [ID_WIDTH-1:0] id_mem [DEPTH-1:0];
reg [DEST_WIDTH-1:0] dest_mem [DEPTH-1:0];
reg [USER_WIDTH-1:0] user_mem [DEPTH-1:0];
reg [DEPTH-1:0] wr_ptr;
reg [DEPTH-1:0] rd_ptr;
reg [DEPTH-1:0] wr_ptr_gray;
reg [DEPTH-1:0] rd_ptr_gray;
reg [DEPTH-1:0] wr_ptr_sync;
reg [DEPTH-1:0] rd_ptr_sync;
reg [DEPTH-1:0] wr_ptr_sync_gray;
reg [DEPTH-1:0] rd_ptr_sync_gray;
reg [DATA_WIDTH-1:0] data_out;
reg [KEEP_WIDTH-1:0] keep_out;
reg [ID_WIDTH-1:0] id_out;
reg [DEST_WIDTH-1:0] dest_out;
reg [USER_WIDTH-1:0] user_out;
reg full;
reg empty;
reg overflow;
reg underflow;
reg bad_frame;
reg good_frame;
reg [$clog2(DEPTH):0] depth;
reg [$clog2(DEPTH):0] depth_commit;
reg pause;
reg pause_ack;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        wr_ptr <= 0;
        full <= 0;
        overflow <= 0;
        bad_frame <= 0;
        good_frame <= 0;
        s_axis_tready <= 1;
        s_pause_ack <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_ptr] <= s_axis_tdata;
            keep_mem[wr_ptr] <= s_axis_tkeep;
            id_mem[wr_ptr] <= s_axis_tid;
            dest_mem[wr_ptr] <= s_axis_tdest;
            user_mem[wr_ptr] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH - 1) begin
                full <= 1;
                s_axis_tready <= 0;
            end
            if (s_axis_tlast) begin
                good_frame <= 1;
            end
        end
        if (s_pause_req) begin
            pause <= 1;
            s_pause_ack <= 1;
        end else begin
            pause <= 0;
            s_pause_ack <= 0;
        end
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        rd_ptr <= 0;
        empty <= 1;
        underflow <= 0;
        bad_frame <= 0;
        good_frame <= 0;
        m_axis_tvalid <= 0;
        m_pause_ack <= 0;
    end else begin
        if (m_axis_tready && m_axis_tvalid) begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH - 1) begin
                empty <= 1;
                m_axis_tvalid <= 0;
            end
        end
        if (m_pause_req) begin
            pause <= 1;
            m_pause_ack <= 1;
        end else begin
            pause <= 0;
            m_pause_ack <= 0;
        end
    end
end

always @(posedge s_clk) begin
    wr_ptr_gray <= {wr_ptr[DEPTH-2:0], 1'b0};
end

always @(posedge m_clk) begin
    rd_ptr_gray <= {rd_ptr[DEPTH-2:0], 1'b0};
end

always @(posedge m_clk) begin
    wr_ptr_sync <= wr_ptr_gray;
end

always @(posedge s_clk) begin
    rd_ptr_sync <= rd_ptr_gray;
end

always @(posedge m_clk) begin
    wr_ptr_sync_gray <= {wr_ptr_sync[DEPTH-2:0], 1'b0};
end

always @(posedge s_clk) begin
    rd_ptr_sync_gray <= {rd_ptr_sync[DEPTH-2:0], 1'b0};
end

always @(posedge s_clk) begin
    if (wr_ptr_sync_gray == rd_ptr_sync_gray) begin
        empty <= 1;
    end else begin
        empty <= 0;
    end
end

always @(posedge m_clk) begin
    if (wr_ptr_sync_gray == rd_ptr_sync_gray) begin
        full <= 1;
    end else begin
        full <= 0;
    end
end

always @(posedge s_clk) begin
    depth <= wr_ptr_sync_gray - rd_ptr_sync_gray;
end

always @(posedge m_clk) begin
    depth_commit <= wr_ptr_sync_gray - rd_ptr_sync_gray;
end

always @(posedge s_clk) begin
    if (full && s_axis_tvalid) begin
        overflow <= 1;
    end else begin
        overflow <= 0;
    end
end

always @(posedge m_clk) begin
    if (empty && m_axis_tready) begin
        underflow <= 1;
    end else begin
        underflow <= 0;
    end
end

always @(posedge s_clk) begin
    if (bad_frame) begin
        s_status_bad_frame <= 1;
    end else begin
        s_status_bad_frame <= 0;
    end
end

always @(posedge m_clk) begin
    if (bad_frame) begin
        m_status_bad_frame <= 1;
    end else begin
        m_status_bad_frame <= 0;
    end
end

always @(posedge s_clk) begin
    if (good_frame) begin
        s_status_good_frame <= 1;
    end else begin
        s_status_good_frame <= 0;
    end
end

always @(posedge m_clk) begin
    if (good_frame) begin
        m_status_good_frame <= 1;
    end else begin
        m_status_good_frame <= 0;
    end
end

always @(posedge m_clk) begin
    if (!empty) begin
        data_out <= mem[rd_ptr];
        keep_out <= keep_mem[rd_ptr];
        id_out <= id_mem[rd_ptr];
        dest_out <= dest_mem[rd_ptr];
        user_out <= user_mem[rd_ptr];
        m_axis_tvalid <= 1;
    end else begin
        m_axis_tvalid <= 0;
    end
end

assign m_axis_tdata = data_out;
assign m_axis_tkeep = keep_out;
assign m_axis_tid = id_out;
assign m_axis_tdest = dest_out;
assign m_axis_tuser = user_out;
assign s_status_depth = depth;
assign s_status_depth_commit = depth_commit;
assign s_status_overflow = overflow;
assign m_status_depth = depth;
assign m_status_depth_commit = depth_commit;
assign m_status_overflow = overflow;

endmodule
