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
    // Write Channel: Slave -> Master
    // ========================================================================
    
    // Slave side: capture AW and W when both are valid
    reg        s_aw_valid;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;
    reg        s_w_valid;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;
    
    // AW handshake
    wire s_aw_handshake = s_axil_awvalid && s_axil_awready;
    wire s_w_handshake  = s_axil_wvalid && s_axil_wready;
    
    // AW ready: accept when not already holding an AW
    assign s_axil_awready = !s_aw_valid;
    
    // W ready: accept when not already holding a W
    assign s_axil_wready = !s_w_valid;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_valid <= 1'b0;
            s_aw_addr  <= {ADDR_WIDTH{1'b0}};
            s_aw_prot  <= 3'b000;
            s_w_valid  <= 1'b0;
            s_w_data   <= {DATA_WIDTH{1'b0}};
            s_w_strb   <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_aw_handshake) begin
                s_aw_valid <= 1'b1;
                s_aw_addr  <= s_axil_awaddr;
                s_aw_prot  <= s_axil_awprot;
            end
            if (s_w_handshake) begin
                s_w_valid <= 1'b1;
                s_w_data  <= s_axil_wdata;
                s_w_strb  <= s_axil_wstrb;
            end
        end
    end
    
    // Both AW and W captured: send to master
    wire s_write_ready = s_aw_valid && s_w_valid;
    
    // Master side: AW channel
    reg        m_aw_valid;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;
    
    // Master side: W channel
    reg        m_w_valid;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;
    
    // AW handshake on master side
    wire m_aw_handshake = m_axil_awvalid && m_axil_awready;
    wire m_w_handshake  = m_axil_wvalid && m_axil_wready;
    
    assign m_axil_awvalid = m_aw_valid;
    assign m_axil_awaddr  = m_aw_addr;
    assign m_axil_awprot  = m_aw_prot;
    
    assign m_axil_wvalid = m_w_valid;
    assign m_axil_wdata  = m_w_data;
    assign m_axil_wstrb  = m_w_strb;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_valid <= 1'b0;
            m_aw_addr  <= {ADDR_WIDTH{1'b0}};
            m_aw_prot  <= 3'b000;
            m_w_valid  <= 1'b0;
            m_w_data   <= {DATA_WIDTH{1'b0}};
            m_w_strb   <= {STRB_WIDTH{1'b0}};
        end else begin
            // Load from slave when slave has both AW and W
            if (s_write_ready) begin
                m_aw_valid <= 1'b1;
                m_aw_addr  <= s_aw_addr;
                m_aw_prot  <= s_aw_prot;
                m_w_valid  <= 1'b1;
                m_w_data   <= s_w_data;
                m_w_strb   <= s_w_strb;
            end
            // Clear AW when master accepts
            if (m_aw_handshake) begin
                m_aw_valid <= 1'b0;
            end
            // Clear W when master accepts
            if (m_w_handshake) begin
                m_w_valid <= 1'b0;
            end
        end
    end
    
    // Clear slave-side AW and W when master has accepted both
    wire m_write_complete = m_aw_handshake && m_w_handshake;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // Already handled above
        end else begin
            if (m_write_complete) begin
                s_aw_valid <= 1'b0;
                s_w_valid  <= 1'b0;
            end
        end
    end
    
    // ========================================================================
    // Write Response: Master -> Slave
    // ========================================================================
    
    // Master side: capture B response
    reg        m_b_valid;
    reg [1:0]  m_b_resp;
    
    wire m_b_handshake = m_axil_bvalid && m_axil_bready;
    
    assign m_axil_bready = !m_b_valid;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_valid <= 1'b0;
            m_b_resp  <= 2'b00;
        end else begin
            if (m_b_handshake) begin
                m_b_valid <= 1'b1;
                m_b_resp  <= m_axil_bresp;
            end
        end
    end
    
    // Slave side: present B response
    reg        s_b_valid;
    reg [1:0]  s_b_resp;
    
    wire s_b_handshake = s_axil_bvalid && s_axil_bready;
    
    assign s_axil_bvalid = s_b_valid;
    assign s_axil_bresp  = s_b_resp;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid <= 1'b0;
            s_b_resp  <= 2'b00;
        end else begin
            if (m_b_valid) begin
                s_b_valid <= 1'b1;
                s_b_resp  <= m_b_resp;
            end
            if (s_b_handshake) begin
                s_b_valid <= 1'b0;
            end
        end
    end
    
    // ========================================================================
    // Read Address: Slave -> Master
    // ========================================================================
    
    // Slave side: capture AR
    reg        s_ar_valid;
    reg [ADDR_WIDTH-1:0] s_ar_addr;
    reg [2:0]  s_ar_prot;
    
    wire s_ar_handshake = s_axil_arvalid && s_axil_arready;
    
    assign s_axil_arready = !s_ar_valid;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_valid <= 1'b0;
            s_ar_addr  <= {ADDR_WIDTH{1'b0}};
            s_ar_prot  <= 3'b000;
        end else begin
            if (s_ar_handshake) begin
                s_ar_valid <= 1'b1;
                s_ar_addr  <= s_axil_araddr;
                s_ar_prot  <= s_axil_arprot;
            end
        end
    end
    
    // Master side: present AR
    reg        m_ar_valid;
    reg [ADDR_WIDTH-1:0] m_ar_addr;
    reg [2:0]  m_ar_prot;
    
    wire m_ar_handshake = m_axil_arvalid && m_axil_arready;
    
    assign m_axil_arvalid = m_ar_valid;
    assign m_axil_araddr  = m_ar_addr;
    assign m_axil_arprot  = m_ar_prot;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_valid <= 1'b0;
            m_ar_addr  <= {ADDR_WIDTH{1'b0}};
            m_ar_prot  <= 3'b000;
        end else begin
            if (s_ar_valid) begin
                m_ar_valid <= 1'b1;
                m_ar_addr  <= s_ar_addr;
                m_ar_prot  <= s_ar_prot;
            end
            if (m_ar_handshake) begin
                m_ar_valid <= 1'b0;
            end
        end
    end
    
    // Clear slave-side AR when master accepts
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // Already handled above
        end else begin
            if (m_ar_handshake) begin
                s_ar_valid <= 1'b0;
            end
        end
    end
    
    // ========================================================================
    // Read Data: Master -> Slave
    // ========================================================================
    
    // Master side: capture R response
    reg        m_r_valid;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0]  m_r_resp;
    
    wire m_r_handshake = m_axil_rvalid && m_axil_rready;
    
    assign m_axil_rready = !m_r_valid;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_valid <= 1'b0;
            m_r_data  <= {DATA_WIDTH{1'b0}};
            m_r_resp  <= 2'b00;
        end else begin
            if (m_r_handshake) begin
                m_r_valid <= 1'b1;
                m_r_data  <= m_axil_rdata;
                m_r_resp  <= m_axil_rresp;
            end
        end
    end
    
    // Slave side: present R response
    reg        s_r_valid;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0]  s_r_resp;
    
    wire s_r_handshake = s_axil_rvalid && s_axil_rready;
    
    assign s_axil_rvalid = s_r_valid;
    assign s_axil_rdata  = s_r_data;
    assign s_axil_rresp  = s_r_resp;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_valid <= 1'b0;
            s_r_data  <= {DATA_WIDTH{1'b0}};
            s_r_resp  <= 2'b00;
        end else begin
            if (m_r_valid) begin
                s_r_valid <= 1'b1;
                s_r_data  <= m_r_data;
                s_r_resp  <= m_r_resp;
            end
            if (s_r_handshake) begin
                s_r_valid <= 1'b0;
            end
        end
    end

endmodule
