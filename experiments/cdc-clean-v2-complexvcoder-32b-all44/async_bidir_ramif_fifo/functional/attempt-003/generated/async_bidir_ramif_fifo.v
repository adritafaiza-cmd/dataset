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
  reg [ASIZE-1:0] b_wr_ptr, b_wr_ptr_gray, b_rd_ptr, b_rd_ptr_gray;
  reg [ASIZE-1:0] a_gray_wr_ptr, a_gray_rd_ptr, b_gray_wr_ptr, b_gray_rd_ptr;
  reg [ASIZE-1:0] a_gray_rd_ptr_sync, b_gray_rd_ptr_sync;
  reg a_full_flag, a_afull_flag, a_empty_flag, a_aempty_flag;
  reg b_full_flag, b_afull_flag, b_empty_flag, b_aempty_flag;
  reg [DSIZE-1:0] a_ram_wdata, b_ram_wdata;
  reg a_ram_winc, b_ram_winc, a_ram_rinc, b_ram_rinc;
  reg [ASIZE-1:0] a_ram_addr, b_ram_addr;

  // Gray code conversion functions
  function [ASIZE-1:0] binary_to_gray;
    input [ASIZE-1:0] bin;
    binary_to_gray = bin ^ (bin >> 1);
  endfunction

  function [ASIZE-1:0] gray_to_binary;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE-2; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    gray_to_binary = bin;
  endfunction

  // A-domain logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
      a_full_flag <= 0;
      a_afull_flag <= 0;
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else begin
      // Write pointer update
      if (a_winc && !a_full_flag) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= binary_to_gray(a_wr_ptr + 1);
      end

      // Read pointer update
      if (a_rinc && !a_empty_flag) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= binary_to_gray(a_rd_ptr + 1);
      end

      // Full flag
      a_full_flag <= (a_wr_ptr_gray == a_gray_rd_ptr_sync + 1);
      a_afull_flag <= (a_wr_ptr_gray == a_gray_rd_ptr_sync + 2);

      // Empty flag
      a_empty_flag <= (a_gray_wr_ptr == a_rd_ptr_gray);
      a_aempty_flag <= (a_gray_wr_ptr == a_rd_ptr_gray + 1);
    end
  end

  // B-domain logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
      b_full_flag <= 0;
      b_afull_flag <= 0;
      b_empty_flag <= 1;
      b_aempty_flag <= 1;
    end else begin
      // Write pointer update
      if (b_winc && !b_full_flag) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= binary_to_gray(b_wr_ptr + 1);
      end

      // Read pointer update
      if (b_rinc && !b_empty_flag) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= binary_to_gray(b_rd_ptr + 1);
      end

      // Full flag
      b_full_flag <= (b_wr_ptr_gray == b_gray_rd_ptr_sync + 1);
      b_afull_flag <= (b_wr_ptr_gray == b_gray_rd_ptr_sync + 2);

      // Empty flag
      b_empty_flag <= (b_gray_wr_ptr == b_rd_ptr_gray);
      b_aempty_flag <= (b_gray_wr_ptr == b_rd_ptr_gray + 1);
    end
  end

  // Gray code synchronization from A to B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      a_gray_rd_ptr_sync <= 0;
    else
      a_gray_rd_ptr_sync <= a_gray_rd_ptr;
  end

  // Gray code synchronization from B to A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      b_gray_rd_ptr_sync <= 0;
    else
      b_gray_rd_ptr_sync <= b_gray_rd_ptr;
  end

  // A-domain RAM control
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ram_wdata <= 0;
      a_ram_winc <= 0;
      a_ram_rinc <= 0;
    end else begin
      a_ram_wdata <= a_wdata;
      a_ram_winc <= a_winc && !a_full_flag;
      a_ram_rinc <= a_rinc && !a_empty_flag;
    end
  end

  // B-domain RAM control
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ram_wdata <= 0;
      b_ram_winc <= 0;
      b_ram_rinc <= 0;
    end else begin
      b_ram_wdata <= b_wdata;
      b_ram_winc <= b_winc && !b_full_flag;
      b_ram_rinc <= b_rinc && !b_empty_flag;
    end
  end

  // Address generation
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_ram_addr <= 0;
    else if (a_winc && !a_full_flag)
      a_ram_addr <= a_wr_ptr;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_ram_addr <= 0;
    else if (b_winc && !b_full_flag)
      b_ram_addr <= b_wr_ptr;
  end

  // Data output
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata <= 0;
    else if (a_rinc && !a_empty_flag)
      a_rdata <= i_ram_a_rdata;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata <= 0;
    else if (b_rinc && !b_empty_flag)
      b_rdata <= i_ram_b_rdata;
  end

  // Gray code pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_gray_wr_ptr <= 0;
      a_gray_rd_ptr <= 0;
    end else begin
      a_gray_wr_ptr <= binary_to_gray(a_wr_ptr);
      a_gray_rd_ptr <= binary_to_gray(a_rd_ptr);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_gray_wr_ptr <= 0;
      b_gray_rd_ptr <= 0;
    end else begin
      b_gray_wr_ptr <= binary_to_gray(b_wr_ptr);
      b_gray_rd_ptr <= binary_to_gray(b_rd_ptr);
    end
  end

  // Outputs
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_ram_wdata;
  assign o_ram_a_addr = a_ram_addr;
  assign o_ram_a_rinc = a_ram_rinc;
  assign o_ram_a_winc = a_ram_winc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_ram_wdata;
  assign o_ram_b_addr = b_ram_addr;
  assign o_ram_b_rinc = b_ram_rinc;
  assign o_ram_b_winc = b_ram_winc;

  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;

  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

endmodule
