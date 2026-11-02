Implement the SystemVerilog module `spi_master`.

SPI master IP top level RTL

Functional contract and interface notes:

Description: SPI master IP top level RTL
Only mode 0 is supported.
Only free running sclk may supported. For gated clock, work around may required.
Change log
08/09/2021
11/19/2021 Add seperate misos so that it is easier for debugging if pins are available

Required clock and reset behavior:

- Clock ports: spi_clk_in, sclk, avmm_clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_rstnsync: spi_rstnsync sclk_rstnsync ( .clk(sclk), .i_rst_n(rst_n), .scan_mode(1'b0), .sync_rst_n(rst_n_sclk) );
- spi_rstnsync: spi_rstnsync aclk_rstnsync ( .clk(avmm_clk), .i_rst_n(rst_n), .scan_mode(1'b0), .sync_rst_n(rst_n_avmm) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module spi_master #(
    parameter BUF_SIZE = 512,
    parameter BUF_ADWIDTH = $clog2(BUF_SIZE),
    parameter SS_WIDTH = 4
)(
    //System interface
    input                 spi_clk_in, //Free running clock
    input                 rst_n,      //System reset
    //SPI interface
    output                sclk,       //Free running SPI clock out 
    output [SS_WIDTH-1:0] ss_n,
    output                mosi,
    input  [SS_WIDTH-1:0] miso,
    //avalon interface
    input                 avmm_clk,   //Free running clock
    input [16:0]          avmm_addr,
    input [3:0]           avmm_byte_en, //Expect this to be 4'f since design is word based
    input                 avmm_write,
    input                 avmm_read,
    input [31:0]          avmm_wdata,
    output                avmm_rdatavld,
    output [31:0]         avmm_rdata,
    output                avmm_waitreq,
    //Optional Interrupt port. Can connect to GPIO if necessary
    output                spi_inta
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
