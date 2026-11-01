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

    // Internal signals
    wire s_aw_handshake;
    wire s_w_handshake;
    wire s_ar_handshake;
    wire s_b_handshake;
    wire s_r_handshake;

    wire m_aw_handshake;
    wire m_w_handshake;
    wire m_b_handshake;
    wire m_ar_handshake;
    wire m_r_handshake;

    // Write address channel
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0] s_awprot_reg;
    reg s_awvalid_reg;
    reg s_awready_reg;

    // Write data channel
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg s_wvalid_reg;
    reg s_wready_reg;

    // Write response channel
    reg [1:0] s_bresp_reg;
    reg s_bvalid_reg;

    // Read address channel
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0] s_arprot_reg;
    reg s_arvalid_reg;
    reg s_arready_reg;

    // Read data channel
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0] s_rresp_reg;
    reg s_rvalid_reg;

    // Master side registers
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_awvalid_reg;

    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_wvalid_reg;

    reg m_bready_reg;

    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_arvalid_reg;

    reg m_rready_reg;

    // CDC synchronizers for write address
    reg [ADDR_WIDTH-1:0] awaddr_sync_1;
    reg [ADDR_WIDTH-1:0] awaddr_sync_2;
    reg [ADDR_WIDTH-1:0] awaddr_sync_3;
    reg [2:0] awprot_sync_1;
    reg [2:0] awprot_sync_2;
    reg [2:0] awprot_sync_3;
    reg awvalid_sync_1;
    reg awvalid_sync_2;
    reg awvalid_sync_3;

    // CDC synchronizers for write data
    reg [DATA_WIDTH-1:0] wdata_sync_1;
    reg [DATA_WIDTH-1:0] wdata_sync_2;
    reg [DATA_WIDTH-1:0] wdata_sync_3;
    reg [STRB_WIDTH-1:0] wstrb_sync_1;
    reg [STRB_WIDTH-1:0] wstrb_sync_2;
    reg [STRB_WIDTH-1:0] wstrb_sync_3;
    reg wvalid_sync_1;
    reg wvalid_sync_2;
    reg wvalid_sync_3;

    // CDC synchronizers for write response
    reg [1:0] bresp_sync_1;
    reg [1:0] bresp_sync_2;
    reg [1:0] bresp_sync_3;
    reg bvalid_sync_1;
    reg bvalid_sync_2;
    reg bvalid_sync_3;

    // CDC synchronizers for read address
    reg [ADDR_WIDTH-1:0] araddr_sync_1;
    reg [ADDR_WIDTH-1:0] araddr_sync_2;
    reg [ADDR_WIDTH-1:0] araddr_sync_3;
    reg [2:0] arprot_sync_1;
    reg [2:0] arprot_sync_2;
    reg [2:0] arprot_sync_3;
    reg arvalid_sync_1;
    reg arvalid_sync_2;
    reg arvalid_sync_3;

    // CDC synchronizers for read data
    reg [DATA_WIDTH-1:0] rdata_sync_1;
    reg [DATA_WIDTH-1:0] rdata_sync_2;
    reg [DATA_WIDTH-1:0] rdata_sync_3;
    reg [1:0] rresp_sync_1;
    reg [1:0] rresp_sync_2;
    reg [1:0] rresp_sync_3;
    reg rvalid_sync_1;
    reg rvalid_sync_2;
    reg rvalid_sync_3;

    // Handshake signals
    assign s_axil_awready = s_awready_reg;
    assign s_axil_wready = s_wready_reg;
    assign s_axil_bresp = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    assign s_axil_arready = s_arready_reg;
    assign s_axil_rdata = s_rdata_reg;
    assign s_axil_rresp = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;
    assign m_axil_bready = m_bready_reg;
    assign m_axil_araddr = m_araddr_reg;
    assign m_axil_arprot = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_rready = m_rready_reg;

    assign s_aw_handshake = s_axil_awvalid & s_axil_awready;
    assign s_w_handshake = s_axil_wvalid & s_axil_wready;
    assign s_ar_handshake = s_axil_arvalid & s_axil_arready;
    assign s_b_handshake = s_axil_bvalid & s_axil_bready;
    assign s_r_handshake = s_axil_rvalid & s_axil_rready;

    assign m_aw_handshake = m_axil_awvalid & m_axil_awready;
    assign m_w_handshake = m_axil_wvalid & m_axil_wready;
    assign m_b_handshake = m_axil_bvalid & m_axil_bready;
    assign m_ar_handshake = m_axil_arvalid & m_axil_arready;
    assign m_r_handshake = m_axil_rvalid & m_axil_rready;

    // Slave clock domain logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
            s_awvalid_reg <= 1'b0;
            s_awready_reg <= 1'b0;

            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg <= 1'b0;
            s_wready_reg <= 1'b0;

            s_bresp_reg <= 2'b00;
            s_bvalid_reg <= 1'b0;

            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
            s_arvalid_reg <= 1'b0;
            s_arready_reg <= 1'b0;

            s_rdata_reg <= {DATA_WIDTH{1'b0}};
            s_rresp_reg <= 2'b00;
            s_rvalid_reg <= 1'b0;
        end else begin
            // Write address channel
            if (s_axil_awvalid && !s_awvalid_reg) begin
                s_awaddr_reg <= s_axil_awaddr;
                s_awprot_reg <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
            end
            if (s_awvalid_reg && m_aw_handshake) begin
                s_awvalid_reg <= 1'b0;
            end

            // Write data channel
            if (s_axil_wvalid && !s_wvalid_reg) begin
                s_wdata_reg <= s_axil_wdata;
                s_wstrb_reg <= s_axil_wstrb;
                s_wvalid_reg <= 1'b1;
            end
            if (s_wvalid_reg && m_w_handshake) begin
                s_wvalid_reg <= 1'b0;
            end

            // Write response channel
            if (s_bvalid_reg && s_axil_bready) begin
                s_bvalid_reg <= 1'b0;
            end
            if (!s_bvalid_reg && bvalid_sync_3) begin
                s_bresp_reg <= bresp_sync_3;
                s_bvalid_reg <= 1'b1;
            end

            // Read address channel
            if (s_axil_arvalid && !s_arvalid_reg) begin
                s_araddr_reg <= s_axil_araddr;
                s_arprot_reg <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
            end
            if (s_arvalid_reg && m_ar_handshake) begin
                s_arvalid_reg <= 1'b0;
            end

            // Read data channel
            if (s_rvalid_reg && s_axil_rready) begin
                s_rvalid_reg <= 1'b0;
            end
            if (!s_rvalid_reg && rvalid_sync_3) begin
                s_rdata_reg <= rdata_sync_3;
                s_rresp_reg <= rresp_sync_3;
                s_rvalid_reg <= 1'b1;
            end
        end
    end

    // Master clock domain logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg <= 3'b000;
            m_awvalid_reg <= 1'b0;

            m_wdata_reg <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg <= {STRB_WIDTH{1'b0}};
            m_wvalid_reg <= 1'b0;

            m_bready_reg <= 1'b0;

            m_araddr_reg <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg <= 3'b000;
            m_arvalid_reg <= 1'b0;

            m_rready_reg <= 1'b0;
        end else begin
            // Write address channel
            if (!m_awvalid_reg && awvalid_sync_3) begin
                m_awaddr_reg <= awaddr_sync_3;
                m_awprot_reg <= awprot_sync_3;
                m_awvalid_reg <= 1'b1;
            end
            if (m_awvalid_reg && m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
            end

            // Write data channel
            if (!m_wvalid_reg && wvalid_sync_3) begin
                m_wdata_reg <= wdata_sync_3;
                m_wstrb_reg <= wstrb_sync_3;
                m_wvalid_reg <= 1'b1;
            end
            if (m_wvalid_reg && m_axil_wready) begin
                m_wvalid_reg <= 1'b0;
            end

            // Write response channel
            if (m_axil_bvalid && !m_bready_reg) begin
                m_bready_reg <= 1'b1;
            end
            if (m_bready_reg && m_axil_bvalid) begin
                m_bready_reg <= 1'b0;
            end

            // Read address channel
            if (!m_arvalid_reg && arvalid_sync_3) begin
                m_araddr_reg <= araddr_sync_3;
                m_arprot_reg <= arprot_sync_3;
                m_arvalid_reg <= 1'b1;
            end
            if (m_arvalid_reg && m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
            end

            // Read data channel
            if (m_axil_rvalid && !m_rready_reg) begin
                m_rready_reg <= 1'b1;
            end
            if (m_rready_reg && m_axil_rvalid) begin
                m_rready_reg <= 1'b0;
            end
        end
    end

    // CDC synchronizers for write address
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            awaddr_sync_1 <= {ADDR_WIDTH{1'b0}};
            awaddr_sync_2 <= {ADDR_WIDTH{1'b0}};
            awaddr_sync_3 <= {ADDR_WIDTH{1'b0}};
            awprot_sync_1 <= 3'b000;
            awprot_sync_2 <= 3'b000;
            awprot_sync_3 <= 3'b000;
            awvalid_sync_1 <= 1'b0;
            awvalid_sync_2 <= 1'b0;
            awvalid_sync_3 <= 1'b0;
        end else begin
            awaddr_sync_1 <= s_awaddr_reg;
            awaddr_sync_2 <= awaddr_sync_1;
            awaddr_sync_3 <= awaddr_sync_2;
            awprot_sync_1 <= s_awprot_reg;
            awprot_sync_2 <= awprot_sync_1;
            awprot_sync_3 <= awprot_sync_2;
            awvalid_sync_1 <= s_awvalid_reg;
            awvalid_sync_2 <= awvalid_sync_1;
            awvalid_sync_3 <= awvalid_sync_2;
        end
    end

    // CDC synchronizers for write data
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wdata_sync_1 <= {DATA_WIDTH{1'b0}};
            wdata_sync_2 <= {DATA_WIDTH{1'b0}};
            wdata_sync_3 <= {DATA_WIDTH{1'b0}};
            wstrb_sync_1 <= {STRB_WIDTH{1'b0}};
            wstrb_sync_2 <= {STRB_WIDTH{1'b0}};
            wstrb_sync_3 <= {STRB_WIDTH{1'b0}};
            wvalid_sync_1 <= 1'b0;
            wvalid_sync_2 <= 1'b0;
            wvalid_sync_3 <= 1'b0;
        end else begin
            wdata_sync_1 <= s_wdata_reg;
            wdata_sync_2 <= wdata_sync_1;
            wdata_sync_3 <= wdata_sync_2;
            wstrb_sync_1 <= s_wstrb_reg;
            wstrb_sync_2 <= wstrb_sync_1;
            wstrb_sync_3 <= wstrb_sync_2;
            wvalid_sync_1 <= s_wvalid_reg;
            wvalid_sync_2 <= wvalid_sync_1;
            wvalid_sync_3 <= wvalid_sync_2;
        end
    end

    // CDC synchronizers for write response
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            bresp_sync_1 <= 2'b00;
            bresp_sync_2 <= 2'b00;
            bresp_sync_3 <= 2'b00;
            bvalid_sync_1 <= 1'b0;
            bvalid_sync_2 <= 1'b0;
            bvalid_sync_3 <= 1'b0;
        end else begin
            bresp_sync_1 <= m_axil_bresp;
            bresp_sync_2 <= bresp_sync_1;
            bresp_sync_3 <= bresp_sync_2;
            bvalid_sync_1 <= m_axil_bvalid;
            bvalid_sync_2 <= bvalid_sync_1;
            bvalid_sync_3 <= bvalid_sync_2;
        end
    end

    // CDC synchronizers for read address
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            araddr_sync_1 <= {ADDR_WIDTH{1'b0}};
            araddr_sync_2 <= {ADDR_WIDTH{1'b0}};
            araddr_sync_3 <= {ADDR_WIDTH{1'b0}};
            arprot_sync_1 <= 3'b000;
            arprot_sync_2 <= 3'b000;
            arprot_sync_3 <= 3'b000;
            arvalid_sync_1 <= 1'b0;
            arvalid_sync_2 <= 1'b0;
            arvalid_sync_3 <= 1'b0;
        end else begin
            araddr_sync_1 <= s_araddr_reg;
            araddr_sync_2 <= araddr_sync_1;
            araddr_sync_3 <= araddr_sync_2;
            arprot_sync_1 <= s_arprot_reg;
            arprot_sync_2 <= arprot_sync_1;
            arprot_sync_3 <= arprot_sync_2;
            arvalid_sync_1 <= s_arvalid_reg;
            arvalid_sync_2 <= arvalid_sync_1;
            arvalid_sync_3 <= arvalid_sync_2;
        end
    end

    // CDC synchronizers for read data
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rdata_sync_1 <= {DATA_WIDTH{1'b0}};
            rdata_sync_2 <= {DATA_WIDTH{1'b0}};
            rdata_sync_3 <= {DATA_WIDTH{1'b0}};
            rresp_sync_1 <= 2'b00;
            rresp_sync_2 <= 2'b00;
            rresp_sync_3 <= 2'b00;
            rvalid_sync_1 <= 1'b0;
            rvalid_sync_2 <= 1'b0;
            rvalid_sync_3 <= 1'b0;
        end else begin
            rdata_sync_1 <= m_axil_rdata;
            rdata_sync_2 <= rdata_sync_1;
            rdata_sync_3 <= rdata_sync_2;
            rresp_sync_1 <= m_axil_rresp;
            rresp_sync_2 <= rresp_sync_1;
            rresp_sync_3 <= rresp_sync_2;
            rvalid_sync_1 <= m_axil_rvalid;
            rvalid_sync_2 <= rvalid_sync_1;
            rvalid_sync_3 <= rvalid_sync_2;
        end
    end

endmodule
