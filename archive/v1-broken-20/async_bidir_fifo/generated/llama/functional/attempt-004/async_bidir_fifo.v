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
  reg [ASIZE-1:0] a_wr_ptr;
  reg [ASIZE-1:0] a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr;
  reg [ASIZE-1:0] b_rd_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray;
  reg [ASIZE-1:0] a_rd_ptr_gray;
  reg [ASIZE-1:0] b_wr_ptr_gray;
  reg [ASIZE-1:0] b_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_sync;
  reg [ASIZE-1:0] a_rd_ptr_sync;
  reg [ASIZE-1:0] b_wr_ptr_sync;
  reg [ASIZE-1:0] b_rd_ptr_sync;
  reg [ASIZE-1:0] a_wr_ptr_sync_gray;
  reg [ASIZE-1:0] a_rd_ptr_sync_gray;
  reg [ASIZE-1:0] b_wr_ptr_sync_gray;
  reg [ASIZE-1:0] b_rd_ptr_sync_gray;
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;
  reg a_full_reg;
  reg a_afull_reg;
  reg a_empty_reg;
  reg a_aempty_reg;
  reg b_full_reg;
  reg b_afull_reg;
  reg b_empty_reg;
  reg b_aempty_reg;

  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
      a_rdata_reg <= 0;
      a_full_reg <= 0;
      a_afull_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      if (a_dir) begin
        if (a_winc && !a_full_reg) begin
          mem[a_wr_ptr] <= a_wdata;
          a_wr_ptr <= a_wr_ptr + 1;
          a_wr_ptr_gray <= gray_encode(a_wr_ptr);
        end
      end else begin
        if (a_rinc && !a_empty_reg) begin
          a_rdata_reg <= mem[a_rd_ptr];
          a_rd_ptr <= a_rd_ptr + 1;
          a_rd_ptr_gray <= gray_encode(a_rd_ptr);
        end
      end
      if (a_wr_ptr == (2**ASIZE - 1)) begin
        a_wr_ptr <= 0;
        a_wr_ptr_gray <= 0;
      end
      if (a_rd_ptr == (2**ASIZE - 1)) begin
        a_rd_ptr <= 0;
        a_rd_ptr_gray <= 0;
      end
      if (a_wr_ptr_gray == a_rd_ptr_gray) begin
        a_empty_reg <= 1;
        a_full_reg <= 0;
      end else if (a_wr_ptr_gray == (a_rd_ptr_gray + 1) % (2**ASIZE)) begin
        a_empty_reg <= 0;
        a_full_reg <= 1;
      end else if (a_wr_ptr_gray == (a_rd_ptr_gray + (2**(ASIZE-1) - 1)) % (2**ASIZE)) begin
        a_afull_reg <= 1;
      end else begin
        a_afull_reg <= 0;
      end
      if (a_wr_ptr_gray == a_rd_ptr_gray && a_rinc) begin
        a_aempty_reg <= 1;
      end else begin
        a_aempty_reg <= 0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
      b_rdata_reg <= 0;
      b_full_reg <= 0;
      b_afull_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      if (b_dir) begin
        if (b_winc && !b_full_reg) begin
          mem[b_wr_ptr] <= b_wdata;
          b_wr_ptr <= b_wr_ptr + 1;
          b_wr_ptr_gray <= gray_encode(b_wr_ptr);
        end
      end else begin
        if (b_rinc && !b_empty_reg) begin
          b_rdata_reg <= mem[b_rd_ptr];
          b_rd_ptr <= b_rd_ptr + 1;
          b_rd_ptr_gray <= gray_encode(b_rd_ptr);
        end
      end
      if (b_wr_ptr == (2**ASIZE - 1)) begin
        b_wr_ptr <= 0;
        b_wr_ptr_gray <= 0;
      end
      if (b_rd_ptr == (2**ASIZE - 1)) begin
        b_rd_ptr <= 0;
        b_rd_ptr_gray <= 0;
      end
      if (b_wr_ptr_gray == b_rd_ptr_gray) begin
        b_empty_reg <= 1;
        b_full_reg <= 0;
      end else if (b_wr_ptr_gray == (b_rd_ptr_gray + 1) % (2**ASIZE)) begin
        b_empty_reg <= 0;
        b_full_reg <= 1;
      end else if (b_wr_ptr_gray == (b_rd_ptr_gray + (2**(ASIZE-1) - 1)) % (2**ASIZE)) begin
        b_afull_reg <= 1;
      end else begin
        b_afull_reg <= 0;
      end
      if (b_wr_ptr_gray == b_rd_ptr_gray && b_rinc) begin
        b_aempty_reg <= 1;
      end else begin
        b_aempty_reg <= 0;
      end
    end
  end

  always @(posedge a_clk) begin
    a_wr_ptr_sync <= a_wr_ptr;
    a_rd_ptr_sync <= a_rd_ptr;
    a_wr_ptr_sync_gray <= gray_encode(a_wr_ptr_sync);
    a_rd_ptr_sync_gray <= gray_encode(a_rd_ptr_sync);
  end

  always @(posedge b_clk) begin
    b_wr_ptr_sync <= b_wr_ptr;
    b_rd_ptr_sync <= b_rd_ptr;
    b_wr_ptr_sync_gray <= gray_encode(b_wr_ptr_sync);
    b_rd_ptr_sync_gray <= gray_encode(b_rd_ptr_sync);
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

  function [ASIZE-1:0] gray_encode;
    input [ASIZE-1:0] bin;
    begin
      gray_encode = bin ^ (bin >> 1);
    end
  endfunction

endmodule
