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
  localparam AFW   = ASIZE + 1;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Shared memory
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // A-side FIFO (A writes, B reads)
  reg [AFW-1:0] a_wr_ptr;
  reg [AFW-1:0] a_rd_ptr;
  reg [AFW-1:0] a_rd_ptr_sync1, a_rd_ptr_sync2;
  reg [AFW-1:0] a_wr_ptr_sync1, a_wr_ptr_sync2;

  // B-side FIFO (B writes, A reads)
  reg [AFW-1:0] b_wr_ptr;
  reg [AFW-1:0] b_rd_ptr;
  reg [AFW-1:0] b_rd_ptr_sync1, b_rd_ptr_sync2;
  reg [AFW-1:0] b_wr_ptr_sync1, b_wr_ptr_sync2;

  // A-side status
  wire [AFW-1:0] a_wr_ptr_gray;
  wire [AFW-1:0] a_rd_ptr_gray;
  wire [AFW-1:0] a_wr_ptr_gray_sync;
  wire [AFW-1:0] a_rd_ptr_gray_sync;

  // B-side status
  wire [AFW-1:0] b_wr_ptr_gray;
  wire [AFW-1:0] b_rd_ptr_gray;
  wire [AFW-1:0] b_wr_ptr_gray_sync;
  wire [AFW-1:0] b_rd_ptr_gray_sync;

  // Gray code conversion
  function [AFW-1:0] bin2gray;
    input [AFW-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [AFW-1:0] gray2bin;
    input [AFW-1:0] gray;
    integer i;
    begin
      gray2bin[AFW-1] = gray[AFW-1];
      for (i = AFW-2; i >= 0; i = i - 1)
        gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
  endfunction

  // A-side FIFO: A writes, B reads
  assign a_wr_ptr_gray = bin2gray(a_wr_ptr);
  assign a_rd_ptr_gray = bin2gray(a_rd_ptr);

  // Synchronize A's read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync1 <= {AFW{1'b0}};
      a_rd_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      a_rd_ptr_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
    end
  end

  // Synchronize A's write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AFW{1'b0}};
      a_wr_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
    end
  end

  // B-side FIFO: B writes, A reads
  assign b_wr_ptr_gray = bin2gray(b_wr_ptr);
  assign b_rd_ptr_gray = bin2gray(b_rd_ptr);

  // Synchronize B's read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync1 <= {AFW{1'b0}};
      b_rd_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      b_rd_ptr_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
    end
  end

  // Synchronize B's write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AFW{1'b0}};
      b_wr_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
    end
  end

  // A-side FIFO status (in A domain)
  wire [AFW-1:0] a_wr_ptr_gray_sync = a_wr_ptr_sync2; // Not used directly, but for clarity
  wire [AFW-1:0] a_rd_ptr_gray_sync = a_rd_ptr_sync2;

  // For A-side FIFO: A is writer, B is reader
  // A sees its own write pointer and B's read pointer (synced to A domain)
  // Wait, I need to be careful. Let me re-think.

  // A-side FIFO: A writes, B reads
  // A domain: A has write pointer. B's read pointer needs to be synced to A domain.
  // B domain: B has read pointer. A's write pointer needs to be synced to B domain.

  // So in A domain:
  //   a_wr_ptr is local
  //   b_rd_ptr_sync2 is B's read pointer synced to A domain
  //   a_full = (a_wr_ptr == b_rd_ptr_sync2) with wrap-around check
  //   a_empty = (a_wr_ptr == b_rd_ptr_sync2)

  // In B domain:
  //   b_rd_ptr is local
  //   a_wr_ptr_sync2 is A's write pointer synced to B domain
  //   b_full = (b_rd_ptr == a_wr_ptr_sync2) with wrap-around check
  //   b_empty = (b_rd_ptr == a_wr_ptr_sync2)

  // Let me redo the synchronization properly.

  // A-side FIFO: A writes, B reads
  // Sync A's write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AFW{1'b0}};
      a_wr_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
    end
  end

  // Sync B's read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync1 <= {AFW{1'b0}};
      b_rd_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      b_rd_ptr_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
    end
  end

  // B-side FIFO: B writes, A reads
  // Sync B's write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AFW{1'b0}};
      b_wr_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
    end
  end

  // Sync A's read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync1 <= {AFW{1'b0}};
      a_rd_ptr_sync2 <= {AFW{1'b0}};
    end else begin
      a_rd_ptr_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
    end
  end

  // A-side FIFO status (A domain)
  // A is writer, B is reader
  // a_full: A's write pointer catches up to B's read pointer
  // a_empty: A's write pointer equals B's read pointer
  wire [AFW-1:0] a_fifo_wr_ptr = a_wr_ptr;
  wire [AFW-1:0] a_fifo_rd_ptr = b_rd_ptr_sync2;

  wire a_fifo_full = (a_fifo_wr_ptr[AFW-1] == a_fifo_rd_ptr[AFW-1]) &&
                     (a_fifo_wr_ptr[AFW-2:0] == a_fifo_rd_ptr[AFW-2:0]);
  wire a_fifo_empty = a_fifo_full;

  // B-side FIFO status (B domain)
  // B is writer, A is reader
  wire [AFW-1:0] b_fifo_wr_ptr = b_wr_ptr;
  wire [AFW-1:0] b_fifo_rd_ptr = a_rd_ptr_sync2;

  wire b_fifo_full = (b_fifo_wr_ptr[AFW-1] == b_fifo_rd_ptr[AFW-1]) &&
                     (b_fifo_wr_ptr[AFW-2:0] == b_fifo_rd_ptr[AFW-2:0]);
  wire b_fifo_empty = b_fifo_full;

  // Almost full/empty
  wire [AFW-1:0] a_fifo_diff = a_fifo_wr_ptr - a_fifo_rd_ptr;
  wire [AFW-1:0] b_fifo_diff = b_fifo_wr_ptr - b_fifo_rd_ptr;

  wire a_afull = (a_fifo_diff >= AFULL_THRESH);
  wire a_aempty = (a_fifo_diff <= AEMPTY_THRESH);
  wire b_afull = (b_fifo_diff >= AFULL_THRESH);
  wire b_aempty = (b_fifo_diff <= AEMPTY_THRESH);

  // A-side write (A writes to A-side FIFO)
  wire a_write_en = a_winc && !a_fifo_full;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AFW{1'b0}};
    else if (a_write_en)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  always @(posedge a_clk) begin
    if (a_write_en)
      mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // B-side read from A-side FIFO (B reads from A-side FIFO)
  wire b_read_a_en = b_rinc && !a_fifo_empty;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr <= {AFW{1'b0}};
    else if (b_read_a_en)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // A-side read from B-side FIFO (A reads from B-side FIFO)
  wire a_read_b_en = a_rinc && !b_fifo_empty;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr <= {AFW{1'b0}};
    else if (a_read_b_en)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  // B-side write (B writes to B-side FIFO)
  wire b_write_en = b_winc && !b_fifo_full;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AFW{1'b0}};
    else if (b_write_en)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  always @(posedge b_clk) begin
    if (b_write_en)
      mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // Read data
  // A reads from B-side FIFO
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else
      a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
  end

  // B reads from A-side FIFO
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else
      b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
  end

  // Direction-based output selection
  // a_dir: 0 = A reads from B-side FIFO, 1 = A reads from A-side FIFO? 
  // Actually, let me re-read the problem.
  // "Move words in either direction, as selected on each side."
  // a_dir and b_dir select the direction.
  // I think a_dir selects whether A is writing or reading, and b_dir similarly.
  // But the interface has separate winc/rinc for each side.
  // Let me assume:
  //   a_dir = 0: A is in read mode (a_rinc is valid, a_winc ignored)
  //   a_dir = 1: A is in write mode (a_winc is valid, a_rinc ignored)
  //   b_dir = 0: B is in read mode (b_rinc is valid, b_winc ignored)
  //   b_dir = 1: B is in write mode (b_winc is valid, b_rinc ignored)

  // But that doesn't quite make sense for a bidirectional FIFO.
  // Let me reconsider. Perhaps:
  //   a_dir = 0: A writes to the FIFO (A->B direction)
  //   a_dir = 1: A reads from the FIFO (B->A direction)
  //   b_dir = 0: B writes to the FIFO (B->A direction)
  //   b_dir = 1: B reads from the FIFO (A->B direction)

  // So:
  //   A writes when a_dir=0 and a_winc
  //   A reads when a_dir=1 and a_rinc
  //   B writes when b_dir=0 and b_winc
  //   B reads when b_dir=1 and b_rinc

  // Let me redo the logic with this interpretation.

  // A-side write enable (A writes to A->B FIFO)
  wire a_write_en2 = (a_dir == 1'b0) && a_winc && !a_fifo_full;
  // A-side read enable (A reads from B->A FIFO)
  wire a_read_b_en2 = (a_dir == 1'b1) && a_rinc && !b_fifo_empty;

  // B-side write enable (B writes to B->A FIFO)
  wire b_write_en2 = (b_dir == 1'b0) && b_winc && !b_fifo_full;
  // B-side read enable (B reads from A->B FIFO)
  wire b_read_a_en2 = (b_dir == 1'b1) && b_rinc && !a_fifo_empty;

  // Update pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AFW{1'b0}};
      a_rd_ptr <= {AFW{1'b0}};
    end else begin
      if (a_write_en2)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_read_b_en2)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AFW{1'b0}};
      b_rd_ptr <= {AFW{1'b0}};
    end else begin
      if (b_write_en2)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_read_a_en2)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // Memory writes
  always @(posedge a_clk) begin
    if (a_write_en2)
      mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  always @(posedge b_clk) begin
    if (b_write_en2)
      mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // Read data
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else
      a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else
      b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
  end

  // Output assignments
  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

  assign a_full   = a_fifo_full;
  assign a_afull  = a_afull;
  assign a_empty  = a_fifo_empty;
  assign a_aempty = a_aempty;

  assign b_full   = b_fifo_full;
  assign b_afull  = b_afull;
  assign b_empty  = b_fifo_empty;
  assign b_aempty = b_aempty;

endmodule
