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

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Clock domain A: write pointer (when a_dir=1) and read pointer (when a_dir=0)
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;

  // Clock domain B: write pointer (when b_dir=1) and read pointer (when b_dir=0)
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;

  // Synchronizers for pointers crossing from A to B
  reg [AWIDTH-1:0] a_wr_ptr_sync1, a_wr_ptr_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_sync1, a_rd_ptr_sync2;

  // Synchronizers for pointers crossing from B to A
  reg [AWIDTH-1:0] b_wr_ptr_sync1, b_wr_ptr_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_sync1, b_rd_ptr_sync2;

  // Synchronizers for direction signals
  reg a_dir_sync1, a_dir_sync2;
  reg b_dir_sync1, b_dir_sync2;

  // Synchronizers for write enable (to ensure data is stable before pointer update)
  reg a_winc_sync1, a_winc_sync2;
  reg b_winc_sync1, b_winc_sync2;

  // Synchronizers for read enable
  reg a_rinc_sync1, a_rinc_sync2;
  reg b_rinc_sync1, b_rinc_sync2;

  // Synchronizers for write data (only needed if we need to verify, but we'll use a different approach)
  // Actually, for bidirectional FIFO, we need to be careful. Let's use a simpler approach:
  // Each side has its own FIFO. The direction signal determines which side is writing and which is reading.
  // But the problem says "Move words in either direction, as selected on each side."
  // This means a_dir and b_dir can be different? No, that would be ambiguous.
  // Let me re-read: "Move words in either direction, as selected on each side."
  // I think a_dir and b_dir should be the same, or one is the complement of the other.
  // Actually, looking at the interface, both sides have a_dir and b_dir inputs.
  // I think the intent is that a_dir indicates whether A is writing (1) or reading (0),
  // and b_dir indicates whether B is writing (1) or reading (0).
  // For a valid transfer, if a_dir=1 then b_dir=0 (A writes, B reads), or vice versa.
  // But what if they disagree? Let's assume they are always consistent.

  // Let's use a different approach: two separate FIFOs, one for A->B and one for B->A.
  // But that would require 2x the memory. Let's stick with a single FIFO and use direction.

  // Actually, let me reconsider. The problem says "bidirectional asynchronous FIFO".
  // I think the simplest correct implementation is to have two separate FIFOs:
  // FIFO1: A writes, B reads (when a_dir=1, b_dir=0)
  // FIFO2: B writes, A reads (when a_dir=0, b_dir=1)
  // But the interface only has one set of data/pointer signals per side.

  // Let me re-read the problem statement more carefully.
  // "Move words in either direction, as selected on each side."
  // "Preserve their order and honor full and empty status."
  // "Pointers in both directions cross as acknowledged binary snapshots"

  // I think the intended design is a single FIFO where the direction determines
  // which side is the writer and which is the reader. The direction signals
  // a_dir and b_dir should be complements (a_dir = ~b_dir) for valid operation.

  // Let's implement it as a single FIFO with direction-dependent read/write.

  // Synchronizers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync2 <= {AWIDTH{1'b0}};
      a_dir_sync1 <= 1'b0;
      a_dir_sync2 <= 1'b0;
      a_winc_sync1 <= 1'b0;
      a_winc_sync2 <= 1'b0;
      a_rinc_sync1 <= 1'b0;
      a_rinc_sync2 <= 1'b0;
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
      a_rd_ptr_sync1 <= a_rd_ptr;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
      a_dir_sync1 <= a_dir;
      a_dir_sync2 <= a_dir_sync1;
      a_winc_sync1 <= a_winc;
      a_winc_sync2 <= a_winc_sync1;
      a_rinc_sync1 <= a_rinc;
      a_rinc_sync2 <= a_rinc_sync1;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync2 <= {AWIDTH{1'b0}};
      b_dir_sync1 <= 1'b0;
      b_dir_sync2 <= 1'b0;
      b_winc_sync1 <= 1'b0;
      b_winc_sync2 <= 1'b0;
      b_rinc_sync1 <= 1'b0;
      b_rinc_sync2 <= 1'b0;
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
      b_rd_ptr_sync1 <= b_rd_ptr;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
      b_dir_sync1 <= b_dir;
      b_dir_sync2 <= b_dir_sync1;
      b_winc_sync1 <= b_winc;
      b_winc_sync2 <= b_winc_sync1;
      b_rinc_sync1 <= b_rinc;
      b_rinc_sync2 <= b_rinc_sync1;
    end
  end

  // Clock domain A: update pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_dir) begin
        // A is writing
        if (a_winc && !a_full) begin
          mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
          a_wr_ptr <= a_wr_ptr + 1'b1;
        end
      end else begin
        // A is reading
        if (a_rinc && !a_empty) begin
          a_rd_ptr <= a_rd_ptr + 1'b1;
        end
      end
    end
  end

  // Clock domain B: update pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_dir) begin
        // B is writing
        if (b_winc && !b_full) begin
          mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
          b_wr_ptr <= b_wr_ptr + 1'b1;
        end
      end else begin
        // B is reading
        if (b_rinc && !b_empty) begin
          b_rd_ptr <= b_rd_ptr + 1'b1;
        end
      end
    end
  end

  // Compute full/empty for side A
  // When a_dir=1, A is the writer. A's full is based on A's write pointer vs B's read pointer.
  // When a_dir=0, A is the reader. A's empty is based on A's read pointer vs B's write pointer.

  // For A as writer: full when a_wr_ptr - b_rd_ptr_sync2 >= DEPTH
  // For A as reader: empty when a_rd_ptr == b_wr_ptr_sync2

  wire [AWIDTH-1:0] a_wr_minus_b_rd = a_wr_ptr - b_rd_ptr_sync2;
  wire [AWIDTH-1:0] b_wr_minus_a_rd = b_wr_ptr_sync2 - a_rd_ptr;

  wire a_full_as_writer = (a_wr_minus_b_rd >= DEPTH);
  wire a_empty_as_reader = (a_rd_ptr == b_wr_ptr_sync2);

  wire a_full = a_dir ? a_full_as_writer : 1'b0;
  wire a_empty = a_dir ? 1'b0 : a_empty_as_reader;

  wire a_afull = a_dir ? (a_wr_minus_b_rd >= AFULL_THRESH) : 1'b0;
  wire a_aempty = a_dir ? 1'b0 : (b_wr_minus_a_rd <= AEMPTY_THRESH);

  // For B as writer: full when b_wr_ptr - a_rd_ptr_sync2 >= DEPTH
  // For B as reader: empty when b_rd_ptr == a_wr_ptr_sync2

  wire [AWIDTH-1:0] b_wr_minus_a_rd2 = b_wr_ptr - a_rd_ptr_sync2;
  wire [AWIDTH-1:0] a_wr_minus_b_rd2 = a_wr_ptr_sync2 - b_rd_ptr;

  wire b_full_as_writer = (b_wr_minus_a_rd2 >= DEPTH);
  wire b_empty_as_reader = (b_rd_ptr == a_wr_ptr_sync2);

  wire b_full = b_dir ? b_full_as_writer : 1'b0;
  wire b_empty = b_dir ? 1'b0 : b_empty_as_reader;

  wire b_afull = b_dir ? (b_wr_minus_a_rd2 >= AFULL_THRESH) : 1'b0;
  wire b_aempty = b_dir ? 1'b0 : (a_wr_minus_b_rd2 <= AEMPTY_THRESH);

  // Read data
  // When a_dir=0, A reads from mem[a_rd_ptr]
  // When b_dir=0, B reads from mem[b_rd_ptr]
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= {DSIZE{1'b0}};
    end else begin
      if (!a_dir) begin
        a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= {DSIZE{1'b0}};
    end else begin
      if (!b_dir) begin
        b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
      end
    end
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
