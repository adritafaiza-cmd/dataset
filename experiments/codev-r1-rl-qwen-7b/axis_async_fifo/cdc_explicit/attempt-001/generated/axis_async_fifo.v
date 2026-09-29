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
    // AXI input
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
    // AXI output
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
    // Pause
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    // Status
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
    localparam TOTAL_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // FIFO memory
    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wptr, rptr; // Extra bit for full/empty detection
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;

    // Synchronization registers
    reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;
    reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;

    // Write domain signals
    wire full;
    wire [ADDR_WIDTH-1:0] waddr = wptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] raddr = rptr[ADDR_WIDTH-1:0];

    // Read domain signals
    wire empty;
    wire [TOTAL_WIDTH-1:0] dout;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Write pointer update
    always @(posedge s_clk) begin
        if (s_rst) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            wptr <= wptr + 1;
            wptr_gray <= bin2gray(wptr + 1);
            mem[waddr] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
        end
    end

    // Read pointer update
    always @(posedge m_clk) begin
        if (m_rst) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rptr <= rptr + 1;
            rptr_gray <= bin2gray(rptr + 1);
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge s_clk) begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync1;
    end

    // Synchronize write pointer to read domain
    always @(posedge m_clk) begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync1;
    end

    // Full and empty conditions
    assign full = (wptr[ADDR_WIDTH-1:0] == rptr_gray_sync2[ADDR_WIDTH-1:0]) && (wptr[ADDR_WIDTH] != rptr_gray_sync2[ADDR_WIDTH]);
    assign empty = (wptr_gray_sync2 == rptr_gray);

    // Assign outputs
    assign s_axis_tready = !full || DROP_WHEN_FULL;

    // Read data
    assign {m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser} = mem[raddr];

    // Status signals (simplified)
    assign s_status_depth = wptr - rptr_gray_sync2;
    assign m_status_depth = wptr_gray_sync2 - rptr;

    // Pause handling (simplified)
    assign s_pause_ack = !full;
    assign m_pause_ack = !empty;

endmodule
