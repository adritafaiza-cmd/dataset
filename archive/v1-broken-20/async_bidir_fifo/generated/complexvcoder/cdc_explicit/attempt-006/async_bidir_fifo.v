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
  logic [DSIZE-1:0] a_fifo_rdata;
  logic a_fifo_full;
  logic a_fifo_afull;
  logic a_fifo_empty;
  logic a_fifo_aempty;
  logic b_fifo_rdata;
  logic b_fifo_full;
  logic b_fifo_afull;
  logic b_fifo_empty;
  logic b_fifo_aempty;

  // FIFO instances
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_fifo_rdata),
    .full(a_fifo_full),
    .afull(a_fifo_afull),
    .empty(a_fifo_empty),
    .aempty(a_fifo_aempty)
  );

  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_fifo_rdata),
    .full(b_fifo_full),
    .afull(b_fifo_afull),
    .empty(b_fifo_empty),
    .aempty(b_fifo_aempty)
  );

  // Direction select logic
  assign a_rdata = a_dir ? a_fifo_rdata : b_fifo_rdata;
  assign b_rdata = a_dir ? b_fifo_rdata : a_fifo_rdata;

  assign a_full = a_dir ? a_fifo_full : b_fifo_full;
  assign a_afull = a_dir ? a_fifo_afull : b_fifo_afull;
  assign a_empty = a_dir ? a_fifo_empty : b_fifo_empty;
  assign a_aempty = a_dir ? a_fifo_aempty : b_fifo_aempty;

  assign b_full = a_dir ? b_fifo_full : a_fifo_full;
  assign b_afull = a_dir ? b_fifo_afull : a_fifo_afull;
  assign b_empty = a_dir ? b_fifo_empty : a_fifo_empty;
  assign b_aempty = a_dir ? b_fifo_aempty : a_fifo_aempty;

endmodule
