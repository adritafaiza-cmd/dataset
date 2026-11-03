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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wr_ptr_s, wr_ptr_m;
    reg [ADDR_WIDTH:0] rd_ptr_s, rd_ptr_m;
    reg [ADDR_WIDTH:0] wr_ptr_gray_s, wr_ptr_gray_m;
    reg [ADDR_WIDTH:0] rd_ptr_gray_s, rd_ptr_gray_m;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_m, wr_ptr_gray_sync_s;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_m, rd_ptr_gray_sync_s;

    reg [DATA_WIDTH-1:0] mem_tdata [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_tkeep [0:DEPTH-1];
    reg                  mem_tlast [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_tuser [0:DEPTH-1];

    reg                  s_axis_tready_reg;
    reg                  m_axis_tvalid_reg;
    reg                  s_pause_ack_reg;
    reg                  m_pause_ack_reg;

    reg [$clog2(DEPTH):0] s_status_depth_reg;
    reg [$clog2(DEPTH):0] s_status_depth_commit_reg;
    reg                   s_status_overflow_reg;
    reg                   s_status_bad_frame_reg;
    reg                   s_status_good_frame_reg;
    reg [$clog2(DEPTH):0] m_status_depth_reg;
    reg [$clog2(DEPTH):0] m_status_depth_commit_reg;
    reg                   m_status_overflow_reg;
    reg                   m_status_bad_frame_reg;
    reg                   m_status_good_frame_reg;

    wire [ADDR_WIDTH:0] wr_ptr_gray_next_s;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next_s;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next_m;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next_m;

    wire [ADDR_WIDTH:0] depth_s, depth_m;
    wire full_s, empty_s, full_m, empty_m;

    assign wr_ptr_gray_next_s = (wr_ptr_s + 1) ^ (wr_ptr_s + 1) >> 1;
    assign rd_ptr_gray_next_s = rd_ptr_s ^ rd_ptr_s >> 1;
    assign wr_ptr_gray_next_m = (wr_ptr_m + 1) ^ (wr_ptr_m + 1) >> 1;
    assign rd_ptr_gray_next_m = rd_ptr_m ^ rd_ptr_m >> 1;

    assign depth_s = wr_ptr_gray_sync_s - rd_ptr_gray_s;
    assign depth_m = wr_ptr_gray_sync_m - rd_ptr_m;

    assign full_s = depth_s == DEPTH;
    assign empty_s = depth_s == 0;
    assign full_m = depth_m == DEPTH;
    assign empty_m = depth_m == 0;

    assign s_axis_tready = !full_s && !s_pause_req;
    assign m_axis_tvalid = !empty_m && !m_pause_req;

    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_s <= 0;
            rd_ptr_s <= 0;
            wr_ptr_gray_s <= 0;
            rd_ptr_gray_s <= 0;
            wr_ptr_gray_sync_m <= 0;
            rd_ptr_gray_sync_m <= 0;
            s_axis_tready_reg <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            wr_ptr_gray_sync_m <= wr_ptr_gray_m;
            rd_ptr_gray_sync_m <= rd_ptr_m;

            if (s_axis_tvalid && s_axis_tready) begin
                mem_tdata[wr_ptr_s] <= s_axis_tdata;
                mem_tkeep[wr_ptr_s] <= s_axis_tkeep;
                mem_tlast[wr_ptr_s] <= s_axis_tlast;
                mem_tid[wr_ptr_s] <= s_axis_tid;
                mem_tdest[wr_ptr_s] <= s_axis_tdest;
                mem_tuser[wr_ptr_s] <= s_axis_tuser;
                wr_ptr_s <= wr_ptr_s + 1;
                wr_ptr_gray_s <= wr_ptr_gray_next_s;
            end

            if (m_axis_tready && m_axis_tvalid) begin
                rd_ptr_s <= rd_ptr_s + 1;
                rd_ptr_gray_s <= rd_ptr_gray_next_s;
            end

            s_status_depth_reg <= depth_s;
            s_status_depth_commit_reg <= depth_s;
            s_status_overflow_reg <= full_s;
            s_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            s_status_good_frame_reg <= 0; // Placeholder for good frame detection
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_m <= 0;
            rd_ptr_m <= 0;
            wr_ptr_gray_m <= 0;
            rd_ptr_gray_m <= 0;
            wr_ptr_gray_sync_s <= 0;
            rd_ptr_gray_sync_s <= 0;
            m_axis_tvalid_reg <= 0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            wr_ptr_gray_sync_s <= wr_ptr_gray_s;
            rd_ptr_gray_sync_s <= rd_ptr_s;

            if (m_axis_tready && m_axis_tvalid) begin
                rd_ptr_m <= rd_ptr_m + 1;
                rd_ptr_gray_m <= rd_ptr_gray_next_m;
            end

            m_status_depth_reg <= depth_m;
            m_status_depth_commit_reg <= depth_m;
            m_status_overflow_reg <= full_m;
            m_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            m_status_good_frame_reg <= 0; // Placeholder for good frame detection
        end
    end

    always @(posedge m_clk) begin
        if (!m_rst && m_axis_tvalid) begin
            m_axis_tdata <= mem_tdata[rd_ptr_m];
            m_axis_tkeep <= mem_tkeep[rd_ptr_m];
            m_axis_tlast <= mem_tlast[rd_ptr_m];
            m_axis_tid <= mem_tid[rd_ptr_m];
            m_axis_tdest <= mem_tdest[rd_ptr_m];
            m_axis_tuser <= mem_tuser[rd_ptr_m];
        end
    end

    assign s_status_depth = s_status_depth_reg;
    assign s_status_depth_commit = s_status_depth_commit_reg;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_depth = m_status_depth_reg;
    assign m_status_depth_commit = m_status_depth_commit_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule
