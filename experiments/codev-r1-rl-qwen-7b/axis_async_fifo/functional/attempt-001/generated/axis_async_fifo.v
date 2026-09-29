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
)(
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
    localparam STATUS_WIDTH = ADDR_WIDTH + 1;

    // FIFO memory arrays
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];
    reg                  mem_last [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wptr, rptr;

    // Gray code conversions
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronization registers
    reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;
    reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;

    // Convert Gray to binary
    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >=0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Synchronized pointers
    reg [ADDR_WIDTH:0] rptr_sync_bin, wptr_sync_bin;

    // Full and empty conditions
    wire full, empty;

    // Write domain logic
    wire s_axis_tready_internal;
    assign s_axis_tready_internal = !full;

    // Read domain logic
    wire m_axis_tvalid_internal;
    assign m_axis_tvalid_internal = !empty;

    // Assign outputs
    assign s_axis_tready = s_axis_tready_internal;
    assign m_axis_tvalid = m_axis_tvalid_internal;

    // Status signals
    assign s_status_depth = wptr - rptr_sync_bin;
    assign m_status_depth = wptr_sync_bin - rptr;

    // Data output
    assign m_axis_tdata = mem_data[rptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = (KEEP_ENABLE) ? mem_keep[rptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tlast = (LAST_ENABLE) ? mem_last[rptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tid = (ID_ENABLE) ? mem_id[rptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tdest = (DEST_ENABLE) ? mem_dest[rptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tuser = (USER_ENABLE) ? mem_user[rptr[ADDR_WIDTH-1:0]] : 0;

    // Write pointer update
    always @(posedge s_clk) begin
        if (s_rst) begin
            wptr <= 0;
        end else if (s_axis_tvalid && s_axis_tready_internal) begin
            mem_data[wptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            if (KEEP_ENABLE) mem_keep[wptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            if (ID_ENABLE) mem_id[wptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            if (DEST_ENABLE) mem_dest[wptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            if (USER_ENABLE) mem_user[wptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
            if (LAST_ENABLE) mem_last[wptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            wptr <= wptr + 1;
        end
    end

    // Read pointer update
    always @(posedge m_clk) begin
        if (m_rst) begin
            rptr <= 0;
        end else if (m_axis_tvalid_internal && m_axis_tready) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversions
    wire [ADDR_WIDTH:0] wptr_gray = bin2gray(wptr);
    wire [ADDR_WIDTH:0] rptr_gray = bin2gray(rptr);

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

    // Convert synchronized Gray pointers to binary
    always @* begin
        rptr_sync_bin = gray2bin(rptr_gray_sync2);
        wptr_sync_bin = gray2bin(wptr_gray_sync2);
    end

    // Full and empty conditions
    assign full = ( (wptr[ADDR_WIDTH] != rptr_sync_bin[ADDR_WIDTH]) &&
                    (wptr[ADDR_WIDTH-1:0] == rptr_sync_bin[ADDR_WIDTH-1:0]) );

    assign empty = (wptr_sync_bin == rptr);

    // Pause signals (simplified)
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status overflow (placeholder)
    assign s_status_overflow = 0;
    assign m_status_overflow = 0;

    // Status frames (placeholder)
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

    // Depth commit (placeholder)
    assign s_status_depth_commit = s_status_depth;
    assign m_status_depth_commit = m_status_depth;

endmodule
