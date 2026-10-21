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
    
    // State Machine States
    localparam IDLE = 2'b00;
    localparam AW_REQ = 2'b01;
    localparam AW_ACK = 2'b10;
    localparam W_REQ = 2'b11;
    localparam W_ACK = 2'b00; // Reuse IDLE for W_ACK completion if no data, but we need distinct states for flow control
    // Let's refine states for clarity:
    // 00: IDLE
    // 01: AW_VALID (Waiting for AW_READY)
    // 10: W_VALID (Waiting for W_READY)
    // 11: B_VALID (Waiting for B_READY)
    
    // Transaction IDs
    localparam AW_ID = 2'b00;
    localparam W_ID  = 2'b01;
    localparam B_ID  = 2'b10;
    localparam R_ID  = 2'b11;

    // State Registers
    reg [1:0] s_state, n_state;
    
    // AW Channel State
    reg [1:0] aw_state; // 00:Idle, 01:Valid
    reg [1:0] aw_id;
    reg [ADDR_WIDTH-1:0] aw_addr;
    reg [2:0] aw_prot;
    reg aw_valid;
    
    // W Channel State
    reg [1:0] w_state; // 00:Idle, 01:Valid
    reg [1:0] w_id;
    reg [DATA_WIDTH-1:0] w_data;
    reg [STRB_WIDTH-1:0] w_strb;
    reg w_valid;
    
    // B Channel State
    reg [1:0] b_state; // 00:Idle, 01:Valid
    reg [1:0] b_id;
    reg [1:0] b_resp;
    reg b_valid;
    
    // R Channel State
    reg [1:0] r_state; // 00:Idle, 01:Valid
    reg [1:0] r_id;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [2:0] r_prot;
    reg [DATA_WIDTH-1:0] r_data;
    reg [1:0] r_resp;
    reg r_valid;
    
    // CDC Registers (Synchronous to s_clk)
    reg [1:0] s_aw_state;
    reg [1:0] s_aw_id;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0] s_aw_prot;
    reg s_aw_valid;
    
    reg [1:0] s_w_state;
    reg [1:0] s_w_id;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;
    reg s_w_valid;
    
    reg [1:0] s_b_state;
    reg [1:0] s_b_id;
    reg [1:0] s_b_resp;
    reg s_b_valid;
    
    reg [1:0] s_r_state;
    reg [1:0] s_r_id;
    reg [ADDR_WIDTH-1:0] s_r_addr;
    reg [2:0] s_r_prot;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0] s_r_resp;
    reg s_r_valid;
    
    // CDC Registers (Synchronous to m_clk)
    reg [1:0] m_aw_state;
    reg [1:0] m_aw_id;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0] m_aw_prot;
    reg m_aw_valid;
    
    reg [1:0] m_w_state;
    reg [1:0] m_w_id;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;
    reg m_w_valid;
    
    reg [1:0] m_b_state;
    reg [1:0] m_b_id;
    reg [1:0] m_b_resp;
    reg m_b_valid;
    
    reg [1:0] m_r_state;
    reg [1:0] m_r_id;
    reg [ADDR_WIDTH-1:0] m_r_addr;
    reg [2:0] m_r_prot;
    reg [DATA_WIDTH-1:0] m_r_data;
    reg [1:0] m_r_resp;
    reg m_r_valid;

    // -----------------------------------------------------------------------
    // Clock Domain Crossing: Slave (s_clk) -> Master (m_clk)
    // -----------------------------------------------------------------------
    
    // AW Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_state <= IDLE;
            s_aw_id <= AW_ID;
            s_aw_addr <= '0;
            s_aw_prot <= '0;
            s_aw_valid <= 1'b0;
        end else begin
            s_aw_state <= s_aw_state;
            s_aw_id <= s_aw_id;
            s_aw_addr <= s_aw_addr;
            s_aw_prot <= s_aw_prot;
            s_aw_valid <= s_axil_awvalid;
        end
    end

    // W Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_state <= IDLE;
            s_w_id <= W_ID;
            s_w_data <= '0;
            s_w_strb <= '0;
            s_w_valid <= 1'b0;
        end else begin
            s_w_state <= s_w_state;
            s_w_id <= s_w_id;
            s_w_data <= s_axil_wdata;
            s_w_strb <= s_axil_wstrb;
            s_w_valid <= s_axil_wvalid;
        end
    end

    // B Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_state <= IDLE;
            s_b_id <= B_ID;
            s_b_resp <= 2'b00;
            s_b_valid <= 1'b0;
        end else begin
            s_b_state <= s_b_state;
            s_b_id <= s_b_id;
            s_b_resp <= s_axil_bresp;
            s_b_valid <= s_axil_bvalid;
        end
    end

    // R Channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_state <= IDLE;
            s_r_id <= R_ID;
            s_r_addr <= '0;
            s_r_prot <= '0;
            s_r_data <= '0;
            s_r_resp <= 2'b00;
            s_r_valid <= 1'b0;
        end else begin
            s_r_state <= s_r_state;
            s_r_id <= s_r_id;
            s_r_addr <= s_axil_araddr;
            s_r_prot <= s_axil_arprot;
            s_r_data <= '0; // Data will be updated when valid
            s_r_resp <= 2'b00;
            s_r_valid <= s_axil_rvalid;
        end
    end

    // -----------------------------------------------------------------------
    // Clock Domain Crossing: Master (m_clk) -> Slave (s_clk)
    // -----------------------------------------------------------------------
    
    // AW Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_state <= IDLE;
            m_aw_id <= AW_ID;
            m_aw_addr <= '0;
            m_aw_prot <= '0;
            m_aw_valid <= 1'b0;
        end else begin
            m_aw_state <= m_aw_state;
            m_aw_id <= m_aw_id;
            m_aw_addr <= m_aw_addr;
            m_aw_prot <= m_aw_prot;
            m_aw_valid <= m_axil_awvalid;
        end
    end

    // W Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_state <= IDLE;
            m_w_id <= W_ID;
            m_w_data <= '0;
            m_w_strb <= '0;
            m_w_valid <= 1'b0;
        end else begin
            m_w_state <= m_w_state;
            m_w_id <= m_w_id;
            m_w_data <= m_axil_wdata;
            m_w_strb <= m_axil_wstrb;
            m_w_valid <= m_axil_wvalid;
        end
    end

    // B Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_state <= IDLE;
            m_b_id <= B_ID;
            m_b_resp <= 2'b00;
            m_b_valid <= 1'b0;
        end else begin
            m_b_state <= m_b_state;
            m_b_id <= m_b_id;
            m_b_resp <= m_axil_bresp;
            m_b_valid <= m_axil_bvalid;
        end
    end

    // R Channel
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_state <= IDLE;
            m_r_id <= R_ID;
            m_r_addr <= '0;
            m_r_prot <= '0;
            m_r_data <= '0;
            m_r_resp <= 2'b00;
            m_r_valid <= 1'b0;
        end else begin
            m_r_state <= m_r_state;
            m_r_id <= m_r_id;
            m_r_addr <= m_axil_araddr;
            m_r_prot <= m_axil_arprot;
            m_r_data <= m_axil_rdata;
            m_r_resp <= m_axil_rresp;
            m_r_valid <= m_axil_rvalid;
        end
    end

    // -----------------------------------------------------------------------
    // Slave Logic (s_clk domain)
    // -----------------------------------------------------------------------
    
    // AW Channel Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awready <= 1'b0;
        end else begin
            // Ready if idle or if we have a pending AW request waiting for master
            // Since we are bridging, we just forward. 
            // To avoid deadlock, we need to ensure we don't assert ready if we can't accept.
            // Simplest CDC: Assert ready when we are in IDLE state or if we have a valid request 
            // that the master is ready for. 
            // However, standard CDC for AXI Lite usually involves a handshake.
            // We will assert ready if the internal state is IDLE or if we have a valid request 
            // and the master is ready (checked via CDC registers).
            
            // Actually, for a simple bridge, we can just forward the signals if the CDC registers 
            // indicate the master is ready. But to be safe against metastability and ensure 
            // no lost transactions, we use a state machine.
            
            // Logic: If we are in IDLE, we can accept. If we have a pending request (s_aw_valid),
            // we can only accept new requests if the master is ready (m_aw_ready).
            // But wait, the master is on m_clk. We need to know if m_axil_awready is high.
            // We have m_axil_awready in m_clk domain. We need to sample it.
            
            // Let's use a simple handshake logic:
            // If s_axil_awvalid is high, we wait for m_axil_awready.
            // We need to capture m_axil_awready in s_clk domain.
            
            // Re-evaluating strategy: 
            // 1. Capture m_axil_awready in s_clk domain (m_aw_ready_sampled).
            // 2. If s_axil_awvalid is high and m_aw_ready_sampled is high, assert s_axil_awready.
            // 3. If s_axil_awvalid is high and m_aw_ready_sampled is low, hold s_axil_awready low.
            // 4. If s_axil_awvalid is low, deassert s_axil_awready.
            
            // This requires capturing m_axil_awready.
            reg m_aw_ready_sampled;
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) m_aw_ready_sampled <= 1'b0;
                else m_aw_ready_sampled <= m_axil_awready;
            end
            
            if (s_rst)
                s_axil_awready <= 1'b0;
            else if (s_axil_awvalid && m_aw_ready_sampled)
                s_axil_awready <= 1'b1;
            else
                s_axil_awready <= 1'b0;
        end
    end

    // W Channel Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_wready <= 1'b0;
        end else begin
            reg m_w_ready_sampled;
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) m_w_ready_sampled <= 1'b0;
                else m_w_ready_sampled <= m_axil_wready;
            end
            
            if (s_axil_wvalid && m_w_ready_sampled)
                s_axil_wready <= 1'b1;
            else
                s_axil_wready <= 1'b0;
        end
    end

    // B Channel Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            // We need to generate B response based on the AW request we received.
            // Since this is a pass-through bridge, we just forward the B response from the master.
            // We need to know if the master has a B response ready.
            
            reg m_b_valid_sampled;
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) m_b_valid_sampled <= 1'b0;
                else m_b_valid_sampled <= m_axil_bvalid;
            end
            
            if (m_b_valid_sampled) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= m_axil_bresp;
            end else begin
                s_axil_bvalid <= 1'b0;
                s_axil_bresp <= 2'b00;
            end
        end
    end

    // R Channel Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= '0;
            s_axil_rresp <= 2'b00;
        end else begin
            // Forward R response from master
            reg m_r_valid_sampled;
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) m_r_valid_sampled <= 1'b0;
                else m_r_valid_sampled <= m_axil_rvalid;
            end
            
            if (m_r_valid_sampled) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rdata <= m_axil_rdata;
                s_axil_rresp <= m_axil_rresp;
            end else begin
                s_axil_rvalid <= 1'b0;
                s_axil_rdata <= '0;
                s_axil_rresp <= 2'b00;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Master Logic (m_clk domain)
    // -----------------------------------------------------------------------
    
    // AW Channel Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awvalid <= 1'b0;
            m_axil_awaddr <= '0;
            m_axil_awprot <= '0;
        end else begin
            // We need to generate AW request based on the AW request from slave.
            // We need to know if the slave is ready.
            
            reg s_aw_valid_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_aw_valid_sampled <= 1'b0;
                else s_aw_valid_sampled <= s_axil_awvalid;
            end
            
            reg s_aw_ready_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_aw_ready_sampled <= 1'b0;
                else s_aw_ready_sampled <= s_axil_awready;
            end
            
            if (s_aw_valid_sampled && s_aw_ready_sampled) begin
                m_axil_awvalid <= 1'b1;
                m_axil_awaddr <= s_axil_awaddr;
                m_axil_awprot <= s_axil_awprot;
            end else begin
                m_axil_awvalid <= 1'b0;
                m_axil_awaddr <= '0;
                m_axil_awprot <= '0;
            end
        end
    end

    // W Channel Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_wvalid <= 1'b0;
            m_axil_wdata <= '0;
            m_axil_wstrb <= '0;
        end else begin
            reg s_w_valid_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_w_valid_sampled <= 1'b0;
                else s_w_valid_sampled <= s_axil_wvalid;
            end
            
            reg s_w_ready_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_w_ready_sampled <= 1'b0;
                else s_w_ready_sampled <= s_axil_wready;
            end
            
            if (s_w_valid_sampled && s_w_ready_sampled) begin
                m_axil_wvalid <= 1'b1;
                m_axil_wdata <= s_axil_wdata;
                m_axil_wstrb <= s_axil_wstrb;
            end else begin
                m_axil_wvalid <= 1'b0;
                m_axil_wdata <= '0;
                m_axil_wstrb <= '0;
            end
        end
    end

    // B Channel Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_bready <= 1'b0;
        end else begin
            // We need to generate B ready based on the B request from slave.
            reg s_b_valid_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_b_valid_sampled <= 1'b0;
                else s_b_valid_sampled <= s_axil_bvalid;
            end
            
            reg s_b_ready_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_b_ready_sampled <= 1'b0;
                else s_b_ready_sampled <= s_axil_bready;
            end
            
            if (s_b_valid_sampled && s_b_ready_sampled) begin
                m_axil_bready <= 1'b1;
            end else begin
                m_axil_bready <= 1'b0;
            end
        end
    end

    // R Channel Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_rready <= 1'b0;
        end else begin
            // We need to generate R ready based on the R request from slave.
            reg s_r_valid_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_r_valid_sampled <= 1'b0;
                else s_r_valid_sampled <= s_axil_rvalid;
            end
            
            reg s_r_ready_sampled;
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) s_r_ready_sampled <= 1'b0;
                else s_r_ready_sampled <= s_axil_rready;
            end
            
            if (s_r_valid_sampled && s_r_ready_sampled) begin
                m_axil_rready <= 1'b1;
            end else begin
                m_axil_rready <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
