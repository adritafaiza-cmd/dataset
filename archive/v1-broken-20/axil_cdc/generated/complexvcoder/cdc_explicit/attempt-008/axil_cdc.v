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

    // Internal signals for synchronization and handshaking
    wire [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
    wire [2:0] s_axil_awprot_reg;
    wire s_axil_awvalid_reg;
    wire s_axil_awready_reg;
    wire [DATA_WIDTH-1:0] s_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    wire s_axil_wvalid_reg;
    wire s_axil_wready_reg;
    wire s_axil_bresp_reg;
    wire s_axil_bvalid_reg;
    wire s_axil_araddr_reg;
    wire [2:0] s_axil_arprot_reg;
    wire s_axil_arvalid_reg;
    wire s_axil_arready_reg;
    wire [DATA_WIDTH-1:0] s_axil_rdata_reg;
    wire [1:0] s_axil_rresp_reg;
    wire s_axil_rvalid_reg;
    wire s_axil_rready_reg;

    wire [ADDR_WIDTH-1:0] m_axil_awaddr_reg;
    wire [2:0] m_axil_awprot_reg;
    wire m_axil_awvalid_reg;
    wire m_axil_awready_reg;
    wire [DATA_WIDTH-1:0] m_axil_wdata_reg;
    wire [STRB_WIDTH-1:0] m_axil_wstrb_reg;
    wire m_axil_wvalid_reg;
    wire m_axil_wready_reg;
    wire [1:0] m_axil_bresp_reg;
    wire m_axil_bvalid_reg;
    wire m_axil_araddr_reg;
    wire [2:0] m_axil_arprot_reg;
    wire m_axil_arvalid_reg;
    wire m_axil_arready_reg;
    wire [DATA_WIDTH-1:0] m_axil_rdata_reg;
    wire [1:0] m_axil_rresp_reg;
    wire m_axil_rvalid_reg;
    wire m_axil_rready_reg;

    // Synchronizer for slave to master
    axil_sync #(.DATA_WIDTH(ADDR_WIDTH+3+DATA_WIDTH+STRB_WIDTH+1), .RST_POLARITY(1)) sync_slave_to_master (
        .clk_in(s_clk),
        .rst_in(s_rst),
        .clk_out(m_clk),
        .rst_out(m_rst),
        .data_in({s_axil_awaddr, s_axil_awprot, s_axil_awvalid, s_axil_wdata, s_axil_wstrb, s_axil_wvalid}),
        .data_out({m_axil_awaddr_reg, m_axil_awprot_reg, m_axil_awvalid_reg, m_axil_wdata_reg, m_axil_wstrb_reg, m_axil_wvalid_reg})
    );

    // Synchronizer for master to slave
    axil_sync #(.DATA_WIDTH(ADDR_WIDTH+3+DATA_WIDTH+STRB_WIDTH+1), .RST_POLARITY(1)) sync_master_to_slave (
        .clk_in(m_clk),
        .rst_in(m_rst),
        .clk_out(s_clk),
        .rst_out(s_rst),
        .data_in({m_axil_awaddr_reg, m_axil_awprot_reg, m_axil_awvalid_reg, m_axil_wdata_reg, m_axil_wstrb_reg, m_axil_wvalid_reg}),
        .data_out({s_axil_awaddr_reg, s_axil_awprot_reg, s_axil_awvalid_reg, s_axil_wdata_reg, s_axil_wstrb_reg, s_axil_wvalid_reg})
    );

    // Handshaking logic
    assign s_axil_awready = m_axil_awready_reg;
    assign s_axil_wready = m_axil_wready_reg;
    assign m_axil_awaddr = s_axil_awaddr_reg;
    assign m_axil_awprot = s_axil_awprot_reg;
    assign m_axil_awvalid = s_axil_awvalid_reg;
    assign m_axil_wdata = s_axil_wdata_reg;
    assign m_axil_wstrb = s_axil_wstrb_reg;
    assign m_axil_wvalid = s_axil_wvalid_reg;

    assign s_axil_bresp = m_axil_bresp_reg;
    assign s_axil_bvalid = m_axil_bvalid_reg;
    assign m_axil_bready = s_axil_bready;

    assign s_axil_arready = m_axil_arready_reg;
    assign s_axil_rdata = m_axil_rdata_reg;
    assign s_axil_rresp = m_axil_rresp_reg;
    assign s_axil_rvalid = m_axil_rvalid_reg;
    assign m_axil_rready = s_axil_rready;

endmodule

module axil_sync #(
    parameter DATA_WIDTH = 8,
    parameter RST_POLARITY = 0
)
(
    input  wire clk_in,
    input  wire rst_in,
    input  wire clk_out,
    input  wire rst_out,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] data_out_reg;

    always @(posedge clk_out or posedge rst_out) begin
        if (rst_out == RST_POLARITY) begin
            data_out_reg <= 0;
        end else begin
            data_out_reg <= data_in;
        end
    end

    assign data_out = data_out_reg;

endmodule
