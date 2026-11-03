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

    wire [ADDR_WIDTH-1:0] s_awaddr_reg, m_awaddr_reg;
    wire [2:0] s_awprot_reg, m_awprot_reg;
    wire s_awvalid_reg, m_awvalid_reg;
    wire s_awready_reg, m_awready_reg;
    wire [DATA_WIDTH-1:0] s_wdata_reg, m_wdata_reg;
    wire [STRB_WIDTH-1:0] s_wstrb_reg, m_wstrb_reg;
    wire s_wvalid_reg, m_wvalid_reg;
    wire s_wready_reg, m_wready_reg;
    wire [1:0] s_bresp_reg, m_bresp_reg;
    wire s_bvalid_reg, m_bvalid_reg;
    wire s_bready_reg, m_bready_reg;
    wire [ADDR_WIDTH-1:0] s_araddr_reg, m_araddr_reg;
    wire [2:0] s_arprot_reg, m_arprot_reg;
    wire s_arvalid_reg, m_arvalid_reg;
    wire s_arready_reg, m_arready_reg;
    wire [DATA_WIDTH-1:0] s_rdata_reg, m_rdata_reg;
    wire [1:0] s_rresp_reg, m_rresp_reg;
    wire s_rvalid_reg, m_rvalid_reg;
    wire s_rready_reg, m_rready_reg;

    axil_slave
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    )
    slave
    (
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
        .awaddr_out(m_awaddr_reg),
        .awprot_out(m_awprot_reg),
        .awvalid_out(m_awvalid_reg),
        .awready_in(m_awready_reg),
        .wdata_out(m_wdata_reg),
        .wstrb_out(m_wstrb_reg),
        .wvalid_out(m_wvalid_reg),
        .wready_in(m_wready_reg),
        .bresp_in(m_bresp_reg),
        .bvalid_in(m_bvalid_reg),
        .bready_out(m_bready_reg),
        .araddr_out(m_araddr_reg),
        .arprot_out(m_arprot_reg),
        .arvalid_out(m_arvalid_reg),
        .arready_in(m_arready_reg),
        .rdata_in(m_rdata_reg),
        .rresp_in(m_rresp_reg),
        .rvalid_in(m_rvalid_reg),
        .rready_out(m_rready_reg)
    );

    axil_master
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    )
    master
    (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_awaddr_reg),
        .awprot(m_awprot_reg),
        .awvalid(m_awvalid_reg),
        .awready(s_axil_awready),
        .wdata(m_wdata_reg),
        .wstrb(m_wstrb_reg),
        .wvalid(m_wvalid_reg),
        .wready(s_axil_wready),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(s_axil_bready),
        .araddr(m_araddr_reg),
        .arprot(m_arprot_reg),
        .arvalid(m_arvalid_reg),
        .arready(s_axil_arready),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(s_axil_rready)
    );

endmodule

module axil_slave
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire [2:0] awprot,
    input wire awvalid,
    output wire awready,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [STRB_WIDTH-1:0] wstrb,
    input wire wvalid,
    output wire wready,
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire [2:0] arprot,
    input wire arvalid,
    output wire arready,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready,
    output wire [ADDR_WIDTH-1:0] awaddr_out,
    output wire [2:0] awprot_out,
    output wire awvalid_out,
    input wire awready_in,
    output wire [DATA_WIDTH-1:0] wdata_out,
    output wire [STRB_WIDTH-1:0] wstrb_out,
    output wire wvalid_out,
    input wire wready_in,
    input wire [1:0] bresp_in,
    input wire bvalid_in,
    output wire bready_out,
    input wire [ADDR_WIDTH-1:0] araddr_out,
    input wire [2:0] arprot_out,
    output wire arvalid_out,
    input wire arready_in,
    input wire [DATA_WIDTH-1:0] rdata_in,
    input wire [1:0] rresp_in,
    input wire rvalid_in,
    output wire rready_out
);

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    wire awready_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    wire wready_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    wire bready_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    wire arready_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;
    wire rready_reg;

    assign awaddr_out = awaddr_reg;
    assign awprot_out = awprot_reg;
    assign awvalid_out = awvalid_reg;
    assign wdata_out = wdata_reg;
    assign wstrb_out = wstrb_reg;
    assign wvalid_out = wvalid_reg;
    assign araddr_out = araddr_reg;
    assign arprot_out = arprot_reg;
    assign arvalid_out = arvalid_reg;
    assign rdata_in = rdata_reg;
    assign rresp_in = rresp_reg;
    assign rvalid_in = rvalid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            if (awvalid && !awready_reg) begin
                awaddr_reg <= awaddr;
                awprot_reg <= awprot;
                awvalid_reg <= 1;
                awready_reg <= 0;
            end else if (awready_reg) begin
                awvalid_reg <= 0;
                awready_reg <= 1;
            end

            if (wvalid && !wready_reg) begin
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;
                wvalid_reg <= 1;
                wready_reg <= 0;
            end else if (wready_reg) begin
                wvalid_reg <= 0;
                wready_reg <= 1;
            end

            if (arvalid && !arready_reg) begin
                araddr_reg <= araddr;
                arprot_reg <= arprot;
                arvalid_reg <= 1;
                arready_reg <= 0;
            end else if (arready_reg) begin
                arvalid_reg <= 0;
                arready_reg <= 1;
            end

            if (bready_reg) begin
                bready_reg <= 0;
            end

            if (rready_reg) begin
                rready_reg <= 0;
            end
        end
    end

    assign awready = awready_reg;
    assign wready = wready_reg;
    assign bresp = bresp_reg;
    assign bvalid = bvalid_reg;
    assign arready = arready_reg;
    assign rdata = rdata_reg;
    assign rresp = rresp_reg;
    assign rvalid = rvalid_reg;

endmodule

module axil_master
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire [2:0] awprot,
    input wire awvalid,
    output wire awready,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [STRB_WIDTH-1:0] wstrb,
    input wire wvalid,
    output wire wready,
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire [2:0] arprot,
    input wire arvalid,
    output wire arready,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready
);

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    wire awready_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    wire wready_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    wire bready_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    wire arready_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;
    wire rready_reg;

    assign awaddr_reg = awaddr;
    assign awprot_reg = awprot;
    assign awvalid_reg = awvalid;
    assign wdata_reg = wdata;
    assign wstrb_reg = wstrb;
    assign wvalid_reg = wvalid;
    assign araddr_reg = araddr;
    assign arprot_reg = arprot;
    assign arvalid_reg = arvalid;
    assign bready_reg = bready;
    assign rready_reg = rready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awaddr_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            if (awvalid_reg && !awready_reg) begin
                awready_reg <= 1;
            end else if (awready_reg) begin
                awready_reg <= 0;
            end

            if (wvalid_reg && !wready_reg) begin
                wready_reg <= 1;
            end else if (wready_reg) begin
                wready_reg <= 0;
            end

            if (arvalid_reg && !arready_reg) begin
                arready_reg <= 1;
            end else if (arready_reg) begin
                arready_reg <= 0;
            end

            if (bready_reg) begin
                bvalid_reg <= 0;
            end

            if (rready_reg) begin
                rvalid_reg <= 0;
            end
        end
    end

    assign awready = awready_reg;
    assign wready = wready_reg;
    assign bresp = bresp_reg;
    assign bvalid = bvalid_reg;
    assign arready = arready_reg;
    assign rdata = rdata_reg;
    assign rresp = rresp_reg;
    assign rvalid = rvalid_reg;

endmodule
