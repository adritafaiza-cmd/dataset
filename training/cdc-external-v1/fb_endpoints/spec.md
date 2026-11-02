Implement the SystemVerilog module `fb_endpoints`.

The fabric benchmark's LFSR source (S2) and CRC sink (S3) on their

Functional contract and interface notes:

Module: fb_endpoints
Purpose: The fabric benchmark's LFSR source (S2) and CRC sink (S3) on their
own clock, behind CDC crossings, with their verdicts brought back.
(DE10 PRD sections 4.1 and 5.3: fabric-only mode, clocks)
Description:
Two slave ports on the FABRIC clock (aclk): s_rd_* is the LFSR source
window, s_wr_* the CRC sink window. Each crosses into the ENDPOINT clock
(ep_clk) through its own axi4_cdc_{rd,wr}, where one axi4_dma_slaves --
the same source/sink the Genesys 2 STREAM harness uses -- answers both.
Nothing here knows which fabric is upstream; both legs see this block
unchanged.
Why a separate clock: the endpoints accept a beat every cycle, and on a
clock at least as fast as the fabric's they cannot be what limits a run.
The slave-side observers sit on the s_* ports, upstream of the crossings,
so the crossings and endpoints fall out of the fabric's measured latency.
Status back to aclk. The CRCs and beat counts live in ep_clk. They return
as ONE coherent snapshot through cdc_2_phase_handshake, resent
continuously: the aclk side only ever sees a complete bundle, never a mix
of an old CRC and a new count. The cost is a lag of a few cycles of both
clocks per update -- identical in every leg, and outside the measurement
(the observers do the timing; the harness timer only stops the run).
The clear pulse goes the other way through sync_pulse. A clear issued
while beats are in flight is the host's error, as in the STREAM harness.
Parameters:
NUM_CHANNELS   - STREAM channels (1..8)
CH_SEL_ADDR    - 1 (default): a burst's channel is its address bits
[CH_ADDR_LSB +: log2(NUM_CHANNELS)] -- every leg, because
SmartConnect (leg B2) carries no ID to its slaves and the
endpoints must be identical in all legs. 0: the low ID
bits, as in the STREAM harness.
CH_ADDR_LSB    - with CH_SEL_ADDR: each channel's window is 2^CH_ADDR_LSB
bytes (default 16: channel N at window base + N * 64 KB);
the host places each channel's buffers in its own window
AXI_ID_WIDTH   - slave-side ID width ({fabric slot, master id} on legs A and
B1, 0-valued on B2); unused for channel selection by address
AXI_DATA_WIDTH - fabric data width
CDC_DEPTH      - async FIFO depth per AXI channel; 16 sustains a beat per
cycle with the synchronizer round trip in flight
LFSR_SEED      - source seed (channel N uses LFSR_SEED ^ N); identical in
every leg -- the legs are compared on the same data
Related Modules:
axi4_dma_slaves, axi4_cdc_rd, axi4_cdc_wr, cdc_2_phase_handshake, sync_pulse

Required clock and reset behavior:

- Clock ports: aclk, ep_clk.
- Reset ports: aresetn, ep_aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- sync_pulse: sync_pulse u_clear_sync ( .i_src_clk(aclk), .i_src_rst_n(aresetn), .i_pulse(i_clear), .i_dst_clk(ep_clk), .i_dst_rst_n(ep_aresetn), .o_pulse(w_ep_clear) );
- cdc_2_phase_handshake: cdc_2_phase_handshake #( .DATA_WIDTH(SNAP_W) ) u_status ( .clk_src(ep_clk), .rst_src_n(ep_aresetn), .src_valid(1'b1), .src_ready(), .src_data(w_snap_src), .src_timeout(), .clk_dst(aclk), .rst_dst_n(aresetn), .dst_valid(w_snap_dst_valid), .dst_ready(1'b1), .dst_data(w_snap_dst) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module fb_endpoints #(
    parameter int          NUM_CHANNELS   = 8,
    parameter int          AXI_ID_WIDTH   = 10,
    parameter int          AXI_ADDR_WIDTH = 32,
    parameter int          AXI_DATA_WIDTH = 128,
    parameter int          CDC_DEPTH      = 16,
    parameter logic [31:0] LFSR_SEED      = 32'hDEADBEEF,
    parameter bit          CH_SEL_ADDR    = 1'b1,
    parameter int          CH_ADDR_LSB    = 16,
    // Short params
    parameter int IW = AXI_ID_WIDTH,
    parameter int AW = AXI_ADDR_WIDTH,
    parameter int DW = AXI_DATA_WIDTH,
    parameter int SW = DW / 8,
    parameter int NC = NUM_CHANNELS
) (
    // Fabric clock: the slave ports and every status output
    input  logic              aclk,
    input  logic              aresetn,
    // Endpoint clock
    input  logic              ep_clk,
    input  logic              ep_aresetn,
    // Clear both CRCs and beat counts (aclk pulse)
    input  logic              i_clear,
    // S2: LFSR source (read only)
    input  logic [IW-1:0]     s_rd_arid,
    input  logic [AW-1:0]     s_rd_araddr,
    input  logic [7:0]        s_rd_arlen,
    input  logic [2:0]        s_rd_arsize,
    input  logic [1:0]        s_rd_arburst,
    input  logic              s_rd_arlock,
    input  logic [3:0]        s_rd_arcache,
    input  logic [2:0]        s_rd_arprot,
    input  logic [3:0]        s_rd_arqos,
    input  logic              s_rd_arvalid,
    output logic              s_rd_arready,
    output logic [IW-1:0]     s_rd_rid,
    output logic [DW-1:0]     s_rd_rdata,
    output logic [1:0]        s_rd_rresp,
    output logic              s_rd_rlast,
    output logic              s_rd_rvalid,
    input  logic              s_rd_rready,
    // S3: CRC sink (write only)
    input  logic [IW-1:0]     s_wr_awid,
    input  logic [AW-1:0]     s_wr_awaddr,
    input  logic [7:0]        s_wr_awlen,
    input  logic [2:0]        s_wr_awsize,
    input  logic [1:0]        s_wr_awburst,
    input  logic              s_wr_awlock,
    input  logic [3:0]        s_wr_awcache,
    input  logic [2:0]        s_wr_awprot,
    input  logic [3:0]        s_wr_awqos,
    input  logic              s_wr_awvalid,
    output logic              s_wr_awready,
    input  logic [DW-1:0]     s_wr_wdata,
    input  logic [SW-1:0]     s_wr_wstrb,
    input  logic              s_wr_wlast,
    input  logic              s_wr_wvalid,
    output logic              s_wr_wready,
    output logic [IW-1:0]     s_wr_bid,
    output logic [1:0]        s_wr_bresp,
    output logic              s_wr_bvalid,
    input  logic              s_wr_bready,
    // Verdicts, aclk domain (one coherent snapshot, refreshed continuously)
    output logic [NC-1:0][31:0] o_read_crc_value,
    output logic [NC-1:0]       o_read_crc_valid,
    output logic [31:0]         o_read_beat_count,
    output logic [NC-1:0][31:0] o_write_crc_value,
    output logic [NC-1:0]       o_write_crc_valid,
    output logic [31:0]         o_write_beat_count
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
