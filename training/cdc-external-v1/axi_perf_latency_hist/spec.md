Implement the SystemVerilog module `axi_perf_latency_hist`.

Per-transaction AXI latency histogram (RFC perfmon Stage D).

Functional contract and interface notes:

Module: axi_perf_latency_hist
Purpose: Per-transaction AXI latency histogram (RFC perfmon Stage D).
Captures per-transaction latency on an AXI master bus and bins it into a
log2 histogram, surfaced via CSR-indexed readout (no MonBus packets). This
is a self-contained snoop block (it does NOT gate the AXI path) instantiated
alongside the datapath monitors -- it deliberately leaves the shared
axi_monitor_base untouched.
Metrics:
IS_READ=1 : metric 0 = AR handshake -> first R beat
metric 1 = AR handshake -> RLAST beat
IS_READ=0 : metric 0 = AW handshake -> B response
Transaction matching: AXI requires same-ID responses in order, so a per-
channel (channel = id[CW-1:0]) FIFO of command-phase timestamps matches each
completion to its oldest outstanding command. A single AXI data/response bus
carries at most one beat per cycle, so at most one push and one pop occur per
cycle -- no multi-writer hazard on the shared histogram.
Window control mirrors axi_bus_meter: i_clear (one-cycle pulse on the perf
RUN rising edge) resets the histogram + FIFOs; i_freeze (~RUN) holds the
histogram so a closed window can be read back. The free-running timestamp
counter is NOT frozen so latencies straddling the close boundary stay correct.

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
module axi_perf_latency_hist #(
    parameter int ID_WIDTH        = 8,
    parameter int NUM_CHANNELS    = 8,
    parameter int MAX_OUTSTANDING = 8,      // per-channel timestamp FIFO depth
    parameter int NUM_BINS        = 16,     // log2 bins: bin b counts [2^b, 2^(b+1))
    parameter bit IS_READ         = 1'b1,   // 1 = read (2 metrics), 0 = write (1 metric)
    parameter int CNT_W           = 32,
    // Derived
    parameter int CW   = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1,
    parameter int PW   = (MAX_OUTSTANDING > 1) ? $clog2(MAX_OUTSTANDING) : 1,
    parameter int PW1  = PW + 1,
    parameter int BINW = (NUM_BINS > 1) ? $clog2(NUM_BINS) : 1
) (
    input  logic                 aclk,
    input  logic                 aresetn,
    // Window control (drive from the perf RUN bit, same as axi_bus_meter)
    input  logic                 i_clear,    // one-cycle: reset histogram + FIFOs
    input  logic                 i_freeze,   // hold histogram (counters stop)
    // Command channel (AR for reads, AW for writes)
    input  logic                 cmd_valid,
    input  logic                 cmd_ready,
    input  logic [ID_WIDTH-1:0]  cmd_id,
    // Read data channel (R) -- used when IS_READ=1
    input  logic                 data_valid,
    input  logic                 data_ready,
    input  logic                 data_last,
    input  logic [ID_WIDTH-1:0]  data_id,
    // Write response channel (B) -- used when IS_READ=0
    input  logic                 resp_valid,
    input  logic                 resp_ready,
    input  logic [ID_WIDTH-1:0]  resp_id,
    // CSR-indexed readout
    input  logic                 i_hist_metric,        // 0 or 1 (1 = RLAST, reads only)
    input  logic [BINW-1:0]      i_hist_bin,           // which bin to read
    output logic [CNT_W-1:0]     o_hist_count,         // selected bin count
    output logic [CNT_W-1:0]     o_hist_total,         // selected metric's total txns
    // Backpressure request: the timestamp FIFO for the channel addressed by the
    // CURRENT cmd_id cannot take another entry. Combinational in cmd_id, so a
    // consumer can AND it into the command-channel ready.
    //
    // Without this the module degrades SILENTLY: w_push is qualified on the
    // FIFO having room, so a command that arrives at a full channel handshakes
    // normally and is simply never timestamped. It is missing from o_hist_total
    // and its completion later pops some OTHER command's timestamp, so the
    // surviving latencies are misattributed as well as undercounted -- there is
    // no error, no flag, and nothing in the totals says a sample was lost.
    //
    // This matters most where the histogram is the ONLY instrumentation (the
    // observer in a monitors-off build): the transaction table it sits beside
    // blocks at MAX_TRANSACTIONS across all channels, while this FIFO is
    // MAX_OUTSTANDING PER CHANNEL, so a single channel can be inside the
    // table's limit and past this one.
    //
    // o_cmd_block says a command WOULD be lost; it is high whenever a channel
    // sits at its limit, command or not, so it is a hold-off signal and not a
    // loss count. A consumer that wants to know a sample WAS lost uses
    // o_sample_lost.
    output logic                 o_cmd_block,
    // One-cycle pulse: a command handshook on a full channel inside the
    // measurement window (not frozen) and was not timestamped. This is the loss itself, so a sticky built on it reads
    // clear for a channel that only fills to its limit (a one-channel master
    // running exactly MAX_OUTSTANDING deep sets o_cmd_block on every cycle it
    // is full while losing nothing).
    output logic                 o_sample_lost
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
