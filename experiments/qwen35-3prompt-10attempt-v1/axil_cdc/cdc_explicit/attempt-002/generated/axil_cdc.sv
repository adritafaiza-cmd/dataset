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
    // CDC Logic: Synchronous FIFOs for multi-bit data transfer
    // ------------------------------------------------------------------
    
    // Write Channel FIFO (Data + Strb)
    // Depth: 2 is sufficient for 1 outstanding transaction
    parameter FIFO_DEPTH = 2;
    parameter FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    wire [DATA_WIDTH-1:0] wdata_in;
    wire [STRB_WIDTH-1:0] wstrb_in;
    wire wvalid_in;
    wire wready_in;
    wire wfull;
    wire wempty;
    wire woverflow;
    wire wunderflow;
    
    // Read Channel FIFO (Data + Resp)
    wire [DATA_WIDTH-1:0] rdata_out;
    wire [1:0] rresp_out;
    wire rvalid_out;
    wire rready_out;
    wire rfull;
    wire rempty;
    wire roverflow;
    wire runderflow;

    // Address/Control FIFOs (Single bit valid, multi-bit data)
    // We use a simple 2-state machine approach for addresses to avoid complex FIFOs
    // but wrap them in CDC-safe registers.
    
    // ------------------------------------------------------------------
    // Write Channel Implementation
    // ------------------------------------------------------------------
    
    // 1. Capture Slave Write Data on Slave Clock
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg wready_reg;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 1;
        end else begin
            wdata_reg <= s_axil_wdata;
            wstrb_reg <= s_axil_wstrb;
            wvalid_reg <= s_axil_wvalid;
            wready_reg <= s_axil_wready;
        end
    end
    
    // 2. Capture Master Write Ready on Master Clock
    reg m_wready_reg;
    reg m_wvalid_reg;
    reg m_wdata_reg;
    reg m_wstrb_reg;
    reg m_wvalid_capture;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wready_reg <= 0;
            m_wvalid_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wvalid_capture <= 0;
        end else begin
            m_wready_reg <= m_axil_wready;
            m_wvalid_reg <= m_axil_wvalid;
            m_wdata_reg <= m_axil_wdata;
            m_wstrb_reg <= m_axil_wstrb;
            m_wvalid_capture <= m_axil_wvalid;
        end
    end
    
    // 3. Write FIFO Logic (Slave Domain)
    // State: IDLE, WAITING_FOR_MASTER_READY
    reg [1:0] w_state; // 0: IDLE, 1: WAITING_FOR_MASTER_READY
    reg [FIFO_ADDR_WIDTH-1:0] w_fifo_addr;
    reg [DATA_WIDTH-1:0] w_fifo_data;
    reg [STRB_WIDTH-1:0] w_fifo_strb;
    reg w_fifo_valid;
    reg w_fifo_ready;
    
    // Simple 2-deep FIFO implementation using pointers
    reg [FIFO_ADDR_WIDTH-1:0] w_rptr;
    reg [FIFO_ADDR_WIDTH-1:0] w_wptr;
    reg [FIFO_ADDR_WIDTH-1:0] w_full_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] w_empty_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] w_count;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_rptr <= 0;
            w_wptr <= 0;
            w_count <= 0;
            w_fifo_valid <= 0;
            w_fifo_ready <= 1;
            w_state <= 0;
        end else begin
            w_rptr <= w_rptr + 1;
            w_wptr <= w_wptr + 1;
            w_count <= w_count + 1;
            w_fifo_valid <= 1;
            w_fifo_ready <= 0;
            w_state <= 1;
        end
    end
    
    // ------------------------------------------------------------------
    // Read Channel Implementation
    // ------------------------------------------------------------------
    
    // 1. Capture Slave Read Data on Slave Clock
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg arready_reg;
    reg arvalid_capture;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            arready_reg <= 1;
            arvalid_capture <= 0;
        end else begin
            araddr_reg <= s_axil_araddr;
            arprot_reg <= s_axil_arprot;
            arvalid_reg <= s_axil_arvalid;
            arready_reg <= s_axil_arready;
            arvalid_capture <= s_axil_arvalid;
        end
    end
    
    // 2. Capture Master Read Ready on Master Clock
    reg m_arready_reg;
    reg m_arvalid_reg;
    reg m_araddr_reg;
    reg m_arprot_reg;
    reg m_arvalid_capture;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_arready_reg <= 0;
            m_arvalid_reg <= 0;
            m_araddr_reg <= 0;
            m_arprot_reg <= 0;
            m_arvalid_capture <= 0;
        end else begin
            m_arready_reg <= m_axil_arready;
            m_arvalid_reg <= m_axil_arvalid;
            m_araddr_reg <= m_axil_araddr;
            m_arprot_reg <= m_axil_arprot;
            m_arvalid_capture <= m_axil_arvalid;
        end
    end
    
    // 3. Read FIFO Logic (Slave Domain)
    reg [1:0] r_state; // 0: IDLE, 1: WAITING_FOR_MASTER_READY
    reg [FIFO_ADDR_WIDTH-1:0] r_fifo_addr;
    reg [DATA_WIDTH-1:0] r_fifo_data;
    reg [1:0] r_fifo_resp;
    reg r_fifo_valid;
    reg r_fifo_ready;
    
    reg [FIFO_ADDR_WIDTH-1:0] r_rptr;
    reg [FIFO_ADDR_WIDTH-1:0] r_wptr;
    reg [FIFO_ADDR_WIDTH-1:0] r_count;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_rptr <= 0;
            r_wptr <= 0;
            r_count <= 0;
            r_fifo_valid <= 0;
            r_fifo_ready <= 1;
            r_state <= 0;
        end else begin
            r_rptr <= r_rptr + 1;
            r_wptr <= r_wptr + 1;
            r_count <= r_count + 1;
            r_fifo_valid <= 1;
            r_fifo_ready <= 0;
            r_state <= 1;
        end
    end
    
    // ------------------------------------------------------------------
    // Master Side Logic (Clock Domain m_clk)
    // ------------------------------------------------------------------
    
    // Write Channel Master Side
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_capture;
    assign m_axil_wready = m_wready_reg;
    
    // Read Channel Master Side
    assign m_axil_araddr = m_araddr_reg;
    assign m_axil_arprot = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_capture;
    assign m_axil_arready = m_arready_reg;
    
    // ------------------------------------------------------------------
    // Slave Side Logic (Clock Domain s_clk)
    // ------------------------------------------------------------------
    
    // Write Channel Slave Side
    assign s_axil_wready = wready_reg;
    assign s_axil_wvalid = wvalid_reg;
    assign s_axil_wdata = wdata_reg;
    assign s_axil_wstrb = wstrb_reg;
    
    // Read Channel Slave Side
    assign s_axil_arready = arready_reg;
    assign s_axil_arvalid = arvalid_reg;
    assign s_axil_araddr = araddr_reg;
    assign s_axil_arprot = arprot_reg;
    
    // ------------------------------------------------------------------
    // Cross-Clock Domain Handshaking Logic
    // ------------------------------------------------------------------
    
    // Write Channel Handshake
    // Slave sends data when wvalid_reg is high.
    // Master sends ready when m_wready_reg is high.
    // We need to align these signals.
    
    // Slave side: Wait for master ready before asserting wvalid
    // Master side: Wait for slave data before asserting wvalid
    
    // Since we are using a simple state machine approach without a full FIFO for addresses,
    // we will use a "flyweight" approach where we hold the transaction in a register
    // until the other domain is ready.
    
    // Write Channel:
    // 1. Slave captures wdata/wstrb/wvalid.
    // 2. Slave waits for m_wready_reg (sampled on s_clk) to assert s_axil_wready.
    // 3. Master sees s_axil_wready, asserts m_axil_wvalid.
    // 4. Master captures wdata/wstrb/wvalid.
    // 5. Master asserts m_axil_wready.
    // 6. Slave sees m_axil_wready, asserts s_axil_wvalid.
    // 7. Master sees s_axil_wvalid, completes transaction.
    
    // To simplify and ensure no loss, we use a 2-state machine on the slave side
    // to hold the transaction until the master is ready.
    
    // Write Channel State Machine (Slave Domain)
    // State 0: Idle
    // State 1: Waiting for Master Ready (holding wdata, wstrb)
    // State 2: Waiting for Master Valid (holding wdata, wstrb)
    
    reg [1:0] w_fsm; // 0: IDLE, 1: WAIT_READY, 2: WAIT_VALID
    reg [DATA_WIDTH-1:0] w_hold_data;
    reg [STRB_WIDTH-1:0] w_hold_strb;
    reg w_hold_valid;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_fsm <= 0;
            w_hold_data <= 0;
            w_hold_strb <= 0;
            w_hold_valid <= 0;
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_bvalid <= 0;
            s_axil_bresp <= 0;
        end else begin
            // Address Capture
            if (s_axil_awvalid && s_axil_awready) begin
                // Address accepted, move to waiting for write data
                w_fsm <= 1;
                w_hold_data <= s_axil_wdata;
                w_hold_strb <= s_axil_wstrb;
                w_hold_valid <= 1;
                s_axil_awready <= 0;
                s_axil_wready <= 0;
            end else if (w_fsm == 1) begin
                // Waiting for write data
                if (s_axil_wvalid && s_axil_wready) begin
                    w_fsm <= 2;
                    s_axil_wready <= 0;
                end
            end else if (w_fsm == 2) begin
                // Waiting for master to accept write
                // Check if master is ready (sampled on s_clk)
                if (m_wready_reg) begin
                    // Send data to master
                    m_axil_wdata <= w_hold_data;
                    m_axil_wstrb <= w_hold_strb;
                    m_axil_wvalid <= 1;
                    s_axil_wready <= 1;
                    s_axil_wvalid <= 1;
                    w_fsm <= 0; // Reset state after sending
                    w_hold_valid <= 0;
                end
            end
            
            // Address Ready
            if (w_fsm == 0) begin
                s_axil_awready <= 1;
            end
            
            // Write Ready
            if (w_fsm == 1) begin
                s_axil_wready <= 1;
            end
            
            // Write Valid
            if (w_fsm == 2) begin
                s_axil_wvalid <= 1;
            end
            
            // Write Response (B channel)
            // Assume OK for simplicity, or pass through if needed.
            // For CDC, we need to send B response back to slave.
            // We sample m_axil_bvalid on s_clk.
            reg m_bvalid_reg;
            reg m_bresp_reg;
            
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    m_bvalid_reg <= 0;
                    m_bresp_reg <= 0;
                end else begin
                    m_bvalid_reg <= m_axil_bvalid;
                    m_bresp_reg <= m_axil_bresp;
                end
            end
            
            if (m_bvalid_reg && m_axil_bready) begin
                s_axil_bvalid <= 1;
                s_axil_bresp <= m_bresp_reg;
                s_axil_bready <= 0;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 0;
            end
        end
    end
    
    // Read Channel State Machine (Slave Domain)
    // State 0: Idle
    // State 1: Waiting for Master Ready (holding araddr, arprot)
    // State 2: Waiting for Master Valid (holding araddr, arprot)
    // State 3: Waiting for Data (holding araddr, arprot)
    // State 4: Waiting for Response (holding araddr, arprot)
    
    reg [1:0] r_fsm; // 0: IDLE, 1: WAIT_READY, 2: WAIT_VALID, 3: WAIT_DATA, 4: WAIT_RESP
    reg [ADDR_WIDTH-1:0] r_hold_addr;
    reg [2:0] r_hold_prot;
    reg r_hold_valid;
    reg [DATA_WIDTH-1:0] r_hold_data;
    reg [1:0] r_hold_resp;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_fsm <= 0;
            r_hold_addr <= 0;
            r_hold_prot <= 0;
            r_hold_valid <= 0;
            s_axil_arready <= 0;
            s_axil_rvalid <= 0;
            s_axil_rdata <= 0;
            s_axil_rresp <= 0;
        end else begin
            // Address Capture
            if (s_axil_arvalid && s_axil_arready) begin
                r_fsm <= 1;
                r_hold_addr <= s_axil_araddr;
                r_hold_prot <= s_axil_arprot;
                r_hold_valid <= 1;
                s_axil_arready <= 0;
            end else if (r_fsm == 1) begin
                // Waiting for address ready from master
                if (m_arready_reg) begin
                    r_fsm <= 2;
                    s_axil_arready <= 0;
                end
            end else if (r_fsm == 2) begin
                // Waiting for address valid from master
                if (m_arvalid_reg) begin
                    r_fsm <= 3;
                    s_axil_arvalid <= 1;
                    s_axil_arready <= 1;
                end
            end else if (r_fsm == 3) begin
                // Waiting for data from master
                // Check if master has data (sampled on s_clk)
                if (m_axil_rvalid_reg && m_axil_rready_reg) begin
                    r_fsm <= 4;
                    r_hold_data <= m_axil_rdata;
                    r_hold_resp <= m_axil_rresp;
                    s_axil_rvalid <= 1;
                    s_axil_rready <= 0;
                end
            end else if (r_fsm == 4) begin
                // Waiting for response from master
                // Check if master has response (sampled on s_clk)
                if (m_axil_bvalid_reg && m_axil_bready_reg) begin
                    r_fsm <= 0;
                    s_axil_rvalid <= 0;
                    s_axil_rdata <= r_hold_data;
                    s_axil_rresp <= r_hold_resp;
                    s_axil_bvalid <= 1;
                    s_axil_bresp <= m_axil_bresp;
                    s_axil_bready <= 0;
                end else if (s_axil_bvalid && s_axil_bready) begin
                    s_axil_bvalid <= 0;
                end
            end
            
            // Address Ready
            if (r_fsm == 0) begin
                s_axil_arready <= 1;
            end
            
            // Address Valid
            if (r_fsm == 2) begin
                s_axil_arvalid <= 1;
            end
            
            // Read Data Valid
            if (r_fsm == 3) begin
                s_axil_rvalid <= 1;
            end
            
            // Read Data Ready
            if (r_fsm == 4) begin
                s_axil_rready <= 1;
            end
        end
    end
    
    // Helper registers for Master side sampling
    reg m_arvalid_reg;
    reg m_axil_rvalid_reg;
    reg m_axil_rready_reg;
    reg m_axil_bvalid_reg;
    reg m_axil_bready_reg;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_arvalid_reg <= 0;
            m_axil_rvalid_reg <= 0;
            m_axil_rready_reg <= 0;
            m_axil_bvalid_reg <= 0;
            m_axil_bready_reg <= 0;
        end else begin
            m_arvalid_reg <= m_axil_arvalid;
            m_axil_rvalid_reg <= m_axil_rvalid;
            m_axil_rready_reg <= m_axil_rready;
            m_axil_bvalid_reg <= m_axil_bvalid;
            m_axil_bready_reg <= m_axil_bready;
        end
    end
    
    // Address Valid on Master Side
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Read Data Ready on Master Side
    assign m_axil_rready = m_axil_rready_reg;
    
    // Read Response Ready on Master Side
    assign m_axil_bready = m_axil_bready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Read Data Valid on Slave Side (from FSM)
    assign s_axil_rvalid = (r_fsm == 3);
    
    // Read Data Ready on Slave Side (from FSM)
    assign s_axil_rready = (r_fsm == 4);
    
    // Write Address Ready on Slave Side (from FSM)
    assign s_axil_awready = (w_fsm == 0);
    
    // Write Data Ready on Slave Side (from FSM)
    assign s_axil_wready = (w_fsm == 1);
    
    // Write Address Valid on Slave Side (from FSM)
    assign s_axil_awvalid = (w_fsm == 0); // Address is valid when FSM is in IDLE state, ready to accept
    
    // Write Data Valid on Slave Side (from FSM)
    assign s_axil_wvalid = (w_fsm == 2);
    
    // Write Response Valid on Slave Side (from FSM)
    assign s_axil_bvalid = (r_fsm == 4 && m_axil_bvalid_reg); // Simplified: only valid when transitioning back to idle
    
    // Write Response Ready on Slave Side (from FSM)
    assign s_axil_bready = (r_fsm == 4);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from FSM)
    assign m_axil_arvalid = m_arvalid_reg;
    
    // Address Ready on Master Side (from FSM)
    assign m_axil_arready = m_axil_arready_reg;
    
    // Address Valid on Slave Side (from FSM)
    assign s_axil_arvalid = (r_fsm == 2);
    
    // Address Ready on Slave Side (from FSM)
    assign s_axil_arready = (r_fsm == 0);
    
    // Address Valid on Master Side (from