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
     * Internal signals
     */
    reg                           s_aw_valid_reg;
    reg                           s_aw_ready_reg;
    reg                           s_w_valid_reg;
    reg                           s_w_ready_reg;
    reg [1:0]                     s_b_resp_reg;
    reg                           s_b_valid_reg;
    reg                           s_ar_valid_reg;
    reg                           s_ar_ready_reg;
    reg [DATA_WIDTH-1:0]          s_r_data_reg;
    reg [1:0]                     s_r_resp_reg;
    reg                           s_r_valid_reg;
    reg                           m_aw_valid_reg;
    reg                           m_aw_ready_reg;
    reg                           m_w_valid_reg;
    reg                           m_w_ready_reg;
    reg                           m_b_ready_reg;
    reg                           m_ar_valid_reg;
    reg                           m_ar_ready_reg;
    reg                           m_r_ready_reg;
    reg [ADDR_WIDTH-1:0]          s_awaddr_sync;
    reg [2:0]                     s_awprot_sync;
    reg [DATA_WIDTH-1:0]          s_wdata_sync;
    reg [STRB_WIDTH-1:0]          s_wstrb_sync;
    reg [ADDR_WIDTH-1:0]          s_araddr_sync;
    reg [2:0]                     s_arprot_sync;
    reg [1:0]                     m_bresp_sync;
    reg                           m_bvalid_sync;
    reg [DATA_WIDTH-1:0]          m_rdata_sync;
    reg [1:0]                     m_rresp_sync;
    reg                           m_rvalid_sync;

    /*
     * Cross-clock domain synchronization for write address channel
     */
    reg [ADDR_WIDTH-1:0]          s_awaddr_meta;
    reg [2:0]                     s_awprot_meta;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_awaddr_sync <= 0;
            s_awprot_sync <= 0;
            s_awaddr_meta <= 0;
            s_awprot_meta <= 0;
        end else begin
            s_awaddr_meta <= s_axil_awaddr;
            s_awprot_meta <= s_axil_awprot;
            s_awaddr_sync <= s_awaddr_meta;
            s_awprot_sync <= s_awprot_meta;
        end
    end

    /*
     * Cross-clock domain synchronization for write data channel
     */
    reg [DATA_WIDTH-1:0]          s_wdata_meta;
    reg [STRB_WIDTH-1:0]          s_wstrb_meta;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wdata_sync <= 0;
            s_wstrb_sync <= 0;
            s_wdata_meta <= 0;
            s_wstrb_meta <= 0;
        end else begin
            s_wdata_meta <= s_axil_wdata;
            s_wstrb_meta <= s_axil_wstrb;
            s_wdata_sync <= s_wdata_meta;
            s_wstrb_sync <= s_wstrb_meta;
        end
    end

    /*
     * Cross-clock domain synchronization for read address channel
     */
    reg [ADDR_WIDTH-1:0]          s_araddr_meta;
    reg [2:0]                     s_arprot_meta;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_araddr_sync <= 0;
            s_arprot_sync <= 0;
            s_araddr_meta <= 0;
            s_arprot_meta <= 0;
        end else begin
            s_araddr_meta <= s_axil_araddr;
            s_arprot_meta <= s_axil_arprot;
            s_araddr_sync <= s_araddr_meta;
            s_arprot_sync <= s_arprot_meta;
        end
    end

    /*
     * Cross-clock domain synchronization for write response channel
     */
    reg [1:0]                     m_bresp_meta;
    reg                           m_bvalid_meta;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_bresp_sync <= 0;
            m_bvalid_sync <= 0;
            m_bresp_meta <= 0;
            m_bvalid_meta <= 0;
        end else begin
            m_bresp_meta <= m_axil_bresp;
            m_bvalid_meta <= m_axil_bvalid;
            m_bresp_sync <= m_bresp_meta;
            m_bvalid_sync <= m_bvalid_meta;
        end
    end

    /*
     * Cross-clock domain synchronization for read data channel
     */
    reg [DATA_WIDTH-1:0]          m_rdata_meta;
    reg [1:0]                     m_rresp_meta;
    reg                           m_rvalid_meta;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rdata_sync <= 0;
            m_rresp_sync <= 0;
            m_rvalid_sync <= 0;
            m_rdata_meta <= 0;
            m_rresp_meta <= 0;
            m_rvalid_meta <= 0;
        end else begin
            m_rdata_meta <= m_axil_rdata;
            m_rresp_meta <= m_axil_rresp;
            m_rvalid_meta <= m_axil_rvalid;
            m_rdata_sync <= m_rdata_meta;
            m_rresp_sync <= m_rresp_meta;
            m_rvalid_sync <= m_rvalid_meta;
        end
    end

    /*
     * Slave interface write address channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_valid_reg <= 0;
            s_aw_ready_reg <= 0;
        end else begin
            if (s_axil_awvalid && !s_aw_valid_reg && m_axil_awready) begin
                s_aw_valid_reg <= 1;
                s_aw_ready_reg <= 1;
            end else if (m_axil_awready) begin
                s_aw_valid_reg <= 0;
                s_aw_ready_reg <= 0;
            end
        end
    end

    /*
     * Slave interface write data channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_valid_reg <= 0;
            s_w_ready_reg <= 0;
        end else begin
            if (s_axil_wvalid && !s_w_valid_reg && m_axil_wready) begin
                s_w_valid_reg <= 1;
                s_w_ready_reg <= 1;
            end else if (m_axil_wready) begin
                s_w_valid_reg <= 0;
                s_w_ready_reg <= 0;
            end
        end
    end

    /*
     * Slave interface write response channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_resp_reg <= 0;
            s_b_valid_reg <= 0;
        end else begin
            if (m_bvalid_sync && !s_b_valid_reg) begin
                s_b_resp_reg <= m_bresp_sync;
                s_b_valid_reg <= 1;
            end else if (s_axil_bready) begin
                s_b_valid_reg <= 0;
            end
        end
    end

    /*
     * Slave interface read address channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_valid_reg <= 0;
            s_ar_ready_reg <= 0;
        end else begin
            if (s_axil_arvalid && !s_ar_valid_reg && m_axil_arready) begin
                s_ar_valid_reg <= 1;
                s_ar_ready_reg <= 1;
            end else if (m_axil_arready) begin
                s_ar_valid_reg <= 0;
                s_ar_ready_reg <= 0;
            end
        end
    end

    /*
     * Slave interface read data channel
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_reg <= 0;
            s_r_resp_reg <= 0;
            s_r_valid_reg <= 0;
        end else begin
            if (m_rvalid_sync && !s_r_valid_reg) begin
                s_r_data_reg <= m_rdata_sync;
                s_r_resp_reg <= m_rresp_sync;
                s_r_valid_reg <= 1;
            end else if (s_axil_rready) begin
                s_r_valid_reg <= 0;
            end
        end
    end

    /*
     * Master interface write address channel
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_valid_reg <= 0;
            m_aw_ready_reg <= 0;
        end else begin
            if (s_aw_valid_reg && !m_aw_valid_reg) begin
                m_aw_valid_reg <= 1;
                m_aw_ready_reg <= 1;
            end else if (m_axil_awready) begin
                m_aw_valid_reg <= 0;
                m_aw_ready_reg <= 0;
            end
        end
    end

    /*
     * Master interface write data channel
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_valid_reg <= 0;
            m_w_ready_reg <= 0;
        end else begin
            if (s_w_valid_reg && !m_w_valid_reg) begin
                m_w_valid_reg <= 1;
                m_w_ready_reg <= 1;
            end else if (m_axil_wready) begin
                m_w_valid_reg <= 0;
                m_w_ready_reg <= 0;
            end
        end
    end

    /*
     * Master interface write response channel
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_reg <= 0;
        end else begin
            if (m_axil_bvalid) begin
                m_b_ready_reg <= 1;
            end else if (m_axil_awready || m_axil_wready) begin
                m_b_ready_reg <= 0;
            end
        end
    end

    /*
     * Master interface read address channel
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_valid_reg <= 0;
            m_ar_ready_reg <= 0;
        end else begin
            if (s_ar_valid_reg && !m_ar_valid_reg) begin
                m_ar_valid_reg <= 1;
                m_ar_ready_reg <= 1;
            end else if (m_axil_arready) begin
                m_ar_valid_reg <= 0;
                m_ar_ready_reg <= 0;
            end
        end
    end

    /*
     * Master interface read data channel
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_ready_reg <= 0;
        end else begin
            if (m_axil_rvalid) begin
                m_r_ready_reg <= 1;
            end else if (m_axil_arready) begin
                m_r_ready_reg <= 0;
            end
        end
    end

    /*
     * Assignments
     */
    assign s_axil_awready = s_aw_ready_reg;
    assign s_axil_wready = s_w_ready_reg;
    assign s_axil_bresp = s_b_resp_reg;
    assign s_axil_bvalid = s_b_valid_reg;
    assign s_axil_arready = s_ar_ready_reg;
    assign s_axil_rdata = s_r_data_reg;
    assign s_axil_rresp = s_r_resp_reg;
    assign s_axil_rvalid = s_r_valid_reg;
    assign m_axil_awaddr = s_awaddr_sync;
    assign m_axil_awprot = s_awprot_sync;
    assign m_axil_awvalid = m_aw_valid_reg;
    assign m_axil_wdata = s_wdata_sync;
    assign m_axil_wstrb = s_wstrb_sync;
    assign m_axil_wvalid = m_w_valid_reg;
    assign m_axil_bready = m_b_ready_reg;
    assign m_axil_araddr = s_araddr_sync;
    assign m_axil_arprot = s_arprot_sync;
    assign m_axil_arvalid = m_ar_valid_reg;
    assign m_axil_rready = m_r_ready_reg;

endmodule
