```verilog
module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] wptr_a, wptr_b, rptr_a, rptr_b;
  reg [ASIZE-1:0] wptr_a_gray, wptr_b_gray, rptr_a_gray, rptr_b_gray;
  reg [ASIZE-1:0] wptr_a_bin, wptr_b_bin, rptr_a_bin, rptr_b_bin;
  reg [ASIZE-1:0] wptr_a_sync, wptr_b_sync, rptr_a_sync, rptr_b_sync;
  reg [ASIZE-1:0] wptr_a_sync2, wptr_b_sync2, rptr_a_sync2, rptr_b_sync2;
  reg [ASIZE-1:0] wptr_a_sync3, wptr_b_sync3, rptr_a_sync3, rptr_b_sync3;
  reg [ASIZE-1:0] wptr_a_sync4, wptr_b_sync4, rptr_a_sync4, rptr_b_sync4;
  reg [ASIZE-1:0] wptr_a_sync5, wptr_b_sync5, rptr_a_sync5, rptr_b_sync5;
  reg [ASIZE-1:0] wptr_a_sync6, wptr_b_sync6, rptr_a_sync6, rptr_b_sync6;
  reg [ASIZE-1:0] wptr_a_sync7, wptr_b_sync7, rptr_a_sync7, rptr_b_sync7;
  reg [ASIZE-1:0] wptr_a_sync8, wptr_b_sync8, rptr_a_sync8, rptr_b_sync8;
  reg [ASIZE-1:0] wptr_a_sync9, wptr_b_sync9, rptr_a_sync9, rptr_b_sync9;
  reg [ASIZE-1:0] wptr_a_sync10, wptr_b_sync10, rptr_a_sync10, rptr_b_sync10;
  reg [ASIZE-1:0] wptr_a_sync11, wptr_b_sync11, rptr_a_sync11, rptr_b_sync11;
  reg [ASIZE-1:0] wptr_a_sync12, wptr_b_sync12, rptr_a_sync12, rptr_b_sync12;
  reg [ASIZE-1:0] wptr_a_sync13, wptr_b_sync13, rptr_a_sync13, rptr_b_sync13;
  reg [ASIZE-1:0] wptr_a_sync14, wptr_b_sync14, rptr_a_sync14, rptr_b_sync14;
  reg [ASIZE-1:0] wptr_a_sync15, wptr_b_sync15, rptr_a_sync15, rptr_b_sync15;
  reg [ASIZE-1:0] wptr_a_sync16, wptr_b_sync16, rptr_a_sync16, rptr_b_sync16;
  reg [ASIZE-1:0] wptr_a_sync17, wptr_b_sync17, rptr_a_sync17, rptr_b_sync17;
  reg [ASIZE-1:0] wptr_a_sync18, wptr_b_sync18, rptr_a_sync18, rptr_b_sync18;
  reg [ASIZE-1:0] wptr_a_sync19, wptr_b_sync19, rptr_a_sync19, rptr_b_sync19;
  reg [ASIZE-1:0] wptr_a_sync20, wptr_b_sync20, rptr_a_sync20, rptr_b_sync20;
  reg [ASIZE-1:0] wptr_a_sync21, wptr_b_sync21, rptr_a_sync21, rptr_b_sync21;
  reg [ASIZE-1:0] wptr_a_sync22, wptr_b_sync22, rptr_a_sync22, rptr_b_sync22;
  reg [ASIZE-1:0] wptr_a_sync23, wptr_b_sync23, rptr_a_sync23, rptr_b_sync23;
  reg [ASIZE-1:0] wptr_a_sync24, wptr_b_sync24, rptr_a_sync24, rptr_b_sync24;
  reg [ASIZE-1:0] wptr_a_sync25, wptr_b_sync25, rptr_a_sync25, rptr_b_sync25;
  reg [ASIZE-1:0] wptr_a_sync26, wptr_b_sync26, rptr_a_sync26, rptr_b_sync26;
  reg [ASIZE-1:0] wptr_a_sync27, wptr_b_sync27, rptr_a_sync27, rptr_b_sync27;
  reg [ASIZE-1:0] wptr_a_sync28, wptr_b_sync28, rptr_a_sync28, rptr_b_sync28;
  reg [ASIZE-1:0] wptr_a_sync29, wptr_b_sync29, rptr_a_sync29, rptr_b_sync29;
  reg [ASIZE-1:0] wptr_a_sync30, wptr_b_sync30, rptr_a_sync30, rptr_b_sync30;
  reg [ASIZE-1:0] wptr_a_sync31, wptr_b_sync31, rptr_a_sync31, rptr_b_sync31;
  reg [ASIZE-1:0] wptr_a_sync32, wptr_b_sync32, rptr_a_sync32, rptr_b_sync32;
  reg [ASIZE-1:0] wptr_a_sync33, wptr_b_sync33, rptr_a_sync33, rptr_b_sync33;
  reg [ASIZE-1:0] wptr_a_sync34, wptr_b_sync34, rptr_a_sync34, rptr_b_sync34;
  reg [ASIZE-1:0] wptr_a_sync35, wptr_b_sync35, rptr_a_sync35, rptr_b_sync35;
  reg [ASIZE-1:0] wptr_a_sync36, wptr_b_sync36, rptr_a_sync36, rptr_b_sync36;
  reg [ASIZE-1:0] wptr_a_sync37, wptr_b_sync37, rptr_a_sync37, rptr_b_sync37;
  reg [ASIZE-1:0] wptr_a_sync38, wptr_b_sync38, rptr_a_sync38, rptr_b_sync38;
  reg [ASIZE-1:0] wptr_a_sync39, wptr_b_sync39, rptr_a_sync39, rptr_b_sync39;
  reg [ASIZE-1:0] wptr_a_sync40, wptr_b_sync40, rptr_a_sync40, rptr_b_sync40;
  reg [ASIZE-1:0] wptr_a_sync41, wptr_b_sync41, rptr_a_sync41, rptr_b_sync41;
  reg [ASIZE-1:0] wptr_a_sync42, wptr_b_sync42, rptr_a_sync42, rptr_b_sync42;
  reg [ASIZE-1:0] wptr_a_sync43, wptr_b_sync43, rptr_a_sync43, rptr_b_sync43;
  reg [ASIZE-1:0] wptr_a_sync44, wptr_b_sync44, rptr_a_sync44, rptr_b_sync44;
  reg [ASIZE-1:0] wptr_a_sync45, wptr_b_sync45, rptr_a_sync45, rptr_b_sync45;
  reg [ASIZE-1:0] wptr_a_sync46, wptr_b_sync46, rptr_a_sync46, rptr_b_sync46;
  reg [ASIZE-1:0] wptr_a_sync47, wptr_b_sync47, rptr_a_sync47, rptr_b_sync47;
  reg [ASIZE-1:0] wptr_a_sync48, wptr_b_sync48, rptr_a_sync48, rptr_b_sync48;
  reg [ASIZE-1:0] wptr_a_sync49, wptr_b_sync49, rptr_a_sync49, rptr_b_sync49;
  reg [ASIZE-1:0] wptr_a_sync50, wptr_b_sync50, rptr_a_sync50, rptr_b_sync50;
  reg [ASIZE-1:0] wptr_a_sync51, wptr_b_sync51, rptr_a_sync51, rptr_b_sync51;
  reg [ASIZE-1:0] wptr_a_sync52, wptr_b_sync52, rptr_a_sync52, rptr_b_sync52;
  reg [ASIZE-1:0] wptr_a_sync53, wptr_b_sync53, rptr_a_sync53, rptr_b_sync53;
  reg [ASIZE-1:0] wptr_a_sync54, wptr_b_sync54, rptr_a_sync54, rptr_b_sync54;
  reg [ASIZE-1:0] wptr_a_sync55, wptr_b_sync55, rptr_a_sync55, rptr_b_sync55;
  reg [ASIZE-1:0] wptr_a_sync56, wptr_b_sync56, rptr_a_sync56, rptr_b_sync56;
  reg [ASIZE-1:0] wptr_a_sync57, wptr_b_sync57, rptr_a_sync57, rptr_b_sync57;
  reg [ASIZE-1:0] wptr_a_sync58, wptr_b_sync58, rptr_a_sync58, rptr_b_sync58;
  reg [ASIZE-1:0] wptr_a_sync59, wptr_b_sync59, rptr_a_sync59, rptr_b_sync59;
  reg [ASIZE-1:0] wptr_a_sync60, wptr_b_sync60, rptr_a_sync60, rptr_b_sync60;
  reg [ASIZE-1:0] wptr_a_sync61, wptr_b_sync61, rptr_a_sync61, rptr_b_sync61;
  reg [ASIZE-1:0] wptr_a_sync62, wptr_b_sync62, rptr_a_sync62, rptr_b_sync62;
  reg [ASIZE-1:0] wptr_a_sync63, wptr_b_sync63, rptr_a_sync63, rptr_b_sync63;
  reg [ASIZE-1:0] wptr_a_sync64, wptr_b_sync64, rptr_a_sync64, rptr_b_sync64;
  reg [ASIZE-1:0] wptr_a_sync65, wptr_b_sync65, rptr_a_sync65, rptr_b_sync65;
  reg [ASIZE-1:0] wptr_a_sync66, wptr_b_sync66, rptr_a_sync66, rptr_b_sync66;
  reg [ASIZE-1:0] wptr_a_sync67, wptr_b_sync67, rptr_a_sync67, rptr_b_sync67;
  reg [ASIZE-1:0] wptr_a_sync68, wptr_b_sync68, rptr_a_sync68, rptr_b_sync68;
  reg [ASIZE-1:0] wptr_a_sync69, wptr_b_sync69, rptr_a_sync69, rptr_b_sync69;
  reg [ASIZE-1:0] wptr_a_sync70, wptr_b_sync70, rptr_a_sync70, rptr_b_sync70;
  reg [ASIZE-1:0] wptr_a_sync71, wptr_b_sync71, rptr_a_sync71, rptr_b_sync71;
  reg [ASIZE-1:0] wptr_a_sync72, wptr_b_sync72, rptr_a_sync72, rptr_b_sync72;
  reg [ASIZE-1:0] wptr_a_sync73, wptr_b_sync73, rptr_a_sync73, rptr_b_sync73;
  reg [ASIZE-1:0] wptr_a_sync74, wptr_b_sync74, rptr_a_sync74, rptr_b_sync74;
  reg [ASIZE-1:0] wptr_a_sync75, wptr_b_sync75, rptr_a_sync75, rptr_b_sync75;
  reg [ASIZE-1:0] wptr_a_sync76, wptr_b_sync76, rptr_a_sync76, rptr_b_sync76;
  reg [ASIZE-1:0] wptr_a_sync77, wptr_b_sync77, rptr_a_sync77, rptr_b_sync77;
  reg [ASIZE-1:0] wptr_a_sync78, wptr_b_sync78, rptr_a_sync78, rptr_b_sync78;
  reg [ASIZE-1:0] wptr_a_sync79, wptr_b_sync79, rptr_a_sync79, rptr_b_sync79;
  reg [ASIZE-1:0] wptr_a_sync80, wptr_b_sync80, rptr_a_sync80, rptr_b_sync80;
  reg [ASIZE-1:0] wptr_a_sync81, wptr_b_sync81, rptr_a_sync81, rptr_b_sync81;
  reg [ASIZE-1:0] wptr_a_sync82, wptr_b_sync82, rptr_a_sync82, rptr_b_sync82;
  reg [ASIZE-1:0] wptr_a_sync83, wptr_b_sync83, rptr_a_sync83, rptr_b_sync83;
  reg [ASIZE-1:0] wptr_a_sync84, wptr_b_sync84, rptr_a_sync84, rptr_b_sync84;
  reg [ASIZE-1:0] wptr_a_sync85, wptr_b_sync85, rptr_a_sync85, rptr_b_sync85;
  reg [ASIZE-1:0] wptr_a_sync86, wptr_b_sync86, rptr_a_sync86, rptr_b_sync86;
  reg [ASIZE-1:0] wptr_a_sync87, wptr_b_sync87, rptr_a_sync87, rptr_b_sync87;
  reg [ASIZE-1:0] wptr_a_sync88, wptr_b_sync88, rptr_a_sync88, rptr_b_sync88;
  reg [ASIZE-1:0] wptr_a_sync89, wptr_b_sync89, rptr_a_sync89, rptr_b_sync89;
  reg [ASIZE-1:0] wptr_a_sync90, wptr_b_sync90, rptr_a_sync90, rptr_b_sync90;
  reg [ASIZE-1:0] wptr_a_sync91, wptr_b_sync91, rptr_a_sync91, rptr_b_sync91;
  reg [ASIZE-1:0] wptr_a_sync92, wptr_b_sync92, rptr_a_sync92, rptr_b_sync92;
  reg [ASIZE-1:0] wptr_a_sync93, wptr_b_sync93, rptr_a_sync93, rptr_b_sync93;
  reg [ASIZE-1:0] wptr_a_sync94, wptr_b_sync94, rptr_a_sync94, rptr_b_sync94;
  reg [ASIZE-1:0] wptr_a_sync95, wptr_b_sync95, rptr_a_sync95, rptr_b_sync95;
  reg [ASIZE-1:0] wptr_a_sync96, wptr_b_sync96, rptr_a_sync96, rptr_b_sync96;
  reg [ASIZE-1:0] wptr_a_sync97, wptr_b_sync97, rptr_a_sync97, rptr_b_sync97;
  reg [ASIZE-1:0] wptr_a_sync98, wptr_b_sync98, rptr_a_sync98, rptr_b_sync98;
  reg [ASIZE-1:0] wptr_a_sync99, wptr_b_sync99, rptr_a_sync99, rptr_b_sync99;
  reg [ASIZE-1:0] wptr_a_sync100, wptr_b_sync100, rptr_a_sync100, rptr_b_sync100;
  reg [ASIZE-1:0] wptr_a_sync101, wptr_b_sync101, rptr_a_sync101, rptr_b_sync101;
  reg [ASIZE-1:0] wptr_a_sync102, wptr_b_sync102, rptr_a_sync102, rptr_b_sync102;
  reg [ASIZE-1:0] wptr_a_sync103, wptr_b_sync103, rptr_a_sync103, rptr_b_sync103;
  reg [ASIZE-1:0] wptr_a_sync104, wptr_b_sync104, rptr_a_sync104, rptr_b_sync104;
  reg [ASIZE-1:0] wptr_a_sync105, wptr_b_sync105, rptr_a_sync105, rptr_b_sync105;
  reg [ASIZE-1:0] wptr_a_sync106, wptr_b_sync106, rptr_a_sync106, rptr_b_sync106;
  reg [ASIZE-1:0] wptr_a_sync107, wptr_b_sync107, rptr_a_sync107, rptr_b_sync107;
  reg [ASIZE-1:0] wptr_a_sync108, wptr_b_sync108, rptr_a_sync108, rptr_b_sync108;
  reg [ASIZE-1:0] wptr_a_sync109, wptr_b_sync109, rptr_a_sync109, rptr_b_sync109;
  reg [ASIZE-1:0] wptr_a_sync110, wptr_b_sync110, rptr_a_sync110, rptr_b_sync110;
  reg [ASIZE-1:0] wptr_a_sync111, wptr_b_sync111, rptr_a_sync111, rptr_b_sync111;
  reg [ASIZE-1:0] wptr_a_sync112, wptr_b_sync112, rptr_a_sync112, rptr_b_sync112;
  reg [ASIZE-1:0] wptr_a_sync113, wptr_b_sync113, rptr_a_sync113, rptr_b_sync113;
  reg [ASIZE-1:0] wptr_a_sync114, wptr_b_sync114, rptr_a_sync114, rptr_b_sync114;
  reg [ASIZE-1:0] wptr_a_sync115, wptr_b_sync115, rptr_a_sync115, rptr_b_sync115;
  reg [ASIZE-1:0] wptr_a_sync116, wptr_b_sync116, rptr_a_sync116, rptr_b_sync116;
  reg [ASIZE-1:0] wptr_a_sync117, wptr_b_sync117, rptr_a_sync117, rptr_b_sync117;
  reg [ASIZE-1:0] wptr_a_sync118, wptr_b_sync118, rptr_a_sync118, rptr_b_sync118;
  reg [ASIZE-1:0] wptr_a_sync119, wptr_b_sync119, rptr_a_sync119, rptr_b_sync119;
  reg [ASIZE-1:0] wptr_a_sync120, wptr_b_sync120, rptr_a_sync120, rptr_b_sync120;
  reg [ASIZE-1:0] wptr_a_sync121, wptr_b_sync121, rptr_a_sync121, rptr_b_sync121;
  reg [ASIZE-1:0] wptr_a_sync122, wptr_b_sync122, rptr_a_sync122, rptr_b_sync122;
  reg [ASIZE-1:0] wptr_a_sync123, wptr_b_sync123, rptr_a_sync123, rptr_b_sync123;
  reg [ASIZE-1:0] wptr_a_sync124, wptr_b_sync124, rptr_a_sync124, rptr_b_sync124;
  reg [ASIZE-1:0] wptr_a_sync125, wptr_b_sync125, rptr_a_sync125, rptr_b_sync125;
  reg [ASIZE-1:0] wptr_a_sync126, wptr_b_sync126, rptr_a_sync126, rptr_b_sync126;
  reg [ASIZE-1:0] wptr_a_sync127, wptr_b_sync127, rptr_a_sync127, rptr_b_sync127;
  reg [ASIZE-1:0] wptr_a_sync128, wptr_b_sync128, rptr_a_sync128, rptr_b_sync128;
  reg [ASIZE-1:0] wptr_a_sync129, wptr_b_sync129, rptr_a_sync129, rptr_b_sync129;
  reg [ASIZE-1:0] wptr_a_sync130, wptr_b_sync130, rptr_a_sync130, rptr_b_sync130;
  reg [ASIZE-1:0] wptr_a_sync131, wptr_b_sync131, rptr_a_sync131, rptr_b_sync131;
  reg [ASIZE-1:0] wptr_a_sync132, wptr_b_sync132, rptr_a_sync132, rptr_b_sync132;
  reg [ASIZE-1:0] wptr_a_sync133, wptr_b_sync133, rptr_a_sync133, rptr_b_sync133;
  reg [ASIZE-1:0] wptr_a_sync134, wptr_b_sync134, rptr_a_sync134, rptr_b_sync134;
  reg [ASIZE-1:0] wptr_a_sync135, wptr_b_sync135, rptr_a_sync135, rptr_b_sync135;
  reg [ASIZE-1:0] wptr_a_sync136, wptr_b_sync136, rptr_a_sync136, rptr_b_sync136;
  reg [ASIZE-1:0] wptr_a_sync137, wptr_b_sync137, rptr_a_sync137, rptr_b_sync137;
  reg [ASIZE-1:0] wptr_a_sync138, wptr_b_sync138, rptr_a_sync138, rptr_b_sync138;
  reg [ASIZE-1:0] wptr_a_sync139, wptr_b_sync139, rptr_a_sync139, rptr_b_sync139;
  reg [ASIZE-1:0] wptr_a_sync140, wptr_b_sync140, rptr_a_sync140, rptr_b_sync140;
  reg [ASIZE-1:0] wptr_a_sync141, wptr_b_sync141, rptr_a_sync141, rptr_b_sync141;
  reg [ASIZE-1:0] wptr_a_sync142, wptr_b_sync142, rptr_a_sync142, rptr_b_sync142;
  reg [ASIZE-1:0] wptr_a_sync143, wptr_b_sync143, rptr_a_sync143, rptr_b_sync143;
  reg [ASIZE-1:0] wptr_a_sync144, wptr_b_sync144, rptr_a_sync144, rptr_b_sync144;
  reg [ASIZE-1:0] wptr_a_sync145, wptr_b_sync145, rptr_a_sync145, rptr_b_sync145;
  reg [ASIZE-1:0] wptr_a_sync146, wptr_b_sync146, rptr_a_sync146, rptr_b_sync146;
  reg [ASIZE-1:0] wptr_a_sync147, wptr_b_sync147, rptr_a_sync147, rptr_b_sync147;
  reg [ASIZE-1:0] wptr_a_sync148, wptr_b_sync148, rptr_a_sync148, rptr_b_sync148;
  reg [ASIZE-1:0] wptr_a_sync149, wptr_b_sync149, rptr_a_sync149, rptr_b_sync149;
  reg [ASIZE-1:0] wptr_a_sync150, wptr_b_sync150, rptr_a_sync150, rptr_b_sync150;
  reg [ASIZE-1:0] wptr_a_sync151, wptr_b_sync151, rptr_a_sync151, rptr_b_sync151;
  reg [ASIZE-1:0] wptr_a_sync152, wptr_b_sync152, rptr_a_sync152, rptr_b_sync152;
  reg [ASIZE-1:0] wptr_a_sync153, wptr_b_sync153, rptr_a_sync153, rptr_b_sync153;
  reg [ASIZE-1:0] wptr_a_sync154, wptr_b_sync154, rptr_a_sync154, rptr_b_sync154;
  reg [ASIZE-1:0] wptr_a_sync155, wptr_b_sync155, rptr_a_sync155, rptr_b_sync155;
  reg [ASIZE-1:0] wptr_a_sync156, wptr_b_sync156, rptr_a_sync156, rptr_b_sync156;
  reg [ASIZE-1:0] wptr_a_sync157, wptr_b_sync157, rptr_a_sync157, rptr_b_sync157;
  reg [ASIZE-1:0] wptr_a_sync158, wptr_b_sync158, rptr_a_sync158, rptr_b_sync158;
  reg [ASIZE-1:0] wptr_a_sync159, wptr_b_sync159, rptr_a_sync159, rptr_b_sync159;
  reg [ASIZE-1:0] wptr_a_sync160, wptr_b_sync160, rptr_a_sync160, rptr_b_sync160;
  reg [ASIZE-1:0] wptr_a_sync161, wptr_b_sync161, rptr_a_sync161, rptr_b_sync161;
  reg [ASIZE-1:0] wptr_a_sync162, wptr_b_sync162, rptr_a_sync162, rptr_b_sync162;
  reg [ASIZE-1:0] wptr_a_sync163, wptr_b_sync163, rptr_a_sync163, rptr_b_sync163;
  reg [ASIZE-1:0] wptr_a_sync164, wptr_b_sync164, rptr_a_sync164, rptr_b_sync164;
  reg [ASIZE-1:0] wptr_a_sync165, wptr_b_sync165, rptr_a_sync165, rptr_b_sync165;
  reg [ASIZE-1:0] wptr_a_sync166, wptr_b_sync166, rptr_a_sync166, rptr_b_sync166;
  reg [ASIZE-1:0] wptr_a_sync167, wptr_b_sync167, rptr_a_sync167, rptr_b_sync167;
  reg [ASIZE-1:0] wptr_a_sync168, wptr_b_sync168, rptr_a_sync168, rptr_b_sync168;
  reg [ASIZE-1:0] wptr_a_sync169, wptr_b_sync169, rptr_a_sync169, rptr_b_sync169;
  reg [ASIZE-1:0] wptr_a_sync170, wptr_b_sync170, rptr_a_sync170, rptr_b_sync170;
  reg [ASIZE-1:0] wptr_a_sync171, wptr_b_sync171, rptr_a_sync171, rptr_b_sync171;
  reg [ASIZE-1:0] wptr_a_sync172, wptr_b_sync172, rptr_a_sync172, rptr_b_sync172;
  reg [ASIZE-1:0] wptr_a_sync173, wptr_b_sync173, rptr_a_sync173, rptr_b_sync173;
  reg [ASIZE-1:0] wptr_a_sync174, wptr_b_sync174, rptr_a_sync174, rptr_b_sync174;
  reg [ASIZE-1:0] wptr_a_sync175, wptr_b_sync175, rptr_a_sync175, rptr_b_sync175;
  reg [ASIZE-1:0] wptr_a_sync176, wptr_b_sync176, rptr_a_sync176, rptr_b_sync176;
  reg [ASIZE-1:0] wptr_a_sync177, wptr_b_sync177, rptr_a_sync177, rptr_b_sync177;
  reg [ASIZE-1:0] wptr_a_sync178, wptr_b_sync178, rptr_a_sync178, rptr_b_sync178;
  reg [ASIZE-1:0] wptr_a_sync179, wptr_b_sync179, rptr_a_sync179, rptr_b_sync179;
  reg [ASIZE-1:0] wptr_a_sync180, wptr_b_sync180, rptr_a_sync180, rptr_b_sync180;
  reg [ASIZE-1:0] wptr_a_sync181, wptr_b_sync181, rptr_a_sync181, rptr_b_sync181;
  reg [ASIZE-1:0] wptr_a_sync182, wptr_b_sync182, rptr_a_sync182, rptr_b_sync182;
  reg [ASIZE-1:0] wptr_a_sync183, wptr_b_sync183, rptr_a_sync183, rptr_b_sync183;
  reg [ASIZE-1:0] wptr_a_sync184, wptr_b_sync184, rptr_a_sync184, rptr_b_sync184;
  reg [ASIZE-1:0] wptr_a_sync185, wptr_b_sync185, rptr_a_sync185, rptr_b_sync185;
  reg [ASIZE-1:0] wptr_a_sync186, wptr_b_sync186, rptr_a_sync186, rptr_b_sync186;
  reg [ASIZE-1:0] wptr_a_sync187, wptr_b_sync187, rptr_a_sync187, rptr_b_sync187;
  reg [ASIZE-1:0] wptr_a_sync188, wptr_b_sync188, rptr_a_sync188, rptr_b_sync188;
  reg [ASIZE-1:0] wptr_a_sync189, wptr_b_sync189, rptr_a_sync189, rptr_b_sync189;
  reg [ASIZE-1:0] wptr_a_sync190, wptr_b_sync190, rptr_a_sync190, rptr_b_sync190;
  reg [ASIZE-1:0] wptr_a_sync191, wptr_b_sync191, rptr_a_sync191, rptr_b_sync191;
  reg [ASIZE-1:0] wptr_a_sync192, wptr_b_sync192, rptr_a_sync192, rptr_b_sync192;
  reg [ASIZE-1:0] wptr_a_sync193, wptr_b_sync193, rptr_a_sync193, rptr_b_sync193;
  reg [ASIZE-1:0] wptr_a_sync194, wptr_b_sync194, rptr_a_sync194, rptr_b_sync194;
  reg [ASIZE-1:0] wptr_a_sync195, wptr_b_sync195, rptr_a_sync195, rptr_b_sync195;
  reg [ASIZE-1:0] wptr_a_sync196, wptr_b_sync196, rptr_a_sync196, rptr_b_sync196;
  reg [ASIZE-1:0] wptr_a_sync197, wptr_b_sync197, rptr_a_sync197, rptr_b_sync197;
  reg [ASIZE-1:0] wptr_a_sync198, wptr_b_sync198, rptr_a_sync198, rptr_b_sync198;
  reg [ASIZE-1:0] wptr_a_sync199, wptr_b_sync199, rptr_a_sync199, rptr_b_sync199;
  reg [ASIZE-1:0] wptr_a_sync200, wptr_b_sync200, rptr_a_sync200, rptr_b_sync200;
  reg [ASIZE-1:0] wptr_a_sync201, wptr_b_sync201, rptr_a_sync201, rptr_b_sync201;
  reg [ASIZE-1:0] wptr_a_sync202, wptr_b_sync202, rptr_a_sync202, rptr_b_sync202;
  reg [ASIZE-1:0] wptr_a_sync203, wptr_b_sync203, rptr_a_sync203, rptr_b_sync203;
  reg [ASIZE-1:0] wptr_a_sync204, wptr_b_sync204, rptr_a_sync204, rptr_b_sync204;
  reg [ASIZE-1:0] wptr_a_sync205, wptr_b_sync205, rptr_a_sync205, rptr_b_sync205;
  reg [ASIZE-1:0] wptr_a_sync206, wptr_b_sync206, rptr_a_sync206, rptr_b_sync206;
  reg [ASIZE-1:0] wptr_a_sync207, wptr_b_sync207, rptr_a_sync207, rptr_b_sync207;
  reg [ASIZE-1:0] wptr_a_sync208, wptr_b_sync208, rptr_a_sync208, rptr_b_sync208;
  reg [ASIZE-1:0] wptr_a_sync209, wptr_b_sync209, rptr_a_sync209, rptr_b_sync209;
  reg [ASIZE-1:0] wptr_a_sync210, wptr_b_sync210, rptr_a_sync210, rptr_b_sync210;
  reg [ASIZE-1:0] wptr_a_sync211, wptr_b_sync211, rptr_a_sync211, rptr_b_sync211;
  reg [ASIZE-1:0] wptr_a_sync212, wptr_b_sync212, rptr_a_sync212, rptr_b_sync212;
  reg [ASIZE-1:0] wptr_a_sync213, wptr_b_sync213, rptr_a_sync213, rptr_b_sync213;
  reg [ASIZE-1:0] wptr_a_sync214, wptr_b_sync214, rptr_a_sync214, rptr_b_sync214;
  reg [ASIZE-1:0] wptr_a_sync215, wptr_b_sync215, rptr_a_sync215, rptr_b_sync215;
  reg [ASIZE-1:0] wptr_a_sync216, wptr_b_sync216, rptr_a_sync216, rptr_b_sync216;
  reg [ASIZE-1:0] wptr_a_sync217, wptr_b_sync217, rptr_a_sync217, rptr_b_sync217;
  reg [ASIZE-1:0] wptr_a_sync218, wptr_b_sync218, rptr_a_sync218, rptr_b_sync218;
  reg [ASIZE-1:0] wptr_a_sync219, wptr_b_sync219, rptr_a_sync219, rptr_b_sync219;
  reg [ASIZE-1:0] wptr_a_sync220, wptr_b_sync220, rptr_a_sync220, rptr_b_sync220;
  reg [ASIZE-1:0] wptr_a_sync221, wptr_b_sync221, rptr_a_sync221, rptr_b_sync221;
  reg [ASIZE-1:0] wptr_a_sync222, wptr_b_sync222, rptr_a_sync222, rptr_b_sync222;
  reg [ASIZE-1:0] wptr_a_sync223, wptr_b_sync223, rptr_a_sync223, rptr_b_sync223;
  reg [ASIZE-1:0] wptr_a_sync224, wptr_b_sync224, rptr_a_sync224, rptr_b_sync224;
  reg [ASIZE-1:0] wptr_a_sync225, wptr_b_sync225, rptr_a_sync225, rptr_b_sync225;
  reg [ASIZE-1:0] wptr_a_sync226, wptr_b_sync226, rptr_a_sync226, rptr_b_sync226;
  reg [ASIZE-1:0] wptr_a_sync227, wptr_b_sync227, rptr_a_sync227, rptr_b_sync227;
  reg [ASIZE-1:0] wptr_a_sync228, wptr_b_sync228, rptr_a_sync228, rptr_b_sync228;
  reg [ASIZE-1:0] wptr_a_sync229, wptr_b_sync229, rptr_a_sync229, rptr_b_sync229;
  reg [ASIZE-1:0] wptr_a_sync230, wptr_b_sync230, rptr_a_sync230, rptr_b_sync230;
  reg [ASIZE-1:0] wptr_a_sync231, wptr_b_sync231, r
