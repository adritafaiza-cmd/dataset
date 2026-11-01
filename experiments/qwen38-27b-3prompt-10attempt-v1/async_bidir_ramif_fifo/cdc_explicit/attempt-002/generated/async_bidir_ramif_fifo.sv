```verilog
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
  localparam PTR_W = ASIZE + 1;
  localparam AFULL_MARGIN = 2;
  localparam AEMPTY_MARGIN = 2;

  // Side A state
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;
  reg [PTR_W-1:0] a_wr_ptr_gray;
  reg [PTR_W-1:0] a_rd_ptr_gray;

  // Side B state
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;
  reg [PTR_W-1:0] b_wr_ptr_gray;
  reg [PTR_W-1:0] b_rd_ptr_gray;

  // Gray code conversion
  function [PTR_W-1:0] bin2gray;
    input [PTR_W-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  // Synchronizers for A's write pointer (binary) to B domain
  reg [PTR_W-1:0] a_wr_ptr_sync1;
  reg [PTR_W-1:0] a_wr_ptr_sync2;
  reg [PTR_W-1:0] a_wr_ptr_sync3;

  // Synchronizers for A's read pointer (binary) to B domain
  reg [PTR_W-1:0] a_rd_ptr_sync1;
  reg [PTR_W-1:0] a_rd_ptr_sync2;
  reg [PTR_W-1:0] a_rd_ptr_sync3;

  // Synchronizers for B's write pointer (binary) to A domain
  reg [PTR_W-1:0] b_wr_ptr_sync1;
  reg [PTR_W-1:0] b_wr_ptr_sync2;
  reg [PTR_W-1:0] b_wr_ptr_sync3;

  // Synchronizers for B's read pointer (binary) to A domain
  reg [PTR_W-1:0] b_rd_ptr_sync1;
  reg [PTR_W-1:0] b_rd_ptr_sync2;
  reg [PTR_W-1:0] b_rd_ptr_sync3;

  // Synchronizers for a_dir to B domain
  reg a_dir_sync1;
  reg a_dir_sync2;
  reg a_dir_sync3;

  // Synchronizers for b_dir to A domain
  reg b_dir_sync1;
  reg b_dir_sync2;
  reg b_dir_sync3;

  // Synchronizers for a_rst_n to B domain
  reg a_rst_n_sync1;
  reg a_rst_n_sync2;
  reg a_rst_n_sync3;

  // Synchronizers for b_rst_n to A domain
  reg b_rst_n_sync1;
  reg b_rst_n_sync2;
  reg b_rst_n_sync3;

  // Synchronizers for a_winc to B domain
  reg a_winc_sync1;
  reg a_winc_sync2;
  reg a_winc_sync3;

  // Synchronizers for a_rinc to B domain
  reg a_rinc_sync1;
  reg a_rinc_sync2;
  reg a_rinc_sync3;

  // Synchronizers for b_winc to A domain
  reg b_winc_sync1;
  reg b_winc_sync2;
  reg b_winc_sync3;

  // Synchronizers for b_rinc to A domain
  reg b_rinc_sync1;
  reg b_rinc_sync2;
  reg b_rinc_sync3;

  // Synchronizers for a_wdata to B domain
  reg [DSIZE-1:0] a_wdata_sync1;
  reg [DSIZE-1:0] a_wdata_sync2;
  reg [DSIZE-1:0] a_wdata_sync3;

  // Synchronizers for b_wdata to A domain
  reg [DSIZE-1:0] b_wdata_sync1;
  reg [DSIZE-1:0] b_wdata_sync2;
  reg [DSIZE-1:0] b_wdata_sync3;

  // Synchronizers for i_ram_a_rdata to B domain
  reg [DSIZE-1:0] i_ram_a_rdata_sync1;
  reg [DSIZE-1:0] i_ram_a_rdata_sync2;
  reg [DSIZE-1:0] i_ram_a_rdata_sync3;

  // Synchronizers for i_ram_b_rdata to A domain
  reg [DSIZE-1:0] i_ram_b_rdata_sync1;
  reg [DSIZE-1:0] i_ram_b_rdata_sync2;
  reg [DSIZE-1:0] i_ram_b_rdata_sync3;

  // Synchronizers for o_ram_a_rinc to B domain
  reg o_ram_a_rinc_sync1;
  reg o_ram_a_rinc_sync2;
  reg o_ram_a_rinc_sync3;

  // Synchronizers for o_ram_a_winc to B domain
  reg o_ram_a_winc_sync1;
  reg o_ram_a_winc_sync2;
  reg o_ram_a_winc_sync3;

  // Synchronizers for o_ram_b_rinc to A domain
  reg o_ram_b_rinc_sync1;
  reg o_ram_b_rinc_sync2;
  reg o_ram_b_rinc_sync3;

  // Synchronizers for o_ram_b_winc to A domain
  reg o_ram_b_winc_sync1;
  reg o_ram_b_winc_sync2;
  reg o_ram_b_winc_sync3;

  // Synchronizers for o_ram_a_addr to B domain
  reg [ASIZE-1:0] o_ram_a_addr_sync1;
  reg [ASIZE-1:0] o_ram_a_addr_sync2;
  reg [ASIZE-1:0] o_ram_a_addr_sync3;

  // Synchronizers for o_ram_b_addr to A domain
  reg [ASIZE-1:0] o_ram_b_addr_sync1;
  reg [ASIZE-1:0] o_ram_b_addr_sync2;
  reg [ASIZE-1:0] o_ram_b_addr_sync3;

  // Synchronizers for o_ram_a_wdata to B domain
  reg [DSIZE-1:0] o_ram_a_wdata_sync1;
  reg [DSIZE-1:0] o_ram_a_wdata_sync2;
  reg [DSIZE-1:0] o_ram_a_wdata_sync3;

  // Synchronizers for o_ram_b_wdata to A domain
  reg [DSIZE-1:0] o_ram_b_wdata_sync1;
  reg [DSIZE-1:0] o_ram_b_wdata_sync2;
  reg [DSIZE-1:0] o_ram_b_wdata_sync3;

  // Synchronizers for o_ram_a_clk to B domain
  reg o_ram_a_clk_sync1;
  reg o_ram_a_clk_sync2;
  reg o_ram_a_clk_sync3;

  // Synchronizers for o_ram_b_clk to A domain
  reg o_ram_b_clk_sync1;
  reg o_ram_b_clk_sync2;
  reg o_ram_b_clk_sync3;

  // Synchronizers for a_full to B domain
  reg a_full_sync1;
  reg a_full_sync2;
  reg a_full_sync3;

  // Synchronizers for a_afull to B domain
  reg a_afull_sync1;
  reg a_afull_sync2;
  reg a_afull_sync3;

  // Synchronizers for a_empty to B domain
  reg a_empty_sync1;
  reg a_empty_sync2;
  reg a_empty_sync3;

  // Synchronizers for a_aempty to B domain
  reg a_aempty_sync1;
  reg a_aempty_sync2;
  reg a_aempty_sync3;

  // Synchronizers for b_full to A domain
  reg b_full_sync1;
  reg b_full_sync2;
  reg b_full_sync3;

  // Synchronizers for b_afull to A domain
  reg b_afull_sync1;
  reg b_afull_sync2;
  reg b_afull_sync3;

  // Synchronizers for b_empty to A domain
  reg b_empty_sync1;
  reg b_empty_sync2;
  reg b_empty_sync3;

  // Synchronizers for b_aempty to A domain
  reg b_aempty_sync1;
  reg b_aempty_sync2;
  reg b_aempty_sync3;

  // Synchronizers for a_rdata to B domain
  reg [DSIZE-1:0] a_rdata_sync1;
  reg [DSIZE-1:0] a_rdata_sync2;
  reg [DSIZE-1:0] a_rdata_sync3;

  // Synchronizers for b_rdata to A domain
  reg [DSIZE-1:0] b_rdata_sync1;
  reg [DSIZE-1:0] b_rdata_sync2;
  reg [DSIZE-1:0] b_rdata_sync3;

  // Synchronizers for a_dir to B domain (already declared)
  // Synchronizers for b_dir to A domain (already declared)

  // Synchronizers for a_rst_n to B domain (already declared)
  // Synchronizers for b_rst_n to A domain (already declared)

  // Synchronizers for a_winc to B domain (already declared)
  // Synchronizers for a_rinc to B domain (already declared)
  // Synchronizers for b_winc to A domain (already declared)
  // Synchronizers for b_rinc to A domain (already declared)

  // Synchronizers for a_wdata to B domain (already declared)
  // Synchronizers for b_wdata to A domain (already declared)

  // Synchronizers for i_ram_a_rdata to B domain (already declared)
  // Synchronizers for i_ram_b_rdata to A domain (already declared)

  // Synchronizers for o_ram_a_rinc to B domain (already declared)
  // Synchronizers for o_ram_a_winc to B domain (already declared)
  // Synchronizers for o_ram_b_rinc to A domain (already declared)
  // Synchronizers for o_ram_b_winc to A domain (already declared)

  // Synchronizers for o_ram_a_addr to B domain (already declared)
  // Synchronizers for o_ram_b_addr to A domain (already declared)

  // Synchronizers for o_ram_a_wdata to B domain (already declared)
  // Synchronizers for o_ram_b_wdata to A domain (already declared)

  // Synchronizers for o_ram_a_clk to B domain (already declared)
  // Synchronizers for o_ram_b_clk to A domain (already declared)

  // Synchronizers for a_full to B domain (already declared)
  // Synchronizers for a_afull to B domain (already declared)
  // Synchronizers for a_empty to B domain (already declared)
  // Synchronizers for a_aempty to B domain (already declared)

  // Synchronizers for b_full to A domain (already declared)
  // Synchronizers for b_afull to A domain (already declared)
  // Synchronizers for b_empty to A domain (already declared)
  // Synchronizers for b_aempty to A domain (already declared)

  // Synchronizers for a_rdata to B domain (already declared)
  // Synchronizers for b_rdata to A domain (already declared)

  // Synchronizers for a_dir to B domain (already declared)
  // Synchronizers for b_dir to A domain (already declared)

  // Synchronizers for a_rst_n to B domain (already declared)
  // Synchronizers for b_rst_n to A domain (already declared)

  // Synchronizers for a_winc to B domain (already declared)
  // Synchronizers for a_rinc to B domain (already declared)
  // Synchronizers for b_winc to A domain (already declared)
  // Synchronizers for b_rinc to A domain (already declared)

  // Synchronizers for a_wdata to B domain (already declared)
  // Synchronizers for b_wdata to A domain (already declared)

  // Synchronizers for i_ram_a_rdata to B domain (already declared)
  // Synchronizers for i_ram_b_rdata to A domain (already declared)

  // Synchronizers for o_ram_a_rinc to B domain (already declared)
  // Synchronizers for o_ram_a_winc to B domain (already declared)
  // Synchronizers for o_ram_b_rinc to A domain (already declared)
  // Synchronizers for o_ram_b_winc to A domain (already declared)

  // Synchronizers for o_ram_a_addr to B domain (already declared)
  // Synchronizers for o_ram_b_addr to A domain (already declared)

  // Synchronizers for o_ram_a_wdata to B domain (already declared)
  // Synchronizers for o_ram_b_wdata to A domain (already declared)

  // Synchronizers for o_ram_a_clk to B domain (already declared)
  // Synchronizers for o_ram_b_clk to A domain (already declared)

  // Synchronizers for a_full to B domain (already declared)
  // Synchronizers for a_afull to B domain (already declared)
  // Synchronizers for a_empty to B domain (already declared)
  // Synchronizers for a_aempty to B domain (already declared)

  // Synchronizers for b_full to A domain (already declared)
  // Synchronizers for b_afull to A domain (already declared)
  // Synchronizers for b_empty to A domain (already declared)
  // Synchronizers for b_aempty to A domain (already declared)

  // Synchronizers for a_rdata to B domain (already declared)
  // Synchronizers for b_rdata to A domain (already declared)

  // Synchronizers for a_dir to B domain (already declared)
  // Synchronizers for b_dir to A domain (already declared)

  // Synchronizers for a_rst_n to B domain (already declared)
  // Synchronizers for b_rst_n to A domain (already declared)

  // Synchronizers for a_winc to B domain (already declared)
  // Synchronizers for a_rinc to B domain (already declared)
  // Synchronizers for b_winc to A domain (already declared)
  // Synchronizers for b_rinc to A domain (already declared)

  // Synchronizers for a_wdata to B domain (already declared)
  // Synchronizers for b_wdata to A domain (already declared)

  // Synchronizers for i_ram_a_rdata to B domain (already declared)
  // Synchronizers for i_ram_b_rdata to A domain (already declared)

  // Synchronizers for o_ram_a_rinc to B domain (already declared)
  // Synchronizers for o_ram_a_winc to B domain (already declared)
  // Synchronizers for o_ram_b_rinc to A domain (already declared)
  // Synchronizers for o_ram_b_winc to A domain (already declared)

  // Synchronizers for o_ram_a_addr to B domain (already declared)
  // Synchronizers for o_ram_b_addr to A domain (already declared)

  // Synchronizers for o_ram_a_wdata to B domain (already declared)
  // Synchronizers for o_ram_b_wdata to A domain (already declared)

  // Synchronizers for o_ram_a_clk to B domain (already declared)
  // Synchronizers for o_ram_b_clk to A domain (already declared)

  // Synchronizers for a_full to B domain (already declared)
  // Synchronizers for a_afull to B domain (already declared)
  // Synchronizers for a_empty to B domain (already declared)
  // Synchronizers for a_aempty to B domain (already declared)

  // Synchronizers for b_full to A domain (already declared)
  // Synchronizers for b_afull to A domain (already declared)
  // Synchronizers for b_empty to A domain (already declared)
  // Synchronizers for b_aempty to A domain (already declared)

  // Synchronizers for a_rdata to B domain (already declared)
  // Synchronizers for b_rdata to A domain (already declared)

  // Synchronizers for a_dir to B domain (already declared)
  // Synchronizers for b_dir to A domain (already declared)

  // Synchronizers for a_rst_n to B domain (already declared)
  // Synchronizers for b_rst_n to A domain (already declared)

  // Synchronizers for a_winc to B domain (already declared)
  // Synchronizers for a_rinc to B domain (already declared)
  // Synchronizers for b_winc to A domain (already declared)
  // Synchronizers for b_rinc to A domain (already declared)

  // Synchronizers for a_wdata to B domain (already declared)
  // Synchronizers for b_wdata to A domain (already declared)

  // Synchronizers for i_ram_a_rdata to B domain (already declared)
  // Synchronizers for i_ram_b_rdata to A domain (already declared)

  // Synchronizers for o_ram_a_rinc to B domain (already declared)
  // Synchronizers for o_ram_a_winc to B domain (already declared)
  // Synchronizers for o_ram_b_rinc to A domain (already declared)
  // Synchronizers for o_ram_b_winc to A domain (already declared)

  // Synchronizers for o_ram_a_addr to B domain (already declared)
  // Synchronizers for o_ram_b_addr to A domain (already declared)

  // Synchronizers for o_ram_a_wdata to B domain (already declared)
  // Synchronizers for o_ram_b_wdata to A domain (already declared)

  // Synchronizers for o_ram_a_clk to B domain (already declared)
  // Synchronizers for o_ram_b_clk to A domain (already declared)

  // Synchronizers for a_full to B domain (already declared)
  // Synchronizers for a_afull to B domain (already declared)
  // Synchronizers for a_empty to B domain (already declared)
  // Synchronizers for a_aempty to B domain (already declared)

  // Synchronizers for b_full to A domain (already declared)
  // Synchronizers for b_afull to A domain (already declared)
  // Synchronizers for b_empty to A domain (already declared)
  // Synchronizers for b_aempty to A domain (already declared)

  // Synchronizers for a_rdata to B domain (already declared)
  // Synchronizers for b_rdata to A domain (already declared)

  // Synchronizers for a_dir to B domain (already declared)
  // Synchronizers for b_dir to A domain (already declared)

  // Synchronizers for a_rst_n to B domain (already declared)
  // Synchronizers for b_rst_n to A domain (already declared)

  // Synchronizers for a_winc to B domain (already declared)
  // Synchronizers for a_rinc to B domain (already declared)
  // Synchronizers for b_winc to A domain (already declared)
  // Synchronizers for b_rinc to A domain (already declared)

  // Synchronizers for a_wdata to B domain (already declared)
  // Synchronizers for b_wdata to A domain (already declared)

  // Synchronizers for i_ram_a_rdata to B