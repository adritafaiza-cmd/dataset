module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
) (
    // Slave interface (s_clk domain)
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

    // Master interface (m_clk domain)
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

    // Write CDC signals
    reg [ADDR_WIDTH-1:0] awaddr_s;
    reg [DATA_WIDTH-1:0] wdata_s;
    reg [STRB_WIDTH-1:0] wstrb_s;
    reg awvalid_s, wvalid_s;
    reg write_pending;

    // Synchronizers for write
    reg write_pending_m1, write_pending_m2;
    reg awready_m, wready_m;

    // Read CDC signals
    reg [ADDR_WIDTH-1:0] araddr_s;
    reg arvalid_s;
    reg read_pending;

    // Synchronizers for read
    reg read_pending_m1, read_pending_m2;
    reg arready_m;

    // Response registers
    reg [1:0] bresp_reg;
    reg bvalid_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;

    // Slave write handling
    always @(posedge s_clk) begin
        if (s_rst) begin
            awvalid_s <= 0;
            wvalid_s <= 0;
            write_pending <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_wvalid && !write_pending) begin
                awaddr_s <= s_axil_awaddr;
                wdata_s <= s_axil_wdata;
                wstrb_s <= s_axil_wstrb;
                awvalid_s <= 1;
                wvalid_s <= 1;
                write_pending <= 1;
            end else if (awready_m && wready_m && write_pending) begin
                awvalid_s <= 0;
                wvalid_s <= 0;
                write_pending <= 0;
            end
        end
    end

    // Master write handling
    assign m_axil_awaddr = awaddr_s;
    assign m_axil_awprot = s_axil_awprot;
    assign m_axil_awvalid = awvalid_s;
    assign m_axil_wdata = wdata_s;
    assign m_axil_wstrb = wstrb_s;
    assign m_axil_wvalid = wvalid_s;
    assign m_axil_bready = 1'b1;

    // Synchronize write pending to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_pending_m1 <= 0;
            write_pending_m2 <= 0;
        end else begin
            write_pending_m1 <= write_pending;
            write_pending_m2 <= write_pending_m1;
        end
    end

    // Capture write response from master
    always @(posedge s_clk) begin
        if (m_axil_bvalid && m_axil_bready) begin
            bresp_reg <= m_axil_bresp;
            bvalid_reg <= 1;
        end else if (s_axil_bready && bvalid_reg) begin
            bvalid_reg <= 0;
        end
    end

    assign s_axil_bresp = bresp_reg;
    assign s_axil_bvalid = bvalid_reg;

    // Slave read handling
    always @(posedge s_clk) begin
        if (s_rst) begin
            arvalid_s <= 0;
            read_pending <= 0;
        end else begin
            if (s_axil_arvalid && !read_pending) begin
                araddr_s <= s_axil_araddr;
                arvalid_s <= 1;
                read_pending <= 1;
            end else if (arready_m && read_pending) begin
                arvalid_s <= 0;
                read_pending <= 0;
            end
        end
    end

    // Master read handling
    assign m_axil_araddr = araddr_s;
    assign m_axil_arprot = s_axil_arprot;
    assign m_axil_arvalid = arvalid_s;
    assign m_axil_rready = 1'b1;

    // Synchronize read pending to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_pending_m1 <= 0;
            read_pending_m2 <= 0;
        end else begin
            read_pending_m1 <= read_pending;
            read_pending_m2 <= read_pending_m1;
        end
    end

    // Capture read data from master
    always @(posedge s_clk) begin
        if (m_axil_rvalid && m_axil_rready) begin
            rdata_reg <= m_axil_rdata;
            rresp_reg <= m_axil_rresp;
            s_axil_rvalid <= 1;
        end else if (s_axil_rready && s_axil_rvalid) begin
            s_axil_rvalid <= 0;
        end
    end

    assign s_axil_rdata = rdata_reg;
    assign s_axil_rresp = rresp_reg;
    assign s_axil_rvalid = s_axil_rvalid;

    // Assign ready signals
    assign s_axil_awready = !write_pending && s_axil_awvalid && s_axil_wvalid;
    assign s_axil_wready = !write_pending && s_axil_wvalid && s_axil_awvalid;
    assign s_axil_arready = !read_pending && s_axil_arvalid;

endmodule
