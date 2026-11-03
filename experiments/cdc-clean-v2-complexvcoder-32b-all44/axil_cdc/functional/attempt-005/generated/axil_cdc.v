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

    // Internal signals
    reg [ADDR_WIDTH+3:0]          s_aw_fifo_data;
    reg                           s_aw_fifo_valid;
    wire                          s_aw_fifo_ready;

    reg [DATA_WIDTH+STRB_WIDTH:0] s_w_fifo_data;
    reg                           s_w_fifo_valid;
    wire                          s_w_fifo_ready;

    reg [ADDR_WIDTH+3:0]          s_ar_fifo_data;
    reg                           s_ar_fifo_valid;
    wire                          s_ar_fifo_ready;

    reg [ADDR_WIDTH+3:0]          m_aw_fifo_data;
    reg                           m_aw_fifo_valid;
    wire                          m_aw_fifo_ready;

    reg [DATA_WIDTH+STRB_WIDTH:0] m_w_fifo_data;
    reg                           m_w_fifo_valid;
    wire                          m_w_fifo_ready;

    reg [ADDR_WIDTH+3:0]          m_ar_fifo_data;
    reg                           m_ar_fifo_valid;
    wire                          m_ar_fifo_ready;

    reg [1:0]                     m_bresp;
    reg                           m_bvalid;
    reg [DATA_WIDTH-1:0]          m_rdata;
    reg [1:0]                     m_rresp;
    reg                           m_rvalid;

    // FIFO for AW channel from slave to master
    fifo_async #(.WIDTH(ADDR_WIDTH+4))
    fifo_aw (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_awaddr, s_axil_awprot, s_axil_awvalid}),
        .s_valid(s_axil_awvalid),
        .s_ready(s_aw_fifo_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(m_aw_fifo_data),
        .m_valid(m_aw_fifo_valid),
        .m_ready(m_aw_fifo_ready)
    );

    // FIFO for W channel from slave to master
    fifo_async #(.WIDTH(DATA_WIDTH+STRB_WIDTH+1))
    fifo_w (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_wdata, s_axil_wstrb, s_axil_wvalid}),
        .s_valid(s_axil_wvalid),
        .s_ready(s_w_fifo_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(m_w_fifo_data),
        .m_valid(m_w_fifo_valid),
        .m_ready(m_w_fifo_ready)
    );

    // FIFO for AR channel from slave to master
    fifo_async #(.WIDTH(ADDR_WIDTH+4))
    fifo_ar (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_data({s_axil_araddr, s_axil_arprot, s_axil_arvalid}),
        .s_valid(s_axil_arvalid),
        .s_ready(s_ar_fifo_ready),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_data(m_ar_fifo_data),
        .m_valid(m_ar_fifo_valid),
        .m_ready(m_ar_fifo_ready)
    );

    // FIFO for B channel from master to slave
    fifo_async #(.WIDTH(3))
    fifo_b (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data({m_axil_bresp, m_axil_bvalid}),
        .s_valid(m_axil_bvalid),
        .s_ready(m_axil_bready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data({m_bresp, m_bvalid}),
        .m_valid(m_bvalid),
        .m_ready(s_axil_bready)
    );

    // FIFO for R channel from master to slave
    fifo_async #(.WIDTH(DATA_WIDTH+3))
    fifo_r (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .s_valid(m_axil_rvalid),
        .s_ready(m_axil_rready),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .m_data({m_rdata, m_rresp, m_rvalid}),
        .m_valid(m_rvalid),
        .m_ready(s_axil_rready)
    );

    // Slave AW channel
    assign s_axil_awready = s_aw_fifo_ready;

    // Slave W channel
    assign s_axil_wready = s_w_fifo_ready;

    // Slave B channel
    assign s_axil_bresp = m_bresp;
    assign s_axil_bvalid = m_bvalid;

    // Slave AR channel
    assign s_axil_arready = s_ar_fifo_ready;

    // Slave R channel
    assign s_axil_rdata = m_rdata;
    assign s_axil_rresp = m_rresp;
    assign s_axil_rvalid = m_rvalid;

    // Master AW channel
    assign m_axil_awaddr = m_aw_fifo_data[ADDR_WIDTH+3:4];
    assign m_axil_awprot = m_aw_fifo_data[3:1];
    assign m_axil_awvalid = m_aw_fifo_data[0];

    // Master W channel
    assign m_axil_wdata = m_w_fifo_data[DATA_WIDTH+STRB_WIDTH:STRB_WIDTH+1];
    assign m_axil_wstrb = m_w_fifo_data[STRB_WIDTH:1];
    assign m_axil_wvalid = m_w_fifo_data[0];

    // Master B channel
    assign m_axil_bready = m_bvalid;

    // Master AR channel
    assign m_axil_araddr = m_ar_fifo_data[ADDR_WIDTH+3:4];
    assign m_axil_arprot = m_ar_fifo_data[3:1];
    assign m_axil_arvalid = m_ar_fifo_data[0];

    // Master R channel
    assign m_axil_rready = m_rvalid;

endmodule

module fifo_async #
(
    parameter WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [WIDTH-1:0]       s_data,
    input  wire                   s_valid,
    output wire                   s_ready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output reg [WIDTH-1:0]        m_data,
    output reg                    m_valid,
    input  wire                   m_ready
);

    reg [WIDTH-1:0]               s_reg;
    reg                           s_valid_reg;
    reg [WIDTH-1:0]               m_reg;
    reg                           m_valid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_reg <= 0;
            s_valid_reg <= 0;
        end else begin
            if (s_ready && s_valid) begin
                s_reg <= s_data;
                s_valid_reg <= 1;
            end else if (m_ready) begin
                s_valid_reg <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_reg <= 0;
            m_valid_reg <= 0;
        end else begin
            if (m_ready && m_valid_reg) begin
                m_valid_reg <= 0;
            end else if (s_valid_reg) begin
                m_reg <= s_reg;
                m_valid_reg <= 1;
            end
        end
    end

    assign s_ready = ~s_valid_reg || m_ready;

endmodule
