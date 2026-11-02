Implement the SystemVerilog module `axi4_slave_wr_crc_check`.

//   AXI4 write-only slave that computes CRC-32 on received data for DMA

Functional contract and interface notes:

Module: axi4_slave_wr_crc_check
Protocol handling: the AXI channel logic is the standard `axi4_slave_wr`
protocol module (instantiated below), with the pattern / CRC logic on its
fub_axi_* user interface. Remaining TODO (task #79): move to the
monitored `axi4_slave_wr_mon` variant.
Description:
AXI4 write-only slave that computes CRC-32 on received data for DMA
validation. Combines axi4_slave_wr protocol handler with CRC checker.
Per-channel mode (NUM_CHANNELS > 1): the slave maintains independent
CRC state per channel, demuxed off the low bits of the W-side wuser
(which the STREAM master drives with the burst's channel index). The
AW FSM accepts one burst at a time and W beats are in-order with AW,
so the channel captured with the AW is the active channel during W: the
low CIW bits of awid, or awaddr[CH_ADDR_LSB +: CIW] when CH_SEL_ADDR = 1.
Per-channel outputs:
write_crc_value [NUM_CHANNELS][31:0] - per-channel CRC values
write_crc_valid [NUM_CHANNELS]       - per-channel valid flags
write_beat_count[NUM_CHANNELS][31:0] - per-channel beat counts
Aggregate output (for harness timer):
write_beat_count_total [31:0]        - sum of per-channel beat counts

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn, crc_reset.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axi4_slave_wr_crc_check #(
    // AXI parameters
    parameter int NUM_CHANNELS  = 1,
    parameter int SKID_DEPTH_AW = 2,
    parameter int SKID_DEPTH_W  = 4,
    parameter int SKID_DEPTH_B  = 2,
    parameter int AXI_ID_WIDTH  = 8,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_USER_WIDTH = 1,
    // CRC parameters (MUST MATCH axi4_slave_rd_injector!)
    parameter int CRC_WIDTH      = 32,
    parameter int CRC_DATA_WIDTH = 32,
    parameter logic [31:0] CRC_POLY    = 32'h04C11DB7,
    parameter logic [31:0] CRC_INIT    = 32'hFFFFFFFF,
    parameter logic [31:0] CRC_XOROUT  = 32'hFFFFFFFF,
    parameter int CRC_REFIN  = 1,
    parameter int CRC_REFOUT = 1,
    // Which 32-bit slice to CRC from AXI_DATA_WIDTH
    parameter int CRC_SLICE_OFFSET = 0,
    // BYTE_CRC=1 (byte-granular RAPIDS, rapids TASK-019): the per-channel CRC
    // runs over the STROBED bytes of every W beat in lane order, four per
    // cycle through cascade_sel, with wready held low while a beat is fed.
    // 0: the CRC_SLICE_OFFSET 32-bit slice of every beat (STREAM's harness).
    parameter bit BYTE_CRC = 1'b0,
    // Channel select. 0 (default): the channel is the low CIW bits of the
    // burst's ID (AR/AW), as every harness built so far drives it.
    // 1: the channel is the burst's address bits [CH_ADDR_LSB +: CIW] -- for a
    // fabric that does not carry the master's ID to its slaves (SmartConnect's
    // MI ID width is 0). Each channel then owns a 2^CH_ADDR_LSB-byte window;
    // the windows never overlap and a burst never crosses one (AXI bursts stop
    // at 4 KB, so CH_ADDR_LSB >= 12). CH_ADDR_LSB + CIW <= AXI_ADDR_WIDTH.
    parameter bit CH_SEL_ADDR = 1'b0,
    parameter int CH_ADDR_LSB = 16,
    // ERR_INJECT=1 (rapids TASK-020) builds the B-response error injector:
    // a chosen burst on a chosen channel answers cfg_err_resp instead of
    // OKAY, so a DUT's write-error path can be reached from a harness.
    // 0 (default) elaborates none of it and holds BRESP at OKAY -- the block
    // is then identical to its pre-TASK-020 behaviour, which is what
    // STREAM's and the RAPIDS-beats harnesses keep using.
    parameter bit ERR_INJECT = 1'b0,
    // Derived
    parameter int CIW = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    // Global Clock and Reset
    input  logic                        aclk,
    input  logic                        aresetn,
    // Test Control
    input  logic                        crc_reset,
    // Per-channel CRC and Status Outputs
    output logic [NUM_CHANNELS-1:0][31:0] write_crc_value,
    output logic [NUM_CHANNELS-1:0]       write_crc_valid,
    output logic [NUM_CHANNELS-1:0][31:0] write_beat_count,
    // Aggregate beat count (sum across channels) for the harness stop trigger.
    output logic [31:0]                   write_beat_count_total,
    // AXI4 Slave Interface (Write-Only)
    // Write address channel (AW)
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  logic [7:0]                  s_axi_awlen,
    input  logic [2:0]                  s_axi_awsize,
    input  logic [1:0]                  s_axi_awburst,
    input  logic                        s_axi_awlock,
    input  logic [3:0]                  s_axi_awcache,
    input  logic [2:0]                  s_axi_awprot,
    input  logic [3:0]                  s_axi_awqos,
    input  logic [3:0]                  s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_awuser,
    input  logic                        s_axi_awvalid,
    output logic                        s_axi_awready,
    // Write data channel (W)
    input  logic [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                        s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_wuser,
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,
    // Write response channel (B)
    output logic [AXI_ID_WIDTH-1:0]     s_axi_bid,
    output logic [1:0]                  s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_buser,
    output logic                        s_axi_bvalid,
    input  logic                        s_axi_bready,
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
