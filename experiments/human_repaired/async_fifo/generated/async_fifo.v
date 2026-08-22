// Functionally correct async FIFO with intentional CDC unsafety:
// binary pointers and occupancy are used directly across clocks.
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

  localparam DEPTH = (1 << ASIZE);

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0]   wptr;
  reg [ASIZE:0]   rptr;
  reg [DSIZE-1:0] rdata_q;
  reg [DSIZE-1:0] rdata_hold;

  wire [ASIZE:0] count = wptr - rptr;
  wire [ASIZE-1:0] raddr = rptr[ASIZE-1:0];
  wire [ASIZE-1:0] waddr = wptr[ASIZE-1:0];

  assign wfull   = (count == DEPTH[ASIZE:0]);
  assign rempty  = (count == { (ASIZE+1){1'b0} });
  assign awfull  = (count == (DEPTH[ASIZE:0] - 1'b1));
  assign arempty = (count == {{ASIZE{1'b0}}, 1'b1});

  // Hold the last valid word so a late read sample after rempty
  // still sees the popped data. Combinational when not empty.
  always @(*) begin
    if (!rempty)
      rdata_hold = mem[raddr];
  end

  assign rdata = (FALLTHROUGH == "TRUE") ? rdata_hold : rdata_q;

  always @(posedge wclk)
    if (winc && !wfull)
      mem[waddr] <= wdata;

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
      wptr <= { (ASIZE+1){1'b0} };
    else if (winc && !wfull)
      wptr <= wptr + 1'b1;
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr    <= { (ASIZE+1){1'b0} };
      rdata_q <= {DSIZE{1'b0}};
    end else if (rinc && !rempty) begin
      rdata_q <= mem[raddr];
      rptr    <= rptr + 1'b1;
    end
  end

endmodule
