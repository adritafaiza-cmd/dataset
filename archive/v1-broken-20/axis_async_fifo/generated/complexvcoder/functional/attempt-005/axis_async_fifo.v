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
    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_ram [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_ram [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_ram [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_ram [0:DEPTH-1];
    reg full, empty, pause_s, pause_m;
    reg [31:0] wr_ptr, rd_ptr, wr_cnt, rd_cnt;

    // Write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
        end else if (s_axis_tvalid && s_axis_tready && !full) begin
            ram[wr_ptr] <= s_axis_tdata;
            if (KEEP_ENABLE) keep_ram[wr_ptr] <= s_axis_tkeep;
            if (USER_ENABLE) user_ram[wr_ptr] <= s_axis_tuser;
            if (ID_ENABLE) id_ram[wr_ptr] <= s_axis_tid;
            if (DEST_ENABLE) dest_ram[wr_ptr] <= s_axis_tdest;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
        end else if (m_axis_tready && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // FIFO control logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            full <= 0;
            empty <= 1;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !full) begin
                wr_cnt <= wr_cnt + 1;
            end
            if (m_axis_tready && !empty) begin
                rd_cnt <= rd_cnt + 1;
            end
            full <= (wr_cnt == DEPTH);
            empty <= (rd_cnt == wr_cnt);
        end
    end

    // Output data
    assign s_axis_tready = !full;

    // Status signals
    assign s_status_depth = wr_cnt;
    assign s_status_depth_commit = wr_cnt;
    assign s_status_overflow = full;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;

    // Pause handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            pause_s <= 0;
        end else begin
            pause_s <= s_pause_req;
        end
    end
    assign s_pause_ack = pause_s;

    // Pause handling
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            pause_m <= 0;
        end else begin
            pause_m <= m_pause_req;
        end
    end
    assign m_pause_ack = pause_m;

    // Output data
    assign m_axis_tdata = ram[rd_ptr];
    if (KEEP_ENABLE) assign m_axis_tkeep = keep_ram[rd_ptr];
    if (USER_ENABLE) assign m_axis_tuser = user_ram[rd_ptr];
    if (ID_ENABLE) assign m_axis_tid = id_ram[rd_ptr];
    if (DEST_ENABLE) assign m_axis_tdest = dest_ram[rd_ptr];
    assign m_axis_tlast = (rd_cnt == (wr_cnt - 1));
    assign m_axis_tvalid = !empty && m_axis_tready;

endmodule
