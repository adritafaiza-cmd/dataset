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

  // Side A (reader side when a_dir=0, writer side when a_dir=1)
  // We need two FIFOs: A->B and B->A
  // Actually, let's think about this differently.
  
  // The bidirectional FIFO has two independent FIFOs:
  // 1. A-to-B FIFO: writes from A (when a_dir=1), reads from B (when b_dir=0)
  // 2. B-to-A FIFO: writes from B (when b_dir=1), reads from A (when a_dir=0)
  
  // Let's implement two separate async FIFOs.

  // FIFO 1: A to B
  // Writer: A side, when a_dir=1 and a_winc=1
  // Reader: B side, when b_dir=0 and b_rinc=1
  reg [PTR_W-1:0] ab_wr_ptr_a;  // write pointer in A clock domain
  reg [PTR_W-1:0] ab_rd_ptr_b;  // read pointer in B clock domain
  reg [PTR_W-1:0] ab_wr_ptr_b;  // write pointer synchronized to B
  reg [PTR_W-1:0] ab_rd_ptr_a;  // read pointer synchronized to A

  // FIFO 2: B to A
  // Writer: B side, when b_dir=1 and b_winc=1
  // Reader: A side, when a_dir=0 and a_rinc=1
  reg [PTR_W-1:0] ba_wr_ptr_b;  // write pointer in B clock domain
  reg [PTR_W-1:0] ba_rd_ptr_a;  // read pointer in A clock domain
  reg [PTR_W-1:0] ba_wr_ptr_a;  // write pointer synchronized to A
  reg [PTR_W-1:0] ba_rd_ptr_b;  // read pointer synchronized to B

  // Storage for A-to-B FIFO
  reg [DSIZE-1:0] ab_mem [0:DEPTH-1];
  // Storage for B-to-A FIFO
  reg [DSIZE-1:0] ba_mem [0:DEPTH-1];

  // Synchronization signals
  wire ab_wr_en_a = a_dir & a_winc;
  wire ab_rd_en_b = ~b_dir & b_rinc;
  wire ba_wr_en_b = b_dir & b_winc;
  wire ba_rd_en_a = ~a_dir & a_rinc;

  // A-to-B FIFO: Write in A domain
  integer i;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ab_wr_ptr_a <= {PTR_W{1'b0}};
      ab_rd_ptr_a <= {PTR_W{1'b0}};
    end else begin
      if (ab_wr_en_a)
        ab_wr_ptr_a <= ab_wr_ptr_a + 1'b1;
      if (ba_rd_en_a)
        ba_rd_ptr_a <= ba_rd_ptr_a + 1'b1;
    end
  end

  // B-to-A FIFO: Write in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ba_wr_ptr_b <= {PTR_W{1'b0}};
      ba_rd_ptr_b <= {PTR_W{1'b0}};
    end else begin
      if (ba_wr_en_b)
        ba_wr_ptr_b <= ba_wr_ptr_b + 1'b1;
      if (ab_rd_en_b)
        ab_rd_ptr_b <= ab_rd_ptr_b + 1'b1;
    end
  end

  // Synchronize A-to-B write pointer to B domain
  reg [PTR_W-1:0] ab_wr_ptr_b_sync1, ab_wr_ptr_b_sync2, ab_wr_ptr_b_sync3;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ab_wr_ptr_b_sync1 <= {PTR_W{1'b0}};
      ab_wr_ptr_b_sync2 <= {PTR_W{1'b0}};
      ab_wr_ptr_b_sync3 <= {PTR_W{1'b0}};
    end else begin
      ab_wr_ptr_b_sync1 <= ab_wr_ptr_a;
      ab_wr_ptr_b_sync2 <= ab_wr_ptr_b_sync1;
      ab_wr_ptr_b_sync3 <= ab_wr_ptr_b_sync2;
    end
  end
  assign ab_wr_ptr_b = ab_wr_ptr_b_sync3;

  // Synchronize A-to-B read pointer to A domain
  reg [PTR_W-1:0] ab_rd_ptr_a_sync1, ab_rd_ptr_a_sync2, ab_rd_ptr_a_sync3;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ab_rd_ptr_a_sync1 <= {PTR_W{1'b0}};
      ab_rd_ptr_a_sync2 <= {PTR_W{1'b0}};
      ab_rd_ptr_a_sync3 <= {PTR_W{1'b0}};
    end else begin
      ab_rd_ptr_a_sync1 <= ab_rd_ptr_b;
      ab_rd_ptr_a_sync2 <= ab_rd_ptr_a_sync1;
      ab_rd_ptr_a_sync3 <= ab_rd_ptr_a_sync2;
    end
  end
  assign ab_rd_ptr_a = ab_rd_ptr_a_sync3;

  // Synchronize B-to-A write pointer to A domain
  reg [PTR_W-1:0] ba_wr_ptr_a_sync1, ba_wr_ptr_a_sync2, ba_wr_ptr_a_sync3;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ba_wr_ptr_a_sync1 <= {PTR_W{1'b0}};
      ba_wr_ptr_a_sync2 <= {PTR_W{1'b0}};
      ba_wr_ptr_a_sync3 <= {PTR_W{1'b0}};
    end else begin
      ba_wr_ptr_a_sync1 <= ba_wr_ptr_b;
      ba_wr_ptr_a_sync2 <= ba_wr_ptr_a_sync1;
      ba_wr_ptr_a_sync3 <= ba_wr_ptr_a_sync2;
    end
  end
  assign ba_wr_ptr_a = ba_wr_ptr_a_sync3;

  // Synchronize B-to-A read pointer to B domain
  reg [PTR_W-1:0] ba_rd_ptr_b_sync1, ba_rd_ptr_b_sync2, ba_rd_ptr_b_sync3;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ba_rd_ptr_b_sync1 <= {PTR_W{1'b0}};
      ba_rd_ptr_b_sync2 <= {PTR_W{1'b0}};
      ba_rd_ptr_b_sync3 <= {PTR_W{1'b0}};
    end else begin
      ba_rd_ptr_b_sync1 <= ba_rd_ptr_a;
      ba_rd_ptr_b_sync2 <= ba_rd_ptr_b_sync1;
      ba_rd_ptr_b_sync3 <= ba_rd_ptr_b_sync2;
    end
  end
  assign ba_rd_ptr_b = ba_rd_ptr_b_sync3;

  // A-to-B FIFO: Write data in A domain
  always @(posedge a_clk) begin
    if (ab_wr_en_a)
      ab_mem[ab_wr_ptr_a[ASIZE-1:0]] <= a_wdata;
  end

  // B-to-A FIFO: Write data in B domain
  always @(posedge b_clk) begin
    if (ba_wr_en_b)
      ba_mem[ba_wr_ptr_b[ASIZE-1:0]] <= b_wdata;
  end

  // A-to-B FIFO: Read data in B domain
  reg [DSIZE-1:0] ab_rdata_b;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      ab_rdata_b <= {DSIZE{1'b0}};
    else
      ab_rdata_b <= ab_mem[ab_rd_ptr_b[ASIZE-1:0]];
  end

  // B-to-A FIFO: Read data in A domain
  reg [DSIZE-1:0] ba_rdata_a;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      ba_rdata_a <= {DSIZE{1'b0}};
    else
      ba_rdata_a <= ba_mem[ba_rd_ptr_a[ASIZE-1:0]];
  end

  // Full/Empty flags for A-to-B FIFO
  // In A domain: full when write pointer catches up to read pointer
  wire ab_full_a = (ab_wr_ptr_a == ab_rd_ptr_a) ? 1'b0 : 
                   (ab_wr_ptr_a[PTR_W-1] != ab_rd_ptr_a[PTR_W-1]) ? 
                   (ab_wr_ptr_a[ASIZE-1:0] == ab_rd_ptr_a[ASIZE-1:0]) : 1'b0;
  // Actually, for a FIFO of depth DEPTH, full when (wr_ptr - rd_ptr) == DEPTH
  // With PTR_W = ASIZE+1 bits, full when upper bits differ and lower bits equal
  wire ab_full_a = (ab_wr_ptr_a[ASIZE-1:0] == ab_rd_ptr_a[ASIZE-1:0]) && 
                   (ab_wr_ptr_a[PTR_W-1] != ab_rd_ptr_a[PTR_W-1]);
  wire ab_empty_a = (ab_wr_ptr_a == ab_rd_ptr_a);

  // In B domain: full when write pointer catches up to read pointer
  wire ab_full_b = (ab_wr_ptr_b[ASIZE-1:0] == ab_rd_ptr_b[ASIZE-1:0]) && 
                   (ab_wr_ptr_b[PTR_W-1] != ab_rd_ptr_b[PTR_W-1]);
  wire ab_empty_b = (ab_wr_ptr_b == ab_rd_ptr_b);

  // Full/Empty flags for B-to-A FIFO
  // In B domain: full when write pointer catches up to read pointer
  wire ba_full_b = (ba_wr_ptr_b[ASIZE-1:0] == ba_rd_ptr_b[ASIZE-1:0]) && 
                   (ba_wr_ptr_b[PTR_W-1] != ba_rd_ptr_b[PTR_W-1]);
  wire ba_empty_b = (ba_wr_ptr_b == ba_rd_ptr_b);

  // In A domain: full when write pointer catches up to read pointer
  wire ba_full_a = (ba_wr_ptr_a[ASIZE-1:0] == ba_rd_ptr_a[ASIZE-1:0]) && 
                   (ba_wr_ptr_a[PTR_W-1] != ba_rd_ptr_a[PTR_W-1]);
  wire ba_empty_a = (ba_wr_ptr_a == ba_rd_ptr_a);

  // Almost full/empty flags
  // A-to-B FIFO almost full in A domain
  wire ab_afull_a = (ab_wr_ptr_a - ab_rd_ptr_a) >= AFULL_THRESH;
  // A-to-B FIFO almost empty in B domain
  wire ab_aempty_b = (ab_wr_ptr_b - ab_rd_ptr_b) <= AEMPTY_THRESH;

  // B-to-A FIFO almost full in B domain
  wire ba_afull_b = (ba_wr_ptr_b - ba_rd_ptr_b) >= AFULL_THRESH;
  // B-to-A FIFO almost empty in A domain
  wire ba_aempty_a = (ba_wr_ptr_a - ba_rd_ptr_a) <= AEMPTY_THRESH;

  // Output assignments
  // A side: 
  // - When a_dir=1 (write), a_full should reflect A-to-B FIFO full
  // - When a_dir=0 (read), a_empty should reflect B-to-A FIFO empty
  // - a_rdata is from B-to-A FIFO when reading
  assign a_full   = a_dir ? ab_full_a : ba_full_a;
  assign a_afull  = a_dir ? ab_afull_a : ba_afull_b; // Note: ba_afull_b is in B domain, need to sync
  assign a_empty  = a_dir ? ab_empty_a : ba_empty_a;
  assign a_aempty = a_dir ? ab_aempty_b : ba_aempty_a; // Note: ab_aempty_b is in B domain, need to sync
  assign a_rdata  = ba_rdata_a;

  // B side:
  // - When b_dir=1 (write), b_full should reflect B-to-A FIFO full
  // - When b_dir=0 (read), b_empty should reflect A-to-B FIFO empty
  // - b_rdata is from A-to-B FIFO when reading
  assign b_full   = b_dir ? ba_full_b : ab_full_b;
  assign b_afull  = b_dir ? ba_afull_b : ab_afull_a; // Note: ab_afull_a is in A domain, need to sync
  assign b_empty  = b_dir ? ba_empty_b : ab_empty_b;
  assign b_aempty = b_dir ? ba_aempty_a : ab_aempty_b; // Note: ba_aempty_a is in A domain, need to sync
  assign b_rdata  = ab_rdata_b;

endmodule
