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

    /*
     * Write transaction crossing
     */
    axil_cdc_crossing #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) write_crossing (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_awaddr(s_axil_awaddr),
        .src_awprot(s_axil_awprot),
        .src_awvalid(s_axil_awvalid),
        .src_awready(s_axil_awready),
        .src_wdata(s_axil_wdata),
        .src_wstrb(s_axil_wstrb),
        .src_wvalid(s_axil_wvalid),
        .src_wready(s_axil_wready),
        .src_rdata(1'b0), // Not used for write crossing
        .src_rresp(2'b0), // Not used for write crossing
        .src_rvalid(1'b0), // Not used for write crossing
        .src_rready(1'b1), // Not used for write crossing
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_awaddr(m_axil_awaddr),
        .dst_awprot(m_axil_awprot),
        .dst_awvalid(m_axil_awvalid),
        .dst_awready(m_axil_awready),
        .dst_wdata(m_axil_wdata),
        .dst_wstrb(m_axil_wstrb),
        .dst_wvalid(m_axil_wvalid),
        .dst_wready(m_axil_wready),
        .dst_rdata(), // Not used for write crossing
        .dst_rresp(), // Not used for write crossing
        .dst_rvalid(), // Not used for write crossing
        .dst_rready()  // Not used for write crossing
    );

    /*
     * Read transaction crossing
     */
    axil_cdc_crossing #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) read_crossing (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_awaddr(s_axil_araddr),
        .src_awprot(s_axil_arprot),
        .src_awvalid(s_axil_arvalid),
        .src_awready(s_axil_arready),
        .src_wdata(1'b0), // Not used for read crossing
        .src_wstrb(1'b0), // Not used for read crossing
        .src_wvalid(1'b0), // Not used for read crossing
        .src_wready(1'b1), // Not used for read crossing
        .src_rdata(s_axil_rdata),
        .src_rresp(s_axil_rresp),
        .src_rvalid(s_axil_rvalid),
        .src_rready(s_axil_rready),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_awaddr(m_axil_araddr),
        .dst_awprot(m_axil_arprot),
        .dst_awvalid(m_axil_arvalid),
        .dst_awready(m_axil_arready),
        .dst_wdata(), // Not used for read crossing
        .dst_wstrb(), // Not used for read crossing
        .dst_wvalid(), // Not used for read crossing
        .dst_wready(), // Not used for read crossing
        .dst_rdata(m_axil_rdata),
        .dst_rresp(m_axil_rresp),
        .dst_rvalid(m_axil_rvalid),
        .dst_rready(m_axil_rready)
    );

    /*
     * Bresp transaction crossing
     */
    axil_cdc_crossing #(
        .DATA_WIDTH(2), // For bresp
        .ADDR_WIDTH(1), // Placeholder, not used
        .STRB_WIDTH(1)  // Placeholder, not used
    ) bresp_crossing (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_awaddr(m_axil_bresp), // Use bresp as awaddr
        .src_awprot(2'b0), // Not used
        .src_awvalid(m_axil_bvalid),
        .src_awready(m_axil_bready),
        .src_wdata(1'b0), // Not used for bresp crossing
        .src_wstrb(1'b0), // Not used for bresp crossing
        .src_wvalid(1'b0), // Not used for bresp crossing
        .src_wready(1'b1), // Not used for bresp crossing
        .src_rdata(1'b0), // Not used for bresp crossing
        .src_rresp(2'b0), // Not used for bresp crossing
        .src_rvalid(1'b0), // Not used for bresp crossing
        .src_rready(1'b1), // Not used for bresp crossing
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_awaddr(s_axil_bresp), // Use bresp as awaddr
        .dst_awprot(), // Not used
        .dst_awvalid(s_axil_bvalid),
        .dst_awready(s_axil_bready),
        .dst_wdata(), // Not used for bresp crossing
        .dst_wstrb(), // Not used for bresp crossing
        .dst_wvalid(), // Not used for bresp crossing
        .dst_wready(), // Not used for bresp crossing
        .dst_rdata(), // Not used for bresp crossing
        .dst_rresp(), // Not used for bresp crossing
        .dst_rvalid(), // Not used for bresp crossing
        .dst_rready()  // Not used for bresp crossing
    );

endmodule

module axil_cdc_crossing #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   src_clk,
    input  wire                   src_rst,
    input  wire [ADDR_WIDTH-1:0]  src_awaddr,
    input  wire [2:0]             src_awprot,
    input  wire                   src_awvalid,
    output wire                   src_awready,
    input  wire [DATA_WIDTH-1:0]  src_wdata,
    input  wire [STRB_WIDTH-1:0]  src_wstrb,
    input  wire                   src_wvalid,
    output wire                   src_wready,
    output wire [DATA_WIDTH-1:0]  src_rdata,
    output wire [1:0]             src_rresp,
    output wire                   src_rvalid,
    input  wire                   src_rready,
    input  wire                   dst_clk,
    input  wire                   dst_rst,
    output wire [ADDR_WIDTH-1:0]  dst_awaddr,
    output wire [2:0]             dst_awprot,
    output wire                   dst_awvalid,
    input  wire                   dst_awready,
    output wire [DATA_WIDTH-1:0]  dst_wdata,
    output wire [STRB_WIDTH-1:0]  dst_wstrb,
    output wire                   dst_wvalid,
    input  wire                   dst_wready,
    input  wire [DATA_WIDTH-1:0]  dst_rdata,
    input  wire [1:0]             dst_rresp,
    input  wire                   dst_rvalid,
    output wire                   dst_rready
);

    reg [ADDR_WIDTH-1:0]  awaddr_reg [1:0];
    reg [2:0]             awprot_reg [1:0];
    reg                   awvalid_reg [1:0];
    reg                   awready_reg;
    reg [DATA_WIDTH-1:0]  wdata_reg [1:0];
    reg [STRB_WIDTH-1:0]  wstrb_reg [1:0];
    reg                   wvalid_reg [1:0];
    reg                   wready_reg;
    reg [DATA_WIDTH-1:0]  rdata_reg [1:0];
    reg [1:0]             rresp_reg [1:0];
    reg                   rvalid_reg [1:0];
    reg                   rready_reg;

    reg [1:0] aw_stage;
    reg [1:0] w_stage;
    reg [1:0] r_stage;

    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst) begin
            aw_stage <= 2'b00;
            awready_reg <= 1'b0;
            awaddr_reg[0] <= {ADDR_WIDTH{1'b0}};
            awaddr_reg[1] <= {ADDR_WIDTH{1'b0}};
            awprot_reg[0] <= 3'b000;
            awprot_reg[1] <= 3'b000;
            awvalid_reg[0] <= 1'b0;
            awvalid_reg[1] <= 1'b0;
            w_stage <= 2'b00;
            wready_reg <= 1'b0;
            wdata_reg[0] <= {DATA_WIDTH{1'b0}};
            wdata_reg[1] <= {DATA_WIDTH{1'b0}};
            wstrb_reg[0] <= {STRB_WIDTH{1'b0}};
            wstrb_reg[1] <= {STRB_WIDTH{1'b0}};
            wvalid_reg[0] <= 1'b0;
            wvalid_reg[1] <= 1'b0;
        end else begin
            // AW Channel
            if (awready_reg && src_awvalid) begin
                awaddr_reg[aw_stage] <= src_awaddr;
                awprot_reg[aw_stage] <= src_awprot;
                awvalid_reg[aw_stage] <= src_awvalid;
                aw_stage <= aw_stage + 1;
            end
            awready_reg <= ~awvalid_reg[aw_stage];

            // W Channel
            if (wready_reg && src_wvalid) begin
                wdata_reg[w_stage] <= src_wdata;
                wstrb_reg[w_stage] <= src_wstrb;
                wvalid_reg[w_stage] <= src_wvalid;
                w_stage <= w_stage + 1;
            end
            wready_reg <= ~wvalid_reg[w_stage];
        end
    end

    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            r_stage <= 2'b00;
            rready_reg <= 1'b0;
            rdata_reg[0] <= {DATA_WIDTH{1'b0}};
            rdata_reg[1] <= {DATA_WIDTH{1'b0}};
            rresp_reg[0] <= 2'b00;
            rresp_reg[1] <= 2'b00;
            rvalid_reg[0] <= 1'b0;
            rvalid_reg[1] <= 1'b0;
        end else begin
            // AW Channel
            if (dst_awready && awvalid_reg[aw_stage]) begin
                dst_awaddr <= awaddr_reg[aw_stage];
                dst_awprot <= awprot_reg[aw_stage];
                dst_awvalid <= awvalid_reg[aw_stage];
                aw_stage <= aw_stage - 1;
            end else begin
                dst_awvalid <= 1'b0;
            end

            // W Channel
            if (dst_wready && wvalid_reg[w_stage]) begin
                dst_wdata <= wdata_reg[w_stage];
                dst_wstrb <= wstrb_reg[w_stage];
                dst_wvalid <= wvalid_reg[w_stage];
                w_stage <= w_stage - 1;
            end else begin
                dst_wvalid <= 1'b0;
            end

            // R Channel
            if (dst_rvalid && dst_rready) begin
                rdata_reg[r_stage] <= dst_rdata;
                rresp_reg[r_stage] <= dst_rresp;
                rvalid_reg[r_stage] <= dst_rvalid;
                r_stage <= r_stage + 1;
            end
            rready_reg <= ~rvalid_reg[r_stage];
        end
    end

    assign src_awready = awready_reg;
    assign src_wready = wready_reg;
    assign src_rdata = rdata_reg[r_stage];
    assign src_rresp = rresp_reg[r_stage];
    assign src_rvalid = rvalid_reg[r_stage];
    assign dst_rready = rready_reg;

endmodule
