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

    // Pack sideband into a single word for storage
    // Layout: [user | dest | id | last | keep | data]
    localparam SIDE_KEEP   = KEEP_ENABLE ? KEEP_WIDTH : 0;
    localparam SIDE_LAST   = LAST_ENABLE ? 1 : 0;
    localparam SIDE_ID     = ID_ENABLE   ? ID_WIDTH   : 0;
    localparam SIDE_DEST   = DEST_ENABLE ? DEST_WIDTH : 0;
    localparam SIDE_USER   = USER_ENABLE ? USER_WIDTH : 0;
    localparam SIDE_TOTAL  = SIDE_KEEP + SIDE_LAST + SIDE_ID + SIDE_DEST + SIDE_USER;
    localparam WORD_WIDTH  = DATA_WIDTH + SIDE_TOTAL;

    // Offsets for packing/unpacking
    localparam OFF_DATA  = 0;
    localparam OFF_KEEP  = OFF_DATA + DATA_WIDTH;
    localparam OFF_LAST  = OFF_KEEP + SIDE_KEEP;
    localparam OFF_ID    = OFF_LAST + SIDE_LAST;
    localparam OFF_DEST  = OFF_ID + SIDE_ID;
    localparam OFF_USER  = OFF_DEST + SIDE_DEST;

    // Write pointer and read pointer
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;

    // RAM storage
    reg [WORD_WIDTH-1:0] mem [0:DEPTH-1];

    // Write logic
    wire write_en = s_axis_tvalid & s_axis_tready;
    wire [ADDR_WIDTH-1:0] waddr = wptr[ADDR_WIDTH-1:0];

    // Pack data for write
    wire [WORD_WIDTH-1:0] wdata;
    assign wdata[OFF_DATA +: DATA_WIDTH] = s_axis_tdata;
    generate
        if (KEEP_ENABLE) begin : gen_keep
            assign wdata[OFF_KEEP +: KEEP_WIDTH] = s_axis_tkeep;
        end else begin : gen_keep_no
            assign wdata[OFF_KEEP +: 1] = 1'b0;
        end
    endgenerate
    generate
        if (LAST_ENABLE) begin : gen_last
            assign wdata[OFF_LAST +: 1] = s_axis_tlast;
        end else begin : gen_last_no
            assign wdata[OFF_LAST +: 1] = 1'b0;
        end
    endgenerate
    generate
        if (ID_ENABLE) begin : gen_id
            assign wdata[OFF_ID +: ID_WIDTH] = s_axis_tid;
        end else begin : gen_id_no
            assign wdata[OFF_ID +: 1] = 1'b0;
        end
    endgenerate
    generate
        if (DEST_ENABLE) begin : gen_dest
            assign wdata[OFF_DEST +: DEST_WIDTH] = s_axis_tdest;
        end else begin : gen_dest_no
            assign wdata[OFF_DEST +: 1] = 1'b0;
        end
    endgenerate
    generate
        if (USER_ENABLE) begin : gen_user
            assign wdata[OFF_USER +: USER_WIDTH] = s_axis_tuser;
        end else begin : gen_user_no
            assign wdata[OFF_USER +: 1] = 1'b0;
        end
    endgenerate

    // Read logic
    wire [ADDR_WIDTH-1:0] raddr = rptr[ADDR_WIDTH-1:0];
    wire [WORD_WIDTH-1:0] rdata;

    // RAM read
    always @(posedge clk) begin
        if (write_en) begin
            mem[waddr] <= wdata;
        end
    end

    // Combinational read for zero-latency, or registered for pipelined
    generate
        if (RAM_PIPELINE) begin : gen_ram_pipe
            reg [WORD_WIDTH-1:0] rdata_reg;
            always @(posedge clk) begin
                rdata_reg <= mem[raddr];
            end
            assign rdata = rdata_reg;
        end else begin : gen_ram_comb
            assign rdata = mem[raddr];
        end
    endgenerate

    // Unpack read data
    wire [DATA_WIDTH-1:0] rdata_data;
    wire [KEEP_WIDTH-1:0] rdata_keep;
    wire                  rdata_last;
    wire [ID_WIDTH-1:0]   rdata_id;
    wire [DEST_WIDTH-1:0] rdata_dest;
    wire [USER_WIDTH-1:0] rdata_user;

    assign rdata_data = rdata[OFF_DATA +: DATA_WIDTH];
    generate
        if (KEEP_ENABLE) begin : gen_rkeep
            assign rdata_keep = rdata[OFF_KEEP +: KEEP_WIDTH];
        end else begin : gen_rkeep_no
            assign rdata_keep = {KEEP_WIDTH{1'b0}};
        end
    endgenerate
    generate
        if (LAST_ENABLE) begin : gen_rlast
            assign rdata_last = rdata[OFF_LAST];
        end else begin : gen_rlast_no
            assign rdata_last = 1'b0;
        end
    endgenerate
    generate
        if (ID_ENABLE) begin : gen_rid
            assign rdata_id = rdata[OFF_ID +: ID_WIDTH];
        end else begin : gen_rid_no
            assign rdata_id = {ID_WIDTH{1'b0}};
        end
    endgenerate
    generate
        if (DEST_ENABLE) begin : gen_rdest
            assign rdata_dest = rdata[OFF_DEST +: DEST_WIDTH];
        end else begin : gen_rdest_no
            assign rdata_dest = {DEST_WIDTH{1'b0}};
        end
    endgenerate
    generate
        if (USER_ENABLE) begin : gen_ruser
            assign rdata_user = rdata[OFF_USER +: USER_WIDTH];
        end else begin : gen_ruser_no
            assign rdata_user = {USER_WIDTH{1'b0}};
        end
    endgenerate

    // FIFO full/empty
    wire fifo_empty = (wptr == rptr);
    wire fifo_full  = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) && (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);

    // Depth calculation
    wire [ADDR_WIDTH:0] depth = wptr - rptr;

    // Pause logic
    reg pause_active;
    wire pause_block = PAUSE_ENABLE && pause_active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_active <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (pause_req && !pause_active) begin
                pause_active <= 1'b1;
            end else if (!pause_req && pause_active) begin
                // For FRAME_PAUSE, wait until frame boundary
                if (FRAME_PAUSE) begin
                    if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                        pause_active <= 1'b0;
                    end
                end else begin
                    pause_active <= 1'b0;
                end
            end
        end
    end

    assign pause_ack = PAUSE_ENABLE ? pause_active : 1'b0;

    // Frame tracking for FRAME_FIFO
    reg in_frame;
    reg frame_bad;
    reg frame_oversize;
    reg [ADDR_WIDTH:0] frame_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_frame     <= 1'b0;
            frame_bad    <= 1'b0;
            frame_oversize <= 1'b0;
            frame_count  <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (write_en) begin
                if (!in_frame) begin
                    in_frame     <= 1'b1;
                    frame_bad    <= 1'b0;
                    frame_oversize <= 1'b0;
                    frame_count  <= 1;
                end else begin
                    frame_count <= frame_count + 1;
                    if (frame_count >= DEPTH[ADDR_WIDTH:0]) begin
                        frame_oversize <= 1'b1;
                    end
                    // Check bad frame via user sideband
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        frame_bad <= 1'b1;
                    end
                    if (s_axis_tlast) begin
                        in_frame <= 1'b0;
                    end
                end
            end
        end
    end

    // Determine if current write should be dropped
    wire drop_write = 1'b0;
    generate
        if (DROP_OVERSIZE_FRAME) begin : gen_drop_oversize
            assign drop_write = drop_write | (in_frame && frame_oversize);
        end else begin : gen_no_drop_oversize
            assign drop_write = drop_write | 1'b0;
        end
    endgenerate
    generate
        if (DROP_BAD_FRAME) begin : gen_drop_bad
            assign drop_write = drop_write | (in_frame && frame_bad);
        end else begin : gen_no_drop_bad
            assign drop_write = drop_write | 1'b0;
        end
    endgenerate

    // Overflow handling
    reg overflow_flag;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            overflow_flag <= 1'b0;
        end else begin
            if (fifo_full && s_axis_tvalid) begin
                overflow_flag <= 1'b1;
            end
        end
    end

    // Write ready logic
    wire write_allowed = !fifo_full && !pause_block && !drop_write;
    assign s_axis_tready = write_allowed;

    // Update write pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (write_en && !drop_write) begin
            wptr <= wptr + 1;
        end
    end

    // Read valid and ready
    wire read_valid = !fifo_empty;
    wire read_ready = m_axis_tready;
    wire read_en = read_valid && read_ready;

    // Update read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rptr <= {(ADDR_WIDTH+1){1'b0}};
        end else if (read_en) begin
            rptr <= rptr + 1;
        end
    end

    // Output assignments
    assign m_axis_tdata  = rdata_data;
    assign m_axis_tkeep  = rdata_keep;
    assign m_axis_tvalid = read_valid;
    assign m_axis_tlast  = rdata_last;
    assign m_axis_tid    = rdata_id;
    assign m_axis_tdest  = rdata_dest;
    assign m_axis_tuser  = rdata_user;

    // Status outputs
    assign status_depth = depth;
    assign status_depth_commit = depth;
    assign status_overflow = overflow_flag;

    // Frame status
    reg bad_frame_flag;
    reg good_frame_flag;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bad_frame_flag  <= 1'b0;
            good_frame_flag <= 1'b0;
        end else begin
            if (read_en && m_axis_tlast) begin
                if (frame_bad) begin
                    bad_frame_flag  <= 1'b1;
                    good_frame_flag <= 1'b0;
                end else begin
                    bad_frame_flag  <= 1'b0;
                    good_frame_flag <= 1'b1;
                end
            end
        end
    end

    assign status_bad_frame  = bad_frame_flag;
    assign status_good_frame = good_frame_flag;

endmodule
