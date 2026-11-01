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

  // Side A pointers (in A clock domain)
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;

  // Side B pointers (in B clock domain)
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;

  // Gray code pointers for CDC
  wire [PTR_W-1:0] a_wr_ptr_gray = a_wr_ptr ^ (a_wr_ptr >> 1);
  wire [PTR_W-1:0] a_rd_ptr_gray = a_rd_ptr ^ (a_rd_ptr >> 1);
  wire [PTR_W-1:0] b_wr_ptr_gray = b_wr_ptr ^ (b_wr_ptr >> 1);
  wire [PTR_W-1:0] b_rd_ptr_gray = b_rd_ptr ^ (b_rd_ptr >> 1);

  // Synchronized pointers in opposite domains
  reg [PTR_W-1:0] a_wr_ptr_gray_sync1, a_wr_ptr_gray_sync2;
  reg [PTR_W-1:0] a_rd_ptr_gray_sync1, a_rd_ptr_gray_sync2;
  reg [PTR_W-1:0] b_wr_ptr_gray_sync1, b_wr_ptr_gray_sync2;
  reg [PTR_W-1:0] b_rd_ptr_gray_sync1, b_rd_ptr_gray_sync2;

  // Convert gray to binary
  function [PTR_W-1:0] gray2bin;
    input [PTR_W-1:0] gray;
    reg [PTR_W-1:0] bin;
    integer i;
    begin
      bin[PTR_W-1] = gray[PTR_W-1];
      for (i = PTR_W-2; i >= 0; i = i - 1)
        bin[i] = bin[i+1] ^ gray[i];
      gray2bin = bin;
    end
  endfunction

  wire [PTR_W-1:0] a_wr_ptr_bin_b = gray2bin(a_wr_ptr_gray_sync2);
  wire [PTR_W-1:0] a_rd_ptr_bin_b = gray2bin(a_rd_ptr_gray_sync2);
  wire [PTR_W-1:0] b_wr_ptr_bin_a = gray2bin(b_wr_ptr_gray_sync2);
  wire [PTR_W-1:0] b_rd_ptr_bin_a = gray2bin(b_rd_ptr_gray_sync2);

  // Synchronize gray pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync1 <= {PTR_W{1'b0}};
      a_wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
      a_rd_ptr_gray_sync1 <= {PTR_W{1'b0}};
      a_rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
      a_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync1 <= {PTR_W{1'b0}};
      b_wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
      b_rd_ptr_gray_sync1 <= {PTR_W{1'b0}};
      b_rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
      b_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Determine effective write/read enables per side
  // Side A: dir=1 means write, dir=0 means read
  wire a_write_en = a_dir & a_winc & ~a_full;
  wire a_read_en  = ~a_dir & a_rinc & ~a_empty;

  // Side B: dir=1 means write, dir=0 means read
  wire b_write_en = b_dir & b_winc & ~b_full;
  wire b_read_en  = ~b_dir & b_rinc & ~b_empty;

  // Update pointers in A domain
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

  // Update pointers in B domain
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

  // Write to memory
  // A writes when a_write_en
  always @(posedge a_clk) begin
    if (a_write_en)
      mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // B writes when b_write_en
  always @(posedge b_clk) begin
    if (b_write_en)
      mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // Read data
  // A reads when a_read_en
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else if (a_read_en)
      a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
  end

  // B reads when b_read_en
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else if (b_read_en)
      b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
  end

  // Compute full/empty flags
  // A side: full when a_wr_ptr - b_rd_ptr_bin_a == DEPTH
  //         empty when a_rd_ptr == b_wr_ptr_bin_a
  wire a_full  = (a_wr_ptr - b_rd_ptr_bin_a) == DEPTH;
  wire a_empty = (a_rd_ptr == b_wr_ptr_bin_a);

  // B side: full when b_wr_ptr - a_rd_ptr_bin_b == DEPTH
  //         empty when b_rd_ptr == a_wr_ptr_bin_b
  wire b_full  = (b_wr_ptr - a_rd_ptr_bin_b) == DEPTH;
  wire b_empty = (b_rd_ptr == a_wr_ptr_bin_b);

  // Almost full/empty
  wire a_afull  = (a_wr_ptr - b_rd_ptr_bin_a) >= AFULL_THRESH;
  wire a_aempty = (b_wr_ptr_bin_a - a_rd_ptr) <= AEMPTY_THRESH;

  wire b_afull  = (b_wr_ptr - a_rd_ptr_bin_b) >= AFULL_THRESH;
  wire b_aempty = (a_wr_ptr_bin_b - b_rd_ptr) <= AEMPTY_THRESH;

  // Output assignments
  assign a_rdata  = a_rdata_reg;
  assign a_full   = a_full;
  assign a_afull  = a_afull;
  assign a_empty  = a_empty;
  assign a_aempty = a_aempty;

  assign b_rdata  = b_rdata_reg;
  assign b_full   = b_full;
  assign b_afull  = b_afull;
  assign b_empty  = b_empty;
  assign b_aempty = b_aempty;

endmodule
