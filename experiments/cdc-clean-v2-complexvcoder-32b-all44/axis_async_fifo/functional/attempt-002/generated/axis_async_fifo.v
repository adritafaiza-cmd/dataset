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

reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
reg [LAST_ENABLE-1:0] mem_last [0:DEPTH-1];
reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
reg [ADDR_WIDTH:0] wr_ptr_sync, rd_ptr_sync;

reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

reg [ADDR_WIDTH:0] s_depth, m_depth;

reg s_axis_tready_reg;
reg m_axis_tvalid_reg;

reg s_status_overflow_reg;
reg s_status_bad_frame_reg;
reg s_status_good_frame_reg;

reg m_status_overflow_reg;
reg m_status_bad_frame_reg;
reg m_status_good_frame_reg;

reg [ADDR_WIDTH:0] s_status_depth_reg;
reg [ADDR_WIDTH:0] s_status_depth_commit_reg;
reg [ADDR_WIDTH:0] m_status_depth_reg;
reg [ADDR_WIDTH:0] m_status_depth_commit_reg;

assign s_axis_tready = s_axis_tready_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;

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

assign s_pause_ack = 1'b0;
assign m_pause_ack = 1'b0;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
        s_axis_tready_reg <= 1'b0;
        s_status_overflow_reg <= 1'b0;
        s_status_bad_frame_reg <= 1'b0;
        s_status_good_frame_reg <= 1'b0;
        s_status_depth_reg <= 0;
        s_status_depth_commit_reg <= 0;
    end else begin
        reg [ADDR_WIDTH:0] wr_ptr_next;
        reg [ADDR_WIDTH:0] wr_ptr_gray_next;
        reg [ADDR_WIDTH:0] rd_ptr_sync_next;
        reg [ADDR_WIDTH:0] rd_ptr_gray_sync_next;
        reg [ADDR_WIDTH:0] s_depth_next;

        wr_ptr_next = wr_ptr;
        wr_ptr_gray_next = wr_ptr_gray;
        rd_ptr_sync_next = rd_ptr_gray_sync;
        rd_ptr_gray_sync_next = rd_ptr_gray_sync;
        s_depth_next = s_depth;

        if (s_axis_tvalid && s_axis_tready_reg) begin
            mem_data[wr_ptr] <= s_axis_tdata;
            mem_keep[wr_ptr] <= s_axis_tkeep;
            mem_last[wr_ptr] <= s_axis_tlast;
            mem_id[wr_ptr] <= s_axis_tid;
            mem_dest[wr_ptr] <= s_axis_tdest;
            mem_user[wr_ptr] <= s_axis_tuser;

            wr_ptr_next = wr_ptr + 1;
            wr_ptr_gray_next = wr_ptr_next ^ (wr_ptr_next >> 1);
        end

        rd_ptr_sync_next = rd_ptr_gray_sync;
        rd_ptr_gray_sync_next = rd_ptr_gray;

        if (rd_ptr_sync_next != rd_ptr_gray_sync) begin
            rd_ptr_sync_next = rd_ptr_gray_sync;
        end

        s_depth_next = wr_ptr_gray_next - rd_ptr_sync_next;

        wr_ptr <= wr_ptr_next;
        wr_ptr_gray <= wr_ptr_gray_next;
        rd_ptr_gray_sync <= rd_ptr_gray_sync_next;
        s_depth <= s_depth_next;

        if (s_depth_next >= DEPTH) begin
            s_axis_tready_reg <= 1'b0;
            s_status_overflow_reg <= 1'b1;
        end else begin
            s_axis_tready_reg <= 1'b1;
            s_status_overflow_reg <= 1'b0;
        end

        s_status_depth_reg <= s_depth_next;
        s_status_depth_commit_reg <= s_depth_next;
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        m_axis_tvalid_reg <= 1'b0;
        m_status_bad_frame_reg <= 1'b0;
        m_status_good_frame_reg <= 1'b0;
        m_status_depth_reg <= 0;
        m_status_depth_commit_reg <= 0;
    end else begin
        reg [ADDR_WIDTH:0] rd_ptr_next;
        reg [ADDR_WIDTH:0] rd_ptr_gray_next;
        reg [ADDR_WIDTH:0] wr_ptr_sync_next;
        reg [ADDR_WIDTH:0] wr_ptr_gray_sync_next;
        reg [ADDR_WIDTH:0] m_depth_next;

        rd_ptr_next = rd_ptr;
        rd_ptr_gray_next = rd_ptr_gray;
        wr_ptr_sync_next = wr_ptr_gray_sync;
        wr_ptr_gray_sync_next = wr_ptr_gray_sync;
        m_depth_next = m_depth;

        if (m_axis_tvalid_reg && m_axis_tready) begin
            rd_ptr_next = rd_ptr + 1;
            rd_ptr_gray_next = rd_ptr_next ^ (rd_ptr_next >> 1);
        end

        wr_ptr_sync_next = wr_ptr_gray_sync;
        wr_ptr_gray_sync_next = wr_ptr_gray;

        if (wr_ptr_sync_next != wr_ptr_gray_sync) begin
            wr_ptr_sync_next = wr_ptr_gray_sync;
        end

        m_depth_next = wr_ptr_sync_next - rd_ptr_gray_next;

        rd_ptr <= rd_ptr_next;
        rd_ptr_gray <= rd_ptr_gray_next;
        wr_ptr_gray_sync <= wr_ptr_gray_sync_next;
        m_depth <= m_depth_next;

        m_axis_tdata <= mem_data[rd_ptr];
        m_axis_tkeep <= mem_keep[rd_ptr];
        m_axis_tlast <= mem_last[rd_ptr];
        m_axis_tid <= mem_id[rd_ptr];
        m_axis_tdest <= mem_dest[rd_ptr];
        m_axis_tuser <= mem_user[rd_ptr];

        if (m_depth_next > 0) begin
            m_axis_tvalid_reg <= 1'b1;
        end else begin
            m_axis_tvalid_reg <= 1'b0;
        end

        m_status_depth_reg <= m_depth_next;
        m_status_depth_commit_reg <= m_depth_next;
    end
end

endmodule
