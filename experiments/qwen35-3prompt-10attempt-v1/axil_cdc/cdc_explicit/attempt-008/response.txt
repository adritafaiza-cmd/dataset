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
    wire s_rst_n;
    wire m_rst_n;
    wire s_aw_valid, s_w_valid, s_ar_valid, s_r_valid;
    wire s_aw_ready, s_w_ready, s_ar_ready, s_r_ready;
    wire m_aw_valid, m_w_valid, m_ar_valid, m_r_valid;
    wire m_aw_ready, m_w_ready, m_ar_ready, m_r_ready;
    
    wire [ADDR_WIDTH-1:0] s_aw_addr, s_ar_addr;
    wire [2:0] s_aw_prot, s_ar_prot;
    wire [DATA_WIDTH-1:0] s_w_data, s_w_strb;
    wire [DATA_WIDTH-1:0] s_r_data;
    wire [1:0] s_b_resp, s_r_resp;
    
    wire [ADDR_WIDTH-1:0] m_aw_addr, m_ar_addr;
    wire [2:0] m_aw_prot, m_ar_prot;
    wire [DATA_WIDTH-1:0] m_w_data, m_w_strb;
    wire [DATA_WIDTH-1:0] m_r_data;
    wire [1:0] m_b_resp, m_r_resp;

    // CDC Registers for Reset Synchronization
    reg s_rst_sync;
    reg m_rst_sync;

    // Write Channel State Machine (Slave -> Master)
    reg [1:0] s_write_state; // 0: Idle, 1: Waiting Master Ready, 2: Waiting Slave Ready
    reg [ADDR_WIDTH-1:0] s_write_addr;
    reg [2:0] s_write_prot;
    reg [DATA_WIDTH-1:0] s_write_data;
    reg [STRB_WIDTH-1:0] s_write_strb;
    reg s_write_valid;
    reg s_write_ready;
    reg s_write_done;

    // Read Channel State Machine (Slave -> Master)
    reg [1:0] s_read_state; // 0: Idle, 1: Waiting Master Ready, 2: Waiting Slave Ready
    reg [ADDR_WIDTH-1:0] s_read_addr;
    reg [2:0] s_read_prot;
    reg s_read_valid;
    reg s_read_ready;
    reg s_read_done;

    // Master Write Channel State Machine (Master -> Slave)
    reg [1:0] m_write_state; // 0: Idle, 1: Waiting Slave Ready, 2: Waiting Master Ready
    reg [ADDR_WIDTH-1:0] m_write_addr;
    reg [2:0] m_write_prot;
    reg [DATA_WIDTH-1:0] m_write_data;
    reg [STRB_WIDTH-1:0] m_write_strb;
    reg m_write_valid;
    reg m_write_ready;
    reg m_write_done;

    // Master Read Channel State Machine (Master -> Slave)
    reg [1:0] m_read_state; // 0: Idle, 1: Waiting Slave Ready, 2: Waiting Master Ready
    reg [ADDR_WIDTH-1:0] m_read_addr;
    reg [2:0] m_read_prot;
    reg m_read_valid;
    reg m_read_ready;
    reg m_read_done;

    // Response Storage for Slave Side (to return to Master)
    reg [1:0] s_b_resp_storage;
    reg s_b_valid_storage;
    reg s_b_ready_storage;
    
    reg [DATA_WIDTH-1:0] s_r_data_storage;
    reg [1:0] s_r_resp_storage;
    reg s_r_valid_storage;
    reg s_r_ready_storage;

    // Response Storage for Master Side (to return to Slave)
    reg [1:0] m_b_resp_storage;
    reg m_b_valid_storage;
    reg m_b_ready_storage;
    
    reg [DATA_WIDTH-1:0] m_r_data_storage;
    reg [1:0] m_r_resp_storage;
    reg m_r_valid_storage;
    reg m_r_ready_storage;

    // ------------------------------------------------------------------
    // Reset Synchronization
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_sync <= 1'b1;
        else
            s_rst_sync <= s_rst;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_sync <= 1'b1;
        else
            m_rst_sync <= m_rst;
    end

    // ------------------------------------------------------------------
    // Slave Side: Write Channel (s -> m)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_write_state <= 2'b00;
            s_write_addr <= '0;
            s_write_prot <= '0;
            s_write_data <= '0;
            s_write_strb <= '0;
            s_write_valid <= 1'b0;
            s_write_ready <= 1'b1;
            s_write_done <= 1'b0;
        end else begin
            case (s_write_state)
                2'b00: begin // Idle
                    if (s_axil_awvalid & s_axil_awready & s_axil_wvalid & s_axil_wready) begin
                        s_write_addr <= s_axil_awaddr;
                        s_write_prot <= s_axil_awprot;
                        s_write_data <= s_axil_wdata;
                        s_write_strb <= s_axil_wstrb;
                        s_write_valid <= 1'b1;
                        s_write_state <= 2'b01;
                    end
                    s_write_ready <= 1'b1;
                end
                2'b01: begin // Waiting for Master Write Ready
                    if (m_axil_wready) begin
                        s_write_state <= 2'b10;
                    end
                    s_write_ready <= 1'b0;
                end
                2'b10: begin // Waiting for Master Write Valid (to release)
                    if (m_axil_wvalid) begin
                        s_write_state <= 2'b00;
                        s_write_valid <= 1'b0;
                        s_write_done <= 1'b1;
                    end
                end
                default: begin
                    s_write_state <= 2'b00;
                    s_write_ready <= 1'b1;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Slave Side: Read Channel (s -> m)
    // ------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_read_state <= 2'b00;
            s_read_addr <= '0;
            s_read_prot <= '0;
            s_read_valid <= 1'b0;
            s_read_ready <= 1'b1;
            s_read_done <= 1'b0;
        end else begin
            case (s_read_state)
                2'b00: begin // Idle
                    if (s_axil_arvalid & s_axil_arready) begin
                        s_read_addr <= s_axil_araddr;
                        s_read_prot <= s_axil_arprot;
                        s_read_valid <= 1'b1;
                        s_read_state <= 2'b01;
                    end
                    s_read_ready <= 1'b1;
                end
                2'b01: begin // Waiting for Master Read Ready
                    if (m_axil_rready) begin
                        s_read_state <= 2'b10;
                    end
                    s_read_ready <= 1'b0;
                end
                2'b10: begin // Waiting for Master Read Valid (to release)
                    if (m_axil_rvalid) begin
                        s_read_state <= 2'b00;
                        s_read_valid <= 1'b0;
                        s_read_done <= 1'b1;
                    end
                end
                default: begin
                    s_read_state <= 2'b00;
                    s_read_ready <= 1'b1;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Master Side: Write Channel (m -> s)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_write_state <= 2'b00;
            m_write_addr <= '0;
            m_write_prot <= '0;
            m_write_data <= '0;
            m_write_strb <= '0;
            m_write_valid <= 1'b0;
            m_write_ready <= 1'b1;
            m_write_done <= 1'b0;
        end else begin
            case (m_write_state)
                2'b00: begin // Idle
                    if (s_axil_wready) begin
                        m_write_addr <= s_write_addr;
                        m_write_prot <= s_write_prot;
                        m_write_data <= s_write_data;
                        m_write_strb <= s_write_strb;
                        m_write_valid <= 1'b1;
                        m_write_state <= 2'b01;
                    end
                    m_write_ready <= 1'b1;
                end
                2'b01: begin // Waiting for Slave Write Ready
                    if (s_axil_wready) begin
                        m_write_state <= 2'b10;
                    end
                    m_write_ready <= 1'b0;
                end
                2'b10: begin // Waiting for Slave Write Valid (to release)
                    if (s_axil_wvalid) begin
                        m_write_state <= 2'b00;
                        m_write_valid <= 1'b0;
                        m_write_done <= 1'b1;
                    end
                end
                default: begin
                    m_write_state <= 2'b00;
                    m_write_ready <= 1'b1;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Master Side: Read Channel (m -> s)
    // ------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_read_state <= 2'b00;
            m_read_addr <= '0;
            m_read_prot <= '0;
            m_read_valid <= 1'b0;
            m_read_ready <= 1'b1;
            m_read_done <= 1'b0;
        end else begin
            case (m_read_state)
                2'b00: begin // Idle
                    if (s_axil_rready) begin
                        m_read_addr <= s_read_addr;
                        m_read_prot <= s_read_prot;
                        m_read_valid <= 1'b1;
                        m_read_state <= 2'b01;
                    end
                    m_read_ready <= 1'b1;
                end
                2'b01: begin // Waiting for Slave Read Ready
                    if (s_axil_rready) begin
                        m_read_state <= 2'b10;
                    end
                    m_read_ready <= 1'b0;
                end
                2'b10: begin // Waiting for Slave Read Valid (to release)
                    if (s_axil_rvalid) begin
                        m_read_state <= 2'b00;
                        m_read_valid <= 1'b0;
                        m_read_done <= 1'b1;
                    end
                end
                default: begin
                    m_read_state <= 2'b00;
                    m_read_ready <= 1'b1;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Data Transfer (Write Data)
    // ------------------------------------------------------------------
    // Slave -> Master Write Data
    reg [DATA_WIDTH-1:0] s_w_data_sync;
    reg [STRB_WIDTH-1:0] s_w_strb_sync;
    reg s_w_valid_sync;
    reg s_w_ready_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_data_sync <= '0;
            s_w_strb_sync <= '0;
            s_w_valid_sync <= 1'b0;
            s_w_ready_sync <= 1'b1;
        end else begin
            if (s_write_state == 2'b01 && s_write_valid) begin
                s_w_data_sync <= s_write_data;
                s_w_strb_sync <= s_write_strb;
                s_w_valid_sync <= 1'b1;
                s_w_ready_sync <= 1'b0;
            end else if (s_write_state == 2'b10 && s_write_valid) begin
                s_w_valid_sync <= 1'b0;
                s_w_ready_sync <= 1'b1;
            end else begin
                s_w_ready_sync <= 1'b1;
            end
        end
    end

    // Master -> Slave Write Data
    reg [DATA_WIDTH-1:0] m_w_data_sync;
    reg [STRB_WIDTH-1:0] m_w_strb_sync;
    reg m_w_valid_sync;
    reg m_w_ready_sync;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_data_sync <= '0;
            m_w_strb_sync <= '0;
            m_w_valid_sync <= 1'b0;
            m_w_ready_sync <= 1'b1;
        end else begin
            if (m_write_state == 2'b01 && m_write_valid) begin
                m_w_data_sync <= m_write_data;
                m_w_strb_sync <= m_write_strb;
                m_w_valid_sync <= 1'b1;
                m_w_ready_sync <= 1'b0;
            end else if (m_write_state == 2'b10 && m_write_valid) begin
                m_w_valid_sync <= 1'b0;
                m_w_ready_sync <= 1'b1;
            end else begin
                m_w_ready_sync <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Data Transfer (Read Data)
    // ------------------------------------------------------------------
    // Slave -> Master Read Data
    reg [DATA_WIDTH-1:0] s_r_data_sync;
    reg [1:0] s_r_resp_sync;
    reg s_r_valid_sync;
    reg s_r_ready_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_sync <= '0;
            s_r_resp_sync <= '0;
            s_r_valid_sync <= 1'b0;
            s_r_ready_sync <= 1'b1;
        end else begin
            if (s_read_state == 2'b01 && s_read_valid) begin
                s_r_data_sync <= s_read_data;
                s_r_resp_sync <= s_read_resp;
                s_r_valid_sync <= 1'b1;
                s_r_ready_sync <= 1'b0;
            end else if (s_read_state == 2'b10 && s_read_valid) begin
                s_r_valid_sync <= 1'b0;
                s_r_ready_sync <= 1'b1;
            end else begin
                s_r_ready_sync <= 1'b1;
            end
        end
    end

    // Master -> Slave Read Data
    reg [DATA_WIDTH-1:0] m_r_data_sync;
    reg [1:0] m_r_resp_sync;
    reg m_r_valid_sync;
    reg m_r_ready_sync;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_data_sync <= '0;
            m_r_resp_sync <= '0;
            m_r_valid_sync <= 1'b0;
            m_r_ready_sync <= 1'b1;
        end else begin
            if (m_read_state == 2'b01 && m_read_valid) begin
                m_r_data_sync <= m_read_data;
                m_r_resp_sync <= m_read_resp;
                m_r_valid_sync <= 1'b1;
                m_r_ready_sync <= 1'b0;
            end else if (m_read_state == 2'b10 && m_read_valid) begin
                m_r_valid_sync <= 1'b0;
                m_r_ready_sync <= 1'b1;
            end else begin
                m_r_ready_sync <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Data Transfer (B-Response)
    // ------------------------------------------------------------------
    // Slave -> Master B-Response
    reg [1:0] s_b_resp_sync;
    reg s_b_valid_sync;
    reg s_b_ready_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_resp_sync <= '0;
            s_b_valid_sync <= 1'b0;
            s_b_ready_sync <= 1'b1;
        end else begin
            if (s_write_state == 2'b01 && s_write_done) begin
                s_b_resp_sync <= s_b_resp_storage;
                s_b_valid_sync <= 1'b1;
                s_b_ready_sync <= 1'b0;
            end else if (s_write_state == 2'b10 && s_write_done) begin
                s_b_valid_sync <= 1'b0;
                s_b_ready_sync <= 1'b1;
            end else begin
                s_b_ready_sync <= 1'b1;
            end
        end
    end

    // Master -> Slave B-Response
    reg [1:0] m_b_resp_sync;
    reg m_b_valid_sync;
    reg m_b_ready_sync;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_resp_sync <= '0;
            m_b_valid_sync <= 1'b0;
            m_b_ready_sync <= 1'b1;
        end else begin
            if (m_write_state == 2'b01 && m_write_done) begin
                m_b_resp_sync <= m_b_resp_storage;
                m_b_valid_sync <= 1'b1;
                m_b_ready_sync <= 1'b0;
            end else if (m_write_state == 2'b10 && m_write_done) begin
                m_b_valid_sync <= 1'b0;
                m_b_ready_sync <= 1'b1;
            end else begin
                m_b_ready_sync <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Data Transfer (R-Response)
    // ------------------------------------------------------------------
    // Slave -> Master R-Response
    reg [DATA_WIDTH-1:0] s_r_data_resp_sync;
    reg [1:0] s_r_resp_resp_sync;
    reg s_r_valid_resp_sync;
    reg s_r_ready_resp_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_resp_sync <= '0;
            s_r_resp_resp_sync <= '0;
            s_r_valid_resp_sync <= 1'b0;
            s_r_ready_resp_sync <= 1'b1;
        end else begin
            if (s_read_state == 2'b01 && s_read_done) begin
                s_r_data_resp_sync <= s_r_data_storage;
                s_r_resp_resp_sync <= s_r_resp_storage;
                s_r_valid_resp_sync <= 1'b1;
                s_r_ready_resp_sync <= 1'b0;
            end else if (s_read_state == 2'b10 && s_read_done) begin
                s_r_valid_resp_sync <= 1'b0;
                s_r_ready_resp_sync <= 1'b1;
            end else begin
                s_r_ready_resp_sync <= 1'b1;
            end
        end
    end

    // Master -> Slave R-Response
    reg [DATA_WIDTH-1:0] m_r_data_resp_sync;
    reg [1:0] m_r_resp_resp_sync;
    reg m_r_valid_resp_sync;
    reg m_r_ready_resp_sync;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_data_resp_sync <= '0;
            m_r_resp_resp_sync <= '0;
            m_r_valid_resp_sync <= 1'b0;
            m_r_ready_resp_sync <= 1'b1;
        end else begin
            if (m_read_state == 2'b01 && m_read_done) begin
                m_r_data_resp_sync <= m_r_data_storage;
                m_r_resp_resp_sync <= m_r_resp_storage;
                m_r_valid_resp_sync <= 1'b1;
                m_r_ready_resp_sync <= 1'b0;
            end else if (m_read_state == 2'b10 && m_read_done) begin
                m_r_valid_resp_sync <= 1'b0;
                m_r_ready_resp_sync <= 1'b1;
            end else begin
                m_r_ready_resp_sync <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Slave Side: Output Logic
    // ------------------------------------------------------------------
    assign s_axil_awready = (s_write_state == 2'b00);
    assign s_axil_wready = (s_write_state == 2'b00);
    assign s_axil_arready = (s_read_state == 2'b00);
    assign s_axil_rready = (m_read_state == 2'b00);

    assign s_axil_awaddr = s_write_addr;
    assign s_axil_awprot = s_write_prot;
    assign s_axil_wdata = s_w_data_sync;
    assign s_axil_wstrb = s_w_strb_sync;
    assign s_axil_bresp = s_b_resp_sync;
    assign s_axil_rdata = s_r_data_resp_sync;
    assign s_axil_rresp = s_r_resp_resp_sync;

    // ------------------------------------------------------------------
    // Master Side: Output Logic
    // ------------------------------------------------------------------
    assign m_axil_awaddr = m_write_addr;
    assign m_axil_awprot = m_write_prot;
    assign m_axil_wdata = m_w_data_sync;
    assign m_axil_wstrb = m_w_strb_sync;
    assign m_axil_bresp = m_b_resp_sync;
    assign m_axil_araddr = m_read_addr;
    assign m_axil_arprot = m_read_prot;
    assign m_axil_rdata = m_r_data_resp_sync;
    assign m_axil_rresp = m_r_resp_resp_sync;

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Handshake Logic
    // ------------------------------------------------------------------
    // Slave Write Valid/Ready
    assign s_axil_awvalid = s_write_valid;
    assign s_axil_wvalid = s_write_valid;
    assign s_axil_arvalid = s_read_valid;
    assign s_axil_rvalid = m_read_valid;

    assign s_axil_bready = s_b_ready_sync;
    assign s_axil_rready = s_r_ready_resp_sync;

    // Master Write Valid/Ready
    assign m_axil_awvalid = m_write_valid;
    assign m_axil_wvalid = m_write_valid;
    assign m_axil_arvalid = m_read_valid;
    assign m_axil_bvalid = m_b_valid_sync;
    assign m_axil_rvalid = m_r_valid_resp_sync;

    assign m_axil_awready = m_aw_ready_sync;
    assign m_axil_wready = m_w_ready_sync;
    assign m_axil_arready = m_ar_ready_sync;
    assign m_axil_bready = m_b_ready_sync;
    assign m_axil_rready = m_r_ready_resp_sync;

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Handshake State Updates
    // ------------------------------------------------------------------
    // Slave Write State Machine (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_write_state <= 2'b00;
            s_write_valid <= 1'b0;
            s_write_ready <= 1'b1;
            s_write_done <= 1'b0;
        end else begin
            case (s_write_state)
                2'b00: begin
                    if (s_axil_awvalid & s_axil_awready & s_axil_wvalid & s_axil_wready) begin
                        s_write_state <= 2'b01;
                        s_write_valid <= 1'b1;
                        s_write_ready <= 1'b0;
                    end else begin
                        s_write_ready <= 1'b1;
                    end
                end
                2'b01: begin
                    if (m_axil_wready) begin
                        s_write_state <= 2'b10;
                    end
                    s_write_ready <= 1'b0;
                end
                2'b10: begin
                    if (m_axil_wvalid) begin
                        s_write_state <= 2'b00;
                        s_write_valid <= 1'b0;
                        s_write_ready <= 1'b1;
                        s_write_done <= 1'b1;
                    end
                end
                default: begin
                    s_write_state <= 2'b00;
                    s_write_valid <= 1'b0;
                    s_write_ready <= 1'b1;
                    s_write_done <= 1'b0;
                end
            endcase
        end
    end

    // Slave Read State Machine (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_read_state <= 2'b00;
            s_read_valid <= 1'b0;
            s_read_ready <= 1'b1;
            s_read_done <= 1'b0;
        end else begin
            case (s_read_state)
                2'b00: begin
                    if (s_axil_arvalid & s_axil_arready) begin
                        s_read_state <= 2'b01;
                        s_read_valid <= 1'b1;
                        s_read_ready <= 1'b0;
                    end else begin
                        s_read_ready <= 1'b1;
                    end
                end
                2'b01: begin
                    if (m_axil_rready) begin
                        s_read_state <= 2'b10;
                    end
                    s_read_ready <= 1'b0;
                end
                2'b10: begin
                    if (m_axil_rvalid) begin
                        s_read_state <= 2'b00;
                        s_read_valid <= 1'b0;
                        s_read_ready <= 1'b1;
                        s_read_done <= 1'b1;
                    end
                end
                default: begin
                    s_read_state <= 2'b00;
                    s_read_valid <= 1'b0;
                    s_read_ready <= 1'b1;
                    s_read_done <= 1'b0;
                end
            endcase
        end
    end

    // Master Write State Machine (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_write_state <= 2'b00;
            m_write_valid <= 1'b0;
            m_write_ready <= 1'b1;
            m_write_done <= 1'b0;
        end else begin
            case (m_write_state)
                2'b00: begin
                    if (s_axil_wready) begin
                        m_write_state <= 2'b01;
                        m_write_valid <= 1'b1;
                        m_write_ready <= 1'b0;
                    end else begin
                        m_write_ready <= 1'b1;
                    end
                end
                2'b01: begin
                    if (s_axil_wready) begin
                        m_write_state <= 2'b10;
                    end
                    m_write_ready <= 1'b0;
                end
                2'b10: begin
                    if (s_axil_wvalid) begin
                        m_write_state <= 2'b00;
                        m_write_valid <= 1'b0;
                        m_write_ready <= 1'b1;
                        m_write_done <= 1'b1;
                    end
                end
                default: begin
                    m_write_state <= 2'b00;
                    m_write_valid <= 1'b0;
                    m_write_ready <= 1'b1;
                    m_write_done <= 1'b0;
                end
            endcase
        end
    end

    // Master Read State Machine (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_read_state <= 2'b00;
            m_read_valid <= 1'b0;
            m_read_ready <= 1'b1;
            m_read_done <= 1'b0;
        end else begin
            case (m_read_state)
                2'b00: begin
                    if (s_axil_rready) begin
                        m_read_state <= 2'b01;
                        m_read_valid <= 1'b1;
                        m_read_ready <= 1'b0;
                    end else begin
                        m_read_ready <= 1'b1;
                    end
                end
                2'b01: begin
                    if (s_axil_rready) begin
                        m_read_state <= 2'b10;
                    end
                    m_read_ready <= 1'b0;
                end
                2'b10: begin
                    if (s_axil_rvalid) begin
                        m_read_state <= 2'b00;
                        m_read_valid <= 1'b0;
                        m_read_ready <= 1'b1;
                        m_read_done <= 1'b1;
                    end
                end
                default: begin
                    m_read_state <= 2'b00;
                    m_read_valid <= 1'b0;
                    m_read_ready <= 1'b1;
                    m_read_done <= 1'b0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // CDC: Cross Clock Domain Handshake State Updates (Continued)
    // ------------------------------------------------------------------
    // Slave Write Response State Machine (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_resp_storage <= '0;
            s_b_valid_storage <= 1'b0;
            s_b_ready_storage <= 1'b1;
        end else begin
            if (s_write_state == 2'b01 && s_write_done) begin
                s_b_resp_storage <= s_axil_bresp;
                s_b_valid_storage <= 1'b1;
                s_b_ready_storage <= 1'b0;
            end else if (s_write_state == 2'b10 && s_write_done) begin
                s_b_valid_storage <= 1'b0;
                s_b_ready_storage <= 1'b1;
            end else begin
                s_b_ready_storage <= 1'b1;
            end
        end
    end

    // Master Write Response State Machine (m_clk)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_resp_storage <= '0;
            m_b_valid_storage <= 1'b0;
            m_b_ready_storage <= 1'b1;
        end else begin
            if (m_write_state == 2'b01 && m_write_done) begin
                m_b_resp_storage <= m_axil_bresp;
                m_b_valid_storage <= 1'b1;
                m_b_ready_storage <= 1'b0;
            end else if (m_write_state == 2'b10 && m_write_done) begin
                m_b_valid_storage <= 1'b0;
                m_b_ready_storage <= 1'b1;
            end else begin
                m_b_ready_storage <= 1'b1;
            end
        end
    end

    // Slave Read Response State Machine (s_clk)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_storage <= '0;
            s_r_resp_storage <= '0;
            s_r_valid_storage <= 1'b0;
            s_r_ready_storage <= 1'b1;
        end else begin
            if (s_read_state == 2'b01 && s_read_done) begin
                s_r_data_storage <= m_axil_rdata;
                s_r_resp_storage <= m_axil_rresp;
                s_r_valid_storage <= 1'b1;
                s_r_ready_storage <= 1'b0;
            end else if (s_read_state == 2'b10 && s_read_done) begin
                s_r_valid_storage <= 1'b0;
                s_r_ready_storage <= 1'b1;