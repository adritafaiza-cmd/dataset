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
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   pause_req,
    output wire                   pause_ack,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal signals
    reg [LOG2_DEPTH-1:0] wr_ptr;
    reg [LOG2_DEPTH-1:0] rd_ptr;
    reg [LOG2_DEPTH-1:0] wr_ptr_commit;
    reg [LOG2_DEPTH-1:0] rd_ptr_commit;
    reg [LOG2_DEPTH:0] full_cnt;
    reg [LOG2_DEPTH:0] empty_cnt;
    reg [LOG2_DEPTH-1:0] head;
    reg [LOG2_DEPTH-1:0] tail;
    
    // Frame state machine
    reg [LOG2_DEPTH-1:0] frame_head;
    reg [LOG2_DEPTH-1:0] frame_tail;
    reg [LOG2_DEPTH:0] frame_full_cnt;
    reg frame_in_frame;
    reg frame_frame_valid;
    reg frame_frame_last;
    reg frame_frame_id;
    reg frame_frame_dest;
    reg frame_frame_user;
    reg frame_frame_keep;
    reg frame_frame_data;
    reg frame_frame_last_flag;
    reg frame_frame_drop;
    reg frame_frame_mark;
    reg frame_frame_pause;
    reg frame_frame_bad;
    reg frame_frame_good;
    
    // Output FIFO state
    reg [LOG2_DEPTH-1:0] out_wr_ptr;
    reg [LOG2_DEPTH-1:1] out_wr_ptr_commit;
    reg [LOG2_DEPTH-1:0] out_rd_ptr;
    reg [LOG2_DEPTH-1:0] out_rd_ptr_commit;
    reg [LOG2_DEPTH:0] out_full_cnt;
    reg [LOG2_DEPTH:0] out_empty_cnt;
    reg [LOG2_DEPTH-1:0] out_head;
    reg [LOG2_DEPTH-1:0] out_tail;
    reg out_frame_valid;
    reg out_frame_last;
    reg out_frame_id;
    reg out_frame_dest;
    reg out_frame_user;
    reg out_frame_keep;
    reg out_frame_data;
    reg out_frame_last_flag;
    reg out_frame_drop;
    reg out_frame_mark;
    reg out_frame_pause;
    reg out_frame_bad;
    reg out_frame_good;

    // RAMs
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] out_ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_ram_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_ram_user [0:DEPTH-1];
    reg out_ram_last [0:DEPTH-1];

    // Frame RAMs
    reg [DATA_WIDTH-1:0] frame_ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_ram_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_ram_user [0:DEPTH-1];
    reg frame_ram_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH-1];
    reg frame_fifo_last [0:DEPTH-1];

    // Output FIFO RAMs
    reg [DATA_WIDTH-1:0] out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] out_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] out_fifo_user [0:DEPTH-1];
    reg out_fifo_last [0:DEPTH-1];

    // Frame FIFO RAMs
    reg [DATA_WIDTH-1:0] frame_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] frame_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] frame_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] frame_fifo_user [0:DEPTH