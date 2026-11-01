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
    function automatic sync3;
        input  wire clk;
        input  wire rst;
        input  wire d;
        output reg [2:0] q;
        begin
            if (rst)
                q <= 3'b000;
            else
                q <= {q[1:0], d};
        end
    endfunction

    // Synchronizer: m_clk -> s_clk
    function automatic sync3_m;
        input  wire clk;
        input  wire rst;
        input  wire d;
        output reg [2:0] q;
        begin
            if (rst)
                q <= 3'b000;
            else
                q <= {q[1:0], d};
        end
    endfunction

    // ========================================================================
    // Write Address Channel (AW): s_clk -> m_clk
    // ========================================================================

    // Handshake signals
    reg        s_aw_req;
    reg        s_aw_ack;
    wire       s_aw_ack_sync;
    wire       s_aw_ack_sync2;
    wire       s_aw_ack_sync3;

    // Data to be sent
    reg [ADDR_WIDTH-1:0] s_aw_addr_reg;
    reg [2:0]            s_aw_prot_reg;

    // Synchronizer for ack (m_clk -> s_clk)
    reg [2:0] s_aw_ack_sync_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_aw_ack_sync_reg <= 3'b000;
        else
            s_aw_ack_sync_reg <= {s_aw_ack_sync_reg[1:0], s_aw_ack};
    end
    assign s_axil_awready = s_aw_ack_sync_reg[2];

    // Synchronizer for req (s_clk -> m_clk)
    reg [2:0] m_aw_req_sync_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_req_sync_reg <= 3'b000;
        else
            m_aw_req_sync_reg <= {m_aw_req_sync_reg[1:0], s_aw_req};
    end
    wire m_aw_req_sync = m_aw_req_sync_reg[2];

    // Synchronizer for addr (s_clk -> m_clk) - use 2-stage for each bit
    // We'll use a simple approach: hold data stable until ack
    // Synchronize the entire address and prot using multi-bit sync
    // For safety, we synchronize each bit with 2 FFs, but that's complex.
    // Instead, we use a handshake where data is stable when req is high.
    // We synchronize req, and when req goes high, we capture the data.
    // The data is guaranteed stable because we only change it when not in transfer.

    // In m_clk domain, detect rising edge of synchronized req
    reg m_aw_req_sync_d;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_req_sync_d <= 1'b0;
        else
            m_aw_req_sync_d <= m_aw_req_sync;
    end
    wire m_aw_req_rise = m_aw_req_sync & ~m_aw_req_sync_d;

    // Capture data in m_clk domain when req rises
    reg [ADDR_WIDTH-1:0] m_aw_addr_reg;
    reg [2:0]            m_aw_prot_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_addr_reg <= {ADDR_WIDTH{1'b0}};
            m_aw_prot_reg <= 3'b000;
        end else if (m_aw_req_rise) begin
            m_aw_addr_reg <= s_aw_addr_reg;
            m_aw_prot_reg <= s_aw_prot_reg;
        end
    end

    // Master AW channel
    reg m_aw_valid;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_aw_valid <= 1'b0;
        else if (m_aw_req_rise)
            m_aw_valid <= 1'b1;
        else if (m_axil_awvalid & m_axil_awready)
            m_aw_valid <= 1'b0;
    end

    assign m_axil_awaddr  = m_aw_addr_reg;
    assign m_axil_awprot  = m_aw_prot_reg;
    assign m_axil_awvalid = m_aw_valid;

    // Acknowledge when master AW handshake completes
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_aw_ack <= 1'b0;
        else if (m_axil_awvalid & m_axil_awready)
            s_aw_ack <= 1'b1;
        else if (s_aw_ack_sync_reg[2])
            s_aw_ack <= 1'b0;
    end

    // Slave AW channel
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_req      <= 1'b0;
            s_aw_addr_reg <= {ADDR_WIDTH{1'b0}};
            s_aw_prot_reg <= 3'b000;
        end else begin
            if (s_axil_awvalid & s_axil_awready) begin
                s_aw_req      <= 1'b1;
                s_aw_addr_reg <= s_axil_awaddr;
                s_aw_prot_reg <= s_axil_awprot;
            end else if (s_aw_ack_sync_reg[2]) begin
                s_aw_req <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Data Channel (W): s_clk -> m_clk
    // ========================================================================

    reg        s_w_req;
    reg        s_w_ack;
    reg [DATA_WIDTH-1:0] s_w_data_reg;
    reg [STRB_WIDTH-1:0] s_w_strb_reg;

    // Synchronizer for ack (m_clk -> s_clk)
    reg [2:0] s_w_ack_sync_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_w_ack_sync_reg <= 3'b000;
        else
            s_w_ack_sync_reg <= {s_w_ack_sync_reg[1:0], s_w_ack};
    end
    assign s_axil_wready = s_w_ack_sync_reg[2];

    // Synchronizer for req (s_clk -> m_clk)
    reg [2:0] m_w_req_sync_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_req_sync_reg <= 3'b000;
        else
            m_w_req_sync_reg <= {m_w_req_sync_reg[1:0], s_w_req};
    end
    wire m_w_req_sync = m_w_req_sync_reg[2];

    reg m_w_req_sync_d;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_req_sync_d <= 1'b0;
        else
            m_w_req_sync_d <= m_w_req_sync;
    end
    wire m_w_req_rise = m_w_req_sync & ~m_w_req_sync_d;

    reg [DATA_WIDTH-1:0] m_w_data_reg;
    reg [STRB_WIDTH-1:0] m_w_strb_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_data_reg <= {DATA_WIDTH{1'b0}};
            m_w_strb_reg <= {STRB_WIDTH{1'b0}};
        end else if (m_w_req_rise) begin
            m_w_data_reg <= s_w_data_reg;
            m_w_strb_reg <= s_w_strb_reg;
        end
    end

    reg m_w_valid;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_w_valid <= 1'b0;
        else if (m_w_req_rise)
            m_w_valid <= 1'b1;
        else if (m_axil_wvalid & m_axil_wready)
            m_w_valid <= 1'b0;
    end

    assign m_axil_wdata  = m_w_data_reg;
    assign m_axil_wstrb  = m_w_strb_reg;
    assign m_axil_wvalid = m_w_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_w_ack <= 1'b0;
        else if (m_axil_wvalid & m_axil_wready)
            s_w_ack <= 1'b1;
        else if (s_w_ack_sync_reg[2])
            s_w_ack <= 1'b0;
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_req      <= 1'b0;
            s_w_data_reg <= {DATA_WIDTH{1'b0}};
            s_w_strb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_axil_wvalid & s_axil_wready) begin
                s_w_req      <= 1'b1;
                s_w_data_reg <= s_axil_wdata;
                s_w_strb_reg <= s_axil_wstrb;
            end else if (s_w_ack_sync_reg[2]) begin
                s_w_req <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Write Response Channel (B): m_clk -> s_clk
    // ========================================================================

    reg        m_b_req;
    reg        m_b_ack;
    reg [1:0]  m_b_resp_reg;

    // Synchronizer for req (m_clk -> s_clk)
    reg [2:0] s_b_req_sync_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_req_sync_reg <= 3'b000;
        else
            s_b_req_sync_reg <= {s_b_req_sync_reg[1:0], m_b_req};
    end
    wire s_b_req_sync = s_b_req_sync_reg[2];

    reg s_b_req_sync_d;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_req_sync_d <= 1'b0;
        else
            s_b_req_sync_d <= s_b_req_sync;
    end
    wire s_b_req_rise = s_b_req_sync & ~s_b_req_sync_d;

    reg [1:0] s_b_resp_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_resp_reg <= 2'b00;
        else if (s_b_req_rise)
            s_b_resp_reg <= m_b_resp_reg;
    end

    reg s_b_valid;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_b_valid <= 1'b0;
        else if (s_b_req_rise)
            s_b_valid <= 1'b1;
        else if (s_axil_bvalid & s_axil_bready)
            s_b_valid <= 1'b0;
    end

    assign s_axil_bresp  = s_b_resp_reg;
    assign s_axil_bvalid = s_b_valid;

    // Synchronizer for ack (s_clk -> m_clk)
    reg [2:0] m_b_ack_sync_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_b_ack_sync_reg <= 3'b000;
        else
            m_b_ack_sync_reg <= {m_b_ack_sync_reg[1:0], m_b_ack};
    end
    wire m_b_ack_sync = m_b_ack_sync_reg[2];

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_req      <= 1'b0;
            m_b_resp_reg <= 2'b00;
        end else begin
            if (m_axil_bvalid & m_axil_bready) begin
                m_b_req      <= 1'b1;
                m_b_resp_reg <= m_axil_bresp;
            end else if (m_b_ack_sync) begin
                m_b_req <= 1'b0;
            end
        end
    end

    assign m_axil_bready = m_b_ack_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_b_ack <= 1'b0;
        else if (s_axil_bvalid & s_axil_bready)
            m_b_ack <= 1'b1;
        else if (s_b_req_sync_reg[2])
            m_b_ack <= 1'b0;
    end

    // ========================================================================
    // Read Address Channel (AR): s_clk -> m_clk
    // ========================================================================

    reg        s_ar_req;
    reg        s_ar_ack;
    reg [ADDR_WIDTH-1:0] s_ar_addr_reg;
    reg [2:0]            s_ar_prot_reg;

    // Synchronizer for ack (m_clk -> s_clk)
    reg [2:0] s_ar_ack_sync_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_ar_ack_sync_reg <= 3'b000;
        else
            s_ar_ack_sync_reg <= {s_ar_ack_sync_reg[1:0], s_ar_ack};
    end
    assign s_axil_arready = s_ar_ack_sync_reg[2];

    // Synchronizer for req (s_clk -> m_clk)
    reg [2:0] m_ar_req_sync_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_req_sync_reg <= 3'b000;
        else
            m_ar_req_sync_reg <= {m_ar_req_sync_reg[1:0], s_ar_req};
    end
    wire m_ar_req_sync = m_ar_req_sync_reg[2];

    reg m_ar_req_sync_d;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_req_sync_d <= 1'b0;
        else
            m_ar_req_sync_d <= m_ar_req_sync;
    end
    wire m_ar_req_rise = m_ar_req_sync & ~m_ar_req_sync_d;

    reg [ADDR_WIDTH-1:0] m_ar_addr_reg;
    reg [2:0]            m_ar_prot_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_addr_reg <= {ADDR_WIDTH{1'b0}};
            m_ar_prot_reg <= 3'b000;
        end else if (m_ar_req_rise) begin
            m_ar_addr_reg <= s_ar_addr_reg;
            m_ar_prot_reg <= s_ar_prot_reg;
        end
    end

    reg m_ar_valid;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ar_valid <= 1'b0;
        else if (m_ar_req_rise)
            m_ar_valid <= 1'b1;
        else if (m_axil_arvalid & m_axil_arready)
            m_ar_valid <= 1'b0;
    end

    assign m_axil_araddr  = m_ar_addr_reg;
    assign m_axil_arprot  = m_ar_prot_reg;
    assign m_axil_arvalid = m_ar_valid;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            s_ar_ack <= 1'b0;
        else if (m_axil_arvalid & m_axil_arready)
            s_ar_ack <= 1'b1;
        else if (s_ar_ack_sync_reg[2])
            s_ar_ack <= 1'b0;
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_req      <= 1'b0;
            s_ar_addr_reg <= {ADDR_WIDTH{1'b0}};
            s_ar_prot_reg <= 3'b000;
        end else begin
            if (s_axil_arvalid & s_axil_arready) begin
                s_ar_req      <= 1'b1;
                s_ar_addr_reg <= s_axil_araddr;
                s_ar_prot_reg <= s_axil_arprot;
            end else if (s_ar_ack_sync_reg[2]) begin
                s_ar_req <= 1'b0;
            end
        end
    end

    // ========================================================================
    // Read Data Channel (R): m_clk -> s_clk
    // ========================================================================

    reg        m_r_req;
    reg        m_r_ack;
    reg [DATA_WIDTH-1:0] m_r_data_reg;
    reg [1:0]            m_r_resp_reg;

    // Synchronizer for req (m_clk -> s_clk)
    reg [2:0] s_r_req_sync_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_req_sync_reg <= 3'b000;
        else
            s_r_req_sync_reg <= {s_r_req_sync_reg[1:0], m_r_req};
    end
    wire s_r_req_sync = s_r_req_sync_reg[2];

    reg s_r_req_sync_d;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_req_sync_d <= 1'b0;
        else
            s_r_req_sync_d <= s_r_req_sync;
    end
    wire s_r_req_rise = s_r_req_sync & ~s_r_req_sync_d;

    reg [DATA_WIDTH-1:0] s_r_data_reg;
    reg [1:0]            s_r_resp_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data_reg <= {DATA_WIDTH{1'b0}};
            s_r_resp_reg <= 2'b00;
        end else if (s_r_req_rise) begin
            s_r_data_reg <= m_r_data_reg;
            s_r_resp_reg <= m_r_resp_reg;
        end
    end

    reg s_r_valid;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_r_valid <= 1'b0;
        else if (s_r_req_rise)
            s_r_valid <= 1'b1;
        else if (s_axil_rvalid & s_axil_rready)
            s_r_valid <= 1'b0;
    end

    assign s_axil_rdata  = s_r_data_reg;
    assign s_axil_rresp  = s_r_resp_reg;
    assign s_axil_rvalid = s_r_valid;

    // Synchronizer for ack (s_clk -> m_clk)
    reg [2:0] m_r_ack_sync_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_r_ack_sync_reg <= 3'b000;
        else
            m_r_ack_sync_reg <= {m_r_ack_sync_reg[1:0], m_r_ack};
    end
    wire m_r_ack_sync = m_r_ack_sync_reg[2];

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_req      <= 1'b0;
            m_r_data_reg <= {DATA_WIDTH{1'b0}};
            m_r_resp_reg <= 2'b00;
        end else begin
            if (m_axil_rvalid & m_axil_rready) begin
                m_r_req      <= 1'b1;
                m_r_data_reg <= m_axil_rdata;
                m_r_resp_reg <= m_axil_rresp;
            end else if (m_r_ack_sync) begin
                m_r_req <= 1'b0;
            end
        end
    end

    assign m_axil_rready = m_r_ack_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            m_r_ack <= 1'b0;
        else if (s_axil_rvalid & s_axil_rready)
            m_r_ack <= 1'b1;
        else if (s_r_req_sync_reg[2])
            m_r_ack <= 1'b0;
    end

endmodule
