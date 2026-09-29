module axis_async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH > 8),
    parameter KEEP_WIDTH = ((DATA_WIDTH + 7) / 8),
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
) (
    // AXI Stream Input
    input wire s_clk,
    input wire s_rst,
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,

    // AXI Stream Output
    input wire m_clk,
    input wire m_rst,
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [ID_WIDTH-1:0] m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser,

    // Pause
    input wire s_pause_req,
    output wire s_pause_ack,
    input wire m_pause_req,
    output wire m_pause_ack,

    // Status
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire s_status_overflow,
    output wire s_status_bad_frame,
    output wire s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire m_status_overflow,
    output wire m_status_bad_frame,
    output wire m_status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_m [1:0];
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_s [1:0];
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain logic
    wire full = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_gray_sync_s[ADDR_WIDTH-1:0]) && (wr_ptr[ADDR_WIDTH] != rd_ptr_gray_sync_s[ADDR_WIDTH]);
    assign s_axis_tready = !full || (MARK_WHEN_FULL && ...); // Simplified

    // Read domain logic
    wire empty = (rd_ptr == wr_ptr_gray_sync_m[1]);
    assign m_axis_tvalid = !empty;

    // Memory write
    always @(posedge s_clk) begin
        if (s_axis_tvalid && s_axis_tready)
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
    end

    // Memory read
    assign m_axis_tdata = mem[rd_ptr[ADDR_WIDTH-1:0]];

    // Pointer updates
    always @(posedge s_clk) if (s_rst) wr_ptr <= 0; else if (s_axis_tvalid && s_axis_tready) wr_ptr <= wr_ptr + 1;
    always @(posedge m_clk) if (m_rst) rd_ptr <= 0; else if (m_axis_tvalid && m_axis_tready) rd_ptr <= rd_ptr + 1;

    // Gray code conversions
    always @(*) begin
        wr_ptr_gray = wr_ptr >> 1 ^ wr_ptr;
        rd_ptr_gray = rd_ptr >> 1 ^ rd_ptr;
    end

    // Synchronizers
    always @(posedge m_clk) begin
        if (m_rst) {wr_ptr_gray_sync_m[0], wr_ptr_gray_sync_m[1]} <= 0;
        else {wr_ptr_gray_sync_m[0], wr_ptr_gray_sync_m[1]} <= {wr_ptr_gray, wr_ptr_gray_sync_m[0]};
    end

    always @(posedge s_clk) begin
        if (s_rst) {rd_ptr_gray_sync_s[0], rd_ptr_gray_sync_s[1]} <= 0;
        else {rd_ptr_gray_sync_s[0], rd_ptr_gray_sync_s[1]} <= {rd_ptr_gray, rd_ptr_gray_sync_s[0]};
    end

    // Status signals (simplified)
    assign s_status_depth = wr_ptr - rd_ptr_gray_sync_s[ADDR_WIDTH:0];
    assign m_status_depth = wr_ptr_gray_sync_m[1] - rd_ptr;

    // Tie-off unused signals
    assign s_pause_ack = 0;
    assign m_pause_ack = 0;
    assign s_status_depth_commit = 0;
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_depth_commit = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

    // Tie-off sideband signals
    assign m_axis_tkeep = KEEP_ENABLE ? s_axis_tkeep : 0;
    assign m_axis_tlast = LAST_ENABLE ? s_axis_tlast : 0;
    assign m_axis_tid = ID_ENABLE ? s_axis_tid : 0;
    assign m_axis_tdest = DEST_ENABLE ? s_axis_tdest : 0;
    assign m_axis_tuser = USER_ENABLE ? s_axis_tuser : 0;

endmodule
