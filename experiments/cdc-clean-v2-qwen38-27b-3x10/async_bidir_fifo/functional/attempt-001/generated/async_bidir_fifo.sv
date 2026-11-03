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

  // Side A pointers (A is writer when a_dir=1, reader when a_dir=0)
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;

  // Side B pointers (B is writer when b_dir=1, reader when b_dir=0)
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;

  // Crossed pointers (synchronized to opposite clock domain)
  // a_wr_ptr_synced: A's write pointer synchronized to B's clock domain
  // a_rd_ptr_synced: A's read pointer synchronized to B's clock domain
  // b_wr_ptr_synced: B's write pointer synchronized to A's clock domain
  // b_rd_ptr_synced: B's read pointer synchronized to A's clock domain

  reg [PTR_W-1:0] a_wr_ptr_synced;
  reg [PTR_W-1:0] a_rd_ptr_synced;
  reg [PTR_W-1:0] b_wr_ptr_synced;
  reg [PTR_W-1:0] b_rd_ptr_synced;

  // Synchronization registers
  reg [PTR_W-1:0] a_wr_ptr_sync_r1, a_wr_ptr_sync_r2;
  reg [PTR_W-1:0] a_rd_ptr_sync_r1, a_rd_ptr_sync_r2;
  reg [PTR_W-1:0] b_wr_ptr_sync_r1, b_wr_ptr_sync_r2;
  reg [PTR_W-1:0] b_rd_ptr_sync_r1, b_rd_ptr_sync_r2;

  // Synchronize A's write pointer to B's clock domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync_r1 <= {PTR_W{1'b0}};
      a_wr_ptr_sync_r2 <= {PTR_W{1'b0}};
    end else begin
      a_wr_ptr_sync_r1 <= a_wr_ptr;
      a_wr_ptr_sync_r2 <= a_wr_ptr_sync_r1;
    end
  end
  assign a_wr_ptr_synced = a_wr_ptr_sync_r2;

  // Synchronize A's read pointer to B's clock domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync_r1 <= {PTR_W{1'b0}};
      a_rd_ptr_sync_r2 <= {PTR_W{1'b0}};
    end else begin
      a_rd_ptr_sync_r1 <= a_rd_ptr;
      a_rd_ptr_sync_r2 <= a_rd_ptr_sync_r1;
    end
  end
  assign a_rd_ptr_synced = a_rd_ptr_sync_r2;

  // Synchronize B's write pointer to A's clock domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync_r1 <= {PTR_W{1'b0}};
      b_wr_ptr_sync_r2 <= {PTR_W{1'b0}};
    end else begin
      b_wr_ptr_sync_r1 <= b_wr_ptr;
      b_wr_ptr_sync_r2 <= b_wr_ptr_sync_r1;
    end
  end
  assign b_wr_ptr_synced = b_wr_ptr_sync_r2;

  // Synchronize B's read pointer to A's clock domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync_r1 <= {PTR_W{1'b0}};
      b_rd_ptr_sync_r2 <= {PTR_W{1'b0}};
    end else begin
      b_rd_ptr_sync_r1 <= b_rd_ptr;
      b_rd_ptr_sync_r2 <= b_rd_ptr_sync_r1;
    end
  end
  assign b_rd_ptr_synced = b_rd_ptr_sync_r2;

  // Determine effective write and read pointers for each side
  // When a_dir=1: A writes, B reads. A's write pointer is a_wr_ptr, A's read pointer is b_rd_ptr_synced
  // When a_dir=0: A reads, B writes. A's read pointer is a_rd_ptr, A's write pointer is b_wr_ptr_synced

  // For side A:
  // If a_dir=1 (A is writer):
  //   A's local write pointer = a_wr_ptr
  //   A's local read pointer (from B's perspective) = b_rd_ptr_synced
  //   a_full: a_wr_ptr - b_rd_ptr_synced >= DEPTH
  //   a_empty: a_wr_ptr == b_rd_ptr_synced
  // If a_dir=0 (A is reader):
  //   A's local read pointer = a_rd_ptr
  //   A's local write pointer (from B's perspective) = b_wr_ptr_synced
  //   a_empty: a_rd_ptr == b_wr_ptr_synced
  //   a_full: b_wr_ptr_synced - a_rd_ptr >= DEPTH (but A is reader, so full is less relevant)

  // Let's define the effective pointers for each side
  // Side A effective write pointer (the pointer that advances when A writes)
  wire [PTR_W-1:0] a_eff_wr_ptr = a_dir ? a_wr_ptr : b_wr_ptr_synced;
  // Side A effective read pointer (the pointer that advances when A reads)
  wire [PTR_W-1:0] a_eff_rd_ptr = a_dir ? b_rd_ptr_synced : a_rd_ptr;

  // Side B effective write pointer
  wire [PTR_W-1:0] b_eff_wr_ptr = b_dir ? b_wr_ptr : a_wr_ptr_synced;
  // Side B effective read pointer
  wire [PTR_W-1:0] b_eff_rd_ptr = b_dir ? a_rd_ptr_synced : b_rd_ptr;

  // Compute fill level for each side
  // Fill = (eff_wr_ptr - eff_rd_ptr) mod DEPTH
  // Since pointers are PTR_W bits wide and DEPTH = 2^ASIZE, we can use the upper bit to determine wrap

  wire [PTR_W-1:0] a_fill = a_eff_wr_ptr - a_eff_rd_ptr;
  wire [PTR_W-1:0] b_fill = b_eff_wr_ptr - b_eff_rd_ptr;

  // Full: fill >= DEPTH
  assign a_full  = (a_fill >= DEPTH);
  assign b_full  = (b_fill >= DEPTH);

  // Empty: fill == 0
  assign a_empty  = (a_fill == 0);
  assign b_empty  = (b_fill == 0);

  // Almost full: fill >= DEPTH - 2
  assign a_afull  = (a_fill >= AFULL_THRESH);
  assign b_afull  = (b_fill >= AFULL_THRESH);

  // Almost empty: fill <= 1
  assign a_aempty = (a_fill <= AEMPTY_THRESH);
  assign b_aempty = (b_fill <= AEMPTY_THRESH);

  // Write logic
  // A writes when a_dir=1 and a_winc=1 and not full
  wire a_write_en = a_dir & a_winc & ~a_full;
  // B writes when b_dir=1 and b_winc=1 and not full
  wire b_write_en = b_dir & b_winc & ~b_full;

  // Read logic
  // A reads when a_dir=0 and a_rinc=1 and not empty
  wire a_read_en = ~a_dir & a_rinc & ~a_empty;
  // B reads when b_dir=0 and b_rinc=1 and not empty
  wire b_read_en = ~b_dir & b_rinc & ~b_empty;

  // Memory write
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {PTR_W{1'b0}};
    end else if (a_write_en) begin
      mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
      a_wr_ptr <= a_wr_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {PTR_W{1'b0}};
    end else if (b_write_en) begin
      mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
      b_wr_ptr <= b_wr_ptr + 1'b1;
    end
  end

  // Read data
  // A reads from a_rd_ptr when a_dir=0
  // B reads from b_rd_ptr when b_dir=0
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr <= {PTR_W{1'b0}};
      a_rdata_reg <= {DSIZE{1'b0}};
    end else if (a_read_en) begin
      a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
      a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr <= {PTR_W{1'b0}};
      b_rdata_reg <= {DSIZE{1'b0}};
    end else if (b_read_en) begin
      b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
      b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
