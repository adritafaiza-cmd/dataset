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

    localparam S_FIFO_WIDTH = S_DATA_WIDTH + S_KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;
    localparam M_FIFO_WIDTH = M_DATA_WIDTH + M_KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    reg [S_FIFO_WIDTH-1:0] s_fifo_data;
    reg [M_FIFO_WIDTH-1:0] m_fifo_data;
    reg s_fifo_wr_en;
    reg s_fifo_rd_en;
    reg m_fifo_wr_en;
    reg m_fifo_rd_en;
    reg [S_FIFO_WIDTH-1:0] s_fifo_dout;
    reg [M_FIFO_WIDTH-1:0] m_fifo_dout;
    reg [$clog2(DEPTH):0] s_fifo_count;
    reg [$clog2(DEPTH):0] m_fifo_count;
    reg s_fifo_full;
    reg m_fifo_full;
    reg s_fifo_empty;
    reg m_fifo_empty;

    // Asynchronous FIFO
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_FIFO_WIDTH)
    ) s_to_m_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_wr_en(s_fifo_wr_en),
        .s_din(s_fifo_data),
        .s_full(s_fifo_full),
        .s_count(s_fifo_count),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_rd_en(m_fifo_rd_en),
        .m_dout(s_fifo_dout),
        .m_empty(m_fifo_empty),
        .m_count(m_fifo_count)
    );

    // Width Adapter
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH)
    ) width_adapter_inst (
        .s_data(s_fifo_dout[S_DATA_WIDTH-1:0]),
        .s_keep(s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH-1:S_DATA_WIDTH]),
        .s_tlast(s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH]),
        .s_tid(s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH]),
        .s_tdest(s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH]),
        .s_tuser(s_fifo_dout[S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:S_DATA_WIDTH+S_KEEP_WIDTH+ID_WIDTH+DEST_WIDTH]),
        .m_data(m_axis_tdata),
        .m_keep(m_axis_tkeep),
        .m_tlast(m_axis_tlast),
        .m_tid(m_axis_tid),
        .m_tdest(m_axis_tdest),
        .m_tuser(m_axis_tuser)
    );

    // FIFO Write Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_wr_en <= 0;
        end else begin
            s_fifo_wr_en <= s_axis_tvalid && !s_fifo_full && !s_pause_req;
        end
    end

    // FIFO Read Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_fifo_rd_en <= 0;
        end else begin
            m_fifo_rd_en <= m_axis_tready && !m_fifo_empty && !m_pause_req;
        end
    end

    // FIFO Data Assignment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_data <= 0;
        end else if (s_fifo_wr_en) begin
            s_fifo_data <= {s_axis_tuser, s_axis_tdest, s_axis_tid, s_axis_tlast, s_axis_tkeep, s_axis_tdata};
        end
    end

    // AXI-Stream Handshake
    assign s_axis_tready = !s_fifo_full && !s_pause_req;
    assign m_axis_tvalid = !m_fifo_empty && !m_pause_req;

    // Pause Acknowledgment
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status Signals
    assign s_status_depth = s_fifo_count;
    assign s_status_depth_commit = s_fifo_count;
    assign s_status_overflow = s_fifo_full;
    assign s_status_bad_frame = 1'b0; // Placeholder, no bad frame detection implemented
    assign s_status_good_frame = 1'b0; // Placeholder, no good frame detection implemented

    assign m_status_depth = m_fifo_count;
    assign m_status_depth_commit = m_fifo_count;
    assign m_status_overflow = m_fifo_full;
    assign m_status_bad_frame = 1'b0; // Placeholder, no bad frame detection implemented
    assign m_status_good_frame = 1'b0; // Placeholder, no good frame detection implemented

endmodule

// Asynchronous FIFO Module
module axis_async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 32
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire                     s_wr_en,
    input  wire [DATA_WIDTH-1:0]    s_din,
    output reg                      s_full,
    output reg [$clog2(DEPTH):0]    s_count,
    input  wire                     m_clk,
    input  wire                     m_rst,
    input  wire                     m_rd_en,
    output reg [DATA_WIDTH-1:0]     m_dout,
    output reg                      m_empty,
    output reg [$clog2(DEPTH):0]    m_count
);

    reg [$clog2(DEPTH):0] wptr, rptr;
    reg [$clog2(DEPTH):0] wptr_gray, rptr_gray;
    reg [$clog2(DEPTH):0] wptr_gray_sync, rptr_gray_sync;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write Pointer Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (s_wr_en && !s_full) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // Read Pointer Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (m_rd_en && !m_empty) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    // Gray Code Synchronization
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    // Full and Empty Flags
    assign s_full = (wptr_gray_sync == (rptr_gray ^ (rptr_gray >> 1))) && (wptr_gray_sync[$clog2(DEPTH)] != rptr_gray[$clog2(DEPTH)]);
    assign m_empty = (wptr_gray == rptr_gray_sync) && (wptr_gray[$clog2(DEPTH)] == rptr_gray_sync[$clog2(DEPTH)]);

    // FIFO Memory Write
    always @(posedge s_clk) begin
        if (s_wr_en && !s_full) begin
            mem[wptr] <= s_din;
        end
    end

    // FIFO Memory Read
    always @(posedge m_clk) begin
        if (m_rd_en && !m_empty) begin
            m_dout <= mem[rptr];
        end
    end

    // FIFO Count
    assign s_count = wptr - rptr_gray_sync;
    assign m_count = wptr_gray_sync - rptr;

endmodule

// Width Adapter Module
module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1
)
(
    input  wire [S_DATA_WIDTH-1:0]  s_data,
    input  wire [S_KEEP_WIDTH-1:0]  s_keep,
    input  wire                     s_tlast,
    input  wire [7:0]               s_tid,
    input  wire [7:0]               s_tdest,
    input  wire [0:0]               s_tuser,
    output wire [M_DATA_WIDTH-1:0]  m_data,
    output wire [M_KEEP_WIDTH-1:0]  m_keep,
    output wire                     m_tlast,
    output wire [7:0]               m_tid,
    output wire [7:0]               m_tdest,
    output wire [0:0]               m_tuser
);

    assign m_data = s_data;
    assign m_keep = s_keep;
    assign m_tlast = s_tlast;
    assign m_tid = s_tid;
    assign m_tdest = s_tdest;
    assign m_tuser = s_tuser;

endmodule
