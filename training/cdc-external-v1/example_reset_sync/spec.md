Implement the SystemVerilog module `example_reset_sync`.

Implement example reset sync using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_reset_sync instantiation
This example distributes a single power-on reset (POR) to three independent
clock domains. Each domain gets its own reset synchronizer so that each
domain's flip-flops exit reset synchronously with their own clock.
unpredictable times, leading to glitches or X-propagation during simulation.

Required clock and reset behavior:

- Clock ports: clk_100m, clk_200m, clk_50m.
- Reset ports: por_rst_n, rst_100m_n, rst_200m_n, rst_50m_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_reset_sync: cdc_reset_sync #(.SYNC_STAGES(2)) u_rst_100m ( .clk (clk_100m), .rst_async_n (por_rst_n), .rst_sync_n (rst_100m_n) );
- cdc_reset_sync: cdc_reset_sync #(.SYNC_STAGES(3)) u_rst_200m ( .clk (clk_200m), .rst_async_n (por_rst_n), .rst_sync_n (rst_200m_n) );
- cdc_reset_sync: cdc_reset_sync #(.SYNC_STAGES(2)) u_rst_50m ( .clk (clk_50m), .rst_async_n (por_rst_n), .rst_sync_n (rst_50m_n) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_reset_sync (
    input  logic por_rst_n,     // Asynchronous power-on reset (active low)
    input  logic clk_100m,      // 100 MHz clock domain
    output logic rst_100m_n,    // Synchronized reset for 100 MHz domain
    input  logic clk_200m,      // 200 MHz clock domain
    output logic rst_200m_n,    // Synchronized reset for 200 MHz domain
    input  logic clk_50m,       // 50 MHz clock domain
    output logic rst_50m_n      // Synchronized reset for 50 MHz domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
