module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
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
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signal widths
    localparam KEEP_W = KEEP_ENABLE ? KEEP_WIDTH : 1;
    localparam ID_W   = ID_ENABLE   ? ID_WIDTH   : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_W-1:0]     ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_W-1:0]       ram_id   [0:DEPTH-1];
    reg [DEST_W-1:0]     ram_dest [0:DEPTH-1];
    reg [USER_W-1:0]     ram_user [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // Depth calculation
    wire [$clog2(DEPTH):0] depth = wr_ptr - rd_ptr;
    wire [$clog2(DEPTH):0] depth_commit = depth; // Same for single clock

    // Full/Empty
    wire full  = (depth == DEPTH);
    wire empty = (depth == 0);

    // Pause logic
    reg pause_active;
    wire pause_effective = PAUSE_ENABLE ? pause_active : 1'b0;

    // Frame tracking for FRAME_FIFO
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_count;

    // Status registers
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Write enable
    wire wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire rd_en = m_axis_tvalid && m_axis_tready;

    // Determine if we should accept data
    wire can_accept = !full && !pause_effective;

    // Frame FIFO logic
    wire frame_start = !in_frame;
    wire frame_end   = s_axis_tlast;

    // Check for bad frame based on user sideband
    wire user_bad = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Oversize check: if frame exceeds DEPTH
    wire oversize = FRAME_FIFO && (frame_count >= DEPTH) && !frame_end;

    // Determine if this beat should be dropped
    wire drop_beat = 0;
    wire mark_beat = 0;

    // For DROP_OVERSIZE_FRAME: drop entire frame if it exceeds DEPTH
    // For DROP_BAD_FRAME: drop entire frame if user indicates bad
    // For DROP_WHEN_FULL: drop beat if FIFO is full
    // For MARK_WHEN_FULL: mark beat as bad if FIFO is full

    // Simplified approach: 
    // - If DROP_WHEN_FULL and full, drop the beat (don't write)
    // - If MARK_WHEN_FULL and full, write but mark as bad
    // - If DROP_OVERSIZE_FRAME and frame would exceed DEPTH, drop entire frame
    // - If DROP_BAD_FRAME and user_bad, drop entire frame

    // For frame-based dropping, we need to track if we're in a drop state
    reg drop_frame_active;

    // Reset drop_frame_active when frame ends
    wire drop_frame_clear = frame_end || !in_frame;

    // Determine if we should start dropping a frame
    wire start_drop_frame = 0;
    if (DROP_OVERSIZE_FRAME && oversize) begin
        start_drop_frame = 1;
    end else if (DROP_BAD_FRAME && user_bad && frame_start) begin
        start_drop_frame = 1;
    end

    // Update drop_frame_active
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            drop_frame_active <= 1'b0;
        end else if (drop_frame_clear) begin
            drop_frame_active <= 1'b0;
        end else if (start_drop_frame) begin
            drop_frame_active <= 1'b1;
        end
    end

    // Determine if current beat is dropped
    wire beat_dropped = drop_frame_active || (DROP_WHEN_FULL && full);

    // Determine if current beat is marked as bad
    wire beat_marked = MARK_WHEN_FULL && full;

    // Effective write enable
    wire eff_wr_en = wr_en && !beat_dropped;

    // s_axis_tready
    assign s_axis_tready = can_accept && !drop_frame_active;

    // Write to RAM
    always @(posedge clk) begin
        if (eff_wr_en) begin
            ram_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[wr_ptr[ADDR_WIDTH-1:0]] <= KEEP_ENABLE ? s_axis_tkeep : {KEEP_W{1'b0}};
            ram_last[wr_ptr[ADDR_WIDTH-1:0]] <= LAST_ENABLE ? s_axis_tlast : 1'b0;
            ram_id[wr_ptr[ADDR_WIDTH-1:0]]   <= ID_ENABLE   ? s_axis_tid   : {ID_W{1'b0}};
            ram_dest[wr_ptr[ADDR_WIDTH-1:0]] <= DEST_ENABLE ? s_axis_tdest : {DEST_W{1'b0}};
            ram_user[wr_ptr[ADDR_WIDTH-1:0]] <= USER_ENABLE ? s_axis_tuser : {USER_W{1'b0}};
        end
    end

    // Update write pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (eff_wr_en) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read from RAM
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // Output data
    assign m_axis_tdata = ram_data[rd_addr];
    assign m_axis_tkeep = KEEP_ENABLE ? ram_keep[rd_addr] : {KEEP_W{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? ram_last[rd_addr] : 1'b0;
    assign m_axis_tid   = ID_ENABLE   ? ram_id[rd_addr]   : {ID_W{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? ram_dest[rd_addr] : {DEST_W{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? ram_user[rd_addr] : {USER_W{1'b0}};

    // m_axis_tvalid
    assign m_axis_tvalid = !empty;

    // Update read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (pause_req) begin
                pause_active <= 1'b1;
            end else if (!empty && !full) begin
                // Release pause when FIFO is not empty and not full
                pause_active <= 1'b0;
            end
        end
    end

    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    // Frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 1'b0;
            frame_count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (eff_wr_en) begin
                if (frame_start) begin
                    in_frame <= 1'b1;
                    frame_count <= 1'b1;
                end else if (frame_end) begin
                    in_frame <= 1'b0;
                    frame_count <= {(ADDR_WIDTH+1){1'b0}};
                end else begin
                    frame_count <= frame_count + 1'b1;
                end
            end
        end
    end

    // Status: overflow
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg <= 1'b0;
        end else if (s_axis_tvalid && full) begin
            status_overflow_reg <= 1'b1;
        end
    end

    // Status: bad frame
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_bad_frame_reg <= 1'b0;
        end else if (eff_wr_en && frame_end && (drop_frame_active || (DROP_BAD_FRAME && user_bad))) begin
            status_bad_frame_reg <= 1'b1;
        end
    end

    // Status: good frame
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_good_frame_reg <= 1'b0;
        end else if (eff_wr_en && frame_end && !drop_frame_active && !(DROP_BAD_FRAME && user_bad)) begin
            status_good_frame_reg <= 1'b1;
        end
    end

    assign status_overflow   = status_overflow_reg;
    assign status_bad_frame  = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;
    assign status_depth      = depth;
    assign status_depth_commit = depth_commit;

endmodule
