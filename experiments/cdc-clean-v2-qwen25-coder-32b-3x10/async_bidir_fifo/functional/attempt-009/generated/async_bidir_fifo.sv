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

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // a_side signals
  reg [ASIZE:0] a_wr_ptr, a_wr_ptr_gray, a_wr_ptr_gray_nxt;
  reg [ASIZE:0] a_rd_ptr, a_rd_ptr_gray, a_rd_ptr_gray_nxt;
  reg [DSIZE-1:0] a_rdata_reg;

  // b_side signals
  reg [ASIZE:0] b_wr_ptr, b_wr_ptr_gray, b_wr_ptr_gray_nxt;
  reg [ASIZE:0] b_rd_ptr, b_rd_ptr_gray, b_rd_ptr_gray_nxt;
  reg [DSIZE-1:0] b_rdata_reg;

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
    for (i = ASIZE-1; i > 0; i = i - 1)
      bin[i-1] = bin[i] ^ bin[i-1];
    gray_to_bin = bin;
  endfunction

  // a_side logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
    end else begin
      a_wr_ptr_gray <= a_wr_ptr_gray_nxt;
      a_rd_ptr_gray <= a_rd_ptr_gray_nxt;
      if (a_dir && !a_full) begin
        mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
      end
      if (!a_dir && !a_empty) begin
        a_rd_ptr <= a_rd_ptr + 1;
      end
    end
  end

  always @(*) begin
    a_wr_ptr_gray_nxt = bin_to_gray(a_wr_ptr);
    a_rd_ptr_gray_nxt = bin_to_gray(a_rd_ptr);
  end

  assign a_full = (a_wr_ptr_gray_nxt == {a_rd_ptr_gray[ASIZE], ~a_rd_ptr_gray[ASIZE-1:0]});
  assign a_afull = (a_wr_ptr_gray_nxt == {a_rd_ptr_gray[ASIZE], ~a_rd_ptr_gray[ASIZE-1:0], 1'b1});
  assign a_empty = (a_wr_ptr_gray == a_rd_ptr_gray);
  assign a_aempty = (a_wr_ptr_gray == {a_rd_ptr_gray[ASIZE], a_rd_ptr_gray[ASIZE-1:0], 1'b0});

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else if (!a_dir && !a_empty) begin
      a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
    end
  end

  assign a_rdata = a_rdata_reg;

  // b_side logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
    end else begin
      b_wr_ptr_gray <= b_wr_ptr_gray_nxt;
      b_rd_ptr_gray <= b_rd_ptr_gray_nxt;
      if (b_dir && !b_full) begin
        mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
      end
      if (!b_dir && !b_empty) begin
        b_rd_ptr <= b_rd_ptr + 1;
      end
    end
  end

  always @(*) begin
    b_wr_ptr_gray_nxt = bin_to_gray(b_wr_ptr);
    b_rd_ptr_gray_nxt = bin_to_gray(b_rd_ptr);
  end

  assign b_full = (b_wr_ptr_gray_nxt == {b_rd_ptr_gray[ASIZE], ~b_rd_ptr_gray[ASIZE-1:0]});
  assign b_afull = (b_wr_ptr_gray_nxt == {b_rd_ptr_gray[ASIZE], ~b_rd_ptr_gray[ASIZE-1:0], 1'b1});
  assign b_empty = (b_wr_ptr_gray == b_rd_ptr_gray);
  assign b_aempty = (b_wr_ptr_gray == {b_rd_ptr_gray[ASIZE], b_rd_ptr_gray[ASIZE-1:0], 1'b0});

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else if (!b_dir && !b_empty) begin
      b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
    end
  end

  assign b_rdata = b_rdata_reg;

endmodule
