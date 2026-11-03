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

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // A-side pointers (A clock domain)
  reg [AWIDTH:0] a_wr_ptr;
  reg [AWIDTH:0] a_rd_ptr;

  // B-side pointers (B clock domain)
  reg [AWIDTH:0] b_wr_ptr;
  reg [AWIDTH:0] b_rd_ptr;

  // Synchronized pointers
  reg [AWIDTH:0] a_wr_ptr_sync;
  reg [AWIDTH:0] a_rd_ptr_sync;
  reg [AWIDTH:0] b_wr_ptr_sync;
  reg [AWIDTH:0] b_rd_ptr_sync;

  // Direction registers (synchronized)
  reg a_dir_sync;
  reg b_dir_sync;

  // Write enable for A-side FIFO (A clock domain)
  wire a_wr_en;
  // Read enable for A-side FIFO (A clock domain)
  wire a_rd_en;

  // Write enable for B-side FIFO (B clock domain)
  wire b_wr_en;
  // Read enable for B-side FIFO (B clock domain)
  wire b_rd_en;

  // Full/empty signals
  wire a_fifo_full;
  wire a_fifo_empty;
  wire b_fifo_full;
  wire b_fifo_empty;

  // Almost full/empty
  wire a_fifo_afull;
  wire a_fifo_aempty;
  wire b_fifo_afull;
  wire b_fifo_aempty;

  // Data path: A writes to FIFO when a_dir=1, B writes when b_dir=1
  // A reads from FIFO when a_dir=0, B reads when b_dir=0

  // Determine which side is writing/reading based on direction
  // a_dir=1: A is writer, B is reader
  // a_dir=0: A is reader, B is writer
  // b_dir=1: B is writer, A is reader
  // b_dir=0: B is reader, A is writer

  // For the FIFO to work bidirectionally, we need:
  // When a_dir=1 and b_dir=1: A writes, B reads
  // When a_dir=0 and b_dir=0: B writes, A reads
  // When a_dir=1 and b_dir=0: A writes, A reads (conflict - shouldn't happen normally)
  // When a_dir=0 and b_dir=1: B writes, B reads (conflict)

  // Actually, let's think about this differently. The FIFO has a single write port and single read port.
  // The direction signals determine which external interface is connected to which FIFO port.

  // Let's define:
  // A-side write to FIFO: a_winc && a_dir
  // A-side read from FIFO: a_rinc && !a_dir
  // B-side write to FIFO: b_winc && b_dir
  // B-side read from FIFO: b_rinc && !b_dir

  // But we can only have one writer and one reader at a time.
  // The design assumes that the directions are consistent:
  // If a_dir=1, then b_dir should be 1 (A writes, B reads)
  // If a_dir=0, then b_dir should be 0 (B writes, A reads)

  // Let's assume the directions are properly set by the user.

  // A-side FIFO write enable
  assign a_wr_en = a_winc & a_dir;
  // A-side FIFO read enable
  assign a_rd_en = a_rinc & ~a_dir;

  // B-side FIFO write enable
  assign b_wr_en = b_winc & b_dir;
  // B-side FIFO read enable
  assign b_rd_en = b_rinc & ~b_dir;

  // A-side full: FIFO is full
  assign a_fifo_full = (a_wr_ptr[AWIDTH-1:0] == a_rd_ptr_sync[AWIDTH-1:0]) &&
                       (a_wr_ptr[AWIDTH] != a_rd_ptr_sync[AWIDTH]);

  // A-side empty: FIFO is empty
  assign a_fifo_empty = (a_wr_ptr_sync[AWIDTH:0] == a_rd_ptr[AWIDTH:0]);

  // A-side almost full
  assign a_fifo_afull = a_fifo_full ||
                        ((a_wr_ptr[AWIDTH-1:0] == a_rd_ptr_sync[AWIDTH-1:0]) &&
                         (a_wr_ptr[AWIDTH] != a_rd_ptr_sync[AWIDTH]) &&
                         (a_wr_ptr[AWIDTH-1:0] == (a_rd_ptr_sync[AWIDTH-1:0] + AFULL_THRESH[AWIDTH-1:0])));

  // Actually, let's compute almost full more carefully
  // Almost full when count >= DEPTH - 2
  // count = (a_wr_ptr - a_rd_ptr_sync) mod DEPTH

  // Let's use a simpler approach:
  // a_afull when the number of entries is >= DEPTH - 2
  // We can compute this by checking if the difference is >= DEPTH - 2

  // For simplicity, let's define:
  wire [AWIDTH-1:0] a_count;
  wire [AWIDTH-1:0] b_count;

  assign a_count = a_wr_ptr[AWIDTH-1:0] - a_rd_ptr_sync[AWIDTH-1:0];
  assign b_count = b_wr_ptr[AWIDTH-1:0] - b_rd_ptr_sync[AWIDTH-1:0];

  assign a_fifo_afull = (a_count >= AFULL_THRESH[AWIDTH-1:0]);
  assign a_fifo_aempty = (a_count <= AEMPTY_THRESH[AWIDTH-1:0]);

  assign b_fifo_afull = (b_count >= AFULL_THRESH[AWIDTH-1:0]);
  assign b_fifo_aempty = (b_count <= AEMPTY_THRESH[AWIDTH-1:0]);

  // B-side full
  assign b_fifo_full = (b_wr_ptr[AWIDTH-1:0] == b_rd_ptr_sync[AWIDTH-1:0]) &&
                       (b_wr_ptr[AWIDTH] != b_rd_ptr_sync[AWIDTH]);

  // B-side empty
  assign b_fifo_empty = (b_wr_ptr_sync[AWIDTH:0] == b_rd_ptr[AWIDTH:0]);

  // Output assignments
  assign a_full   = a_fifo_full;
  assign a_afull  = a_fifo_afull;
  assign a_empty  = a_fifo_empty;
  assign a_aempty = a_fifo_aempty;

  assign b_full   = b_fifo_full;
  assign b_afull  = b_fifo_afull;
  assign b_empty  = b_fifo_empty;
  assign b_aempty = b_fifo_aempty;

  // A-side read data
  assign a_rdata = mem[a_rd_ptr[AWIDTH-1:0]];

  // B-side read data
  assign b_rdata = mem[b_rd_ptr[AWIDTH-1:0]];

  // A clock domain: write to FIFO
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {1'b0, {AWIDTH{1'b0}}};
      a_rd_ptr <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      if (a_wr_en) begin
        mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1'b1;
      end
      if (a_rd_en) begin
        a_rd_ptr <= a_rd_ptr + 1'b1;
      end
    end
  end

  // B clock domain: write to FIFO
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {1'b0, {AWIDTH{1'b0}}};
      b_rd_ptr <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      if (b_wr_en) begin
        mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1'b1;
      end
      if (b_rd_en) begin
        b_rd_ptr <= b_rd_ptr + 1'b1;
      end
    end
  end

  // Synchronize A write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      a_wr_ptr_sync <= a_wr_ptr;
    end
  end

  // Synchronize A read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      a_rd_ptr_sync <= a_rd_ptr;
    end
  end

  // Synchronize B write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      b_wr_ptr_sync <= b_wr_ptr;
    end
  end

  // Synchronize B read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync <= {1'b0, {AWIDTH{1'b0}}};
    end else begin
      b_rd_ptr_sync <= b_rd_ptr;
    end
  end

  // Synchronize direction signals
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_dir_sync <= 1'b0;
    end else begin
      a_dir_sync <= a_dir;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_dir_sync <= 1'b0;
    end else begin
      b_dir_sync <= b_dir;
    end
  end

endmodule
