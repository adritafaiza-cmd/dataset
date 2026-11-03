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
    reg                   wr_en;
    reg                   rd_en;
    reg                   fifo_full;
    reg                   fifo_empty;
    reg                   frame_start;
    reg                   frame_end;
    reg                   frame_err;
    reg                   frame_good;
    reg [$clog2(DEPTH):0] frame_cnt;
    reg                   pause_state;
    reg [$clog2(DEPTH):0] depth_cnt;
    reg [$clog2(DEPTH):0] depth_commit;

    // FIFO memory
    reg [DATA_WIDTH-1:0]  mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0]  mem_keep [DEPTH-1:0];
    reg                   mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]    mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0]  mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0]  mem_user [DEPTH-1:0];

    // Write enable logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_en <= 0;
        end else begin
            wr_en <= s_axis_tvalid & s_axis_tready & ~fifo_full;
            if (wr_en) begin
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // Read enable logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_en <= 0;
        end else begin
            rd_en <= m_axis_tvalid & m_axis_tready & ~fifo_empty;
            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // FIFO full and empty flags
    always @(*) begin
        fifo_full = (wr_ptr == {~rd_ptr[0], rd_ptr[$clog2(DEPTH):1]});
        fifo_empty = (wr_ptr == rd_ptr);
    end

    // FIFO read and write
    always @(posedge clk) begin
        if (wr_en) begin
            mem_data[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tdata;
            mem_keep[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tkeep;
            mem_last[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tlast;
            mem_id[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tid;
            mem_dest[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tdest;
            mem_user[wr_ptr[$clog2(DEPTH)-1:0]] <= s_axis_tuser;
        end
    end

    // Output data
    assign m_axis_tdata = mem_data[rd_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tkeep = mem_keep[rd_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tlast = mem_last[rd_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tid = mem_id[rd_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tdest = mem_dest[rd_ptr[$clog2(DEPTH)-1:0]];
    assign m_axis_tuser = mem_user[rd_ptr[$clog2(DEPTH)-1:0]];

    // Handshake signals
    assign s_axis_tready = ~fifo_full;
    assign m_axis_tvalid = ~fifo_empty;

    // Frame control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_start <= 0;
            frame_end <= 0;
            frame_err <= 0;
            frame_good <= 0;
            frame_cnt <= 0;
        end else begin
            frame_start <= s_axis_tvalid & ~s_axis_tready & ~frame_start;
            frame_end <= rd_en & mem_last[rd_ptr[$clog2(DEPTH)-1:0]];
            frame_err <= frame_err | (frame_cnt > DEPTH);
            frame_good <= frame_end & ~frame_err;
            if (s_axis_tvalid & s_axis_tready) begin
                frame_cnt <= frame_cnt + 1;
            end
            if (frame_end) begin
                frame_cnt <= 0;
                frame_err <= 0;
            end
        end
    end

    // Pause control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_state <= 0;
        end else begin
            pause_state <= pause_req;
        end
    end

    assign pause_ack = pause_state;

    // Status signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth_cnt <= 0;
            depth_commit <= 0;
        end else begin
            if (wr_en & ~rd_en) begin
                depth_cnt <= depth_cnt + 1;
            end else if (~wr_en & rd_en) begin
                depth_cnt <= depth_cnt - 1;
            end
            if (frame_end) begin
                depth_commit <= depth_cnt;
            end
        end
    end

    assign status_depth = depth_cnt;
    assign status_depth_commit = depth_commit;
    assign status_overflow = frame_err;
    assign status_bad_frame = frame_err;
    assign status_good_frame = frame_good;

endmodule
