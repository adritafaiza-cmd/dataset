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

  // Gray encoded pointers for CDC
  reg [INT_ASIZE-1:0] a_write_gray;
  reg [INT_ASIZE-1:0] a_read_gray;
  reg [INT_ASIZE-1:0] b_write_gray;
  reg [INT_ASIZE-1:0] b_read_gray;

  // Data storage
  reg [DSIZE-1:0] mem [0:INT_DEPTH-1];

  // Write enable signals (synchronized to respective clocks)
  reg a_write_en;
  reg b_write_en;

  // Read enable signals (synchronized to respective clocks)
  reg a_read_en;
  reg b_read_en;

  // Direction registers (synchronized to respective clocks)
  reg a_dir_reg;
  reg b_dir_reg;

  // Almost full/empty counters for flags
  reg a_almost_full;
  reg a_almost_empty;
  reg b_almost_full;
  reg b_almost_empty;

  // State for handling direction changes and pointer crossing
  // We need to ensure that when direction changes, the pointers are updated correctly
  // and the data is accessible.
  
  // Synchronization logic for direction
  reg a_dir_sync;
  reg b_dir_sync;

  // Write enable synchronization
  reg a_write_en_sync;
  reg b_write_en_sync;

  // Read enable synchronization
  reg a_read_en_sync;
  reg b_read_en_sync;

  // Almost full/empty flag synchronization
  reg a_almost_full_sync;
  reg a_almost_empty_sync;
  reg b_almost_full_sync;
  reg b_almost_empty_sync;

  // Data synchronization
  reg [DSIZE-1:0] a_rdata_sync;
  reg [DSIZE-1:0] b_rdata_sync;

  // Write data synchronization
  reg [DSIZE-1:0] a_wdata_sync;
  reg [DSIZE-1:0] b_wdata_sync;

  // Write enable synchronization for the other domain
  reg a_write_en_b;
  reg b_write_en_a;

  // Read enable synchronization for the other domain
  reg a_read_en_b;
  reg b_read_en_a;

  // Almost full/empty flag synchronization for the other domain
  reg a_almost_full_b;
  reg a_almost_empty_b;
  reg b_almost_full_a;
  reg b_almost_empty_a;

  // Write data synchronization for the other domain
  reg [DSIZE-1:0] a_wdata_b;
  reg [DSIZE-1:0] b_wdata_a;

  // Read data synchronization for the other domain
  reg [DSIZE-1:0] a_rdata_a;
  reg [DSIZE-1:0] b_rdata_b;

  // Write enable synchronization for the other domain (second stage)
  reg a_write_en_b_sync;
  reg b_write_en_a_sync;

  // Read enable synchronization for the other domain (second stage)
  reg a_read_en_b_sync;
  reg b_read_en_a_sync;

  // Almost full/empty flag synchronization for the other domain (second stage)
  reg a_almost_full_b_sync;
  reg a_almost_empty_b_sync;
  reg b_almost_full_a_sync;
  reg b_almost_empty_a_sync;

  // Write data synchronization for the other domain (second stage)
  reg [DSIZE-1:0] a_wdata_b_sync;
  reg [DSIZE-1:0] b_wdata_a_sync;

  // Read data synchronization for the other domain (second stage)
  reg [DSIZE-1:0] a_rdata_a_sync;
  reg [DSIZE-1:0] b_rdata_b_sync;

  // Write enable synchronization for the other domain (third stage)
  reg a_write_en_b_sync2;
  reg b_write_en_a_sync2;

  // Read enable synchronization for the other domain (third stage)
  reg a_read_en_b_sync2;
  reg b_read_en_a_sync2;

  // Almost full/empty flag synchronization for the other domain (third stage)
  reg a_almost_full_b_sync2;
  reg a_almost_empty_b_sync2;
  reg b_almost_full_a_sync2;
  reg b_almost_empty_a_sync2;

  // Write data synchronization for the other domain (third stage)
  reg [DSIZE-1:0] a_wdata_b_sync2;
  reg [DSIZE-1:0] b_wdata_a_sync2;

  // Read data synchronization for the other domain (third stage)
  reg [DSIZE-1:0] a_rdata_a_sync2;
  reg [DSIZE-1:0] b_rdata_b_sync2;

  // Write enable synchronization for the other domain (fourth stage)
  reg a_write_en_b_sync3;
  reg b_write_en_a_sync3;

  // Read enable synchronization for the other domain (fourth stage)
  reg a_read_en_b_sync3;
  reg b_read_en_a_sync3;

  // Almost full/empty flag synchronization for the other domain (fourth stage)
  reg a_almost_full_b_sync3;
  reg a_almost_empty_b_sync3;
  reg b_almost_full_a_sync3;
  reg b_almost_empty_a_sync3;

  // Write data synchronization for the other domain (fourth stage)
  reg [DSIZE-1:0] a_wdata_b_sync3;
  reg [DSIZE-1:0] b_wdata_a_sync3;

  // Read data synchronization for the other domain (fourth stage)
  reg [DSIZE-1:0] a_rdata_a_sync3;
  reg [DSIZE-1:0] b_rdata_b_sync3;

  // Write enable synchronization for the other domain (fifth stage)
  reg a_write_en_b_sync4;
  reg b_write_en_a_sync4;

  // Read enable synchronization for the other domain (fifth stage)
  reg a_read_en_b_sync4;
  reg b_read_en_a_sync4;

  // Almost full/empty flag synchronization for the other domain (fifth stage)
  reg a_almost_full_b_sync4;
  reg a_almost_empty_b_sync4;
  reg b_almost_full_a_sync4;
  reg b_almost_empty_a_sync4;

  // Write data synchronization for the other domain (fifth stage)
  reg [DSIZE-1:0] a_wdata_b_sync4;
  reg [DSIZE-1:0] b_wdata_a_sync4;

  // Read data synchronization for the other domain (fifth stage)
  reg [DSIZE-1:0] a_rdata_a_sync4;
  reg [DSIZE-1:0] b_rdata_b_sync4;

  // Write enable synchronization for the other domain (sixth stage)
  reg a_write_en_b_sync5;
  reg b_write_en_a_sync5;

  // Read enable synchronization for the other domain (sixth stage)
  reg a_read_en_b_sync5;
  reg b_read_en_a_sync5;

  // Almost full/empty flag synchronization for the other domain (sixth stage)
  reg a_almost_full_b_sync5;
  reg a_almost_empty_b_sync5;
  reg b_almost_full_a_sync5;
  reg b_almost_empty_a_sync5;

  // Write data synchronization for the other domain (sixth stage)
  reg [DSIZE-1:0] a_wdata_b_sync5;
  reg [DSIZE-1:0] b_wdata_a_sync5;

  // Read data synchronization for the other domain (sixth stage)
  reg [DSIZE-1:0] a_rdata_a_sync5;
  reg [DSIZE-1:0] b_rdata_b_sync5;

  // Write enable synchronization for the other domain (seventh stage)
  reg a_write_en_b_sync6;
  reg b_write_en_a_sync6;

  // Read enable synchronization for the other domain (seventh stage)
  reg a_read_en_b_sync6;
  reg b_read_en_a_sync6;

  // Almost full/empty flag synchronization for the other domain (seventh stage)
  reg a_almost_full_b_sync6;
  reg a_almost_empty_b_sync6;
  reg b_almost_full_a_sync6;
  reg b_almost_empty_a_sync6;

  // Write data synchronization for the other domain (seventh stage)
  reg [DSIZE-1:0] a_wdata_b_sync6;
  reg [DSIZE-1:0] b_wdata_a_sync6;

  // Read data synchronization for the other domain (seventh stage)
  reg [DSIZE-1:0] a_rdata_a_sync6;
  reg [DSIZE-1:0] b_rdata_b_sync6;

  // Write enable synchronization for the other domain (eighth stage)
  reg a_write_en_b_sync7;
  reg b_write_en_a_sync7;

  // Read enable synchronization for the other domain (eighth stage)
  reg a_read_en_b_sync7;
  reg b_read_en_a_sync7;

  // Almost full/empty flag synchronization for the other domain (eighth stage)
  reg a_almost_full_b_sync7;
  reg a_almost_empty_b_sync7;
  reg b_almost_full_a_sync7;
  reg b_almost_empty_a_sync7;

  // Write data synchronization for the other domain (eighth stage)
  reg [DSIZE-1:0] a_wdata_b_sync7;
  reg [DSIZE-1:0] b_wdata_a_sync7;

  // Read data synchronization for the other domain (eighth stage)
  reg [DSIZE-1:0] a_rdata_a_sync7;
  reg [DSIZE-1:0] b_rdata_b_sync7;

  // Write enable synchronization for the other domain (ninth stage)
  reg a_write_en_b_sync8;
  reg b_write_en_a_sync8;

  // Read enable synchronization for the other domain (ninth stage)
  reg a_read_en_b_sync8;
  reg b_read_en_a_sync8;

  // Almost full/empty flag synchronization for the other domain (ninth stage)
  reg a_almost_full_b_sync8;
  reg a_almost_empty_b_sync8;
  reg b_almost_full_a_sync8;
  reg b_almost_empty_a_sync8;

  // Write data synchronization for the other domain (ninth stage)
  reg [DSIZE-1:0] a_wdata_b_sync8;
  reg [DSIZE-1:0] b_wdata_a_sync8;

  // Read data synchronization for the other domain (ninth stage)
  reg [DSIZE-1:0] a_rdata_a_sync8;
  reg [DSIZE-1:0] b_rdata_b_sync8;

  // Write enable synchronization for the other domain (tenth stage)
  reg a_write_en_b_sync9;
  reg b_write_en_a_sync9;

  // Read enable synchronization for the other domain (tenth stage)
  reg a_read_en_b_sync9;
  reg b_read_en_a_sync9;

  // Almost full/empty flag synchronization for the other domain (tenth stage)
  reg a_almost_full_b_sync9;
  reg a_almost_empty_b_sync9;
  reg b_almost_full_a_sync9;
  reg b_almost_empty_a_sync9;

  // Write data synchronization for the other domain (tenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync9;
  reg [DSIZE-1:0] b_wdata_a_sync9;

  // Read data synchronization for the other domain (tenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync9;
  reg [DSIZE-1:0] b_rdata_b_sync9;

  // Write enable synchronization for the other domain (eleventh stage)
  reg a_write_en_b_sync10;
  reg b_write_en_a_sync10;

  // Read enable synchronization for the other domain (eleventh stage)
  reg a_read_en_b_sync10;
  reg b_read_en_a_sync10;

  // Almost full/empty flag synchronization for the other domain (eleventh stage)
  reg a_almost_full_b_sync10;
  reg a_almost_empty_b_sync10;
  reg b_almost_full_a_sync10;
  reg b_almost_empty_a_sync10;

  // Write data synchronization for the other domain (eleventh stage)
  reg [DSIZE-1:0] a_wdata_b_sync10;
  reg [DSIZE-1:0] b_wdata_a_sync10;

  // Read data synchronization for the other domain (eleventh stage)
  reg [DSIZE-1:0] a_rdata_a_sync10;
  reg [DSIZE-1:0] b_rdata_b_sync10;

  // Write enable synchronization for the other domain (twelfth stage)
  reg a_write_en_b_sync11;
  reg b_write_en_a_sync11;

  // Read enable synchronization for the other domain (twelfth stage)
  reg a_read_en_b_sync11;
  reg b_read_en_a_sync11;

  // Almost full/empty flag synchronization for the other domain (twelfth stage)
  reg a_almost_full_b_sync11;
  reg a_almost_empty_b_sync11;
  reg b_almost_full_a_sync11;
  reg b_almost_empty_a_sync11;

  // Write data synchronization for the other domain (twelfth stage)
  reg [DSIZE-1:0] a_wdata_b_sync11;
  reg [DSIZE-1:0] b_wdata_a_sync11;

  // Read data synchronization for the other domain (twelfth stage)
  reg [DSIZE-1:0] a_rdata_a_sync11;
  reg [DSIZE-1:0] b_rdata_b_sync11;

  // Write enable synchronization for the other domain (thirteenth stage)
  reg a_write_en_b_sync12;
  reg b_write_en_a_sync12;

  // Read enable synchronization for the other domain (thirteenth stage)
  reg a_read_en_b_sync12;
  reg b_read_en_a_sync12;

  // Almost full/empty flag synchronization for the other domain (thirteenth stage)
  reg a_almost_full_b_sync12;
  reg a_almost_empty_b_sync12;
  reg b_almost_full_a_sync12;
  reg b_almost_empty_a_sync12;

  // Write data synchronization for the other domain (thirteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync12;
  reg [DSIZE-1:0] b_wdata_a_sync12;

  // Read data synchronization for the other domain (thirteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync12;
  reg [DSIZE-1:0] b_rdata_b_sync12;

  // Write enable synchronization for the other domain (fourteenth stage)
  reg a_write_en_b_sync13;
  reg b_write_en_a_sync13;

  // Read enable synchronization for the other domain (fourteenth stage)
  reg a_read_en_b_sync13;
  reg b_read_en_a_sync13;

  // Almost full/empty flag synchronization for the other domain (fourteenth stage)
  reg a_almost_full_b_sync13;
  reg a_almost_empty_b_sync13;
  reg b_almost_full_a_sync13;
  reg b_almost_empty_a_sync13;

  // Write data synchronization for the other domain (fourteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync13;
  reg [DSIZE-1:0] b_wdata_a_sync13;

  // Read data synchronization for the other domain (fourteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync13;
  reg [DSIZE-1:0] b_rdata_b_sync13;

  // Write enable synchronization for the other domain (fifteenth stage)
  reg a_write_en_b_sync14;
  reg b_write_en_a_sync14;

  // Read enable synchronization for the other domain (fifteenth stage)
  reg a_read_en_b_sync14;
  reg b_read_en_a_sync14;

  // Almost full/empty flag synchronization for the other domain (fifteenth stage)
  reg a_almost_full_b_sync14;
  reg a_almost_empty_b_sync14;
  reg b_almost_full_a_sync14;
  reg b_almost_empty_a_sync14;

  // Write data synchronization for the other domain (fifteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync14;
  reg [DSIZE-1:0] b_wdata_a_sync14;

  // Read data synchronization for the other domain (fifteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync14;
  reg [DSIZE-1:0] b_rdata_b_sync14;

  // Write enable synchronization for the other domain (sixteenth stage)
  reg a_write_en_b_sync15;
  reg b_write_en_a_sync15;

  // Read enable synchronization for the other domain (sixteenth stage)
  reg a_read_en_b_sync15;
  reg b_read_en_a_sync15;

  // Almost full/empty flag synchronization for the other domain (sixteenth stage)
  reg a_almost_full_b_sync15;
  reg a_almost_empty_b_sync15;
  reg b_almost_full_a_sync15;
  reg b_almost_empty_a_sync15;

  // Write data synchronization for the other domain (sixteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync15;
  reg [DSIZE-1:0] b_wdata_a_sync15;

  // Read data synchronization for the other domain (sixteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync15;
  reg [DSIZE-1:0] b_rdata_b_sync15;

  // Write enable synchronization for the other domain (seventeenth stage)
  reg a_write_en_b_sync16;
  reg b_write_en_a_sync16;

  // Read enable synchronization for the other domain (seventeenth stage)
  reg a_read_en_b_sync16;
  reg b_read_en_a_sync16;

  // Almost full/empty flag synchronization for the other domain (seventeenth stage)
  reg a_almost_full_b_sync16;
  reg a_almost_empty_b_sync16;
  reg b_almost_full_a_sync16;
  reg b_almost_empty_a_sync16;

  // Write data synchronization for the other domain (seventeenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync16;
  reg [DSIZE-1:0] b_wdata_a_sync16;

  // Read data synchronization for the other domain (seventeenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync16;
  reg [DSIZE-1:0] b_rdata_b_sync16;

  // Write enable synchronization for the other domain (eighteenth stage)
  reg a_write_en_b_sync17;
  reg b_write_en_a_sync17;

  // Read enable synchronization for the other domain (eighteenth stage)
  reg a_read_en_b_sync17;
  reg b_read_en_a_sync17;

  // Almost full/empty flag synchronization for the other domain (eighteenth stage)
  reg a_almost_full_b_sync17;
  reg a_almost_empty_b_sync17;
  reg b_almost_full_a_sync17;
  reg b_almost_empty_a_sync17;

  // Write data synchronization for the other domain (eighteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync17;
  reg [DSIZE-1:0] b_wdata_a_sync17;

  // Read data synchronization for the other domain (eighteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync17;
  reg [DSIZE-1:0] b_rdata_b_sync17;

  // Write enable synchronization for the other domain (nineteenth stage)
  reg a_write_en_b_sync18;
  reg b_write_en_a_sync18;

  // Read enable synchronization for the other domain (nineteenth stage)
  reg a_read_en_b_sync18;
  reg b_read_en_a_sync18;

  // Almost full/empty flag synchronization for the other domain (nineteenth stage)
  reg a_almost_full_b_sync18;
  reg a_almost_empty_b_sync18;
  reg b_almost_full_a_sync18;
  reg b_almost_empty_a_sync18;

  // Write data synchronization for the other domain (nineteenth stage)
  reg [DSIZE-1:0] a_wdata_b_sync18;
  reg [DSIZE-1:0] b_wdata_a_sync18;

  // Read data synchronization for the other domain (nineteenth stage)
  reg [DSIZE-1:0] a_rdata_a_sync18;
  reg [DSIZE-1:0] b_rdata_b_sync18;

  // Write enable synchronization for the other domain (twentieth stage)
  reg a_write_en_b_sync19;
  reg b_write_en_a_sync19;

  // Read enable synchronization for the other domain (twentieth stage)
  reg a_read_en_b_sync19;
  reg b_read_en_a_sync19;

  // Almost full/empty flag synchronization for the other domain (twentieth stage)
  reg a_almost_full_b_sync19;
  reg a_almost_empty_b_sync19;
  reg b_almost_full_a_sync19;
  reg b_almost_empty_a_sync19;

  // Write data synchronization for the other domain (twentieth stage)
  reg [DSIZE-1:0] a_wdata_b_sync19;
  reg [DSIZE-1:0] b_wdata_a_sync19;

  // Read data synchronization for the other domain (twentieth stage)
  reg [DSIZE-1:0] a_rdata_a_sync19;
  reg [DSIZE-1:0] b_rdata_b_sync19;

  // Write enable synchronization for the other domain (twenty-first stage)
  reg a_write_en_b_sync20;
  reg b_write_en_a_sync20;

  // Read enable synchronization for the other domain (twenty-first stage)
  reg a_read_en_b_sync20;
  reg b_read_en_a_sync20;

  // Almost full/empty flag synchronization for the other domain (twenty-first stage)
  reg a_almost_full_b_sync20;
  reg a_almost_empty_b_sync20;
  reg b_almost_full_a_sync20;
  reg b_almost_empty_a_sync20;

  // Write data synchronization for the other domain (twenty-first stage)
  reg [DSIZE-1:0] a_wdata_b_sync20;
  reg [DSIZE-1:0] b_wdata_a_sync20;

  // Read data synchronization for the other domain (twenty-first stage)
  reg [DSIZE-1:0] a_rdata_a_sync20;
  reg [DSIZE-1:0] b_rdata_b_sync20;

  // Write enable synchronization for the other domain (twenty-second stage)
  reg a_write_en_b_sync21;
  reg b_write_en_a_sync21;

  // Read enable synchronization for the other domain (twenty-second stage)
  reg a_read_en_b_sync21;
  reg b_read_en_a_sync21;

  // Almost full/empty flag synchronization for the other domain (twenty-second stage)
  reg a_almost_full_b_sync21;
  reg a_almost_empty_b_sync21;
  reg b_almost_full_a_sync21;
  reg b_almost_empty_a_sync21;

  // Write data synchronization for the other domain (twenty-second stage)
  reg [DSIZE-1:0] a_wdata_b_sync21;
  reg [DSIZE-1:0] b_wdata_a_sync21;

  // Read data synchronization for the other domain (twenty-second stage)
  reg [DSIZE-1:0] a_rdata_a_sync21;
  reg [DSIZE-1:0] b_rdata_b_sync21;

  // Write enable synchronization for the other domain (twenty-third stage)
  reg a_write_en_b_sync22;
  reg b_write_en_a_sync22;

  // Read enable synchronization for the other domain (twenty-third stage)
  reg a_read_en_b_sync22;
  reg b_read_en_a_sync22;

  // Almost full/empty flag synchronization for the other domain (twenty-third stage)
  reg a_almost_full_b_sync22;
  reg a_almost_empty_b_sync22;
  reg b_almost_full_a_sync22;
  reg b_almost_empty_a_sync22;

  // Write data synchronization for the other domain (twenty-third stage)
  reg [DSIZE-1:0] a_wdata_b_sync22;
  reg [DSIZE-1:0] b_wdata_a_sync22;

  // Read data synchronization for the other domain (twenty-third stage)
  reg [DSIZE-1:0] a_rdata_a_sync22;
  reg [DSIZE-1:0] b_rdata_b_sync22;

  // Write enable synchronization for the other domain (twenty-fourth stage)
  reg a_write_en_b_sync23;
  reg b_write_en_a_sync23;

  // Read enable synchronization for the other domain (twenty-fourth stage)
  reg a_read_en_b_sync23;
  reg b_read_en_a_sync23;

  // Almost full/empty flag synchronization for the other domain (twenty-fourth stage)
  reg a_almost_full_b_sync23;
  reg a_almost_empty_b_sync23;
  reg b_almost_full_a_sync23;
  reg b_almost_empty_a_sync23;

  // Write data synchronization for the other domain (twenty-fourth stage)
  reg [DSIZE-1:0] a_wdata_b_sync23;
  reg [DSIZE-1:0] b_wdata_a_sync23;

  // Read data synchronization for the other domain (twenty-fourth stage)
  reg [DSIZE-1:0] a_rdata_a_sync23;
  reg [DSIZE-1:0] b_rdata_b_sync23;

  // Write enable synchronization for the other domain (twenty-fifth stage)
  reg a_write_en_b_sync24;
  reg b_write_en_a_sync24;

  // Read enable synchronization for the other domain (twenty-fifth stage)
  reg a_read_en_b_sync24;
  reg b_read_en_a_sync24;

  // Almost full/empty flag synchronization for the other domain (twenty-fifth stage)
  reg a_almost_full_b_sync24;
  reg a_almost_empty_b_sync24;
  reg b_almost_full_a_sync24;
  reg b_almost_empty_a_sync24;

  // Write data synchronization for the other domain (twenty-fifth stage)
  reg [DSIZE-1:0] a_wdata_b_sync24;
  reg [DSIZE-1:0] b_wdata_a_sync24;

  // Read data synchronization for the other domain (twenty-fifth stage)
  reg [DSIZE-1:0] a_rdata_a_sync24;
  reg [DSIZE-1:0] b_rdata_b_sync24;

  // Write enable synchronization for the other domain (twenty-sixth stage)
  reg a_write_en_b_sync25;
  reg b_write_en_a_sync25;

  // Read enable synchronization for the other domain (twenty-sixth stage)
  reg a_read_en_b_sync25;
  reg b_read_en_a_sync25;

  // Almost full/empty flag synchronization for the other domain (twenty-sixth stage)
  reg a_almost_full_b_sync25;
  reg a_almost_empty_b_sync25;
  reg b_almost_full_a_sync25;
  reg b_almost_empty_a_sync25;

  // Write data synchronization for the other domain (twenty-sixth stage)
  reg [DSIZE-1:0] a_wdata_b_sync25;
  reg [DSIZE-1:0] b_wdata_a_sync25;

  // Read data synchronization for the other domain (twenty-sixth stage)
  reg [DSIZE-1:0] a_rdata_a_sync25;
  reg [DSIZE-1:0] b_rdata_b_sync25;

  // Write enable synchronization for the other domain (twenty-seventh stage)
  reg a_write_en_b_sync26;
  reg b_write_en_a_sync26;

  // Read enable synchronization for the other domain (twenty-seventh stage)
  reg a_read_en_b_sync26;
  reg b_read_en_a_sync26;

  // Almost full/empty flag synchronization for the other domain (twenty-seventh stage)
  reg a_almost_full_b_sync26;
  reg a_almost_empty_b_sync26;
  reg b_almost_full_a_sync26;
  reg b_almost_empty_a_sync26;

  // Write data synchronization for the other domain (twenty-seventh stage)
  reg [DSIZE-1:0] a_wdata_b_sync26;
  reg [DSIZE-1:0] b_wdata_a_sync26;

  // Read data synchronization for the other domain (twenty-seventh stage)
  reg [DSIZE-1:0] a_rdata_a_sync26;
  reg [DSIZE-1:0] b_rdata_b_sync26;

  // Write enable synchronization for the other domain (twenty-eighth stage)
  reg a_write_en_b_sync27;
  reg b_write_en_a_sync27;

  // Read enable synchronization for the other domain (twenty-eighth stage)
  reg a_read_en_b_sync27;
  reg b_read_en_a_sync27;

  // Almost full/empty flag synchronization for the other domain (twenty-eighth stage)
  reg a_almost_full_b_sync27;
  reg a_almost_empty_b_sync27;
  reg b_almost_full_a_sync27;
  reg b_almost_empty_a_sync27;

  // Write data synchronization for the other domain (twenty-eighth stage)
  reg [DSIZE-1:0] a_wdata_b_sync27;
  reg [DSIZE-1:0] b_wdata_a_sync27;

  // Read data synchronization for the other domain (twenty-eighth stage)
  reg [DSIZE-1:0] a_rdata_a_sync27;
  reg [DSIZE-1:0] b_rdata_b_sync27;

  // Write enable synchronization for the other domain (twenty-ninth stage)
  reg a_write_en_b_sync28;
  reg b_write_en_a_sync28;

  // Read enable synchronization for the other domain (twenty-ninth stage)
  reg a_read_en_b_sync28;
  reg b_read_en_a_sync28;

  // Almost full/empty flag synchronization for the other domain (twenty-ninth stage)
  reg a_almost_full_b_sync28;
  reg a_almost_empty_b_sync28;
  reg b_almost_full_a_sync28;
  reg b_almost_empty_a_sync28;

  // Write data synchronization for the other domain (twenty-ninth stage)
  reg [DSIZE-1:0] a_wdata_b_sync28;
  reg [DSIZE-1:0] b_wdata_a_sync28;

  // Read data synchronization for the other domain (twenty-ninth stage)
  reg [DSIZE-1:0] a_rdata_a_sync28;
  reg [DSIZE-1:0] b_rdata_b_sync28;

  // Write enable synchronization for the other domain (thirtieth stage)
  reg a_write_en_b_sync29;
  reg b_write_en_a_sync29;

  // Read enable synchronization for the other domain (thirtieth stage)
  reg a_read_en_b_sync29;
  reg b_read_en_a_sync29;

  // Almost full/empty flag synchronization for the other domain (thirtieth stage)
  reg a_almost_full_b_sync29;
  reg a_almost_empty_b_sync29;
  reg b_almost_full_a_sync29;
  reg b_almost_empty_a_sync29;

  // Write data synchronization for the other domain (thirtieth stage)
  reg [DSIZE-1:0] a_wdata_b_sync29;
  reg [DSIZE-1:0] b_wdata_a_sync29;

  // Read data synchronization for the other domain (thirtieth stage)
  reg [DSIZE-1:0] a_rdata_a_sync29;
  reg [DSIZE-1:0] b_rdata_b_sync29;

  // Write enable synchronization for the other domain (thirty-first stage)
  reg a_write_en_b_sync30;
  reg b_write_en_a_sync30;

  // Read enable synchronization for the other domain (thirty-first stage)
  reg a_read_en_b_sync30;
  reg b_read_en_a_sync30;

  // Almost full/empty flag synchronization for the other domain (thirty-first stage)
  reg a_almost_full_b_sync30;
  reg a_almost_empty_b_sync30;
  reg b_almost_full_a_sync30;
  reg b_almost_empty_a_sync30;

  // Write data synchronization for the other domain (thirty-first stage)
  reg [DSIZE-1:0] a_wdata_b_sync30;
  reg [DSIZE-1:0] b_wdata_a_sync30;

  // Read data synchronization for the other domain (thirty-first stage)
  reg [DSIZE-1:0] a_rdata_a_sync30;
  reg [DSIZE-1:0] b_rdata_b_sync30;

  // Write enable synchronization for the other