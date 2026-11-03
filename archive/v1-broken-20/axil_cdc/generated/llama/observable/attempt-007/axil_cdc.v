module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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

reg [ADDR_WIDTH-1:0] awaddr;
reg [2:0] awprot;
reg [DATA_WIDTH-1:0] wdata;
reg [STRB_WIDTH-1:0] wstrb;
reg [ADDR_WIDTH-1:0] araddr;
reg [2:0] arprot;

reg [1:0] bresp;
reg [1:0] rresp;
reg [DATA_WIDTH-1:0] rdata;

reg awvalid;
reg wvalid;
reg arvalid;
reg bready;
reg rready;

reg [1:0] state;
reg [1:0] next_state;

always @(posedge s_clk)
begin
    if (s_rst)
    begin
        state <= 0;
        awvalid <= 0;
        wvalid <= 0;
        arvalid <= 0;
        bready <= 0;
        rready <= 0;
    end
    else
    begin
        state <= next_state;
        awvalid <= 0;
        wvalid <= 0;
        arvalid <= 0;
        bready <= 0;
        rready <= 0;

        case (state)
            0:
            begin
                if (s_axil_awvalid)
                begin
                    awaddr <= s_axil_awaddr;
                    awprot <= s_axil_awprot;
                    awvalid <= 1;
                    next_state <= 1;
                end
                else if (s_axil_arvalid)
                begin
                    araddr <= s_axil_araddr;
                    arprot <= s_axil_arprot;
                    arvalid <= 1;
                    next_state <= 2;
                end
                else
                begin
                    next_state <= 0;
                end
            end
            1:
            begin
                if (s_axil_wvalid)
                begin
                    wdata <= s_axil_wdata;
                    wstrb <= s_axil_wstrb;
                    wvalid <= 1;
                    next_state <= 3;
                end
                else
                begin
                    next_state <= 1;
                end
            end
            2:
            begin
                next_state <= 2;
            end
            3:
            begin
                bready <= 1;
                next_state <= 0;
            end
            default:
            begin
                next_state <= 0;
            end
        endcase
    end
end

always @(posedge m_clk)
begin
    if (m_rst)
    begin
        m_axil_awaddr <= 0;
        m_axil_awprot <= 0;
        m_axil_awvalid <= 0;
        m_axil_wdata <= 0;
        m_axil_wstrb <= 0;
        m_axil_wvalid <= 0;
        m_axil_araddr <= 0;
        m_axil_arprot <= 0;
        m_axil_arvalid <= 0;
        m_axil_rready <= 0;
        m_axil_bready <= 0;
    end
    else
    begin
        m_axil_awaddr <= awaddr;
        m_axil_awprot <= awprot;
        m_axil_awvalid <= awvalid;
        m_axil_wdata <= wdata;
        m_axil_wstrb <= wstrb;
        m_axil_wvalid <= wvalid;
        m_axil_araddr <= araddr;
        m_axil_arprot <= arprot;
        m_axil_arvalid <= arvalid;
        m_axil_rready <= rready;
        m_axil_bready <= bready;
    end
end

always @(posedge m_clk)
begin
    if (m_rst)
    begin
        s_axil_bresp <= 0;
        s_axil_rresp <= 0;
        s_axil_rdata <= 0;
        s_axil_bvalid <= 0;
        s_axil_rvalid <= 0;
    end
    else
    begin
        s_axil_bresp <= m_axil_bresp;
        s_axil_rresp <= m_axil_rresp;
        s_axil_rdata <= m_axil_rdata;
        s_axil_bvalid <= m_axil_bvalid;
        s_axil_rvalid <= m_axil_rvalid;
    end
end

assign s_axil_awready = (state == 0) && (s_axil_awvalid);
assign s_axil_wready = (state == 1) && (s_axil_wvalid);
assign s_axil_arready = (state == 0) && (s_axil_arvalid);
assign s_axil_rready = (state == 0) && (s_axil_rvalid);
assign s_axil_bready = (state == 3) && (s_axil_bvalid);

assign m_axil_rready = rready;
assign m_axil_bready = bready;

endmodule
