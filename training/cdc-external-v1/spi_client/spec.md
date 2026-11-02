Implement the SystemVerilog module `spi_client`.

Implement the declared SPI client interface and transfer requests into the internal clock domain through the clock-barrier synchronizers.

Functional contract and interface notes:

We do not use an enable signal for the SPI client, as that enable signal would be clocked on the
internal clock domain, causing issues with the logic that is clocked on the external SPI clock.
Instead what we do is, send out a in_idle signal via a separate wire. When this signal is high,
the SPI server knows that the SPI client will respond. When this signal is low, the SPI server
should not drive the external clock nor the MOSI line.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_async, rst.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_clock_barrier_crossing: spi_clock_barrier_crossing spi_clock_barrier_crossing_inst ( .clk(clk), .rst(rst), .enable_configuration(enable_configuration), .MOSI_data_ready(MOSI_data_ready), .load_MISO_data(load_MISO_data), .write_new(write_new), .read_sync(read_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module spi_client #(
    parameter integer MESSAGE_BIT_WIDTH = 32,
    parameter integer CODE_BIT_WIDTH = 4,
    parameter integer START_ADDRESS_BIT_WIDTH = 16,
    localparam integer NumTransactionsBitWidth = MESSAGE_BIT_WIDTH - CODE_BIT_WIDTH - START_ADDRESS_BIT_WIDTH - 1
) (
    input rst_async,
    input  SCK,
    output MISO,
    input  MOSI,
    input clk,
    input rst,
    input enable_configuration,
    output [CODE_BIT_WIDTH-1:0] code,
    output reg [START_ADDRESS_BIT_WIDTH-1:0] current_address,
    input [MESSAGE_BIT_WIDTH-1:0] MISO_data,
    output reg [MESSAGE_BIT_WIDTH-1:0] MOSI_data,
    output config_data_ready,
    output [START_ADDRESS_BIT_WIDTH-1:0] current_config_address,
    output [MESSAGE_BIT_WIDTH-1:0] config_data,
    output write_new,
    output read_sync
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
