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

    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
    reg [LAST_ENABLE-1:0] fifo_last [0:DEPTH-1];
    reg [ID_ENABLE*ID_WIDTH-1:0] fifo_id [0:DEPTH-1];
    reg [DEST_ENABLE*DEST_WIDTH-1:0] fifo_dest [0:DEPTH-1];
    reg [USER_ENABLE*USER_WIDTH-1:0] fifo_user [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [ADDR_WIDTH-1:0] wr_addr_gray;
    reg [ADDR_WIDTH-1:0] rd_addr_gray;
    reg [ADDR_WIDTH-1:0] wr_addr_gray_sync;
    reg [ADDR_WIDTH-1:0] rd_addr_gray_sync;

    reg [ADDR_WIDTH:0] depth;
    reg [ADDR_WIDTH:0] depth_commit;
    reg overflow;
    reg bad_frame;
    reg good_frame;

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;

    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    wire wr_en;
    wire rd_en;

    assign wr_en = s_axis_tvalid & s_axis_tready_reg & ~s_pause_req;
    assign rd_en = m_axis_tready & m_axis_tvalid_reg & ~m_pause_req;

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    assign s_status_depth = depth;
    assign s_status_depth_commit = depth_commit;
    assign s_status_overflow = overflow;
    assign s_status_bad_frame = bad_frame;
    assign s_status_good_frame = good_frame;

    assign m_status_depth = depth;
    assign m_status_depth_commit = depth_commit;
    assign m_status_overflow = overflow;
    assign m_status_bad_frame = bad_frame;
    assign m_status_good_frame = good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_addr <= 0;
            wr_addr_gray <= 0;
            wr_addr_gray_sync <= 0;
            s_axis_tready_reg <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            if (wr_en) begin
                fifo_data[wr_addr] <= s_axis_tdata;
                fifo_keep[wr_addr] <= s_axis_tkeep;
                fifo_last[wr_addr] <= s_axis_tlast;
                if (ID_ENABLE) fifo_id[wr_addr] <= s_axis_tid;
                if (DEST_ENABLE) fifo_dest[wr_addr] <= s_axis_tdest;
                if (USER_ENABLE) fifo_user[wr_addr] <= s_axis_tuser;
                wr_addr <= wr_addr + 1;
                wr_addr_gray <= wr_addr ^ (wr_addr >> 1);
            end
            wr_addr_gray_sync <= wr_addr_gray;
            s_axis_tready_reg <= (wr_addr_gray_sync != rd_addr_gray) & ~overflow;
            s_pause_ack_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_addr <= 0;
            rd_addr_gray <= 0;
            rd_addr_gray_sync <= 0;
            m_axis_tvalid_reg <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            if (rd_en) begin
                rd_addr <= rd_addr + 1;
                rd_addr_gray <= rd_addr ^ (rd_addr >> 1);
            end
            rd_addr_gray_sync <= rd_addr_gray;
            m_axis_tvalid_reg <= (wr_addr_gray_sync != rd_addr_gray_sync);
            m_pause_ack_reg <= m_pause_req;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            depth <= 0;
            depth_commit <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            if (wr_en && !rd_en && (depth < DEPTH)) begin
                depth <= depth + 1;
            end else if (!wr_en && rd_en && (depth > 0)) begin
                depth <= depth - 1;
            end
            depth_commit <= depth;
            overflow <= (wr_en && !rd_en && (depth == DEPTH));
            // Placeholder for bad_frame and good_frame logic
            bad_frame <= 0;
            good_frame <= 0;
        end
    end

    assign m_axis_tdata = fifo_data[rd_addr];
    assign m_axis_tkeep = fifo_keep[rd_addr];
    assign m_axis_tlast = fifo_last[rd_addr];
    assign m_axis_tid = (ID_ENABLE) ? fifo_id[rd_addr] : 0;
    assign m_axis_tdest = (DEST_ENABLE) ? fifo_dest[rd_addr] : 0;
    assign m_axis_tuser = (USER_ENABLE) ? fifo_user[rd_addr] : 0;

endmodule
