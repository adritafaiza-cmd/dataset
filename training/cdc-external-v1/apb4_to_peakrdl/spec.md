Implement the SystemVerilog module `apb4_to_peakrdl`.

One-stop APB slave -> PeakRDL passthrough ("cpuif") adapter.

Functional contract and interface notes:

Module: apb4_to_peakrdl
Purpose: One-stop APB slave -> PeakRDL passthrough ("cpuif") adapter.
Stitches the two existing converters:
APB (pclk) --apb4_slave_cdc--> CMD/RSP (aclk) --peakrdl_to_cmdrsp--> cpuif
so a design that exposes a PeakRDL passthrough register interface
(regblk_* / s_cpuif_*) can be driven from a plain APB slave port.
The CDC lets the APB bus and the register/core clock differ; tie
pclk==aclk for a single-clock system (the CDC then adds a couple of
synchronizer cycles but is otherwise transparent).
This is the exact stack the (retired) pumice_csr_slave documented
and that stream_top_ch8 wires inline; factored out here so board
harnesses can adapt a bridge APB config window onto a rearchitected
rtl/amba/apb4/apb4_slave_cdc.sv

Required clock and reset behavior:

- Clock ports: aclk, pclk.
- Reset ports: aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );
- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync_pclk ( .clk (pclk), .rst_n (presetn), .sync_rst_n (w_aresetn_pclk) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module apb4_to_peakrdl #(
    parameter int ADDR_WIDTH = 12,   // APB + cpuif byte address width
    parameter int DATA_WIDTH = 32,   // Must match PeakRDL generation (32)
    parameter int PROT_WIDTH = 3,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,
    // CDC command/response FIFO depth (>=2)
    parameter int CDC_DEPTH  = 2,
    // Async-FIFO pointer encoding, forwarded to the CDC block below:
    // 0 = Gray (power-of-2 depth only), 1 = Johnson (any depth, DEPTH-bit
    // pointers). Gray by default -- Johnson is opt-in.
    parameter int USE_JOHNSON = 0,
    parameter bit USE_2_PHASE_CDC = 1'b1
) (
    // Register/core clock domain (drives the cpuif master)
    input  logic                    aclk,
    input  logic                    aresetn,
    // APB clock domain
    input  logic                    pclk,
    input  logic                    presetn,
    // ---- APB slave port ----
    input  logic                    s_apb_PSEL,
    input  logic                    s_apb_PENABLE,
    output logic                    s_apb_PREADY,
    input  logic [ADDR_WIDTH-1:0]   s_apb_PADDR,
    input  logic                    s_apb_PWRITE,
    input  logic [DATA_WIDTH-1:0]   s_apb_PWDATA,
    input  logic [STRB_WIDTH-1:0]   s_apb_PSTRB,
    input  logic [PROT_WIDTH-1:0]   s_apb_PPROT,
    output logic [DATA_WIDTH-1:0]   s_apb_PRDATA,
    output logic                    s_apb_PSLVERR,
    // ---- PeakRDL passthrough (cpuif) master ----
    output logic                    cpuif_req,
    output logic                    cpuif_req_is_wr,
    output logic [ADDR_WIDTH-1:0]   cpuif_addr,
    output logic [DATA_WIDTH-1:0]   cpuif_wr_data,
    output logic [DATA_WIDTH-1:0]   cpuif_wr_biten,
    input  logic                    cpuif_req_stall_wr,
    input  logic                    cpuif_req_stall_rd,
    input  logic                    cpuif_rd_ack,
    input  logic                    cpuif_rd_err,
    input  logic [DATA_WIDTH-1:0]   cpuif_rd_data,
    input  logic                    cpuif_wr_ack,
    input  logic                    cpuif_wr_err
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
