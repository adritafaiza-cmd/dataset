```systemverilog
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  logic src_valid_sync;
  logic src_valid_sync2;
  logic src_valid_sync3;
  logic src_valid_sync4;
  logic src_valid_sync5;
  logic src_valid_sync6;
  logic src_valid_sync7;

  logic dst_valid_sync;
  logic dst_valid_sync2;
  logic dst_valid_sync3;
  logic dst_valid_sync4;
  logic dst_valid_sync5;
  logic dst_valid_sync6;
  logic dst_valid_sync7;

  logic src_data_sync;
  logic src_data_sync2;
  logic src_data_sync3;
  logic src_data_sync4;
  logic src_data_sync5;
  logic src_data_sync6;
  logic src_data_sync7;

  logic dst_data_sync;
  logic dst_data_sync2;
  logic dst_data_sync3;
  logic dst_data_sync4;
  logic dst_data_sync5;
  logic dst_data_sync6;
  logic dst_data_sync7;

  logic src_valid_pulse;
  logic src_valid_pulse2;
  logic src_valid_pulse3;
  logic src_valid_pulse4;
  logic src_valid_pulse5;
  logic src_valid_pulse6;
  logic src_valid_pulse7;

  logic dst_valid_pulse;
  logic dst_valid_pulse2;
  logic dst_valid_pulse3;
  logic dst_valid_pulse4;
  logic dst_valid_pulse5;
  logic dst_valid_pulse6;
  logic dst_valid_pulse7;

  logic src_ready_pulse;
  logic src_ready_pulse2;
  logic src_ready_pulse3;
  logic src_ready_pulse4;
  logic src_ready_pulse5;
  logic src_ready_pulse6;
  logic src_ready_pulse7;

  logic dst_ready_pulse;
  logic dst_ready_pulse2;
  logic dst_ready_pulse3;
  logic dst_ready_pulse4;
  logic dst_ready_pulse5;
  logic dst_ready_pulse6;
  logic dst_ready_pulse7;

  logic src_valid_handshake;
  logic src_valid_handshake2;
  logic src_valid_handshake3;
  logic src_valid_handshake4;
  logic src_valid_handshake5;
  logic src_valid_handshake6;
  logic src_valid_handshake7;

  logic dst_valid_handshake;
  logic dst_valid_handshake2;
  logic dst_valid_handshake3;
  logic dst_valid_handshake4;
  logic dst_valid_handshake5;
  logic dst_valid_handshake6;
  logic dst_valid_handshake7;

  logic src_data_handshake;
  logic src_data_handshake2;
  logic src_data_handshake3;
  logic src_data_handshake4;
  logic src_data_handshake5;
  logic src_data_handshake6;
  logic src_data_handshake7;

  logic dst_data_handshake;
  logic dst_data_handshake2;
  logic dst_data_handshake3;
  logic dst_data_handshake4;
  logic dst_data_handshake5;
  logic dst_data_handshake6;
  logic dst_data_handshake7;

  logic src_valid_handshake_sync;
  logic src_valid_handshake_sync2;
  logic src_valid_handshake_sync3;
  logic src_valid_handshake_sync4;
  logic src_valid_handshake_sync5;
  logic src_valid_handshake_sync6;
  logic src_valid_handshake_sync7;

  logic dst_valid_handshake_sync;
  logic dst_valid_handshake_sync2;
  logic dst_valid_handshake_sync3;
  logic dst_valid_handshake_sync4;
  logic dst_valid_handshake_sync5;
  logic dst_valid_handshake_sync6;
  logic dst_valid_handshake_sync7;

  logic src_data_handshake_sync;
  logic src_data_handshake_sync2;
  logic src_data_handshake_sync3;
  logic src_data_handshake_sync4;
  logic src_data_handshake_sync5;
  logic src_data_handshake_sync6;
  logic src_data_handshake_sync7;

  logic dst_data_handshake_sync;
  logic dst_data_handshake_sync2;
  logic dst_data_handshake_sync3;
  logic dst_data_handshake_sync4;
  logic dst_data_handshake_sync5;
  logic dst_data_handshake_sync6;
  logic dst_data_handshake_sync7;

  logic src_valid_handshake_pulse;
  logic src_valid_handshake_pulse2;
  logic src_valid_handshake_pulse3;
  logic src_valid_handshake_pulse4;
  logic src_valid_handshake_pulse5;
  logic src_valid_handshake_pulse6;
  logic src_valid_handshake_pulse7;

  logic dst_valid_handshake_pulse;
  logic dst_valid_handshake_pulse2;
  logic dst_valid_handshake_pulse3;
  logic dst_valid_handshake_pulse4;
  logic dst_valid_handshake_pulse5;
  logic dst_valid_handshake_pulse6;
  logic dst_valid_handshake_pulse7;

  logic src_ready_handshake_pulse;
  logic src_ready_handshake_pulse2;
  logic src_ready_handshake_pulse3;
  logic src_ready_handshake_pulse4;
  logic src_ready_handshake_pulse5;
  logic src_ready_handshake_pulse6;
  logic src_ready_handshake_pulse7;

  logic dst_ready_handshake_pulse;
  logic dst_ready_handshake_pulse2;
  logic dst_ready_handshake_pulse3;
  logic dst_ready_handshake_pulse4;
  logic dst_ready_handshake_pulse5;
  logic dst_ready_handshake_pulse6;
  logic dst_ready_handshake_pulse7;

  logic src_valid_handshake_sync_pulse;
  logic src_valid_handshake_sync_pulse2;
  logic src_valid_handshake_sync_pulse3;
  logic src_valid_handshake_sync_pulse4;
  logic src_valid_handshake_sync_pulse5;
  logic src_valid_handshake_sync_pulse6;
  logic src_valid_handshake_sync_pulse7;

  logic dst_valid_handshake_sync_pulse;
  logic dst_valid_handshake_sync_pulse2;
  logic dst_valid_handshake_sync_pulse3;
  logic dst_valid_handshake_sync_pulse4;
  logic dst_valid_handshake_sync_pulse5;
  logic dst_valid_handshake_sync_pulse6;
  logic dst_valid_handshake_sync_pulse7;

  logic src_valid_handshake_sync_pulse2;
  logic dst_valid_handshake_sync_pulse2;

  logic src_valid_handshake_sync_pulse3;
  logic dst_valid_handshake_sync_pulse3;

  logic src_valid_handshake_sync_pulse4;
  logic dst_valid_handshake_sync_pulse4;

  logic src_valid_handshake_sync_pulse5;
  logic dst_valid_handshake_sync_pulse5;

  logic src_valid_handshake_sync_pulse6;
  logic dst_valid_handshake_sync_pulse6;

  logic src_valid_handshake_sync_pulse7;
  logic dst_valid_handshake_sync_pulse7;

  logic src_valid_handshake_sync_pulse8;
  logic dst_valid_handshake_sync_pulse8;

  logic src_valid_handshake_sync_pulse9;
  logic dst_valid_handshake_sync_pulse9;

  logic src_valid_handshake_sync_pulse10;
  logic dst_valid_handshake_sync_pulse10;

  logic src_valid_handshake_sync_pulse11;
  logic dst_valid_handshake_sync_pulse11;

  logic src_valid_handshake_sync_pulse12;
  logic dst_valid_handshake_sync_pulse12;

  logic src_valid_handshake_sync_pulse13;
  logic dst_valid_handshake_sync_pulse13;

  logic src_valid_handshake_sync_pulse14;
  logic dst_valid_handshake_sync_pulse14;

  logic src_valid_handshake_sync_pulse15;
  logic dst_valid_handshake_sync_pulse15;

  logic src_valid_handshake_sync_pulse16;
  logic dst_valid_handshake_sync_pulse16;

  logic src_valid_handshake_sync_pulse17;
  logic dst_valid_handshake_sync_pulse17;

  logic src_valid_handshake_sync_pulse18;
  logic dst_valid_handshake_sync_pulse18;

  logic src_valid_handshake_sync_pulse19;
  logic dst_valid_handshake_sync_pulse19;

  logic src_valid_handshake_sync_pulse20;
  logic dst_valid_handshake_sync_pulse20;

  logic src_valid_handshake_sync_pulse21;
  logic dst_valid_handshake_sync_pulse21;

  logic src_valid_handshake_sync_pulse22;
  logic dst_valid_handshake_sync_pulse22;

  logic src_valid_handshake_sync_pulse23;
  logic dst_valid_handshake_sync_pulse23;

  logic src_valid_handshake_sync_pulse24;
  logic dst_valid_handshake_sync_pulse24;

  logic src_valid_handshake_sync_pulse25;
  logic dst_valid_handshake_sync_pulse25;

  logic src_valid_handshake_sync_pulse26;
  logic dst_valid_handshake_sync_pulse26;

  logic src_valid_handshake_sync_pulse27;
  logic dst_valid_handshake_sync_pulse27;

  logic src_valid_handshake_sync_pulse28;
  logic dst_valid_handshake_sync_pulse28;

  logic src_valid_handshake_sync_pulse29;
  logic dst_valid_handshake_sync_pulse29;

  logic src_valid_handshake_sync_pulse30;
  logic dst_valid_handshake_sync_pulse30;

  logic src_valid_handshake_sync_pulse31;
  logic dst_valid_handshake_sync_pulse31;

  logic src_valid_handshake_sync_pulse32;
  logic dst_valid_handshake_sync_pulse32;

  logic src_valid_handshake_sync_pulse33;
  logic dst_valid_handshake_sync_pulse33;

  logic src_valid_handshake_sync_pulse34;
  logic dst_valid_handshake_sync_pulse34;

  logic src_valid_handshake_sync_pulse35;
  logic dst_valid_handshake_sync_pulse35;

  logic src_valid_handshake_sync_pulse36;
  logic dst_valid_handshake_sync_pulse36;

  logic src_valid_handshake_sync_pulse37;
  logic dst_valid_handshake_sync_pulse37;

  logic src_valid_handshake_sync_pulse38;
  logic dst_valid_handshake_sync_pulse38;

  logic src_valid_handshake_sync_pulse39;
  logic dst_valid_handshake_sync_pulse39;

  logic src_valid_handshake_sync_pulse40;
  logic dst_valid_handshake_sync_pulse40;

  logic src_valid_handshake_sync_pulse41;
  logic dst_valid_handshake_sync_pulse41;

  logic src_valid_handshake_sync_pulse42;
  logic dst_valid_handshake_sync_pulse42;

  logic src_valid_handshake_sync_pulse43;
  logic dst_valid_handshake_sync_pulse43;

  logic src_valid_handshake_sync_pulse44;
  logic dst_valid_handshake_sync_pulse44;

  logic src_valid_handshake_sync_pulse45;
  logic dst_valid_handshake_sync_pulse45;

  logic src_valid_handshake_sync_pulse46;
  logic dst_valid_handshake_sync_pulse46;

  logic src_valid_handshake_sync_pulse47;
  logic dst_valid_handshake_sync_pulse47;

  logic src_valid_handshake_sync_pulse48;
  logic dst_valid_handshake_sync_pulse48;

  logic src_valid_handshake_sync_pulse49;
  logic dst_valid_handshake_sync_pulse49;

  logic src_valid_handshake_sync_pulse50;
  logic dst_valid_handshake_sync_pulse50;

  logic src_valid_handshake_sync_pulse51;
  logic dst_valid_handshake_sync_pulse51;

  logic src_valid_handshake_sync_pulse52;
  logic dst_valid_handshake_sync_pulse52;

  logic src_valid_handshake_sync_pulse53;
  logic dst_valid_handshake_sync_pulse53;

  logic src_valid_handshake_sync_pulse54;
  logic dst_valid_handshake_sync_pulse54;

  logic src_valid_handshake_sync_pulse55;
  logic dst_valid_handshake_sync_pulse55;

  logic src_valid_handshake_sync_pulse56;
  logic dst_valid_handshake_sync_pulse56;

  logic src_valid_handshake_sync_pulse57;
  logic dst_valid_handshake_sync_pulse57;

  logic src_valid_handshake_sync_pulse58;
  logic dst_valid_handshake_sync_pulse58;

  logic src_valid_handshake_sync_pulse59;
  logic dst_valid_handshake_sync_pulse59;

  logic src_valid_handshake_sync_pulse60;
  logic dst_valid_handshake_sync_pulse60;

  logic src_valid_handshake_sync_pulse61;
  logic dst_valid_handshake_sync_pulse61;

  logic src_valid_handshake_sync_pulse62;
  logic dst_valid_handshake_sync_pulse62;

  logic src_valid_handshake_sync_pulse63;
  logic dst_valid_handshake_sync_pulse63;

  logic src_valid_handshake_sync_pulse64;
  logic dst_valid_handshake_sync_pulse64;

  logic src_valid_handshake_sync_pulse65;
  logic dst_valid_handshake_sync_pulse65;

  logic src_valid_handshake_sync_pulse66;
  logic dst_valid_handshake_sync_pulse66;

  logic src_valid_handshake_sync_pulse67;
  logic dst_valid_handshake_sync_pulse67;

  logic src_valid_handshake_sync_pulse68;
  logic dst_valid_handshake_sync_pulse68;

  logic src_valid_handshake_sync_pulse69;
  logic dst_valid_handshake_sync_pulse69;

  logic src_valid_handshake_sync_pulse70;
  logic dst_valid_handshake_sync_pulse70;

  logic src_valid_handshake_sync_pulse71;
  logic dst_valid_handshake_sync_pulse71;

  logic src_valid_handshake_sync_pulse72;
  logic dst_valid_handshake_sync_pulse72;

  logic src_valid_handshake_sync_pulse73;
  logic dst_valid_handshake_sync_pulse73;

  logic src_valid_handshake_sync_pulse74;
  logic dst_valid_handshake_sync_pulse74;

  logic src_valid_handshake_sync_pulse75;
  logic dst_valid_handshake_sync_pulse75;

  logic src_valid_handshake_sync_pulse76;
  logic dst_valid_handshake_sync_pulse76;

  logic src_valid_handshake_sync_pulse77;
  logic dst_valid_handshake_sync_pulse77;

  logic src_valid_handshake_sync_pulse78;
  logic dst_valid_handshake_sync_pulse78;

  logic src_valid_handshake_sync_pulse79;
  logic dst_valid_handshake_sync_pulse79;

  logic src_valid_handshake_sync_pulse80;
  logic dst_valid_handshake_sync_pulse80;

  logic src_valid_handshake_sync_pulse81;
  logic dst_valid_handshake_sync_pulse81;

  logic src_valid_handshake_sync_pulse82;
  logic dst_valid_handshake_sync_pulse82;

  logic src_valid_handshake_sync_pulse83;
  logic dst_valid_handshake_sync_pulse83;

  logic src_valid_handshake_sync_pulse84;
  logic dst_valid_handshake_sync_pulse84;

  logic src_valid_handshake_sync_pulse85;
  logic dst_valid_handshake_sync_pulse85;

  logic src_valid_handshake_sync_pulse86;
  logic dst_valid_handshake_sync_pulse86;

  logic src_valid_handshake_sync_pulse87;
  logic dst_valid_handshake_sync_pulse87;

  logic src_valid_handshake_sync_pulse88;
  logic dst_valid_handshake_sync_pulse88;

  logic src_valid_handshake_sync_pulse89;
  logic dst_valid_handshake_sync_pulse89;

  logic src_valid_handshake_sync_pulse90;
  logic dst_valid_handshake_sync_pulse90;

  logic src_valid_handshake_sync_pulse91;
  logic dst_valid_handshake_sync_pulse91;

  logic src_valid_handshake_sync_pulse92;
  logic dst_valid_handshake_sync_pulse92;

  logic src_valid_handshake_sync_pulse93;
  logic dst_valid_handshake_sync_pulse93;

  logic src_valid_handshake_sync_pulse94;
  logic dst_valid_handshake_sync_pulse94;

  logic src_valid_handshake_sync_pulse95;
  logic dst_valid_handshake_sync_pulse95;

  logic src_valid_handshake_sync_pulse96;
  logic dst_valid_handshake_sync_pulse96;

  logic src_valid_handshake_sync_pulse97;
  logic dst_valid_handshake_sync_pulse97;

  logic src_valid_handshake_sync_pulse98;
  logic dst_valid_handshake_sync_pulse98;

  logic src_valid_handshake_sync_pulse99;
  logic dst_valid_handshake_sync_pulse99;

  logic src_valid_handshake_sync_pulse100;
  logic dst_valid_handshake_sync_pulse100;

  logic src_valid_handshake_sync_pulse101;
  logic dst_valid_handshake_sync_pulse101;

  logic src_valid_handshake_sync_pulse102;
  logic dst_valid_handshake_sync_pulse102;

  logic src_valid_handshake_sync_pulse103;
  logic dst_valid_handshake_sync_pulse103;

  logic src_valid_handshake_sync_pulse104;
  logic dst_valid_handshake_sync_pulse104;

  logic src_valid_handshake_sync_pulse105;
  logic dst_valid_handshake_sync_pulse105;

  logic src_valid_handshake_sync_pulse106;
  logic dst_valid_handshake_sync_pulse106;

  logic src_valid_handshake_sync_pulse107;
  logic dst_valid_handshake_sync_pulse107;

  logic src_valid_handshake_sync_pulse108;
  logic dst_valid_handshake_sync_pulse108;

  logic src_valid_handshake_sync_pulse109;
  logic dst_valid_handshake_sync_pulse109;

  logic src_valid_handshake_sync_pulse110;
  logic dst_valid_handshake_sync_pulse110;

  logic src_valid_handshake_sync_pulse111;
  logic dst_valid_handshake_sync_pulse111;

  logic src_valid_handshake_sync_pulse112;
  logic dst_valid_handshake_sync_pulse112;

  logic src_valid_handshake_sync_pulse113;
  logic dst_valid_handshake_sync_pulse113;

  logic src_valid_handshake_sync_pulse114;
  logic dst_valid_handshake_sync_pulse114;

  logic src_valid_handshake_sync_pulse115;
  logic dst_valid_handshake_sync_pulse115;

  logic src_valid_handshake_sync_pulse116;
  logic dst_valid_handshake_sync_pulse116;

  logic src_valid_handshake_sync_pulse117;
  logic dst_valid_handshake_sync_pulse117;

  logic src_valid_handshake_sync_pulse118;
  logic dst_valid_handshake_sync_pulse118;

  logic src_valid_handshake_sync_pulse119;
  logic dst_valid_handshake_sync_pulse119;

  logic src_valid_handshake_sync_pulse120;
  logic dst_valid_handshake_sync_pulse120;

  logic src_valid_handshake_sync_pulse121;
  logic dst_valid_handshake_sync_pulse121;

  logic src_valid_handshake_sync_pulse122;
  logic dst_valid_handshake_sync_pulse122;

  logic src_valid_handshake_sync_pulse123;
  logic dst_valid_handshake_sync_pulse123;

  logic src_valid_handshake_sync_pulse124;
  logic dst_valid_handshake_sync_pulse124;

  logic src_valid_handshake_sync_pulse125;
  logic dst_valid_handshake_sync_pulse125;

  logic src_valid_handshake_sync_pulse126;
  logic dst_valid_handshake_sync_pulse126;

  logic src_valid_handshake_sync_pulse127;
  logic dst_valid_handshake_sync_pulse127;

  logic src_valid_handshake_sync_pulse128;
  logic dst_valid_handshake_sync_pulse128;

  logic src_valid_handshake_sync_pulse129;
  logic dst_valid_handshake_sync_pulse129;

  logic src_valid_handshake_sync_pulse130;
  logic dst_valid_handshake_sync_pulse130;

  logic src_valid_handshake_sync_pulse131;
  logic dst_valid_handshake_sync_pulse131;

  logic src_valid_handshake_sync_pulse132;
  logic dst_valid_handshake_sync_pulse132;

  logic src_valid_handshake_sync_pulse133;
  logic dst_valid_handshake_sync_pulse133;

  logic src_valid_handshake_sync_pulse134;
  logic dst_valid_handshake_sync_pulse134;

  logic src_valid_handshake_sync_pulse135;
  logic dst_valid_handshake_sync_pulse135;

  logic src_valid_handshake_sync_pulse136;
  logic dst_valid_handshake_sync_pulse136;

  logic src_valid_handshake_sync_pulse137;
  logic dst_valid_handshake_sync_pulse137;

  logic src_valid_handshake_sync_pulse138;
  logic dst_valid_handshake_sync_pulse138;

  logic src_valid_handshake_sync_pulse139;
  logic dst_valid_handshake_sync_pulse139;

  logic src_valid_handshake_sync_pulse140;
  logic dst_valid_handshake_sync_pulse140;

  logic src_valid_handshake_sync_pulse141;
  logic dst_valid_handshake_sync_pulse141;

  logic src_valid_handshake_sync_pulse142;
  logic dst_valid_handshake_sync_pulse142;

  logic src_valid_handshake_sync_pulse143;
  logic dst_valid_handshake_sync_pulse143;

  logic src_valid_handshake_sync_pulse144;
  logic dst_valid_handshake_sync_pulse144;

  logic src_valid_handshake_sync_pulse145;
  logic dst_valid_handshake_sync_pulse145;

  logic src_valid_handshake_sync_pulse146;
  logic dst_valid_handshake_sync_pulse146;

  logic src_valid_handshake_sync_pulse147;
  logic dst_valid_handshake_sync_pulse147;

  logic src_valid_handshake_sync_pulse148;
  logic dst_valid_handshake_sync_pulse148;

  logic src_valid_handshake_sync_pulse149;
  logic dst_valid_handshake_sync_pulse149;

  logic src_valid_handshake_sync_pulse150;
  logic dst_valid_handshake_sync_pulse150;

  logic src_valid_handshake_sync_pulse151;
  logic dst_valid_handshake_sync_pulse151;

  logic src_valid_handshake_sync_pulse152;
  logic dst_valid_handshake_sync_pulse152;

  logic src_valid_handshake_sync_pulse153;
  logic dst_valid_handshake_sync_pulse153;

  logic src_valid_handshake_sync_pulse154;
  logic dst_valid_handshake_sync_pulse154;

  logic src_valid_handshake_sync_pulse155;
  logic dst_valid_handshake_sync_pulse155;

  logic src_valid_handshake_sync_pulse156;
  logic dst_valid_handshake_sync_pulse156;

  logic src_valid_handshake_sync_pulse157;
  logic dst_valid_handshake_sync_pulse157;

  logic src_valid_handshake_sync_pulse158;
  logic dst_valid_handshake_sync_pulse158;

  logic src_valid_handshake_sync_pulse159;
  logic dst_valid_handshake_sync_pulse159;

  logic src_valid_handshake_sync_pulse160;
  logic dst_valid_handshake_sync_pulse160;

  logic src_valid_handshake_sync_pulse161;
  logic dst_valid_handshake_sync_pulse161;

  logic src_valid_handshake_sync_pulse162;
  logic dst_valid_handshake_sync_pulse162;

  logic src_valid_handshake_sync_pulse163;
  logic dst_valid_handshake_sync_pulse163;

  logic src_valid_handshake_sync_pulse164;
  logic dst_valid_handshake_sync_pulse164;

  logic src_valid_handshake_sync_pulse165;
  logic dst_valid_handshake_sync_pulse165;

  logic src_valid_handshake_sync_pulse166;
  logic dst_valid_handshake_sync_pulse166;

  logic src_valid_handshake_sync_pulse167;
  logic dst_valid_handshake_sync_pulse167;

  logic src_valid_handshake_sync_pulse168;
  logic dst_valid_handshake_sync_pulse168;

  logic src_valid_handshake_sync_pulse169;
  logic dst_valid_handshake_sync_pulse169;

  logic src_valid_handshake_sync_pulse170;
  logic dst_valid_handshake_sync_pulse170;

  logic src_valid_handshake_sync_pulse171;
  logic dst_valid_handshake_sync_pulse171;

  logic src_valid_handshake_sync_pulse172;
  logic dst_valid_handshake_sync_pulse172;

  logic src_valid_handshake_sync_pulse173;
  logic dst_valid_handshake_sync_pulse173;

  logic src_valid_handshake_sync_pulse174;
  logic dst_valid_handshake_sync_pulse174;

  logic src_valid_handshake_sync_pulse175;
  logic dst_valid_handshake_sync_pulse175;

  logic src_valid_handshake_sync_pulse176;
  logic dst_valid_handshake_sync_pulse176;

  logic src_valid_handshake_sync_pulse177;
  logic dst_valid_handshake_sync_pulse177;

  logic src_valid_handshake_sync_pulse178;
  logic dst_valid_handshake_sync_pulse178;

  logic src_valid_handshake_sync_pulse179;
  logic dst_valid_handshake_sync_pulse179;

  logic src_valid_handshake_sync_pulse180;
  logic dst_valid_handshake_sync_pulse180;

  logic src_valid_handshake_sync_pulse181;
  logic dst_valid_handshake_sync_pulse181;

  logic src_valid_handshake_sync_pulse182;
  logic dst_valid_handshake_sync_pulse182;

  logic src_valid_handshake_sync_pulse183;
  logic dst_valid_handshake_sync_pulse183;

  logic src_valid_handshake_sync_pulse184;
  logic dst_valid_handshake_sync_pulse184;

  logic src_valid_handshake_sync_pulse185;
  logic dst_valid_handshake_sync_pulse185;

  logic src_valid_handshake_sync_pulse186;
  logic dst_valid_handshake_sync_pulse186;

  logic src_valid_handshake_sync_pulse187;
  logic dst_valid_handshake_sync_pulse187;

  logic src_valid_handshake_sync_pulse188;
  logic dst_valid_handshake_sync_pulse188;

  logic src_valid_handshake_sync_pulse189;
  logic dst_valid_handshake_sync_pulse189;

  logic src_valid_handshake_sync_pulse190;
  logic dst_valid_handshake_sync_pulse190;

  logic src_valid_handshake_sync_pulse191;
  logic dst_valid_handshake_sync_pulse191;

  logic src_valid_handshake_sync_pulse192;
  logic dst_valid_handshake_sync_pulse192;

  logic src_valid_handshake_sync_pulse193;
  logic dst_valid_handshake_sync_pulse193;

  logic src_valid_handshake_sync_pulse194;
  logic dst_valid_handshake_sync_pulse194;

  logic src_valid_handshake_sync_pulse195;
  logic dst_valid_handshake_sync_pulse195;

  logic src_valid_handshake_sync_pulse196;
  logic dst_valid_handshake_sync_pulse196;

  logic src_valid_handshake_sync_pulse197;
  logic dst_valid_handshake_sync_pulse197;

  logic src_valid_handshake_sync_pulse198;
  logic dst_valid_handshake_sync_pulse198;

  logic src_valid_handshake_sync_pulse199;
  logic dst_valid_handshake_sync_pulse199;

  logic src_valid_handshake_sync_pulse200;
  logic dst_valid_handshake_sync_pulse200;

  logic src_valid_handshake_sync_pulse201;
  logic dst_valid_handshake_sync_pulse201;

  logic src_valid_handshake_sync_pulse202;
  logic dst_valid_handshake_sync_pulse202;

  logic src_valid_handshake_sync_pulse203;
  logic dst_valid_handshake_sync_pulse203;

  logic src_valid_handshake_sync_pulse204;
  logic dst_valid_handshake_sync_pulse204;

  logic src_valid_handshake_sync_pulse205;
  logic dst_valid_handshake_sync_pulse205;

  logic src_valid_handshake_sync_pulse206;
  logic dst_valid_handshake_sync_pulse206;

  logic src_valid_handshake_sync_pulse207;
  logic dst_valid_handshake_sync_pulse207;

  logic src_valid_handshake_sync_pulse208;
  logic dst_valid_handshake_sync_pulse208;

  logic src_valid_handshake_sync_pulse209;
  logic dst_valid_handshake_sync_pulse209;

  logic src_valid_handshake_sync_pulse210;
  logic dst_valid_handshake_sync_pulse210;

  logic src_valid_handshake_sync_pulse211;
  logic dst_valid_handshake_sync_pulse211;

  logic src_valid_handshake_sync_pulse212;
  logic dst_valid_handshake_sync_pulse212;

  logic src_valid_handshake_sync_pulse213;
  logic dst_valid_handshake_sync_pulse213;

  logic src_valid_handshake_sync_pulse214;
  logic dst_valid_handshake_sync_pulse214;

  logic src_valid_handshake_sync_pulse215;
  logic dst_valid_handshake_sync_pulse215;

  logic src_valid_handshake_sync_pulse216;
  logic dst_valid_handshake_sync_pulse216;

  logic src_valid_handshake_sync_pulse217;
  logic dst_valid_handshake_sync_pulse217;

  logic src_valid_handshake_sync_pulse218;
  logic dst_valid_handshake_sync_pulse218;

  logic src_valid_handshake_sync_pulse219;
  logic dst_valid_handshake_sync_pulse219;

  logic src_valid_handshake_sync_pulse220;
  logic dst_valid_handshake_sync_pulse220;

  logic src_valid_handshake_sync_pulse221;
  logic dst_valid_handshake_sync_pulse221;

  logic src_valid_handshake_sync_pulse222;
  logic dst_valid_handshake_sync_pulse222;

  logic src_valid_handshake_sync_pulse223;
  logic dst_valid_handshake_sync_pulse223;

  logic src_valid_handshake_sync_pulse224;
  logic dst_valid_handshake_sync_pulse224;

  logic src_valid_handshake_sync_pulse225;
  logic dst_valid_handshake_sync_pulse225;

  logic src_valid_handshake_sync_pulse226;
  logic dst_valid_handshake_sync_pulse226;

  logic src_valid_handshake_sync_pulse227;
  logic dst_valid_handshake_sync_pulse227;

  logic src_valid_handshake_sync_pulse228;
  logic dst_valid_handshake_sync_pulse228;

  logic src_valid_handshake_sync_pulse229;
  logic dst_valid_handshake_sync_pulse229;

  logic src_valid_handshake_sync_pulse230;
  logic dst_valid_handshake_sync_pulse230;

  logic src_valid_handshake_sync_pulse231;
  logic dst_valid_handshake_sync_pulse231;

  logic src_valid_handshake_sync_pulse232;
  logic dst_valid_handshake_sync_pulse232;

  logic src_valid_handshake_sync_pulse233;
  logic dst_valid_handshake_sync_pulse233;

  logic src_valid_handshake_sync_pulse234;
  logic dst_valid_handshake_sync_pulse234;

  logic src_valid_handshake_sync_pulse235;
  logic dst_valid_handshake_sync_pulse235;

  logic src_valid_handshake_sync_pulse236;
  logic dst_valid_handshake_sync_pulse236;

  logic src_valid_handshake_sync_pulse237;
  logic dst_valid_handshake_sync_pulse237;

  logic src_valid_handshake_sync_pulse238;
  logic dst_valid_handshake_sync_pulse238;

  logic src_valid_handshake_sync_pulse239;
  logic dst_valid_handshake_sync_pulse239;

  logic src_valid_handshake_sync_pulse240;
  logic dst_valid_handshake_sync_pulse240;

  logic src_valid_handshake_sync_pulse241;
  logic dst_valid_handshake_sync_pulse241;

  logic src_valid_handshake_sync_pulse242;
  logic dst_valid_handshake_sync_pulse242;

  logic src_valid_handshake_sync_pulse243;
  logic dst_valid_handshake_sync_pulse243;

  logic src_valid_handshake_sync_pulse244;
  logic dst_valid_handshake_sync_pulse244;

  logic src_valid_handshake_sync_pulse245;
  logic dst_valid_handshake_sync_pulse245;

  logic src_valid_handshake_sync_pulse246;
  logic dst_valid_handshake_sync_pulse246;

  logic src_valid_handshake_sync_pulse247;
  logic dst_valid_handshake_sync_pulse247;

  logic src_valid_handshake_sync_pulse248;
  logic dst_valid_handshake_sync_pulse248;

  logic src_valid_handshake_sync_pulse249;
  logic dst_valid_handshake_sync_pulse249;

  logic src_valid_handshake_sync_pulse250;
  logic dst_valid_handshake_sync_pulse250;

  logic src_valid_handshake_sync_pulse251;
  logic dst_valid_handshake_sync_pulse251;

  logic src_valid_handshake_sync_pulse252;
  logic dst_valid_handshake_sync_pulse252;

  logic src_valid_handshake_sync_pulse253;
  logic dst_valid_handshake_sync_pulse253;

  logic src_valid_handshake_sync_pulse254;
  logic dst_valid_handshake_sync_pulse254;

  logic src_valid_handshake_sync_pulse255;
  logic dst_valid_handshake_sync_pulse255;

  logic src_valid_handshake_sync_pulse256;
  logic dst_valid_handshake_sync_pulse256;

  logic src_valid_handshake_sync_pulse257;
  logic dst_valid_handshake_sync_pulse257;

  logic src_valid_handshake_sync_pulse258;
  logic dst_valid_handshake_sync_pulse258;

  logic src_valid_handshake_sync_pulse259;
  logic dst_valid_handshake_sync_pulse259;

  logic src_valid_handshake_sync_pulse260;
  logic dst_valid_handshake_sync_pulse260;

  logic src_valid_handshake_sync_pulse261;
  logic dst_valid_handshake_sync_pulse261;

  logic src_valid_handshake_sync_pulse262;
  logic dst_valid_handshake_sync_pulse262;

  logic src_valid_handshake_sync_pulse263;
  logic dst_valid_handshake_sync_pulse263;

  logic src_valid_handshake_sync_pulse264;
  logic dst_valid_handshake_sync_pulse264;

  logic src_valid_handshake_sync_pulse265;
  logic dst_valid_handshake_sync_pulse265;

  logic src_valid_handshake_sync_pulse266;
  logic dst_valid_handshake_sync_pulse266;

  logic src_valid_handshake_sync_pulse267;
  logic dst_valid_handshake_sync_pulse267;

  logic src_valid_handshake_sync_pulse268;
  logic dst_valid_handshake_sync_pulse268;

  logic src_valid_handshake_sync_pulse269;
  logic dst_valid_handshake_sync_pulse269;

  logic src_valid_handshake_sync_pulse270;
  logic dst_valid_handshake_sync_pulse270;

  logic src_valid_handshake_sync_pulse271;
  logic dst_valid_handshake_sync_pulse271;

  logic src_valid_handshake_sync_pulse272;
  logic dst_valid_handshake_sync_pulse272;

  logic src_valid_handshake_sync_pulse273;
  logic dst_valid_handshake_sync_pulse273;

  logic src_valid_handshake_sync_pulse274;
  logic dst_valid_handshake_sync_pulse274;

  logic src_valid_handshake_sync_pulse275;
  logic dst_valid_handshake_sync_pulse275;

  logic src_valid_handshake_sync_pulse276;
  logic dst_valid_handshake_sync_pulse276;

  logic src_valid_handshake_sync_pulse277;
  logic dst_valid_handshake_sync_pulse277;

  logic src_valid_handshake_sync_pulse278;
  logic dst_valid_handshake_sync_pulse278;

  logic src_valid_handshake_sync_pulse279;
  logic dst_valid_handshake_sync_pulse279;

  logic src_valid_handshake_sync_pulse280;
  logic dst_valid_handshake_sync_pulse280;

  logic src_valid_handshake_sync_pulse281;
  logic dst_valid_handshake_sync_pulse281;

  logic src_valid_handshake_sync_pulse282;
  logic dst_valid_handshake_sync_pulse282;

  logic src_valid_handshake_sync_pulse283;
  logic dst_valid_handshake_sync_pulse283;

  logic src_valid_handshake_sync_pulse284;
  logic dst_valid_handshake_sync_pulse284;

  logic src_valid_handshake_sync_pulse285;
  logic dst_valid_handshake_sync_pulse285;

  logic src_valid_handshake_sync_pulse286;
  logic dst_valid_handshake_sync_pulse286;

  logic src_valid_handshake_sync_pulse287;
  logic dst_valid_handshake_sync_pulse287;

  logic src_valid_handshake_sync_pulse288;
  logic dst_valid_handshake_sync_pulse288;

  logic src_valid_handshake_sync_pulse289;
  logic dst_valid_handshake_sync_pulse289;

  logic src_valid_handshake_sync_pulse290;
  logic dst_valid_handshake_sync_pulse290;

  logic src_valid_handshake_sync_pulse291;
  logic dst_valid_handshake_sync_pulse291;

  logic src_valid_handshake_sync_pulse292;
  logic dst_valid_handshake_sync_pulse292;

  logic src_valid_handshake_sync_pulse293;
  logic dst_valid_handshake_sync_pulse293;

  logic src_valid_handshake_sync_pulse294;
  logic dst_valid_handshake_sync_pulse294;

  logic src_valid_handshake_sync_pulse295;
  logic dst_valid_handshake_sync_pulse295;

  logic src_valid_handshake_sync_pulse296;
  logic dst_valid_handshake_sync_pulse296;

  logic src_valid_handshake_sync_pulse297;
  logic dst_valid_handshake_sync_pulse297;

  logic src_valid_handshake_sync_pulse298;
  logic dst_valid_handshake_sync_pulse298;

  logic src_valid_handshake_sync_pulse299;
  logic dst_valid_handshake_sync_pulse299;

  logic src_valid_handshake_sync_pulse300;
  logic dst_valid_handshake_sync_pulse300;

  logic src_valid_handshake_sync_pulse301;
  logic dst_valid_handshake_sync_pulse301;

  logic src_valid_handshake_sync_pulse302;
  logic dst_valid_handshake_sync_pulse302;

  logic src_valid_handshake_sync_pulse303;
  logic dst_valid_handshake_sync_pulse303;

  logic src_valid_handshake_sync_pulse304;
  logic dst_valid_handshake_sync_pulse304;

  logic src_valid_handshake_sync_pulse305;
  logic dst_valid_handshake_sync_pulse305;

  logic src_valid_handshake_sync_pulse306;
  logic dst_valid_handshake_sync_pulse306;

  logic src_valid_handshake_sync_pulse307;
  logic dst_valid_handshake_sync_pulse307;

  logic src_valid_handshake_sync_pulse308;
  logic dst_valid_handshake_sync_pulse308;

  logic src_valid_handshake_sync_pulse309;
  logic dst_valid_handshake_sync_pulse309;

  logic src_valid_handshake_sync_pulse310;
  logic dst_valid_handshake_sync_pulse310;

  logic src_valid_handshake_sync_pulse311;
  logic dst_valid_handshake_sync_pulse311;

  logic src_valid_handshake_sync_pulse312;
  logic dst_valid_handshake_sync_pulse312;

  logic src_valid_handshake_sync_pulse313;
  logic dst_valid_handshake_sync_pulse313;

  logic src_valid_handshake_sync_pulse314;
  logic dst_valid_handshake_sync_pulse314;

  logic src_valid_handshake_sync_pulse315;
  logic dst_valid_handshake_sync_pulse315;

  logic src_valid_handshake_sync_pulse316;
  logic dst_valid_handshake_sync_pulse316;

  logic src_valid_handshake_sync_pulse317;
  logic dst_valid_handshake_sync_pulse317;

  logic src_valid_handshake_sync_pulse318;
  logic dst_valid_handshake_sync_pulse318;

  logic src_valid_handshake_sync_pulse319;
  logic dst_valid_handshake_sync_pulse319;

  logic src_valid_handshake_sync_pulse320;
  logic dst_valid_handshake_sync_pulse320;

  logic src_valid_handshake_sync_pulse321;
  logic dst_valid_handshake_sync_pulse321;

  logic src_valid_handshake_sync_pulse322;
  logic dst_valid_handshake_sync_pulse322;

  logic src_valid_handshake_sync_pulse323;
  logic dst_valid_handshake_sync_pulse323;

  logic src_valid_handshake_sync_pulse324;
  logic dst_valid_handshake_sync_pulse324;

  logic src_valid_handshake_sync_pulse325;
  logic dst_valid_handshake_sync_pulse325;

  logic src_valid_handshake_sync_pulse326;
  logic dst_valid_handshake_sync_pulse326;

  logic src_valid_handshake_sync_pulse327;
  logic dst_valid_handshake_sync_pulse327;

  logic src_valid_handshake_sync_pulse328;
  logic dst_valid_handshake_sync_pulse328;

  logic src_valid_handshake_sync_pulse329;
  logic dst_valid_handshake_sync_pulse329;

  logic src_valid_handshake_sync_pulse330;
  logic dst_valid_handshake_sync_pulse330;

  logic src_valid_handshake_sync_pulse331;
  logic dst_valid_handshake_sync_pulse331;

  logic src_valid_handshake_sync_pulse332;
  logic dst_valid_handshake_sync_pulse332;

  logic src_valid_handshake_sync_pulse333;
  logic dst_valid_handshake_sync_pulse333;

  logic src_valid_handshake_sync_pulse334;
  logic dst_valid_handshake_sync_pulse334;

  logic src_valid_handshake_sync_pulse335;
  logic dst_valid_handshake_sync_pulse335;

  logic src_valid_handshake_sync_pulse336;
  logic dst_valid_handshake_sync_pulse336;

  logic src_valid_handshake_sync_pulse337;
  logic dst_valid_handshake_sync_pulse337;

  logic src_valid_handshake_sync_pulse338;
  logic dst_valid_handshake_sync_pulse338;

  logic src_valid_handshake_sync_pulse339;
  logic dst_valid_handshake_sync_pulse339;

  logic src_valid_handshake_sync_pulse340;
  logic dst_valid_handshake_sync_pulse340;

  logic src_valid_handshake_sync_pulse341;
  logic dst_valid_handshake_sync_pulse341;

  logic src_valid_handshake_sync_pulse342
