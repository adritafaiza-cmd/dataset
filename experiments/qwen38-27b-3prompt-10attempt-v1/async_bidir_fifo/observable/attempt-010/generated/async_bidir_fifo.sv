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

  localparam AWIDTH = ASIZE;
  localparam DEPTH  = 1 << AWIDTH;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // Internal FIFO storage
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Direction registers (synchronized)
  reg a_dir_reg;
  reg b_dir_reg;

  // Write pointers
  reg [AWIDTH:0] a_wr_ptr;
  reg [AWIDTH:0] b_wr_ptr;

  // Read pointers
  reg [AWIDTH:0] a_rd_ptr;
  reg [AWIDTH:0] b_rd_ptr;

  // Gray code pointers
  wire [AWIDTH:0] a_wr_ptr_gray;
  wire [AWIDTH:0] b_wr_ptr_gray;
  wire [AWIDTH:0] a_rd_ptr_gray;
  wire [AWIDTH:0] b_rd_ptr_gray;

  // Synchronized gray pointers
  reg [AWIDTH:0] a_wr_ptr_gray_sync1, a_wr_ptr_gray_sync2;
  reg [AWIDTH:0] b_wr_ptr_gray_sync1, b_wr_ptr_gray_sync2;
  reg [AWIDTH:0] a_rd_ptr_gray_sync1, a_rd_ptr_gray_sync2;
  reg [AWIDTH:0] b_rd_ptr_gray_sync1, b_rd_ptr_gray_sync2;

  // Binary pointers reconstructed from gray
  reg [AWIDTH:0] a_wr_ptr_bin_sync;
  reg [AWIDTH:0] b_wr_ptr_bin_sync;
  reg [AWIDTH:0] a_rd_ptr_bin_sync;
  reg [AWIDTH:0] b_rd_ptr_bin_sync;

  // Full/Empty signals
  wire a_full_internal;
  wire b_full_internal;
  wire a_empty_internal;
  wire b_empty_internal;

  // Almost full/empty
  wire a_afull_internal;
  wire b_afull_internal;
  wire a_aempty_internal;
  wire b_aempty_internal;

  // Write enable
  wire a_write_en;
  wire b_write_en;

  // Read enable
  wire a_read_en;
  wire b_read_en;

  // Fall-through logic
  wire fallthrough;

  // Data path
  wire [DSIZE-1:0] a_read_data;
  wire [DSIZE-1:0] b_read_data;

  // Gray code conversion functions
  function [AWIDTH:0] bin2gray;
    input [AWIDTH:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [AWIDTH:0] gray2bin;
    input [AWIDTH:0] gray;
    reg [AWIDTH:0] bin;
    integer i;
    begin
      bin[AWIDTH] = gray[AWIDTH];
      for (i = AWIDTH-1; i >= 0; i = i - 1)
        bin[i] = gray[i] ^ bin[i+1];
      gray2bin = bin;
    end
  endfunction

  // Gray code pointers
  assign a_wr_ptr_gray = bin2gray(a_wr_ptr);
  assign b_wr_ptr_gray = bin2gray(b_wr_ptr);
  assign a_rd_ptr_gray = bin2gray(a_rd_ptr);
  assign b_rd_ptr_gray = bin2gray(b_rd_ptr);

  // Synchronize gray pointers across clock domains
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
      a_rd_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
      a_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
      b_rd_ptr_gray_sync1 <= {AWIDTH+1{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH+1{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
      b_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Convert synchronized gray to binary
  assign a_wr_ptr_bin_sync = gray2bin(a_wr_ptr_gray_sync2);
  assign b_wr_ptr_bin_sync = gray2bin(b_wr_ptr_gray_sync2);
  assign a_rd_ptr_bin_sync = gray2bin(a_rd_ptr_gray_sync2);
  assign b_rd_ptr_bin_sync = gray2bin(b_rd_ptr_gray_sync2);

  // Full/Empty detection
  // A side: writes when a_dir=1, reads when a_dir=0
  // B side: writes when b_dir=1, reads when b_dir=0
  // 
  // For A side:
  //   a_full: A is writing, so check if a_wr_ptr == b_rd_ptr (B's read pointer)
  //   a_empty: A is reading, so check if a_rd_ptr == b_wr_ptr (B's write pointer)
  //
  // For B side:
  //   b_full: B is writing, so check if b_wr_ptr == a_rd_ptr (A's read pointer)
  //   b_empty: B is reading, so check if b_rd_ptr == a_wr_ptr (A's write pointer)

  assign a_full_internal  = (a_wr_ptr == a_rd_ptr_bin_sync);
  assign b_full_internal  = (b_wr_ptr == b_rd_ptr_bin_sync);
  assign a_empty_internal = (a_rd_ptr == a_wr_ptr_bin_sync);
  assign b_empty_internal = (b_rd_ptr == b_wr_ptr_bin_sync);

  // Almost full/empty
  assign a_afull_internal  = (a_wr_ptr - a_rd_ptr_bin_sync) == AFULL_THRESH[AWIDTH:0];
  assign b_afull_internal  = (b_wr_ptr - b_rd_ptr_bin_sync) == AFULL_THRESH[AWIDTH:0];
  assign a_aempty_internal = (a_wr_ptr_bin_sync - a_rd_ptr) == AEMPTY_THRESH[AWIDTH:0];
  assign b_aempty_internal = (b_wr_ptr_bin_sync - b_rd_ptr) == AEMPTY_THRESH[AWIDTH:0];

  // Write/Read enables
  assign a_write_en = a_winc & a_dir & ~a_full_internal;
  assign b_write_en = b_winc & b_dir & ~b_full_internal;
  assign a_read_en  = a_rinc & ~a_dir & ~a_empty_internal;
  assign b_read_en  = b_rinc & ~b_dir & ~b_empty_internal;

  // Fall-through: if FALLTHROUGH is "TRUE", allow read when empty but write is happening
  // Actually, fall-through means the data can be read in the same cycle it's written
  // For simplicity, we'll implement it as: if fallthrough is enabled, the read data
  // is combinational from the write data when the FIFO is empty and a write is occurring
  assign fallthrough = (FALLTHROUGH == "TRUE");

  // Update write pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AWIDTH+1{1'b0}};
    else if (a_write_en)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AWIDTH+1{1'b0}};
    else if (b_write_en)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // Update read pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr <= {AWIDTH+1{1'b0}};
    else if (a_read_en)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr <= {AWIDTH+1{1'b0}};
    else if (b_read_en)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // Write to memory
  always @(posedge a_clk) begin
    if (a_write_en)
      mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
  end

  always @(posedge b_clk) begin
    if (b_write_en)
      mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
  end

  // Read from memory
  assign a_read_data = mem[a_rd_ptr[AWIDTH-1:0]];
  assign b_read_data = mem[b_rd_ptr[AWIDTH-1:0]];

  // Fall-through: if enabled and FIFO is empty and write is happening, pass through
  wire a_fallthrough_data = fallthrough & a_empty_internal & a_write_en;
  wire b_fallthrough_data = fallthrough & b_empty_internal & b_write_en;

  assign a_rdata = a_fallthrough_data ? a_wdata : a_read_data;
  assign b_rdata = b_fallthrough_data ? b_wdata : b_read_data;

  // Output signals
  assign a_full   = a_full_internal;
  assign a_afull  = a_afull_internal;
  assign a_empty  = a_empty_internal;
  assign a_aempty = a_aempty_internal;
  assign b_full   = b_full_internal;
  assign b_afull  = b_afull_internal;
  assign b_empty  = b_empty_internal;
  assign b_aempty = b_aempty_internal;

endmodule
