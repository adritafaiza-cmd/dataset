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

    // ========================================================================
    // Write Channel: Slave -> Master
    // ========================================================================
    
    // Slave side: capture AW and W when both are valid
    reg        s_aw_valid;
    reg [ADDR_WIDTH-1:0] s_aw_addr;
    reg [2:0]  s_aw_prot;
    reg        s_w_valid;
    reg [DATA_WIDTH-1:0] s_w_data;
    reg [STRB_WIDTH-1:0] s_w_strb;
    
    // AW handshake on slave side
    wire s_aw_handshake = s_axil_awvalid & s_axil_awready;
    wire s_w_handshake  = s_axil_wvalid & s_axil_wready;
    
    // We accept AW and W independently, but need both before forwarding
    // For simplicity, we'll use a state machine approach:
    // State 0: Idle - waiting for AW and W
    // State 1: Have AW, waiting for W
    // State 2: Have W, waiting for AW
    // State 3: Have both, ready to send to master
    
    reg [1:0] s_wr_state;
    localparam S_WR_IDLE = 2'd0;
    localparam S_WR_HAVE_AW = 2'd1;
    localparam S_WR_HAVE_W = 2'd2;
    localparam S_WR_BOTH = 2'd3;
    
    // Slave side ready signals
    assign s_axil_awready = (s_wr_state == S_WR_IDLE) || (s_wr_state == S_WR_HAVE_W);
    assign s_axil_wready  = (s_wr_state == S_WR_IDLE) || (s_wr_state == S_WR_HAVE_AW);
    
    // Slave side state machine
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_state <= S_WR_IDLE;
            s_aw_valid <= 1'b0;
            s_w_valid  <= 1'b0;
        end else begin
            case (s_wr_state)
                S_WR_IDLE: begin
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        s_aw_addr <= s_axil_awaddr;
                        s_aw_prot <= s_axil_awprot;
                        s_w_data  <= s_axil_wdata;
                        s_w_strb  <= s_axil_wstrb;
                        s_aw_valid <= 1'b1;
                        s_w_valid  <= 1'b1;
                        s_wr_state <= S_WR_BOTH;
                    end else if (s_axil_awvalid) begin
                        s_aw_addr <= s_axil_awaddr;
                        s_aw_prot <= s_axil_awprot;
                        s_aw_valid <= 1'b1;
                        s_wr_state <= S_WR_HAVE_AW;
                    end else if (s_axil_wvalid) begin
                        s_w_data  <= s_axil_wdata;
                        s_w_strb  <= s_axil_wstrb;
                        s_w_valid  <= 1'b1;
                        s_wr_state <= S_WR_HAVE_W;
                    end
                end
                S_WR_HAVE_AW: begin
                    if (s_axil_wvalid) begin
                        s_w_data  <= s_axil_wdata;
                        s_w_strb  <= s_axil_wstrb;
                        s_w_valid  <= 1'b1;
                        s_wr_state <= S_WR_BOTH;
                    end
                end
                S_WR_HAVE_W: begin
                    if (s_axil_awvalid) begin
                        s_aw_addr <= s_axil_awaddr;
                        s_aw_prot <= s_axil_awprot;
                        s_aw_valid <= 1'b1;
                        s_wr_state <= S_WR_BOTH;
                    end
                end
                S_WR_BOTH: begin
                    // Wait for master to accept
                    if (m_wr_ack_sync) begin
                        s_aw_valid <= 1'b0;
                        s_w_valid  <= 1'b0;
                        s_wr_state <= S_WR_IDLE;
                    end
                end
                default: s_wr_state <= S_WR_IDLE;
            endcase
        end
    end
    
    // ========================================================================
    // Write Channel: Master side
    // ========================================================================
    
    // We need to send AW and W to master. We'll use a simple approach:
    // Send AW first, then W, or send both simultaneously.
    // For AXI4-Lite, we can send AW and W independently.
    
    // Master side state machine for write
    reg        m_aw_valid;
    reg [ADDR_WIDTH-1:0] m_aw_addr;
    reg [2:0]  m_aw_prot;
    reg        m_w_valid;
    reg [DATA_WIDTH-1:0] m_w_data;
    reg [STRB_WIDTH-1:0] m_w_strb;
    
    // Synchronization of slave-side "both ready" signal to master clock
    // We need to tell the master side that we have data to send
    
    // Use a simple handshake: slave sets a flag, master clears it
    reg s_wr_send_req;
    reg m_wr_send_ack;
    
    // Synchronize s_wr_send_req to m_clk
    reg [2:0] s_wr_send_req_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_send_req_sync <= 3'b0;
        end else begin
            s_wr_send_req_sync <= {s_wr_send_req_sync[1:0], s_wr_send_req};
        end
    end
    wire m_wr_send_req = s_wr_send_req_sync[2];
    
    // Synchronize m_wr_send_ack to s_clk
    reg [2:0] m_wr_send_ack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_wr_send_ack_sync <= 3'b0;
        end else begin
            m_wr_send_ack_sync <= {m_wr_send_ack_sync[1:0], m_wr_send_ack};
        end
    end
    wire s_wr_ack_sync = m_wr_send_ack_sync[2];
    
    // Slave side: set send request when we have both AW and W
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_send_req <= 1'b0;
        end else begin
            if (s_wr_state == S_WR_BOTH && !s_wr_send_req) begin
                s_wr_send_req <= 1'b1;
            end else if (s_wr_ack_sync) begin
                s_wr_send_req <= 1'b0;
            end
        end
    end
    
    // Master side: handle the send request
    reg m_wr_state;
    localparam M_WR_IDLE = 1'b0;
    localparam M_WR_SEND_AW = 1'b1;
    localparam M_WR_SEND_W = 1'b2;
    localparam M_WR_WAIT_B = 1'b3;
    
    // Actually, let's simplify: we'll send AW and W to master, and wait for B response.
    // The master side will drive m_axil_awvalid and m_axil_wvalid.
    
    // For the master side, we need to:
    // 1. When m_wr_send_req is high, start sending AW
    // 2. When AW is accepted, start sending W
    // 3. When W is accepted, wait for B response
    // 4. When B is received, send ack back to slave
    
    // Let's use a simpler approach: send AW and W simultaneously
    // since AXI4-Lite allows this.
    
    // Master side: drive AW and W
    assign m_axil_awaddr  = s_aw_addr;
    assign m_axil_awprot  = s_aw_prot;
    assign m_axil_awvalid = m_wr_send_req && (m_wr_state == M_WR_IDLE || m_wr_state == M_WR_SEND_AW);
    
    assign m_axil_wdata   = s_w_data;
    assign m_axil_wstrb   = s_w_strb;
    assign m_axil_wvalid  = m_wr_send_req && (m_wr_state == M_WR_IDLE || m_wr_state == M_WR_SEND_W);
    
    // Master side state machine
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_state <= M_WR_IDLE;
            m_wr_send_ack <= 1'b0;
        end else begin
            case (m_wr_state)
                M_WR_IDLE: begin
                    if (m_wr_send_req) begin
                        m_wr_state <= M_WR_SEND_AW;
                    end
                end
                M_WR_SEND_AW: begin
                    if (m_axil_awready) begin
                        m_wr_state <= M_WR_SEND_W;
                    end
                end
                M_WR_SEND_W: begin
                    if (m_axil_wready) begin
                        m_wr_state <= M_WR_WAIT_B;
                    end
                end
                M_WR_WAIT_B: begin
                    if (m_axil_bvalid && m_axil_bready) begin
                        m_wr_state <= M_WR_IDLE;
                        m_wr_send_ack <= 1'b1;
                    end
                end
                default: m_wr_state <= M_WR_IDLE;
            endcase
        end
    end
    
    // Clear ack after one cycle
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_send_ack <= 1'b0;
        end else begin
            m_wr_send_ack <= 1'b0;
        end
    end
    
    // B channel: master to slave
    // We need to forward B response from master to slave
    reg        s_b_valid;
    reg [1:0]  s_b_resp;
    
    // Synchronize m_axil_bvalid and m_axil_bresp to s_clk
    reg [2:0] m_b_valid_sync;
    reg [2:0] m_b_resp_sync;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_b_valid_sync <= 3'b0;
            m_b_resp_sync  <= 3'b0;
        end else begin
            m_b_valid_sync <= {m_b_valid_sync[1:0], m_axil_bvalid};
            m_b_resp_sync  <= {m_b_resp_sync[1:0], m_axil_bresp};
        end
    end
    
    wire s_b_valid_sync = m_b_valid_sync[2];
    wire [1:0] s_b_resp_sync = m_b_resp_sync[2:1];
    
    // Slave side: capture B response
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_valid <= 1'b0;
            s_b_resp  <= 2'b0;
        end else begin
            if (s_b_valid_sync && !s_b_valid) begin
                s_b_valid <= 1'b1;
                s_b_resp  <= s_b_resp_sync;
            end else if (s_b_valid && s_axil_bready) begin
                s_b_valid <= 1'b0;
            end
        end
    end
    
    assign s_axil_bvalid = s_b_valid;
    assign s_axil_bresp  = s_b_resp;
    
    // Master side: drive B ready
    assign m_axil_bready = 1'b1;
    
    // ========================================================================
    // Read Channel: Slave -> Master
    // ========================================================================
    
    // Slave side: capture AR
    reg        s_ar_valid;
    reg [ADDR_WIDTH-1:0] s_ar_addr;
    reg [2:0]  s_ar_prot;
    
    // AR handshake on slave side
    assign s_axil_arready = !s_ar_valid;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_valid <= 1'b0;
        end else begin
            if (s_axil_arvalid && !s_ar_valid) begin
                s_ar_addr <= s_axil_araddr;
                s_ar_prot <= s_axil_arprot;
                s_ar_valid <= 1'b1;
            end else if (s_ar_valid && s_ar_ack_sync) begin
                s_ar_valid <= 1'b0;
            end
        end
    end
    
    // Synchronization of slave-side AR valid to master clock
    reg [2:0] s_ar_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_ar_valid_sync <= 3'b0;
        end else begin
            s_ar_valid_sync <= {s_ar_valid_sync[1:0], s_ar_valid};
        end
    end
    wire m_ar_valid = s_ar_valid_sync[2];
    
    // Synchronization of master-side AR ack to slave clock
    reg        m_ar_ack;
    reg [2:0] m_ar_ack_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_ar_ack_sync <= 3'b0;
        end else begin
            m_ar_ack_sync <= {m_ar_ack_sync[1:0], m_ar_ack};
        end
    end
    wire s_ar_ack_sync = m_ar_ack_sync[2];
    
    // Master side: drive AR
    assign m_axil_araddr  = s_ar_addr;
    assign m_axil_arprot  = s_ar_prot;
    assign m_axil_arvalid = m_ar_valid;
    
    // Master side: handle AR
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_ack <= 1'b0;
        end else begin
            if (m_ar_valid && m_axil_arready) begin
                m_ar_ack <= 1'b1;
            end else begin
                m_ar_ack <= 1'b0;
            end
        end
    end
    
    // R channel: master to slave
    reg        s_r_valid;
    reg [DATA_WIDTH-1:0] s_r_data;
    reg [1:0]  s_r_resp;
    
    // Synchronize m_axil_rvalid, m_axil_rdata, m_axil_rresp to s_clk
    reg [2:0] m_r_valid_sync;
    reg [2*DATA_WIDTH+1:0] m_r_data_sync;
    reg [2:0] m_r_resp_sync;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_r_valid_sync <= 3'b0;
            m_r_data_sync  <= {(2*DATA_WIDTH+1){1'b0}};
            m_r_resp_sync  <= 3'b0;
        end else begin
            m_r_valid_sync <= {m_r_valid_sync[1:0], m_axil_rvalid};
            m_r_data_sync  <= {m_r_data_sync[2*DATA_WIDTH:1], m_axil_rdata};
            m_r_resp_sync  <= {m_r_resp_sync[1:0], m_axil_rresp};
        end
    end
    
    wire s_r_valid_sync = m_r_valid_sync[2];
    wire [DATA_WIDTH-1:0] s_r_data_sync = m_r_data_sync[2*DATA_WIDTH-1:DATA_WIDTH];
    wire [1:0] s_r_resp_sync = m_r_resp_sync[2:1];
    
    // Slave side: capture R response
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_valid <= 1'b0;
        end else begin
            if (s_r_valid_sync && !s_r_valid) begin
                s_r_valid <= 1'b1;
                s_r_data  <= s_r_data_sync;
                s_r_resp  <= s_r_resp_sync;
            end else if (s_r_valid && s_axil_rready) begin
                s_r_valid <= 1'b0;
            end
        end
    end
    
    assign s_axil_rvalid = s_r_valid;
    assign s_axil_rdata  = s_r_data;
    assign s_axil_rresp  = s_r_resp;
    
    // Master side: drive R ready
    assign m_axil_rready = 1'b1;

endmodule
