Implement the SystemVerilog module `bch_decoder_axis4`.

Binary BCH decoder with AXI4-Stream interfaces.

Functional contract and interface notes:

Module: bch_decoder_axis4
Description: Binary BCH decoder with AXI4-Stream interfaces.
The component's integration top (TASK-006), the counterpart to
`bch_encoder_axis4`. `bch_decoder_core` speaks a bare valid/ready/last
handshake plus a per-block verdict; this wraps the stream halves in the
house `axis4_slave` / `axis4_master` skid wrappers and leaves the verdict
as sideband.
Parameters:
FIELD_DIM       GF(2^m) field dimension, m
PRIM_POLY       primitive polynomial of degree m, as an integer
T_BITS          t, correctable bit errors per block
N_BITS          n, codeword length in bits
FIRST_ROOT      b, must match the encoder
BITS_PER_BEAT   B, the AXI4-Stream beat width
SKID_DEPTH      depth of the two AXIS skid buffers, 2..8
AXIS_*_WIDTH    tid / tdest / tuser widths, captured and held per block
Notes:
- tstrb vs keep: identical rule to `bch_encoder_axis4`. Byte-aligned
codes use tstrb; non-byte-aligned codes carry keep on tuser low bits.
Profile keep modes are listed in `bch_encoder_axis4.sv`.
- The decoder emits k corrected data bits per n-bit block; parity is
consumed, not forwarded. tid and tdest are captured from the block's
first accepted beat and held across the beats it produces.
- out_status_* are valid with THIS module's m_axis_tlast, not the core's
internal one. They are re-registered on the core's last output beat and
held, because the outlet skid delays the data past the point where the
core's status is still valid. A consumer sampling at m_axis_tlast gets
the verdict for the block that just ended.

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
module bch_decoder_axis4
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
    // received codeword bits in
    input  logic [BITS_PER_BEAT-1:0]   s_axis_tdata,
    input  logic [BITS_PER_BEAT/8-1:0] s_axis_tstrb,
    input  logic                       s_axis_tlast,
    input  logic [IW-1:0]              s_axis_tid,
    input  logic [DESTW-1:0]           s_axis_tdest,
    input  logic [UW-1:0]              s_axis_tuser,
    input  logic                       s_axis_tvalid,
    output logic                       s_axis_tready,
    // corrected data bits out: k beats per block
    output logic [BITS_PER_BEAT-1:0]   m_axis_tdata,
    output logic [BITS_PER_BEAT/8-1:0] m_axis_tstrb,
    output logic                       m_axis_tlast,
    output logic [IW-1:0]              m_axis_tid,
    output logic [DESTW-1:0]           m_axis_tdest,
    output logic [UW-1:0]              m_axis_tuser,
    output logic                       m_axis_tvalid,
    input  logic                       m_axis_tready,
    // per-block verdict, valid with m_axis_tlast
    output logic                       out_status_ok,
    output logic [$clog2(T_BITS+1)-1:0] out_status_corrected,
    output logic                       out_status_uncorrectable,
    output logic                       out_status_frame_err
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
