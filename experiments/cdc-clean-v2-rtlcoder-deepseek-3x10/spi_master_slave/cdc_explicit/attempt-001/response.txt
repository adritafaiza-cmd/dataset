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

    // Internal registers
    reg [N-1:0]         tx_data;
    reg [N-1:0]         rx_data;
    reg [N-1:0]         shift_reg;
    reg [$clog2(N)-1:0] shift_cnt;
    reg                 tx_done;
    reg                 rx_done;
    reg                 tx_start;
    reg                 rx_start;
    reg                 tx_busy;
    reg                 rx_busy;

    // Clock divider
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] clk_div_cnt;
    wire                            clk_div_en;

    // CDC synchronizers
    reg                             sclk_sync;
    reg                             pclk_sync;
    reg                             rst_sync;
    reg                             spi_miso_sync;
    reg                             wren_sync;
    reg [N-1:0]                     di_sync;

    // CDC release synchronizers
    reg                             sclk_release;
    reg                             pclk_release;
    reg                             rst_release;
    reg                             spi_miso_release;
    reg                             wren_release;
    reg [N-1:0]                     di_release;

    // CDC release synchronizer stages
    reg                             sclk_release_stage1;
    reg                             pclk_release_stage1;
    reg                             rst_release_stage1;
    reg                             spi_miso_release_stage1;
    reg                             wren_release_stage1;
    reg [N-1:0]                     di_release_stage1;

    // CDC release synchronizer stages
    reg                             sclk_release_stage2;
    reg                             pclk_release_stage2;
    reg                             rst_release_stage2;
    reg                             spi_miso_release_stage2;
    reg                             wren_release_stage2;
    reg [N-1:0]                     di_release_stage2;

    // CDC release synchronizer stages
    reg                             sclk_release_stage3;
    reg                             pclk_release_stage3;
    reg                             rst_release_stage3;
    reg                             spi_miso_release_stage3;
    reg                             wren_release_stage3;
    reg [N-1:0]                     di_release_stage3;

    // CDC release synchronizer stages
    reg                             sclk_release_stage4;
    reg                             pclk_release_stage4;
    reg                             rst_release_stage4;
    reg                             spi_miso_release_stage4;
    reg                             wren_release_stage4;
    reg [N-1:0]                     di_release_stage4;

    // CDC release synchronizer stages
    reg                             sclk_release_stage5;
    reg                             pclk_release_stage5;
    reg                             rst_release_stage5;
    reg                             spi_miso_release_stage5;
    reg                             wren_release_stage5;
    reg [N-1:0]                     di_release_stage5;

    // CDC release synchronizer stages
    reg                             sclk_release_stage6;
    reg                             pclk_release_stage6;
    reg                             rst_release_stage6;
    reg                             spi_miso_release_stage6;
    reg                             wren_release_stage6;
    reg [N-1:0]                     di_release_stage6;

    // CDC release synchronizer stages
    reg                             sclk_release_stage7;
    reg                             pclk_release_stage7;
    reg                             rst_release_stage7;
    reg                             spi_miso_release_stage7;
    reg                             wren_release_stage7;
    reg [N-1:0]                     di_release_stage7;

    // CDC release synchronizer stages
    reg                             sclk_release_stage8;
    reg                             pclk_release_stage8;
    reg                             rst_release_stage8;
    reg                             spi_miso_release_stage8;
    reg                             wren_release_stage8;
    reg [N-1:0]                     di_release_stage8;

    // CDC release synchronizer stages
    reg                             sclk_release_stage9;
    reg                             pclk_release_stage9;
    reg                             rst_release_stage9;
    reg                             spi_miso_release_stage9;
    reg                             wren_release_stage9;
    reg [N-1:0]                     di_release_stage9;

    // CDC release synchronizer stages
    reg                             sclk_release_stage10;
    reg                             pclk_release_stage10;
    reg                             rst_release_stage10;
    reg                             spi_miso_release_stage10;
    reg                             wren_release_stage10;
    reg [N-1:0]                     di_release_stage10;

    // CDC release synchronizer stages
    reg                             sclk_release_stage11;
    reg                             pclk_release_stage11;
    reg                             rst_release_stage11;
    reg                             spi_miso_release_stage11;
    reg                             wren_release_stage11;
    reg [N-1:0]                     di_release_stage11;

    // CDC release synchronizer stages
    reg                             sclk_release_stage12;
    reg                             pclk_release_stage12;
    reg                             rst_release_stage12;
    reg                             spi_miso_release_stage12;
    reg                             wren_release_stage12;
    reg [N-1:0]                     di_release_stage12;

    // CDC release synchronizer stages
    reg                             sclk_release_stage13;
    reg                             pclk_release_stage13;
    reg                             rst_release_stage13;
    reg                             spi_miso_release_stage13;
    reg                             wren_release_stage13;
    reg [N-1:0]                     di_release_stage13;

    // CDC release synchronizer stages
    reg                             sclk_release_stage14;
    reg                             pclk_release_stage14;
    reg                             rst_release_stage14;
    reg                             spi_miso_release_stage14;
    reg                             wren_release_stage14;
    reg [N-1:0]                     di_release_stage14;

    // CDC release synchronizer stages
    reg                             sclk_release_stage15;
    reg                             pclk_release_stage15;
    reg                             rst_release_stage15;
    reg                             spi_miso_release_stage15;
    reg                             wren_release_stage15;
    reg [N-1:0]                     di_release_stage15;

    // CDC release synchronizer stages
    reg                             sclk_release_stage16;
    reg                             pclk_release_stage16;
    reg                             rst_release_stage16;
    reg                             spi_miso_release_stage16;
    reg                             wren_release_stage16;
    reg [N-1:0]                     di_release_stage16;

    // CDC release synchronizer stages
    reg                             sclk_release_stage17;
    reg                             pclk_release_stage17;
    reg                             rst_release_stage17;
    reg                             spi_miso_release_stage17;
    reg                             wren_release_stage17;
    reg [N-1:0]                     di_release_stage17;

    // CDC release synchronizer stages
    reg                             sclk_release_stage18;
    reg                             pclk_release_stage18;
    reg                             rst_release_stage18;
    reg                             spi_miso_release_stage18;
    reg                             wren_release_stage18;
    reg [N-1:0]                     di_release_stage18;

    // CDC release synchronizer stages
    reg                             sclk_release_stage19;
    reg                             pclk_release_stage19;
    reg                             rst_release_stage19;
    reg                             spi_miso_release_stage19;
    reg                             wren_release_stage19;
    reg [N-1:0]                     di_release_stage19;

    // CDC release synchronizer stages
    reg                             sclk_release_stage20;
    reg                             pclk_release_stage20;
    reg                             rst_release_stage20;
    reg                             spi_miso_release_stage20;
    reg                             wren_release_stage20;
    reg [N-1:0]                     di_release_stage20;

    // CDC release synchronizer stages
    reg                             sclk_release_stage21;
    reg                             pclk_release_stage21;
    reg                             rst_release_stage21;
    reg                             spi_miso_release_stage21;
    reg                             wren_release_stage21;
    reg [N-1:0]                     di_release_stage21;

    // CDC release synchronizer stages
    reg                             sclk_release_stage22;
    reg                             pclk_release_stage22;
    reg                             rst_release_stage22;
    reg                             spi_miso_release_stage22;
    reg                             wren_release_stage22;
    reg [N-1:0]                     di_release_stage22;

    // CDC release synchronizer stages
    reg                             sclk_release_stage23;
    reg                             pclk_release_stage23;
    reg                             rst_release_stage23;
    reg                             spi_miso_release_stage23;
    reg                             wren_release_stage23;
    reg [N-1:0]                     di_release_stage23;

    // CDC release synchronizer stages
    reg                             sclk_release_stage24;
    reg                             pclk_release_stage24;
    reg                             rst_release_stage24;
    reg                             spi_miso_release_stage24;
    reg                             wren_release_stage24;
    reg [N-1:0]                     di_release_stage24;

    // CDC release synchronizer stages
    reg                             sclk_release_stage25;
    reg                             pclk_release_stage25;
    reg                             rst_release_stage25;
    reg                             spi_miso_release_stage25;
    reg                             wren_release_stage25;
    reg [N-1:0]                     di_release_stage25;

    // CDC release synchronizer stages
    reg                             sclk_release_stage26;
    reg                             pclk_release_stage26;
    reg                             rst_release_stage26;
    reg                             spi_miso_release_stage26;
    reg                             wren_release_stage26;
    reg [N-1:0]                     di_release_stage26;

    // CDC release synchronizer stages
    reg                             sclk_release_stage27;
    reg                             pclk_release_stage27;
    reg                             rst_release_stage27;
    reg                             spi_miso_release_stage27;
    reg                             wren_release_stage27;
    reg [N-1:0]                     di_release_stage27;

    // CDC release synchronizer stages
    reg                             sclk_release_stage28;
    reg                             pclk_release_stage28;
    reg                             rst_release_stage28;
    reg                             spi_miso_release_stage28;
    reg                             wren_release_stage28;
    reg [N-1:0]                     di_release_stage28;

    // CDC release synchronizer stages
    reg                             sclk_release_stage29;
    reg                             pclk_release_stage29;
    reg                             rst_release_stage29;
    reg                             spi_miso_release_stage29;
    reg                             wren_release_stage29;
    reg [N-1:0]                     di_release_stage29;

    // CDC release synchronizer stages
    reg                             sclk_release_stage30;
    reg                             pclk_release_stage30;
    reg                             rst_release_stage30;
    reg                             spi_miso_release_stage30;
    reg                             wren_release_stage30;
    reg [N-1:0]                     di_release_stage30;

    // CDC release synchronizer stages
    reg                             sclk_release_stage31;
    reg                             pclk_release_stage31;
    reg                             rst_release_stage31;
    reg                             spi_miso_release_stage31;
    reg                             wren_release_stage31;
    reg [N-1:0]                     di_release_stage31;

    // CDC release synchronizer stages
    reg                             sclk_release_stage32;
    reg                             pclk_release_stage32;
    reg                             rst_release_stage32;
    reg                             spi_miso_release_stage32;
    reg                             wren_release_stage32;
    reg [N-1:0]                     di_release_stage32;

    // CDC release synchronizer stages
    reg                             sclk_release_stage33;
    reg                             pclk_release_stage33;
    reg                             rst_release_stage33;
    reg                             spi_miso_release_stage33;
    reg                             wren_release_stage33;
    reg [N-1:0]                     di_release_stage33;

    // CDC release synchronizer stages
    reg                             sclk_release_stage34;
    reg                             pclk_release_stage34;
    reg                             rst_release_stage34;
    reg                             spi_miso_release_stage34;
    reg                             wren_release_stage34;
    reg [N-1:0]                     di_release_stage34;

    // CDC release synchronizer stages
    reg                             sclk_release_stage35;
    reg                             pclk_release_stage35;
    reg                             rst_release_stage35;
    reg                             spi_miso_release_stage35;
    reg                             wren_release_stage35;
    reg [N-1:0]                     di_release_stage35;

    // CDC release synchronizer stages
    reg                             sclk_release_stage36;
    reg                             pclk_release_stage36;
    reg                             rst_release_stage36;
    reg                             spi_miso_release_stage36;
    reg                             wren_release_stage36;
    reg [N-1:0]                     di_release_stage36;

    // CDC release synchronizer stages
    reg                             sclk_release_stage37;
    reg                             pclk_release_stage37;
    reg                             rst_release_stage37;
    reg                             spi_miso_release_stage37;
    reg                             wren_release_stage37;
    reg [N-1:0]                     di_release_stage37;

    // CDC release synchronizer stages
    reg                             sclk_release_stage38;
    reg                             pclk_release_stage38;
    reg                             rst_release_stage38;
    reg                             spi_miso_release_stage38;
    reg                             wren_release_stage38;
    reg [N-1:0]                     di_release_stage38;

    // CDC release synchronizer stages
    reg                             sclk_release_stage39;
    reg                             pclk_release_stage39;
    reg                             rst_release_stage39;
    reg                             spi_miso_release_stage39;
    reg                             wren_release_stage39;
    reg [N-1:0]                     di_release_stage39;

    // CDC release synchronizer stages
    reg                             sclk_release_stage40;
    reg                             pclk_release_stage40;
    reg                             rst_release_stage40;
    reg                             spi_miso_release_stage40;
    reg                             wren_release_stage40;
    reg [N-1:0]                     di_release_stage40;

    // CDC release synchronizer stages
    reg                             sclk_release_stage41;
    reg                             pclk_release_stage41;
    reg                             rst_release_stage41;
    reg                             spi_miso_release_stage41;
    reg                             wren_release_stage41;
    reg [N-1:0]                     di_release_stage41;

    // CDC release synchronizer stages
    reg                             sclk_release_stage42;
    reg                             pclk_release_stage42;
    reg                             rst_release_stage42;
    reg                             spi_miso_release_stage42;
    reg                             wren_release_stage42;
    reg [N-1:0]                     di_release_stage42;

    // CDC release synchronizer stages
    reg                             sclk_release_stage43;
    reg                             pclk_release_stage43;
    reg                             rst_release_stage43;
    reg                             spi_miso_release_stage43;
    reg                             wren_release_stage43;
    reg [N-1:0]                     di_release_stage43;

    // CDC release synchronizer stages
    reg                             sclk_release_stage44;
    reg                             pclk_release_stage44;
    reg                             rst_release_stage44;
    reg                             spi_miso_release_stage44;
    reg                             wren_release_stage44;
    reg [N-1:0]                     di_release_stage44;

    // CDC release synchronizer stages
    reg                             sclk_release_stage45;
    reg                             pclk_release_stage45;
    reg                             rst_release_stage45;
    reg                             spi_miso_release_stage45;
    reg                             wren_release_stage45;
    reg [N-1:0]                     di_release_stage45;

    // CDC release synchronizer stages
    reg                             sclk_release_stage46;
    reg                             pclk_release_stage46;
    reg                             rst_release_stage46;
    reg                             spi_miso_release_stage46;
    reg                             wren_release_stage46;
    reg [N-1:0]                     di_release_stage46;

    // CDC release synchronizer stages
    reg                             sclk_release_stage47;
    reg                             pclk_release_stage47;
    reg                             rst_release_stage47;
    reg                             spi_miso_release_stage47;
    reg                             wren_release_stage47;
    reg [N-1:0]                     di_release_stage47;

    // CDC release synchronizer stages
    reg                             sclk_release_stage48;
    reg                             pclk_release_stage48;
    reg                             rst_release_stage48;
    reg                             spi_miso_release_stage48;
    reg                             wren_release_stage48;
    reg [N-1:0]                     di_release_stage48;

    // CDC release synchronizer stages
    reg                             sclk_release_stage49;
    reg                             pclk_release_stage49;
    reg                             rst_release_stage49;
    reg                             spi_miso_release_stage49;
    reg                             wren_release_stage49;
    reg [N-1:0]                     di_release_stage49;

    // CDC release synchronizer stages
    reg                             sclk_release_stage50;
    reg                             pclk_release_stage50;
    reg                             rst_release_stage50;
    reg                             spi_miso_release_stage50;
    reg                             wren_release_stage50;
    reg [N-1:0]                     di_release_stage50;

    // CDC release synchronizer stages
    reg                             sclk_release_stage51;
    reg                             pclk_release_stage51;
    reg                             rst_release_stage51;
    reg                             spi_miso_release_stage51;
    reg                             wren_release_stage51;
    reg [N-1:0]                     di_release_stage51;

    // CDC release synchronizer stages
    reg                             sclk_release_stage52;
    reg                             pclk_release_stage52;
    reg                             rst_release_stage52;
    reg                             spi_miso_release_stage52;
    reg                             wren_release_stage52;
    reg [N-1:0]                     di_release_stage52;

    // CDC release synchronizer stages
    reg                             sclk_release_stage53;
    reg                             pclk_release_stage53;
    reg                             rst_release_stage53;
    reg                             spi_miso_release_stage53;
    reg                             wren_release_stage53;
    reg [N-1:0]                     di_release_stage53;

    // CDC release synchronizer stages
    reg                             sclk_release_stage54;
    reg                             pclk_release_stage54;
    reg                             rst_release_stage54;
    reg                             spi_miso_release_stage54;
    reg                             wren_release_stage54;
    reg [N-1:0]                     di_release_stage54;

    // CDC release synchronizer stages
    reg                             sclk_release_stage55;
    reg                             pclk_release_stage55;
    reg                             rst_release_stage55;
    reg                             spi_miso_release_stage55;
    reg                             wren_release_stage55;
    reg [N-1:0]                     di_release_stage55;

    // CDC release synchronizer stages
    reg                             sclk_release_stage56;
    reg                             pclk_release_stage56;
    reg                             rst_release_stage56;
    reg                             spi_miso_release_stage56;
    reg                             wren_release_stage56;
    reg [N-1:0]                     di_release_stage56;

    // CDC release synchronizer stages
    reg                             sclk_release_stage57;
    reg                             pclk_release_stage57;
    reg                             rst_release_stage57;
    reg                             spi_miso_release_stage57;
    reg                             wren_release_stage57;
    reg [N-1:0]                     di_release_stage57;

    // CDC release synchronizer stages
    reg                             sclk_release_stage58;
    reg                             pclk_release_stage58;
    reg                             rst_release_stage58;
    reg                             spi_miso_release_stage58;
    reg                             wren_release_stage58;
    reg [N-1:0]                     di_release_stage58;

    // CDC release synchronizer stages
    reg                             sclk_release_stage59;
    reg                             pclk_release_stage59;
    reg                             rst_release_stage59;
    reg                             spi_miso_release_stage59;
    reg                             wren_release_stage59;
    reg [N-1:0]                     di_release_stage59;

    // CDC release synchronizer stages
    reg                             sclk_release_stage60;
    reg                             pclk_release_stage60;
    reg                             rst_release_stage60;
    reg                             spi_miso_release_stage60;
    reg                             wren_release_stage60;
    reg [N-1:0]                     di_release_stage60;

    // CDC release synchronizer stages
    reg                             sclk_release_stage61;
    reg                             pclk_release_stage61;
    reg                             rst_release_stage61;
    reg                             spi_miso_release_stage61;
    reg                             wren_release_stage61;
    reg [N-1:0]                     di_release_stage61;

    // CDC release synchronizer stages
    reg                             sclk_release_stage62;
    reg                             pclk_release_stage62;
    reg                             rst_release_stage62;
    reg                             spi_miso_release_stage62;
    reg                             wren_release_stage62;
    reg [N-1:0]                     di_release_stage62;

    // CDC release synchronizer stages
    reg                             sclk_release_stage63;
    reg                             pclk_release_stage63;
    reg                             rst_release_stage63;
    reg                             spi_miso_release_stage63;
    reg                             wren_release_stage63;
    reg [N-1:0]                     di_release_stage63;

    // CDC release synchronizer stages
    reg                             sclk_release_stage64;
    reg                             pclk_release_stage64;
    reg                             rst_release_stage64;
    reg                             spi_miso_release_stage64;
    reg                             wren_release_stage64;
    reg [N-1:0]                     di_release_stage64;

    // CDC release synchronizer stages
    reg                             sclk_release_stage65;
    reg                             pclk_release_stage65;
    reg                             rst_release_stage65;
    reg                             spi_miso_release_stage65;
    reg                             wren_release_stage65;
    reg [N-1:0]                     di_release_stage65;

    // CDC release synchronizer stages
    reg                             sclk_release_stage66;
    reg                             pclk_release_stage66;
    reg                             rst_release_stage66;
    reg                             spi_miso_release_stage66;
    reg                             wren_release_stage66;
    reg [N-1:0]                     di_release_stage66;

    // CDC release synchronizer stages
    reg                             sclk_release_stage67;
    reg                             pclk_release_stage67;
    reg                             rst_release_stage67;
    reg                             spi_miso_release_stage67;
    reg                             wren_release_stage67;
    reg [N-1:0]                     di_release_stage67;

    // CDC release synchronizer stages
    reg                             sclk_release_stage68;
    reg                             pclk_release_stage68;
    reg                             rst_release_stage68;
    reg                             spi_miso_release_stage68;
    reg                             wren_release_stage68;
    reg [N-1:0]                     di_release_stage68;

    // CDC release synchronizer stages
    reg                             sclk_release_stage69;
    reg                             pclk_release_stage69;
    reg                             rst_release_stage69;
    reg                             spi_miso_release_stage69;
    reg                             wren_release_stage69;
    reg [N-1:0]                     di_release_stage69;

    // CDC release synchronizer stages
    reg                             sclk_release_stage70;
    reg                             pclk_release_stage70;
    reg                             rst_release_stage70;
    reg                             spi_miso_release_stage70;
    reg                             wren_release_stage70;
    reg [N-1:0]                     di_release_stage70;

    // CDC release synchronizer stages
    reg                             sclk_release_stage71;
    reg                             pclk_release_stage71;
    reg                             rst_release_stage71;
    reg                             spi_miso_release_stage71;
    reg                             wren_release_stage71;
    reg [N-1:0]                     di_release_stage71;

    // CDC release synchronizer stages
    reg                             sclk_release_stage72;
    reg                             pclk_release_stage72;
    reg                             rst_release_stage72;
    reg                             spi_miso_release_stage72;
    reg                             wren_release_stage72;
    reg [N-1:0]                     di_release_stage72;

    // CDC release synchronizer stages
    reg                             sclk_release_stage73;
    reg                             pclk_release_stage73;
    reg                             rst_release_stage73;
    reg                             spi_miso_release_stage73;
    reg                             wren_release_stage73;
    reg [N-1:0]                     di_release_stage73;

    // CDC release synchronizer stages
    reg                             sclk_release_stage74;
    reg                             pclk_release_stage74;
    reg                             rst_release_stage74;
    reg                             spi_miso_release_stage74;
    reg                             wren_release_stage74;
    reg [N-1:0]                     di_release_stage74;

    // CDC release synchronizer stages
    reg                             sclk_release_stage75;
    reg                             pclk_release_stage75;
    reg                             rst_release_stage75;
    reg                             spi_miso_release_stage75;
    reg                             wren_release_stage75;
    reg [N-1:0]                     di_release_stage75;

    // CDC release synchronizer stages
    reg                             sclk_release_stage76;
    reg                             pclk_release_stage76;
    reg                             rst_release_stage76;
    reg                             spi_miso_release_stage76;
    reg                             wren_release_stage76;
    reg [N-1:0]                     di_release_stage76;

    // CDC release synchronizer stages
    reg                             sclk_release_stage77;
    reg                             pclk_release_stage77;
    reg                             rst_release_stage77;
    reg                             spi_miso_release_stage77;
    reg                             wren_release_stage77;
    reg [N-1:0]                     di_release_stage77;

    // CDC release synchronizer stages
    reg                             sclk_release_stage78;
    reg                             pclk_release_stage78;
    reg                             rst_release_stage78;
    reg                             spi_miso_release_stage78;
    reg                             wren_release_stage78;
    reg [N-1:0]                     di_release_stage