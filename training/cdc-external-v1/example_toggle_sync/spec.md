Implement the SystemVerilog module `example_toggle_sync`.

Implement example toggle sync using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_toggle_sync instantiation
This example uses the toggle synchronizer to signal a "packet received"
event from a 25 MHz MAC clock domain to a 100 MHz CPU clock domain.
The MAC toggles rx_event_toggle once per received packet. The toggle
synchronizer detects each edge and generates a single-cycle pulse in the
CPU domain to trigger processing.

Required clock and reset behavior:

- Clock ports: clk_mac, clk_cpu.
- Reset ports: rst_mac_n, rst_cpu_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_toggle_sync: cdc_toggle_sync u_rx_sync ( .clk_dst (clk_cpu), .rst_dst_n (rst_cpu_n), .toggle_src (rx_event_toggle), .toggle_dst (rx_toggle_sync), .pulse_dst (rx_pulse_cpu) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_toggle_sync (
    input  logic clk_mac,        // 25 MHz MAC clock
    input  logic rst_mac_n,
    input  logic rx_event_toggle, // Toggled in MAC domain on each packet received
    input  logic clk_cpu,         // 100 MHz CPU clock
    input  logic rst_cpu_n,
    output logic rx_toggle_sync,  // Synchronized toggle output
    output logic rx_pulse_cpu     // 1-cycle pulse in CPU domain per packet
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
