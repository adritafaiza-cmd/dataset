Implement the SystemVerilog module `axil_to_axi4_wide_align_wr`.

Drop-in replacement for axi4_dwidth_converter_wr when the

Functional contract and interface notes:

Module: axil_to_axi4_wide_align_wr
Purpose: Drop-in replacement for axi4_dwidth_converter_wr when the
slave-side master is effectively AXIL (single-beat, narrow).
Why this exists:
The narrow→wide upsize converter `axi_data_upsize` aggregates N
narrow beats into one wide beat by beat counter. For an AXIL
master (every transfer is single-beat at a sub-row address),
every beat lands at lane 0 of the wide bus regardless of awaddr.
The bridge generator wraps AXIL masters with `axi4_slave_wr`
which presents fub_axi_* with awlen=0/awsize=narrow/awburst=01 —
and this module replaces the buggy upsize in that path.
Per AXI4 spec for single-beat narrow writes on a wide bus:
- awaddr's low bits identify the byte offset within the wide row
- wstrb[b]=1 enables wdata[8*b +: 8] (byte lane b carries data)
So the master is responsible for placing its narrow data and
strobes at the correct byte lanes. This module does that
master-side alignment.
Interface: AXI4 slave (matches axi4_dwidth_converter_wr's slave
port) on the master-side; emits a single-beat wide AXI4 write.
awlen/awsize on the slave side are ignored (always treated as
single-beat narrow → single-beat wide aligned).

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
module axil_to_axi4_wide_align_wr #(
    parameter int S_AXI_DATA_WIDTH  = 32,
    parameter int M_AXI_DATA_WIDTH  = 256,
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    parameter int SKID_DEPTH_AW     = 2,   // accepted for API parity
    parameter int SKID_DEPTH_W      = 2,
    parameter int SKID_DEPTH_B      = 2
) (
    input  logic                                  aclk,
    input  logic                                  aresetn,
    // -------- AXI4 slave (from master via wrapper) --------
    input  logic [AXI_ID_WIDTH-1:0]               s_axi_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]             s_axi_awaddr,
    input  logic [7:0]                            s_axi_awlen,
    input  logic [2:0]                            s_axi_awsize,
    input  logic [1:0]                            s_axi_awburst,
    input  logic                                  s_axi_awlock,
    input  logic [3:0]                            s_axi_awcache,
    input  logic [2:0]                            s_axi_awprot,
    input  logic [3:0]                            s_axi_awqos,
    input  logic [3:0]                            s_axi_awregion,
    input  logic [AXI_USER_WIDTH-1:0]             s_axi_awuser,
    input  logic                                  s_axi_awvalid,
    output logic                                  s_axi_awready,
    input  logic [S_AXI_DATA_WIDTH-1:0]           s_axi_wdata,
    input  logic [S_AXI_DATA_WIDTH/8-1:0]         s_axi_wstrb,
    input  logic                                  s_axi_wlast,
    input  logic [AXI_USER_WIDTH-1:0]             s_axi_wuser,
    input  logic                                  s_axi_wvalid,
    output logic                                  s_axi_wready,
    output logic [AXI_ID_WIDTH-1:0]               s_axi_bid,
    output logic [1:0]                            s_axi_bresp,
    output logic [AXI_USER_WIDTH-1:0]             s_axi_buser,
    output logic                                  s_axi_bvalid,
    input  logic                                  s_axi_bready,
    // -------- AXI4 master (to crossbar / wide slave) --------
    output logic [AXI_ID_WIDTH-1:0]               m_axi_awid,
    output logic [AXI_ADDR_WIDTH-1:0]             m_axi_awaddr,
    output logic [7:0]                            m_axi_awlen,
    output logic [2:0]                            m_axi_awsize,
    output logic [1:0]                            m_axi_awburst,
    output logic                                  m_axi_awlock,
    output logic [3:0]                            m_axi_awcache,
    output logic [2:0]                            m_axi_awprot,
    output logic [3:0]                            m_axi_awqos,
    output logic [3:0]                            m_axi_awregion,
    output logic [AXI_USER_WIDTH-1:0]             m_axi_awuser,
    output logic                                  m_axi_awvalid,
    input  logic                                  m_axi_awready,
    output logic [M_AXI_DATA_WIDTH-1:0]           m_axi_wdata,
    output logic [M_AXI_DATA_WIDTH/8-1:0]         m_axi_wstrb,
    output logic                                  m_axi_wlast,
    output logic [AXI_USER_WIDTH-1:0]             m_axi_wuser,
    output logic                                  m_axi_wvalid,
    input  logic                                  m_axi_wready,
    input  logic [AXI_ID_WIDTH-1:0]               m_axi_bid,
    input  logic [1:0]                            m_axi_bresp,
    input  logic [AXI_USER_WIDTH-1:0]             m_axi_buser,
    input  logic                                  m_axi_bvalid,
    output logic                                  m_axi_bready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
