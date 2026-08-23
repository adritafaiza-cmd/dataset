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

  // Write domain
  reg [DSIZE-1:0] fifo [0:(2**ASIZE)-1];
  reg [ASIZE-1:0] wrptr = 0;
  reg [ASIZE-1:0] rdptr = 0;
  reg [ASIZE-1:0] count = 0;
  reg [ASIZE-1:0] next_wrptr;
  reg [ASIZE-1:0] next_rdptr;
  reg [ASIZE-1:0] next_count;
  reg [ASIZE-1:0] next_count_wr;
  reg [ASIZE-1:0] next_count_rd;
  reg [ASIZE-1:0] next_count_rd_r;
  reg [ASIZE-1:0] next_count_rd_w;
  reg [ASIZE-1:0] next_count_rd_r_r;
  reg [ASIZE-1:0] next_count_rd_w_r;
  reg [ASIZE-1:0] next_count_rd_w_r_r;
  reg [ASIZE-1:0] next_count_rd_w_r_r;
  reg [ASIZE-1:0] next_count_rd_w_r_r_r;
  reg [ASIZE-1:0] next_count_rd_w_r_d;
  reg [ASIZE-1:0] next_count_rd_w_r_d_r;
  wire [ASIZE-1:0] next_count_rd_w_r_d_r;

  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      wrptr <= 0;
      rdptr <= 0;
      count <= 0;
    end else if (winc && ~wfull) begin
      fifo[wrptr] <= wdata;
      next_wrptr <= wrptr + 1;
      next_count <= count + 1;
      next_count_wr <= next_count;
    end else begin
      next_wrptr <= wrptr;
      next_count_wr <= count;
    end
  end

  // Read domain
  reg [DSIZE-1:0] rdata_reg;
  reg [ASIZE-1:0] rdptr_reg;
  reg [ASIZE-1:0] count_reg;
  reg [ASIZE-1:0] next_count_rd;
  reg [ASIZE-1:0] next_count_rd_r;
  reg [ASIZE-1:0] next_count_rd_w;
  reg [ASIZE-1:0] next_count_rd_w_r;
  reg [ASIZE-1:0] next_count_rd_w_r_r;
  reg [ASIZE-1:0] next_count_rd_w_r_d;
  reg [ASIZE-1:0] next_count_rd_w_r_d_r;
  wire [ASIZE-1:0] next_count_rd_w_r_d_r_r;

  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      rdptr_reg <= 0;
      count_reg <= 0;
    end else if (rinc && ~rempty) begin
      rdata_reg <= fifo[rdptr_reg];
      next_count_rd <= count_reg - 1;
      next_count_rd_r <= next_count_rd;
      next_count_rd_w_r_d_r_r <= next_count_rd_w_r_d_r;
      next_count_rd_w_r_d_r_r_r <= next_count_rd_w_r_d_r_r;
      next_count_rd_w_r_d_r_r_d_r <= next_count_rd_w_r_d_r_r_d_r;
      next_count_rd_w_r_d_r_r_d_r_r_d_r_r_d_r_r_w <= next_count_rd_w_r_d_r_r_d_r_r_d_r_r_d_w;
      next_count_rd_w_r_d_r_r_d_r_r_d_r_r_d_r_r_d_w <= next_count_rd_w_r_d_r_r_d_r_r_d_w;
      next_count_rd_w_r_d_r_r_d_r_r_d_w_r <= next_count_rd_w_r_d_r_r_d_w;
      next_rdptr <= rdptr_reg + 1;
      next_count_rd_w_r_d_r_r_d_w_r_d_r_w <= next_count_rd_w_r_d_r_r_d_w;
    end else begin
      next_count_rd <= count_reg;
      next_count_rd_w_r_d_r_r_d_w_r_d_r_w <= count_reg;
      next_rdptr <= rdptr_reg;
    end
  end

  // Write domain -> Read domain
  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_w <= 0;
    end else if (winc && ~wfull) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_w <= count;
    end
  end

  // Read domain -> Write domain
  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_d_r_w_r <= 0;
    end else if (rinc && ~rempty) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_d_r_w_r <= count_reg - 1;
    end
  end

  // Write domain -> Read domain
  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_d_r_w_r_d_r_w <= 0;
    end else if (winc && ~wfull) begin
      next_count_rd_w_r_d_r_r_d_w_r_d_r_d_w_r_d_r_w_d_r_w <= wrptr;
  end
  end

  // Read domain -> Write domain
  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      next_count_rd_w_r_d_r_w_r_d_r_w_d_r_w_r_d_w <= 0;
    end else if (rinc && ~rempty) begin
      next_count_rd_w_r_d_r_w_r_d_r_w_d_r_w_r
