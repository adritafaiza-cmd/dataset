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
     * Handshake control for AW channel
     */
    cdc_handshake #(.WIDTH(1)) aw_handshake (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(s_axil_awvalid),
        .local_ready(s_axil_awready),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(m_axil_awvalid),
        .remote_ready(m_axil_awready)
    );

    /*
     * Handshake control for W channel
     */
    cdc_handshake #(.WIDTH(1)) w_handshake (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(s_axil_wvalid),
        .local_ready(s_axil_wready),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(m_axil_wvalid),
        .remote_ready(m_axil_wready)
    );

    /*
     * Handshake control for B channel
     */
    cdc_handshake #(.WIDTH(1)) b_handshake (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(s_axil_bready),
        .local_ready(s_axil_bvalid),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(m_axil_bvalid),
        .remote_ready(m_axil_bready)
    );

    /*
     * Handshake control for AR channel
     */
    cdc_handshake #(.WIDTH(1)) ar_handshake (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(s_axil_arvalid),
        .local_ready(s_axil_arready),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(m_axil_arvalid),
        .remote_ready(m_axil_arready)
    );

    /*
     * Handshake control for R channel
     */
    cdc_handshake #(.WIDTH(1)) r_handshake (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(s_axil_rready),
        .local_ready(s_axil_rvalid),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(m_axil_rvalid),
        .remote_ready(m_axil_rready)
    );

    /*
     * Data synchronization for AW channel
     */
    cdc_data #(.WIDTH(ADDR_WIDTH+3)) aw_data (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(aw_handshake.local_valid),
        .local_ready(aw_handshake.local_ready),
        .local_data({s_axil_awaddr, s_axil_awprot}),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(aw_handshake.remote_valid),
        .remote_ready(aw_handshake.remote_ready),
        .remote_data({m_axil_awaddr, m_axil_awprot})
    );

    /*
     * Data synchronization for W channel
     */
    cdc_data #(.WIDTH(DATA_WIDTH+STRB_WIDTH)) w_data (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(w_handshake.local_valid),
        .local_ready(w_handshake.local_ready),
        .local_data({s_axil_wdata, s_axil_wstrb}),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(w_handshake.remote_valid),
        .remote_ready(w_handshake.remote_ready),
        .remote_data({m_axil_wdata, m_axil_wstrb})
    );

    /*
     * Data synchronization for B channel
     */
    cdc_data #(.WIDTH(2)) b_data (
        .local_clk(m_clk),
        .local_rst(m_rst),
        .local_valid(b_handshake.remote_valid),
        .local_ready(b_handshake.remote_ready),
        .local_data(m_axil_bresp),
        .remote_clk(s_clk),
        .remote_rst(s_rst),
        .remote_valid(b_handshake.local_valid),
        .remote_ready(b_handshake.local_ready),
        .remote_data(s_axil_bresp)
    );

    /*
     * Data synchronization for AR channel
     */
    cdc_data #(.WIDTH(ADDR_WIDTH+3)) ar_data (
        .local_clk(s_clk),
        .local_rst(s_rst),
        .local_valid(ar_handshake.local_valid),
        .local_ready(ar_handshake.local_ready),
        .local_data({s_axil_araddr, s_axil_arprot}),
        .remote_clk(m_clk),
        .remote_rst(m_rst),
        .remote_valid(ar_handshake.remote_valid),
        .remote_ready(ar_handshake.remote_ready),
        .remote_data({m_axil_araddr, m_axil_arprot})
    );

    /*
     * Data synchronization for R channel
     */
    cdc_data #(.WIDTH(DATA_WIDTH+2)) r_data (
        .local_clk(m_clk),
        .local_rst(m_rst),
        .local_valid(r_handshake.remote_valid),
        .local_ready(r_handshake.remote_ready),
        .local_data({m_axil_rdata, m_axil_rresp}),
        .remote_clk(s_clk),
        .remote_rst(s_rst),
        .remote_valid(r_handshake.local_valid),
        .remote_ready(r_handshake.local_ready),
        .remote_data({s_axil_rdata, s_axil_rresp})
    );

endmodule

module cdc_handshake #
(
    parameter WIDTH = 1
)
(
    input  wire local_clk,
    input  wire local_rst,
    input  wire local_valid,
    output wire local_ready,
    input  wire remote_clk,
    input  wire remote_rst,
    output wire remote_valid,
    input  wire remote_ready
);

    reg [WIDTH-1:0] valid_sync;

    always @(posedge remote_clk or posedge remote_rst) begin
        if (remote_rst)
            valid_sync <= 0;
        else
            valid_sync <= {valid_sync[WIDTH-2:0], local_valid};
    end

    assign remote_valid = valid_sync[WIDTH-1];
    assign local_ready  = remote_ready;

endmodule

module cdc_data #
(
    parameter WIDTH = 32
)
(
    input  wire local_clk,
    input  wire local_rst,
    input  wire local_valid,
    input  wire local_ready,
    input  wire [WIDTH-1:0] local_data,
    input  wire remote_clk,
    input  wire remote_rst,
    output wire remote_valid,
    output wire remote_ready,
    output wire [WIDTH-1:0] remote_data
);

    reg [WIDTH-1:0] data_sync;
    reg [1:0]       valid_sync;

    always @(posedge remote_clk or posedge remote_rst) begin
        if (remote_rst) begin
            data_sync  <= 0;
            valid_sync <= 0;
        end else begin
            if (local_ready) begin
                data_sync  <= local_data;
                valid_sync <= {valid_sync[0], local_valid};
            end
        end
    end

    assign remote_data  = data_sync;
    assign remote_valid = valid_sync[1];
    assign remote_ready = ~valid_sync[1] | local_ready;

endmodule
