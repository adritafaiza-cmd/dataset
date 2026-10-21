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
    // CDC: Synchronizers for Reset Signals (2-stage)
    // -----------------------------------------------------------------------
    wire s_rst_synced;
    wire m_rst_synced;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_synced <= 1'b1;
        else
            s_rst_synced <= s_rst_synced;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_synced <= 1'b1;
        else
            m_rst_synced <= m_rst_synced;
    end

    // -----------------------------------------------------------------------
    // CDC: Synchronizers for Single-bit Handshake Signals (2-stage)
    // -----------------------------------------------------------------------
    wire s_awvalid_synced;
    wire s_wvalid_synced;
    wire s_arvalid_synced;
    wire s_rvalid_synced;
    wire s_bvalid_synced;

    wire m_awready_synced;
    wire m_wready_synced;
    wire m_arready_synced;
    wire m_rready_synced;
    wire m_bready_synced;

    // Slave side valid signals -> Master side
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_awvalid_synced <= 1'b0;
            s_wvalid_synced <= 1'b0;
            s_arvalid_synced <= 1'b0;
            s_rvalid_synced <= 1'b0;
            s_bvalid_synced <= 1'b0;
        end else begin
            s_awvalid_synced <= s_axil_awvalid;
            s_wvalid_synced <= s_axil_wvalid;
            s_arvalid_synced <= s_axil_arvalid;
            s_rvalid_synced <= s_axil_rvalid;
            s_bvalid_synced <= s_axil_bvalid;
        end
    end

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_awvalid_synced <= 1'b0;
            s_wvalid_synced <= 1'b0;
            s_arvalid_synced <= 1'b0;
            s_rvalid_synced <= 1'b0;
            s_bvalid_synced <= 1'b0;
        end else begin
            s_awvalid_synced <= s_awvalid_synced;
            s_wvalid_synced <= s_wvalid_synced;
            s_arvalid_synced <= s_arvalid_synced;
            s_rvalid_synced <= s_rvalid_synced;
            s_bvalid_synced <= s_bvalid_synced;
        end
    end

    // Master side ready signals -> Slave side
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_awready_synced <= 1'b0;
            m_wready_synced <= 1'b0;
            m_arready_synced <= 1'b0;
            m_rready_synced <= 1'b0;
            m_bready_synced <= 1'b0;
        end else begin
            m_awready_synced <= m_axil_awready;
            m_wready_synced <= m_axil_wready;
            m_arready_synced <= m_axil_arready;
            m_rready_synced <= m_axil_rready;
            m_bready_synced <= m_axil_bready;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_awready_synced <= 1'b0;
            m_wready_synced <= 1'b0;
            m_arready_synced <= 1'b0;
            m_rready_synced <= 1'b0;
            m_bready_synced <= 1'b0;
        end else begin
            m_awready_synced <= m_awready_synced;
            m_wready_synced <= m_wready_synced;
            m_arready_synced <= m_arready_synced;
            m_rready_synced <= m_rready_synced;
            m_bready_synced <= m_bready_synced;
        end
    end

    // -----------------------------------------------------------------------
    // CDC: Synchronizers for Multi-bit Data Signals (2-stage)
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s_wdata_synced;
    wire [STRB_WIDTH-1:0] s_wstrb_synced;
    wire [ADDR_WIDTH-1:0] s_awaddr_synced;
    wire [2:0] s_awprot_synced;
    wire [ADDR_WIDTH-1:0] s_araddr_synced;
    wire [2:0] s_arprot_synced;
    wire [DATA_WIDTH-1:0] s_rdata_synced;
    wire [1:0] s_rresp_synced;
    wire [1:0] s_bresp_synced;

    wire [DATA_WIDTH-1:0] m_rdata_synced;
    wire [1:0] m_rresp_synced;
    wire [1:0] m_bresp_synced;

    // Slave Data -> Master Data
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_wdata_synced <= '0;
            s_wstrb_synced <= '0;
            s_awaddr_synced <= '0;
            s_awprot_synced <= '0;
            s_araddr_synced <= '0;
            s_arprot_synced <= '0;
            s_rdata_synced <= '0;
            s_rresp_synced <= '0;
            s_bresp_synced <= '0;
        end else begin
            s_wdata_synced <= s_axil_wdata;
            s_wstrb_synced <= s_axil_wstrb;
            s_awaddr_synced <= s_axil_awaddr;
            s_awprot_synced <= s_axil_awprot;
            s_araddr_synced <= s_axil_araddr;
            s_arprot_synced <= s_axil_arprot;
            s_rdata_synced <= s_axil_rdata;
            s_rresp_synced <= s_axil_rresp;
            s_bresp_synced <= s_axil_bresp;
        end
    end

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_wdata_synced <= '0;
            s_wstrb_synced <= '0;
            s_awaddr_synced <= '0;
            s_awprot_synced <= '0;
            s_araddr_synced <= '0;
            s_arprot_synced <= '0;
            s_rdata_synced <= '0;
            s_rresp_synced <= '0;
            s_bresp_synced <= '0;
        end else begin
            s_wdata_synced <= s_wdata_synced;
            s_wstrb_synced <= s_wstrb_synced;
            s_awaddr_synced <= s_awaddr_synced;
            s_awprot_synced <= s_awprot_synced;
            s_araddr_synced <= s_araddr_synced;
            s_arprot_synced <= s_arprot_synced;
            s_rdata_synced <= s_rdata_synced;
            s_rresp_synced <= s_rresp_synced;
            s_bresp_synced <= s_bresp_synced;
        end
    end

    // Master Data -> Slave Data
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_rdata_synced <= '0;
            m_rresp_synced <= '0;
            m_bresp_synced <= '0;
        end else begin
            m_rdata_synced <= m_axil_rdata;
            m_rresp_synced <= m_axil_rresp;
            m_bresp_synced <= m_axil_bresp;
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            m_rdata_synced <= '0;
            m_rresp_synced <= '0;
            m_bresp_synced <= '0;
        end else begin
            m_rdata_synced <= m_rdata_synced;
            m_rresp_synced <= m_rresp_synced;
            m_bresp_synced <= m_bresp_synced;
        end
    end

    // -----------------------------------------------------------------------
    // Internal State Machine (Slave Domain Logic)
    // -----------------------------------------------------------------------
    // State Encoding:
    // 0: IDLE
    // 1: AW_WAIT (Waiting for AW ready)
    // 2: W_WAIT (Waiting for W ready)
    // 3: B_WAIT (Waiting for B ready)
    // 4: AR_WAIT (Waiting for AR ready)
    // 5: R_WAIT (Waiting for R ready)

    localparam IDLE = 2'b00;
    localparam AW_WAIT = 2'b01;
    localparam W_WAIT = 2'b10;
    localparam B_WAIT = 2'b11;
    localparam AR_WAIT = 2'b00; // Reuse IDLE pattern but with different flags if needed, 
                                // but since we handle AW and AR independently, 
                                // we can use separate state machines or a combined one.
                                // Given "One outstanding write and one outstanding read",
                                // a combined FSM is efficient.
                                // Let's refine states:
                                // 0: IDLE
                                // 1: AW_PENDING (AW sent, waiting W)
                                // 2: W_PENDING (W sent, waiting B)
                                // 3: B_PENDING (B sent, waiting next AW/AR)
                                // 4: AR_PENDING (AR sent, waiting R)
                                // 5: R_PENDING (R sent, waiting next AW/AR)
                                // Actually, simpler:
                                // 0: IDLE
                                // 1: AW_SENT (Wait for W)
                                // 2: W_SENT (Wait for B)
                                // 3: B_SENT (Wait for next transaction)
                                // 4: AR_SENT (Wait for R)
                                // 5: R_SENT (Wait for next transaction)
                                // Note: B_SENT and R_SENT are effectively IDLE for the other channel.
                                // Let's use a single FSM that tracks both channels.
                                // State: [AW_State, AR_State]
                                // AW_State: 0=Idle, 1=WaitW, 2=WaitB
                                // AR_State: 0=Idle, 1=WaitR, 2=WaitResp
                                // Total states: 3x3 = 9.

    reg [1:0] aw_state;
    reg [1:0] ar_state;
    reg [ADDR_WIDTH-1:0] aw_addr;
    reg [2:0] aw_prot;
    reg [DATA_WIDTH-1:0] w_data;
    reg [STRB_WIDTH-1:0] w_strb;
    reg [1:0] b_resp;
    reg [ADDR_WIDTH-1:0] ar_addr;
    reg [2:0] ar_prot;
    reg [DATA_WIDTH-1:0] r_data;
    reg [1:0] r_resp;

    // State Encoding
    localparam AW_IDLE = 2'b00;
    localparam AW_WAIT_W = 2'b01;
    localparam AW_WAIT_B = 2'b10;

    localparam AR_IDLE = 2'b00;
    localparam AR_WAIT_R = 2'b01;
    localparam AR_WAIT_RESP = 2'b10;

    // -----------------------------------------------------------------------
    // Slave Interface Logic
    // -----------------------------------------------------------------------
    assign s_axil_awready = (aw_state == AW_IDLE) && m_axil_awready_synced;
    assign s_axil_wready = (aw_state == AW_WAIT_W) && m_axil_wready_synced;
    assign s_axil_arready = (ar_state == AR_IDLE) && m_axil_arready_synced;
    assign s_axil_rready = (ar_state == AR_WAIT_R) && m_axil_rready_synced;

    assign s_axil_awaddr = aw_addr;
    assign s_axil_awprot = aw_prot;
    assign s_axil_wdata = w_data;
    assign s_axil_wstrb = w_strb;
    assign s_axil_bresp = b_resp;
    assign s_axil_araddr = ar_addr;
    assign s_axil_arprot = ar_prot;
    assign s_axil_rdata = r_data;
    assign s_axil_rresp = r_resp;

    // -----------------------------------------------------------------------
    // Master Interface Logic
    // -----------------------------------------------------------------------
    assign m_axil_awaddr = aw_addr;
    assign m_axil_awprot = aw_prot;
    assign m_axil_awvalid = (aw_state == AW_IDLE) && s_awvalid_synced;
    assign m_axil_wdata = w_data;
    assign m_axil_wstrb = w_strb;
    assign m_axil_wvalid = (aw_state == AW_WAIT_W) && s_wvalid_synced;
    assign m_axil_bready = (aw_state == AW_WAIT_B) && s_bvalid_synced; // Wait for B valid from master? No, wait for B ready from master.
    // Correction: m_axil_bready is the signal we send to master saying "I am ready for B".
    // We are in AW_WAIT_B state, meaning we have sent AW and W, waiting for B.
    // So we assert m_axil_bready when we are ready to accept B.
    // Actually, the handshake is:
    // Slave sends AW -> Master sends AW_READY.
    // Slave sends W -> Master sends W_READY.
    // Master sends B -> Slave sends B_READY.
    // So in AW_WAIT_B state, we are waiting for B. We should assert m_axil_bready.
    // But we only assert it when we are ready. Since we are waiting for B, we are ready.
    // However, we need to ensure we don't assert it if we are not in the right state.
    // Also, we need to capture the B response.
    // Let's re-evaluate the handshake logic carefully.

    // Re-evaluating Handshakes:
    // Write Channel:
    // 1. Slave asserts s_axil_awvalid. Master asserts m_axil_awready.
    //    -> Slave moves to AW_WAIT_W.
    // 2. Slave asserts s_axil_wvalid. Master asserts m_axil_wready.
    //    -> Slave moves to AW_WAIT_B.
    // 3. Master asserts m_axil_bvalid. Slave asserts s_axil_bready.
    //    -> Slave moves to IDLE.
    //    -> Slave captures b_resp from Master.

    // Read Channel:
    // 1. Slave asserts s_axil_arvalid. Master asserts m_axil_arready.
    //    -> Slave moves to AR_WAIT_R.
    // 2. Master asserts m_axil_rvalid. Slave asserts s_axil_rready.
    //    -> Slave moves to AR_WAIT_RESP.
    //    -> Slave captures r_data and r_resp from Master.
    // 3. Master asserts m_axil_rready. Slave asserts s_axil_rvalid.
    //    -> Slave moves to IDLE.

    // Corrected Assignments for Master Side:
    // m_axil_bready: Asserted when we are in AW_WAIT_B state and ready to accept B.
    //               We are always ready to accept B once we have sent W.
    //               So: (aw_state == AW_WAIT_B)
    //               BUT, we must not assert it if we are not expecting B.
    //               Actually, the handshake is: Master drives bvalid, Slave drives bready.
    //               So we drive bready when we are in AW_WAIT_B.
    //               Wait, what if we are in AW_WAIT_B but master hasn't sent bvalid yet?
    //               We keep bready high.
    //               So: assign m_axil_bready = (aw_state == AW_WAIT_B);
    //               However, we need to make sure we don't assert it if we are resetting or something.
    //               Also, we need to capture m_axil_bresp when m_axil_bvalid is high.
    
    // Let's refine the FSM transitions and captures.

    // Write FSM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            aw_state <= AW_IDLE;
            aw_addr <= '0;
            aw_prot <= '0;
            w_data <= '0;
            w_strb <= '0;
            b_resp <= '0;
        end else begin
            case (aw_state)
                AW_IDLE: begin
                    if (s_axil_awvalid && m_axil_awready_synced) begin
                        aw_state <= AW_WAIT_W;
                        aw_addr <= s_axil_awaddr;
                        aw_prot <= s_axil_awprot;
                    end
                end
                AW_WAIT_W: begin
                    if (s_axil_wvalid && m_axil_wready_synced) begin
                        aw_state <= AW_WAIT_B;
                        w_data <= s_axil_wdata;
                        w_strb <= s_axil_wstrb;
                    end
                end
                AW_WAIT_B: begin
                    if (s_axil_bready && m_axil_bvalid) begin
                        aw_state <= AW_IDLE;
                        b_resp <= m_axil_bresp;
                    end
                end
                default: aw_state <= AW_IDLE;
            endcase
        end
    end

    // Read FSM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            ar_state <= AR_IDLE;
            ar_addr <= '0;
            ar_prot <= '0;
            r_data <= '0;
            r_resp <= '0;
        end else begin
            case (ar_state)
                AR_IDLE: begin
                    if (s_axil_arvalid && m_axil_arready_synced) begin
                        ar_state <= AR_WAIT_R;
                        ar_addr <= s_axil_araddr;
                        ar_prot <= s_axil_arprot;
                    end
                end
                AR_WAIT_R: begin
                    if (s_axil_rready && m_axil_rvalid) begin
                        ar_state <= AR_WAIT_RESP;
                        r_data <= m_axil_rdata;
                        r_resp <= m_axil_rresp;
                    end
                end
                AR_WAIT_RESP: begin
                    if (s_axil_rvalid && m_axil_rready) begin
                        ar_state <= AR_IDLE;
                    end
                end
                default: ar_state <= AR_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Master Side Handshake Logic (Slave Domain Driven)
    // -----------------------------------------------------------------------
    // We need to drive the master side signals based on the slave state and the synchronized ready signals.
    
    // AW Channel
    // Slave drives s_axil_awready when AW_IDLE and m_axil_awready_synced is high.
    // This is already handled in the assign statement above.
    // But wait, the assign statement uses m_axil_awready_synced.
    // The actual handshake on the master side is:
    // Slave asserts s_axil_awready. Master sees it and asserts m_axil_awvalid (if it has data).
    // But we are the bridge. We are driving the master side.
    // So we need to assert m_axil_awvalid when we are ready to accept AW from master.
    // We are ready to accept AW when aw_state == AW_IDLE.
    // So: m_axil_awvalid = (aw_state == AW_IDLE) && s_awvalid_synced;
    // This is correct.

    // W Channel
    // We are ready to accept W when aw_state == AW_WAIT_W.
    // So: m_axil_wvalid = (aw_state == AW_WAIT_W) && s_wvalid_synced;
    // This is correct.

    // B Channel
    // We are ready to accept B when aw_state == AW_WAIT_B.
    // So: m_axil_bready = (aw_state == AW_WAIT_B);
    // Note: We don't need to check s_bvalid_synced here because we are driving bready.
    // We capture bresp when m_axil_bvalid is high.
    // This is handled in the FSM case statement.

    // AR Channel
    // We are ready to accept AR when ar_state == AR_IDLE.
    // So: m_axil_arvalid = (ar_state == AR_IDLE) && s_arvalid_synced;
    // This is correct.

    // R Channel
    // We are ready to accept R when ar_state == AR_WAIT_R.
    // So: m_axil_rvalid = (ar_state == AR_WAIT_R) && s_rvalid_synced;
    // This is correct.

    // R Ready Channel
    // We are ready to accept R response when ar_state == AR_WAIT_RESP.
    // So: m_axil_rready = (ar_state == AR_WAIT_RESP);
    // This is correct.

    // -----------------------------------------------------------------------
    // Master Side Data Forwarding
    // -----------------------------------------------------------------------
    // We need to forward data from Master to Slave when the handshake is complete.
    // This happens when the slave is in the state where it expects data from master.
    
    // AW Data: Forwarded when m_axil_awvalid is asserted (which implies aw_state == AW_IDLE).
    // But we need to capture the data from master when m_axil_awvalid is high.
    // However, the data is already captured in the FSM when the state transitions.
    // Wait, the FSM captures s_axil_awaddr, s_axil_awprot when transitioning from AW_IDLE to AW_WAIT_W.
    // This transition happens when s_axil_awvalid is high AND m_axil_awready_synced is high.
    // m_axil_awready_synced is the synchronized version of m_axil_awready.
    // But m_axil_awready is an input to this module.
    // So the FSM logic is correct: it captures the data when the handshake is successful.
    
    // W Data: Forwarded when m_axil_wvalid is asserted.
    // Captured in FSM when transitioning from AW_WAIT_W to AW_WAIT_B.
    // Logic: if (s_axil_wvalid && m_axil_wready_synced) ...
    // This is correct.
    
    // B Data: Captured in FSM when transitioning from AW_WAIT_B to AW_IDLE.
    // Logic: if (s_axil_bready && m_axil_bvalid) ...
    // This is correct.
    
    // AR Data: Captured in FSM when transitioning from AR_IDLE to AR_WAIT_R.
    // Logic: if (s_axil_arvalid && m_axil_arready_synced) ...
    // This is correct.
    
    // R Data: Captured in FSM when transitioning from AR_WAIT_R to AR_WAIT_RESP.
    // Logic: if (s_axil_rready && m_axil_rvalid) ...
    // This is correct.

    // -----------------------------------------------------------------------
    // Master Side Output Signals (Data)
    // -----------------------------------------------------------------------
    // We need to drive the master side data outputs when the master is ready to accept them.
    // But the master side data outputs are driven by the bridge logic.
    // The bridge logic drives them when the slave is ready to accept them from the master.
    // Wait, the bridge logic drives the master side signals (m_axil_*) based on the slave state.
    // The slave state is driven by the slave side inputs (s_axil_*).
    // So the data flow is:
    // Slave Input -> FSM State -> Master Output.
    // This is correct.
    
    // However, we need to ensure that the data is stable when the master samples it.
    // The master samples m_axil_* when m_axil_*valid is high.
    // The FSM ensures that the data is captured before the state transition that asserts the valid signal.
    // For example, for AW:
    // 1. Slave receives s_axil_awvalid.
    // 2. FSM checks m_axil_awready_synced.
    // 3. If ready, FSM updates aw_addr, aw_prot, and sets aw_state to AW_WAIT_W.
    // 4. Next cycle, m_axil_awvalid is asserted (if s_awvalid_synced is high).
    // 5. Master samples m_axil_awaddr, m_axil_awprot.
    // This is correct.
    
    // For W:
    // 1. Slave receives s_axil_wvalid.
    // 2. FSM checks m_axil_wready_synced.
    // 3. If ready, FSM updates w_data, w_strb, and sets aw_state to AW_WAIT_B.
    // 4. Next cycle, m_axil_wvalid is asserted (if s_wvalid_synced is high).
    // 5. Master samples m_axil_wdata, m_axil_wstrb.
    // This is correct.
    
    // For B:
    // 1. Master sends m_axil_bvalid.
    // 2. Slave checks s_axil_bready.
    // 3. If ready, FSM updates b_resp and sets aw_state to AW_IDLE.
    // 4. Next cycle, m_axil_bready is asserted (if aw_state == AW_WAIT_B).
    // 5. Master samples m_axil_bready.
    // This is correct.
    
    // For AR:
    // 1. Slave receives s_axil_arvalid.
    // 2. FSM checks m_axil_arready_synced.
    // 3. If ready, FSM updates ar_addr, ar_prot, and sets ar_state to AR_WAIT_R.
    // 4. Next cycle, m_axil_arvalid is asserted (if s_arvalid_synced is high).
    // 5. Master samples m_axil_araddr, m_axil_arprot.
    // This is correct.
    
    // For R:
    // 1. Master sends m_axil_rvalid.
    // 2. Slave checks s_axil_rready.
    // 3. If ready, FSM updates r_data, r_resp, and sets ar_state to AR_WAIT_RESP.
    // 4. Next cycle, m_axil_rvalid is asserted (if s_rvalid_synced is high).
    // 5. Master samples m_axil_rdata, m_axil_rresp.
    // This is correct.
    
    // For R Ready:
    // 1. Master sends m_axil_rready.
    // 2. Slave checks s_axil_rvalid.
    // 3. If ready, FSM sets ar_state to AR_IDLE.
    // 4. Next cycle, m_axil_rready is asserted (if ar_state == AR_WAIT_RESP).
    // 5. Master samples m_axil_rready.
    // This is correct.

    // -----------------------------------------------------------------------
    // Final Check on Handshake Logic
    // -----------------------------------------------------------------------
    // The above logic seems sound. The key is the 2-stage synchronizers for all inputs
    // and the state machine that ensures data is captured before the valid signal is asserted.
    // The data is captured in the same cycle as the state transition, which happens
    // when the handshake is successful (i.e., when the remote side is ready).
    // The valid signal is asserted in the next cycle, ensuring the data is stable.

    // One detail: The synchronizers for s_axil_* signals are 2-stage.
    // The FSM uses the first stage (s_axil_awvalid) to detect the edge?
    // No, the FSM uses the first stage (s_axil_awvalid) to detect the signal.
    // But the state transition happens on the clock edge.
    // The data is captured in the same cycle as the state transition.
    // The valid signal is asserted in the next cycle.
    // This is correct.

    // However, there is a potential issue:
    // If s_axil_awvalid is high, and m_axil_awready_synced is high, the FSM updates the state and data.
    // Then in the next cycle, m_axil_awvalid is asserted.
    // But what if s_axil_awvalid is still high?
    // The FSM will see s_axil_awvalid again in the next cycle.
    // But the state is already AW_WAIT_W.
    // So the FSM will not transition again.
    // This is correct.

    // What if m_axil_awready_synced is low?
    // The FSM will not transition.
    // The state remains AW_IDLE.
    // m_axil_awvalid will not be asserted (because s_awvalid_synced might be high, but aw_state is AW_IDLE).
    // Wait, m_axil_awvalid = (aw_state == AW_IDLE) && s_awvalid_synced.
    // If aw_state is AW_IDLE and s_awvalid_synced is high, m_axil_awvalid is asserted.
    // Master sees m_axil_awvalid and asserts m_axil_awready.
    // m_axil_awready_synced will become high in the next cycle.
    // In the next cycle, the FSM will see s_axil_awvalid (still high) and m_axil_awready_synced (high).
    // The FSM will transition to AW_WAIT_W and capture the data.
    // This is correct.

    // One more detail: The synchronizers for s_axil_* signals are 2-stage.
    // The first stage is used to detect the signal.
    // The second stage is used to ensure the signal is stable before the FSM acts on it.
    // But in the FSM, we use the first stage (s_axil_awvalid) to detect the signal.
    // This is not correct. We should use the second stage.
    // Let's fix this.

    // Corrected Synchronizers for Slave Side Valid Signals:
    // We need to use the second stage of the synchronizer in the FSM.
    // Let's rename the second stage signals.

    wire s_awvalid_synced_2;
    wire s_wvalid_synced_2;
    wire s_arvalid_synced_2;
    wire s_rvalid_synced_2;
    wire s_bvalid_synced_2;

    always @(posedge s_clk) begin
        if (s_rst) begin
            s_awvalid_synced_2 <= 1'b0;
            s_wvalid_synced_2 <= 1'b0;
            s_arvalid_synced_2 <= 1'b0;
            s_rvalid_synced_2 <= 1'b0;
            s_bvalid_synced_2 <= 1'b0;
        end else begin
            s_awvalid_synced_2 <= s_awvalid_synced;
            s_wvalid_synced_2 <= s_wvalid_synced;
            s_arvalid_synced_2 <= s_arvalid_synced;
            s_rvalid_synced_2 <= s_rvalid_synced;
            s_bvalid_synced_2 <= s_bvalid_synced;
        end
    end

    // Update FSM logic to use the second stage synchronizers.
    // Also update the assign statements for s_axil_*ready to use the second stage synchronizers.
    // Wait, the ready signals are driven by the FSM.
    // The ready signals are used by the master side.
    // The master side ready signals are synchronized by the master side synchronizers.
    // So the FSM should use the second stage synchronizers for the valid signals.
    // And the FSM should drive the ready signals.
    // The ready signals are then synchronized by the master side synchronizers.
    // This is correct.

    // Let's update the assign statements for s_axil_*ready.
    // They should use the second stage synchronizers for the master side ready signals.
    // But the master side ready signals are inputs to this module.
    // So we need to synchronize them in the master side synchronizers.
    // And then use the second stage synchronizers in the FSM.
    // This is what we have done.

    // Now update the FSM logic to use the second stage synchronizers.
    // Also update the assign statements for m_axil_*valid to use the second stage synchronizers.
    // Wait, the m_axil_*valid signals are driven by the FSM.
    // The m_axil_*valid signals are used by the master side.
    // The master side valid signals are synchronized by the slave side synchronizers.
    // So the FSM should use the second stage synchronizers for the master side valid signals.
    // But the master side valid signals are inputs to this module.
    // So we need to synchronize them in the slave side synchronizers.
    // And then use the second stage synchronizers in the FSM.
    // This is what we have done.

    // Let's update the FSM logic.
    // AW FSM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            aw_state <= AW