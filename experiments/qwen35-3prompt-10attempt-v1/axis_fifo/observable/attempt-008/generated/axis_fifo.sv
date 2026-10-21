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

    // Internal signals for pipeline stages
    wire [LOG2_DEPTH:0] wr_addr;
    wire [LOG2_DEPTH:0] rd_addr;
    wire [LOG2_DEPTH:0] wr_addr_next;
    wire [LOG2_DEPTH:0] rd_addr_next;
    
    // Write pointer logic
    reg [LOG2_DEPTH:0] wr_ptr;
    reg [LOG2_DEPTH:0] rd_ptr;
    reg [LOG2_DEPTH:0] wr_ptr_next;
    reg [LOG2_DEPTH:0] rd_ptr_next;
    
    // FIFO Depth counters
    reg [LOG2_DEPTH:0] depth_count;
    reg [LOG2_DEPTH:0] depth_count_next;
    
    // Control signals
    reg s_axis_tready_int;
    reg m_axis_tvalid_int;
    reg m_axis_tlast_int;
    reg [ID_WIDTH-1:0] m_axis_tid_int;
    reg [DEST_WIDTH-1:0] m_axis_tdest_int;
    reg [USER_WIDTH-1:0] m_axis_tuser_int;
    reg [DATA_WIDTH-1:0] m_axis_tdata_int;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_int;
    reg bad_frame_flag;
    reg oversize_frame_flag;
    reg pause_state;
    reg pause_ack_int;
    
    // RAM Pipeline Stages
    wire [DATA_WIDTH-1:0] ram_data_in;
    wire [KEEP_WIDTH-1:0] ram_keep_in;
    wire [ID_WIDTH-1:0] ram_id_in;
    wire [DEST_WIDTH-1:0] ram_dest_in;
    wire [USER_WIDTH-1:0] ram_user_in;
    wire [DATA_WIDTH-1:0] ram_data_out;
    wire [KEEP_WIDTH-1:0] ram_keep_out;
    wire [ID_WIDTH-1:0] ram_id_out;
    wire [DEST_WIDTH-1:0] ram_dest_out;
    wire [USER_WIDTH-1:0] ram_user_out;
    wire ram_wr_en;
    wire ram_rd_en;
    wire ram_wr_clk;
    wire ram_rd_clk;
    
    // Output FIFO
    wire [DATA_WIDTH-1:0] out_fifo_data_in;
    wire [KEEP_WIDTH-1:0] out_fifo_keep_in;
    wire [ID_WIDTH-1:0] out_fifo_id_in;
    wire [DEST_WIDTH-1:0] out_fifo_dest_in;
    wire [USER_WIDTH-1:0] out_fifo_user_in;
    wire out_fifo_wr_en;
    wire out_fifo_rd_en;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire out_fifo_wr_clk;
    wire out_fifo_rd_clk;

    // Generate RAM Pipeline
    generate
        if (RAM_PIPELINE) begin : gen_ram_pipeline
            // Write path
            assign ram_wr_clk = clk;
            assign ram_wr_en = s_axis_tvalid_int & s_axis_tready_int;
            
            assign ram_data_in = s_axis_tdata;
            assign ram_keep_in = s_axis_tkeep;
            assign ram_id_in = s_axis_tid;
            assign ram_dest_in = s_axis_tdest;
            assign ram_user_in = s_axis_tuser;
            
            // Read path
            assign ram_rd_clk = clk;
            assign ram_rd_en = m_axis_tvalid_int & m_axis_tready;
            
            assign m_axis_tdata_int = ram_data_out;
            assign m_axis_tkeep_int = ram_keep_out;
            assign m_axis_tid_int = ram_id_out;
            assign m_axis_tdest_int = ram_dest_out;
            assign m_axis_tuser_int = ram_user_out;
            
            // Address generation
            assign wr_addr = wr_ptr;
            assign rd_addr = rd_ptr;
            
            assign wr_addr_next = (wr_ptr == (DEPTH-1)) ? 0 : wr_ptr + 1;
            assign rd_addr_next = (rd_ptr == (DEPTH-1)) ? 0 : rd_ptr + 1;
            
            assign wr_ptr_next = wr_addr_next;
            assign rd_ptr_next = rd_addr_next;
            
            // Depth counter
            assign depth_count_next = (wr_addr == rd_addr) ? 0 : depth_count + 1;
            assign depth_count = depth_count_next;
            
            // Status signals
            assign status_depth = depth_count;
            assign status_depth_commit = depth_count;
            assign status_overflow = (depth_count == (DEPTH-1)) && s_axis_tvalid_int;
            assign status_bad_frame = bad_frame_flag;
            assign status_good_frame = !bad_frame_flag;
            
            // Pause logic
            assign pause_ack_int = (depth_count < (DEPTH-1)) && !pause_state;
            assign pause_ack = pause_ack_int;
            assign pause_state = (pause_req && !pause_ack_int);
            
            // Bad frame detection
            assign bad_frame_flag = (s_axis_tvalid_int && s_axis_tready_int && 
                                     (s_axis_tkeep == USER_BAD_FRAME_MASK) && 
                                     (s_axis_tuser == USER_BAD_FRAME_VALUE));
            
            // Oversize frame detection
            assign oversize_frame_flag = (s_axis_tvalid_int && s_axis_tready_int && 
                                          (s_axis_tkeep == USER_BAD_FRAME_MASK));
            
            // Drop/Mark logic
            reg drop_flag;
            reg mark_flag;
            
            assign drop_flag = (DROP_WHEN_FULL && (depth_count == (DEPTH-1))) ||
                               (DROP_BAD_FRAME && bad_frame_flag) ||
                               (DROP_OVERSIZE_FRAME && oversize_frame_flag);
            
            assign mark_flag = (MARK_WHEN_FULL && (depth_count == (DEPTH-1)));
            
            // Write enable logic
            reg wr_en;
            assign wr_en = s_axis_tvalid_int & s_axis_tready_int & !drop_flag;
            
            // Read enable logic
            reg rd_en;
            assign rd_en = m_axis_tvalid_int & m_axis_tready & !pause_state;
            
            // Output FIFO
            assign out_fifo_wr_clk = clk;
            assign out_fifo_wr_en = rd_en;
            assign out_fifo_data_in = m_axis_tdata_int;
            assign out_fifo_keep_in = m_axis_tkeep_int;
            assign out_fifo_id_in = m_axis_tid_int;
            assign out_fifo_dest_in = m_axis_tdest_int;
            assign out_fifo_user_in = m_axis_tuser_int;
            
            assign out_fifo_rd_clk = clk;
            assign out_fifo_rd_en = m_axis_tvalid_int & m_axis_tready;
            
            assign m_axis_tdata = out_fifo_data_in;
            assign m_axis_tkeep = out_fifo_keep_in;
            assign m_axis_tid = out_fifo_id_in;
            assign m_axis_tdest = out_fifo_dest_in;
            assign m_axis_tuser = out_fifo_user_in;
            
            assign m_axis_tvalid_int = out_fifo_wr_en;
            assign m_axis_tlast_int = s_axis_tlast;
            
            // Output FIFO empty/full signals
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign m_axis_tvalid_int = out_fifo_wr_en;
            assign m_axis_tready = out_fifo_rd_en;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr_en;
            
            // Output FIFO depth
            reg [LOG2_DEPTH:0] out_fifo_depth;
            assign out_fifo_depth = out_fifo_wr_en ? out_fifo_depth + 1 : out_fifo_depth - 1;
            assign status_depth_commit = out_fifo_depth;
            
            // Output FIFO empty/full
            assign out_fifo_empty = out_fifo_rd_en;
            assign out_fifo_full = out_fifo_wr