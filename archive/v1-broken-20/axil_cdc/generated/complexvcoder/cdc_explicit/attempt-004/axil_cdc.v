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

    // Internal signals for AXI4-Lite slave to master
    wire [ADDR_WIDTH-1:0] s_axil_awaddr_m;
    wire [2:0] s_axil_awprot_m;
    wire s_axil_awvalid_m;
    wire s_axil_awready_s;
    wire [DATA_WIDTH-1:0] s_axil_wdata_m;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_m;
    wire s_axil_wvalid_m;
    wire s_axil_wready_s;
    wire [1:0] s_axil_bresp_m;
    wire s_axil_bvalid_m;
    wire s_axil_bready_s;
    wire [ADDR_WIDTH-1:0] s_axil_araddr_m;
    wire [2:0] s_axil_arprot_m;
    wire s_axil_arvalid_m;
    wire s_axil_arready_s;
    wire [DATA_WIDTH-1:0] s_axil_rdata_m;
    wire [1:0] s_axil_rresp_m;
    wire s_axil_rvalid_m;
    wire s_axil_rready_s;

    // Internal signals for AXI4-Lite master to slave
    wire [ADDR_WIDTH-1:0] m_axil_awaddr_s;
    wire [2:0] m_axil_awprot_s;
    wire m_axil_awvalid_s;
    wire m_axil_awready_m;
    wire [DATA_WIDTH-1:0] m_axil_wdata_s;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_s;
    wire m_axil_wvalid_s;
    wire m_axil_wready_m;
    wire [1:0] m_axil_bresp_s;
    wire m_axil_bvalid_s;
    wire m_axil_bready_m;
    wire [ADDR_WIDTH-1:0] m_axil_araddr_s;
    wire [2:0] m_axil_arprot_s;
    wire m_axil_arvalid_s;
    wire m_axil_arready_m;
    wire [DATA_WIDTH-1:0] m_axil_rdata_s;
    wire [1:0] m_axil_rresp_s;
    wire m_axil_rvalid_s;
    wire m_axil_rready_m;

    // AXI4-Lite slave to master interface
    assign s_axil_awaddr_m = s_axil_awaddr;
    assign s_axil_awprot_m = s_axil_awprot;
    assign s_axil_awvalid_m = s_axil_awvalid;
    assign s_axil_wdata_m = s_axil_wdata;
    assign s_axil_wstrb_m = s_axil_wstrb;
    assign s_axil_wvalid_m = s_axil_wvalid;
    assign s_axil_araddr_m = s_axil_araddr;
    assign s_axil_arprot_m = s_axil_arprot;
    assign s_axil_arvalid_m = s_axil_arvalid;

    assign s_axil_awready = s_axil_awready_s;
    assign s_axil_wready = s_axil_wready_s;
    assign s_axil_bresp = s_axil_bresp_m;
    assign s_axil_bvalid = s_axil_bvalid_m;
    assign s_axil_arready = s_axil_arready_s;
    assign s_axil_rdata = s_axil_rdata_m;
    assign s_axil_rresp = s_axil_rresp_m;
    assign s_axil_rvalid = s_axil_rvalid_m;

    // AXI4-Lite master to slave interface
    assign m_axil_awaddr_s = m_axil_awaddr;
    assign m_axil_awprot_s = m_axil_awprot;
    assign m_axil_awvalid_s = m_axil_awvalid;
    assign m_axil_wdata_s = m_axil_wdata;
    assign m_axil_wstrb_s = m_axil_wstrb;
    assign m_axil_wvalid_s = m_axil_wvalid;
    assign m_axil_araddr_s = m_axil_araddr;
    assign m_axil_arprot_s = m_axil_arprot;
    assign m_axil_arvalid_s = m_axil_arvalid;

    assign m_axil_awready = m_axil_awready_m;
    assign m_axil_wready = m_axil_wready_m;
    assign m_axil_bresp = m_axil_bresp_s;
    assign m_axil_bvalid = m_axil_bvalid_s;
    assign m_axil_arready = m_axil_arready_m;
    assign m_axil_rdata = m_axil_rdata_s;
    assign m_axil_rresp = m_axil_rresp_s;
    assign m_axil_rvalid = m_axil_rvalid_s;

    // Clock domain crossing logic for AXI4-Lite slave to master
    axil_crossing #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) axil_crossing_slv2m (
        .clk(s_clk),
        .rst(s_rst),
        .awaddr(s_axil_awaddr),
        .awprot(s_axil_awprot),
        .awvalid(s_axil_awvalid),
        .awready(s_axil_awready_m),
        .wdata(s_axil_wdata),
        .wstrb(s_axil_wstrb),
        .wvalid(s_axil_wvalid),
        .wready(s_axil_wready_m),
        .bresp(s_axil_bresp),
        .bvalid(s_axil_bvalid),
        .bready(s_axil_bready_m),
        .araddr(s_axil_araddr),
        .arprot(s_axil_arprot),
        .arvalid(s_axil_arvalid),
        .arready(s_axil_arready_m),
        .rdata(s_axil_rdata),
        .rresp(s_axil_rresp),
        .rvalid(s_axil_rvalid),
        .rready(s_axil_rready_m)
    );

    // Clock domain crossing logic for AXI4-Lite master to slave
    axil_crossing #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) axil_crossing_m2slv (
        .clk(m_clk),
        .rst(m_rst),
        .awaddr(m_axil_awaddr),
        .awprot(m_axil_awprot),
        .awvalid(m_axil_awvalid),
        .awready(m_axil_awready_s),
        .wdata(m_axil_wdata),
        .wstrb(m_axil_wstrb),
        .wvalid(m_axil_wvalid),
        .wready(m_axil_wready_s),
        .bresp(m_axil_bresp),
        .bvalid(m_axil_bvalid),
        .bready(m_axil_bready_s),
        .araddr(m_axil_araddr),
        .arprot(m_axil_arprot),
        .arvalid(m_axil_arvalid),
        .arready(m_axil_arready_s),
        .rdata(m_axil_rdata),
        .rresp(m_axil_rresp),
        .rvalid(m_axil_rvalid),
        .rready(m_axil_rready_s)
    );

endmodule

module axil_crossing #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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
    input  wire                   rready
);

    // Write address channel
    wire awvalid_s;
    wire awready_s;
    wire [ADDR_WIDTH-1:0] awaddr_s;
    wire [2:0] awprot_s;

    // Write data channel
    wire wvalid_s;
    wire wready_s;
    wire [DATA_WIDTH-1:0] wdata_s;
    wire [STRB_WIDTH-1:0] wstrb_s;

    // Write response channel
    wire bvalid_s;
    wire bready_s;
    wire [1:0] bresp_s;

    // Read address channel
    wire arvalid_s;
    wire arready_s;
    wire [ADDR_WIDTH-1:0] araddr_s;
    wire [2:0] arprot_s;

    // Read data channel
    wire rvalid_s;
    wire rready_s;
    wire [DATA_WIDTH-1:0] rdata_s;
    wire [1:0] rresp_s;

    // Write address channel
    axil_crossing_channel #(
        .WIDTH(ADDR_WIDTH + 3)
    ) axil_crossing_aw (
        .clk(clk),
        .rst(rst),
        .valid(awvalid),
        .ready(awready),
        .data({awaddr, awprot}),
        .valid_out(awvalid_s),
        .ready_out(awready_s),
        .data_out({awaddr_s, awprot_s})
    );

    // Write data channel
    axil_crossing_channel #(
        .WIDTH(DATA_WIDTH + STRB_WIDTH)
    ) axil_crossing_w (
        .clk(clk),
        .rst(rst),
        .valid(wvalid),
        .ready(wready),
        .data({wdata, wstrb}),
        .valid_out(wvalid_s),
        .ready_out(wready_s),
        .data_out({wdata_s, wstrb_s})
    );

    // Write response channel
    axil_crossing_channel #(
        .WIDTH(2)
    ) axil_crossing_b (
        .clk(clk),
        .rst(rst),
        .valid(bvalid),
        .ready(bready),
        .data(bresp),
        .valid_out(bvalid_s),
        .ready_out(bready_s),
        .data_out(bresp_s)
    );

    // Read address channel
    axil_crossing_channel #(
        .WIDTH(ADDR_WIDTH + 3)
    ) axil_crossing_ar (
        .clk(clk),
        .rst(rst),
        .valid(arvalid),
        .ready(arready),
        .data({araddr, arprot}),
        .valid_out(arvalid_s),
        .ready_out(arready_s),
        .data_out({araddr_s, arprot_s})
    );

    // Read data channel
    axil_crossing_channel #(
        .WIDTH(DATA_WIDTH + 2)
    ) axil_crossing_r (
        .clk(clk),
        .rst(rst),
        .valid(rvalid),
        .ready(rready),
        .data({rdata, rresp}),
        .valid_out(rvalid_s),
        .ready_out(rready_s),
        .data_out({rdata_s, rresp_s})
    );

    // Connect slave to master
    assign awaddr_s = awaddr;
    assign awprot_s = awprot;
    assign wdata_s = wdata;
    assign wstrb_s = wstrb;
    assign araddr_s = araddr;
    assign arprot_s = arprot;

    assign awvalid = awvalid_s;
    assign wvalid = wvalid_s;
    assign arvalid = arvalid_s;

    assign awready = awready_s;
    assign wready = wready_s;
    assign arready = arready_s;

    assign bresp = bresp_s;
    assign bvalid = bvalid_s;
    assign rdata = rdata_s;
    assign rresp = rresp_s;
    assign rvalid = rvalid_s;

endmodule

module axil_crossing_channel #(
    parameter WIDTH = 32
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   valid,
    input  wire                   ready,
    input  wire [WIDTH-1:0]       data,
    output wire                   valid_out,
    output wire                   ready_out,
    output wire [WIDTH-1:0]       data_out
);

    reg [WIDTH-1:0] data_reg;
    reg valid_reg;
    reg ready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 0;
            valid_reg <= 0;
            ready_reg <= 0;
        end else begin
            if (valid && ready) begin
                data_reg <= data;
                valid_reg <= 1;
            end else begin
                valid_reg <= 0;
            end

            if (valid_out && ready_out) begin
                ready_reg <= 1;
            end else begin
                ready_reg <= 0;
            end
        end
    end

    assign data_out = data_reg;
    assign valid_out = valid_reg;
    assign ready_out = ready_reg;

endmodule
