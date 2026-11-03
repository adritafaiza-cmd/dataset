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

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [LAST_ENABLE:0] last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg [3:0] wr_ptr;
    reg [3:0] rd_ptr;
    reg [3:0] wr_cnt;
    reg [3:0] rd_cnt;
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Clock domain crossing for write
    always @(posedge s_clk) begin
        if (s_rst) begin
            wr_ptr <= 4'b0000;
            wr_cnt <= 4'b0000;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_pause_req) begin
                mem[wr_ptr] <= s_axis_tdata;
                keep_mem[wr_ptr] <= s_axis_tkeep;
                last_mem[wr_ptr] <= s_axis_tlast;
                id_mem[wr_ptr] <= s_axis_tid;
                dest_mem[wr_ptr] <= s_axis_tdest;
                user_mem[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                wr_cnt <= wr_cnt + 1;
            end
        end
    end

    // Clock domain crossing for read
    always @(posedge m_clk) begin
        if (m_rst) begin
            rd_ptr <= 4'b0000;
            rd_cnt <= 4'b0000;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
        end else begin
            if (m_axis_tready && m_axis_tvalid_reg && !m_pause_req) begin
                m_axis_tdata <= mem[rd_ptr];
                m_axis_tkeep <= keep_mem[rd_ptr];
                m_axis_tlast <= last_mem[rd_ptr];
                m_axis_tid <= id_mem[rd_ptr];
                m_axis_tdest <= dest_mem[rd_ptr];
                m_axis_tuser <= user_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                rd_cnt <= rd_cnt + 1;
                if (m_axis_tlast) begin
                    rd_cnt <= 4'b0000;
                end
            end
            m_axis_tvalid_reg <= (rd_cnt > 0);
            m_axis_tlast_reg <= (rd_cnt == wr_cnt);
        end
    end

    // Status signals
    assign s_status_depth = wr_cnt;
    assign s_status_depth_commit = rd_cnt;
    assign s_status_overflow = (wr_cnt == DEPTH);
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b1;
    assign m_status_depth = wr_cnt;
    assign m_status_depth_commit = rd_cnt;
    assign m_status_overflow = (wr_cnt == DEPTH);
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b1;

    // Pause signals
    assign s_pause_ack_reg = s_pause_req;
    assign m_pause_ack_reg = m_pause_req;

    // Handshake signals
    assign s_axis_tready = (wr_cnt < DEPTH) && !s_pause_req;
    assign m_axis_tvalid = (rd_cnt > 0) && !m_pause_req;

endmodule
