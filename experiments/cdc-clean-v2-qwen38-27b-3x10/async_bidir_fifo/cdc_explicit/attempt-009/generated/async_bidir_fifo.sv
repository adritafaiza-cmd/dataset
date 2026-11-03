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
  reg [AWIDTH-1:0] wr_ptr_ab_a;
  reg [AWIDTH-1:0] rd_ptr_ab_a;
  reg [AWIDTH-1:0] wr_ptr_ab_b;
  reg [AWIDTH-1:0] rd_ptr_ab_b;

  // Internal FIFO for B->A direction
  reg [DSIZE-1:0] fifo_ba [0:DEPTH-1];
  reg [AWIDTH-1:0] wr_ptr_ba_b;
  reg [AWIDTH-1:0] rd_ptr_ba_b;
  reg [AWIDTH-1:0] wr_ptr_ba_a;
  reg [AWIDTH-1:0] rd_ptr_ba_a;

  // Synchronization registers for A->B write pointer (to B domain)
  reg [AWIDTH-1:0] wr_ptr_ab_b_sync1;
  reg [AWIDTH-1:0] wr_ptr_ab_b_sync2;

  // Synchronization registers for A->B read pointer (to A domain)
  reg [AWIDTH-1:0] rd_ptr_ab_a_sync1;
  reg [AWIDTH-1:0] rd_ptr_ab_a_sync2;

  // Synchronization registers for B->A write pointer (to A domain)
  reg [AWIDTH-1:0] wr_ptr_ba_a_sync1;
  reg [AWIDTH-1:0] wr_ptr_ba_a_sync2;

  // Synchronization registers for B->A read pointer (to B domain)
  reg [AWIDTH-1:0] rd_ptr_ba_b_sync1;
  reg [AWIDTH-1:0] rd_ptr_ba_b_sync2;

  // Data synchronization for A->B (two stages in B domain)
  reg [DSIZE-1:0] data_ab_b_sync1;
  reg [DSIZE-1:0] data_ab_b_sync2;
  reg [DSIZE-1:0] data_ab_b_valid1;
  reg [DSIZE-1:0] data_ab_b_valid2;

  // Data synchronization for B->A (two stages in A domain)
  reg [DSIZE-1:0] data_ba_a_sync1;
  reg [DSIZE-1:0] data_ba_a_sync2;
  reg [DSIZE-1:0] data_ba_a_valid1;
  reg [DSIZE-1:0] data_ba_a_valid2;

  // Direction change tracking
  reg a_dir_reg;
  reg b_dir_reg;

  // A domain: A->B write logic
  wire a_write_ab = a_dir & a_winc;
  wire a_read_ab = ~a_dir & a_rinc;

  // B domain: A->B read logic
  wire b_read_ab = ~b_dir & b_rinc;
  wire b_write_ab = b_dir & b_winc;

  // A domain: B->A read logic
  wire a_read_ba = ~a_dir & a_rinc;
  wire a_write_ba = a_dir & a_winc;

  // B domain: B->A write logic
  wire b_write_ba = b_dir & b_winc;
  wire b_read_ba = ~b_dir & b_rinc;

  // A->B FIFO: Write in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wr_ptr_ab_a <= {AWIDTH{1'b0}};
      rd_ptr_ab_a <= {AWIDTH{1'b0}};
    end else begin
      if (a_write_ab) begin
        fifo_ab[wr_ptr_ab_a[ASIZE-1:0]] <= a_wdata;
        wr_ptr_ab_a <= wr_ptr_ab_a + 1'b1;
      end
      if (a_read_ab) begin
        rd_ptr_ab_a <= rd_ptr_ab_a + 1'b1;
      end
    end
  end

  // A->B FIFO: Read in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wr_ptr_ab_b <= {AWIDTH{1'b0}};
      rd_ptr_ab_b <= {AWIDTH{1'b0}};
    end else begin
      if (b_read_ab) begin
        rd_ptr_ab_b <= rd_ptr_ab_b + 1'b1;
      end
    end
  end

  // B->A FIFO: Write in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wr_ptr_ba_b <= {AWIDTH{1'b0}};
      rd_ptr_ba_b <= {AWIDTH{1'b0}};
    end else begin
      if (b_write_ba) begin
        fifo_ba[wr_ptr_ba_b[ASIZE-1:0]] <= b_wdata;
        wr_ptr_ba_b <= wr_ptr_ba_b + 1'b1;
      end
      if (b_read_ba) begin
        rd_ptr_ba_b <= rd_ptr_ba_b + 1'b1;
      end
    end
  end

  // B->A FIFO: Read in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wr_ptr_ba_a <= {AWIDTH{1'b0}};
      rd_ptr_ba_a <= {AWIDTH{1'b0}};
    end else begin
      if (a_read_ba) begin
        rd_ptr_ba_a <= rd_ptr_ba_a + 1'b1;
      end
    end
  end

  // Synchronize A->B write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wr_ptr_ab_b_sync1 <= {AWIDTH{1'b0}};
      wr_ptr_ab_b_sync2 <= {AWIDTH{1'b0}};
    end else begin
      wr_ptr_ab_b_sync1 <= wr_ptr_ab_a;
      wr_ptr_ab_b_sync2 <= wr_ptr_ab_b_sync1;
    end
  end

  // Synchronize A->B read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      rd_ptr_ab_a_sync1 <= {AWIDTH{1'b0}};
      rd_ptr_ab_a_sync2 <= {AWIDTH{1'b0}};
    end else begin
      rd_ptr_ab_a_sync1 <= rd_ptr_ab_b;
      rd_ptr_ab_a_sync2 <= rd_ptr_ab_a_sync1;
    end
  end

  // Synchronize B->A write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wr_ptr_ba_a_sync1 <= {AWIDTH{1'b0}};
      wr_ptr_ba_a_sync2 <= {AWIDTH{1'b0}};
    end else begin
      wr_ptr_ba_a_sync1 <= wr_ptr_ba_b;
      wr_ptr_ba_a_sync2 <= wr_ptr_ba_a_sync1;
    end
  end

  // Synchronize B->A read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      rd_ptr_ba_b_sync1 <= {AWIDTH{1'b0}};
      rd_ptr_ba_b_sync2 <= {AWIDTH{1'b0}};
    end else begin
      rd_ptr_ba_b_sync1 <= rd_ptr_ba_a;
      rd_ptr_ba_b_sync2 <= rd_ptr_ba_b_sync1;
    end
  end

  // Data path for A->B: capture data when write happens, sync to B domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      data_ab_b_sync1 <= {DSIZE{1'b0}};
      data_ab_b_valid1 <= 1'b0;
    end else begin
      if (a_write_ab) begin
        data_ab_b_sync1 <= a_wdata;
        data_ab_b_valid1 <= 1'b1;
      end else begin
        data_ab_b_valid1 <= 1'b0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      data_ab_b_sync2 <= {DSIZE{1'b0}};
      data_ab_b_valid2 <= 1'b0;
    end else begin
      data_ab_b_sync2 <= data_ab_b_sync1;
      data_ab_b_valid2 <= data_ab_b_valid1;
    end
  end

  // Data path for B->A: capture data when write happens, sync to A domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      data_ba_a_sync1 <= {DSIZE{1'b0}};
      data_ba_a_valid1 <= 1'b0;
    end else begin
      if (b_write_ba) begin
        data_ba_a_sync1 <= b_wdata;
        data_ba_a_valid1 <= 1'b1;
      end else begin
        data_ba_a_valid1 <= 1'b0;
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      data_ba_a_sync2 <= {DSIZE{1'b0}};
      data_ba_a_valid2 <= 1'b0;
    end else begin
      data_ba_a_sync2 <= data_ba_a_sync1;
      data_ba_a_valid2 <= data_ba_a_valid1;
    end
  end

  // Read data outputs
  // A side reads from B->A FIFO
  assign a_rdata = fifo_ba[rd_ptr_ba_a[ASIZE-1:0]];

  // B side reads from A->B FIFO
  assign b_rdata = fifo_ab[rd_ptr_ab_b[ASIZE-1:0]];

  // Status flags for A side
  // A->B FIFO: A is writer
  wire [AWIDTH-1:0] ab_count_a = wr_ptr_ab_a - rd_ptr_ab_a_sync2;
  assign a_full = (ab_count_a == DEPTH);
  assign a_afull = (ab_count_a >= AFULL_THRESH);

  // B->A FIFO: A is reader
  wire [AWIDTH-1:0] ba_count_a = wr_ptr_ba_a_sync2 - rd_ptr_ba_a;
  assign a_empty = (ba_count_a == 0);
  assign a_aempty = (ba_count_a <= AEMPTY_THRESH);

  // Status flags for B side
  // A->B FIFO: B is reader
  wire [AWIDTH-1:0] ab_count_b = wr_ptr_ab_b_sync2 - rd_ptr_ab_b;
  assign b_empty = (ab_count_b == 0);
  assign b_aempty = (ab_count_b <= AEMPTY_THRESH);

  // B->A FIFO: B is writer
  wire [AWIDTH-1:0] ba_count_b = wr_ptr_ba_b - rd_ptr_ba_b_sync2;
  assign b_full = (ba_count_b == DEPTH);
  assign b_afull = (ba_count_b >= AFULL_THRESH);

endmodule
