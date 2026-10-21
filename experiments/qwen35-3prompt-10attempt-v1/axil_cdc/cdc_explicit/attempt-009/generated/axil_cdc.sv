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

    // ------------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------------
    wire s_rst_n;
    wire m_rst_n;
    wire s_valid;
    wire m_valid;
    wire s_ready;
    wire m_ready;
    wire s_data_valid;
    wire m_data_valid;
    wire s_data_ready;
    wire m_data_ready;
    wire s_resp_valid;
    wire m_resp_valid;
    wire s_resp_ready;
    wire m_resp_ready;

    // CDC Handshake Signals (Single bit)
    wire s_to_m_valid;
    wire m_to_s_valid;
    wire s_to_m_ready;
    wire m_to_s_ready;

    // CDC Data Signals (Multi-bit)
    wire [ADDR_WIDTH-1:0] s_to_m_addr;
    wire [2:0]            s_to_m_prot;
    wire [DATA_WIDTH-1:0] s_to_m_wdata;
    wire [STRB_WIDTH-1:0] s_to_m_wstrb;
    wire [1:0]            s_to_m_bresp;
    wire [DATA_WIDTH-1:0] s_to_m_rdata;
    wire [1:0]            s_to_m_rresp;

    wire [ADDR_WIDTH-1:0] m_to_s_addr;
    wire [2:0]            m_to_s_prot;
    wire [DATA_WIDTH-1:0] m_to_s_wdata;
    wire [STRB_WIDTH-1:0] m_to_s_wstrb;
    wire [1:0]            m_to_s_bresp;
    wire [DATA_WIDTH-1:0] m_to_s_rdata;
    wire [1:0]            m_to_s_rresp;

    // ------------------------------------------------------------------------
    // Reset Generation (Safe RDC)
    // ------------------------------------------------------------------------
    reg s_rst_n_int;
    reg m_rst_n_int;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_n_int <= 1'b1;
        else
            s_rst_n_int <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_n_int <= 1'b1;
        else
            m_rst_n_int <= 1'b0;
    end

    assign s_rst_n = s_rst_n_int;
    assign m_rst_n = m_rst_n_int;

    // ------------------------------------------------------------------------
    // CDC Handshake Logic (Gray Code / 2-Stage Synchronizer)
    // ------------------------------------------------------------------------
    // Slave -> Master Handshake
    reg s_to_m_valid_sync1;
    reg s_to_m_valid_sync2;
    reg s_to_m_ready_sync1;
    reg s_to_m_ready_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_to_m_valid_sync1 <= 1'b0;
            s_to_m_valid_sync2 <= 1'b0;
            s_to_m_ready_sync1 <= 1'b0;
            s_to_m_ready_sync2 <= 1'b0;
        end else begin
            s_to_m_valid_sync1 <= s_to_m_valid;
            s_to_m_valid_sync2 <= s_to_m_valid_sync1;
            s_to_m_ready_sync1 <= s_to_m_ready;
            s_to_m_ready_sync2 <= s_to_m_ready_sync1;
        end
    end

    assign s_to_m_ready = s_to_m_ready_sync1;
    assign m_valid = s_to_m_valid_sync2;

    // Master -> Slave Handshake
    reg m_to_s_valid_sync1;
    reg m_to_s_valid_sync2;
    reg m_to_s_ready_sync1;
    reg m_to_s_ready_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_to_s_valid_sync1 <= 1'b0;
            m_to_s_valid_sync2 <= 1'b0;
            m_to_s_ready_sync1 <= 1'b0;
            m_to_s_ready_sync2 <= 1'b0;
        end else begin
            m_to_s_valid_sync1 <= m_to_s_valid;
            m_to_s_valid_sync2 <= m_to_s_valid_sync1;
            m_to_s_ready_sync1 <= m_to_s_ready;
            m_to_s_ready_sync2 <= m_to_s_ready_sync1;
        end
    end

    assign m_to_s_ready = m_to_s_ready_sync1;
    assign s_valid = m_to_s_valid_sync2;

    // ------------------------------------------------------------------------
    // CDC Data Logic (Gray Code / 2-Stage Synchronizer)
    // ------------------------------------------------------------------------
    // Address & Prot
    reg [ADDR_WIDTH-1:0] s_to_m_addr_sync1;
    reg [ADDR_WIDTH-1:0] s_to_m_addr_sync2;
    reg [2:0]            s_to_m_prot_sync1;
    reg [2:0]            s_to_m_prot_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_to_m_addr_sync1 <= '{default: 0};
            s_to_m_addr_sync2 <= '{default: 0};
            s_to_m_prot_sync1 <= 3'b0;
            s_to_m_prot_sync2 <= 3'b0;
        end else begin
            s_to_m_addr_sync1 <= s_to_m_addr;
            s_to_m_addr_sync2 <= s_to_m_addr_sync1;
            s_to_m_prot_sync1 <= s_to_m_prot;
            s_to_m_prot_sync2 <= s_to_m_prot_sync1;
        end
    end

    assign s_to_m_addr = s_to_m_addr_sync2;
    assign s_to_m_prot = s_to_m_prot_sync2;

    // Write Data & Strb
    reg [DATA_WIDTH-1:0] s_to_m_wdata_sync1;
    reg [DATA_WIDTH-1:0] s_to_m_wdata_sync2;
    reg [STRB_WIDTH-1:0] s_to_m_wstrb_sync1;
    reg [STRB_WIDTH-1:0] s_to_m_wstrb_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_to_m_wdata_sync1 <= '{default: 0};
            s_to_m_wdata_sync2 <= '{default: 0};
            s_to_m_wstrb_sync1 <= '{default: 0};
            s_to_m_wstrb_sync2 <= '{default: 0};
        end else begin
            s_to_m_wdata_sync1 <= s_to_m_wdata;
            s_to_m_wdata_sync2 <= s_to_m_wdata_sync1;
            s_to_m_wstrb_sync1 <= s_to_m_wstrb;
            s_to_m_wstrb_sync2 <= s_to_m_wstrb_sync1;
        end
    end

    assign s_to_m_wdata = s_to_m_wdata_sync2;
    assign s_to_m_wstrb = s_to_m_wstrb_sync2;

    // Response Data
    reg [1:0]            s_to_m_bresp_sync1;
    reg [1:0]            s_to_m_bresp_sync2;
    reg [DATA_WIDTH-1:0] s_to_m_rdata_sync1;
    reg [DATA_WIDTH-1:0] s_to_m_rdata_sync2;
    reg [1:0]            s_to_m_rresp_sync1;
    reg [1:0]            s_to_m_rresp_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_to_m_bresp_sync1 <= 2'b0;
            s_to_m_bresp_sync2 <= 2'b0;
            s_to_m_rdata_sync1 <= '{default: 0};
            s_to_m_rdata_sync2 <= '{default: 0};
            s_to_m_rresp_sync1 <= 2'b0;
            s_to_m_rresp_sync2 <= 2'b0;
        end else begin
            s_to_m_bresp_sync1 <= s_to_m_bresp;
            s_to_m_bresp_sync2 <= s_to_m_bresp_sync1;
            s_to_m_rdata_sync1 <= s_to_m_rdata;
            s_to_m_rdata_sync2 <= s_to_m_rdata_sync1;
            s_to_m_rresp_sync1 <= s_to_m_rresp;
            s_to_m_rresp_sync2 <= s_to_m_rresp_sync1;
        end
    end

    assign s_to_m_bresp = s_to_m_bresp_sync2;
    assign s_to_m_rdata = s_to_m_rdata_sync2;
    assign s_to_m_rresp = s_to_m_rresp_sync2;

    // Master -> Slave Data
    reg [ADDR_WIDTH-1:0] m_to_s_addr_sync1;
    reg [ADDR_WIDTH-1:0] m_to_s_addr_sync2;
    reg [2:0]            m_to_s_prot_sync1;
    reg [2:0]            m_to_s_prot_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_to_s_addr_sync1 <= '{default: 0};
            m_to_s_addr_sync2 <= '{default: 0};
            m_to_s_prot_sync1 <= 3'b0;
            m_to_s_prot_sync2 <= 3'b0;
        end else begin
            m_to_s_addr_sync1 <= m_to_s_addr;
            m_to_s_addr_sync2 <= m_to_s_addr_sync1;
            m_to_s_prot_sync1 <= m_to_s_prot;
            m_to_s_prot_sync2 <= m_to_s_prot_sync1;
        end
    end

    assign m_to_s_addr = m_to_s_addr_sync2;
    assign m_to_s_prot = m_to_s_prot_sync2;

    // Write Data & Strb
    reg [DATA_WIDTH-1:0] m_to_s_wdata_sync1;
    reg [DATA_WIDTH-1:0] m_to_s_wdata_sync2;
    reg [STRB_WIDTH-1:0] m_to_s_wstrb_sync1;
    reg [STRB_WIDTH-1:0] m_to_s_wstrb_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_to_s_wdata_sync1 <= '{default: 0};
            m_to_s_wdata_sync2 <= '{default: 0};
            m_to_s_wstrb_sync1 <= '{default: 0};
            m_to_s_wstrb_sync2 <= '{default: 0};
        end else begin
            m_to_s_wdata_sync1 <= m_to_s_wdata;
            m_to_s_wdata_sync2 <= m_to_s_wdata_sync1;
            m_to_s_wstrb_sync1 <= m_to_s_wstrb;
            m_to_s_wstrb_sync2 <= m_to_s_wstrb_sync1;
        end
    end

    assign m_to_s_wdata = m_to_s_wdata_sync2;
    assign m_to_s_wstrb = m_to_s_wstrb_sync2;

    // Response Data
    reg [1:0]            m_to_s_bresp_sync1;
    reg [1:0]            m_to_s_bresp_sync2;
    reg [DATA_WIDTH-1:0] m_to_s_rdata_sync1;
    reg [DATA_WIDTH-1:0] m_to_s_rdata_sync2;
    reg [1:0]            m_to_s_rresp_sync1;
    reg [1:0]            m_to_s_rresp_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_to_s_bresp_sync1 <= 2'b0;
            m_to_s_bresp_sync2 <= 2'b0;
            m_to_s_rdata_sync1 <= '{default: 0};
            m_to_s_rdata_sync2 <= '{default: 0};
            m_to_s_rresp_sync1 <= 2'b0;
            m_to_s_rresp_sync2 <= 2'b0;
        end else begin
            m_to_s_bresp_sync1 <= m_to_s_bresp;
            m_to_s_bresp_sync2 <= m_to_s_bresp_sync1;
            m_to_s_rdata_sync1 <= m_to_s_rdata;
            m_to_s_rdata_sync2 <= m_to_s_rdata_sync1;
            m_to_s_rresp_sync1 <= m_to_s_rresp;
            m_to_s_rresp_sync2 <= m_to_s_rresp_sync1;
        end
    end

    assign m_to_s_bresp = m_to_s_bresp_sync2;
    assign m_to_s_rdata = m_to_s_rdata_sync2;
    assign m_to_s_rresp = m_to_s_rresp_sync2;

    // ------------------------------------------------------------------------
    // State Machines
    // ------------------------------------------------------------------------
    // Slave Side State Machine
    // States: IDLE, AW_WAIT, W_WAIT, B_WAIT, AR_WAIT, R_WAIT
    localparam [1:0] STATE_IDLE = 2'b00;
    localparam [1:0] STATE_AW = 2'b01;
    localparam [1:0] STATE_W = 2'b10;
    localparam [1:0] STATE_B = 2'b11;
    localparam [1:0] STATE_AR = 2'b00; // Reuse IDLE logic for AR start, but distinct flow
    localparam [1:0] STATE_R = 2'b01; // Reuse AW logic for AR start, but distinct flow

    // To simplify state encoding with limited states, we use a flag-based approach
    // or separate FSMs for Write and Read. Given "One outstanding write and one outstanding read",
    // we can have a combined FSM.
    // Let's define states clearly:
    // 0: IDLE
    // 1: AW_WAIT (Waiting for AW ready)
    // 2: W_WAIT (Waiting for W ready)
    // 3: B_WAIT (Waiting for B ready)
    // 4: AR_WAIT (Waiting for AR ready)
    // 5: R_WAIT (Waiting for R ready)

    reg [2:0] s_state;
    reg [2:0] m_state;

    // Slave State Encoding
    localparam [2:0] S_IDLE = 3'b000;
    localparam [2:0] S_AW_WAIT = 3'b001;
    localparam [2:0] S_W_WAIT = 3'b010;
    localparam [2:0] S_B_WAIT = 3'b011;
    localparam [2:0] S_AR_WAIT = 3'b100;
    localparam [2:0] S_R_WAIT = 3'b101;

    // Master State Encoding
    localparam [2:0] M_IDLE = 3'b000;
    localparam [2:0] M_AW_WAIT = 3'b001;
    localparam [2:0] M_W_WAIT = 3'b010;
    localparam [2:0] M_B_WAIT = 3'b011;
    localparam [2:0] M_AR_WAIT = 3'b100;
    localparam [2:0] M_R_WAIT = 3'b101;

    // Slave FSM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_state <= S_IDLE;
        else begin
            case (s_state)
                S_IDLE: begin
                    if (s_axil_awvalid && s_axil_awready)
                        s_state <= S_AW_WAIT;
                    else if (s_axil_arvalid && s_axil_arready)
                        s_state <= S_AR_WAIT;
                    else
                        s_state <= S_IDLE;
                end
                S_AW_WAIT: begin
                    if (s_axil_awready)
                        s_state <= S_W_WAIT;
                    else
                        s_state <= S_AW_WAIT;
                end
                S_W_WAIT: begin
                    if (s_axil_wvalid && s_axil_wready)
                        s_state <= S_B_WAIT;
                    else
                        s_state <= S_W_WAIT;
                end
                S_B_WAIT: begin
                    if (s_axil_bready)
                        s_state <= S_IDLE;
                    else
                        s_state <= S_B_WAIT;
                end
                S_AR_WAIT: begin
                    if (s_axil_arready)
                        s_state <= S_R_WAIT;
                    else
                        s_state <= S_AR_WAIT;
                end
                S_R_WAIT: begin
                    if (s_axil_rready)
                        s_state <= S_IDLE;
                    else
                        s_state <= S_R_WAIT;
                end
                default: s_state <= S_IDLE;
            endcase
        end
    end

    // Master FSM
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_state <= M_IDLE;
        else begin
            case (m_state)
                M_IDLE: begin
                    if (m_axil_awvalid && m_axil_awready)
                        m_state <= M_AW_WAIT;
                    else if (m_axil_arvalid && m_axil_arready)
                        m_state <= M_AR_WAIT;
                    else
                        m_state <= M_IDLE;
                end
                M_AW_WAIT: begin
                    if (m_axil_awready)
                        m_state <= M_W_WAIT;
                    else
                        m_state <= M_AW_WAIT;
                end
                M_W_WAIT: begin
                    if (m_axil_wvalid && m_axil_wready)
                        m_state <= M_B_WAIT;
                    else
                        m_state <= M_W_WAIT;
                end
                M_B_WAIT: begin
                    if (m_axil_bready)
                        m_state <= M_IDLE;
                    else
                        m_state <= M_B_WAIT;
                end
                M_AR_WAIT: begin
                    if (m_axil_arready)
                        m_state <= M_R_WAIT;
                    else
                        m_state <= M_AR_WAIT;
                end
                M_R_WAIT: begin
                    if (m_axil_rready)
                        m_state <= M_IDLE;
                    else
                        m_state <= M_R_WAIT;
                end
                default: m_state <= M_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Output Logic (Slave Side)
    // ------------------------------------------------------------------------
    // AW Channel
    assign s_axil_awready = (s_state == S_IDLE) || (s_state == S_AW_WAIT);
    assign s_axil_awaddr = (s_state == S_AW_WAIT) ? s_axil_awaddr : 0; // Address captured at entry
    assign s_axil_awprot = (s_state == S_AW_WAIT) ? s_axil_awprot : 0;
    assign s_axil_awvalid = (s_state == S_AW_WAIT);

    // W Channel
    assign s_axil_wready = (s_state == S_W_WAIT);
    assign s_axil_wdata = (s_state == S_W_WAIT) ? s_axil_wdata : 0;
    assign s_axil_wstrb = (s_state == S_W_WAIT) ? s_axil_wstrb : 0;
    assign s_axil_wvalid = (s_state == S_W_WAIT);

    // B Channel
    assign s_axil_bready = (s_state == S_B_WAIT);
    assign s_axil_bresp = (s_state == S_B_WAIT) ? s_axil_bresp : 0;
    assign s_axil_bvalid = (s_state == S_B_WAIT);

    // AR Channel
    assign s_axil_arready = (s_state == S_IDLE) || (s_state == S_AR_WAIT);
    assign s_axil_araddr = (s_state == S_AR_WAIT) ? s_axil_araddr : 0;
    assign s_axil_arprot = (s_state == S_AR_WAIT) ? s_axil_arprot : 0;
    assign s_axil_arvalid = (s_state == S_AR_WAIT);

    // R Channel
    assign s_axil_rready = (s_state == S_R_WAIT);
    assign s_axil_rdata = (s_state == S_R_WAIT) ? s_axil_rdata : 0;
    assign s_axil_rresp = (s_state == S_R_WAIT) ? s_axil_rresp : 0;
    assign s_axil_rvalid = (s_state == S_R_WAIT);

    // ------------------------------------------------------------------------
    // Output Logic (Master Side)
    // ------------------------------------------------------------------------
    // AW Channel
    assign m_axil_awready = (m_state == M_IDLE) || (m_state == M_AW_WAIT);
    assign m_axil_awaddr = (m_state == M_AW_WAIT) ? m_axil_awaddr : 0;
    assign m_axil_awprot = (m_state == M_AW_WAIT) ? m_axil_awprot : 0;
    assign m_axil_awvalid = (m_state == M_AW_WAIT);

    // W Channel
    assign m_axil_wready = (m_state == M_W_WAIT);
    assign m_axil_wdata = (m_state == M_W_WAIT) ? m_axil_wdata : 0;
    assign m_axil_wstrb = (m_state == M_W_WAIT) ? m_axil_wstrb : 0;
    assign m_axil_wvalid = (m_state == M_W_WAIT);

    // B Channel
    assign m_axil_bready = (m_state == M_B_WAIT);
    assign m_axil_bresp = (m_state == M_B_WAIT) ? m_axil_bresp : 0;
    assign m_axil_bvalid = (m_state == M_B_WAIT);

    // AR Channel
    assign m_axil_arready = (m_state == M_IDLE) || (m_state == M_AR_WAIT);
    assign m_axil_araddr = (m_state == M_AR_WAIT) ? m_axil_araddr : 0;
    assign m_axil_arprot = (m_state == M_AR_WAIT) ? m_axil_arprot : 0;
    assign m_axil_arvalid = (m_state == M_AR_WAIT);

    // R Channel
    assign m_axil_rready = (m_state == M_R_WAIT);
    assign m_axil_rdata = (m_state == M_R_WAIT) ? m_axil_rdata : 0;
    assign m_axil_rresp = (m_state == M_R_WAIT) ? m_axil_rresp : 0;
    assign m_axil_rvalid = (m_state == M_R_WAIT);

    // ------------------------------------------------------------------------
    // Data Forwarding Logic
    // ------------------------------------------------------------------------
    // Slave -> Master Forwarding
    // Address
    assign m_axil_awaddr = (s_state == S_AW_WAIT) ? s_axil_awaddr : 0;
    assign m_axil_awprot = (s_state == S_AW_WAIT) ? s_axil_awprot : 0;
    assign m_axil_awvalid = (s_state == S_AW_WAIT) && s_valid;

    assign m_axil_wdata = (s_state == S_W_WAIT) ? s_axil_wdata : 0;
    assign m_axil_wstrb = (s_state == S_W_WAIT) ? s_axil_wstrb : 0;
    assign m_axil_wvalid = (s_state == S_W_WAIT) && s_valid;

    assign m_axil_bready = (s_state == S_B_WAIT) && s_valid;

    assign m_axil_araddr = (s_state == S_AR_WAIT) ? s_axil_araddr : 0;
    assign m_axil_arprot = (s_state == S_AR_WAIT) ? s_axil_arprot : 0;
    assign m_axil_arvalid = (s_state == S_AR_WAIT) && s_valid;

    assign m_axil_rready = (s_state == S_R_WAIT) && s_valid;

    // Master -> Slave Forwarding
    // Address
    assign s_axil_awaddr = (m_state == M_AW_WAIT) ? m_axil_awaddr : 0;
    assign s_axil_awprot = (m_state == M_AW_WAIT) ? m_axil_awprot : 0;
    assign s_axil_awvalid = (m_state == M_AW_WAIT) && m_valid;

    assign s_axil_wdata = (m_state == M_W_WAIT) ? m_axil_wdata : 0;
    assign s_axil_wstrb = (m_state == M_W_WAIT) ? m_axil_wstrb : 0;
    assign s_axil_wvalid = (m_state == M_W_WAIT) && m_valid;

    assign s_axil_bready = (m_state == M_B_WAIT) && m_valid;

    assign s_axil_araddr = (m_state == M_AR_WAIT) ? m_axil_araddr : 0;
    assign s_axil_arprot = (m_state == M_AR_WAIT) ? m_axil_arprot : 0;
    assign s_axil_arvalid = (m_state == M_AR_WAIT) && m_valid;

    assign s_axil_rready = (m_state == M_R_WAIT) && m_valid;

    // Response Forwarding (Slave -> Master)
    assign m_axil_bresp = (s_state == S_B_WAIT) ? s_axil_bresp : 0;
    assign m_axil_bvalid = (s_state == S_B_WAIT) && s_valid;

    assign m_axil_rdata = (s_state == S_R_WAIT) ? s_axil_rdata : 0;
    assign m_axil_rresp = (s_state == S_R_WAIT) ? s_axil_rresp : 0;
    assign m_axil_rvalid = (s_state == S_R_WAIT) && s_valid;

    // Response Forwarding (Master -> Slave)
    assign s_axil_bresp = (m_state == M_B_WAIT) ? m_axil_bresp : 0;
    assign s_axil_bvalid = (m_state == M_B_WAIT) && m_valid;

    assign s_axil_rdata = (m_state == M_R_WAIT) ? m_axil_rdata : 0;
    assign s_axil_rresp = (m_state == M_R_WAIT) ? m_axil_rresp : 0;
    assign s_axil_rvalid = (m_state == M_R_WAIT) && m_valid;

endmodule
```<|im_end|>
