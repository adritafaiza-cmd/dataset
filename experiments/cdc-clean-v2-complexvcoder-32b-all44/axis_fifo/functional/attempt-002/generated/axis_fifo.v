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

    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] depth, depth_commit;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg                  mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_id [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

    wire full, empty, almost_full, almost_empty;
    wire wr_en, rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire [KEEP_WIDTH-1:0] rd_keep;
    wire                  rd_last;
    wire [ID_WIDTH-1:0]   rd_id;
    wire [DEST_WIDTH-1:0] rd_dest;
    wire [USER_WIDTH-1:0] rd_user;

    wire [ADDR_WIDTH:0] wr_ptr_next, rd_ptr_next;

    assign wr_ptr_next = wr_ptr + 1;
    assign rd_ptr_next = rd_ptr + 1;

    assign full = (wr_ptr_gray_sync == (rd_ptr_gray + 1));
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray);
    assign almost_full = (wr_ptr_gray_sync == (rd_ptr_gray + DEPTH - 1));
    assign almost_empty = (wr_ptr_gray_sync == rd_ptr_gray + 1);

    assign wr_en = s_axis_tvalid & s_axis_tready;
    assign rd_en = m_axis_tvalid & m_axis_tready;

    assign s_axis_tready = !full;
    assign m_axis_tvalid = !empty;

    assign rd_data = mem_data[rd_ptr];
    assign rd_keep = mem_keep[rd_ptr];
    assign rd_last = mem_last[rd_ptr];
    assign rd_id = mem_id[rd_ptr];
    assign rd_dest = mem_dest[rd_ptr];
    assign rd_user = mem_user[rd_ptr];

    assign m_axis_tdata = rd_data;
    assign m_axis_tkeep = rd_keep;
    assign m_axis_tlast = rd_last;
    assign m_axis_tid = rd_id;
    assign m_axis_tdest = rd_dest;
    assign m_axis_tuser = rd_user;

    assign pause_ack = (PAUSE_ENABLE && pause_req && full);

    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = 0; // Placeholder, need to implement overflow logic
    assign status_bad_frame = 0; // Placeholder, need to implement bad frame logic
    assign status_good_frame = 0; // Placeholder, need to implement good frame logic

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_ptr_gray <= 0;
            rd_ptr_gray <= 0;
            wr_ptr_gray_sync <= 0;
            rd_ptr_gray_sync <= 0;
            depth <= 0;
            depth_commit <= 0;
        end else begin
            if (wr_en && !full) begin
                mem_data[wr_ptr] <= s_axis_tdata;
                mem_keep[wr_ptr] <= s_axis_tkeep;
                mem_last[wr_ptr] <= s_axis_tlast;
                mem_id[wr_ptr] <= s_axis_tid;
                mem_dest[wr_ptr] <= s_axis_tdest;
                mem_user[wr_ptr] <= s_axis_tuser;
                wr_ptr <= wr_ptr_next;
                wr_ptr_gray <= wr_ptr_next ^ (wr_ptr_next >> 1);
            end

            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr_next;
                rd_ptr_gray <= rd_ptr_next ^ (rd_ptr_next >> 1);
            end

            wr_ptr_gray_sync <= wr_ptr_gray;
            rd_ptr_gray_sync <= rd_ptr_gray;

            if (wr_en && !full) begin
                depth <= depth + 1;
            end else if (rd_en && !empty) begin
                depth <= depth - 1;
            end

            depth_commit <= depth;
        end
    end

endmodule
