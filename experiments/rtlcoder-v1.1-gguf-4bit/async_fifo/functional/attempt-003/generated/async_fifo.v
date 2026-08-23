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

  // FIFO implementation
  reg [DSIZE-1:0] fifo [0:(2**ASIZE)-1];
  reg [ASIZE-1:0] head = 0;
  reg [ASIZE-1:0] tail = 0;
  reg [ASIZE-1:0] count = 0;

  // Write domain
  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      head <= 0;
      tail <= 0;
      count <= 0;
      wfull <= 0;
    end else if (winc && ~wfull) begin
      fifo[head] <= wdata;
      head <= head + 1;
      count <= count + 1;
      wfull <= (count == 2**ASIZE);
    end
  end

  // Read domain
  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      head <= 0;
      tail <= 0;
      count <= 0;
      rempty <= 1;
    end else if (rinc && ~rempty) begin
      rdata <= fifo[tail];
      tail <= tail + 1;
      count <= count - 1;
      rempty <= (count == 1);
    end
  end

  // Write full and read empty indicators
  assign awfull = wfull;
  assign arempty = rempty;

  // FALLTHROUGH implementation
  assign rdata = (FALLTHROUGH == "TRUE") ? fifo[tail] : rdata;


endmodule
