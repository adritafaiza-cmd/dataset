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

    // Internal signals
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] fifo_count;
    reg [$clog2(DEPTH):0] fifo_commit_count;
    reg fifo_full;
    reg fifo_empty;
    reg frame_in_progress;
    reg bad_frame_detected;
    reg good_frame_detected;
    reg pause_state;
    reg frame_pause_state;
    reg [DATA_WIDTH-1:0] fifo_data;
    reg [KEEP_WIDTH-1:0] fifo_keep;
    reg fifo_last;
    reg [ID_WIDTH-1:0] fifo_id;
    reg [DEST_WIDTH-1:0] fifo_dest;
    reg [USER_WIDTH-1:0] fifo_user;
    reg [DATA_WIDTH-1:0] fifo_data_wr;
    reg [KEEP_WIDTH-1:0] fifo_keep_wr;
    reg fifo_last_wr;
    reg [ID_WIDTH-1:0] fifo_id_wr;
    reg [DEST_WIDTH-1:0] fifo_dest_wr;
    reg [USER_WIDTH-1:0] fifo_user_wr;

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    // Write and read operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
            fifo_commit_count <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            frame_in_progress <= 0;
            bad_frame_detected <= 0;
            good_frame_detected <= 0;
            pause_state <= 0;
            frame_pause_state <= 0;
        end else begin
            // Write pointer update
            if (s_axis_tvalid && s_axis_tready) begin
                mem_data[wr_ptr] <= s_axis_tdata;
                mem_keep[wr_ptr] <= s_axis_tkeep;
                mem_last[wr_ptr] <= s_axis_tlast;
                mem_id[wr_ptr] <= s_axis_tid;
                mem_dest[wr_ptr] <= s_axis_tdest;
                mem_user[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                fifo_count <= fifo_count + 1;
                if (s_axis_tlast) begin
                    frame_in_progress <= 0;
                    if (!bad_frame_detected) begin
                        good_frame_detected <= 1;
                    end
                    bad_frame_detected <= 0;
                end else if (!frame_in_progress) begin
                    frame_in_progress <= 1;
                    good_frame_detected <= 0;
                end
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    bad_frame_detected <= 1;
                end
                if (fifo_count == DEPTH - 1) begin
                    fifo_full <= 1;
                    if (MARK_WHEN_FULL) begin
                        fifo_commit_count <= fifo_count;
                    end
                end else begin
                    fifo_full <= 0;
                end
                fifo_empty <= 0;
            end

            // Read pointer update
            if (m_axis_tvalid && m_axis_tready) begin
                rd_ptr <= rd_ptr + 1;
                fifo_count <= fifo_count - 1;
                if (fifo_count == 0) begin
                    fifo_empty <= 1;
                end else begin
                    fifo_empty <= 0;
                end
            end

            // Pause state
            if (PAUSE_ENABLE) begin
                if (pause_req && !pause_state) begin
                    pause_state <= 1;
                end else if (!pause_req && pause_state) begin
                    pause_state <= 0;
                end
            end

            // Frame pause state
            if (FRAME_PAUSE) begin
                if (frame_in_progress && !frame_pause_state) begin
                    frame_pause_state <= 1;
                end else if (!frame_in_progress && frame_pause_state) begin
                    frame_pause_state <= 0;
                end
            end

            // Commit count
            if (fifo_count == 0) begin
                fifo_commit_count <= 0;
            end
        end
    end

    // Status signals
    assign status_depth = fifo_count;
    assign status_depth_commit = fifo_commit_count;
    assign status_overflow = fifo_full;
    assign status_bad_frame = bad_frame_detected;
    assign status_good_frame = good_frame_detected;

    // Handshake signals
    assign s_axis_tready = !fifo_full && !pause_state;
    assign m_axis_tvalid = !fifo_empty && !frame_pause_state;

    // Output signals
    assign m_axis_tdata = mem_data[rd_ptr];
    assign m_axis_tkeep = mem_keep[rd_ptr];
    assign m_axis_tlast = mem_last[rd_ptr];
    assign m_axis_tid = mem_id[rd_ptr];
    assign m_axis_tdest = mem_dest[rd_ptr];
    assign m_axis_tuser = mem_user[rd_ptr];

    // Pause acknowledge
    assign pause_ack = pause_state;

endmodule
