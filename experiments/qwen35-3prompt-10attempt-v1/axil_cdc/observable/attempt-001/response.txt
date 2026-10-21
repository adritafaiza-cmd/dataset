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
    wire [ADDR_WIDTH-1:0] s_awaddr, s_araddr;
    wire [2:0]            s_awprot, s_arprot;
    wire [DATA_WIDTH-1:0] s_wdata;
    wire [STRB_WIDTH-1:0] s_wstrb;
    wire                  s_wvalid;
    wire [1:0]            s_bresp, s_rresp;
    wire                  s_bvalid, s_rvalid;
    wire                  s_awready, s_arready, s_wready, s_bready, s_rready;

    wire [ADDR_WIDTH-1:0] m_awaddr, m_araddr;
    wire [2:0]            m_awprot, m_arprot;
    wire [DATA_WIDTH-1:0] m_wdata;
    wire [STRB_WIDTH-1:0] m_wstrb;
    wire                  m_wvalid;
    wire [1:0]            m_bresp, m_rresp;
    wire                  m_bvalid, m_rvalid;
    wire                  m_awready, m_arready, m_wready, m_bready, m_rready;

    // CDC Registers for Slave -> Master (Write Address, Read Address, Protocols)
    reg [ADDR_WIDTH-1:0] s2m_awaddr, s2m_araddr;
    reg [2:0]            s2m_awprot, s2m_arprot;
    reg [DATA_WIDTH-1:0] s2m_wdata;
    reg [STRB_WIDTH-1:0] s2m_wstrb;
    reg                  s2m_wvalid;
    reg [1:0]            s2m_bresp, s2m_rresp;
    reg                  s2m_bvalid, s2m_rvalid;
    reg                  s2m_awready, s2m_arready, s2m_wready, s2m_bready, s2m_rready;

    // CDC Registers for Master -> Slave (Write Address, Read Address, Protocols)
    reg [ADDR_WIDTH-1:0] m2s_awaddr, m2s_araddr;
    reg [2:0]            m2s_awprot, m2s_arprot;
    reg [DATA_WIDTH-1:0] m2s_wdata;
    reg [STRB_WIDTH-1:0] m2s_wstrb;
    reg                  m2s_wvalid;
    reg [1:0]            m2s_bresp, m2s_rresp;
    reg                  m2s_bvalid, m2s_rvalid;
    reg                  m2s_awready, m2s_arready, m2s_wready, m2s_bready, m2s_rready;

    // Transaction State Machines
    // Write Transaction State
    reg [2:0] s_write_state; // 0:Idle, 1:AW, 2:W, 3:B
    reg [2:0] m_write_state; // 0:Idle, 1:AW, 2:W, 3:B
    reg [ADDR_WIDTH-1:0] s_write_addr;
    reg [2:0]            s_write_prot;
    reg [DATA_WIDTH-1:0] s_write_data;
    reg [STRB_WIDTH-1:0] s_write_strb;
    reg                  s_write_valid;
    reg [1:0]            s_write_resp;
    reg                  s_write_done;

    reg [2:0] m_write_state; // 0:Idle, 1:AW, 2:W, 3:B
    reg [ADDR_WIDTH-1:0] m_write_addr;
    reg [2:0]            m_write_prot;
    reg [DATA_WIDTH-1:0] m_write_data;
    reg [STRB_WIDTH-1:0] m_write_strb;
    reg                  m_write_valid;
    reg [1:0]            m_write_resp;
    reg                  m_write_done;

    // Read Transaction State
    reg [2:0] s_read_state;   // 0:Idle, 1:AR, 2:R
    reg [2:0] m_read_state;   // 0:Idle, 1:AR, 2:R
    reg [ADDR_WIDTH-1:0] s_read_addr;
    reg [2:0]            s_read_prot;
    reg [DATA_WIDTH-1:0] s_read_data;
    reg [1:0]            s_read_resp;
    reg                  s_read_valid;
    reg                  s_read_done;

    reg [2:0] m_read_state;   // 0:Idle, 1:AR, 2:R
    reg [ADDR_WIDTH-1:0] m_read_addr;
    reg [2:0]            m_read_prot;
    reg [DATA_WIDTH-1:0] m_read_data;
    reg [1:0]            m_read_resp;
    reg                  m_read_valid;
    reg                  m_read_done;

    // -----------------------------------------------------------------------
    // Clock Domain Crossing: Slave -> Master (Write Path)
    // -----------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr    <= {ADDR_WIDTH{1'b0}};
            s2m_awprot    <= 3'b000;
            s2m_wdata     <= {DATA_WIDTH{1'b0}};
            s2m_wstrb     <= {STRB_WIDTH{1'b0}};
            s2m_wvalid    <= 1'b0;
            s2m_bresp     <= 2'b00;
            s2m_rresp     <= 2'b00;
            s2m_bvalid    <= 1'b0;
            s2m_rvalid    <= 1'b0;
            s2m_awready   <= 1'b1;
            s2m_arready   <= 1'b1;
            s2m_wready    <= 1'b1;
            s2m_bready    <= 1'b1;
            s2m_rready    <= 1'b1;
            s_write_state <= 3'b000;
            s_write_done  <= 1'b0;
        end else begin
            // Update ready signals based on master side
            s2m_awready <= m_axil_awready;
            s2m_arready <= m_axil_arready;
            s2m_wready  <= m_axil_wready;
            s2m_bready  <= m_axil_bready;
            s2m_rready  <= m_axil_rready;

            // Capture Write Address
            if (s_axil_awvalid && s_axil_awready) begin
                s2m_awaddr    <= s_axil_awaddr;
                s2m_awprot    <= s_axil_awprot;
                s_write_state <= 3'b001; // AW State
                s_write_addr  <= s_axil_awaddr;
                s_write_prot  <= s_axil_awprot;
            end

            // Capture Write Data
            if (s_axil_wvalid && s_axil_wready) begin
                s2m_wdata     <= s_axil_wdata;
                s2m_wstrb     <= s_axil_wstrb;
                s_write_state <= 3'b010; // W State
                s_write_data  <= s_axil_wdata;
                s_write_strb  <= s_axil_wstrb;
            end

            // Capture Write Response
            if (s_axil_bvalid && s_axil_bready) begin
                s2m_bresp     <= s_axil_bresp;
                s_write_state <= 3'b011; // B State
                s_write_resp  <= s_axil_bresp;
            end

            // Capture Read Address
            if (s_axil_arvalid && s_axil_arready) begin
                s2m_araddr    <= s_axil_araddr;
                s2m_arprot    <= s_axil_arprot;
                s_read_state  <= 3'b001; // AR State
                s_read_addr   <= s_axil_araddr;
                s_read_prot   <= s_axil_arprot;
            end

            // Capture Read Data
            if (s_axil_rvalid && s_axil_rready) begin
                s2m_rdata     <= s_axil_rdata;
                s2m_rresp     <= s_axil_rresp;
                s_read_state  <= 3'b010; // R State
                s_read_data   <= s_axil_rdata;
                s_read_resp   <= s_axil_rresp;
            end

            // Capture Read Response
            if (s_axil_bvalid && s_axil_bready) begin
                s2m_bresp     <= s_axil_bresp;
                s_read_state  <= 3'b011; // B State
                s_read_resp   <= s_axil_bresp;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Clock Domain Crossing: Master -> Slave (Write Path)
    // -----------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_awaddr    <= {ADDR_WIDTH{1'b0}};
            m2s_awprot    <= 3'b000;
            m2s_wdata     <= {DATA_WIDTH{1'b0}};
            m2s_wstrb     <= {STRB_WIDTH{1'b0}};
            m2s_wvalid    <= 1'b0;
            m2s_bresp     <= 2'b00;
            m2s_rresp     <= 2'b00;
            m2s_bvalid    <= 1'b0;
            m2s_rvalid    <= 1'b0;
            m2s_awready   <= 1'b1;
            m2s_arready   <= 1'b1;
            m2s_wready    <= 1'b1;
            m2s_bready    <= 1'b1;
            m2s_rready    <= 1'b1;
            m_write_state <= 3'b000;
            m_write_done  <= 1'b0;
        end else begin
            // Update ready signals based on slave side
            m2s_awready <= s_axil_awready;
            m2s_arready <= s_axil_arready;
            m2s_wready  <= s_axil_wready;
            m2s_bready  <= s_axil_bready;
            m2s_rready  <= s_axil_rready;

            // Capture Write Address
            if (m_axil_awvalid && m_axil_awready) begin
                m2s_awaddr    <= m_axil_awaddr;
                m2s_awprot    <= m_axil_awprot;
                m_write_state <= 3'b001; // AW State
                m_write_addr  <= m_axil_awaddr;
                m_write_prot  <= m_axil_awprot;
            end

            // Capture Write Data
            if (m_axil_wvalid && m_axil_wready) begin
                m2s_wdata     <= m_axil_wdata;
                m2s_wstrb     <= m_axil_wstrb;
                m_write_state <= 3'b010; // W State
                m_write_data  <= m_axil_wdata;
                m_write_strb  <= m_axil_wstrb;
            end

            // Capture Write Response
            if (m_axil_bvalid && m_axil_bready) begin
                m2s_bresp     <= m_axil_bresp;
                m_write_state <= 3'b011; // B State
                m_write_resp  <= m_axil_bresp;
            end

            // Capture Read Address
            if (m_axil_arvalid && m_axil_arready) begin
                m2s_araddr    <= m_axil_araddr;
                m2s_arprot    <= m_axil_arprot;
                m_read_state  <= 3'b001; // AR State
                m_read_addr   <= m_axil_araddr;
                m_read_prot   <= m_axil_arprot;
            end

            // Capture Read Data
            if (m_axil_rvalid && m_axil_rready) begin
                m2s_rdata     <= m_axil_rdata;
                m2s_rresp     <= m_axil_rresp;
                m_read_state  <= 3'b010; // R State
                m_read_data   <= m_axil_rdata;
                m_read_resp   <= m_axil_rresp;
            end

            // Capture Read Response
            if (m_axil_bvalid && m_axil_bready) begin
                m2s_bresp     <= m_axil_bresp;
                m_read_state  <= 3'b011; // B State
                m_read_resp   <= m_axil_bresp;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Slave Side Logic (s_clk domain)
    // -----------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_bresp   <= 2'b00;
            s_axil_rresp   <= 2'b00;
            s_axil_rdata   <= {DATA_WIDTH{1'b0}};
            s_write_state  <= 3'b000;
            s_read_state   <= 3'b000;
            s_write_done   <= 1'b0;
            s_read_done    <= 1'b0;
        end else begin
            // Write Address Ready
            if (s_write_state == 3'b000) begin
                s_axil_awready <= 1'b1;
            end else begin
                s_axil_awready <= 1'b0;
            end

            // Write Data Ready
            if (s_write_state == 3'b001) begin
                s_axil_wready <= 1'b1;
            end else begin
                s_axil_wready <= 1'b0;
            end

            // Write Response Valid
            if (s_write_state == 3'b011) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= s2m_bresp;
            end else begin
                s_axil_bvalid <= 1'b0;
                s_axil_bresp  <= 2'b00;
            end

            // Read Address Ready
            if (s_read_state == 3'b000) begin
                s_axil_arready <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
            end

            // Read Data Valid
            if (s_read_state == 3'b010) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rdata  <= s2m_rdata;
                s_axil_rresp  <= s2m_rresp;
            end else begin
                s_axil_rvalid <= 1'b0;
                s_axil_rdata  <= {DATA_WIDTH{1'b0}};
                s_axil_rresp  <= 2'b00;
            end

            // Read Response Valid
            if (s_read_state == 3'b011) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= s2m_bresp;
            end else begin
                s_axil_bvalid <= 1'b0;
                s_axil_bresp  <= 2'b00;
            end

            // State Machine: Write
            case (s_write_state)
                3'b000: begin // Idle
                    if (s_axil_awvalid && s_axil_awready) begin
                        s_write_state <= 3'b001;
                    end
                end
                3'b001: begin // AW
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_write_state <= 3'b010;
                    end
                end
                3'b010: begin // W
                    if (s_axil_bvalid && s_axil_bready) begin
                        s_write_state <= 3'b011;
                    end
                end
                3'b011: begin // B
                    s_write_state <= 3'b000;
                end
            endcase

            // State Machine: Read
            case (s_read_state)
                3'b000: begin // Idle
                    if (s_axil_arvalid && s_axil_arready) begin
                        s_read_state <= 3'b001;
                    end
                end
                3'b001: begin // AR
                    if (s_axil_rvalid && s_axil_rready) begin
                        s_read_state <= 3'b010;
                    end
                end
                3'b010: begin // R
                    if (s_axil_bvalid && s_axil_bready) begin
                        s_read_state <= 3'b011;
                    end
                end
                3'b011: begin // B
                    s_read_state <= 3'b000;
                end
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Master Side Logic (m_clk domain)
    // -----------------------------------------------------------------------
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_awready <= 1'b0;
            m_axil_wready  <= 1'b0;
            m_axil_bvalid  <= 1'b0;
            m_axil_arready <= 1'b0;
            m_axil_rvalid  <= 1'b0;
            m_axil_bresp   <= 2'b00;
            m_axil_rresp   <= 2'b00;
            m_axil_rdata   <= {DATA_WIDTH{1'b0}};
            m_write_state  <= 3'b000;
            m_read_state   <= 3'b000;
            m_write_done   <= 1'b0;
            m_read_done    <= 1'b0;
        end else begin
            // Write Address Ready
            if (m_write_state == 3'b000) begin
                m_axil_awready <= 1'b1;
            end else begin
                m_axil_awready <= 1'b0;
            end

            // Write Data Ready
            if (m_write_state == 3'b001) begin
                m_axil_wready <= 1'b1;
            end else begin
                m_axil_wready <= 1'b0;
            end

            // Write Response Valid
            if (m_write_state == 3'b011) begin
                m_axil_bvalid <= 1'b1;
                m_axil_bresp  <= m2s_bresp;
            end else begin
                m_axil_bvalid <= 1'b0;
                m_axil_bresp  <= 2'b00;
            end

            // Read Address Ready
            if (m_read_state == 3'b000) begin
                m_axil_arready <= 1'b1;
            end else begin
                m_axil_arready <= 1'b0;
            end

            // Read Data Valid
            if (m_read_state == 3'b010) begin
                m_axil_rvalid <= 1'b1;
                m_axil_rdata  <= m2s_rdata;
                m_axil_rresp  <= m2s_rresp;
            end else begin
                m_axil_rvalid <= 1'b0;
                m_axil_rdata  <= {DATA_WIDTH{1'b0}};
                m_axil_rresp  <= 2'b00;
            end

            // Read Response Valid
            if (m_read_state == 3'b011) begin
                m_axil_bvalid <= 1'b1;
                m_axil_bresp  <= m2s_bresp;
            end else begin
                m_axil_bvalid <= 1'b0;
                m_axil_bresp  <= 2'b00;
            end

            // State Machine: Write
            case (m_write_state)
                3'b000: begin // Idle
                    if (m_axil_awvalid && m_axil_awready) begin
                        m_write_state <= 3'b001;
                    end
                end
                3'b001: begin // AW
                    if (m_axil_wvalid && m_axil_wready) begin
                        m_write_state <= 3'b010;
                    end
                end
                3'b010: begin // W
                    if (m_axil_bvalid && m_axil_bready) begin
                        m_write_state <= 3'b011;
                    end
                end
                3'b011: begin // B
                    m_write_state <= 3'b000;
                end
            endcase

            // State Machine: Read
            case (m_read_state)
                3'b000: begin // Idle
                    if (m_axil_arvalid && m_axil_arready) begin
                        m_read_state <= 3'b001;
                    end
                end
                3'b001: begin // AR
                    if (m_axil_rvalid && m_axil_rready) begin
                        m_read_state <= 3'b010;
                    end
                end
                3'b010: begin // R
                    if (m_axil_bvalid && m_axil_bready) begin
                        m_read_state <= 3'b011;
                    end
                end
                3'b011: begin // B
                    m_read_state <= 3'b000;
                end
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Output Assignments
    // -----------------------------------------------------------------------
    assign s_axil_awaddr = s2m_awaddr;
    assign s_axil_awprot = s2m_awprot;
    assign s_axil_wdata  = s2m_wdata;
    assign s_axil_wstrb  = s2m_wstrb;
    assign s_axil_bresp  = s2m_bresp;
    assign s_axil_araddr = s2m_araddr;
    assign s_axil_arprot = s2m_arprot;
    assign s_axil_rdata  = s2m_rdata;
    assign s_axil_rresp  = s2m_rresp;

    assign m_axil_awaddr = m2s_awaddr;
    assign m_axil_awprot = m2s_awprot;
    assign m_axil_wdata  = m2s_wdata;
    assign m_axil_wstrb  = m2s_wstrb;
    assign m_axil_bresp  = m2s_bresp;
    assign m_axil_araddr = m2s_araddr;
    assign m_axil_arprot = m2s_arprot;
    assign m_axil_rdata  = m2s_rdata;
    assign m_axil_rresp  = m2s_rresp;

    // -----------------------------------------------------------------------
    // Final Output Logic (Combining State Machine with CDC Registers)
    // This block drives the actual AXI signals based on the internal state
    // and the CDC registered values.
    // -----------------------------------------------------------------------

    // Slave Outputs
    assign s_axil_awready = (s_write_state == 3'b000) ? 1'b1 : 1'b0;
    assign s_axil_wready  = (s_write_state == 3'b001) ? 1'b1 : 1'b0;
    assign s_axil_bvalid  = (s_write_state == 3'b011) ? 1'b1 : 1'b0;
    assign s_axil_bresp   = (s_write_state == 3'b011) ? s2m_bresp : 2'b00;
    assign s_axil_arready = (s_read_state == 3'b000) ? 1'b1 : 1'b0;
    assign s_axil_rvalid  = (s_read_state == 3'b010) ? 1'b1 : 1'b0;
    assign s_axil_rdata   = (s_read_state == 3'b010) ? s2m_rdata : {DATA_WIDTH{1'b0}};
    assign s_axil_rresp   = (s_read_state == 3'b010) ? s2m_rresp : 2'b00;
    assign s_axil_bresp   = (s_read_state == 3'b011) ? s2m_bresp : 2'b00;

    // Master Outputs
    assign m_axil_awready = (m_write_state == 3'b000) ? 1'b1 : 1'b0;
    assign m_axil_wready  = (m_write_state == 3'b001) ? 1'b1 : 1'b0;
    assign m_axil_bvalid  = (m_write_state == 3'b011) ? 1'b1 : 1'b0;
    assign m_axil_bresp   = (m_write_state == 3'b011) ? m2s_bresp : 2'b00;
    assign m_axil_arready = (m_read_state == 3'b000) ? 1'b1 : 1'b0;
    assign m_axil_rvalid  = (m_read_state == 3'b010) ? 1'b1 : 1'b0;
    assign m_axil_rdata   = (m_read_state == 3'b010) ? m2s_rdata : {DATA_WIDTH{1'b0}};
    assign m_axil_rresp   = (m_read_state == 3'b010) ? m2s_rresp : 2'b00;
    assign m_axil_bresp   = (m_read_state == 3'b011) ? m2s_bresp : 2'b00;

    // Drive the CDC registers from the slave inputs
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr    <= {ADDR_WIDTH{1'b0}};
            s2m_awprot    <= 3'b000;
            s2m_wdata     <= {DATA_WIDTH{1'b0}};
            s2m_wstrb     <= {STRB_WIDTH{1'b0}};
            s2m_wvalid    <= 1'b0;
            s2m_bresp     <= 2'b00;
            s2m_rresp     <= 2'b00;
            s2m_bvalid    <= 1'b0;
            s2m_rvalid    <= 1'b0;
            s2m_awready   <= 1'b1;
            s2m_arready   <= 1'b1;
            s2m_wready    <= 1'b1;
            s2m_bready    <= 1'b1;
            s2m_rready    <= 1'b1;
        end else begin
            s2m_awaddr    <= s_axil_awaddr;
            s2m_awprot    <= s_axil_awprot;
            s2m_wdata     <= s_axil_wdata;
            s2m_wstrb     <= s_axil_wstrb;
            s2m_wvalid    <= s_axil_wvalid;
            s2m_bresp     <= s_axil_bresp;
            s2m_rresp     <= s_axil_rresp;
            s2m_bvalid    <= s_axil_bvalid;
            s2m_rvalid    <= s_axil_rvalid;
            s2m_awready   <= s_axil_awready;
            s2m_arready   <= s_axil_arready;
            s2m_wready    <= s_axil_wready;
            s2m_bready    <= s_axil_bready;
            s2m_rready    <= s_axil_rready;
        end
    end

    // Drive the CDC registers from the master inputs
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_awaddr    <= {ADDR_WIDTH{1'b0}};
            m2s_awprot    <= 3'b000;
            m2s_wdata     <= {DATA_WIDTH{1'b0}};
            m2s_wstrb     <= {STRB_WIDTH{1'b0}};
            m2s_wvalid    <= 1'b0;
            m2s_bresp     <= 2'b00;
            m2s_rresp     <= 2'b00;
            m2s_bvalid    <= 1'b0;
            m2s_rvalid    <= 1'b0;
            m2s_awready   <= 1'b1;
            m2s_arready   <= 1'b1;
            m2s_wready    <= 1'b1;
            m2s_bready    <= 1'b1;
            m2s_rready    <= 1'b1;
        end else begin
            m2s_awaddr    <= m_axil_awaddr;
            m2s_awprot    <= m_axil_awprot;
            m2s_wdata     <= m_axil_wdata;
            m2s_wstrb     <= m_axil_wstrb;
            m2s_wvalid    <= m_axil_wvalid;
            m2s_bresp     <= m_axil_bresp;
            m2s_rresp     <= m_axil_rresp;
            m2s_bvalid    <= m_axil_bvalid;
            m2s_rvalid    <= m_axil_rvalid;
            m2s_awready   <= m_axil_awready;
            m2s_arready   <= m_axil_arready;
            m2s_wready    <= m_axil_wready;
            m2s_bready    <= m_axil_bready;
            m2s_rready    <= m_axil_rready;
        end
    end

    // -----------------------------------------------------------------------
    // Final Output Logic (Driving the external ports)
    // -----------------------------------------------------------------------
    assign s_axil_awaddr = s2m_awaddr;
    assign s_axil_awprot = s2m_awprot;
    assign s_axil_wdata  = s2m_wdata;
    assign s_axil_wstrb  = s2m_wstrb;
    assign s_axil_bresp  = s2m_bresp;
    assign s_axil_araddr = s2m_araddr;
    assign s_axil_arprot = s2m_arprot;
    assign s_axil_rdata  = s2m_rdata;
    assign s_axil_rresp  = s2m_rresp;

    assign m_axil_awaddr = m2s_awaddr;
    assign m_axil_awprot = m2s_awprot;
    assign m_axil_wdata  = m2s_wdata;
    assign m_axil_wstrb  = m2s_wstrb;
    assign m_axil_bresp  = m2s_bresp;
    assign m_axil_araddr = m2s_araddr;
    assign m_axil_arprot = m2s_arprot;
    assign m_axil_rdata  = m2s_rdata;
    assign m_axil_rresp  = m2s_rresp;

    // -----------------------------------------------------------------------
    // State Machine Logic (Slave Side)
    // -----------------------------------------------------------------------
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_write_state <= 3'b000;
            s_read_state  <= 3'b000;
        end else begin
            // Write State Machine
            case (s_write_state)
                3'b000: if (s_axil_awvalid && s_axil_awready) s_write_state <= 3'b001;
                3'b001: if (s_axil_wvalid && s_axil_wready) s_write_state <= 3'b010;
                3'b010