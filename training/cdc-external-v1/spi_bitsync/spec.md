Implement the SystemVerilog module `spi_bitsync`.

Implement spi bitsync using the interface and behavioral contract below.

Functional contract and interface notes:

Standard bit/multi-bit synchronizer.
User may need to replace this module with technology library synchronizer.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module spi_bitsync
  #(
    parameter DWIDTH = 1'b1,    // Sync Data input
    parameter RESET_VAL = 1'b0  // Reset value
    )
    (
    input  logic              clk,     // clock
    input  logic              rst_n,   // async reset
    input  logic [DWIDTH-1:0] data_in, // data in
    output logic [DWIDTH-1:0] data_out // data out
     );
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
