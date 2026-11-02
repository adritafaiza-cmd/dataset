Implement the SystemVerilog module `cxs_slave_cg`.

cxs_slave behind one amba_clock_gate_ctrl

Functional contract and interface notes:

Module: cxs_slave_cg
Purpose: cxs_slave behind one amba_clock_gate_ctrl
IHI 0079D 5.5 anticipates exactly this block: "It is common for the clock
in the Receiver to stop during the STOP state ... The assertion of the
CXSACTIVEREQ signal might be used to restart that clock."
The core's `busy` covers every state in which a flit or a credit return
can still arrive -- ACTIVEACK or the synchronized ACTIVEREQ high, or any
credit outstanding -- plus a flit waiting on the FUB side. So the block
gates only in STOP with every credit home and the FIFO empty, where the
transmitter "must not send flits or credit returns" (5.2).
- CXS_LINK_CTRL = 1: gates in STOP; a rising CXSACTIVEREQ wakes it.
- CXS_LINK_CTRL = 0: credits stay outstanding indefinitely, `busy`
never falls, and this wrapper never gates (see cxs_master_cg).
Activity terms (vault/handbook/design/clock-gating-activity-terms):
user_valid = core busy                       (includes fub_cxs_valid,
the pending output)
axi_valid  = s_cxs_valid | s_cxs_crdrtn | ACTIVEREQ synchronized here
CXSACTIVEREQ is asynchronous (5.5), so the wake term goes through its own
glitch_free_n_dff_arn on the FREE-RUNNING aclk: a wake term must be in the
gate's own clock domain, and the core's synchronizer sits on the gated
clock and is frozen in STOP. Event outputs (CXSCRDGNT and its check bit,
fub_cxs_valid) are masked with !cg_gating.

Required clock and reset behavior:

- Clock ports: aclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (ACTIVEREQ_SYNC_STAGES), .WIDTH (1) ) u_req_wake_sync ( .clk (aclk), .rst_n (aresetn), .d (s_cxs_activereq), .q (w_req_wake) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cxs_slave_cg
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
    parameter bit  CXS_CREDIT_BEYOND_SPEC = 1'b0,   // see cxs_master / cxs_slave
    parameter int  CXS_STREAM_PRCL_BITS   = 0,      // per-stream tracking key (cxs_stream_key)
    parameter int  CXS_STREAM_SRCID_BITS  = 0,
    parameter int  CXS_STREAM_TGTID_BITS  = 0,
    parameter bit CXS_LINK_CTRL         = 1'b1,
    parameter bit CXS_CHECK             = 1'b0,
    parameter int RX_FIFO_DEPTH         = CXS_MAX_CREDIT,
    parameter int ACTIVEREQ_SYNC_STAGES = 2,
    // Clock gating parameters
    parameter int CG_IDLE_COUNT_WIDTH   = 4,
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
    input  logic                           aclk,
    input  logic                           aresetn,
    // Clock gating configuration
    input  logic                           cfg_cg_enable,
    input  logic [CG_IDLE_COUNT_WIDTH-1:0] cfg_cg_idle_count,
    // Configuration
    input  logic                  cfg_rx_enable,
    input  logic                  cfg_deact_hint,
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
    // CXS check signals
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
    // FUB side
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
    output logic [CRW-1:0]        credits_outstanding,
    output logic [1:0]            link_state,
    output logic                  in_packet,
    output logic                  credit_starved,
    output logic                  protocol_error,
    output logic                  parity_error,
    // Clock gating status
    output logic                  cg_gating,
    output logic                  cg_idle
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
