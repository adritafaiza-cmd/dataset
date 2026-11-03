Please act as a professional Verilog designer.

Implement an SPI master with a parallel-side word interface.

sclk_i and pclk_i are independent clocks. Please take care of any clock-domain crossings between them. The reset is active-high.

Send accepted parallel words over SPI and return received words when complete. Keep the serial interface idle after reset.

Revised behavior (benchmark v2):
di_req_o indicates that the previous request/response handshake has returned to idle and a new word can be accepted. wr_ack_o pulses on acceptance; do_valid_o pulses once per completed word. Extra turnaround latency is permitted. Do not duplicate serial transactions.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

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
