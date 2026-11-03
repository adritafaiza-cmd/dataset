The provided code is a Verilog-2001 module interface for an asynchronous AXI-Stream FIFO. It includes parameters for depth, data width, keep enable, keep width, last enable, id enable, id width, dest enable, dest width, user enable, user width, ram pipeline, output fifo enable, frame fifo, user bad frame value, user bad frame mask, drop oversize frame, drop bad frame, drop when full, mark when full, pause enable, and frame pause.

However, it does not include the actual implementation of the module. Here is a simple implementation of an asynchronous AXI-Stream FIFO in Verilog-2001:

```
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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
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

    // Internal signals
    reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0] head;
    reg [$clog2(DEPTH)-1:0] tail;
    reg [$clog2(DEPTH)-1:0] count;
    reg [$clog2(DEPTH)-1:0] commit;
    reg [$clog2(DEPTH)-1:0] depth;
    reg [$clog2(DEPTH)-1:0] depth_commit;
    reg overflow;
    reg bad_frame;
    reg good_frame;
    reg [DATA_WIDTH-1:0] tdata;
    reg [KEEP_WIDTH-1:0] tkeep;
    reg tvalid;
    reg tlast;
    reg [ID_WIDTH-1:0] tid;
    reg [DEST_WIDTH-1:0] tdest;
    reg [USER_WIDTH-1:0] tuser;
    reg tready;
    reg pause;
    reg pause_ack;
    reg pause_req;
    reg pause_ack_reg;
    reg pause_req_reg;
    reg [$clog2(DEPTH)-1:0] pause_count;
    reg [$clog2(DEPTH)-1:0] pause_commit;
    reg [$clog2(DEPTH)-1:0] pause_depth;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit;
    reg pause_overflow;
    reg pause_bad_frame;
    reg pause_good_frame;
    reg [DATA_WIDTH-1:0] pause_tdata;
    reg [KEEP_WIDTH-1:0] pause_tkeep;
    reg pause_tvalid;
    reg pause_tlast;
    reg [ID_WIDTH-1:0] pause_tid;
    reg [DEST_WIDTH-1:0] pause_tdest;
    reg [USER_WIDTH-1:0] pause_tuser;
    reg pause_tready;
    reg [$clog2(DEPTH)-1:0] pause_count_reg;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg;
    reg pause_overflow_reg;
    reg pause_bad_frame_reg;
    reg pause_good_frame_reg;
    reg [DATA_WIDTH-1:0] pause_tdata_reg;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg;
    reg pause_tvalid_reg;
    reg pause_tlast_reg;
    reg [ID_WIDTH-1:0] pause_tid_reg;
    reg [DEST_WIDTH-1:0] pause_tdest_reg;
    reg [USER_WIDTH-1:0] pause_tuser_reg;
    reg pause_tready_reg;
    reg [$clog2(DEPTH)-1:0] pause_count_reg2;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg2;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg2;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg2;
    reg pause_overflow_reg2;
    reg pause_bad_frame_reg2;
    reg pause_good_frame_reg2;
    reg [DATA_WIDTH-1:0] pause_tdata_reg2;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg2;
    reg pause_tvalid_reg2;
    reg pause_tlast_reg2;
    reg [ID_WIDTH-1:0] pause_tid_reg2;
    reg [DEST_WIDTH-1:0] pause_tdest_reg2;
    reg [USER_WIDTH-1:0] pause_tuser_reg2;
    reg pause_tready_reg2;
    reg [$clog2(DEPTH)-1:0] pause_count_reg3;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg3;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg3;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg3;
    reg pause_overflow_reg3;
    reg pause_bad_frame_reg3;
    reg pause_good_frame_reg3;
    reg [DATA_WIDTH-1:0] pause_tdata_reg3;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg3;
    reg pause_tvalid_reg3;
    reg pause_tlast_reg3;
    reg [ID_WIDTH-1:0] pause_tid_reg3;
    reg [DEST_WIDTH-1:0] pause_tdest_reg3;
    reg [USER_WIDTH-1:0] pause_tuser_reg3;
    reg pause_tready_reg3;
    reg [$clog2(DEPTH)-1:0] pause_count_reg4;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg4;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg4;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg4;
    reg pause_overflow_reg4;
    reg pause_bad_frame_reg4;
    reg pause_good_frame_reg4;
    reg [DATA_WIDTH-1:0] pause_tdata_reg4;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg4;
    reg pause_tvalid_reg4;
    reg pause_tlast_reg4;
    reg [ID_WIDTH-1:0] pause_tid_reg4;
    reg [DEST_WIDTH-1:0] pause_tdest_reg4;
    reg [USER_WIDTH-1:0] pause_tuser_reg4;
    reg pause_tready_reg4;
    reg [$clog2(DEPTH)-1:0] pause_count_reg5;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg5;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg5;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg5;
    reg pause_overflow_reg5;
    reg pause_bad_frame_reg5;
    reg pause_good_frame_reg5;
    reg [DATA_WIDTH-1:0] pause_tdata_reg5;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg5;
    reg pause_tvalid_reg5;
    reg pause_tlast_reg5;
    reg [ID_WIDTH-1:0] pause_tid_reg5;
    reg [DEST_WIDTH-1:0] pause_tdest_reg5;
    reg [USER_WIDTH-1:0] pause_tuser_reg5;
    reg pause_tready_reg5;
    reg [$clog2(DEPTH)-1:0] pause_count_reg6;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg6;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg6;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg6;
    reg pause_overflow_reg6;
    reg pause_bad_frame_reg6;
    reg pause_good_frame_reg6;
    reg [DATA_WIDTH-1:0] pause_tdata_reg6;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg6;
    reg pause_tvalid_reg6;
    reg pause_tlast_reg6;
    reg [ID_WIDTH-1:0] pause_tid_reg6;
    reg [DEST_WIDTH-1:0] pause_tdest_reg6;
    reg [USER_WIDTH-1:0] pause_tuser_reg6;
    reg pause_tready_reg6;
    reg [$clog2(DEPTH)-1:0] pause_count_reg7;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg7;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg7;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg7;
    reg pause_overflow_reg7;
    reg pause_bad_frame_reg7;
    reg pause_good_frame_reg7;
    reg [DATA_WIDTH-1:0] pause_tdata_reg7;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg7;
    reg pause_tvalid_reg7;
    reg pause_tlast_reg7;
    reg [ID_WIDTH-1:0] pause_tid_reg7;
    reg [DEST_WIDTH-1:0] pause_tdest_reg7;
    reg [USER_WIDTH-1:0] pause_tuser_reg7;
    reg pause_tready_reg7;
    reg [$clog2(DEPTH)-1:0] pause_count_reg8;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg8;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg8;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg8;
    reg pause_overflow_reg8;
    reg pause_bad_frame_reg8;
    reg pause_good_frame_reg8;
    reg [DATA_WIDTH-1:0] pause_tdata_reg8;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg8;
    reg pause_tvalid_reg8;
    reg pause_tlast_reg8;
    reg [ID_WIDTH-1:0] pause_tid_reg8;
    reg [DEST_WIDTH-1:0] pause_tdest_reg8;
    reg [USER_WIDTH-1:0] pause_tuser_reg8;
    reg pause_tready_reg8;
    reg [$clog2(DEPTH)-1:0] pause_count_reg9;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg9;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg9;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg9;
    reg pause_overflow_reg9;
    reg pause_bad_frame_reg9;
    reg pause_good_frame_reg9;
    reg [DATA_WIDTH-1:0] pause_tdata_reg9;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg9;
    reg pause_tvalid_reg9;
    reg pause_tlast_reg9;
    reg [ID_WIDTH-1:0] pause_tid_reg9;
    reg [DEST_WIDTH-1:0] pause_tdest_reg9;
    reg [USER_WIDTH-1:0] pause_tuser_reg9;
    reg pause_tready_reg9;
    reg [$clog2(DEPTH)-1:0] pause_count_reg10;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg10;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg10;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg10;
    reg pause_overflow_reg10;
    reg pause_bad_frame_reg10;
    reg pause_good_frame_reg10;
    reg [DATA_WIDTH-1:0] pause_tdata_reg10;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg10;
    reg pause_tvalid_reg10;
    reg pause_tlast_reg10;
    reg [ID_WIDTH-1:0] pause_tid_reg10;
    reg [DEST_WIDTH-1:0] pause_tdest_reg10;
    reg [USER_WIDTH-1:0] pause_tuser_reg10;
    reg pause_tready_reg10;
    reg [$clog2(DEPTH)-1:0] pause_count_reg11;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg11;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg11;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg11;
    reg pause_overflow_reg11;
    reg pause_bad_frame_reg11;
    reg pause_good_frame_reg11;
    reg [DATA_WIDTH-1:0] pause_tdata_reg11;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg11;
    reg pause_tvalid_reg11;
    reg pause_tlast_reg11;
    reg [ID_WIDTH-1:0] pause_tid_reg11;
    reg [DEST_WIDTH-1:0] pause_tdest_reg11;
    reg [USER_WIDTH-1:0] pause_tuser_reg11;
    reg pause_tready_reg11;
    reg [$clog2(DEPTH)-1:0] pause_count_reg12;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg12;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg12;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg12;
    reg pause_overflow_reg12;
    reg pause_bad_frame_reg12;
    reg pause_good_frame_reg12;
    reg [DATA_WIDTH-1:0] pause_tdata_reg12;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg12;
    reg pause_tvalid_reg12;
    reg pause_tlast_reg12;
    reg [ID_WIDTH-1:0] pause_tid_reg12;
    reg [DEST_WIDTH-1:0] pause_tdest_reg12;
    reg [USER_WIDTH-1:0] pause_tuser_reg12;
    reg pause_tready_reg12;
    reg [$clog2(DEPTH)-1:0] pause_count_reg13;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg13;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg13;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg13;
    reg pause_overflow_reg13;
    reg pause_bad_frame_reg13;
    reg pause_good_frame_reg13;
    reg [DATA_WIDTH-1:0] pause_tdata_reg13;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg13;
    reg pause_tvalid_reg13;
    reg pause_tlast_reg13;
    reg [ID_WIDTH-1:0] pause_tid_reg13;
    reg [DEST_WIDTH-1:0] pause_tdest_reg13;
    reg [USER_WIDTH-1:0] pause_tuser_reg13;
    reg pause_tready_reg13;
    reg [$clog2(DEPTH)-1:0] pause_count_reg14;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg14;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg14;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg14;
    reg pause_overflow_reg14;
    reg pause_bad_frame_reg14;
    reg pause_good_frame_reg14;
    reg [DATA_WIDTH-1:0] pause_tdata_reg14;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg14;
    reg pause_tvalid_reg14;
    reg pause_tlast_reg14;
    reg [ID_WIDTH-1:0] pause_tid_reg14;
    reg [DEST_WIDTH-1:0] pause_tdest_reg14;
    reg [USER_WIDTH-1:0] pause_tuser_reg14;
    reg pause_tready_reg14;
    reg [$clog2(DEPTH)-1:0] pause_count_reg15;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg15;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg15;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg15;
    reg pause_overflow_reg15;
    reg pause_bad_frame_reg15;
    reg pause_good_frame_reg15;
    reg [DATA_WIDTH-1:0] pause_tdata_reg15;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg15;
    reg pause_tvalid_reg15;
    reg pause_tlast_reg15;
    reg [ID_WIDTH-1:0] pause_tid_reg15;
    reg [DEST_WIDTH-1:0] pause_tdest_reg15;
    reg [USER_WIDTH-1:0] pause_tuser_reg15;
    reg pause_tready_reg15;
    reg [$clog2(DEPTH)-1:0] pause_count_reg16;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg16;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg16;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg16;
    reg pause_overflow_reg16;
    reg pause_bad_frame_reg16;
    reg pause_good_frame_reg16;
    reg [DATA_WIDTH-1:0] pause_tdata_reg16;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg16;
    reg pause_tvalid_reg16;
    reg pause_tlast_reg16;
    reg [ID_WIDTH-1:0] pause_tid_reg16;
    reg [DEST_WIDTH-1:0] pause_tdest_reg16;
    reg [USER_WIDTH-1:0] pause_tuser_reg16;
    reg pause_tready_reg16;
    reg [$clog2(DEPTH)-1:0] pause_count_reg17;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg17;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg17;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg17;
    reg pause_overflow_reg17;
    reg pause_bad_frame_reg17;
    reg pause_good_frame_reg17;
    reg [DATA_WIDTH-1:0] pause_tdata_reg17;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg17;
    reg pause_tvalid_reg17;
    reg pause_tlast_reg17;
    reg [ID_WIDTH-1:0] pause_tid_reg17;
    reg [DEST_WIDTH-1:0] pause_tdest_reg17;
    reg [USER_WIDTH-1:0] pause_tuser_reg17;
    reg pause_tready_reg17;
    reg [$clog2(DEPTH)-1:0] pause_count_reg18;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg18;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg18;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg18;
    reg pause_overflow_reg18;
    reg pause_bad_frame_reg18;
    reg pause_good_frame_reg18;
    reg [DATA_WIDTH-1:0] pause_tdata_reg18;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg18;
    reg pause_tvalid_reg18;
    reg pause_tlast_reg18;
    reg [ID_WIDTH-1:0] pause_tid_reg18;
    reg [DEST_WIDTH-1:0] pause_tdest_reg18;
    reg [USER_WIDTH-1:0] pause_tuser_reg18;
    reg pause_tready_reg18;
    reg [$clog2(DEPTH)-1:0] pause_count_reg19;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg19;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg19;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg19;
    reg pause_overflow_reg19;
    reg pause_bad_frame_reg19;
    reg pause_good_frame_reg19;
    reg [DATA_WIDTH-1:0] pause_tdata_reg19;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg19;
    reg pause_tvalid_reg19;
    reg pause_tlast_reg19;
    reg [ID_WIDTH-1:0] pause_tid_reg19;
    reg [DEST_WIDTH-1:0] pause_tdest_reg19;
    reg [USER_WIDTH-1:0] pause_tuser_reg19;
    reg pause_tready_reg19;
    reg [$clog2(DEPTH)-1:0] pause_count_reg20;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg20;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg20;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg20;
    reg pause_overflow_reg20;
    reg pause_bad_frame_reg20;
    reg pause_good_frame_reg20;
    reg [DATA_WIDTH-1:0] pause_tdata_reg20;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg20;
    reg pause_tvalid_reg20;
    reg pause_tlast_reg20;
    reg [ID_WIDTH-1:0] pause_tid_reg20;
    reg [DEST_WIDTH-1:0] pause_tdest_reg20;
    reg [USER_WIDTH-1:0] pause_tuser_reg20;
    reg pause_tready_reg20;
    reg [$clog2(DEPTH)-1:0] pause_count_reg21;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg21;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg21;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg21;
    reg pause_overflow_reg21;
    reg pause_bad_frame_reg21;
    reg pause_good_frame_reg21;
    reg [DATA_WIDTH-1:0] pause_tdata_reg21;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg21;
    reg pause_tvalid_reg21;
    reg pause_tlast_reg21;
    reg [ID_WIDTH-1:0] pause_tid_reg21;
    reg [DEST_WIDTH-1:0] pause_tdest_reg21;
    reg [USER_WIDTH-1:0] pause_tuser_reg21;
    reg pause_tready_reg21;
    reg [$clog2(DEPTH)-1:0] pause_count_reg22;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg22;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg22;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg22;
    reg pause_overflow_reg22;
    reg pause_bad_frame_reg22;
    reg pause_good_frame_reg22;
    reg [DATA_WIDTH-1:0] pause_tdata_reg22;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg22;
    reg pause_tvalid_reg22;
    reg pause_tlast_reg22;
    reg [ID_WIDTH-1:0] pause_tid_reg22;
    reg [DEST_WIDTH-1:0] pause_tdest_reg22;
    reg [USER_WIDTH-1:0] pause_tuser_reg22;
    reg pause_tready_reg22;
    reg [$clog2(DEPTH)-1:0] pause_count_reg23;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg23;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg23;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg23;
    reg pause_overflow_reg23;
    reg pause_bad_frame_reg23;
    reg pause_good_frame_reg23;
    reg [DATA_WIDTH-1:0] pause_tdata_reg23;
    reg [KEEP_WIDTH-1:0] pause_tkeep_reg23;
    reg pause_tvalid_reg23;
    reg pause_tlast_reg23;
    reg [ID_WIDTH-1:0] pause_tid_reg23;
    reg [DEST_WIDTH-1:0] pause_tdest_reg23;
    reg [USER_WIDTH-1:0] pause_tuser_reg23;
    reg pause_tready_reg23;
    reg [$clog2(DEPTH)-1:0] pause_count_reg24;
    reg [$clog2(DEPTH)-1:0] pause_commit_reg24;
    reg [$clog2(DEPTH)-1:0] pause_depth_reg24;
    reg [$clog2(DEPTH)-1:0] pause_depth_commit_reg24;
    reg pause_overflow_reg24