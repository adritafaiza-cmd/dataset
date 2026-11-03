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
  localparam AFULL_THRESH = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Side A: write pointer (when a_dir=1), read pointer (when a_dir=0)
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;

  // Side B: write pointer (when b_dir=1), read pointer (when b_dir=0)
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;

  // Synchronizers for pointers crossing domains
  // A's write pointer synchronized to B domain
  reg [PTR_W-1:0] a_wr_ptr_b_sync0, a_wr_ptr_b_sync1, a_wr_ptr_b_sync2;
  // A's read pointer synchronized to B domain
  reg [PTR_W-1:0] a_rd_ptr_b_sync0, a_rd_ptr_b_sync1, a_rd_ptr_b_sync2;
  // B's write pointer synchronized to A domain
  reg [PTR_W-1:0] b_wr_ptr_a_sync0, b_wr_ptr_a_sync1, b_wr_ptr_a_sync2;
  // B's read pointer synchronized to A domain
  reg [PTR_W-1:0] b_rd_ptr_a_sync0, b_rd_ptr_a_sync1, b_rd_ptr_a_sync2;

  // Direction synchronizers
  reg a_dir_b_sync0, a_dir_b_sync1, a_dir_b_sync2;
  reg b_dir_a_sync0, b_dir_a_sync1, b_dir_a_sync2;

  // Synchronizer logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_b_sync0 <= {PTR_W{1'b0}};
      a_wr_ptr_b_sync1 <= {PTR_W{1'b0}};
      a_wr_ptr_b_sync2 <= {PTR_W{1'b0}};
      a_rd_ptr_b_sync0 <= {PTR_W{1'b0}};
      a_rd_ptr_b_sync1 <= {PTR_W{1'b0}};
      a_rd_ptr_b_sync2 <= {PTR_W{1'b0}};
      a_dir_b_sync0 <= 1'b0;
      a_dir_b_sync1 <= 1'b0;
      a_dir_b_sync2 <= 1'b0;
    end else begin
      a_wr_ptr_b_sync0 <= a_wr_ptr;
      a_wr_ptr_b_sync1 <= a_wr_ptr_b_sync0;
      a_wr_ptr_b_sync2 <= a_wr_ptr_b_sync1;
      a_rd_ptr_b_sync0 <= a_rd_ptr;
      a_rd_ptr_b_sync1 <= a_rd_ptr_b_sync0;
      a_rd_ptr_b_sync2 <= a_rd_ptr_b_sync1;
      a_dir_b_sync0 <= a_dir;
      a_dir_b_sync1 <= a_dir_b_sync0;
      a_dir_b_sync2 <= a_dir_b_sync1;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_a_sync0 <= {PTR_W{1'b0}};
      b_wr_ptr_a_sync1 <= {PTR_W{1'b0}};
      b_wr_ptr_a_sync2 <= {PTR_W{1'b0}};
      b_rd_ptr_a_sync0 <= {PTR_W{1'b0}};
      b_rd_ptr_a_sync1 <= {PTR_W{1'b0}};
      b_rd_ptr_a_sync2 <= {PTR_W{1'b0}};
      b_dir_a_sync0 <= 1'b0;
      b_dir_a_sync1 <= 1'b0;
      b_dir_a_sync2 <= 1'b0;
    end else begin
      b_wr_ptr_a_sync0 <= b_wr_ptr;
      b_wr_ptr_a_sync1 <= b_wr_ptr_a_sync0;
      b_wr_ptr_a_sync2 <= b_wr_ptr_a_sync1;
      b_rd_ptr_a_sync0 <= b_rd_ptr;
      b_rd_ptr_a_sync1 <= b_rd_ptr_a_sync0;
      b_rd_ptr_a_sync2 <= b_rd_ptr_a_sync1;
      b_dir_a_sync0 <= b_dir;
      b_dir_a_sync1 <= b_dir_a_sync0;
      b_dir_a_sync2 <= b_dir_a_sync1;
    end
  end

  // Synchronized pointer values
  wire [PTR_W-1:0] a_wr_ptr_b = a_wr_ptr_b_sync2;
  wire [PTR_W-1:0] a_rd_ptr_b = a_rd_ptr_b_sync2;
  wire [PTR_W-1:0] b_wr_ptr_a = b_wr_ptr_a_sync2;
  wire [PTR_W-1:0] b_rd_ptr_a = b_rd_ptr_a_sync2;
  wire a_dir_b = a_dir_b_sync2;
  wire b_dir_a = b_dir_a_sync2;

  // Determine effective write/read pointers for each side
  // When a_dir=1, A is writer: a_wr_ptr is the local write pointer
  // When a_dir=0, A is reader: a_rd_ptr is the local read pointer
  // The opposite side's pointer (synchronized) tells us the other end's position

  // For side A:
  // If a_dir=1 (A writes): A's write pointer advances. The read pointer is from B side (b_rd_ptr_a)
  // If a_dir=0 (A reads): A's read pointer advances. The write pointer is from B side (b_wr_ptr_a)

  // Effective write pointer for A's perspective:
  // When A is writer: a_wr_ptr
  // When A is reader: b_wr_ptr_a (the writer is B)
  wire [PTR_W-1:0] a_eff_wr_ptr = a_dir ? a_wr_ptr : b_wr_ptr_a;
  wire [PTR_W-1:0] a_eff_rd_ptr = a_dir ? b_rd_ptr_a : a_rd_ptr;

  // For side B:
  // When b_dir=1 (B writes): b_wr_ptr
  // When b_dir=0 (B reads): b_rd_ptr
  // The opposite side's pointer (synchronized) tells us the other end's position
  wire [PTR_W-1:0] b_eff_wr_ptr = b_dir ? b_wr_ptr : a_wr_ptr_b;
  wire [PTR_W-1:0] b_eff_rd_ptr = b_dir ? b_rd_ptr : a_rd_ptr_b;

  // Compute occupancy from each side's perspective
  // Occupancy = (wr_ptr - rd_ptr) mod DEPTH
  // We need to handle the wrap-around

  // For side A:
  wire [PTR_W-1:0] a_occ = a_eff_wr_ptr - a_eff_rd_ptr;
  wire a_full = (a_occ == DEPTH);
  wire a_afull = (a_occ >= AFULL_THRESH);
  wire a_empty = (a_occ == 0);
  wire a_aempty = (a_occ <= AEMPTY_THRESH);

  // For side B:
  wire [PTR_W-1:0] b_occ = b_eff_wr_ptr - b_eff_rd_ptr;
  wire b_full = (b_occ == DEPTH);
  wire b_afull = (b_occ >= AFULL_THRESH);
  wire b_empty = (b_occ == 0);
  wire b_aempty = (b_occ <= AEMPTY_THRESH);

  // Write enable logic
  // A can write when a_dir=1 and not full
  wire a_write_en = a_dir & a_winc & ~a_full;
  // B can write when b_dir=1 and not full
  wire b_write_en = b_dir & b_winc & ~b_full;

  // Read enable logic
  // A can read when a_dir=0 and not empty
  wire a_read_en = ~a_dir & a_rinc & ~a_empty;
  // B can read when b_dir=0 and not empty
  wire b_read_en = ~b_dir & b_rinc & ~b_empty;

  // Memory write logic
  // Only one side can write at a time (the writer side)
  // If A is writer, write to mem[a_wr_ptr[ASIZE-1:0]]
  // If B is writer, write to mem[b_wr_ptr[ASIZE-1:0]]
  // We need to ensure no conflict. Since only one side is writer at a time,
  // we can use a simple approach.

  // Write to memory
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {PTR_W{1'b0}};
      a_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (a_write_en) begin
        mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1'b1;
      end
      if (a_read_en) begin
        a_rd_ptr <= a_rd_ptr + 1'b1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {PTR_W{1'b0}};
      b_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (b_write_en) begin
        mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1'b1;
      end
      if (b_read_en) begin
        b_rd_ptr <= b_rd_ptr + 1'b1;
      end
    end
  end

  // Read data logic
  // A reads from mem[a_rd_ptr[ASIZE-1:0]] when a_dir=0
  // B reads from mem[b_rd_ptr[ASIZE-1:0]] when b_dir=0
  // We use registered read data to avoid combinational read issues

  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= {DSIZE{1'b0}};
    end else begin
      if (a_read_en) begin
        a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= {DSIZE{1'b0}};
    end else begin
      if (b_read_en) begin
        b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
      end
    end
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
