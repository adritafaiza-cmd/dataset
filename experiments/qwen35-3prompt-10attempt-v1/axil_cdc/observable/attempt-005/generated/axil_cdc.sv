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

    // ------------------------------------------------------------------------
    // Internal State for Write Channel (Slave -> Master)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  s_waddr;
    reg [DATA_WIDTH-1:0]  s_wdata;
    reg [STRB_WIDTH-1:0]  s_wstrb;
    reg [2:0]             s_wprot;
    reg                   s_wvalid;
    reg                   s_wready;
    reg                   s_wpending;
    reg                   s_wlast; // Write channel is inherently single beat for AXI-Lite

    // Internal State for Read Channel (Slave -> Master)
    reg [ADDR_WIDTH-1:0]  s_raddr;
    reg [2:0]             s_rprot;
    reg                   s_rvalid;
    reg                   s_rready;
    reg                   s_rpending;
    reg [DATA_WIDTH-1:0]  s_rdata;
    reg [1:0]             s_rresp;
    reg                   s_rlast; // Read channel is inherently single beat for AXI-Lite

    // Internal State for Response Channel (Master -> Slave)
    reg [ADDR_WIDTH-1:0]  m_baddr;
    reg [1:0]             m_bresp;
    reg                   m_bvalid;
    reg                   m_bready;
    reg                   m_bpending;

    // Internal State for Read Response Channel (Master -> Slave)
    reg [ADDR_WIDTH-1:0]  m_raddr;
    reg [DATA_WIDTH-1:0]  m_rdata;
    reg [1:0]             m_rresp;
    reg                   m_rvalid;
    reg                   m_rready;
    reg                   m_rpending;

    // ------------------------------------------------------------------------
    // CDC Logic: Write Address/Data/Prot (Slave -> Master)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  s_waddr_cdc;
    reg [DATA_WIDTH-1:0]  s_wdata_cdc;
    reg [STRB_WIDTH-1:0]  s_wstrb_cdc;
    reg [2:0]             s_wprot_cdc;
    reg                   s_wvalid_cdc;
    reg                   s_wready_cdc;
    reg                   s_wpending_cdc;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_waddr_cdc     <= 0;
            s_wdata_cdc     <= 0;
            s_wstrb_cdc     <= 0;
            s_wprot_cdc     <= 0;
            s_wvalid_cdc    <= 0;
            s_wready_cdc    <= 1;
            s_wpending_cdc  <= 0;
        end else begin
            // Capture incoming signals
            if (s_axil_awvalid && s_axil_awready) begin
                s_waddr_cdc     <= s_axil_awaddr;
                s_wdata_cdc     <= s_axil_wdata;
                s_wstrb_cdc     <= s_axil_wstrb;
                s_wprot_cdc     <= s_axil_awprot;
                s_wvalid_cdc    <= 1;
                s_wready_cdc    <= 0;
                s_wpending_cdc  <= 1;
            end else if (s_wpending_cdc) begin
                s_wvalid_cdc    <= 0;
                s_wready_cdc    <= 1;
                s_wpending_cdc  <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Read Address/Prot (Slave -> Master)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  s_raddr_cdc;
    reg [2:0]             s_rprot_cdc;
    reg                   s_rvalid_cdc;
    reg                   s_rready_cdc;
    reg                   s_rpending_cdc;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_raddr_cdc     <= 0;
            s_rprot_cdc     <= 0;
            s_rvalid_cdc    <= 0;
            s_rready_cdc    <= 1;
            s_rpending_cdc  <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_raddr_cdc     <= s_axil_araddr;
                s_rprot_cdc     <= s_axil_arprot;
                s_rvalid_cdc    <= 1;
                s_rready_cdc    <= 0;
                s_rpending_cdc  <= 1;
            end else if (s_rpending_cdc) begin
                s_rvalid_cdc    <= 0;
                s_rready_cdc    <= 1;
                s_rpending_cdc  <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Write Response (Master -> Slave)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  m_baddr_cdc;
    reg [1:0]             m_bresp_cdc;
    reg                   m_bvalid_cdc;
    reg                   m_bready_cdc;
    reg                   m_bpending_cdc;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_baddr_cdc     <= 0;
            m_bresp_cdc     <= 0;
            m_bvalid_cdc    <= 0;
            m_bready_cdc    <= 1;
            m_bpending_cdc  <= 0;
        end else begin
            if (m_axil_bvalid && m_axil_bready) begin
                m_baddr_cdc     <= m_axil_awaddr; // Store address to match later if needed, though AXI-Lite B usually just needs valid
                m_bresp_cdc     <= m_axil_bresp;
                m_bvalid_cdc    <= 1;
                m_bready_cdc    <= 0;
                m_bpending_cdc  <= 1;
            end else if (m_bpending_cdc) begin
                m_bvalid_cdc    <= 0;
                m_bready_cdc    <= 1;
                m_bpending_cdc  <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // CDC Logic: Read Response (Master -> Slave)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  m_raddr_cdc;
    reg [DATA_WIDTH-1:0]  m_rdata_cdc;
    reg [1:0]             m_rresp_cdc;
    reg                   m_rvalid_cdc;
    reg                   m_rready_cdc;
    reg                   m_rpending_cdc;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_raddr_cdc     <= 0;
            m_rdata_cdc     <= 0;
            m_rresp_cdc     <= 0;
            m_rvalid_cdc    <= 0;
            m_rready_cdc    <= 1;
            m_rpending_cdc  <= 0;
        end else begin
            if (m_axil_rvalid && m_axil_rready) begin
                m_raddr_cdc     <= m_axil_araddr;
                m_rdata_cdc     <= m_axil_rdata;
                m_rresp_cdc     <= m_axil_rresp;
                m_rvalid_cdc    <= 1;
                m_rready_cdc    <= 0;
                m_rpending_cdc  <= 1;
            end else if (m_rpending_cdc) begin
                m_rvalid_cdc    <= 0;
                m_rready_cdc    <= 1;
                m_rpending_cdc  <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Master Side Logic (Clock Domain m_clk)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  m_awaddr;
    reg [2:0]             m_awprot;
    reg                   m_awvalid;
    reg                   m_awready;
    reg                   m_awpending;

    reg [DATA_WIDTH-1:0]  m_wdata;
    reg [STRB_WIDTH-1:0]  m_wstrb;
    reg                   m_wvalid;
    reg                   m_wready;
    reg                   m_wpending;

    reg [ADDR_WIDTH-1:0]  m_araddr;
    reg [2:0]             m_arprot;
    reg                   m_arvalid;
    reg                   m_arready;
    reg                   m_arpending;

    reg [DATA_WIDTH-1:0]  m_rdata;
    reg [1:0]             m_rresp;
    reg                   m_rvalid;
    reg                   m_rready;
    reg                   m_rpending;

    // Write Address Capture
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awaddr <= 0;
            m_awprot <= 0;
            m_awvalid <= 0;
            m_awready <= 1;
            m_awpending <= 0;
        end else begin
            if (s_wvalid_cdc && m_axil_awready) begin
                m_awaddr <= s_waddr_cdc;
                m_awprot <= s_wprot_cdc;
                m_awvalid <= 1;
                m_awready <= 0;
                m_awpending <= 1;
            end else if (m_awpending) begin
                m_awvalid <= 0;
                m_awready <= 1;
                m_awpending <= 0;
            end
        end
    end

    // Write Data Capture
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wdata <= 0;
            m_wstrb <= 0;
            m_wvalid <= 0;
            m_wready <= 1;
            m_wpending <= 0;
        end else begin
            if (s_wvalid_cdc && m_axil_wready) begin
                m_wdata <= s_wdata_cdc;
                m_wstrb <= s_wstrb_cdc;
                m_wvalid <= 1;
                m_wready <= 0;
                m_wpending <= 1;
            end else if (m_wpending) begin
                m_wvalid <= 0;
                m_wready <= 1;
                m_wpending <= 0;
            end
        end
    end

    // Read Address Capture
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_araddr <= 0;
            m_arprot <= 0;
            m_arvalid <= 0;
            m_arready <= 1;
            m_arpending <= 0;
        end else begin
            if (s_rvalid_cdc && m_axil_arready) begin
                m_araddr <= s_raddr_cdc;
                m_arprot <= s_rprot_cdc;
                m_arvalid <= 1;
                m_arready <= 0;
                m_arpending <= 1;
            end else if (m_arpending) begin
                m_arvalid <= 0;
                m_arready <= 1;
                m_arpending <= 0;
            end
        end
    end

    // Write Response Capture
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bresp <= 0;
            m_bvalid <= 0;
            m_bready <= 1;
            m_bpending <= 0;
        end else begin
            if (m_bvalid_cdc && s_axil_bready) begin
                m_bresp <= m_bresp_cdc;
                m_bvalid <= 1;
                m_bready <= 0;
                m_bpending <= 1;
            end else if (m_bpending) begin
                m_bvalid <= 0;
                m_bready <= 1;
                m_bpending <= 0;
            end
        end
    end

    // Read Response Capture
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rdata <= 0;
            m_rresp <= 0;
            m_rvalid <= 0;
            m_rready <= 1;
            m_rpending <= 0;
        end else begin
            if (m_rvalid_cdc && s_axil_rready) begin
                m_rdata <= m_rdata_cdc;
                m_rresp <= m_rresp_cdc;
                m_rvalid <= 1;
                m_rready <= 0;
                m_rpending <= 1;
            end else if (m_rpending) begin
                m_rvalid <= 0;
                m_rready <= 1;
                m_rpending <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Slave Side Logic (Clock Domain s_clk)
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0]  s_awaddr;
    reg [2:0]             s_awprot;
    reg                   s_awvalid;
    reg                   s_awready;
    reg                   s_awpending;

    reg [DATA_WIDTH-1:0]  s_wdata;
    reg [STRB_WIDTH-1:0]  s_wstrb;
    reg                   s_wvalid;
    reg                   s_wready;
    reg                   s_wpending;

    reg [ADDR_WIDTH-1:0]  s_araddr;
    reg [2:0]             s_arprot;
    reg                   s_arvalid;
    reg                   s_arready;
    reg                   s_arpending;

    reg [DATA_WIDTH-1:0]  s_rdata;
    reg [1:0]             s_rresp;
    reg                   s_rvalid;
    reg                   s_rready;
    reg                   s_rpending;

    // Write Address Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr <= 0;
            s_awprot <= 0;
            s_awvalid <= 0;
            s_awready <= 1;
            s_awpending <= 0;
        end else begin
            if (m_axil_awvalid && s_wready) begin
                s_awaddr <= m_awaddr;
                s_awprot <= m_awprot;
                s_awvalid <= 1;
                s_awready <= 0;
                s_awpending <= 1;
            end else if (s_awpending) begin
                s_awvalid <= 0;
                s_awready <= 1;
                s_awpending <= 0;
            end
        end
    end

    // Write Data Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata <= 0;
            s_wstrb <= 0;
            s_wvalid <= 0;
            s_wready <= 1;
            s_wpending <= 0;
        end else begin
            if (m_axil_wvalid && s_wready) begin
                s_wdata <= m_wdata;
                s_wstrb <= m_wstrb;
                s_wvalid <= 1;
                s_wready <= 0;
                s_wpending <= 1;
            end else if (s_wpending) begin
                s_wvalid <= 0;
                s_wready <= 1;
                s_wpending <= 0;
            end
        end
    end

    // Read Address Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr <= 0;
            s_arprot <= 0;
            s_arvalid <= 0;
            s_arready <= 1;
            s_arpending <= 0;
        end else begin
            if (m_axil_arvalid && s_wready) begin // Note: s_wready is shared for simplicity in AXI-Lite bridge logic, though strictly separate channels are better. Here we assume the bridge handles arbitration internally or the master doesn't stall. For a pure bridge, we need separate ready signals.
                // Correction: In a real bridge, Read and Write channels are independent. 
                // The 's_wready' used above for Read Address capture is incorrect logic if Write is also happening.
                // Let's fix the logic: We need separate ready signals for AW and AR on the slave side.
                // However, since this is a single module instance, we must ensure the internal state machines don't conflict.
                // AXI-Lite spec: AW and AR are independent.
                // Let's restructure the slave side captures to use specific ready flags.
            end
        end
    end

    // Re-implementing Slave Side Logic with proper separation of AW and AR channels
    // AW Channel
    reg [ADDR_WIDTH-1:0]  s_awaddr_int;
    reg [2:0]             s_awprot_int;
    reg                   s_awvalid_int;
    reg                   s_awready_int;
    reg                   s_awpending_int;

    // AR Channel
    reg [ADDR_WIDTH-1:0]  s_araddr_int;
    reg [2:0]             s_arprot_int;
    reg                   s_arvalid_int;
    reg                   s_arready_int;
    reg                   s_arpending_int;

    // W Channel
    reg [DATA_WIDTH-1:0]  s_wdata_int;
    reg [STRB_WIDTH-1:0]  s_wstrb_int;
    reg                   s_wvalid_int;
    reg                   s_wready_int;
    reg                   s_wpending_int;

    // B Channel
    reg [1:0]             s_bresp_int;
    reg                   s_bvalid_int;
    reg                   s_bready_int;
    reg                   s_bpending_int;

    // R Channel
    reg [DATA_WIDTH-1:0]  s_rdata_int;
    reg [1:0]             s_rresp_int;
    reg                   s_rvalid_int;
    reg                   s_rready_int;
    reg                   s_rpending_int;

    // AW Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_awaddr_int <= 0;
            s_awprot_int <= 0;
            s_awvalid_int <= 0;
            s_awready_int <= 1;
            s_awpending_int <= 0;
        end else begin
            if (m_axil_awvalid && s_awready_int) begin
                s_awaddr_int <= m_awaddr;
                s_awprot_int <= m_awprot;
                s_awvalid_int <= 1;
                s_awready_int <= 0;
                s_awpending_int <= 1;
            end else if (s_awpending_int) begin
                s_awvalid_int <= 0;
                s_awready_int <= 1;
                s_awpending_int <= 0;
            end
        end
    end

    // AR Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_araddr_int <= 0;
            s_arprot_int <= 0;
            s_arvalid_int <= 0;
            s_arready_int <= 1;
            s_arpending_int <= 0;
        end else begin
            if (m_axil_arvalid && s_arready_int) begin
                s_araddr_int <= m_araddr;
                s_arprot_int <= m_arprot;
                s_arvalid_int <= 1;
                s_arready_int <= 0;
                s_arpending_int <= 1;
            end else if (s_arpending_int) begin
                s_arvalid_int <= 0;
                s_arready_int <= 1;
                s_arpending_int <= 0;
            end
        end
    end

    // W Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wdata_int <= 0;
            s_wstrb_int <= 0;
            s_wvalid_int <= 0;
            s_wready_int <= 1;
            s_wpending_int <= 0;
        end else begin
            if (m_axil_wvalid && s_wready_int) begin
                s_wdata_int <= m_wdata;
                s_wstrb_int <= m_wstrb;
                s_wvalid_int <= 1;
                s_wready_int <= 0;
                s_wpending_int <= 1;
            end else if (s_wpending_int) begin
                s_wvalid_int <= 0;
                s_wready_int <= 1;
                s_wpending_int <= 0;
            end
        end
    end

    // B Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bresp_int <= 0;
            s_bvalid_int <= 0;
            s_bready_int <= 1;
            s_bpending_int <= 0;
        end else begin
            if (m_axil_bvalid && s_bready_int) begin
                s_bresp_int <= m_bresp;
                s_bvalid_int <= 1;
                s_bready_int <= 0;
                s_bpending_int <= 1;
            end else if (s_bpending_int) begin
                s_bvalid_int <= 0;
                s_bready_int <= 1;
                s_bpending_int <= 0;
            end
        end
    end

    // R Capture
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rdata_int <= 0;
            s_rresp_int <= 0;
            s_rvalid_int <= 0;
            s_rready_int <= 1;
            s_rpending_int <= 0;
        end else begin
            if (m_axil_rvalid && s_rready_int) begin
                s_rdata_int <= m_rdata;
                s_rresp_int <= m_rresp;
                s_rvalid_int <= 1;
                s_rready_int <= 0;
                s_rpending_int <= 1;
            end else if (s_rpending_int) begin
                s_rvalid_int <= 0;
                s_rready_int <= 1;
                s_rpending_int <= 0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Output Assignments
    // ------------------------------------------------------------------------
    assign s_axil_awready = s_awready_int;
    assign s_axil_wready  = s_wready_int;
    assign s_axil_bvalid  = s_bvalid_int;
    assign s_axil_bresp   = s_bresp_int;
    assign s_axil_arready = s_arready_int;
    assign s_axil_rvalid  = s_rvalid_int;
    assign s_axil_rdata   = s_rdata_int;
    assign s_axil_rresp   = s_rresp_int;

    assign m_axil_awaddr  = s_awaddr_int;
    assign m_axil_awprot  = s_awprot_int;
    assign m_axil_awvalid = s_awvalid_int;
    assign m_axil_wdata   = s_wdata_int;
    assign m_axil_wstrb   = s_wstrb_int;
    assign m_axil_wvalid  = s_wvalid_int;
    assign m_axil_bresp   = s_bresp_int;
    assign m_axil_bvalid  = s_bvalid_int;
    assign m_axil_araddr  = s_araddr_int;
    assign m_axil_arprot  = s_arprot_int;
    assign m_axil_arvalid = s_arvalid_int;
    assign m_axil_rdata   = s_rdata_int;
    assign m_axil_rresp   = s_rresp_int;
    assign m_axil_rvalid  = s_rvalid_int;

endmodule
```<|im_end|>
