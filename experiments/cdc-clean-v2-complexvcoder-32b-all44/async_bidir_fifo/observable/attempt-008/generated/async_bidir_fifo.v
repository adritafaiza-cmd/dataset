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

  wire [DSIZE-1:0] fifo_a_to_b_rdata;
  wire fifo_a_to_b_full;
  wire fifo_a_to_b_afull;
  wire fifo_a_to_b_empty;
  wire fifo_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_b_to_a_rdata;
  wire fifo_b_to_a_full;
  wire fifo_b_to_a_afull;
  wire fifo_b_to_a_empty;
  wire fifo_b_to_a_aempty;

  async_fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    fifo_a_to_b (
      .a_winc   (a_winc),
      .a_wdata  (a_wdata),
      .a_rinc   (a_rinc),
      .a_rdata  (fifo_a_to_b_rdata),
      .a_full   (fifo_a_to_b_full),
      .a_afull  (fifo_a_to_b_afull),
      .a_empty  (fifo_a_to_b_empty),
      .a_aempty (fifo_a_to_b_aempty),
      .a_dir    (a_dir),
      .a_clk    (a_clk),
      .a_rst_n  (a_rst_n)
    );

  async_fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    fifo_b_to_a (
      .a_winc   (b_winc),
      .a_wdata  (b_wdata),
      .a_rinc   (b_rinc),
      .a_rdata  (fifo_b_to_a_rdata),
      .a_full   (fifo_b_to_a_full),
      .a_afull  (fifo_b_to_a_afull),
      .a_empty  (fifo_b_to_a_empty),
      .a_aempty (fifo_b_to_a_aempty),
      .a_dir    (b_dir),
      .a_clk    (b_clk),
      .a_rst_n  (b_rst_n)
    );

  assign a_rdata = fifo_a_to_b_rdata;
  assign a_full = fifo_a_to_b_full;
  assign a_afull = fifo_a_to_b_afull;
  assign a_empty = fifo_a_to_b_empty;
  assign a_aempty = fifo_a_to_b_aempty;

  assign b_rdata = fifo_b_to_a_rdata;
  assign b_full = fifo_b_to_a_full;
  assign b_afull = fifo_b_to_a_afull;
  assign b_empty = fifo_b_to_a_empty;
  assign b_aempty = fifo_b_to_a_aempty;

endmodule

module async_fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              a_clk,
       input wire              a_rst_n
       );

  reg [DSIZE-1:0] a_ram [0:(2**ASIZE)-1];
  reg [ASIZE-1:0] a_wr_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray;
  reg [ASIZE-1:0] b_wr_ptr_gray;
  reg [ASIZE-1:0] a_rd_ptr;
  reg [ASIZE-1:0] a_rd_ptr_gray;
  reg [ASIZE-1:0] b_rd_ptr_gray;
  reg a_full_flag;
  reg a_afull_flag;
  reg a_empty_flag;
  reg a_aempty_flag;

  wire [ASIZE-1:0] a_wr_ptr_gray_sync;
  wire [ASIZE-1:0] a_rd_ptr_gray_sync;

  // Gray code conversion
  function [ASIZE-1:0] bin_to_gray;
    input [ASIZE-1:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Sync pointers to other clock domain
  sync_gray_counter #(.ASIZE(ASIZE))
    sync_wr_ptr (
      .a_clk (a_clk),
      .a_rst_n (a_rst_n),
      .a_gray (a_wr_ptr_gray),
      .b_gray (a_wr_ptr_gray_sync)
    );

  sync_gray_counter #(.ASIZE(ASIZE))
    sync_rd_ptr (
      .a_clk (a_clk),
      .a_rst_n (a_rst_n),
      .a_gray (a_rd_ptr_gray),
      .b_gray (a_rd_ptr_gray_sync)
    );

  // Write side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_full_flag <= 0;
      a_afull_flag <= 0;
    end else if (a_winc && !a_full_flag) begin
      a_ram[a_wr_ptr] <= a_wdata;
      a_wr_ptr <= a_wr_ptr + 1;
      a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
    end
  end

  // Read side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else if (a_rinc && !a_empty_flag) begin
      a_rd_ptr <= a_rd_ptr + 1;
      a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
    end
  end

  // Data output
  assign a_rdata = a_ram[a_rd_ptr];

  // Full and almost full flags
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_flag <= 0;
      a_afull_flag <= 0;
    end else begin
      a_full_flag <= (a_wr_ptr_gray_sync == bin_to_gray(a_rd_ptr + 1));
      a_afull_flag <= (a_wr_ptr_gray_sync == bin_to_gray(a_rd_ptr + (2**ASIZE - 1)));
    end
  end

  // Empty and almost empty flags
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else begin
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray_sync);
      a_aempty_flag <= (a_wr_ptr_gray == bin_to_gray(a_rd_ptr + 1));
    end
  end

endmodule

module sync_gray_counter
  #(
    parameter ASIZE = 4
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire [ASIZE-1:0]  a_gray,
       output reg [ASIZE-1:0]  b_gray
       );

  reg [ASIZE-1:0] b_gray_reg1;
  reg [ASIZE-1:0] b_gray_reg2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_gray_reg1 <= 0;
      b_gray_reg2 <= 0;
      b_gray <= 0;
    end else begin
      b_gray_reg1 <= a_gray;
      b_gray_reg2 <= b_gray_reg1;
      b_gray <= b_gray_reg2;
    end
  end

endmodule
