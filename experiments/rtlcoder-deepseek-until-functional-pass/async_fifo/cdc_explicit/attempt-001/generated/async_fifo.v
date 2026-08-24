module async_fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
)(
  input  wire             wclk,
  input  wire             wrst_n,
  input  wire             winc,
  input  wire [DSIZE-1:0] wdata,
  output wire             wfull,
  output wire             awfull,

  input  wire             rclk,
  input  wire             rrst_n,
  input  wire             rinc,
  output wire [DSIZE-1:0] rdata,
  output wire             rempty,
  output wire             arempty
);

  // Define the FIFO
  reg [DSIZE-1:0] fifo [0:(2**ASIZE)-1];
  reg [ASIZE-1:0] wptr;
  reg [ASIZE-1:0] rptr;
  reg [ASIZE-1:0] wptr_next;
  reg [ASIZE-1:0] rptr_next;
  reg [ASIZE-1:0] wptr_next_next;
  reg [ASIZE-1:0] rptr_next_next;
  reg [ASIZE-1:0] wptr_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] rptr_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
  reg [ASIZE-1:0] wptr_next_next_next_next_
