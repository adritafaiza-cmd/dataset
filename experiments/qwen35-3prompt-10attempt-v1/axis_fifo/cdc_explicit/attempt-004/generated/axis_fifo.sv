```verilog
`timescale 1ns/1ps

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

    // Internal parameters for sizing
    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);
    
    // Frame parameters
    localparam FRAME_DATA_WIDTH = DATA_WIDTH;
    localparam FRAME_KEEP_WIDTH = KEEP_WIDTH;
    localparam FRAME_LAST_ENABLE = LAST_ENABLE;
    localparam FRAME_ID_ENABLE = ID_ENABLE;
    localparam FRAME_ID_WIDTH = ID_WIDTH;
    localparam FRAME_DEST_ENABLE = DEST_ENABLE;
    localparam FRAME_DEST_WIDTH = DEST_WIDTH;
    localparam FRAME_USER_ENABLE = USER_ENABLE;
    localparam FRAME_USER_WIDTH = USER_WIDTH;
    localparam FRAME_BAD_FRAME_VALUE = USER_BAD_FRAME_VALUE;
    localparam FRAME_BAD_FRAME_MASK = USER_BAD_FRAME_MASK;
    localparam FRAME_DROP_OVERSIZE = DROP_OVERSIZE_FRAME;
    localparam FRAME_DROP_BAD = DROP_BAD_FRAME;
    localparam FRAME_PAUSE = FRAME_PAUSE;

    // Internal signals
    wire [LOG2_DEPTH:0] wr_addr;
    wire [LOG2_DEPTH:0] rd_addr;
    wire [LOG2_DEPTH:0] next_rd_addr;
    wire [LOG2_DEPTH:0] next_wr_addr;
    wire [LOG2_DEPTH:0] next_rd_addr_commit;
    wire [LOG2_DEPTH:0] next_wr_addr_commit;
    wire [LOG2_DEPTH:0] next_rd_addr_pause;
    wire [LOG2_DEPTH:0] next_wr_addr_pause;
    
    wire [LOG2_DEPTH:0] wr_addr_commit;
    wire [LOG2_DEPTH:0] rd_addr_commit;
    
    wire [LOG2_DEPTH:0] wr_addr_pause;
    wire [LOG2_DEPTH:0] rd_addr_pause;
    
    wire [LOG2_DEPTH:0] wr_addr_frame;
    wire [LOG2_DEPTH:0] rd_addr_frame;
    
    wire [LOG2_DEPTH:0] wr_addr_bad;
    wire [LOG2_DEPTH:0] rd_addr_bad;
    
    wire [LOG2_DEPTH:0] wr_addr_full;
    wire [LOG2_DEPTH:0] rd_addr_full;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req;
    wire [LOG2_DEPTH:0] rd_addr_pause_req;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_status;
    wire [LOG2_DEPTH:0] rd_addr_status;
    
    wire [LOG2_DEPTH:0] wr_addr_depth;
    wire [LOG2_DEPTH:0] rd_addr_depth;
    
    wire [LOG2_DEPTH:0] wr_addr_commit_depth;
    wire [LOG2_DEPTH:0] rd_addr_commit_depth;
    
    wire [LOG2_DEPTH:0] wr_addr_overflow;
    wire [LOG2_DEPTH:0] rd_addr_overflow;
    
    wire [LOG2_DEPTH:0] wr_addr_bad_frame;
    wire [LOG2_DEPTH:0] rd_addr_bad_frame;
    
    wire [LOG2_DEPTH:0] wr_addr_good_frame;
    wire [LOG2_DEPTH:0] rd_addr_good_frame;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    wire [LOG2_DEPTH:0] rd_addr_pause_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack;
    
    wire [LOG2_DEPTH:0] wr_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done;
    wire [LOG2_DEPTH:0] rd_addr_pause_req_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack_done_ack