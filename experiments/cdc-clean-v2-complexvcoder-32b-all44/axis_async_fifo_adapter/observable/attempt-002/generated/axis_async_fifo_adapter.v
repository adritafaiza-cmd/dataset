module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    // Internal signals
    wire [S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_wr_data;
    wire fifo_wr_en;
    wire fifo_full;
    wire fifo_empty;
    wire [M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_rd_data;
    wire fifo_rd_en;

    // Status signals
    wire [$clog2(DEPTH):0] s_wr_depth;
    wire [$clog2(DEPTH):0] m_rd_depth;

    // FIFO instantiation
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH)
    ) fifo_inst (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .wr_data(fifo_wr_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        .empty(fifo_empty),
        .rd_data(fifo_rd_data),
        .rd_en(fifo_rd_en),
        .wr_depth(s_wr_depth),
        .rd_depth(m_rd_depth)
    );

    // Write side logic
    assign fifo_wr_data = {s_axis_tid, s_axis_tdest, s_axis_tuser, s_axis_tlast, s_axis_tkeep, s_axis_tdata};
    assign fifo_wr_en = s_axis_tvalid & ~fifo_full;
    assign s_axis_tready = ~fifo_full;

    // Read side logic
    assign m_axis_tdata = fifo_rd_data[0+:M_DATA_WIDTH];
    assign m_axis_tkeep = fifo_rd_data[M_DATA_WIDTH+:M_KEEP_WIDTH];
    assign m_axis_tlast = fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH];
    assign m_axis_tid = fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+:ID_WIDTH];
    assign m_axis_tdest = fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+:DEST_WIDTH];
    assign m_axis_tuser = fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+:USER_WIDTH];
    assign fifo_rd_en = m_axis_tready & ~fifo_empty;
    assign m_axis_tvalid = ~fifo_empty;

    // Status assignments
    assign s_status_depth = s_wr_depth;
    assign s_status_depth_commit = s_wr_depth;
    assign s_status_overflow = fifo_full;
    assign s_status_bad_frame = 1'b0; // Not implemented
    assign s_status_good_frame = 1'b0; // Not implemented
    assign m_status_depth = m_rd_depth;
    assign m_status_depth_commit = m_rd_depth;
    assign m_status_overflow = fifo_full;
    assign m_status_bad_frame = 1'b0; // Not implemented
    assign m_status_good_frame = 1'b0; // Not implemented

    // Pause signals (not implemented)
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 32
)
(
    input  wire                     clk_wr,
    input  wire                     rst_wr,
    input  wire                     clk_rd,
    input  wire                     rst_rd,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire                     wr_en,
    output wire                     full,
    output wire                     empty,
    output wire [DATA_WIDTH-1:0]    rd_data,
    input  wire                     rd_en,
    output wire [$clog2(DEPTH):0]   wr_depth,
    output wire [$clog2(DEPTH):0]   rd_depth
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write side logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
        end else if (wr_en & ~full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read side logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
        end else if (rd_en & ~empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Gray code synchronization
    always @(posedge clk_wr) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    always @(posedge clk_rd) begin
        rd_ptr_gray_sync <= rd_ptr_gray;
    end

    // Full and empty flags
    assign full = (wr_ptr_gray[ADDR_WIDTH] != rd_ptr_gray_sync[ADDR_WIDTH]) & (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr_gray_sync[ADDR_WIDTH] == rd_ptr_gray[ADDR_WIDTH]) & (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);

    // Read data
    assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];

    // Depth counters
    assign wr_depth = wr_ptr - rd_ptr_gray_sync;
    assign rd_depth = rd_ptr - wr_ptr_gray_sync;

endmodule
