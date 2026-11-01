module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  localparam DEPTH = 1 << ASIZE;
  localparam AWIDTH = ASIZE + 1;
  localparam AFULL_THRESH = DEPTH - 1;
  localparam AEMPTY_THRESH = 1;

  // Side A state
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_gray;
  reg [AWIDTH-1:0] a_rd_ptr_gray;

  // Side B state
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_gray;
  reg [AWIDTH-1:0] b_rd_ptr_gray;

  // Gray code conversion functions
  function [AWIDTH-1:0] bin2gray;
    input [AWIDTH-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  // Synchronizers for A's write pointer (to B domain)
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync3;

  // Synchronizers for A's read pointer (to B domain)
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync3;

  // Synchronizers for B's write pointer (to A domain)
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync3;

  // Synchronizers for B's read pointer (to A domain)
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync3;

  // Gray to binary conversion
  function [AWIDTH-1:0] gray2bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
  endfunction

  // Synchronized pointers in each domain
  wire [AWIDTH-1:0] a_wr_ptr_gray_b = a_wr_ptr_gray_sync3;
  wire [AWIDTH-1:0] a_rd_ptr_gray_b = a_rd_ptr_gray_sync3;
  wire [AWIDTH-1:0] b_wr_ptr_gray_a = b_wr_ptr_gray_sync3;
  wire [AWIDTH-1:0] b_rd_ptr_gray_a = b_rd_ptr_gray_sync3;

  // Convert synchronized gray pointers to binary
  wire [AWIDTH-1:0] a_wr_ptr_b = gray2bin(a_wr_ptr_gray_b);
  wire [AWIDTH-1:0] a_rd_ptr_b = gray2bin(a_rd_ptr_gray_b);
  wire [AWIDTH-1:0] b_wr_ptr_a = gray2bin(b_wr_ptr_gray_a);
  wire [AWIDTH-1:0] b_rd_ptr_a = gray2bin(b_rd_ptr_gray_a);

  // Determine effective write/read pointers based on direction
  // a_dir: 0 = A writes to B, 1 = B writes to A
  // b_dir: 0 = B writes to A, 1 = A writes to B
  // For a bidirectional FIFO, the direction determines which side is writing and which is reading.
  // Let's define:
  //   If a_dir == 0: A is the writer, B is the reader. Data flows A -> B.
  //   If a_dir == 1: B is the writer, A is the reader. Data flows B -> A.
  // Similarly for b_dir, but they should be consistent. Let's assume a_dir and b_dir are complementary or we use a_dir to determine flow.
  // Actually, looking at the ports, both sides have winc, rinc, wdata, rdata.
  // The "bidirectional" aspect means data can flow in either direction.
  // Let's interpret:
  //   a_dir = 0: A writes, B reads (A->B)
  //   a_dir = 1: B writes, A reads (B->A)
  //   b_dir should be the opposite of a_dir for consistency, but let's use a_dir as the primary control.
  //   Actually, let's re-read: "Same bidirectional FIFO rules as a two-port async FIFO."
  //   Typically, a bidirectional FIFO has a direction signal that determines the flow.
  //   Let's assume a_dir determines the direction: 0 = A to B, 1 = B to A.
  //   When a_dir = 0:
  //     - A side: write enabled by a_winc, read enabled by a_rinc (but a_rinc would be for reading from B? No.)
  //     - Actually, in a bidirectional FIFO, each side can write and read, but the direction determines which side's writes go to the other side's reads.
  //     - Let's simplify: The FIFO has a single direction. When a_dir=0, data flows from A to B. A writes, B reads.
  //     - When a_dir=1, data flows from B to A. B writes, A reads.
  //     - The winc/rinc signals on each side are only active when that side is the writer/reader respectively.
  //     - So for A:
  //       - If a_dir=0: A is writer. a_winc controls writes. a_rinc is ignored (or A is not reading).
  //       - If a_dir=1: A is reader. a_rinc controls reads. a_winc is ignored.
  //     - For B:
  //       - If a_dir=0: B is reader. b_rinc controls reads. b_winc is ignored.
  //       - If a_dir=1: B is writer. b_winc controls writes. b_rinc is ignored.
  //   But the ports have both winc and rinc on both sides. Let's assume the direction signal gates the appropriate operations.

  // Let's define the effective operations:
  wire a_is_writer = ~a_dir;
  wire a_is_reader = a_dir;
  wire b_is_writer = a_dir;
  wire b_is_reader = ~a_dir;

  wire a_write_en = a_is_writer & a_winc;
  wire a_read_en  = a_is_reader & a_rinc;
  wire b_write_en = b_is_writer & b_winc;
  wire b_read_en  = b_is_reader & b_rinc;

  // Pointer updates
  // A's write pointer increments when A writes
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AWIDTH{1'b0}};
    else if (a_write_en)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  // A's read pointer increments when A reads
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr <= {AWIDTH{1'b0}};
    else if (a_read_en)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  // B's write pointer increments when B writes
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AWIDTH{1'b0}};
    else if (b_write_en)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // B's read pointer increments when B reads
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
    b_rd_ptr <= {AWIDTH{1'b0}};
    else if (b_read_en)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // Gray code pointers
  always @(*) begin
    a_wr_ptr_gray = bin2gray(a_wr_ptr);
    a_rd_ptr_gray = bin2gray(a_rd_ptr);
    b_wr_ptr_gray = bin2gray(b_wr_ptr);
    b_rd_ptr_gray = bin2gray(b_rd_ptr);
  end

  // Synchronizers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      a_wr_ptr_gray_sync3 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync3 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
      a_wr_ptr_gray_sync3 <= a_wr_ptr_gray_sync2;
      a_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
      a_rd_ptr_gray_sync3 <= a_rd_ptr_gray_sync2;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      b_wr_ptr_gray_sync3 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync3 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
      b_wr_ptr_gray_sync3 <= b_wr_ptr_gray_sync2;
      b_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
      b_rd_ptr_gray_sync3 <= b_rd_ptr_gray_sync2;
    end
  end

  // Full/Empty flags
  // For A->B direction (a_dir=0):
  //   A is writer, B is reader.
  //   A full: a_wr_ptr - b_rd_ptr_a >= DEPTH - 1 (but b_rd_ptr_a is B's read pointer as seen by A)
  //   Wait, when A writes and B reads, the FIFO is full when A's write pointer is one ahead of B's read pointer.
  //   The read pointer that matters for A's full flag is B's read pointer (since B is reading).
  //   So a_full = (a_wr_ptr - b_rd_ptr_a) >= DEPTH - 1
  //   a_empty = (a_wr_ptr == b_rd_ptr_a)
  // For B->A direction (a_dir=1):
  //   B is writer, A is reader.
  //   B full: b_wr_ptr - a_rd_ptr_b >= DEPTH - 1
  //   B empty: b_wr_ptr == a_rd_ptr_b
  //   A full: not applicable (A is reader)
  //   A empty: a_rd_ptr == b_wr_ptr_a

  wire [AWIDTH-1:0] a_wr_minus_b_rd = a_wr_ptr - b_rd_ptr_a;
  wire [AWIDTH-1:0] b_wr_minus_a_rd = b_wr_ptr - a_rd_ptr_b;

  wire a_full_raw = (a_wr_minus_b_rd >= (DEPTH - 1));
  wire a_empty_raw = (a_wr_ptr == b_rd_ptr_a);
  wire b_full_raw = (b_wr_minus_a_rd >= (DEPTH - 1));
  wire b_empty_raw = (b_wr_ptr == a_rd_ptr_b);

  // Apply direction
  assign a_full = a_is_writer ? a_full_raw : 1'b0;
  assign a_empty = a_is_reader ? a_empty_raw : 1'b0;
  assign b_full = b_is_writer ? b_full_raw : 1'b0;
  assign b_empty = b_is_reader ? b_empty_raw : 1'b0;

  // Almost full/empty
  assign a_afull = a_is_writer ? (a_wr_minus_b_rd >= (DEPTH - 2)) : 1'b0;
  assign a_aempty = a_is_reader ? (a_wr_minus_b_rd <= 1) : 1'b0;
  assign b_afull = b_is_writer ? (b_wr_minus_a_rd >= (DEPTH - 2)) : 1'b0;
  assign b_aempty = b_is_reader ? (b_wr_minus_a_rd <= 1) : 1'b0;

  // RAM interface
  // o_ram_a_clk = a_clk
  // o_ram_b_clk = b_clk
  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  // A side RAM:
  // When A writes (a_write_en), write to RAM A at address a_wr_ptr[ASIZE-1:0]
  // When A reads (a_read_en), read from RAM A at address a_rd_ptr[ASIZE-1:0]
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc = a_write_en;
  assign o_ram_a_rinc = a_read_en;
  assign a_rdata = i_ram_a_rdata;

  // B side RAM:
  // When B writes (b_write_en), write to RAM B at address b_wr_ptr[ASIZE-1:0]
  // When B reads (b_read_en), read from RAM B at address b_rd_ptr[ASIZE-1:0]
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc = b_write_en;
  assign o_ram_b_rinc = b_read_en;
  assign b_rdata = i_ram_b_rdata;

endmodule
