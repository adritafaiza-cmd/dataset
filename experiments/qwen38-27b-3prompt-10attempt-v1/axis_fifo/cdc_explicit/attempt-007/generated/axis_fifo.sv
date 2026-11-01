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
    localparam DEPTH_POW2 = (1 << ADDR_WIDTH);
    localparam DEPTH_MASK = DEPTH_POW2 - 1;

    // Total sideband width
    localparam SIDE_WIDTH = (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                            (LAST_ENABLE ? 1 : 0) +
                            (ID_ENABLE ? ID_WIDTH : 0) +
                            (DEST_ENABLE ? DEST_WIDTH : 0) +
                            (USER_ENABLE ? USER_WIDTH : 0);

    // Combined data + sideband width
    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

    // Pack sideband into a single vector for storage
    wire [SIDE_WIDTH-1:0] side_in;
    assign side_in = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}})
    };

    wire [TOTAL_WIDTH-1:0] data_in;
    assign data_in = {side_in, s_axis_tdata};

    // Unpack sideband from stored data
    wire [SIDE_WIDTH-1:0] side_out;
    wire [DATA_WIDTH-1:0] data_out;

    assign data_out = side_out[DATA_WIDTH-1:0];
    assign side_out = side_out; // placeholder, will be assigned below

    // Actually, let's define the unpacking properly
    wire [TOTAL_WIDTH-1:0] ram_data_out;
    assign data_out = ram_data_out[DATA_WIDTH-1:0];
    assign side_out = ram_data_out[TOTAL_WIDTH-1:DATA_WIDTH];

    wire [KEEP_WIDTH-1:0] m_axis_tkeep_w;
    wire                   m_axis_tlast_w;
    wire [ID_WIDTH-1:0]    m_axis_tid_w;
    wire [DEST_WIDTH-1:0]  m_axis_tdest_w;
    wire [USER_WIDTH-1:0]  m_axis_tuser_w;

    assign m_axis_tkeep_w  = KEEP_ENABLE  ? side_out[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast_w  = LAST_ENABLE  ? side_out[DATA_WIDTH + KEEP_WIDTH + 1-1:DATA_WIDTH + KEEP_WIDTH] : 1'b0;
    assign m_axis_tid_w    = ID_ENABLE    ? side_out[DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + ID_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest_w  = DEST_ENABLE  ? side_out[DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + DEST_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser_w  = USER_ENABLE  ? side_out[TOTAL_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + (DEST_ENABLE?DEST_WIDTH:0)] : {USER_WIDTH{1'b0}};

    // RAM storage
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH_POW2-1];

    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // Full/Empty
    wire fifo_full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    wire fifo_empty = (wr_ptr == rd_ptr);

    // Write enable
    wire wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    wire rd_en = m_axis_tvalid && m_axis_tready;

    // Frame tracking
    reg frame_active;
    reg frame_bad;
    reg frame_oversize;

    // Pause logic
    reg pause_active;
    reg pause_at_frame_end;

    // Status latches
    reg status_overflow_r;
    reg status_bad_frame_r;
    reg status_good_frame_r;

    // Depth tracking
    reg [$clog2(DEPTH):0] depth_r;
    reg [$clog2(DEPTH):0] depth_commit_r;

    // Determine if we should accept a write
    wire can_write = !fifo_full || DROP_WHEN_FULL;
    wire should_drop = (fifo_full && DROP_WHEN_FULL) || 
                       (frame_active && DROP_OVERSIZE_FRAME && frame_oversize) ||
                       (frame_active && DROP_BAD_FRAME && frame_bad);

    // Frame size tracking (max frame size = DEPTH)
    reg [$clog2(DEPTH):0] frame_size;

    // Bad frame detection
    wire user_bad = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Write to RAM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            frame_active <= 0;
            frame_bad <= 0;
            frame_oversize <= 0;
            frame_size <= 0;
            pause_active <= 0;
            pause_at_frame_end <= 0;
            status_overflow_r <= 0;
            status_bad_frame_r <= 0;
            status_good_frame_r <= 0;
            depth_r <= 0;
            depth_commit_r <= 0;
        end else begin
            // Handle writes
            if (wr_en && !should_drop) begin
                ram[wr_addr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                depth_r <= depth_r + 1;
                depth_commit_r <= depth_commit_r + 1;

                // Frame tracking
                if (!frame_active) begin
                    frame_active <= 1;
                    frame_size <= 1;
                    frame_bad <= user_bad;
                    frame_oversize <= 0;
                end else begin
                    frame_size <= frame_size + 1;
                    if (frame_size + 1 > DEPTH) begin
                        frame_oversize <= 1;
                    end
                    if (user_bad) begin
                        frame_bad <= 1;
                    end
                end

                // Check for frame end
                if (LAST_ENABLE && s_axis_tlast) begin
                    // Frame complete
                    if (frame_bad) begin
                        status_bad_frame_r <= 1;
                    end else begin
                        status_good_frame_r <= 1;
                    end
                    frame_active <= 0;
                    frame_size <= 0;
                    frame_bad <= 0;
                    frame_oversize <= 0;

                    // Pause at frame end
                    if (PAUSE_ENABLE && FRAME_PAUSE) begin
                        pause_at_frame_end <= 1;
                    end
                end
            end else if (wr_en && should_drop) begin
                // Drop the beat
                if (fifo_full && DROP_WHEN_FULL) begin
                    status_overflow_r <= 1;
                end
                // Frame tracking continues but data is dropped
                if (!frame_active) begin
                    frame_active <= 1;
                    frame_size <= 1;
                    frame_bad <= user_bad;
                    frame_oversize <= 0;
                end else begin
                    frame_size <= frame_size + 1;
                    if (frame_size + 1 > DEPTH) begin
                        frame_oversize <= 1;
                    end
                    if (user_bad) begin
                        frame_bad <= 1;
                    end
                end

                if (LAST_ENABLE && s_axis_tlast) begin
                    if (frame_bad) begin
                        status_bad_frame_r <= 1;
                    end else begin
                        status_good_frame_r <= 1;
                    end
                    frame_active <= 0;
                    frame_size <= 0;
                    frame_bad <= 0;
                    frame_oversize <= 0;

                    if (PAUSE_ENABLE && FRAME_PAUSE) begin
                        pause_at_frame_end <= 1;
                    end
                end
            end

            // Handle reads
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
                depth_r <= depth_r - 1;
            end

            // Pause logic
            if (PAUSE_ENABLE) begin
                if (pause_req && !pause_active) begin
                    pause_active <= 1;
                end else if (!pause_req && pause_active) begin
                    if (FRAME_PAUSE) begin
                        // Wait for frame end
                        if (pause_at_frame_end) begin
                            pause_active <= 0;
                            pause_at_frame_end <= 0;
                        end
                    end else begin
                        pause_active <= 0;
                    end
                end
            end
        end
    end

    // Output logic
    wire [TOTAL_WIDTH-1:0] ram_out;
    assign ram_out = ram[rd_addr];

    // Pipeline the RAM read if needed
    reg [TOTAL_WIDTH-1:0] ram_out_pipe;
    reg                    valid_pipe;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_out_pipe <= 0;
            valid_pipe <= 0;
        end else begin
            if (rd_en) begin
                valid_pipe <= 0;
            end else if (!fifo_empty) begin
                ram_out_pipe <= ram[rd_addr];
                valid_pipe <= 1;
            end
        end
    end

    // Output valid
    wire m_axis_tvalid_w;
    assign m_axis_tvalid_w = !fifo_empty && !pause_active;

    // Assign outputs
    assign m_axis_tdata  = ram_out[DATA_WIDTH-1:0];
    assign m_axis_tkeep  = KEEP_ENABLE  ? ram_out[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tvalid = m_axis_tvalid_w;
    assign m_axis_tlast  = LAST_ENABLE  ? ram_out[DATA_WIDTH + KEEP_WIDTH + 1-1:DATA_WIDTH + KEEP_WIDTH] : 1'b0;
    assign m_axis_tid    = ID_ENABLE    ? ram_out[DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + ID_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest  = DEST_ENABLE  ? ram_out[DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + DEST_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser  = USER_ENABLE  ? ram_out[TOTAL_WIDTH-1:DATA_WIDTH + KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + (DEST_ENABLE?DEST_WIDTH:0)] : {USER_WIDTH{1'b0}};

    // Input ready
    assign s_axis_tready = can_write && !pause_active;

    // Pause ack
    assign pause_ack = pause_active;

    // Status
    assign status_depth = depth_r;
    assign status_depth_commit = depth_commit_r;
    assign status_overflow = status_overflow_r;
    assign status_bad_frame = status_bad_frame_r;
    assign status_good_frame = status_good_frame_r;

endmodule
