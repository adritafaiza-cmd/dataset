Implement the SystemVerilog module `axis4_slave_pattern_check`.

AXI-Stream slave that checks a deterministic, PER-CHANNEL LFSR data

Functional contract and interface notes:

Module: axis4_slave_pattern_check
Purpose: AXI-Stream slave that checks a deterministic, PER-CHANNEL LFSR data
pattern. This is the AXIS SOURCE checker for the RAPIDS
characterization harness and is pattern/CRC-CONSISTENT with
axi4_slave_rd_injector: the per-channel 32-bit CRC-32 it computes
is bit-identical to axi4_slave_rd_injector.read_crc_value for the
same stream (source self-check: rd_gen -> m_axis -> axis_check).
Description:
On cfg_start every channel's LFSR is seeded identically to the generator
(seed ^ ch). Incoming beats are DEMUXed by s_axis_tid[CIW-1:0] into the
matching channel context. On each accepted beat for channel ch:
- the received tdata is compared against the locally-regenerated pattern
{REP{lfsr_out[ch]}}; any mismatch latches o_data_error (sticky);
- that channel's LFSR + dataint_crc-32 advance (fed the 32-bit
lfsr_out[ch], exactly like axi4_slave_rd_injector).
The LFSR advances only on accepted beats, so the check is independent of
upstream stalls / interleave order across channels.
Per-channel CRC (o_actual_crc[ch]/o_actual_crc_valid[ch]) mirrors
axi4_slave_rd_injector.read_crc_value semantics -- NOT the old XOR-fold.
CRC bit-consistency (copied VERBATIM from the axi4 blocks): identical LFSR
(WIDTH=32, TAP_INDEX_WIDTH=12, TAP_COUNT=4, seed ^ ch) + identical
dataint_crc (DATA_WIDTH=32, CRC_WIDTH=32, POLY=0x04C11DB7,
POLY_INIT=0xFFFFFFFF, XOROUT=0xFFFFFFFF, REFIN=1, REFOUT=1,
cascade_sel=4'b1000, data=lfsr_out[ch]) with the same gating
(load_crc_start=cfg_start, load_from_cascade=accepted-beat-for-ch).
Notes:
- AXIS_DATA_WIDTH must be a multiple of LFSR_WIDTH.
- s_axis_tready = ready_en (pure sink; deassert to model backpressure).

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (clk), .rst_n (rst_n), .sync_rst_n (w_rst_n) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axis4_slave_pattern_check #(
    parameter int          NUM_CHANNELS     = 1,
    parameter int          AXIS_DATA_WIDTH  = 512,
    parameter int          AXIS_ID_WIDTH    = 8,
    parameter int          AXIS_DEST_WIDTH  = 4,
    parameter int          AXIS_USER_WIDTH  = 1,
    // LFSR parameters (32-bit fixed; MUST MATCH axi4_slave_rd_injector!)
    parameter int          LFSR_WIDTH       = 32,
    parameter logic [31:0] LFSR_SEED        = 32'hDEADBEEF,
    parameter logic [47:0] LFSR_TAPS        = {12'd23, 12'd3, 12'd2, 12'd1},
    // CRC parameters (fixed; MUST MATCH axi4_slave_rd_injector!)
    parameter int          CRC_WIDTH        = 32,
    parameter int          CRC_DATA_WIDTH   = 32,
    parameter logic [31:0] CRC_POLY         = 32'h04C11DB7,
    parameter logic [31:0] CRC_INIT         = 32'hFFFFFFFF,
    parameter logic [31:0] CRC_XOROUT       = 32'hFFFFFFFF,
    parameter int          CRC_REFIN        = 1,
    parameter int          CRC_REFOUT       = 1,
    parameter int          BEAT_COUNT_WIDTH = 32,
    // BYTE_CRC=1 (byte-granular RAPIDS, rapids TASK-019): the per-channel CRC
    // runs over the strobed bytes of every beat, four per cycle through
    // cascade_sel, with tready held low while a beat is fed; the word compare
    // is replaced by a tstrb-contiguity check. 0: the LFSR word CRC + compare.
    parameter bit          BYTE_CRC         = 1'b0,
    // Derived
    parameter int          STRB_WIDTH       = AXIS_DATA_WIDTH / 8,
    parameter int          REP              = AXIS_DATA_WIDTH / LFSR_WIDTH,
    parameter int          CIW              = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    input  logic                          clk,
    input  logic                          rst_n,
    // Configuration / control
    input  logic                          cfg_start,          // pulse: arm + seed all channels
    input  logic [LFSR_WIDTH-1:0]         cfg_lfsr_seed,      // 0 => use LFSR_SEED param
    input  logic                          ready_en,           // s_axis_tready = ready_en
    // Per-channel actual CRC (mirrors axi4_slave_rd_injector.read_crc_value)
    output logic [NUM_CHANNELS-1:0][31:0] o_actual_crc,
    output logic [NUM_CHANNELS-1:0]       o_actual_crc_valid,
    output logic                          o_data_error,       // sticky: any beat mismatch
    output logic [NUM_CHANNELS-1:0][31:0] o_beat_count,       // per-channel beats received
    output logic [31:0]                   o_beat_count_total, // sum across channels
    output logic [BEAT_COUNT_WIDTH-1:0]   o_pkt_count,        // tlast beats received (aggregate)
    // AXI-Stream slave
    input  logic                          s_axis_tvalid,
    output logic                          s_axis_tready,
    input  logic [AXIS_DATA_WIDTH-1:0]    s_axis_tdata,
    input  logic [STRB_WIDTH-1:0]         s_axis_tstrb,
    input  logic                          s_axis_tlast,
    input  logic [AXIS_ID_WIDTH-1:0]      s_axis_tid,
    input  logic [AXIS_DEST_WIDTH-1:0]    s_axis_tdest,
    input  logic [AXIS_USER_WIDTH-1:0]    s_axis_tuser
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
