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
  reg [ASIZE-1:0] a_ptr, a_ptr_gray, b_ptr, b_ptr_gray;
  reg [ASIZE-1:0] a_ptr_sync, b_ptr_sync;
  reg [ASIZE-1:0] a_ptr_sync2, b_ptr_sync2;
  reg [ASIZE-1:0] a_ptr_sync3, b_ptr_sync3;
  reg [ASIZE-1:0] a_ptr_sync4, b_ptr_sync4;
  reg [ASIZE-1:0] a_ptr_sync5, b_ptr_sync5;
  reg [ASIZE-1:0] a_ptr_sync6, b_ptr_sync6;
  reg [ASIZE-1:0] a_ptr_sync7, b_ptr_sync7;
  reg [ASIZE-1:0] a_ptr_sync8, b_ptr_sync8;
  reg [ASIZE-1:0] a_ptr_sync9, b_ptr_sync9;
  reg [ASIZE-1:0] a_ptr_sync10, b_ptr_sync10;
  reg [ASIZE-1:0] a_ptr_sync11, b_ptr_sync11;
  reg [ASIZE-1:0] a_ptr_sync12, b_ptr_sync12;
  reg [ASIZE-1:0] a_ptr_sync13, b_ptr_sync13;
  reg [ASIZE-1:0] a_ptr_sync14, b_ptr_sync14;
  reg [ASIZE-1:0] a_ptr_sync15, b_ptr_sync15;
  reg [ASIZE-1:0] a_ptr_sync16, b_ptr_sync16;
  reg [ASIZE-1:0] a_ptr_sync17, b_ptr_sync17;
  reg [ASIZE-1:0] a_ptr_sync18, b_ptr_sync18;
  reg [ASIZE-1:0] a_ptr_sync19, b_ptr_sync19;
  reg [ASIZE-1:0] a_ptr_sync20, b_ptr_sync20;
  reg [ASIZE-1:0] a_ptr_sync21, b_ptr_sync21;
  reg [ASIZE-1:0] a_ptr_sync22, b_ptr_sync22;
  reg [ASIZE-1:0] a_ptr_sync23, b_ptr_sync23;

  assign a_full = (a_ptr_gray == b_ptr_sync23) && (a_dir == 1'b1);
  assign a_afull = (a_ptr_gray == b_ptr_sync23) && (a_dir == 1'b1);
  assign a_empty = (a_ptr_gray == b_ptr_sync23) && (a_dir == 1'b0);
  assign a_aempty = (a_ptr_gray == b_ptr_sync23) && (a_dir == 1'b0);

  assign b_full = (b_ptr_gray == a_ptr_sync23) && (b_dir == 1'b1);
  assign b_afull = (b_ptr_gray == a_ptr_sync23) && (b_dir == 1'b1);
  assign b_empty = (b_ptr_gray == a_ptr_sync23) && (b_dir == 1'b0);
  assign b_aempty = (b_ptr_gray == a_ptr_sync23) && (b_dir == 1'b0);

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr <= 0;
      a_ptr_gray <= 0;
    end else begin
      if (a_winc &&!a_full) begin
        a_ptr <= a_ptr + 1;
        a_ptr_gray <= gray_encode(a_ptr + 1);
      end
      if (a_rinc &&!a_empty) begin
        a_ptr <= a_ptr - 1;
        a_ptr_gray <= gray_encode(a_ptr - 1);
      end
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr <= 0;
      b_ptr_gray <= 0;
    end else begin
      if (b_winc &&!b_full) begin
        b_ptr <= b_ptr + 1;
        b_ptr_gray <= gray_encode(b_ptr + 1);
      end
      if (b_rinc &&!b_empty) begin
        b_ptr <= b_ptr - 1;
        b_ptr_gray <= gray_encode(b_ptr - 1);
      end
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr_sync <= 0;
      a_ptr_sync2 <= 0;
      a_ptr_sync3 <= 0;
      a_ptr_sync4 <= 0;
      a_ptr_sync5 <= 0;
      a_ptr_sync6 <= 0;
      a_ptr_sync7 <= 0;
      a_ptr_sync8 <= 0;
      a_ptr_sync9 <= 0;
      a_ptr_sync10 <= 0;
      a_ptr_sync11 <= 0;
      a_ptr_sync12 <= 0;
      a_ptr_sync13 <= 0;
      a_ptr_sync14 <= 0;
      a_ptr_sync15 <= 0;
      a_ptr_sync16 <= 0;
      a_ptr_sync17 <= 0;
      a_ptr_sync18 <= 0;
      a_ptr_sync19 <= 0;
      a_ptr_sync20 <= 0;
      a_ptr_sync21 <= 0;
      a_ptr_sync22 <= 0;
      a_ptr_sync23 <= 0;
    end else begin
      a_ptr_sync <= b_ptr_gray;
      a_ptr_sync2 <= a_ptr_sync;
      a_ptr_sync3 <= a_ptr_sync2;
      a_ptr_sync4 <= a_ptr_sync3;
      a_ptr_sync5 <= a_ptr_sync4;
      a_ptr_sync6 <= a_ptr_sync5;
      a_ptr_sync7 <= a_ptr_sync6;
      a_ptr_sync8 <= a_ptr_sync7;
      a_ptr_sync9 <= a_ptr_sync8;
      a_ptr_sync10 <= a_ptr_sync9;
      a_ptr_sync11 <= a_ptr_sync10;
      a_ptr_sync12 <= a_ptr_sync11;
      a_ptr_sync13 <= a_ptr_sync12;
      a_ptr_sync14 <= a_ptr_sync13;
      a_ptr_sync15 <= a_ptr_sync14;
      a_ptr_sync16 <= a_ptr_sync15;
      a_ptr_sync17 <= a_ptr_sync16;
      a_ptr_sync18 <= a_ptr_sync17;
      a_ptr_sync19 <= a_ptr_sync18;
      a_ptr_sync20 <= a_ptr_sync19;
      a_ptr_sync21 <= a_ptr_sync20;
      a_ptr_sync22 <= a_ptr_sync21;
      a_ptr_sync23 <= a_ptr_sync22;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr_sync <= 0;
      b_ptr_sync2 <= 0;
      b_ptr_sync3 <= 0;
      b_ptr_sync4 <= 0;
      b_ptr_sync5 <= 0;
      b_ptr_sync6 <= 0;
      b_ptr_sync7 <= 0;
      b_ptr_sync8 <= 0;
      b_ptr_sync9 <= 0;
      b_ptr_sync10 <= 0;
      b_ptr_sync11 <= 0;
      b_ptr_sync12 <= 0;
      b_ptr_sync13 <= 0;
      b_ptr_sync14 <= 0;
      b_ptr_sync15 <= 0;
      b_ptr_sync16 <= 0;
      b_ptr_sync17 <= 0;
      b_ptr_sync18 <= 0;
      b_ptr_sync19 <= 0;
      b_ptr_sync20 <= 0;
      b_ptr_sync21 <= 0;
      b_ptr_sync22 <= 0;
      b_ptr_sync23 <= 0;
    end else begin
      b_ptr_sync <= a_ptr_gray;
      b_ptr_sync2 <= b_ptr_sync;
      b_ptr_sync3 <= b_ptr_sync2;
      b_ptr_sync4 <= b_ptr_sync3;
      b_ptr_sync5 <= b_ptr_sync4;
      b_ptr_sync6 <= b_ptr_sync5;
      b_ptr_sync7 <= b_ptr_sync6;
      b_ptr_sync8 <= b_ptr_sync7;
      b_ptr_sync9 <= b_ptr_sync8;
      b_ptr_sync10 <= b_ptr_sync9;
      b_ptr_sync11 <= b_ptr_sync10;
      b_ptr_sync12 <= b_ptr_sync11;
      b_ptr_sync13 <= b_ptr_sync12;
      b_ptr_sync14 <= b_ptr_sync13;
      b_ptr_sync15 <= b_ptr_sync14;
      b_ptr_sync16 <= b_ptr_sync15;
      b_ptr_sync17 <= b_ptr_sync16;
      b_ptr_sync18 <= b_ptr_sync17;
      b_ptr_sync19 <= b_ptr_sync18;
      b_ptr_sync20 <= b_ptr_sync19;
      b_ptr_sync21 <= b_ptr_sync20;
      b_ptr_sync22 <= b_ptr_sync21;
      b_ptr_sync23 <= b_ptr_sync22;
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else if (a_rinc &&!a_empty) begin
      a_rdata <= mem[a_ptr_gray];
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_rdata <= 0;
    end else if (b_rinc &&!b_empty) begin
      b_rdata <= mem[b_ptr_gray];
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      mem <= '{default:0};
    end else if (a_winc &&!a_full) begin
      mem[a_ptr_gray] <= a_wdata;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      mem <= '{default:0};
    end else if (b_winc &&!b_full) begin
      mem[b_ptr_gray] <= b_wdata;
    end

  function [ASIZE-1:0] gray_encode;
    input [ASIZE-1:0] bin;
    begin
      gray_encode = bin ^ (bin >> 1);
    end
  endfunction

endmodule
