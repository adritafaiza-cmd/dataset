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
  localparam AWIDTH = ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  reg [AWIDTH:0] a_wr_ptr, a_rd_ptr, a_wr_ptr_gray, a_rd_ptr_gray;
  reg [AWIDTH:0] b_wr_ptr, b_rd_ptr, b_wr_ptr_gray, b_rd_ptr_gray;

  reg [AWIDTH:0] a_wr_ptr_gray_sync, a_rd_ptr_gray_sync;
  reg [AWIDTH:0] b_wr_ptr_gray_sync, b_rd_ptr_gray_sync;

  // Gray code conversion functions
  function [AWIDTH:0] bin_to_gray;
    input [AWIDTH:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  function [AWIDTH:0] gray_to_bin;
    input [AWIDTH:0] gray;
    integer i;
    reg [AWIDTH:0] bin;
    bin = gray;
    for (i = AWIDTH; i > 0; i = i - 1)
      bin[i-1] = bin[i] ^ bin[i-1];
    gray_to_bin = bin;
  endfunction

  // A-side write and read pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
    end else if (a_winc && !a_full) begin
      a_wr_ptr <= a_wr_ptr + 1;
      a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
    end else if (a_rinc && !a_empty) begin
      a_rd_ptr <= a_rd_ptr + 1;
      a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
    end
  end

  // B-side write and read pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
    end else if (b_winc && !b_full) begin
      b_wr_ptr <= b_wr_ptr + 1;
      b_wr_ptr_gray <= bin_to_gray(b_wr_ptr + 1);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
    end else if (b_rinc && !b_empty) begin
      b_rd_ptr <= b_rd_ptr + 1;
      b_rd_ptr_gray <= bin_to_gray(b_rd_ptr + 1);
    end
  end

  // Cross-domain synchronization of pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync <= 0;
      b_rd_ptr_gray_sync <= 0;
    end else begin
      b_wr_ptr_gray_sync <= b_wr_ptr_gray;
      b_rd_ptr_gray_sync <= b_rd_ptr_gray;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync <= 0;
      a_rd_ptr_gray_sync <= 0;
    end else begin
      a_wr_ptr_gray_sync <= a_wr_ptr_gray;
      a_rd_ptr_gray_sync <= a_rd_ptr_gray;
    end
  end

  // Calculate full and empty flags
  wire [AWIDTH:0] a_wr_ptr_sync, a_rd_ptr_sync;
  wire [AWIDTH:0] b_wr_ptr_sync, b_rd_ptr_sync;

  assign a_wr_ptr_sync = gray_to_bin(b_wr_ptr_gray_sync);
  assign a_rd_ptr_sync = gray_to_bin(a_rd_ptr_gray_sync);
  assign b_wr_ptr_sync = gray_to_bin(a_wr_ptr_gray_sync);
  assign b_rd_ptr_sync = gray_to_bin(b_rd_ptr_gray_sync);

  wire [AWIDTH:0] a_fill_level, b_fill_level;
  assign a_fill_level = a_wr_ptr_sync - a_rd_ptr;
  assign b_fill_level = b_wr_ptr_sync - b_rd_ptr;

  assign a_full = (a_fill_level >= DEPTH);
  assign a_afull = (a_fill_level >= DEPTH - 1);
  assign a_empty = (a_fill_level == 0);
  assign a_aempty = (a_fill_level == 1);

  assign b_full = (b_fill_level >= DEPTH);
  assign b_afull = (b_fill_level >= DEPTH - 1);
  assign b_empty = (b_fill_level == 0);
  assign b_aempty = (b_fill_level == 1);

  // Data write and read
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      mem <= '{default:0};
    end else if (a_winc && !a_full) begin
      mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      mem <= '{default:0};
    end else if (b_winc && !b_full) begin
      mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else if (a_rinc && !a_empty) begin
      a_rdata <= mem[a_rd_ptr[AWIDTH-1:0]];
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata <= 0;
    end else if (b_rinc && !b_empty) begin
      b_rdata <= mem[b_rd_ptr[AWIDTH-1:0]];
    end
  end

endmodule
