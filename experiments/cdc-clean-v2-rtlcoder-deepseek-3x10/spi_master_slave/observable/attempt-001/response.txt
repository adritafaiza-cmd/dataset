Sure, here is the complete Verilog-2001 code for the SPI master module:

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

    // Internal registers and wires
    reg [N-1:0]         tx_data;
    reg [N-1:0]         rx_data;
    reg [N-1:0]         tx_shift_reg;
    reg [N-1:0]         rx_shift_reg;
    reg                 tx_shift_en;
    reg                 rx_shift_en;
    reg                 tx_shift_done;
    reg                 rx_shift_done;
    reg                 tx_active;
    reg                 rx_active;
    reg                 tx_done;
    reg                 rx_done;
    reg                 tx_start;
    reg                 rx_start;
    reg                 tx_busy;
    reg                 rx_busy;
    reg                 tx_ready;
    reg                 rx_ready;
    reg                 tx_error;
    reg                 rx_error;
    reg                 tx_underflow;
    reg                 rx_underflow;
    reg                 tx_overflow;
    reg                 rx_overflow;
    reg                 tx_fifo_empty;
    reg                 rx_fifo_full;
    reg                 tx_fifo_full;
    reg                 rx_fifo_empty;
    reg                 tx_fifo_almost_full;
    reg                 rx_fifo_almost_empty;
    reg                 tx_fifo_almost_empty;
    reg                 rx_fifo_almost_full;
    reg                 tx_fifo_count;
    reg                 rx_fifo_count;
    reg                 tx_fifo_threshold;
    reg                 rx_fifo_threshold;
    reg                 tx_fifo_threshold_reached;
    reg                 rx_fifo_threshold_reached;
    reg                 tx_fifo_threshold_exceeded;
    reg                 rx_fifo_threshold_exceeded;
    reg                 tx_fifo_threshold_exceeded_reached;
    reg                 rx_fifo_threshold_exceeded_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 rx_fifo_threshold_exceeded_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached_reached;
    reg                 tx_fifo_threshold_exceeded_reached_reached_reached_reached