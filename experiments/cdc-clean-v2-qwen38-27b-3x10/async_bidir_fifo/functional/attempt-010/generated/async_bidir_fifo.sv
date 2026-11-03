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

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Side A: write pointer (when a_dir=1), read pointer (when a_dir=0)
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;

  // Side B: write pointer (when b_dir=1), read pointer (when b_dir=0)
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;

  // Cross-domain pointer synchronization
  // A's write pointer synchronized to B domain
  reg [PTR_W-1:0] a_wr_ptr_b1, a_wr_ptr_b2, a_wr_ptr_b3;
  // A's read pointer synchronized to B domain
  reg [PTR_W-1:0] a_rd_ptr_b1, a_rd_ptr_b2, a_rd_ptr_b3;
  // B's write pointer synchronized to A domain
  reg [PTR_W-1:0] b_wr_ptr_a1, b_wr_ptr_a2, b_wr_ptr_a3;
  // B's read pointer synchronized to A domain
  reg [PTR_W-1:0] b_rd_ptr_a1, b_rd_ptr_a2, b_rd_ptr_a3;

  // Synchronization flops for A_wr_ptr to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_b1 <= {PTR_W{1'b0}};
      a_wr_ptr_b2 <= {PTR_W{1'b0}};
      a_wr_ptr_b3 <= {PTR_W{1'b0}};
    end else begin
      a_wr_ptr_b1 <= a_wr_ptr;
      a_wr_ptr_b2 <= a_wr_ptr_b1;
      a_wr_ptr_b3 <= a_wr_ptr_b2;
    end
  end

  // Synchronization flops for A_rd_ptr to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_b1 <= {PTR_W{1'b0}};
      a_rd_ptr_b2 <= {PTR_W{1'b0}};
      a_rd_ptr_b3 <= {PTR_W{1'b0}};
    end else begin
      a_rd_ptr_b1 <= a_rd_ptr;
      a_rd_ptr_b2 <= a_rd_ptr_b1;
      a_rd_ptr_b3 <= a_rd_ptr_b2;
    end
  end

  // Synchronization flops for B_wr_ptr to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_a1 <= {PTR_W{1'b0}};
      b_wr_ptr_a2 <= {PTR_W{1'b0}};
      b_wr_ptr_a3 <= {PTR_W{1'b0}};
    end else begin
      b_wr_ptr_a1 <= b_wr_ptr;
      b_wr_ptr_a2 <= b_wr_ptr_a1;
      b_wr_ptr_a3 <= b_wr_ptr_a2;
    end
  end

  // Synchronization flops for B_rd_ptr to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_a1 <= {PTR_W{1'b0}};
      b_rd_ptr_a2 <= {PTR_W{1'b0}};
      b_rd_ptr_a3 <= {PTR_W{1'b0}};
    end else begin
      b_rd_ptr_a1 <= b_rd_ptr;
      b_rd_ptr_a2 <= b_rd_ptr_a1;
      b_rd_ptr_a3 <= b_rd_ptr_a2;
    end
  end

  // Determine effective write and read pointers for each side
  // When a_dir=1: A is writer, so a_wr_ptr is the local write pointer, b_rd_ptr (synced) is the remote read pointer
  // When a_dir=0: A is reader, so a_rd_ptr is the local read pointer, b_wr_ptr (synced) is the remote write pointer

  // For side A:
  // If a_dir=1 (write mode):
  //   Local write pointer: a_wr_ptr
  //   Remote read pointer: b_rd_ptr_a3 (B's read pointer synced to A)
  //   Full condition: a_wr_ptr - b_rd_ptr_a3 == DEPTH
  //   Empty condition: a_wr_ptr == b_rd_ptr_a3 (but this is for the FIFO from A's perspective as writer)
  //   Actually, let's think of it differently.

  // The FIFO has two ends. Data written on one end is read on the other.
  // Let's define:
  //   wr_ptr: the pointer that advances on writes
  //   rd_ptr: the pointer that advances on reads
  //
  // When a_dir=1 and b_dir=0: A writes, B reads
  //   wr_ptr = a_wr_ptr, rd_ptr = b_rd_ptr
  // When a_dir=0 and b_dir=1: B writes, A reads
  //   wr_ptr = b_wr_ptr, rd_ptr = a_rd_ptr
  //
  // But the direction can change dynamically. Let's handle each side's view.

  // Side A view:
  // If a_dir=1 (A is writing):
  //   A's write pointer: a_wr_ptr
  //   The read pointer is on B side: b_rd_ptr (synced to A as b_rd_ptr_a3)
  //   Full: a_wr_ptr - b_rd_ptr_a3 == DEPTH
  //   Empty: a_wr_ptr == b_rd_ptr_a3
  // If a_dir=0 (A is reading):
  //   A's read pointer: a_rd_ptr
  //   The write pointer is on B side: b_wr_ptr (synced to A as b_wr_ptr_a3)
  //   Full: b_wr_ptr_a3 - a_rd_ptr == DEPTH
  //   Empty: b_wr_ptr_a3 == a_rd_ptr

  wire [PTR_W-1:0] a_local_wr_ptr;
  wire [PTR_W-1:0] a_local_rd_ptr;
  wire [PTR_W-1:0] a_remote_wr_ptr;
  wire [PTR_W-1:0] a_remote_rd_ptr;

  assign a_local_wr_ptr  = a_dir ? a_wr_ptr : {PTR_W{1'b0}};
  assign a_local_rd_ptr  = a_dir ? {PTR_W{1'b0}} : a_rd_ptr;
  assign a_remote_wr_ptr = a_dir ? {PTR_W{1'b0}} : b_wr_ptr_a3;
  assign a_remote_rd_ptr = a_dir ? b_rd_ptr_a3 : {PTR_W{1'b0}};

  // Side B view:
  // If b_dir=1 (B is writing):
  //   B's write pointer: b_wr_ptr
  //   The read pointer is on A side: a_rd_ptr (synced to B as a_rd_ptr_b3)
  //   Full: b_wr_ptr - a_rd_ptr_b3 == DEPTH
  //   Empty: b_wr_ptr == a_rd_ptr_b3
  // If b_dir=0 (B is reading):
  //   B's read pointer: b_rd_ptr
  //   The write pointer is on A side: a_wr_ptr (synced to B as a_wr_ptr_b3)
  //   Full: a_wr_ptr_b3 - b_rd_ptr == DEPTH
  //   Empty: a_wr_ptr_b3 == b_rd_ptr

  wire [PTR_W-1:0] b_local_wr_ptr;
  wire [PTR_W-1:0] b_local_rd_ptr;
  wire [PTR_W-1:0] b_remote_wr_ptr;
  wire [PTR_W-1:0] b_remote_rd_ptr;

  assign b_local_wr_ptr  = b_dir ? b_wr_ptr : {PTR_W{1'b0}};
  assign b_local_rd_ptr  = b_dir ? {PTR_W{1'b0}} : b_rd_ptr;
  assign b_remote_wr_ptr = b_dir ? {PTR_W{1'b0}} : a_wr_ptr_b3;
  assign b_remote_rd_ptr = b_dir ? a_rd_ptr_b3 : {PTR_W{1'b0}};

  // Compute full and empty for each side
  // For a side that is writing: full = local_wr - remote_rd == DEPTH, empty = local_wr == remote_rd
  // For a side that is reading: full = remote_wr - local_rd == DEPTH, empty = remote_wr == local_rd

  wire a_full_raw;
  wire a_empty_raw;
  wire b_full_raw;
  wire b_empty_raw;

  // Side A
  assign a_full_raw  = a_dir ? (a_wr_ptr - b_rd_ptr_a3 == DEPTH[PTR_W-1:0])
                             : (b_wr_ptr_a3 - a_rd_ptr == DEPTH[PTR_W-1:0]);
  assign a_empty_raw = a_dir ? (a_wr_ptr == b_rd_ptr_a3)
                             : (b_wr_ptr_a3 == a_rd_ptr);

  // Side B
  assign b_full_raw  = b_dir ? (b_wr_ptr - a_rd_ptr_b3 == DEPTH[PTR_W-1:0])
                             : (a_wr_ptr_b3 - b_rd_ptr == DEPTH[PTR_W-1:0]);
  assign b_empty_raw = b_dir ? (b_wr_ptr == a_rd_ptr_b3)
                             : (a_wr_ptr_b3 == b_rd_ptr);

  // Almost full and almost empty (one entry margin)
  wire a_afull_raw;
  wire a_aempty_raw;
  wire b_afull_raw;
  wire b_aempty_raw;

  assign a_afull_raw  = a_dir ? (a_wr_ptr - b_rd_ptr_a3 == DEPTH[PTR_W-1:0] - 1)
                              : (b_wr_ptr_a3 - a_rd_ptr == DEPTH[PTR_W-1:0] - 1);
  assign a_aempty_raw = a_dir ? (a_wr_ptr - b_rd_ptr_a3 == 1)
                              : (b_wr_ptr_a3 - a_rd_ptr == 1);

  assign b_afull_raw  = b_dir ? (b_wr_ptr - a_rd_ptr_b3 == DEPTH[PTR_W-1:0] - 1)
                              : (a_wr_ptr_b3 - b_rd_ptr == DEPTH[PTR_W-1:0] - 1);
  assign b_aempty_raw = b_dir ? (b_wr_ptr - a_rd_ptr_b3 == 1)
                              : (a_wr_ptr_b3 - b_rd_ptr == 1);

  // Register the flags for stability
  reg a_full_r, a_afull_r, a_empty_r, a_aempty_r;
  reg b_full_r, b_afull_r, b_empty_r, b_aempty_r;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_r   <= 1'b0;
      a_afull_r  <= 1'b0;
      a_empty_r  <= 1'b1;
      a_aempty_r <= 1'b1;
    end else begin
      a_full_r   <= a_full_raw;
      a_afull_r  <= a_afull_raw;
      a_empty_r  <= a_empty_raw;
      a_aempty_r <= a_aempty_raw;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_r   <= 1'b0;
      b_afull_r  <= 1'b0;
      b_empty_r  <= 1'b1;
      b_aempty_r <= 1'b1;
    end else begin
      b_full_r   <= b_full_raw;
      b_afull_r  <= b_afull_raw;
      b_empty_r  <= b_empty_raw;
      b_aempty_r <= b_aempty_raw;
    end
  end

  assign a_full   = a_full_r;
  assign a_afull  = a_afull_r;
  assign a_empty  = a_empty_r;
  assign a_aempty = a_aempty_r;
  assign b_full   = b_full_r;
  assign b_afull  = b_afull_r;
  assign b_empty  = b_empty_r;
  assign b_aempty = b_aempty_r;

  // Write logic
  // Side A writes when a_dir=1 and a_winc=1 and not full
  wire a_write_en;
  wire b_write_en;
  wire a_read_en;
  wire b_read_en;

  assign a_write_en = a_dir & a_winc & ~a_full_r;
  assign b_write_en = b_dir & b_winc & ~b_full_r;
  assign a_read_en  = ~a_dir & a_rinc & ~a_empty_r;
  assign b_read_en  = ~b_dir & b_rinc & ~b_empty_r;

  // Update pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {PTR_W{1'b0}};
      a_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (a_write_en)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_read_en)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {PTR_W{1'b0}};
      b_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (b_write_en)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_read_en)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // Memory write
  // When A writes, write to mem[a_wr_ptr[ASIZE-1:0]]
  // When B writes, write to mem[b_wr_ptr[ASIZE-1:0]]
  // We need to handle potential simultaneous writes from both sides (shouldn't happen if directions are complementary, but let's be safe)
  // Actually, if a_dir=1 and b_dir=1, both could try to write. But the FIFO is bidirectional, so typically only one side writes at a time.
  // Let's assume that when a_dir=1, A is the writer, and when b_dir=1, B is the writer. If both are 1, we have a conflict.
  // For simplicity, let's prioritize A's write if both try to write.

  always @(posedge a_clk) begin
    if (a_write_en)
      mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  always @(posedge b_clk) begin
    if (b_write_en)
      mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // Read data
  // Side A reads when a_dir=0, read from mem[a_rd_ptr[ASIZE-1:0]]
  // Side B reads when b_dir=0, read from mem[b_rd_ptr[ASIZE-1:0]]
  // Register the read data for stability

  reg [DSIZE-1:0] a_rdata_r;
  reg [DSIZE-1:0] b_rdata_r;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_r <= {DSIZE{1'b0}};
    else if (a_read_en)
      a_rdata_r <= mem[a_rd_ptr[ASIZE-1:0]];
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_r <= {DSIZE{1'b0}};
    else if (b_read_en)
      b_rdata_r <= mem[b_rd_ptr[ASIZE-1:0]];
  end

  assign a_rdata = a_rdata_r;
  assign b_rdata = b_rdata_r;

endmodule
