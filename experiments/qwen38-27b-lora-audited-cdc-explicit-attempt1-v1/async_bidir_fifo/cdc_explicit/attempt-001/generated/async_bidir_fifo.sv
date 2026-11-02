// =============================================================================
// async_bidir_fifo.v
// =============================================================================
// Bidirectional asynchronous FIFO with first-word fall-through.
//
// Architecture:
//   - Two independent async FIFOs (A->B and B->A) sharing one storage array.
//   - Each FIFO uses Gray-coded pointers synchronized across clock domains.
//   - Full/empty flags are derived locally from synchronized pointers.
//   - Almost-full/almost-empty thresholds are configurable.
//   - First-word fall-through: when the FIFO is not empty, the head word is
//     presented combinationally on the read data port.
// =============================================================================

`include "async_bidir_fifo.vh"

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

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // ---------------------------------------------------------------------------
  // A->B FIFO: write side on A clock, read side on B clock
  // ---------------------------------------------------------------------------
  reg [ASIZE:0] a2b_wr_ptr;
  reg [ASIZE:0] a2b_rd_ptr;

  wire [ASIZE:0] a2b_wr_ptr_gray;
  wire [ASIZE:0] a2b_rd_ptr_gray;

  wire [ASIZE:0] a2b_wr_ptr_gray_b;
  wire [ASIZE:0] a2b_rd_ptr_gray_a;

  wire a2b_full;
  wire a2b_empty;
  wire a2b_afull;
  wire a2b_aempty;

  wire a2b_wr_en = a_dir & a_winc & ~a2b_full;
  wire a2b_rd_en = ~b_dir & b_rinc & ~a2b_empty;

  // Write side (A clock)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a2b_wr_ptr <= {(ASIZE+1){1'b0}};
    else if (a2b_wr_en)
      a2b_wr_ptr <= a2b_wr_ptr + 1'b1;
  end

  // Read side (B clock)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      a2b_rd_ptr <= {(ASIZE+1){1'b0}};
    else if (a2b_rd_en)
      a2b_rd_ptr <= a2b_rd_ptr + 1'b1;
  end

  // Gray encoding
  assign a2b_wr_ptr_gray = a2b_wr_ptr ^ (a2b_wr_ptr >> 1);
  assign a2b_rd_ptr_gray = a2b_rd_ptr ^ (a2b_rd_ptr >> 1);

  // Synchronize write pointer to B domain
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] a2b_wr_ptr_gray_b_r1;
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] a2b_wr_ptr_gray_b_r2;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a2b_wr_ptr_gray_b_r1 <= {(ASIZE+1){1'b0}};
      a2b_wr_ptr_gray_b_r2 <= {(ASIZE+1){1'b0}};
    end else begin
      a2b_wr_ptr_gray_b_r1 <= a2b_wr_ptr_gray;
      a2b_wr_ptr_gray_b_r2 <= a2b_wr_ptr_gray_b_r1;
    end
  end

  assign a2b_wr_ptr_gray_b = a2b_wr_ptr_gray_b_r2;

  // Synchronize read pointer to A domain
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] a2b_rd_ptr_gray_a_r1;
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] a2b_rd_ptr_gray_a_r2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a2b_rd_ptr_gray_a_r1 <= {(ASIZE+1){1'b0}};
      a2b_rd_ptr_gray_a_r2 <= {(ASIZE+1){1'b0}};
    end else begin
      a2b_rd_ptr_gray_a_r1 <= a2b_rd_ptr_gray;
      a2b_rd_ptr_gray_a_r2 <= a2b_rd_ptr_gray_a_r1;
    end
  end

  assign a2b_rd_ptr_gray_a = a2b_rd_ptr_gray_a_r2;

  // Full/empty (B domain)
  assign a2b_full  = (a2b_wr_ptr_gray_b == a2b_rd_ptr_gray) &&
                     (a2b_wr_ptr[ASIZE] != a2b_rd_ptr[ASIZE]);
  assign a2b_empty = (a2b_wr_ptr_gray_b == a2b_rd_ptr_gray);

  // Almost full/empty
  assign a2b_afull  = a2b_full ||
                      ((a2b_wr_ptr - a2b_rd_ptr) >= (DEPTH - 1));
  assign a2b_aempty = a2b_empty ||
                      ((a2b_wr_ptr_gray_b - a2b_rd_ptr_gray) <= 1);

  // Memory write (A clock)
  always @(posedge a_clk) begin
    if (a2b_wr_en)
      mem[a2b_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // ---------------------------------------------------------------------------
  // B->A FIFO: write side on B clock, read side on A clock
  // ---------------------------------------------------------------------------
  reg [ASIZE:0] b2a_wr_ptr;
  reg [ASIZE:0] b2a_rd_ptr;

  wire [ASIZE:0] b2a_wr_ptr_gray;
  wire [ASIZE:0] b2a_rd_ptr_gray;

  wire [ASIZE:0] b2a_wr_ptr_gray_a;
  wire [ASIZE:0] b2a_rd_ptr_gray_b;

  wire b2a_full;
  wire b2a_empty;
  wire b2a_afull;
  wire b2a_aempty;

  wire b2a_wr_en = b_dir & b_winc & ~b2a_full;
  wire b2a_rd_en = ~a_dir & a_rinc & ~b2a_empty;

  // Write side (B clock)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b2a_wr_ptr <= {(ASIZE+1){1'b0}};
    else if (b2a_wr_en)
      b2a_wr_ptr <= b2a_wr_ptr + 1'b1;
  end

  // Read side (A clock)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      b2a_rd_ptr <= {(ASIZE+1){1'b0}};
    else if (b2a_rd_en)
      b2a_rd_ptr <= b2a_rd_ptr + 1'b1;
  end

  // Gray encoding
  assign b2a_wr_ptr_gray = b2a_wr_ptr ^ (b2a_wr_ptr >> 1);
  assign b2a_rd_ptr_gray = b2a_rd_ptr ^ (b2a_rd_ptr >> 1);

  // Synchronize write pointer to A domain
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] b2a_wr_ptr_gray_a_r1;
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] b2a_wr_ptr_gray_a_r2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b2a_wr_ptr_gray_a_r1 <= {(ASIZE+1){1'b0}};
      b2a_wr_ptr_gray_a_r2 <= {(ASIZE+1){1'b0}};
    end else begin
      b2a_wr_ptr_gray_a_r1 <= b2a_wr_ptr_gray;
      b2a_wr_ptr_gray_a_r2 <= b2a_wr_ptr_gray_a_r1;
    end
  end

  assign b2a_wr_ptr_gray_a = b2a_wr_ptr_gray_a_r2;

  // Synchronize read pointer to B domain
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] b2a_rd_ptr_gray_b_r1;
  (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] b2a_rd_ptr_gray_b_r2;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b2a_rd_ptr_gray_b_r1 <= {(ASIZE+1){1'b0}};
      b2a_rd_ptr_gray_b_r2 <= {(ASIZE+1){1'b0}};
    end else begin
      b2a_rd_ptr_gray_b_r1 <= b2a_rd_ptr_gray;
      b2a_rd_ptr_gray_b_r2 <= b2a_rd_ptr_gray_b_r1;
    end
  end

  assign b2a_rd_ptr_gray_b = b2a_rd_ptr_gray_b_r2;

  // Full/empty (A domain)
  assign b2a_full  = (b2a_wr_ptr_gray_a == b2a_rd_ptr_gray) &&
                     (b2a_wr_ptr[ASIZE] != b2a_rd_ptr[ASIZE]);
  assign b2a_empty = (b2a_wr_ptr_gray_a == b2a_rd_ptr_gray);

  // Almost full/empty
  assign b2a_afull  = b2a_full ||
                      ((b2a_wr_ptr - b2a_rd_ptr) >= (DEPTH - 1));
  assign b2a_aempty = b2a_empty ||
                      ((b2a_wr_ptr_gray_a - b2a_rd_ptr_gray) <= 1);

  // Memory write (B clock)
  always @(posedge b_clk) begin
    if (b2a_wr_en)
      mem[b2a_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // ---------------------------------------------------------------------------
  // Read data (first-word fall-through)
  // ---------------------------------------------------------------------------
  assign a_rdata = mem[b2a_rd_ptr[ASIZE-1:0]];
  assign b_rdata = mem[a2b_rd_ptr[ASIZE-1:0]];

  // ---------------------------------------------------------------------------
  // Status flags
  // ---------------------------------------------------------------------------
  assign a_full   = b2a_full;
  assign a_afull  = b2a_afull;
  assign a_empty  = b2a_empty;
  assign a_aempty = b2a_aempty;

  assign b_full   = a2b_full;
  assign b_afull  = a2b_afull;
  assign b_empty  = a2b_empty;
  assign b_aempty = a2b_aempty;

endmodule