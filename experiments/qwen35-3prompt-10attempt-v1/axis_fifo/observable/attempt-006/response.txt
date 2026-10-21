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
    localparam FULL_THRESHOLD = DEPTH - 1;
    localparam EMPTY_THRESHOLD = 0;

    // Internal signals
    reg [LOG2_DEPTH-1:0] wr_ptr;
    reg [LOG2_DEPTH-1:0] rd_ptr;
    reg [LOG2_DEPTH-1:0] next_wr_ptr;
    reg [LOG2_DEPTH-1:0] next_rd_ptr;
    reg [LOG2_DEPTH-1:0] commit_ptr;
    reg [LOG2_DEPTH-1:0] commit_next_ptr;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr;
    
    reg [DEPTH-1:0] wr_en;
    reg [DEPTH-1:0] rd_en;
    reg [DEPTH-1:0] data_mem;
    reg [KEEP_WIDTH-1:0] keep_mem;
    reg [LOG2_DEPTH-1:0] last_mem;
    reg [ID_WIDTH-1:0] id_mem;
    reg [DEST_WIDTH-1:0] dest_mem;
    reg [USER_WIDTH-1:0] user_mem;
    
    reg [DEPTH-1:0] wr_valid;
    reg [DEPTH-1:0] rd_valid;
    reg [DEPTH-1:0] wr_ready;
    reg [DEPTH-1:0] rd_ready;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr;
    reg [LOG2_DEPTH-1:0] frame_end_ptr;
    reg frame_active;
    reg frame_bad;
    reg frame_oversize;
    reg frame_complete;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr;
    reg [DEPTH-1:0] output_fifo_wr_en;
    reg [DEPTH-1:0] output_fifo_rd_en;
    reg [DEPTH-1:0] output_fifo_data;
    reg [KEEP_WIDTH-1:0] output_fifo_keep;
    reg [LOG2_DEPTH-1:0] output_fifo_last;
    reg [ID_WIDTH-1:0] output_fifo_id;
    reg [DEST_WIDTH-1:0] output_fifo_dest;
    reg [USER_WIDTH-1:0] output_fifo_user;
    reg [DEPTH-1:0] output_fifo_valid;
    reg [DEPTH-1:0] output_fifo_ready;
    
    reg [LOG2_DEPTH-1:0] pause_ptr;
    reg [DEPTH-1:0] pause_wr_en;
    reg [DEPTH-1:0] pause_rd_en;
    reg [DEPTH-1:0] pause_data;
    reg [DEPTH-1:0] pause_valid;
    reg [DEPTH-1:0] pause_ready;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg;
    reg frame_active_reg;
    reg frame_bad_reg;
    reg frame_oversize_reg;
    reg frame_complete_reg;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg;
    reg [DEPTH-1:0] output_fifo_wr_en_reg;
    reg [DEPTH-1:0] output_fifo_rd_en_reg;
    reg [DEPTH-1:0] output_fifo_data_reg;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg;
    reg [ID_WIDTH-1:0] output_fifo_id_reg;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg;
    reg [USER_WIDTH-1:0] output_fifo_user_reg;
    reg [DEPTH-1:0] output_fifo_valid_reg;
    reg [DEPTH-1:0] output_fifo_ready_reg;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg;
    reg [DEPTH-1:0] pause_wr_en_reg;
    reg [DEPTH-1:0] pause_rd_en_reg;
    reg [DEPTH-1:0] pause_data_reg;
    reg [DEPTH-1:0] pause_valid_reg;
    reg [DEPTH-1:0] pause_ready_reg;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next;
    reg frame_active_reg_next;
    reg frame_bad_reg_next;
    reg frame_oversize_reg_next;
    reg frame_complete_reg_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next;
    reg [DEPTH-1:0] pause_data_reg_next;
    reg [DEPTH-1:0] pause_valid_reg_next;
    reg [DEPTH-1:0] pause_ready_reg_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next;
    reg frame_active_reg_next_next;
    reg frame_bad_reg_next_next;
    reg frame_oversize_reg_next_next;
    reg frame_complete_reg_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next;
    reg frame_active_reg_next_next_next;
    reg frame_bad_reg_next_next_next;
    reg frame_oversize_reg_next_next_next;
    reg frame_complete_reg_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next;
    reg frame_active_reg_next_next_next_next;
    reg frame_bad_reg_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next;
    reg frame_complete_reg_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_last_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [ID_WIDTH-1:0] output_fifo_id_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEST_WIDTH-1:0] output_fifo_dest_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [USER_WIDTH-1:0] output_fifo_user_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_valid_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_ready_reg_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] pause_ptr_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_wr_en_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_rd_en_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_data_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_valid_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] pause_ready_reg_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] commit_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_rd_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] commit_wr_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] frame_start_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] frame_end_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_active_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_bad_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_oversize_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg frame_complete_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    
    reg [LOG2_DEPTH-1:0] output_fifo_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [LOG2_DEPTH-1:0] output_fifo_commit_ptr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_wr_en_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_rd_en_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [DEPTH-1:0] output_fifo_data_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [KEEP_WIDTH-1:0] output_fifo_keep_reg_next_next_next_next_next_next_next_next_next_next_next_next