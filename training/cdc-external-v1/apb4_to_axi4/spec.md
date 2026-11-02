Implement the SystemVerilog module `apb4_to_axi4`.

Implement apb4 to axi4 using the interface and behavioral contract below.

Functional contract and interface notes:

apb4_to_axi4: APB4 completer in, AXI4 requester out.
The mirror of axi4_to_apb4_shim. An APB4 requester (a small CPU, a debug
port, a register sequencer) drives this module's s_apb_* completer
surface and every transfer comes out as one single-beat AXI4 transaction
on m_axi_*. Two proven pieces, no new protocol logic:
apb4_slave          PSEL/PENABLE/PREADY handshake, skid-buffered
cmd/rsp pair, orphan-response guard
apb_cmdrsp_to_axi4  one command -> one AXI4 write or read -> one rsp
APB4 has no USER signals, so the AXI USER fields are driven to zero and
the returned ones are dropped here. The bridge generator instantiates
this for a master port with protocol = "apb".

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
module apb4_to_axi4 #(
    parameter int APB_ADDR_WIDTH  = 32,
    parameter int APB_DATA_WIDTH  = 32,
    parameter int AXI_ID_WIDTH    = 1,
    parameter int AXI_USER_WIDTH  = 1,
    parameter logic [AXI_ID_WIDTH-1:0] DEFAULT_ID = '0,
    // Skid depth inside apb4_slave (cmd and rsp).
    parameter int DEPTH           = 2,
    parameter int AW = APB_ADDR_WIDTH,
    parameter int DW = APB_DATA_WIDTH,
    parameter int SW = APB_DATA_WIDTH / 8,
    parameter int IW = AXI_ID_WIDTH,
    parameter int UW = AXI_USER_WIDTH
) (
    input  logic            aclk,
    input  logic            aresetn,
    // APB4 completer (external requester drives these)
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
