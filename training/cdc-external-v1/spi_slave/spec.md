Implement the SystemVerilog module `spi_slave`.

SPI Slave IP top level RTL

Functional contract and interface notes:

Description: SPI Slave IP top level RTL
Only mode 0 is supported.
Only free running sclk may supported. For gated clock, work around may required.
Change log
08/09/2021
11/19/2021 Remove tristate buffer.

Required clock and reset behavior:

- Clock ports: sclk, avmm_clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_rstnsync: spi_rstnsync sclk_rstnsync ( .clk(sclk), .i_rst_n(rst_n), .scan_mode(1'b0), .sync_rst_n(rst_n_sclk) );
- spi_rstnsync: spi_rstnsync aclk_rstnsync ( .clk(avmm_clk), .i_rst_n(rst_n), .scan_mode(1'b0), .sync_rst_n(rst_n_avmm) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module spi_slave #(
    parameter BUF_SIZE = 256,
    parameter BUF_ADWIDTH = $clog2(BUF_SIZE)
)(
    //System interface
    input                 rst_n,      //System reset
    //SPI interface
    input                 sclk,       //Free running SPI clock out 
    input                 ss_n,
    input                 mosi,
    output                miso,
    //avalon interface
    input                 avmm_clk,   //Free running clock
    //avalon interface 0
    output [16:0]         avmm0_addr,
    output [3:0]          avmm0_byte_en, //Expect this to be 4'f since design is word based
    output                avmm0_write,
    output                avmm0_read,
    output [31:0]         avmm0_wdata,
    input                 avmm0_rdatavld,
    input  [31:0]         avmm0_rdata,
    input                 avmm0_waitreq,
    //avalon interface 1
    output [16:0]         avmm1_addr,
    output [3:0]          avmm1_byte_en, //Expect this to be 4'f since design is word based
    output                avmm1_write,
    output                avmm1_read,
    output [31:0]         avmm1_wdata,
    input                 avmm1_rdatavld,
    input  [31:0]         avmm1_rdata,
    input                 avmm1_waitreq,
    //avalon interface 2
    output [16:0]         avmm2_addr,
    output [3:0]          avmm2_byte_en, //Expect this to be 4'f since design is word based
    output                avmm2_write,
    output                avmm2_read,
    output [31:0]         avmm2_wdata,
    input                 avmm2_rdatavld,
    input  [31:0]         avmm2_rdata,
    input                 avmm2_waitreq
    
    //Optional Interrupt port. Can connect to GPIO if necessary
//  output                spi_inta
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
