Implement the SystemVerilog module `sync_pulse`.

//   Safe pulse synchronizer for crossing clock domains. Converts a single-

Functional contract and interface notes:

Module: sync_pulse
Purpose: //   Safe pulse synchronizer for crossing clock domains. Converts a single-
Module: sync_pulse
Description:
Safe pulse synchronizer for crossing clock domains. Converts a single-
cycle pulse in the source clock domain to a single-cycle pulse in the
destination clock domain using a toggle-based handshake. Guarantees no
pulse loss for source pulses separated by at least 3 destination clock
cycles.
Features:
- Metastability-safe using 3-stage synchronizer
- No pulse loss (if minimum spacing met)
- Single-cycle output pulse in destination domain
- Handles arbitrary clock frequency ratios
- Minimal logic footprint
Parameters:
SYNC_STAGES:
Description: Number of synchronizer stages for metastability filtering
Type: int
Range: 2 to 4
Default: 3
Constraints: SYNC_STAGES=2 (minimum), SYNC_STAGES=3 (recommended)
Higher stages INCREASE MTBF (more settling time per stage)
at the cost of one extra destination clock of latency each.
See the Timing section below, which has this right.
Ports:
Source Clock Domain:
i_src_clk:    Source clock (where input pulse originates)
i_src_rst_n:  Source domain active-low reset
i_pulse:      Input pulse (must be single-cycle high)
Destination Clock Domain:
i_dst_clk:    Destination clock (where output pulse appears)
i_dst_rst_n:  Destination domain active-low reset
o_pulse:      Synchronized output pulse (single-cycle high)
Timing:
Latency:         ~SYNC_STAGES destination clocks to the pulse edge; the
edge detector is combinational (o_pulse = r_sync[N-1] ^
r_sync_prev), so it adds no stage. (SYNC_STAGES + 2) is a
conservative bound, not the true edge latency.
Min Pulse Gap:   3*T_dst + 2*T_src (see spacing requirement below)
MTBF:            increases with SYNC_STAGES; a real figure needs the flop's
metastability tau/T0, the dst clock, and the event rate --
it is not a fixed hours constant.
Protocol:
1. Source pulse toggles r_src_toggle register
2. Toggle is synchronized to destination clock domain
3. Edge detector generates single-cycle pulse in destination domain
(NOTE: this module is one-way -- there is no reverse synchronizer, no
ready/o_ready port, and no destination-to-source feedback path.)
Source pulse spacing requirement:
- Minimum spacing = 3*T_dst + 2*T_src (clock periods)
- For continuous pulses, check o_pulse spacing in destination domain
Safety:
- ASYNC_REG attribute on synchronizer prevents optimization
- Metastability filtered by multi-stage synchronizer
- No combinational paths between clock domains
- Safe for arbitrary clock frequency ratios
Usage Example:
sync_pulse #(
.SYNC_STAGES(3)
) u_sync_pulse (
.i_src_clk      (btn_clk),
.i_src_rst_n    (sys_rst_n),
.i_pulse        (button_press_pulse),
.i_dst_clk      (disp_clk),
.i_dst_rst_n    (sys_rst_n),
.o_pulse        (button_press_sync)
);
Related Modules:
- reset_sync.sv: For reset synchronization
- edge_detect.sv: For edge-to-pulse conversion
Notes:
- Input pulse MUST be single-cycle high in source domain
- For multi-cycle signals, use edge detector first
- Ensure resets are properly synchronized in both domains
- Use XDC constraints: set_false_path between clock domains
References:
- Cummings, Clifford E. "Clock Domain Crossing (CDC) Design &
Verification Techniques Using SystemVerilog." SNUG 2008.
- "Synthesis and Scripting Techniques for Designing Multi-Asynchronous
Clock Designs." Xilinx WP275.

Required clock and reset behavior:

- Clock ports: i_src_clk, i_dst_clk.
- Reset ports: i_src_rst_n, i_dst_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module sync_pulse #(
    parameter int SYNC_STAGES = 3    // Synchronizer depth (2-4)
) (
    // Source clock domain
    input  logic i_src_clk,
    input  logic i_src_rst_n,
    input  logic i_pulse,
    // Destination clock domain
    input  logic i_dst_clk,
    input  logic i_dst_rst_n,
    output logic o_pulse
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
