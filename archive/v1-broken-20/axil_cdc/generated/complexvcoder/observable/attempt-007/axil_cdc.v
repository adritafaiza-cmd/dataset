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

    // Internal signals for state machine and handshake signals
    reg [ADDR_WIDTH-1:0] s_awaddr_reg, m_awaddr_reg;
    reg [2:0] s_awprot_reg, m_awprot_reg;
    reg s_awvalid_reg, m_awvalid_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg, m_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg, m_wstrb_reg;
    reg s_wvalid_reg, m_wvalid_reg;
    reg s_bready_reg, m_bready_reg;
    reg [ADDR_WIDTH-1:0] s_araddr_reg, m_araddr_reg;
    reg [2:0] s_arprot_reg, m_arprot_reg;
    reg s_arvalid_reg, m_arvalid_reg;
    reg s_rready_reg, m_rready_reg;

    // Internal signals for handshake signals
    reg s_awready_reg, s_wready_reg, s_bvalid_reg, s_arready_reg, s_rvalid_reg;
    reg m_awready_reg, m_wready_reg, m_bvalid_reg, m_arready_reg, m_rvalid_reg;

    // Handshake logic for write address channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= 0;
            s_awprot_reg <= 0;
            s_awvalid_reg <= 0;
            m_awready_reg <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awvalid_reg <= 0;
            end
            m_awready_reg <= s_axil_awready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= 0;
            m_awprot_reg <= 0;
            m_awvalid_reg <= 0;
        end else begin
            if (m_axil_awvalid && m_awready_reg) begin
                m_awaddr_reg <= m_axil_awaddr;
                m_awprot_reg <= m_axil_awprot;
                m_awvalid_reg <= 0;
            end
        end
    end

    // Handshake logic for write data channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_wvalid_reg <= 0;
            m_wready_reg <= 0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_wvalid_reg <= 0;
            end
            m_wready_reg <= s_axil_wready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wvalid_reg <= 0;
        end else begin
            if (m_axil_wvalid && m_wready_reg) begin
                m_wdata_reg <= m_axil_wdata;
                m_wstrb_reg <= m_axil_wstrb;
                m_wvalid_reg <= 0;
            end
        end
    end

    // Handshake logic for write response channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bready_reg <= 0;
        end else begin
            s_bready_reg <= s_axil_bready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bvalid_reg <= 0;
        end else begin
            if (m_axil_bvalid && m_bready_reg) begin
                m_bvalid_reg <= 0;
            end
        end
    end

    // Handshake logic for read address channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= 0;
            s_arprot_reg <= 0;
            s_arvalid_reg <= 0;
            m_arready_reg <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_arvalid_reg <= 0;
            end
            m_arready_reg <= s_axil_arready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg <= 0;
            m_arprot_reg <= 0;
            m_arvalid_reg <= 0;
        end else begin
            if (m_axil_arvalid && m_arready_reg) begin
                m_araddr_reg <= m_axil_araddr;
                m_arprot_reg <= m_axil_arprot;
                m_arvalid_reg <= 0;
            end
        end
    end

    // Handshake logic for read data channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rready_reg <= 0;
        end else begin
            s_rready_reg <= s_axil_rready;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rvalid_reg <= 0;
            m_axil_rdata <= 0;
            m_axil_rresp <= 0;
        end else begin
            if (m_axil_rvalid && m_rready_reg) begin
                m_rvalid_reg <= 0;
            end
            if (m_rvalid_reg) begin
                m_axil_rdata <= m_rdata_reg;
                m_axil_rresp <= m_rresp_reg;
            end
        end
    end

    // Assign outputs to interfaces
    assign s_axil_awready = m_awready_reg;
    assign s_axil_wready = m_wready_reg;
    assign s_axil_bvalid = m_bvalid_reg;
    assign s_axil_arready = m_arready_reg;
    assign s_axil_rvalid = m_rvalid_reg;

    assign m_axil_awaddr = s_awaddr_reg;
    assign m_axil_awprot = s_awprot_reg;
    assign m_axil_awvalid = s_awvalid_reg;
    assign m_axil_wdata = s_wdata_reg;
    assign m_axil_wstrb = s_wstrb_reg;
    assign m_axil_wvalid = s_wvalid_reg;
    assign m_axil_bready = s_bready_reg;
    assign m_axil_araddr = s_araddr_reg;
    assign m_axil_arprot = s_arprot_reg;
    assign m_axil_arvalid = s_arvalid_reg;
    assign m_axil_rready = s_rready_reg;

endmodule
