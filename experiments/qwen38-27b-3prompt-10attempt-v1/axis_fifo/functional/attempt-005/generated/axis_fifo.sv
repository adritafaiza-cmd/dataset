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

    // Internal signals
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] rd_ptr_commit;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];

    // Frame tracking
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_start_ptr;
    reg [ADDR_WIDTH:0] frame_len;

    // Status registers
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Pause logic
    reg pause_active;
    reg pause_at_frame_end;

    // Write enable
    wire wr_en = s_axis_tvalid & s_axis_tready;
    wire rd_en = m_axis_tvalid & m_axis_tready;

    // Full/Empty logic
    wire [ADDR_WIDTH:0] depth = wr_ptr - rd_ptr;
    wire full = (depth == DEPTH);
    wire empty = (depth == 0);

    // Frame oversize detection
    wire frame_oversize_now = FRAME_FIFO && in_frame && (frame_len == DEPTH) && !s_axis_tlast;

    // Determine if we should accept the write
    wire accept_write = wr_en && !full && !frame_oversize_now;

    // Determine if frame is bad
    wire is_bad_frame = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Update frame_bad when we see a bad beat
    wire mark_bad = accept_write && is_bad_frame;

    // Determine if we should drop the frame
    wire drop_frame = (DROP_OVERSIZE_FRAME && frame_oversize_now) || 
                      (DROP_BAD_FRAME && in_frame && frame_bad && s_axis_tlast);

    // Determine if we should mark when full
    wire mark_full = MARK_WHEN_FULL && full && wr_en;

    // Pause logic
    wire pause_now = PAUSE_ENABLE && pause_req;
    wire pause_at_last = FRAME_PAUSE && pause_now && in_frame && s_axis_tlast;

    // s_axis_tready logic
    assign s_axis_tready = !full && !pause_active && !frame_oversize_now;

    // Write pointer update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (accept_write) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_commit <= 0;
        end else begin
            rd_ptr_commit <= rd_ptr;
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Memory write
    always @(posedge clk) begin
        if (accept_write) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            keep_mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            last_mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            id_mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            dest_mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            user_mem[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame <= 0;
            frame_bad <= 0;
            frame_oversize <= 0;
            frame_start_ptr <= 0;
            frame_len <= 0;
        end else begin
            if (accept_write) begin
                if (!in_frame) begin
                    in_frame <= 1;
                    frame_bad <= 0;
                    frame_oversize <= 0;
                    frame_start_ptr <= wr_ptr;
                    frame_len <= 1;
                end else begin
                    frame_len <= frame_len + 1;
                    if (mark_bad) begin
                        frame_bad <= 1;
                    end
                    if (frame_oversize_now) begin
                        frame_oversize <= 1;
                    end
                    if (s_axis_tlast) begin
                        in_frame <= 0;
                    end
                end
            end
        end
    end

    // Status registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            if (mark_full) begin
                status_overflow_reg <= 1;
            end
            if (mark_bad) begin
                status_bad_frame_reg <= 1;
            end
            // Good frame: frame completed without bad or oversize
            if (accept_write && s_axis_tlast && in_frame && !frame_bad && !frame_oversize) begin
                status_good_frame_reg <= 1;
            end
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 0;
            pause_at_frame_end <= 0;
        end else begin
            if (pause_now) begin
                if (FRAME_PAUSE && in_frame) begin
                    pause_at_frame_end <= 1;
                end else begin
                    pause_active <= 1;
                end
            end else begin
                pause_at_frame_end <= 0;
                if (pause_active) begin
                    if (!FRAME_PAUSE || !in_frame) begin
                        pause_active <= 0;
                    end
                end
            end
        end
    end

    // Pause ack
    assign pause_ack = pause_active || (FRAME_PAUSE && pause_at_frame_end && in_frame);

    // Output logic
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    assign m_axis_tdata = mem[rd_addr];
    assign m_axis_tkeep = keep_mem[rd_addr];
    assign m_axis_tlast = last_mem[rd_addr];
    assign m_axis_tid = id_mem[rd_addr];
    assign m_axis_tdest = dest_mem[rd_addr];
    assign m_axis_tuser = user_mem[rd_addr];

    assign m_axis_tvalid = !empty;

    // Status outputs
    assign status_depth = depth;
    assign status_depth_commit = wr_ptr - rd_ptr_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

endmodule
