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

    // Synchronizers for AXI4-Lite signals
    wire [ADDR_WIDTH-1:0] s_awaddr_sync;
    wire [2:0] s_awprot_sync;
    wire s_awvalid_sync;
    wire m_awready_sync;

    wire [DATA_WIDTH-1:0] s_wdata_sync;
    wire [STRB_WIDTH-1:0] s_wstrb_sync;
    wire s_wvalid_sync;
    wire m_wready_sync;

    wire [1:0] m_bresp_sync;
    wire m_bvalid_sync;

    wire [ADDR_WIDTH-1:0] s_araddr_sync;
    wire [2:0] s_arprot_sync;
    wire s_arvalid_sync;
    wire m_arready_sync;

    wire [DATA_WIDTH-1:0] m_rdata_sync;
    wire [1:0] m_rresp_sync;
    wire m_rvalid_sync;

    // Instantiate synchronizers
    synchronizer #(.WIDTH(ADDR_WIDTH)) awaddr_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_awaddr), .data_out(s_awaddr_sync)
    );
    synchronizer #(.WIDTH(3)) awprot_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_awprot), .data_out(s_awprot_sync)
    );
    synchronizer #(.WIDTH(1)) awvalid_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_awvalid), .data_out(s_awvalid_sync)
    );
    synchronizer #(.WIDTH(1)) awready_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_awready), .data_out(m_awready_sync)
    );

    synchronizer #(.WIDTH(DATA_WIDTH)) wdata_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_wdata), .data_out(s_wdata_sync)
    );
    synchronizer #(.WIDTH(STRB_WIDTH)) wstrb_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_wstrb), .data_out(s_wstrb_sync)
    );
    synchronizer #(.WIDTH(1)) wvalid_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_wvalid), .data_out(s_wvalid_sync)
    );
    synchronizer #(.WIDTH(1)) wready_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_wready), .data_out(m_wready_sync)
    );

    synchronizer #(.WIDTH(2)) bresp_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_bresp), .data_out(m_bresp_sync)
    );
    synchronizer #(.WIDTH(1)) bvalid_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_bvalid), .data_out(m_bvalid_sync)
    );

    synchronizer #(.WIDTH(ADDR_WIDTH)) araddr_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_araddr), .data_out(s_araddr_sync)
    );
    synchronizer #(.WIDTH(3)) arprot_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_arprot), .data_out(s_arprot_sync)
    );
    synchronizer #(.WIDTH(1)) arvalid_synchronizer (
        .clk(s_clk), .rst(s_rst), .data_in(s_axil_arvalid), .data_out(s_arvalid_sync)
    );
    synchronizer #(.WIDTH(1)) arready_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_arready), .data_out(m_arready_sync)
    );

    synchronizer #(.WIDTH(DATA_WIDTH)) rdata_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_rdata), .data_out(m_rdata_sync)
    );
    synchronizer #(.WIDTH(2)) rresp_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_rresp), .data_out(m_rresp_sync)
    );
    synchronizer #(.WIDTH(1)) rvalid_synchronizer (
        .clk(m_clk), .rst(m_rst), .data_in(m_axil_rvalid), .data_out(m_rvalid_sync)
    );

    // AXI4-Lite master interface
    assign m_axil_awaddr = s_awaddr_sync;
    assign m_axil_awprot = s_awprot_sync;
    assign m_axil_awvalid = s_awvalid_sync;
    assign s_axil_awready = m_awready_sync;

    assign m_axil_wdata = s_wdata_sync;
    assign m_axil_wstrb = s_wstrb_sync;
    assign m_axil_wvalid = s_wvalid_sync;
    assign s_axil_wready = m_wready_sync;

    assign s_axil_bresp = m_bresp_sync;
    assign s_axil_bvalid = m_bvalid_sync;
    assign m_axil_bready = s_axil_bready;

    assign m_axil_araddr = s_araddr_sync;
    assign m_axil_arprot = s_arprot_sync;
    assign m_axil_arvalid = s_arvalid_sync;
    assign s_axil_arready = m_arready_sync;

    assign s_axil_rdata = m_rdata_sync;
    assign s_axil_rresp = m_rresp_sync;
    assign s_axil_rvalid = m_rvalid_sync;
    assign m_axil_rready = s_axil_rready;

endmodule

module synchronizer #(
    parameter WIDTH = 1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [WIDTH-1:0]       data_in,
    output wire [WIDTH-1:0]       data_out
);

    reg [WIDTH-1:0] sync_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            sync_reg <= {WIDTH{1'b0}};
        else
            sync_reg <= data_in;
    end

    assign data_out = sync_reg;

endmodule
