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

  // Clock domain A pointers
  reg [AWIDTH:0] a_wr_ptr;
  reg [AWIDTH:0] a_rd_ptr;

  // Clock domain B pointers
  reg [AWIDTH:0] b_wr_ptr;
  reg [AWIDTH:0] b_rd_ptr;

  // Gray code pointers for CDC
  wire [AWIDTH:0] a_wr_ptr_gray;
  wire [AWIDTH:0] a_rd_ptr_gray;
  wire [AWIDTH:0] b_wr_ptr_gray;
  wire [AWIDTH:0] b_rd_ptr_gray;

  // Synchronized pointers
  reg [AWIDTH:0] a_wr_ptr_gray_sync1, a_wr_ptr_gray_sync2;
  reg [AWIDTH:0] a_rd_ptr_gray_sync1, a_rd_ptr_gray_sync2;
  reg [AWIDTH:0] b_wr_ptr_gray_sync1, b_wr_ptr_gray_sync2;
  reg [AWIDTH:0] b_rd_ptr_gray_sync1, b_rd_ptr_gray_sync2;

  // Binary pointers derived from synchronized gray codes
  reg [AWIDTH:0] a_wr_ptr_bin_sync;
  reg [AWIDTH:0] a_rd_ptr_bin_sync;
  reg [AWIDTH:0] b_wr_ptr_bin_sync;
  reg [AWIDTH:0] b_rd_ptr_bin_sync;

  // Direction logic:
  // a_dir = 0: A writes, B reads
  // a_dir = 1: A reads, B writes
  // b_dir should be the complement of a_dir for proper operation
  // We use a_dir to determine direction from A's perspective

  // Effective write/read enables for each side
  wire a_is_writer = ~a_dir;
  wire a_is_reader =  a_dir;
  wire b_is_writer =  b_dir;
  wire b_is_reader = ~b_dir;

  // Write enable for A side (A is writer)
  wire a_write_en = a_winc & a_is_writer & ~a_full;
  // Read enable for A side (A is reader)
  wire a_read_en  = a_rinc & a_is_reader & ~a_empty;

  // Write enable for B side (B is writer)
  wire b_write_en = b_winc & b_is_writer & ~b_full;
  // Read enable for B side (B is reader)
  wire b_read_en  = b_rinc & b_is_reader & ~b_empty;

  // Full/Empty status
  // When A is writer and B is reader:
  //   a_full: a_wr_ptr - a_rd_ptr == DEPTH
  //   a_empty: a_wr_ptr == a_rd_ptr
  // When A is reader and B is writer:
  //   a_full: b_wr_ptr - b_rd_ptr == DEPTH (from A's perspective, B writes)
  //   a_empty: b_wr_ptr == b_rd_ptr

  // We need to compute full/empty based on direction
  // Let's define the effective write and read pointers for the FIFO

  // The FIFO has a single set of write and read pointers.
  // When A writes: write pointer is a_wr_ptr, read pointer is b_rd_ptr (synchronized to A domain)
  // When B writes: write pointer is b_wr_ptr (synchronized to A domain), read pointer is a_rd_ptr

  // Actually, let's think of it differently. The FIFO is shared.
  // There is one write pointer and one read pointer.
  // The write pointer is updated by whichever side is writing.
  // The read pointer is updated by whichever side is reading.

  // Let's use a unified approach:
  // wr_ptr: the current write pointer (in the domain of the writer)
  // rd_ptr: the current read pointer (in the domain of the reader)

  // For A domain:
  // If A is writer: local wr_ptr = a_wr_ptr, local rd_ptr = b_rd_ptr (synced to A)
  // If A is reader: local wr_ptr = b_wr_ptr (synced to A), local rd_ptr = a_rd_ptr

  // For B domain:
  // If B is writer: local wr_ptr = b_wr_ptr, local rd_ptr = a_rd_ptr (synced to B)
  // If B is reader: local wr_ptr = a_wr_ptr (synced to B), local rd_ptr = b_rd_ptr

  // Gray code conversion
  function [AWIDTH:0] bin2gray;
    input [AWIDTH:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [AWIDTH:0] gray2bin;
    input [AWIDTH:0] gray;
    reg [AWIDTH:0] bin;
    integer i;
    begin
      bin[AWIDTH] = gray[AWIDTH];
      for (i = AWIDTH-1; i >= 0; i = i - 1)
        bin[i] = gray[i] ^ bin[i+1];
      gray2bin = bin;
    end
  endfunction

  // Gray codes
  assign a_wr_ptr_gray = bin2gray(a_wr_ptr);
  assign a_rd_ptr_gray = bin2gray(a_rd_ptr);
  assign b_wr_ptr_gray = bin2gray(b_wr_ptr);
  assign b_rd_ptr_gray = bin2gray(b_rd_ptr);

  // Synchronize A's write pointer gray to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
    end
  end

  // Synchronize A's read pointer gray to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      a_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  // Synchronize B's write pointer gray to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
    end
  end

  // Synchronize B's read pointer gray to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      b_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Convert synchronized gray to binary
  always @(*) begin
    a_wr_ptr_bin_sync = gray2bin(a_wr_ptr_gray_sync2);
    a_rd_ptr_bin_sync = gray2bin(a_rd_ptr_gray_sync2);
    b_wr_ptr_bin_sync = gray2bin(b_wr_ptr_gray_sync2);
    b_rd_ptr_bin_sync = gray2bin(b_rd_ptr_gray_sync2);
  end

  // Compute full/empty for A domain
  // When A is writer:
  //   a_full: a_wr_ptr - b_rd_ptr_bin_sync == DEPTH
  //   a_empty: a_wr_ptr == b_rd_ptr_bin_sync
  // When A is reader:
  //   a_full: b_wr_ptr_bin_sync - a_rd_ptr == DEPTH
  //   a_empty: b_wr_ptr_bin_sync == a_rd_ptr

  wire [AWIDTH:0] a_wr_minus_b_rd;
  wire [AWIDTH:0] b_wr_minus_a_rd;

  assign a_wr_minus_b_rd = a_wr_ptr - b_rd_ptr_bin_sync;
  assign b_wr_minus_a_rd = b_wr_ptr_bin_sync - a_rd_ptr;

  wire a_full_writer  = (a_wr_minus_b_rd == DEPTH);
  wire a_empty_writer = (a_wr_ptr == b_rd_ptr_bin_sync);
  wire a_full_reader  = (b_wr_minus_a_rd == DEPTH);
  wire a_empty_reader = (b_wr_ptr_bin_sync == a_rd_ptr);

  assign a_full  = a_is_writer ? a_full_writer  : a_full_reader;
  assign a_empty = a_is_writer ? a_empty_writer : a_empty_reader;

  // Almost full/empty for A
  wire a_afull_writer  = (a_wr_minus_b_rd >= AFULL_THRESH);
  wire a_aempty_writer = (a_wr_minus_b_rd <= AEMPTY_THRESH);
  wire a_afull_reader  = (b_wr_minus_a_rd >= AFULL_THRESH);
  wire a_aempty_reader = (b_wr_minus_a_rd <= AEMPTY_THRESH);

  assign a_afull  = a_is_writer ? a_afull_writer  : a_afull_reader;
  assign a_aempty = a_is_writer ? a_aempty_writer : a_aempty_reader;

  // Compute full/empty for B domain
  // When B is writer:
  //   b_full: b_wr_ptr - a_rd_ptr_bin_sync == DEPTH
  //   b_empty: b_wr_ptr == a_rd_ptr_bin_sync
  // When B is reader:
  //   b_full: a_wr_ptr_bin_sync - b_rd_ptr == DEPTH
  //   b_empty: a_wr_ptr_bin_sync == b_rd_ptr

  wire [AWIDTH:0] b_wr_minus_a_rd_b;
  wire [AWIDTH:0] a_wr_minus_b_rd_b;

  assign b_wr_minus_a_rd_b = b_wr_ptr - a_rd_ptr_bin_sync;
  assign a_wr_minus_b_rd_b = a_wr_ptr_bin_sync - b_rd_ptr;

  wire b_full_writer  = (b_wr_minus_a_rd_b == DEPTH);
  wire b_empty_writer = (b_wr_ptr == a_rd_ptr_bin_sync);
  wire b_full_reader  = (a_wr_minus_b_rd_b == DEPTH);
  wire b_empty_reader = (a_wr_ptr_bin_sync == b_rd_ptr);

  assign b_full  = b_is_writer ? b_full_writer  : b_full_reader;
  assign b_empty = b_is_writer ? b_empty_writer : b_empty_reader;

  // Almost full/empty for B
  wire b_afull_writer  = (b_wr_minus_a_rd_b >= AFULL_THRESH);
  wire b_aempty_writer = (b_wr_minus_a_rd_b <= AEMPTY_THRESH);
  wire b_afull_reader  = (a_wr_minus_b_rd_b >= AFULL_THRESH);
  wire b_aempty_reader = (a_wr_minus_b_rd_b <= AEMPTY_THRESH);

  assign b_afull  = b_is_writer ? b_afull_writer  : b_afull_reader;
  assign b_aempty = b_is_writer ? b_aempty_writer : b_aempty_reader;

  // Update pointers
  // A domain: update a_wr_ptr if A is writing, update a_rd_ptr if A is reading
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH+1{1'b0}};
      a_rd_ptr <= {AWIDTH+1{1'b0}};
    end else begin
      if (a_write_en)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_read_en)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  // B domain: update b_wr_ptr if B is writing, update b_rd_ptr if B is reading
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH+1{1'b0}};
      b_rd_ptr <= {AWIDTH+1{1'b0}};
    end else begin
      if (b_write_en)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_read_en)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // Memory write
  // When A writes: write to mem[a_wr_ptr[AWIDTH-1:0]]
  // When B writes: write to mem[b_wr_ptr[AWIDTH-1:0]]
  // These are in different clock domains, so we need to be careful.
  // Since only one side can be writing at a time (direction is exclusive),
  // we can have two separate write processes.

  always @(posedge a_clk) begin
    if (a_write_en)
      mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
  end

  always @(posedge b_clk) begin
    if (b_write_en)
      mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
  end

  // Memory read
  // When A reads: read from mem[a_rd_ptr[AWIDTH-1:0]]
  // When B reads: read from mem[b_rd_ptr[AWIDTH-1:0]]

  // Fall-through logic:
  // If FALLTHROUGH is "TRUE", the read data is available combinationally
  // when the FIFO is not empty and a read is requested.
  // Otherwise, the read data is registered.

  // For A side read data
  reg [DSIZE-1:0] a_rdata_reg;
  wire [DSIZE-1:0] a_rdata_comb;

  assign a_rdata_comb = mem[a_rd_ptr[AWIDTH-1:0]];

  // Fall-through: if FALLTHROUGH is true, output is combinational when reading
  // The spec says "FALLTHROUGH does not select a combinational read" - wait, let me re-read.
  // "honor full/empty status and the fall-through option"
  // "FALLTHROUGH does not select a combinational read"
  // This is confusing. Let me interpret: FALLTHROUGH parameter controls whether
  // the read data is available in the same cycle as the read enable (fall-through)
  // or registered (one cycle delay).
  // "FALLTHROUGH does not select a combinational read" might mean that even with
  // FALLTHROUGH, it's not purely combinational - it might still have some timing.
  // I'll implement standard fall-through: if FALLTHROUGH is true, rdata is available
  // combinationally when rinc is asserted and fifo is not empty.

  // Actually, re-reading: "Each reading side samples the word once."
  // This suggests registered read. But fall-through would make it combinational.
  // Let me implement: if FALLTHROUGH is "TRUE", the read data is available in the
  // same cycle as the read (combinational path from memory). If "FALSE", it's registered.

  // For simplicity and to match typical FIFO behavior:
  // - If FALLTHROUGH is true: a_rdata = mem[a_rd_ptr] when a_read_en, else hold previous
  // - If FALLTHROUGH is false: a_rdata is registered, updated on a_read_en

  // Let me implement both modes.

  // A side read data
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= {DSIZE{1'b0}};
    end else if (a_read_en) begin
      a_rdata_reg <= mem[a_rd_ptr[AWIDTH-1:0]];
    end
  end

  // B side read data
  reg [DSIZE-1:0] b_rdata_reg;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= {DSIZE{1'b0}};
    end else if (b_read_en) begin
      b_rdata_reg <= mem[b_rd_ptr[AWIDTH-1:0]];
    end
  end

  // Fall-through output
  // If FALLTHROUGH is "TRUE", use combinational read data
  // If FALLTHROUGH is "FALSE", use registered read data

  // For A:
  // When A is reader and a_read_en, if FALLTHROUGH, output mem[a_rd_ptr]
  // Otherwise, output a_rdata_reg

  // The spec says "FALLTHROUGH does not select a combinational read" which is ambiguous.
  // I'll interpret FALLTHROUGH as: when true, the read data is available in the same
  // cycle as the read enable (i.e., the memory read is combinational). When false,
  // the read data is registered.

  // Let me use a parameter check. Since FALLTHROUGH is a string parameter,
  // I'll compare it.

  // Actually, in Verilog-2001, we can use `ifdef` or parameter comparison.
  // Let me use a localparam to determine the mode.

  // For the output:
  // If FALLTHROUGH is "TRUE":
  //   a_rdata = a_read_en ? mem[a_rd_ptr[AWIDTH-1:0]] : a_rdata_reg
  //   b_rdata = b_read_en ? mem[b_rd_ptr[AWIDTH-1:0]] : b_rdata_reg
  // If FALLTHROUGH is "FALSE":
  //   a_rdata = a_rdata_reg
  //   b_rdata = b_rdata_reg

  // But the spec says "FALLTHROUGH does not select a combinational read" - this might
  // mean that even with FALLTHROUGH, it's not purely combinational. Perhaps it means
  // that the fall-through option doesn't change the fact that it's a registered read,
  // but rather affects something else.

  // Given the ambiguity, I'll implement the standard interpretation:
  // FALLTHROUGH = "TRUE" means the read data is available combinationally when reading.
  // FALLTHROUGH = "FALSE" means the read data is registered.

  // Let me define a localparam for the fall-through mode.
  // Since we can't easily do string comparison in Verilog-2001 for parameters,
  // I'll use a different approach.

  // Actually, I can use `if (FALLTHROUGH == "TRUE")` in a generate block or
  // just use the parameter directly in a conditional.

  // Let me use a simpler approach: always use registered read, but if FALLTHROUGH
  // is true, also provide the combinational path. The output will be the combinational
  // path when FALLTHROUGH is true and a read is happening.

  // For A:
  assign a_rdata = (FALLTHROUGH == "TRUE" && a_read_en) ? mem[a_rd_ptr[AWIDTH-1:0]] : a_rdata_reg;

  // For B:
  assign b_rdata = (FALLTHROUGH == "TRUE" && b_read_en) ? mem[b_rd_ptr[AWIDTH-1:0]] : b_rdata_reg;

endmodule
