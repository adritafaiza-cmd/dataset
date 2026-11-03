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

    // Internal signals for CDC synchronization
    wire [ADDR_WIDTH-1:0] awaddr_sync;
    wire [2:0] awprot_sync;
    wire awvalid_sync;
    wire awready_sync;
    wire [DATA_WIDTH-1:0] wdata_sync;
    wire [STRB_WIDTH-1:0] wstrb_sync;
    wire wvalid_sync;
    wire wready_sync;
    wire [ADDR_WIDTH-1:0] araddr_sync;
    wire [2:0] arprot_sync;
    wire arvalid_sync;
    wire arready_sync;
    wire [1:0] bresp_sync;
    wire bvalid_sync;
    wire bready_sync;
    wire [DATA_WIDTH-1:0] rdata_sync;
    wire [1:0] rresp_sync;
    wire rvalid_sync;
    wire rready_sync;

    // CDC synchronization instances
    cdc_sync #(.WIDTH(ADDR_WIDTH)) aw_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_awaddr), .s_valid(s_axil_awvalid), .s_ready(awready_sync),
        .m_data(awaddr_sync), .m_valid(awvalid_sync), .m_ready(m_axil_awready)
    );

    cdc_sync #(.WIDTH(3)) awprot_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_awprot), .s_valid(s_axil_awvalid), .s_ready(awready_sync),
        .m_data(awprot_sync), .m_valid(awvalid_sync), .m_ready(m_axil_awready)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) wdata_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_wdata), .s_valid(s_axil_wvalid), .s_ready(wready_sync),
        .m_data(wdata_sync), .m_valid(wvalid_sync), .m_ready(m_axil_wready)
    );

    cdc_sync #(.WIDTH(STRB_WIDTH)) wstrb_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_wstrb), .s_valid(s_axil_wvalid), .s_ready(wready_sync),
        .m_data(wstrb_sync), .m_valid(wvalid_sync), .m_ready(m_axil_wready)
    );

    cdc_sync #(.WIDTH(ADDR_WIDTH)) ar_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_araddr), .s_valid(s_axil_arvalid), .s_ready(arready_sync),
        .m_data(araddr_sync), .m_valid(arvalid_sync), .m_ready(m_axil_arready)
    );

    cdc_sync #(.WIDTH(3)) arprot_sync (
        .s_clk(s_clk), .s_rst(s_rst),
        .m_clk(m_clk), .m_rst(m_rst),
        .s_data(s_axil_arprot), .s_valid(s_axil_arvalid), .s_ready(arready_sync),
        .m_data(arprot_sync), .m_valid(arvalid_sync), .m_ready(m_axil_arready)
    );

    cdc_sync #(.WIDTH(2)) bresp_sync (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_bresp), .s_valid(m_axil_bvalid), .s_ready(bready_sync),
        .m_data(bresp_sync), .m_valid(bvalid_sync), .m_ready(s_axil_bready)
    );

    cdc_sync #(.WIDTH(DATA_WIDTH)) rdata_sync (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_rdata), .s_valid(m_axil_rvalid), .s_ready(rready_sync),
        .m_data(rdata_sync), .m_valid(rvalid_sync), .m_ready(s_axil_rready)
    );

    cdc_sync #(.WIDTH(2)) rresp_sync (
        .s_clk(m_clk), .s_rst(m_rst),
        .m_clk(s_clk), .m_rst(s_rst),
        .s_data(m_axil_rresp), .s_valid(m_axil_rvalid), .s_ready(rready_sync),
        .m_data(rresp_sync), .m_valid(rvalid_sync), .m_ready(s_axil_rready)
    );

    // AXI Lite slave interface signals
    assign s_axil_awready = awready_sync;
    assign s_axil_wready = wready_sync;
    assign s_axil_bresp = bresp_sync;
    assign s_axil_bvalid = bvalid_sync;
    assign s_axil_arready = arready_sync;
    assign s_axil_rdata = rdata_sync;
    assign s_axil_rresp = rresp_sync;
    assign s_axil_rvalid = rvalid_sync;

    // AXI Lite master interface signals
    assign m_axil_awaddr = awaddr_sync;
    assign m_axil_awprot = awprot_sync;
    assign m_axil_awvalid = awvalid_sync;
    assign m_axil_wdata = wdata_sync;
    assign m_axil_wstrb = wstrb_sync;
    assign m_axil_wvalid = wvalid_sync;
    assign m_axil_bready = bready_sync;
    assign m_axil_araddr = araddr_sync;
    assign m_axil_arprot = arprot_sync;
    assign m_axil_arvalid = arvalid_sync;
    assign m_axil_rready = rready_sync;

endmodule

// CDC synchronization module
module cdc_sync #
(
    parameter WIDTH = 1
)
(
    input wire s_clk,
    input wire s_rst,
    input wire m_clk,
    input wire m_rst,
    input wire [WIDTH-1:0] s_data,
    input wire s_valid,
    output wire s_ready,
    output wire [WIDTH-1:0] m_data,
    output wire m_valid,
    input wire m_ready
);

    reg [WIDTH-1:0] s_data_reg [1:0];
    reg [WIDTH-1:0] m_data_reg [1:0];
    reg s_valid_reg;
    reg m_valid_reg;

    // Synchronizer for data from source to destination clock domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_data_reg[0] <= 0;
            s_data_reg[1] <= 0;
        end else begin
            if (s_valid) begin
                s_data_reg[0] <= s_data;
                s_data_reg[1] <= s_data_reg[0];
            end
        end
    end

    // Synchronizer for valid signal from source to destination clock domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_valid_reg <= 0;
            m_valid_reg <= 0;
        end else begin
            s_valid_reg <= s_valid_reg | s_valid;
            m_valid_reg <= s_valid_reg & ~m_ready;
        end
    end

    assign s_ready = ~s_valid_reg;
    assign m_data = m_data_reg[1];
    assign m_valid = m_valid_reg;

    // Synchronizer for data from destination to source clock domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_data_reg[0] <= 0;
            m_data_reg[1] <= 0;
        end else begin
            if (m_valid_reg) begin
                m_data_reg[0] <= m_data_reg[1];
            end
        end
    end

endmodule
