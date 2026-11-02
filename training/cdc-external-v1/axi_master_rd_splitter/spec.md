Implement the SystemVerilog module `axi_master_rd_splitter`.

Axi Master Rd Splitter module

Functional contract and interface notes:

Module: axi_master_rd_splitter
Purpose: Axi Master Rd Splitter module
*Assumption**: All AXI transactions are aligned to the data bus width.
*Assumption**: All AXI transfers use the maximum transfer size equal to the bus width.
*Assumption**: All AXI bursts use incrementing address mode (`AxBURST = 2'b01`).
*Assumption**: Transactions never wrap around the top of address space (0xFFFFFFFF -> 0x00000000).
*Overview**: This module accepts AXI read transactions on the fub interface and splits them
*FUB_ARREADY Assertion Strategy**:
*Splitting Sequence for Boundary-Crossing Transactions**:
*Key Properties**:
*Example Split Sequence** (4KB boundary, 64-byte beats):

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
module axi_master_rd_splitter
#(
    // AXI parameters
    parameter int AXI_ID_WIDTH      = 8,
    parameter int AXI_ADDR_WIDTH    = 32,
    parameter int AXI_DATA_WIDTH    = 32,
    parameter int AXI_USER_WIDTH    = 1,
    // FIFO depth
    parameter int SPLIT_FIFO_DEPTH  = 4,
    // short names
    parameter int IW = AXI_ID_WIDTH,
    parameter int AW = AXI_ADDR_WIDTH,
    parameter int DW = AXI_DATA_WIDTH,
    parameter int UW = AXI_USER_WIDTH
)
(
    // Global Clock and Reset
    input  logic aclk,
    input  logic aresetn,
    // Alignment mask signal (12-bit)
    input  logic [11:0] alignment_mask,
    // Master AXI Interface
    // Read address channel (AR)
    output logic [IW-1:0]              m_axi_arid,
    output logic [AW-1:0]              m_axi_araddr,
    output logic [7:0]                 m_axi_arlen,
    output logic [2:0]                 m_axi_arsize,
    output logic [1:0]                 m_axi_arburst,
    output logic                       m_axi_arlock,
    output logic [3:0]                 m_axi_arcache,
    output logic [2:0]                 m_axi_arprot,
    output logic [3:0]                 m_axi_arqos,
    output logic [3:0]                 m_axi_arregion,
    output logic [UW-1:0]              m_axi_aruser,
    output logic                       m_axi_arvalid,
    input  logic                       m_axi_arready,
    // Read data channel (R)
    input  logic [IW-1:0]              m_axi_rid,
    input  logic [DW-1:0]              m_axi_rdata,
    input  logic [1:0]                 m_axi_rresp,
    input  logic                       m_axi_rlast,
    input  logic [UW-1:0]              m_axi_ruser,
    input  logic                       m_axi_rvalid,
    output logic                       m_axi_rready,
    // Block ready from the errmon
    input  logic                       block_ready,
    // Slave AXI Interface
    // Read address channel (AR)
    input  logic [IW-1:0]              fub_arid,
    input  logic [AW-1:0]              fub_araddr,
    input  logic [7:0]                 fub_arlen,
    input  logic [2:0]                 fub_arsize,
    input  logic [1:0]                 fub_arburst,
    input  logic                       fub_arlock,
    input  logic [3:0]                 fub_arcache,
    input  logic [2:0]                 fub_arprot,
    input  logic [3:0]                 fub_arqos,
    input  logic [3:0]                 fub_arregion,
    input  logic [UW-1:0]              fub_aruser,
    input  logic                       fub_arvalid,
    output logic                       fub_arready,
    // Read data channel (R)
    output logic [IW-1:0]              fub_rid,
    output logic [DW-1:0]              fub_rdata,
    output logic [1:0]                 fub_rresp,
    output logic                       fub_rlast,
    output logic [UW-1:0]              fub_ruser,
    output logic                       fub_rvalid,
    input  logic                       fub_rready,
    // Output split information
    output logic [AW-1:0]              fub_split_addr,
    output logic [IW-1:0]              fub_split_id,
    output logic [7:0]                 fub_split_cnt,
    output logic                       fub_split_valid,
    // Sticky: a split-info record was dropped because the FIFO was
    // full. Sizing this FIFO is a correctness requirement, so the
    // violation has to be observable rather than silent.
    output logic                       o_split_fifo_overflow,
    input  logic                       fub_split_ready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
