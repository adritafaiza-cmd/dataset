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

    // ------------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
    wire [2:0]            s_axil_awprot_reg;
    wire                  s_axil_awvalid_reg;
    wire                  s_axil_awready_reg;
    wire [DATA_WIDTH-1:0] s_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    wire                  s_axil_wvalid_reg;
    wire                  s_axil_wready_reg;
    wire [1:0]            s_axil_bresp_reg;
    wire                  s_axil_bvalid_reg;
    wire                  s_axil_bready_reg;
    wire [ADDR_WIDTH-1:0] s_axil_araddr_reg;
    wire [2:0]            s_axil_arprot_reg;
    wire                  s_axil_arvalid_reg;
    wire                  s_axil_arready_reg;
    wire [DATA_WIDTH-1:0] s_axil_rdata_reg;
    wire [1:0]            s_axil_rresp_reg;
    wire                  s_axil_rvalid_reg;
    wire                  s_axil_rready_reg;

    wire [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
    wire [2:0]            m_axil_awprot_reg;
    wire                  m_axil_awvalid_reg;
    wire                  m_axil_awready_reg;
    wire [DATA_WIDTH-1:0] m_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    wire                  m_axil_wvalid_reg;
    wire                  m_axil_wready_reg;
    wire [1:0]            m_axil_bresp_reg;
    wire                  m_axil_bvalid_reg;
    wire                  m_axil_bready_reg;
    wire [ADDR_WIDTH-1:0] m_axil_araddr_reg;
    wire [2:0]            m_axil_arprot_reg;
    wire                  m_axil_arvalid_reg;
    wire                  m_axil_arready_reg;
    wire [DATA_WIDTH-1:0] m_axil_rdata_reg;
    wire [1:0]            m_axil_rresp_reg;
    wire                  m_axil_rvalid_reg;
    wire                  m_axil_rready_reg;

    // CDC Registers for Slave -> Master
    reg [ADDR_WIDTH-1:0] s2m_awaddr;
    reg [2:0]            s2m_awprot;
    reg                  s2m_awvalid;
    reg                  s2m_awready;
    reg [DATA_WIDTH-1:0] s2m_wdata;
    reg [STRB_WIDTH-1:0] s2m_wstrb;
    reg                  s2m_wvalid;
    reg                  s2m_wready;
    reg [1:0]            s2m_bresp;
    reg                  s2m_bvalid;
    reg                  s2m_bready;
    reg [ADDR_WIDTH-1:0] s2m_araddr;
    reg [2:0]            s2m_arprot;
    reg                  s2m_arvalid;
    reg                  s2m_arready;
    reg [DATA_WIDTH-1:0] s2m_rdata;
    reg [1:0]            s2m_rresp;
    reg                  s2m_rvalid;
    reg                  s2m_rready;

    // CDC Registers for Master -> Slave
    reg [ADDR_WIDTH-1:0] m2s_awaddr;
    reg [2:0]            m2s_awprot;
    reg                  m2s_awvalid;
    reg                  m2s_awready;
    reg [DATA_WIDTH-1:0] m2s_wdata;
    reg [STRB_WIDTH-1:0] m2s_wstrb;
    reg                  m2s_wvalid;
    reg                  m2s_wready;
    reg [1:0]            m2s_bresp;
    reg                  m2s_bvalid;
    reg                  m2s_bready;
    reg [ADDR_WIDTH-1:0] m2s_araddr;
    reg [2:0]            m2s_arprot;
    reg                  m2s_arvalid;
    reg                  m2s_arready;
    reg [DATA_WIDTH-1:0] m2s_rdata;
    reg [1:0]            m2s_rresp;
    reg                  m2s_rvalid;
    reg                  m2s_rready;

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr    <= '{default: 0};
            s2m_awprot    <= 3'b000;
            s2m_awvalid   <= 1'b0;
            s2m_awready   <= 1'b1;
            s2m_wdata     <= '{default: 0};
            s2m_wstrb     <= '{default: 0};
            s2m_wvalid    <= 1'b0;
            s2m_wready    <= 1'b1;
            s2m_bresp     <= 2'b00;
            s2m_bvalid    <= 1'b0;
            s2m_bready    <= 1'b1;
            s2m_araddr    <= '{default: 0};
            s2m_arprot    <= 3'b000;
            s2m_arvalid   <= 1'b0;
            s2m_arready   <= 1'b1;
            s2m_rdata     <= '{default: 0};
            s2m_rresp     <= 2'b00;
            s2m_rvalid    <= 1'b0;
            s2m_rready    <= 1'b1;
        end else begin
            // Write Address
            s2m_awaddr    <= s_axil_awaddr_reg;
            s2m_awprot    <= s_axil_awprot_reg;
            s2m_awvalid   <= s_axil_awvalid_reg;
            s2m_awready   <= s_axil_awready_reg;
            
            // Write Data
            s2m_wdata     <= s_axil_wdata_reg;
            s2m_wstrb     <= s_axil_wstrb_reg;
            s2m_wvalid    <= s_axil_wvalid_reg;
            s2m_wready    <= s_axil_wready_reg;
            
            // Read Address
            s2m_araddr    <= s_axil_araddr_reg;
            s2m_arprot    <= s_axil_arprot_reg;
            s2m_arvalid   <= s_axil_arvalid_reg;
            s2m_arready   <= s_axil_arready_reg;
            
            // Write Response
            s2m_bresp     <= s_axil_bresp_reg;
            s2m_bvalid    <= s_axil_bvalid_reg;
            s2m_bready    <= s_axil_bready_reg;
            
            // Read Data
            s2m_rdata     <= s_axil_rdata_reg;
            s2m_rresp     <= s_axil_rresp_reg;
            s2m_rvalid    <= s_axil_rvalid_reg;
            s2m_rready    <= s_axil_rready_reg;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_awaddr    <= '{default: 0};
            m2s_awprot    <= 3'b000;
            m2s_awvalid   <= 1'b0;
            m2s_awready   <= 1'b1;
            m2s_wdata     <= '{default: 0};
            m2s_wstrb     <= '{default: 0};
            m2s_wvalid    <= 1'b0;
            m2s_wready    <= 1'b1;
            m2s_bresp     <= 2'b00;
            m2s_bvalid    <= 1'b0;
            m2s_bready    <= 1'b1;
            m2s_araddr    <= '{default: 0};
            m2s_arprot    <= 3'b000;
            m2s_arvalid   <= 1'b0;
            m2s_arready   <= 1'b1;
            m2s_rdata     <= '{default: 0};
            m2s_rresp     <= 2'b00;
            m2s_rvalid    <= 1'b0;
            m2s_rready    <= 1'b1;
        end else begin
            // Write Address
            m2s_awaddr    <= m_axil_awaddr_reg;
            m2s_awprot    <= m_axil_awprot_reg;
            m2s_awvalid   <= m_axil_awvalid_reg;
            m2s_awready   <= m_axil_awready_reg;
            
            // Write Data
            m2s_wdata     <= m_axil_wdata_reg;
            m2s_wstrb     <= m_axil_wstrb_reg;
            m2s_wvalid    <= m_axil_wvalid_reg;
            m2s_wready    <= m_axil_wready_reg;
            
            // Read Address
            m2s_araddr    <= m_axil_araddr_reg;
            m2s_arprot    <= m_axil_arprot_reg;
            m2s_arvalid   <= m_axil_arvalid_reg;
            m2s_arready   <= m_axil_arready_reg;
            
            // Write Response
            m2s_bresp     <= m_axil_bresp_reg;
            m2s_bvalid    <= m_axil_bvalid_reg;
            m2s_bready    <= m_axil_bready_reg;
            
            // Read Data
            m2s_rdata     <= m_axil_rdata_reg;
            m2s_rresp     <= m_axil_rresp_reg;
            m2s_rvalid    <= m_axil_rvalid_reg;
            m2s_rready    <= m_axil_rready_reg;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Read Data, Write Response)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_rdata    <= '{default: 0};
            m_axil_rresp    <= 2'b00;
            m_axil_rvalid   <= 1'b0;
            m_axil_rready   <= 1'b1;
            m_axil_bresp    <= 2'b00;
            m_axil_bvalid   <= 1'b0;
            m_axil_bready   <= 1'b1;
        end else begin
            m_axil_rdata    <= s2m_rdata;
            m_axil_rresp    <= s2m_rresp;
            m_axil_rvalid   <= s2m_rvalid;
            m_axil_rready   <= s2m_rready;
            m_axil_bresp    <= s2m_bresp;
            m_axil_bvalid   <= s2m_bvalid;
            m_axil_bready   <= s2m_bready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Read Data, Write Response)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_rdata    <= '{default: 0};
            s_axil_rresp    <= 2'b00;
            s_axil_rvalid   <= 1'b0;
            s_axil_rready   <= 1'b1;
            s_axil_bresp    <= 2'b00;
            s_axil_bvalid   <= 1'b0;
            s_axil_bready   <= 1'b1;
        end else begin
            s_axil_rdata    <= m2s_rdata;
            s_axil_rresp    <= m2s_rresp;
            s_axil_rvalid   <= m2s_rvalid;
            s_axil_rready   <= m2s_rready;
            s_axil_bresp    <= m2s_bresp;
            s_axil_bvalid   <= m2s_bvalid;
            s_axil_bready   <= m2s_bready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m_wstrb;
            m_axil_wvalid    <= s2m_wvalid;
            m_axil_wready    <= s2m_wready;
            m_axil_araddr    <= s2m_araddr;
            m_axil_arprot    <= s2m_arprot;
            m_axil_arvalid   <= s2m_arvalid;
            m_axil_arready   <= s2m_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr    <= '{default: 0};
            s_axil_awprot    <= 3'b000;
            s_axil_awvalid   <= 1'b0;
            s_axil_awready   <= 1'b1;
            s_axil_wdata     <= '{default: 0};
            s_axil_wstrb     <= '{default: 0};
            s_axil_wvalid    <= 1'b0;
            s_axil_wready    <= 1'b1;
            s_axil_araddr    <= '{default: 0};
            s_axil_arprot    <= 3'b000;
            s_axil_arvalid   <= 1'b0;
            s_axil_arready   <= 1'b1;
        end else begin
            s_axil_awaddr    <= m2s_awaddr;
            s_axil_awprot    <= m2s_awprot;
            s_axil_awvalid   <= m2s_awvalid;
            s_axil_awready   <= m2s_awready;
            s_axil_wdata     <= m2s_wdata;
            s_axil_wstrb     <= m2s_wstrb;
            s_axil_wvalid    <= m2s_wvalid;
            s_axil_wready    <= m2s_wready;
            s_axil_araddr    <= m2s_araddr;
            s_axil_arprot    <= m2s_arprot;
            s_axil_arvalid   <= m2s_arvalid;
            s_axil_arready   <= m2s_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m_wstrb;
            m_axil_wvalid    <= s2m_wvalid;
            m_axil_wready    <= s2m_wready;
            m_axil_araddr    <= s2m_araddr;
            m_axil_arprot    <= s2m_arprot;
            m_axil_arvalid   <= s2m_arvalid;
            m_axil_arready   <= s2m_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr    <= '{default: 0};
            s_axil_awprot    <= 3'b000;
            s_axil_awvalid   <= 1'b0;
            s_axil_awready   <= 1'b1;
            s_axil_wdata     <= '{default: 0};
            s_axil_wstrb     <= '{default: 0};
            s_axil_wvalid    <= 1'b0;
            s_axil_wready    <= 1'b1;
            s_axil_araddr    <= '{default: 0};
            s_axil_arprot    <= 3'b000;
            s_axil_arvalid   <= 1'b0;
            s_axil_arready   <= 1'b1;
        end else begin
            s_axil_awaddr    <= m2s_awaddr;
            s_axil_awprot    <= m2s_awprot;
            s_axil_awvalid   <= m2s_awvalid;
            s_axil_awready   <= m2s_awready;
            s_axil_wdata     <= m2s_wdata;
            s_axil_wstrb     <= m2s_wstrb;
            s_axil_wvalid    <= m2s_wvalid;
            s_axil_wready    <= m2s_wready;
            s_axil_araddr    <= m2s_araddr;
            s_axil_arprot    <= m2s_arprot;
            s_axil_arvalid   <= m2s_arvalid;
            s_axil_arready   <= m2s_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m_wstrb;
            m_axil_wvalid    <= s2m_wvalid;
            m_axil_wready    <= s2m_wready;
            m_axil_araddr    <= s2m_araddr;
            m_axil_arprot    <= s2m_arprot;
            m_axil_arvalid   <= s2m_arvalid;
            m_axil_arready   <= s2m_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr    <= '{default: 0};
            s_axil_awprot    <= 3'b000;
            s_axil_awvalid   <= 1'b0;
            s_axil_awready   <= 1'b1;
            s_axil_wdata     <= '{default: 0};
            s_axil_wstrb     <= '{default: 0};
            s_axil_wvalid    <= 1'b0;
            s_axil_wready    <= 1'b1;
            s_axil_araddr    <= '{default: 0};
            s_axil_arprot    <= 3'b000;
            s_axil_arvalid   <= 1'b0;
            s_axil_arready   <= 1'b1;
        end else begin
            s_axil_awaddr    <= m2s_awaddr;
            s_axil_awprot    <= m2s_awprot;
            s_axil_awvalid   <= m2s_awvalid;
            s_axil_awready   <= m2s_awready;
            s_axil_wdata     <= m2s_wdata;
            s_axil_wstrb     <= m2s_wstrb;
            s_axil_wvalid    <= m2s_wvalid;
            s_axil_wready    <= m2s_wready;
            s_axil_araddr    <= m2s_araddr;
            s_axil_arprot    <= m2s_arprot;
            s_axil_arvalid   <= m2s_arvalid;
            s_axil_arready   <= m2s_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m_wstrb;
            m_axil_wvalid    <= s2m_wvalid;
            m_axil_wready    <= s2m_wready;
            m_axil_araddr    <= s2m_araddr;
            m_axil_arprot    <= s2m_arprot;
            m_axil_arvalid   <= s2m_arvalid;
            m_axil_arready   <= s2m_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr    <= '{default: 0};
            s_axil_awprot    <= 3'b000;
            s_axil_awvalid   <= 1'b0;
            s_axil_awready   <= 1'b1;
            s_axil_wdata     <= '{default: 0};
            s_axil_wstrb     <= '{default: 0};
            s_axil_wvalid    <= 1'b0;
            s_axil_wready    <= 1'b1;
            s_axil_araddr    <= '{default: 0};
            s_axil_arprot    <= 3'b000;
            s_axil_arvalid   <= 1'b0;
            s_axil_arready   <= 1'b1;
        end else begin
            s_axil_awaddr    <= m2s_awaddr;
            s_axil_awprot    <= m2s_awprot;
            s_axil_awvalid   <= m2s_awvalid;
            s_axil_awready   <= m2s_awready;
            s_axil_wdata     <= m2s_wdata;
            s_axil_wstrb     <= m2s_wstrb;
            s_axil_wvalid    <= m2s_wvalid;
            s_axil_wready    <= m2s_wready;
            s_axil_araddr    <= m2s_araddr;
            s_axil_arprot    <= m2s_arprot;
            s_axil_arvalid   <= m2s_arvalid;
            s_axil_arready   <= m2s_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m_wstrb;
            m_axil_wvalid    <= s2m_wvalid;
            m_axil_wready    <= s2m_wready;
            m_axil_araddr    <= s2m_araddr;
            m_axil_arprot    <= s2m_arprot;
            m_axil_arvalid   <= s2m_arvalid;
            m_axil_arready   <= s2m_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Slave -> Master (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr    <= '{default: 0};
            s_axil_awprot    <= 3'b000;
            s_axil_awvalid   <= 1'b0;
            s_axil_awready   <= 1'b1;
            s_axil_wdata     <= '{default: 0};
            s_axil_wstrb     <= '{default: 0};
            s_axil_wvalid    <= 1'b0;
            s_axil_wready    <= 1'b1;
            s_axil_araddr    <= '{default: 0};
            s_axil_arprot    <= 3'b000;
            s_axil_arvalid   <= 1'b0;
            s_axil_arready   <= 1'b1;
        end else begin
            s_axil_awaddr    <= m2s_awaddr;
            s_axil_awprot    <= m2s_awprot;
            s_axil_awvalid   <= m2s_awvalid;
            s_axil_awready   <= m2s_awready;
            s_axil_wdata     <= m2s_wdata;
            s_axil_wstrb     <= m2s_wstrb;
            s_axil_wvalid    <= m2s_wvalid;
            s_axil_wready    <= m2s_wready;
            s_axil_araddr    <= m2s_araddr;
            s_axil_arprot    <= m2s_arprot;
            s_axil_arvalid   <= m2s_arvalid;
            s_axil_arready   <= m2s_arready;
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Master -> Slave (Write Address, Write Data, Read Address)
    // ------------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr    <= '{default: 0};
            m_axil_awprot    <= 3'b000;
            m_axil_awvalid   <= 1'b0;
            m_axil_awready   <= 1'b1;
            m_axil_wdata     <= '{default: 0};
            m_axil_wstrb     <= '{default: 0};
            m_axil_wvalid    <= 1'b0;
            m_axil_wready    <= 1'b1;
            m_axil_araddr    <= '{default: 0};
            m_axil_arprot    <= 3'b000;
            m_axil_arvalid   <= 1'b0;
            m_axil_arready   <= 1'b1;
        end else begin
            m_axil_awaddr    <= s2m_awaddr;
            m_axil_awprot    <= s2m_awprot;
            m_axil_awvalid   <= s2m_awvalid;
            m_axil_awready   <= s2m_awready;
            m_axil_wdata     <= s2m_wdata;
            m_axil_wstrb     <= s2m