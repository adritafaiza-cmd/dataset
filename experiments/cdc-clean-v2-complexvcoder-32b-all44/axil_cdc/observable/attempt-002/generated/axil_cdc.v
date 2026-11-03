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

    // AX Write Address Channel
    cdc_sync #(.WIDTH(ADDR_WIDTH)) awaddr_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_awaddr), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_awaddr)
    );
    cdc_sync #(.WIDTH(3)) awprot_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_awprot), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_awprot)
    );
    cdc_sync #(.WIDTH(1)) awvalid_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_awvalid), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_awvalid)
    );
    cdc_sync #(.WIDTH(1)) awready_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_awready), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_awready)
    );

    // AX Write Data Channel
    cdc_sync #(.WIDTH(DATA_WIDTH)) wdata_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_wdata), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_wdata)
    );
    cdc_sync #(.WIDTH(STRB_WIDTH)) wstrb_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_wstrb), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_wstrb)
    );
    cdc_sync #(.WIDTH(1)) wvalid_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_wvalid), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_wvalid)
    );
    cdc_sync #(.WIDTH(1)) wready_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_wready), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_wready)
    );

    // AX Write Response Channel
    cdc_sync #(.WIDTH(2)) bresp_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_bresp), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_bresp)
    );
    cdc_sync #(.WIDTH(1)) bvalid_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_bvalid), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_bvalid)
    );
    cdc_sync #(.WIDTH(1)) bready_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_bready), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_bready)
    );

    // AX Read Address Channel
    cdc_sync #(.WIDTH(ADDR_WIDTH)) araddr_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_araddr), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_araddr)
    );
    cdc_sync #(.WIDTH(3)) arprot_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_arprot), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_arprot)
    );
    cdc_sync #(.WIDTH(1)) arvalid_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_arvalid), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_arvalid)
    );
    cdc_sync #(.WIDTH(1)) arready_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_arready), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_arready)
    );

    // AX Read Data Channel
    cdc_sync #(.WIDTH(DATA_WIDTH)) rdata_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_rdata), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_rdata)
    );
    cdc_sync #(.WIDTH(2)) rresp_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_rresp), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_rresp)
    );
    cdc_sync #(.WIDTH(1)) rvalid_sync (
        .src_clk(m_clk), .src_rst(m_rst), .in(m_axil_rvalid), .dst_clk(s_clk), .dst_rst(s_rst), .out(s_axil_rvalid)
    );
    cdc_sync #(.WIDTH(1)) rready_sync (
        .src_clk(s_clk), .src_rst(s_rst), .in(s_axil_rready), .dst_clk(m_clk), .dst_rst(m_rst), .out(m_axil_rready)
    );

endmodule

module cdc_sync #
(
    parameter WIDTH = 1
)
(
    input  wire                     src_clk,
    input  wire                     src_rst,
    input  wire [WIDTH-1:0]         in,
    input  wire                     dst_clk,
    input  wire                     dst_rst,
    output reg [WIDTH-1:0]          out
);

    reg [WIDTH-1:0] reg1;
    reg [WIDTH-1:0] reg2;

    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst)
            reg1 <= {WIDTH{1'b0}};
        else
            reg1 <= in;
    end

    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            reg2 <= {WIDTH{1'b0}};
            out  <= {WIDTH{1'b0}};
        end else begin
            reg2 <= reg1;
            out  <= reg2;
        end
    end

endmodule
