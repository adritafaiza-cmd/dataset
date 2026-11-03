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

    // ========================================================================
    // Write Address Channel (AW) - Slave to Master
    // ========================================================================
    // Slave side: capture AW when valid and ready
    reg        s_aw_valid;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;

    wire s_aw_handshake = s_axil_awvalid && s_axil_awready;

    // Master side: register AW data
    reg        m_aw_valid;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;

    // Handshake signals
    reg        s_aw_ready;
    reg        m_aw_ready;

    // AW channel: slave captures, master forwards
    // Use a simple handshake: slave asserts valid, master acknowledges

    // Slave side AW logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_valid <= 1'b0;
            s_aw_addr  <= {ADDR_WIDTH{1'b0}};
            s_aw_prot  <= 3'b000;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_aw_valid <= 1'b1;
                s_aw_addr  <= s_axil_awaddr;
                s_aw_prot  <= s_axil_awprot;
            end else if (s_aw_valid && m_aw_ready) begin
                s_aw_valid <= 1'b0;
            end
        end
    end

    // Slave AW ready: ready when not holding a pending AW
    assign s_axil_awready = ~s_aw_valid;

    // Master side AW logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_valid <= 1'b0;
            m_aw_addr  <= {ADDR_WIDTH{1'b0}};
            m_aw_prot  <= 3'b000;
        end else begin
            if (s_aw_valid && m_aw_ready) begin
                m_aw_valid <= 1'b0;
            end else if (s_aw_valid && ~m_aw_valid) begin
                m_aw_valid <= 1'b1;
                m_aw_addr  <= s_aw_addr;
                m_aw_prot  <= s_aw_prot;
            end
        end
    end

    // Master AW ready: ready when not holding a pending AW
    assign m_axil_awready = ~m_aw_valid;

    // Master AW output
    assign m_axil_awaddr  = m_aw_addr;
    assign m_axil_awprot  = m_aw_prot;
    assign m_axil_awvalid = m_aw_valid;

    // ========================================================================
    // Write Data Channel (W) - Slave to Master
    // ========================================================================
    reg        s_w_valid;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;

    wire s_w_handshake = s_axil_wvalid && s_axil_wready;

    reg        m_w_valid;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;

    reg        s_w_ready;
    reg        m_w_ready;

    // Slave side W logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_valid <= 1'b0;
            s_w_data  <= {DATA_WIDTH{1'b0}};
            s_w_strb  <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_w_valid <= 1'b1;
                s_w_data  <= s_axil_wdata;
                s_w_strb  <= s_axil_wstrb;
            end else if (s_w_valid && m_w_ready) begin
                s_w_valid <= 1'b0;
            end
        end
    end

    assign s_axil_wready = ~s_w_valid;

    // Master side W logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_valid <= 1'b0;
            m_w_data  <= {DATA_WIDTH{1'b0}};
            m_w_strb  <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_w_valid && m_w_ready) begin
                m_w_valid <= 1'b0;
            end else if (s_w_valid && ~m_w_valid) begin
                m_w_valid <= 1'b1;
                m_w_data  <= s_w_data;
                m_w_strb  <= s_w_strb;
            end
        end
    end

    assign m_axil_wready = ~m_w_valid;

    assign m_axil_wdata  = m_w_data;
    assign m_axil_wstrb  = m_w_strb;
    assign m_axil_wvalid = m_w_valid;

    // ========================================================================
    // Write Response Channel (B) - Master to Slave
    // ========================================================================
    reg        m_b_valid;
    reg [1:0]  m_b_resp;

    reg        s_b_valid;
    reg [1:0]  s_b_resp;

    // Master side B logic: capture B response
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_valid <= 1'b0;
            m_b_resp  <= 2'b00;
        end else begin
            if (m_axil_bvalid && m_axil_bready) begin
                m_b_valid <= 1'b0;
            end else if (m_axil_bvalid && ~m_b_valid) begin
                m_b_valid <= 1'b1;
                m_b_resp  <= m_axil_bresp;
            end
        end
    end

    // Master B ready: ready when not holding a pending B
    assign m_axil_bready = ~m_b_valid;

    // Slave side B logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid <= 1'b0;
            s_b_resp  <= 2'b00;
        end else begin
            if (m_b_valid && s_axil_bready) begin
                s_b_valid <= 1'b0;
            end else if (m_b_valid && ~s_b_valid) begin
                s_b_valid <= 1'b1;
                s_b_resp  <= m_b_resp;
            end
        end
    end

    assign s_axil_bvalid = s_b_valid;
    assign s_axil_bresp  = s_b_resp;

    // ========================================================================
    // Read Address Channel (AR) - Slave to Master
    // ========================================================================
    reg        s_ar_valid;
    reg [ADDR_WIDTH-1:0] s_ar_addr;
    reg [2:0]  s_ar_prot;

    reg        m_ar_valid;
    reg [ADDR_WIDTH-1:0] m_ar_addr;
    reg [2:0]  m_ar_prot;

    // Slave side AR logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_valid <= 1'b0;
            s_ar_addr  <= {ADDR_WIDTH{1'b0}};
            s_ar_prot  <= 3'b000;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_ar_valid <= 1'b1;
                s_ar_addr  <= s_axil_araddr;
                s_ar_prot  <= s_axil_arprot;
            end else if (s_ar_valid && m_ar_ready) begin
                s_ar_valid <= 1'b0;
            end
        end
    end

    assign s_axil_arready = ~s_ar_valid;

    // Master side AR logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_valid <= 1'b0;
            m_ar_addr  <= {ADDR_WIDTH{1'b0}};
            m_ar_prot  <= 3'b000;
        end else begin
            if (s_ar_valid && m_ar_ready) begin
                m_ar_valid <= 1'b0;
            end else if (s_ar_valid && ~m_ar_valid) begin
                m_ar_valid <= 1'b1;
                m_ar_addr  <= s_ar_addr;
                m_ar_prot  <= s_ar_prot;
            end
        end
    end

    assign m_axil_arready = ~m_ar_valid;

    assign m_axil_araddr  = m_ar_addr;
    assign m_axil_arprot  = m_ar_prot;
    assign m_axil_arvalid = m_ar_valid;

    // ========================================================================
    // Read Data Channel (R) - Master to Slave
    // ========================================================================
    reg        m_r_valid;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0]  m_r_resp;

    reg        s_r_valid;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0]  s_r_resp;

    // Master side R logic: capture R response
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_valid <= 1'b0;
            m_r_data  <= {DATA_WIDTH{1'b0}};
            m_r_resp  <= 2'b00;
        end else begin
            if (m_axil_rvalid && m_axil_rready) begin
                m_r_valid <= 1'b0;
            end else if (m_axil_rvalid && ~m_r_valid) begin
                m_r_valid <= 1'b1;
                m_r_data  <= m_axil_rdata;
                m_r_resp  <= m_axil_rresp;
            end
        end
    end

    assign m_axil_rready = ~m_r_valid;

    // Slave side R logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_valid <= 1'b0;
            s_r_data  <= {DATA_WIDTH{1'b0}};
            s_r_resp  <= 2'b00;
        end else begin
            if (m_r_valid && s_axil_rready) begin
                s_r_valid <= 1'b0;
            end else if (m_r_valid && ~s_r_valid) begin
                s_r_valid <= 1'b1;
                s_r_data  <= m_r_data;
                s_r_resp  <= m_r_resp;
            end
        end
    end

    assign s_axil_rvalid = s_r_valid;
    assign s_axil_rdata  = s_r_data;
    assign s_axil_rresp  = s_r_resp;

endmodule
