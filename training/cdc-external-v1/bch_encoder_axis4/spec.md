Implement the SystemVerilog module `bch_encoder_axis4`.

Binary BCH systematic encoder with AXI4-Stream interfaces.

Functional contract and interface notes:

Module: bch_encoder_axis4
Description: Binary BCH systematic encoder with AXI4-Stream interfaces.
This is the component's integration top (TASK-006). `bch_encoder_core`
speaks a bare valid/ready/last handshake, which is the right interface for
the algorithm but the wrong one for a fabric. This wraps it in the house
`axis4_slave` / `axis4_master` skid wrappers so a consumer connects a
stream, not ten renamed wires.
Parameters:
FIELD_DIM       GF(2^m) field dimension, m
PRIM_POLY       primitive polynomial of degree m, as an integer
T_BITS          t, correctable bit errors per block
N_BITS          n, codeword length in bits
FIRST_ROOT      b in g(x) = lcm of minimal polynomials of alpha^b ..
alpha^(b+2t-1)
BITS_PER_BEAT   B, the AXI4-Stream beat width; also the core's in_data/
out_data width
SKID_DEPTH      depth of the two AXIS skid buffers, 2..8
AXIS_*_WIDTH    tid / tdest / tuser widths, captured and held per block
Notes:
- tstrb vs keep. The core's `keep` is PER BIT; AXI4-Stream's tstrb is
PER BYTE. When K_BITS and N_BITS are both byte-aligned the core's keep
is guaranteed byte-aligned, so tstrb carries it (one strobe bit per byte,
high only when all eight keep bits in that byte are high). In that mode
tuser is driven to zero. When either K or N is not byte-aligned the keep
cannot be expressed per byte, so it rides the low BITS_PER_BEAT bits of
tuser and tstrb is driven all-ones -- the same rule the RS wrappers use
for non-byte-sized symbols.
Profile keep modes:
(m=6, n=63, k=56, B=8)  tuser mode  (63 is not byte-aligned)
(m=6, n=63, k=51, B=8)  tuser mode  (63 is not byte-aligned)
(m=13, n=4224, k=4120, B=8)  tstrb mode
(m=13, n=4224, k=4120, B=32) tstrb mode (k is not a multiple of B, so
the encoder emits a partial data-phase beat with tlast=0; the
keep is still byte-aligned and is carried faithfully by tstrb)
- No beat packer is instantiated. The BCH encoder core already places
partial beats only at the end of a phase (the final data beat and the
final parity beat). The wrapper preserves that beat layout and carries
the per-bit keep through the appropriate sideband.
- tid and tdest are captured from the block's FIRST accepted beat and held
until its last output beat leaves; parity beats carry the same id/dest.

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
module bch_encoder_axis4
    import bch_pkg::*;
#(
    parameter int FIELD_DIM     = bch_pkg::FIELD_DIM,
    parameter int PRIM_POLY     = bch_pkg::PRIM_POLY,
    parameter int T_BITS        = bch_pkg::T_BITS,
    parameter int N_BITS        = bch_pkg::N_BITS,
    parameter int FIRST_ROOT    = bch_pkg::FIRST_ROOT,
    parameter int BITS_PER_BEAT = bch_pkg::BITS_PER_BEAT,
    // derived, exposed for the consumer's convenience
    parameter int K_BITS        = N_BITS - bch_degree_g(FIELD_DIM, PRIM_POLY, T_BITS, FIRST_ROOT),
    parameter int SKID_DEPTH    = 2,
    parameter int AXIS_ID_WIDTH = 0,
    parameter int AXIS_DEST_WIDTH = 0,
    // Default is BITS_PER_BEAT so the package default (n=63, non-byte-aligned)
    // can carry per-bit keep on tuser without an explicit override.
    parameter int AXIS_USER_WIDTH = BITS_PER_BEAT,
    // zero-width AXIS sidebands still need a 1-bit wire
    parameter int IW            = (AXIS_ID_WIDTH   > 0) ? AXIS_ID_WIDTH   : 1,
    parameter int DESTW         = (AXIS_DEST_WIDTH > 0) ? AXIS_DEST_WIDTH : 1,
    parameter int UW            = (AXIS_USER_WIDTH > 0) ? AXIS_USER_WIDTH : 1
) (
    input  logic                       aclk,
    input  logic                       aresetn,
    // data bits in
    input  logic [BITS_PER_BEAT-1:0]   s_axis_tdata,
    input  logic [BITS_PER_BEAT/8-1:0] s_axis_tstrb,
    input  logic                       s_axis_tlast,
    input  logic [IW-1:0]              s_axis_tid,
    input  logic [DESTW-1:0]           s_axis_tdest,
    input  logic [UW-1:0]              s_axis_tuser,
    input  logic                       s_axis_tvalid,
    output logic                       s_axis_tready,
    // coded bits out: k data beats then the parity beats
    output logic [BITS_PER_BEAT-1:0]   m_axis_tdata,
    output logic [BITS_PER_BEAT/8-1:0] m_axis_tstrb,
    output logic                       m_axis_tlast,
    output logic [IW-1:0]              m_axis_tid,
    output logic [DESTW-1:0]           m_axis_tdest,
    output logic [UW-1:0]              m_axis_tuser,
    output logic                       m_axis_tvalid,
    input  logic                       m_axis_tready,
    // one-cycle pulse: a block ended with other than k data bits
    output logic                       frame_err
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
