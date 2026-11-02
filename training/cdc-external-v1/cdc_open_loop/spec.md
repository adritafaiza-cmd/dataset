Implement the SystemVerilog module `cdc_open_loop`.

Open-loop multi-bit CDC using valid/data stretching.

Functional contract and interface notes:

Module: cdc_open_loop
Purpose: Open-loop multi-bit CDC using valid/data stretching.
The source asserts src_valid for one cycle. The module captures the data
and stretches the valid signal for STRETCH_CYCLES source clock cycles,
holding data stable throughout. A multi-stage synchronizer in the
destination domain samples the stretched valid and latches the data on
the rising edge.
The source data bus must remain stable long enough for the
synchronized enable to propagate through the destination sync
chain and load the destination register. That gives:
STRETCH_CYCLES >= ceil((SYNC_STAGES + 1) * T_dst / T_src)
where T_dst and T_src are the destination and source clock
periods. (SYNC_STAGES + 1) counts the sync FFs plus the load edge.
Example: a 1 GHz source crossing to 100 MHz with SYNC_STAGES=2
needs STRETCH_CYCLES >= ceil(3 * 10/1) = 30. The 1.5*T_dst rule of
thumb is enough to capture the valid pulse alone, but the multi-bit
data bus needs the longer hold so r_src_data is still stable when
the destination latches it.
This is a true open-loop design: no return path, no handshake, no
backpressure. The source is busy for exactly STRETCH_CYCLES and then
free to send again. If the destination misses the stretched valid
(because STRETCH_CYCLES is too short), the transfer is silently lost.
Use when:
- Clock ratio is known and fixed (or bounded)
- Destination is always ready (no flow control needed)
- Minimum area/complexity is desired
- Config registers, status updates, infrequent events
For unknown/variable clock ratios, use cdc_2_phase_handshake (closed-loop).
For streaming data, use fifo_async or gaxi_fifo_async.
REQUIRED SDC CONSTRAINTS
# 1. Stretched valid (single-bit, synchronized by destination)
set_max_delay -datapath_only \
-from [get_pins u_cdc/r_src_valid_stretch_reg/C] \
-to   [get_pins u_cdc/u_valid_sync/q_reg[0]/D] \
<dst_period_ns>
# 2. Data bus (quasi-static, held for STRETCH_CYCLES src clocks)
set_max_delay -datapath_only \
-from [get_pins u_cdc/r_src_data_reg[*]/C] \
-to   [get_pins u_cdc/r_dst_data_reg[*]/D] \
<dst_period_ns>

Required clock and reset behavior:

- Clock ports: clk_src, clk_dst.
- Reset ports: rst_src_n, rst_dst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (SYNC_STAGES), .WIDTH (1) ) u_valid_sync ( .clk (clk_dst), .rst_n (rst_dst_n), .d (r_src_valid_stretch), .q (w_valid_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_open_loop #(
    parameter int DATA_WIDTH     = 8,    // Width of the data bus
    parameter int STRETCH_CYCLES = 8,    // Source clocks to hold valid+data (manual default)
    parameter int SYNC_STAGES    = 2,    // Destination synchronizer depth (2-4)
    // ---- Auto-compute STRETCH_CYCLES from clock periods (opt-in) ----
    //
    // The destination needs at least (SYNC_STAGES + 1) dst-clock periods
    // to safely capture a stretched pulse. Required hold time:
    //
    //     STRETCH * src_period >= (SYNC_STAGES + 1) * dst_period
    //
    // Solved for STRETCH:
    //
    //     STRETCH = ceil((SYNC_STAGES + 1) * SRC_CLK_HZ / DST_CLK_HZ)
    //
    // To turn this on, set AUTO_STRETCH = 1 and provide SRC_CLK_HZ (the
    // FASTEST source clock you want handled safely; sources above this
    // start dropping pulses) and DST_CLK_HZ. When AUTO_STRETCH = 0
    // (default), the STRETCH_CYCLES parameter above is used verbatim —
    // no breaking change for existing callers.
    parameter int AUTO_STRETCH = 0,   // 0 = use STRETCH_CYCLES; 1 = auto-compute
    parameter int SRC_CLK_HZ   = 25_000_000,
    parameter int DST_CLK_HZ   = 100_000_000
) (
    // Source clock domain
    input  logic                  clk_src,      // Source domain clock
    input  logic                  rst_src_n,    // Source domain async reset (active low)
    input  logic                  src_valid,    // Single-cycle pulse: data is valid NOW
    input  logic [DATA_WIDTH-1:0] src_data,     // Data from source domain
    output logic                  src_busy,     // High during stretch (blocks next valid)
    // Destination clock domain
    input  logic                  clk_dst,      // Destination domain clock
    input  logic                  rst_dst_n,    // Destination domain async reset (active low)
    output logic                  dst_valid,    // Single-cycle pulse: data latched
    output logic [DATA_WIDTH-1:0] dst_data      // Latched data (stable until next dst_valid)
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
