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

  // Shared storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // A-side pointers
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;

  // B-side pointers
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;

  // Gray code pointers for CDC
  wire [AWIDTH-1:0] a_wr_gray = a_wr_ptr ^ (a_wr_ptr >> 1);
  wire [AWIDTH-1:0] a_rd_gray = a_rd_ptr ^ (a_rd_ptr >> 1);
  wire [AWIDTH-1:0] b_wr_gray = b_wr_ptr ^ (b_wr_ptr >> 1);
  wire [AWIDTH-1:0] b_rd_gray = b_rd_ptr ^ (b_rd_ptr >> 1);

  // Synchronized pointers in B domain (for A->B direction)
  reg [AWIDTH-1:0] a_wr_gray_b1, a_wr_gray_b2, a_wr_gray_b3;
  reg [AWIDTH-1:0] a_rd_gray_b1, a_rd_gray_b2, a_rd_gray_b3;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_gray_b1 <= {AWIDTH{1'b0}};
      a_wr_gray_b2 <= {AWIDTH{1'b0}};
      a_wr_gray_b3 <= {AWIDTH{1'b0}};
      a_rd_gray_b1 <= {AWIDTH{1'b0}};
      a_rd_gray_b2 <= {AWIDTH{1'b0}};
      a_rd_gray_b3 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_gray_b1 <= a_wr_gray;
      a_wr_gray_b2 <= a_wr_gray_b1;
      a_wr_gray_b3 <= a_wr_gray_b2;
      a_rd_gray_b1 <= a_rd_gray;
      a_rd_gray_b2 <= a_rd_gray_b1;
      a_rd_gray_b3 <= a_rd_gray_b2;
    end
  end

  // Synchronized pointers in A domain (for B->A direction)
  reg [AWIDTH-1:0] b_wr_gray_a1, b_wr_gray_a2, b_wr_gray_a3;
  reg [AWIDTH-1:0] b_rd_gray_a1, b_rd_gray_a2, b_rd_gray_a3;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_gray_a1 <= {AWIDTH{1'b0}};
      b_wr_gray_a2 <= {AWIDTH{1'b0}};
      b_wr_gray_a3 <= {AWIDTH{1'b0}};
      b_rd_gray_a1 <= {AWIDTH{1'b0}};
      b_rd_gray_a2 <= {AWIDTH{1'b0}};
      b_rd_gray_a3 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_gray_a1 <= b_wr_gray;
      b_wr_gray_a2 <= b_wr_gray_a1;
      b_wr_gray_a3 <= b_wr_gray_a2;
      b_rd_gray_a1 <= b_rd_gray;
      b_rd_gray_a2 <= b_rd_gray_a1;
      b_rd_gray_a3 <= b_rd_gray_a2;
    end
  end

  // Convert gray to binary
  function [AWIDTH-1:0] gray2bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  // A-side: determine if A is writing to B or reading from B
  // a_dir = 1: A writes to B (A is source), A reads from B (A is destination)
  // Actually, let's think about this more carefully.
  // a_dir selects the direction for A side.
  // If a_dir = 1, A is the writer (A->B direction)
  // If a_dir = 0, A is the reader (B->A direction)
  // Similarly for b_dir.
  // But both sides can't be writers or both readers simultaneously in a meaningful way.
  // Let's assume:
  // a_dir = 1: A writes, B reads (A->B)
  // a_dir = 0: A reads, B writes (B->A)
  // b_dir should be the complement for consistency, but we'll use each side's dir independently.

  // For A->B direction:
  // A writes to mem using a_wr_ptr
  // B reads from mem using a_rd_ptr (synchronized to B domain)
  // A's full: a_wr_ptr - a_rd_ptr >= DEPTH
  // A's empty: a_wr_ptr == a_rd_ptr (but this is for A as reader of B->A)

  // Let me reconsider the architecture.
  // The FIFO is bidirectional. At any given time, data flows in one direction.
  // a_dir and b_dir select the direction.
  // If a_dir=1 and b_dir=0: A writes, B reads (A->B)
  // If a_dir=0 and b_dir=1: B writes, A reads (B->A)
  // We'll handle both cases.

  // A-side write enable (A->B direction)
  wire a_write_en = a_winc & a_dir;
  // A-side read enable (B->A direction)
  wire a_read_en = a_rinc & !a_dir;

  // B-side write enable (B->A direction)
  wire b_write_en = b_winc & b_dir;
  // B-side read enable (A->B direction)
  wire b_read_en = b_rinc & !b_dir;

  // A->B direction: A writes, B reads
  // A's full status: based on a_wr_ptr and a_rd_ptr (a_rd_ptr is in A domain)
  // But a_rd_ptr is updated by B side reads. We need to sync a_rd_ptr back to A.
  // Wait, a_rd_ptr is in A domain? No, a_rd_ptr should be in the domain of the reader.
  // Let me restructure.

  // For A->B:
  // Writer is A, so write pointer is in A domain: a_wr_ptr
  // Reader is B, so read pointer is in B domain: let's call it ab_rd_ptr (in B domain)
  // A's full: a_wr_ptr - ab_rd_ptr_synced_to_A >= DEPTH
  // B's empty: ab_rd_ptr == a_wr_ptr_synced_to_B

  // For B->A:
  // Writer is B, so write pointer is in B domain: b_wr_ptr
  // Reader is A, so read pointer is in A domain: let's call it ba_rd_ptr (in A domain)
  // B's full: b_wr_ptr - ba_rd_ptr_synced_to_B >= DEPTH
  // A's empty: ba_rd_ptr == b_wr_ptr_synced_to_A

  // Let me redefine pointers:
  // A->B direction:
  //   a_wr_ptr (A domain) - write pointer
  //   ab_rd_ptr (B domain) - read pointer
  // B->A direction:
  //   b_wr_ptr (B domain) - write pointer
  //   ba_rd_ptr (A domain) - read pointer

  // But we only have one mem. The pointers for both directions share the same mem.
  // This is tricky. Let me think differently.

  // Actually, for a bidirectional FIFO, we can have two separate FIFOs sharing the same memory,
  // or we can have a single FIFO that changes direction.
  // Given the interface, it seems like we have one FIFO that can go either way.
  // The direction is selected by a_dir and b_dir.

  // Let's assume:
  // When a_dir=1, b_dir=0: A->B
  // When a_dir=0, b_dir=1: B->A
  // The pointers are:
  // For A->B: write ptr in A domain, read ptr in B domain
  // For B->A: write ptr in B domain, read ptr in A domain

  // We'll use:
  // a_wr_ptr: A domain, used when A is writer (a_dir=1)
  // b_wr_ptr: B domain, used when B is writer (b_dir=1)
  // ab_rd_ptr: B domain, used when B is reader (b_dir=0) for A->B
  // ba_rd_ptr: A domain, used when A is reader (a_dir=0) for B->A

  // But we need to sync read pointers back to the writer's domain for full/empty.

  // Let me simplify by having:
  // For A->B:
  //   wr_ptr in A domain (a_wr_ptr)
  //   rd_ptr in B domain (ab_rd_ptr)
  //   A full: a_wr_ptr - ab_rd_ptr_synced >= DEPTH
  //   B empty: ab_rd_ptr == a_wr_ptr_synced

  // For B->A:
  //   wr_ptr in B domain (b_wr_ptr)
  //   rd_ptr in A domain (ba_rd_ptr)
  //   B full: b_wr_ptr - ba_rd_ptr_synced >= DEPTH
  //   A empty: ba_rd_ptr == b_wr_ptr_synced

  // We need to sync:
  // ab_rd_ptr from B to A (for A full)
  // a_wr_ptr from A to B (for B empty)
  // ba_rd_ptr from A to B (for B full)
  // b_wr_ptr from B to A (for A empty)

  // Let's implement this.

  // A->B direction pointers
  reg [AWIDTH-1:0] a_wr_ptr_ab;  // A domain, write pointer for A->B
  reg [AWIDTH-1:0] ab_rd_ptr;    // B domain, read pointer for A->B

  // B->A direction pointers
  reg [AWIDTH-1:0] b_wr_ptr_ba;  // B domain, write pointer for B->A
  reg [AWIDTH-1:0] ba_rd_ptr;    // A domain, read pointer for B->A

  // Gray codes
  wire [AWIDTH-1:0] a_wr_ptr_ab_gray = a_wr_ptr_ab ^ (a_wr_ptr_ab >> 1);
  wire [AWIDTH-1:0] ab_rd_ptr_gray = ab_rd_ptr ^ (ab_rd_ptr >> 1);
  wire [AWIDTH-1:0] b_wr_ptr_ba_gray = b_wr_ptr_ba ^ (b_wr_ptr_ba >> 1);
  wire [AWIDTH-1:0] ba_rd_ptr_gray = ba_rd_ptr ^ (ba_rd_ptr >> 1);

  // Sync a_wr_ptr_ab from A to B (for B empty in A->B)
  reg [AWIDTH-1:0] a_wr_ptr_ab_b1, a_wr_ptr_ab_b2, a_wr_ptr_ab_b3;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_ab_b1 <= {AWIDTH{1'b0}};
      a_wr_ptr_ab_b2 <= {AWIDTH{1'b0}};
      a_wr_ptr_ab_b3 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_ab_b1 <= a_wr_ptr_ab_gray;
      a_wr_ptr_ab_b2 <= a_wr_ptr_ab_b1;
      a_wr_ptr_ab_b3 <= a_wr_ptr_ab_b2;
    end
  end

  // Sync ab_rd_ptr from B to A (for A full in A->B)
  reg [AWIDTH-1:0] ab_rd_ptr_a1, ab_rd_ptr_a2, ab_rd_ptr_a3;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ab_rd_ptr_a1 <= {AWIDTH{1'b0}};
      ab_rd_ptr_a2 <= {AWIDTH{1'b0}};
      ab_rd_ptr_a3 <= {AWIDTH{1'b0}};
    end else begin
      ab_rd_ptr_a1 <= ab_rd_ptr_gray;
      ab_rd_ptr_a2 <= ab_rd_ptr_a1;
      ab_rd_ptr_a3 <= ab_rd_ptr_a2;
    end
  end

  // Sync b_wr_ptr_ba from B to A (for A empty in B->A)
  reg [AWIDTH-1:0] b_wr_ptr_ba_a1, b_wr_ptr_ba_a2, b_wr_ptr_ba_a3;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_ba_a1 <= {AWIDTH{1'b0}};
      b_wr_ptr_ba_a2 <= {AWIDTH{1'b0}};
      b_wr_ptr_ba_a3 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_ba_a1 <= b_wr_ptr_ba_gray;
      b_wr_ptr_ba_a2 <= b_wr_ptr_ba_a1;
      b_wr_ptr_ba_a3 <= b_wr_ptr_ba_a2;
    end
  end

  // Sync ba_rd_ptr from A to B (for B full in B->A)
  reg [AWIDTH-1:0] ba_rd_ptr_b1, ba_rd_ptr_b2, ba_rd_ptr_b3;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ba_rd_ptr_b1 <= {AWIDTH{1'b0}};
      ba_rd_ptr_b2 <= {AWIDTH{1'b0}};
      ba_rd_ptr_b3 <= {AWIDTH{1'b0}};
    end else begin
      ba_rd_ptr_b1 <= ba_rd_ptr_gray;
      ba_rd_ptr_b2 <= ba_rd_ptr_b1;
      ba_rd_ptr_b3 <= ba_rd_ptr_b2;
    end
  end

  // Convert synced gray to binary
  wire [AWIDTH-1:0] a_wr_ptr_ab_b_bin = gray2bin(a_wr_ptr_ab_b3);
  wire [AWIDTH-1:0] ab_rd_ptr_a_bin = gray2bin(ab_rd_ptr_a3);
  wire [AWIDTH-1:0] b_wr_ptr_ba_a_bin = gray2bin(b_wr_ptr_ba_a3);
  wire [AWIDTH-1:0] ba_rd_ptr_b_bin = gray2bin(ba_rd_ptr_b3);

  // A->B direction:
  // A full: a_wr_ptr_ab - ab_rd_ptr_a_bin >= DEPTH
  wire [AWIDTH-1:0] a_full_diff_ab = a_wr_ptr_ab - ab_rd_ptr_a_bin;
  wire a_full_ab = (a_full_diff_ab >= DEPTH);

  // B empty: ab_rd_ptr == a_wr_ptr_ab_b_bin
  wire b_empty_ab = (ab_rd_ptr == a_wr_ptr_ab_b_bin);

  // B->A direction:
  // B full: b_wr_ptr_ba - ba_rd_ptr_b_bin >= DEPTH
  wire [AWIDTH-1:0] b_full_diff_ba = b_wr_ptr_ba - ba_rd_ptr_b_bin;
  wire b_full_ba = (b_full_diff_ba >= DEPTH);

  // A empty: ba_rd_ptr == b_wr_ptr_ba_a_bin
  wire a_empty_ba = (ba_rd_ptr == b_wr_ptr_ba_a_bin);

  // A-side full: depends on direction
  // If a_dir=1 (A->B), A is writer, full = a_full_ab
  // If a_dir=0 (B->A), A is reader, full is not applicable (or 0)
  assign a_full = a_dir ? a_full_ab : 1'b0;

  // A-side empty: depends on direction
  // If a_dir=1 (A->B), A is writer, empty is not applicable (or 0)
  // If a_dir=0 (B->A), A is reader, empty = a_empty_ba
  assign a_empty = a_dir ? 1'b0 : a_empty_ba;

  // B-side full: depends on direction
  // If b_dir=1 (B->A), B is writer, full = b_full_ba
  // If b_dir=0 (A->B), B is reader, full is not applicable (or 0)
  assign b_full = b_dir ? b_full_ba : 1'b0;

  // B-side empty: depends on direction
  // If b_dir=1 (B->A), B is writer, empty is not applicable (or 0)
  // If b_dir=0 (A->B), B is reader, empty = b_empty_ab
  assign b_empty = b_dir ? 1'b0 : b_empty_ab;

  // Almost full/empty
  assign a_afull = a_dir ? (a_full_diff_ab >= AFULL_THRESH) : 1'b0;
  assign a_aempty = a_dir ? 1'b0 : (b_wr_ptr_ba_a_bin - ba_rd_ptr <= AEMPTY_THRESH);
  assign b_afull = b_dir ? (b_full_diff_ba >= AFULL_THRESH) : 1'b0;
  assign b_aempty = b_dir ? 1'b0 : (a_wr_ptr_ab_b_bin - ab_rd_ptr <= AEMPTY_THRESH);

  // A-side write (A->B direction)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr_ab <= {AWIDTH{1'b0}};
    else if (a_write_en && !a_full_ab)
      a_wr_ptr_ab <= a_wr_ptr_ab + 1'b1;
  end

  // A-side read (B->A direction)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      ba_rd_ptr <= {AWIDTH{1'b0}};
    else if (a_read_en && !a_empty_ba)
      ba_rd_ptr <= ba_rd_ptr + 1'b1;
  end

  // B-side write (B->A direction)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr_ba <= {AWIDTH{1'b0}};
    else if (b_write_en && !b_full_ba)
      b_wr_ptr_ba <= b_wr_ptr_ba + 1'b1;
  end

  // B-side read (A->B direction)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      ab_rd_ptr <= {AWIDTH{1'b0}};
    else if (b_read_en && !b_empty_ab)
      ab_rd_ptr <= ab_rd_ptr + 1'b1;
  end

  // Memory write
  // A->B: A writes to mem[a_wr_ptr_ab[ASIZE-1:0]]
  // B->A: B writes to mem[b_wr_ptr_ba[ASIZE-1:0]]
  always @(posedge a_clk) begin
    if (a_write_en && !a_full_ab)
      mem[a_wr_ptr_ab[ASIZE-1:0]] <= a_wdata;
  end

  always @(posedge b_clk) begin
    if (b_write_en && !b_full_ba)
      mem[b_wr_ptr_ba[ASIZE-1:0]] <= b_wdata;
  end

  // Memory read
  // A->B: B reads from mem[ab_rd_ptr[ASIZE-1:0]]
  // B->A: A reads from mem[ba_rd_ptr[ASIZE-1:0]]
  assign b_rdata = mem[ab_rd_ptr[ASIZE-1:0]];
  assign a_rdata = mem[ba_rd_ptr[ASIZE-1:0]];

endmodule
