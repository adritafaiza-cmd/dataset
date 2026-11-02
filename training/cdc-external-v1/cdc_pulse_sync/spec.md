Implement the SystemVerilog module `cdc_pulse_sync`.

//   Pulse synchronizer for crossing a single-cycle pulse from the source

Functional contract and interface notes:

Module  : cdc_pulse_sync
Language: SystemVerilog
Description:
Pulse synchronizer for crossing a single-cycle pulse from the source
clock domain to the destination clock domain.
CDC Principle (Toggle-Based Pulse Synchronization):
A single-cycle pulse may be shorter than one destination clock period and
could be invisible to a simple synchronizer. This module uses a three-step
toggle-based approach:
Step 1 – Pulse-to-Toggle (source domain):
A flip-flop toggles on each input pulse, converting the short pulse to
a persistent level change that cannot be missed by the synchronizer.
Step 2 – 2-Stage Synchronization:
The toggle signal is synchronized to the destination domain using a
standard 2-stage flip-flop chain, eliminating metastability.
Step 3 – Toggle-to-Pulse (destination domain):
An XOR of the current and previous synchronized toggle detects each
toggle edge and regenerates a single-cycle pulse in the destination domain.
Safety:
- Safe because only a persistent toggle (not the original pulse) crosses
the clock boundary.
- Pulses must be separated by at least the round-trip synchronization
latency: approximately 4 destination clock cycles (2 sync + 1 edge
detect + 1 margin) to prevent pulse merging.
Use Cases:
- Crossing a single-cycle strobe or trigger between clock domains
- Interrupt signals between clock domains
- Event notification across clock domain boundaries
Limitations:
- Minimum inter-pulse spacing: ~4 destination clock cycles; pulses closer
together may be lost.
- 2–3 destination clock cycles of latency.
- Does not detect pulse loss (no overflow flag).
Timing Assumptions:
- One pulse in = one pulse out, assuming minimum spacing is met.
- Does not preserve data associated with the pulse (use cdc_data_sync for
data transfer).
Example Instantiation:
cdc_pulse_sync u_pulse_sync (
.clk_src   (clk_src),
.rst_src_n (rst_src_n),
.pulse_src (strobe_src),
.clk_dst   (clk_dst),
.rst_dst_n (rst_dst_n),
.pulse_dst (strobe_dst)
);

Required clock and reset behavior:

- Clock ports: clk_src, clk_dst.
- Reset ports: rst_src_n, rst_dst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_pulse_sync (
    // Source domain
    input  logic clk_src,    // Source domain clock
    input  logic rst_src_n,  // Source domain reset (active low)
    input  logic pulse_src,  // Single-cycle input pulse in source domain
    // Destination domain
    input  logic clk_dst,    // Destination domain clock
    input  logic rst_dst_n,  // Destination domain reset (active low)
    output logic pulse_dst   // Single-cycle output pulse in destination domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
