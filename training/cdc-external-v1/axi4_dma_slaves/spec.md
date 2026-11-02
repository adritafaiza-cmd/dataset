Implement the SystemVerilog module `axi4_dma_slaves`.

Synthetic AXI4 slave pair for DMA / streaming engine

Functional contract and interface notes:

Module: axi4_dma_slaves
Purpose: Synthetic AXI4 slave pair for DMA / streaming engine
characterization. Combines:
- axi4_slave_rd_injector     (AR/R: synthetic LFSR data source)
- axi4_slave_wr_crc_check    (AW/W/B: CRC-checking sink)
into one block that an AXI master can plug into for
Use case: stream_char_harness instantiates this on STREAM's
m_axi_rd / m_axi_wr to characterize DMA throughput, response
delay sweeps, CRC end-to-end integrity, etc.
CRC config (poly / init / xorout / refin / refout) is shared
across both sides on purpose -- the master writes back the same
LFSR data it read, so both sides compute against the same CRC.
LFSR config affects only the read side (pattern generation).
The two reset inputs are kept separate so the harness can clear
the read LFSR and the write CRC independently if it wants to
being driven from the same CSR clear pulse in practice.

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn, read_lfsr_reset, write_crc_reset.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module axi4_dma_slaves #(
    parameter int NUM_CHANNELS   = 1,
    parameter int AXI_ID_WIDTH   = 8,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_USER_WIDTH = 1,
    // Skid depths -- per-side
    parameter int SKID_DEPTH_AR  = 2,
    parameter int SKID_DEPTH_R   = 4,
    parameter int SKID_DEPTH_AW  = 2,
    parameter int SKID_DEPTH_W   = 4,
    parameter int SKID_DEPTH_B   = 2,
    // LFSR configuration (read side only)
    parameter int LFSR_WIDTH = 32,
    parameter logic [31:0] LFSR_SEED = 32'hDEADBEEF,
    parameter logic [47:0] LFSR_TAPS = {12'd23, 12'd3, 12'd2, 12'd1},
    // CRC configuration (shared across both sides)
    parameter int CRC_WIDTH      = 32,
    parameter int CRC_DATA_WIDTH = 32,
    parameter logic [31:0] CRC_POLY    = 32'h04C11DB7,
    parameter logic [31:0] CRC_INIT    = 32'hFFFFFFFF,
    parameter logic [31:0] CRC_XOROUT  = 32'hFFFFFFFF,
    parameter int CRC_REFIN  = 1,
    parameter int CRC_REFOUT = 1,
    // Replication factor for the read-side pattern generator
    parameter int REPLICATION_FACTOR = (AXI_DATA_WIDTH + 31) / 32,
    // Slice offset for the write-side CRC accumulator
    parameter int CRC_SLICE_OFFSET = 0,
    // Channel select, both sides (see axi4_slave_rd_injector): 0 = low ID
    // bits, 1 = address bits [CH_ADDR_LSB +: CIW]
    parameter bit CH_SEL_ADDR = 1'b0,
    parameter int CH_ADDR_LSB = 16,
    parameter int CIW = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1
) (
    input  logic                          aclk,
    input  logic                          aresetn,
    // ---------------------------------------------------------------
    // Resets (separate so each side can be re-armed independently).
    // Typically driven by the same CSR clear pulse in practice.
    // ---------------------------------------------------------------
    input  logic                          read_lfsr_reset,
    input  logic                          write_crc_reset,
    // ---------------------------------------------------------------
    // Per-channel CRC + beat-count observation (read side)
    // ---------------------------------------------------------------
    output logic [NUM_CHANNELS-1:0][31:0] read_crc_value,
    output logic [NUM_CHANNELS-1:0]       read_crc_valid,
    output logic [NUM_CHANNELS-1:0][31:0] read_beat_count,
    output logic [31:0]                   read_beat_count_total,
    // ---------------------------------------------------------------
    // Per-channel CRC + beat-count observation (write side)
    // ---------------------------------------------------------------
    output logic [NUM_CHANNELS-1:0][31:0] write_crc_value,
    output logic [NUM_CHANNELS-1:0]       write_crc_valid,
    output logic [NUM_CHANNELS-1:0][31:0] write_beat_count,
    output logic [31:0]                   write_beat_count_total,
    // ---------------------------------------------------------------
    // AXI4 read slave (AR + R)
    // ---------------------------------------------------------------
    input  logic [AXI_ID_WIDTH-1:0]       s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  logic [7:0]                    s_axi_arlen,
    input  logic [2:0]                    s_axi_arsize,
    input  logic [1:0]                    s_axi_arburst,
    input  logic                          s_axi_arlock,
    input  logic [3:0]                    s_axi_arcache,
    input  logic [2:0]                    s_axi_arprot,
    input  logic [3:0]                    s_axi_arqos,
    input  logic [3:0]                    s_axi_arregion,
    input  logic [AXI_USER_WIDTH-1:0]     s_axi_aruser,
    input  logic                          s_axi_arvalid,
    output logic                          s_axi_arready,
    output logic [AXI_ID_WIDTH-1:0]       s_axi_rid,
    output logic [AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output logic [1:0]                    s_axi_rresp,
    output logic                          s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]     s_axi_ruser,
    output logic                          s_axi_rvalid,
    input  logic                          s_axi_rready,
    // ---------------------------------------------------------------
    // AXI4 write slave (AW + W + B)
    // ---------------------------------------------------------------
    input  logic [AXI_ID_WIDTH-1:0]       s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  logic [7:0]                    s_axi_awlen,
    input  logic [2:0]                    s_axi_awsize,
    input  logic [1:0]                    s_axi_awburst,
    input  logic                          s_axi_awlock,
    input  logic [3:0]                    s_axi_awcache,
    input  logic [2:0]                    s_axi_awprot,
    input  logic [3:0]                    s_axi_awqos,
    input  logic [3:0]                    s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]     s_axi_awuser,
    input  logic                          s_axi_awvalid,
    output logic                          s_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0]   s_axi_wstrb,
    input  logic                          s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]     s_axi_wuser,
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,
    output logic [AXI_ID_WIDTH-1:0]       s_axi_bid,
    output logic [1:0]                    s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]     s_axi_buser,
    output logic                          s_axi_bvalid,
    input  logic                          s_axi_bready,
    // ---------------------------------------------------------------
    // Per-side busy status (handy for harness-level stop triggers).
    // ---------------------------------------------------------------
    output logic                          busy_rd,
    output logic                          busy_wr
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
