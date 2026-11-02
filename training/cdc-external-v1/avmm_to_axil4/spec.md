Implement the SystemVerilog module `avmm_to_axil4`.

Avalon-MM slave in, AXI4-Lite master out.

Functional contract and interface notes:

Module: avmm_to_axil4
Purpose: Avalon-MM slave in, AXI4-Lite master out.
Description:
The host front-end for Intel boards. Quartus has no JTAG-to-AXI master;
its debug master is the "JTAG to Avalon Master Bridge", an Avalon-MM
master. This block sits behind it and presents the AXI4-Lite master the
harness bridges expect, so an Intel harness has the same front-end
contract as the Xilinx harnesses' uart_axil_bridge.
One transfer at a time. waitrequest is held until the AXI side has
answered, which makes every write non-posted: a configuration write is
complete at the slave before the next command is accepted, and the order
the host wrote things in is the order they land. The JTAG master is
nowhere near fast enough for pipelining to matter.
Avalon side (pipelined, variable latency):
- byte addresses (declare addressUnits SYMBOLS if packaged for
Platform Designer); address and byteenable pass straight through
- a read is accepted in the clock its R beat arrives and returned one
clock later on readdatavalid, as Avalon requires
- a write is accepted in the clock its B response arrives;
writeresponsevalid follows one clock later for masters that use it
- response[1:0] carries RRESP/BRESP unchanged: the two encodings are
identical (00 OKAY, 10 SLVERR/SLAVEERROR, 11 DECERR/DECODEERROR)
- read and write together is illegal Avalon; the write wins
No width conversion. Both sides share ADDR_WIDTH and DATA_WIDTH; put a
width converter behind this block when they differ.
Parameters:
ADDR_WIDTH, DATA_WIDTH - shared by both sides
SKID_DEPTH_*           - the AXI4-Lite masters' channel skids
AXIL_PROT              - AWPROT/ARPROT driven on every command (Avalon
carries no protection bits)
Related Modules:
- uart_axil_bridge (the Xilinx-board front-end this one stands in for)
- wb4_to_axil4.sv (the same job from a Wishbone master)
Test:
Location: projects/components/utility-ip/converters/dv/tests/test_avmm_to_axil4.py

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
module avmm_to_axil4 #(
    parameter int ADDR_WIDTH    = 32,
    parameter int DATA_WIDTH    = 32,
    parameter int SKID_DEPTH_AW = 2,
    parameter int SKID_DEPTH_W  = 2,
    parameter int SKID_DEPTH_B  = 2,
    parameter int SKID_DEPTH_AR = 2,
    parameter int SKID_DEPTH_R  = 2,
    parameter logic [2:0] AXIL_PROT = 3'b000,
    // Short params
    parameter int AW = ADDR_WIDTH,
    parameter int DW = DATA_WIDTH,
    parameter int SW = DW/8
)
(
    input  logic              aclk,
    input  logic              aresetn,
    // Avalon-MM slave
    input  logic [AW-1:0]     s_avmm_address,
    input  logic              s_avmm_read,
    input  logic              s_avmm_write,
    input  logic [DW-1:0]     s_avmm_writedata,
    input  logic [SW-1:0]     s_avmm_byteenable,
    output logic              s_avmm_waitrequest,
    output logic [DW-1:0]     s_avmm_readdata,
    output logic              s_avmm_readdatavalid,
    output logic [1:0]        s_avmm_response,
    output logic              s_avmm_writeresponsevalid,
    // AXI4-Lite master
    output logic [AW-1:0]     m_axil_awaddr,
    output logic [2:0]        m_axil_awprot,
    output logic              m_axil_awvalid,
    input  logic              m_axil_awready,
    output logic [DW-1:0]     m_axil_wdata,
    output logic [SW-1:0]     m_axil_wstrb,
    output logic              m_axil_wvalid,
    input  logic              m_axil_wready,
    input  logic [1:0]        m_axil_bresp,
    input  logic              m_axil_bvalid,
    output logic              m_axil_bready,
    output logic [AW-1:0]     m_axil_araddr,
    output logic [2:0]        m_axil_arprot,
    output logic              m_axil_arvalid,
    input  logic              m_axil_arready,
    input  logic [DW-1:0]     m_axil_rdata,
    input  logic [1:0]        m_axil_rresp,
    input  logic              m_axil_rvalid,
    output logic              m_axil_rready,
    output logic              busy
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
