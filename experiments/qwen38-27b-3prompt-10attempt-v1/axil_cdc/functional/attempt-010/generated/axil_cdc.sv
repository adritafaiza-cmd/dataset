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

    // Write channel: AW
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg                  s_awvalid_reg;
    reg                  s_awready_reg;
    reg                  s_awpending_reg;

    // Write channel: W
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg                  s_wready_reg;
    reg                  s_wpending_reg;

    // Write channel: B
    reg [1:0] s_bresp_reg;
    reg       s_bvalid_reg;
    reg       s_bready_reg;

    // Read channel: AR
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arready_reg;
    reg                  s_arpending_reg;

    // Read channel: R
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;
    reg                  s_rready_reg;

    // Master side registers
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0]            m_awprot_reg;
    reg                  m_awvalid_reg;
    reg                  m_awready_reg;
    reg                  m_awpending_reg;

    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_wvalid_reg;
    reg                  m_wready_reg;
    reg                  m_wpending_reg;

    reg [1:0] m_bresp_reg;
    reg       m_bvalid_reg;
    reg       m_bready_reg;

    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0]            m_arprot_reg;
    reg                  m_arvalid_reg;
    reg                  m_arready_reg;
    reg                  m_arpending_reg;

    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;
    reg                  m_rready_reg;

    // CDC synchronizers
    // AW channel
    reg [ADDR_WIDTH-1:0] awaddr_sync1, awaddr_sync2;
    reg [2:0]            awprot_sync1, awprot_sync2;
    reg                  awvalid_sync1, awvalid_sync2;
    reg                  awready_sync1, awready_sync2;

    // W channel
    reg [DATA_WIDTH-1:0] wdata_sync1, wdata_sync2;
    reg [STRB_WIDTH-1:0] wstrb_sync1, wstrb_sync2;
    reg                  wvalid_sync1, wvalid_sync2;
    reg                  wready_sync1, wready_sync2;

    // B channel
    reg [1:0] bresp_sync1, bresp_sync2;
    reg       bvalid_sync1, bvalid_sync2;
    reg       bready_sync1, bready_sync2;

    // AR channel
    reg [ADDR_WIDTH-1:0] araddr_sync1, araddr_sync2;
    reg [2:0]            arprot_sync1, arprot_sync2;
    reg                  arvalid_sync1, arvalid_sync2;
    reg                  arready_sync1, arready_sync2;

    // R channel
    reg [DATA_WIDTH-1:0] rdata_sync1, rdata_sync2;
    reg [1:0]            rresp_sync1, rresp_sync2;
    reg                  rvalid_sync1, rvalid_sync2;
    reg                  rready_sync1, rready_sync2;

    // Slave side: AW
    assign s_axil_awready = s_awready_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg    <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg    <= 3'b000;
            s_awvalid_reg   <= 1'b0;
            s_awready_reg   <= 1'b0;
            s_awpending_reg <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_awready_reg) begin
                s_awaddr_reg    <= s_axil_awaddr;
                s_awprot_reg    <= s_axil_awprot;
                s_awvalid_reg   <= 1'b1;
                s_awpending_reg <= 1'b1;
            end else if (s_awpending_reg && awvalid_sync2) begin
                s_awpending_reg <= 1'b0;
                s_awvalid_reg   <= 1'b0;
            end
            s_awready_reg <= awready_sync2;
        end
    end

    // Slave side: W
    assign s_axil_wready = s_wready_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg    <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg    <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg   <= 1'b0;
            s_wready_reg   <= 1'b0;
            s_wpending_reg <= 1'b0;
        end else begin
            if (s_axil_wvalid && s_wready_reg) begin
                s_wdata_reg    <= s_axil_wdata;
                s_wstrb_reg    <= s_axil_wstrb;
                s_wvalid_reg   <= 1'b1;
                s_wpending_reg <= 1'b1;
            end else if (s_wpending_reg && wvalid_sync2) begin
                s_wpending_reg <= 1'b0;
                s_wvalid_reg   <= 1'b0;
            end
            s_wready_reg <= wready_sync2;
        end
    end

    // Slave side: B
    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
        end else begin
            if (s_bvalid_reg && s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end else if (bvalid_sync2) begin
                s_bresp_reg  <= bresp_sync2;
                s_bvalid_reg <= 1'b1;
            end
            s_bready_reg <= bready_sync2;
        end
    end

    // Slave side: AR
    assign s_axil_arready = s_arready_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg    <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg    <= 3'b000;
            s_arvalid_reg   <= 1'b0;
            s_arready_reg   <= 1'b0;
            s_arpending_reg <= 1'b0;
        end else begin
            if (s_axil_arvalid && s_arready_reg) begin
                s_araddr_reg    <= s_axil_araddr;
                s_arprot_reg    <= s_axil_arprot;
                s_arvalid_reg   <= 1'b1;
                s_arpending_reg <= 1'b1;
            end else if (s_arpending_reg && arvalid_sync2) begin
                s_arpending_reg <= 1'b0;
                s_arvalid_reg   <= 1'b0;
            end
            s_arready_reg <= arready_sync2;
        end
    end

    // Slave side: R
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
        end else begin
            if (s_rvalid_reg && s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end else if (rvalid_sync2) begin
                s_rdata_reg  <= rdata_sync2;
                s_rresp_reg  <= rresp_sync2;
                s_rvalid_reg <= 1'b1;
            end
            s_rready_reg <= rready_sync2;
        end
    end

    // Master side: AW
    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg    <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg    <= 3'b000;
            m_awvalid_reg   <= 1'b0;
            m_awready_reg   <= 1'b0;
            m_awpending_reg <= 1'b0;
        end else begin
            if (awvalid_sync2 && m_axil_awready) begin
                m_awpending_reg <= 1'b0;
                m_awvalid_reg   <= 1'b0;
            end else if (awvalid_sync2) begin
                m_awaddr_reg    <= awaddr_sync2;
                m_awprot_reg    <= awprot_sync2;
                m_awvalid_reg   <= 1'b1;
                m_awpending_reg <= 1'b1;
            end
            m_awready_reg <= awready_sync2;
        end
    end

    // Master side: W
    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata_reg    <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg    <= {STRB_WIDTH{1'b0}};
            m_wvalid_reg   <= 1'b0;
            m_wready_reg   <= 1'b0;
            m_wpending_reg <= 1'b0;
        end else begin
            if (wvalid_sync2 && m_axil_wready) begin
                m_wpending_reg <= 1'b0;
                m_wvalid_reg   <= 1'b0;
            end else if (wvalid_sync2) begin
                m_wdata_reg    <= wdata_sync2;
                m_wstrb_reg    <= wstrb_sync2;
                m_wvalid_reg   <= 1'b1;
                m_wpending_reg <= 1'b1;
            end
            m_wready_reg <= wready_sync2;
        end
    end

    // Master side: B
    assign m_axil_bready = m_bready_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp_reg  <= 2'b00;
            m_bvalid_reg <= 1'b0;
            m_bready_reg <= 1'b0;
        end else begin
            if (m_axil_bvalid && m_bready_reg) begin
                m_bresp_reg  <= m_axil_bresp;
                m_bvalid_reg <= 1'b1;
            end else if (m_bvalid_reg && bready_sync2) begin
                m_bvalid_reg <= 1'b0;
            end
            m_bready_reg <= bready_sync2;
        end
    end

    // Master side: AR
    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg    <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg    <= 3'b000;
            m_arvalid_reg   <= 1'b0;
            m_arready_reg   <= 1'b0;
            m_arpending_reg <= 1'b0;
        end else begin
            if (arvalid_sync2 && m_axil_arready) begin
                m_arpending_reg <= 1'b0;
                m_arvalid_reg   <= 1'b0;
            end else if (arvalid_sync2) begin
                m_araddr_reg    <= araddr_sync2;
                m_arprot_reg    <= arprot_sync2;
                m_arvalid_reg   <= 1'b1;
                m_arpending_reg <= 1'b1;
            end
            m_arready_reg <= arready_sync2;
        end
    end

    // Master side: R
    assign m_axil_rready = m_rready_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata_reg  <= {DATA_WIDTH{1'b0}};
            m_rresp_reg  <= 2'b00;
            m_rvalid_reg <= 1'b0;
            m_rready_reg <= 1'b0;
        end else begin
            if (m_axil_rvalid && m_rready_reg) begin
                m_rdata_reg  <= m_axil_rdata;
                m_rresp_reg  <= m_axil_rresp;
                m_rvalid_reg <= 1'b1;
            end else if (m_rvalid_reg && rready_sync2) begin
                m_rvalid_reg <= 1'b0;
            end
            m_rready_reg <= rready_sync2;
        end
    end

    // CDC: Slave to Master (AW)
    always @(posedge s_clk) begin
        awaddr_sync1 <= s_awaddr_reg;
        awaddr_sync2 <= awaddr_sync1;
        awprot_sync1 <= s_awprot_reg;
        awprot_sync2 <= awprot_sync1;
        awvalid_sync1 <= s_awvalid_reg;
        awvalid_sync2 <= awvalid_sync1;
    end

    // CDC: Master to Slave (AW ready)
    always @(posedge m_clk) begin
        awready_sync1 <= m_axil_awready;
        awready_sync2 <= awready_sync1;
    end

    // CDC: Slave to Master (W)
    always @(posedge s_clk) begin
        wdata_sync1 <= s_wdata_reg;
        wdata_sync2 <= wdata_sync1;
        wstrb_sync1 <= s_wstrb_reg;
        wstrb_sync2 <= wstrb_sync1;
        wvalid_sync1 <= s_wvalid_reg;
        wvalid_sync2 <= wvalid_sync1;
    end

    // CDC: Master to Slave (W ready)
    always @(posedge m_clk) begin
        wready_sync1 <= m_axil_wready;
        wready_sync2 <= wready_sync1;
    end

    // CDC: Master to Slave (B)
    always @(posedge m_clk) begin
        bresp_sync1 <= m_bresp_reg;
        bresp_sync2 <= bresp_sync1;
        bvalid_sync1 <= m_bvalid_reg;
        bvalid_sync2 <= bvalid_sync1;
    end

    // CDC: Slave to Master (B ready)
    always @(posedge s_clk) begin
        bready_sync1 <= s_axil_bready;
        bready_sync2 <= bready_sync1;
    end

    // CDC: Slave to Master (AR)
    always @(posedge s_clk) begin
        araddr_sync1 <= s_araddr_reg;
        araddr_sync2 <= araddr_sync1;
        arprot_sync1 <= s_arprot_reg;
        arprot_sync2 <= arprot_sync1;
        arvalid_sync1 <= s_arvalid_reg;
        arvalid_sync2 <= arvalid_sync1;
    end

    // CDC: Master to Slave (AR ready)
    always @(posedge m_clk) begin
        arready_sync1 <= m_axil_arready;
        arready_sync2 <= arready_sync1;
    end

    // CDC: Master to Slave (R)
    always @(posedge m_clk) begin
        rdata_sync1 <= m_rdata_reg;
        rdata_sync2 <= rdata_sync1;
        rresp_sync1 <= m_rresp_reg;
        rresp_sync2 <= rresp_sync1;
        rvalid_sync1 <= m_rvalid_reg;
        rvalid_sync2 <= rvalid_sync1;
    end

    // CDC: Slave to Master (R ready)
    always @(posedge s_clk) begin
        rready_sync1 <= s_axil_rready;
        rready_sync2 <= rready_sync1;
    end

endmodule
