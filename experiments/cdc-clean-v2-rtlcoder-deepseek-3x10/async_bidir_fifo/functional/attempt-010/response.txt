Sure, here is the Verilog code for a bidirectional asynchronous FIFO:

```
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

  // Local parameters
  localparam FSIZE = 1 << ASIZE;

  // Internal signals
  reg [DSIZE-1:0] fifo [FSIZE-1:0];
  reg [ASIZE-1:0] a_head;
  reg [ASIZE-1:0] a_tail;
  reg [ASIZE-1:0] b_head;
  reg [ASIZE-1:0] b_tail;
  reg [ASIZE-1:0] a_next_head;
  reg [ASIZE-1:0] b_next_head;
  reg [ASIZE-1:0] a_next_tail;
  reg [ASIZE-1:0] b_next_tail;
  reg [ASIZE-1:0] a_next_next_head;
  reg [ASIZE-1:0] b_next_next_head;
  reg [ASIZE-1:0] a_next_next_tail;
  reg [ASIZE-1:0] b_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [ASIZE-1:0] a_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [ASIZE-1:0] b_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next