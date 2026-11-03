Sure, here is the complete Verilog code for the SPI master module:

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
    reg [N-1:0]         shift_reg_next;
    reg                 sclk_div_cnt;
    reg                 sclk_div_cnt_next;
    reg                 sclk_div_cnt_reset;
    reg                 sclk_div_cnt_reset_next;
    reg                 sclk_div_cnt_en;
    reg                 sclk_div_cnt_en_next;
    reg                 sclk_div_cnt_en_reset;
    reg                 sclk_div_cnt_en_reset_next;
    reg                 sclk_div_cnt_en_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_next;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x;
    reg                 sclk_div_cnt_en_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_reset_2x_