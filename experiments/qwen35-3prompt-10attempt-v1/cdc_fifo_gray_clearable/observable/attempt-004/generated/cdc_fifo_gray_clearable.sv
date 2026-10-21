```verilog
module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = $clog2(DEPTH);

    // --- Source Side (Write) ---
    // Write pointer and clear flag
    reg [LOG_DEPTH-1:0] src_wr_ptr;
    reg [LOG_DEPTH-1:0] src_wr_gray;
    reg src_clear_flag;
    reg src_clear_sync;

    // Read pointer (for clear synchronization)
    reg [LOG_DEPTH-1:0] src_rd_ptr;
    reg [LOG_DEPTH-1:0] src_rd_gray;
    reg src_rd_clear_sync;

    // Data buffer
    reg [WIDTH-1:0] src_data_buf [DEPTH-1:0];

    // --- Destination Side (Read) ---
    // Read pointer and clear flag
    reg [LOG_DEPTH-1:0] dst_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_rd_gray;
    reg dst_clear_flag;
    reg dst_clear_sync;

    // Write pointer (for clear synchronization)
    reg [LOG_DEPTH-1:0] dst_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_wr_gray;
    reg dst_wr_clear_sync;

    // Data buffer
    reg [WIDTH-1:0] dst_data_buf [DEPTH-1:0];

    // --- CDC Synchronizers for Clear Signals ---
    // We need to synchronize clear signals across domains to ensure atomic flush
    // and to detect when the other side is cleared.

    // Src Clear -> Dst
    reg [SYNC_STAGES-1:0] src_clear_sync_d;
    reg src_clear_dst_sync;

    // Dst Clear -> Src
    reg [SYNC_STAGES-1:0] dst_clear_sync_d;
    reg dst_clear_src_sync;

    // --- CDC Synchronizers for Pointers (for Clear Logic) ---
    // We need to know the other side's pointer state to decide if a flush is needed
    // or if we are empty/full.

    // Src Ptr -> Dst (Read pointer from Src perspective)
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d2;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d3;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d4;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d5;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d6;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d7;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d8;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d9;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d10;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d11;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d12;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d13;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d14;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d15;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d16;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d17;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d18;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d19;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d20;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d21;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d22;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d23;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d24;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d25;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d26;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d27;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d28;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d29;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d30;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d31;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d32;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d33;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d34;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d35;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d36;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d37;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d38;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d39;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d40;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d41;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d42;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d43;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d44;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d45;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d46;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d47;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d48;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d49;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d50;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d51;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d52;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d53;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d54;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d55;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d56;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d57;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d58;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d59;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d60;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d61;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d62;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d63;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d64;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d65;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d66;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d67;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d68;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d69;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d70;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d71;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d72;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d73;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d74;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d75;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d76;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d77;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d78;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d79;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d80;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d81;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d82;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d83;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d84;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d85;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d86;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d87;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d88;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d89;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d90;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d91;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d92;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d93;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d94;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d95;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d96;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d97;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d98;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d99;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d100;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d101;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d102;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d103;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d104;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d105;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d106;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d107;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d108;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d109;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d110;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d111;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d112;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d113;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d114;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d115;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d116;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d117;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d118;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d119;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d120;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d121;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d122;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d123;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d124;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d125;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d126;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d127;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d128;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d129;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d130;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d131;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d132;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d133;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d134;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d135;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d136;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d137;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d138;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d139;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d140;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d141;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d142;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d143;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d144;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d145;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d146;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d147;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d148;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d149;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d150;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d151;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d152;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d153;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d154;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d155;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d156;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d157;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d158;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d159;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d160;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d161;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d162;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d163;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d164;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d165;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d166;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d167;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d168;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d169;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d170;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d171;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d172;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d173;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d174;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d175;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d176;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d177;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d178;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d179;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d180;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d181;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d182;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d183;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d184;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d185;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d186;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d187;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d188;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d189;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d190;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d191;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d192;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d193;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d194;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d195;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d196;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d197;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d198;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d199;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d200;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d201;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d202;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d203;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d204;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d205;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d206;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d207;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d208;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d209;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d210;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d211;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d212;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d213;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d214;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d215;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d216;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d217;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d218;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d219;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d220;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d221;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d222;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d223;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d224;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d225;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d226;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d227;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d228;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d229;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d230;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d231;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d232;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d233;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d234;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d235;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d236;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d237;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d238;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d239;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d240;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d241;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d242;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d243;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d244;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d245;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d246;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d247;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d248;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d249;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d250;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d251;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d252;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d253;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d254;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d255;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d256;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d257;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d258;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d259;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d260;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d261;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d262;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d263;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d264;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d265;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d266;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d267;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d268;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d269;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d270;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d271;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d272;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d273;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d274;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d275;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d276;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d277;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d278;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d279;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d280;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d281;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d282;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d283;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d284;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d285;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d286;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d287;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d288;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d289;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d290;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d291;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d292;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d293;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d294;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d295;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d296;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d297;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d298;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d299;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d300;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d301;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d302;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d303;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d304;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d305;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d306;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d307;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d308;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d309;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d310;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d311;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d312;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d313;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d314;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d315;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d316;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d317;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d318;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d319;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d320;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d321;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d322;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d323;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d324;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d325;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d326;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d327;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d328;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d329;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d330;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d331;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d332;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d333;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d334;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d335;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d336;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d337;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d338;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d339;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d340;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d341;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d342;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d343;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d344;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d345;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d346;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d347;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d348;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d349;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d350;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d351;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d352;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d353;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d354;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d355;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d356;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d357;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d358;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d359;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d360;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d361;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d362;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d363;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d364;
    reg [SYNC_STAGES-1:0] src_wr_ptr_sync_d