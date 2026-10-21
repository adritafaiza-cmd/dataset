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
    wire [ADDR_WIDTH-1:0] s_awaddr, s_araddr;
    wire [2:0]            s_awprot, s_arprot;
    wire [DATA_WIDTH-1:0] s_wdata;
    wire [STRB_WIDTH-1:0] s_wstrb;
    wire                  s_wvalid;
    wire [DATA_WIDTH-1:0] s_rdata;
    wire [1:0]            s_rresp;
    wire                  s_rvalid;
    
    wire [ADDR_WIDTH-1:0] m_awaddr, m_araddr;
    wire [2:0]            m_awprot, m_arprot;
    wire [DATA_WIDTH-1:0] m_wdata;
    wire [STRB_WIDTH-1:0] m_wstrb;
    wire                  m_wvalid;
    wire [DATA_WIDTH-1:0] m_rdata;
    wire [1:0]            m_rresp;
    wire                  m_rvalid;

    // CDC Registers for Address/Protocols
    reg [ADDR_WIDTH-1:0] s_awaddr_reg, s_araddr_reg;
    reg [2:0]            s_awprot_reg, s_arprot_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg                  s_wvalid_reg;
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0]            s_rresp_reg;
    reg                  s_rvalid_reg;

    reg [ADDR_WIDTH-1:0] m_awaddr_reg, m_araddr_reg;
    reg [2:0]            m_awprot_reg, m_arprot_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg                  m_wvalid_reg;
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0]            m_rresp_reg;
    reg                  m_rvalid_reg;

    // CDC Registers for Valid/Ready Handshaking
    reg                  s_awvalid_reg, s_arvalid_reg, s_wvalid_reg, s_rvalid_reg;
    reg                  s_awready_reg, s_arready_reg, s_wready_reg, s_rready_reg;
    reg                  s_bvalid_reg;
    reg                  s_bready_reg;

    reg                  m_awvalid_reg, m_arvalid_reg, m_wvalid_reg, m_rvalid_reg;
    reg                  m_awready_reg, m_arready_reg, m_wready_reg, m_rready_reg;
    reg                  m_bvalid_reg;
    reg                  m_bready_reg;

    // Transaction State Machine State
    typedef enum logic [1:0] {
        IDLE,
        AW_PENDING,
        AR_PENDING,
        W_PENDING,
        B_PENDING,
        R_PENDING
    } state_t;

    state_t state, next_state;

    // Write Response Buffer
    reg [1:0] bresp_buffer;
    reg       bresp_valid;

    // Read Response Buffer
    reg [DATA_WIDTH-1:0] rdata_buffer;
    reg [1:0]            rresp_buffer;
    reg                  rresp_valid;

    // Write Data Buffer (for delayed response)
    reg [DATA_WIDTH-1:0] wdata_buffer;
    reg [STRB_WIDTH-1:0] wstrb_buffer;
    reg                  wdata_valid;

    // Address/Protocols Buffer
    reg [ADDR_WIDTH-1:0] awaddr_buffer;
    reg [2:0]            awprot_buffer;
    reg                  awaddr_valid;

    reg [ADDR_WIDTH-1:0] araddr_buffer;
    reg [2:0]            arprot_buffer;
    reg                  araddr_valid;

    // ------------------------------------------------------------------
    // CDC Logic: Slave Side to Master Side (s -> m)
    // ------------------------------------------------------------------
    // Address/Protocol Capture
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg   <= '0;
            s_araddr_reg   <= '0;
            s_awprot_reg   <= '0;
            s_arprot_reg   <= '0;
            s_wdata_reg    <= '0;
            s_wstrb_reg    <= '0;
            s_wvalid_reg   <= 1'b0;
            s_rdata_reg    <= '0;
            s_rresp_reg    <= '0;
            s_rvalid_reg   <= 1'b0;
        end else begin
            s_awaddr_reg   <= s_awaddr;
            s_araddr_reg   <= s_araddr;
            s_awprot_reg   <= s_awprot;
            s_arprot_reg   <= s_arprot;
            s_wdata_reg    <= s_wdata;
            s_wstrb_reg    <= s_wstrb;
            s_wvalid_reg   <= s_wvalid;
            s_rdata_reg    <= s_rdata;
            s_rresp_reg    <= s_rresp;
            s_rvalid_reg   <= s_rvalid;
        end
    end

    // Valid/Ready Handshake (Simple 2-stage FIFO concept)
    // We use a single register for valid/ready to handle the crossing.
    // To ensure no loss, we hold the signal until the other domain is ready.
    
    // Slave Valid -> Master Valid
    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_awvalid_reg <= 1'b0;
            s_arvalid_reg <= 1'b0;
            s_wvalid_reg  <= 1'b0;
            s_rvalid_reg  <= 1'b0;
            s_bvalid_reg  <= 1'b0;
            s_bready_reg  <= 1'b1; // Assume ready initially
        end else begin
            s_awvalid_reg <= s_axil_awvalid;
            s_arvalid_reg <= s_axil_arvalid;
            s_wvalid_reg  <= s_axil_wvalid;
            s_rvalid_reg  <= s_axil_rvalid;
            s_bvalid_reg  <= s_axil_bvalid;
            // Ready is driven by the handshake logic below
        end
    end

    // Slave Ready -> Master Ready
    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_awready_reg <= 1'b1;
            s_arready_reg <= 1'b1;
            s_wready_reg  <= 1'b1;
            s_rready_reg  <= 1'b1;
            s_bready_reg  <= 1'b1;
        end else begin
            s_awready_reg <= s_axil_awready;
            s_arready_reg <= s_axil_arready;
            s_wready_reg  <= s_axil_wready;
            s_rready_reg  <= s_axil_rready;
            s_bready_reg  <= s_axil_bready;
        end
    end

    // ------------------------------------------------------------------
    // CDC Logic: Master Side to Slave Side (m -> s)
    // ------------------------------------------------------------------
    // Address/Protocol Capture
    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_awaddr_reg   <= '0;
            m_araddr_reg   <= '0;
            m_awprot_reg   <= '0;
            m_arprot_reg   <= '0;
            m_wdata_reg    <= '0;
            m_wstrb_reg    <= '0;
            m_wvalid_reg   <= 1'b0;
            m_rdata_reg    <= '0;
            m_rresp_reg    <= '0;
            m_rvalid_reg   <= 1'b0;
        end else begin
            m_awaddr_reg   <= m_axil_awaddr;
            m_araddr_reg   <= m_axil_araddr;
            m_awprot_reg   <= m_axil_awprot;
            m_arprot_reg   <= m_axil_arprot;
            m_wdata_reg    <= m_axil_wdata;
            m_wstrb_reg    <= m_axil_wstrb;
            m_wvalid_reg   <= m_axil_wvalid;
            m_rdata_reg    <= m_axil_rdata;
            m_rresp_reg    <= m_axil_rresp;
            m_rvalid_reg   <= m_axil_rvalid;
        end
    end

    // Valid/Ready Handshake
    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awvalid_reg <= 1'b0;
            m_arvalid_reg <= 1'b0;
            m_wvalid_reg  <= 1'b0;
            m_rvalid_reg  <= 1'b0;
            m_bvalid_reg  <= 1'b0;
            m_bready_reg  <= 1'b1;
        end else begin
            m_awvalid_reg <= m_axil_awvalid;
            m_arvalid_reg <= m_axil_arvalid;
            m_wvalid_reg  <= m_axil_wvalid;
            m_rvalid_reg  <= m_axil_rvalid;
            m_bvalid_reg  <= m_axil_bvalid;
            m_bready_reg  <= m_axil_bready;
        end
    end

    // Ready signals from Slave side
    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awready_reg <= 1'b1;
            m_arready_reg <= 1'b1;
            m_wready_reg  <= 1'b1;
            m_rready_reg  <= 1'b1;
        end else begin
            m_awready_reg <= m_axil_awready;
            m_arready_reg <= m_axil_arready;
            m_wready_reg  <= m_axil_wready;
            m_rready_reg  <= m_axil_rready;
        end
    end

    // ------------------------------------------------------------------
    // Handshake Logic (Slave Side)
    // ------------------------------------------------------------------
    // Generate ready signals based on internal state and CDC registers
    assign s_axil_awready = (s_awvalid_reg && s_awready_reg) ? 1'b1 : 1'b0;
    assign s_axil_arready = (s_arvalid_reg && s_arready_reg) ? 1'b1 : 1'b0;
    assign s_axil_wready  = (s_wvalid_reg && s_wready_reg) ? 1'b1 : 1'b0;
    assign s_axil_rready  = (s_rvalid_reg && s_rready_reg) ? 1'b1 : 1'b0;
    assign s_axil_bready  = (s_bvalid_reg && s_bready_reg) ? 1'b1 : 1'b0;

    // ------------------------------------------------------------------
    // Handshake Logic (Master Side)
    // ------------------------------------------------------------------
    assign m_axil_awready = (m_awvalid_reg && m_awready_reg) ? 1'b1 : 1'b0;
    assign m_axil_arready = (m_arvalid_reg && m_arready_reg) ? 1'b1 : 1'b0;
    assign m_axil_wready  = (m_wvalid_reg && m_wready_reg) ? 1'b1 : 1'b0;
    assign m_axil_rready  = (m_rvalid_reg && m_rready_reg) ? 1'b1 : 1'b0;
    assign m_axil_bready  = (m_bvalid_reg && m_bready_reg) ? 1'b1 : 1'b0;

    // ------------------------------------------------------------------
    // AXI Lite Protocol State Machine
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (m_axil_awvalid && m_axil_awready) begin
                        state <= AW_PENDING;
                    end else if (m_axil_arvalid && m_axil_arready) begin
                        state <= AR_PENDING;
                    end
                end

                AW_PENDING: begin
                    if (m_axil_wvalid && m_axil_wready) begin
                        state <= W_PENDING;
                    end else if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                    end
                end

                AR_PENDING: begin
                    if (m_axil_rvalid && m_axil_rready) begin
                        state <= R_PENDING;
                    end else if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                    end
                end

                W_PENDING: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                    end
                end

                R_PENDING: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Output Logic (Slave Side)
    // ------------------------------------------------------------------
    assign s_axil_awaddr = s_awaddr_reg;
    assign s_axil_awprot = s_awprot_reg;
    assign s_axil_wdata  = s_wdata_reg;
    assign s_axil_wstrb  = s_wstrb_reg;
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_bresp  = s_bresp_buffer; // Will be updated in state machine

    assign s_axil_awvalid = s_awvalid_reg;
    assign s_axil_arvalid = s_arvalid_reg;
    assign s_axil_wvalid  = s_wvalid_reg;
    assign s_axil_rvalid  = s_rvalid_reg;
    assign s_axil_bvalid  = s_bvalid_reg;

    // ------------------------------------------------------------------
    // Output Logic (Master Side)
    // ------------------------------------------------------------------
    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = m_awprot_reg;
    assign m_axil_wdata  = m_wdata_reg;
    assign m_axil_wstrb  = m_wstrb_reg;
    assign m_axil_rdata  = m_rdata_reg;
    assign m_axil_rresp  = m_rresp_reg;
    assign m_axil_bresp  = m_bresp_buffer;

    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_wvalid  = m_wvalid_reg;
    assign m_axil_rvalid  = m_rvalid_reg;
    assign m_axil_bvalid  = m_bvalid_reg;

    // ------------------------------------------------------------------
    // State Machine Logic for Master Side
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            state <= IDLE;
            bresp_buffer <= '0;
            bresp_valid <= 1'b0;
            wdata_buffer <= '0;
            wstrb_buffer <= '0;
            wdata_valid <= 1'b0;
            awaddr_buffer <= '0;
            awprot_buffer <= '0;
            awaddr_valid <= 1'b0;
            araddr_buffer <= '0;
            arprot_buffer <= '0;
            araddr_valid <= 1'b0;
            rdata_buffer <= '0;
            rresp_buffer <= '0;
            rresp_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (m_axil_awvalid && m_axil_awready) begin
                        state <= AW_PENDING;
                        awaddr_buffer <= m_axil_awaddr;
                        awprot_buffer <= m_axil_awprot;
                        awaddr_valid <= 1'b1;
                    end else if (m_axil_arvalid && m_axil_arready) begin
                        state <= AR_PENDING;
                        araddr_buffer <= m_axil_araddr;
                        arprot_buffer <= m_axil_arprot;
                        araddr_valid <= 1'b1;
                    end
                end

                AW_PENDING: begin
                    if (m_axil_wvalid && m_axil_wready) begin
                        state <= W_PENDING;
                        wdata_buffer <= m_axil_wdata;
                        wstrb_buffer <= m_axil_wstrb;
                        wdata_valid <= 1'b1;
                    end else if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                        bresp_buffer <= m_axil_bresp;
                        bresp_valid <= 1'b1;
                    end
                end

                AR_PENDING: begin
                    if (m_axil_rvalid && m_axil_rready) begin
                        state <= R_PENDING;
                        rdata_buffer <= m_axil_rdata;
                        rresp_buffer <= m_axil_rresp;
                        rresp_valid <= 1'b1;
                    end else if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                        bresp_buffer <= m_axil_bresp;
                        bresp_valid <= 1'b1;
                    end
                end

                W_PENDING: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                        bresp_buffer <= m_axil_bresp;
                        bresp_valid <= 1'b1;
                    end
                end

                R_PENDING: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        state <= IDLE;
                        bresp_buffer <= m_axil_bresp;
                        bresp_valid <= 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    bresp_buffer <= '0;
                    bresp_valid <= 1'b0;
                    wdata_buffer <= '0;
                    wstrb_buffer <= '0;
                    wdata_valid <= 1'b0;
                    awaddr_buffer <= '0;
                    awprot_buffer <= '0;
                    awaddr_valid <= 1'b0;
                    araddr_buffer <= '0;
                    arprot_buffer <= '0;
                    araddr_valid <= 1'b0;
                    rdata_buffer <= '0;
                    rresp_buffer <= '0;
                    rresp_valid <= 1'b0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Output Drivers for Slave Side based on State Machine
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr <= '0;
            s_axil_awprot <= '0;
            s_axil_wdata  <= '0;
            s_axil_wstrb  <= '0;
            s_axil_rdata  <= '0;
            s_axil_rresp  <= '0;
            s_axil_bresp  <= '0;
            s_axil_awvalid <= 1'b0;
            s_axil_arvalid <= 1'b0;
            s_axil_wvalid  <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axil_awaddr <= '0;
                    s_axil_awprot <= '0;
                    s_axil_wdata  <= '0;
                    s_axil_wstrb  <= '0;
                    s_axil_rdata  <= '0;
                    s_axil_rresp  <= '0;
                    s_axil_bresp  <= '0;
                    s_axil_awvalid <= 1'b0;
                    s_axil_arvalid <= 1'b0;
                    s_axil_wvalid  <= 1'b0;
                    s_axil_rvalid  <= 1'b0;
                    s_axil_bvalid  <= 1'b0;
                end

                AW_PENDING: begin
                    s_axil_awaddr <= awaddr_buffer;
                    s_axil_awprot <= awprot_buffer;
                    s_axil_wdata  <= wdata_buffer;
                    s_axil_wstrb  <= wstrb_buffer;
                    s_axil_rdata  <= '0;
                    s_axil_rresp  <= '0;
                    s_axil_bresp  <= '0;
                    s_axil_awvalid <= awaddr_valid;
                    s_axil_arvalid <= 1'b0;
                    s_axil_wvalid  <= wdata_valid;
                    s_axil_rvalid  <= 1'b0;
                    s_axil_bvalid  <= 1'b0;
                end

                AR_PENDING: begin
                    s_axil_awaddr <= '0;
                    s_axil_awprot <= '0;
                    s_axil_wdata  <= '0;
                    s_axil_wstrb  <= '0;
                    s_axil_rdata  <= rdata_buffer;
                    s_axil_rresp  <= rresp_buffer;
                    s_axil_bresp  <= '0;
                    s_axil_awvalid <= 1'b0;
                    s_axil_arvalid <= araddr_valid;
                    s_axil_wvalid  <= 1'b0;
                    s_axil_rvalid  <= rresp_valid;
                    s_axil_bvalid  <= 1'b0;
                end

                W_PENDING: begin
                    s_axil_awaddr <= '0;
                    s_axil_awprot <= '0;
                    s_axil_wdata  <= '0;
                    s_axil_wstrb  <= '0;
                    s_axil_rdata  <= '0;
                    s_axil_rresp  <= '0;
                    s_axil_bresp  <= bresp_buffer;
                    s_axil_awvalid <= 1'b0;
                    s_axil_arvalid <= 1'b0;
                    s_axil_wvalid  <= 1'b0;
                    s_axil_rvalid  <= 1'b0;
                    s_axil_bvalid  <= bresp_valid;
                end

                R_PENDING: begin
                    s_axil_awaddr <= '0;
                    s_axil_awprot <= '0;
                    s_axil_wdata  <= '0;
                    s_axil_wstrb  <= '0;
                    s_axil_rdata  <= '0;
                    s_axil_rresp  <= '0;
                    s_axil_bresp  <= bresp_buffer;
                    s_axil_awvalid <= 1'b0;
                    s_axil_arvalid <= 1'b0;
                    s_axil_wvalid  <= 1'b0;
                    s_axil_rvalid  <= 1'b0;
                    s_axil_bvalid  <= bresp_valid;
                end

                default: begin
                    s_axil_awaddr <= '0;
                    s_axil_awprot <= '0;
                    s_axil_wdata  <= '0;
                    s_axil_wstrb  <= '0;
                    s_axil_rdata  <= '0;
                    s_axil_rresp  <= '0;
                    s_axil_bresp  <= '0;
                    s_axil_awvalid <= 1'b0;
                    s_axil_arvalid <= 1'b0;
                    s_axil_wvalid  <= 1'b0;
                    s_axil_rvalid  <= 1'b0;
                    s_axil_bvalid  <= 1'b0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Output Drivers for Master Side based on State Machine
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr <= '0;
            m_axil_awprot <= '0;
            m_axil_wdata  <= '0;
            m_axil_wstrb  <= '0;
            m_axil_rdata  <= '0;
            m_axil_rresp  <= '0;
            m_axil_bresp  <= '0;
            m_axil_awvalid <= 1'b0;
            m_axil_arvalid <= 1'b0;
            m_axil_wvalid  <= 1'b0;
            m_axil_rvalid  <= 1'b0;
            m_axil_bvalid  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    m_axil_awaddr <= '0;
                    m_axil_awprot <= '0;
                    m_axil_wdata  <= '0;
                    m_axil_wstrb  <= '0;
                    m_axil_rdata  <= '0;
                    m_axil_rresp  <= '0;
                    m_axil_bresp  <= '0;
                    m_axil_awvalid <= 1'b0;
                    m_axil_arvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_rvalid  <= 1'b0;
                    m_axil_bvalid  <= 1'b0;
                end

                AW_PENDING: begin
                    m_axil_awaddr <= awaddr_buffer;
                    m_axil_awprot <= awprot_buffer;
                    m_axil_wdata  <= wdata_buffer;
                    m_axil_wstrb  <= wstrb_buffer;
                    m_axil_rdata  <= '0;
                    m_axil_rresp  <= '0;
                    m_axil_bresp  <= '0;
                    m_axil_awvalid <= awaddr_valid;
                    m_axil_arvalid <= 1'b0;
                    m_axil_wvalid  <= wdata_valid;
                    m_axil_rvalid  <= 1'b0;
                    m_axil_bvalid  <= 1'b0;
                end

                AR_PENDING: begin
                    m_axil_awaddr <= '0;
                    m_axil_awprot <= '0;
                    m_axil_wdata  <= '0;
                    m_axil_wstrb  <= '0;
                    m_axil_rdata  <= rdata_buffer;
                    m_axil_rresp  <= rresp_buffer;
                    m_axil_bresp  <= '0;
                    m_axil_awvalid <= 1'b0;
                    m_axil_arvalid <= araddr_valid;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_rvalid  <= rresp_valid;
                    m_axil_bvalid  <= 1'b0;
                end

                W_PENDING: begin
                    m_axil_awaddr <= '0;
                    m_axil_awprot <= '0;
                    m_axil_wdata  <= '0;
                    m_axil_wstrb  <= '0;
                    m_axil_rdata  <= '0;
                    m_axil_rresp  <= '0;
                    m_axil_bresp  <= bresp_buffer;
                    m_axil_awvalid <= 1'b0;
                    m_axil_arvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_rvalid  <= 1'b0;
                    m_axil_bvalid  <= bresp_valid;
                end

                R_PENDING: begin
                    m_axil_awaddr <= '0;
                    m_axil_awprot <= '0;
                    m_axil_wdata  <= '0;
                    m_axil_wstrb  <= '0;
                    m_axil_rdata  <= '0;
                    m_axil_rresp  <= '0;
                    m_axil_bresp  <= bresp_buffer;
                    m_axil_awvalid <= 1'b0;
                    m_axil_arvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_rvalid  <= 1'b0;
                    m_axil_bvalid  <= bresp_valid;
                end

                default: begin
                    m_axil_awaddr <= '0;
                    m_axil_awprot <= '0;
                    m_axil_wdata  <= '0;
                    m_axil_wstrb  <= '0;
                    m_axil_rdata  <= '0;
                    m_axil_rresp  <= '0;
                    m_axil_bresp  <= '0;
                    m_axil_awvalid <= 1'b0;
                    m_axil_arvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_rvalid  <= 1'b0;
                    m_axil_bvalid  <= 1'b0;
                end
            endcase
        end
    end

endmodule
```<|im_end|>
