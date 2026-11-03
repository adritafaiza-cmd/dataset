module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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

// Write Channel
reg [ADDR_WIDTH-1:0]  s_awaddr;
reg [2:0]             s_awprot;
reg                   s_awvalid;
reg                   s_awready;
reg [DATA_WIDTH-1:0]  s_wdata;
reg [STRB_WIDTH-1:0]  s_wstrb;
reg                   s_wvalid;
reg                   s_wready;
reg [1:0]             s_bresp;
reg                   s_bvalid;
reg                   s_bready;

reg [ADDR_WIDTH-1:0]  m_awaddr;
reg [2:0]             m_awprot;
reg                   m_awvalid;
reg                   m_awready;
reg [DATA_WIDTH-1:0]  m_wdata;
reg [STRB_WIDTH-1:0]  m_wstrb;
reg                   m_wvalid;
reg                   m_wready;
reg [1:0]             m_bresp;
reg                   m_bvalid;
reg                   m_bready;

// Read Channel
reg [ADDR_WIDTH-1:0]  s_araddr;
reg [2:0]             s_arprot;
reg                   s_arvalid;
reg                   s_arready;
reg [DATA_WIDTH-1:0]  s_rdata;
reg [1:0]             s_rresp;
reg                   s_rvalid;
reg                   s_rready;

reg [ADDR_WIDTH-1:0]  m_araddr;
reg [2:0]             m_arprot;
reg                   m_arvalid;
reg                   m_arready;
reg [DATA_WIDTH-1:0]  m_rdata;
reg [1:0]             m_rresp;
reg                   m_rvalid;
reg                   m_rready;

// Clock Domain Crossing
reg                   s_awvalid_sync;
reg                   s_wvalid_sync;
reg                   s_arvalid_sync;
reg                   m_bvalid_sync;
reg                   m_rvalid_sync;

always @(posedge s_clk or posedge s_rst)
begin
    if (s_rst)
    begin
        s_awvalid_sync <= 1'b0;
        s_wvalid_sync <= 1'b0;
        s_arvalid_sync <= 1'b0;
    end
    else
    begin
        s_awvalid_sync <= s_axil_awvalid;
        s_wvalid_sync <= s_axil_wvalid;
        s_arvalid_sync <= s_axil_arvalid;
    end
end

always @(posedge m_clk or posedge m_rst)
begin
    if (m_rst)
    begin
        m_bvalid_sync <= 1'b0;
        m_rvalid_sync <= 1'b0;
    end
    else
    begin
        m_bvalid_sync <= m_axil_bvalid;
        m_rvalid_sync <= m_axil_rvalid;
    end
end

// Write Channel
always @(posedge s_clk or posedge s_rst)
begin
    if (s_rst)
    begin
        s_awaddr <= {ADDR_WIDTH{1'b0}};
        s_awprot <= 3'b0;
        s_awvalid <= 1'b0;
        s_wdata <= {DATA_WIDTH{1'b0}};
        s_wstrb <= {STRB_WIDTH{1'b0}};
        s_wvalid <= 1'b0;
        s_bresp <= 2'b0;
        s_bvalid <= 1'b0;
        s_axil_awready <= 1'b0;
        s_axil_wready <= 1'b0;
    end
    else
    begin
        if (s_axil_awvalid && s_axil_awready)
        begin
            s_awaddr <= s_axil_awaddr;
            s_awprot <= s_axil_awprot;
            s_awvalid <= 1'b1;
        end
        else if (s_awvalid && m_axil_awready)
        begin
            s_awvalid <= 1'b0;
        end

        if (s_axil_wvalid && s_axil_wready)
        begin
            s_wdata <= s_axil_wdata;
            s_wstrb <= s_axil_wstrb;
            s_wvalid <= 1'b1;
        end
        else if (s_wvalid && m_axil_wready)
        begin
            s_wvalid <= 1'b0;
        end

        if (m_axil_bvalid && m_axil_bready)
        begin
            s_bresp <= m_axil_bresp;
            s_bvalid <= 1'b1;
        end
        else if (s_bvalid && s_axil_bready)
        begin
            s_bvalid <= 1'b0;
        end

        if (s_awvalid && !m_axil_awready)
        begin
            s_axil_awready <= 1'b0;
        end
        else
        begin
            s_axil_awready <= 1'b1;
        end

        if (s_wvalid && !m_axil_wready)
        begin
            s_axil_wready <= 1'b0;
        end
        else
        begin
            s_axil_wready <= 1'b1;
        end

        if (s_bvalid && !s_axil_bready)
        begin
            s_axil_bvalid <= 1'b0;
        end
        else
        begin
            s_axil_bvalid <= s_bvalid;
            s_axil_bresp <= s_bresp;
        end
    end
end

always @(posedge m_clk or posedge m_rst)
begin
    if (m_rst)
    begin
        m_awaddr <= {ADDR_WIDTH{1'b0}};
        m_awprot <= 3'b0;
        m_axil_awvalid <= 1'b0;
        m_wdata <= {DATA_WIDTH{1'b0}};
        m_wstrb <= {STRB_WIDTH{1'b0}};
        m_axil_wvalid <= 1'b0;
        m_axil_bready <= 1'b0;
    end
    else
    begin
        if (s_awvalid_sync && !m_axil_awready)
        begin
            m_axil_awvalid <= 1'b1;
            m_awaddr <= s_awaddr;
            m_awprot <= s_awprot;
        end
        else if (m_axil_awvalid && m_axil_awready)
        begin
            m_axil_awvalid <= 1'b0;
        end

        if (s_wvalid_sync && !m_axil_wready)
        begin
            m_axil_wvalid <= 1'b1;
            m_wdata <= s_wdata;
            m_wstrb <= s_wstrb;
        end
        else if (m_axil_wvalid && m_axil_wready)
        begin
            m_axil_wvalid <= 1'b0;
        end

        if (m_bvalid_sync && !m_axil_bready)
        begin
            m_axil_bready <= 1'b1;
        end
        else
        begin
            m_axil_bready <= 1'b0;
        end
    end
end

// Read Channel
always @(posedge s_clk or posedge s_rst)
begin
    if (s_rst)
    begin
        s_araddr <= {ADDR_WIDTH{1'b0}};
        s_arprot <= 3'b0;
        s_arvalid <= 1'b0;
        s_rdata <= {DATA_WIDTH{1'b0}};
        s_rresp <= 2'b0;
        s_rvalid <= 1'b0;
        s_axil_arready <= 1'b0;
        s_axil_rvalid <= 1'b0;
    end
    else
    begin
        if (s_axil_arvalid && s_axil_arready)
        begin
            s_araddr <= s_axil_araddr;
            s_arprot <= s_axil_arprot;
            s_arvalid <= 1'b1;
        end
        else if (s_arvalid && m_axil_arready)
        begin
            s_arvalid <= 1'b0;
        end

        if (m_axil_rvalid && m_axil_rready)
        begin
            s_rdata <= m_axil_rdata;
            s_rresp <= m_axil_rresp;
            s_rvalid <= 1'b1;
        end
        else if (s_rvalid && s_axil_rready)
        begin
            s_rvalid <= 1'b0;
        end

        if (s_arvalid && !m_axil_arready)
        begin
            s_axil_arready <= 1'b0;
        end
        else
        begin
            s_axil_arready <= 1'b1;
        end

        if (s_rvalid && !s_axil_rready)
        begin
            s_axil_rvalid <= 1'b0;
        end
        else
        begin
            s_axil_rvalid <= s_rvalid;
            s_axil_rdata <= s_rdata;
            s_axil_rresp <= s_rresp;
        end
    end
end

always @(posedge m_clk or posedge m_rst)
begin
    if (m_rst)
    begin
        m_araddr <= {ADDR_WIDTH{1'b0}};
        m_arprot <= 3'b0;
        m_axil_arvalid <= 1'b0;
        m_rdata <= {DATA_WIDTH{1'b0}};
        m_rresp <= 2'b0;
        m_axil_rready <= 1'b0;
    end
    else
    begin
        if (s_arvalid_sync && !m_axil_arready)
        begin
            m_axil_arvalid <= 1'b1;
            m_araddr <= s_araddr;
            m_arprot <= s_arprot;
        end
        else if (m_axil_arvalid && m_axil_arready)
        begin
            m_axil_arvalid <= 1'b0;
        end

        if (m_rvalid_sync && !m_axil_rready)
        begin
            m_axil_rready <= 1'b1;
        end
        else
        begin
            m_axil_rready <= 1'b0;
        end
    end
end

endmodule
