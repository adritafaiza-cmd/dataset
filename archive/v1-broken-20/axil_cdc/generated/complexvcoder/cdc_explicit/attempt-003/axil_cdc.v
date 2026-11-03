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

    wire [ADDR_WIDTH-1:0]  s_awaddr_sync, s_awprot_sync, s_araddr_sync, s_arprot_sync;
    wire                   s_awvalid_sync, s_arvalid_sync;
    wire                   m_awready_sync, m_arready_sync;
    wire [DATA_WIDTH-1:0]  s_wdata_sync, s_wstrb_sync;
    wire                   s_wvalid_sync;
    wire                   m_wready_sync;
    wire [1:0]             s_bresp_sync, s_bresp_sync_out;
    wire                   s_bvalid_sync, m_bready_sync;
    wire [DATA_WIDTH-1:0]  m_rdata_sync, s_rdata_sync_out;
    wire [1:0]             m_rresp_sync, s_rresp_sync_out;
    wire                   m_rvalid_sync, s_rready_sync;

    cdc_sync #(
        .WIDTH(ADDR_WIDTH),
        .POLARITY(1)
    ) s_to_m_awaddr_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_awaddr),
        .out(s_awaddr_sync)
    );
    cdc_sync #(
        .WIDTH(3),
        .POLARITY(1)
    ) s_to_m_awprot_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_awprot),
        .out(s_awprot_sync)
    );
    cdc_sync #(
        .WIDTH(ADDR_WIDTH),
        .POLARITY(1)
    ) s_to_m_araddr_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_araddr),
        .out(s_araddr_sync)
    );
    cdc_sync #(
        .WIDTH(3),
        .POLARITY(1)
    ) s_to_m_arprot_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_arprot),
        .out(s_arprot_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) s_to_m_awvalid_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_awvalid),
        .out(s_awvalid_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) s_to_m_arvalid_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_arvalid),
        .out(s_arvalid_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) m_to_s_awready_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_awready),
        .out(m_awready_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) m_to_s_arready_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_arready),
        .out(m_arready_sync)
    );
    cdc_sync #(
        .WIDTH(DATA_WIDTH),
        .POLARITY(1)
    ) s_to_m_wdata_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_wdata),
        .out(s_wdata_sync)
    );
    cdc_sync #(
        .WIDTH(STRB_WIDTH),
        .POLARITY(1)
    ) s_to_m_wstrb_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_wstrb),
        .out(s_wstrb_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) s_to_m_wvalid_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_wvalid),
        .out(s_wvalid_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) m_to_s_wready_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_wready),
        .out(m_wready_sync)
    );
    cdc_sync #(
        .WIDTH(2),
        .POLARITY(1)
    ) m_to_s_bresp_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_bresp),
        .out(m_bresp_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) m_to_s_bvalid_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_bvalid),
        .out(m_bvalid_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) s_to_m_bready_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_bready),
        .out(s_bready_sync)
    );
    cdc_sync #(
        .WIDTH(DATA_WIDTH),
        .POLARITY(1)
    ) m_to_s_rdata_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_rdata),
        .out(m_rdata_sync)
    );
    cdc_sync #(
        .WIDTH(2),
        .POLARITY(1)
    ) m_to_s_rresp_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_rresp),
        .out(m_rresp_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) m_to_s_rvalid_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(m_axil_rvalid),
        .out(m_rvalid_sync)
    );
    cdc_sync #(
        .WIDTH(1),
        .POLARITY(1)
    ) s_to_m_rready_sync (
        .clk(s_clk),
        .rst(s_rst),
        .in(s_axil_rready),
        .out(s_rready_sync)
    );

    axil_cdc_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) slave (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_awaddr_sync),
        .awprot(s_awprot_sync),
        .awvalid(s_awvalid_sync),
        .awready(m_awready_sync),
        .wdata(s_wdata_sync),
        .wstrb(s_wstrb_sync),
        .wvalid(s_wvalid_sync),
        .wready(m_wready_sync),
        .bresp(s_bresp_sync_out),
        .bvalid(s_bvalid_sync),
        .bready(s_bready_sync),
        .araddr(s_araddr_sync),
        .arprot(s_arprot_sync),
        .arvalid(s_arvalid_sync),
        .arready(m_arready_sync),
        .rdata(s_rdata_sync_out),
        .rresp(s_rresp_sync_out),
        .rvalid(s_rvalid_sync),
        .rready(s_rready_sync)
    );

    axil_cdc_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) master (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_axil_awaddr),
        .awprot(m_axil_awprot),
        .awvalid(m_axil_awvalid),
        .awready(s_awready_sync),
        .wdata(m_axil_wdata),
        .wstrb(m_axil_wstrb),
        .wvalid(m_axil_wvalid),
        .wready(s_wready_sync),
        .bresp(m_bresp_sync),
        .bvalid(m_bvalid_sync),
        .bready(m_bready_sync),
        .araddr(m_axil_araddr),
        .arprot(m_axil_arprot),
        .arvalid(m_axil_arvalid),
        .arready(s_arready_sync),
        .rdata(m_rdata_sync),
        .rresp(m_rresp_sync),
        .rvalid(m_rvalid_sync),
        .rready(m_axil_rready)
    );

endmodule
