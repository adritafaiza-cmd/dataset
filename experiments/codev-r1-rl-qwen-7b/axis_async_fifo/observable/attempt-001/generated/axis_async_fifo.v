module axis_async_fifo #(
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
localparam TOTAL_WIDTH = DATA_WIDTH + 
                         (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                         (LAST_ENABLE ? 1 : 0) +
                         (ID_ENABLE ? ID_WIDTH : 0) +
                         (DEST_ENABLE ? DEST_WIDTH : 0) +
                         (USER_ENABLE ? USER_WIDTH : 0);

// Memory
reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];

// Write domain signals
reg [ADDR_WIDTH:0] wptr_bin, wptr_gray;
reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;

// Read domain signals
reg [ADDR_WIDTH:0] rptr_bin, rptr_gray;
reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;

// Full and empty
wire full, empty;

// Gray code conversion
function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
    bin2gray = bin ^ (bin >> 1);
endfunction

// Write pointer logic
always @(posedge s_clk) begin
    if (s_rst) begin
        wptr_bin <= 0;
        wptr_gray <= 0;
        rptr_gray_sync1 <= 0;
        rptr_gray_sync2 <= 0;
    end else begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync1;
        if (s_axis_tvalid && s_axis_tready) begin
            wptr_bin <= wptr_bin + 1;
            wptr_gray <= bin2gray(wptr_bin + 1);
        end
    end
end

// Read pointer logic
always @(posedge m_clk) begin
    if (m_rst) begin
        rptr_bin <= 0;
        rptr_gray <= 0;
        wptr_gray_sync1 <= 0;
        wptr_gray_sync2 <= 0;
    end else begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync1;
        if (m_axis_tvalid && m_axis_tready) begin
            rptr_bin <= rptr_bin + 1;
            rptr_gray <= bin2gray(rptr_bin + 1);
        end
    end
end

// Full and empty conditions
assign full = (wptr_gray == { ~rptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rptr_gray_sync2[ADDR_WIDTH-2:0] });
assign empty = (rptr_gray == wptr_gray_sync2);

// tready assignments
assign s_axis_tready = !full && !s_pause_req;
assign m_axis_tvalid = !empty;

// Pause ack
assign s_pause_ack = s_pause_req && !full;
assign m_pause_ack = m_pause_req && !empty;

// Memory write
always @(posedge s_clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
        mem[wptr_bin[ADDR_WIDTH-1:0]] <= { s_axis_tuser, s_axis_tdest, s_axis_tid, s_axis_tlast, s_axis_tkeep, s_axis_tdata };
    end
end

// Memory read
reg [TOTAL_WIDTH-1:0] m_axis_entry;
always @(posedge m_clk) begin
    if (RAM_PIPELINE) begin
        m_axis_entry <= mem[rptr_bin[ADDR_WIDTH-1:0]];
    end
end

// Assign outputs
assign { m_axis_tuser, m_axis_tdest, m_axis_tid, m_axis_tlast, m_axis_tkeep, m_axis_tdata } = RAM_PIPELINE ? m_axis_entry : mem[rptr_bin[ADDR_WIDTH-1:0]];

// Status signals
assign s_status_depth = wptr_bin;
assign s_status_depth_commit = wptr_bin - rptr_bin;
assign s_status_overflow = 0;
assign s_status_bad_frame = 0;
assign s_status_good_frame = 0;
assign m_status_depth = wptr_bin;
assign m_status_depth_commit = wptr_bin - rptr_bin;
assign m_status_overflow = 0;
assign m_status_bad_frame = 0;
assign m_status_good_frame = 0;

endmodule
