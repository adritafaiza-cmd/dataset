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
  reg [ASIZE-1:0] a_wr_ptr, a_wr_ptr_gray, a_rd_ptr, a_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_gray_synced, a_rd_ptr_gray_synced;
  reg             a_full_flag, a_afull_flag, a_empty_flag, a_aempty_flag;

  reg [ASIZE-1:0] b_wr_ptr, b_wr_ptr_gray, b_rd_ptr, b_rd_ptr_gray;
  reg [ASIZE-1:0] b_wr_ptr_gray_synced, b_rd_ptr_gray_synced;
  reg             b_full_flag, b_afull_flag, b_empty_flag, b_aempty_flag;

  reg [ASIZE-1:0] a_ram_addr, b_ram_addr;

  // Gray code conversion
  function [ASIZE-1:0] bin_to_gray;
    input [ASIZE-1:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray code to binary conversion
  function [ASIZE-1:0] gray_to_bin;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE - 2; i >= 0; i = i - 1)
      bin[i] = bin[i + 1] ^ gray[i];
    gray_to_bin = bin;
  endfunction

  // A-side logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
      a_wr_ptr_gray_synced <= 0;
      a_rd_ptr_gray_synced <= 0;
    end else begin
      // Write pointer
      if (a_winc && !a_full_flag) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
      end

      // Read pointer
      if (a_rinc && !a_empty_flag) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
      end

      // Synchronize write pointer to b_clk domain
      a_wr_ptr_gray_synced <= b_wr_ptr_gray_synced;

      // Synchronize read pointer to b_clk domain
      a_rd_ptr_gray_synced <= b_rd_ptr_gray_synced;
    end
  end

  // B-side logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
      b_wr_ptr_gray_synced <= 0;
      b_rd_ptr_gray_synced <= 0;
    end else begin
      // Write pointer
      if (b_winc && !b_full_flag) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= bin_to_gray(b_wr_ptr + 1);
      end

      // Read pointer
      if (b_rinc && !b_empty_flag) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= bin_to_gray(b_rd_ptr + 1);
      end

      // Synchronize write pointer to a_clk domain
      b_wr_ptr_gray_synced <= a_wr_ptr_gray_synced;

      // Synchronize read pointer to a_clk domain
      b_rd_ptr_gray_synced <= a_rd_ptr_gray_synced;
    end
  end

  // A-side flags
  always @(*) begin
    a_full_flag = (a_wr_ptr_gray == (a_rd_ptr_gray_synced ^ (1 << ASIZE)));
    a_afull_flag = (a_wr_ptr_gray == (a_rd_ptr_gray_synced ^ (1 << (ASIZE - 1))));
    a_empty_flag = (a_wr_ptr_gray_synced == a_rd_ptr_gray);
    a_aempty_flag = (a_wr_ptr_gray_synced == (a_rd_ptr_gray ^ (1 << (ASIZE - 1))));
  end

  // B-side flags
  always @(*) begin
    b_full_flag = (b_wr_ptr_gray == (b_rd_ptr_gray_synced ^ (1 << ASIZE)));
    b_afull_flag = (b_wr_ptr_gray == (b_rd_ptr_gray_synced ^ (1 << (ASIZE - 1))));
    b_empty_flag = (b_wr_ptr_gray_synced == b_rd_ptr_gray);
    b_aempty_flag = (b_wr_ptr_gray_synced == (b_rd_ptr_gray ^ (1 << (ASIZE - 1))));
  end

  // A-side RAM interface
  always @(*) begin
    o_ram_a_clk = a_clk;
    o_ram_a_wdata = a_wdata;
    o_ram_a_addr = a_wr_ptr;
    o_ram_a_rinc = a_rinc && !a_empty_flag;
    o_ram_a_winc = a_winc && !a_full_flag;
    a_rdata = i_ram_a_rdata;
  end

  // B-side RAM interface
  always @(*) begin
    o_ram_b_clk = b_clk;
    o_ram_b_wdata = b_wdata;
    o_ram_b_addr = b_wr_ptr;
    o_ram_b_rinc = b_rinc && !b_empty_flag;
    o_ram_b_winc = b_winc && !b_full_flag;
    b_rdata = i_ram_b_rdata;
  end

  // Outputs
  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;

  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

endmodule
