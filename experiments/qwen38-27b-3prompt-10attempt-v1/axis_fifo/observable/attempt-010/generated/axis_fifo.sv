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

    // Internal FIFO storage
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg                  mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // Frame tracking
    reg frame_active;
    reg frame_overflow;
    reg frame_bad;

    // Status latches
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Pause logic
    reg pause_active;

    // Write enable
    wire wr_en;
    wire rd_en;

    // Full/Empty
    wire fifo_full;
    wire fifo_empty;

    // Depth calculation
    wire [ADDR_WIDTH:0] depth;
    wire [ADDR_WIDTH:0] depth_commit;

    assign fifo_full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                        (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    assign fifo_empty = (wr_ptr == rd_ptr);

    assign depth        = wr_ptr - rd_ptr;
    assign depth_commit = depth;

    // Determine if we can accept a new beat
    wire can_accept;
    wire drop_beat;
    wire mark_beat;

    // Frame size tracking: count beats in current frame
    reg [ADDR_WIDTH:0] frame_beat_count;

    // Oversize detection: frame exceeds DEPTH
    wire frame_oversize;
    assign frame_oversize = (frame_beat_count >= DEPTH[ADDR_WIDTH:0]) && !s_axis_tlast;

    // Bad frame detection based on user sideband
    wire user_bad_frame;
    generate
        if (USER_ENABLE) begin
            assign user_bad_frame = (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
        end else begin
            assign user_bad_frame = 1'b0;
        end
    endgenerate

    // Drop/mark logic
    wire should_drop;
    wire should_mark;

    assign should_drop = (DROP_WHEN_FULL && fifo_full) || 
                         (DROP_OVERSIZE_FRAME && frame_oversize) ||
                         (DROP_BAD_FRAME && user_bad_frame);
    assign should_mark = (MARK_WHEN_FULL && fifo_full) && !should_drop;

    // Write enable: accept beat if valid, not paused, and not dropping
    assign wr_en = s_axis_tvalid && !pause_active && !should_drop;

    // Read enable: output valid and ready
    assign rd_en = m_axis_tvalid && m_axis_tready;

    // Output valid: FIFO not empty and not paused
    assign m_axis_tvalid = !fifo_empty && !pause_active;

    // Input ready: not full, not paused, and not dropping
    assign s_axis_tready = !fifo_full && !pause_active && !should_drop;

    // Pause logic
    assign pause_ack = pause_active;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (pause_req) begin
                    pause_active <= 1'b1;
                end else if (!pause_req && fifo_empty) begin
                    pause_active <= 1'b0;
                end
            end else begin
                pause_active <= 1'b0;
            end
        end
    end

    // Frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_active     <= 1'b0;
            frame_overflow   <= 1'b0;
            frame_bad        <= 1'b0;
            frame_beat_count <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            if (wr_en) begin
                if (!frame_active) begin
                    // Start of new frame
                    frame_active     <= 1'b1;
                    frame_overflow   <= 1'b0;
                    frame_bad        <= user_bad_frame;
                    frame_beat_count <= 1'b1;
                end else begin
                    // Continue frame
                    frame_beat_count <= frame_beat_count + 1'b1;
                    if (frame_oversize) begin
                        frame_overflow <= 1'b1;
                    end
                    if (user_bad_frame) begin
                        frame_bad <= 1'b1;
                    end
                end
                if (s_axis_tlast) begin
                    // End of frame
                    frame_active     <= 1'b0;
                    frame_beat_count <= {ADDR_WIDTH+1{1'b0}};
                end
            end
        end
    end

    // Status latches
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg   <= 1'b0;
            status_bad_frame_reg  <= 1'b0;
            status_good_frame_reg <= 1'b0;
        end else begin
            // Overflow: tried to write when full
            if (s_axis_tvalid && fifo_full && !pause_active) begin
                status_overflow_reg <= 1'b1;
            end
            
            // Bad frame: frame ended with bad flag
            if (wr_en && s_axis_tlast && (frame_bad || frame_overflow)) begin
                status_bad_frame_reg <= 1'b1;
            end
            
            // Good frame: frame ended without bad/overflow
            if (wr_en && s_axis_tlast && !frame_bad && !frame_overflow) begin
                status_good_frame_reg <= 1'b1;
            end
        end
    end

    assign status_overflow   = status_overflow_reg;
    assign status_bad_frame  = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Write to memory
    always @(posedge clk) begin
        if (wr_en) begin
            mem_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            mem_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            mem_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            mem_id[wr_ptr[ADDR_WIDTH-1:0]]   <= s_axis_tid;
            mem_dest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            mem_user[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read from memory
    wire [ADDR_WIDTH-1:0] rd_addr;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // Output registers
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg                  out_last;
    reg [ID_WIDTH-1:0]   out_id;
    reg [DEST_WIDTH-1:0] out_dest;
    reg [USER_WIDTH-1:0] out_user;

    always @(posedge clk) begin
        if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Combinational read for output
    assign m_axis_tdata = mem_data[rd_addr];
    assign m_axis_tkeep = mem_keep[rd_addr];
    assign m_axis_tlast = mem_last[rd_addr];
    assign m_axis_tid   = mem_id[rd_addr];
    assign m_axis_tdest = mem_dest[rd_addr];
    assign m_axis_tuser = mem_user[rd_addr];

    assign status_depth        = depth;
    assign status_depth_commit = depth_commit;

endmodule
