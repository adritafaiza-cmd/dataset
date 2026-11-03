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
     * CDC Handshake and Data Modules
     */

    // AW Channel
    cdc_handshake #(.WIDTH(1)) aw_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_valid(s_axil_awvalid), .s_ready(s_axil_awready),
        .m_valid(m_axil_awvalid), .m_ready(m_axil_awready)
    );

    cdc_data #(.WIDTH(ADDR_WIDTH)) awaddr_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_awaddr), .m_data(m_axil_awaddr)
    );

    cdc_data #(.WIDTH(3)) awprot_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_awprot), .m_data(m_axil_awprot)
    );

    // W Channel
    cdc_handshake #(.WIDTH(1)) w_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_valid(s_axil_wvalid), .s_ready(s_axil_wready),
        .m_valid(m_axil_wvalid), .m_ready(m_axil_wready)
    );

    cdc_data #(.WIDTH(DATA_WIDTH)) wdata_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_wdata), .m_data(m_axil_wdata)
    );

    cdc_data #(.WIDTH(STRB_WIDTH)) wstrb_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_wstrb), .m_data(m_axil_wstrb)
    );

    // B Channel
    cdc_handshake #(.WIDTH(1)) b_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_valid(m_axil_bvalid), .s_ready(m_axil_bready),
        .m_valid(s_axil_bvalid), .m_ready(s_axil_bready)
    );

    cdc_data #(.WIDTH(2)) bresp_cdc (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_bresp), .m_data(s_axil_bresp)
    );

    // AR Channel
    cdc_handshake #(.WIDTH(1)) ar_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_valid(s_axil_arvalid), .s_ready(s_axil_arready),
        .m_valid(m_axil_arvalid), .m_ready(m_axil_arready)
    );

    cdc_data #(.WIDTH(ADDR_WIDTH)) araddr_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_araddr), .m_data(m_axil_araddr)
    );

    cdc_data #(.WIDTH(3)) arprot_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_arprot), .m_data(m_axil_arprot)
    );

    // R Channel
    cdc_handshake #(.WIDTH(1)) r_cdc (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_valid(m_axil_rvalid), .s_ready(m_axil_rready),
        .m_valid(s_axil_rvalid), .m_ready(s_axil_rready)
    );

    cdc_data #(.WIDTH(DATA_WIDTH)) rdata_cdc (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_rdata), .m_data(s_axil_rdata)
    );

    cdc_data #(.WIDTH(2)) rresp_cdc (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_rresp), .m_data(s_axil_rresp)
    );

endmodule

module cdc_handshake #(
    parameter WIDTH = 1
)
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire m_clk,
    input  wire m_rst,
    input  wire s_valid,
    output wire s_ready,
    output wire m_valid,
    input  wire m_ready
);

    reg [WIDTH-1:0] s_valid_reg;
    reg [WIDTH-1:0] m_valid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_valid_reg <= 0;
        else
            s_valid_reg <= s_valid;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_valid_reg <= 0;
        else
            m_valid_reg <= s_valid_reg;
    end

    assign s_ready = m_valid_reg & m_ready;
    assign m_valid = s_valid_reg;

endmodule

module cdc_data #(
    parameter WIDTH = 32
)
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire m_clk,
    input  wire m_rst,
    input  wire [WIDTH-1:0] s_data,
    output wire [WIDTH-1:0] m_data
);

    reg [WIDTH-1:0] s_data_reg1;
    reg [WIDTH-1:0] s_data_reg2;
    reg [WIDTH-1:0] m_data_reg1;
    reg [WIDTH-1:0] m_data_reg2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_data_reg1 <= 0;
            s_data_reg2 <= 0;
        end else begin
            s_data_reg1 <= s_data;
            s_data_reg2 <= s_data_reg1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_data_reg1 <= 0;
            m_data_reg2 <= 0;
        end else begin
            m_data_reg1 <= s_data_reg2;
            m_data_reg2 <= m_data_reg1;
        end
    end

    assign m_data = m_data_reg2;

endmodule
