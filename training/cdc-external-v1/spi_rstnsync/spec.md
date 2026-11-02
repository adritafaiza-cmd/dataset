Implement the SystemVerilog module `spi_rstnsync`.

For rst_n, asynchronously assertion and sychronously de-assertion (AASD)

Functional contract and interface notes:

Description: For rst_n, asynchronously assertion and sychronously de-assertion (AASD)
Assumptions: i_rst_n is assumed to be bypassed with scan_clk during scan_mode

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: i_rst_n, sync_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_bitsync: spi_bitsync #(.DWIDTH(1), .RESET_VAL(0) ) i_sync_rst_n ( .clk (clk ), .rst_n (i_rst_n ), .data_in (first_stg_rst_n ), .data_out (prescan_sync_rst_n) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module spi_rstnsync
  (
    input  logic clk,		// Destination clock of reset to be synced
    input  logic i_rst_n,        // Asynchronous reset input
    input  logic	scan_mode,	// Scan bypass for reset
    output logic sync_rst_n	// Synchronized reset output
   
   );
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
