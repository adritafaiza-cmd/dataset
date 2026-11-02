Implement the SystemVerilog module `bch_encoder_axi4`.

Binary BCH encoder as an AXI4 memory-to-memory job engine.

Functional contract and interface notes:

Module: bch_encoder_axi4
Description: Binary BCH encoder as an AXI4 memory-to-memory job engine.
The AXI4 counterpart to bch_encoder_axis4: a job names a source address,
a destination address and a BLOCK COUNT, and the block reads k data bits
per block, encodes, and writes the n-bit codewords out.
bch_axi4_read_engine feeds the core and bch_axi4_write_engine drains it,
both on the one AXI4 master port -- the read and write channel sets are
independent, so nothing arbitrates between them.
The job is in BLOCKS, not bytes. A codec's unit of work is a block; the
source and destination beat counts differ by construction (k in, n out).
Parameters:
FIELD_DIM / PRIM_POLY / T_BITS / N_BITS / FIRST_ROOT
the code, exactly as bch_encoder_core takes them
DATA_WIDTH       AXI and stream width; also the BCH bits per beat
ADDR_WIDTH       AXI address width
ID_WIDTH         AXI id width
MAX_OUTSTANDING  requests in flight per direction
Notes:
- A codeword is written PACKED: exactly ceil(N/B) beats with any partial
one last, which is bch_decoder_core's in_keep contract. The core starts
parity on a fresh beat, so at K % B != 0 its output carries a partial
beat mid-codeword that a decoder flags as mis-framed. bch_beat_packer
closes that up, and is omitted when there is nothing to pack.
- in_keep is generated here, because the read engine deals in beats and
knows nothing about bits. Full on every beat except a block's last,
which carries K_TAIL bits when k does not fill its final beat.
- The write side writes whole beats. A partial final beat's unused lanes
carry whatever the core emitted; the consumer knows the bit count from
the profile and the block count.
- cfg_done is the WRITE engine's done ANDed with the read's.

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
module bch_encoder_axi4
    import bch_pkg::bch_beats;
    import bch_pkg::bch_degree_g;
#(
    parameter int FIELD_DIM     = bch_pkg::FIELD_DIM,
    parameter int PRIM_POLY     = bch_pkg::PRIM_POLY,
    parameter int T_BITS        = bch_pkg::T_BITS,
    parameter int N_BITS        = bch_pkg::N_BITS,
    parameter int FIRST_ROOT    = bch_pkg::FIRST_ROOT,
    parameter int DATA_WIDTH    = bch_pkg::BITS_PER_BEAT,
    parameter int ADDR_WIDTH    = 32,
    parameter int ID_WIDTH      = 4,
    parameter int MAX_OUTSTANDING = 4,
    parameter int USER_WIDTH    = 1,
    // derived, exposed for the consumer's convenience
    parameter int K_BITS        = N_BITS - bch_degree_g(FIELD_DIM, PRIM_POLY, T_BITS, FIRST_ROOT),
    parameter int BITS_PER_BEAT = DATA_WIDTH
) (
    input  logic                    aclk,
    input  logic                    aresetn,
    // -- job -----------------------------------------------------------------
    input  logic                    cfg_start,          // one-cycle pulse
    input  logic [ADDR_WIDTH-1:0]   cfg_src_addr,
    input  logic [ADDR_WIDTH-1:0]   cfg_dst_addr,
    input  logic [15:0]             cfg_blocks,
    input  logic [7:0]              cfg_burst_len,
    input  logic [ID_WIDTH-1:0]     cfg_axi_id,
    output logic                    cfg_done,
    output logic                    resp_err,           // sticky, either direction
    output logic                    frame_err,          // sticky: a short/long block
    // -- AXI4 master: read channels ------------------------------------------
    output logic [ID_WIDTH-1:0]     m_axi_arid,
    output logic [ADDR_WIDTH-1:0]   m_axi_araddr,
    output logic [7:0]              m_axi_arlen,
    output logic [2:0]              m_axi_arsize,
    output logic [1:0]              m_axi_arburst,
    output logic                    m_axi_arlock,
    output logic [3:0]              m_axi_arcache,
    output logic [2:0]              m_axi_arprot,
    output logic [3:0]              m_axi_arqos,
    output logic [3:0]              m_axi_arregion,
    output logic [USER_WIDTH-1:0]   m_axi_aruser,
    output logic                    m_axi_arvalid,
    input  logic                    m_axi_arready,
    input  logic [ID_WIDTH-1:0]     m_axi_rid,
    input  logic [DATA_WIDTH-1:0]   m_axi_rdata,
    input  logic [1:0]              m_axi_rresp,
    input  logic                    m_axi_rlast,
    input  logic [USER_WIDTH-1:0]   m_axi_ruser,
    input  logic                    m_axi_rvalid,
    output logic                    m_axi_rready,
    // -- AXI4 master: write channels -----------------------------------------
    output logic [ID_WIDTH-1:0]     m_axi_awid,
    output logic [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output logic [7:0]              m_axi_awlen,
    output logic [2:0]              m_axi_awsize,
    output logic [1:0]              m_axi_awburst,
    output logic                    m_axi_awlock,
    output logic [3:0]              m_axi_awcache,
    output logic [2:0]              m_axi_awprot,
    output logic [3:0]              m_axi_awqos,
    output logic [3:0]              m_axi_awregion,
    output logic [USER_WIDTH-1:0]   m_axi_awuser,
    output logic                    m_axi_awvalid,
    input  logic                    m_axi_awready,
    output logic [DATA_WIDTH-1:0]   m_axi_wdata,
    output logic [DATA_WIDTH/8-1:0] m_axi_wstrb,
    output logic                    m_axi_wlast,
    output logic [USER_WIDTH-1:0]   m_axi_wuser,
    output logic                    m_axi_wvalid,
    input  logic                    m_axi_wready,
    input  logic [ID_WIDTH-1:0]     m_axi_bid,
    input  logic [1:0]              m_axi_bresp,
    input  logic [USER_WIDTH-1:0]   m_axi_buser,
    input  logic                    m_axi_bvalid,
    output logic                    m_axi_bready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
