```verilog
module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // State machine states
    localparam S_IDLE    = 2'd0;
    localparam S_WAIT_WR = 2'd1;
    localparam S_SHIFT   = 2'd2;
    localparam S_DONE    = 2'd3;

    reg [1:0] state;
    reg [1:0] state_next;

    // Shift register for MOSI
    reg [N-1:0] mosi_shift;
    // Shift register for MISO
    reg [N-1:0] miso_shift;
    // Bit counter
    reg [$clog2(N):0] bit_cnt;

    // Clock divider for SPI clock generation
    reg [SPI_2X_CLK_DIV-1:0] clk_div;
    reg sck_toggle;

    // Synchronization of pclk signals to sclk domain
    reg [1:0] wren_sync;
    reg [1:0] wren_sync_next;
    wire wren_sclk = wren_sync[1];

    reg [1:0] di_req_sync;
    reg [1:0] di_req_sync_next;
    wire di_req_sclk = di_req_sync[1];

    // Synchronization of sclk signals to pclk domain
    reg [1:0] state_sync;
    reg [1:0] state_sync_next;
    wire state_pclk = state_sync[1];

    reg [1:0] do_valid_sync;
    reg [1:0] do_valid_sync_next;
    wire do_valid_pclk = do_valid_sync[1];

    // Synchronize di_i to sclk domain
    reg [N-1:0] di_sync;
    reg [N-1:0] di_sync_next;
    wire [N-1:0] di_sclk = di_sync[1];

    // Synchronize spi_miso_i to sclk domain (already in sclk domain, but ensure stability)
    // spi_miso_i is sampled on sclk edges, so it's already in sclk domain

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_sync;
    reg [N-1:0] do_sync_next;
    wire [N-1:0] do_pclk = do_sync[1];

    // Synchronize wr_ack to sclk domain
    reg [1:0] wr_ack_sync;
    reg [1:0] wr_ack_sync_next;
    wire wr_ack_sclk = wr_ack_sync[1];

    // Synchronize spi_ssel_o to pclk domain for potential use
    reg [1:0] ssel_sync;
    reg [1:0] ssel_sync_next;
    wire ssel_pclk = ssel_sync[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_sync;
    reg [1:0] sck_sync_next;
    wire sck_pclk = sck_sync[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_sync;
    reg [1:0] mosi_sync_next;
    wire mosi_pclk = mosi_sync[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync;
    reg [1:0] di_req_out_sync_next;
    wire di_req_out_pclk = di_req_out_sync[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync;
    reg [1:0] wr_ack_out_sync_next;
    wire wr_ack_out_pclk = wr_ack_out_sync[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync;
    reg [1:0] do_valid_out_sync_next;
    wire do_valid_out_pclk = do_valid_out_sync[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync;
    reg [N-1:0] do_out_sync_next;
    wire [N-1:0] do_out_pclk = do_out_sync[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync;
    reg [1:0] ssel_out_sync_next;
    wire ssel_out_pclk = ssel_out_sync[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync;
    reg [1:0] sck_out_sync_next;
    wire sck_out_pclk = sck_out_sync[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync;
    reg [1:0] mosi_out_sync_next;
    wire mosi_out_pclk = mosi_out_sync[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync2;
    reg [1:0] di_req_out_sync2_next;
    wire di_req_out_pclk2 = di_req_out_sync2[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync2;
    reg [1:0] wr_ack_out_sync2_next;
    wire wr_ack_out_pclk2 = wr_ack_out_sync2[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync2;
    reg [1:0] do_valid_out_sync2_next;
    wire do_valid_out_pclk2 = do_valid_out_sync2[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync2;
    reg [N-1:0] do_out_sync2_next;
    wire [N-1:0] do_out_pclk2 = do_out_sync2[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync2;
    reg [1:0] ssel_out_sync2_next;
    wire ssel_out_pclk2 = ssel_out_sync2[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync2;
    reg [1:0] sck_out_sync2_next;
    wire sck_out_pclk2 = sck_out_sync2[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync2;
    reg [1:0] mosi_out_sync2_next;
    wire mosi_out_pclk2 = mosi_out_sync2[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync3;
    reg [1:0] di_req_out_sync3_next;
    wire di_req_out_pclk3 = di_req_out_sync3[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync3;
    reg [1:0] wr_ack_out_sync3_next;
    wire wr_ack_out_pclk3 = wr_ack_out_sync3[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync3;
    reg [1:0] do_valid_out_sync3_next;
    wire do_valid_out_pclk3 = do_valid_out_sync3[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync3;
    reg [N-1:0] do_out_sync3_next;
    wire [N-1:0] do_out_pclk3 = do_out_sync3[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync3;
    reg [1:0] ssel_out_sync3_next;
    wire ssel_out_pclk3 = ssel_out_sync3[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync3;
    reg [1:0] sck_out_sync3_next;
    wire sck_out_pclk3 = sck_out_sync3[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync3;
    reg [1:0] mosi_out_sync3_next;
    wire mosi_out_pclk3 = mosi_out_sync3[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync4;
    reg [1:0] di_req_out_sync4_next;
    wire di_req_out_pclk4 = di_req_out_sync4[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync4;
    reg [1:0] wr_ack_out_sync4_next;
    wire wr_ack_out_pclk4 = wr_ack_out_sync4[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync4;
    reg [1:0] do_valid_out_sync4_next;
    wire do_valid_out_pclk4 = do_valid_out_sync4[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync4;
    reg [N-1:0] do_out_sync4_next;
    wire [N-1:0] do_out_pclk4 = do_out_sync4[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync4;
    reg [1:0] ssel_out_sync4_next;
    wire ssel_out_pclk4 = ssel_out_sync4[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync4;
    reg [1:0] sck_out_sync4_next;
    wire sck_out_pclk4 = sck_out_sync4[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync4;
    reg [1:0] mosi_out_sync4_next;
    wire mosi_out_pclk4 = mosi_out_sync4[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync5;
    reg [1:0] di_req_out_sync5_next;
    wire di_req_out_pclk5 = di_req_out_sync5[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync5;
    reg [1:0] wr_ack_out_sync5_next;
    wire wr_ack_out_pclk5 = wr_ack_out_sync5[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync5;
    reg [1:0] do_valid_out_sync5_next;
    wire do_valid_out_pclk5 = do_valid_out_sync5[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync5;
    reg [N-1:0] do_out_sync5_next;
    wire [N-1:0] do_out_pclk5 = do_out_sync5[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync5;
    reg [1:0] ssel_out_sync5_next;
    wire ssel_out_pclk5 = ssel_out_sync5[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync5;
    reg [1:0] sck_out_sync5_next;
    wire sck_out_pclk5 = sck_out_sync5[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync5;
    reg [1:0] mosi_out_sync5_next;
    wire mosi_out_pclk5 = mosi_out_sync5[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync6;
    reg [1:0] di_req_out_sync6_next;
    wire di_req_out_pclk6 = di_req_out_sync6[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync6;
    reg [1:0] wr_ack_out_sync6_next;
    wire wr_ack_out_pclk6 = wr_ack_out_sync6[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync6;
    reg [1:0] do_valid_out_sync6_next;
    wire do_valid_out_pclk6 = do_valid_out_sync6[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync6;
    reg [N-1:0] do_out_sync6_next;
    wire [N-1:0] do_out_pclk6 = do_out_sync6[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync6;
    reg [1:0] ssel_out_sync6_next;
    wire ssel_out_pclk6 = ssel_out_sync6[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync6;
    reg [1:0] sck_out_sync6_next;
    wire sck_out_pclk6 = sck_out_sync6[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync6;
    reg [1:0] mosi_out_sync6_next;
    wire mosi_out_pclk6 = mosi_out_sync6[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync7;
    reg [1:0] di_req_out_sync7_next;
    wire di_req_out_pclk7 = di_req_out_sync7[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync7;
    reg [1:0] wr_ack_out_sync7_next;
    wire wr_ack_out_pclk7 = wr_ack_out_sync7[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync7;
    reg [1:0] do_valid_out_sync7_next;
    wire do_valid_out_pclk7 = do_valid_out_sync7[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync7;
    reg [N-1:0] do_out_sync7_next;
    wire [N-1:0] do_out_pclk7 = do_out_sync7[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync7;
    reg [1:0] ssel_out_sync7_next;
    wire ssel_out_pclk7 = ssel_out_sync7[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync7;
    reg [1:0] sck_out_sync7_next;
    wire sck_out_pclk7 = sck_out_sync7[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync7;
    reg [1:0] mosi_out_sync7_next;
    wire mosi_out_pclk7 = mosi_out_sync7[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync8;
    reg [1:0] di_req_out_sync8_next;
    wire di_req_out_pclk8 = di_req_out_sync8[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync8;
    reg [1:0] wr_ack_out_sync8_next;
    wire wr_ack_out_pclk8 = wr_ack_out_sync8[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync8;
    reg [1:0] do_valid_out_sync8_next;
    wire do_valid_out_pclk8 = do_valid_out_sync8[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync8;
    reg [N-1:0] do_out_sync8_next;
    wire [N-1:0] do_out_pclk8 = do_out_sync8[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync8;
    reg [1:0] ssel_out_sync8_next;
    wire ssel_out_pclk8 = ssel_out_sync8[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync8;
    reg [1:0] sck_out_sync8_next;
    wire sck_out_pclk8 = sck_out_sync8[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync8;
    reg [1:0] mosi_out_sync8_next;
    wire mosi_out_pclk8 = mosi_out_sync8[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync9;
    reg [1:0] di_req_out_sync9_next;
    wire di_req_out_pclk9 = di_req_out_sync9[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync9;
    reg [1:0] wr_ack_out_sync9_next;
    wire wr_ack_out_pclk9 = wr_ack_out_sync9[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync9;
    reg [1:0] do_valid_out_sync9_next;
    wire do_valid_out_pclk9 = do_valid_out_sync9[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync9;
    reg [N-1:0] do_out_sync9_next;
    wire [N-1:0] do_out_pclk9 = do_out_sync9[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync9;
    reg [1:0] ssel_out_sync9_next;
    wire ssel_out_pclk9 = ssel_out_sync9[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync9;
    reg [1:0] sck_out_sync9_next;
    wire sck_out_pclk9 = sck_out_sync9[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync9;
    reg [1:0] mosi_out_sync9_next;
    wire mosi_out_pclk9 = mosi_out_sync9[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync10;
    reg [1:0] di_req_out_sync10_next;
    wire di_req_out_pclk10 = di_req_out_sync10[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync10;
    reg [1:0] wr_ack_out_sync10_next;
    wire wr_ack_out_pclk10 = wr_ack_out_sync10[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync10;
    reg [1:0] do_valid_out_sync10_next;
    wire do_valid_out_pclk10 = do_valid_out_sync10[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync10;
    reg [N-1:0] do_out_sync10_next;
    wire [N-1:0] do_out_pclk10 = do_out_sync10[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync10;
    reg [1:0] ssel_out_sync10_next;
    wire ssel_out_pclk10 = ssel_out_sync10[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync10;
    reg [1:0] sck_out_sync10_next;
    wire sck_out_pclk10 = sck_out_sync10[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync10;
    reg [1:0] mosi_out_sync10_next;
    wire mosi_out_pclk10 = mosi_out_sync10[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync11;
    reg [1:0] di_req_out_sync11_next;
    wire di_req_out_pclk11 = di_req_out_sync11[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync11;
    reg [1:0] wr_ack_out_sync11_next;
    wire wr_ack_out_pclk11 = wr_ack_out_sync11[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync11;
    reg [1:0] do_valid_out_sync11_next;
    wire do_valid_out_pclk11 = do_valid_out_sync11[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync11;
    reg [N-1:0] do_out_sync11_next;
    wire [N-1:0] do_out_pclk11 = do_out_sync11[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync11;
    reg [1:0] ssel_out_sync11_next;
    wire ssel_out_pclk11 = ssel_out_sync11[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync11;
    reg [1:0] sck_out_sync11_next;
    wire sck_out_pclk11 = sck_out_sync11[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync11;
    reg [1:0] mosi_out_sync11_next;
    wire mosi_out_pclk11 = mosi_out_sync11[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync12;
    reg [1:0] di_req_out_sync12_next;
    wire di_req_out_pclk12 = di_req_out_sync12[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync12;
    reg [1:0] wr_ack_out_sync12_next;
    wire wr_ack_out_pclk12 = wr_ack_out_sync12[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync12;
    reg [1:0] do_valid_out_sync12_next;
    wire do_valid_out_pclk12 = do_valid_out_sync12[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync12;
    reg [N-1:0] do_out_sync12_next;
    wire [N-1:0] do_out_pclk12 = do_out_sync12[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync12;
    reg [1:0] ssel_out_sync12_next;
    wire ssel_out_pclk12 = ssel_out_sync12[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync12;
    reg [1:0] sck_out_sync12_next;
    wire sck_out_pclk12 = sck_out_sync12[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync12;
    reg [1:0] mosi_out_sync12_next;
    wire mosi_out_pclk12 = mosi_out_sync12[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync13;
    reg [1:0] di_req_out_sync13_next;
    wire di_req_out_pclk13 = di_req_out_sync13[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync13;
    reg [1:0] wr_ack_out_sync13_next;
    wire wr_ack_out_pclk13 = wr_ack_out_sync13[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync13;
    reg [1:0] do_valid_out_sync13_next;
    wire do_valid_out_pclk13 = do_valid_out_sync13[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync13;
    reg [N-1:0] do_out_sync13_next;
    wire [N-1:0] do_out_pclk13 = do_out_sync13[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync13;
    reg [1:0] ssel_out_sync13_next;
    wire ssel_out_pclk13 = ssel_out_sync13[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync13;
    reg [1:0] sck_out_sync13_next;
    wire sck_out_pclk13 = sck_out_sync13[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync13;
    reg [1:0] mosi_out_sync13_next;
    wire mosi_out_pclk13 = mosi_out_sync13[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync14;
    reg [1:0] di_req_out_sync14_next;
    wire di_req_out_pclk14 = di_req_out_sync14[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync14;
    reg [1:0] wr_ack_out_sync14_next;
    wire wr_ack_out_pclk14 = wr_ack_out_sync14[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync14;
    reg [1:0] do_valid_out_sync14_next;
    wire do_valid_out_pclk14 = do_valid_out_sync14[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync14;
    reg [N-1:0] do_out_sync14_next;
    wire [N-1:0] do_out_pclk14 = do_out_sync14[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync14;
    reg [1:0] ssel_out_sync14_next;
    wire ssel_out_pclk14 = ssel_out_sync14[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync14;
    reg [1:0] sck_out_sync14_next;
    wire sck_out_pclk14 = sck_out_sync14[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync14;
    reg [1:0] mosi_out_sync14_next;
    wire mosi_out_pclk14 = mosi_out_sync14[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync15;
    reg [1:0] di_req_out_sync15_next;
    wire di_req_out_pclk15 = di_req_out_sync15[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync15;
    reg [1:0] wr_ack_out_sync15_next;
    wire wr_ack_out_pclk15 = wr_ack_out_sync15[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync15;
    reg [1:0] do_valid_out_sync15_next;
    wire do_valid_out_pclk15 = do_valid_out_sync15[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync15;
    reg [N-1:0] do_out_sync15_next;
    wire [N-1:0] do_out_pclk15 = do_out_sync15[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync15;
    reg [1:0] ssel_out_sync15_next;
    wire ssel_out_pclk15 = ssel_out_sync15[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync15;
    reg [1:0] sck_out_sync15_next;
    wire sck_out_pclk15 = sck_out_sync15[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync15;
    reg [1:0] mosi_out_sync15_next;
    wire mosi_out_pclk15 = mosi_out_sync15[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync16;
    reg [1:0] di_req_out_sync16_next;
    wire di_req_out_pclk16 = di_req_out_sync16[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync16;
    reg [1:0] wr_ack_out_sync16_next;
    wire wr_ack_out_pclk16 = wr_ack_out_sync16[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync16;
    reg [1:0] do_valid_out_sync16_next;
    wire do_valid_out_pclk16 = do_valid_out_sync16[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync16;
    reg [N-1:0] do_out_sync16_next;
    wire [N-1:0] do_out_pclk16 = do_out_sync16[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync16;
    reg [1:0] ssel_out_sync16_next;
    wire ssel_out_pclk16 = ssel_out_sync16[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync16;
    reg [1:0] sck_out_sync16_next;
    wire sck_out_pclk16 = sck_out_sync16[1];

    // Synchronize spi_mosi_o to pclk domain
    reg [1:0] mosi_out_sync16;
    reg [1:0] mosi_out_sync16_next;
    wire mosi_out_pclk16 = mosi_out_sync16[1];

    // Synchronize di_req_o to pclk domain
    reg [1:0] di_req_out_sync17;
    reg [1:0] di_req_out_sync17_next;
    wire di_req_out_pclk17 = di_req_out_sync17[1];

    // Synchronize wr_ack_o to pclk domain
    reg [1:0] wr_ack_out_sync17;
    reg [1:0] wr_ack_out_sync17_next;
    wire wr_ack_out_pclk17 = wr_ack_out_sync17[1];

    // Synchronize do_valid_o to pclk domain
    reg [1:0] do_valid_out_sync17;
    reg [1:0] do_valid_out_sync17_next;
    wire do_valid_out_pclk17 = do_valid_out_sync17[1];

    // Synchronize do_o to pclk domain
    reg [N-1:0] do_out_sync17;
    reg [N-1:0] do_out_sync17_next;
    wire [N-1:0] do_out_pclk17 = do_out_sync17[1];

    // Synchronize spi_ssel_o to pclk domain
    reg [1:0] ssel_out_sync17;
    reg [1:0] ssel_out_sync17_next;
    wire ssel_out_pclk17 = ssel_out_sync17[1];

    // Synchronize spi_sck_o to pclk domain
    reg [1:0] sck_out_sync17;
    reg [1:0] sck_out_sync17_next;
    wire sck_out_pclk17 = sck_out_sync17[1];

    // Synchronize spi_m