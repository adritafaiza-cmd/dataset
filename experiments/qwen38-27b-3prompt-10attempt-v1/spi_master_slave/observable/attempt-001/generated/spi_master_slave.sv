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

    // SCLK domain signals
    reg [N-1:0] sclk_tx_reg;
    reg [N-1:0] sclk_rx_reg;
    reg [N-1:0] sclk_bit_cnt;
    reg         sclk_active;
    reg         sclk_phase;
    reg [N-1:0] sclk_shift_reg;
    reg         sclk_mosi_reg;
    reg         sclk_ssel_reg;
    reg         sclk_sck_reg;
    reg         sclk_tx_done;
    reg         sclk_rx_done;

    // PCLK domain signals
    reg [N-1:0] pclk_tx_reg;
    reg [N-1:0] pclk_rx_reg;
    reg         pclk_tx_valid;
    reg         pclk_rx_valid;
    reg         pclk_tx_req;
    reg         pclk_rx_ack;
    reg         pclk_wr_ack;
    reg         pclk_do_valid;

    // Synchronizers for pclk -> sclk
    reg [1:0] sync_tx_valid;
    reg [1:0] sync_tx_data_0;
    reg [1:0] sync_tx_data_1;
    reg [1:0] sync_tx_data_2;
    reg [1:0] sync_tx_data_3;
    reg [1:0] sync_tx_data_4;
    reg [1:0] sync_tx_data_5;
    reg [1:0] sync_tx_data_6;
    reg [1:0] sync_tx_data_7;

    // Synchronizers for sclk -> pclk
    reg [1:0] sync_rx_done;
    reg [1:0] sync_rx_data_0;
    reg [1:0] sync_rx_data_1;
    reg [1:0] sync_rx_data_2;
    reg [1:0] sync_rx_data_3;
    reg [1:0] sync_rx_data_4;
    reg [1:0] sync_rx_data_5;
    reg [1:0] sync_rx_data_6;
    reg [1:0] sync_rx_data_7;

    // Synchronizers for pclk -> sclk (for tx request)
    reg [1:0] sync_tx_req;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk_0;
    reg [1:0] sync_rx_data_pclk_1;
    reg [1:0] sync_rx_data_pclk_2;
    reg [1:0] sync_rx_data_pclk_3;
    reg [1:0] sync_rx_data_pclk_4;
    reg [1:0] sync_rx_data_pclk_5;
    reg [1:0] sync_rx_data_pclk_6;
    reg [1:0] sync_rx_data_pclk_7;

    // Synchronizers for pclk -> sclk (for tx data)
    reg [1:0] sync_tx_data_sclk_0;
    reg [1:0] sync_tx_data_sclk_1;
    reg [1:0] sync_tx_data_sclk_2;
    reg [1:0] sync_tx_data_sclk_3;
    reg [1:0] sync_tx_data_sclk_4;
    reg [1:0] sync_tx_data_sclk_5;
    reg [1:0] sync_tx_data_sclk_6;
    reg [1:0] sync_tx_data_sclk_7;

    // Synchronizers for pclk -> sclk (for tx valid)
    reg [1:0] sync_tx_valid_sclk;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk2;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk2_0;
    reg [1:0] sync_rx_data_pclk2_1;
    reg [1:0] sync_rx_data_pclk2_2;
    reg [1:0] sync_rx_data_pclk2_3;
    reg [1:0] sync_rx_data_pclk2_4;
    reg [1:0] sync_rx_data_pclk2_5;
    reg [1:0] sync_rx_data_pclk2_6;
    reg [1:0] sync_rx_data_pclk2_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk3;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk3;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk3_0;
    reg [1:0] sync_rx_data_pclk3_1;
    reg [1:0] sync_rx_data_pclk3_2;
    reg [1:0] sync_rx_data_pclk3_3;
    reg [1:0] sync_rx_data_pclk3_4;
    reg [1:0] sync_rx_data_pclk3_5;
    reg [1:0] sync_rx_data_pclk3_6;
    reg [1:0] sync_rx_data_pclk3_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk2;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk2;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk4;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk4;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk4_0;
    reg [1:0] sync_rx_data_pclk4_1;
    reg [1:0] sync_rx_data_pclk4_2;
    reg [1:0] sync_rx_data_pclk4_3;
    reg [1:0] sync_rx_data_pclk4_4;
    reg [1:0] sync_rx_data_pclk4_5;
    reg [1:0] sync_rx_data_pclk4_6;
    reg [1:0] sync_rx_data_pclk4_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk3;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk3;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk5;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk5;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk5_0;
    reg [1:0] sync_rx_data_pclk5_1;
    reg [1:0] sync_rx_data_pclk5_2;
    reg [1:0] sync_rx_data_pclk5_3;
    reg [1:0] sync_rx_data_pclk5_4;
    reg [1:0] sync_rx_data_pclk5_5;
    reg [1:0] sync_rx_data_pclk5_6;
    reg [1:0] sync_rx_data_pclk5_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk4;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk4;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk6;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk6;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk6_0;
    reg [1:0] sync_rx_data_pclk6_1;
    reg [1:0] sync_rx_data_pclk6_2;
    reg [1:0] sync_rx_data_pclk6_3;
    reg [1:0] sync_rx_data_pclk6_4;
    reg [1:0] sync_rx_data_pclk6_5;
    reg [1:0] sync_rx_data_pclk6_6;
    reg [1:0] sync_rx_data_pclk6_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk5;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk5;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk7;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk7;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk7_0;
    reg [1:0] sync_rx_data_pclk7_1;
    reg [1:0] sync_rx_data_pclk7_2;
    reg [1:0] sync_rx_data_pclk7_3;
    reg [1:0] sync_rx_data_pclk7_4;
    reg [1:0] sync_rx_data_pclk7_5;
    reg [1:0] sync_rx_data_pclk7_6;
    reg [1:0] sync_rx_data_pclk7_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk6;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk6;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk8;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk8;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk8_0;
    reg [1:0] sync_rx_data_pclk8_1;
    reg [1:0] sync_rx_data_pclk8_2;
    reg [1:0] sync_rx_data_pclk8_3;
    reg [1:0] sync_rx_data_pclk8_4;
    reg [1:0] sync_rx_data_pclk8_5;
    reg [1:0] sync_rx_data_pclk8_6;
    reg [1:0] sync_rx_data_pclk8_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk7;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk7;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk9;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk9;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk9_0;
    reg [1:0] sync_rx_data_pclk9_1;
    reg [1:0] sync_rx_data_pclk9_2;
    reg [1:0] sync_rx_data_pclk9_3;
    reg [1:0] sync_rx_data_pclk9_4;
    reg [1:0] sync_rx_data_pclk9_5;
    reg [1:0] sync_rx_data_pclk9_6;
    reg [1:0] sync_rx_data_pclk9_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk8;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk8;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk10;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk10;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk10_0;
    reg [1:0] sync_rx_data_pclk10_1;
    reg [1:0] sync_rx_data_pclk10_2;
    reg [1:0] sync_rx_data_pclk10_3;
    reg [1:0] sync_rx_data_pclk10_4;
    reg [1:0] sync_rx_data_pclk10_5;
    reg [1:0] sync_rx_data_pclk10_6;
    reg [1:0] sync_rx_data_pclk10_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk9;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk9;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk11;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk11;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk11_0;
    reg [1:0] sync_rx_data_pclk11_1;
    reg [1:0] sync_rx_data_pclk11_2;
    reg [1:0] sync_rx_data_pclk11_3;
    reg [1:0] sync_rx_data_pclk11_4;
    reg [1:0] sync_rx_data_pclk11_5;
    reg [1:0] sync_rx_data_pclk11_6;
    reg [1:0] sync_rx_data_pclk11_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk10;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk10;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk12;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk12;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk12_0;
    reg [1:0] sync_rx_data_pclk12_1;
    reg [1:0] sync_rx_data_pclk12_2;
    reg [1:0] sync_rx_data_pclk12_3;
    reg [1:0] sync_rx_data_pclk12_4;
    reg [1:0] sync_rx_data_pclk12_5;
    reg [1:0] sync_rx_data_pclk12_6;
    reg [1:0] sync_rx_data_pclk12_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk11;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk11;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk13;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk13;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk13_0;
    reg [1:0] sync_rx_data_pclk13_1;
    reg [1:0] sync_rx_data_pclk13_2;
    reg [1:0] sync_rx_data_pclk13_3;
    reg [1:0] sync_rx_data_pclk13_4;
    reg [1:0] sync_rx_data_pclk13_5;
    reg [1:0] sync_rx_data_pclk13_6;
    reg [1:0] sync_rx_data_pclk13_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk12;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk12;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk14;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk14;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk14_0;
    reg [1:0] sync_rx_data_pclk14_1;
    reg [1:0] sync_rx_data_pclk14_2;
    reg [1:0] sync_rx_data_pclk14_3;
    reg [1:0] sync_rx_data_pclk14_4;
    reg [1:0] sync_rx_data_pclk14_5;
    reg [1:0] sync_rx_data_pclk14_6;
    reg [1:0] sync_rx_data_pclk14_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk13;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk13;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk15;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk15;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk15_0;
    reg [1:0] sync_rx_data_pclk15_1;
    reg [1:0] sync_rx_data_pclk15_2;
    reg [1:0] sync_rx_data_pclk15_3;
    reg [1:0] sync_rx_data_pclk15_4;
    reg [1:0] sync_rx_data_pclk15_5;
    reg [1:0] sync_rx_data_pclk15_6;
    reg [1:0] sync_rx_data_pclk15_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk14;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk14;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk16;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk16;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk16_0;
    reg [1:0] sync_rx_data_pclk16_1;
    reg [1:0] sync_rx_data_pclk16_2;
    reg [1:0] sync_rx_data_pclk16_3;
    reg [1:0] sync_rx_data_pclk16_4;
    reg [1:0] sync_rx_data_pclk16_5;
    reg [1:0] sync_rx_data_pclk16_6;
    reg [1:0] sync_rx_data_pclk16_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk15;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk15;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk17;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk17;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk17_0;
    reg [1:0] sync_rx_data_pclk17_1;
    reg [1:0] sync_rx_data_pclk17_2;
    reg [1:0] sync_rx_data_pclk17_3;
    reg [1:0] sync_rx_data_pclk17_4;
    reg [1:0] sync_rx_data_pclk17_5;
    reg [1:0] sync_rx_data_pclk17_6;
    reg [1:0] sync_rx_data_pclk17_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk16;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk16;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk18;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk18;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk18_0;
    reg [1:0] sync_rx_data_pclk18_1;
    reg [1:0] sync_rx_data_pclk18_2;
    reg [1:0] sync_rx_data_pclk18_3;
    reg [1:0] sync_rx_data_pclk18_4;
    reg [1:0] sync_rx_data_pclk18_5;
    reg [1:0] sync_rx_data_pclk18_6;
    reg [1:0] sync_rx_data_pclk18_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk17;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk17;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk19;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk19;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk19_0;
    reg [1:0] sync_rx_data_pclk19_1;
    reg [1:0] sync_rx_data_pclk19_2;
    reg [1:0] sync_rx_data_pclk19_3;
    reg [1:0] sync_rx_data_pclk19_4;
    reg [1:0] sync_rx_data_pclk19_5;
    reg [1:0] sync_rx_data_pclk19_6;
    reg [1:0] sync_rx_data_pclk19_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk18;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk18;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk20;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk20;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk20_0;
    reg [1:0] sync_rx_data_pclk20_1;
    reg [1:0] sync_rx_data_pclk20_2;
    reg [1:0] sync_rx_data_pclk20_3;
    reg [1:0] sync_rx_data_pclk20_4;
    reg [1:0] sync_rx_data_pclk20_5;
    reg [1:0] sync_rx_data_pclk20_6;
    reg [1:0] sync_rx_data_pclk20_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk19;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk19;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk21;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk21;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk21_0;
    reg [1:0] sync_rx_data_pclk21_1;
    reg [1:0] sync_rx_data_pclk21_2;
    reg [1:0] sync_rx_data_pclk21_3;
    reg [1:0] sync_rx_data_pclk21_4;
    reg [1:0] sync_rx_data_pclk21_5;
    reg [1:0] sync_rx_data_pclk21_6;
    reg [1:0] sync_rx_data_pclk21_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk20;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk20;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk22;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk22;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk22_0;
    reg [1:0] sync_rx_data_pclk22_1;
    reg [1:0] sync_rx_data_pclk22_2;
    reg [1:0] sync_rx_data_pclk22_3;
    reg [1:0] sync_rx_data_pclk22_4;
    reg [1:0] sync_rx_data_pclk22_5;
    reg [1:0] sync_rx_data_pclk22_6;
    reg [1:0] sync_rx_data_pclk22_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk21;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk21;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk23;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk23;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk23_0;
    reg [1:0] sync_rx_data_pclk23_1;
    reg [1:0] sync_rx_data_pclk23_2;
    reg [1:0] sync_rx_data_pclk23_3;
    reg [1:0] sync_rx_data_pclk23_4;
    reg [1:0] sync_rx_data_pclk23_5;
    reg [1:0] sync_rx_data_pclk23_6;
    reg [1:0] sync_rx_data_pclk23_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk22;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk22;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk24;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk24;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk24_0;
    reg [1:0] sync_rx_data_pclk24_1;
    reg [1:0] sync_rx_data_pclk24_2;
    reg [1:0] sync_rx_data_pclk24_3;
    reg [1:0] sync_rx_data_pclk24_4;
    reg [1:0] sync_rx_data_pclk24_5;
    reg [1:0] sync_rx_data_pclk24_6;
    reg [1:0] sync_rx_data_pclk24_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk23;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk23;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk25;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk25;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk25_0;
    reg [1:0] sync_rx_data_pclk25_1;
    reg [1:0] sync_rx_data_pclk25_2;
    reg [1:0] sync_rx_data_pclk25_3;
    reg [1:0] sync_rx_data_pclk25_4;
    reg [1:0] sync_rx_data_pclk25_5;
    reg [1:0] sync_rx_data_pclk25_6;
    reg [1:0] sync_rx_data_pclk25_7;

    // Synchronizers for pclk -> sclk (for rx ack)
    reg [1:0] sync_rx_ack_sclk24;

    // Synchronizers for pclk -> sclk (for tx req)
    reg [1:0] sync_tx_req_sclk24;

    // Synchronizers for sclk -> pclk (for tx done)
    reg [1:0] sync_tx_done_pclk26;

    // Synchronizers for sclk -> pclk (for rx done)
    reg [1:0] sync_rx_done_pclk26;

    // Synchronizers for sclk -> pclk (for rx data)
    reg [1:0] sync_rx_data_pclk26_0;
    reg [1:0] sync_rx_data_pclk26_1;
    reg [1:0] sync_rx_data_pclk26_2;
    reg [1:0] sync_rx_data_pclk26_3;
    reg [1:0] sync_rx_data_pclk26_4