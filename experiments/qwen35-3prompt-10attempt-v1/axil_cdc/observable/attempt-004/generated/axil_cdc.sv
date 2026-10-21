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
    wire [ADDR_WIDTH-1:0] s_addr;
    wire [2:0]            s_prot;
    wire                  s_aw_valid;
    wire                  s_w_valid;
    wire                  s_ar_valid;
    wire                  s_r_valid;
    wire                  s_b_valid;
    
    wire [ADDR_WIDTH-1:0] m_addr;
    wire [2:0]            m_prot;
    wire                  m_aw_valid;
    wire                  m_w_valid;
    wire                  m_ar_valid;
    wire                  m_r_valid;
    wire                  m_b_valid;

    // CDC Registers for Address/Prot
    reg [ADDR_WIDTH-1:0] s_addr_reg1, s_addr_reg2;
    reg [2:0]            s_prot_reg1, s_prot_reg2;
    reg                  s_aw_valid_reg1, s_aw_valid_reg2;
    reg                  s_w_valid_reg1, s_w_valid_reg2;
    reg                  s_ar_valid_reg1, s_ar_valid_reg2;
    reg                  s_r_valid_reg1, s_r_valid_reg2;
    reg                  s_b_valid_reg1, s_b_valid_reg2;
    
    reg [ADDR_WIDTH-1:0] m_addr_reg1, m_addr_reg2;
    reg [2:0]            m_prot_reg1, m_prot_reg2;
    reg                  m_aw_valid_reg1, m_aw_valid_reg2;
    reg                  m_w_valid_reg1, m_w_valid_reg2;
    reg                  m_ar_valid_reg1, m_ar_valid_reg2;
    reg                  m_r_valid_reg1, m_r_valid_reg2;
    reg                  m_b_valid_reg1, m_b_valid_reg2;

    // State Machine for Slave Side (S-Clock Domain)
    // States: IDLE, AW_WAIT, W_WAIT, AR_WAIT, R_WAIT, B_WAIT
    localparam IDLE = 3'b000;
    localparam AW_WAIT = 3'b001;
    localparam W_WAIT = 3'b010;
    localparam AR_WAIT = 3'b011;
    localparam R_WAIT = 3'b100;
    localparam B_WAIT = 3'b101;

    reg [2:0] s_state;
    reg [2:0] s_next_state;
    
    // Transaction Buffers
    reg [ADDR_WIDTH-1:0] s_buf_addr;
    reg [2:0]            s_buf_prot;
    reg [DATA_WIDTH-1:0] s_buf_wdata;
    reg [STRB_WIDTH-1:0] s_buf_wstrb;
    reg                  s_buf_wvalid;
    reg                  s_buf_arvalid;
    reg                  s_buf_rvalid;
    reg                  s_buf_bvalid;
    reg                  s_buf_aw_valid;
    reg                  s_buf_w_ready;
    reg                  s_buf_ar_ready;
    reg                  s_buf_r_ready;
    reg                  s_buf_b_ready;
    
    // Write Response Buffer
    reg [1:0] s_buf_bresp;
    reg [DATA_WIDTH-1:0] s_buf_rdata;
    reg [1:0] s_buf_rresp;

    // Master Side State Machine (M-Clock Domain)
    // States: IDLE, AW_WAIT, W_WAIT, AR_WAIT, R_WAIT, B_WAIT
    localparam M_IDLE = 3'b000;
    localparam M_AW_WAIT = 3'b001;
    localparam M_W_WAIT = 3'b010;
    localparam M_AR_WAIT = 3'b011;
    localparam M_R_WAIT = 3'b100;
    localparam M_B_WAIT = 3'b101;

    reg [2:0] m_state;
    reg [2:0] m_next_state;
    
    // Master Transaction Buffers
    reg [ADDR_WIDTH-1:0] m_buf_addr;
    reg [2:0]            m_buf_prot;
    reg [DATA_WIDTH-1:0] m_buf_wdata;
    reg [STRB_WIDTH-1:0] m_buf_wstrb;
    reg                  m_buf_wvalid;
    reg                  m_buf_arvalid;
    reg                  m_buf_rvalid;
    reg                  m_buf_bvalid;
    reg                  m_buf_aw_valid;
    reg                  m_buf_w_ready;
    reg                  m_buf_ar_ready;
    reg                  m_buf_r_ready;
    reg                  m_buf_b_ready;
    
    // Master Write Response Buffer
    reg [1:0] m_buf_bresp;
    reg [DATA_WIDTH-1:0] m_buf_rdata;
    reg [1:0] m_buf_rresp;

    // -----------------------------------------------------------------------
    // CDC Logic: S -> M (Slave to Master)
    // -----------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_addr_reg1 <= {ADDR_WIDTH{1'b0}};
            s_prot_reg1 <= 3'b000;
            s_aw_valid_reg1 <= 1'b0;
            s_w_valid_reg1 <= 1'b0;
            s_ar_valid_reg1 <= 1'b0;
            s_r_valid_reg1 <= 1'b0;
            s_b_valid_reg1 <= 1'b0;
        end else begin
            s_addr_reg1 <= s_addr_reg2;
            s_prot_reg1 <= s_prot_reg2;
            s_aw_valid_reg1 <= s_aw_valid_reg2;
            s_w_valid_reg1 <= s_w_valid_reg2;
            s_ar_valid_reg1 <= s_ar_valid_reg2;
            s_r_valid_reg1 <= s_r_valid_reg2;
            s_b_valid_reg1 <= s_b_valid_reg2;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_addr_reg1 <= {ADDR_WIDTH{1'b0}};
            m_prot_reg1 <= 3'b000;
            m_aw_valid_reg1 <= 1'b0;
            m_w_valid_reg1 <= 1'b0;
            m_ar_valid_reg1 <= 1'b0;
            m_r_valid_reg1 <= 1'b0;
            m_b_valid_reg1 <= 1'b0;
        end else begin
            m_addr_reg1 <= m_addr_reg2;
            m_prot_reg1 <= m_prot_reg2;
            m_aw_valid_reg1 <= m_aw_valid_reg2;
            m_w_valid_reg1 <= m_w_valid_reg2;
            m_ar_valid_reg1 <= m_ar_valid_reg2;
            m_r_valid_reg1 <= m_r_valid_reg2;
            m_b_valid_reg1 <= m_b_valid_reg2;
        end
    end

    // -----------------------------------------------------------------------
    // CDC Logic: M -> S (Master to Slave)
    // -----------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_addr_reg1 <= {ADDR_WIDTH{1'b0}};
            m_prot_reg1 <= 3'b000;
            m_aw_valid_reg1 <= 1'b0;
            m_w_valid_reg1 <= 1'b0;
            m_ar_valid_reg1 <= 1'b0;
            m_r_valid_reg1 <= 1'b0;
            m_b_valid_reg1 <= 1'b0;
        end else begin
            m_addr_reg1 <= m_addr_reg2;
            m_prot_reg1 <= m_prot_reg2;
            m_aw_valid_reg1 <= m_aw_valid_reg2;
            m_w_valid_reg1 <= m_w_valid_reg2;
            m_ar_valid_reg1 <= m_ar_valid_reg2;
            m_r_valid_reg1 <= m_r_valid_reg2;
            m_b_valid_reg1 <= m_b_valid_reg2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_addr_reg1 <= {ADDR_WIDTH{1'b0}};
            m_prot_reg1 <= 3'b000;
            m_aw_valid_reg1 <= 1'b0;
            m_w_valid_reg1 <= 1'b0;
            m_ar_valid_reg1 <= 1'b0;
            m_r_valid_reg1 <= 1'b0;
            m_b_valid_reg1 <= 1'b0;
        end else begin
            m_addr_reg1 <= m_addr_reg2;
            m_prot_reg1 <= m_prot_reg2;
            m_aw_valid_reg1 <= m_aw_valid_reg2;
            m_w_valid_reg1 <= m_w_valid_reg2;
            m_ar_valid_reg1 <= m_ar_valid_reg2;
            m_r_valid_reg1 <= m_r_valid_reg2;
            m_b_valid_reg1 <= m_b_valid_reg2;
        end
    end

    // -----------------------------------------------------------------------
    // Slave Side Logic (S-Clock Domain)
    // -----------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_state <= IDLE;
            s_buf_addr <= {ADDR_WIDTH{1'b0}};
            s_buf_prot <= 3'b000;
            s_buf_wdata <= {DATA_WIDTH{1'b0}};
            s_buf_wstrb <= {STRB_WIDTH{1'b0}};
            s_buf_wvalid <= 1'b0;
            s_buf_arvalid <= 1'b0;
            s_buf_rvalid <= 1'b0;
            s_buf_bvalid <= 1'b0;
            s_buf_aw_valid <= 1'b0;
            s_buf_w_ready <= 1'b1;
            s_buf_ar_ready <= 1'b1;
            s_buf_r_ready <= 1'b1;
            s_buf_b_ready <= 1'b1;
            s_buf_bresp <= 2'b00;
            s_buf_rdata <= {DATA_WIDTH{1'b0}};
            s_buf_rresp <= 2'b00;
        end else begin
            // State Machine Logic
            case (s_state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        s_state <= AW_WAIT;
                        s_buf_addr <= s_axil_awaddr;
                        s_buf_prot <= s_axil_awprot;
                        s_buf_aw_valid <= 1'b1;
                    end else if (s_axil_arvalid && s_axil_arready) begin
                        s_state <= AR_WAIT;
                        s_buf_addr <= s_axil_araddr;
                        s_buf_prot <= s_axil_arprot;
                        s_buf_arvalid <= 1'b1;
                    end
                end

                AW_WAIT: begin
                    if (s_buf_aw_valid && m_axil_awready) begin
                        s_state <= W_WAIT;
                        s_buf_wvalid <= 1'b1;
                        s_buf_wdata <= s_axil_wdata;
                        s_buf_wstrb <= s_axil_wstrb;
                        s_buf_aw_valid <= 1'b0;
                    end else if (s_axil_awvalid && s_axil_awready) begin
                        s_state <= AW_WAIT;
                        s_buf_addr <= s_axil_awaddr;
                        s_buf_prot <= s_axil_awprot;
                        s_buf_aw_valid <= 1'b1;
                    end
                end

                W_WAIT: begin
                    if (s_buf_wvalid && m_axil_wready) begin
                        s_state <= (s_axil_arvalid && s_axil_arready) ? AR_WAIT : IDLE;
                        s_buf_wvalid <= 1'b0;
                        s_buf_wready <= 1'b1;
                    end else if (s_axil_wvalid && s_axil_wready) begin
                        s_buf_wdata <= s_axil_wdata;
                        s_buf_wstrb <= s_axil_wstrb;
                        s_buf_wready <= 1'b0;
                    end
                end

                AR_WAIT: begin
                    if (s_buf_arvalid && m_axil_arready) begin
                        s_state <= R_WAIT;
                        s_buf_rvalid <= 1'b1;
                        s_buf_arvalid <= 1'b0;
                    end else if (s_axil_arvalid && s_axil_arready) begin
                        s_state <= AR_WAIT;
                        s_buf_addr <= s_axil_araddr;
                        s_buf_prot <= s_axil_arprot;
                        s_buf_arvalid <= 1'b1;
                    end
                end

                R_WAIT: begin
                    if (s_buf_rvalid && m_axil_rready) begin
                        s_state <= (s_axil_awvalid && s_axil_awready) ? AW_WAIT : IDLE;
                        s_buf_rvalid <= 1'b0;
                        s_buf_rready <= 1'b1;
                    end else if (s_axil_rvalid && s_axil_rready) begin
                        s_buf_rdata <= s_axil_rdata;
                        s_buf_rresp <= s_axil_rresp;
                        s_buf_rready <= 1'b0;
                    end
                end

                B_WAIT: begin
                    if (s_buf_bvalid && m_axil_bready) begin
                        s_state <= IDLE;
                        s_buf_bvalid <= 1'b0;
                        s_buf_bready <= 1'b1;
                    end else if (s_axil_bvalid && s_axil_bready) begin
                        s_buf_bresp <= s_axil_bresp;
                        s_buf_bready <= 1'b0;
                    end
                end

                default: s_state <= IDLE;
            endcase

            // Output Logic
            s_axil_awready <= (s_state == IDLE && s_axil_awvalid) ? 1'b1 : 1'b0;
            s_axil_wready <= (s_state == W_WAIT && s_axil_wvalid) ? 1'b1 : 1'b0;
            s_axil_arready <= (s_state == IDLE && s_axil_arvalid) ? 1'b1 : 1'b0;
            s_axil_rready <= (s_state == R_WAIT && s_axil_rvalid) ? 1'b1 : 1'b0;
            s_axil_bready <= (s_state == B_WAIT && s_axil_bvalid) ? 1'b1 : 1'b0;

            s_axil_awvalid <= s_buf_aw_valid;
            s_axil_wdata <= s_buf_wdata;
            s_axil_wstrb <= s_buf_wstrb;
            s_axil_wvalid <= s_buf_wvalid;
            s_axil_araddr <= s_buf_addr;
            s_axil_arprot <= s_buf_prot;
            s_axil_arvalid <= s_buf_arvalid;
            s_axil_rdata <= s_buf_rdata;
            s_axil_rresp <= s_buf_rresp;
            s_axil_rvalid <= s_buf_rvalid;
            s_axil_bresp <= s_buf_bresp;
            s_axil_bvalid <= s_buf_bvalid;
        end
    end

    // -----------------------------------------------------------------------
    // Master Side Logic (M-Clock Domain)
    // -----------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_state <= M_IDLE;
            m_buf_addr <= {ADDR_WIDTH{1'b0}};
            m_buf_prot <= 3'b000;
            m_buf_wdata <= {DATA_WIDTH{1'b0}};
            m_buf_wstrb <= {STRB_WIDTH{1'b0}};
            m_buf_wvalid <= 1'b0;
            m_buf_arvalid <= 1'b0;
            m_buf_rvalid <= 1'b0;
            m_buf_bvalid <= 1'b0;
            m_buf_aw_valid <= 1'b0;
            m_buf_w_ready <= 1'b1;
            m_buf_ar_ready <= 1'b1;
            m_buf_r_ready <= 1'b1;
            m_buf_b_ready <= 1'b1;
            m_buf_bresp <= 2'b00;
            m_buf_rdata <= {DATA_WIDTH{1'b0}};
            m_buf_rresp <= 2'b00;
        end else begin
            // State Machine Logic
            case (m_state)
                M_IDLE: begin
                    if (m_axil_awvalid && m_axil_awready) begin
                        m_state <= M_AW_WAIT;
                        m_buf_addr <= m_axil_awaddr;
                        m_buf_prot <= m_axil_awprot;
                        m_buf_aw_valid <= 1'b1;
                    end else if (m_axil_arvalid && m_axil_arready) begin
                        m_state <= M_AR_WAIT;
                        m_buf_addr <= m_axil_araddr;
                        m_buf_prot <= m_axil_arprot;
                        m_buf_arvalid <= 1'b1;
                    end
                end

                M_AW_WAIT: begin
                    if (m_buf_aw_valid && s_axil_awready) begin
                        m_state <= M_W_WAIT;
                        m_buf_wvalid <= 1'b1;
                        m_buf_wdata <= m_axil_wdata;
                        m_buf_wstrb <= m_axil_wstrb;
                        m_buf_aw_valid <= 1'b0;
                    end else if (m_axil_awvalid && m_axil_awready) begin
                        m_state <= M_AW_WAIT;
                        m_buf_addr <= m_axil_awaddr;
                        m_buf_prot <= m_axil_awprot;
                        m_buf_aw_valid <= 1'b1;
                    end
                end

                M_W_WAIT: begin
                    if (m_buf_wvalid && s_axil_wready) begin
                        m_state <= (m_axil_arvalid && m_axil_arready) ? M_AR_WAIT : M_IDLE;
                        m_buf_wvalid <= 1'b0;
                        m_buf_wready <= 1'b1;
                    end else if (m_axil_wvalid && m_axil_wready) begin
                        m_buf_wdata <= m_axil_wdata;
                        m_buf_wstrb <= m_axil_wstrb;
                        m_buf_wready <= 1'b0;
                    end
                end

                M_AR_WAIT: begin
                    if (m_buf_arvalid && s_axil_arready) begin
                        m_state <= M_R_WAIT;
                        m_buf_rvalid <= 1'b1;
                        m_buf_arvalid <= 1'b0;
                    end else if (m_axil_arvalid && m_axil_arready) begin
                        m_state <= M_AR_WAIT;
                        m_buf_addr <= m_axil_araddr;
                        m_buf_prot <= m_axil_arprot;
                        m_buf_arvalid <= 1'b1;
                    end
                end

                M_R_WAIT: begin
                    if (m_buf_rvalid && s_axil_rready) begin
                        m_state <= (m_axil_awvalid && m_axil_awready) ? M_AW_WAIT : M_IDLE;
                        m_buf_rvalid <= 1'b0;
                        m_buf_rready <= 1'b1;
                    end else if (m_axil_rvalid && m_axil_rready) begin
                        m_buf_rdata <= m_axil_rdata;
                        m_buf_rresp <= m_axil_rresp;
                        m_buf_rready <= 1'b0;
                    end
                end

                M_B_WAIT: begin
                    if (m_buf_bvalid && s_axil_bready) begin
                        m_state <= M_IDLE;
                        m_buf_bvalid <= 1'b0;
                        m_buf_bready <= 1'b1;
                    end else if (m_axil_bvalid && m_axil_bready) begin
                        m_buf_bresp <= m_axil_bresp;
                        m_buf_bready <= 1'b0;
                    end
                end

                default: m_state <= M_IDLE;
            endcase

            // Output Logic
            m_axil_awready <= (m_state == M_IDLE && m_axil_awvalid) ? 1'b1 : 1'b0;
            m_axil_wready <= (m_state == M_W_WAIT && m_axil_wvalid) ? 1'b1 : 1'b0;
            m_axil_arready <= (m_state == M_IDLE && m_axil_arvalid) ? 1'b1 : 1'b0;
            m_axil_rready <= (m_state == M_R_WAIT && m_axil_rvalid) ? 1'b1 : 1'b0;
            m_axil_bready <= (m_state == M_B_WAIT && m_axil_bvalid) ? 1'b1 : 1'b0;

            m_axil_awaddr <= m_buf_addr;
            m_axil_awprot <= m_buf_prot;
            m_axil_awvalid <= m_buf_aw_valid;
            m_axil_wdata <= m_buf_wdata;
            m_axil_wstrb <= m_buf_wstrb;
            m_axil_wvalid <= m_buf_wvalid;
            m_axil_araddr <= m_buf_addr;
            m_axil_arprot <= m_buf_prot;
            m_axil_arvalid <= m_buf_arvalid;
            m_axil_rdata <= m_buf_rdata;
            m_axil_rresp <= m_buf_rresp;
            m_axil_rvalid <= m_buf_rvalid;
            m_axil_bresp <= m_buf_bresp;
            m_axil_bvalid <= m_buf_bvalid;
        end
    end

endmodule
```<|im_end|>
