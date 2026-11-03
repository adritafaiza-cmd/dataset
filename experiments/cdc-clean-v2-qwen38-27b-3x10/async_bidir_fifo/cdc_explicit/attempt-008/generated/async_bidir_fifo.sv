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

  localparam DEPTH = 1 << ASIZE;
  localparam PTR_W = ASIZE + 1;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Internal FIFO for A->B direction
  reg [DSIZE-1:0] fifo_ab [0:DEPTH-1];
  reg [PTR_W-1:0] ab_wr_ptr;
  reg [PTR_W-1:0] ab_rd_ptr;

  // Internal FIFO for B->A direction
  reg [DSIZE-1:0] fifo_ba [0:DEPTH-1];
  reg [PTR_W-1:0] ba_wr_ptr;
  reg [PTR_W-1:0] ba_rd_ptr;

  // Synchronized pointers for A->B FIFO
  reg [PTR_W-1:0] ab_wr_ptr_sync1, ab_wr_ptr_sync2;
  reg [PTR_W-1:0] ab_rd_ptr_sync1, ab_rd_ptr_sync2;

  // Synchronized pointers for B->A FIFO
  reg [PTR_W-1:0] ba_wr_ptr_sync1, ba_wr_ptr_sync2;
  reg [PTR_W-1:0] ba_rd_ptr_sync1, ba_rd_ptr_sync2;

  // A-side: write to A->B FIFO, read from B->A FIFO
  wire a_write_ab = a_dir & a_winc & ~a_full;
  wire a_read_ba  = ~a_dir & a_rinc & ~a_empty;

  // B-side: write to B->A FIFO, read from A->B FIFO
  wire b_write_ba = b_dir & b_winc & ~b_full;
  wire b_read_ab  = ~b_dir & b_rinc & ~b_empty;

  // A->B FIFO write (A clock domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      ab_wr_ptr <= {PTR_W{1'b0}};
    else if (a_write_ab)
      ab_wr_ptr <= ab_wr_ptr + 1'b1;
  end

  // A->B FIFO read (B clock domain)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      ab_rd_ptr <= {PTR_W{1'b0}};
    else if (b_read_ab)
      ab_rd_ptr <= ab_rd_ptr + 1'b1;
  end

  // B->A FIFO write (B clock domain)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      ba_wr_ptr <= {PTR_W{1'b0}};
    else if (b_write_ba)
      ba_wr_ptr <= ba_wr_ptr + 1'b1;
  end

  // B->A FIFO read (A clock domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      ba_rd_ptr <= {PTR_W{1'b0}};
    else if (a_read_ba)
      ba_rd_ptr <= ba_rd_ptr + 1'b1;
  end

  // Data storage: A->B FIFO (written in A domain, read in B domain)
  always @(posedge a_clk) begin
    if (a_write_ab)
      fifo_ab[ab_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // Data storage: B->A FIFO (written in B domain, read in A domain)
  always @(posedge b_clk) begin
    if (b_write_ba)
      fifo_ba[ba_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // Synchronize A->B write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ab_wr_ptr_sync1 <= {PTR_W{1'b0}};
      ab_wr_ptr_sync2 <= {PTR_W{1'b0}};
    end else begin
      ab_wr_ptr_sync1 <= ab_wr_ptr;
      ab_wr_ptr_sync2 <= ab_wr_ptr_sync1;
    end
  end

  // Synchronize A->B read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ab_rd_ptr_sync1 <= {PTR_W{1'b0}};
      ab_rd_ptr_sync2 <= {PTR_W{1'b0}};
    end else begin
      ab_rd_ptr_sync1 <= ab_rd_ptr;
      ab_rd_ptr_sync2 <= ab_rd_ptr_sync1;
    end
  end

  // Synchronize B->A write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ba_wr_ptr_sync1 <= {PTR_W{1'b0}};
      ba_wr_ptr_sync2 <= {PTR_W{1'b0}};
    end else begin
      ba_wr_ptr_sync1 <= ba_wr_ptr;
      ba_wr_ptr_sync2 <= ba_wr_ptr_sync1;
    end
  end

  // Synchronize B->A read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ba_rd_ptr_sync1 <= {PTR_W{1'b0}};
      ba_rd_ptr_sync2 <= {PTR_W{1'b0}};
    end else begin
      ba_rd_ptr_sync1 <= ba_rd_ptr;
      ba_rd_ptr_sync2 <= ba_rd_ptr_sync1;
    end
  end

  // A->B FIFO status in A domain (using synchronized read pointer)
  wire [PTR_W-1:0] ab_wr_ptr_a = ab_wr_ptr;
  wire [PTR_W-1:0] ab_rd_ptr_a = ab_rd_ptr_sync2;
  wire [PTR_W-1:0] ab_count_a  = ab_wr_ptr_a - ab_rd_ptr_a;

  // A->B FIFO status in B domain (using synchronized write pointer)
  wire [PTR_W-1:0] ab_wr_ptr_b = ab_wr_ptr_sync2;
  wire [PTR_W-1:0] ab_rd_ptr_b = ab_rd_ptr;
  wire [PTR_W-1:0] ab_count_b  = ab_wr_ptr_b - ab_rd_ptr_b;

  // B->A FIFO status in A domain (using synchronized write pointer)
  wire [PTR_W-1:0] ba_wr_ptr_a = ba_wr_ptr_sync2;
  wire [PTR_W-1:0] ba_rd_ptr_a = ba_rd_ptr;
  wire [PTR_W-1:0] ba_count_a  = ba_wr_ptr_a - ba_rd_ptr_a;

  // B->A FIFO status in B domain (using synchronized read pointer)
  wire [PTR_W-1:0] ba_wr_ptr_b = ba_wr_ptr;
  wire [PTR_W-1:0] ba_rd_ptr_b = ba_rd_ptr_sync2;
  wire [PTR_W-1:0] ba_count_b  = ba_wr_ptr_b - ba_rd_ptr_b;

  // A-side flags
  // a_full: A->B FIFO is full (A is writer)
  assign a_full  = (ab_count_a == DEPTH);
  assign a_afull = (ab_count_a >= AFULL_THRESH);
  // a_empty: B->A FIFO is empty (A is reader)
  assign a_empty  = (ba_count_a == 0);
  assign a_aempty = (ba_count_a <= AEMPTY_THRESH);

  // B-side flags
  // b_full: B->A FIFO is full (B is writer)
  assign b_full  = (ba_count_b == DEPTH);
  assign b_afull = (ba_count_b >= AFULL_THRESH);
  // b_empty: A->B FIFO is empty (B is reader)
  assign b_empty  = (ab_count_b == 0);
  assign b_aempty = (ab_count_b <= AEMPTY_THRESH);

  // Read data
  // A reads from B->A FIFO
  assign a_rdata = fifo_ba[ba_rd_ptr[ASIZE-1:0]];
  // B reads from A->B FIFO
  assign b_rdata = fifo_ab[ab_rd_ptr[ASIZE-1:0]];

endmodule
