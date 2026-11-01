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
    wire [DATA_WIDTH-1:0]  ram_data;
    wire [KEEP_WIDTH-1:0]  ram_keep;
    wire                    ram_last;
    wire [ID_WIDTH-1:0]    ram_tid;
    wire [DEST_WIDTH-1:0]  ram_tdest;
    wire [USER_WIDTH-1:0]  ram_tuser;

    // Write pointer and read pointer
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;

    // RAM storage
    reg [DATA_WIDTH-1:0]  mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  mem_keep [0:DEPTH-1];
    reg                    mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    mem_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  mem_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  mem_tuser [0:DEPTH-1];

    // Frame tracking
    reg frame_active;
    reg [ADDR_WIDTH:0] frame_start_ptr;
    reg frame_oversize;
    reg frame_bad;

    // Status registers
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    // Pause logic
    reg pause_active;

    // Write enable
    wire write_en;
    wire read_en;

    // Full and empty conditions
    wire full;
    wire empty;

    // Depth calculation
    wire [ADDR_WIDTH:0] depth;
    wire [ADDR_WIDTH:0] depth_commit;

    // Frame drop logic
    wire drop_frame;
    wire mark_frame;

    // Output valid
    wire out_valid;

    // Determine if we should write to RAM
    assign write_en = s_axis_tvalid && s_axis_tready && !rst;
    assign read_en = m_axis_tvalid && m_axis_tready && !rst;

    // Full condition: write pointer is one ahead of read pointer
    assign full = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) && 
                  (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);
    
    // Empty condition: write pointer equals read pointer
    assign empty = (wptr == rptr);

    // Depth calculation
    assign depth = wptr - rptr;
    assign depth_commit = depth;

    // Frame oversize detection
    wire frame_oversize_next;
    assign frame_oversize_next = frame_active && (depth >= DEPTH[ADDR_WIDTH:0]);

    // Frame drop decision
    assign drop_frame = (DROP_OVERSIZE_FRAME && frame_oversize) || 
                        (DROP_BAD_FRAME && frame_bad);

    // Mark when full
    assign mark_frame = MARK_WHEN_FULL && full && s_axis_tvalid;

    // Pause logic
    wire pause_req_internal;
    assign pause_req_internal = PAUSE_ENABLE ? pause_req : 1'b0;

    // s_axis_tready logic
    wire tready_base;
    assign tready_base = !full || (DROP_WHEN_FULL && !frame_active) || 
                         (drop_frame && frame_active);

    assign s_axis_tready = tready_base && !pause_active && !rst;

    // Output valid
    assign out_valid = !empty && !rst;
    assign m_axis_tvalid = out_valid;

    // RAM read
    wire [ADDR_WIDTH-1:0] read_addr;
    assign read_addr = rptr[ADDR_WIDTH-1:0];

    assign ram_data = mem_data[read_addr];
    assign ram_keep = mem_keep[read_addr];
    assign ram_last = mem_last[read_addr];
    assign ram_tid = mem_tid[read_addr];
    assign ram_tdest = mem_tdest[read_addr];
    assign ram_tuser = mem_tuser[read_addr];

    // Output assignment
    assign m_axis_tdata = ram_data;
    assign m_axis_tkeep = KEEP_ENABLE ? ram_keep : {KEEP_WIDTH{1'b1}};
    assign m_axis_tlast = LAST_ENABLE ? ram_last : 1'b0;
    assign m_axis_tid = ID_ENABLE ? ram_tid : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? ram_tdest : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? ram_tuser : {USER_WIDTH{1'b0}};

    // Status outputs
    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

    // Pause ack
    assign pause_ack = pause_active;

    // Write address
    wire [ADDR_WIDTH-1:0] write_addr;
    assign write_addr = wptr[ADDR_WIDTH-1:0];

    // Frame tracking logic
    wire frame_start;
    wire frame_end;
    assign frame_start = write_en && !frame_active;
    assign frame_end = write_en && s_axis_tlast;

    // Update frame tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_active <= 1'b0;
            frame_start_ptr <= {ADDR_WIDTH+1{1'b0}};
            frame_oversize <= 1'b0;
            frame_bad <= 1'b0;
        end else begin
            if (frame_start) begin
                frame_active <= 1'b1;
                frame_start_ptr <= wptr;
                frame_oversize <= 1'b0;
                frame_bad <= 1'b0;
            end else if (frame_end) begin
                frame_active <= 1'b0;
            end else if (frame_active) begin
                if (frame_oversize_next) begin
                    frame_oversize <= 1'b1;
                end
            end
        end
    end

    // Write to RAM
    always @(posedge clk) begin
        if (write_en) begin
            mem_data[write_addr] <= s_axis_tdata;
            mem_keep[write_addr] <= KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
            mem_last[write_addr] <= LAST_ENABLE ? s_axis_tlast : 1'b0;
            mem_tid[write_addr] <= ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
            mem_tdest[write_addr] <= DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
            mem_tuser[write_addr] <= USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
        end
    end

    // Update pointers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr <= {ADDR_WIDTH+1{1'b0}};
            rptr <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            if (write_en) begin
                wptr <= wptr + 1'b1;
            end
            if (read_en) begin
                rptr <= rptr + 1'b1;
            end
        end
    end

    // Status registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_overflow_reg <= 1'b0;
            status_bad_frame_reg <= 1'b0;
            status_good_frame_reg <= 1'b0;
        end else begin
            // Overflow: write when full and not dropping
            if (write_en && full && !drop_frame) begin
                status_overflow_reg <= 1'b1;
            end

            // Bad frame: frame ended with bad status
            if (frame_end && frame_bad) begin
                status_bad_frame_reg <= 1'b1;
            end

            // Good frame: frame ended without bad status
            if (frame_end && !frame_bad) begin
                status_good_frame_reg <= 1'b1;
            end
        end
    end

    // Pause logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else begin
            if (pause_req_internal) begin
                pause_active <= 1'b1;
            end else if (!pause_req_internal && !m_axis_tvalid) begin
                pause_active <= 1'b0;
            end
        end
    end

endmodule
