Implement the SystemVerilog module `axis4_master_injector`.

AXI-Stream master that emits a deterministic, PER-CHANNEL LFSR data

Functional contract and interface notes:

Module: axis4_master_injector
Purpose: AXI-Stream master that emits a deterministic, PER-CHANNEL LFSR data
pattern for characterization/verification. This is the AXIS SINK
stimulus for the RAPIDS characterization harness and is
pattern/CRC-CONSISTENT with axi4_slave_rd_injector /
axi4_slave_wr_crc_check: the per-channel 32-bit CRC-32 it computes
is bit-identical to what axi4_slave_wr_crc_check produces for the
same emitted stream (sink self-check: axis_gen -> m_axi_wr ->
wr_crc_check).
Description:
On cfg_start the block streams cfg_num_beats beats PER CHANNEL for every
channel selected in cfg_channel_mask (mask == 0 => all NUM_CHANNELS active),
scheduled sequentially (finish one channel, then the next) so each
channel's LFSR sequence is contiguous -- or, with cfg_interleave set,
round-robin beat by beat across the active channels so every active
channel holds data in the DUT at once (the aggregate-window case). Each
channel N maintains an
independent LFSR seeded (seed ^ N) -- IDENTICAL to axi4_slave_rd_injector
-- and its own dataint_crc-32 instance. Each beat:
- m_axis_tid   = channel index
- m_axis_tdata = {REP{lfsr_out[ch]}}  (32-bit LFSR replicated to fill bus)
- the active channel's LFSR + CRC advance on the accepted beat only
- tlast asserted every cfg_beats_per_pkt beats (0 => tlast on each
channel's final beat only), and always on each channel's final beat.
Because the LFSR advances only on accepted beats, beat N of channel C is a
deterministic function of (seed ^ C, N), independent of tready stalls and
of the scheduling mode: the per-channel data, CRC and packet boundaries
are identical in sequential and interleaved runs; only the order in which
channels take the bus differs.
The per-channel expected CRC is exported continuously (o_expected_crc[ch],
o_expected_crc_valid[ch]) mirroring axi4_slave_rd_injector's
read_crc_value / read_crc_valid semantics -- NOT the old XOR-fold signature.
CRC bit-consistency (copied VERBATIM from the axi4 blocks):
- shifter_lfsr_fibonacci #(WIDTH=32, TAP_INDEX_WIDTH=12, TAP_COUNT=4),
seed_data = (seed ^ ch), enable = (accepted-beat-for-ch || load),
seed_load = load.
- dataint_crc #(DATA_WIDTH=32, CRC_WIDTH=32, REFIN=1, REFOUT=1) with
POLY=0x04C11DB7, POLY_INIT=0xFFFFFFFF, XOROUT=0xFFFFFFFF,
cascade_sel=4'b1000, data=lfsr_out[ch], load_crc_start=load,
load_from_cascade=accepted-beat-for-ch.
Notes:
- AXIS_DATA_WIDTH must be a multiple of LFSR_WIDTH (tdata = REP x lfsr_out).
- No address channel (pure stream): simpler than the AXI4 pattern gen.

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
module axis4_master_injector #(
    parameter int          NUM_CHANNELS     = 1,
    parameter int          AXIS_DATA_WIDTH  = 512,
    parameter int          AXIS_ID_WIDTH    = 8,
    parameter int          AXIS_DEST_WIDTH  = 4,
    parameter int          AXIS_USER_WIDTH  = 1,
    // LFSR parameters (32-bit fixed; MUST MATCH axi4_slave_rd_injector!)
    parameter int          LFSR_WIDTH       = 32,
    parameter logic [31:0] LFSR_SEED        = 32'hDEADBEEF,
    parameter logic [47:0] LFSR_TAPS        = {12'd23, 12'd3, 12'd2, 12'd1},
    // CRC parameters (fixed; MUST MATCH axi4_slave_rd_injector /
    // axi4_slave_wr_crc_check!)
    parameter int          CRC_WIDTH        = 32,
    parameter int          CRC_DATA_WIDTH   = 32,   // process 32-bit LFSR output only
    parameter logic [31:0] CRC_POLY         = 32'h04C11DB7,  // CRC-32 Ethernet
    parameter logic [31:0] CRC_INIT         = 32'hFFFFFFFF,
    parameter logic [31:0] CRC_XOROUT       = 32'hFFFFFFFF,
    parameter int          CRC_REFIN        = 1,
    parameter int          CRC_REFOUT       = 1,
    parameter int          BEAT_COUNT_WIDTH = 32,
    // Derived
    parameter int          STRB_WIDTH       = AXIS_DATA_WIDTH / 8,
    parameter int          REP              = AXIS_DATA_WIDTH / LFSR_WIDTH,
    parameter int          CIW              = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    input  logic                          clk,
    input  logic                          rst_n,
    // Configuration / control
    input  logic                          cfg_start,          // pulse: begin a run
    input  logic [LFSR_WIDTH-1:0]         cfg_lfsr_seed,      // 0 => use LFSR_SEED param
    input  logic [NUM_CHANNELS-1:0]       cfg_channel_mask,   // active channels (0 => all)
    input  logic [BEAT_COUNT_WIDTH-1:0]   cfg_num_beats,      // beats to send PER CHANNEL
    input  logic [BEAT_COUNT_WIDTH-1:0]   cfg_beats_per_pkt,  // tlast cadence (0 => 1 pkt/channel)
    input  logic                          cfg_interleave,     // 1: round-robin active channels per beat
    input  logic [AXIS_DEST_WIDTH-1:0]    cfg_tdest,
    // Byte-granular packets (rapids TASK-019): bytes strobed on every tlast
    // beat, contiguous from lane 0. 0 (or >= STRB_WIDTH) keeps every lane,
    // which is the beat-granular behaviour.
    input  logic [7:0]                    cfg_last_bytes,
    output logic                          cfg_busy,
    output logic                          cfg_done,           // 1-cycle pulse at end of run
    // Per-channel expected CRC (mirrors axi4_slave_rd_injector.read_crc_value)
    output logic [NUM_CHANNELS-1:0][31:0] o_expected_crc,
    output logic [NUM_CHANNELS-1:0]       o_expected_crc_valid,
    output logic [NUM_CHANNELS-1:0][31:0] o_beat_count,       // per-channel beats emitted
    output logic [31:0]                   o_beat_count_total, // sum across channels
    // AXI-Stream master
    output logic                          m_axis_tvalid,
    input  logic                          m_axis_tready,
    output logic [AXIS_DATA_WIDTH-1:0]    m_axis_tdata,
    output logic [STRB_WIDTH-1:0]         m_axis_tstrb,
    output logic                          m_axis_tlast,
    output logic [AXIS_ID_WIDTH-1:0]      m_axis_tid,
    output logic [AXIS_DEST_WIDTH-1:0]    m_axis_tdest,
    output logic [AXIS_USER_WIDTH-1:0]    m_axis_tuser
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
