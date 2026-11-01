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
    wire [DATA_WIDTH-1:0] ram_dout;
    wire [KEEP_WIDTH-1:0] ram_keep_dout;
    wire                   ram_last_dout;
    wire [ID_WIDTH-1:0]    ram_tid_dout;
    wire [DEST_WIDTH-1:0]  ram_tdest_dout;
    wire [USER_WIDTH-1:0]  ram_tuser_dout;

    // Write pointer and read pointer
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser [0:DEPTH-1];

    // Frame tracking
    reg                  in_frame;
    reg [ADDR_WIDTH:0]   frame_start_ptr;
    reg                  frame_overflow;
    reg                  frame_bad;

    // Status registers
    reg                  status_overflow_reg;
    reg                  status_bad_frame_reg;
    reg                  status_good_frame_reg;

    // Pause logic
    reg                  pause_active;

    // Write enable
    wire wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire rd_en = m_axis_tvalid && m_axis_tready;

    // Full and empty
    wire full = (wr_ptr == rd_ptr) && (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);
    wire empty = (wr_ptr == rd_ptr);

    // Depth calculation
    wire [$clog2(DEPTH):0] depth = wr_ptr - rd_ptr;

    // Frame size tracking
    reg [ADDR_WIDTH:0] frame_size;

    // Determine if current beat is the last beat of a frame
    wire is_last_beat = s_axis_tlast;

    // Check if frame is oversized
    wire frame_oversized = (frame_size + 1 > DEPTH);

    // Determine if we should drop the frame
    wire drop_frame = (DROP_OVERSIZE_FRAME && frame_oversized) || 
                      (DROP_BAD_FRAME && frame_bad);

    // Determine if we should mark the frame as bad
    wire mark_frame = (MARK_WHEN_FULL && full);

    // Determine if we should drop when full
    wire drop_when_full = (DROP_WHEN_FULL && full);

    // Effective write enable
    wire eff_wr_en = wr_en && !drop_frame && !drop_when_full;

    // Determine if this beat completes a frame
    wire frame_complete = eff_wr_en && is_last_beat;

    // Determine if this beat starts a new frame
    wire frame_start = eff_wr_en && !in_frame;

    // Update in_frame status
    always @(posedge clk or posedge rst) begin
        if (rst)
            in_frame <= 1'b0;
        else if (frame_complete)
            in_frame <= 1'b0;
        else if (frame_start)
            in_frame <= 1'b1;
    end

    // Update frame size
    always @(posedge clk or posedge rst) begin
        if (rst)
            frame_size <= 0;
        else if (frame_complete)
            frame_size <= 0;
        else if (eff_wr_en)
            frame_size <= frame_size + 1;
    end

    // Update frame_bad status
    always @(posedge clk or posedge rst) begin
        if (rst)
            frame_bad <= 1'b0;
        else if (frame_complete)
            frame_bad <= 1'b0;
        else if (eff_wr_en && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
            frame_bad <= 1'b1;
    end

    // Update frame_start_ptr
    always @(posedge clk or posedge rst) begin
        if (rst)
            frame_start_ptr <= 0;
        else if (frame_start)
            frame_start_ptr <= wr_ptr;
    end

    // Update frame_overflow
    always @(posedge clk or posedge rst) begin
        if (rst)
            frame_overflow <= 1'b0;
        else if (frame_complete)
            frame_overflow <= 1'b0;
        else if (eff_wr_en && frame_oversized)
            frame_overflow <= 1'b1;
    end

    // Write to RAM
    always @(posedge clk) begin
        if (eff_wr_en) begin
            ram_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            ram_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_tid[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            ram_tdest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            ram_tuser[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Read from RAM
    always @(posedge clk) begin
        ram_dout <= ram_data[rd_ptr[ADDR_WIDTH-1:0]];
        ram_keep_dout <= ram_keep[rd_ptr[ADDR_WIDTH-1:0]];
        ram_last_dout <= ram_last[rd_ptr[ADDR_WIDTH-1:0]];
        ram_tid_dout <= ram_tid[rd_ptr[ADDR_WIDTH-1:0]];
        ram_tdest_dout <= ram_tdest[rd_ptr[ADDR_WIDTH-1:0]];
        ram_tuser_dout <= ram_tuser[rd_ptr[ADDR_WIDTH-1:0]];
    end

    // Update write pointer
    always @(posedge clk or posedge rst) begin
        if (rst)
            wr_ptr <= 0;
        else if (eff_wr_en)
            wr_ptr <= wr_ptr + 1;
    end

    // Update read pointer
    always @(posedge clk or posedge rst) begin
        if (rst)
            rd_ptr <= 0;
        else if (rd_en)
            rd_ptr <= rd_ptr + 1;
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            pause_active <= 1'b0;
        else if (PAUSE_ENABLE) begin
            if (pause_req)
                pause_active <= 1'b1;
            else if (empty)
                pause_active <= 1'b0;
        end
        else
            pause_active <= 1'b0;
    end

    // Output signals
    assign m_axis_tdata = ram_dout;
    assign m_axis_tkeep = ram_keep_dout;
    assign m_axis_tvalid = !empty && !pause_active;
    assign m_axis_tlast = ram_last_dout;
    assign m_axis_tid = ram_tid_dout;
    assign m_axis_tdest = ram_tdest_dout;
    assign m_axis_tuser = ram_tuser_dout;

    // Input ready
    assign s_axis_tready = !full && !pause_active;

    // Pause ack
    assign pause_ack = pause_active;

    // Status depth
    assign status_depth = depth;
    assign status_depth_commit = depth;

    // Status overflow
    always @(posedge clk or posedge rst) begin
        if (rst)
            status_overflow_reg <= 1'b0;
        else if (full && s_axis_tvalid)
            status_overflow_reg <= 1'b1;
        else
            status_overflow_reg <= 1'b0;
    end
    assign status_overflow = status_overflow_reg;

    // Status bad frame
    always @(posedge clk or posedge rst) begin
        if (rst)
            status_bad_frame_reg <= 1'b0;
        else if (frame_complete && frame_bad)
            status_bad_frame_reg <= 1'b1;
        else
            status_bad_frame_reg <= 1'b0;
    end
    assign status_bad_frame = status_bad_frame_reg;

    // Status good frame
    always @(posedge clk or posedge rst) begin
        if (rst)
            status_good_frame_reg <= 1'b0;
        else if (frame_complete && !frame_bad && !frame_overflow)
            status_good_frame_reg <= 1'b1;
        else
            status_good_frame_reg <= 1'b0;
    end
    assign status_good_frame = status_good_frame_reg;

endmodule
