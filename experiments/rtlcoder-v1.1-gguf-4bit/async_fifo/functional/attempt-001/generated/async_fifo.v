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

  // Internal state
  reg [ASIZE-1:0] wrptr;
  reg [ASIZE-1:0] rdptr;
  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] count;
  reg [ASIZE-1:0] next_count;
  reg [DSIZE-1:0] next_mem [2**ASIZE-1:0];
  reg [DSIZE-1:0] next_rdata;
  reg [ASIZE-1:0] next_wrptr;
  reg [ASIZE-1:0] next_rdptr;
  reg wfull_reg;
  reg rempty_reg;

  // Write domain
  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      wrptr <= 0;
      count <= 0;
    end else if (winc && ~wfull_reg) begin
      mem[wrptr] <= wdata;
      next_wrptr <= wrptr + 1;
      next_count <= count + 1;
    end else begin
      next_wrptr <= wrptr;
      next_count <= count;
    end
  end

  // Read domain
  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      rdptr <= 0;
      count <= 0;
      rempty_reg <= 1;
    end else if (rinc && ~rempty_reg) begin
      next_rdptr <= rdptr + 1;
      next_count <= count - 1;
    end else begin
      next_rdptr <= rdptr;
      next_count <= count;
    end
  end

  // Update state
  always @(*) begin
    wrptr <= next_wrptr;
    rdptr <= next_rdptr;
    count <= next_count;
    rempty_reg <= (count == 0);
    wfull_reg <= (count == 2**ASIZE);
  end

  // Output signals
  assign wfull = wfull_reg;
  assign awfull = (count == 2**ASIZE-1);
  assign rempty = rempty_reg;
  assign arempty = (count == 1);
  assign rdata = (FALLTHROUGH == "TRUE") ? mem[rdptr] : next_rdata;


endmodule
