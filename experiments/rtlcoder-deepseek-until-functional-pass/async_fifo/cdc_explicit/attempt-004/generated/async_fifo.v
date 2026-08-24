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
  reg [ASIZE:0] count;

  // Define the write logic
  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      wptr <= 0;
      count <= 0;
    end else if (winc && ~wfull) begin
      fifo[wptr] <= wdata;
      wptr <= wptr + 1;
      count <= count + 1;
    end
  end

  assign wfull = (count == (2**ASIZE));
  assign awfull = (count == (2**ASIZE) - 1);

  // Define the read logic
  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      rptr <= 0;
      count <= 0;
    end else if (rinc && ~rempty) begin
      rdata <= fifo[rptr];
      rptr <= rptr + 1;
      count <= count - 1;
    end
  end

  assign rempty = (count == 0);
  assign arempty = (count == 1);

  // Define the fallthrough logic
  generate
    if (FALLTHROUGH == "TRUE") begin
      always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
          rdata <= 0;
        end else if (rinc && ~rempty) begin
          rdata <= fifo[rptr];
        end
      end
    end
  endgenerate


endmodule
