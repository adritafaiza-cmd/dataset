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

    localparam DEPTH_ADDR = $clog2(DEPTH);
    localparam TOTAL_WIDTH = DATA_WIDTH + 
        (KEEP_ENABLE ? KEEP_WIDTH : 0) +
        (LAST_ENABLE ? 1 : 0) +
        (ID_ENABLE ? ID_WIDTH : 0) +
        (DEST_ENABLE ? DEST_WIDTH : 0) +
        (USER_ENABLE ? USER_WIDTH : 0);

    // FIFO memory
    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain signals
    reg [DEPTH_ADDR:0] wptr_bin = 0;
    reg [DEPTH_ADDR:0] wptr_gray = 0;
    reg [DEPTH_ADDR:0] rptr_gray_sync1 = 0, rptr_gray_sync2 = 0;

    // Read domain signals
    reg [DEPTH_ADDR:0] rptr_bin = 0;
    reg [DEPTH_ADDR:0] rptr_gray = 0;
    reg [DEPTH_ADDR:0] wptr_gray_sync1 = 0, wptr_gray_sync2 = 0;

    // Concatenate input signals
    wire [TOTAL_WIDTH-1:0] s_axis_concat;
    assign s_axis_concat = {s_axis_tdata,
        KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}},
        LAST_ENABLE ? s_axis_tlast : 1'b0,
        ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}},
        DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}},
        USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}
    };

    // Convert Gray to binary
    function [DEPTH_ADDR:0] gray2bin;
        input [DEPTH_ADDR:0] gray;
        integer i;
        begin
            gray2bin[DEPTH_ADDR] = gray[DEPTH_ADDR];
            for (i = DEPTH_ADDR-1; i >= 0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Full and empty conditions
    wire [DEPTH_ADDR:0] rptr_bin_sync = gray2bin(rptr_gray_sync2);
    wire full = ( (wptr_bin - rptr_bin_sync) >= DEPTH );
    wire empty = (rptr_bin == wptr_bin);

    // Write logic
    always @(posedge s_clk) begin
        if (s_rst) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[wptr_bin[DEPTH_ADDR-1:0]] <= s_axis_concat;
            wptr_bin <= wptr_bin + 1;
        end
        wptr_gray <= (wptr_bin >> 1) ^ wptr_bin;
    end

    // Synchronize read pointer to write domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Read logic
    always @(posedge m_clk) begin
        if (m_rst) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rptr_bin <= rptr_bin + 1;
        end
        rptr_gray <= (rptr_bin >> 1) ^ rptr_bin;
    end

    // Synchronize write pointer to read domain
    always @(posedge m_clk) begin
        if (m_rst) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Convert synchronized write pointer to binary
    wire [DEPTH_ADDR:0] wptr_bin_sync = gray2bin(wptr_gray_sync2);

    // Assign outputs
    assign s_axis_tready = !full || (DROP_WHEN_FULL ? 1'b1 : !full);
    assign m_axis_tvalid = !empty;

    // Split memory output
    wire [TOTAL_WIDTH-1:0] m_axis_concat;
    assign m_axis_concat = mem[rptr_bin[DEPTH_ADDR-1:0]];

    assign {m_axis_tdata,
        m_axis_tkeep,
        m_axis_tlast,
        m_axis_tid,
        m_axis_tdest,
        m_axis_tuser} = m_axis_concat;

    // Status signals (simplified)
    assign s_status_depth = wptr_bin - rptr_bin_sync;
    assign m_status_depth = wptr_bin_sync - rptr_bin;

    // Pause signals (stubbed)
    assign s_pause_ack = !s_pause_req;
    assign m_pause_ack = !m_pause_req;

    // Error signals (stubbed)
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

endmodule
