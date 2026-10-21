```verilog
module axis_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    localparam S_KEEP_MASK = S_KEEP_ENABLE ? (1 << S_KEEP_WIDTH) - 1 : 0;
    localparam M_KEEP_MASK = M_KEEP_ENABLE ? (1 << M_KEEP_WIDTH) - 1 : 0;

    reg [S_DATA_WIDTH-1:0]  s_data_reg;
    reg [S_KEEP_WIDTH-1:0]  s_keep_reg;
    reg                     s_last_reg;
    reg                     s_valid_reg;
    reg                     s_ready_reg;
    reg                     s_last_valid;
    reg                     m_valid_reg;
    reg                     m_last_reg;
    reg                     m_last_valid;
    reg [M_DATA_WIDTH-1:0]  m_data_reg;
    reg [M_KEEP_WIDTH-1:0]  m_keep_reg;
    reg [ID_WIDTH-1:0]      m_tid_reg;
    reg [DEST_WIDTH-1:0]    m_tdest_reg;
    reg [USER_WIDTH-1:0]    m_tuser_reg;

    reg [S_DATA_WIDTH-1:0]  s_data_buf;
    reg [S_KEEP_WIDTH-1:0]  s_keep_buf;
    reg                     s_last_buf;
    reg                     s_valid_buf;
    reg                     s_ready_buf;
    reg                     s_last_valid_buf;
    reg                     m_valid_buf;
    reg                     m_last_buf;
    reg                     m_last_valid_buf;
    reg [M_DATA_WIDTH-1:0]  m_data_buf;
    reg [M_KEEP_WIDTH-1:0]  m_keep_buf;
    reg [ID_WIDTH-1:0]      m_tid_buf;
    reg [DEST_WIDTH-1:0]    m_tdest_buf;
    reg [USER_WIDTH-1:0]    m_tuser_buf;

    reg [S_DATA_WIDTH-1:0]  s_data_in;
    reg [S_KEEP_WIDTH-1:0]  s_keep_in;
    reg                     s_last_in;
    reg                     s_valid_in;
    reg                     s_ready_in;
    reg                     s_last_valid_in;
    reg                     m_valid_in;
    reg                     m_last_in;
    reg                     m_last_valid_in;
    reg [M_DATA_WIDTH-1:0]  m_data_in;
    reg [M_KEEP_WIDTH-1:0]  m_keep_in;
    reg [ID_WIDTH-1:0]      m_tid_in;
    reg [DEST_WIDTH-1:0]    m_tdest_in;
    reg [USER_WIDTH-1:0]    m_tuser_in;

    reg [S_DATA_WIDTH-1:0]  s_data_out;
    reg [S_KEEP_WIDTH-1:0]  s_keep_out;
    reg                     s_last_out;
    reg                     s_valid_out;
    reg                     s_ready_out;
    reg                     s_last_valid_out;
    reg                     m_valid_out;
    reg                     m_last_out;
    reg                     m_last_valid_out;
    reg [M_DATA_WIDTH-1:0]  m_data_out;
    reg [M_KEEP_WIDTH-1:0]  m_keep_out;
    reg [ID_WIDTH-1:0]      m_tid_out;
    reg [DEST_WIDTH-1:0]    m_tdest_out;
    reg [USER_WIDTH-1:0]    m_tuser_out;

    reg [S_DATA_WIDTH-1:0]  s_data_final;
    reg [S_KEEP_WIDTH-1:0]  s_keep_final;
    reg                     s_last_final;
    reg                     s_valid_final;
    reg                     s_ready_final;
    reg                     s_last_valid_final;
    reg                     m_valid_final;
    reg                     m_last_final;
    reg                     m_last_valid_final;
    reg [M_DATA_WIDTH-1:0]  m_data_final;
    reg [M_KEEP_WIDTH-1:0]  m_keep_final;
    reg [ID_WIDTH-1:0]      m_tid_final;
    reg [DEST_WIDTH-1:0]    m_tdest_final;
    reg [USER_WIDTH-1:0]    m_tuser_final;

    reg [S_DATA_WIDTH-1:0]  s_data_last;
    reg [S_KEEP_WIDTH-1:0]  s_keep_last;
    reg                     s_last_last;
    reg                     s_valid_last;
    reg                     s_ready_last;
    reg                     s_last_valid_last;
    reg                     m_valid_last;
    reg                     m_last_last;
    reg                     m_last_valid_last;
    reg [M_DATA_WIDTH-1:0]  m_data_last;
    reg [M_KEEP_WIDTH-1:0]  m_keep_last;
    reg [ID_WIDTH-1:0]      m_tid_last;
    reg [DEST_WIDTH-1:0]    m_tdest_last;
    reg [USER_WIDTH-1:0]    m_tuser_last;

    reg [S_DATA_WIDTH-1:0]  s_data_next;
    reg [S_KEEP_WIDTH-1:0]  s_keep_next;
    reg                     s_last_next;
    reg                     s_valid_next;
    reg                     s_ready_next;
    reg                     s_last_valid_next;
    reg                     m_valid_next;
    reg                     m_last_next;
    reg                     m_last_valid_next;
    reg [M_DATA_WIDTH-1:0]  m_data_next;
    reg [M_KEEP_WIDTH-1:0]  m_keep_next;
    reg [ID_WIDTH-1:0]      m_tid_next;
    reg [DEST_WIDTH-1:0]    m_tdest_next;
    reg [USER_WIDTH-1:0]    m_tuser_next;

    reg [S_DATA_WIDTH-1:0]  s_data_curr;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr;
    reg                     s_last_curr;
    reg                     s_valid_curr;
    reg                     s_ready_curr;
    reg                     s_last_valid_curr;
    reg                     m_valid_curr;
    reg                     m_last_curr;
    reg                     m_last_valid_curr;
    reg [M_DATA_WIDTH-1:0]  m_data_curr;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr;
    reg [ID_WIDTH-1:0]      m_tid_curr;
    reg [DEST_WIDTH-1:0]    m_tdest_curr;
    reg [USER_WIDTH-1:0]    m_tuser_curr;

    reg [S_DATA_WIDTH-1:0]  s_data_prev;
    reg [S_KEEP_WIDTH-1:0]  s_keep_prev;
    reg                     s_last_prev;
    reg                     s_valid_prev;
    reg                     s_ready_prev;
    reg                     s_last_valid_prev;
    reg                     m_valid_prev;
    reg                     m_last_prev;
    reg                     m_last_valid_prev;
    reg [M_DATA_WIDTH-1:0]  m_data_prev;
    reg [M_KEEP_WIDTH-1:0]  m_keep_prev;
    reg [ID_WIDTH-1:0]      m_tid_prev;
    reg [DEST_WIDTH-1:0]    m_tdest_prev;
    reg [USER_WIDTH-1:0]    m_tuser_prev;

    reg [S_DATA_WIDTH-1:0]  s_data_old;
    reg [S_KEEP_WIDTH-1:0]  s_keep_old;
    reg                     s_last_old;
    reg                     s_valid_old;
    reg                     s_ready_old;
    reg                     s_last_valid_old;
    reg                     m_valid_old;
    reg                     m_last_old;
    reg                     m_last_valid_old;
    reg [M_DATA_WIDTH-1:0]  m_data_old;
    reg [M_KEEP_WIDTH-1:0]  m_keep_old;
    reg [ID_WIDTH-1:0]      m_tid_old;
    reg [DEST_WIDTH-1:0]    m_tdest_old;
    reg [USER_WIDTH-1:0]    m_tuser_old;

    reg [S_DATA_WIDTH-1:0]  s_data_new;
    reg [S_KEEP_WIDTH-1:0]  s_keep_new;
    reg                     s_last_new;
    reg                     s_valid_new;
    reg                     s_ready_new;
    reg                     s_last_valid_new;
    reg                     m_valid_new;
    reg                     m_last_new;
    reg                     m_last_valid_new;
    reg [M_DATA_WIDTH-1:0]  m_data_new;
    reg [M_KEEP_WIDTH-1:0]  m_keep_new;
    reg [ID_WIDTH-1:0]      m_tid_new;
    reg [DEST_WIDTH-1:0]    m_tdest_new;
    reg [USER_WIDTH-1:0]    m_tuser_new;

    reg [S_DATA_WIDTH-1:0]  s_data_curr2;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr2;
    reg                     s_last_curr2;
    reg                     s_valid_curr2;
    reg                     s_ready_curr2;
    reg                     s_last_valid_curr2;
    reg                     m_valid_curr2;
    reg                     m_last_curr2;
    reg                     m_last_valid_curr2;
    reg [M_DATA_WIDTH-1:0]  m_data_curr2;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr2;
    reg [ID_WIDTH-1:0]      m_tid_curr2;
    reg [DEST_WIDTH-1:0]    m_tdest_curr2;
    reg [USER_WIDTH-1:0]    m_tuser_curr2;

    reg [S_DATA_WIDTH-1:0]  s_data_curr3;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr3;
    reg                     s_last_curr3;
    reg                     s_valid_curr3;
    reg                     s_ready_curr3;
    reg                     s_last_valid_curr3;
    reg                     m_valid_curr3;
    reg                     m_last_curr3;
    reg                     m_last_valid_curr3;
    reg [M_DATA_WIDTH-1:0]  m_data_curr3;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr3;
    reg [ID_WIDTH-1:0]      m_tid_curr3;
    reg [DEST_WIDTH-1:0]    m_tdest_curr3;
    reg [USER_WIDTH-1:0]    m_tuser_curr3;

    reg [S_DATA_WIDTH-1:0]  s_data_curr4;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr4;
    reg                     s_last_curr4;
    reg                     s_valid_curr4;
    reg                     s_ready_curr4;
    reg                     s_last_valid_curr4;
    reg                     m_valid_curr4;
    reg                     m_last_curr4;
    reg                     m_last_valid_curr4;
    reg [M_DATA_WIDTH-1:0]  m_data_curr4;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr4;
    reg [ID_WIDTH-1:0]      m_tid_curr4;
    reg [DEST_WIDTH-1:0]    m_tdest_curr4;
    reg [USER_WIDTH-1:0]    m_tuser_curr4;

    reg [S_DATA_WIDTH-1:0]  s_data_curr5;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr5;
    reg                     s_last_curr5;
    reg                     s_valid_curr5;
    reg                     s_ready_curr5;
    reg                     s_last_valid_curr5;
    reg                     m_valid_curr5;
    reg                     m_last_curr5;
    reg                     m_last_valid_curr5;
    reg [M_DATA_WIDTH-1:0]  m_data_curr5;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr5;
    reg [ID_WIDTH-1:0]      m_tid_curr5;
    reg [DEST_WIDTH-1:0]    m_tdest_curr5;
    reg [USER_WIDTH-1:0]    m_tuser_curr5;

    reg [S_DATA_WIDTH-1:0]  s_data_curr6;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr6;
    reg                     s_last_curr6;
    reg                     s_valid_curr6;
    reg                     s_ready_curr6;
    reg                     s_last_valid_curr6;
    reg                     m_valid_curr6;
    reg                     m_last_curr6;
    reg                     m_last_valid_curr6;
    reg [M_DATA_WIDTH-1:0]  m_data_curr6;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr6;
    reg [ID_WIDTH-1:0]      m_tid_curr6;
    reg [DEST_WIDTH-1:0]    m_tdest_curr6;
    reg [USER_WIDTH-1:0]    m_tuser_curr6;

    reg [S_DATA_WIDTH-1:0]  s_data_curr7;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr7;
    reg                     s_last_curr7;
    reg                     s_valid_curr7;
    reg                     s_ready_curr7;
    reg                     s_last_valid_curr7;
    reg                     m_valid_curr7;
    reg                     m_last_curr7;
    reg                     m_last_valid_curr7;
    reg [M_DATA_WIDTH-1:0]  m_data_curr7;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr7;
    reg [ID_WIDTH-1:0]      m_tid_curr7;
    reg [DEST_WIDTH-1:0]    m_tdest_curr7;
    reg [USER_WIDTH-1:0]    m_tuser_curr7;

    reg [S_DATA_WIDTH-1:0]  s_data_curr8;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr8;
    reg                     s_last_curr8;
    reg                     s_valid_curr8;
    reg                     s_ready_curr8;
    reg                     s_last_valid_curr8;
    reg                     m_valid_curr8;
    reg                     m_last_curr8;
    reg                     m_last_valid_curr8;
    reg [M_DATA_WIDTH-1:0]  m_data_curr8;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr8;
    reg [ID_WIDTH-1:0]      m_tid_curr8;
    reg [DEST_WIDTH-1:0]    m_tdest_curr8;
    reg [USER_WIDTH-1:0]    m_tuser_curr8;

    reg [S_DATA_WIDTH-1:0]  s_data_curr9;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr9;
    reg                     s_last_curr9;
    reg                     s_valid_curr9;
    reg                     s_ready_curr9;
    reg                     s_last_valid_curr9;
    reg                     m_valid_curr9;
    reg                     m_last_curr9;
    reg                     m_last_valid_curr9;
    reg [M_DATA_WIDTH-1:0]  m_data_curr9;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr9;
    reg [ID_WIDTH-1:0]      m_tid_curr9;
    reg [DEST_WIDTH-1:0]    m_tdest_curr9;
    reg [USER_WIDTH-1:0]    m_tuser_curr9;

    reg [S_DATA_WIDTH-1:0]  s_data_curr10;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr10;
    reg                     s_last_curr10;
    reg                     s_valid_curr10;
    reg                     s_ready_curr10;
    reg                     s_last_valid_curr10;
    reg                     m_valid_curr10;
    reg                     m_last_curr10;
    reg                     m_last_valid_curr10;
    reg [M_DATA_WIDTH-1:0]  m_data_curr10;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr10;
    reg [ID_WIDTH-1:0]      m_tid_curr10;
    reg [DEST_WIDTH-1:0]    m_tdest_curr10;
    reg [USER_WIDTH-1:0]    m_tuser_curr10;

    reg [S_DATA_WIDTH-1:0]  s_data_curr11;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr11;
    reg                     s_last_curr11;
    reg                     s_valid_curr11;
    reg                     s_ready_curr11;
    reg                     s_last_valid_curr11;
    reg                     m_valid_curr11;
    reg                     m_last_curr11;
    reg                     m_last_valid_curr11;
    reg [M_DATA_WIDTH-1:0]  m_data_curr11;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr11;
    reg [ID_WIDTH-1:0]      m_tid_curr11;
    reg [DEST_WIDTH-1:0]    m_tdest_curr11;
    reg [USER_WIDTH-1:0]    m_tuser_curr11;

    reg [S_DATA_WIDTH-1:0]  s_data_curr12;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr12;
    reg                     s_last_curr12;
    reg                     s_valid_curr12;
    reg                     s_ready_curr12;
    reg                     s_last_valid_curr12;
    reg                     m_valid_curr12;
    reg                     m_last_curr12;
    reg                     m_last_valid_curr12;
    reg [M_DATA_WIDTH-1:0]  m_data_curr12;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr12;
    reg [ID_WIDTH-1:0]      m_tid_curr12;
    reg [DEST_WIDTH-1:0]    m_tdest_curr12;
    reg [USER_WIDTH-1:0]    m_tuser_curr12;

    reg [S_DATA_WIDTH-1:0]  s_data_curr13;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr13;
    reg                     s_last_curr13;
    reg                     s_valid_curr13;
    reg                     s_ready_curr13;
    reg                     s_last_valid_curr13;
    reg                     m_valid_curr13;
    reg                     m_last_curr13;
    reg                     m_last_valid_curr13;
    reg [M_DATA_WIDTH-1:0]  m_data_curr13;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr13;
    reg [ID_WIDTH-1:0]      m_tid_curr13;
    reg [DEST_WIDTH-1:0]    m_tdest_curr13;
    reg [USER_WIDTH-1:0]    m_tuser_curr13;

    reg [S_DATA_WIDTH-1:0]  s_data_curr14;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr14;
    reg                     s_last_curr14;
    reg                     s_valid_curr14;
    reg                     s_ready_curr14;
    reg                     s_last_valid_curr14;
    reg                     m_valid_curr14;
    reg                     m_last_curr14;
    reg                     m_last_valid_curr14;
    reg [M_DATA_WIDTH-1:0]  m_data_curr14;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr14;
    reg [ID_WIDTH-1:0]      m_tid_curr14;
    reg [DEST_WIDTH-1:0]    m_tdest_curr14;
    reg [USER_WIDTH-1:0]    m_tuser_curr14;

    reg [S_DATA_WIDTH-1:0]  s_data_curr15;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr15;
    reg                     s_last_curr15;
    reg                     s_valid_curr15;
    reg                     s_ready_curr15;
    reg                     s_last_valid_curr15;
    reg                     m_valid_curr15;
    reg                     m_last_curr15;
    reg                     m_last_valid_curr15;
    reg [M_DATA_WIDTH-1:0]  m_data_curr15;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr15;
    reg [ID_WIDTH-1:0]      m_tid_curr15;
    reg [DEST_WIDTH-1:0]    m_tdest_curr15;
    reg [USER_WIDTH-1:0]    m_tuser_curr15;

    reg [S_DATA_WIDTH-1:0]  s_data_curr16;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr16;
    reg                     s_last_curr16;
    reg                     s_valid_curr16;
    reg                     s_ready_curr16;
    reg                     s_last_valid_curr16;
    reg                     m_valid_curr16;
    reg                     m_last_curr16;
    reg                     m_last_valid_curr16;
    reg [M_DATA_WIDTH-1:0]  m_data_curr16;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr16;
    reg [ID_WIDTH-1:0]      m_tid_curr16;
    reg [DEST_WIDTH-1:0]    m_tdest_curr16;
    reg [USER_WIDTH-1:0]    m_tuser_curr16;

    reg [S_DATA_WIDTH-1:0]  s_data_curr17;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr17;
    reg                     s_last_curr17;
    reg                     s_valid_curr17;
    reg                     s_ready_curr17;
    reg                     s_last_valid_curr17;
    reg                     m_valid_curr17;
    reg                     m_last_curr17;
    reg                     m_last_valid_curr17;
    reg [M_DATA_WIDTH-1:0]  m_data_curr17;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr17;
    reg [ID_WIDTH-1:0]      m_tid_curr17;
    reg [DEST_WIDTH-1:0]    m_tdest_curr17;
    reg [USER_WIDTH-1:0]    m_tuser_curr17;

    reg [S_DATA_WIDTH-1:0]  s_data_curr18;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr18;
    reg                     s_last_curr18;
    reg                     s_valid_curr18;
    reg                     s_ready_curr18;
    reg                     s_last_valid_curr18;
    reg                     m_valid_curr18;
    reg                     m_last_curr18;
    reg                     m_last_valid_curr18;
    reg [M_DATA_WIDTH-1:0]  m_data_curr18;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr18;
    reg [ID_WIDTH-1:0]      m_tid_curr18;
    reg [DEST_WIDTH-1:0]    m_tdest_curr18;
    reg [USER_WIDTH-1:0]    m_tuser_curr18;

    reg [S_DATA_WIDTH-1:0]  s_data_curr19;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr19;
    reg                     s_last_curr19;
    reg                     s_valid_curr19;
    reg                     s_ready_curr19;
    reg                     s_last_valid_curr19;
    reg                     m_valid_curr19;
    reg                     m_last_curr19;
    reg                     m_last_valid_curr19;
    reg [M_DATA_WIDTH-1:0]  m_data_curr19;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr19;
    reg [ID_WIDTH-1:0]      m_tid_curr19;
    reg [DEST_WIDTH-1:0]    m_tdest_curr19;
    reg [USER_WIDTH-1:0]    m_tuser_curr19;

    reg [S_DATA_WIDTH-1:0]  s_data_curr20;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr20;
    reg                     s_last_curr20;
    reg                     s_valid_curr20;
    reg                     s_ready_curr20;
    reg                     s_last_valid_curr20;
    reg                     m_valid_curr20;
    reg                     m_last_curr20;
    reg                     m_last_valid_curr20;
    reg [M_DATA_WIDTH-1:0]  m_data_curr20;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr20;
    reg [ID_WIDTH-1:0]      m_tid_curr20;
    reg [DEST_WIDTH-1:0]    m_tdest_curr20;
    reg [USER_WIDTH-1:0]    m_tuser_curr20;

    reg [S_DATA_WIDTH-1:0]  s_data_curr21;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr21;
    reg                     s_last_curr21;
    reg                     s_valid_curr21;
    reg                     s_ready_curr21;
    reg                     s_last_valid_curr21;
    reg                     m_valid_curr21;
    reg                     m_last_curr21;
    reg                     m_last_valid_curr21;
    reg [M_DATA_WIDTH-1:0]  m_data_curr21;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr21;
    reg [ID_WIDTH-1:0]      m_tid_curr21;
    reg [DEST_WIDTH-1:0]    m_tdest_curr21;
    reg [USER_WIDTH-1:0]    m_tuser_curr21;

    reg [S_DATA_WIDTH-1:0]  s_data_curr22;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr22;
    reg                     s_last_curr22;
    reg                     s_valid_curr22;
    reg                     s_ready_curr22;
    reg                     s_last_valid_curr22;
    reg                     m_valid_curr22;
    reg                     m_last_curr22;
    reg                     m_last_valid_curr22;
    reg [M_DATA_WIDTH-1:0]  m_data_curr22;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr22;
    reg [ID_WIDTH-1:0]      m_tid_curr22;
    reg [DEST_WIDTH-1:0]    m_tdest_curr22;
    reg [USER_WIDTH-1:0]    m_tuser_curr22;

    reg [S_DATA_WIDTH-1:0]  s_data_curr23;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr23;
    reg                     s_last_curr23;
    reg                     s_valid_curr23;
    reg                     s_ready_curr23;
    reg                     s_last_valid_curr23;
    reg                     m_valid_curr23;
    reg                     m_last_curr23;
    reg                     m_last_valid_curr23;
    reg [M_DATA_WIDTH-1:0]  m_data_curr23;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr23;
    reg [ID_WIDTH-1:0]      m_tid_curr23;
    reg [DEST_WIDTH-1:0]    m_tdest_curr23;
    reg [USER_WIDTH-1:0]    m_tuser_curr23;

    reg [S_DATA_WIDTH-1:0]  s_data_curr24;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr24;
    reg                     s_last_curr24;
    reg                     s_valid_curr24;
    reg                     s_ready_curr24;
    reg                     s_last_valid_curr24;
    reg                     m_valid_curr24;
    reg                     m_last_curr24;
    reg                     m_last_valid_curr24;
    reg [M_DATA_WIDTH-1:0]  m_data_curr24;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr24;
    reg [ID_WIDTH-1:0]      m_tid_curr24;
    reg [DEST_WIDTH-1:0]    m_tdest_curr24;
    reg [USER_WIDTH-1:0]    m_tuser_curr24;

    reg [S_DATA_WIDTH-1:0]  s_data_curr25;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr25;
    reg                     s_last_curr25;
    reg                     s_valid_curr25;
    reg                     s_ready_curr25;
    reg                     s_last_valid_curr25;
    reg                     m_valid_curr25;
    reg                     m_last_curr25;
    reg                     m_last_valid_curr25;
    reg [M_DATA_WIDTH-1:0]  m_data_curr25;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr25;
    reg [ID_WIDTH-1:0]      m_tid_curr25;
    reg [DEST_WIDTH-1:0]    m_tdest_curr25;
    reg [USER_WIDTH-1:0]    m_tuser_curr25;

    reg [S_DATA_WIDTH-1:0]  s_data_curr26;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr26;
    reg                     s_last_curr26;
    reg                     s_valid_curr26;
    reg                     s_ready_curr26;
    reg                     s_last_valid_curr26;
    reg                     m_valid_curr26;
    reg                     m_last_curr26;
    reg                     m_last_valid_curr26;
    reg [M_DATA_WIDTH-1:0]  m_data_curr26;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr26;
    reg [ID_WIDTH-1:0]      m_tid_curr26;
    reg [DEST_WIDTH-1:0]    m_tdest_curr26;
    reg [USER_WIDTH-1:0]    m_tuser_curr26;

    reg [S_DATA_WIDTH-1:0]  s_data_curr27;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr27;
    reg                     s_last_curr27;
    reg                     s_valid_curr27;
    reg                     s_ready_curr27;
    reg                     s_last_valid_curr27;
    reg                     m_valid_curr27;
    reg                     m_last_curr27;
    reg                     m_last_valid_curr27;
    reg [M_DATA_WIDTH-1:0]  m_data_curr27;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr27;
    reg [ID_WIDTH-1:0]      m_tid_curr27;
    reg [DEST_WIDTH-1:0]    m_tdest_curr27;
    reg [USER_WIDTH-1:0]    m_tuser_curr27;

    reg [S_DATA_WIDTH-1:0]  s_data_curr28;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr28;
    reg                     s_last_curr28;
    reg                     s_valid_curr28;
    reg                     s_ready_curr28;
    reg                     s_last_valid_curr28;
    reg                     m_valid_curr28;
    reg                     m_last_curr28;
    reg                     m_last_valid_curr28;
    reg [M_DATA_WIDTH-1:0]  m_data_curr28;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr28;
    reg [ID_WIDTH-1:0]      m_tid_curr28;
    reg [DEST_WIDTH-1:0]    m_tdest_curr28;
    reg [USER_WIDTH-1:0]    m_tuser_curr28;

    reg [S_DATA_WIDTH-1:0]  s_data_curr29;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr29;
    reg                     s_last_curr29;
    reg                     s_valid_curr29;
    reg                     s_ready_curr29;
    reg                     s_last_valid_curr29;
    reg                     m_valid_curr29;
    reg                     m_last_curr29;
    reg                     m_last_valid_curr29;
    reg [M_DATA_WIDTH-1:0]  m_data_curr29;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr29;
    reg [ID_WIDTH-1:0]      m_tid_curr29;
    reg [DEST_WIDTH-1:0]    m_tdest_curr29;
    reg [USER_WIDTH-1:0]    m_tuser_curr29;

    reg [S_DATA_WIDTH-1:0]  s_data_curr30;
    reg [S_KEEP_WIDTH-1:0]  s_keep_curr30;
    reg                     s_last_curr30;
    reg                     s_valid_curr30;
    reg                     s_ready_curr30;
    reg                     s_last_valid_curr30;
    reg                     m_valid_curr30;
    reg                     m_last_curr30;
    reg                     m_last_valid_curr30;
    reg [M_DATA_WIDTH-1:0]  m_data_curr30;
    reg [M_KEEP_WIDTH-1:0]  m_keep_curr30;
    reg [ID_WIDTH-1:0]      m_tid_curr30;
   