Implement the SystemVerilog module `example_sync2`.

Implement example sync2 using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_sync2 instantiation
This example shows how to use the 2-stage flip-flop synchronizer to cross
a single-bit control flag from a 100 MHz source domain to a 200 MHz
destination domain.
Key rule: flag_src must be quasi-static (stable for >> 1 dst clock cycle).
For pulsed signals, use cdc_pulse_sync instead.

Required clock and reset behavior:

- Clock ports: clk_100m, clk_200m.
- Reset ports: rst_100m_n, rst_200m_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_sync2: cdc_sync2 #( .RESET_VAL (1'b0) ) u_flag_sync ( .clk_dst (clk_200m), .rst_dst_n (rst_200m_n), .data_src (flag_src), .data_dst (flag_dst) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_sync2 (
    input  logic clk_100m,    // 100 MHz source clock
    input  logic rst_100m_n,  // Source domain reset
    input  logic flag_src,    // Flag generated in 100 MHz domain
    input  logic clk_200m,    // 200 MHz destination clock
    input  logic rst_200m_n,  // Destination domain reset
    output logic flag_dst     // Flag synchronized to 200 MHz domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
