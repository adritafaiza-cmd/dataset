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

    // ------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------
    wire s_aw_valid, s_w_valid, s_ar_valid, s_r_valid;
    wire s_aw_ready, s_w_ready, s_ar_ready, s_r_ready;
    wire m_aw_valid, m_w_valid, m_ar_valid, m_r_valid;
    wire m_aw_ready, m_w_ready, m_ar_ready, m_r_ready;
    wire m_b_valid, m_b_ready;
    wire m_r_valid, m_r_ready;

    // State registers for Write Channel
    reg s_aw_state, s_w_state;
    reg m_aw_state, m_w_state;
    reg [ADDR_WIDTH-1:0] s_aw_addr, m_aw_addr;
    reg [2:0] s_aw_prot, m_aw_prot;
    reg [DATA_WIDTH-1:0] s_w_data, m_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb, m_w_strb;

    // State registers for Read Channel
    reg s_ar_state, s_r_state;
    reg m_ar_state, m_r_state;
    reg [ADDR_WIDTH-1:0] s_ar_addr, m_ar_addr;
    reg [2:0] s_ar_prot, m_ar_prot;
    reg [DATA_WIDTH-1:0] s_r_data, m_r_data;
    reg [1:0] s_r_resp, m_r_resp;

    // CDC Synchronizers (2-stage)
    reg s_aw_sync1, s_aw_sync2;
    reg s_w_sync1, s_w_sync2;
    reg s_ar_sync1, s_ar_sync2;
    reg s_r_sync1, s_r_sync2;
    reg s_b_sync1, s_b_sync2;
    reg s_r_valid_sync1, s_r_valid_sync2;

    reg m_aw_sync1, m_aw_sync2;
    reg m_w_sync1, m_w_sync2;
    reg m_ar_sync1, m_ar_sync2;
    reg m_r_sync1, m_r_sync2;
    reg m_b_sync1, m_b_sync2;
    reg m_r_valid_sync1, m_r_valid_sync2;

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Address)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_sync1 <= 1'b0;
            s_aw_sync2 <= 1'b0;
        end else begin
            s_aw_sync1 <= s_axil_awvalid;
            s_aw_sync2 <= s_aw_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_state <= 1'b0;
            m_aw_addr  <= '0;
            m_aw_prot  <= '0;
            m_aw_valid <= 1'b0;
        end else begin
            if (s_aw_sync2) begin
                m_aw_state <= 1'b1;
                m_aw_addr  <= s_axil_awaddr;
                m_aw_prot  <= s_axil_awprot;
                m_axil_awaddr <= s_axil_awaddr;
                m_axil_awprot <= s_axil_awprot;
                m_axil_awvalid <= 1'b1;
            end else begin
                m_aw_state <= 1'b0;
                m_axil_awvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Data)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_sync1 <= 1'b0;
            s_w_sync2 <= 1'b0;
        end else begin
            s_w_sync1 <= s_axil_wvalid;
            s_w_sync2 <= s_w_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_state <= 1'b0;
            m_w_data  <= '0;
            m_w_strb  <= '0;
            m_w_valid <= 1'b0;
        end else begin
            if (s_w_sync2) begin
                m_w_state <= 1'b1;
                m_w_data  <= s_axil_wdata;
                m_w_strb  <= s_axil_wstrb;
                m_axil_wdata <= s_axil_wdata;
                m_axil_wstrb <= s_axil_wstrb;
                m_axil_wvalid <= 1'b1;
            end else begin
                m_w_state <= 1'b0;
                m_axil_wvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Read Address)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_sync1 <= 1'b0;
            s_ar_sync2 <= 1'b0;
        end else begin
            s_ar_sync1 <= s_axil_arvalid;
            s_ar_sync2 <= s_ar_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_state <= 1'b0;
            m_ar_addr  <= '0;
            m_ar_prot  <= '0;
            m_ar_valid <= 1'b0;
        end else begin
            if (s_ar_sync2) begin
                m_ar_state <= 1'b1;
                m_ar_addr  <= s_axil_araddr;
                m_ar_prot  <= s_axil_arprot;
                m_axil_araddr <= s_axil_araddr;
                m_axil_arprot <= s_axil_arprot;
                m_axil_arvalid <= 1'b1;
            end else begin
                m_ar_state <= 1'b0;
                m_axil_arvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_sync1 <= 1'b0;
            m_aw_sync2 <= 1'b0;
            m_w_sync1  <= 1'b0;
            m_w_sync2  <= 1'b0;
        end else begin
            m_aw_sync1 <= m_axil_awready;
            m_aw_sync2 <= m_aw_sync1;
            m_w_sync1  <= m_axil_wready;
            m_w_sync2  <= m_w_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_state <= 1'b0;
            s_w_state  <= 1'b0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
        end else begin
            if (m_aw_sync2) begin
                s_aw_state <= 1'b1;
                s_axil_awready <= 1'b1;
            end else begin
                s_aw_state <= 1'b0;
                s_axil_awready <= 1'b0;
            end

            if (m_w_sync2) begin
                s_w_state <= 1'b1;
                s_axil_wready <= 1'b1;
            end else begin
                s_w_state <= 1'b0;
                s_axil_wready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Read Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_sync1 <= 1'b0;
            m_ar_sync2 <= 1'b0;
            m_r_sync1  <= 1'b0;
            m_r_sync2  <= 1'b0;
        end else begin
            m_ar_sync1 <= m_axil_arready;
            m_ar_sync2 <= m_ar_sync1;
            m_r_sync1  <= m_axil_rready;
            m_r_sync2  <= m_r_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_state <= 1'b0;
            s_r_state  <= 1'b0;
            s_axil_arready <= 1'b0;
            s_axil_rready <= 1'b0;
        end else begin
            if (m_ar_sync2) begin
                s_ar_state <= 1'b1;
                s_axil_arready <= 1'b1;
            end else begin
                s_ar_state <= 1'b0;
                s_axil_arready <= 1'b0;
            end

            if (m_r_sync2) begin
                s_r_state <= 1'b1;
                s_axil_rready <= 1'b1;
            end else begin
                s_r_state <= 1'b0;
                s_axil_rready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_sync1 <= 1'b0;
            m_b_sync2 <= 1'b0;
        end else begin
            m_b_sync1 <= m_axil_bvalid;
            m_b_sync2 <= m_b_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= '0;
        end else begin
            if (m_b_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= m_axil_bresp;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bvalid <= 1'b0;
                s_axil_bresp <= '0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Read Response)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_valid_sync1 <= 1'b0;
            m_r_valid_sync2 <= 1'b0;
        end else begin
            m_r_valid_sync1 <= m_axil_rvalid;
            m_r_valid_sync2 <= m_r_valid_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_state <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= '0;
            s_axil_rresp <= '0;
        end else begin
            if (m_r_valid_sync2) begin
                s_r_state <= 1'b1;
                s_axil_rvalid <= 1'b1;
                s_axil_rdata <= m_axil_rdata;
                s_axil_rresp <= m_axil_rresp;
            end else begin
                s_r_state <= 1'b0;
                s_axil_rvalid <= 1'b0;
                s_axil_rdata <= '0;
                s_axil_rresp <= '0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Read Data)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_sync1 <= 1'b0;
            s_r_data_sync2 <= 1'b0;
        end else begin
            s_r_data_sync1 <= s_axil_rdata;
            s_r_data_sync2 <= s_r_data_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_state <= 1'b0;
            m_r_data  <= '0;
            m_r_resp  <= '0;
            m_r_valid <= 1'b0;
        end else begin
            if (s_r_data_sync2) begin
                m_r_state <= 1'b1;
                m_r_data  <= s_axil_rdata;
                m_r_resp  <= s_axil_rresp;
                m_axil_rdata <= s_axil_rdata;
                m_axil_rresp <= s_axil_rresp;
                m_axil_rvalid <= 1'b1;
            end else begin
                m_r_state <= 1'b0;
                m_axil_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Read Response)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_resp_sync1 <= 1'b0;
            s_r_resp_sync2 <= 1'b0;
        end else begin
            s_r_resp_sync1 <= s_axil_rresp;
            s_r_resp_sync2 <= s_r_resp_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_state <= 1'b0;
            m_r_resp  <= '0;
            m_r_valid <= 1'b0;
        end else begin
            if (s_r_resp_sync2) begin
                m_r_state <= 1'b1;
                m_r_resp  <= s_axil_rresp;
                m_axil_rresp <= s_axil_rresp;
                m_axil_rvalid <= 1'b1;
            end else begin
                m_r_state <= 1'b0;
                m_axil_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Read Data Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_data_ready_sync1 <= 1'b0;
            m_r_data_ready_sync2 <= 1'b0;
        end else begin
            m_r_data_ready_sync1 <= m_axil_rready;
            m_r_data_ready_sync2 <= m_r_data_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_state <= 1'b0;
            s_axil_rready <= 1'b0;
        end else begin
            if (m_r_data_ready_sync2) begin
                s_r_state <= 1'b1;
                s_axil_rready <= 1'b1;
            end else begin
                s_r_state <= 1'b0;
                s_axil_rready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Read Data Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_valid_sync1 <= 1'b0;
            s_r_valid_sync2 <= 1'b0;
        end else begin
            s_r_valid_sync1 <= s_axil_rvalid;
            s_r_valid_sync2 <= s_r_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_state <= 1'b0;
            m_r_valid <= 1'b0;
        end else begin
            if (s_r_valid_sync2) begin
                m_r_state <= 1'b1;
                m_axil_rvalid <= 1'b1;
            end else begin
                m_r_state <= 1'b0;
                m_axil_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Read Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_resp_valid_sync1 <= 1'b0;
            s_r_resp_valid_sync2 <= 1'b0;
        end else begin
            s_r_resp_valid_sync1 <= s_axil_rvalid;
            s_r_resp_valid_sync2 <= s_r_resp_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_state <= 1'b0;
            m_r_valid <= 1'b0;
        end else begin
            if (s_r_resp_valid_sync2) begin
                m_r_state <= 1'b1;
                m_axil_rvalid <= 1'b1;
            end else begin
                m_r_state <= 1'b0;
                m_axil_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Read Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_resp_ready_sync1 <= 1'b0;
            m_r_resp_ready_sync2 <= 1'b0;
        end else begin
            m_r_resp_ready_sync1 <= m_axil_rready;
            m_r_resp_ready_sync2 <= m_r_resp_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_state <= 1'b0;
            s_axil_rready <= 1'b0;
        end else begin
            if (m_r_resp_ready_sync2) begin
                s_r_state <= 1'b1;
                s_axil_rready <= 1'b1;
            end else begin
                s_r_state <= 1'b0;
                s_axil_rready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid_sync1 <= 1'b0;
            s_b_valid_sync2 <= 1'b0;
        end else begin
            s_b_valid_sync1 <= s_axil_bvalid;
            s_b_valid_sync2 <= s_b_valid_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= 1'b0;
            m_b_valid <= 1'b0;
        end else begin
            if (s_b_valid_sync2) begin
                m_b_state <= 1'b1;
                m_axil_bvalid <= 1'b1;
            end else begin
                m_b_state <= 1'b0;
                m_axil_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Response Ready)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_ready_sync1 <= 1'b0;
            m_b_ready_sync2 <= 1'b0;
        end else begin
            m_b_ready_sync1 <= m_axil_bready;
            m_b_ready_sync2 <= m_b_ready_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= 1'b0;
            s_axil_bready <= 1'b0;
        end else begin
            if (m_b_ready_sync2) begin
                s_b_state <= 1'b1;
                s_axil_bready <= 1'b1;
            end else begin
                s_b_state <= 1'b0;
                s_axil_bready <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Response Valid)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
           