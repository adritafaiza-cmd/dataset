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
  reg [ASIZE-1:0] a_wr_ptr_sync_gray, a_rd_ptr_sync_gray, b_wr_ptr_sync_gray, b_rd_ptr_sync_gray;
  reg [ASIZE-1:0] a_wr_ptr_sync2, a_rd_ptr_sync2, b_wr_ptr_sync2, b_rd_ptr_sync2;
  reg [ASIZE-1:0] a_wr_ptr_sync2_gray, a_rd_ptr_sync2_gray, b_wr_ptr_sync2_gray, b_rd_ptr_sync2_gray;

  reg a_full_int, a_afull_int, a_empty_int, a_aempty_int;
  reg b_full_int, b_afull_int, b_empty_int, b_aempty_int;

  assign a_full = a_full_int;
  assign a_afull = a_afull_int;
  assign a_empty = a_empty_int;
  assign a_aempty = a_aempty_int;
  assign b_full = b_full_int;
  assign b_afull = b_afull_int;
  assign b_empty = b_empty_int;
  assign b_aempty = b_aempty_int;

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
    end else if (a_dir) begin
      if (a_winc && !a_full_int) begin
        mem[a_wr_ptr] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
      end
    end else if (a_rinc && !a_empty_int) begin
      a_rd_ptr <= a_rd_ptr + 1;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
    end else if (b_dir) begin
      if (b_winc && !b_full_int) begin
        mem[b_wr_ptr] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
      end
    end else if (b_rinc && !b_empty_int) begin
      b_rd_ptr <= b_rd_ptr + 1;
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
    end else begin
      a_wr_ptr_gray <= gray_encode(a_wr_ptr);
      a_rd_ptr_gray <= gray_encode(a_rd_ptr);
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
    end else begin
      b_wr_ptr_gray <= gray_encode(b_wr_ptr);
      b_rd_ptr_gray <= gray_encode(b_rd_ptr);
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr_sync <= 0;
      a_rd_ptr_sync <= 0;
    end else begin
      a_wr_ptr_sync <= b_wr_ptr_sync2;
      a_rd_ptr_sync <= b_rd_ptr_sync2;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr_sync <= 0;
      b_rd_ptr_sync <= 0;
    end else begin
      b_wr_ptr_sync <= a_wr_ptr_sync2;
      b_rd_ptr_sync <= a_rd_ptr_sync2;
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr_sync_gray <= 0;
      a_rd_ptr_sync_gray <= 0;
    end else begin
      a_wr_ptr_sync_gray <= gray_encode(a_wr_ptr_sync);
      a_rd_ptr_sync_gray <= gray_encode(a_rd_ptr_sync);
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr_sync_gray <= 0;
      b_rd_ptr_sync_gray <= 0;
    end else begin
      b_wr_ptr_sync_gray <= gray_encode(b_wr_ptr_sync);
      b_rd_ptr_sync_gray <= gray_encode(b_rd_ptr_sync);
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr_sync2 <= 0;
      a_rd_ptr_sync2 <= 0;
    end else begin
      a_wr_ptr_sync2 <= b_wr_ptr_sync;
      a_rd_ptr_sync2 <= b_rd_ptr_sync;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr_sync2 <= 0;
      b_rd_ptr_sync2 <= 0;
    end else begin
      b_wr_ptr_sync2 <= a_wr_ptr_sync;
      b_rd_ptr_sync2 <= a_rd_ptr_sync;
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_wr_ptr_sync2_gray <= 0;
      a_rd_ptr_sync2_gray <= 0;
    end else begin
      a_wr_ptr_sync2_gray <= gray_encode(a_wr_ptr_sync2);
      a_rd_ptr_sync2_gray <= gray_encode(a_rd_ptr_sync2);
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_wr_ptr_sync2_gray <= 0;
      b_rd_ptr_sync2_gray <= 0;
    end else begin
      b_wr_ptr_sync2_gray <= gray_encode(b_wr_ptr_sync2);
      b_rd_ptr_sync2_gray <= gray_encode(b_rd_ptr_sync2);
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_full_int <= 0;
      a_afull_int <= 0;
      a_empty_int <= 1;
      a_aempty_int <= 1;
    end else begin
      if (a_dir && a_winc && !a_full_int) begin
        if (a_wr_ptr == a_rd_ptr + 2**ASIZE - 1) begin
          a_full_int <= 1;
        end else if (a_wr_ptr == a_rd_ptr + 2**ASIZE - 2) begin
          a_afull_int <= 1;
        end
      end else if (!a_dir && a_rinc && !a_empty_int) begin
        if (a_rd_ptr == a_wr_ptr) begin
          a_empty_int <= 1;
        end else if (a_rd_ptr == a_wr_ptr + 1) begin
          a_aempty_int <= 1;
        end
      end
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_full_int <= 0;
      b_afull_int <= 0;
      b_empty_int <= 1;
      b_aempty_int <= 1;
    end else begin
      if (b_dir && b_winc && !b_full_int) begin
        if (b_wr_ptr == b_rd_ptr + 2**ASIZE - 1) begin
          b_full_int <= 1;
        end else if (b_wr_ptr == b_rd_ptr + 2**ASIZE - 2) begin
          b_afull_int <= 1;
        end
      end else if (!b_dir && b_rinc && !b_empty_int) begin
        if (b_rd_ptr == b_wr_ptr) begin
          b_empty_int <= 1;
        end else if (b_rd_ptr == b_wr_ptr + 1) begin
          b_aempty_int <= 1;
        end
      end
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else if (a_dir) begin
      a_rdata <= 0;
    end else if (a_rinc && !a_empty_int) begin
      a_rdata <= mem[a_rd_ptr];
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_rdata <= 0;
    end else if (b_dir) begin
      b_rdata <= 0;
    end else if (b_rinc && !b_empty_int) begin
      b_rdata <= mem[b_rd_ptr];
    end

  function [ASIZE-1:0] gray_encode;
    input [ASIZE-1:0] bin;
    reg [ASIZE-1:0] gray;
    begin
      gray = bin ^ (bin >> 1);
      gray_encode = gray;
    end
  endfunction

endmodule
