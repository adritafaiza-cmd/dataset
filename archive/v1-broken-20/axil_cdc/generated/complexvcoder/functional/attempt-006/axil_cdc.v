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

    wire [ADDR_WIDTH-1:0] slave_awaddr;
    wire [2:0] slave_awprot;
    wire slave_awvalid;
    wire slave_awready;
    wire [DATA_WIDTH-1:0] slave_wdata;
    wire [STRB_WIDTH-1:0] slave_wstrb;
    wire slave_wvalid;
    wire slave_wready;
    wire [1:0] slave_bresp;
    wire slave_bvalid;
    wire slave_bready;
    wire [ADDR_WIDTH-1:0] slave_araddr;
    wire [2:0] slave_arprot;
    wire slave_arvalid;
    wire slave_arready;
    wire [DATA_WIDTH-1:0] slave_rdata;
    wire [1:0] slave_rresp;
    wire slave_rvalid;
    wire slave_rready;

    wire [ADDR_WIDTH-1:0] master_awaddr;
    wire [2:0] master_awprot;
    wire master_awvalid;
    wire master_awready;
    wire [DATA_WIDTH-1:0] master_wdata;
    wire [STRB_WIDTH-1:0] master_wstrb;
    wire master_wvalid;
    wire master_wready;
    wire [1:0] master_bresp;
    wire master_bvalid;
    wire master_bready;
    wire [ADDR_WIDTH-1:0] master_araddr;
    wire [2:0] master_arprot;
    wire master_arvalid;
    wire master_arready;
    wire [DATA_WIDTH-1:0] master_rdata;
    wire [1:0] master_rresp;
    wire master_rvalid;
    wire master_rready;

    axil_cdc_slave slave_inst (
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
        .awready_in(slave_awready),
        .wdata_out(slave_wdata),
        .wstrb_out(slave_wstrb),
        .wvalid_out(slave_wvalid),
        .wready_in(slave_wready),
        .bresp_in(slave_bresp),
        .bvalid_in(slave_bvalid),
        .bready_out(slave_bready),
        .araddr_out(slave_araddr),
        .arprot_out(slave_arprot),
        .arvalid_out(slave_arvalid),
        .arready_in(slave_arready),
        .rdata_in(slave_rdata),
        .rresp_in(slave_rresp),
        .rvalid_in(slave_rvalid),
        .rready_out(slave_rready)
    );

    axil_cdc_master master_inst (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_axil_awaddr),
        .awprot(m_axil_awprot),
        .awvalid(m_axil_awvalid),
        .awready(m_axil_awready),
        .wdata(m_axil_wdata),
        .wstrb(m_axil_wstrb),
        .wvalid(m_axil_wvalid),
        .wready(m_axil_wready),
        .bresp(m_axil_bresp),
        .bvalid(m_axil_bvalid),
        .bready(m_axil_bready),
        .araddr(m_axil_araddr),
        .arprot(m_axil_arprot),
        .arvalid(m_axil_arvalid),
        .arready(m_axil_arready),
        .rdata(m_axil_rdata),
        .rresp(m_axil_rresp),
        .rvalid(m_axil_rvalid),
        .rready(m_axil_rready),
        .awaddr_out(master_awaddr),
        .awprot_out(master_awprot),
        .awvalid_out(master_awvalid),
        .awready_in(master_awready),
        .wdata_out(master_wdata),
        .wstrb_out(master_wstrb),
        .wvalid_out(master_wvalid),
        .wready_in(master_wready),
        .bresp_in(master_bresp),
        .bvalid_in(master_bvalid),
        .bready_out(master_bready),
        .araddr_out(master_araddr),
        .arprot_out(master_arprot),
        .arvalid_out(master_arvalid),
        .arready_in(master_arready),
        .rdata_in(master_rdata),
        .rresp_in(master_rresp),
        .rvalid_in(master_rvalid),
        .rready_out(master_rready)
    );

endmodule

module axil_cdc_slave (
    input  wire                   clk,
    input  wire                   rst,
    input  wire [ADDR_WIDTH-1:0]  awaddr,
    input  wire [2:0]             awprot,
    input  wire                   awvalid,
    output wire                   awready,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [STRB_WIDTH-1:0]  wstrb,
    input  wire                   wvalid,
    output wire                   wready,
    output wire [1:0]             bresp,
    output wire                   bvalid,
    input  wire                   bready,
    input  wire [ADDR_WIDTH-1:0]  araddr,
    input  wire [2:0]             arprot,
    input  wire                   arvalid,
    output wire                   arready,
    output wire [DATA_WIDTH-1:0]  rdata,
    output wire [1:0]             rresp,
    output wire                   rvalid,
    input  wire                   rready,
    output wire [ADDR_WIDTH-1:0]  awaddr_out,
    output wire [2:0]             awprot_out,
    output wire                   awvalid_out,
    input  wire                   awready_in,
    output wire [DATA_WIDTH-1:0]  wdata_out,
    output wire [STRB_WIDTH-1:0]  wstrb_out,
    output wire                   wvalid_out,
    input  wire                   wready_in,
    input  wire [1:0]             bresp_in,
    input  wire                   bvalid_in,
    output wire                   bready_out,
    output wire [ADDR_WIDTH-1:0]  araddr_out,
    output wire [2:0]             arprot_out,
    output wire                   arvalid_out,
    input  wire                   arready_in,
    input  wire [DATA_WIDTH-1:0]  rdata_in,
    input  wire [1:0]             rresp_in,
    input  wire                   rvalid_in,
    output wire                   rready_out
);

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg awvalid_reg;
    reg [2:0] awprot_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg arvalid_reg;
    reg [2:0] arprot_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;

    assign awready = (awvalid_reg && awready_in) || (!awvalid_reg && !awready_in);
    assign wready = (wvalid_reg && wready_in) || (!wvalid_reg && !wready_in);
    assign arready = (arvalid_reg && arready_in) || (!arvalid_reg && !arready_in);
    assign rready_out = rvalid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awaddr_reg <= 0;
            awvalid_reg <= 0;
            awprot_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            bresp_reg <= 0;
            bvalid_reg <= 0;
            araddr_reg <= 0;
            arvalid_reg <= 0;
            arprot_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
            rvalid_reg <= 0;
        end else begin
            if (awvalid && awready) begin
                awaddr_reg <= awaddr;
                awvalid_reg <= 0;
            end else if (awvalid) begin
                awvalid_reg <= 1;
            end

            if (wvalid && wready) begin
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;
                wvalid_reg <= 0;
            end else if (wvalid) begin
                wvalid_reg <= 1;
            end

            if (bvalid_in && bready_out) begin
                bresp_reg <= bresp_in;
                bvalid_reg <= 0;
            end else if (bvalid_in) begin
                bvalid_reg <= 1;
            end

            if (arvalid && arready) begin
                araddr_reg <= araddr;
                arvalid_reg <= 0;
            end else if (arvalid) begin
                arvalid_reg <= 1;
            end

            if (rvalid_in && rready_out) begin
                rdata_reg <= rdata_in;
                rresp_reg <= rresp_in;
                rvalid_reg <= 0;
            end else if (rvalid_in) begin
                rvalid_reg <= 1;
            end
        end
    end

    assign awaddr_out = awaddr_reg;
    assign awprot_out = awprot_reg;
    assign awvalid_out = awvalid_reg;
    assign wdata_out = wdata_reg;
    assign wstrb_out = wstrb_reg;
    assign wvalid_out = wvalid_reg;
    assign bresp_out = bresp_reg;
    assign bvalid_out = bvalid_reg;
    assign araddr_out = araddr_reg;
    assign arprot_out = arprot_reg;
    assign arvalid_out = arvalid_reg;
    assign rdata_out = rdata_reg;
    assign rresp_out = rresp_reg;
    assign rvalid_out = rvalid_reg;

endmodule

module axil_cdc_master (
    input  wire                   clk,
    input  wire                   rst,
    input  wire [ADDR_WIDTH-1:0]  awaddr,
    input  wire [2:0]             awprot,
    input  wire                   awvalid,
    output wire                   awready,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [STRB_WIDTH-1:0]  wstrb,
    input  wire                   wvalid,
    output wire                   wready,
    output wire [1:0]             bresp,
    output wire                   bvalid,
    input  wire                   bready,
    input  wire [ADDR_WIDTH-1:0]  araddr,
    input  wire [2:0]             arprot,
    input  wire                   arvalid,
    output wire                   arready,
    output wire [DATA_WIDTH-1:0]  rdata,
    output wire [1:0]             rresp,
    output wire                   rvalid,
    input  wire                   rready,
    output wire [ADDR_WIDTH-1:0]  awaddr_out,
    output wire [2:0]             awprot_out,
    output wire                   awvalid_out,
    input  wire                   awready_in,
    output wire [DATA_WIDTH-1:0]  wdata_out,
    output wire [STRB_WIDTH-1:0]  wstrb_out,
    output wire                   wvalid_out,
    input  wire                   wready_in,
    input  wire [1:0]             bresp_in,
    input  wire                   bvalid_in,
    output wire                   bready_out,
    output wire [ADDR_WIDTH-1:0]  araddr_out,
    output wire [2:0]             arprot_out,
    output wire                   arvalid_out,
    input  wire                   arready_in,
    input  wire [DATA_WIDTH-1:0]  rdata_in,
    input  wire [1:0]             rresp_in,
    input  wire                   rvalid_in,
    output wire                   rready_out
);

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg awvalid_reg;
    reg [2:0] awprot_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg wvalid_reg;
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg arvalid_reg;
    reg [2:0] arprot_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;
    reg rvalid_reg;

    assign awready = (awvalid_reg && awready_in) || (!awvalid_reg && !awready_in);
    assign wready = (wvalid_reg && wready_in) || (!wvalid_reg && !wready_in);
    assign arready = (arvalid_reg && arready_in) || (!arvalid_reg && !arready_in);
    assign rready_out = rvalid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awaddr_reg <= 0;
            awvalid_reg <= 0;
            awprot_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wvalid_reg <= 0;
            bresp_reg <= 0;
            bvalid_reg <= 0;
            araddr_reg <= 0;
            arvalid_reg <= 0;
            arprot_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
            rvalid_reg <= 0;
        end else begin
            if (awvalid && awready) begin
                awaddr_reg <= awaddr;
                awvalid_reg <= 0;
            end else if (awvalid) begin
                awvalid_reg <= 1;
            end

            if (wvalid && wready) begin
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;
                wvalid_reg <= 0;
            end else if (wvalid) begin
                wvalid_reg <= 1;
            end

            if (bvalid_in && bready_out) begin
                bresp_reg <= bresp_in;
                bvalid_reg <= 0;
            end else if (bvalid_in) begin
                bvalid_reg <= 1;
            end

            if (arvalid && arready) begin
                araddr_reg <= araddr;
                arvalid_reg <= 0;
            end else if (arvalid) begin
                arvalid_reg <= 1;
            end

            if (rvalid_in && rready_out) begin
                rdata_reg <= rdata_in;
                rresp_reg <= rresp_in;
                rvalid_reg <= 0;
            end else if (rvalid_in) begin
                rvalid_reg <= 1;
            end
        end
    end

    assign awaddr_out = awaddr_reg;
    assign awprot_out = awprot_reg;
    assign awvalid_out = awvalid_reg;
    assign wdata_out = wdata_reg;
    assign wstrb_out = wstrb_reg;
    assign wvalid_out = wvalid_reg;
    assign bresp_out = bresp_reg;
    assign bvalid_out = bvalid_reg;
    assign araddr_out = araddr_reg;
    assign arprot_out = arprot_reg;
    assign arvalid_out = arvalid_reg;
    assign rdata_out = rdata_reg;
    assign rresp_out = rresp_reg;
    assign rvalid_out = rvalid_reg;

endmodule
