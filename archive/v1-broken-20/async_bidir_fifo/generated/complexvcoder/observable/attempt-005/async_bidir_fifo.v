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

  // FIFO cores
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) a_fifo (
    .clk(a_clk), .rst_n(a_rst_n), .winc(a_winc), .wdata(a_wdata), .rinc(a_rinc), 
    .rdata(a_rdata), .full(a_full), .afull(a_afull), .empty(a_empty), .aempty(a_aempty)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) b_fifo (
    .clk(b_clk), .rst_n(b_rst_n), .winc(b_winc), .wdata(b_wdata), .rinc(b_rinc), 
    .rdata(b_rdata), .full(b_full), .afull(b_afull), .empty(b_empty), .aempty(b_aempty)
  );

  // Clock domain crossing for a_to_b
  wire [DSIZE-1:0] a_to_b_rdata;
  wire a_to_b_full, a_to_b_empty, a_to_b_aempty;

  clock_domain_crossing #(.DSIZE(DSIZE), .FALLTHROUGH(FALLTHROUGH)) a_to_b (
    .clk_a(a_clk), .clk_b(b_clk), .rst_n_a(a_rst_n), .rst_n_b(b_rst_n), 
    .winc_a(a_winc), .wdata_a(a_wdata), .rinc_a(a_rinc), 
    .rdata_b(a_to_b_rdata), .full_b(a_to_b_full), .empty_b(a_to_b_empty), .aempty_b(a_to_b_aempty),
    .dir_a(a_dir), .dir_b(b_dir)
  );

  // Clock domain crossing for b_to_a
  wire [DSIZE-1:0] b_to_a_rdata;
  wire b_to_a_full, b_to_a_empty, b_to_a_aempty;

  clock_domain_crossing #(.DSIZE(DSIZE), .FALLTHROUGH(FALLTHROUGH)) b_to_a (
    .clk_a(a_clk), .clk_b(b_clk), .rst_n_a(a_rst_n), .rst_n_b(b_rst_n), 
    .winc_b(b_winc), .wdata_b(b_wdata), .rinc_b(b_rinc), 
    .rdata_a(b_to_a_rdata), .full_a(b_to_a_full), .empty_a(b_to_a_empty), .aempty_a(b_to_a_aempty),
    .dir_a(a_dir), .dir_b(b_dir)
  );

  // Connect a_to_b to b_fifo
  assign b_fifo.wdata = a_to_b_rdata;
  assign b_fifo.winc = a_to_b_full;

  // Connect b_to_a to a_fifo
  assign a_fifo.wdata = b_to_a_rdata;
  assign a_fifo.winc = b_to_a_full;

endmodule
