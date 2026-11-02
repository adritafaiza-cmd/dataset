Implement the SystemVerilog module `example_pulse_sync`.

Implement example pulse sync using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_pulse_sync instantiation
This example crosses a single-cycle interrupt strobe from a 125 MHz CPU
clock domain to a 50 MHz peripheral clock domain.
The pulse synchronizer uses toggle-based encoding so the pulse cannot be
missed, even if the source clock is faster than the destination clock.
Limitation: consecutive pulses must be separated by at least ~4 destination
clock cycles (80 ns at 50 MHz). For bursts, use a FIFO instead.

Required clock and reset behavior:

- Clock ports: clk_cpu, clk_periph.
- Reset ports: rst_cpu_n, rst_periph_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_pulse_sync: cdc_pulse_sync u_irq_sync ( .clk_src (clk_cpu), .rst_src_n (rst_cpu_n), .pulse_src (irq_pulse), .clk_dst (clk_periph), .rst_dst_n (rst_periph_n), .pulse_dst (irq_periph) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_pulse_sync (
    input  logic clk_cpu,      // 125 MHz CPU clock
    input  logic rst_cpu_n,
    input  logic irq_pulse,    // 1-cycle interrupt pulse in CPU domain
    input  logic clk_periph,   // 50 MHz peripheral clock
    input  logic rst_periph_n,
    output logic irq_periph    // 1-cycle interrupt pulse in peripheral domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
