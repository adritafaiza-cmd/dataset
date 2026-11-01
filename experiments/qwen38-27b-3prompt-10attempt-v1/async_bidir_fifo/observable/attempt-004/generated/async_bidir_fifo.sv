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
  localparam AWIDTH1 = AWIDTH + 1;

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Direction registers (synchronized to local clock)
  reg a_dir_r;
  reg b_dir_r;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_dir_r <= 1'b0;
    else
      a_dir_r <= a_dir;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_dir_r <= 1'b0;
    else
      b_dir_r <= b_dir;
  end

  // Write pointer in A domain
  reg [AWIDTH1-1:0] a_wr_ptr;
  // Read pointer in A domain (for A reading from FIFO)
  reg [AWIDTH1-1:0] a_rd_ptr;

  // Write pointer in B domain
  reg [AWIDTH1-1:0] b_wr_ptr;
  // Read pointer in B domain (for B reading from FIFO)
  reg [AWIDTH1-1:0] b_rd_ptr;

  // Synchronized pointers for status generation
  // A domain: synchronized B write pointer and B read pointer
  reg [AWIDTH1-1:0] b_wr_ptr_sync1, b_wr_ptr_sync2;
  reg [AWIDTH1-1:0] b_rd_ptr_sync1, b_rd_ptr_sync2;

  // B domain: synchronized A write pointer and A read pointer
  reg [AWIDTH1-1:0] a_wr_ptr_sync1, a_wr_ptr_sync2;
  reg [AWIDTH1-1:0] a_rd_ptr_sync1, a_rd_ptr_sync2;

  // Synchronize B write pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AWIDTH1{1'b0}};
      b_wr_ptr_sync2 <= {AWIDTH1{1'b0}};
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
    end
  end

  // Synchronize B read pointer to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync1 <= {AWIDTH1{1'b0}};
      b_rd_ptr_sync2 <= {AWIDTH1{1'b0}};
    end else begin
      b_rd_ptr_sync1 <= b_rd_ptr;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
    end
  end

  // Synchronize A write pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AWIDTH1{1'b0}};
      a_wr_ptr_sync2 <= {AWIDTH1{1'b0}};
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
    end
  end

  // Synchronize A read pointer to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync1 <= {AWIDTH1{1'b0}};
      a_rd_ptr_sync2 <= {AWIDTH1{1'b0}};
    end else begin
      a_rd_ptr_sync1 <= a_rd_ptr;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
    end
  end

  // Determine effective write and read pointers in A domain
  // If a_dir_r is 0: A writes, B reads
  // If a_dir_r is 1: B writes, A reads
  // But the FIFO is shared. Let's think of it as:
  // The FIFO has a single write pointer and single read pointer.
  // The direction determines which side writes and which side reads.
  
  // Actually, let me reconsider. The FIFO is bidirectional. 
  // a_dir selects whether A is writing (a_dir=0) or reading (a_dir=1).
  // b_dir selects whether B is writing (b_dir=0) or reading (b_dir=1).
  // For the FIFO to work, one side must write and the other must read.
  // We assume valid configurations: (a_dir=0, b_dir=1) or (a_dir=1, b_dir=0).
  
  // Let's define:
  // In A domain:
  //   If a_dir_r == 0: A is writing. a_winc increments a_wr_ptr.
  //   If a_dir_r == 1: A is reading. a_rinc increments a_rd_ptr.
  //   The write pointer for the FIFO from A's perspective is a_wr_ptr if A writes, else b_wr_ptr (synced).
  //   The read pointer for the FIFO from A's perspective is a_rd_ptr if A reads, else b_rd_ptr (synced).
  
  // This is getting complex. Let me use a simpler model:
  // The FIFO has a global write pointer and read pointer.
  // When A writes, it uses a_wr_ptr. When B writes, it uses b_wr_ptr.
  // When A reads, it uses a_rd_ptr. When B reads, it uses b_rd_ptr.
  // But we need to synchronize these across domains.
  
  // Alternative approach: Use two separate FIFOs? No, the problem says "bidirectional".
  
  // Let me re-read the problem. "Move words in either direction, as selected on each side."
  // This suggests that the direction can change. But for a simple implementation,
  // let's assume the direction is stable during operation.
  
  // I'll implement it as:
  // - If a_dir_r == 0 and b_dir_r == 1: A writes, B reads.
  // - If a_dir_r == 1 and b_dir_r == 0: B writes, A reads.
  
  // For status generation in A domain:
  // - If A is writing (a_dir_r==0): 
  //   - a_full: a_wr_ptr - b_rd_ptr_sync2 == DEPTH
  //   - a_empty: a_wr_ptr == b_rd_ptr_sync2
  // - If A is reading (a_dir_r==1):
  //   - a_full: b_wr_ptr_sync2 - a_rd_ptr == DEPTH
  //   - a_empty: b_wr_ptr_sync2 == a_rd_ptr
  
  // Similarly for B domain.

  // A domain status
  wire a_is_writer = ~a_dir_r;
  wire a_is_reader = a_dir_r;

  wire [AWIDTH1-1:0] a_eff_wr_ptr;
  wire [AWIDTH1-1:0] a_eff_rd_ptr;

  assign a_eff_wr_ptr = a_is_writer ? a_wr_ptr : b_wr_ptr_sync2;
  assign a_eff_rd_ptr = a_is_reader ? a_rd_ptr : b_rd_ptr_sync2;

  wire [AWIDTH1-1:0] a_count = a_eff_wr_ptr - a_eff_rd_ptr;
  wire a_full_internal  = (a_count == DEPTH);
  wire a_empty_internal = (a_count == 0);

  // Almost full/empty thresholds
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 2;

  assign a_full   = a_full_internal;
  assign a_empty  = a_empty_internal;
  assign a_afull  = (a_count >= AFULL_THRESH);
  assign a_aempty = (a_count <= AEMPTY_THRESH);

  // B domain status
  wire b_is_writer = ~b_dir_r;
  wire b_is_reader = b_dir_r;

  wire [AWIDTH1-1:0] b_eff_wr_ptr;
  wire [AWIDTH1-1:0] b_eff_rd_ptr;

  assign b_eff_wr_ptr = b_is_writer ? b_wr_ptr : a_wr_ptr_sync2;
  assign b_eff_rd_ptr = b_is_reader ? b_rd_ptr : a_rd_ptr_sync2;

  wire [AWIDTH1-1:0] b_count = b_eff_wr_ptr - b_eff_rd_ptr;
  wire b_full_internal  = (b_count == DEPTH);
  wire b_empty_internal = (b_count == 0);

  assign b_full   = b_full_internal;
  assign b_empty  = b_empty_internal;
  assign b_afull  = (b_count >= AFULL_THRESH);
  assign b_aempty = (b_count <= AEMPTY_THRESH);

  // Write logic in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AWIDTH1{1'b0}};
    else if (a_is_writer && a_winc && !a_full)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  // Read logic in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr <= {AWIDTH1{1'b0}};
    else if (a_is_reader && a_rinc && !a_empty)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  // Write logic in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AWIDTH1{1'b0}};
    else if (b_is_writer && b_winc && !b_full)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // Read logic in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr <= {AWIDTH1{1'b0}};
    else if (b_is_reader && b_rinc && !b_empty)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // Memory write in A domain
  always @(posedge a_clk) begin
    if (a_is_writer && a_winc && !a_full)
      mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
  end

  // Memory write in B domain
  always @(posedge b_clk) begin
    if (b_is_writer && b_winc && !b_full)
      mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
  end

  // Read data in A domain
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else if (a_is_reader && !a_empty)
      a_rdata_reg <= mem[a_rd_ptr[AWIDTH-1:0]];
  end

  // Read data in B domain
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else if (b_is_reader && !b_empty)
      b_rdata_reg <= mem[b_rd_ptr[AWIDTH-1:0]];
  end

  // Fall-through logic
  // If FALLTHROUGH is "TRUE", the read data is combinational (bypasses register)
  // when the FIFO is not empty. Otherwise, it's registered.
  
  wire a_fallthrough = (FALLTHROUGH == "TRUE");
  wire b_fallthrough = (FALLTHROUGH == "TRUE");

  // For A: if fallthrough and A is reading, output combinational read
  // Otherwise, output registered read
  assign a_rdata = (a_fallthrough && a_is_reader && !a_empty) ? 
                   mem[a_rd_ptr[AWIDTH-1:0]] : a_rdata_reg;

  // For B: if fallthrough and B is reading, output combinational read
  // Otherwise, output registered read
  assign b_rdata = (b_fallthrough && b_is_reader && !b_empty) ? 
                   mem[b_rd_ptr[AWIDTH-1:0]] : b_rdata_reg;

endmodule
