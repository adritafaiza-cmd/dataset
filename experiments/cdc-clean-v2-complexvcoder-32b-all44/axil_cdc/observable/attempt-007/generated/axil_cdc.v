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
     * CDC instances for AW, W, B, AR, and R channels
     */
    cdc #(.DATA_WIDTH(ADDR_WIDTH + 3)) aw_cdc (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_data({s_axil_awaddr, s_axil_awprot}),
        .src_valid(s_axil_awvalid),
        .src_ready(s_axil_awready),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_data({m_axil_awaddr, m_axil_awprot}),
        .dst_valid(m_axil_awvalid),
        .dst_ready(m_axil_awready)
    );

    cdc #(.DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)) w_cdc (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_data({s_axil_wdata, s_axil_wstrb}),
        .src_valid(s_axil_wvalid),
        .src_ready(s_axil_wready),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_data({m_axil_wdata, m_axil_wstrb}),
        .dst_valid(m_axil_wvalid),
        .dst_ready(m_axil_wready)
    );

    cdc #(.DATA_WIDTH(2 + 1)) b_cdc (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_data({m_axil_bresp, m_axil_bvalid}),
        .src_valid(m_axil_bvalid),
        .src_ready(m_axil_bready),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_data({s_axil_bresp, s_axil_bvalid}),
        .dst_valid(s_axil_bvalid),
        .dst_ready(s_axil_bready)
    );

    cdc #(.DATA_WIDTH(ADDR_WIDTH + 3)) ar_cdc (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_data({s_axil_araddr, s_axil_arprot}),
        .src_valid(s_axil_arvalid),
        .src_ready(s_axil_arready),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_data({m_axil_araddr, m_axil_arprot}),
        .dst_valid(m_axil_arvalid),
        .dst_ready(m_axil_arready)
    );

    cdc #(.DATA_WIDTH(DATA_WIDTH + 2 + 1)) r_cdc (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .src_valid(m_axil_rvalid),
        .src_ready(m_axil_rready),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_data({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .dst_valid(s_axil_rvalid),
        .dst_ready(s_axil_rready)
    );

endmodule

module cdc #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   src_clk,
    input  wire                   src_rst,
    input  wire [DATA_WIDTH-1:0]  src_data,
    input  wire                   src_valid,
    output wire                   src_ready,
    input  wire                   dst_clk,
    input  wire                   dst_rst,
    output wire [DATA_WIDTH-1:0]  dst_data,
    output wire                   dst_valid,
    input  wire                   dst_ready
);

    reg [DATA_WIDTH-1:0] src_reg_data;
    reg [1:0]            src_reg_valid;
    reg [1:0]            dst_reg_valid;
    reg [1:0]            dst_reg_ready;

    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst) begin
            src_reg_valid <= 2'b00;
            src_reg_data  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (src_ready) begin
                src_reg_valid <= {src_reg_valid[0], src_valid};
                src_reg_data  <= src_data;
            end
        end
    end

    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            dst_reg_valid <= 2'b00;
            dst_reg_ready <= 2'b00;
        end else begin
            dst_reg_valid <= {dst_reg_valid[0], src_reg_valid[1]};
            if (dst_reg_ready[1] && dst_ready) begin
                dst_reg_ready <= 2'b00;
            end else if (dst_ready && ~dst_reg_ready[1]) begin
                dst_reg_ready <= 2'b01;
            end
        end
    end

    assign dst_valid = dst_reg_valid[1];
    assign dst_data  = src_reg_data;
    assign src_ready = ~dst_reg_ready[1] || dst_ready;

endmodule
