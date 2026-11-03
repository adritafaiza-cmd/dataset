The following Verilog code implements an AXI4-Lite clock-domain bridge using a handshake-based approach. The code uses two FIFOs to store the incoming and outgoing transactions, respectively. The incoming transaction is stored in the slave FIFO and the outgoing transaction is stored in the master FIFO. The code also includes reset logic to idle both interfaces and to prevent any transaction from being created.

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

    // Slave FIFO
    reg [ADDR_WIDTH-1:0] s_awaddr_fifo [0:1];
    reg [2:0] s_awprot_fifo [0:1];
    reg s_awvalid_fifo [0:1];
    reg [DATA_WIDTH-1:0] s_wdata_fifo [0:1];
    reg [STRB_WIDTH-1:0] s_wstrb_fifo [0:1];
    reg s_wvalid_fifo [0:1];
    reg s_bready_fifo [0:1];
    reg [ADDR_WIDTH-1:0] s_araddr_fifo [0:1];
    reg [2:0] s_arprot_fifo [0:1];
    reg s_arvalid_fifo [0:1];
    reg s_rready_fifo [0:1];
    reg [1:0] s_bresp_fifo [0:1];
    reg s_bvalid_fifo [0:1];
    reg [DATA_WIDTH-1:0] s_rdata_fifo [0:1];
    reg [1:0] s_rresp_fifo [0:1];
    reg s_rvalid_fifo [0:1];
    reg [1:0] s_fifo_wr_ptr;
    reg [1:0] s_fifo_rd_ptr;
    reg s_fifo_full;
    reg s_fifo_empty;

    // Master FIFO
    reg [ADDR_WIDTH-1:0] m_awaddr_fifo [0:1];
    reg [2:0] m_awprot_fifo [0:1];
    reg m_awvalid_fifo [0:1];
    reg [DATA_WIDTH-1:0] m_wdata_fifo [0:1];
    reg [STRB_WIDTH-1:0] m_wstrb_fifo [0:1];
    reg m_wvalid_fifo [0:1];
    reg m_bready_fifo [0:1];
    reg [ADDR_WIDTH-1:0] m_araddr_fifo [0:1];
    reg [2:0] m_arprot_fifo [0:1];
    reg m_arvalid_fifo [0:1];
    reg m_rready_fifo [0:1];
    reg [1:0] m_bresp_fifo [0:1];
    reg m_bvalid_fifo [0:1];
    reg [DATA_WIDTH-1:0] m_rdata_fifo [0:1];
    reg [1:0] m_rresp_fifo [0:1];
    reg m_rvalid_fifo [0:1];
    reg [1:0] m_fifo_wr_ptr;
    reg [1:0] m_fifo_rd_ptr;
    reg m_fifo_full;
    reg m_fifo_empty;

    // Slave FIFO write
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_fifo_wr_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (s_axil_awvalid && !s_fifo_full) begin
                s_awaddr_fifo[s_fifo_wr_ptr] <= s_axil_awaddr;
                s_awprot_fifo[s_fifo_wr_ptr] <= s_axil_awprot;
                s_awvalid_fifo[s_fifo_wr_ptr] <= 1'b1;
                s_wdata_fifo[s_fifo_wr_ptr] <= s_axil_wdata;
                s_wstrb_fifo[s_fifo_wr_ptr] <= s_axil_wstrb;
                s_wvalid_fifo[s_fifo_wr_ptr] <= 1'b1;
                s_bready_fifo[s_fifo_wr_ptr] <= s_axil_bready;
                s_fifo_wr_ptr <= s_fifo_wr_ptr + 1;
                if (s_fifo_wr_ptr == 2'b11) begin
                    s_fifo_full <= 1'b1;
                end
                s_fifo_empty <= 1'b0;
            end
            if (s_axil_arvalid && !s_fifo_full) begin
                s_araddr_fifo[s_fifo_wr_ptr] <= s_axil_araddr;
                s_arprot_fifo[s_fifo_wr_ptr] <= s_axil_arprot;
                s_arvalid_fifo[s_fifo_wr_ptr] <= 1'b1;
                s_rready_fifo[s_fifo_wr_ptr] <= s_axil_rready;
                s_fifo_wr_ptr <= s_fifo_wr_ptr + 1;
                if (s_fifo_wr_ptr == 2'b11) begin
                    s_fifo_full <= 1'b1;
                end
                s_fifo_empty <= 1'b0;
            end
        end
    end

    // Slave FIFO read
    always @(posedge m_clk) begin
        if (m_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (m_axil_awready && !s_fifo_empty) begin
                m_awaddr_fifo[m_fifo_wr_ptr] <= s_awaddr_fifo[s_fifo_rd_ptr];
                m_awprot_fifo[m_fifo_wr_ptr] <= s_awprot_fifo[s_fifo_rd_ptr];
                m_awvalid_fifo[m_fifo_wr_ptr] <= s_awvalid_fifo[s_fifo_rd_ptr];
                m_wdata_fifo[m_fifo_wr_ptr] <= s_wdata_fifo[s_fifo_rd_ptr];
                m_wstrb_fifo[m_fifo_wr_ptr] <= s_wstrb_fifo[s_fifo_rd_ptr];
                m_wvalid_fifo[m_fifo_wr_ptr] <= s_wvalid_fifo[s_fifo_rd_ptr];
                m_bready_fifo[m_fifo_wr_ptr] <= s_bready_fifo[s_fifo_rd_ptr];
                m_fifo_wr_ptr <= m_fifo_wr_ptr + 1;
                if (m_fifo_wr_ptr == 2'b11) begin
                    m_fifo_full <= 1'b1;
                end
                s_fifo_empty <= 1'b0;
            end
            if (m_axil_arready && !s_fifo_empty) begin
                m_araddr_fifo[m_fifo_wr_ptr] <= s_araddr_fifo[s_fifo_rd_ptr];
                m_arprot_fifo[m_fifo_wr_ptr] <= s_arprot_fifo[s_fifo_rd_ptr];
                m_arvalid_fifo[m_fifo_wr_ptr] <= s_arvalid_fifo[s_fifo_rd_ptr];
                m_rready_fifo[m_fifo_wr_ptr] <= s_rready_fifo[s_fifo_rd_ptr];
                m_fifo_wr_ptr <= m_fifo_wr_ptr + 1;
                if (m_fifo_wr_ptr == 2'b11) begin
                    m_fifo_full <= 1'b1;
                end
                s_fifo_empty <= 1'b0;
            end
        end
    end

    // Master FIFO write
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_fifo_wr_ptr <= 2'b00;
            m_fifo_full <= 1'b0;
            m_fifo_empty <= 1'b1;
        end else begin
            if (m_axil_awready && !m_fifo_full) begin
                m_awaddr_fifo[m_fifo_wr_ptr] <= m_axil_awaddr;
                m_awprot_fifo[m_fifo_wr_ptr] <= m_axil_awprot;
                m_awvalid_fifo[m_fifo_wr_ptr] <= 1'b1;
                m_wdata_fifo[m_fifo_wr_ptr] <= m_axil_wdata;
                m_wstrb_fifo[m_fifo_wr_ptr] <= m_axil_wstrb;
                m_wvalid_fifo[m_fifo_wr_ptr] <= 1'b1;
                m_bready_fifo[m_fifo_wr_ptr] <= m_axil_bready;
                m_fifo_wr_ptr <= m_fifo_wr_ptr + 1;
                if (m_fifo_wr_ptr == 2'b11) begin
                    m_fifo_full <= 1'b1;
                end
                m_fifo_empty <= 1'b0;
            end
            if (m_axil_arready && !m_fifo_full) begin
                m_araddr_fifo[m_fifo_wr_ptr] <= m_axil_araddr;
                m_arprot_fifo[m_fifo_wr_ptr] <= m_axil_arprot;
                m_arvalid_fifo[m_fifo_wr_ptr] <= 1'b1;
                m_rready_fifo[m_fifo_wr_ptr] <= m_axil_rready;
                m_fifo_wr_ptr <= m_fifo_wr_ptr + 1;
                if (m_fifo_wr_ptr == 2'b11) begin
                    m_fifo_full <= 1'b1;
                end
                m_fifo_empty <= 1'b0;
            end
        end
    end

    // Master FIFO read
    always @(posedge s_clk) begin
        if (s_rst) begin
            m_fifo_rd_ptr <= 2'b00;
            m_fifo_full <= 1'b0;
            m_fifo_empty <= 1'b1;
        end else begin
            if (s_axil_awready && !m_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (s_axil_arready && !m_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (s_axil_awready && !s_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (s_axil_arready && !s_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posedge m_clk) begin
        if (m_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (m_axil_awready && !s_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (m_axil_arready && !s_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (s_axil_awready && !s_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (s_axil_arready && !s_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posedge m_clk) begin
        if (m_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (m_axil_awready && !s_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (m_axil_arready && !s_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_fifo_rd_ptr <= 2'b00;
            s_fifo_full <= 1'b0;
            s_fifo_empty <= 1'b1;
        end else begin
            if (s_axil_awready && !s_fifo_empty) begin
                s_awaddr_fifo[s_fifo_rd_ptr] <= m_awaddr_fifo[m_fifo_rd_ptr];
                s_awprot_fifo[s_fifo_rd_ptr] <= m_awprot_fifo[m_fifo_rd_ptr];
                s_awvalid_fifo[s_fifo_rd_ptr] <= m_awvalid_fifo[m_fifo_rd_ptr];
                s_wdata_fifo[s_fifo_rd_ptr] <= m_wdata_fifo[m_fifo_rd_ptr];
                s_wstrb_fifo[s_fifo_rd_ptr] <= m_wstrb_fifo[m_fifo_rd_ptr];
                s_wvalid_fifo[s_fifo_rd_ptr] <= m_wvalid_fifo[m_fifo_rd_ptr];
                s_bready_fifo[s_fifo_rd_ptr] <= m_bready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
            if (s_axil_arready && !s_fifo_empty) begin
                s_araddr_fifo[s_fifo_rd_ptr] <= m_araddr_fifo[m_fifo_rd_ptr];
                s_arprot_fifo[s_fifo_rd_ptr] <= m_arprot_fifo[m_fifo_rd_ptr];
                s_arvalid_fifo[s_fifo_rd_ptr] <= m_arvalid_fifo[m_fifo_rd_ptr];
                s_rready_fifo[s_fifo_rd_ptr] <= m_rready_fifo[m_fifo_rd_ptr];
                s_fifo_rd_ptr <= s_fifo_rd_ptr + 1;
                if (s_fifo_rd_ptr == 2'b11) begin
                    s_fifo_full <= 1'b0;
                end
                m_fifo_empty <= 1'b1;
            end
        end
    end

    // Slave FIFO read
    always @(posed