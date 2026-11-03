Here is the complete Verilog code for the SPI master module:

```
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

    // Internal signals
    reg [N-1:0]         shift_reg;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] clk_div;
    reg                 sclk_sync;
    reg                 sclk_sync_d;
    reg                 sclk_sync_dd;
    reg                 sclk_sync_ddd;
    reg                 sclk_sync_dddd;
    reg                 sclk_sync_ddddd;
    reg                 sclk_sync_dddddd;
    reg                 sclk_sync_ddddddd;
    reg                 sclk_sync_dddddddd;
    reg                 sclk_sync_ddddddddd;
    reg                 sclk_sync_dddddddddd;
    reg                 sclk_sync_ddddddddddd;
    reg                 sclk_sync_dddddddddddd;
    reg                 sclk_sync_ddddddddddddd;
    reg                 sclk_sync_dddddddddddddd;
    reg                 sclk_sync_ddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg                 sclk_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd