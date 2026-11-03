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
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr, b_wr_ptr, b_rd_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray, a_rd_ptr_gray, b_wr_ptr_gray, b_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_sync, a_rd_ptr_sync, b_wr_ptr_sync, b_rd_ptr_sync;
  reg [ASIZE-1:0] a_wr_ptr_sync2, a_rd_ptr_sync2, b_wr_ptr_sync2, b_rd_ptr_sync2;
  reg [ASIZE-1:0] a_wr_ptr_sync3, a_rd_ptr_sync3, b_wr_ptr_sync3, b_rd_ptr_sync3;
  reg [ASIZE-1:0] a_wr_ptr_sync4, a_rd_ptr_sync4, b_wr_ptr_sync4, b_rd_ptr_sync4;
  reg [ASIZE-1:0] a_wr_ptr_sync5, a_rd_ptr_sync5, b_wr_ptr_sync5, b_rd_ptr_sync5;
  reg [ASIZE-1:0] a_wr_ptr_sync6, a_rd_ptr_sync6, b_wr_ptr_sync6, b_rd_ptr_sync6;
  reg [ASIZE-1:0] a_wr_ptr_sync7, a_rd_ptr_sync7, b_wr_ptr_sync7, b_rd_ptr_sync7;
  reg [ASIZE-1:0] a_wr_ptr_sync8, a_rd_ptr_sync8, b_wr_ptr_sync8, b_rd_ptr_sync8;
  reg [ASIZE-1:0] a_wr_ptr_sync9, a_rd_ptr_sync9, b_wr_ptr_sync9, b_rd_ptr_sync9;
  reg [ASIZE-1:0] a_wr_ptr_sync10, a_rd_ptr_sync10, b_wr_ptr_sync10, b_rd_ptr_sync10;
  reg [ASIZE-1:0] a_wr_ptr_sync11, a_rd_ptr_sync11, b_wr_ptr_sync11, b_rd_ptr_sync11;
  reg [ASIZE-1:0] a_wr_ptr_sync12, a_rd_ptr_sync12, b_wr_ptr_sync12, b_rd_ptr_sync12;
  reg [ASIZE-1:0] a_wr_ptr_sync13, a_rd_ptr_sync13, b_wr_ptr_sync13, b_rd_ptr_sync13;
  reg [ASIZE-1:0] a_wr_ptr_sync14, a_rd_ptr_sync14, b_wr_ptr_sync14, b_rd_ptr_sync14;
  reg [ASIZE-1:0] a_wr_ptr_sync15, a_rd_ptr_sync15, b_wr_ptr_sync15, b_rd_ptr_sync15;
  reg [ASIZE-1:0] a_wr_ptr_sync16, a_rd_ptr_sync16, b_wr_ptr_sync16, b_rd_ptr_sync16;
  reg [ASIZE-1:0] a_wr_ptr_sync17, a_rd_ptr_sync17, b_wr_ptr_sync17, b_rd_ptr_sync17;
  reg [ASIZE-1:0] a_wr_ptr_sync18, a_rd_ptr_sync18, b_wr_ptr_sync18, b_rd_ptr_sync18;
  reg [ASIZE-1:0] a_wr_ptr_sync19, a_rd_ptr_sync19, b_wr_ptr_sync19, b_rd_ptr_sync19;
  reg [ASIZE-1:0] a_wr_ptr_sync20, a_rd_ptr_sync20, b_wr_ptr_sync20, b_rd_ptr_sync20;
  reg [ASIZE-1:0] a_wr_ptr_sync21, a_rd_ptr_sync21, b_wr_ptr_sync21, b_rd_ptr_sync21;
  reg [ASIZE-1:0] a_wr_ptr_sync22, a_rd_ptr_sync22, b_wr_ptr_sync22, b_rd_ptr_sync22;
  reg [ASIZE-1:0] a_wr_ptr_sync23, a_rd_ptr_sync23, b_wr_ptr_sync23, b_rd_ptr_sync23;
  reg [ASIZE-1:0] a_wr_ptr_sync24, a_rd_ptr_sync24, b_wr_ptr_sync24, b_rd_ptr_sync24;
  reg [ASIZE-1:0] a_wr_ptr_sync25, a_rd_ptr_sync25, b_wr_ptr_sync25, b_rd_ptr_sync25;
  reg [ASIZE-1:0] a_wr_ptr_sync26, a_rd_ptr_sync26, b_wr_ptr_sync26, b_rd_ptr_sync26;
  reg [ASIZE-1:0] a_wr_ptr_sync27, a_rd_ptr_sync27, b_wr_ptr_sync27, b_rd_ptr_sync27;
  reg [ASIZE-1:0] a_wr_ptr_sync28, a_rd_ptr_sync28, b_wr_ptr_sync28, b_rd_ptr_sync28;
  reg [ASIZE-1:0] a_wr_ptr_sync29, a_rd_ptr_sync29, b_wr_ptr_sync29, b_rd_ptr_sync29;
  reg [ASIZE-1:0] a_wr_ptr_sync30, a_rd_ptr_sync30, b_wr_ptr_sync30, b_rd_ptr_sync30;
  reg [ASIZE-1:0] a_wr_ptr_sync31, a_rd_ptr_sync31, b_wr_ptr_sync31, b_rd_ptr_sync31;
  reg [ASIZE-1:0] a_wr_ptr_sync32, a_rd_ptr_sync32, b_wr_ptr_sync32, b_rd_ptr_sync32;
  reg [ASIZE-1:0] a_wr_ptr_sync33, a_rd_ptr_sync33, b_wr_ptr_sync33, b_rd_ptr_sync33;
  reg [ASIZE-1:0] a_wr_ptr_sync34, a_rd_ptr_sync34, b_wr_ptr_sync34, b_rd_ptr_sync34;
  reg [ASIZE-1:0] a_wr_ptr_sync35, a_rd_ptr_sync35, b_wr_ptr_sync35, b_rd_ptr_sync35;
  reg [ASIZE-1:0] a_wr_ptr_sync36, a_rd_ptr_sync36, b_wr_ptr_sync36, b_rd_ptr_sync36;
  reg [ASIZE-1:0] a_wr_ptr_sync37, a_rd_ptr_sync37, b_wr_ptr_sync37, b_rd_ptr_sync37;
  reg [ASIZE-1:0] a_wr_ptr_sync38, a_rd_ptr_sync38, b_wr_ptr_sync38, b_rd_ptr_sync38;
  reg [ASIZE-1:0] a_wr_ptr_sync39, a_rd_ptr_sync39, b_wr_ptr_sync39, b_rd_ptr_sync39;
  reg [ASIZE-1:0] a_wr_ptr_sync40, a_rd_ptr_sync40, b_wr_ptr_sync40, b_rd_ptr_sync40;
  reg [ASIZE-1:0] a_wr_ptr_sync41, a_rd_ptr_sync41, b_wr_ptr_sync41, b_rd_ptr_sync41;
  reg [ASIZE-1:0] a_wr_ptr_sync42, a_rd_ptr_sync42, b_wr_ptr_sync42, b_rd_ptr_sync42;
  reg [ASIZE-1:0] a_wr_ptr_sync43, a_rd_ptr_sync43, b_wr_ptr_sync43, b_rd_ptr_sync43;
  reg [ASIZE-1:0] a_wr_ptr_sync44, a_rd_ptr_sync44, b_wr_ptr_sync44, b_rd_ptr_sync44;
  reg [ASIZE-1:0] a_wr_ptr_sync45, a_rd_ptr_sync45, b_wr_ptr_sync45, b_rd_ptr_sync45;
  reg [ASIZE-1:0] a_wr_ptr_sync46, a_rd_ptr_sync46, b_wr_ptr_sync46, b_rd_ptr_sync46;
  reg [ASIZE-1:0] a_wr_ptr_sync47, a_rd_ptr_sync47, b_wr_ptr_sync47, b_rd_ptr_sync47;
  reg [ASIZE-1:0] a_wr_ptr_sync48, a_rd_ptr_sync48, b_wr_ptr_sync48, b_rd_ptr_sync48;
  reg [ASIZE-1:0] a_wr_ptr_sync49, a_rd_ptr_sync49, b_wr_ptr_sync49, b_rd_ptr_sync49;
  reg [ASIZE-1:0] a_wr_ptr_sync50, a_rd_ptr_sync50, b_wr_ptr_sync50, b_rd_ptr_sync50;
  reg [ASIZE-1:0] a_wr_ptr_sync51, a_rd_ptr_sync51, b_wr_ptr_sync51, b_rd_ptr_sync51;
  reg [ASIZE-1:0] a_wr_ptr_sync52, a_rd_ptr_sync52, b_wr_ptr_sync52, b_rd_ptr_sync52;
  reg [ASIZE-1:0] a_wr_ptr_sync53, a_rd_ptr_sync53, b_wr_ptr_sync53, b_rd_ptr_sync53;
  reg [ASIZE-1:0] a_wr_ptr_sync54, a_rd_ptr_sync54, b_wr_ptr_sync54, b_rd_ptr_sync54;
  reg [ASIZE-1:0] a_wr_ptr_sync55, a_rd_ptr_sync55, b_wr_ptr_sync55, b_rd_ptr_sync55;
  reg [ASIZE-1:0] a_wr_ptr_sync56, a_rd_ptr_sync56, b_wr_ptr_sync56, b_rd_ptr_sync56;
  reg [ASIZE-1:0] a_wr_ptr_sync57, a_rd_ptr_sync57, b_wr_ptr_sync57, b_rd_ptr_sync57;
  reg [ASIZE-1:0] a_wr_ptr_sync58, a_rd_ptr_sync58, b_wr_ptr_sync58, b_rd_ptr_sync58;
  reg [ASIZE-1:0] a_wr_ptr_sync59, a_rd_ptr_sync59, b_wr_ptr_sync59, b_rd_ptr_sync59;
  reg [ASIZE-1:0] a_wr_ptr_sync60, a_rd_ptr_sync60, b_wr_ptr_sync60, b_rd_ptr_sync60;
  reg [ASIZE-1:0] a_wr_ptr_sync61, a_rd_ptr_sync61, b_wr_ptr_sync61, b_rd_ptr_sync61;
  reg [ASIZE-1:0] a_wr_ptr_sync62, a_rd_ptr_sync62, b_wr_ptr_sync62, b_rd_ptr_sync62;
  reg [ASIZE-1:0] a_wr_ptr_sync63, a_rd_ptr_sync63, b_wr_ptr_sync63, b_rd_ptr_sync63;
  reg [ASIZE-1:0] a_wr_ptr_sync64, a_rd_ptr_sync64, b_wr_ptr_sync64, b_rd_ptr_sync64;
  reg [ASIZE-1:0] a_wr_ptr_sync65, a_rd_ptr_sync65, b_wr_ptr_sync65, b_rd_ptr_sync65;
  reg [ASIZE-1:0] a_wr_ptr_sync66, a_rd_ptr_sync66, b_wr_ptr_sync66, b_rd_ptr_sync66;
  reg [ASIZE-1:0] a_wr_ptr_sync67, a_rd_ptr_sync67, b_wr_ptr_sync67, b_rd_ptr_sync67;
  reg [ASIZE-1:0] a_wr_ptr_sync68, a_rd_ptr_sync68, b_wr_ptr_sync68, b_rd_ptr_sync68;
  reg [ASIZE-1:0] a_wr_ptr_sync69, a_rd_ptr_sync69, b_wr_ptr_sync69, b_rd_ptr_sync69;
  reg [ASIZE-1:0] a_wr_ptr_sync70, a_rd_ptr_sync70, b_wr_ptr_sync70, b_rd_ptr_sync70;
  reg [ASIZE-1:0] a_wr_ptr_sync71, a_rd_ptr_sync71, b_wr_ptr_sync71, b_rd_ptr_sync71;
  reg [ASIZE-1:0] a_wr_ptr_sync72, a_rd_ptr_sync72, b_wr_ptr_sync72, b_rd_ptr_sync72;
  reg [ASIZE-1:0] a_wr_ptr_sync73, a_rd_ptr_sync73, b_wr_ptr_sync73, b_rd_ptr_sync73;
  reg [ASIZE-1:0] a_wr_ptr_sync74, a_rd_ptr_sync74, b_wr_ptr_sync74, b_rd_ptr_sync74;
  reg [ASIZE-1:0] a_wr_ptr_sync75, a_rd_ptr_sync75, b_wr_ptr_sync75, b_rd_ptr_sync75;
  reg [ASIZE-1:0] a_wr_ptr_sync76, a_rd_ptr_sync76, b_wr_ptr_sync76, b_rd_ptr_sync76;
  reg [ASIZE-1:0] a_wr_ptr_sync77, a_rd_ptr_sync77, b_wr_ptr_sync77, b_rd_ptr_sync77;
  reg [ASIZE-1:0] a_wr_ptr_sync78, a_rd_ptr_sync78, b_wr_ptr_sync78, b_rd_ptr_sync78;
  reg [ASIZE-1:0] a_wr_ptr_sync79, a_rd_ptr_sync79, b_wr_ptr_sync79, b_rd_ptr_sync79;
  reg [ASIZE-1:0] a_wr_ptr_sync80, a_rd_ptr_sync80, b_wr_ptr_sync80, b_rd_ptr_sync80;
  reg [ASIZE-1:0] a_wr_ptr_sync81, a_rd_ptr_sync81, b_wr_ptr_sync81, b_rd_ptr_sync81;
  reg [ASIZE-1:0] a_wr_ptr_sync82, a_rd_ptr_sync82, b_wr_ptr_sync82, b_rd_ptr_sync82;
  reg [ASIZE-1:0] a_wr_ptr_sync83, a_rd_ptr_sync83, b_wr_ptr_sync83, b_rd_ptr_sync83;
  reg [ASIZE-1:0] a_wr_ptr_sync84, a_rd_ptr_sync84, b_wr_ptr_sync84, b_rd_ptr_sync84;
  reg [ASIZE-1:0] a_wr_ptr_sync85, a_rd_ptr_sync85, b_wr_ptr_sync85, b_rd_ptr_sync85;
  reg [ASIZE-1:0] a_wr_ptr_sync86, a_rd_ptr_sync86, b_wr_ptr_sync86, b_rd_ptr_sync86;
  reg [ASIZE-1:0] a_wr_ptr_sync87, a_rd_ptr_sync87, b_wr_ptr_sync87, b_rd_ptr_sync87;
  reg [ASIZE-1:0] a_wr_ptr_sync88, a_rd_ptr_sync88, b_wr_ptr_sync88, b_rd_ptr_sync88;
  reg [ASIZE-1:0] a_wr_ptr_sync89, a_rd_ptr_sync89, b_wr_ptr_sync89, b_rd_ptr_sync89;
  reg [ASIZE-1:0] a_wr_ptr_sync90, a_rd_ptr_sync90, b_wr_ptr_sync90, b_rd_ptr_sync90;
  reg [ASIZE-1:0] a_wr_ptr_sync91, a_rd_ptr_sync91, b_wr_ptr_sync91, b_rd_ptr_sync91;
  reg [ASIZE-1:0] a_wr_ptr_sync92, a_rd_ptr_sync92, b_wr_ptr_sync92, b_rd_ptr_sync92;
  reg [ASIZE-1:0] a_wr_ptr_sync93, a_rd_ptr_sync93, b_wr_ptr_sync93, b_rd_ptr_sync93;
  reg [ASIZE-1:0] a_wr_ptr_sync94, a_rd_ptr_sync94, b_wr_ptr_sync94, b_rd_ptr_sync94;
  reg [ASIZE-1:0] a_wr_ptr_sync95, a_rd_ptr_sync95, b_wr_ptr_sync95, b_rd_ptr_sync95;
  reg [ASIZE-1:0] a_wr_ptr_sync96, a_rd_ptr_sync96, b_wr_ptr_sync96, b_rd_ptr_sync96;
  reg [ASIZE-1:0] a_wr_ptr_sync97, a_rd_ptr_sync97, b_wr_ptr_sync97, b_rd_ptr_sync97;
  reg [ASIZE-1:0] a_wr_ptr_sync98, a_rd_ptr_sync98, b_wr_ptr_sync98, b_rd_ptr_sync98;
  reg [ASIZE-1:0] a_wr_ptr_sync99, a_rd_ptr_sync99, b_wr_ptr_sync99, b_rd_ptr_sync99;
  reg [ASIZE-1:0] a_wr_ptr_sync100, a_rd_ptr_sync100, b_wr_ptr_sync100, b_rd_ptr_sync100;
  reg [ASIZE-1:0] a_wr_ptr_sync101, a_rd_ptr_sync101, b_wr_ptr_sync101, b_rd_ptr_sync101;
  reg [ASIZE-1:0] a_wr_ptr_sync102, a_rd_ptr_sync102, b_wr_ptr_sync102, b_rd_ptr_sync102;
  reg [ASIZE-1:0] a_wr_ptr_sync103, a_rd_ptr_sync103, b_wr_ptr_sync103, b_rd_ptr_sync103;
  reg [ASIZE-1:0] a_wr_ptr_sync104, a_rd_ptr_sync104, b_wr_ptr_sync104, b_rd_ptr_sync104;
  reg [ASIZE-1:0] a_wr_ptr_sync105, a_rd_ptr_sync105, b_wr_ptr_sync105, b_rd_ptr_sync105;
  reg [ASIZE-1:0] a_wr_ptr_sync106, a_rd_ptr_sync106, b_wr_ptr_sync106, b_rd_ptr_sync106;
  reg [ASIZE-1:0] a_wr_ptr_sync107, a_rd_ptr_sync107, b_wr_ptr_sync107, b_rd_ptr_sync107;
  reg [ASIZE-1:0] a_wr_ptr_sync108, a_rd_ptr_sync108, b_wr_ptr_sync108, b_rd_ptr_sync108;
  reg [ASIZE-1:0] a_wr_ptr_sync109, a_rd_ptr_sync109, b_wr_ptr_sync109, b_rd_ptr_sync109;
  reg [ASIZE-1:0] a_wr_ptr_sync110, a_rd_ptr_sync110, b_wr_ptr_sync110, b_rd_ptr_sync110;
  reg [ASIZE-1:0] a_wr_ptr_sync111, a_rd_ptr_sync111, b_wr_ptr_sync111, b_rd_ptr_sync111;
  reg [ASIZE-1:0] a_wr_ptr_sync112, a_rd_ptr_sync112, b_wr_ptr_sync112, b_rd_ptr_sync112;
  reg [ASIZE-1:0] a_wr_ptr_sync113, a_rd_ptr_sync113, b_wr_ptr_sync113, b_rd_ptr_sync113;
  reg [ASIZE-1:0] a_wr_ptr_sync114, a_rd_ptr_sync114, b_wr_ptr_sync114, b_rd_ptr_sync114;
  reg [ASIZE-1:0] a_wr_ptr_sync115, a_rd_ptr_sync115, b_wr_ptr_sync115, b_rd_ptr_sync115;
  reg [ASIZE-1:0] a_wr_ptr_sync116, a_rd_ptr_sync116, b_wr_ptr_sync116, b_rd_ptr_sync116;
  reg [ASIZE-1:0] a_wr_ptr_sync117, a_rd_ptr_sync117, b_wr_ptr_sync117, b_rd_ptr_sync117;
  reg [ASIZE-1:0] a_wr_ptr_sync118, a_rd_ptr_sync118, b_wr_ptr_sync118, b_rd_ptr_sync118;
  reg [ASIZE-1:0] a_wr_ptr_sync119, a_rd_ptr_sync119, b_wr_ptr_sync119, b_rd_ptr_sync119;
  reg [ASIZE-1:0] a_wr_ptr_sync120, a_rd_ptr_sync120, b_wr_ptr_sync120, b_rd_ptr_sync120;
  reg [ASIZE-1:0] a_wr_ptr_sync121, a_rd_ptr_sync121, b_wr_ptr_sync121, b_rd_ptr_sync121;
  reg [ASIZE-1:0] a_wr_ptr_sync122, a_rd_ptr_sync122, b_wr_ptr_sync122, b_rd_ptr_sync122;
  reg [ASIZE-1:0] a_wr_ptr_sync123, a_rd_ptr_sync123, b_wr_ptr_sync123, b_rd_ptr_sync123;
  reg [ASIZE-1:0] a_wr_ptr_sync124, a_rd_ptr_sync124, b_wr_ptr_sync124, b_rd_ptr_sync124;
  reg [ASIZE-1:0] a_wr_ptr_sync125, a_rd_ptr_sync125, b_wr_ptr_sync125, b_rd_ptr_sync125;
  reg [ASIZE-1:0] a_wr_ptr_sync126, a_rd_ptr_sync126, b_wr_ptr_sync126, b_rd_ptr_sync126;
  reg [ASIZE-1:0] a_wr_ptr_sync127, a_rd_ptr_sync127, b_wr_ptr_sync127, b_rd_ptr_sync127;
  reg [ASIZE-1:0] a_wr_ptr_sync128, a_rd_ptr_sync128, b_wr_ptr_sync128, b_rd_ptr_sync128;
  reg [ASIZE-1:0] a_wr_ptr_sync129, a_rd_ptr_sync129, b_wr_ptr_sync129, b_rd_ptr_sync129;
  reg [ASIZE-1:0] a_wr_ptr_sync130, a_rd_ptr_sync130, b_wr_ptr_sync130, b_rd_ptr_sync130;
  reg [ASIZE-1:0] a_wr_ptr_sync131, a_rd_ptr_sync131, b_wr_ptr_sync131, b_rd_ptr_sync131;
  reg [ASIZE-1:0] a_wr_ptr_sync132, a_rd_ptr_sync132, b_wr_ptr_sync132, b_rd_ptr_sync132;
  reg [ASIZE-1:0] a_wr_ptr_sync133, a_rd_ptr_sync133, b_wr_ptr_sync133, b_rd_ptr_sync133;
  reg [ASIZE-1:0] a_wr_ptr_sync134, a_rd_ptr_sync134, b_wr_ptr_sync134, b_rd_ptr_sync134;
  reg [ASIZE-1:0] a_wr_ptr_sync135, a_rd_ptr_sync135, b_wr_ptr_sync135, b_rd_ptr_sync135;
  reg [ASIZE-1:0] a_wr_ptr_sync136, a_rd_ptr_sync136, b_wr_ptr_sync136, b_rd_ptr_sync136;
  reg [ASIZE-1:0] a_wr_ptr_sync137, a_rd_ptr_sync137, b_wr_ptr_sync137, b_rd_ptr_sync137;
  reg [ASIZE-1:0] a_wr_ptr_sync138, a_rd_ptr_sync138, b_wr_ptr_sync138, b_rd_ptr_sync138;
  reg [ASIZE-1:0] a_wr_ptr_sync139, a_rd_ptr_sync139, b_wr_ptr_sync139, b_rd_ptr_sync139;
  reg [ASIZE-1:0] a_wr_ptr_sync140, a_rd_ptr_sync140, b_wr_ptr_sync140, b_rd_ptr_sync140;
  reg [ASIZE-1:0] a_wr_ptr_sync141, a_rd_ptr_sync141, b_wr_ptr_sync141, b_rd_ptr_sync141;
  reg [ASIZE-1:0] a_wr_ptr_sync142, a_rd_ptr_sync142, b_wr_ptr_sync142, b_rd_ptr_sync142;
  reg [ASIZE-1:0] a_wr_ptr_sync143, a_rd_ptr_sync143, b_wr_ptr_sync143, b_rd_ptr_sync143;
  reg [ASIZE-1:0] a_wr_ptr_sync144, a_rd_ptr_sync144, b_wr_ptr_sync144, b_rd_ptr_sync144;
  reg [ASIZE-1:0] a_wr_ptr_sync145, a_rd_ptr_sync145, b_wr_ptr_sync145, b_rd_ptr_sync145;
  reg [ASIZE-1:0] a_wr_ptr_sync146, a_rd_ptr_sync146, b_wr_ptr_sync146, b_rd_ptr_sync146;
  reg [ASIZE-1:0] a_wr_ptr_sync147, a_rd_ptr_sync147, b_wr_ptr_sync147, b_rd_ptr_sync147;
  reg [ASIZE-1:0] a_wr_ptr_sync148, a_rd_ptr_sync148, b_wr_ptr_sync148, b_rd_ptr_sync148;
  reg [ASIZE-1:0] a_wr_ptr_sync149, a_rd_ptr_sync149, b_wr_ptr_sync149, b_rd_ptr_sync149;
  reg [ASIZE-1:0] a_wr_ptr_sync150, a_rd_ptr_sync150, b_wr_ptr_sync150, b_rd_ptr_sync150;
  reg [ASIZE-1:0] a_wr_ptr_sync151, a_rd_ptr_sync151, b_wr_ptr_sync151, b_rd_ptr_sync151;
  reg [ASIZE-1:0] a_wr_ptr_sync152, a_rd_ptr_sync152, b_wr_ptr_sync152, b_rd_ptr_sync152;
  reg [ASIZE-1:0] a_wr_ptr_sync153, a_rd_ptr_sync153, b_wr_ptr_sync153, b_rd_ptr_sync153;
  reg [ASIZE-1:0] a_wr_ptr_sync154, a_rd_ptr_sync154, b_wr_ptr_sync154, b_rd_ptr_sync154;
  reg [ASIZE-1:0] a_wr_ptr_sync155, a_rd_ptr_sync155, b_wr_ptr_sync155, b_rd_ptr_sync155;
  reg [ASIZE-1:0] a_wr_ptr_sync156, a_rd_ptr_sync156, b_wr_ptr_sync156, b_rd_ptr_sync156;
  reg [ASIZE-1:0] a_wr_ptr_sync157, a_rd_ptr_sync157, b_wr_ptr_sync157, b_rd_ptr_sync157;
  reg [ASIZE-1:0] a_wr_ptr_sync158, a_rd_ptr_sync158, b_wr_ptr_sync158, b_rd_ptr_sync158;
  reg [ASIZE-1:0] a_wr_ptr_sync159, a_rd_ptr_sync159, b_wr_ptr_sync159, b_rd_ptr_sync159;
  reg [ASIZE-1:0] a_wr_ptr_sync160, a_rd_ptr_sync160, b_wr_ptr_sync160, b_rd_ptr_sync160;
  reg [ASIZE-1:0] a_wr_ptr_sync161, a_rd_ptr_sync161, b_wr_ptr_sync161, b_rd_ptr_sync161;
  reg [ASIZE-1:0] a_wr_ptr_sync162, a_rd_ptr_sync162, b_wr_ptr_sync162, b_rd_ptr_sync162;
  reg [ASIZE-1:0] a_wr_ptr_sync163, a_rd_ptr_sync163, b_wr_ptr_sync163, b_rd_ptr_sync163;
  reg [ASIZE-1:0] a_wr_ptr_sync164, a_rd_ptr_sync164, b_wr_ptr_sync164, b_rd_ptr_sync164;
  reg [ASIZE-1:0] a_wr_ptr_sync165, a_rd_ptr_sync165, b_wr_ptr_sync165, b_rd_ptr_sync165;
  reg [ASIZE-1:0] a_wr_ptr_sync166, a_rd_ptr_sync166, b_wr_ptr_sync166, b_rd_ptr_sync166;
  reg [ASIZE-1:0] a_wr_ptr_sync167, a_rd_ptr_sync167, b_wr_ptr_sync167, b_rd_ptr_sync167;
  reg [ASIZE-1:0] a_wr_ptr_sync168, a_rd_ptr_sync168, b_wr_ptr_sync168, b_rd_ptr_sync168;
  reg [ASIZE-1:0] a_wr_ptr_sync169, a_rd_ptr_sync169, b_wr_ptr_sync169, b_rd_ptr_sync169;
  reg [ASIZE-1:0] a_wr_ptr_sync170, a_rd_ptr_sync170, b_wr_ptr_sync170, b_rd_ptr_sync170;
  reg [ASIZE-1:0] a_wr_ptr_sync171, a_rd_ptr_sync171, b_wr_ptr_sync171, b_rd_ptr_sync171;
  reg [ASIZE-1:0] a_wr_ptr_sync172, a_rd_ptr_sync172, b_wr_ptr_sync172, b_rd_ptr_sync172;
  reg [ASIZE-1:0] a_wr_ptr_sync173, a_rd_ptr_sync173, b_wr_ptr_sync173, b_rd_ptr_sync173;
  reg [ASIZE-1:0] a_wr_ptr_sync174, a_rd_ptr_sync174, b_wr_ptr_sync174, b_rd_ptr_sync174;
  reg [ASIZE-1:0] a_wr_ptr_sync175, a_rd_ptr_sync175, b_wr_ptr_sync175, b_rd_ptr_sync175;
  reg [ASIZE-1:0] a_wr_ptr_sync176, a_rd_ptr_sync176, b_wr_ptr_sync176, b_rd_ptr_sync176;
  reg [ASIZE-1:0] a_wr_ptr_sync177, a_rd_ptr_sync177, b_wr_ptr_sync177, b_rd_ptr_sync177;
  reg [ASIZE-1:0] a_wr_ptr_sync178, a_rd_ptr_sync178, b_wr_ptr_sync178, b_rd_ptr_sync178;
  reg [ASIZE-1:0] a_wr_ptr_sync179, a_rd_ptr_sync179, b_wr_ptr_sync179, b_rd_ptr_sync179;
  reg [ASIZE-1:0] a_wr_ptr_sync180, a_rd_ptr_sync180, b_wr_ptr_sync180, b_rd_ptr_sync180;
  reg [ASIZE-1:0] a_wr_ptr_sync181, a_rd_ptr_sync181, b_wr_ptr_sync181, b_rd_ptr_sync181;
  reg [ASIZE-1:0] a_wr_ptr_sync182, a_rd_ptr_sync182, b_wr_ptr_sync182, b_rd_ptr_sync182;
  reg [ASIZE-1:0] a_wr_ptr_sync183, a_rd_ptr_sync183, b_wr_ptr_sync183, b_rd_ptr_sync183;
  reg [ASIZE-1:0] a_wr_ptr_sync184, a_rd_ptr_sync184, b_wr_ptr_sync184, b_rd_ptr_sync184;
  reg [ASIZE-1:0] a_wr_ptr_sync185, a_rd_ptr_sync185, b_wr_ptr_sync185, b_rd_ptr_sync185;
  reg [ASIZE-1:0] a_wr_ptr_sync186, a_rd_ptr_sync186, b_wr_ptr_sync186, b_rd_ptr_sync186;
  reg [ASIZE-1:0] a_wr_ptr_sync187, a_rd_ptr_sync187, b_wr_ptr_sync187, b_rd_ptr_sync187;
  reg [ASIZE-1:0] a_wr_ptr_sync188, a_rd_ptr_sync188, b_wr_ptr_sync188, b_rd_ptr_sync188;
  reg [ASIZE-1:0] a_wr_ptr_sync189, a_rd_ptr_sync189, b_wr_ptr_sync189, b_rd_ptr_sync189;
  reg [ASIZE-1:0] a_wr_ptr_sync190, a_rd_ptr_sync190, b_wr_ptr_sync190, b_rd_ptr_sync190;
  reg [ASIZE-1:0] a_wr_ptr_sync191, a_rd_ptr_sync191, b_wr_ptr_sync191, b_rd_ptr_sync191;
  reg [ASIZE-1:0] a_wr_ptr_sync192, a_rd_ptr_sync192, b_wr_ptr_sync192, b_rd_ptr_sync192;
  reg [ASIZE-1:0] a_wr_ptr_sync193, a_rd_ptr_sync193, b_wr_ptr_sync193, b_rd_ptr_sync193;
  reg [ASIZE-1:0] a_wr_ptr_sync194, a_rd_ptr_sync194, b_wr_ptr_sync194, b_rd_ptr_sync194;
  reg [ASIZE-1:0] a_wr_ptr_sync195, a_rd_ptr_sync195, b_wr_ptr_sync195, b_rd_ptr_sync195;
  reg [ASIZE-1:0] a_wr_ptr_sync196, a_rd_ptr_sync196, b_wr_ptr_sync196, b_rd_ptr_sync196;
  reg [ASIZE-1:0] a_wr_ptr_sync197, a_rd_ptr_sync197, b_wr_ptr_sync197, b_rd_ptr_sync197;
  reg [ASIZE-1:0] a_wr_ptr_sync198, a_rd_ptr_sync198, b_wr_ptr_sync198, b_rd_ptr_sync198;
  reg [ASIZE-1:0] a_wr_ptr_sync199, a_rd_ptr_sync199, b_wr_ptr_sync199, b_rd_ptr_sync199;
  reg [ASIZE-1:0] a_wr_ptr_sync200, a_rd_ptr_sync200, b_wr_ptr_sync200, b_rd_ptr_sync200;
  reg [ASIZE-1:0] a_wr_ptr_sync201, a_rd_ptr_sync201, b_wr_ptr_sync201, b_rd_ptr_sync201;
  reg [ASIZE-1:0] a_wr_ptr_sync202, a_rd_ptr_sync202, b_wr_ptr_sync202, b_rd_ptr_sync202;
  reg [ASIZE-1:0] a_wr_ptr_sync203, a_rd_ptr_sync203, b_wr_ptr_sync203, b_rd_ptr_sync203;
  reg [ASIZE-1:0] a_wr_ptr_sync204, a_rd_ptr_sync204, b_wr_ptr_sync204, b_rd_ptr_sync204;
  reg [ASIZE-1:0] a_wr_ptr_sync205, a_rd_ptr_sync205, b_wr_ptr_sync205, b_rd_ptr_sync205;
  reg [ASIZE-1:0] a_wr_ptr_sync206, a_rd_ptr_sync206, b_wr_ptr_sync206, b_rd_ptr_sync206;
  reg [ASIZE-1:0] a_wr_ptr_sync207, a_rd_ptr_sync207, b_wr_ptr_sync207, b_rd_ptr_sync207;
  reg [ASIZE-1:0] a_wr_ptr_sync208, a_rd_ptr_sync208, b_wr_ptr_sync208, b_rd_ptr_sync208;
  reg [ASIZE-1:0] a_wr_ptr_sync209, a_rd_ptr_sync209, b_wr_ptr_sync209, b_rd_ptr_sync209;
  reg [ASIZE-1:0] a_wr_ptr_sync210, a_rd_ptr_sync210, b_wr_ptr_sync210, b_rd_ptr_sync210;
  reg [ASIZE-1:0] a_wr_ptr_sync211, a_rd_ptr_sync211, b_wr_ptr_sync211, b_rd_ptr_sync211;
  reg [ASIZE-1:0] a_wr_ptr_sync212, a_rd_ptr_sync212, b_wr_ptr_sync212, b_rd_ptr_sync212;
  reg [ASIZE-1:0] a_wr_ptr_sync213, a_rd_ptr_sync213, b_wr_ptr_sync213, b_rd_ptr_sync213;
  reg [ASIZE-1:0] a_wr_ptr_sync214, a_rd_ptr_sync214, b_wr_ptr_sync214, b_rd_ptr_sync214;
  reg [ASIZE-1:0] a_wr_ptr_sync215, a_rd_ptr_sync215, b_wr_ptr_sync215, b_rd_ptr_sync215;
  reg [ASIZE-1:0] a_wr_ptr_sync216, a_rd_ptr_sync216, b_wr_ptr_sync216, b_rd_ptr_sync216;
  reg [ASIZE-1:0] a_wr_ptr_sync217, a_rd_ptr_sync217, b_wr_ptr_sync217, b_rd_ptr_sync217;
  reg [ASIZE-1:0] a_wr_ptr_sync218, a_rd_ptr_sync218, b_wr_ptr_sync218, b_rd_ptr_sync218;
  reg [ASIZE-1:0] a_wr_ptr_sync219, a_rd_ptr_sync219, b_wr_ptr_sync219, b_rd_ptr_sync219;
  reg [ASIZE-1:0] a_wr_ptr_sync220, a_rd_ptr_sync220, b_wr_ptr_sync220, b_rd_ptr_sync220;
  reg [ASIZE-1:0] a_wr_ptr_sync221, a_rd_ptr_sync221, b_wr_ptr_sync221, b_rd_ptr_sync221;
  reg [ASIZE-1:0] a_wr_ptr_sync222, a_rd_ptr_sync222, b_wr_ptr_sync222, b_rd_ptr_sync222;
  reg [ASIZE-1:0] a_wr_ptr_sync223, a_rd_ptr_sync223, b_wr_ptr_sync223, b_rd_ptr_sync223;
  reg [ASIZE-1:0] a_wr_ptr_sync224, a_rd_ptr_sync224, b_wr_ptr_sync224, b_rd_ptr_sync224;
  reg [ASIZE-1:0] a_wr_ptr_sync225, a_rd_ptr_sync225, b_wr_ptr_sync225, b_rd_ptr_sync225;
  reg [ASIZE-1:0] a_wr_ptr_sync226, a_rd_ptr_sync226, b_wr_ptr_sync226, b_rd_ptr_sync226;
  reg [ASIZE-1:0] a_wr_ptr_sync227, a_rd_ptr_sync227, b_wr_ptr_sync227, b_rd_ptr_sync227;
  reg [ASIZE-1:0] a_wr_ptr_sync228, a_rd_ptr_sync228, b_wr_ptr_sync228, b_rd_ptr_sync228;
  reg [ASIZE-1:0] a_wr_ptr_sync229, a_rd_ptr_sync229, b_wr_ptr_sync229, b_rd_ptr_sync229;
  reg [ASIZE-1:0] a_wr_ptr_sync230, a_rd_ptr_sync230, b_wr_ptr_sync230, b_rd_ptr_sync230;
  reg [ASIZE-1:0] a_wr_ptr_sync231, a_rd_ptr_sync231, b_wr_ptr_sync231, b_rd_ptr_sync231;
  reg [ASIZE-1:0] a_wr_ptr_sync232, a_rd_ptr
