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

    reg [ADDR_WIDTH-1:0] s_awaddr_reg;
    reg [2:0] s_awprot_reg;
    reg s_awvalid_reg;
    reg [DATA_WIDTH-1:0] s_wdata_reg;
    reg [STRB_WIDTH-1:0] s_wstrb_reg;
    reg s_wvalid_reg;
    reg s_bready_reg;
    reg [ADDR_WIDTH-1:0] s_araddr_reg;
    reg [2:0] s_arprot_reg;
    reg s_arvalid_reg;
    reg s_rready_reg;

    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [2:0] m_awprot_reg;
    reg m_awvalid_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;
    reg m_wvalid_reg;
    reg m_bready_reg;
    reg [ADDR_WIDTH-1:0] m_araddr_reg;
    reg [2:0] m_arprot_reg;
    reg m_arvalid_reg;
    reg m_rready_reg;

    reg [1:0] s_bresp_reg;
    reg s_bvalid_reg;
    reg [DATA_WIDTH-1:0] s_rdata_reg;
    reg [1:0] s_rresp_reg;
    reg s_rvalid_reg;

    reg [1:0] m_bresp_reg;
    reg m_bvalid_reg;
    reg [DATA_WIDTH-1:0] m_rdata_reg;
    reg [1:0] m_rresp_reg;
    reg m_rvalid_reg;

    // Slave to Master synchronization
    cdc_sync #(.WIDTH(ADDR_WIDTH)) awaddr_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_awaddr),
        .dout(m_awaddr_reg)
    );

    cdc_sync #(.WIDTH(3)) awprot_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_awprot),
        .dout(m_awprot_reg)
    );

    cdc_sync #(.WIDTH(1)) awvalid_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_awvalid),
        .dout(m_awvalid_reg)
    );

    cdc_sync #(.WIDTH(1)) awready_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_awready),
        .dout(s_axil_awready)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) wdata_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_wdata),
        .dout(m_wdata_reg)
    );

    cdc_sync #(.WIDTH(STRB_WIDTH)) wstrb_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_wstrb),
        .dout(m_wstrb_reg)
    );

    cdc_sync #(.WIDTH(1)) wvalid_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_wvalid),
        .dout(m_wvalid_reg)
    );

    cdc_sync #(.WIDTH(1)) wready_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_wready),
        .dout(s_axil_wready)
    );

    cdc_sync #(.WIDTH(1)) bready_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_bready),
        .dout(m_bready_reg)
    );

    cdc_sync #(.WIDTH(1)) bresp_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_bresp),
        .dout(s_bresp_reg)
    );

    cdc_sync #(.WIDTH(1)) bvalid_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_bvalid),
        .dout(s_bvalid_reg)
    );

    cdc_sync #(.WIDTH(ADDR_WIDTH)) araddr_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_araddr),
        .dout(m_araddr_reg)
    );

    cdc_sync #(.WIDTH(3)) arprot_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_arprot),
        .dout(m_arprot_reg)
    );

    cdc_sync #(.WIDTH(1)) arvalid_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_arvalid),
        .dout(m_arvalid_reg)
    );

    cdc_sync #(.WIDTH(1)) arready_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_arready),
        .dout(s_axil_arready)
    );

    cdc_sync #(.WIDTH(1)) rready_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_rready),
        .dout(m_rready_reg)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) rdata_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_rdata),
        .dout(s_rdata_reg)
    );

    cdc_sync #(.WIDTH(1)) rresp_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_rresp),
        .dout(s_rresp_reg)
    );

    cdc_sync #(.WIDTH(1)) rvalid_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(m_axil_rvalid),
        .dout(s_rvalid_reg)
    );

    // Assign master outputs
    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = m_awprot_reg;
    assign m_axil_awvalid = m_awvalid_reg;
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;
    assign m_axil_wvalid = m_wvalid_reg;
    assign m_axil_bready = m_bready_reg;
    assign m_axil_araddr = m_araddr_reg;
    assign m_axil_arprot = m_arprot_reg;
    assign m_axil_arvalid = m_arvalid_reg;
    assign m_axil_rready = m_rready_reg;

    // Assign slave outputs
    assign s_axil_bresp = s_bresp_reg;
    assign s_axil_bvalid = s_bvalid_reg;
    assign s_axil_rdata = s_rdata_reg;
    assign s_axil_rresp = s_rresp_reg;
    assign s_axil_rvalid = s_rvalid_reg;

endmodule

module cdc_sync #
(
    parameter WIDTH = 1
)
(
    input wire s_clk,
    input wire s_rst,
    input wire m_clk,
    input wire m_rst,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] dff1;
    reg [WIDTH-1:0] dff2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            dff1 <= 0;
        end else begin
            dff1 <= din;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            dff2 <= 0;
            dout <= 0;
        end else begin
            dff2 <= dff1;
            dout <= dff2;
        end
    end

endmodule
