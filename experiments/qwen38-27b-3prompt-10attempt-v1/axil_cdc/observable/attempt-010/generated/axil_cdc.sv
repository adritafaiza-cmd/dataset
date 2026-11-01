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
    // Synchronizers
    // ========================================================================

    // Synchronizer: s_clk -> m_clk
    function automatic sync2;
        input wire clk;
        input wire rst;
        input wire d;
        output reg [1:0] q;
        begin
            if (rst)
                q <= 2'b00;
            else
                q <= {q[0], d};
        end
    endfunction

    // Synchronizer: m_clk -> s_clk
    function automatic sync2_m;
        input wire clk;
        input wire rst;
        input wire d;
        output reg [1:0] q;
        begin
            if (rst)
                q <= 2'b00;
            else
                q <= {q[0], d};
        end
    endfunction

    // ========================================================================
    // Write Address Channel (s_clk -> m_clk)
    // ========================================================================

    // Synchronizer for awvalid
    reg [1:0] s2m_awvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s2m_awvalid_sync <= 2'b00;
        else
            s2m_awvalid_sync <= {s2m_awvalid_sync[0], s_axil_awvalid};
    end

    // Synchronizer for awready
    reg [1:0] m2s_awready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m2s_awready_sync <= 2'b00;
        else
            m2s_awready_sync <= {m2s_awready_sync[0], m_axil_awready};
    end

    // Write address data (stable when awvalid is high)
    reg [ADDR_WIDTH-1:0] s2m_awaddr_reg;
    reg [2:0] s2m_awprot_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            s2m_awprot_reg <= 3'b000;
        end else if (s_axil_awvalid) begin
            s2m_awaddr_reg <= s_axil_awaddr;
            s2m_awprot_reg <= s_axil_awprot;
        end
    end

    // Master side: generate awvalid and capture address
    reg m_awvalid_reg;
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_aw_handshake_done;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_awvalid_reg <= 1'b0;
            m_awaddr_reg <= {ADDR_WIDTH{1'b0}};
            m_awprot_reg <= 3'b000;
            m_aw_handshake_done <= 1'b0;
        end else begin
            if (m_aw_handshake_done) begin
                // Wait for next request
                if (s2m_awvalid_sync[1] && !s2m_awvalid_sync[0]) begin
                    // New request detected (rising edge of synchronized awvalid)
                    m_awvalid_reg <= 1'b1;
                    m_awaddr_reg <= s2m_awaddr_reg;
                    m_awprot_reg <= s2m_awprot_reg;
                    m_aw_handshake_done <= 1'b0;
                end
            end else begin
                if (m_awvalid_reg && m_axil_awready) begin
                    m_awvalid_reg <= 1'b0;
                    m_aw_handshake_done <= 1'b1;
                end
            end
        end
    end

    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = m_awprot_reg;

    // Slave side: awready is high when master is ready and no pending handshake
    assign s_axil_awready = m2s_awready_sync[1] && !m_awvalid_reg;

    // ========================================================================
    // Write Data Channel (s_clk -> m_clk)
    // ========================================================================

    // Synchronizer for wvalid
    reg [1:0] s2m_wvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s2m_wvalid_sync <= 2'b00;
        else
            s2m_wvalid_sync <= {s2m_wvalid_sync[0], s_axil_wvalid};
    end

    // Synchronizer for wready
    reg [1:0] m2s_wready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m2s_wready_sync <= 2'b00;
        else
            m2s_wready_sync <= {m2s_wready_sync[0], m_axil_wready};
    end

    // Write data (stable when wvalid is high)
    reg [DATA_WIDTH-1:0] s2m_wdata_reg;
    reg [STRB_WIDTH-1:0] s2m_wstrb_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_wdata_reg <= {DATA_WIDTH{1'b0}};
            s2m_wstrb_reg <= {STRB_WIDTH{1'b0}};
        end else if (s_axil_wvalid) begin
            s2m_wdata_reg <= s_axil_wdata;
            s2m_wstrb_reg <= s_axil_wstrb;
        end
    end

    // Master side: generate wvalid and capture data
    reg m_wvalid_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_w_handshake_done;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wvalid_reg <= 1'b0;
            m_wdata_reg <= {DATA_WIDTH{1'b0}};
            m_wstrb_reg <= {STRB_WIDTH{1'b0}};
            m_w_handshake_done <= 1'b0;
        end else begin
            if (m_w_handshake_done) begin
                // Wait for next request
                if (s2m_wvalid_sync[1] && !s2m_wvalid_sync[0]) begin
                    // New request detected (rising edge of synchronized wvalid)
                    m_wvalid_reg <= 1'b1;
                    m_wdata_reg <= s2m_wdata_reg;
                    m_wstrb_reg <= s2m_wstrb_reg;
                    m_w_handshake_done <= 1'b0;
                end
            end else begin
                if (m_wvalid_reg && m_axil_wready) begin
                    m_wvalid_reg <= 1'b0;
                    m_w_handshake_done <= 1'b1;
                end
            end
        end
    end

    assign m_axil_wvalid = m_wvalid_reg;
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;

    // Slave side: wready is high when master is ready and no pending handshake
    assign s_axil_wready = m2s_wready_sync[1] && !m_wvalid_reg;

    // ========================================================================
    // Write Response Channel (m_clk -> s_clk)
    // ========================================================================

    // Synchronizer for bvalid
    reg [1:0] m2s_bvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m2s_bvalid_sync <= 2'b00;
        else
            m2s_bvalid_sync <= {m2s_bvalid_sync[0], m_axil_bvalid};
    end

    // Synchronizer for bready
    reg [1:0] s2m_bready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s2m_bready_sync <= 2'b00;
        else
            s2m_bready_sync <= {s2m_bready_sync[0], s_axil_bready};
    end

    // Write response data (stable when bvalid is high)
    reg [1:0] m2s_bresp_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m2s_bresp_reg <= 2'b00;
        else if (m_axil_bvalid)
            m2s_bresp_reg <= m_axil_bresp;
    end

    // Slave side: generate bvalid and capture response
    reg s_bvalid_reg;
    reg [1:0] s_bresp_reg;
    reg s_b_handshake_done;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bvalid_reg <= 1'b0;
            s_bresp_reg <= 2'b00;
            s_b_handshake_done <= 1'b0;
        end else begin
            if (s_b_handshake_done) begin
                // Wait for next response
                if (m2s_bvalid_sync[1] && !m2s_bvalid_sync[0]) begin
                    // New response detected (rising edge of synchronized bvalid)
                    s_bvalid_reg <= 1'b1;
                    s_bresp_reg <= m2s_bresp_reg;
                    s_b_handshake_done <= 1'b0;
                end
            end else begin
                if (s_bvalid_reg && s_axil_bready) begin
                    s_bvalid_reg <= 1'b0;
                    s_b_handshake_done <= 1'b1;
                end
            end
        end
    end

    assign s_axil_bvalid = s_bvalid_reg;
    assign s_axil_bresp = s_bresp_reg;

    // Master side: bready is high when slave is ready and no pending handshake
    assign m_axil_bready = s2m_bready_sync[1] && !s_bvalid_reg;

    // ========================================================================
    // Read Address Channel (s_clk -> m_clk)
    // ========================================================================

    // Synchronizer for arvalid
    reg [1:0] s2m_arvalid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s2m_arvalid_sync <= 2'b00;
        else
            s2m_arvalid_sync <= {s2m_arvalid_sync[0], s_axil_arvalid};
    end

    // Synchronizer for arready
    reg [1:0] m2s_arready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m2s_arready_sync <= 2'b00;
        else
            m2s_arready_sync <= {m2s_arready_sync[0], m_axil_arready};
    end

    // Read address data (stable when arvalid is high)
    reg [ADDR_WIDTH-1:0] s2m_araddr_reg;
    reg [2:0] s2m_arprot_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s2m_araddr_reg <= {ADDR_WIDTH{1'b0}};
            s2m_arprot_reg <= 3'b000;
        end else if (s_axil_arvalid) begin
            s2m_araddr_reg <= s_axil_araddr;
            s2m_arprot_reg <= s_axil_arprot;
        end
    end

    // Master side: generate arvalid and capture address
    reg m_arvalid_reg;
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_ar_handshake_done;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_arvalid_reg <= 1'b0;
            m_araddr_reg <= {ADDR_WIDTH{1'b0}};
            m_arprot_reg <= 3'b000;
            m_ar_handshake_done <= 1'b0;
        end else begin
            if (m_ar_handshake_done) begin
                // Wait for next request
                if (s2m_arvalid_sync[1] && !s2m_arvalid_sync[0]) begin
                    // New request detected (rising edge of synchronized arvalid)
                    m_arvalid_reg <= 1'b1;
                    m_araddr_reg <= s2m_araddr_reg;
                    m_arprot_reg <= s2m_arprot_reg;
                    m_ar_handshake_done <= 1'b0;
                end
            end else begin
                if (m_arvalid_reg && m_axil_arready) begin
                    m_arvalid_reg <= 1'b0;
                    m_ar_handshake_done <= 1'b1;
                end
            end
        end
    end

    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_araddr = m_araddr_reg;
    assign m_axil_arprot = m_arprot_reg;

    // Slave side: arready is high when master is ready and no pending handshake
    assign s_axil_arready = m2s_arready_sync[1] && !m_arvalid_reg;

    // ========================================================================
    // Read Data Channel (m_clk -> s_clk)
    // ========================================================================

    // Synchronizer for rvalid
    reg [1:0] m2s_rvalid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m2s_rvalid_sync <= 2'b00;
        else
            m2s_rvalid_sync <= {m2s_rvalid_sync[0], m_axil_rvalid};
    end

    // Synchronizer for rready
    reg [1:0] s2m_rready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s2m_rready_sync <= 2'b00;
        else
            s2m_rready_sync <= {s2m_rready_sync[0], s_axil_rready};
    end

    // Read data (stable when rvalid is high)
    reg [DATA_WIDTH-1:0] m2s_rdata_reg;
    reg [1:0] m2s_rresp_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m2s_rdata_reg <= {DATA_WIDTH{1'b0}};
            m2s_rresp_reg <= 2'b00;
        end else if (m_axil_rvalid) begin
            m2s_rdata_reg <= m_axil_rdata;
            m2s_rresp_reg <= m_axil_rresp;
        end
    end

    // Slave side: generate rvalid and capture data
    reg s_rvalid_reg;
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0] s_rresp_reg;
    reg s_r_handshake_done;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rvalid_reg <= 1'b0;
            s_rdata_reg <= {DATA_WIDTH{1'b0}};
            s_rresp_reg <= 2'b00;
            s_r_handshake_done <= 1'b0;
        end else begin
            if (s_r_handshake_done) begin
                // Wait for next response
                if (m2s_rvalid_sync[1] && !m2s_rvalid_sync[0]) begin
                    // New response detected (rising edge of synchronized rvalid)
                    s_rvalid_reg <= 1'b1;
                    s_rdata_reg <= m2s_rdata_reg;
                    s_rresp_reg <= m2s_rresp_reg;
                    s_r_handshake_done <= 1'b0;
                end
            end else begin
                if (s_rvalid_reg && s_axil_rready) begin
                    s_rvalid_reg <= 1'b0;
                    s_r_handshake_done <= 1'b1;
                end
            end
        end
    end

    assign s_axil_rvalid = s_rvalid_reg;
    assign s_axil_rdata = s_rdata_reg;
    assign s_axil_rresp = s_rresp_reg;

    // Master side: rready is high when slave is ready and no pending handshake
    assign m_axil_rready = s2m_rready_sync[1] && !s_rvalid_reg;

endmodule
