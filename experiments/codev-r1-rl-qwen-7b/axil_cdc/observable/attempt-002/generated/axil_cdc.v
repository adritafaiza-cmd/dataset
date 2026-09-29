module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
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

    // Write channel CDC
    reg awvalid_toggle_s = 0;
    reg wvalid_toggle_s = 0;
    reg [ADDR_WIDTH-1:0] awaddr_s;
    reg [DATA_WIDTH-1:0] wdata_s;
    reg [STRB_WIDTH-1:0] wstrb_s;

    // Read channel CDC
    reg arvalid_toggle_s = 0;
    reg rvalid_toggle_m = 0;

    // Synchronization registers for write
    reg aw_toggle_m1, aw_toggle_m2;
    reg w_toggle_m1, w_toggle_m2;

    // Synchronization registers for read
    reg ar_toggle_m1, ar_toggle_m2;
    reg r_toggle_s1, r_toggle_s2;

    // Master interface signals
    reg [ADDR_WIDTH-1:0] m_awaddr_reg;
    reg [DATA_WIDTH-1:0] m_wdata_reg;
    reg [STRB_WIDTH-1:0] m_wstrb_reg;

    // Slave interface assignments
    assign s_axil_awready = !awvalid_toggle_s;
    assign s_axil_wready = !wvalid_toggle_s;
    assign s_axil_bresp = 2'b00;
    assign s_axil_bvalid = awvalid_toggle_s && wvalid_toggle_s;
    assign s_axil_arready = !arvalid_toggle_s;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = 2'b00;
    assign s_axil_rvalid = r_toggle_s2;

    // Master interface assignments
    assign m_axil_awaddr = m_awaddr_reg;
    assign m_axil_awprot = 3'b000;
    assign m_axil_awvalid = aw_toggle_m2;
    assign m_axil_wdata = m_wdata_reg;
    assign m_axil_wstrb = m_wstrb_reg;
    assign m_axil_wvalid = w_toggle_m2;
    assign m_axil_bready = 1'b1;
    assign m_axil_araddr = s_axil_araddr;
    assign m_axil_arprot = 3'b000;
    assign m_axil_arvalid = arvalid_toggle_s;
    assign m_axil_rready = r_toggle_s2;

    // Write CDC logic
    always @(posedge s_clk) begin
        if (s_rst) begin
            awvalid_toggle_s <= 0;
            wvalid_toggle_s <= 0;
            awaddr_s <= 0;
            wdata_s <= 0;
            wstrb_s <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                awaddr_s <= s_axil_awaddr;
                awvalid_toggle_s <= ~awvalid_toggle_s;
            end
            if (s_axil_wvalid && s_axil_wready) begin
                wdata_s <= s_axil_wdata;
                wstrb_s <= s_axil_wstrb;
                wvalid_toggle_s <= ~wvalid_toggle_s;
            end
        end
    end

    // Synchronize write toggles to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            aw_toggle_m1 <= 0;
            aw_toggle_m2 <= 0;
            w_toggle_m1 <= 0;
            w_toggle_m2 <= 0;
        end else begin
            aw_toggle_m1 <= awvalid_toggle_s;
            aw_toggle_m2 <= aw_toggle_m1;
            w_toggle_m1 <= wvalid_toggle_s;
            w_toggle_m2 <= w_toggle_m1;
        end
    end

    // Read CDC logic
    always @(posedge s_clk) begin
        if (s_rst) begin
            arvalid_toggle_s <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                arvalid_toggle_s <= ~arvalid_toggle_s;
            end
        end
    end

    // Synchronize read toggle to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            ar_toggle_m1 <= 0;
            ar_toggle_m2 <= 0;
        end else begin
            ar_toggle_m1 <= arvalid_toggle_s;
            ar_toggle_m2 <= ar_toggle_m1;
        end
    end

    // Master interface handling
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_awaddr_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
        end else begin
            if (aw_toggle_m2) begin
                m_awaddr_reg <= awaddr_s;
            end
            if (w_toggle_m2) begin
                m_wdata_reg <= wdata_s;
                m_wstrb_reg <= wstrb_s;
            end
        end
    end

    // Read response handling
    always @(posedge s_clk) begin
        if (s_rst) begin
            r_toggle_s1 <= 0;
            r_toggle_s2 <= 0;
        end else begin
            r_toggle_s1 <= m_axil_rvalid;
            r_toggle_s2 <= r_toggle_s1;
        end
    end

endmodule
