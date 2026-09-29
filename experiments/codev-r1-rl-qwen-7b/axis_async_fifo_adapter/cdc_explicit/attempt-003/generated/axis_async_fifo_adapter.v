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
    // AXI input
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
    // AXI output
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
    // Pause
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    // Status
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

    // FIFO memory and pointers
    reg [S_DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [($clog2(DEPTH)+1)/2-1:0] wr_ptr_gray, rd_ptr_gray;

    // Synchronizers
    reg [($clog2(DEPTH)+1)/2-1:0] wr_ptr_gray_sync_m, rd_ptr_gray_sync_s;

    // Convert gray to binary
    function [$clog2(DEPTH):0] gray2bin;
        input [($clog2(DEPTH)+1)/2-1:0] gray;
        reg [$clog2(DEPTH):0] bin;
        integer i;
        begin
            bin[($clog2(DEPTH))] = gray[($clog2(DEPTH))];
            for (i = ($clog2(DEPTH)-1); i >=0; i = i-1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    wire [$clog2(DEPTH):0] wr_ptr_bin = gray2bin(wr_ptr_gray_sync_m);
    wire full = (wr_ptr_bin - rd_ptr) >= DEPTH;
    wire [$clog2(DEPTH):0] wr_depth = wr_ptr - rd_ptr;

    // Read domain logic
    wire [$clog2(DEPTH):0] rd_ptr_bin = gray2bin(rd_ptr_gray_sync_s);
    wire empty = (wr_ptr_bin == rd_ptr_bin);
    wire [$clog2(DEPTH):0] rd_depth = wr_ptr_bin - rd_ptr_bin;

    // Assign status signals
    assign s_status_depth = wr_depth;
    assign m_status_depth = rd_depth;

    // Write side
    assign s_axis_tready = ~full;

    // Read side
    assign m_axis_tvalid = ~empty;

    // Width conversion logic (simplified example)
    // This is a placeholder; actual implementation requires detailed handling
    assign m_axis_tdata = mem[rd_ptr[$clog2(DEPTH)-1:0]];

    // Tie-off unused signals
    assign m_axis_tkeep = 0;
    assign m_axis_tlast = 0;
    assign m_axis_tid = 0;
    assign m_axis_tdest = 0;
    assign m_axis_tuser = 0;

    // Pause and status assignments (simplified)
    assign s_pause_ack = 0;
    assign m_pause_ack = 0;
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

    // Synchronizers and pointer updates
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tdata;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr + 1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr + 1;
        end
    end

    // Gray code synchronization
    always @(posedge m_clk) begin
        wr_ptr_gray_sync_m <= wr_ptr_gray;
    end

    always @(posedge s_clk) begin
        rd_ptr_gray_sync_s <= rd_ptr_gray;
    end

endmodule
