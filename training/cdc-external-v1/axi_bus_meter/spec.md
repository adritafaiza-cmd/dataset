Implement the SystemVerilog module `axi_bus_meter`.

Per-cycle valid/ready bucket counter for one AXI data channel.

Functional contract and interface notes:

Module: axi_bus_meter
Purpose: Per-cycle valid/ready bucket counter for one AXI data channel.
Used by stream_char to characterize datapath utilization on the
stream engine's read R bus and write W bus.
One instance per AXI bus to be measured. Drop in on the R channel of the
read engine (aggregate + per-channel via rid) and on the W channel of the
write engine (aggregate + per-channel via an engine-side sideband, since
W beats carry no id in AXI4).
Cycle classification (methodology: see DMA_UTILIZATION_MEASUREMENT.md §3):
valid  ready    bucket           meaning
-----  -----    ------           -------
1      1      productive       data delivered
1      0      backpressure     master wants to send, slave stalls
0      1      starvation       slave ready, master not producing
0      0      idle             both sides quiet
Counters:
- Aggregate (32-bit, 4 buckets) -- always increments based on bus state.
Lives 42.9 s at 100 MHz before overflow, plenty for a single run.
- Per-channel (16-bit, 4 buckets, NUM_CHANNELS deep) -- increments the
bucket for `i_channel_id` only when `i_channel_valid` is high. The
caller drives `i_channel_valid` true whenever some channel is on the
hook for the current cycle (e.g. mid-burst). For cycles where the
engine has no work on any channel, leave it low and only aggregate
idle/starvation get attributed.
- Per-channel overflow sticky: NUM_CHANNELS x 4 bits. Each bit is set
when the corresponding 16-bit counter wraps. Software checks this
mask after stopping the meter; if any bit is set, the burst was too
long for 16-bit per-channel resolution (>655 us at 100 MHz) and the
per-channel numbers should be discarded for that channel.
Clearing:
- `i_clear` is a synchronous one-cycle pulse. On clear, all counters
reset to 0 and all overflow stickies clear. Wire to the same control
bit that clears the debug_sram + harness CRC state (so the host gets
atomic reset of the entire measurement substrate from one CSR write).

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axi_bus_meter #(
    parameter int NUM_CHANNELS = 8,
    parameter int CW           = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    input  logic                          aclk,
    input  logic                          aresetn,
    // Synchronous clear pulse (one cycle wide).
    input  logic                          i_clear,
    // Freeze input. When high, every counter and overflow sticky holds
    // its value -- no productive/backpressure/starvation/idle increments,
    // no overflow flag flips. Drive this from the characterization
    // timer's 'done' so the measurement window closes the moment the
    // workload finishes; otherwise the lifetime starvation count drifts
    // upward at one bit per cycle for every cycle of post-burst
    // host-side polling, contaminating the in-window utilization math.
    // Hold low for unbounded free-running measurement.
    input  logic                          i_freeze,
    // AXI bus snoop. For the read engine, wire i_valid=m_axi_rvalid,
    // i_ready=m_axi_rready, i_channel_id=m_axi_rid[CW-1:0], and
    // i_channel_valid=m_axi_rvalid (rid is only meaningful when rvalid).
    // For the write engine, wire i_valid=m_axi_wvalid, i_ready=m_axi_wready,
    // i_channel_id=<engine's r_w_channel_id sideband>, and i_channel_valid
    // to a "W beats in flight on this channel" indicator from the engine.
    input  logic                          i_valid,
    input  logic                          i_ready,
    input  logic [CW-1:0]                 i_channel_id,
    input  logic                          i_channel_valid,
    // Aggregate counters
    output logic [31:0]                   o_agg_productive,
    output logic [31:0]                   o_agg_backpressure,
    output logic [31:0]                   o_agg_starvation,
    output logic [31:0]                   o_agg_idle,
    // Per-channel counters
    output logic [15:0]                   o_ch_productive   [NUM_CHANNELS],
    output logic [15:0]                   o_ch_backpressure [NUM_CHANNELS],
    output logic [15:0]                   o_ch_starvation   [NUM_CHANNELS],
    output logic [15:0]                   o_ch_idle         [NUM_CHANNELS],
    // Per-channel overflow stickies, packed {prod, bp, starv, idle} per channel.
    output logic [NUM_CHANNELS*4-1:0]     o_ch_overflow
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
