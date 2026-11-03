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

    /*
     * Write Channel
     */
    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0]            s_awprot_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_awvalid_reg;
    reg                  s_wvalid_reg;
    reg                  s_awvalid_meta;
    reg                  s_wvalid_meta;
    reg                  s_awvalid_sync;
    reg                  s_wvalid_sync;

    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0]            m_awprot_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_awvalid_reg;
    reg                  m_wvalid_reg;
    reg                  m_awvalid_meta;
    reg                  m_wvalid_meta;
    reg                  m_awvalid_sync;
    reg                  m_wvalid_sync;

    reg                  s_bready_meta;
    reg                  s_bready_sync;
    reg                  m_bvalid_meta;
    reg                  m_bvalid_sync;

    /*
     * Read Channel
     */
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0]            s_arprot_reg;
    reg                  s_arvalid_reg;
    reg                  s_arvalid_meta;
    reg                  s_arvalid_sync;

    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0]            m_arprot_reg;
    reg                  m_arvalid_reg;
    reg                  m_arvalid_meta;
    reg                  m_arvalid_sync;

    reg                  s_rready_meta;
    reg                  s_rready_sync;
    reg                  m_rvalid_meta;
    reg                  m_rvalid_sync;

    /*
     * Write Channel CDC
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg  <= {3{1'b0}};
            s_wdata_reg   <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg   <= {STRB_WIDTH{1'b0}};
            s_awvalid_reg <= 1'b0;
            s_wvalid_reg  <= 1'b0;
            s_awvalid_meta <= 1'b0;
            s_wvalid_meta  <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
            end else if (m_axil_awready) begin
                s_awvalid_reg <= 1'b0;
            end

            if (s_axil_wvalid && s_axil_wready) begin
                s_wdata_reg   <= s_axil_wdata;
                s_wstrb_reg   <= s_axil_wstrb;
                s_wvalid_reg  <= 1'b1;
            end else if (m_axil_wready) begin
                s_wvalid_reg  <= 1'b0;
            end

            s_awvalid_meta <= s_awvalid_reg;
            s_wvalid_meta  <= s_wvalid_reg;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg  <= {3{1'b0}};
            m_wdata_reg   <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg   <= {STRB_WIDTH{1'b0}};
            m_awvalid_reg <= 1'b0;
            m_wvalid_reg  <= 1'b0;
            m_awvalid_meta <= 1'b0;
            m_wvalid_meta  <= 1'b0;
            m_awvalid_sync <= 1'b0;
            m_wvalid_sync  <= 1'b0;
        end else begin
            m_awvalid_meta <= s_awvalid_meta;
            m_wvalid_meta  <= s_wvalid_meta;
            m_awvalid_sync <= m_awvalid_meta;
            m_wvalid_sync  <= m_wvalid_meta;

            if (m_awvalid_sync) begin
                m_awaddr_reg  <= s_awaddr_reg;
                m_awprot_reg  <= s_awprot_reg;
                m_awvalid_reg <= 1'b1;
            end else if (m_axil_awready) begin
                m_awvalid_reg <= 1'b0;
            end

            if (m_wvalid_sync) begin
                m_wdata_reg   <= s_wdata_reg;
                m_wstrb_reg   <= s_wstrb_reg;
                m_wvalid_reg  <= 1'b1;
            end else if (m_axil_wready) begin
                m_wvalid_reg  <= 1'b0;
            end
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bready_meta <= 1'b0;
            s_bready_sync <= 1'b0;
        end else begin
            s_bready_meta <= s_axil_bready;
            s_bready_sync <= s_bready_meta;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bvalid_meta <= 1'b0;
            m_bvalid_sync <= 1'b0;
        end else begin
            m_bvalid_meta <= s_bvalid_sync;
            m_bvalid_sync <= m_bvalid_meta;
        end
    end

    assign s_axil_awready = !s_awvalid_reg;
    assign s_axil_wready  = !s_wvalid_reg;
    assign m_axil_awaddr  = m_awaddr_reg;
    assign m_axil_awprot  = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_wdata   = m_wdata_reg;
    assign m_axil_wstrb   = m_wstrb_reg;
    assign m_axil_wvalid  = m_wvalid_reg;
    assign m_axil_bready  = s_bready_sync;
    assign s_axil_bresp   = m_axil_bresp;
    assign s_axil_bvalid  = m_bvalid_sync;

    /*
     * Read Channel CDC
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg  <= {3{1'b0}};
            s_arvalid_reg <= 1'b0;
            s_arvalid_meta <= 1'b0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
            end else if (m_axil_arready) begin
                s_arvalid_reg <= 1'b0;
            end

            s_arvalid_meta <= s_arvalid_reg;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr_reg  <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg  <= {3{1'b0}};
            m_arvalid_reg <= 1'b0;
            m_arvalid_meta <= 1'b0;
            m_arvalid_sync <= 1'b0;
        end else begin
            m_arvalid_meta <= s_arvalid_meta;
            m_arvalid_sync <= m_arvalid_meta;

            if (m_arvalid_sync) begin
                m_araddr_reg  <= s_araddr_reg;
                m_arprot_reg  <= s_arprot_reg;
                m_arvalid_reg <= 1'b1;
            end else if (m_axil_arready) begin
                m_arvalid_reg <= 1'b0;
            end
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rready_meta <= 1'b0;
            s_rready_sync <= 1'b0;
        end else begin
            s_rready_meta <= s_axil_rready;
            s_rready_sync <= s_rready_meta;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rvalid_meta <= 1'b0;
            m_rvalid_sync <= 1'b0;
        end else begin
            m_rvalid_meta <= s_rvalid_sync;
            m_rvalid_sync <= m_rvalid_meta;
        end
    end

    assign s_axil_arready = !s_arvalid_reg;
    assign m_axil_araddr  = m_araddr_reg;
    assign m_axil_arprot  = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_rready  = s_rready_sync;
    assign s_axil_rdata   = m_axil_rdata;
    assign s_axil_rresp   = m_axil_rresp;
    assign s_axil_rvalid  = m_rvalid_sync;

endmodule
