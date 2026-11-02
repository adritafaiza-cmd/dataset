Implement the SystemVerilog module `mspi_intf`.

Implement mspi intf using the interface and behavioral contract below.

Functional contract and interface notes:

This module handle SPI bus side interface:
Receive command from AVMM domain register.
Receive control info from AVMM domain register (skew/delay for this static info enforced by SDC)
Generate counter to shifting out miso from tx buffer and shifting in mosi to rx buffer
Only SPI mode 0 is supported. SCLK is free running.

Required clock and reset behavior:

- Clock ports: avmm_clk, rst_n_sclk, sclk.
- Reset ports: rst_n_avmm, rst_n_sclk.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_bitsync: spi_bitsync #(.DWIDTH(32)) bitsync2_cmd_reg ( .clk (sclk), .rst_n (rst_n_sclk), .data_in (cmd_reg[31:0]), .data_out (cmd_reg_sync[31:0]) );
- spi_bitsync: spi_bitsync sync_req_aclk ( .clk (avmm_clk), .rst_n (rst_n_avmm), .data_in (cdc_req), .data_out (cdc_req_aclk) );
- spi_bitsync: spi_bitsync sync_req_sclk ( .clk (sclk), .rst_n (rst_n_sclk), .data_in (cdc_req_aclk), .data_out (cdc_ack_sclk) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module mspi_intf
#(
    parameter SS_WIDTH = 4,
    parameter BUF_SIZE = 256,
    parameter BUF_ADWIDTH = $clog2(BUF_SIZE)
)(
//To TX/RX Buffer
output reg [31:0]            rx_buf_wdata,
output reg                   rx_buf_we,
output reg [BUF_ADWIDTH-1:0] rx_buf_waddr,
output reg [BUF_ADWIDTH-1:0] tx_buf_raddr,
input  [31:0]                tx_buf_rdata,
output                       spi_active,
//Contro from CSR
input                        avmm_clk,
input                        rst_n_avmm,
input  [31:0]                cmd_reg,    //From avmm clock domain
//SPI interface signal
input                        rst_n_sclk,
input                        sclk,       //Free running SPI clock out
output reg [SS_WIDTH-1:0]    ss_n,
output reg                   mosi,
input      [SS_WIDTH-1:0]    miso
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
