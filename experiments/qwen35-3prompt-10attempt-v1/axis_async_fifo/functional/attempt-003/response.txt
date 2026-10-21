```verilog
module axis_async_fifo #
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal wires for cross-clock pointers
    wire [LOG2_DEPTH-1:0] s_ptr;
    wire [LOG2_DEPTH-1:0] s_ptr_commit;
    wire [LOG2_DEPTH-1:0] m_ptr;
    wire [LOG2_DEPTH-1:0] m_ptr_commit;

    // Cross-clock FIFO pointers
    wire [LOG2_DEPTH-1:0] s_ptr_in;
    wire [LOG2_DEPTH-1:0] m_ptr_in;
    wire [LOG2_DEPTH-1:0] s_ptr_out;
    wire [LOG2_DEPTH-1:0] m_ptr_out;

    // Cross-clock FIFO pointers (commit)
    wire [LOG2_DEPTH-1:0] s_ptr_in_commit;
    wire [LOG2_DEPTH-1:0] m_ptr_in_commit;
    wire [LOG2_DEPTH-1:0] s_ptr_out_commit;
    wire [LOG2_DEPTH-1:0] m_ptr_out_commit;

    // Cross-clock FIFO pointers (read/write enable)
    wire s_wr_en;
    wire s_rd_en;
    wire m_wr_en;
    wire m_rd_en;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit;
    wire s_rd_en_commit;
    wire m_wr_en_commit;
    wire m_rd_en_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in;
    wire s_rd_en_commit_in;
    wire m_wr_en_commit_in;
    wire m_rd_en_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out;
    wire s_rd_en_commit_out;
    wire m_wr_en_commit_out;
    wire m_rd_en_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit;
    wire s_rd_en_commit_in_commit;
    wire m_wr_en_commit_in_commit;
    wire m_rd_en_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit;
    wire s_rd_en_commit_out_commit;
    wire m_wr_en_commit_out_commit;
    wire m_rd_en_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire s_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;
    wire m_rd_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire s_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_wr_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;
    wire m_rd_en_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit_out_commit;

    // Cross-clock FIFO pointers (read/write enable commit)
    wire s_wr_en_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in_commit_in;
    wire s_rd_en_commit_in_commit