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
     * CDC Handshake instances
     */
    cdc_handshake aw_handshake (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_valid(s_axil_awvalid),
        .s_ready(s_axil_awready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_ready(m_axil_awready),
        .m_valid(m_axil_awvalid)
    );

    cdc_handshake w_handshake (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_valid(s_axil_wvalid),
        .s_ready(s_axil_wready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_ready(m_axil_wready),
        .m_valid(m_axil_wvalid)
    );

    cdc_handshake b_handshake (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_valid(m_axil_bvalid),
        .s_ready(m_axil_bready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_ready(s_axil_bready),
        .m_valid(s_axil_bvalid)
    );

    cdc_handshake ar_handshake (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_valid(s_axil_arvalid),
        .s_ready(s_axil_arready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_ready(m_axil_arready),
        .m_valid(m_axil_arvalid)
    );

    cdc_handshake r_handshake (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_valid(m_axil_rvalid),
        .s_ready(m_axil_rready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_ready(s_axil_rready),
        .m_valid(s_axil_rvalid)
    );

    /*
     * CDC Sync instances
     */
    cdc_sync #(.WIDTH(ADDR_WIDTH)) awaddr_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_awaddr),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_awaddr)
    );

    cdc_sync #(.WIDTH(3)) awprot_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_awprot),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_awprot)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) wdata_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_wdata),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_wdata)
    );

    cdc_sync #(.WIDTH(STRB_WIDTH)) wstrb_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_wstrb),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_wstrb)
    );

    cdc_sync #(.WIDTH(2)) bresp_sync (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_in(m_axil_bresp),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_out(s_axil_bresp)
    );

    cdc_sync #(.WIDTH(ADDR_WIDTH)) araddr_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_araddr),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_araddr)
    );

    cdc_sync #(.WIDTH(3)) arprot_sync (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_in(s_axil_arprot),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_out(m_axil_arprot)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) rdata_sync (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_in(m_axil_rdata),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_out(s_axil_rdata)
    );

    cdc_sync #(.WIDTH(2)) rresp_sync (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_in(m_axil_rresp),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_out(s_axil_rresp)
    );

endmodule

module cdc_handshake
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire s_valid,
    output wire s_ready,
    input  wire m_clk,
    input  wire m_rst,
    input  wire m_ready,
    output wire m_valid
);

    reg s_valid_r, s_ready_r;
    reg m_valid_r, m_ready_r;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_valid_r <= 0;
        else
            s_valid_r <= s_valid;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ready_r <= 0;
        else
            m_ready_r <= m_ready;
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_ready_r <= 0;
        else
            s_ready_r <= m_ready_r & ~s_valid_r;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_valid_r <= 0;
        else
            m_valid_r <= s_valid_r & m_ready_r;
    end

    assign s_ready = s_ready_r;
    assign m_valid = m_valid_r;

endmodule

module cdc_sync #(
    parameter WIDTH = 1
)
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire [WIDTH-1:0] s_in,
    input  wire m_clk,
    input  wire m_rst,
    output wire [WIDTH-1:0] m_out
);

    reg [WIDTH-1:0] s_in_r1, s_in_r2;
    reg [WIDTH-1:0] m_out_r1, m_out_r2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_r1 <= 0;
            s_in_r2 <= 0;
        end else begin
            s_in_r1 <= s_in;
            s_in_r2 <= s_in_r1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_out_r1 <= 0;
            m_out_r2 <= 0;
        end else begin
            m_out_r1 <= s_in_r2;
            m_out_r2 <= m_out_r1;
        end
    end

    assign m_out = m_out_r2;

endmodule
