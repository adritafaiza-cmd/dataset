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
  localparam AFULL_THRESH  = DEPTH - 1;
  localparam AEMPTY_THRESH = 1;

  // --- A-side state ---
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_b;
  reg [AWIDTH-1:0] a_rd_ptr_b;
  reg [AWIDTH-1:0] a_wr_ptr_b_sync1;
  reg [AWIDTH-1:0] a_wr_ptr_b_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_b_sync1;
  reg [AWIDTH-1:0] a_rd_ptr_b_sync2;

  // --- B-side state ---
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_a;
  reg [AWIDTH-1:0] b_rd_ptr_a;
  reg [AWIDTH-1:0] b_wr_ptr_a_sync1;
  reg [AWIDTH-1:0] b_wr_ptr_a_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_a_sync1;
  reg [AWIDTH-1:0] b_rd_ptr_a_sync2;

  // --- A-side derived signals ---
  wire [AWIDTH-1:0] a_wr_ptr_b_sync = a_wr_ptr_b_sync2;
  wire [AWIDTH-1:0] a_rd_ptr_b_sync = a_rd_ptr_b_sync2;

  wire a_full  = (a_wr_ptr == a_rd_ptr_b_sync) && (a_wr_ptr[ASIZE] != a_rd_ptr_b_sync[ASIZE]);
  wire a_empty = (a_wr_ptr_b_sync == a_rd_ptr) && (a_wr_ptr_b_sync[ASIZE] == a_rd_ptr[ASIZE]);
  wire a_afull  = (a_wr_ptr - a_rd_ptr_b_sync) >= AFULL_THRESH;
  wire a_aempty = (a_wr_ptr_b_sync - a_rd_ptr) <= AEMPTY_THRESH;

  // --- B-side derived signals ---
  wire [AWIDTH-1:0] b_wr_ptr_a_sync = b_wr_ptr_a_sync2;
  wire [AWIDTH-1:0] b_rd_ptr_a_sync = b_rd_ptr_a_sync2;

  wire b_full  = (b_wr_ptr == b_rd_ptr_a_sync) && (b_wr_ptr[ASIZE] != b_rd_ptr_a_sync[ASIZE]);
  wire b_empty = (b_wr_ptr_a_sync == b_rd_ptr) && (b_wr_ptr_a_sync[ASIZE] == b_rd_ptr[ASIZE]);
  wire b_afull  = (b_wr_ptr - b_rd_ptr_a_sync) >= AFULL_THRESH;
  wire b_aempty = (b_wr_ptr_a_sync - b_rd_ptr) <= AEMPTY_THRESH;

  // --- A-side pointer updates ---
  wire a_wr_en = a_winc && !a_full;
  wire a_rd_en = a_rinc && !a_empty;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_wr_en) a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_rd_en) a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  // --- B-side pointer updates ---
  wire b_wr_en = b_winc && !b_full;
  wire b_rd_en = b_rinc && !b_empty;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_wr_en) b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_rd_en) b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // --- A-side: snapshot B's pointers into A's domain ---
  // b_wr_ptr and b_rd_ptr are in B's domain. We need to send them to A.
  // But wait: the pointers that cross are the *remote* side's pointers.
  // For A to know if it's full, it needs to know B's read pointer (how much B has consumed).
  // For A to know if it's empty, it needs to know B's write pointer (how much B has produced).
  // Actually, let me reconsider the architecture.
  
  // The FIFO is bidirectional. Data can flow A->B or B->A.
  // The direction is controlled by a_dir and b_dir.
  // When a_dir=1, A writes to the FIFO (A is the source). B reads from the FIFO (B is the sink).
  // When b_dir=1, B writes to the FIFO (B is the source). A reads from the FIFO (A is the sink).
  
  // The RAM is shared. The write port and read port are separate.
  // The write side writes to RAM, the read side reads from RAM.
  
  // For A->B direction:
  //   A writes to RAM using o_ram_a_* ports
  //   B reads from RAM using o_ram_b_* ports
  //   A's write pointer increments on a_winc
  //   B's read pointer increments on b_rinc
  //   A needs to know B's read pointer to detect full
  //   B needs to know A's write pointer to detect empty
  
  // For B->A direction:
  //   B writes to RAM using o_ram_b_* ports
  //   A reads from RAM using o_ram_a_* ports
  //   B's write pointer increments on b_winc
  //   A's read pointer increments on a_rinc
  //   B needs to know A's read pointer to detect full
  //   A needs to know B's write pointer to detect empty

  // So the pointers that cross:
  //   A_wr_ptr -> B domain (for B to detect empty in A->B, or full in B->A)
  //   A_rd_ptr -> B domain (for B to detect full in A->B, or empty in B->A)
  //   B_wr_ptr -> A domain (for A to detect empty in A->B, or full in B->A)
  //   B_rd_ptr -> A domain (for A to detect full in A->B, or empty in B->A)

  // Let me redefine:
  // a_wr_ptr: A's write pointer (in A domain)
  // a_rd_ptr: A's read pointer (in A domain)
  // b_wr_ptr: B's write pointer (in B domain)
  // b_rd_ptr: B's read pointer (in B domain)

  // Crossings:
  // a_wr_ptr -> B: a_wr_ptr_b
  // a_rd_ptr -> B: a_rd_ptr_b
  // b_wr_ptr -> A: b_wr_ptr_a
  // b_rd_ptr -> A: b_rd_ptr_a

  // Full/Empty logic:
  // In A->B mode (a_dir=1, b_dir=0):
  //   A is writer, B is reader
  //   a_full: A can't write if FIFO is full. Full when a_wr_ptr has lapped a_rd_ptr_b (B's read ptr as seen by A)
  //   a_empty: A can't read (but A is writer, so a_empty is for B's perspective? No, a_empty is A's empty status)
  //   Actually, a_full and a_empty are from A's perspective.
  //   a_full: FIFO is full, A cannot write. This happens when the number of items in FIFO = DEPTH.
  //   a_empty: FIFO is empty, A cannot read. This happens when the number of items in FIFO = 0.
  
  // The number of items in the FIFO depends on the direction.
  // If A->B: items = a_wr_ptr - b_rd_ptr (mod 2^AWIDTH)
  // If B->A: items = b_wr_ptr - a_rd_ptr (mod 2^AWIDTH)

  // So:
  // a_full in A->B mode: (a_wr_ptr - b_rd_ptr_a_sync) == DEPTH
  // a_empty in A->B mode: (a_wr_ptr - b_rd_ptr_a_sync) == 0
  // a_full in B->A mode: (b_wr_ptr_a_sync - a_rd_ptr) == DEPTH
  // a_empty in B->A mode: (b_wr_ptr_a_sync - a_rd_ptr) == 0

  // Similarly for B:
  // b_full in A->B mode: (a_wr_ptr_b_sync - b_rd_ptr) == DEPTH
  // b_empty in A->B mode: (a_wr_ptr_b_sync - b_rd_ptr) == 0
  // b_full in B->A mode: (b_wr_ptr - a_rd_ptr_b_sync) == DEPTH
  // b_empty in B->A mode: (b_wr_ptr - a_rd_ptr_b_sync) == 0

  // Let me redo the pointer crossing and status logic properly.

  // --- A-side: sync B's pointers into A's domain ---
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_a_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_a_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_a_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_a_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_a_sync1 <= b_wr_ptr_a;
      b_wr_ptr_a_sync2 <= b_wr_ptr_a_sync1;
      b_rd_ptr_a_sync1 <= b_rd_ptr_a;
      b_rd_ptr_a_sync2 <= b_rd_ptr_a_sync1;
    end
  end

  // --- B-side: sync A's pointers into B's domain ---
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_b_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_b_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_b_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_b_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_b_sync1 <= a_wr_ptr_b;
      a_wr_ptr_b_sync2 <= a_wr_ptr_b_sync1;
      a_rd_ptr_b_sync1 <= a_rd_ptr_b;
      a_rd_ptr_b_sync2 <= a_rd_ptr_b_sync1;
    end
  end

  // --- A-side status ---
  wire [AWIDTH-1:0] a_items_ab = a_wr_ptr - b_rd_ptr_a_sync2; // A->B: items in FIFO
  wire [AWIDTH-1:0] a_items_ba = b_wr_ptr_a_sync2 - a_rd_ptr; // B->A: items in FIFO

  wire a_full_ab  = (a_items_ab == DEPTH);
  wire a_empty_ab = (a_items_ab == 0);
  wire a_full_ba  = (a_items_ba == DEPTH);
  wire a_empty_ba = (a_items_ba == 0);

  assign a_full  = a_dir ? a_full_ab  : a_full_ba;
  assign a_empty = a_dir ? a_empty_ab : a_empty_ba;

  wire [AWIDTH-1:0] a_afull_ab  = a_items_ab;
  wire [AWIDTH-1:0] a_aempty_ab = a_items_ab;
  wire [AWIDTH-1:0] a_afull_ba  = a_items_ba;
  wire [AWIDTH-1:0] a_aempty_ba = a_items_ba;

  assign a_afull  = a_dir ? (a_afull_ab  >= AFULL_THRESH)  : (a_afull_ba  >= AFULL_THRESH);
  assign a_aempty = a_dir ? (a_aempty_ab <= AEMPTY_THRESH) : (a_aempty_ba <= AEMPTY_THRESH);

  // --- B-side status ---
  wire [AWIDTH-1:0] b_items_ab = a_wr_ptr_b_sync2 - b_rd_ptr; // A->B: items in FIFO
  wire [AWIDTH-1:0] b_items_ba = b_wr_ptr - a_rd_ptr_b_sync2; // B->A: items in FIFO

  wire b_full_ab  = (b_items_ab == DEPTH);
  wire b_empty_ab = (b_items_ab == 0);
  wire b_full_ba  = (b_items_ba == DEPTH);
  wire b_empty_ba = (b_items_ba == 0);

  assign b_full  = b_dir ? b_full_ba  : b_full_ab;
  assign b_empty = b_dir ? b_empty_ba : b_empty_ab;

  wire [AWIDTH-1:0] b_afull_ab  = b_items_ab;
  wire [AWIDTH-1:0] b_aempty_ab = b_items_ab;
  wire [AWIDTH-1:0] b_afull_ba  = b_items_ba;
  wire [AWIDTH-1:0] b_aempty_ba = b_items_ba;

  assign b_afull  = b_dir ? (b_afull_ba  >= AFULL_THRESH)  : (b_afull_ab  >= AFULL_THRESH);
  assign b_aempty = b_dir ? (b_aempty_ba <= AEMPTY_THRESH) : (b_aempty_ab <= AEMPTY_THRESH);

  // --- A-side pointer crossing to B ---
  // a_wr_ptr and a_rd_ptr are in A domain. We need to send them to B.
  // We use a simple 2-flop synchronizer for each.
  // But the pointers change in A domain. We need to capture them and sync to B.
  // The standard approach is to use a gray code or binary with handshake.
  // The problem says "acknowledged binary snapshots". Let's use a simple 2-flop sync for now,
  // assuming the pointers change slowly enough or we use a more robust method.
  // For simplicity and given the constraints, I'll use 2-flop synchronizers.

  // Actually, for binary pointers, 2-flop sync can miss transitions. 
  // The problem says "acknowledged binary snapshots". This implies a handshake.
  // Let me implement a simple handshake-based synchronizer.

  // For each pointer crossing, we need:
  //   Source domain: register the pointer, assert a "valid" signal
  //   Destination domain: sync the valid signal, when valid is high, capture the pointer

  // Let me implement this for a_wr_ptr -> B and a_rd_ptr -> B.

  // --- a_wr_ptr to B ---
  reg [AWIDTH-1:0] a_wr_ptr_reg;
  reg              a_wr_ptr_valid;
  reg              a_wr_ptr_valid_b_sync1;
  reg              a_wr_ptr_valid_b_sync2;
  reg              a_wr_ptr_valid_b_sync3;
  reg [AWIDTH-1:0] a_wr_ptr_b;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_reg   <= {AWIDTH{1'b0}};
      a_wr_ptr_valid <= 1'b0;
    end else begin
      a_wr_ptr_reg <= a_wr_ptr;
      if (a_wr_ptr_valid_b_sync3 == 1'b0) begin
        a_wr_ptr_valid <= 1'b1;
      end else begin
        a_wr_ptr_valid <= 1'b0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_valid_b_sync1 <= 1'b0;
      a_wr_ptr_valid_b_sync2 <= 1'b0;
      a_wr_ptr_valid_b_sync3 <= 1'b0;
      a_wr_ptr_b             <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_valid_b_sync1 <= a_wr_ptr_valid;
      a_wr_ptr_valid_b_sync2 <= a_wr_ptr_valid_b_sync1;
      a_wr_ptr_valid_b_sync3 <= a_wr_ptr_valid_b_sync2;
      if (a_wr_ptr_valid_b_sync3 == 1'b1) begin
        a_wr_ptr_b <= a_wr_ptr_reg;
      end
    end
  end

  // --- a_rd_ptr to B ---
  reg [AWIDTH-1:0] a_rd_ptr_reg;
  reg              a_rd_ptr_valid;
  reg              a_rd_ptr_valid_b_sync1;
  reg              a_rd_ptr_valid_b_sync2;
  reg              a_rd_ptr_valid_b_sync3;
  reg [AWIDTH-1:0] a_rd_ptr_b;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr_reg   <= {AWIDTH{1'b0}};
      a_rd_ptr_valid <= 1'b0;
    end else begin
      a_rd_ptr_reg <= a_rd_ptr;
      if (a_rd_ptr_valid_b_sync3 == 1'b0) begin
        a_rd_ptr_valid <= 1'b1;
      end else begin
        a_rd_ptr_valid <= 1'b0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_valid_b_sync1 <= 1'b0;
      a_rd_ptr_valid_b_sync2 <= 1'b0;
      a_rd_ptr_valid_b_sync3 <= 1'b0;
      a_rd_ptr_b             <= {AWIDTH{1'b0}};
    end else begin
      a_rd_ptr_valid_b_sync1 <= a_rd_ptr_valid;
      a_rd_ptr_valid_b_sync2 <= a_rd_ptr_valid_b_sync1;
      a_rd_ptr_valid_b_sync3 <= a_rd_ptr_valid_b_sync2;
      if (a_rd_ptr_valid_b_sync3 == 1'b1) begin
        a_rd_ptr_b <= a_rd_ptr_reg;
      end
    end
  end

  // --- b_wr_ptr to A ---
  reg [AWIDTH-1:0] b_wr_ptr_reg;
  reg              b_wr_ptr_valid;
  reg              b_wr_ptr_valid_a_sync1;
  reg              b_wr_ptr_valid_a_sync2;
  reg              b_wr_ptr_valid_a_sync3;
  reg [AWIDTH-1:0] b_wr_ptr_a;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_reg   <= {AWIDTH{1'b0}};
      b_wr_ptr_valid <= 1'b0;
    end else begin
      b_wr_ptr_reg <= b_wr_ptr;
      if (b_wr_ptr_valid_a_sync3 == 1'b0) begin
        b_wr_ptr_valid <= 1'b1;
      end else begin
        b_wr_ptr_valid <= 1'b0;
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_valid_a_sync1 <= 1'b0;
      b_wr_ptr_valid_a_sync2 <= 1'b0;
      b_wr_ptr_valid_a_sync3 <= 1'b0;
      b_wr_ptr_a             <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_valid_a_sync1 <= b_wr_ptr_valid;
      b_wr_ptr_valid_a_sync2 <= b_wr_ptr_valid_a_sync1;
      b_wr_ptr_valid_a_sync3 <= b_wr_ptr_valid_a_sync2;
      if (b_wr_ptr_valid_a_sync3 == 1'b1) begin
        b_wr_ptr_a <= b_wr_ptr_reg;
      end
    end
  end

  // --- b_rd_ptr to A ---
  reg [AWIDTH-1:0] b_rd_ptr_reg;
  reg              b_rd_ptr_valid;
  reg              b_rd_ptr_valid_a_sync1;
  reg              b_rd_ptr_valid_a_sync2;
  reg              b_rd_ptr_valid_a_sync3;
  reg [AWIDTH-1:0] b_rd_ptr_a;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr_reg   <= {AWIDTH{1'b0}};
      b_rd_ptr_valid <= 1'b0;
    end else begin
      b_rd_ptr_reg <= b_rd_ptr;
      if (b_rd_ptr_valid_a_sync3 == 1'b0) begin
        b_rd_ptr_valid <= 1'b1;
      end else begin
        b_rd_ptr_valid <= 1'b0;
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_valid_a_sync1 <= 1'b0;
      b_rd_ptr_valid_a_sync2 <= 1'b0;
      b_rd_ptr_valid_a_sync3 <= 1'b0;
      b_rd_ptr_a             <= {AWIDTH{1'b0}};
    end else begin
      b_rd_ptr_valid_a_sync1 <= b_rd_ptr_valid;
      b_rd_ptr_valid_a_sync2 <= b_rd_ptr_valid_a_sync1;
      b_rd_ptr_valid_a_sync3 <= b_rd_ptr_valid_a_sync2;
      if (b_rd_ptr_valid_a_sync3 == 1'b1) begin
        b_rd_ptr_a <= b_rd_ptr_reg;
      end
    end
  end

  // --- RAM interface ---
  // o_ram_a_clk and o_ram_b_clk are outputs. They should be tied to a_clk and b_clk respectively.
  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  // A-side RAM:
  // When a_dir=1, A is the writer. o_ram_a_winc = a_winc && !a_full
  // When a_dir=0, A is the reader. o_ram_a_rinc = a_rinc && !a_empty
  // The address is the lower ASIZE bits of the respective pointer.

  wire a_ram_winc = a_dir && a_winc && !a_full;
  wire a_ram_rinc = !a_dir && a_rinc && !a_empty;

  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr  = a_dir ? a_wr_ptr[ASIZE-1:0] : a_rd_ptr[ASIZE-1:0];
  assign o_ram_a_winc  = a_ram_winc;
  assign o_ram_a_rinc  = a_ram_rinc;

  // B-side RAM:
  // When b_dir=1, B is the writer. o_ram_b_winc = b_winc && !b_full
  // When b_dir=0, B is the reader. o_ram_b_rinc = b_rinc && !b_empty

  wire b_ram_winc = b_dir && b_winc && !b_full;
  wire b_ram_rinc = !b_dir && b_rinc && !b_empty;

  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr  = b_dir ? b_wr_ptr[ASIZE-1:0] : b_rd_ptr[ASIZE-1:0];
  assign o_ram_b_winc  = b_ram_winc;
  assign o_ram_b_rinc  = b_ram_rinc;

  // --- Read data output ---
  // a_rdata: When A is the reader (a_dir=0), a_rdata comes from i_ram_a_rdata.
  //          When A is the writer (a_dir=1), a_rdata is don't care, but we can tie it to i_ram_a_rdata.
  // b_rdata: When B is the reader (b_dir=0), b_rdata comes from i_ram_b_rdata.
  //          When B is the writer (b_dir=1), b_rdata is don't care, but we can tie it to i_ram_b_rdata.

  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

endmodule
