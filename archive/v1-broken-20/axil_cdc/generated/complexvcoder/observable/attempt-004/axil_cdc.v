`timescale 1ns / 1ps

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

    wire [ADDR_WIDTH-1:0]  slave_awaddr;
    wire [2:0]             slave_awprot;
    wire                   slave_awvalid;
    wire                   slave_awready;
    wire [DATA_WIDTH-1:0]  slave_wdata;
    wire [STRB_WIDTH-1:0]  slave_wstrb;
    wire                   slave_wvalid;
    wire                   slave_wready;
    wire [1:0]             slave_bresp;
    wire                   slave_bvalid;
    wire                   slave_bready;
    wire [ADDR_WIDTH-1:0]  slave_araddr;
    wire [2:0]             slave_arprot;
    wire                   slave_arvalid;
    wire                   slave_arready;
    wire [DATA_WIDTH-1:0]  slave_rdata;
    wire [1:0]             slave_rresp;
    wire                   slave_rvalid;
    wire                   slave_rready;

    wire [ADDR_WIDTH-1:0]  master_awaddr;
    wire [2:0]             master_awprot;
    wire                   master_awvalid;
    wire                   master_awready;
    wire [DATA_WIDTH-1:0]  master_wdata;
    wire [STRB_WIDTH-1:0]  master_wstrb;
    wire                   master_wvalid;
    wire                   master_wready;
    wire [1:0]             master_bresp;
    wire                   master_bvalid;
    wire                   master_bready;
    wire [ADDR_WIDTH-1:0]  master_araddr;
    wire [2:0]             master_arprot;
    wire                   master_arvalid;
    wire                   master_arready;
    wire [DATA_WIDTH-1:0]  master_rdata;
    wire [1:0]             master_rresp;
    wire                   master_rvalid;
    wire                   master_rready;

    axil_cdc_slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH)) slave_inst (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(s_axil_awready),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(s_axil_wready),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(s_axil_bready),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(s_axil_arready),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(s_axil_rready),
        .awaddr_out(slave_awaddr),
        .awprot_out(slave_awprot),
        .awvalid_out(slave_awvalid),
        .awready_out(slave_awready),
        .wdata_out(slave_wdata),
        .wstrb_out(slave_wstrb),
        .wvalid_out(slave_wvalid),
        .wready_out(slave_wready),
        .bresp_out(slave_bresp),
        .bvalid_out(slave_bvalid),
        .bready_out(slave_bready),
        .araddr_out(slave_araddr),
        .arprot_out(slave_arprot),
        .arvalid_out(slave_arvalid),
        .arready_out(slave_arready),
        .rdata_out(slave_rdata),
        .rresp_out(slave_rresp),
        .rvalid_out(slave_rvalid),
        .rready_out(slave_rready)
    );

    axil_cdc_master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH)) master_inst (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr_out(master_awaddr),
        .awprot_out(master_awprot),
        .awvalid_out(master_awvalid),
        .awready_in(m_axil_awready),
        .wdata_out(master_wdata),
        .wstrb_out(master_wstrb),
        .wvalid_out(master_wvalid),
        .wready_in(m_axil_wready),
        .bresp_in(m_axil_bresp),
        .bvalid_in(m_axil_bvalid),
        .bready_out(master_bready),
        .araddr_out(master_araddr),
        .arprot_out(master_arprot),
        .arvalid_out(master_arvalid),
        .arready_in(m_axil_arready),
        .rdata_in(m_axil_rdata),
        .rresp_in(m_axil_rresp),
        .rvalid_in(m_axil_rvalid),
        .rready_out(master_rready)
    );

endmodule
