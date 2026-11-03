```verilog
module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
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
    input  wire                     s_clk,
    input  wire                     s_rst,
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
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    // FIFO signals
    reg [$clog2(DEPTH):0]           wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0]           wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync2, rd_ptr_gray_sync2;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync3, rd_ptr_gray_sync3;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync4, rd_ptr_gray_sync4;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync5, rd_ptr_gray_sync5;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync6, rd_ptr_gray_sync6;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync7, rd_ptr_gray_sync7;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync8, rd_ptr_gray_sync8;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync9, rd_ptr_gray_sync9;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync10, rd_ptr_gray_sync10;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync11, rd_ptr_gray_sync11;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync12, rd_ptr_gray_sync12;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync13, rd_ptr_gray_sync13;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync14, rd_ptr_gray_sync14;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync15, rd_ptr_gray_sync15;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync16, rd_ptr_gray_sync16;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync17, rd_ptr_gray_sync17;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync18, rd_ptr_gray_sync18;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync19, rd_ptr_gray_sync19;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync20, rd_ptr_gray_sync20;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync21, rd_ptr_gray_sync21;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync22, rd_ptr_gray_sync22;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync23, rd_ptr_gray_sync23;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync24, rd_ptr_gray_sync24;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync25, rd_ptr_gray_sync25;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync26, rd_ptr_gray_sync26;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync27, rd_ptr_gray_sync27;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync28, rd_ptr_gray_sync28;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync29, rd_ptr_gray_sync29;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync30, rd_ptr_gray_sync30;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync31, rd_ptr_gray_sync31;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync32, rd_ptr_gray_sync32;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync33, rd_ptr_gray_sync33;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync34, rd_ptr_gray_sync34;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync35, rd_ptr_gray_sync35;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync36, rd_ptr_gray_sync36;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync37, rd_ptr_gray_sync37;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync38, rd_ptr_gray_sync38;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync39, rd_ptr_gray_sync39;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync40, rd_ptr_gray_sync40;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync41, rd_ptr_gray_sync41;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync42, rd_ptr_gray_sync42;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync43, rd_ptr_gray_sync43;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync44, rd_ptr_gray_sync44;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync45, rd_ptr_gray_sync45;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync46, rd_ptr_gray_sync46;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync47, rd_ptr_gray_sync47;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync48, rd_ptr_gray_sync48;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync49, rd_ptr_gray_sync49;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync50, rd_ptr_gray_sync50;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync51, rd_ptr_gray_sync51;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync52, rd_ptr_gray_sync52;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync53, rd_ptr_gray_sync53;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync54, rd_ptr_gray_sync54;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync55, rd_ptr_gray_sync55;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync56, rd_ptr_gray_sync56;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync57, rd_ptr_gray_sync57;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync58, rd_ptr_gray_sync58;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync59, rd_ptr_gray_sync59;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync60, rd_ptr_gray_sync60;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync61, rd_ptr_gray_sync61;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync62, rd_ptr_gray_sync62;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync63, rd_ptr_gray_sync63;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync64, rd_ptr_gray_sync64;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync65, rd_ptr_gray_sync65;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync66, rd_ptr_gray_sync66;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync67, rd_ptr_gray_sync67;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync68, rd_ptr_gray_sync68;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync69, rd_ptr_gray_sync69;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync70, rd_ptr_gray_sync70;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync71, rd_ptr_gray_sync71;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync72, rd_ptr_gray_sync72;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync73, rd_ptr_gray_sync73;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync74, rd_ptr_gray_sync74;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync75, rd_ptr_gray_sync75;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync76, rd_ptr_gray_sync76;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync77, rd_ptr_gray_sync77;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync78, rd_ptr_gray_sync78;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync79, rd_ptr_gray_sync79;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync80, rd_ptr_gray_sync80;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync81, rd_ptr_gray_sync81;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync82, rd_ptr_gray_sync82;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync83, rd_ptr_gray_sync83;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync84, rd_ptr_gray_sync84;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync85, rd_ptr_gray_sync85;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync86, rd_ptr_gray_sync86;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync87, rd_ptr_gray_sync87;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync88, rd_ptr_gray_sync88;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync89, rd_ptr_gray_sync89;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync90, rd_ptr_gray_sync90;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync91, rd_ptr_gray_sync91;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync92, rd_ptr_gray_sync92;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync93, rd_ptr_gray_sync93;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync94, rd_ptr_gray_sync94;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync95, rd_ptr_gray_sync95;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync96, rd_ptr_gray_sync96;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync97, rd_ptr_gray_sync97;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync98, rd_ptr_gray_sync98;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync99, rd_ptr_gray_sync99;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync100, rd_ptr_gray_sync100;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync101, rd_ptr_gray_sync101;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync102, rd_ptr_gray_sync102;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync103, rd_ptr_gray_sync103;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync104, rd_ptr_gray_sync104;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync105, rd_ptr_gray_sync105;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync106, rd_ptr_gray_sync106;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync107, rd_ptr_gray_sync107;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync108, rd_ptr_gray_sync108;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync109, rd_ptr_gray_sync109;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync110, rd_ptr_gray_sync110;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync111, rd_ptr_gray_sync111;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync112, rd_ptr_gray_sync112;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync113, rd_ptr_gray_sync113;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync114, rd_ptr_gray_sync114;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync115, rd_ptr_gray_sync115;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync116, rd_ptr_gray_sync116;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync117, rd_ptr_gray_sync117;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync118, rd_ptr_gray_sync118;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync119, rd_ptr_gray_sync119;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync120, rd_ptr_gray_sync120;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync121, rd_ptr_gray_sync121;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync122, rd_ptr_gray_sync122;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync123, rd_ptr_gray_sync123;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync124, rd_ptr_gray_sync124;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync125, rd_ptr_gray_sync125;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync126, rd_ptr_gray_sync126;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync127, rd_ptr_gray_sync127;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync128, rd_ptr_gray_sync128;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync129, rd_ptr_gray_sync129;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync130, rd_ptr_gray_sync130;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync131, rd_ptr_gray_sync131;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync132, rd_ptr_gray_sync132;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync133, rd_ptr_gray_sync133;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync134, rd_ptr_gray_sync134;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync135, rd_ptr_gray_sync135;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync136, rd_ptr_gray_sync136;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync137, rd_ptr_gray_sync137;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync138, rd_ptr_gray_sync138;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync139, rd_ptr_gray_sync139;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync140, rd_ptr_gray_sync140;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync141, rd_ptr_gray_sync141;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync142, rd_ptr_gray_sync142;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync143, rd_ptr_gray_sync143;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync144, rd_ptr_gray_sync144;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync145, rd_ptr_gray_sync145;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync146, rd_ptr_gray_sync146;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync147, rd_ptr_gray_sync147;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync148, rd_ptr_gray_sync148;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync149, rd_ptr_gray_sync149;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync150, rd_ptr_gray_sync150;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync151, rd_ptr_gray_sync151;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync152, rd_ptr_gray_sync152;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync153, rd_ptr_gray_sync153;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync154, rd_ptr_gray_sync154;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync155, rd_ptr_gray_sync155;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync156, rd_ptr_gray_sync156;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync157, rd_ptr_gray_sync157;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync158, rd_ptr_gray_sync158;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync159, rd_ptr_gray_sync159;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync160, rd_ptr_gray_sync160;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync161, rd_ptr_gray_sync161;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync162, rd_ptr_gray_sync162;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync163, rd_ptr_gray_sync163;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync164, rd_ptr_gray_sync164;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync165, rd_ptr_gray_sync165;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync166, rd_ptr_gray_sync166;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync167, rd_ptr_gray_sync167;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync168, rd_ptr_gray_sync168;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync169, rd_ptr_gray_sync169;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync170, rd_ptr_gray_sync170;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync171, rd_ptr_gray_sync171;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync172, rd_ptr_gray_sync172;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync173, rd_ptr_gray_sync173;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync174, rd_ptr_gray_sync174;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync175, rd_ptr_gray_sync175;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync176, rd_ptr_gray_sync176;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync177, rd_ptr_gray_sync177;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync178, rd_ptr_gray_sync178;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync179, rd_ptr_gray_sync179;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync180, rd_ptr_gray_sync180;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync181, rd_ptr_gray_sync181;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync182, rd_ptr_gray_sync182;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync183, rd_ptr_gray_sync183;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync184, rd_ptr_gray_sync184;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync185, rd_ptr_gray_sync185;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync186, rd_ptr_gray_sync186;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync187, rd_ptr_gray_sync187;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync188, rd_ptr_gray_sync188;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync189, rd_ptr_gray_sync189;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync190, rd_ptr_gray_sync190;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync191, rd_ptr_gray_sync191;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync192, rd_ptr_gray_sync192;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync193, rd_ptr_gray_sync193;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync194, rd_ptr_gray_sync194;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync195, rd_ptr_gray_sync195;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync196, rd_ptr_gray_sync196;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync197, rd_ptr_gray_sync197;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync198, rd_ptr_gray_sync198;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync199, rd_ptr_gray_sync199;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync200, rd_ptr_gray_sync200;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync201, rd_ptr_gray_sync201;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync202, rd_ptr_gray_sync202;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync203, rd_ptr_gray_sync203;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync204, rd_ptr_gray_sync204;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync205, rd_ptr_gray_sync205;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync206, rd_ptr_gray_sync206;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync207, rd_ptr_gray_sync207;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync208, rd_ptr_gray_sync208;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync209, rd_ptr_gray_sync209;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync210, rd_ptr_gray_sync210;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync211, rd_ptr_gray_sync211;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync212, rd_ptr_gray_sync212;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync213, rd_ptr_gray_sync213;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync214, rd_ptr_gray_sync214;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync215, rd_ptr_gray_sync215;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync216, rd_ptr_gray_sync216;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync217, rd_ptr_gray_sync217;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync218, rd_ptr_gray_sync218;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync219, rd_ptr_gray_sync219;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync220, rd_ptr_gray_sync220;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync221, rd_ptr_gray_sync221;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync222, rd_ptr_gray_sync222;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync223, rd_ptr_gray_sync223;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync224, rd_ptr_gray_sync224;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync225, rd_ptr_gray_sync225;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync226, rd_ptr_gray_sync226;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync227, rd_ptr_gray_sync227;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync228, rd_ptr_gray_sync228;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync229, rd_ptr_gray_sync229;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync230, rd_ptr_gray_sync230;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync231, rd_ptr_gray_sync231;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync232, rd_ptr_gray_sync232;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync233, rd_ptr_gray_sync233;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync234, rd_ptr_gray_sync234;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync235, rd_ptr_gray_sync235;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync236, rd_ptr_gray_sync236;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync237, rd_ptr_gray_sync237;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync238, rd_ptr_gray_sync238;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync239, rd_ptr_gray_sync239;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync240, rd_ptr_gray_sync240;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync241, rd_ptr_gray_sync241;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync242, rd_ptr_gray_sync242;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync243, rd_ptr_gray_sync243;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync244, rd_ptr_gray_sync244;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync245, rd_ptr_gray_sync245;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync246, rd_ptr_gray_sync246;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync247, rd_ptr_gray_sync247;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync248, rd_ptr_gray_sync248;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync249, rd_ptr_gray_sync249;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync250, rd_ptr_gray_sync250;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync251, rd_ptr_gray_sync251;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync252, rd_ptr_gray_sync252;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync253, rd_ptr_gray_sync253;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync254, rd_ptr_gray_sync254;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync255, rd_ptr_gray_sync255;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync256, rd_ptr_gray_sync256;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync257, rd_ptr_gray_sync257;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync258, rd_ptr_gray_sync258;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync259, rd_ptr_gray_sync259;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync260, rd_ptr_gray_sync260;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync261, rd_ptr_gray_sync261;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync262, rd_ptr_gray_sync262;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync263, rd_ptr_gray_sync263;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync264, rd_ptr_gray_sync264;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync265, rd_ptr_gray_sync265;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync266, rd_ptr_gray_sync266;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync267, rd_ptr_gray_sync267;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync268, rd_ptr_gray_sync268;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync269, rd_ptr_gray_sync269;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync270, rd_ptr_gray_sync270;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync271, rd_ptr_gray_sync271;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync272, rd_ptr_gray_sync272;
    reg [$clog2(DEPTH):0]           wr_ptr_gray_sync273, rd_ptr_gray_sync273;
    reg [$clog2(DEPTH):0]