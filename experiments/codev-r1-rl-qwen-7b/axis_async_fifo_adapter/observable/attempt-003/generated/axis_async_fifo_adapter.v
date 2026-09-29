module axis_async_fifo_adapter #(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH > 8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH + 7) / 8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH > 8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH + 7) / 8),
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

    // Local parameters for width conversion
    localparam integer S_WORDS_PER_M = (M_DATA_WIDTH + S_DATA_WIDTH - 1) / S_DATA_WIDTH;
    localparam integer M_WORDS_PER_S = S_DATA_WIDTH / M_DATA_WIDTH;

    // FIFO memory and pointers
    reg [S_DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [($clog2(DEPTH))-1:0] wptr, rptr;

    // Gray code synchronization
    reg [($clog2(DEPTH))-1:0] wptr_gray, rptr_gray;
    reg [($clog2(DEPTH))-1:0] wptr_sync1, wptr_sync2;
    reg [($clog2(DEPTH))-1:0] rptr_sync1, rptr_sync2;

    // Available entries calculation
    wire [$clog2(DEPTH):0] available_entries_s;
    wire [$clog2(DEPTH):0] available_entries_m;

    // Full and empty flags
    wire full;
    wire empty;

    // Write side logic
    assign s_axis_tready = !full;

    // Read side logic
    assign m_axis_tvalid = !empty;

    // Width conversion buffers
    reg [S_DATA_WIDTH-1:0] read_buffer;
    reg [31:0] read_count;

    // Pause and drop signals
    assign s_pause_ack = s_pause_req && !full;
    assign m_pause_ack = m_pause_req && !empty;

    // Status signals (simplified)
    assign s_status_depth = wptr;
    assign m_status_depth = rptr;

    // FIFO write pointer update
    always @(posedge s_clk) begin
        if (s_rst) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[wptr] <= s_axis_tdata;
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // FIFO read pointer update
    always @(posedge m_clk) begin
        if (m_rst) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rptr <= rptr + read_count;
            rptr_gray <= (rptr + read_count) ^ ((rptr + read_count) >> 1);
        end
    end

    // Synchronize pointers across clock domains
    always @(posedge s_clk) begin
        if (s_rst) begin
            rptr_sync1 <= 0;
            rptr_sync2 <= 0;
        end else begin
            rptr_sync1 <= rptr_gray;
            rptr_sync2 <= rptr_sync1;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            wptr_sync1 <= 0;
            wptr_sync2 <= 0;
        end else begin
            wptr_sync1 <= wptr_gray;
            wptr_sync2 <= wptr_sync1;
        end
    end

    // Available entries calculation
    assign available_entries_s = (wptr >= gray2bin(rptr_sync2)) ? (wptr - gray2bin(rptr_sync2)) : (DEPTH - gray2bin(rptr_sync2) + wptr);
    assign available_entries_m = (gray2bin(wptr_sync2) >= rptr) ? (gray2bin(wptr_sync2) - rptr) : (DEPTH - rptr + gray2bin(wptr_sync2));

    // Full and empty conditions
    assign full = (available_entries_s >= DEPTH);
    assign empty = (available_entries_m == 0);

    // Read buffer logic
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_count <= 0;
            read_buffer <= 0;
        end else begin
            if (read_count == 0 && !empty) begin
                read_buffer <= mem[rptr];
                read_count <= M_WORDS_PER_S;
            end else if (read_count > 0) begin
                read_count <= read_count - 1;
            end
        end
    end

    // Output data assignment
    assign m_axis_tdata = read_buffer[(read_count-1)*M_DATA_WIDTH +: M_DATA_WIDTH];

    // Tie-off unused signals
    assign m_axis_tkeep = 0;
    assign m_axis_tlast = 0;
    assign m_axis_tid = 0;
    assign m_axis_tdest = 0;
    assign m_axis_tuser = 0;

endmodule
