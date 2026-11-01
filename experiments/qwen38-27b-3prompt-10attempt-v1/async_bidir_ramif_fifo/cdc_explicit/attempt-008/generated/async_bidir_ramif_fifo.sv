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
  localparam AWIDTH_P1 = ASIZE + 2;

  // Side A state
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_gray;
  reg [AWIDTH-1:0] a_rd_ptr_gray;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync;

  // Side B state
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_gray;
  reg [AWIDTH-1:0] b_rd_ptr_gray;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync;

  // Gray code conversion functions
  function [AWIDTH-1:0] bin2gray;
    input [AWIDTH-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  // Side A: Write pointer update
  wire a_wr_en = a_winc & ~a_full;
  wire a_rd_en = a_rinc & ~a_empty;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_wr_en)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_rd_en)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  // Side A: Gray code pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_gray <= {AWIDTH{1'b0}};
      a_rd_ptr_gray <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray <= bin2gray(a_wr_ptr);
      a_rd_ptr_gray <= bin2gray(a_rd_ptr);
    end
  end

  // Side B: Write pointer update
  wire b_wr_en = b_winc & ~b_full;
  wire b_rd_en = b_rinc & ~b_empty;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_wr_en)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_rd_en)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // Side B: Gray code pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_gray <= {AWIDTH{1'b0}};
      b_rd_ptr_gray <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray <= bin2gray(b_wr_ptr);
      b_rd_ptr_gray <= bin2gray(b_rd_ptr);
    end
  end

  // Side A: Synchronize B's pointers into A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync <= b_wr_ptr_gray;
      b_rd_ptr_gray_sync <= b_rd_ptr_gray;
    end
  end

  // Side B: Synchronize A's pointers into B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync <= a_wr_ptr_gray;
      a_rd_ptr_gray_sync <= a_rd_ptr_gray;
    end
  end

  // Side A: Full and Empty flags
  // A is full when A's write pointer has caught up to B's read pointer (in A's view)
  // A is empty when A's read pointer has caught up to B's write pointer (in A's view)
  
  // For a bidirectional FIFO with external RAM:
  // Side A writes to RAM port A, reads from RAM port B
  // Side B writes to RAM port B, reads from RAM port A
  
  // A_full: A cannot write because the FIFO is full. This happens when A's write pointer 
  //         (in A domain) has advanced to where B's read pointer is (as seen by A).
  //         Actually, for a standard async FIFO:
  //         A_full = (a_wr_ptr_gray == b_rd_ptr_gray_sync) with MSB inverted
  //         A_empty = (a_rd_ptr_gray == b_wr_ptr_gray_sync)
  
  // Let's use the standard async FIFO full/empty logic:
  // Full: write pointer gray == read pointer gray (from other side) with MSB toggled
  // Empty: read pointer gray == write pointer gray (from other side)

  wire [AWIDTH-1:0] a_wr_ptr_gray_sync_b; // Not needed, we use direct comparison
  
  // A_full: A's write pointer has caught up to B's read pointer
  // In gray code: a_wr_ptr_gray == b_rd_ptr_gray_sync with MSB inverted
  wire a_full_internal = (a_wr_ptr_gray == {~b_rd_ptr_gray_sync[AWIDTH-1], b_rd_ptr_gray_sync[AWIDTH-2:0]});
  
  // A_empty: A's read pointer has caught up to B's write pointer
  wire a_empty_internal = (a_rd_ptr_gray == b_wr_ptr_gray_sync);

  // B_full: B's write pointer has caught up to A's read pointer
  wire b_full_internal = (b_wr_ptr_gray == {~a_rd_ptr_gray_sync[AWIDTH-1], a_rd_ptr_gray_sync[AWIDTH-2:0]});
  
  // B_empty: B's read pointer has caught up to A's write pointer
  wire b_empty_internal = (b_rd_ptr_gray == a_wr_ptr_gray_sync);

  // Almost full/empty thresholds (1 entry away from full/empty)
  wire [AWIDTH-1:0] a_wr_ptr_gray_plus1 = a_wr_ptr_gray + 1'b1;
  wire [AWIDTH-1:0] a_rd_ptr_gray_plus1 = a_rd_ptr_gray + 1'b1;
  wire [AWIDTH-1:0] b_wr_ptr_gray_plus1 = b_wr_ptr_gray + 1'b1;
  wire [AWIDTH-1:0] b_rd_ptr_gray_plus1 = b_rd_ptr_gray + 1'b1;

  wire a_afull_internal = (a_wr_ptr_gray_plus1 == {~b_rd_ptr_gray_sync[AWIDTH-1], b_rd_ptr_gray_sync[AWIDTH-2:0]});
  wire a_aempty_internal = (a_rd_ptr_gray_plus1 == b_wr_ptr_gray_sync);
  wire b_afull_internal = (b_wr_ptr_gray_plus1 == {~a_rd_ptr_gray_sync[AWIDTH-1], a_rd_ptr_gray_sync[AWIDTH-2:0]});
  wire b_aempty_internal = (b_rd_ptr_gray_plus1 == a_wr_ptr_gray_sync);

  // Output flags
  assign a_full   = a_full_internal;
  assign a_afull  = a_afull_internal;
  assign a_empty  = a_empty_internal;
  assign a_aempty = a_aempty_internal;
  assign b_full   = b_full_internal;
  assign b_afull  = b_afull_internal;
  assign b_empty  = b_empty_internal;
  assign b_aempty = b_aempty_internal;

  // RAM interface
  // Side A: Writes to RAM port A, reads from RAM port B
  // Side B: Writes to RAM port B, reads from RAM port A

  // RAM A: Write from A side, Read from B side
  assign o_ram_a_clk   = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr  = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc  = a_wr_en;
  assign o_ram_a_rinc  = b_rd_en;

  // RAM B: Write from B side, Read from A side
  assign o_ram_b_clk   = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr  = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc  = b_wr_en;
  assign o_ram_b_rinc  = a_rd_en;

  // Read data outputs
  // A reads from RAM B
  assign a_rdata = i_ram_b_rdata;
  // B reads from RAM A
  assign b_rdata = i_ram_a_rdata;

endmodule
