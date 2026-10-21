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

  localparam GRANT_WIDTH = ASIZE;
  localparam GRANT_MASK  = { {GRANT_WIDTH-1{1'b0}}, 1'b1 };

  // Internal pointers and counters
  reg [GRANT_WIDTH-1:0] a_wptr, a_rptr;
  reg [GRANT_WIDTH-1:0] b_wptr, b_rptr;
  
  // Cross-domain pointers (snapshot)
  wire [GRANT_WIDTH-1:0] a_wptr_snap, a_rptr_snap;
  wire [GRANT_WIDTH-1:0] b_wptr_snap, b_rptr_snap;

  // Cross-domain pointers (snapshot) for the other side
  wire [GRANT_WIDTH-1:0] a_wptr_snap_b, a_rptr_snap_b;
  wire [GRANT_WIDTH-1:0] b_wptr_snap_a, b_rptr_snap_a;

  // FIFO Depth
  wire [GRANT_WIDTH-1:0] depth = 1 << ASIZE;
  wire [GRANT_WIDTH-1:0] depth_minus_1 = depth - 1;

  // State registers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_reg, a_rptr_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_reg, b_rptr_reg;

  // Cross-domain pointer registers (snapshots)
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Data storage
  reg [DSIZE-1:0] mem [0:depth_minus_1];

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT_WIDTH-1:0] a_wptr_snap_b_reg, a_rptr_snap_b_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_a_reg, b_rptr_snap_a_reg;

  // Write pointers for each domain
  reg [GRANT_WIDTH-1:0] a_wptr_local, a_rptr_local;
  reg [GRANT_WIDTH-1:0] b_wptr_local, b_rptr_local;

  // Read pointers for each domain
  reg [GRANT_WIDTH-1:0] a_rptr_local, a_wptr_local;
  reg [GRANT_WIDTH-1:0] b_rptr_local, b_wptr_local;

  // Write enable signals
  reg a_we;
  reg b_we;

  // Read enable signals
  reg a_re;
  reg b_re;

  // Full/Empty flags
  reg a_full, a_empty;
  reg b_full, b_empty;

  // Almost Full/Empty flags
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointer registers
  reg [GRANT_WIDTH-1:0] a_wptr_snap_reg, a_rptr_snap_reg;
  reg [GRANT_WIDTH-1:0] b_wptr_snap_reg, b_rptr_snap_reg;

  // Cross-domain pointer registers for the other side
  reg [GRANT