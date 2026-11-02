Implement the SystemVerilog module `axis_bus_meter`.

Per-cycle valid/ready bucket counter + byte/packet counters for one

Functional contract and interface notes:

Module: axis_bus_meter
Purpose: Per-cycle valid/ready bucket counter + byte/packet counters for one
AXI-Stream (AXIS) channel. The AXIS analogue of axi_bus_meter: same
4-bucket cycle classification, plus AXIS-native throughput counters
(bytes via tstrb, packets via tlast) that are WINDOW-INDEPENDENT.
One instance per AXIS bus to be measured. Snoop tvalid/tready/tlast/tstrb/tid;
the block is a pure observer (drives nothing back onto the bus).
Cycle classification (identical to axi_bus_meter; see
DMA_UTILIZATION_MEASUREMENT.md §3):
valid  ready    bucket           meaning
-----  -----    ------           -------
1      1      productive       beat transferred
1      0      backpressure     master wants to send, slave stalls
0      1      starvation       slave ready, master not producing
0      0      idle             both sides quiet
AXIS-native counters (increment ONLY on a productive beat, valid&ready):
- o_agg_bytes   : += popcount(tstrb) each productive beat. This is the exact
number of payload bytes moved, independent of how long the
measurement window is held open -- so throughput =
bytes / (busy_time) is robust to backpressure/idle padding
that would distort a pure cycle-utilization figure.
- o_agg_beats   : += 1 each productive beat (== o_agg_productive; provided
for convenience alongside bytes/packets).
- o_agg_packets : += 1 each productive beat with tlast (stream packets).
Counters:
- Aggregate cycle buckets: 32-bit (42.9 s @ 100 MHz before wrap).
- Aggregate bytes: 64-bit (won't wrap in any realistic run).
- Aggregate beats/packets: 32-bit.
- Per-channel (by tid) cycle buckets: 16-bit x NUM_CHANNELS, with a
per-channel 4-bit overflow sticky (see axi_bus_meter for semantics).
Control:
- i_clear  : synchronous one-cycle pulse; zeroes every counter + sticky.
- i_freeze : hold high to freeze the window (no counter moves). Drive from
the characterization window controller.

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
module axis_bus_meter #(
    parameter int DATA_WIDTH   = 512,
    parameter int NUM_CHANNELS = 8,
    parameter int TID_WIDTH    = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1,
    parameter int SW           = DATA_WIDTH / 8,                    // tstrb width
    parameter int CW           = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    input  logic                      aclk,
    input  logic                      aresetn,
    // Synchronous clear pulse (one cycle wide).
    input  logic                      i_clear,
    // Freeze: hold high to close the measurement window.
    input  logic                      i_freeze,
    // AXIS bus snoop. tid selects the per-channel bin (its low CW bits); for a
    // single-stream bus tie tid=0. tstrb counts payload bytes; if the stream has
    // no tstrb, tie it all-ones so bytes == beats * (DATA_WIDTH/8).
    input  logic                      i_tvalid,
    input  logic                      i_tready,
    input  logic                      i_tlast,
    input  logic [SW-1:0]             i_tstrb,
    input  logic [TID_WIDTH-1:0]      i_tid,
    // Aggregate cycle buckets
    output logic [31:0]               o_agg_productive,
    output logic [31:0]               o_agg_backpressure,
    output logic [31:0]               o_agg_starvation,
    output logic [31:0]               o_agg_idle,
    // Aggregate AXIS-native throughput counters (productive beats only)
    output logic [63:0]               o_agg_bytes,
    output logic [31:0]               o_agg_beats,
    output logic [31:0]               o_agg_packets,
    // Per-channel (by tid) cycle buckets
    output logic [15:0]               o_ch_productive   [NUM_CHANNELS],
    output logic [15:0]               o_ch_backpressure [NUM_CHANNELS],
    output logic [15:0]               o_ch_starvation   [NUM_CHANNELS],
    output logic [15:0]               o_ch_idle         [NUM_CHANNELS],
    // Per-channel overflow stickies, packed {prod, bp, starv, idle} per channel.
    output logic [NUM_CHANNELS*4-1:0] o_ch_overflow
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
