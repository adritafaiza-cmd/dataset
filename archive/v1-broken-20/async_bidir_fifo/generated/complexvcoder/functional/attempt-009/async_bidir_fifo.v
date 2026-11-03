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

  // Internal signals
  wire [DSIZE-1:0] a_fifo_wdata;
  wire [DSIZE-1:0] a_fifo_rdata;
  wire a_fifo_full;
  wire a_fifo_afull;
  wire a_fifo_empty;
  wire a_fifo_aempty;
  wire b_fifo_wdata;
  wire [DSIZE-1:0] b_fifo_rdata;
  wire b_fifo_full;
  wire b_fifo_afull;
  wire b_fifo_empty;
  wire b_fifo_aempty;
  wire a_fifo_dir;
  wire b_fifo_dir;

  // FIFO cores
  fifo_core a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc & a_fifo_dir),
    .wdata(a_wdata),
    .rinc(a_rinc & ~a_fifo_dir),
    .rdata(a_fifo_rdata),
    .full(a_fifo_full),
    .afull(a_fifo_afull),
    .empty(a_fifo_empty),
    .aempty(a_fifo_aempty)
  );

  fifo_core b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc & b_fifo_dir),
    .wdata(b_wdata),
    .rinc(b_rinc & ~b_fifo_dir),
    .rdata(b_fifo_rdata),
    .full(b_fifo_full),
    .afull(b_fifo_afull),
    .empty(b_fifo_empty),
    .aempty(b_fifo_aempty)
  );

  // Direction signals
  assign a_fifo_dir = a_dir;
  assign b_fifo_dir = b_dir;

  // Bidirectional connection
  assign a_fifo_wdata = b_fifo_rdata;
  assign b_fifo_wdata = a_fifo_rdata;

  // Assign outputs
  assign a_rdata = a_fifo_rdata;
  assign b_rdata = b_fifo_rdata;

  assign a_full = a_fifo_full;
  assign a_afull = a_fifo_afull;
  assign a_empty = a_fifo_empty;
  assign a_aempty = a_fifo_aempty;

  assign b_full = b_fifo_full;
  assign b_afull = b_fifo_afull;
  assign b_empty = b_fifo_empty;
  assign b_aempty = b_fifo_aempty;

endmodule
