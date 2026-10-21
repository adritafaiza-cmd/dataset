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

    // -----------------------------------------------------------------------
    // Internal Signals
    // -----------------------------------------------------------------------
    wire s_aw_valid, s_w_valid, s_b_valid, s_ar_valid, s_r_valid;
    wire s_aw_ready, s_w_ready, s_b_ready, s_ar_ready, s_r_ready;
    
    wire m_aw_valid, m_w_valid, m_b_valid, m_ar_valid, m_r_valid;
    wire m_aw_ready, m_w_ready, m_b_ready, m_ar_ready, m_r_ready;
    
    reg [ADDR_WIDTH-1:0] s_aw_addr, s_ar_addr;
    reg [2:0] s_aw_prot, s_ar_prot;
    reg [DATA_WIDTH-1:0] s_w_data, s_w_strb;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0] s_b_resp, s_r_resp;
    
    reg s_aw_in_flight, s_ar_in_flight;
    reg s_b_in_flight, s_r_in_flight;
    
    reg [ADDR_WIDTH-1:0] m_aw_addr, m_ar_addr;
    reg [2:0] m_aw_prot, m_ar_prot;
    reg [DATA_WIDTH-1:0] m_w_data, m_w_strb;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0] m_b_resp, m_r_resp;
    
    reg m_aw_in_flight, m_ar_in_flight;
    reg m_b_in_flight, m_r_in_flight;

    // -----------------------------------------------------------------------
    // CDC Logic: Async FIFO / Handshake Bridge
    // -----------------------------------------------------------------------
    
    // --- Write Address Channel (AW) ---
    // Slave -> Master
    wire s_aw_valid_cdc = s_axil_awvalid & ~s_aw_in_flight;
    wire s_aw_ready_cdc = s_axil_awready;
    
    // Master -> Slave
    wire m_aw_valid_cdc = m_axil_awvalid & ~m_aw_in_flight;
    wire m_aw_ready_cdc = m_axil_awready;

    // --- Write Data Channel (W) ---
    // Slave -> Master
    wire s_w_valid_cdc = s_axil_wvalid & ~s_w_in_flight;
    wire s_w_ready_cdc = s_axil_wready;
    
    // Master -> Slave
    wire m_w_valid_cdc = m_axil_wvalid & ~m_w_in_flight;
    wire m_w_ready_cdc = m_axil_wready;

    // --- Write Response Channel (B) ---
    // Master -> Slave
    wire m_b_valid_cdc = m_axil_bvalid & ~m_b_in_flight;
    wire m_b_ready_cdc = m_axil_bready;
    
    // Slave -> Master
    wire s_b_valid_cdc = s_axil_bvalid & ~s_b_in_flight;
    wire s_b_ready_cdc = s_axil_bready;

    // --- Read Address Channel (AR) ---
    // Slave -> Master
    wire s_ar_valid_cdc = s_axil_arvalid & ~s_ar_in_flight;
    wire s_ar_ready_cdc = s_axil_arready;
    
    // Master -> Slave
    wire m_ar_valid_cdc = m_axil_arvalid & ~m_ar_in_flight;
    wire m_ar_ready_cdc = m_axil_arready;

    // --- Read Data Channel (R) ---
    // Master -> Slave
    wire m_r_valid_cdc = m_axil_rvalid & ~m_r_in_flight;
    wire m_r_ready_cdc = m_axil_rready;
    
    // Slave -> Master
    wire s_r_valid_cdc = s_axil_rvalid & ~s_r_in_flight;
    wire s_r_ready_cdc = s_axil_rready;

    // -----------------------------------------------------------------------
    // CDC Implementation: Dual-Edge Synchronizer + Handshake State Machine
    // -----------------------------------------------------------------------

    // --- AW Channel (Slave -> Master) ---
    // Capture valid on m_clk
    reg s_aw_valid_sync1, s_aw_valid_sync2;
    reg s_aw_addr_sync1, s_aw_addr_sync2;
    reg s_aw_prot_sync1, s_aw_prot_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_aw_valid_sync1 <= 1'b0;
            s_aw_valid_sync2 <= 1'b0;
            s_aw_addr_sync1 <= 1'b0;
            s_aw_addr_sync2 <= 1'b0;
            s_aw_prot_sync1 <= 1'b0;
            s_aw_prot_sync2 <= 1'b0;
        end else begin
            s_aw_valid_sync1 <= s_aw_valid_cdc;
            s_aw_valid_sync2 <= s_aw_valid_sync1;
            s_aw_addr_sync1 <= s_aw_addr;
            s_aw_addr_sync2 <= s_aw_addr_sync1;
            s_aw_prot_sync1 <= s_aw_prot;
            s_aw_prot_sync2 <= s_aw_prot_sync1;
        end
    end
    
    wire s_aw_valid_master = s_aw_valid_sync2;
    wire s_aw_addr_master = s_aw_addr_sync2;
    wire s_aw_prot_master = s_aw_prot_sync2;

    // Capture ready on s_clk
    reg m_aw_ready_sync1, m_aw_ready_sync2;
    reg m_aw_in_flight_sync1, m_aw_in_flight_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_aw_ready_sync1 <= 1'b0;
            m_aw_ready_sync2 <= 1'b0;
            m_aw_in_flight_sync1 <= 1'b0;
            m_aw_in_flight_sync2 <= 1'b0;
        end else begin
            m_aw_ready_sync1 <= m_aw_ready_cdc;
            m_aw_ready_sync2 <= m_aw_ready_sync1;
            m_aw_in_flight_sync1 <= m_aw_in_flight;
            m_aw_in_flight_sync2 <= m_aw_in_flight_sync1;
        end
    end
    
    wire m_aw_ready_slave = m_aw_ready_sync2;
    wire m_aw_in_flight_slave = m_aw_in_flight_sync2;

    // --- W Channel (Slave -> Master) ---
    // Capture valid on m_clk
    reg s_w_valid_sync1, s_w_valid_sync2;
    reg s_w_data_sync1, s_w_data_sync2;
    reg s_w_strb_sync1, s_w_strb_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_w_valid_sync1 <= 1'b0;
            s_w_valid_sync2 <= 1'b0;
            s_w_data_sync1 <= 1'b0;
            s_w_data_sync2 <= 1'b0;
            s_w_strb_sync1 <= 1'b0;
            s_w_strb_sync2 <= 1'b0;
        end else begin
            s_w_valid_sync1 <= s_w_valid_cdc;
            s_w_valid_sync2 <= s_w_valid_sync1;
            s_w_data_sync1 <= s_w_data;
            s_w_data_sync2 <= s_w_data_sync1;
            s_w_strb_sync1 <= s_w_strb;
            s_w_strb_sync2 <= s_w_strb_sync1;
        end
    end
    
    wire s_w_valid_master = s_w_valid_sync2;
    wire s_w_data_master = s_w_data_sync2;
    wire s_w_strb_master = s_w_strb_sync2;

    // Capture ready on s_clk
    reg m_w_ready_sync1, m_w_ready_sync2;
    reg m_w_in_flight_sync1, m_w_in_flight_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_w_ready_sync1 <= 1'b0;
            m_w_ready_sync2 <= 1'b0;
            m_w_in_flight_sync1 <= 1'b0;
            m_w_in_flight_sync2 <= 1'b0;
        end else begin
            m_w_ready_sync1 <= m_w_ready_cdc;
            m_w_ready_sync2 <= m_w_ready_sync1;
            m_w_in_flight_sync1 <= m_w_in_flight;
            m_w_in_flight_sync2 <= m_w_in_flight_sync1;
        end
    end
    
    wire m_w_ready_slave = m_w_ready_sync2;
    wire m_w_in_flight_slave = m_w_in_flight_sync2;

    // --- B Channel (Master -> Slave) ---
    // Capture valid on s_clk
    reg m_b_valid_sync1, m_b_valid_sync2;
    reg m_b_resp_sync1, m_b_resp_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_b_valid_sync1 <= 1'b0;
            m_b_valid_sync2 <= 1'b0;
            m_b_resp_sync1 <= 1'b0;
            m_b_resp_sync2 <= 1'b0;
        end else begin
            m_b_valid_sync1 <= m_b_valid_cdc;
            m_b_valid_sync2 <= m_b_valid_sync1;
            m_b_resp_sync1 <= m_b_resp;
            m_b_resp_sync2 <= m_b_resp_sync1;
        end
    end
    
    wire m_b_valid_slave = m_b_valid_sync2;
    wire m_b_resp_slave = m_b_resp_sync2;

    // Capture ready on m_clk
    reg s_b_ready_sync1, s_b_ready_sync2;
    reg s_b_in_flight_sync1, s_b_in_flight_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_b_ready_sync1 <= 1'b0;
            s_b_ready_sync2 <= 1'b0;
            s_b_in_flight_sync1 <= 1'b0;
            s_b_in_flight_sync2 <= 1'b0;
        end else begin
            s_b_ready_sync1 <= s_b_ready_cdc;
            s_b_ready_sync2 <= s_b_ready_sync1;
            s_b_in_flight_sync1 <= s_b_in_flight;
            s_b_in_flight_sync2 <= s_b_in_flight_sync1;
        end
    end
    
    wire s_b_ready_master = s_b_ready_sync2;
    wire s_b_in_flight_master = s_b_in_flight_sync2;

    // --- AR Channel (Slave -> Master) ---
    // Capture valid on m_clk
    reg s_ar_valid_sync1, s_ar_valid_sync2;
    reg s_ar_addr_sync1, s_ar_addr_sync2;
    reg s_ar_prot_sync1, s_ar_prot_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_ar_valid_sync1 <= 1'b0;
            s_ar_valid_sync2 <= 1'b0;
            s_ar_addr_sync1 <= 1'b0;
            s_ar_addr_sync2 <= 1'b0;
            s_ar_prot_sync1 <= 1'b0;
            s_ar_prot_sync2 <= 1'b0;
        end else begin
            s_ar_valid_sync1 <= s_ar_valid_cdc;
            s_ar_valid_sync2 <= s_ar_valid_sync1;
            s_ar_addr_sync1 <= s_ar_addr;
            s_ar_addr_sync2 <= s_ar_addr_sync1;
            s_ar_prot_sync1 <= s_ar_prot;
            s_ar_prot_sync2 <= s_ar_prot_sync1;
        end
    end
    
    wire s_ar_valid_master = s_ar_valid_sync2;
    wire s_ar_addr_master = s_ar_addr_sync2;
    wire s_ar_prot_master = s_ar_prot_sync2;

    // Capture ready on s_clk
    reg m_ar_ready_sync1, m_ar_ready_sync2;
    reg m_ar_in_flight_sync1, m_ar_in_flight_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_ar_ready_sync1 <= 1'b0;
            m_ar_ready_sync2 <= 1'b0;
            m_ar_in_flight_sync1 <= 1'b0;
            m_ar_in_flight_sync2 <= 1'b0;
        end else begin
            m_ar_ready_sync1 <= m_ar_ready_cdc;
            m_ar_ready_sync2 <= m_ar_ready_sync1;
            m_ar_in_flight_sync1 <= m_ar_in_flight;
            m_ar_in_flight_sync2 <= m_ar_in_flight_sync1;
        end
    end
    
    wire m_ar_ready_slave = m_ar_ready_sync2;
    wire m_ar_in_flight_slave = m_ar_in_flight_sync2;

    // --- R Channel (Master -> Slave) ---
    // Capture valid on s_clk
    reg m_r_valid_sync1, m_r_valid_sync2;
    reg m_r_resp_sync1, m_r_resp_sync2;
    reg m_r_data_sync1, m_r_data_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_r_valid_sync1 <= 1'b0;
            m_r_valid_sync2 <= 1'b0;
            m_r_resp_sync1 <= 1'b0;
            m_r_resp_sync2 <= 1'b0;
            m_r_data_sync1 <= 1'b0;
            m_r_data_sync2 <= 1'b0;
        end else begin
            m_r_valid_sync1 <= m_r_valid_cdc;
            m_r_valid_sync2 <= m_r_valid_sync1;
            m_r_resp_sync1 <= m_r_resp;
            m_r_resp_sync2 <= m_r_resp_sync1;
            m_r_data_sync1 <= m_r_data;
            m_r_data_sync2 <= m_r_data_sync1;
        end
    end
    
    wire m_r_valid_slave = m_r_valid_sync2;
    wire m_r_resp_slave = m_r_resp_sync2;
    wire m_r_data_slave = m_r_data_sync2;

    // Capture ready on m_clk
    reg s_r_ready_sync1, s_r_ready_sync2;
    reg s_r_in_flight_sync1, s_r_in_flight_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_r_ready_sync1 <= 1'b0;
            s_r_ready_sync2 <= 1'b0;
            s_r_in_flight_sync1 <= 1'b0;
            s_r_in_flight_sync2 <= 1'b0;
        end else begin
            s_r_ready_sync1 <= s_r_ready_cdc;
            s_r_ready_sync2 <= s_r_ready_sync1;
            s_r_in_flight_sync1 <= s_r_in_flight;
            s_r_in_flight_sync2 <= s_r_in_flight_sync1;
        end
    end
    
    wire s_r_ready_master = s_r_ready_sync2;
    wire s_r_in_flight_master = s_r_in_flight_sync2;

    // -----------------------------------------------------------------------
    // State Machines for Handshake Control
    // -----------------------------------------------------------------------

    // --- AW State Machine (Slave Side) ---
    // States: IDLE, AW_WAIT_READY, AW_WAIT_VALID
    reg [1:0] s_aw_state;
    parameter AW_IDLE = 2'b00, AW_WAIT_READY = 2'b01, AW_WAIT_VALID = 2'b10;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_aw_state <= AW_IDLE;
        else begin
            case (s_aw_state)
                AW_IDLE: begin
                    if (s_axil_awvalid) s_aw_state <= AW_WAIT_READY;
                    else s_aw_state <= AW_IDLE;
                end
                AW_WAIT_READY: begin
                    if (s_axil_awready) s_aw_state <= AW_WAIT_VALID;
                    else s_aw_state <= AW_WAIT_READY;
                end
                AW_WAIT_VALID: begin
                    if (s_aw_ready_cdc) s_aw_state <= AW_IDLE;
                    else s_aw_state <= AW_WAIT_VALID;
                end
                default: s_aw_state <= AW_IDLE;
            endcase
        end
    end

    // --- AW State Machine (Master Side) ---
    // States: IDLE, AW_WAIT_READY, AW_WAIT_VALID
    reg [1:0] m_aw_state;
    parameter M_AW_IDLE = 2'b00, M_AW_WAIT_READY = 2'b01, M_AW_WAIT_VALID = 2'b10;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_aw_state <= M_AW_IDLE;
        else begin
            case (m_aw_state)
                M_AW_IDLE: begin
                    if (s_aw_valid_master) m_aw_state <= M_AW_WAIT_READY;
                    else m_aw_state <= M_AW_IDLE;
                end
                M_AW_WAIT_READY: begin
                    if (m_aw_ready_slave) m_aw_state <= M_AW_WAIT_VALID;
                    else m_aw_state <= M_AW_WAIT_READY;
                end
                M_AW_WAIT_VALID: begin
                    if (m_aw_valid_cdc) m_aw_state <= M_AW_IDLE;
                    else m_aw_state <= M_AW_WAIT_VALID;
                end
                default: m_aw_state <= M_AW_IDLE;
            endcase
        end
    end

    // --- W State Machine (Slave Side) ---
    // States: IDLE, W_WAIT_READY, W_WAIT_VALID
    reg [1:0] s_w_state;
    parameter W_IDLE = 2'b00, W_WAIT_READY = 2'b01, W_WAIT_VALID = 2'b10;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_w_state <= W_IDLE;
        else begin
            case (s_w_state)
                W_IDLE: begin
                    if (s_axil_wvalid) s_w_state <= W_WAIT_READY;
                    else s_w_state <= W_IDLE;
                end
                W_WAIT_READY: begin
                    if (s_axil_wready) s_w_state <= W_WAIT_VALID;
                    else s_w_state <= W_WAIT_READY;
                end
                W_WAIT_VALID: begin
                    if (s_w_ready_cdc) s_w_state <= W_IDLE;
                    else s_w_state <= W_WAIT_VALID;
                end
                default: s_w_state <= W_IDLE;
            endcase
        end
    end

    // --- W State Machine (Master Side) ---
    // States: IDLE, W_WAIT_READY, W_WAIT_VALID
    reg [1:0] m_w_state;
    parameter M_W_IDLE = 2'b00, M_W_WAIT_READY = 2'b01, M_W_WAIT_VALID = 2'b10;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_w_state <= M_W_IDLE;
        else begin
            case (m_w_state)
                M_W_IDLE: begin
                    if (s_w_valid_master) m_w_state <= M_W_WAIT_READY;
                    else m_w_state <= M_W_IDLE;
                end
                M_W_WAIT_READY: begin
                    if (m_w_ready_slave) m_w_state <= M_W_WAIT_VALID;
                    else m_w_state <= M_W_WAIT_READY;
                end
                M_W_WAIT_VALID: begin
                    if (m_w_valid_cdc) m_w_state <= M_W_IDLE;
                    else m_w_state <= M_W_WAIT_VALID;
                end
                default: m_w_state <= M_W_IDLE;
            endcase
        end
    end

    // --- B State Machine (Master Side) ---
    // States: IDLE, B_WAIT_READY, B_WAIT_VALID
    reg [1:0] m_b_state;
    parameter M_B_IDLE = 2'b00, M_B_WAIT_READY = 2'b01, M_B_WAIT_VALID = 2'b10;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_b_state <= M_B_IDLE;
        else begin
            case (m_b_state)
                M_B_IDLE: begin
                    if (m_axil_bvalid) m_b_state <= M_B_WAIT_READY;
                    else m_b_state <= M_B_IDLE;
                end
                M_B_WAIT_READY: begin
                    if (m_axil_bready) m_b_state <= M_B_WAIT_VALID;
                    else m_b_state <= M_B_WAIT_READY;
                end
                M_B_WAIT_VALID: begin
                    if (m_b_ready_cdc) m_b_state <= M_B_IDLE;
                    else m_b_state <= M_B_WAIT_VALID;
                end
                default: m_b_state <= M_B_IDLE;
            endcase
        end
    end

    // --- B State Machine (Slave Side) ---
    // States: IDLE, B_WAIT_READY, B_WAIT_VALID
    reg [1:0] s_b_state;
    parameter S_B_IDLE = 2'b00, S_B_WAIT_READY = 2'b01, S_B_WAIT_VALID = 2'b10;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_b_state <= S_B_IDLE;
        else begin
            case (s_b_state)
                S_B_IDLE: begin
                    if (s_axil_bvalid) s_b_state <= S_B_WAIT_READY;
                    else s_b_state <= S_B_IDLE;
                end
                S_B_WAIT_READY: begin
                    if (s_axil_bready) s_b_state <= S_B_WAIT_VALID;
                    else s_b_state <= S_B_WAIT_READY;
                end
                S_B_WAIT_VALID: begin
                    if (s_b_ready_master) s_b_state <= S_B_IDLE;
                    else s_b_state <= S_B_WAIT_VALID;
                end
                default: s_b_state <= S_B_IDLE;
            endcase
        end
    end

    // --- AR State Machine (Slave Side) ---
    // States: IDLE, AR_WAIT_READY, AR_WAIT_VALID
    reg [1:0] s_ar_state;
    parameter AR_IDLE = 2'b00, AR_WAIT_READY = 2'b01, AR_WAIT_VALID = 2'b10;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_ar_state <= AR_IDLE;
        else begin
            case (s_ar_state)
                AR_IDLE: begin
                    if (s_axil_arvalid) s_ar_state <= AR_WAIT_READY;
                    else s_ar_state <= AR_IDLE;
                end
                AR_WAIT_READY: begin
                    if (s_axil_arready) s_ar_state <= AR_WAIT_VALID;
                    else s_ar_state <= AR_WAIT_READY;
                end
                AR_WAIT_VALID: begin
                    if (s_ar_ready_cdc) s_ar_state <= AR_IDLE;
                    else s_ar_state <= AR_WAIT_VALID;
                end
                default: s_ar_state <= AR_IDLE;
            endcase
        end
    end

    // --- AR State Machine (Master Side) ---
    // States: IDLE, AR_WAIT_READY, AR_WAIT_VALID
    reg [1:0] m_ar_state;
    parameter M_AR_IDLE = 2'b00, M_AR_WAIT_READY = 2'b01, M_AR_WAIT_VALID = 2'b10;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_ar_state <= M_AR_IDLE;
        else begin
            case (m_ar_state)
                M_AR_IDLE: begin
                    if (s_ar_valid_master) m_ar_state <= M_AR_WAIT_READY;
                    else m_ar_state <= M_AR_IDLE;
                end
                M_AR_WAIT_READY: begin
                    if (m_ar_ready_slave) m_ar_state <= M_AR_WAIT_VALID;
                    else m_ar_state <= M_AR_WAIT_READY;
                end
                M_AR_WAIT_VALID: begin
                    if (m_ar_valid_cdc) m_ar_state <= M_AR_IDLE;
                    else m_ar_state <= M_AR_WAIT_VALID;
                end
                default: m_ar_state <= M_AR_IDLE;
            endcase
        end
    end

    // --- R State Machine (Master Side) ---
    // States: IDLE, R_WAIT_READY, R_WAIT_VALID
    reg [1:0] m_r_state;
    parameter M_R_IDLE = 2'b00, M_R_WAIT_READY = 2'b01, M_R_WAIT_VALID = 2'b10;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_r_state <= M_R_IDLE;
        else begin
            case (m_r_state)
                M_R_IDLE: begin
                    if (m_axil_rvalid) m_r_state <= M_R_WAIT_READY;
                    else m_r_state <= M_R_IDLE;
                end
                M_R_WAIT_READY: begin
                    if (m_axil_rready) m_r_state <= M_R_WAIT_VALID;
                    else m_r_state <= M_R_WAIT_READY;
                end
                M_R_WAIT_VALID: begin
                    if (m_r_ready_cdc) m_r_state <= M_R_IDLE;
                    else m_r_state <= M_R_WAIT_VALID;
                end
                default: m_r_state <= M_R_IDLE;
            endcase
        end
    end

    // --- R State Machine (Slave Side) ---
    // States: IDLE, R_WAIT_READY, R_WAIT_VALID
    reg [1:0] s_r_state;
    parameter S_R_IDLE = 2'b00, S_R_WAIT_READY = 2'b01, S_R_WAIT_VALID = 2'b10;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_r_state <= S_R_IDLE;
        else begin
            case (s_r_state)
                S_R_IDLE: begin
                    if (s_axil_rvalid) s_r_state <= S_R_WAIT_READY;
                    else s_r_state <= S_R_IDLE;
                end
                S_R_WAIT_READY: begin
                    if (s_axil_rready) s_r_state <= S_R_WAIT_VALID;
                    else s_r_state <= S_R_WAIT_READY;
                end
                S_R_WAIT_VALID: begin
                    if (s_r_ready_master) s_r_state <= S_R_IDLE;
                    else s_r_state <= S_R_WAIT_VALID;
                end
                default: s_r_state <= S_R_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Output Logic
    // -----------------------------------------------------------------------

    // Slave Outputs
    assign s_axil_awready = (s_aw_state == AW_WAIT_READY);
    assign s_axil_wready = (s_w_state == W_WAIT_READY);
    assign s_axil_bresp = (s_b_state == S_B_WAIT_VALID) ? s_axil_bresp : 2'b0;
    assign s_axil_bvalid = (s_b_state == S_B_WAIT_VALID);
    assign s_axil_arready = (s_ar_state == AR_WAIT_READY);
    assign s_axil_rdata = (s_r_state == S_R_WAIT_VALID) ? s_axil_rdata : 32'h0;
    assign s_axil_rresp = (s_r_state == S_R_WAIT_VALID) ? s_axil_rresp : 2'b0;
    assign s_axil_rvalid = (s_r_state == S_R_WAIT_VALID);

    // Master Outputs
    assign m_axil_awready = (m_aw_state == M_AW_WAIT_READY);
    assign m_axil_wready = (m_w_state == M_W_WAIT_READY);
    assign m_axil_bresp = (m_b_state == M_B_WAIT_VALID) ? m_axil_bresp : 2'b0;
    assign m_axil_bvalid = (m_b_state == M_B_WAIT_VALID);
    assign m_axil_arready = (m_ar_state == M_AR_WAIT_READY);
    assign m_axil_rdata = (m_r_state == M_R_WAIT_VALID) ? m_axil_rdata : 32'h0;
    assign m_axil_rresp = (m_r_state == M_R_WAIT_VALID) ? m_axil_rresp : 2'b0;
    assign m_axil_rvalid = (m_r_state == M_R_WAIT_VALID);

    // -----------------------------------------------------------------------
    // Data Forwarding Logic
    // -----------------------------------------------------------------------

    // AW Forwarding
    assign m_axil_awaddr = (m_aw_state == M_AW_WAIT_VALID) ? m_axil_awaddr : 32'h0;
    assign m_axil_awprot = (m_aw_state == M_AW_WAIT_VALID) ? m_axil_awprot : 3'b0;
    assign m_axil_awvalid = (m_aw_state == M_AW_WAIT_VALID);

    assign s_axil_awaddr = (s_aw_state == AW_WAIT_VALID) ? s_axil_awaddr : 32'h0;
    assign s_axil_awprot = (s_aw_state == AW_WAIT_VALID) ? s_axil_awprot : 3'b0;
    assign s_axil_awvalid = (s_aw_state == AW_WAIT_VALID);

    // W Forwarding
    assign m_axil_wdata = (m_w_state == M_W_WAIT_VALID) ? m_axil_wdata : 32'h0;
    assign m_axil_wstrb = (m_w_state == M_W_WAIT_VALID) ? m_axil_wstrb : 4'h0;
    assign m_axil_wvalid = (m_w_state == M_W_WAIT_VALID);

    assign s_axil_wdata = (s_w_state == W_WAIT_VALID) ? s_axil_wdata : 32'h0;
    assign s_axil_wstrb = (s_w_state == W_WAIT_VALID) ? s_axil_wstrb : 4'h0;
    assign s_axil_wvalid = (s_w_state == W_WAIT_VALID);

    // B Forwarding
    assign s_axil_bresp = (s_b_state == S_B_WAIT_VALID) ? s_axil_bresp : 2'b0;
    assign s_axil_bvalid = (s_b_state == S_B_WAIT_VALID);

    assign m_axil_bresp = (m_b_state == M_B_WAIT_VALID) ? m_axil_bresp : 2'b0;
    assign m_axil_bvalid = (m_b_state == M_B_WAIT_VALID);

    // AR Forwarding
    assign m_axil_araddr = (m_ar_state == M_AR_WAIT_VALID) ? m_axil_araddr : 32'h0;
    assign m_axil_arprot = (m_ar_state == M_AR_WAIT_VALID) ? m_axil_arprot : 3'b0;
    assign m_axil_arvalid = (m_ar_state == M_AR_WAIT_VALID);

    assign s_axil_araddr = (s_ar_state == AR_WAIT_VALID) ? s_axil_araddr : 32'h0;
    assign s_axil_arprot = (s_ar_state == AR_WAIT_VALID) ? s_axil_arprot : 3'b0;
    assign s_axil_arvalid = (s_ar_state == AR_WAIT_VALID);

    // R Forwarding
    assign m_axil_rdata = (m_r_state == M_R_WAIT_VALID) ? m_axil_rdata : 32'h0;
    assign m_axil_rresp = (m_r_state == M_R_WAIT_VALID) ? m_axil_rresp : 2'b0;
    assign m_axil_rvalid = (m_r_state == M_R_WAIT_VALID);

    assign s_axil_rdata = (s_r_state == S_R_WAIT_VALID) ? s_axil_rdata : 32'h0;
    assign s_axil_rresp = (s_r_state == S_R_WAIT_VALID) ? s_axil_rresp : 2'b0;
    assign s_axil_rvalid = (s_r_state == S_R_WAIT_VALID);

endmodule
```<|im_end|>
