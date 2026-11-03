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
    logic [DEPTH-1:0] wr_ptr, rd_ptr;
    logic [DEPTH-1:0] wr_cnt, rd_cnt;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    logic [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    logic [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    logic [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    logic wr_en, rd_en;
    logic [DATA_WIDTH-1:0] out_data;
    logic [KEEP_WIDTH-1:0] out_keep;
    logic out_last;
    logic [ID_WIDTH-1:0] out_id;
    logic [DEST_WIDTH-1:0] out_dest;
    logic [USER_WIDTH-1:0] out_user;
    logic full, empty;
    logic [DATA_WIDTH-1:0] s_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    logic s_axis_tvalid_reg;
    logic s_axis_tlast_reg;
    logic [ID_WIDTH-1:0] s_axis_tid_reg;
    logic [DEST_WIDTH-1:0] s_axis_tdest_reg;
    logic [USER_WIDTH-1:0] s_axis_tuser_reg;
    logic s_axis_tready_reg;
    logic m_axis_tready_reg;
    logic s_pause_ack_reg;
    logic m_pause_ack_reg;

    // Write pointer and count
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_cnt <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && wr_cnt < DEPTH) begin
                wr_ptr <= wr_ptr + 1;
                wr_cnt <= wr_cnt + 1;
            end
        end
    end

    // Read pointer and count
    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_cnt <= 0;
        end else begin
            if (m_axis_tready && rd_cnt > 0) begin
                rd_ptr <= rd_ptr + 1;
                rd_cnt <= rd_cnt - 1;
            end
        end
    end

    // Memory and status
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            mem <= '{default: 0};
            keep_mem <= '{default: 0};
            id_mem <= '{default: 0};
            dest_mem <= '{default: 0};
            user_mem <= '{default: 0};
            wr_en <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && wr_cnt < DEPTH) begin
                mem[wr_ptr] <= s_axis_tdata;
                keep_mem[wr_ptr] <= s_axis_tkeep;
                id_mem[wr_ptr] <= s_axis_tid;
                dest_mem[wr_ptr] <= s_axis_tdest;
                user_mem[wr_ptr] <= s_axis_tuser;
                wr_en <= 1;
            end
        end
    end

    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_cnt <= 0;
        end else begin
            if (m_axis_tready && rd_cnt > 0) begin
                rd_cnt <= rd_cnt - 1;
            end
        end
    end

    assign out_data = mem[rd_ptr];
    assign out_keep = keep_mem[rd_ptr];
    assign out_last = (rd_ptr == wr_ptr - 1) && wr_cnt > 0;
    assign out_id = id_mem[rd_ptr];
    assign out_dest = dest_mem[rd_ptr];
    assign out_user = user_mem[rd_ptr];

    assign s_axis_tready = wr_cnt < DEPTH;
    assign m_axis_tvalid = rd_cnt > 0;
    assign m_axis_tlast = out_last;
    assign m_axis_tdata = out_data;
    assign m_axis_tkeep = out_keep;
    assign m_axis_tid = out_id;
    assign m_axis_tdest = out_dest;
    assign m_axis_tuser = out_user;

    assign s_status_depth = wr_cnt;
    assign s_status_depth_commit = wr_cnt;
    assign s_status_overflow = (wr_cnt == DEPTH) && (rd_cnt == 0);
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = wr_cnt > 0;

    assign m_status_depth = rd_cnt;
    assign m_status_depth_commit = rd_cnt;
    assign m_status_overflow = (wr_cnt == DEPTH) && (rd_cnt == 0);
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = rd_cnt > 0;

    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

endmodule
