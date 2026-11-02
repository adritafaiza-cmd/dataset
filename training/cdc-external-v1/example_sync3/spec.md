Implement the SystemVerilog module `example_sync3`.

Implement example sync3 using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_sync3 instantiation
This example shows the 3-stage synchronizer for a high-frequency (500 MHz)
design where additional metastability resolution time is needed.
The extra FF stage provides ~e^(Tclk/tau) more metastability rejection
compared to cdc_sync2, at the cost of one additional cycle of latency.

Required clock and reset behavior:

- Clock ports: clk_src, clk_500m.
- Reset ports: rst_src_n, rst_500m_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_sync3: cdc_sync3 #( .RESET_VAL (1'b0) ) u_status_sync ( .clk_dst (clk_500m), .rst_dst_n (rst_500m_n), .data_src (status_src), .data_dst (status_dst) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_sync3 (
    input  logic clk_src,    // Source clock (e.g., 250 MHz)
    input  logic rst_src_n,
    input  logic status_src, // Slow-moving status bit in source domain
    input  logic clk_500m,   // 500 MHz destination clock
    input  logic rst_500m_n,
    output logic status_dst  // Status synchronized to 500 MHz domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
