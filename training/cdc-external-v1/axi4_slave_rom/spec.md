Implement the SystemVerilog module `axi4_slave_rom`.

//   AXI4 read-only memory slave wrapper. Combines axi4_slave_rd protocol

Functional contract and interface notes:

Module: axi4_slave_rom
Description:
AXI4 read-only memory slave wrapper. Combines axi4_slave_rd protocol
handler with simple_rom storage backend to provide AXI4-compliant ROM
interface. Useful for boot code, configuration data, lookup tables, etc.
Parameters:
SKID_DEPTH_AR  - AR channel skid buffer depth (default: 2)
SKID_DEPTH_R   - R channel skid buffer depth (default: 4)
AXI_ID_WIDTH   - AXI ID width (default: 8)
AXI_ADDR_WIDTH - AXI address width (default: 32)
AXI_DATA_WIDTH - AXI data width (default: 64)
AXI_USER_WIDTH - AXI user signal width (default: 1)
ROM_INIT_FILE  - ROM initialization file path (default: "none")
Interfaces:
aclk, aresetn     - Clock and reset
s_axi_ar*         - AXI4 read address channel (slave)
s_axi_r*          - AXI4 read data channel (slave)
busy              - Status output (active transactions)
Notes:
- Read-only interface (no write channels)
- Single-cycle ROM access latency
- FPGA block RAM inference for ROM storage
- Supports bursts via AXI4 slave read handler
- ROM address is byte-aligned AXI address shifted by data width

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
module axi4_slave_rom
#(
    parameter int SKID_DEPTH_AR     = 2,                    // AR channel buffer depth
    parameter int SKID_DEPTH_R      = 4,                    // R channel buffer depth
    parameter int AXI_ID_WIDTH      = 8,                    // AXI ID width
    parameter int AXI_ADDR_WIDTH    = 32,                   // AXI address width
    parameter int AXI_DATA_WIDTH    = 64,                   // AXI data width
    parameter int AXI_USER_WIDTH    = 1,                    // AXI user width
    parameter int ROM_ADDR_WIDTH    = 12,                   // ROM depth = 2**ROM_ADDR_WIDTH words
    parameter string ROM_INIT_FILE  = "none"                // ROM initialization file
)
(
    // Global Clock and Reset
    input  logic                        aclk,               // AXI clock
    input  logic                        aresetn,            // AXI reset (active-low)
    // AXI4 Slave Interface (Read-Only)
    // Read address channel (AR)
    input  logic [AXI_ID_WIDTH-1:0]     s_axi_arid,         // Read address ID
    input  logic [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,       // Read address
    input  logic [7:0]                  s_axi_arlen,        // Burst length
    input  logic [2:0]                  s_axi_arsize,       // Burst size
    input  logic [1:0]                  s_axi_arburst,      // Burst type
    input  logic                        s_axi_arlock,       // Lock type
    input  logic [3:0]                  s_axi_arcache,      // Cache type
    input  logic [2:0]                  s_axi_arprot,       // Protection type
    input  logic [3:0]                  s_axi_arqos,        // QoS identifier
    input  logic [3:0]                  s_axi_arregion,     // Region identifier
    input  logic [AXI_USER_WIDTH-1:0]   s_axi_aruser,       // User signal
    input  logic                        s_axi_arvalid,      // Read address valid
    output logic                        s_axi_arready,      // Read address ready
    // Read data channel (R)
    output logic [AXI_ID_WIDTH-1:0]     s_axi_rid,          // Read data ID
    output logic [AXI_DATA_WIDTH-1:0]   s_axi_rdata,        // Read data
    output logic [1:0]                  s_axi_rresp,        // Read response
    output logic                        s_axi_rlast,        // Read last
    output logic [AXI_USER_WIDTH-1:0]   s_axi_ruser,        // User signal
    output logic                        s_axi_rvalid,       // Read data valid
    input  logic                        s_axi_rready,       // Read data ready
    // Status Output
    output logic                        busy                // Busy indicator
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
