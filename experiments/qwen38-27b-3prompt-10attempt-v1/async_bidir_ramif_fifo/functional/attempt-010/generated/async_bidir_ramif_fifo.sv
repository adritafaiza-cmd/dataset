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

  // Side A: write pointer (A writes), read pointer (B reads)
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr_a; // B's read pointer, synchronized to A

  // Side B: write pointer (B writes), read pointer (A reads)
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr_b; // A's read pointer, synchronized to B

  // Synchronization registers
  reg [AWIDTH-1:0] a_wr_ptr_sync1, a_wr_ptr_sync2, a_wr_ptr_sync3;
  reg [AWIDTH-1:0] b_wr_ptr_sync1, b_wr_ptr_sync2, b_wr_ptr_sync3;
  reg [AWIDTH-1:0] a_rd_ptr_sync1, a_rd_ptr_sync2, a_rd_ptr_sync3;
  reg [AWIDTH-1:0] b_rd_ptr_sync1, b_rd_ptr_sync2, b_rd_ptr_sync3;

  // Synchronized pointers
  wire [AWIDTH-1:0] a_wr_ptr_sync = a_wr_ptr_sync3;
  wire [AWIDTH-1:0] b_wr_ptr_sync = b_wr_ptr_sync3;
  wire [AWIDTH-1:0] a_rd_ptr_sync = a_rd_ptr_sync3;
  wire [AWIDTH-1:0] b_rd_ptr_sync = b_rd_ptr_sync3;

  // Synchronize A's write pointer to B's domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      a_wr_ptr_sync3 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
      a_wr_ptr_sync3 <= a_wr_ptr_sync2;
    end
  end

  // Synchronize B's write pointer to A's domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      b_wr_ptr_sync3 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
      b_wr_ptr_sync3 <= b_wr_ptr_sync2;
    end
  end

  // Synchronize A's read pointer to B's domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync3 <= {AWIDTH{1'b0}};
    end else begin
      a_rd_ptr_sync1 <= a_rd_ptr_b;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
      a_rd_ptr_sync3 <= a_rd_ptr_sync2;
    end
  end

  // Synchronize B's read pointer to A's domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync3 <= {AWIDTH{1'b0}};
    end else begin
      b_rd_ptr_sync1 <= b_rd_ptr_a;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
      b_rd_ptr_sync3 <= b_rd_ptr_sync2;
    end
  end

  // A side: write pointer update
  wire a_wr_en = a_winc & a_dir;
  wire a_rd_en = a_rinc & ~a_dir;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AWIDTH{1'b0}};
    else if (a_wr_en)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  // A side: read pointer update (A reads from B's writes)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr_b <= {AWIDTH{1'b0}};
    else if (a_rd_en)
      a_rd_ptr_b <= a_rd_ptr_b + 1'b1;
  end

  // B side: write pointer update
  wire b_wr_en = b_winc & b_dir;
  wire b_rd_en = b_rinc & ~b_dir;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AWIDTH{1'b0}};
    else if (b_wr_en)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // B side: read pointer update (B reads from A's writes)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr_a <= {AWIDTH{1'b0}};
    else if (b_rd_en)
      b_rd_ptr_a <= b_rd_ptr_a + 1'b1;
  end

  // Full/Empty flags
  // A full: A's write pointer has caught up to B's read pointer (synchronized)
  wire a_full = (a_wr_ptr == b_rd_ptr_sync);
  wire a_empty = (a_wr_ptr == a_rd_ptr_b);

  // B full: B's write pointer has caught up to A's read pointer (synchronized)
  wire b_full = (b_wr_ptr == a_rd_ptr_sync);
  wire b_empty = (b_wr_ptr == b_rd_ptr_a);

  // Almost full/empty (1 entry margin)
  wire a_afull = (a_wr_ptr[ASIZE-1:0] == b_rd_ptr_sync[ASIZE-1:0]) &&
                 (a_wr_ptr[ASIZE] != b_rd_ptr_sync[ASIZE]);
  wire a_aempty = (a_wr_ptr[ASIZE-1:0] == a_rd_ptr_b[ASIZE-1:0]) &&
                  (a_wr_ptr[ASIZE] != a_rd_ptr_b[ASIZE]);

  wire b_afull = (b_wr_ptr[ASIZE-1:0] == a_rd_ptr_sync[ASIZE-1:0]) &&
                 (b_wr_ptr[ASIZE] != a_rd_ptr_sync[ASIZE]);
  wire b_aempty = (b_wr_ptr[ASIZE-1:0] == b_rd_ptr_a[ASIZE-1:0]) &&
                  (b_wr_ptr[ASIZE] != b_rd_ptr_a[ASIZE]);

  // RAM interface
  // A side RAM: A writes, B reads
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc = a_wr_en;
  assign o_ram_a_rinc = b_rd_en;

  // B side RAM: B writes, A reads
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc = b_wr_en;
  assign o_ram_b_rinc = a_rd_en;

  // Read data
  // A reads from B's RAM
  assign a_rdata = i_ram_b_rdata;
  // B reads from A's RAM
  assign b_rdata = i_ram_a_rdata;

  // Output flags
  assign a_full = a_full;
  assign a_afull = a_afull;
  assign a_empty = a_empty;
  assign a_aempty = a_aempty;
  assign b_full = b_full;
  assign b_afull = b_afull;
  assign b_empty = b_empty;
  assign b_aempty = b_aempty;

endmodule
