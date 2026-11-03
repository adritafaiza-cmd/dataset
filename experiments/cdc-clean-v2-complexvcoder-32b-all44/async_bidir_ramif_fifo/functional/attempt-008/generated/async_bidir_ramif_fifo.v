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
  reg [ASIZE:0] a_wr_ptr, a_rd_ptr, b_wr_ptr, b_rd_ptr;
  reg [ASIZE:0] a_wr_ptr_gray, a_rd_ptr_gray, b_wr_ptr_gray, b_rd_ptr_gray;
  reg [ASIZE:0] a_wr_ptr_gray_sync, a_rd_ptr_gray_sync, b_wr_ptr_gray_sync, b_rd_ptr_gray_sync;
  reg           a_full_flag, a_empty_flag, b_full_flag, b_empty_flag;
  reg [ASIZE-1:0] a_addr, b_addr;
  reg [ASIZE:0] a_next_wr_ptr, a_next_rd_ptr, b_next_wr_ptr, b_next_rd_ptr;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;

  // Gray code conversion
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray code to binary conversion
  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE-1; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

  // A side logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
      a_wr_ptr_gray_sync <= 0;
      a_rd_ptr_gray_sync <= 0;
      a_full_flag <= 0;
      a_empty_flag <= 1;
      a_addr <= 0;
      a_next_wr_ptr <= 0;
      a_next_rd_ptr <= 0;
    end else begin
      // Update pointers
      a_next_wr_ptr = a_wr_ptr + 1;
      a_next_rd_ptr = a_rd_ptr + 1;

      // Write operation
      if (a_winc && !a_full_flag) begin
        a_wr_ptr <= a_next_wr_ptr;
        a_wr_ptr_gray <= bin_to_gray(a_next_wr_ptr);
      end

      // Read operation
      if (a_rinc && !a_empty_flag) begin
        a_rd_ptr <= a_next_rd_ptr;
        a_rd_ptr_gray <= bin_to_gray(a_next_rd_ptr);
      end

      // Synchronize B side pointers
      a_wr_ptr_gray_sync <= b_wr_ptr_gray;
      a_rd_ptr_gray_sync <= b_rd_ptr_gray;

      // Calculate flags
      a_full_flag <= (a_wr_ptr_gray_sync == (a_rd_ptr_gray + 1));
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray_sync);

      // Address generation
      a_addr <= a_wr_ptr[ASIZE-1:0];

      // Outputs
      o_ram_a_clk <= a_clk;
      o_ram_a_wdata <= a_wdata;
      o_ram_a_addr <= a_addr;
      o_ram_a_winc <= a_winc && !a_full_flag;
      o_ram_a_rinc <= a_rinc && !a_empty_flag;

      if (a_rinc && !a_empty_flag) begin
        a_rdata_reg <= i_ram_a_rdata;
      end
    end
  end

  // B side logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
      b_wr_ptr_gray_sync <= 0;
      b_rd_ptr_gray_sync <= 0;
      b_full_flag <= 0;
      b_empty_flag <= 1;
      b_addr <= 0;
      b_next_wr_ptr <= 0;
      b_next_rd_ptr <= 0;
    end else begin
      // Update pointers
      b_next_wr_ptr = b_wr_ptr + 1;
      b_next_rd_ptr = b_rd_ptr + 1;

      // Write operation
      if (b_winc && !b_full_flag) begin
        b_wr_ptr <= b_next_wr_ptr;
        b_wr_ptr_gray <= bin_to_gray(b_next_wr_ptr);
      end

      // Read operation
      if (b_rinc && !b_empty_flag) begin
        b_rd_ptr <= b_next_rd_ptr;
        b_rd_ptr_gray <= bin_to_gray(b_next_rd_ptr);
      end

      // Synchronize A side pointers
      b_wr_ptr_gray_sync <= a_wr_ptr_gray;
      b_rd_ptr_gray_sync <= a_rd_ptr_gray;

      // Calculate flags
      b_full_flag <= (b_wr_ptr_gray_sync == (b_rd_ptr_gray + 1));
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray_sync);

      // Address generation
      b_addr <= b_wr_ptr[ASIZE-1:0];

      // Outputs
      o_ram_b_clk <= b_clk;
      o_ram_b_wdata <= b_wdata;
      o_ram_b_addr <= b_addr;
      o_ram_b_winc <= b_winc && !b_full_flag;
      o_ram_b_rinc <= b_rinc && !b_empty_flag;

      if (b_rinc && !b_empty_flag) begin
        b_rdata_reg <= i_ram_b_rdata;
      end
    end
  end

  // Outputs
  assign a_rdata = a_rdata_reg;
  assign a_full = a_full_flag;
  assign a_afull = a_full_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_empty_flag;

  assign b_rdata = b_rdata_reg;
  assign b_full = b_full_flag;
  assign b_afull = b_full_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_empty_flag;

endmodule
