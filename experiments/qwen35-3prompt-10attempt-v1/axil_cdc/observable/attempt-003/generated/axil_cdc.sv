```verilog
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

    // Internal signals for CDC
    reg [ADDR_WIDTH-1:0]  s_awaddr, s_araddr;
    reg [2:0]             s_awprot, s_arprot;
    reg [DATA_WIDTH-1:0]  s_wdata;
    reg [STRB_WIDTH-1:0]  s_wstrb;
    reg                   s_awvalid, s_arvalid, s_wvalid;
    reg                   s_bvalid, s_rvalid;
    reg [1:0]             s_bresp, s_rresp;
    reg                   s_awready, s_arready, s_wready, s_bready, s_rready;

    // Master side signals
    wire [ADDR_WIDTH-1:0] m_awaddr, m_araddr;
    wire [2:0]            m_awprot, m_arprot;
    wire [DATA_WIDTH-1:0] m_wdata, m_rdata;
    wire [STRB_WIDTH-1:0] m_wstrb;
    wire                  m_awvalid, m_arvalid, m_wvalid;
    wire                  m_bvalid, m_rvalid;
    wire [1:0]            m_bresp, m_rresp;
    wire                  m_awready, m_arready, m_wready, m_bready, m_rready;

    // CDC Registers for Slave -> Master (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  m_awaddr_reg, m_araddr_reg;
    reg [2:0]             m_awprot_reg, m_arprot_reg;
    reg [DATA_WIDTH-1:0]  m_wdata_reg;
    reg [STRB_WIDTH-1:0]  m_wstrb_reg;
    reg                   m_awvalid_reg, m_arvalid_reg, m_wvalid_reg;
    reg                   m_bvalid_reg, m_rvalid_reg;
    reg [1:0]             m_bresp_reg, m_rresp_reg;
    reg                   m_awready_reg, m_arready_reg, m_wready_reg, m_bready_reg, m_rready_reg;

    // CDC Registers for Master -> Slave (Write Response, Read Response, Read Data)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg, s_wready_reg, s_bready_reg, s_rready_reg;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Write Data, Write Strb)
    reg [ADDR_WIDTH-1:0]  s_awaddr_reg, s_araddr_reg;
    reg [2:0]             s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0]  s_wdata_reg;
    reg [STRB_WIDTH-1:0]  s_wstrb_reg;
    reg                   s_awvalid_reg, s_arvalid_reg, s_wvalid_reg;
    reg                   s_bvalid_reg, s_rvalid_reg;
    reg [1:0]             s_bresp_reg, s_rresp_reg;
    reg                   s_awready_reg, s_arready_reg,