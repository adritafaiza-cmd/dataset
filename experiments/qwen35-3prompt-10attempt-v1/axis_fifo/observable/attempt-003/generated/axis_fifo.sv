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

    // Internal signals for frame tracking
    reg [LOG2_DEPTH-1:0] frame_head;
    reg [LOG2_DEPTH-1:0] frame_tail;
    reg frame_valid;
    reg frame_full;
    reg frame_empty;
    reg [LOG2_DEPTH-1:0] frame_count;
    reg frame_bad;
    reg frame_oversize;
    reg frame_pause;

    // Output FIFO depth tracking
    reg [$clog2(DEPTH):0] out_fifo_count;
    reg [$clog2(DEPTH):0] out_fifo_commit;
    reg out_fifo_full;
    reg out_fifo_empty;

    // Pipeline registers for RAM output
    reg [DATA_WIDTH-1:0] ram_data_out;
    reg [KEEP_WIDTH-1:0] ram_keep_out;
    reg s_axis_tlast_pipe;
    reg [ID_WIDTH-1:0] ram_tid_out;
    reg [DEST_WIDTH-1:0] ram_tdest_out;
    reg [USER_WIDTH-1:0] ram_tuser_out;
    reg m_axis_tvalid_pipe;
    reg m_axis_tlast_pipe;
    reg m_axis_tid_pipe;
    reg m_axis_tdest_pipe;
    reg m_axis_tuser_pipe;

    // Frame state machine
    reg frame_state; // 0: Idle, 1: Collecting, 2: Bad Frame Detected, 3: Oversize Detected
    reg frame_collecting;
    reg frame_bad_detected;
    reg frame_oversize_detected;
    reg frame_pause_req;

    // Input FIFO pointers
    reg [LOG2_DEPTH-1:0] in_head;
    reg [LOG2_DEPTH-1:0] in_tail;
    reg in_full;
    reg in_empty;
    reg [LOG2_DEPTH-1:0] in_count;

    // Frame pointers
    reg [LOG2_DEPTH-1:0] frame_in_head;
    reg [LOG2_DEPTH-1:0] frame_in_tail;
    reg frame_in_full;
    reg frame_in_empty;
    reg [LOG2_DEPTH-1:0] frame_in_count;

    // Frame data storage
    reg [DATA_WIDTH-1:0] frame_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_keep [0:DEPTH-1];
    reg frame_last [0:DEPTH-1];
    reg frame_tid [0:DEPTH-1];
    reg frame_tdest [0:DEPTH-1];
    reg frame_tuser [0:DEPTH-1];
    reg frame_valid [0:DEPTH-1];

    // Frame output pointers
    reg [LOG2_DEPTH-1:0] frame_out_head;
    reg [LOG2_DEPTH-1:0] frame_out_tail;
    reg frame_out_full;
    reg frame_out_empty;
    reg [LOG2_DEPTH-1:0] frame_out_count;

    // Frame output data storage
    reg [DATA_WIDTH-1:0] frame_out_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out_keep [0:DEPTH-1];
    reg frame_out_last [0:DEPTH-1];
    reg frame_out_tid [0:DEPTH-1];
    reg frame_out_tdest [0:DEPTH-1];
    reg frame_out_tuser [0:DEPTH-1];
    reg frame_out_valid [0:DEPTH-1];

    // Frame output pointers (second stage)
    reg [LOG2_DEPTH-1:0] frame_out2_head;
    reg [LOG2_DEPTH-1:0] frame_out2_tail;
    reg frame_out2_full;
    reg frame_out2_empty;
    reg [LOG2_DEPTH-1:0] frame_out2_count;

    // Frame output data storage (second stage)
    reg [DATA_WIDTH-1:0] frame_out2_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out2_keep [0:DEPTH-1];
    reg frame_out2_last [0:DEPTH-1];
    reg frame_out2_tid [0:DEPTH-1];
    reg frame_out2_tdest [0:DEPTH-1];
    reg frame_out2_tuser [0:DEPTH-1];
    reg frame_out2_valid [0:DEPTH-1];

    // Frame output pointers (third stage)
    reg [LOG2_DEPTH-1:0] frame_out3_head;
    reg [LOG2_DEPTH-1:0] frame_out3_tail;
    reg frame_out3_full;
    reg frame_out3_empty;
    reg [LOG2_DEPTH-1:0] frame_out3_count;

    // Frame output data storage (third stage)
    reg [DATA_WIDTH-1:0] frame_out3_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out3_keep [0:DEPTH-1];
    reg frame_out3_last [0:DEPTH-1];
    reg frame_out3_tid [0:DEPTH-1];
    reg frame_out3_tdest [0:DEPTH-1];
    reg frame_out3_tuser [0:DEPTH-1];
    reg frame_out3_valid [0:DEPTH-1];

    // Frame output pointers (fourth stage)
    reg [LOG2_DEPTH-1:0] frame_out4_head;
    reg [LOG2_DEPTH-1:0] frame_out4_tail;
    reg frame_out4_full;
    reg frame_out4_empty;
    reg [LOG2_DEPTH-1:0] frame_out4_count;

    // Frame output data storage (fourth stage)
    reg [DATA_WIDTH-1:0] frame_out4_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out4_keep [0:DEPTH-1];
    reg frame_out4_last [0:DEPTH-1];
    reg frame_out4_tid [0:DEPTH-1];
    reg frame_out4_tdest [0:DEPTH-1];
    reg frame_out4_tuser [0:DEPTH-1];
    reg frame_out4_valid [0:DEPTH-1];

    // Frame output pointers (fifth stage)
    reg [LOG2_DEPTH-1:0] frame_out5_head;
    reg [LOG2_DEPTH-1:0] frame_out5_tail;
    reg frame_out5_full;
    reg frame_out5_empty;
    reg [LOG2_DEPTH-1:0] frame_out5_count;

    // Frame output data storage (fifth stage)
    reg [DATA_WIDTH-1:0] frame_out5_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out5_keep [0:DEPTH-1];
    reg frame_out5_last [0:DEPTH-1];
    reg frame_out5_tid [0:DEPTH-1];
    reg frame_out5_tdest [0:DEPTH-1];
    reg frame_out5_tuser [0:DEPTH-1];
    reg frame_out5_valid [0:DEPTH-1];

    // Frame output pointers (sixth stage)
    reg [LOG2_DEPTH-1:0] frame_out6_head;
    reg [LOG2_DEPTH-1:0] frame_out6_tail;
    reg frame_out6_full;
    reg frame_out6_empty;
    reg [LOG2_DEPTH-1:0] frame_out6_count;

    // Frame output data storage (sixth stage)
    reg [DATA_WIDTH-1:0] frame_out6_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out6_keep [0:DEPTH-1];
    reg frame_out6_last [0:DEPTH-1];
    reg frame_out6_tid [0:DEPTH-1];
    reg frame_out6_tdest [0:DEPTH-1];
    reg frame_out6_tuser [0:DEPTH-1];
    reg frame_out6_valid [0:DEPTH-1];

    // Frame output pointers (seventh stage)
    reg [LOG2_DEPTH-1:0] frame_out7_head;
    reg [LOG2_DEPTH-1:0] frame_out7_tail;
    reg frame_out7_full;
    reg frame_out7_empty;
    reg [LOG2_DEPTH-1:0] frame_out7_count;

    // Frame output data storage (seventh stage)
    reg [DATA_WIDTH-1:0] frame_out7_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out7_keep [0:DEPTH-1];
    reg frame_out7_last [0:DEPTH-1];
    reg frame_out7_tid [0:DEPTH-1];
    reg frame_out7_tdest [0:DEPTH-1];
    reg frame_out7_tuser [0:DEPTH-1];
    reg frame_out7_valid [0:DEPTH-1];

    // Frame output pointers (eighth stage)
    reg [LOG2_DEPTH-1:0] frame_out8_head;
    reg [LOG2_DEPTH-1:0] frame_out8_tail;
    reg frame_out8_full;
    reg frame_out8_empty;
    reg [LOG2_DEPTH-1:0] frame_out8_count;

    // Frame output data storage (eighth stage)
    reg [DATA_WIDTH-1:0] frame_out8_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out8_keep [0:DEPTH-1];
    reg frame_out8_last [0:DEPTH-1];
    reg frame_out8_tid [0:DEPTH-1];
    reg frame_out8_tdest [0:DEPTH-1];
    reg frame_out8_tuser [0:DEPTH-1];
    reg frame_out8_valid [0:DEPTH-1];

    // Frame output pointers (ninth stage)
    reg [LOG2_DEPTH-1:0] frame_out9_head;
    reg [LOG2_DEPTH-1:0] frame_out9_tail;
    reg frame_out9_full;
    reg frame_out9_empty;
    reg [LOG2_DEPTH-1:0] frame_out9_count;

    // Frame output data storage (ninth stage)
    reg [DATA_WIDTH-1:0] frame_out9_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out9_keep [0:DEPTH-1];
    reg frame_out9_last [0:DEPTH-1];
    reg frame_out9_tid [0:DEPTH-1];
    reg frame_out9_tdest [0:DEPTH-1];
    reg frame_out9_tuser [0:DEPTH-1];
    reg frame_out9_valid [0:DEPTH-1];

    // Frame output pointers (tenth stage)
    reg [LOG2_DEPTH-1:0] frame_out10_head;
    reg [LOG2_DEPTH-1:0] frame_out10_tail;
    reg frame_out10_full;
    reg frame_out10_empty;
    reg [LOG2_DEPTH-1:0] frame_out10_count;

    // Frame output data storage (tenth stage)
    reg [DATA_WIDTH-1:0] frame_out10_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out10_keep [0:DEPTH-1];
    reg frame_out10_last [0:DEPTH-1];
    reg frame_out10_tid [0:DEPTH-1];
    reg frame_out10_tdest [0:DEPTH-1];
    reg frame_out10_tuser [0:DEPTH-1];
    reg frame_out10_valid [0:DEPTH-1];

    // Frame output pointers (eleventh stage)
    reg [LOG2_DEPTH-1:0] frame_out11_head;
    reg [LOG2_DEPTH-1:0] frame_out11_tail;
    reg frame_out11_full;
    reg frame_out11_empty;
    reg [LOG2_DEPTH-1:0] frame_out11_count;

    // Frame output data storage (eleventh stage)
    reg [DATA_WIDTH-1:0] frame_out11_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out11_keep [0:DEPTH-1];
    reg frame_out11_last [0:DEPTH-1];
    reg frame_out11_tid [0:DEPTH-1];
    reg frame_out11_tdest [0:DEPTH-1];
    reg frame_out11_tuser [0:DEPTH-1];
    reg frame_out11_valid [0:DEPTH-1];

    // Frame output pointers (twelfth stage)
    reg [LOG2_DEPTH-1:0] frame_out12_head;
    reg [LOG2_DEPTH-1:0] frame_out12_tail;
    reg frame_out12_full;
    reg frame_out12_empty;
    reg [LOG2_DEPTH-1:0] frame_out12_count;

    // Frame output data storage (twelfth stage)
    reg [DATA_WIDTH-1:0] frame_out12_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out12_keep [0:DEPTH-1];
    reg frame_out12_last [0:DEPTH-1];
    reg frame_out12_tid [0:DEPTH-1];
    reg frame_out12_tdest [0:DEPTH-1];
    reg frame_out12_tuser [0:DEPTH-1];
    reg frame_out12_valid [0:DEPTH-1];

    // Frame output pointers (thirteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out13_head;
    reg [LOG2_DEPTH-1:0] frame_out13_tail;
    reg frame_out13_full;
    reg frame_out13_empty;
    reg [LOG2_DEPTH-1:0] frame_out13_count;

    // Frame output data storage (thirteenth stage)
    reg [DATA_WIDTH-1:0] frame_out13_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out13_keep [0:DEPTH-1];
    reg frame_out13_last [0:DEPTH-1];
    reg frame_out13_tid [0:DEPTH-1];
    reg frame_out13_tdest [0:DEPTH-1];
    reg frame_out13_tuser [0:DEPTH-1];
    reg frame_out13_valid [0:DEPTH-1];

    // Frame output pointers (fourteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out14_head;
    reg [LOG2_DEPTH-1:0] frame_out14_tail;
    reg frame_out14_full;
    reg frame_out14_empty;
    reg [LOG2_DEPTH-1:0] frame_out14_count;

    // Frame output data storage (fourteenth stage)
    reg [DATA_WIDTH-1:0] frame_out14_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out14_keep [0:DEPTH-1];
    reg frame_out14_last [0:DEPTH-1];
    reg frame_out14_tid [0:DEPTH-1];
    reg frame_out14_tdest [0:DEPTH-1];
    reg frame_out14_tuser [0:DEPTH-1];
    reg frame_out14_valid [0:DEPTH-1];

    // Frame output pointers (fifteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out15_head;
    reg [LOG2_DEPTH-1:0] frame_out15_tail;
    reg frame_out15_full;
    reg frame_out15_empty;
    reg [LOG2_DEPTH-1:0] frame_out15_count;

    // Frame output data storage (fifteenth stage)
    reg [DATA_WIDTH-1:0] frame_out15_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out15_keep [0:DEPTH-1];
    reg frame_out15_last [0:DEPTH-1];
    reg frame_out15_tid [0:DEPTH-1];
    reg frame_out15_tdest [0:DEPTH-1];
    reg frame_out15_tuser [0:DEPTH-1];
    reg frame_out15_valid [0:DEPTH-1];

    // Frame output pointers (sixteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out16_head;
    reg [LOG2_DEPTH-1:0] frame_out16_tail;
    reg frame_out16_full;
    reg frame_out16_empty;
    reg [LOG2_DEPTH-1:0] frame_out16_count;

    // Frame output data storage (sixteenth stage)
    reg [DATA_WIDTH-1:0] frame_out16_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out16_keep [0:DEPTH-1];
    reg frame_out16_last [0:DEPTH-1];
    reg frame_out16_tid [0:DEPTH-1];
    reg frame_out16_tdest [0:DEPTH-1];
    reg frame_out16_tuser [0:DEPTH-1];
    reg frame_out16_valid [0:DEPTH-1];

    // Frame output pointers (seventeenth stage)
    reg [LOG2_DEPTH-1:0] frame_out17_head;
    reg [LOG2_DEPTH-1:0] frame_out17_tail;
    reg frame_out17_full;
    reg frame_out17_empty;
    reg [LOG2_DEPTH-1:0] frame_out17_count;

    // Frame output data storage (seventeenth stage)
    reg [DATA_WIDTH-1:0] frame_out17_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out17_keep [0:DEPTH-1];
    reg frame_out17_last [0:DEPTH-1];
    reg frame_out17_tid [0:DEPTH-1];
    reg frame_out17_tdest [0:DEPTH-1];
    reg frame_out17_tuser [0:DEPTH-1];
    reg frame_out17_valid [0:DEPTH-1];

    // Frame output pointers (eighteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out18_head;
    reg [LOG2_DEPTH-1:0] frame_out18_tail;
    reg frame_out18_full;
    reg frame_out18_empty;
    reg [LOG2_DEPTH-1:0] frame_out18_count;

    // Frame output data storage (eighteenth stage)
    reg [DATA_WIDTH-1:0] frame_out18_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out18_keep [0:DEPTH-1];
    reg frame_out18_last [0:DEPTH-1];
    reg frame_out18_tid [0:DEPTH-1];
    reg frame_out18_tdest [0:DEPTH-1];
    reg frame_out18_tuser [0:DEPTH-1];
    reg frame_out18_valid [0:DEPTH-1];

    // Frame output pointers (nineteenth stage)
    reg [LOG2_DEPTH-1:0] frame_out19_head;
    reg [LOG2_DEPTH-1:0] frame_out19_tail;
    reg frame_out19_full;
    reg frame_out19_empty;
    reg [LOG2_DEPTH-1:0] frame_out19_count;

    // Frame output data storage (nineteenth stage)
    reg [DATA_WIDTH-1:0] frame_out19_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out19_keep [0:DEPTH-1];
    reg frame_out19_last [0:DEPTH-1];
    reg frame_out19_tid [0:DEPTH-1];
    reg frame_out19_tdest [0:DEPTH-1];
    reg frame_out19_tuser [0:DEPTH-1];
    reg frame_out19_valid [0:DEPTH-1];

    // Frame output pointers (twentieth stage)
    reg [LOG2_DEPTH-1:0] frame_out20_head;
    reg [LOG2_DEPTH-1:0] frame_out20_tail;
    reg frame_out20_full;
    reg frame_out20_empty;
    reg [LOG2_DEPTH-1:0] frame_out20_count;

    // Frame output data storage (twentieth stage)
    reg [DATA_WIDTH-1:0] frame_out20_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out20_keep [0:DEPTH-1];
    reg frame_out20_last [0:DEPTH-1];
    reg frame_out20_tid [0:DEPTH-1];
    reg frame_out20_tdest [0:DEPTH-1];
    reg frame_out20_tuser [0:DEPTH-1];
    reg frame_out20_valid [0:DEPTH-1];

    // Frame output pointers (twenty-first stage)
    reg [LOG2_DEPTH-1:0] frame_out21_head;
    reg [LOG2_DEPTH-1:0] frame_out21_tail;
    reg frame_out21_full;
    reg frame_out21_empty;
    reg [LOG2_DEPTH-1:0] frame_out21_count;

    // Frame output data storage (twenty-first stage)
    reg [DATA_WIDTH-1:0] frame_out21_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out21_keep [0:DEPTH-1];
    reg frame_out21_last [0:DEPTH-1];
    reg frame_out21_tid [0:DEPTH-1];
    reg frame_out21_tdest [0:DEPTH-1];
    reg frame_out21_tuser [0:DEPTH-1];
    reg frame_out21_valid [0:DEPTH-1];

    // Frame output pointers (twenty-second stage)
    reg [LOG2_DEPTH-1:0] frame_out22_head;
    reg [LOG2_DEPTH-1:0] frame_out22_tail;
    reg frame_out22_full;
    reg frame_out22_empty;
    reg [LOG2_DEPTH-1:0] frame_out22_count;

    // Frame output data storage (twenty-second stage)
    reg [DATA_WIDTH-1:0] frame_out22_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out22_keep [0:DEPTH-1];
    reg frame_out22_last [0:DEPTH-1];
    reg frame_out22_tid [0:DEPTH-1];
    reg frame_out22_tdest [0:DEPTH-1];
    reg frame_out22_tuser [0:DEPTH-1];
    reg frame_out22_valid [0:DEPTH-1];

    // Frame output pointers (twenty-third stage)
    reg [LOG2_DEPTH-1:0] frame_out23_head;
    reg [LOG2_DEPTH-1:0] frame_out23_tail;
    reg frame_out23_full;
    reg frame_out23_empty;
    reg [LOG2_DEPTH-1:0] frame_out23_count;

    // Frame output data storage (twenty-third stage)
    reg [DATA_WIDTH-1:0] frame_out23_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out23_keep [0:DEPTH-1];
    reg frame_out23_last [0:DEPTH-1];
    reg frame_out23_tid [0:DEPTH-1];
    reg frame_out23_tdest [0:DEPTH-1];
    reg frame_out23_tuser [0:DEPTH-1];
    reg frame_out23_valid [0:DEPTH-1];

    // Frame output pointers (twenty-fourth stage)
    reg [LOG2_DEPTH-1:0] frame_out24_head;
    reg [LOG2_DEPTH-1:0] frame_out24_tail;
    reg frame_out24_full;
    reg frame_out24_empty;
    reg [LOG2_DEPTH-1:0] frame_out24_count;

    // Frame output data storage (twenty-fourth stage)
    reg [DATA_WIDTH-1:0] frame_out24_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out24_keep [0:DEPTH-1];
    reg frame_out24_last [0:DEPTH-1];
    reg frame_out24_tid [0:DEPTH-1];
    reg frame_out24_tdest [0:DEPTH-1];
    reg frame_out24_tuser [0:DEPTH-1];
    reg frame_out24_valid [0:DEPTH-1];

    // Frame output pointers (twenty-fifth stage)
    reg [LOG2_DEPTH-1:0] frame_out25_head;
    reg [LOG2_DEPTH-1:0] frame_out25_tail;
    reg frame_out25_full;
    reg frame_out25_empty;
    reg [LOG2_DEPTH-1:0] frame_out25_count;

    // Frame output data storage (twenty-fifth stage)
    reg [DATA_WIDTH-1:0] frame_out25_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out25_keep [0:DEPTH-1];
    reg frame_out25_last [0:DEPTH-1];
    reg frame_out25_tid [0:DEPTH-1];
    reg frame_out25_tdest [0:DEPTH-1];
    reg frame_out25_tuser [0:DEPTH-1];
    reg frame_out25_valid [0:DEPTH-1];

    // Frame output pointers (twenty-sixth stage)
    reg [LOG2_DEPTH-1:0] frame_out26_head;
    reg [LOG2_DEPTH-1:0] frame_out26_tail;
    reg frame_out26_full;
    reg frame_out26_empty;
    reg [LOG2_DEPTH-1:0] frame_out26_count;

    // Frame output data storage (twenty-sixth stage)
    reg [DATA_WIDTH-1:0] frame_out26_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out26_keep [0:DEPTH-1];
    reg frame_out26_last [0:DEPTH-1];
    reg frame_out26_tid [0:DEPTH-1];
    reg frame_out26_tdest [0:DEPTH-1];
    reg frame_out26_tuser [0:DEPTH-1];
    reg frame_out26_valid [0:DEPTH-1];

    // Frame output pointers (twenty-seventh stage)
    reg [LOG2_DEPTH-1:0] frame_out27_head;
    reg [LOG2_DEPTH-1:0] frame_out27_tail;
    reg frame_out27_full;
    reg frame_out27_empty;
    reg [LOG2_DEPTH-1:0] frame_out27_count;

    // Frame output data storage (twenty-seventh stage)
    reg [DATA_WIDTH-1:0] frame_out27_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out27_keep [0:DEPTH-1];
    reg frame_out27_last [0:DEPTH-1];
    reg frame_out27_tid [0:DEPTH-1];
    reg frame_out27_tdest [0:DEPTH-1];
    reg frame_out27_tuser [0:DEPTH-1];
    reg frame_out27_valid [0:DEPTH-1];

    // Frame output pointers (twenty-eighth stage)
    reg [LOG2_DEPTH-1:0] frame_out28_head;
    reg [LOG2_DEPTH-1:0] frame_out28_tail;
    reg frame_out28_full;
    reg frame_out28_empty;
    reg [LOG2_DEPTH-1:0] frame_out28_count;

    // Frame output data storage (twenty-eighth stage)
    reg [DATA_WIDTH-1:0] frame_out28_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out28_keep [0:DEPTH-1];
    reg frame_out28_last [0:DEPTH-1];
    reg frame_out28_tid [0:DEPTH-1];
    reg frame_out28_tdest [0:DEPTH-1];
    reg frame_out28_tuser [0:DEPTH-1];
    reg frame_out28_valid [0:DEPTH-1];

    // Frame output pointers (twenty-ninth stage)
    reg [LOG2_DEPTH-1:0] frame_out29_head;
    reg [LOG2_DEPTH-1:0] frame_out29_tail;
    reg frame_out29_full;
    reg frame_out29_empty;
    reg [LOG2_DEPTH-1:0] frame_out29_count;

    // Frame output data storage (twenty-ninth stage)
    reg [DATA_WIDTH-1:0] frame_out29_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out29_keep [0:DEPTH-1];
    reg frame_out29_last [0:DEPTH-1];
    reg frame_out29_tid [0:DEPTH-1];
    reg frame_out29_tdest [0:DEPTH-1];
    reg frame_out29_tuser [0:DEPTH-1];
    reg frame_out29_valid [0:DEPTH-1];

    // Frame output pointers (thirtieth stage)
    reg [LOG2_DEPTH-1:0] frame_out30_head;
    reg [LOG2_DEPTH-1:0] frame_out30_tail;
    reg frame_out30_full;
    reg frame_out30_empty;
    reg [LOG2_DEPTH-1:0] frame_out30_count;

    // Frame output data storage (thirtieth stage)
    reg [DATA_WIDTH-1:0] frame_out30_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out30_keep [0:DEPTH-1];
    reg frame_out30_last [0:DEPTH-1];
    reg frame_out30_tid [0:DEPTH-1];
    reg frame_out30_tdest [0:DEPTH-1];
    reg frame_out30_tuser [0:DEPTH-1];
    reg frame_out30_valid [0:DEPTH-1];

    // Frame output pointers (thirty-first stage)
    reg [LOG2_DEPTH-1:0] frame_out31_head;
    reg [LOG2_DEPTH-1:0] frame_out31_tail;
    reg frame_out31_full;
    reg frame_out31_empty;
    reg [LOG2_DEPTH-1:0] frame_out31_count;

    // Frame output data storage (thirty-first stage)
    reg [DATA_WIDTH-1:0] frame_out31_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out31_keep [0:DEPTH-1];
    reg frame_out31_last [0:DEPTH-1];
    reg frame_out31_tid [0:DEPTH-1];
    reg frame_out31_tdest [0:DEPTH-1];
    reg frame_out31_tuser [0:DEPTH-1];
    reg frame_out31_valid [0:DEPTH-1];

    // Frame output pointers (thirty-second stage)
    reg [LOG2_DEPTH-1:0] frame_out32_head;
    reg [LOG2_DEPTH-1:0] frame_out32_tail;
    reg frame_out32_full;
    reg frame_out32_empty;
    reg [LOG2_DEPTH-1:0] frame_out32_count;

    // Frame output data storage (thirty-second stage)
    reg [DATA_WIDTH-1:0] frame_out32_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] frame_out32_keep [0:DEPTH-1];
    reg frame_out32_last [0:DEPTH-1];
    reg frame_out32_tid [0:DEPTH-1];
    reg frame_out32_tdest [0:DEPTH-1];
    reg frame_out32_tuser [0:DEPTH-1];
    reg frame_out32_valid [0:DEPTH-1];

    // Frame output pointers (thirty-third stage)
    reg [LOG2_DEPTH-1:0] frame_out33_head;
    reg [LOG2_DEPTH-1:0] frame_out33_tail;
    reg frame_out33_full;
    reg frame_out33_empty;
    reg [LOG2_DEPTH-1:0] frame_out33_count;

    // Frame output data storage (thirty-third stage)
    reg [DATA_WIDTH-1:0] frame_out33_data [0:DEPTH-1];