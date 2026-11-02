Implement the SystemVerilog module `cxs_slave`.

CXS Receiver endpoint (Arm IHI 0079, Issues A-D): a credited CXS

Functional contract and interface notes:

Module: cxs_slave
Purpose: CXS Receiver endpoint (Arm IHI 0079, Issues A-D): a credited CXS
link in, FUB-side valid/ready flits out
The CXS counterpart of axis4_slave. Every credit is a promise of one FIFO
slot (IHI 0079D 2.1.2: "the Receiver must guarantee that it can receive
one flit of data for each credit that it grants"), so the receive FIFO is
the credit pool:
r_out    credits granted and not yet spent (CXSVALID) or returned
(CXSCRDRTN), counting the grant on the wire this cycle
grant    another credit when, after this edge,
FIFO occupancy + r_out < RX_FIFO_DEPTH  and  r_out < CXS_MAX_CREDIT
CXSCRDGNT is registered (r_crdgnt) from registered state and this cycle's
VALID / CRDRTN / FUB pop, so a credit spent or returned in cycle t is
granted again at t+1 at the earliest -- the reuse rule of 2.1.2 -- and no
output depends combinationally on any input.
Link control, CXS_LINK_CTRL = 1 (chapter 5). CXSACTIVEREQ "must be treated
by the Receiver as an asynchronous signal" (5.5): it crosses through
glitch_free_n_dff_arn (ACTIVEREQ_SYNC_STAGES flops, with its check bit) --
0 stages is allowed for a known-synchronous system.
- ACTIVATE -> RUN: raise CXSACTIVEACK when ACTIVEREQ is seen and
cfg_rx_enable is set. Credits are granted only in RUN.
- DEACTIVATE: stop granting; flits still in flight are accepted (5.4);
drop ACTIVEACK only when every credit is home (r_out reaches 0), so the
transmitter never sees ACK low while it holds a credit.
- CXSDEACTHINT is cfg_deact_hint, registered.
With CXS_LINK_CTRL = 0 credits are granted whenever there is room and
cfg_rx_enable is set, and CXSACTIVEACK / CXSDEACTHINT are tied low.
Interface protection, CXS_CHECK = 1 (3.2): payload check signals are
checked when CXSVALID is high, for the signals the interface has;
CXSVALIDCHK, CXSCRDRTNCHK and CXSACTIVEREQCHK every cycle out of reset
(ACTIVEREQCHK after the same synchronizer as ACTIVEREQ). A mismatch sets
the sticky parity_error. CXSCRDGNTCHK and CXSACTIVEACKCHK are generated.
Parameters: as cxs_master, plus
- RX_FIFO_DEPTH: receive FIFO depth = the credit pool; default
CXS_MAX_CREDIT. A depth below the credit round trip throttles the link
(2.1.2: the credit count must cover the credit latency for full rate)
- ACTIVEREQ_SYNC_STAGES: synchronizer flops on CXSACTIVEREQ, 0 or >= 2

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (ACTIVEREQ_SYNC_STAGES), .WIDTH (2) ) u_req_sync ( .clk (aclk), .rst_n (aresetn), .d ({s_cxs_activereq, ~s_cxs_activereqchk}), .q ({w_req_s, w_reqchk_n_s}) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cxs_slave
    import cxs_pkg::*;
#(
    parameter int CXS_ISSUE             = CXS_ISSUE_D,
    parameter int CXS_DATA_WIDTH        = 256,
    parameter int CXS_MAX_PKT_PER_FLIT  = 2,
    parameter int CXS_START_ALIGN       = 16,
    parameter bit CXS_HAS_LAST          = 1'b0,
    parameter bit CXS_HAS_PRCLTYPE      = 1'b0,
    parameter int CXS_SRCID_WIDTH       = 0,
    parameter int CXS_TGTID_WIDTH       = 0,
    parameter int CXS_USER_WIDTH        = 0,
    parameter int CXS_MAX_CREDIT        = 15,
    // Credit pool beyond the spec's CXS_MAX_CREDIT cap (63, or 15 before
    // Issue C): the one sanctioned departure, for a receiver whose buffer is
    // a whole SRAM. Both ends of the link must be built with it.
    parameter bit CXS_CREDIT_BEYOND_SPEC = 1'b0,
    // Per-stream packet tracking (IHI 0079D 2.5.2): the low bits of
    // CXSPRCLTYPE / CXSSRCID / CXSTGTID that tell interleaved streams apart.
    // 0/0/0 = the link is one stream (no interleave). See cxs_stream_key.
    parameter int CXS_STREAM_PRCL_BITS  = 0,
    parameter int CXS_STREAM_SRCID_BITS = 0,
    parameter int CXS_STREAM_TGTID_BITS = 0,
    parameter bit CXS_LINK_CTRL         = 1'b1,
    parameter bit CXS_CHECK             = 1'b0,
    parameter int RX_FIFO_DEPTH         = CXS_MAX_CREDIT,
    parameter int ACTIVEREQ_SYNC_STAGES = 2,
    // Short and calculated params
    parameter int DW        = CXS_DATA_WIDTH,
    parameter int N         = CXS_MAX_PKT_PER_FLIT,
    parameter int CNTL_W    = cntl_width(N, DW, CXS_START_ALIGN),
    parameter int CNTL_PW   = port_w(CNTL_W),
    parameter int SRCID_PW  = port_w(CXS_SRCID_WIDTH),
    parameter int TGTID_PW  = port_w(CXS_TGTID_WIDTH),
    parameter int USER_PW   = port_w(CXS_USER_WIDTH),
    parameter int DATACHK_W = chk_width(DW),
    parameter int CNTLCHK_W = port_w(chk_width(CNTL_W)),
    parameter int USERCHK_W = port_w(chk_width(CXS_USER_WIDTH)),
    parameter int CRW       = $clog2(CXS_MAX_CREDIT + 1)
) (
    // Global Clock and Reset
    input  logic                  aclk,
    input  logic                  aresetn,
    // Configuration
    input  logic                  cfg_rx_enable,     // 0 = never activate, never grant
    input  logic                  cfg_deact_hint,    // drives CXSDEACTHINT (registered)
    // CXS Receiver interface
    input  logic                  s_cxs_valid,
    input  logic [DW-1:0]         s_cxs_data,
    input  logic [CNTL_PW-1:0]    s_cxs_cntl,
    input  logic                  s_cxs_last,
    input  logic [2:0]            s_cxs_prcltype,
    input  logic [SRCID_PW-1:0]   s_cxs_srcid,
    input  logic [TGTID_PW-1:0]   s_cxs_tgtid,
    input  logic [USER_PW-1:0]    s_cxs_user,
    output logic                  s_cxs_crdgnt,
    input  logic                  s_cxs_crdrtn,
    input  logic                  s_cxs_activereq,
    output logic                  s_cxs_activeack,
    output logic                  s_cxs_deacthint,
    // CXS check signals (CXS_CHECK = 1)
    input  logic                  s_cxs_validchk,
    input  logic [DATACHK_W-1:0]  s_cxs_datachk,
    input  logic [CNTLCHK_W-1:0]  s_cxs_cntlchk,
    input  logic                  s_cxs_lastchk,
    input  logic                  s_cxs_prcltypechk,
    input  logic                  s_cxs_srcidchk,
    input  logic                  s_cxs_tgtidchk,
    input  logic [USERCHK_W-1:0]  s_cxs_userchk,
    output logic                  s_cxs_crdgntchk,
    input  logic                  s_cxs_crdrtnchk,
    input  logic                  s_cxs_activereqchk,
    output logic                  s_cxs_activeackchk,
    // FUB side (valid/ready flits out)
    output logic                  fub_cxs_valid,
    input  logic                  fub_cxs_ready,
    output logic [DW-1:0]         fub_cxs_data,
    output logic [CNTL_PW-1:0]    fub_cxs_cntl,
    output logic                  fub_cxs_last,
    output logic [2:0]            fub_cxs_prcltype,
    output logic [SRCID_PW-1:0]   fub_cxs_srcid,
    output logic [TGTID_PW-1:0]   fub_cxs_tgtid,
    output logic [USER_PW-1:0]    fub_cxs_user,
    // Status
    output logic                  busy,                // any work or link state that is not STOP
    output logic [CRW-1:0]        credits_outstanding, // granted, not yet spent or returned
    output logic [1:0]            link_state,          // {ACTIVEREQ synced, ACTIVEACK}
    output logic                  in_packet,           // a packet is open on the link
    output logic                  credit_starved,      // RUN, no credit out and none grantable: the FIFO holds every slot (the FUB is the bottleneck)
    output logic                  protocol_error,      // sticky: flit/return without a credit, VALID with CRDRTN, bad CXSCNTL, overflow
    output logic                  parity_error         // sticky: a received check signal mismatched
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
