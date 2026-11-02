Implement the SystemVerilog module `rs_encoder_axis4`.

Reed-Solomon systematic encoder with AXI4-Stream interfaces.

Functional contract and interface notes:

Module: rs_encoder_axis4
Description: Reed-Solomon systematic encoder with AXI4-Stream interfaces.
This is the component's integration top (PRD D9). `rs_encoder_core` speaks
a bare valid/ready/last handshake, which is the right interface for the
algorithm but the wrong one for a fabric. This wraps it in the house
`axis4_slave` / `axis4_master` skid wrappers so a consumer connects a
stream, not eleven renamed wires.
Why this module exists at all: the Nexys A7 loop harness used to rename
the core's handshake onto its generator and checker signals inline, in the
BOARD area. That put an interface decision that belongs to the component
in a project that merely instantiates it, and every future consumer would
have had to repeat it. The adapter lives here now, once.
Parameters:
SYMBOL_WIDTH      GF(2^m) symbol width, m. 8 is the common case.
PRIM_POLY         field polynomial, degree m, as an integer
T_SYMBOLS         correctable symbols per block; parity is 2t symbols
N_SYMBOLS         codeword length in symbols, <= 2^m - 1
FIRST_ROOT        b in g(x) = prod (x - alpha^(b+i))
DATA_WIDTH        stream width; must be a whole number of symbols
SKID_DEPTH        depth of the two AXIS skid buffers, 2..8
AXIS_*_WIDTH      tid / tdest / tuser widths, forwarded beat for beat
Notes:
- tstrb vs keep. The core's `keep` is PER SYMBOL; AXI4-Stream's tstrb is
PER BYTE. At SYMBOL_WIDTH == 8 the two coincide and tstrb carries keep
directly. At any other m they do not, so keep rides the low
SYMBOLS_PER_BEAT bits of tuser and tstrb is driven all ones. The
elaboration guard below enforces a wide enough tuser for that case
rather than silently truncating the strobe.
- keep is low-aligned and may be partial only on a block's last beat,
which is the core's contract, not something this wrapper relaxes.
- tid and tdest are forwarded from the beat that ENTERS the encoder to the
beats that leave it, held for the whole codeword. Parity beats carry the
same id and dest as the block's data beats.

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
module rs_encoder_axis4
    import rs_pkg::*;
#(
    parameter int SYMBOL_WIDTH     = 8,
    parameter int PRIM_POLY        = 'h11D,
    parameter int T_SYMBOLS        = 8,
    parameter int N_SYMBOLS        = (1 << SYMBOL_WIDTH) - 1,
    parameter int FIRST_ROOT       = 0,
    parameter int DATA_WIDTH       = SYMBOL_WIDTH,
    parameter int SKID_DEPTH       = 2,
    parameter int AXIS_ID_WIDTH    = 0,
    parameter int AXIS_DEST_WIDTH  = 0,
    parameter int AXIS_USER_WIDTH  = 0,
    // derived, exposed for the consumer's convenience
    parameter int K_SYMBOLS        = N_SYMBOLS - 2 * T_SYMBOLS,
    parameter int SYMBOLS_PER_BEAT = DATA_WIDTH / SYMBOL_WIDTH,
    // zero-width AXIS sidebands still need a 1-bit wire; these are in the
    // parameter list rather than the body because the PORTS below use them
    parameter int IW               = (AXIS_ID_WIDTH   > 0) ? AXIS_ID_WIDTH   : 1,
    parameter int DESTW            = (AXIS_DEST_WIDTH > 0) ? AXIS_DEST_WIDTH : 1,
    parameter int UW               = (AXIS_USER_WIDTH > 0) ? AXIS_USER_WIDTH : 1
) (
    input  logic                       aclk,
    input  logic                       aresetn,
    // data symbols in
    input  logic [DATA_WIDTH-1:0]      s_axis_tdata,
    input  logic [DATA_WIDTH/8-1:0]    s_axis_tstrb,
    input  logic                       s_axis_tlast,
    input  logic [IW-1:0]              s_axis_tid,
    input  logic [DESTW-1:0]           s_axis_tdest,
    input  logic [UW-1:0]              s_axis_tuser,
    input  logic                       s_axis_tvalid,
    output logic                       s_axis_tready,
    // codeword symbols out: k data beats then the parity beats
    output logic [DATA_WIDTH-1:0]      m_axis_tdata,
    output logic [DATA_WIDTH/8-1:0]    m_axis_tstrb,
    output logic                       m_axis_tlast,
    output logic [IW-1:0]              m_axis_tid,
    output logic [DESTW-1:0]           m_axis_tdest,
    output logic [UW-1:0]              m_axis_tuser,
    output logic                       m_axis_tvalid,
    input  logic                       m_axis_tready,
    // one-cycle pulse: a block ended with other than k data symbols
    output logic                       frame_err
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
