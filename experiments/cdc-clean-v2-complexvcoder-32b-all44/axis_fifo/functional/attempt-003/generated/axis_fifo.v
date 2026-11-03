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

    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] depth;
    reg [$clog2(DEPTH):0] depth_commit;
    reg                     full;
    reg                     empty;
    reg                     wr_en;
    reg                     rd_en;
    reg                     overflow;
    reg                     bad_frame;
    reg                     good_frame;

    reg [DATA_WIDTH-1:0]    mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0]    mem_keep [DEPTH-1:0];
    reg                     mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]      mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0]    mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0]    mem_user [DEPTH-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
            full <= 0;
            empty <= 1;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            if (wr_en && !full) begin
                mem_data[wr_ptr] <= s_axis_tdata;
                mem_keep[wr_ptr] <= s_axis_tkeep;
                mem_last[wr_ptr] <= s_axis_tlast;
                mem_id[wr_ptr] <= s_axis_tid;
                mem_dest[wr_ptr] <= s_axis_tdest;
                mem_user[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
                depth <= depth + 1;
                if (s_axis_tlast) begin
                    depth_commit <= depth_commit + 1;
                    good_frame <= 1;
                end
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                depth <= depth - 1;
                if (mem_last[rd_ptr]) begin
                    depth_commit <= depth_commit - 1;
                end
            end
            if (wr_en && rd_en && (wr_ptr == rd_ptr) && !full) begin
                full <= 1;
                empty <= 0;
            end else if (!wr_en && rd_en && (wr_ptr == rd_ptr) && full) begin
                full <= 0;
                empty <= 1;
            end else if (wr_en && !rd_en && (wr_ptr == rd_ptr + 1) && !full) begin
                full <= 1;
                empty <= 0;
            end else if (!wr_en && rd_en && (wr_ptr == rd_ptr + 1) && full) begin
                full <= 0;
                empty <= 1;
            end else if (wr_en && rd_en && (wr_ptr == rd_ptr) && full) begin
                overflow <= 1;
            end else if (wr_en && !rd_en && (wr_ptr == rd_ptr + 1) && full) begin
                overflow <= 1;
            end else begin
                overflow <= 0;
            end
            if (s_axis_tvalid && s_axis_tready && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                bad_frame <= 1;
            end else begin
                bad_frame <= 0;
            end
            if (s_axis_tvalid && s_axis_tready && (s_axis_tuser & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) begin
                good_frame <= 1;
            end else begin
                good_frame <= 0;
            end
        end
    end

    assign wr_en = s_axis_tvalid && s_axis_tready;
    assign rd_en = m_axis_tvalid && m_axis_tready;

    assign s_axis_tready = !full;
    assign m_axis_tdata = mem_data[rd_ptr];
    assign m_axis_tkeep = mem_keep[rd_ptr];
    assign m_axis_tvalid = !empty;
    assign m_axis_tlast = mem_last[rd_ptr];
    assign m_axis_tid = mem_id[rd_ptr];
    assign m_axis_tdest = mem_dest[rd_ptr];
    assign m_axis_tuser = mem_user[rd_ptr];
    assign pause_ack = 0;

    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = overflow;
    assign status_bad_frame = bad_frame;
    assign status_good_frame = good_frame;

endmodule
