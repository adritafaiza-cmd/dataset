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
    
    // Write Channel
    reg [ADDR_WIDTH-1:0]  i_awaddr;
    reg [2:0]             i_awprot;
    reg                   i_awvalid;
    reg                   i_awready;
    reg [DATA_WIDTH-1:0]  i_wdata;
    reg [STRB_WIDTH-1:0]  i_wstrb;
    reg                   i_wvalid;
    reg                   i_wready;
    reg [1:0]             i_bresp;
    reg                   i_bvalid;
    reg                   i_bready;
    
    // Read Channel
    reg [ADDR_WIDTH-1:0]  i_araddr;
    reg [2:0]             i_arprot;
    reg                   i_arvalid;
    reg                   i_arready;
    reg [DATA_WIDTH-1:0]  i_rdata;
    reg [1:0]             i_rresp;
    reg                   i_rvalid;
    reg                   i_rready;

    // CDC Registers (S -> M)
    reg [ADDR_WIDTH-1:0]  s2m_awaddr;
    reg [2:0]             s2m_awprot;
    reg                   s2m_awvalid;
    reg                   s2m_awready;
    reg [DATA_WIDTH-1:0]  s2m_wdata;
    reg [STRB_WIDTH-1:0]  s2m_wstrb;
    reg                   s2m_wvalid;
    reg                   s2m_wready;
    reg [1:0]             s2m_bresp;
    reg                   s2m_bvalid;
    reg                   s2m_bready;
    
    reg [ADDR_WIDTH-1:0]  s2m_araddr;
    reg [2:0]             s2m_arprot;
    reg                   s2m_arvalid;
    reg                   s2m_arready;
    reg [DATA_WIDTH-1:0]  s2m_rdata;
    reg [1:0]             s2m_rresp;
    reg                   s2m_rvalid;
    reg                   s2m_rready;

    // CDC Registers (M -> S)
    reg [ADDR_WIDTH-1:0]  m2s_awaddr;
    reg [2:0]             m2s_awprot;
    reg                   m2s_awvalid;
    reg                   m2s_awready;
    reg [DATA_WIDTH-1:0]  m2s_wdata;
    reg [STRB_WIDTH-1:0]  m2s_wstrb;
    reg                   m2s_wvalid;
    reg                   m2s_wready;
    reg [1:0]             m2s_bresp;
    reg                   m2s_bvalid;
    reg                   m2s_bready;
    
    reg [ADDR_WIDTH-1:0]  m2s_araddr;
    reg [2:0]             m2s_arprot;
    reg                   m2s_arvalid;
    reg                   m2s_arready;
    reg [DATA_WIDTH-1:0]  m2s_rdata;
    reg [1:0]             m2s_rresp;
    reg                   m2s_rvalid;
    reg                   m2s_rready;

    // State Machines for Write Channel (S -> M)
    reg [2:0] s2m_state;
    parameter S2M_IDLE = 3'b000,
              S2M_WAIT_AR = 3'b001,
              S2M_WAIT_B = 3'b010;

    // State Machines for Read Channel (S -> M)
    reg [2:0] s2m_r_state;
    parameter S2M_R_IDLE = 3'b000,
              S2M_R_WAIT_AR = 3'b001,
              S2M_R_WAIT_R = 3'b010;

    // State Machines for Write Channel (M -> S)
    reg [2:0] m2s_state;
    parameter M2S_IDLE = 3'b000,
              M2S_WAIT_B = 3'b001;

    // State Machines for Read Channel (M -> S)
    reg [2:0] m2s_r_state;
    parameter M2S_R_IDLE = 3'b000,
              M2S_R_WAIT_R = 3'b001;

    // Write Transaction ID (Simple counter based on address for this implementation)
    reg [31:0] s2m_wid;
    reg [31:0] m2s_wid;

    // ------------------------------------------------------------------
    // Clock Domain Crossing: S -> M (Write Address & Prot)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr <= 32'd0;
            s2m_awprot <= 3'd0;
            s2m_awvalid <= 1'b0;
        end else begin
            s2m_awaddr <= s_axil_awaddr;
            s2m_awprot <= s_axil_awprot;
            s2m_awvalid <= s_axil_awvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: S -> M (Write Data & Strb)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_wdata <= 32'd0;
            s2m_wstrb <= 4'd0;
            s2m_wvalid <= 1'b0;
        end else begin
            s2m_wdata <= s_axil_wdata;
            s2m_wstrb <= s_axil_wstrb;
            s2m_wvalid <= s_axil_wvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: S -> M (Read Address & Prot)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_araddr <= 32'd0;
            s2m_arprot <= 3'd0;
            s2m_arvalid <= 1'b0;
        end else begin
            s2m_araddr <= s_axil_araddr;
            s2m_arprot <= s_axil_arprot;
            s2m_arvalid <= s_axil_arvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: M -> S (Write Address & Prot)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_awaddr <= 32'd0;
            m2s_awprot <= 3'd0;
            m2s_awvalid <= 1'b0;
        end else begin
            m2s_awaddr <= m_axil_awaddr;
            m2s_awprot <= m_axil_awprot;
            m2s_awvalid <= m_axil_awvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: M -> S (Write Data & Strb)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_wdata <= 32'd0;
            m2s_wstrb <= 4'd0;
            m2s_wvalid <= 1'b0;
        end else begin
            m2s_wdata <= m_axil_wdata;
            m2s_wstrb <= m_axil_wstrb;
            m2s_wvalid <= m_axil_wvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: M -> S (Read Address & Prot)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_araddr <= 32'd0;
            m2s_arprot <= 3'd0;
            m2s_arvalid <= 1'b0;
        end else begin
            m2s_araddr <= m_axil_araddr;
            m2s_arprot <= m_axil_arprot;
            m2s_arvalid <= m_axil_arvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: S -> M (Write Response)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_bresp <= 2'd0;
            s2m_bvalid <= 1'b0;
        end else begin
            s2m_bresp <= s_axil_bresp;
            s2m_bvalid <= s_axil_bvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: S -> M (Read Response)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_rdata <= 32'd0;
            s2m_rresp <= 2'd0;
            s2m_rvalid <= 1'b0;
        end else begin
            s2m_rdata <= s_axil_rdata;
            s2m_rresp <= s_axil_rresp;
            s2m_rvalid <= s_axil_rvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: M -> S (Write Response)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_bresp <= 2'd0;
            m2s_bvalid <= 1'b0;
        end else begin
            m2s_bresp <= m_axil_bresp;
            m2s_bvalid <= m_axil_bvalid;
        end
    end

    // ------------------------------------------------------------------
    // Clock Domain Crossing: M -> S (Read Response)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_rdata <= 32'd0;
            m2s_rresp <= 2'd0;
            m2s_rvalid <= 1'b0;
        end else begin
            m2s_rdata <= m_axil_rdata;
            m2s_rresp <= m_axil_rresp;
            m2s_rvalid <= m_axil_rvalid;
        end
    end

    // ------------------------------------------------------------------
    // S -> M Write Channel Logic
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_state <= S2M_IDLE;
            s2m_wid <= 32'd0;
        end else begin
            case (s2m_state)
                S2M_IDLE: begin
                    if (s2m_awvalid && s2m_wvalid) begin
                        s2m_state <= S2M_WAIT_AR;
                        s2m_wid <= s2m_wid + 1;
                    end
                end
                S2M_WAIT_AR: begin
                    if (m2s_awready) begin
                        m_axil_awaddr <= s2m_awaddr;
                        m_axil_awprot <= s2m_awprot;
                        m_axil_awvalid <= 1'b1;
                        s2m_state <= S2M_WAIT_B;
                    end
                end
                S2M_WAIT_B: begin
                    if (m2s_bvalid && m2s_bready) begin
                        m_axil_bready <= 1'b1;
                        s2m_state <= S2M_IDLE;
                    end
                end
                default: begin
                    s2m_state <= S2M_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // S -> M Read Channel Logic
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_r_state <= S2M_R_IDLE;
        end else begin
            case (s2m_r_state)
                S2M_R_IDLE: begin
                    if (s2m_arvalid && s2m_wvalid) begin
                        s2m_r_state <= S2M_R_WAIT_AR;
                    end
                end
                S2M_R_WAIT_AR: begin
                    if (m2s_arready) begin
                        m_axil_araddr <= s2m_araddr;
                        m_axil_arprot <= s2m_arprot;
                        m_axil_arvalid <= 1'b1;
                        s2m_r_state <= S2M_R_WAIT_R;
                    end
                end
                S2M_R_WAIT_R: begin
                    if (m2s_rvalid && m2s_rready) begin
                        m_axil_rready <= 1'b1;
                        s2m_r_state <= S2M_R_IDLE;
                    end
                end
                default: begin
                    s2m_r_state <= S2M_R_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // M -> S Write Channel Logic
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_state <= M2S_IDLE;
            m2s_wid <= 32'd0;
        end else begin
            case (m2s_state)
                M2S_IDLE: begin
                    if (m2s_awvalid && m2s_wvalid) begin
                        m2s_state <= M2S_WAIT_B;
                        m2s_wid <= m2s_wid + 1;
                    end
                end
                M2S_WAIT_B: begin
                    if (s2m_bready) begin
                        s_axil_bready <= 1'b1;
                        m2s_state <= M2S_IDLE;
                    end
                end
                default: begin
                    m2s_state <= M2S_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // M -> S Read Channel Logic
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_r_state <= M2S_R_IDLE;
        end else begin
            case (m2s_r_state)
                M2S_R_IDLE: begin
                    if (m2s_arvalid && m2s_wvalid) begin
                        m2s_r_state <= M2S_R_WAIT_R;
                    end
                end
                M2S_R_WAIT_R: begin
                    if (s2m_rready) begin
                        s_axil_rready <= 1'b1;
                        m2s_r_state <= M2S_R_IDLE;
                    end
                end
                default: begin
                    m2s_r_state <= M2S_R_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Output Assignments (S -> M)
    // ------------------------------------------------------------------
    assign s_axil_awready = m2s_awready;
    assign s_axil_wready = m2s_wready;
    assign s_axil_bresp = m2s_bresp;
    assign s_axil_bvalid = m2s_bvalid;
    assign s_axil_arready = m2s_arready;
    assign s_axil_rdata = m2s_rdata;
    assign s_axil_rresp = m2s_rresp;
    assign s_axil_rvalid = m2s_rvalid;

    // ------------------------------------------------------------------
    // Output Assignments (M -> S)
    // ------------------------------------------------------------------
    assign m_axil_awaddr = s2m_awaddr;
    assign m_axil_awprot = s2m_awprot;
    assign m_axil_awvalid = s2m_awvalid;
    assign m_axil_wdata = s2m_wdata;
    assign m_axil_wstrb = s2m_wstrb;
    assign m_axil_wvalid = s2m_wvalid;
    assign m_axil_bresp = s2m_bresp;
    assign m_axil_bvalid = s2m_bvalid;
    assign m_axil_araddr = s2m_araddr;
    assign m_axil_arprot = s2m_arprot;
    assign m_axil_arvalid = s2m_arvalid;
    assign m_axil_rdata = s2m_rdata;
    assign m_axil_rresp = s2m_rresp;
    assign m_axil_rvalid = s2m_rvalid;

endmodule
```<|im_end|>
