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

  localparam AWIDTH = ASIZE + 1;
  localparam DEPTH  = 1 << ASIZE;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // --- A side state ---
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_b;
  reg [AWIDTH-1:0] a_rd_ptr_b;

  // --- B side state ---
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_a;
  reg [AWIDTH-1:0] b_rd_ptr_a;

  // --- CDC synchronizers ---
  // A->B: a_wr_ptr, a_rd_ptr
  reg [AWIDTH-1:0] a_wr_ptr_sync1, a_wr_ptr_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_sync1, a_rd_ptr_sync2;

  // B->A: b_wr_ptr, b_rd_ptr
  reg [AWIDTH-1:0] b_wr_ptr_sync1, b_wr_ptr_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_sync1, b_rd_ptr_sync2;

  // --- A side logic ---
  wire a_wr_en = a_winc & ~a_full;
  wire a_rd_en = a_rinc & ~a_empty;

  wire [AWIDTH-1:0] a_wr_ptr_next = a_wr_ptr + 1'b1;
  wire [AWIDTH-1:0] a_rd_ptr_next = a_rd_ptr + 1'b1;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_wr_en) a_wr_ptr <= a_wr_ptr_next;
      if (a_rd_en) a_rd_ptr <= a_rd_ptr_next;
    end
  end

  // Synchronize A pointers to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_sync1 <= a_wr_ptr;
      a_wr_ptr_sync2 <= a_wr_ptr_sync1;
      a_rd_ptr_sync1 <= a_rd_ptr;
      a_rd_ptr_sync2 <= a_rd_ptr_sync1;
    end
  end

  // B side sees A pointers
  assign a_wr_ptr_b = a_wr_ptr_sync2;
  assign a_rd_ptr_b = a_rd_ptr_sync2;

  // --- B side logic ---
  wire b_wr_en = b_winc & ~b_full;
  wire b_rd_en = b_rinc & ~b_empty;

  wire [AWIDTH-1:0] b_wr_ptr_next = b_wr_ptr + 1'b1;
  wire [AWIDTH-1:0] b_rd_ptr_next = b_rd_ptr + 1'b1;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_wr_en) b_wr_ptr <= b_wr_ptr_next;
      if (b_rd_en) b_rd_ptr <= b_rd_ptr_next;
    end
  end

  // Synchronize B pointers to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_sync1 <= b_wr_ptr;
      b_wr_ptr_sync2 <= b_wr_ptr_sync1;
      b_rd_ptr_sync1 <= b_rd_ptr;
      b_rd_ptr_sync2 <= b_rd_ptr_sync1;
    end
  end

  // A side sees B pointers
  assign b_wr_ptr_a = b_wr_ptr_sync2;
  assign b_rd_ptr_a = b_rd_ptr_sync2;

  // --- Full/Empty calculations ---
  // A side: A is source when a_dir=0, destination when a_dir=1
  // When a_dir=0: A writes, B reads. A full when A wr_ptr - B rd_ptr >= DEPTH
  //               A empty when A wr_ptr == B rd_ptr
  // When a_dir=1: B writes, A reads. A full when B wr_ptr - A rd_ptr >= DEPTH
  //               A empty when B wr_ptr == A rd_ptr

  wire [AWIDTH-1:0] a_count_dir0 = a_wr_ptr - b_rd_ptr_a;
  wire [AWIDTH-1:0] a_count_dir1 = b_wr_ptr_a - a_rd_ptr;

  wire a_full_dir0  = (a_count_dir0 >= DEPTH[AWIDTH-1:0]);
  wire a_empty_dir0 = (a_count_dir0 == {AWIDTH{1'b0}});
  wire a_full_dir1  = (a_count_dir1 >= DEPTH[AWIDTH-1:0]);
  wire a_empty_dir1 = (a_count_dir1 == {AWIDTH{1'b0}});

  assign a_full  = a_dir ? a_full_dir1  : a_full_dir0;
  assign a_empty = a_dir ? a_empty_dir1 : a_empty_dir0;

  wire a_afull_dir0  = (a_count_dir0 >= AFULL_THRESH[AWIDTH-1:0]);
  wire a_aempty_dir0 = (a_count_dir0 <= AEMPTY_THRESH[AWIDTH-1:0]);
  wire a_afull_dir1  = (a_count_dir1 >= AFULL_THRESH[AWIDTH-1:0]);
  wire a_aempty_dir1 = (a_count_dir1 <= AEMPTY_THRESH[AWIDTH-1:0]);

  assign a_afull  = a_dir ? a_afull_dir1  : a_afull_dir0;
  assign a_aempty = a_dir ? a_aempty_dir1 : a_aempty_dir0;

  // B side: B is source when b_dir=0, destination when b_dir=1
  // When b_dir=0: B writes, A reads. B full when B wr_ptr - A rd_ptr >= DEPTH
  //               B empty when B wr_ptr == A rd_ptr
  // When b_dir=1: A writes, B reads. B full when A wr_ptr - B rd_ptr >= DEPTH
  //               B empty when A wr_ptr == B rd_ptr

  wire [AWIDTH-1:0] b_count_dir0 = b_wr_ptr - a_rd_ptr_b;
  wire [AWIDTH-1:0] b_count_dir1 = a_wr_ptr_b - b_rd_ptr;

  wire b_full_dir0  = (b_count_dir0 >= DEPTH[AWIDTH-1:0]);
  wire b_empty_dir0 = (b_count_dir0 == {AWIDTH{1'b0}});
  wire b_full_dir1  = (b_count_dir1 >= DEPTH[AWIDTH-1:0]);
  wire b_empty_dir1 = (b_count_dir1 == {AWIDTH{1'b0}});

  assign b_full  = b_dir ? b_full_dir1  : b_full_dir0;
  assign b_empty = b_dir ? b_empty_dir1 : b_empty_dir0;

  wire b_afull_dir0  = (b_count_dir0 >= AFULL_THRESH[AWIDTH-1:0]);
  wire b_aempty_dir0 = (b_count_dir0 <= AEMPTY_THRESH[AWIDTH-1:0]);
  wire b_afull_dir1  = (b_count_dir1 >= AFULL_THRESH[AWIDTH-1:0]);
  wire b_aempty_dir1 = (b_count_dir1 <= AEMPTY_THRESH[AWIDTH-1:0]);

  assign b_afull  = b_dir ? b_afull_dir1  : b_afull_dir0;
  assign b_aempty = b_dir ? b_aempty_dir1 : b_aempty_dir0;

  // --- RAM interface ---
  // o_ram_a_clk is tied to a_clk
  assign o_ram_a_clk = a_clk;

  // A side RAM:
  // When a_dir=0: A is source, writes to RAM. o_ram_a_winc = a_winc, o_ram_a_rinc = 0
  //               o_ram_a_addr = a_wr_ptr[ASIZE-1:0], o_ram_a_wdata = a_wdata
  //               a_rdata comes from i_ram_a_rdata (but A is writing, so a_rdata is not used for output)
  //               Actually, a_rdata should reflect what A reads. When a_dir=0, A writes, so a_rdata is don't care or 0.
  //               But the spec says a_rdata is output. Let's think: a_rdata is the data read from A's port.
  //               When a_dir=0, A is the source (writing), so a_rinc should be 0 and a_rdata is not valid.
  //               When a_dir=1, A is the destination (reading), so a_rinc drives reads.
  //
  // Actually, re-reading: "Move words in either direction using the external RAM ports for storage."
  // The RAM ports are external. A side has its own RAM port, B side has its own RAM port.
  // When data flows A->B: A writes to its RAM port, B reads from its RAM port.
  // When data flows B->A: B writes to its RAM port, A reads from its RAM port.
  //
  // So:
  // A side RAM:
  //   Write when a_dir=0 and a_winc (A is source)
  //   Read when a_dir=1 and a_rinc (A is destination)
  // B side RAM:
  //   Write when b_dir=0 and b_winc (B is source)
  //   Read when b_dir=1 and b_rinc (B is destination)

  wire a_ram_wen = (a_dir == 1'b0) & a_winc & ~a_full;
  wire a_ram_ren = (a_dir == 1'b1) & a_rinc & ~a_empty;

  assign o_ram_a_winc  = a_ram_wen;
  assign o_ram_a_rinc  = a_ram_ren;
  assign o_ram_a_addr  = a_ram_wen ? a_wr_ptr[ASIZE-1:0] : a_rd_ptr[ASIZE-1:0];
  assign o_ram_a_wdata = a_wdata;

  // a_rdata: when reading from A's RAM, the data comes from i_ram_a_rdata
  // With fall-through, if FALLTHROUGH is true and we're reading, we might get the write data directly
  // But since RAM is external, fall-through means the read data is available in the same cycle as write
  // For simplicity, a_rdata = i_ram_a_rdata when reading, else 0
  assign a_rdata = a_ram_ren ? i_ram_a_rdata : {DSIZE{1'b0}};

  // B side RAM:
  wire b_ram_wen = (b_dir == 1'b0) & b_winc & ~b_full;
  wire b_ram_ren = (b_dir == 1'b1) & b_rinc & ~b_empty;

  assign o_ram_b_clk   = b_clk;
  assign o_ram_b_winc  = b_ram_wen;
  assign o_ram_b_rinc  = b_ram_ren;
  assign o_ram_b_addr  = b_ram_wen ? b_wr_ptr[ASIZE-1:0] : b_rd_ptr[ASIZE-1:0];
  assign o_ram_b_wdata = b_wdata;

  assign b_rdata = b_ram_ren ? i_ram_b_rdata : {DSIZE{1'b0}};

endmodule
