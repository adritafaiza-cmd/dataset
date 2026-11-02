Implement the SystemVerilog module `axi4_dwidth_converter_rd`.

AXI4 Read Data Width Converter (READ-ONLY, STANDALONE)

Functional contract and interface notes:

Module: axi4_dwidth_converter_rd
Purpose: AXI4 Read Data Width Converter (READ-ONLY, STANDALONE)
Description:
Converts between AXI4 read interfaces of different data widths.
Handles ONLY read path (AR, R channels) - no write support.
The R channel data path is delegated to the validated
axi_data_upsize / axi_data_dnsize primitives in this same
directory (each with its own pytest suite) when R bursts arrive
contiguously (R_INTERLEAVE = 0).  With R_INTERLEAVE = 1 the wrapper
converts each beat against its own ID's state instead (gen_rilv).
Either way it owns the AR/R skid buffers, the AR arlen/arsize
rewrite, the per-ID AR records and the rid/ruser carry.
R interleave (2026-10-18): AXI4 permits a slave to interleave R beats
across ARIDs.  Downsize keeps each ID's partial wide beat in
distributed RAM indexed by ID; upsize holds one wide beat and keeps
each ID's remaining narrow-beat count.  Nothing buffers a whole burst.
Each ID has at most one master burst outstanding: master AR issue for
an ID waits until its previous burst has arrived.  Same-ID read chains
serialize on that; cross-ID traffic is concurrent and may interleave
arbitrarily on m_axi R.  This replaced the BUG-009 shared beat pool
(2026-10-04), which stored whole bursts first.
For write conversion, use axi4_dwidth_converter_wr.sv.
Parameters:
S_AXI_DATA_WIDTH: Slave interface data width (32, 64, 128, 256)
M_AXI_DATA_WIDTH: Master interface data width (32, 64, 128, 256)
AXI_ID_WIDTH: Transaction ID width (1-16)
AXI_ADDR_WIDTH: Address bus width (12-64)
AXI_USER_WIDTH: User signal width (0-1024)
SKID_DEPTH_AR: AR channel skid buffer depth (2-8, default 2)
SKID_DEPTH_R: R channel skid buffer depth (2-8, default 4)
RASM_DEPTH, RASM_MAX_OUTSTANDING: unused, kept so existing instances
still elaborate (they sized the retired beat pool).
R_INTERLEAVE: 1 (default) = the m_axi R source may interleave beats of
different ARIDs; each beat is converted per ID as it arrives.  0 =
the source promises every R burst arrives contiguously (bursts of
different IDs may still return in any order); beats go straight to
the data primitive, with RID/RUSER carried through its sideband.
The bridge builds every read converter with 1: its slaves may
interleave R (bridge PRD FR-9).

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
module axi4_dwidth_converter_rd #(
    // Width Configuration
    parameter int S_AXI_DATA_WIDTH  = 32,
    parameter int M_AXI_DATA_WIDTH  = 128,
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // Skid Buffer Depths (for timing closure)
    parameter int SKID_DEPTH_AR     = 4,
    parameter int SKID_DEPTH_R      = 4,
    // Unused: they sized the retired BUG-009 beat pool. Kept so existing
    // instances that set them still elaborate.
    parameter int RASM_DEPTH             = 272,
    parameter int RASM_MAX_OUTSTANDING   = 16,
    // R_INTERLEAVE = 1: R may interleave across IDs, converted per ID as
    // it arrives. 0: contiguous R bursts only (see the header).
    parameter bit R_INTERLEAVE           = 1'b1,
    // Calculated Parameters
    localparam int S_STRB_WIDTH = S_AXI_DATA_WIDTH / 8,
    localparam int M_STRB_WIDTH = M_AXI_DATA_WIDTH / 8,
    localparam int WIDTH_RATIO  = (S_AXI_DATA_WIDTH < M_AXI_DATA_WIDTH) ?
                                  (M_AXI_DATA_WIDTH / S_AXI_DATA_WIDTH) :
                                  (S_AXI_DATA_WIDTH / M_AXI_DATA_WIDTH),
    localparam bit UPSIZE       = (S_AXI_DATA_WIDTH < M_AXI_DATA_WIDTH) ? 1'b1 : 1'b0,
    localparam bit DOWNSIZE     = (S_AXI_DATA_WIDTH > M_AXI_DATA_WIDTH) ? 1'b1 : 1'b0,
    localparam int NUM_IDS      = 1 << AXI_ID_WIDTH,
    localparam int LANE_W       = $clog2(WIDTH_RATIO),
    // Primitive sideband (R_INTERLEAVE = 0, the only mode that builds the
    // primitives): {RRESP, RID, RUSER}, so every converted beat carries its
    // own burst's ID; 2 bits otherwise, tied off.  RRESP is the MSB field: the upsize
    // primitive folds by numeric max, which then keeps the worst response.
    localparam int PSB_W        = R_INTERLEAVE ? 2 : (2 + AXI_ID_WIDTH + AXI_USER_WIDTH),
    // Skid buffer packed widths
    localparam int AR_WIDTH = AXI_ID_WIDTH + AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4 + AXI_USER_WIDTH,
    localparam int R_WIDTH  = S_AXI_DATA_WIDTH + 2 + AXI_USER_WIDTH + 1 + AXI_ID_WIDTH
) (
    // Clock and Reset
    input  logic                        aclk,
    input  logic                        aresetn,
    //==========================================================================
    // Slave AXI Read Interface
    //==========================================================================
    // Read Address Channel
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
    // Read Data Channel
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,
    output logic [S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]                  s_axi_rresp,
    output logic                        s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]   s_axi_ruser,
    output logic                        s_axi_rvalid,
    input  logic                        s_axi_rready,
    //==========================================================================
    // Master AXI Read Interface
    //==========================================================================
    // Read Address Channel
    output logic [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output logic [7:0]                  m_axi_arlen,
    output logic [2:0]                  m_axi_arsize,
    output logic [1:0]                  m_axi_arburst,
    output logic                        m_axi_arlock,
    output logic [3:0]                  m_axi_arcache,
    output logic [2:0]                  m_axi_arprot,
    output logic [3:0]                  m_axi_arqos,
    output logic [3:0]                  m_axi_arregion,
    output logic [AXI_USER_WIDTH-1:0]   m_axi_aruser,
    output logic                        m_axi_arvalid,
    input  logic                        m_axi_arready,
    // Read Data Channel
    input  logic [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input  logic [M_AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [1:0]                  m_axi_rresp,
    input  logic                        m_axi_rlast,
    input  logic [AXI_USER_WIDTH-1:0]   m_axi_ruser,
    input  logic                        m_axi_rvalid,
    output logic                        m_axi_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
