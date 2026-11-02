Implement the SystemVerilog module `apb5_to_axi4`.

Implement apb5 to axi4 using the interface and behavioral contract below.

Functional contract and interface notes:

apb5_to_axi4: APB5 completer in, AXI4 requester out.
apb4_to_axi4 with the APB5 sideband. apb5_slave carries PAUSER/PWUSER
through its command packet and PRUSER/PBUSER through its response packet;
this module maps them onto the AXI USER fields:
PAUSER -> awuser / aruser        PWUSER -> wuser
ruser  -> PRUSER                 buser  -> PBUSER
The APB and AXI USER widths are independent parameters and the mapping
is a plain size cast: the low bits travel, anything wider is zero-filled
or dropped. Inside the bridge the AXI USER width is 1, so one bit of
PAUSER reaches the fabric -- the same width the AXI5-Lite slave side
exposes (axil5_sideband.AXIL5_USER_WIDTH), so an APB5 requester's user
bit can be observed at an AXI5-Lite completer.
PWAKEUP is requester-driven (IHI 0024E 3.7.2, Table 3-7): it is an input
here and is passed to apb5_slave's s_apb_PWAKEUP input. Nothing on the
AXI side carries it, so it goes no further.
Interface parity is not part of this surface (Check_Type = False): the
*CHK signals are conditional on Check_Type (IHI 0024E Table B-2) and so
are absent from this module's ports. apb5_slave is built with
ENABLE_PARITY=0, which leaves its check inputs unchecked and drives its
check outputs LOW; the check inputs, PWAKEUPCHK included, are tied LOW
(the same constant apb5_master drives on its check outputs when parity
is off) and the check outputs are left open.

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
module apb5_to_axi4 #(
    parameter int APB_ADDR_WIDTH  = 32,
    parameter int APB_DATA_WIDTH  = 32,
    parameter int APB_AUSER_WIDTH = 1,
    parameter int APB_WUSER_WIDTH = 1,
    parameter int APB_RUSER_WIDTH = 1,
    parameter int APB_BUSER_WIDTH = 1,
    parameter int AXI_ID_WIDTH    = 1,
    parameter int AXI_USER_WIDTH  = 1,
    parameter logic [AXI_ID_WIDTH-1:0] DEFAULT_ID = '0,
    parameter int DEPTH           = 2,
    parameter int AW  = APB_ADDR_WIDTH,
    parameter int DW  = APB_DATA_WIDTH,
    parameter int SW  = APB_DATA_WIDTH / 8,
    parameter int AUW = APB_AUSER_WIDTH,
    parameter int WUW = APB_WUSER_WIDTH,
    parameter int RUW = APB_RUSER_WIDTH,
    parameter int BUW = APB_BUSER_WIDTH,
    parameter int IW  = AXI_ID_WIDTH,
    parameter int UW  = AXI_USER_WIDTH
) (
    input  logic            aclk,
    input  logic            aresetn,
    // APB5 completer (external requester drives these)
    input  logic            s_apb_PSEL,
    input  logic            s_apb_PENABLE,
    output logic            s_apb_PREADY,
    input  logic [AW-1:0]   s_apb_PADDR,
    input  logic            s_apb_PWRITE,
    input  logic [DW-1:0]   s_apb_PWDATA,
    input  logic [SW-1:0]   s_apb_PSTRB,
    input  logic [2:0]      s_apb_PPROT,
    output logic [DW-1:0]   s_apb_PRDATA,
    output logic            s_apb_PSLVERR,
    input  logic [AUW-1:0]  s_apb_PAUSER,
    input  logic [WUW-1:0]  s_apb_PWUSER,
    input  logic            s_apb_PWAKEUP,
    output logic [RUW-1:0]  s_apb_PRUSER,
    output logic [BUW-1:0]  s_apb_PBUSER,
    // AXI4 requester
    output logic [IW-1:0]   m_axi_awid,
    output logic [AW-1:0]   m_axi_awaddr,
    output logic [7:0]      m_axi_awlen,
    output logic [2:0]      m_axi_awsize,
    output logic [1:0]      m_axi_awburst,
    output logic            m_axi_awlock,
    output logic [3:0]      m_axi_awcache,
    output logic [2:0]      m_axi_awprot,
    output logic [3:0]      m_axi_awqos,
    output logic [3:0]      m_axi_awregion,
    output logic [UW-1:0]   m_axi_awuser,
    output logic            m_axi_awvalid,
    input  logic            m_axi_awready,
    output logic [DW-1:0]   m_axi_wdata,
    output logic [SW-1:0]   m_axi_wstrb,
    output logic            m_axi_wlast,
    output logic [UW-1:0]   m_axi_wuser,
    output logic            m_axi_wvalid,
    input  logic            m_axi_wready,
    input  logic [IW-1:0]   m_axi_bid,
    input  logic [1:0]      m_axi_bresp,
    input  logic [UW-1:0]   m_axi_buser,
    input  logic            m_axi_bvalid,
    output logic            m_axi_bready,
    output logic [IW-1:0]   m_axi_arid,
    output logic [AW-1:0]   m_axi_araddr,
    output logic [7:0]      m_axi_arlen,
    output logic [2:0]      m_axi_arsize,
    output logic [1:0]      m_axi_arburst,
    output logic            m_axi_arlock,
    output logic [3:0]      m_axi_arcache,
    output logic [2:0]      m_axi_arprot,
    output logic [3:0]      m_axi_arqos,
    output logic [3:0]      m_axi_arregion,
    output logic [UW-1:0]   m_axi_aruser,
    output logic            m_axi_arvalid,
    input  logic            m_axi_arready,
    input  logic [IW-1:0]   m_axi_rid,
    input  logic [DW-1:0]   m_axi_rdata,
    input  logic [1:0]      m_axi_rresp,
    input  logic            m_axi_rlast,
    input  logic [UW-1:0]   m_axi_ruser,
    input  logic            m_axi_rvalid,
    output logic            m_axi_rready
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
