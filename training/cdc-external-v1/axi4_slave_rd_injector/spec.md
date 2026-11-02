Implement the SystemVerilog module `axi4_slave_rd_injector`.

//   AXI4 read-only slave that generates pseudo-random patterns using LFSR

Functional contract and interface notes:

Module: axi4_slave_rd_injector
Protocol handling: the AXI channel logic is the standard `axi4_slave_rd`
protocol module (instantiated below), with the pattern / CRC logic on its
fub_axi_* user interface. Remaining TODO (task #78): move to the
monitored `axi4_slave_rd_mon` variant.
Description:
AXI4 read-only slave that generates pseudo-random patterns using LFSR
and computes CRC-32 for DMA validation. Combines axi4_slave_rd protocol
handler with LFSR pattern generator and CRC checker.
Per-channel mode (NUM_CHANNELS > 1): the slave maintains independent
LFSR + CRC state per channel, demuxed off the low bits of s_axi_arid,
or off s_axi_araddr[CH_ADDR_LSB +: CIW] when CH_SEL_ADDR = 1.
This makes the data each channel reads back independent of any other
channel's traffic, so a multi-channel test can verify integrity per
the running CRC.
Parameters:
NUM_CHANNELS   - Number of independent LFSR/CRC contexts (default: 1)
SKID_DEPTH_AR  - AR channel skid buffer depth (default: 2)
SKID_DEPTH_R   - R channel skid buffer depth (default: 4)
AXI_ID_WIDTH   - AXI ID width (default: 8). Channel index is extracted
from arid[CIW-1:0] where CIW = $clog2(NUM_CHANNELS).
AXI_ADDR_WIDTH - AXI address width (default: 32)
AXI_DATA_WIDTH - AXI data width (default: 64, can be wider)
AXI_USER_WIDTH - AXI user signal width (default: 1)
LFSR_SEED      - Base LFSR seed; channel N uses (LFSR_SEED ^ N) so
each channel generates a distinct pseudo-random stream
Per-channel outputs:
read_crc_value [NUM_CHANNELS][31:0]  - per-channel CRC values
read_crc_valid [NUM_CHANNELS]        - per-channel valid flags
read_beat_count[NUM_CHANNELS][31:0]  - per-channel beat counts
Aggregate output (for harness timer):
read_beat_count_total [31:0]         - sum of per-channel beat counts

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn, crc_lfsr_reset.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axi4_slave_rd_injector #(
    // AXI parameters
    parameter int NUM_CHANNELS  = 1,
    parameter int SKID_DEPTH_AR = 2,
    parameter int SKID_DEPTH_R  = 4,
    parameter int AXI_ID_WIDTH  = 8,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_USER_WIDTH = 1,
    // LFSR parameters (32-bit fixed for simplicity and timing)
    parameter int LFSR_WIDTH = 32,
    parameter logic [31:0] LFSR_SEED = 32'hDEADBEEF,
    parameter logic [47:0] LFSR_TAPS = {12'd23, 12'd3, 12'd2, 12'd1},  // Maximal length
    // CRC parameters (fixed, MUST MATCH axi4_slave_wr_crc_check!)
    parameter int CRC_WIDTH      = 32,
    parameter int CRC_DATA_WIDTH = 32,  // Process 32-bit LFSR output only
    parameter logic [31:0] CRC_POLY    = 32'h04C11DB7,  // CRC-32 Ethernet
    parameter logic [31:0] CRC_INIT    = 32'hFFFFFFFF,
    parameter logic [31:0] CRC_XOROUT  = 32'hFFFFFFFF,
    parameter int CRC_REFIN  = 1,
    parameter int CRC_REFOUT = 1,
    // Derived parameters
    parameter int REPLICATION_FACTOR = (AXI_DATA_WIDTH + 31) / 32,
    parameter int CIW = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1,
    // Channel select. 0 (default): the channel is the low CIW bits of the
    // burst's ID (AR/AW), as every harness built so far drives it.
    // 1: the channel is the burst's address bits [CH_ADDR_LSB +: CIW] -- for a
    // fabric that does not carry the master's ID to its slaves (SmartConnect's
    // MI ID width is 0). Each channel then owns a 2^CH_ADDR_LSB-byte window;
    // the windows never overlap and a burst never crosses one (AXI bursts stop
    // at 4 KB, so CH_ADDR_LSB >= 12). CH_ADDR_LSB + CIW <= AXI_ADDR_WIDTH.
    parameter bit CH_SEL_ADDR = 1'b0,
    parameter int CH_ADDR_LSB = 16,
    // ERR_INJECT=1 (rapids TASK-020) builds the R-response error injector:
    // every beat of a chosen burst on a chosen channel answers cfg_err_resp
    // instead of OKAY, so a DUT's read-error path can be reached from a
    // harness. 0 (default) elaborates none of it and holds RRESP at OKAY --
    // identical to the pre-TASK-020 block, which is what STREAM's and the
    // RAPIDS-beats harnesses keep using.
    parameter bit ERR_INJECT = 1'b0
) (
    // Global Clock and Reset
    input  logic                        aclk,
    input  logic                        aresetn,
    // Test Control (from UART controller or test logic)
    input  logic                        crc_lfsr_reset,  // Pulse to reset LFSR and CRC
    // Per-channel CRC and Status Outputs
    output logic [NUM_CHANNELS-1:0][31:0] read_crc_value,
    output logic [NUM_CHANNELS-1:0]       read_crc_valid,
    output logic [NUM_CHANNELS-1:0][31:0] read_beat_count,
    // Aggregate beat count (sum across channels) for the harness stop trigger.
    output logic [31:0]                   read_beat_count_total,
    // AXI4 Slave Interface (Read-Only)
    // Read address channel (AR)
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  logic [7:0]                  s_axi_arlen,
    input  logic [2:0]                  s_axi_arsize,
    input  logic [1:0]                  s_axi_arburst,
    input  logic                        s_axi_arlock,
    input  logic [3:0]                  s_axi_arcache,
    input  logic [2:0]                  s_axi_arprot,
    input  logic [3:0]                  s_axi_arqos,
    input  logic [3:0]                  s_axi_arregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_aruser,
    input  logic                        s_axi_arvalid,
    output logic                        s_axi_arready,
    // Read data channel (R)
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
    output logic [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]                  s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_ruser,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,
    // Error-response injection config (rapids TASK-020).
    // Inert unless ERR_INJECT=1; tie off at 0 otherwise.
    input  logic                        cfg_err_enable,
    input  logic [CIW-1:0]              cfg_err_channel,
    input  logic [15:0]                 cfg_err_skip,
    input  logic [1:0]                  cfg_err_resp,
    input  logic                        cfg_err_oneshot,
    output logic                        err_injected,
    // Status Output
    output logic                        busy
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
