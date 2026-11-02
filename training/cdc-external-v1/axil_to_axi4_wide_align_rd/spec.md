Implement the SystemVerilog module `axil_to_axi4_wide_align_rd`.

Drop-in replacement for axi4_dwidth_converter_rd when the

Functional contract and interface notes:

Module: axil_to_axi4_wide_align_rd
Purpose: Drop-in replacement for axi4_dwidth_converter_rd when the
slave-side master is effectively AXIL (single-beat, narrow).
Mirror of axil_to_axi4_wide_align_wr — for sub-row narrow reads
from a wider slave, the wide R beat has the requested slot at byte
offset (araddr & wide_mask)*8. The generic narrow→wide dnsize
emits multiple narrow beats by beat counter, not the slot the
master asked for. This module:
- Accepts one AXI4 single-beat narrow AR (awlen/awsize ignored).
- Emits one wide AXI4 single-beat AR at the row-aligned address.
- On the wide R beat, extracts the narrow slot via araddr's low
bits and returns it as the narrow R.

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
module axil_to_axi4_wide_align_rd #(
    parameter int S_AXI_DATA_WIDTH  = 32,
    parameter int M_AXI_DATA_WIDTH  = 256,
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    parameter int SKID_DEPTH_AR     = 2,
    parameter int SKID_DEPTH_R      = 4
) (
    input  logic                                  aclk,
    input  logic                                  aresetn,
    // -------- AXI4 slave (from master via wrapper) --------
    input  logic [AXI_ID_WIDTH-1:0]               s_axi_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]             s_axi_araddr,
    input  logic [7:0]                            s_axi_arlen,
    input  logic [2:0]                            s_axi_arsize,
    input  logic [1:0]                            s_axi_arburst,
    input  logic                                  s_axi_arlock,
    input  logic [3:0]                            s_axi_arcache,
    input  logic [2:0]                            s_axi_arprot,
    input  logic [3:0]                            s_axi_arqos,
    input  logic [3:0]                            s_axi_arregion,
    input  logic [AXI_USER_WIDTH-1:0]             s_axi_aruser,
    input  logic                                  s_axi_arvalid,
    output logic                                  s_axi_arready,
    output logic [AXI_ID_WIDTH-1:0]               s_axi_rid,
    output logic [S_AXI_DATA_WIDTH-1:0]           s_axi_rdata,
    output logic [1:0]                            s_axi_rresp,
    output logic                                  s_axi_rlast,
    output logic [AXI_USER_WIDTH-1:0]             s_axi_ruser,
    output logic                                  s_axi_rvalid,
    input  logic                                  s_axi_rready,
    // -------- AXI4 master (to crossbar / wide slave) --------
    output logic [AXI_ID_WIDTH-1:0]               m_axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0]             m_axi_araddr,
    output logic [7:0]                            m_axi_arlen,
    output logic [2:0]                            m_axi_arsize,
    output logic [1:0]                            m_axi_arburst,
    output logic                                  m_axi_arlock,
    output logic [3:0]                            m_axi_arcache,
    output logic [2:0]                            m_axi_arprot,
    output logic [3:0]                            m_axi_arqos,
    output logic [3:0]                            m_axi_arregion,
    output logic [AXI_USER_WIDTH-1:0]             m_axi_aruser,
    output logic                                  m_axi_arvalid,
    input  logic                                  m_axi_arready,
    input  logic [AXI_ID_WIDTH-1:0]               m_axi_rid,
    input  logic [M_AXI_DATA_WIDTH-1:0]           m_axi_rdata,
    input  logic [1:0]                            m_axi_rresp,
    input  logic                                  m_axi_rlast,
    input  logic [AXI_USER_WIDTH-1:0]             m_axi_ruser,
    input  logic                                  m_axi_rvalid,
    output logic                                  m_axi_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
