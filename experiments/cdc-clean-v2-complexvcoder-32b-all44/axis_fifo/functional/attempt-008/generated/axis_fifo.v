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

    reg [DATA_WIDTH-1:0] mem_tdata [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_tkeep [DEPTH-1:0];
    reg                  mem_tlast [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];

    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] depth;
    reg [ADDR_WIDTH:0] depth_commit;
    reg overflow;
    reg bad_frame;
    reg good_frame;

    wire full = (depth == DEPTH);
    wire empty = (depth == 0);

    reg wr_en;
    reg rd_en;

    assign s_axis_tready = !full && !pause_req;
    assign m_axis_tvalid = !empty;
    assign pause_ack = full;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            if (wr_en && !rd_en) begin
                if (depth < DEPTH) begin
                    depth <= depth + 1;
                end else begin
                    overflow <= 1;
                end
            end else if (!wr_en && rd_en) begin
                if (depth > 0) begin
                    depth <= depth - 1;
                end
            end

            if (wr_en) begin
                mem_tdata[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                mem_tkeep[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
                mem_tlast[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
                if (ID_ENABLE) mem_tid[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
                if (DEST_ENABLE) mem_tdest[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
                if (USER_ENABLE) mem_tuser[wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
                wr_ptr <= wr_ptr + 1;
            end

            if (rd_en) begin
                rd_ptr <= rd_ptr + 1;
            end

            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                good_frame <= 1;
            end

            if (s_axis_tvalid && s_axis_tready && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                bad_frame <= 1;
            end

            depth_commit <= depth;
        end
    end

    assign m_axis_tdata = mem_tdata[rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tkeep = mem_tkeep[rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tlast = mem_tlast[rd_ptr[ADDR_WIDTH-1:0]];
    assign m_axis_tid = ID_ENABLE ? mem_tid[rd_ptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tdest = DEST_ENABLE ? mem_tdest[rd_ptr[ADDR_WIDTH-1:0]] : 0;
    assign m_axis_tuser = USER_ENABLE ? mem_tuser[rd_ptr[ADDR_WIDTH-1:0]] : 0;

    assign wr_en = s_axis_tvalid && s_axis_tready;
    assign rd_en = m_axis_tvalid && m_axis_tready;

    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = overflow;
    assign status_bad_frame = bad_frame;
    assign status_good_frame = good_frame;

endmodule
