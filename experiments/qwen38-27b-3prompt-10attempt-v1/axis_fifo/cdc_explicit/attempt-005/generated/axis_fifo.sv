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
    localparam DEPTH_POW2 = (DEPTH == (1 << ADDR_WIDTH)) ? DEPTH : (1 << (ADDR_WIDTH + 1));
    localparam DEPTH_MASK = DEPTH_POW2 - 1;

    // Total sideband width
    localparam SIDE_WIDTH = (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                            (LAST_ENABLE ? 1 : 0) +
                            (ID_ENABLE ? ID_WIDTH : 0) +
                            (DEST_ENABLE ? DEST_WIDTH : 0) +
                            (USER_ENABLE ? USER_WIDTH : 0);

    // Combined data + sideband width
    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

    // Internal signals
    wire [TOTAL_WIDTH-1:0] wr_data;
    wire [TOTAL_WIDTH-1:0] rd_data;
    wire                   wr_en;
    wire                   rd_en;
    wire                   full;
    wire                   empty;
    wire [ADDR_WIDTH:0]    depth;

    // Frame tracking
    reg                    in_frame;
    reg                    frame_bad;
    reg                    frame_oversize;
    reg [ADDR_WIDTH:0]     frame_count;

    // Pause logic
    reg                    pause_active;
    reg                    pause_pending;

    // Status latches
    reg                    overflow_latch;
    reg                    bad_frame_latch;
    reg                    good_frame_latch;

    // Build write data
    assign wr_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Extract read data
    wire [DATA_WIDTH-1:0]   rd_tdata   = rd_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0]   rd_tkeep   = KEEP_ENABLE ? rd_data[DATA_WIDTH : DATA_WIDTH+KEEP_WIDTH-1] : {KEEP_WIDTH{1'b0}};
    wire                    rd_tlast   = LAST_ENABLE ? rd_data[DATA_WIDTH+KEEP_WIDTH] : 1'b0;
    wire [ID_WIDTH-1:0]     rd_tid     = ID_ENABLE ? rd_data[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE : DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH-1] : {ID_WIDTH{1'b0}};
    wire [DEST_WIDTH-1:0]   rd_tdest   = DEST_ENABLE ? rd_data[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE : DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_WIDTH-1] : {DEST_WIDTH{1'b0}};
    wire [USER_WIDTH-1:0]   rd_tuser   = USER_ENABLE ? rd_data[TOTAL_WIDTH-USER_WIDTH : TOTAL_WIDTH-1] : {USER_WIDTH{1'b0}};

    // Frame bad detection
    wire user_bad = USER_ENABLE && (rd_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire frame_bad_signal = user_bad;

    // Oversize detection: frame exceeds DEPTH
    wire oversize_signal = (frame_count == DEPTH) && !rd_tlast;

    // Determine if we should drop this beat
    wire drop_beat = (DROP_OVERSIZE_FRAME && frame_oversize) ||
                     (DROP_BAD_FRAME && frame_bad);

    // Write enable: accept data if not full (or drop when full)
    wire can_write = !full || DROP_WHEN_FULL;
    wire write_accepted = s_axis_tvalid && can_write;

    // Pause logic
    wire pause_block = PAUSE_ENABLE && (pause_active || pause_pending);
    wire effective_write = write_accepted && !pause_block;

    // Frame tracking update
    wire frame_start = effective_write && !in_frame;
    wire frame_end   = effective_write && in_frame && rd_tlast;

    // Note: rd_tlast is from the read side, but for frame tracking on write side,
    // we need to track based on what's being written. Let's use s_axis_tlast for write-side tracking.
    wire wr_frame_start = effective_write && !in_frame;
    wire wr_frame_end   = effective_write && in_frame && s_axis_tlast;

    // Frame count
    wire frame_count_inc = effective_write && in_frame;
    wire frame_count_reset = wr_frame_start;

    // Determine if frame is bad on write side
    wire wr_user_bad = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire wr_frame_bad = wr_user_bad;

    // Oversize on write side
    wire wr_oversize = (frame_count >= DEPTH) && !s_axis_tlast;

    // Drop decision on write side
    wire wr_drop = (DROP_OVERSIZE_FRAME && frame_oversize) ||
                   (DROP_BAD_FRAME && frame_bad);

    // Actually, let's simplify: we track frame state on the write side
    // and use that to decide whether to accept beats.

    // Revised approach:
    // - in_frame: are we currently in a frame?
    // - frame_bad: is the current frame marked bad?
    // - frame_oversize: has the current frame exceeded DEPTH?

    // Write enable considering frame drops
    wire accept_beat = s_axis_tvalid && !pause_block &&
                       (!full || DROP_WHEN_FULL) &&
                       (!wr_drop);

    // Update frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame       <= 1'b0;
            frame_bad      <= 1'b0;
            frame_oversize <= 1'b0;
            frame_count    <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (accept_beat) begin
                if (!in_frame) begin
                    // Start of new frame
                    in_frame       <= 1'b1;
                    frame_bad      <= wr_frame_bad;
                    frame_oversize <= 1'b0;
                    frame_count    <= 1;
                end else begin
                    // Continue frame
                    if (s_axis_tlast) begin
                        // End of frame
                        in_frame       <= 1'b0;
                        frame_bad      <= 1'b0;
                        frame_oversize <= 1'b0;
                        frame_count    <= {(ADDR_WIDTH+1){1'b0}};
                    end else begin
                        // Check for oversize
                        if (frame_count >= DEPTH) begin
                            frame_oversize <= 1'b1;
                        end
                        frame_count <= frame_count + 1;
                        // Update bad flag if new beat is bad
                        if (wr_frame_bad) begin
                            frame_bad <= 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Recalculate wr_drop with updated logic
    wire wr_drop_final = (DROP_OVERSIZE_FRAME && frame_oversize) ||
                         (DROP_BAD_FRAME && frame_bad);

    // Final write enable
    wire final_write_en = s_axis_tvalid && !pause_block &&
                          (!full || DROP_WHEN_FULL) &&
                          !wr_drop_final;

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active  <= 1'b0;
            pause_pending <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (pause_req) begin
                    pause_pending <= 1'b1;
                end else begin
                    pause_pending <= 1'b0;
                end

                if (FRAME_PAUSE) begin
                    // Pause at frame boundary
                    if (pause_pending && !in_frame) begin
                        pause_active <= 1'b1;
                    end else if (!pause_req) begin
                        pause_active <= 1'b0;
                    end
                end else begin
                    // Immediate pause
                    if (pause_req) begin
                        pause_active <= 1'b1;
                    end else begin
                        pause_active <= 1'b0;
                    end
                end
            end else begin
                pause_active  <= 1'b0;
                pause_pending <= 1'b0;
            end
        end
    end

    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            overflow_latch   <= 1'b0;
            bad_frame_latch  <= 1'b0;
            good_frame_latch <= 1'b0;
        end else begin
            // Overflow: tried to write when full and not dropping
            if (s_axis_tvalid && full && !DROP_WHEN_FULL && !pause_block) begin
                overflow_latch <= 1'b1;
            end

            // Bad frame: frame ended and was bad
            if (final_write_en && in_frame && s_axis_tlast && frame_bad) begin
                bad_frame_latch <= 1'b1;
            end

            // Good frame: frame ended and was not bad
            if (final_write_en && in_frame && s_axis_tlast && !frame_bad) begin
                good_frame_latch <= 1'b1;
            end
        end
    end

    assign status_overflow   = overflow_latch;
    assign status_bad_frame  = bad_frame_latch;
    assign status_good_frame = good_frame_latch;

    // FIFO core
    // Simple synchronous FIFO using dual-port RAM
    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH_POW2-1];
    reg [ADDR_WIDTH-1:0]  wr_ptr;
    reg [ADDR_WIDTH-1:0]  rd_ptr;
    reg [ADDR_WIDTH:0]    wr_count;

    // Write
    always @(posedge clk) begin
        if (final_write_en) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read
    wire rd_valid = !empty && m_axis_tready;
    always @(posedge clk) begin
        if (rd_valid) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Depth tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            case ({final_write_en, rd_valid})
                2'b10:   wr_count <= wr_count + 1;
                2'b01:   wr_count <= wr_count - 1;
                default: wr_count <= wr_count;
            endcase
        end
    end

    assign full  = (wr_count == DEPTH);
    assign empty = (wr_count == 0);
    assign depth = wr_count;

    // Output
    assign m_axis_tdata  = rd_tdata;
    assign m_axis_tkeep  = rd_tkeep;
    assign m_axis_tvalid = !empty;
    assign m_axis_tlast  = rd_tlast;
    assign m_axis_tid    = rd_tid;
    assign m_axis_tdest  = rd_tdest;
    assign m_axis_tuser  = rd_tuser;

    // Input ready
    assign s_axis_tready = !full || DROP_WHEN_FULL;

    // Status depth
    assign status_depth        = depth;
    assign status_depth_commit = depth;

    // Read data from memory
    assign rd_data = mem[rd_ptr];

endmodule
