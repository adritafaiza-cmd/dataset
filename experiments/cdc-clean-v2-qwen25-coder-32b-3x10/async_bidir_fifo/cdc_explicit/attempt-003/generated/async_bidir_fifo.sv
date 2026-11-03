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

  localparam DEPTH = 1 << ASIZE;
  localparam AFULL_THRESHOLD = DEPTH - 2;
  localparam AEMPTY_THRESHOLD = 1;

  reg [DSIZE-1:0] mem_a [0:DEPTH-1];
  reg [DSIZE-1:0] mem_b [0:DEPTH-1];

  reg [ASIZE:0] a_wr_ptr, a_wr_ptr_gray, a_wr_ptr_gray_sync;
  reg [ASIZE:0] a_rd_ptr, a_rd_ptr_gray, a_rd_ptr_gray_sync;
  reg [ASIZE:0] b_wr_ptr, b_wr_ptr_gray, b_wr_ptr_gray_sync;
  reg [ASIZE:0] b_rd_ptr, b_rd_ptr_gray, b_rd_ptr_gray_sync;

  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;

  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray code conversion functions
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE; i > 0; i = i - 1)
      bin[i-1] = bin[i] ^ bin[i-1];
    gray_to_bin = bin;
  endfunction

  // A-side logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_wr_ptr_gray_sync <= 0;
      a_full_reg <= 0;
      a_afull_reg <= 0;
    end else begin
      if (a_dir && !a_full_reg) begin
        mem_a[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
      end
      a_wr_ptr_gray_sync <= a_wr_ptr_gray;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
      a_rd_ptr_gray_sync <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      if (!a_dir && !a_empty_reg) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
      end
      a_rd_ptr_gray_sync <= a_rd_ptr_gray;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else if (!a_dir && !a_empty_reg) begin
      a_rdata_reg <= mem_a[a_rd_ptr[ASIZE-1:0]];
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_reg <= 0;
      a_afull_reg <= 0;
    end else begin
      a_full_reg <= (a_wr_ptr_gray_sync[ASIZE:0] == {~a_rd_ptr_gray[ASIZE], a_rd_ptr_gray[ASIZE-1:0]});
      a_afull_reg <= (a_wr_ptr_gray_sync[ASIZE:0] == {~a_rd_ptr_gray[ASIZE-1], a_rd_ptr_gray[ASIZE-2:0], a_rd_ptr_gray[ASIZE]});
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      a_empty_reg <= (a_wr_ptr_gray[ASIZE:0] == a_rd_ptr_gray_sync[ASIZE:0]);
      a_aempty_reg <= (a_wr_ptr_gray[ASIZE:0] == {a_rd_ptr_gray_sync[ASIZE-1], a_rd_ptr_gray_sync[ASIZE-2:0], a_rd_ptr_gray_sync[ASIZE]});
    end
  end

  // B-side logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_wr_ptr_gray_sync <= 0;
      b_full_reg <= 0;
      b_afull_reg <= 0;
    end else begin
      if (b_dir && !b_full_reg) begin
        mem_b[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= bin_to_gray(b_wr_ptr + 1);
      end
      b_wr_ptr_gray_sync <= b_wr_ptr_gray;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
      b_rd_ptr_gray_sync <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      if (!b_dir && !b_empty_reg) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= bin_to_gray(b_rd_ptr + 1);
      end
      b_rd_ptr_gray_sync <= b_rd_ptr_gray;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else if (!b_dir && !b_empty_reg) begin
      b_rdata_reg <= mem_b[b_rd_ptr[ASIZE-1:0]];
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_reg <= 0;
      b_afull_reg <= 0;
    end else begin
      b_full_reg <= (b_wr_ptr_gray_sync[ASIZE:0] == {~b_rd_ptr_gray[ASIZE], b_rd_ptr_gray[ASIZE-1:0]});
      b_afull_reg <= (b_wr_ptr_gray_sync[ASIZE:0] == {~b_rd_ptr_gray[ASIZE-1], b_rd_ptr_gray[ASIZE-2:0], b_rd_ptr_gray[ASIZE]});
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      b_empty_reg <= (b_wr_ptr_gray[ASIZE:0] == b_rd_ptr_gray_sync[ASIZE:0]);
      b_aempty_reg <= (b_wr_ptr_gray[ASIZE:0] == {b_rd_ptr_gray_sync[ASIZE-1], b_rd_ptr_gray_sync[ASIZE-2:0], b_rd_ptr_gray_sync[ASIZE]});
    end
  end

  assign a_rdata = a_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;

  assign b_rdata = b_rdata_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

endmodule
