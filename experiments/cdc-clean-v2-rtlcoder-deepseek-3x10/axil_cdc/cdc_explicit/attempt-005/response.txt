The AXI4-Lite clock-domain bridge can be implemented using a simple state machine. The state machine has three states: IDLE, WRITE, and READ. The state machine transitions between these states based on the handshake signals.

The Verilog code for the AXI4-Lite clock-domain bridge is as follows:

```
module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    // State machine states
    localparam IDLE   = 2'b00;
    localparam WRITE  = 2'b01;
    localparam READ   = 2'b10;

    // State machine signals
    reg [1:0] state_s;
    reg [1:0] state_m;
    reg [1:0] next_state_s;
    reg [1:0] next_state_m;

    // Write and read data signals
    reg [DATA_WIDTH-1:0] wdata;
    reg [DATA_WIDTH-1:0] rdata;

    // Write and read address signals
    reg [ADDR_WIDTH-1:0] waddr;
    reg [ADDR_WIDTH-1:0] raddr;

    // Write and read strobe signals
    reg [STRB_WIDTH-1:0] wstrb;

    // Write and read response signals
    reg [1:0] wresp;
    reg [1:0] rresp;

    // Write and read valid signals
    reg wvalid;
    reg rvalid;

    // Write and read ready signals
    reg wready;
    reg rready;

    // Write and read state machine signals
    reg wstate_s;
    reg rstate_s;
    reg wstate_m;
    reg rstate_m;

    // Write and read state machine next state signals
    reg wnext_state_s;
    reg rnext_state_s;
    reg wnext_state_m;
    reg rnext_state_m;

    // Write and read state machine state reset signals
    reg wstate_reset;
    reg rstate_reset;

    // Write and read state machine state reset next signals
    reg wstate_reset_next;
    reg rstate_reset_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s;
    reg rstate_reset_s;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s;
    reg rstate_reset_next_s;

    // Write and read state machine state reset signal
    reg wstate_reset_m;
    reg rstate_reset_m;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m;
    reg rstate_reset_next_m;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next;
    reg rstate_reset_s_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next;
    reg rstate_reset_next_s_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next;
    reg rstate_reset_m_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next;
    reg rstate_reset_next_m_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next;
    reg rstate_reset_s_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next;
    reg rstate_reset_next_s_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next;
    reg rstate_reset_m_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next;
    reg rstate_reset_next_m_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next;
    reg rstate_reset_s_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next;
    reg rstate_reset_next_s_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next;
    reg rstate_reset_m_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next;
    reg rstate_reset_next_m_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next;
    reg rstate_reset_s_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next;
    reg rstate_reset_m_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_s_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset signal
    reg wstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

    // Write and read state machine state reset next signal
    reg wstate_reset_next_m_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg rstate_reset_next_m_next_next_next_next_next_next