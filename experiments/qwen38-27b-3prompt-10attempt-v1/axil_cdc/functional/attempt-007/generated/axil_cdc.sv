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

    // Internal signals for write address channel
    wire [ADDR_WIDTH-1:0] s_awaddr_reg;
    wire [2:0]            s_awprot_reg;
    wire                  s_awvalid_reg;
    wire                  s_awready_reg;
    wire                  s_aw_handshake;
    wire                  s_aw_pulse;
    wire                  m_aw_pulse;
    wire                  m_aw_valid;
    wire                  m_aw_ready;
    wire                  m_aw_handshake;

    // Internal signals for write data channel
    wire [DATA_WIDTH-1:0] s_wdata_reg;
    wire [STRB_WIDTH-1:0] s_wstrb_reg;
    wire                  s_wvalid_reg;
    wire                  s_wready_reg;
    wire                  s_w_handshake;
    wire                  s_w_pulse;
    wire                  m_w_pulse;
    wire                  m_w_valid;
    wire                  m_w_ready;
    wire                  m_w_handshake;

    // Internal signals for write response channel
    wire [1:0]            s_bresp_reg;
    wire                  s_bvalid_reg;
    wire                  s_bready_reg;
    wire                  s_b_handshake;
    wire                  s_b_pulse;
    wire                  m_b_pulse;
    wire                  m_b_valid;
    wire                  m_b_ready;
    wire                  m_b_handshake;

    // Internal signals for read address channel
    wire [ADDR_WIDTH-1:0] s_araddr_reg;
    wire [2:0]            s_arprot_reg;
    wire                  s_arvalid_reg;
    wire                  s_arready_reg;
    wire                  s_ar_handshake;
    wire                  s_ar_pulse;
    wire                  m_ar_pulse;
    wire                  m_ar_valid;
    wire                  m_ar_ready;
    wire                  m_ar_handshake;

    // Internal signals for read data channel
    wire [DATA_WIDTH-1:0] s_rdata_reg;
    wire [1:0]            s_rresp_reg;
    wire                  s_rvalid_reg;
    wire                  s_rready_reg;
    wire                  s_r_handshake;
    wire                  s_r_pulse;
    wire                  m_r_pulse;
    wire                  m_r_valid;
    wire                  m_r_ready;
    wire                  m_r_handshake;

    // State registers for write address
    reg                   s_aw_pending;
    reg                   s_aw_sent;
    reg                   s_aw_ack;

    // State registers for write data
    reg                   s_w_pending;
    reg                   s_w_sent;
    reg                   s_w_ack;

    // State registers for write response
    reg                   s_b_pending;
    reg                   s_b_sent;
    reg                   s_b_ack;

    // State registers for read address
    reg                   s_ar_pending;
    reg                   s_ar_sent;
    reg                   s_ar_ack;

    // State registers for read data
    reg                   s_r_pending;
    reg                   s_r_sent;
    reg                   s_r_ack;

    // Master side state registers
    reg                   m_aw_pending;
    reg                   m_aw_sent;
    reg                   m_aw_ack;
    reg                   m_w_pending;
    reg                   m_w_sent;
    reg                   m_w_ack;
    reg                   m_b_pending;
    reg                   m_b_sent;
    reg                   m_b_ack;
    reg                   m_ar_pending;
    reg                   m_ar_sent;
    reg                   m_ar_ack;
    reg                   m_r_pending;
    reg                   m_r_sent;
    reg                   m_r_ack;

    // Synchronizer for write address pulse
    reg [2:0] s_aw_sync;
    wire      s_aw_sync_pulse;

    // Synchronizer for write data pulse
    reg [2:0] s_w_sync;
    wire      s_w_sync_pulse;

    // Synchronizer for write response pulse
    reg [2:0] s_b_sync;
    wire      s_b_sync_pulse;

    // Synchronizer for read address pulse
    reg [2:0] s_ar_sync;
    wire      s_ar_sync_pulse;

    // Synchronizer for read data pulse
    reg [2:0] s_r_sync;
    wire      s_r_sync_pulse;

    // Synchronizer for master write address pulse
    reg [2:0] m_aw_sync;
    wire      m_aw_sync_pulse;

    // Synchronizer for master write data pulse
    reg [2:0] m_w_sync;
    wire      m_w_sync_pulse;

    // Synchronizer for master write response pulse
    reg [2:0] m_b_sync;
    wire      m_b_sync_pulse;

    // Synchronizer for master read address pulse
    reg [2:0] m_ar_sync;
    wire      m_ar_sync_pulse;

    // Synchronizer for master read data pulse
    reg [2:0] m_r_sync;
    wire      m_r_sync_pulse;

    // Slave side: Write Address Channel
    assign s_axil_awready = s_awready_reg;
    assign s_aw_handshake = s_axil_awvalid & s_axil_awready;
    assign s_aw_pulse = s_aw_handshake;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s_awprot_reg <= 3'b000;
            s_awvalid_reg <= 1'b0;
            s_awready_reg <= 1'b0;
            s_aw_pending  <= 1'b0;
            s_aw_sent     <= 1'b0;
            s_aw_ack      <= 1'b0;
        end else begin
            if (s_aw_handshake) begin
                s_awaddr_reg  <= s_axil_awaddr;
                s_awprot_reg  <= s_axil_awprot;
                s_awvalid_reg <= 1'b1;
                s_aw_pending  <= 1'b1;
                s_aw_sent     <= 1'b0;
                s_aw_ack      <= 1'b0;
            end else if (s_aw_pending && s_aw_sent) begin
                s_awvalid_reg <= 1'b0;
                s_aw_pending  <= 1'b0;
                s_aw_sent     <= 1'b0;
                s_aw_ack      <= 1'b1;
            end else if (s_aw_pending && !s_aw_sent) begin
                s_aw_sent <= 1'b1;
            end
            s_awready_reg <= !s_aw_pending;
        end
    end

    // Slave side: Write Data Channel
    assign s_axil_wready = s_wready_reg;
    assign s_w_handshake = s_axil_wvalid & s_axil_wready;
    assign s_w_pulse = s_w_handshake;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_reg <= {DATA_WIDTH{1'b0}};
            s_wstrb_reg <= {STRB_WIDTH{1'b0}};
            s_wvalid_reg <= 1'b0;
            s_wready_reg <= 1'b0;
            s_w_pending  <= 1'b0;
            s_w_sent     <= 1'b0;
            s_w_ack      <= 1'b0;
        end else begin
            if (s_w_handshake) begin
                s_wdata_reg  <= s_axil_wdata;
                s_wstrb_reg  <= s_axil_wstrb;
                s_wvalid_reg <= 1'b1;
                s_w_pending  <= 1'b1;
                s_w_sent     <= 1'b0;
                s_w_ack      <= 1'b0;
            end else if (s_w_pending && s_w_sent) begin
                s_wvalid_reg <= 1'b0;
                s_w_pending  <= 1'b0;
                s_w_sent     <= 1'b0;
                s_w_ack      <= 1'b1;
            end else if (s_w_pending && !s_w_sent) begin
                s_w_sent <= 1'b1;
            end
            s_wready_reg <= !s_w_pending;
        end
    end

    // Slave side: Write Response Channel
    assign s_axil_bresp  = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    assign s_b_handshake = s_axil_bvalid & s_axil_bready;
    assign s_b_pulse = s_b_handshake;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg  <= 2'b00;
            s_bvalid_reg <= 1'b0;
            s_bready_reg <= 1'b0;
            s_b_pending  <= 1'b0;
            s_b_sent     <= 1'b0;
            s_b_ack      <= 1'b0;
        end else begin
            if (s_b_pending && s_b_sent) begin
                s_bvalid_reg <= 1'b0;
                s_b_pending  <= 1'b0;
                s_b_sent     <= 1'b0;
                s_b_ack      <= 1'b1;
            end else if (s_b_pending && !s_b_sent) begin
                s_b_sent <= 1'b1;
            end
            s_bready_reg <= !s_b_pending;
        end
    end

    // Slave side: Read Address Channel
    assign s_axil_arready = s_arready_reg;
    assign s_ar_handshake = s_axil_arvalid & s_axil_arready;
    assign s_ar_pulse = s_ar_handshake;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s_arprot_reg <= 3'b000;
            s_arvalid_reg <= 1'b0;
            s_arready_reg <= 1'b0;
            s_ar_pending  <= 1'b0;
            s_ar_sent     <= 1'b0;
            s_ar_ack      <= 1'b0;
        end else begin
            if (s_ar_handshake) begin
                s_araddr_reg  <= s_axil_araddr;
                s_arprot_reg  <= s_axil_arprot;
                s_arvalid_reg <= 1'b1;
                s_ar_pending  <= 1'b1;
                s_ar_sent     <= 1'b0;
                s_ar_ack      <= 1'b0;
            end else if (s_ar_pending && s_ar_sent) begin
                s_arvalid_reg <= 1'b0;
                s_ar_pending  <= 1'b0;
                s_ar_sent     <= 1'b0;
                s_ar_ack      <= 1'b1;
            end else if (s_ar_pending && !s_ar_sent) begin
                s_ar_sent <= 1'b1;
            end
            s_arready_reg <= !s_ar_pending;
        end
    end

    // Slave side: Read Data Channel
    assign s_axil_rdata  = s_rdata_reg;
    assign s_axil_rresp  = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;
    assign s_r_handshake = s_axil_rvalid & s_axil_rready;
    assign s_r_pulse = s_r_handshake;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_reg  <= {DATA_WIDTH{1'b0}};
            s_rresp_reg  <= 2'b00;
            s_rvalid_reg <= 1'b0;
            s_rready_reg <= 1'b0;
            s_r_pending  <= 1'b0;
            s_r_sent     <= 1'b0;
            s_r_ack      <= 1'b0;
        end else begin
            if (s_r_pending && s_r_sent) begin
                s_rvalid_reg <= 1'b0;
                s_r_pending  <= 1'b0;
                s_r_sent     <= 1'b0;
                s_r_ack      <= 1'b1;
            end else if (s_r_pending && !s_r_sent) begin
                s_r_sent <= 1'b1;
            end
            s_rready_reg <= !s_r_pending;
        end
    end

    // Master side: Write Address Channel
    assign m_axil_awaddr  = s_awaddr_reg;
    assign m_axil_awprot  = s_awprot_reg;
    assign m_axil_awvalid = m_aw_valid;
    assign m_aw_handshake = m_axil_awvalid & m_axil_awready;
    assign m_aw_pulse = m_aw_handshake;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_pending <= 1'b0;
            m_aw_sent    <= 1'b0;
            m_aw_ack     <= 1'b0;
        end else begin
            if (m_aw_pending && m_aw_sent) begin
                m_aw_pending <= 1'b0;
                m_aw_sent    <= 1'b0;
                m_aw_ack     <= 1'b1;
            end else if (m_aw_pending && !m_aw_sent) begin
                m_aw_sent <= 1'b1;
            end
        end
    end

    // Master side: Write Data Channel
    assign m_axil_wdata  = s_wdata_reg;
    assign m_axil_wstrb  = s_wstrb_reg;
    assign m_axil_wvalid = m_w_valid;
    assign m_w_handshake = m_axil_wvalid & m_axil_wready;
    assign m_w_pulse = m_w_handshake;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_pending <= 1'b0;
            m_w_sent    <= 1'b0;
            m_w_ack     <= 1'b0;
        end else begin
            if (m_w_pending && m_w_sent) begin
                m_w_pending <= 1'b0;
                m_w_sent    <= 1'b0;
                m_w_ack     <= 1'b1;
            end else if (m_w_pending && !m_w_sent) begin
                m_w_sent <= 1'b1;
            end
        end
    end

    // Master side: Write Response Channel
    assign m_axil_bready = m_b_ready;
    assign m_b_handshake = m_axil_bvalid & m_axil_bready;
    assign m_b_pulse = m_b_handshake;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_pending <= 1'b0;
            m_b_sent    <= 1'b0;
            m_b_ack     <= 1'b0;
        end else begin
            if (m_b_pending && m_b_sent) begin
                m_b_pending <= 1'b0;
                m_b_sent    <= 1'b0;
                m_b_ack     <= 1'b1;
            end else if (m_b_pending && !m_b_sent) begin
                m_b_sent <= 1'b1;
            end
        end
    end

    // Master side: Read Address Channel
    assign m_axil_araddr  = s_araddr_reg;
    assign m_axil_arprot  = s_arprot_reg;
    assign m_axil_arvalid = m_ar_valid;
    assign m_ar_handshake = m_axil_arvalid & m_axil_arready;
    assign m_ar_pulse = m_ar_handshake;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_pending <= 1'b0;
            m_ar_sent    <= 1'b0;
            m_ar_ack     <= 1'b0;
        end else begin
            if (m_ar_pending && m_ar_sent) begin
                m_ar_pending <= 1'b0;
                m_ar_sent    <= 1'b0;
                m_ar_ack     <= 1'b1;
            end else if (m_ar_pending && !m_ar_sent) begin
                m_ar_sent <= 1'b1;
            end
        end
    end

    // Master side: Read Data Channel
    assign m_axil_rready = m_r_ready;
    assign m_r_handshake = m_axil_rvalid & m_axil_rready;
    assign m_r_pulse = m_r_handshake;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_pending <= 1'b0;
            m_r_sent    <= 1'b0;
            m_r_ack     <= 1'b0;
        end else begin
            if (m_r_pending && m_r_sent) begin
                m_r_pending <= 1'b0;
                m_r_sent    <= 1'b0;
                m_r_ack     <= 1'b1;
            end else if (m_r_pending && !m_r_sent) begin
                m_r_sent <= 1'b1;
            end
        end
    end

    // Synchronizers for slave to master pulses
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_aw_sync <= 3'b000;
            s_w_sync  <= 3'b000;
            s_b_sync  <= 3'b000;
            s_ar_sync <= 3'b000;
            s_r_sync  <= 3'b000;
        end else begin
            s_aw_sync <= {s_aw_sync[1:0], s_aw_pulse};
            s_w_sync  <= {s_w_sync[1:0],  s_w_pulse};
            s_b_sync  <= {s_b_sync[1:0],  s_b_pulse};
            s_ar_sync <= {s_ar_sync[1:0], s_ar_pulse};
            s_r_sync  <= {s_r_sync[1:0],  s_r_pulse};
        end
    end

    assign s_aw_sync_pulse = s_aw_sync[2] & ~s_aw_sync[1];
    assign s_w_sync_pulse  = s_w_sync[2]  & ~s_w_sync[1];
    assign s_b_sync_pulse  = s_b_sync[2]  & ~s_b_sync[1];
    assign s_ar_sync_pulse = s_ar_sync[2] & ~s_ar_sync[1];
    assign s_r_sync_pulse  = s_r_sync[2]  & ~s_r_sync[1];

    // Synchronizers for master to slave pulses
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_aw_sync <= 3'b000;
            m_w_sync  <= 3'b000;
            m_b_sync  <= 3'b000;
            m_ar_sync <= 3'b000;
            m_r_sync  <= 3'b000;
        end else begin
            m_aw_sync <= {m_aw_sync[1:0], m_aw_pulse};
            m_w_sync  <= {m_w_sync[1:0],  m_w_pulse};
            m_b_sync  <= {m_b_sync[1:0],  m_b_pulse};
            m_ar_sync <= {m_ar_sync[1:0], m_ar_pulse};
            m_r_sync  <= {m_r_sync[1:0],  m_r_pulse};
        end
    end

    assign m_aw_sync_pulse = m_aw_sync[2] & ~m_aw_sync[1];
    assign m_w_sync_pulse  = m_w_sync[2]  & ~m_w_sync[1];
    assign m_b_sync_pulse  = m_b_sync[2]  & ~m_b_sync[1];
    assign m_ar_sync_pulse = m_ar_sync[2] & ~m_ar_sync[1];
    assign m_r_sync_pulse  = m_r_sync[2]  & ~m_r_sync[1];

    // Master side valid/ready generation
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_valid <= 1'b0;
            m_w_valid  <= 1'b0;
            m_b_ready  <= 1'b0;
            m_ar_valid <= 1'b0;
            m_r_ready  <= 1'b0;
        end else begin
            if (s_aw_sync_pulse) m_aw_valid <= 1'b1;
            if (m_aw_handshake)  m_aw_valid <= 1'b0;

            if (s_w_sync_pulse)  m_w_valid  <= 1'b1;
            if (m_w_handshake)   m_w_valid  <= 1'b0;

            if (s_b_sync_pulse)  m_b_ready  <= 1'b1;
            if (m_b_handshake)   m_b_ready  <= 1'b0;

            if (s_ar_sync_pulse) m_ar_valid <= 1'b1;
            if (m_ar_handshake)  m_ar_valid <= 1'b0;

            if (s_r_sync_pulse)  m_r_ready  <= 1'b1;
            if (m_r_handshake)   m_r_ready  <= 1'b0;
        end
    end

    // Slave side valid/ready generation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awready_reg <= 1'b0;
            s_wready_reg  <= 1'b0;
            s_bvalid_reg  <= 1'b0;
            s_arready_reg <= 1'b0;
            s_rvalid_reg  <= 1'b0;
        end else begin
            if (m_aw_sync_pulse) s_awready_reg <= 1'b1;
            if (s_aw_handshake)  s_awready_reg <= 1'b0;

            if (m_w_sync_pulse)  s_wready_reg  <= 1'b1;
            if (s_w_handshake)   s_wready_reg  <= 1'b0;

            if (m_b_sync_pulse)  s_bvalid_reg  <= 1'b1;
            if (s_b_handshake)   s_bvalid_reg  <= 1'b0;

            if (m_ar_sync_pulse) s_arready_reg <= 1'b1;
            if (s_ar_handshake)  s_arready_reg <= 1'b0;

            if (m_r_sync_pulse)  s_rvalid_reg  <= 1'b1;
            if (s_r_handshake)   s_rvalid_reg  <= 1'b0;
        end
    end

    // Capture response data
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_reg <= 2'b00;
            s_rdata_reg <= {DATA_WIDTH{1'b0}};
            s_rresp_reg <= 2'b00;
        end else begin
            if (m_b_sync_pulse) s_bresp_reg <= m_axil_bresp;
            if (m_r_sync_pulse) begin
                s_rdata_reg <= m_axil_rdata;
                s_rresp_reg <= m_axil_rresp;
            end
        end
    end

endmodule
