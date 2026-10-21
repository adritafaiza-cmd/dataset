```verilog
`timescale 1ns/1ps

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

  localparam INT_ASIZE = ASIZE;
  localparam INT_DEPTH = 1 << INT_ASIZE;
  localparam INT_MASK  = (1 << INT_ASIZE) - 1;

  // Internal pointers and flags
  reg [INT_ASIZE-1:0] a_write_ptr;
  reg [INT_ASIZE-1:0] a_read_ptr;
  reg [INT_ASIZE-1:0] b_write_ptr;
  reg [INT_ASIZE-1:0] b_read_ptr;

  reg [INT_ASIZE-1:0] a_write_ptr_sync;
  reg [INT_ASIZE-1:0] a_read_ptr_sync;
  reg [INT_ASIZE-1:0] b_write_ptr_sync;
  reg [INT_ASIZE-1:0] b_read_ptr_sync;

  reg [INT_ASIZE-1:0] a_write_ptr_cross;
  reg [INT_ASIZE-1:0] a_read_ptr_cross;
  reg [INT_ASIZE-1:0] b_write_ptr_cross;
  reg [INT_ASIZE-1:0] b_read_ptr_cross;

  reg [INT_ASIZE-1:0] a_write_ptr_next;
  reg [INT_ASIZE-1:0] a_read_ptr_next;
  reg [INT_ASIZE-1:0] b_write_ptr_next;
  reg [INT_ASIZE-1:0] b_read_ptr_next;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync2;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync2;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync2;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync2;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync3;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync3;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync3;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync3;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync4;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync4;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync4;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync4;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync5;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync5;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync5;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync5;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync6;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync6;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync6;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync6;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync7;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync7;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync7;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync7;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync8;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync8;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync8;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync8;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync9;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync9;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync9;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync9;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync10;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync10;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync10;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync10;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync11;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync11;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync11;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync11;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync12;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync12;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync12;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync12;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync13;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync13;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync13;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync13;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync14;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync14;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync14;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync14;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync15;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync15;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync15;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync15;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync16;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync16;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync16;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync16;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync17;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync17;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync17;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync17;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync18;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync18;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync18;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync18;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync19;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync19;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync19;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync19;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync20;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync20;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync20;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync20;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync21;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync21;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync21;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync21;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync22;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync22;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync22;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync22;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync23;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync23;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync23;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync23;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync24;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync24;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync24;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync24;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync25;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync25;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync25;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync25;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync26;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync26;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync26;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync26;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync27;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync27;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync27;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync27;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync28;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync28;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync28;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync28;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync29;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync29;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync29;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync29;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync30;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync30;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync30;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync30;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync31;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync31;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync31;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync31;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync32;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync32;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync32;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync32;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync33;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync33;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync33;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync33;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync34;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync34;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync34;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync34;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync35;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync35;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync35;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync35;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync36;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync36;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync36;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync36;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync37;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync37;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync37;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync37;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync38;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync38;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync38;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync38;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync39;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync39;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync39;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync39;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync40;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync40;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync40;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync40;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync41;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync41;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync41;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync41;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync42;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync42;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync42;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync42;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync43;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync43;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync43;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync43;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync44;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync44;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync44;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync44;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync45;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync45;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync45;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync45;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync46;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync46;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync46;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync46;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync47;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync47;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync47;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync47;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync48;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync48;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync48;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync48;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync49;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync49;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync49;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync49;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync50;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync50;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync50;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync50;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync51;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync51;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync51;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync51;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync52;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync52;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync52;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync52;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync53;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync53;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync53;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync53;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync54;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync54;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync54;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync54;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync55;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync55;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync55;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync55;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync56;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync56;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync56;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync56;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync57;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync57;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync57;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync57;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync58;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync58;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync58;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync58;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync59;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync59;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync59;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync59;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync60;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync60;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync60;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync60;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync61;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync61;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync61;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync61;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync62;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync62;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync62;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync62;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync63;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync63;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync63;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync63;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync64;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync64;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync64;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync64;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync65;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync65;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync65;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync65;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync66;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync66;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync66;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync66;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync67;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync67;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync67;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync67;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync68;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync68;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync68;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync68;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync69;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync69;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync69;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync69;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync70;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync70;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync70;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync70;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync71;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync71;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync71;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync71;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync72;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync72;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync72;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync72;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync73;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync73;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync73;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync73;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync74;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync74;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync74;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync74;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync75;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync75;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync75;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync75;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync76;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync76;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync76;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync76;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync77;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync77;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync77;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync77;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync78;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync78;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync78;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync78;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync79;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync79;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync79;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync79;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync80;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync80;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync80;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync80;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync81;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync81;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync81;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync81;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync82;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync82;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync82;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync82;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync83;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync83;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync83;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync83;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync84;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync84;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync84;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync84;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync85;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync85;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync85;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync85;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync86;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync86;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync86;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync86;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync87;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync87;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync87;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync87;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync88;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync88;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync88;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync88;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync89;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync89;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync89;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync89;

  reg [INT_ASIZE-1:0] a_write_ptr_next_cross_sync90;
  reg [INT_ASIZE-1:0] a_read_ptr_next_cross_sync90;
  reg [INT_ASIZE-1:0] b_write_ptr_next_cross_sync90;
  reg [INT_ASIZE-1:0] b_read_ptr_next_cross_sync90;