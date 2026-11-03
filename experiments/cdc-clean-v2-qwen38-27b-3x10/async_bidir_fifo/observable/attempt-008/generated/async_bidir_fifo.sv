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

  localparam AWIDTH = ASIZE;
  localparam DEPTH  = 1 << AWIDTH;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Direction: a_dir=1 means A is writer, B is reader
  //            a_dir=0 means B is writer, A is reader
  // b_dir should be the complement of a_dir for consistent operation
  // We use a_dir to determine direction; b_dir is provided but we rely on a_dir
  // Actually, let's use both: if a_dir=1, A writes to B. If a_dir=0, B writes to A.
  // The problem says "as selected on each side", so a_dir and b_dir should agree.
  // We'll use a_dir as the primary direction signal.

  // Shared FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Write pointer (in writer's clock domain)
  // Read pointer (in reader's clock domain)
  // We need to handle two directions, so we'll have separate pointer sets.

  // Direction A->B: A writes, B reads
  // Direction B->A: B writes, A reads

  // Let's define:
  // When a_dir=1: A is writer, B is reader
  // When a_dir=0: B is writer, A is reader

  // We'll maintain two sets of pointers:
  // Set 1: A writes, B reads (a_dir=1)
  // Set 2: B writes, A reads (a_dir=0)

  // Actually, since direction can change, we need to be careful.
  // Let's assume direction is stable during operation, or we handle it carefully.
  // For simplicity, let's assume a_dir determines the direction and it's stable.

  // Write pointer for A->B direction (A writes)
  reg [AWIDTH:0] a_wr_ptr;
  // Read pointer for A->B direction (B reads)
  reg [AWIDTH:0] b_rd_ptr;

  // Write pointer for B->A direction (B writes)
  reg [AWIDTH:0] b_wr_ptr;
  // Read pointer for B->A direction (A reads)
  reg [AWIDTH:0] a_rd_ptr;

  // Synchronizers for A->B direction
  // A write pointer synchronized to B clock
  reg [AWIDTH:0] a_wr_ptr_sync1, a_wr_ptr_sync2;
  // B read pointer synchronized to A clock
  reg [AWIDTH:0] b_rd_ptr_sync1, b_rd_ptr_sync2;

  // Synchronizers for B->A direction
  // B write pointer synchronized to A clock
  reg [AWIDTH:0] b_wr_ptr_sync1, b_wr_ptr_sync2;
  // A read pointer synchronized to B clock
  reg [AWIDTH:0] a_rd_ptr_sync1, a_rd_ptr_sync2;

  // A->B direction: A writes, B reads
  wire a_to_b_active = a_dir;
  wire b_to_a_active = ~a_dir;

  // A->B: A write enable
  wire a_wr_en = a_to_b_active & a_winc;
  // A->B: B read enable
  wire b_rd_en = a_to_b_active & b_rinc;

  // B->A: B write enable
  wire b_wr_en = b_to_a_active & b_winc;
  // B->A: A read enable
  wire a_rd_en = b_to_a_active & a_rinc;

  // A->B: A write pointer update
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= 0;
    else if (a_wr_en)
      a_wr_ptr <= a_wr_ptr + 1;
  end

  // A->B: B read pointer update
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr <= 0;
    else if (b_rd_en)
      b_rd_ptr <= b_rd_ptr + 1;
  end

  // B->A: B write pointer update
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= 0;
    else if (b_wr_en)
      b_wr_ptr <= b_wr_ptr + 1;
  end

  // B->A: A read pointer update
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
    a_rd_ptr <= 0;
    else if (a_rd_en)
      a_rd_ptr <= a_rd_ptr + 1;
  end

  // Synchronize A write pointer to B clock
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= 0;
      a_wr_ptr_sync2 <= 0;
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
    end
  end

  // Synchronize B read pointer to A clock
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync1 <= 0;
      b_rd_ptr_sync2 <= 0;
    end else begin
      b_rd_ptr_sync1 <= b_rd_ptr;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
    end
  end

  // Synchronize B write pointer to A clock
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= 0;
      b_wr_ptr_sync2 <= 0;
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
    end
  end

  // Synchronize A read pointer to B clock
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync1 <= 0;
      a_rd_ptr_sync2 <= 0;
    end else begin
      a_rd_ptr_sync1 <= a_rd_ptr;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
    end
  end

  // A->B: Full/Empty flags
  // A is writer, B is reader
  // A sees: a_wr_ptr (local), b_rd_ptr_sync2 (synchronized)
  // B sees: a_wr_ptr_sync2 (synchronized), b_rd_ptr (local)

  wire [AWIDTH:0] a_to_b_wr_ptr_a = a_wr_ptr;
  wire [AWIDTH:0] a_to_b_rd_ptr_a = b_rd_ptr_sync2;
  wire [AWIDTH:0] a_to_b_wr_ptr_b = a_wr_ptr_sync2;
  wire [AWIDTH:0] a_to_b_rd_ptr_b = b_rd_ptr;

  // A->B: A side full/empty
  wire [AWIDTH:0] a_to_b_diff_a = a_to_b_wr_ptr_a - a_to_b_rd_ptr_a;
  wire a_to_b_full_a = (a_to_b_diff_a == DEPTH - 1);
  wire a_to_b_empty_a = (a_to_b_diff_a == 0);

  // A->B: B side full/empty
  wire [AWIDTH:0] a_to_b_diff_b = a_to_b_wr_ptr_b - a_to_b_rd_ptr_b;
  wire a_to_b_full_b = (a_to_b_diff_b == DEPTH - 1);
  wire a_to_b_empty_b = (a_to_b_diff_b == 0);

  // B->A: Full/Empty flags
  // B is writer, A is reader
  // B sees: b_wr_ptr (local), a_rd_ptr_sync2 (synchronized)
  // A sees: b_wr_ptr_sync2 (synchronized), a_rd_ptr (local)

  wire [AWIDTH:0] b_to_a_wr_ptr_b = b_wr_ptr;
  wire [AWIDTH:0] b_to_a_rd_ptr_b = a_rd_ptr_sync2;
  wire [AWIDTH:0] b_to_a_wr_ptr_a = b_wr_ptr_sync2;
  wire [AWIDTH:0] b_to_a_rd_ptr_a = a_rd_ptr;

  // B->A: B side full/empty
  wire [AWIDTH:0] b_to_a_diff_b = b_to_a_wr_ptr_b - b_to_a_rd_ptr_b;
  wire b_to_a_full_b = (b_to_a_diff_b == DEPTH - 1);
  wire b_to_a_empty_b = (b_to_a_diff_b == 0);

  // B->A: A side full/empty
  wire [AWIDTH:0] b_to_a_diff_a = b_to_a_wr_ptr_a - b_to_a_rd_ptr_a;
  wire b_to_a_full_a = (b_to_a_diff_a == DEPTH - 1);
  wire b_to_a_empty_a = (b_to_a_diff_a == 0);

  // Almost full/empty
  wire a_to_b_afull_a = (a_to_b_diff_a >= AFULL_THRESH);
  wire a_to_b_aempty_a = (a_to_b_diff_a <= AEMPTY_THRESH);
  wire a_to_b_afull_b = (a_to_b_diff_b >= AFULL_THRESH);
  wire a_to_b_aempty_b = (a_to_b_diff_b <= AEMPTY_THRESH);

  wire b_to_a_afull_b = (b_to_a_diff_b >= AFULL_THRESH);
  wire b_to_a_aempty_b = (b_to_a_diff_b <= AEMPTY_THRESH);
  wire b_to_a_afull_a = (b_to_a_diff_a >= AFULL_THRESH);
  wire b_to_a_aempty_a = (b_to_a_diff_a <= AEMPTY_THRESH);

  // Memory write
  // A->B: A writes to mem
  // B->A: B writes to mem
  // We need to ensure only one writer at a time based on direction

  // A writes when a_to_b_active
  // B writes when b_to_a_active

  // Since direction is determined by a_dir, only one direction is active at a time
  // So only one writer is active at a time

  // A write to memory
  always @(posedge a_clk) begin
    if (a_wr_en)
      mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
  end

  // B write to memory
  always @(posedge b_clk) begin
    if (b_wr_en)
      mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
  end

  // Read data
  // A->B: B reads from mem
  // B->A: A reads from mem

  // B read from memory (A->B direction)
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk) begin
    if (a_to_b_active)
      b_rdata_reg <= mem[b_rd_ptr[AWIDTH-1:0]];
  end

  // A read from memory (B->A direction)
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk) begin
    if (b_to_a_active)
      a_rdata_reg <= mem[a_rd_ptr[AWIDTH-1:0]];
  end

  // Output assignments
  assign a_rdata = b_to_a_active ? a_rdata_reg : {DSIZE{1'b0}};
  assign b_rdata = a_to_b_active ? b_rdata_reg : {DSIZE{1'b0}};

  // A side flags
  // When a_to_b_active: A is writer
  //   a_full = a_to_b_full_a
  //   a_afull = a_to_b_afull_a
  //   a_empty = a_to_b_empty_a (A is writer, so empty means no data to read from A's perspective? No, A is writer)
  //   Actually, a_empty should indicate if A can read. But A is writer in this direction.
  //   Let me reconsider.

  // The interface has a_full, a_afull, a_empty, a_aempty for side A.
  // a_full: A cannot write (A is writer and FIFO is full)
  // a_empty: A cannot read (A is reader and FIFO is empty)
  // a_afull: Almost full (warning for writer)
  // a_aempty: Almost empty (warning for reader)

  // When a_to_b_active (A writes, B reads):
  //   A is writer: a_full = a_to_b_full_a, a_afull = a_to_b_afull_a
  //   A is not reader: a_empty = 1 (no data to read from A), a_aempty = 1
  //   Actually, a_empty should be 1 when A cannot read. Since A is writer, it doesn't read.
  //   But the flag should reflect the FIFO state from A's perspective.
  //   Let's say a_empty = 1 when the FIFO is empty from A's read perspective.
  //   Since A is writer, a_empty = 1 always? That doesn't make sense.

  // Let me re-read the problem. "honor full and empty status"
  // a_full: indicates A cannot write
  // a_empty: indicates A cannot read
  // So when A is writer (a_to_b_active):
  //   a_full = a_to_b_full_a
  //   a_empty = 1 (A is not reading, so it's always "empty" from read perspective)
  //   But that's not useful. Let me think differently.

  // Perhaps a_empty indicates if there's data available for A to read.
  // When A is writer, there's no data for A to read, so a_empty = 1.
  // When A is reader (b_to_a_active), a_empty = b_to_a_empty_a.

  // Similarly, a_full indicates if A can write.
  // When A is writer, a_full = a_to_b_full_a.
  // When A is reader, a_full = 0 (A is not writing, so it's never "full" from write perspective).

  // Let's go with this interpretation.

  assign a_full   = a_to_b_active ? a_to_b_full_a   : 1'b0;
  assign a_afull  = a_to_b_active ? a_to_b_afull_a  : 1'b0;
  assign a_empty  = b_to_a_active ? b_to_a_empty_a  : 1'b1;
  assign a_aempty = b_to_a_active ? b_to_a_aempty_a : 1'b1;

  assign b_full   = b_to_a_active ? b_to_a_full_b   : 1'b0;
  assign b_afull  = b_to_a_active ? b_to_a_afull_b  : 1'b0;
  assign b_empty  = a_to_b_active ? a_to_b_empty_b  : 1'b1;
  assign b_aempty = a_to_b_active ? a_to_b_aempty_b : 1'b1;

endmodule
