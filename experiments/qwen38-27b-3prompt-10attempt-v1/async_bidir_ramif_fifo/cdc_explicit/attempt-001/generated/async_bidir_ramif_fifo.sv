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
  localparam PTR_WIDTH = ASIZE + 1;
  localparam AFULL_MARGIN = 2;
  localparam AEMPTY_MARGIN = 1;

  // Internal signals for side A
  wire [PTR_WIDTH-1:0] a_wr_ptr;
  wire [PTR_WIDTH-1:0] a_rd_ptr;
  wire [PTR_WIDTH-1:0] a_wr_ptr_gray;
  wire [PTR_WIDTH-1:0] a_rd_ptr_gray;
  wire [PTR_WIDTH-1:0] a_wr_ptr_gray_sync;
  wire [PTR_WIDTH-1:0] a_rd_ptr_gray_sync;
  wire [PTR_WIDTH-1:0] a_wr_ptr_bin_sync;
  wire [PTR_WIDTH-1:0] a_rd_ptr_bin_sync;
  wire a_wr_en;
  wire a_rd_en;
  wire a_full_int;
  wire a_empty_int;
  wire a_afull_int;
  wire a_aempty_int;

  // Internal signals for side B
  wire [PTR_WIDTH-1:0] b_wr_ptr;
  wire [PTR_WIDTH-1:0] b_rd_ptr;
  wire [PTR_WIDTH-1:0] b_wr_ptr_gray;
  wire [PTR_WIDTH-1:0] b_rd_ptr_gray;
  wire [PTR_WIDTH-1:0] b_wr_ptr_gray_sync;
  wire [PTR_WIDTH-1:0] b_rd_ptr_gray_sync;
  wire [PTR_WIDTH-1:0] b_wr_ptr_bin_sync;
  wire [PTR_WIDTH-1:0] b_rd_ptr_bin_sync;
  wire b_wr_en;
  wire b_rd_en;
  wire b_full_int;
  wire b_empty_int;
  wire b_afull_int;
  wire b_aempty_int;

  // Gray code conversion functions
  function [PTR_WIDTH-1:0] bin2gray;
    input [PTR_WIDTH-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [PTR_WIDTH-1:0] gray2bin;
    input [PTR_WIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
      for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
  endfunction

  // Side A: Write pointer (binary)
  reg [PTR_WIDTH-1:0] a_wr_ptr_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr_reg <= {PTR_WIDTH{1'b0}};
    else if (a_wr_en)
      a_wr_ptr_reg <= a_wr_ptr_reg + 1'b1;
  end
  assign a_wr_ptr = a_wr_ptr_reg;
  assign a_wr_ptr_gray = bin2gray(a_wr_ptr);

  // Side A: Read pointer (binary)
  reg [PTR_WIDTH-1:0] a_rd_ptr_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr_reg <= {PTR_WIDTH{1'b0}};
    else if (a_rd_en)
      a_rd_ptr_reg <= a_rd_ptr_reg + 1'b1;
  end
  assign a_rd_ptr = a_rd_ptr_reg;
  assign a_rd_ptr_gray = bin2gray(a_rd_ptr);

  // Side B: Write pointer (binary)
  reg [PTR_WIDTH-1:0] b_wr_ptr_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr_reg <= {PTR_WIDTH{1'b0}};
    else if (b_wr_en)
      b_wr_ptr_reg <= b_wr_ptr_reg + 1'b1;
  end
  assign b_wr_ptr = b_wr_ptr_reg;
  assign b_wr_ptr_gray = bin2gray(b_wr_ptr);

  // Side B: Read pointer (binary)
  reg [PTR_WIDTH-1:0] b_rd_ptr_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr_reg <= {PTR_WIDTH{1'b0}};
    else if (b_rd_en)
      b_rd_ptr_reg <= b_rd_ptr_reg + 1'b1;
  end
  assign b_rd_ptr = b_rd_ptr_reg;
  assign b_rd_ptr_gray = bin2gray(b_rd_ptr);

  // CDC: Synchronize A's write pointer gray to B domain
  reg [PTR_WIDTH-1:0] a_wr_ptr_gray_sync_r1;
  reg [PTR_WIDTH-1:0] a_wr_ptr_gray_sync_r2;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync_r1 <= {PTR_WIDTH{1'b0}};
      a_wr_ptr_gray_sync_r2 <= {PTR_WIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync_r1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync_r2 <= a_wr_ptr_gray_sync_r1;
    end
  end
  assign a_wr_ptr_gray_sync = a_wr_ptr_gray_sync_r2;
  assign a_wr_ptr_bin_sync = gray2bin(a_wr_ptr_gray_sync);

  // CDC: Synchronize A's read pointer gray to B domain
  reg [PTR_WIDTH-1:0] a_rd_ptr_gray_sync_r1;
  reg [PTR_WIDTH-1:0] a_rd_ptr_gray_sync_r2;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_rd_ptr_gray_sync_r1 <= {PTR_WIDTH{1'b0}};
      a_rd_ptr_gray_sync_r2 <= {PTR_WIDTH{1'b0}};
    end else begin
      a_rd_ptr_gray_sync_r1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync_r2 <= a_rd_ptr_gray_sync_r1;
    end
  end
  assign a_rd_ptr_gray_sync = a_rd_ptr_gray_sync_r2;
  assign a_rd_ptr_bin_sync = gray2bin(a_rd_ptr_gray_sync);

  // CDC: Synchronize B's write pointer gray to A domain
  reg [PTR_WIDTH-1:0] b_wr_ptr_gray_sync_r1;
  reg [PTR_WIDTH-1:0] b_wr_ptr_gray_sync_r2;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync_r1 <= {PTR_WIDTH{1'b0}};
      b_wr_ptr_gray_sync_r2 <= {PTR_WIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync_r1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync_r2 <= b_wr_ptr_gray_sync_r1;
    end
  end
  assign b_wr_ptr_gray_sync = b_wr_ptr_gray_sync_r2;
  assign b_wr_ptr_bin_sync = gray2bin(b_wr_ptr_gray_sync);

  // CDC: Synchronize B's read pointer gray to A domain
  reg [PTR_WIDTH-1:0] b_rd_ptr_gray_sync_r1;
  reg [PTR_WIDTH-1:0] b_rd_ptr_gray_sync_r2;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_gray_sync_r1 <= {PTR_WIDTH{1'b0}};
      b_rd_ptr_gray_sync_r2 <= {PTR_WIDTH{1'b0}};
    end else begin
      b_rd_ptr_gray_sync_r1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync_r2 <= b_rd_ptr_gray_sync_r1;
    end
  end
  assign b_rd_ptr_gray_sync = b_rd_ptr_gray_sync_r2;
  assign b_rd_ptr_bin_sync = gray2bin(b_rd_ptr_gray_sync);

  // Side A: Full/Empty logic
  // A is full when A's write pointer has caught up to B's read pointer (in A's view)
  // A is empty when A's read pointer equals A's write pointer
  assign a_full_int = (a_wr_ptr == b_rd_ptr_bin_sync);
  assign a_empty_int = (a_rd_ptr == a_wr_ptr);
  assign a_afull_int = (a_wr_ptr - b_rd_ptr_bin_sync) >= (DEPTH - AFULL_MARGIN);
  assign a_aempty_int = (a_wr_ptr - a_rd_ptr) <= AEMPTY_MARGIN;

  // Side B: Full/Empty logic
  // B is full when B's write pointer has caught up to A's read pointer (in B's view)
  // B is empty when B's read pointer equals B's write pointer
  assign b_full_int = (b_wr_ptr == a_rd_ptr_bin_sync);
  assign b_empty_int = (b_rd_ptr == b_wr_ptr);
  assign b_afull_int = (b_wr_ptr - a_rd_ptr_bin_sync) >= (DEPTH - AFULL_MARGIN);
  assign b_aempty_int = (b_wr_ptr - b_rd_ptr) <= AEMPTY_MARGIN;

  // Direction-based enable logic
  // a_dir: 1 means A is writing, 0 means A is reading
  // b_dir: 1 means B is writing, 0 means B is reading
  assign a_wr_en = a_winc & a_dir & ~a_full_int;
  assign a_rd_en = a_rinc & ~a_dir & ~a_empty_int;
  assign b_wr_en = b_winc & b_dir & ~b_full_int;
  assign b_rd_en = b_rinc & ~b_dir & ~b_empty_int;

  // RAM interface
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc = a_wr_en;
  assign o_ram_a_rinc = a_rd_en;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc = b_wr_en;
  assign o_ram_b_rinc = b_rd_en;

  // Read data output
  // For fall-through, we need to handle the case where data is available immediately
  // For simplicity, we use the RAM read data directly
  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

  // Status flags
  assign a_full = a_full_int;
  assign a_afull = a_afull_int;
  assign a_empty = a_empty_int;
  assign a_aempty = a_aempty_int;

  assign b_full = b_full_int;
  assign b_afull = b_afull_int;
  assign b_empty = b_empty_int;
  assign b_aempty = b_aempty_int;

endmodule
