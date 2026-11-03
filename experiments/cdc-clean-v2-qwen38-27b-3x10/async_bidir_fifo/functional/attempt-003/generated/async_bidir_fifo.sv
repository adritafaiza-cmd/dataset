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

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Side A pointers (A is writer when a_dir=1, reader when a_dir=0)
  // We need to track both write and read pointers for each direction.
  // Since direction can change, we maintain separate pointer sets for
  // A->B and B->A transfers.

  // A->B direction: A writes, B reads
  reg [PTR_W-1:0] a2b_wr_ptr_a;  // write pointer in A domain
  reg [PTR_W-1:0] a2b_rd_ptr_a;  // read pointer in A domain (synchronized from B)
  reg [PTR_W-1:0] a2b_wr_ptr_b;  // write pointer in B domain (synchronized from A)
  reg [PTR_W-1:0] a2b_rd_ptr_b;  // read pointer in B domain

  // B->A direction: B writes, A reads
  reg [PTR_W-1:0] b2a_wr_ptr_b;  // write pointer in B domain
  reg [PTR_W-1:0] b2a_rd_ptr_b;  // read pointer in B domain (synchronized from A)
  reg [PTR_W-1:0] b2a_wr_ptr_a;  // write pointer in A domain (synchronized from B)
  reg [PTR_W-1:0] b2a_rd_ptr_a;  // read pointer in A domain

  // Synchronization registers
  // A->B: write pointer from A to B
  reg [PTR_W-1:0] a2b_wr_ptr_sync1, a2b_wr_ptr_sync2, a2b_wr_ptr_sync3;
  // A->B: read pointer from B to A
  reg [PTR_W-1:0] a2b_rd_ptr_sync1, a2b_rd_ptr_sync2, a2b_rd_ptr_sync3;
  // B->A: write pointer from B to A
  reg [PTR_W-1:0] b2a_wr_ptr_sync1, b2a_wr_ptr_sync2, b2a_wr_ptr_sync3;
  // B->A: read pointer from A to B
  reg [PTR_W-1:0] b2a_rd_ptr_sync1, b2a_rd_ptr_sync2, b2a_rd_ptr_sync3;

  // Data synchronization for A->B (data written by A, read by B)
  // We use a simple approach: data is written to mem in A domain,
  // and B reads from mem. Since mem is shared, we need to ensure
  // that data is stable before B reads it. We'll use a data valid
  // mechanism or rely on the pointer synchronization.

  // For simplicity and correctness with asynchronous clocks, we'll
  // use a standard async FIFO approach where data is written in one
  // clock domain and read in another. The memory is shared.

  // Synchronization for A->B write pointer (A to B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a2b_wr_ptr_sync1 <= {PTR_W{1'b0}};
      a2b_wr_ptr_sync2 <= {PTR_W{1'b0}};
      a2b_wr_ptr_sync3 <= {PTR_W{1'b0}};
    end else begin
      a2b_wr_ptr_sync1 <= a2b_wr_ptr_a;
      a2b_wr_ptr_sync2 <= a2b_wr_ptr_sync1;
      a2b_wr_ptr_sync3 <= a2b_wr_ptr_sync2;
    end
  end

  // Synchronization for A->B read pointer (B to A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a2b_rd_ptr_sync1 <= {PTR_W{1'b0}};
      a2b_rd_ptr_sync2 <= {PTR_W{1'b0}};
      a2b_rd_ptr_sync3 <= {PTR_W{1'b0}};
    end else begin
      a2b_rd_ptr_sync1 <= a2b_rd_ptr_b;
      a2b_rd_ptr_sync2 <= a2b_rd_ptr_sync1;
      a2b_rd_ptr_sync3 <= a2b_rd_ptr_sync2;
    end
  end

  // Synchronization for B->A write pointer (B to A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b2a_wr_ptr_sync1 <= {PTR_W{1'b0}};
      b2a_wr_ptr_sync2 <= {PTR_W{1'b0}};
      b2a_wr_ptr_sync3 <= {PTR_W{1'b0}};
    end else begin
      b2a_wr_ptr_sync1 <= b2a_wr_ptr_b;
      b2a_wr_ptr_sync2 <= b2a_wr_ptr_sync1;
      b2a_wr_ptr_sync3 <= b2a_wr_ptr_sync2;
    end
  end

  // Synchronization for B->A read pointer (A to B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b2a_rd_ptr_sync1 <= {PTR_W{1'b0}};
      b2a_rd_ptr_sync2 <= {PTR_W{1'b0}};
      b2a_rd_ptr_sync3 <= {PTR_W{1'b0}};
    end else begin
      b2a_rd_ptr_sync1 <= b2a_rd_ptr_a;
      b2a_rd_ptr_sync2 <= b2a_rd_ptr_sync1;
      b2a_rd_ptr_sync3 <= b2a_rd_ptr_sync2;
    end
  end

  // Synchronized pointer values
  wire [PTR_W-1:0] a2b_wr_ptr_b_sync = a2b_wr_ptr_sync3;
  wire [PTR_W-1:0] a2b_rd_ptr_a_sync = a2b_rd_ptr_sync3;
  wire [PTR_W-1:0] b2a_wr_ptr_a_sync = b2a_wr_ptr_sync3;
  wire [PTR_W-1:0] b2a_rd_ptr_b_sync = b2a_rd_ptr_sync3;

  // Update synchronized pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a2b_wr_ptr_b <= {PTR_W{1'b0}};
    end else begin
      a2b_wr_ptr_b <= a2b_wr_ptr_b_sync;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a2b_rd_ptr_a <= {PTR_W{1'b0}};
    end else begin
      a2b_rd_ptr_a <= a2b_rd_ptr_a_sync;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b2a_wr_ptr_a <= {PTR_W{1'b0}};
    end else begin
      b2a_wr_ptr_a <= b2a_wr_ptr_a_sync;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b2a_rd_ptr_b <= {PTR_W{1'b0}};
    end else begin
      b2a_rd_ptr_b <= b2a_rd_ptr_b_sync;
    end
  end

  // A->B: A writes when a_dir=1 and a_winc=1 and not full
  wire a2b_full = (a2b_wr_ptr_a == a2b_rd_ptr_a_sync) ? 0 : 
                  ((a2b_wr_ptr_a[ASIZE-1:0] == a2b_rd_ptr_a_sync[ASIZE-1:0]) && 
                   (a2b_wr_ptr_a[ASIZE] != a2b_rd_ptr_a_sync[ASIZE]));
  wire a2b_afull = (a2b_wr_ptr_a[ASIZE-1:0] == a2b_rd_ptr_a_sync[ASIZE-1:0]) && 
                   (a2b_wr_ptr_a[ASIZE] != a2b_rd_ptr_a_sync[ASIZE]) ? 0 :
                   ((a2b_wr_ptr_a[ASIZE-1:0] - a2b_rd_ptr_a_sync[ASIZE-1:0]) >= AFULL_THRESH);

  // Actually, let's compute fill level properly
  wire [PTR_W-1:0] a2b_fill = a2b_wr_ptr_a - a2b_rd_ptr_a_sync;
  wire a2b_full  = (a2b_fill == DEPTH);
  wire a2b_afull = (a2b_fill >= AFULL_THRESH);

  // B->A: B writes when b_dir=1 and b_winc=1 and not full
  wire [PTR_W-1:0] b2a_fill = b2a_wr_ptr_b - b2a_rd_ptr_b_sync;
  wire b2a_full  = (b2a_fill == DEPTH);
  wire b2a_afull = (b2a_fill >= AFULL_THRESH);

  // A->B: B reads when b_dir=0 and b_rinc=1 and not empty
  wire [PTR_W-1:0] a2b_empty_level = a2b_rd_ptr_b - a2b_wr_ptr_b_sync;
  wire a2b_empty  = (a2b_empty_level == 0);
  wire a2b_aempty = (a2b_empty_level <= AEMPTY_THRESH);

  // B->A: A reads when a_dir=0 and a_rinc=1 and not empty
  wire [PTR_W-1:0] b2a_empty_level = b2a_rd_ptr_a - b2a_wr_ptr_a_sync;
  wire b2a_empty  = (b2a_empty_level == 0);
  wire b2a_aempty = (b2a_empty_level <= AEMPTY_THRESH);

  // Write enable for A->B (A is writer)
  wire a2b_we = a_dir & a_winc & ~a2b_full;

  // Read enable for A->B (B is reader)
  wire a2b_re = ~b_dir & b_rinc & ~a2b_empty;

  // Write enable for B->A (B is writer)
  wire b2a_we = b_dir & b_winc & ~b2a_full;

  // Read enable for B->A (A is reader)
  wire b2a_re = ~a_dir & a_rinc & ~b2a_empty;

  // A->B: Write in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a2b_wr_ptr_a <= {PTR_W{1'b0}};
    end else if (a2b_we) begin
      mem[a2b_wr_ptr_a[ASIZE-1:0]] <= a_wdata;
      a2b_wr_ptr_a <= a2b_wr_ptr_a + 1'b1;
    end
  end

  // A->B: Read in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a2b_rd_ptr_b <= {PTR_W{1'b0}};
    end else if (a2b_re) begin
      a2b_rd_ptr_b <= a2b_rd_ptr_b + 1'b1;
    end
  end

  // B->A: Write in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b2a_wr_ptr_b <= {PTR_W{1'b0}};
    end else if (b2a_we) begin
      mem[b2a_wr_ptr_b[ASIZE-1:0]] <= b_wdata;
      b2a_wr_ptr_b <= b2a_wr_ptr_b + 1'b1;
    end
  end

  // B->A: Read in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b2a_rd_ptr_a <= {PTR_W{1'b0}};
    end else if (b2a_re) begin
      b2a_rd_ptr_a <= b2a_rd_ptr_a + 1'b1;
    end
  end

  // Read data
  // A reads from B->A FIFO
  assign a_rdata = mem[b2a_rd_ptr_a[ASIZE-1:0]];

  // B reads from A->B FIFO
  assign b_rdata = mem[a2b_rd_ptr_b[ASIZE-1:0]];

  // Status flags
  // A side: full/empty depend on which direction A is operating in
  // When a_dir=1, A is writing to A->B FIFO, so a_full = a2b_full
  // When a_dir=0, A is reading from B->A FIFO, so a_empty = b2a_empty
  // But the spec says full/empty are local to each side. Let's interpret:
  // a_full: A cannot write (A is writer in A->B direction)
  // a_empty: A cannot read (A is reader in B->A direction)
  // a_afull: almost full for A->B
  // a_aempty: almost empty for B->A

  assign a_full   = a2b_full;
  assign a_afull  = a2b_afull;
  assign a_empty  = b2a_empty;
  assign a_aempty = b2a_aempty;

  assign b_full   = b2a_full;
  assign b_afull  = b2a_afull;
  assign b_empty  = a2b_empty;
  assign b_aempty = a2b_aempty;

endmodule
