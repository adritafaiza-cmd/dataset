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

  // Internal signals
  reg [ASIZE-1:0] a_wr_ptr, a_wr_ptr_gray, a_rd_ptr_gray, a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr, b_wr_ptr_gray, b_rd_ptr_gray, b_rd_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray_sync_b, b_wr_ptr_gray_sync_a;
  reg a_full_flag, a_empty_flag, a_afull_flag, a_aempty_flag;
  reg b_full_flag, b_empty_flag, b_afull_flag, b_aempty_flag;
  reg [DSIZE-1:0] a_ram_wdata, a_ram_rdata;
  reg [DSIZE-1:0] b_ram_wdata, b_ram_rdata;
  reg [ASIZE-1:0] a_ram_addr, b_ram_addr;
  reg a_ram_winc, a_ram_rinc;
  reg b_ram_winc, b_ram_rinc;

  // Gray code conversion
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Binary conversion from Gray code
  function [ASIZE-1:0] gray2bin;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE-2; i >= 0; i = i-1) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    gray2bin = bin;
  endfunction

  // Clock domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
    end else begin
      if (a_dir && !a_full_flag && a_winc) begin
        a_wr_ptr <= a_wr_ptr + 1;
      end
      if (!a_dir && !a_empty_flag && a_rinc) begin
        a_rd_ptr <= a_rd_ptr + 1;
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_gray <= 0;
    end else begin
      a_wr_ptr_gray <= bin2gray(a_wr_ptr);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync_b <= 0;
    end else begin
      a_wr_ptr_gray_sync_b <= bin2gray(a_wr_ptr_gray);
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr_gray <= 0;
    end else begin
      a_rd_ptr_gray <= bin2gray(a_rd_ptr);
    end
  end

  // Clock domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
    end else begin
      if (b_dir && !b_full_flag && b_winc) begin
        b_wr_ptr <= b_wr_ptr + 1;
      end
      if (!b_dir && !b_empty_flag && b_rinc) begin
        b_rd_ptr <= b_rd_ptr + 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_gray <= 0;
    end else begin
      b_wr_ptr_gray <= bin2gray(b_wr_ptr);
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync_a <= 0;
    end else begin
      b_wr_ptr_gray_sync_a <= bin2gray(b_wr_ptr_gray);
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_rd_ptr_gray <= 0;
    end else begin
      b_rd_ptr_gray <= bin2gray(b_rd_ptr);
    end
  end

  // FIFO flags
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_flag <= 0;
      a_empty_flag <= 1;
      a_afull_flag <= 0;
      a_aempty_flag <= 1;
    end else begin
      a_full_flag <= (a_wr_ptr_gray_sync_b == bin2gray(a_rd_ptr + (1 << (ASIZE - 1))));
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray);
      a_afull_flag <= (a_wr_ptr_gray_sync_b == bin2gray(a_rd_ptr + (1 << (ASIZE - 2))));
      a_aempty_flag <= (a_wr_ptr_gray == bin2gray(a_rd_ptr + (1 << (ASIZE - 2))));
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_flag <= 0;
      b_empty_flag <= 1;
      b_afull_flag <= 0;
      b_aempty_flag <= 1;
    end else begin
      b_full_flag <= (b_wr_ptr_gray_sync_a == bin2gray(b_rd_ptr + (1 << (ASIZE - 1))));
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray);
      b_afull_flag <= (b_wr_ptr_gray_sync_a == bin2gray(b_rd_ptr + (1 << (ASIZE - 2))));
      b_aempty_flag <= (b_wr_ptr_gray == bin2gray(b_rd_ptr + (1 << (ASIZE - 2))));
    end
  end

  // RAM interface
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ram_wdata <= 0;
      a_ram_addr <= 0;
      a_ram_winc <= 0;
      a_ram_rinc <= 0;
    end else begin
      if (a_dir && !a_full_flag && a_winc) begin
        a_ram_wdata <= a_wdata;
        a_ram_addr <= a_wr_ptr;
        a_ram_winc <= 1;
      end else begin
        a_ram_winc <= 0;
      end

      if (!a_dir && !a_empty_flag && a_rinc) begin
        a_ram_addr <= a_rd_ptr;
        a_ram_rinc <= 1;
      end else begin
        a_ram_rinc <= 0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ram_wdata <= 0;
      b_ram_addr <= 0;
      b_ram_winc <= 0;
      b_ram_rinc <= 0;
    end else begin
      if (b_dir && !b_full_flag && b_winc) begin
        b_ram_wdata <= b_wdata;
        b_ram_addr <= b_wr_ptr;
        b_ram_winc <= 1;
      end else begin
        b_ram_winc <= 0;
      end

      if (!b_dir && !b_empty_flag && b_rinc) begin
        b_ram_addr <= b_rd_ptr;
        b_ram_rinc <= 1;
      end else begin
        b_ram_rinc <= 0;
      end
    end
  end

  // Output assignments
  assign a_rdata = a_ram_rdata;
  assign b_rdata = b_ram_rdata;

  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;

  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_ram_wdata;
  assign i_ram_a_rdata = a_ram_rdata;
  assign o_ram_a_addr = a_ram_addr;
  assign o_ram_a_rinc = a_ram_rinc;
  assign o_ram_a_winc = a_ram_winc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_ram_wdata;
  assign i_ram_b_rdata = b_ram_rdata;
  assign o_ram_b_addr = b_ram_addr;
  assign o_ram_b_rinc = b_ram_rinc;
  assign o_ram_b_winc = b_ram_winc;

endmodule
