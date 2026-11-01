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
  localparam AFULL_THRESH = DEPTH - 1;
  localparam AEMPTY_THRESH = 1;

  // Side A: write pointer (local), read pointer (from B)
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_rd_ptr_gray;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync2;

  // Side B: write pointer (local), read pointer (from A)
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_rd_ptr_gray;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync2;

  // Gray code conversion
  function [AWIDTH-1:0] bin2gray;
    input [AWIDTH-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  // Side A: write enable
  wire a_we = a_winc & ~a_full;
  // Side A: read enable
  wire a_re = a_rinc & ~a_empty;

  // Side B: write enable
  wire b_we = b_winc & ~b_full;
  // Side B: read enable
  wire b_re = b_rinc & ~b_empty;

  // RAM interface
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc = a_we;
  assign o_ram_a_rinc = a_re;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc = b_we;
  assign o_ram_b_rinc = b_re;

  // Read data
  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

  // Side A: write pointer update
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {AWIDTH{1'b0}};
    else if (a_we)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  // Side A: read pointer update (from B's write pointer)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr <= {AWIDTH{1'b0}};
    else if (a_re)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  // Side A: gray code of read pointer for B
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rd_ptr_gray <= {AWIDTH{1'b0}};
    else
      a_rd_ptr_gray <= bin2gray(a_rd_ptr);
  end

  // Side A: sync B's write pointer gray code
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  // Side B: write pointer update
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {AWIDTH{1'b0}};
    else if (b_we)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // Side B: read pointer update (from A's write pointer)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr <= {AWIDTH{1'b0}};
    else if (b_re)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // Side B: gray code of read pointer for A
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rd_ptr_gray <= {AWIDTH{1'b0}};
    else
      b_rd_ptr_gray <= bin2gray(b_rd_ptr);
  end

  // Side B: sync A's write pointer gray code
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Convert gray to binary for comparison
  function [AWIDTH-1:0] gray2bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  wire [AWIDTH-1:0] a_wr_ptr_gray = bin2gray(a_wr_ptr);
  wire [AWIDTH-1:0] b_wr_ptr_gray = bin2gray(b_wr_ptr);

  // Side A: full/empty flags
  wire [AWIDTH-1:0] a_wr_ptr_gray_sync1;
  wire [AWIDTH-1:0] a_wr_ptr_gray_sync2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
    end
  end

  wire [AWIDTH-1:0] a_wr_ptr_bin_sync = gray2bin(a_wr_ptr_gray_sync2);
  wire [AWIDTH-1:0] a_rd_ptr_bin_sync = gray2bin(a_rd_ptr_gray_sync2);

  wire a_full = (a_wr_ptr_bin_sync == a_rd_ptr_bin_sync) && (a_wr_ptr[AWIDTH-1] != a_rd_ptr[AWIDTH-1]);
  wire a_empty = (a_wr_ptr_bin_sync == a_rd_ptr_bin_sync) && (a_wr_ptr[AWIDTH-1] == a_rd_ptr[AWIDTH-1]);

  // Side B: full/empty flags
  wire [AWIDTH-1:0] b_wr_ptr_gray_sync1;
  wire [AWIDTH-1:0] b_wr_ptr_gray_sync2;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
    end
  end

  wire [AWIDTH-1:0] b_wr_ptr_bin_sync = gray2bin(b_wr_ptr_gray_sync2);
  wire [AWIDTH-1:0] b_rd_ptr_bin_sync = gray2bin(b_rd_ptr_gray_sync2);

  wire b_full = (b_wr_ptr_bin_sync == b_rd_ptr_bin_sync) && (b_wr_ptr[AWIDTH-1] != b_rd_ptr[AWIDTH-1]);
  wire b_empty = (b_wr_ptr_bin_sync == b_rd_ptr_bin_sync) && (b_wr_ptr[AWIDTH-1] == b_rd_ptr[AWIDTH-1]);

  // Almost full/empty
  wire [AWIDTH-1:0] a_diff = a_wr_ptr_bin_sync - a_rd_ptr_bin_sync;
  wire [AWIDTH-1:0] b_diff = b_wr_ptr_bin_sync - b_rd_ptr_bin_sync;

  assign a_afull = (a_diff >= AFULL_THRESH[AWIDTH-1:0]);
  assign a_aempty = (a_diff <= AEMPTY_THRESH[AWIDTH-1:0]);
  assign b_afull = (b_diff >= AFULL_THRESH[AWIDTH-1:0]);
  assign b_aempty = (b_diff <= AEMPTY_THRESH[AWIDTH-1:0]);

endmodule
