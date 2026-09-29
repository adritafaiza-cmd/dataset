module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
    /*
     * AXI Lite Slave Interface
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
     * AXI Lite Master Interface
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

    // Write Channel CDC
    reg [ADDR_WIDTH-1:0] awaddr_s, awaddr_m;
    reg [2:0] awprot_s, awprot_m;
    reg [DATA_WIDTH-1:0] wdata_s, wdata_m;
    reg [STRB_WIDTH-1:0] wstrb_s, wstrb_m;
    reg awvalid_s, awvalid_m;
    reg wvalid_s, wvalid_m;
    reg write_toggle_s, write_toggle_m1, write_toggle_m2;
    reg write_ack_toggle_m, write_ack_toggle_s1, write_ack_toggle_s2;
    reg [1:0] bresp_m;
    reg bvalid_received_m;

    // Read Channel CDC
    reg [ADDR_WIDTH-1:0] araddr_s, araddr_m;
    reg [2:0] arprot_s, arprot_m;
    reg arvalid_s, arvalid_m;
    reg read_toggle_s, read_toggle_m1, read_toggle_m2;
    reg read_ack_toggle_m, read_ack_toggle_s1, read_ack_toggle_s2;
    reg [DATA_WIDTH-1:0] rdata_m;
    reg rvalid_received_m;

    // Write CDC Logic
    // Slave to Master CDC
    always @(posedge s_clk) begin
        if (s_rst) begin
            awvalid_s <= 0;
            wvalid_s <= 0;
            write_toggle_s <= 0;
            awaddr_s <= 0;
            awprot_s <= 0;
            wdata_s <= 0;
            wstrb_s <= 0;
        end else begin
            if (s_axil_awvalid && !awvalid_s) begin
                awaddr_s <= s_axil_awaddr;
                awprot_s <= s_axil_awprot;
                awvalid_s <= 1;
            end
            if (s_axil_wvalid && !wvalid_s) begin
                wdata_s <= s_axil_wdata;
                wstrb_s <= s_axil_wstrb;
                wvalid_s <= 1;
            end
            if (awvalid_s && wvalid_s && !write_toggle_s) begin
                write_toggle_s <= ~write_toggle_s;
                awvalid_s <= 0;
                wvalid_s <= 0;
            end
        end
    end

    // CDC synchronization
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_toggle_m1 <= 0;
            write_toggle_m2 <= 0;
            awvalid_m <= 0;
            wvalid_m <= 0;
            awaddr_m <= 0;
            awprot_m <= 0;
            wdata_m <= 0;
            wstrb_m <= 0;
        end else begin
            write_toggle_m1 <= write_toggle_s;
            write_toggle_m2 <= write_toggle_m1;
            if (write_toggle_m2 != write_toggle_m1) begin
                awvalid_m <= 1;
                wvalid_m <= 1;
                awaddr_m <= awaddr_s;
                awprot_m <= awprot_s;
                wdata_m <= wdata_s;
                wstrb_m <= wstrb_s;
            end else if (m_axil_awready && awvalid_m) begin
                awvalid_m <= 0;
            end else if (m_axil_wready && wvalid_m) begin
                wvalid_m <= 0;
            end
        end
    end

    assign m_axil_awvalid = awvalid_m;
    assign m_axil_awaddr = awaddr_m;
    assign m_axil_awprot = awprot_m;
    assign m_axil_wvalid = wvalid_m;
    assign m_axil_wdata = wdata_m;
    assign m_axil_wstrb = wstrb_m;

    // B Response Handling
    assign m_axil_bready = 1; // Always ready to accept B response
    always @(posedge m_clk) begin
        if (m_axil_bvalid) begin
            bresp_m <= m_axil_bresp;
            bvalid_received_m <= 1;
        end else begin
            bvalid_received_m <= 0;
        end
    end

    // Toggle ack back to slave
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_ack_toggle_m <= 0;
        end else if (bvalid_received_m) begin
            write_ack_toggle_m <= ~write_ack_toggle_m;
        end
    end

    // CDC ack to slave
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_ack_toggle_s1 <= 0;
            write_ack_toggle_s2 <= 0;
        end else begin
            write_ack_toggle_s1 <= write_ack_toggle_m;
            write_ack_toggle_s2 <= write_ack_toggle_s1;
        end
    end

    // Write Response to Slave
    assign s_axil_bvalid = bvalid_received_m;
    assign s_axil_bresp = bresp_m;

    // Read Channel CDC
    // Slave to Master CDC
    always @(posedge s_clk) begin
        if (s_rst) begin
            arvalid_s <= 0;
            araddr_s <= 0;
            arprot_s <= 0;
            read_toggle_s <= 0;
        end else begin
            if (s_axil_arvalid && !arvalid_s) begin
                araddr_s <= s_axil_araddr;
                arprot_s <= s_axil_arprot;
                arvalid_s <= 1;
            end
            if (arvalid_s && !read_toggle_s) begin
                read_toggle_s <= ~read_toggle_s;
                arvalid_s <= 0;
            end
        end
    end

    // CDC synchronization
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_toggle_m1 <= 0;
            read_toggle_m2 <= 0;
            arvalid_m <= 0;
            araddr_m <= 0;
            arprot_m <= 0;
        end else begin
            read_toggle_m1 <= read_toggle_s;
            read_toggle_m2 <= read_toggle_m1;
            if (read_toggle_m2 != read_toggle_m1) begin
                arvalid_m <= 1;
                araddr_m <= araddr_s;
                arprot_m <= arprot_s;
            end else if (m_axil_arready && arvalid_m) begin
                arvalid_m <= 0;
            end
        end
    end

    assign m_axil_arvalid = arvalid_m;
    assign m_axil_araddr = araddr_m;
    assign m_axil_arprot = arprot_m;

    // R Data Handling
    assign m_axil_rready = 1; // Always ready to accept R data
    always @(posedge m_clk) begin
        if (m_axil_rvalid) begin
            rdata_m <= m_axil_rdata;
            rvalid_received_m <= 1;
        end else begin
            rvalid_received_m <= 0;
        end
    end

    // Toggle ack back to slave
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_ack_toggle_m <= 0;
        end else if (rvalid_received_m) begin
            read_ack_toggle_m <= ~read_ack_toggle_m;
        end
    end

    // CDC ack to slave
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_ack_toggle_s1 <= 0;
            read_ack_toggle_s2 <= 0;
        end else begin
            read_ack_toggle_s1 <= read_ack_toggle_m;
            read_ack_toggle_s2 <= read_ack_toggle_s1;
        end
    end

    // Read Response to Slave
    assign s_axil_rvalid = rvalid_received_m;
    assign s_axil_rdata = rdata_m;
    assign s_axil_rresp = m_axil_rresp;

    // Slave Ready signals
    assign s_axil_awready = !awvalid_s && !wvalid_s;
    assign s_axil_wready = !awvalid_s && !wvalid_s;
    assign s_axil_arready = !arvalid_s;

endmodule
