```verilog
`timescale 1ns/1ps

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

  localparam INT_ASIZE = ASIZE;
  localparam INT_DEPTH = 1 << INT_ASIZE;

  // Internal pointers and counters
  reg [INT_ASIZE-1:0] a_write_ptr;
  reg [INT_ASIZE-1:0] a_read_ptr;
  reg [INT_ASIZE-1:0] b_write_ptr;
  reg [INT_ASIZE-1:0] b_read_ptr;

  // Gray code pointers for CDC
  reg [INT_ASIZE-1:0] a_write_gray;
  reg [INT_ASIZE-1:0] a_read_gray;
  reg [INT_ASIZE-1:0] b_write_gray;
  reg [INT_ASIZE-1:0] b_read_gray;

  // Cross-domain pointers (stored in opposite domains)
  wire [INT_ASIZE-1:0] a_write_ptr_cross;
  wire [INT_ASIZE-1:0] a_read_ptr_cross;
  wire [INT_ASIZE-1:0] b_write_ptr_cross;
  wire [INT_ASIZE-1:0] b_read_ptr_cross;

  // Data storage
  reg [DSIZE-1:0] mem [INT_DEPTH-1:0];

  // Valid flags for pointers
  reg [INT_ASIZE-1:0] a_write_valid;
  reg [INT_ASIZE-1:0] a_read_valid;
  reg [INT_ASIZE-1:0] b_write_valid;
  reg [INT_ASIZE-1:0] b_read_valid;

  // Cross-domain valid flags
  wire [INT_ASIZE-1:0] a_write_valid_cross;
  wire [INT_ASIZE-1:0] a_read_valid_cross;
  wire [INT_ASIZE-1:0] b_write_valid_cross;
  wire [INT_ASIZE-1:0] b_read_valid_cross;

  // Almost full/empty flags (local)
  reg a_almost_full;
  reg a_almost_empty;
  reg b_almost_full;
  reg b_almost_empty;

  // Almost full/empty flags (crossed)
  wire a_almost_full_cross;
  wire a_almost_empty_cross;
  wire b_almost_full_cross;
  wire b_almost_empty_cross;

  // Write enable signals (local)
  reg a_write_en;
  reg b_write_en;

  // Read enable signals (local)
  reg a_read_en;
  reg b_read_en;

  // Cross-domain write enables
  wire a_write_en_cross;
  wire b_write_en_cross;

  // Cross-domain read enables
  wire a_read_en_cross;
  wire b_read_en_cross;

  // Cross-domain data
  wire [DSIZE-1:0] a_wdata_cross;
  wire [DSIZE-1:0] b_wdata_cross;

  // Cross-domain full/empty flags
  wire a_full_cross;
  wire a_empty_cross;
  wire b_full_cross;
  wire b_empty_cross;

  // Cross-domain almost full/empty flags
  wire a_almost_full_cross_out;
  wire a_almost_empty_cross_out;
  wire b_almost_full_cross_out;
  wire b_almost_empty_cross_out;

  // Cross-domain pointers (output from one domain to the other)
  wire [INT_ASIZE-1:0] a_write_ptr_out;
  wire [INT_ASIZE-1:0] a_read_ptr_out;
  wire [INT_ASIZE-1:0] b_write_ptr_out;
  wire [INT_ASIZE-1:0] b_read_ptr_out;

  // Cross-domain valid flags (output from one domain to the other)
  wire [INT_ASIZE-1:0] a_write_valid_out;
  wire [INT_ASIZE-1:0] a_read_valid_out;
  wire [INT_ASIZE-1:0] b_write_valid_out;
  wire [INT_ASIZE-1:0] b_read_valid_out;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out;
  wire a_empty_out;
  wire b_full_out;
  wire b_empty_out;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out;
  wire a_almost_empty_out;
  wire b_almost_full_out;
  wire b_almost_empty_out;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out;
  wire [DSIZE-1:0] b_wdata_out;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out;
  wire [DSIZE-1:0] b_rdata_out;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out;
  wire b_write_en_out;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out;
  wire b_read_en_out;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross;
  wire a_empty_out_cross;
  wire b_full_out_cross;
  wire b_empty_out_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross;
  wire a_almost_empty_out_cross;
  wire b_almost_full_out_cross;
  wire b_almost_empty_out_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross;
  wire [DSIZE-1:0] b_wdata_out_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross;
  wire [DSIZE-1:0] b_rdata_out_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross;
  wire b_write_en_out_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross;
  wire b_read_en_out_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross;
  wire a_empty_out_cross_cross;
  wire b_full_out_cross_cross;
  wire b_empty_out_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross;
  wire a_almost_empty_out_cross_cross;
  wire b_almost_full_out_cross_cross;
  wire b_almost_empty_out_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross;
  wire b_write_en_out_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross;
  wire b_read_en_out_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross;
  wire a_empty_out_cross_cross_cross;
  wire b_full_out_cross_cross_cross;
  wire b_empty_out_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain full/empty flags (output from one domain to the other)
  wire a_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain almost full/empty flags (output from one domain to the other)
  wire a_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire a_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_full_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_almost_empty_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain data (output from one domain to the other)
  wire [DSIZE-1:0] a_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_wdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read data (output from one domain to the other)
  wire [DSIZE-1:0] a_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire [DSIZE-1:0] b_rdata_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain write enable (output from one domain to the other)
  wire a_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;
  wire b_write_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross;

  // Cross-domain read enable (output from one domain to the other)
  wire a_read_en_out_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross_cross