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

  localparam AWIDTH = ASIZE + 1;
  localparam DEPTH  = 1 << ASIZE;
  localparam AFULL_OFFSET = 2;
  localparam AEMPTY_OFFSET = 1;

  // Side A state
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_sync;
  reg [AWIDTH-1:0] a_rd_ptr_sync;

  // Side B state
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_sync;
  reg [AWIDTH-1:0] b_rd_ptr_sync;

  // Direction registers
  reg a_dir_reg;
  reg b_dir_reg;

  // Synchronization of direction
  reg [1:0] a_dir_sync;
  reg [1:0] b_dir_sync;

  // Synchronization of pointers
  reg [AWIDTH-1:0] a_wr_ptr_sync_reg;
  reg [AWIDTH-1:0] a_rd_ptr_sync_reg;
  reg [AWIDTH-1:0] b_wr_ptr_sync_reg;
  reg [AWIDTH-1:0] b_rd_ptr_sync_reg;

  // Synchronization of direction from A to B
  reg [1:0] a_dir_to_b_sync;
  // Synchronization of direction from B to A
  reg [1:0] b_dir_to_a_sync;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg2;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg2;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg2;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg2;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg2;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg2;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg3;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg3;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg3;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg3;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg3;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg3;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg4;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg4;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg4;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg4;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg4;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg4;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg5;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg5;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg5;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg5;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg5;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg5;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg6;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg6;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg6;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg6;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg6;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg6;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg7;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg7;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg7;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg7;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg7;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg7;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg8;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg8;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg8;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg8;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg8;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg8;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg9;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg9;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg9;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg9;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg9;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg9;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg10;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg10;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg10;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg10;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg10;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg10;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg11;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg11;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg11;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg11;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg11;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg11;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg12;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg12;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg12;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg12;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg12;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg12;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg13;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg13;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg13;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg13;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg13;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg13;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg14;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg14;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg14;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg14;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg14;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg14;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg15;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg15;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg15;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg15;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg15;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg15;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg16;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg16;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg16;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg16;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg16;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg16;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg17;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg17;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg17;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg17;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg17;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg17;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg18;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg18;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg18;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg18;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg18;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg18;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg19;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg19;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg19;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg19;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg19;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg19;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg20;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg20;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg20;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg20;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg20;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg20;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg21;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg21;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg21;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg21;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg21;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg21;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg22;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg22;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg22;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg22;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg22;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg22;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg23;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg23;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg23;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg23;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg23;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg23;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg24;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg24;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg24;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg24;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg24;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg24;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg25;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg25;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg25;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg25;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg25;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg25;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg26;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg26;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg26;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg26;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg26;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg26;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg27;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg27;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg27;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg27;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg27;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg27;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg28;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg28;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg28;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg28;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg28;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg28;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg29;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg29;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg29;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg29;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg29;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg29;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg30;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg30;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg30;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg30;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg30;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg30;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg31;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg31;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg31;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg31;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg31;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg31;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg32;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg32;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg32;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg32;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg32;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg32;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg33;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg33;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg33;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg33;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg33;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg33;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg34;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg34;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg34;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg34;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg34;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg34;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg35;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg35;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg35;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg35;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg35;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg35;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg36;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg36;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg36;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg36;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg36;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg36;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg37;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg37;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg37;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg37;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg37;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg37;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg38;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg38;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg38;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg38;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg38;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a_sync_reg38;

  // Synchronization of A direction to B domain
  reg [1:0] a_dir_to_b_sync_reg39;
  // Synchronization of B direction to A domain
  reg [1:0] b_dir_to_a_sync_reg39;

  // Synchronization of A write pointer to B domain
  reg [AWIDTH-1:0] a_wr_ptr_to_b_sync_reg39;
  // Synchronization of A read pointer to B domain
  reg [AWIDTH-1:0] a_rd_ptr_to_b_sync_reg39;
  // Synchronization of B write pointer to A domain
  reg [AWIDTH-1:0] b_wr_ptr_to_a_sync_reg39;
  // Synchronization of B read pointer to A domain
  reg [AWIDTH-1:0] b_rd_ptr_to_a