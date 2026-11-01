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
  localparam AWIDTH_M1 = ASIZE;
  localparam AWIDTH_M2 = ASIZE - 1;

  // Gray code conversion functions
  function [AWIDTH-1:0] bin2gray;
    input [AWIDTH-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [AWIDTH-1:0] gray2bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
  endfunction

  // Side A registers
  reg [AWIDTH-1:0] a_wr_ptr_bin;
  reg [AWIDTH-1:0] a_rd_ptr_bin;
  reg [AWIDTH-1:0] a_wr_ptr_gray;
  reg [AWIDTH-1:0] a_rd_ptr_gray;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync2;

  // Side B registers
  reg [AWIDTH-1:0] b_wr_ptr_bin;
  reg [AWIDTH-1:0] b_rd_ptr_bin;
  reg [AWIDTH-1:0] b_wr_ptr_gray;
  reg [AWIDTH-1:0] b_rd_ptr_gray;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync2;

  // Derived signals
  wire [AWIDTH-1:0] a_wr_ptr_gray_next;
  wire [AWIDTH-1:0] a_rd_ptr_gray_next;
  wire [AWIDTH-1:0] b_wr_ptr_gray_next;
  wire [AWIDTH-1:0] b_rd_ptr_gray_next;

  wire a_wr_en;
  wire a_rd_en;
  wire b_wr_en;
  wire b_rd_en;

  wire a_full;
  wire a_empty;
  wire b_full;
  wire b_empty;

  wire a_afull;
  wire a_aempty;
  wire b_afull;
  wire b_aempty;

  // RAM interface signals
  wire o_ram_a_clk;
  wire o_ram_b_clk;
  wire [ASIZE-1:0] o_ram_a_addr;
  wire [ASIZE-1:0] o_ram_b_addr;
  wire [DSIZE-1:0] o_ram_a_wdata;
  wire [DSIZE-1:0] o_ram_b_wdata;
  wire o_ram_a_rinc;
  wire o_ram_a_winc;
  wire o_ram_b_rinc;
  wire o_ram_b_winc;

  // Assign RAM clocks
  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  // Side A logic
  assign a_wr_en = a_winc & ~a_full;
  assign a_rd_en = a_rinc & ~a_empty;

  assign a_wr_ptr_gray_next = bin2gray(a_wr_ptr_bin + 1'b1);
  assign a_rd_ptr_gray_next = bin2gray(a_rd_ptr_bin + 1'b1);

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_bin <= {AWIDTH{1'b0}};
      a_rd_ptr_bin <= {AWIDTH{1'b0}};
      a_wr_ptr_gray <= {AWIDTH{1'b0}};
      a_rd_ptr_gray <= {AWIDTH{1'b0}};
    end else begin
      if (a_wr_en) begin
        a_wr_ptr_bin <= a_wr_ptr_bin + 1'b1;
        a_wr_ptr_gray <= a_wr_ptr_gray_next;
      end
      if (a_rd_en) begin
        a_rd_ptr_bin <= a_rd_ptr_bin + 1'b1;
        a_rd_ptr_gray <= a_rd_ptr_gray_next;
      end
    end
  end

  // Side B logic
  assign b_wr_en = b_winc & ~b_full;
  assign b_rd_en = b_rinc & ~b_empty;

  assign b_wr_ptr_gray_next = bin2gray(b_wr_ptr_bin + 1'b1);
  assign b_rd_ptr_gray_next = bin2gray(b_rd_ptr_bin + 1'b1);

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_bin <= {AWIDTH{1'b0}};
      b_rd_ptr_bin <= {AWIDTH{1'b0}};
      b_wr_ptr_gray <= {AWIDTH{1'b0}};
      b_rd_ptr_gray <= {AWIDTH{1'b0}};
    end else begin
      if (b_wr_en) begin
        b_wr_ptr_bin <= b_wr_ptr_bin + 1'b1;
        b_wr_ptr_gray <= b_wr_ptr_gray_next;
      end
      if (b_rd_en) begin
        b_rd_ptr_bin <= b_rd_ptr_bin + 1'b1;
        b_rd_ptr_gray <= b_rd_ptr_gray_next;
      end
    end
  end

  // CDC synchronization for A's write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
    end
  end

  // CDC synchronization for A's read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  // CDC synchronization for B's write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
    end
  end

  // CDC synchronization for B's read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Convert synchronized gray codes back to binary
  wire [AWIDTH-1:0] a_wr_ptr_gray_sync2_bin;
  wire [AWIDTH-1:0] a_rd_ptr_gray_sync2_bin;
  wire [AWIDTH-1:0] b_wr_ptr_gray_sync2_bin;
  wire [AWIDTH-1:0] b_rd_ptr_gray_sync2_bin;

  assign a_wr_ptr_gray_sync2_bin = gray2bin(a_wr_ptr_gray_sync2);
  assign a_rd_ptr_gray_sync2_bin = gray2bin(a_rd_ptr_gray_sync2);
  assign b_wr_ptr_gray_sync2_bin = gray2bin(b_wr_ptr_gray_sync2);
  assign b_rd_ptr_gray_sync2_bin = gray2bin(b_rd_ptr_gray_sync2);

  // Full/Empty logic
  // A side: A writes, B reads
  // A is full when A's write pointer has caught up to B's read pointer (in B's view)
  // A is empty when A's read pointer equals A's write pointer
  // B side: B writes, A reads
  // B is full when B's write pointer has caught up to A's read pointer (in A's view)
  // B is empty when B's read pointer equals B's write pointer

  // For A:
  // a_full: A's write pointer (gray) == B's read pointer (gray) as seen in B domain? 
  // Actually, standard async FIFO:
  // A writes to RAM, B reads from RAM.
  // A's write pointer is in A domain. B's read pointer is in B domain.
  // To determine if A is full, we need to compare A's write pointer with B's read pointer.
  // But they are in different domains.
  // Standard approach: 
  //   - A's write pointer is synchronized to B domain.
  //   - B's read pointer is in B domain.
  //   - In B domain, compare synced A_wr_ptr with B_rd_ptr. If equal, A is full? No.
  //   - Actually, for a FIFO where A writes and B reads:
  //     - Full condition: A's write pointer has wrapped around and caught up to B's read pointer.
  //     - We synchronize A's write pointer to B domain, and compare with B's read pointer.
  //     - But wait, the full flag is generated in A domain typically.
  //   
  // Let me reconsider. In a standard async FIFO:
  //   - Write pointer is in write domain.
  //   - Read pointer is in read domain.
  //   - To generate full flag in write domain: synchronize read pointer to write domain, compare with write pointer.
  //   - To generate empty flag in read domain: synchronize write pointer to read domain, compare with read pointer.
  //
  // So for A (write side):
  //   - a_full: compare a_wr_ptr_bin with b_rd_ptr_gray_sync2_bin (B's read pointer synced to A domain)
  //   - a_empty: compare a_rd_ptr_bin with a_wr_ptr_bin (both in A domain)
  //
  // For B (read side):
  //   - b_empty: compare b_rd_ptr_bin with a_wr_ptr_gray_sync2_bin (A's write pointer synced to B domain)
  //   - b_full: compare b_wr_ptr_bin with a_rd_ptr_gray_sync2_bin (A's read pointer synced to B domain)

  assign a_full = (a_wr_ptr_bin == b_rd_ptr_gray_sync2_bin);
  assign a_empty = (a_rd_ptr_bin == a_wr_ptr_bin);

  assign b_empty = (b_rd_ptr_bin == a_wr_ptr_gray_sync2_bin);
  assign b_full = (b_wr_ptr_bin == a_rd_ptr_gray_sync2_bin);

  // Almost full/empty
  assign a_afull = a_full | (a_wr_ptr_bin == (b_rd_ptr_gray_sync2_bin + 1'b1));
  assign a_aempty = a_empty | (a_rd_ptr_bin == (a_wr_ptr_bin + 1'b1));

  assign b_afull = b_full | (b_wr_ptr_bin == (a_rd_ptr_gray_sync2_bin + 1'b1));
  assign b_aempty = b_empty | (b_rd_ptr_bin == (a_wr_ptr_gray_sync2_bin + 1'b1));

  // RAM interface
  // A side: A writes to RAM, B reads from RAM
  // o_ram_a_winc: A is writing
  // o_ram_a_rinc: B is reading (but this is in B domain, so we need to handle this)
  // Actually, the RAM has two ports. Port A is used by A for writes and by B for reads? 
  // No, typically in a dual-port RAM, each port is independent.
  // Let me re-read the problem.
  // "external dual-port RAM interface"
  // o_ram_a_* and o_ram_b_* are separate ports.
  // So A uses port A for both read and write? Or A writes to port A and reads from port B?
  // Given the signals:
  //   o_ram_a_wdata, o_ram_a_addr, o_ram_a_winc: A writes to RAM port A
  //   o_ram_a_rinc: A reads from RAM port A? But i_ram_a_rdata is the read data for port A.
  //   o_ram_b_wdata, o_ram_b_addr, o_ram_b_winc: B writes to RAM port B
  //   o_ram_b_rinc: B reads from RAM port B? But i_ram_b_rdata is the read data for port B.
  //
  // This suggests that A writes to RAM port A and reads from RAM port A? That doesn't make sense for a FIFO.
  // Alternatively, A writes to RAM port A, and B reads from RAM port A. But then o_ram_b_* would be unused?
  // Or A writes to RAM port A, B writes to RAM port B, and reads are from the other port?
  //
  // Let me think about this differently. In a bidirectional FIFO with external RAM:
  //   - When A writes, it writes to RAM.
  //   - When B reads, it reads from RAM.
  //   - When B writes, it writes to RAM.
  //   - When A reads, it reads from RAM.
  //
  // So the RAM is shared. Each side can write and read.
  // The dual-port RAM has two ports. Port A is used by A, Port B is used by B.
  // But A needs to read what B wrote, and B needs to read what A wrote.
  // This implies that the RAM is a true dual-port RAM where both ports can read and write independently.
  //
  // So:
  //   - A writes to RAM port A: o_ram_a_winc, o_ram_a_addr, o_ram_a_wdata
  //   - A reads from RAM port A: o_ram_a_rinc, o_ram_a_addr, i_ram_a_rdata
  //   - B writes to RAM port B: o_ram_b_winc, o_ram_b_addr, o_ram_b_wdata
  //   - B reads from RAM port B: o_ram_b_rinc, o_ram_b_addr, i_ram_b_rdata
  //
  // But wait, if A writes to port A and B reads from port B, how does B see A's data?
  // Unless the RAM is a shared memory where both ports access the same memory.
  // In that case, A writes to address X via port A, and B reads from address X via port B.
  // This is a true dual-port RAM.
  //
  // So:
  //   - A writes to RAM: o_ram_a_winc = a_wr_en, o_ram_a_addr = a_wr_ptr_bin[ASIZE-1:0], o_ram_a_wdata = a_wdata
  //   - A reads from RAM: o_ram_a_rinc = a_rd_en, o_ram_a_addr = a_rd_ptr_bin[ASIZE-1:0], a_rdata = i_ram_a_rdata
  //   - B writes to RAM: o_ram_b_winc = b_wr_en, o_ram_b_addr = b_wr_ptr_bin[ASIZE-1:0], o_ram_b_wdata = b_wdata
  //   - B reads from RAM: o_ram_b_rinc = b_rd_en, o_ram_b_addr = b_rd_ptr_bin[ASIZE-1:0], b_rdata = i_ram_b_rdata

  assign o_ram_a_winc = a_wr_en;
  assign o_ram_a_addr = a_wr_ptr_bin[ASIZE-1:0];
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_rinc = a_rd_en;
  assign a_rdata = i_ram_a_rdata;

  assign o_ram_b_winc = b_wr_en;
  assign o_ram_b_addr = b_wr_ptr_bin[ASIZE-1:0];
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_rinc = b_rd_en;
  assign b_rdata = i_ram_b_rdata;

endmodule
