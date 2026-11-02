Implement the SystemVerilog module `apb_cmdrsp_to_axi4`.

Implement apb cmdrsp to axi4 using the interface and behavioral contract below.

Functional contract and interface notes:

apb_cmdrsp_to_axi4: APB command/response stream -> AXI4 requester.
The requester half of an APB-in / AXI4-out converter. apb4_slave and
apb5_slave already turn the APB completer surface into a one-outstanding
cmd/rsp pair (PSEL/PENABLE/PREADY handshake, skid buffers, orphan-response
guard); this module turns each command into exactly one single-beat AXI4
transaction and its response back into one rsp beat:
pwrite=1 : AW + W (awlen=0, wlast=1)  ->  B    -> rsp (pslverr = bresp[1])
pwrite=0 : AR      (arlen=0)          ->  R    -> rsp (prdata, pslverr = rresp[1])
APB is strictly one-outstanding, so there is never more than one AXI
transaction in flight and the response needs no ID matching: the AXI ID
is a constant (DEFAULT_ID). AW and W are presented together and each is
held until its own handshake, so the requester is legal against a slave
that accepts W before AW or AW before W.
Both SLVERR and DECERR fold to PSLVERR -- APB has one error bit. The
USER fields ride through unchanged at AXI_USER_WIDTH; the APB4 wrapper
ties them to zero, the APB5 wrapper carries PAUSER/PWUSER/PRUSER/PBUSER.
R is drained to RLAST even though every request is one beat, so a slave
that answers with more beats than asked cannot wedge the port; only the
first beat's data is returned.

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
module apb_cmdrsp_to_axi4 #(
    parameter int AXI_ID_WIDTH    = 1,
    parameter int AXI_ADDR_WIDTH  = 32,
    parameter int AXI_DATA_WIDTH  = 32,
    parameter int AXI_USER_WIDTH  = 1,
    // Constant ID on every request. APB carries no ID, so one value is
    // enough; the bridge prepends its own master index anyway.
    parameter logic [AXI_ID_WIDTH-1:0] DEFAULT_ID = '0,
    // AxCACHE for every request. Device non-bufferable, the natural
    // attribute for a peripheral-bus requester.
    parameter logic [3:0] DEFAULT_CACHE = 4'b0000,
    parameter int IW = AXI_ID_WIDTH,
    parameter int AW = AXI_ADDR_WIDTH,
    parameter int DW = AXI_DATA_WIDTH,
    parameter int SW = AXI_DATA_WIDTH / 8,
    parameter int UW = AXI_USER_WIDTH
) (
    input  logic            aclk,
    input  logic            aresetn,
    // Command stream from apb4_slave / apb5_slave
    input  logic            cmd_valid,
    output logic            cmd_ready,
    input  logic            cmd_pwrite,
    input  logic [AW-1:0]   cmd_paddr,
    input  logic [DW-1:0]   cmd_pwdata,
    input  logic [SW-1:0]   cmd_pstrb,
    input  logic [2:0]      cmd_pprot,
    input  logic [UW-1:0]   cmd_auser,
    input  logic [UW-1:0]   cmd_wuser,
    // Response stream back to it
    output logic            rsp_valid,
    input  logic            rsp_ready,
    output logic [DW-1:0]   rsp_prdata,
    output logic            rsp_pslverr,
    output logic [UW-1:0]   rsp_ruser,
    output logic [UW-1:0]   rsp_buser,
    // AXI4 master
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
