module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
    // Slave interface (s_clk domain)
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

    // Master interface (m_clk domain)
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

    // Write channel handling
    reg aw_received, w_received;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg write_req, write_ack;
    reg write_req_sync1, write_req_sync2;
    reg write_ack_sync1, write_ack_sync2;

    // Master write signals
    reg [ADDR_WIDTH-1:0] m_awaddr;
    reg [2:0] m_awprot;
    reg m_awvalid;
    reg [DATA_WIDTH-1:0] m_wdata;
    reg [STRB_WIDTH-1:0] m_wstrb;
    reg m_wvalid;
    reg m_bready;

    // B response handling
    reg [1:0] bresp_reg;
    reg bvalid_reg;

    // Read channel handling
    reg ar_received;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg read_req, read_ack;
    reg read_req_sync1, read_req_sync2;
    reg read_ack_sync1, read_ack_sync2;

    // Master read signals
    reg [ADDR_WIDTH-1:0] m_araddr;
    reg [2:0] m_arprot;
    reg m_arvalid;
    reg m_rready;

    // R data handling
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;

    // Assign outputs
    assign s_axil_awready = !aw_received;
    assign s_axil_wready = !w_received;

    // Write capture
    always @(posedge s_clk) begin
        if (s_rst) begin
            aw_received <= 0;
            w_received <= 0;
            awaddr_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            write_req <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                awaddr_reg <= s_axil_awaddr;
                aw_received <= 1;
            end
            if (s_axil_wvalid && s_axil_wready) begin
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                w_received <= 1;
            end
            if (aw_received && w_received) begin
                write_req <= ~write_req;
                aw_received <= 0;
                w_received <= 0;
            end
        end
    end

    // Synchronize write_req to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_req_sync1 <= 0;
            write_req_sync2 <= 0;
        end else begin
            write_req_sync1 <= write_req;
            write_req_sync2 <= write_req_sync1;
        end
    end

    // Detect rising edge of write_req in m_clk
    reg write_req_prev;
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_req_prev <= 0;
        end else begin
            write_req_prev <= write_req_sync2;
        end
    end
    wire write_req_rise = ~write_req_prev && write_req_sync2;

    // Master write handling
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_awvalid <= 0;
            m_wvalid <= 0;
            m_bready <= 0;
            write_ack <= 0;
        end else begin
            if (write_req_rise) begin
                m_awaddr <= awaddr_reg;
                m_awprot <= s_axil_awprot;
                m_awvalid <= 1;
                m_wdata <= wdata_reg;
                m_wstrb <= wstrb_reg;
                m_wvalid <= 1;
            end
            if (m_axil_awready && m_awvalid) begin
                m_awvalid <= 0;
            end
            if (m_axil_wready && m_wvalid) begin
                m_wvalid <= 0;
            end
            if (!m_awvalid && !m_wvalid) begin
                m_bready <= 1;
            end
            if (m_axil_bvalid && m_bready) begin
                write_ack <= ~write_ack;
                m_bready <= 0;
                bresp_reg <= m_axil_bresp;
                bvalid_reg <= 1;
            end
        end
    end

    // Synchronize write_ack to s_clk
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_ack_sync1 <= 0;
            write_ack_sync2 <= 0;
        end else begin
            write_ack_sync1 <= write_ack;
            write_ack_sync2 <= write_ack_sync1;
        end
    end

    // B response handling in s_clk
    assign s_axil_bresp = bresp_reg;
    assign s_axil_bvalid = bvalid_reg;

    always @(posedge s_clk) begin
        if (s_rst) begin
            bvalid_reg <= 0;
        end else begin
            if (bvalid_reg && s_axil_bready) begin
                bvalid_reg <= 0;
            end
            if (write_ack_sync2 && !bvalid_reg) begin
                bvalid_reg <= 1;
            end
        end
    end

    // Read handling
    assign s_axil_arready = !ar_received;

    always @(posedge s_clk) begin
        if (s_rst) begin
            ar_received <= 0;
            araddr_reg <= 0;
            read_req <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                araddr_reg <= s_axil_araddr;
                ar_received <= 1;
            end
            if (ar_received) begin
                read_req <= ~read_req;
                ar_received <= 0;
            end
        end
    end

    // Synchronize read_req to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_req_sync1 <= 0;
            read_req_sync2 <= 0;
        end else begin
            read_req_sync1 <= read_req;
            read_req_sync2 <= read_req_sync1;
        end
    end

    // Detect rising edge of read_req in m_clk
    reg read_req_prev;
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_req_prev <= 0;
        end else begin
            read_req_prev <= read_req_sync2;
        end
    end
    wire read_req_rise = ~read_req_prev && read_req_sync2;

    // Master read handling
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_arvalid <= 0;
            m_rready <= 0;
            read_ack <= 0;
            rvalid_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
        end else begin
            if (read_req_rise) begin
                m_araddr <= araddr_reg;
                m_arprot <= s_axil_arprot;
                m_arvalid <= 1;
            end
            if (m_axil_arready && m_arvalid) begin
                m_arvalid <= 0;
            end
            if (m_axil_rvalid && m_rready) begin
                rdata_reg <= m_axil_rdata;
                rresp_reg <= m_axil_rresp;
                rvalid_reg <= 1;
                m_rready <= 0;
            end
            if (rvalid_reg && read_ack_sync2) begin
                rvalid_reg <= 0;
            end
        end
    end

    // Synchronize read_ack to s_clk
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_ack_sync1 <= 0;
            read_ack_sync2 <= 0;
        end else begin
            read_ack_sync1 <= read_ack;
            read_ack_sync2 <= read_ack_sync1;
        end
    end

    // Assign read data to slave interface
    assign s_axil_rdata = rdata_reg;
    assign s_axil_rresp = rresp_reg;
    assign s_axil_rvalid = rvalid_reg;

    // Master read signals
    assign m_axil_rready = rvalid_reg;

    // Assign master write signals
    assign m_axil_awaddr = m_awaddr;
    assign m_axil_awprot = m_awprot;
    assign m_axil_wdata = m_wdata;
    assign m_axil_wstrb = m_wstrb;
    assign m_axil_bready = m_bready;

    // Assign master read signals
    assign m_axil_araddr = m_araddr;
    assign m_axil_arprot = m_arprot;
    assign m_axil_rready = m_rready;

endmodule
