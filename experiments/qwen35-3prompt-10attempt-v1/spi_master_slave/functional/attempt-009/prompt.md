Please act as a professional Verilog designer.

Implement an SPI master with a parallel-side word interface.

Module name:
    spi_master

Language:
    Verilog-2001

Clocks:
    sclk_i: Independent asynchronous clock (async to pclk_i).
    pclk_i: Independent asynchronous clock (async to sclk_i).

Resets:
    rst_i: active-high.

Input ports:
    sclk_i: Clock.
    pclk_i: Clock.
    rst_i: Active-high reset.
    spi_miso_i: See Behavior.
    di_i: See Behavior.
    wren_i: See Behavior.

Output ports:
    spi_ssel_o: See Behavior.
    spi_sck_o: See Behavior.
    spi_mosi_o: See Behavior.
    di_req_o: See Behavior.
    wr_ack_o: See Behavior.
    do_valid_o: Handshake valid.
    do_o: See Behavior.

Parameters:
    N: Implementation depth or word width, as used by the module.
    SPI_2X_CLK_DIV: See Behavior.

Behavior:
    - The testbench instantiates spi_master.
    - Accept N-bit words on di_i when wren_i is high; wr_ack_o acknowledges the write.
    - Shift the word out on spi_mosi_o with spi_sck_o and spi_ssel_o.
    - Capture spi_miso_i and present it on do_o with do_valid_o.
    - di_req_o requests the next word.
    - After reset, selects are inactive and outputs are idle.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
