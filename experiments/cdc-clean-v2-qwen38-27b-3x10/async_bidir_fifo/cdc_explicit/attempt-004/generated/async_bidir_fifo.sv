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
  localparam AWIDTH = ASIZE + 1;
  localparam AFULL_THRESH = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Internal FIFO for A->B direction
  reg [DSIZE-1:0] fifo_ab [0:DEPTH-1];
  reg [AWIDTH-1:0] wr_ptr_ab;
  reg [AWIDTH-1:0] rd_ptr_ab;

  // Internal FIFO for B->A direction
  reg [DSIZE-1:0] fifo_ba [0:DEPTH-1];
  reg [AWIDTH-1:0] wr_ptr_ba;
  reg [AWIDTH-1:0] rd_ptr_ba;

  // Synchronized pointers for A->B FIFO
  // Write pointer (A side) synchronized to B side
  reg [AWIDTH-1:0] wr_ptr_ab_sync1, wr_ptr_ab_sync2;
  // Read pointer (B side) synchronized to A side
  reg [AWIDTH-1:0] rd_ptr_ab_sync1, rd_ptr_ab_sync2;

  // Synchronized pointers for B->A FIFO
  // Write pointer (B side) synchronized to A side
  reg [AWIDTH-1:0] wr_ptr_ba_sync1, wr_ptr_ba_sync2;
  // Read pointer (A side) synchronized to B side
  reg [AWIDTH-1:0] rd_ptr_ba_sync1, rd_ptr_ba_sync2;

  // Synchronized direction signals
  // a_dir synchronized to B side
  reg a_dir_sync1, a_dir_sync2;
  // b_dir synchronized to A side
  reg b_dir_sync1, b_dir_sync2;

  // Synchronized write enable signals
  // a_winc (when a_dir=1) synchronized to B side
  reg a_winc_sync1, a_winc_sync2;
  // b_winc (when b_dir=1) synchronized to A side
  reg b_winc_sync1, b_winc_sync2;

  // Synchronized read enable signals
  // a_rinc (when a_dir=0) synchronized to B side
  reg a_rinc_sync1, a_rinc_sync2;
  // b_rinc (when b_dir=0) synchronized to A side
  reg b_rinc_sync1, b_rinc_sync2;

  // Synchronized data for A->B
  reg [DSIZE-1:0] a_wdata_sync1, a_wdata_sync2;

  // Synchronized data for B->A
  reg [DSIZE-1:0] b_wdata_sync1, b_wdata_sync2;

  // Synchronized reset signals
  reg a_rst_n_sync1, a_rst_n_sync2;
  reg b_rst_n_sync1, b_rst_n_sync2;

  // A side logic
  wire a_write = a_dir & a_winc;
  wire a_read  = ~a_dir & a_rinc;

  // B side logic
  wire b_write = b_dir & b_winc;
  wire b_read  = ~b_dir & b_rinc;

  // A->B FIFO: Write on A side, Read on B side
  // B->A FIFO: Write on B side, Read on A side

  // A side: Write to A->B FIFO, Read from B->A FIFO
  // B side: Read from A->B FIFO, Write to B->A FIFO

  // A side write to A->B FIFO
  wire a_wr_ab = a_write;
  // A side read from B->A FIFO
  wire a_rd_ba = a_read;

  // B side read from A->B FIFO
  wire b_rd_ab = b_read;
  // B side write to B->A FIFO
  wire b_wr_ba = b_write;

  // A->B FIFO full/empty
  wire [AWIDTH-1:0] ab_wr_ptr_sync = wr_ptr_ab_sync2;
  wire [AWIDTH-1:0] ab_rd_ptr_sync = rd_ptr_ab_sync2;
  wire [AWIDTH-1:0] ab_diff = ab_wr_ptr_sync - ab_rd_ptr_sync;
  wire ab_full = (ab_diff == DEPTH);
  wire ab_afull = (ab_diff >= AFULL_THRESH);
  wire ab_empty = (ab_diff == 0);
  wire ab_aempty = (ab_diff <= AEMPTY_THRESH);

  // B->A FIFO full/empty
  wire [AWIDTH-1:0] ba_wr_ptr_sync = wr_ptr_ba_sync2;
  wire [AWIDTH-1:0] ba_rd_ptr_sync = rd_ptr_ba_sync2;
  wire [AWIDTH-1:0] ba_diff = ba_wr_ptr_sync - ba_rd_ptr_sync;
  wire ba_full = (ba_diff == DEPTH);
  wire ba_afull = (ba_diff >= AFULL_THRESH);
  wire ba_empty = (ba_diff == 0);
  wire ba_aempty = (ba_diff <= AEMPTY_THRESH);

  // A side outputs
  assign a_full = ba_full;
  assign a_afull = ba_afull;
  assign a_empty = ba_empty;
  assign a_aempty = ba_aempty;

  // B side outputs
  assign b_full = ab_full;
  assign b_afull = ab_afull;
  assign b_empty = ab_empty;
  assign b_aempty = ab_aempty;

  // A side read data from B->A FIFO
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else if (a_rd_ba && !ba_empty)
      a_rdata_reg <= fifo_ba[rd_ptr_ba[ASIZE-1:0]];
  end
  assign a_rdata = a_rdata_reg;

  // B side read data from A->B FIFO
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else if (b_rd_ab && !ab_empty)
      b_rdata_reg <= fifo_ab[rd_ptr_ab[ASIZE-1:0]];
  end
  assign b_rdata = b_rdata_reg;

  // A->B FIFO write (A side)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wr_ptr_ab <= {AWIDTH{1'b0}};
    end else if (a_wr_ab && !ab_full) begin
      fifo_ab[wr_ptr_ab[ASIZE-1:0]] <= a_wdata;
      wr_ptr_ab <= wr_ptr_ab + 1'b1;
    end
  end

  // A->B FIFO read (B side)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      rd_ptr_ab <= {AWIDTH{1'b0}};
    end else if (b_rd_ab && !ab_empty) begin
      rd_ptr_ab <= rd_ptr_ab + 1'b1;
    end
  end

  // B->A FIFO write (B side)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wr_ptr_ba <= {AWIDTH{1'b0}};
    end else if (b_wr_ba && !ba_full) begin
      fifo_ba[wr_ptr_ba[ASIZE-1:0]] <= b_wdata;
      wr_ptr_ba <= wr_ptr_ba + 1'b1;
    end
  end

  // B->A FIFO read (A side)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      rd_ptr_ba <= {AWIDTH{1'b0}};
    end else if (a_rd_ba && !ba_empty) begin
      rd_ptr_ba <= rd_ptr_ba + 1'b1;
    end
  end

  // Synchronize A->B write pointer to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wr_ptr_ab_sync1 <= {AWIDTH{1'b0}};
      wr_ptr_ab_sync2 <= {AWIDTH{1'b0}};
    end else begin
      wr_ptr_ab_sync1 <= wr_ptr_ab;
      wr_ptr_ab_sync2 <= wr_ptr_ab_sync1;
    end
  end

  // Synchronize A->B read pointer to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      rd_ptr_ab_sync1 <= {AWIDTH{1'b0}};
      rd_ptr_ab_sync2 <= {AWIDTH{1'b0}};
    end else begin
      rd_ptr_ab_sync1 <= rd_ptr_ab;
      rd_ptr_ab_sync2 <= rd_ptr_ab_sync1;
    end
  end

  // Synchronize B->A write pointer to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wr_ptr_ba_sync1 <= {AWIDTH{1'b0}};
      wr_ptr_ba_sync2 <= {AWIDTH{1'b0}};
    end else begin
      wr_ptr_ba_sync1 <= wr_ptr_ba;
      wr_ptr_ba_sync2 <= wr_ptr_ba_sync1;
    end
  end

  // Synchronize B->A read pointer to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      rd_ptr_ba_sync1 <= {AWIDTH{1'b0}};
      rd_ptr_ba_sync2 <= {AWIDTH{1'b0}};
    end else begin
      rd_ptr_ba_sync1 <= rd_ptr_ba;
      rd_ptr_ba_sync2 <= rd_ptr_ba_sync1;
    end
  end

  // Synchronize a_dir to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_dir_sync1 <= 1'b0;
      a_dir_sync2 <= 1'b0;
    end else begin
      a_dir_sync1 <= a_dir;
      a_dir_sync2 <= a_dir_sync1;
    end
  end

  // Synchronize b_dir to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_dir_sync1 <= 1'b0;
      b_dir_sync2 <= 1'b0;
    end else begin
      b_dir_sync1 <= b_dir;
      b_dir_sync2 <= b_dir_sync1;
    end
  end

  // Synchronize a_winc to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_winc_sync1 <= 1'b0;
      a_winc_sync2 <= 1'b0;
    end else begin
      a_winc_sync1 <= a_winc;
      a_winc_sync2 <= a_winc_sync1;
    end
  end

  // Synchronize b_winc to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_winc_sync1 <= 1'b0;
      b_winc_sync2 <= 1'b0;
    end else begin
      b_winc_sync1 <= b_winc;
      b_winc_sync2 <= b_winc_sync1;
    end
  end

  // Synchronize a_rinc to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rinc_sync1 <= 1'b0;
      a_rinc_sync2 <= 1'b0;
    end else begin
      a_rinc_sync1 <= a_rinc;
      a_rinc_sync2 <= a_rinc_sync1;
    end
  end

  // Synchronize b_rinc to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rinc_sync1 <= 1'b0;
      b_rinc_sync2 <= 1'b0;
    end else begin
      b_rinc_sync1 <= b_rinc;
      b_rinc_sync2 <= b_rinc_sync1;
    end
  end

  // Synchronize a_wdata to B side
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wdata_sync1 <= {DSIZE{1'b0}};
      a_wdata_sync2 <= {DSIZE{1'b0}};
    end else begin
      a_wdata_sync1 <= a_wdata;
      a_wdata_sync2 <= a_wdata_sync1;
    end
  end

  // Synchronize b_wdata to A side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wdata_sync1 <= {DSIZE{1'b0}};
      b_wdata_sync2 <= {DSIZE{1'b0}};
    end else begin
      b_wdata_sync1 <= b_wdata;
      b_wdata_sync2 <= b_wdata_sync1;
    end
  end

  // Synchronize a_rst_n to B side
  always @(posedge b_clk) begin
    a_rst_n_sync1 <= a_rst_n;
    a_rst_n_sync2 <= a_rst_n_sync1;
  end

  // Synchronize b_rst_n to A side
  always @(posedge a_clk) begin
    b_rst_n_sync1 <= b_rst_n;
    b_rst_n_sync2 <= b_rst_n_sync1;
  end

endmodule
