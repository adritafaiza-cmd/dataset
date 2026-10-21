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
    
    // State Machine States
    localparam IDLE = 2'b00;
    localparam AW_WAIT = 2'b01;
    localparam W_WAIT = 2'b10;
    localparam B_WAIT = 2'b11;
    
    localparam AR_WAIT = 4'b001;
    localparam R_WAIT = 4'b010;
    
    // CDC Registers (Synchronous to m_clk)
    reg [ADDR_WIDTH-1:0] m_axil_awaddr_cdc;
    reg [2:0] m_axil_awprot_cdc;
    reg m_axil_awvalid_cdc;
    reg m_axil_wdata_cdc;
    reg [STRB_WIDTH-1:0] m_axil_wstrb_cdc;
    reg m_axil_wvalid_cdc;
    reg m_aw_done;
    reg m_bresp_cdc;
    reg m_bvalid_cdc;
    reg m_bready_cdc;
    
    reg [ADDR_WIDTH-1:0] m_axil_araddr_cdc;
    reg [2:0] m_axil_arprot_cdc;
    reg m_axil_arvalid_cdc;
    reg m_axil_rdata_cdc;
    reg [1:0] m_axil_rresp_cdc;
    reg m_axil_rvalid_cdc;
    reg m_ar_done;
    reg m_rready_cdc;
    
    // CDC Registers (Synchronous to s_clk)
    reg [ADDR_WIDTH-1:0] s_axil_awaddr_cdc;
    reg [2:0] s_axil_awprot_cdc;
    reg s_axil_awvalid_cdc;
    reg s_axil_wdata_cdc;
    reg [STRB_WIDTH-1:0] s_axil_wstrb_cdc;
    reg s_axil_wvalid_cdc;
    reg s_aw_done;
    reg s_bresp_cdc;
    reg s_bvalid_cdc;
    reg s_bready_cdc;
    
    reg [ADDR_WIDTH-1:0] s_axil_araddr_cdc;
    reg [2:0] s_axil_arprot_cdc;
    reg s_axil_arvalid_cdc;
    reg s_axil_rdata_cdc;
    reg [1:0] s_axil_rresp_cdc;
    reg s_axil_rvalid_cdc;
    reg s_ar_done;
    reg s_rready_cdc;
    
    // State Registers
    reg [1:0] m_state;
    reg [3:0] s_state;
    
    // Transaction IDs (Simple counter to ensure ordering if needed, 
    // though AXI-Lite doesn't strictly require IDs, it helps with debugging/ordering logic)
    reg [31:0] m_txn_id;
    reg [31:0] s_txn_id;
    
    // ------------------------------------------------------------------
    // Master Side (s_clk -> m_clk)
    // ------------------------------------------------------------------
    
    // 1. Address Capture (s_clk -> m_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr_cdc <= 32'd0;
            s_axil_awprot_cdc <= 3'd0;
            s_axil_awvalid_cdc <= 1'b0;
            s_aw_done <= 1'b0;
            s_axil_wdata_cdc <= 32'd0;
            s_axil_wstrb_cdc <= {STRB_WIDTH{1'b0}};
            s_axil_wvalid_cdc <= 1'b0;
            s_axil_bresp_cdc <= 2'b00;
            s_bvalid_cdc <= 1'b0;
            s_bready_cdc <= 1'b0;
            s_axil_araddr_cdc <= 32'd0;
            s_axil_arprot_cdc <= 3'd0;
            s_axil_arvalid_cdc <= 1'b0;
            s_axil_rdata_cdc <= 32'd0;
            s_axil_rresp_cdc <= 2'b00;
            s_axil_rvalid_cdc <= 1'b0;
            s_axil_rready_cdc <= 1'b0;
            s_ar_done <= 1'b0;
            s_txn_id <= 32'd0;
            s_state <= IDLE;
        end else begin
            s_axil_awaddr_cdc <= s_axil_awaddr;
            s_axil_awprot_cdc <= s_axil_awprot;
            s_axil_wdata_cdc <= s_axil_wdata;
            s_axil_wstrb_cdc <= s_axil_wstrb;
            s_axil_rdata_cdc <= s_axil_rdata;
            s_axil_rresp_cdc <= s_axil_rresp;
            s_axil_bresp_cdc <= s_axil_bresp;
            s_axil_awvalid_cdc <= s_axil_awvalid;
            s_axil_wvalid_cdc <= s_axil_wvalid;
            s_axil_arvalid_cdc <= s_axil_arvalid;
            s_axil_rvalid_cdc <= s_axil_rvalid;
            s_axil_bvalid_cdc <= s_axil_bvalid;
            s_axil_rready_cdc <= s_axil_rready;
            s_axil_bready_cdc <= s_axil_bready;
            s_axil_arready_cdc <= s_axil_arready;
        end
    end
    
    // 2. State Machine (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_state <= IDLE;
        end else begin
            case (s_state)
                IDLE: begin
                    if (s_axil_awvalid_cdc && !s_aw_done) begin
                        s_state <= AW_WAIT;
                        s_txn_id <= s_axil_awaddr; // Use address as simple ID
                    end
                end
                AW_WAIT: begin
                    if (s_aw_done) begin
                        s_state <= W_WAIT;
                    end
                end
                W_WAIT: begin
                    if (s_aw_done) begin
                        s_state <= B_WAIT;
                    end
                end
                B_WAIT: begin
                    if (s_aw_done) begin
                        s_state <= IDLE;
                    end
                end
                default: s_state <= IDLE;
            endcase
        end
    end
    
    // 3. Write Data Capture (s_clk -> m_clk)
    // We need to capture WDATA andWSTRB when AWVALID is high and AWREADY is asserted
    // Since we are in s_clk domain, we capture the data when the transaction is valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_done <= 1'b0;
        end else begin
            // Check if we are in AW_WAIT state and data is valid
            if (s_state == AW_WAIT && s_axil_awvalid_cdc && s_axil_awready_cdc) begin
                s_aw_done <= 1'b1;
            end
            // Check if we are in W_WAIT state and data is valid
            if (s_state == W_WAIT && s_axil_wvalid_cdc && s_axil_wready_cdc) begin
                s_aw_done <= 1'b1;
            end
            // Check if we are in B_WAIT state and response is valid
            if (s_state == B_WAIT && s_axil_bvalid_cdc && s_axil_bready_cdc) begin
                s_aw_done <= 1'b1;
            end
        end
    end
    
    // 4. Master Side Logic (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr <= 32'd0;
            m_axil_awprot <= 3'd0;
            m_axil_awvalid <= 1'b0;
            m_axil_wdata <= 32'd0;
            m_axil_wstrb <= {STRB_WIDTH{1'b0}};
            m_axil_wvalid <= 1'b0;
            m_axil_bready <= 1'b0;
            m_axil_araddr <= 32'd0;
            m_axil_arprot <= 3'd0;
            m_axil_arvalid <= 1'b0;
            m_axil_rready <= 1'b0;
            m_state <= IDLE;
            m_txn_id <= 32'd0;
        end else begin
            // Address Capture
            if (m_axil_awvalid_cdc && !m_axil_awready) begin
                m_axil_awaddr <= s_axil_awaddr_cdc;
                m_axil_awprot <= s_axil_awprot_cdc;
                m_axil_awvalid <= 1'b1;
            end else if (m_axil_awready) begin
                m_axil_awvalid <= 1'b0;
            end
            
            // Write Data Capture
            if (m_axil_wvalid_cdc && !m_axil_wready) begin
                m_axil_wdata <= s_axil_wdata_cdc;
                m_axil_wstrb <= s_axil_wstrb_cdc;
                m_axil_wvalid <= 1'b1;
            end else if (m_axil_wready) begin
                m_axil_wvalid <= 1'b0;
            end
            
            // Read Data Capture
            if (m_axil_rvalid_cdc && !m_axil_rready) begin
                m_axil_rdata <= s_axil_rdata_cdc;
                m_axil_rresp <= s_axil_rresp_cdc;
                m_axil_rvalid <= 1'b1;
            end else if (m_axil_rready) begin
                m_axil_rvalid <= 1'b0;
            end
            
            // Response Capture
            if (m_axil_bvalid_cdc && !m_axil_bready) begin
                m_axil_bresp <= s_axil_bresp_cdc;
                m_axil_bvalid <= 1'b1;
            end else if (m_axil_bready) begin
                m_axil_bvalid <= 1'b0;
            end
            
            // State Machine
            case (m_state)
                IDLE: begin
                    if (m_axil_awvalid && m_axil_awready) begin
                        m_state <= AW_WAIT;
                        m_txn_id <= m_axil_awaddr;
                    end
                end
                AW_WAIT: begin
                    if (m_axil_wvalid && m_axil_wready) begin
                        m_state <= W_WAIT;
                    end
                end
                W_WAIT: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        m_state <= IDLE;
                    end
                end
                default: m_state <= IDLE;
            endcase
        end
    end
    
    // ------------------------------------------------------------------
    // Slave Side (m_clk -> s_clk)
    // ------------------------------------------------------------------
    
    // 1. Address Capture (m_clk -> s_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awaddr_cdc <= 32'd0;
            m_axil_awprot_cdc <= 3'd0;
            m_axil_awvalid_cdc <= 1'b0;
            m_axil_wdata_cdc <= 32'd0;
            m_axil_wstrb_cdc <= {STRB_WIDTH{1'b0}};
            m_axil_wvalid_cdc <= 1'b0;
            m_axil_bresp_cdc <= 2'b00;
            m_axil_bvalid_cdc <= 1'b0;
            m_axil_bready_cdc <= 1'b0;
            m_axil_araddr_cdc <= 32'd0;
            m_axil_arprot_cdc <= 3'd0;
            m_axil_arvalid_cdc <= 1'b0;
            m_axil_rdata_cdc <= 32'd0;
            m_axil_rresp_cdc <= 2'b00;
            m_axil_rvalid_cdc <= 1'b0;
            m_axil_rready_cdc <= 1'b0;
            m_axil_arready_cdc <= 1'b0;
            m_ar_done <= 1'b0;
            m_state <= IDLE;
            m_txn_id <= 32'd0;
        end else begin
            m_axil_awaddr_cdc <= m_axil_awaddr;
            m_axil_awprot_cdc <= m_axil_awprot;
            m_axil_wdata_cdc <= m_axil_wdata;
            m_axil_wstrb_cdc <= m_axil_wstrb;
            m_axil_rdata_cdc <= m_axil_rdata;
            m_axil_rresp_cdc <= m_axil_rresp;
            m_axil_bresp_cdc <= m_axil_bresp;
            m_axil_awvalid_cdc <= m_axil_awvalid;
            m_axil_wvalid_cdc <= m_axil_wvalid;
            m_axil_arvalid_cdc <= m_axil_arvalid;
            m_axil_rvalid_cdc <= m_axil_rvalid;
            m_axil_bvalid_cdc <= m_axil_bvalid;
            m_axil_rready_cdc <= m_axil_rready;
            m_axil_bready_cdc <= m_axil_bready;
            m_axil_arready_cdc <= m_axil_arready;
        end
    end
    
    // 2. State Machine (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_state <= IDLE;
        end else begin
            case (m_state)
                IDLE: begin
                    if (m_axil_awvalid_cdc && !m_ar_done) begin
                        m_state <= AW_WAIT;
                        m_txn_id <= m_axil_awaddr;
                    end
                end
                AW_WAIT: begin
                    if (m_ar_done) begin
                        m_state <= W_WAIT;
                    end
                end
                W_WAIT: begin
                    if (m_ar_done) begin
                        m_state <= B_WAIT;
                    end
                end
                B_WAIT: begin
                    if (m_ar_done) begin
                        m_state <= IDLE;
                    end
                end
                default: m_state <= IDLE;
            endcase
        end
    end
    
    // 3. Write Data Capture (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_done <= 1'b0;
        end else begin
            // Check if we are in AW_WAIT state and data is valid
            if (m_state == AW_WAIT && m_axil_awvalid_cdc && m_axil_awready_cdc) begin
                m_ar_done <= 1'b1;
            end
            // Check if we are in W_WAIT state and data is valid
            if (m_state == W_WAIT && m_axil_wvalid_cdc && m_axil_wready_cdc) begin
                m_ar_done <= 1'b1;
            end
            // Check if we are in B_WAIT state and response is valid
            if (m_state == B_WAIT && m_axil_bvalid_cdc && m_axil_bready_cdc) begin
                m_ar_done <= 1'b1;
            end
        end
    end
    
    // 4. Slave Side Logic (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awaddr <= 32'd0;
            s_axil_awprot <= 3'd0;
            s_axil_awvalid <= 1'b0;
            s_axil_wdata <= 32'd0;
            s_axil_wstrb <= {STRB_WIDTH{1'b0}};
            s_axil_wvalid <= 1'b0;
            s_axil_bready <= 1'b0;
            s_axil_araddr <= 32'd0;
            s_axil_arprot <= 3'd0;
            s_axil_arvalid <= 1'b0;
            s_axil_rdata <= 32'd0;
            s_axil_rresp <= 2'b00;
            s_axil_rvalid <= 1'b0;
            s_axil_rready <= 1'b0;
            s_state <= IDLE;
            s_txn_id <= 32'd0;
        end else begin
            // Address Capture
            if (s_axil_awvalid_cdc && !s_axil_awready) begin
                s_axil_awaddr <= m_axil_awaddr_cdc;
                s_axil_awprot <= m_axil_awprot_cdc;
                s_axil_awvalid <= 1'b1;
            end else if (s_axil_awready) begin
                s_axil_awvalid <= 1'b0;
            end
            
            // Write Data Capture
            if (s_axil_wvalid_cdc && !s_axil_wready) begin
                s_axil_wdata <= m_axil_wdata_cdc;
                s_axil_wstrb <= m_axil_wstrb_cdc;
                s_axil_wvalid <= 1'b1;
            end else if (s_axil_wready) begin
                s_axil_wvalid <= 1'b0;
            end
            
            // Read Data Capture
            if (s_axil_rvalid_cdc && !s_axil_rready) begin
                s_axil_rdata <= m_axil_rdata_cdc;
                s_axil_rresp <= m_axil_rresp_cdc;
                s_axil_rvalid <= 1'b1;
            end else if (s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
            
            // Response Capture
            if (s_axil_bvalid_cdc && !s_axil_bready) begin
                s_axil_bresp <= m_axil_bresp_cdc;
                s_axil_bvalid <= 1'b1;
            end else if (s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
            
            // State Machine
            case (s_state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        s_state <= AW_WAIT;
                        s_txn_id <= s_axil_awaddr;
                    end
                end
                AW_WAIT: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_state <= W_WAIT;
                    end
                end
                W_WAIT: begin
                    if (s_axil_bvalid && s_axil_bready) begin
                        s_state <= IDLE;
                    end
                end
                default: s_state <= IDLE;
            endcase
        end
    end
    
    // ------------------------------------------------------------------
    // Output Assignments
    // ------------------------------------------------------------------
    
    // Master Outputs
    assign m_axil_awaddr = m_axil_awaddr_cdc;
    assign m_axil_awprot = m_axil_awprot_cdc;
    assign m_axil_awvalid = m_axil_awvalid_cdc;
    assign m_axil_wdata = m_axil_wdata_cdc;
    assign m_axil_wstrb = m_axil_wstrb_cdc;
    assign m_axil_wvalid = m_axil_wvalid_cdc;
    assign m_axil_bready = m_axil_bready_cdc;
    assign m_axil_araddr = m_axil_araddr_cdc;
    assign m_axil_arprot = m_axil_arprot_cdc;
    assign m_axil_arvalid = m_axil_arvalid_cdc;
    assign m_axil_rdata = m_axil_rdata_cdc;
    assign m_axil_rresp = m_axil_rresp_cdc;
    assign m_axil_rvalid = m_axil_rvalid_cdc;
    assign m_axil_rready = m_axil_rready_cdc;
    
    // Slave Outputs
    assign s_axil_awready = s_axil_awready_cdc;
    assign s_axil_wready = s_axil_wready_cdc;
    assign s_axil_bresp = s_axil_bresp_cdc;
    assign s_axil_bvalid = s_axil_bvalid_cdc;
    assign s_axil_bready = s_axil_bready_cdc;
    assign s_axil_arready = s_axil_arready_cdc;
    assign s_axil_rdata = s_axil_rdata_cdc;
    assign s_axil_rresp = s_axil_rresp_cdc;
    assign s_axil_rvalid = s_axil_rvalid_cdc;
    assign s_axil_rready = s_axil_rready_cdc;

endmodule
```<|im_end|>
