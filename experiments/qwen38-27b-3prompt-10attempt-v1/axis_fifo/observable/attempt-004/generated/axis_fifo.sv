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
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg                  mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   mem_tid  [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_tdest[0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_tuser[0:DEPTH-1];

    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] commit_ptr;

    wire [ADDR_WIDTH:0] depth = wr_ptr - rd_ptr;
    wire [ADDR_WIDTH:0] commit_depth = wr_ptr - commit_ptr;

    assign status_depth = depth;
    assign status_depth_commit = commit_depth;

    // Frame tracking
    reg in_frame;
    reg [ADDR_WIDTH:0] frame_start_ptr;
    reg frame_overflow;
    reg frame_bad;

    wire frame_active = in_frame;
    wire frame_len = wr_ptr - frame_start_ptr;
    wire frame_oversize = (frame_len > DEPTH[ADDR_WIDTH:0]);

    // Input ready logic
    wire input_full = (depth == DEPTH[ADDR_WIDTH:0]);
    wire frame_full = (frame_active && frame_oversize);
    wire pause_active = (PAUSE_ENABLE && pause_req);
    
    wire can_accept = s_axis_tvalid && !input_full && !frame_full && !pause_active;
    
    assign s_axis_tready = !input_full && !frame_full && !pause_active;

    // Overflow detection
    wire overflow_event = s_axis_tvalid && input_full;
    assign status_overflow = overflow_event;

    // Write logic
    wire do_write = s_axis_tvalid && s_axis_tready;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            commit_ptr <= 0;
            in_frame <= 0;
            frame_start_ptr <= 0;
            frame_overflow <= 0;
            frame_bad <= 0;
        end else begin
            if (do_write) begin
                mem_data[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_keep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_last[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                mem_tid[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                mem_tdest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                mem_tuser[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
            end

            // Frame management
            if (do_write) begin
                if (!in_frame) begin
                    in_frame <= 1;
                    frame_start_ptr <= wr_ptr;
                    frame_overflow <= 0;
                    frame_bad <= 0;
                end else begin
                    if (frame_len >= DEPTH[ADDR_WIDTH:0]) begin
                        frame_overflow <= 1;
                    end
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        frame_bad <= 1;
                    end
                end
                if (s_axis_tlast) begin
                    in_frame <= 0;
                end
            end
        end
    end

    // Read logic
    wire output_empty = (rd_ptr == wr_ptr);
    wire output_valid = !output_empty;

    // Output data
    wire [DATA_WIDTH-1:0] rd_data = mem_data[rd_ptr[ADDR_WIDTH-1:0]];
    wire [KEEP_WIDTH-1:0] rd_keep = mem_keep[rd_ptr[ADDR_WIDTH-1:0]];
    wire                  rd_last = mem_last[rd_ptr[ADDR_WIDTH-1:0]];
    wire [ID_WIDTH-1:0]   rd_tid  = mem_tid[rd_ptr[ADDR_WIDTH-1:0]];
    wire [DEST_WIDTH-1:0] rd_tdest= mem_tdest[rd_ptr[ADDR_WIDTH-1:0]];
    wire [USER_WIDTH-1:0] rd_tuser= mem_tuser[rd_ptr[ADDR_WIDTH-1:0]];

    // Determine if current frame should be dropped or marked
    wire drop_current_frame = (DROP_OVERSIZE_FRAME && frame_overflow) || (DROP_BAD_FRAME && frame_bad);
    wire mark_current_frame = (MARK_WHEN_FULL && input_full);

    // Output ready
    wire do_read = output_valid && m_axis_tready;

    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            commit_ptr <= 0;
        end else begin
            if (do_read) begin
                rd_ptr <= rd_ptr + 1;
                commit_ptr <= commit_ptr + 1;
            end
        end
    end

    // Output signals
    assign m_axis_tvalid = output_valid;
    assign m_axis_tdata = rd_data;
    assign m_axis_tkeep = rd_keep;
    assign m_axis_tlast = rd_last;
    assign m_axis_tid = rd_tid;
    assign m_axis_tdest = rd_tdest;
    
    // User signal: mark if needed
    wire [USER_WIDTH-1:0] user_out;
    generate
        if (USER_ENABLE) begin
            assign user_out = mark_current_frame ? (rd_tuser | USER_BAD_FRAME_MASK) : rd_tuser;
        end else begin
            assign user_out = {USER_WIDTH{1'b0}};
        end
    endgenerate
    assign m_axis_tuser = user_out;

    // Pause
    assign pause_ack = (PAUSE_ENABLE && pause_req) ? 1'b1 : 1'b0;

    // Status
    assign status_bad_frame = frame_bad;
    assign status_good_frame = in_frame && !frame_bad && !frame_overflow;

endmodule
