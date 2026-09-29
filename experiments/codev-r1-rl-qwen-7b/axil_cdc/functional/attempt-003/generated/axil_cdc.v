module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
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

    // Write channel in s_clk domain
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg [2:0] awprot_reg;
    reg write_pending;

    // Read channel in s_clk domain
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [2:0] arprot_reg;
    reg read_pending;

    // CDC synchronization registers for write
    reg write_pending_sync1, write_pending_sync2;

    // CDC synchronization for write done
    reg done_pulse;
    reg done_pulse_sync1, done_pulse_sync2;

    // Read CDC
    reg read_done_pulse;
    reg read_done_sync1, read_done_sync2;

    // Master side signals
    reg [1:0] bresp_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0] rresp_reg;

    // Slave side assignments
    assign s_axil_awready = !write_pending && !read_pending;
    assign s_axil_wready = !write_pending && !read_pending;

    // Capture write data when valid and ready
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_pending <= 0;
            awaddr_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            awprot_reg <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_wvalid && s_axil_awready && s_axil_wready) begin
                awaddr_reg <= s_axil_awaddr;
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                awprot_reg <= s_axil_awprot;
                write_pending <= 1;
            end else if (done_pulse_sync2) begin
                write_pending <= 0;
            end
        end
    end

    // Synchronize write_pending to m_clk domain
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_pending_sync1 <= 0;
            write_pending_sync2 <= 0;
        end else begin
            write_pending_sync1 <= write_pending;
            write_pending_sync2 <= write_pending_sync1;
        end
    end

    // Master side write handling
    assign m_axil_awvalid = write_pending_sync2;
    assign m_axil_awaddr = awaddr_reg;
    assign m_axil_awprot = awprot_reg;

    assign m_axil_wvalid = write_pending_sync2;
    assign m_axil_wdata = wdata_reg;
    assign m_axil_wstrb = wstrb_reg;

    // Capture B response from master
    always @(posedge m_clk) begin
        if (m_rst) begin
            bresp_reg <= 0;
        end else if (m_axil_bvalid && m_axil_bready) begin
            bresp_reg <= m_axil_bresp;
        end
    end

    assign m_axil_bready = 1'b1;

    // Generate done pulse in m_clk domain
    reg done_pulse;
    always @(posedge m_clk) begin
        if (m_rst) begin
            done_pulse <= 0;
        end else begin
            done_pulse <= m_axil_bvalid && m_axil_bready;
        end
    end

    // Synchronize done pulse back to s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            done_pulse_sync1 <= 0;
            done_pulse_sync2 <= 0;
        end else begin
            done_pulse_sync1 <= done_pulse;
            done_pulse_sync2 <= done_pulse_sync1;
        end
    end

    assign s_axil_bvalid = done_pulse_sync2;
    assign s_axil_bresp = bresp_reg;

    // Read channel in s_clk domain
    assign s_axil_arready = !write_pending && !read_pending;

    // Capture read address when valid and ready
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_pending <= 0;
            araddr_reg <= 0;
            arprot_reg <= 0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                araddr_reg <= s_axil_araddr;
                arprot_reg <= s_axil_arprot;
                read_pending <= 1;
            end else if (read_done_sync2) begin
                read_pending <= 0;
            end
        end
    end

    // Synchronize read_pending to m_clk domain
    reg read_pending_sync1, read_pending_sync2;
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_pending_sync1 <= 0;
            read_pending_sync2 <= 0;
        end else begin
            read_pending_sync1 <= read_pending;
            read_pending_sync2 <= read_pending_sync1;
        end
    end

    // Master side read handling
    assign m_axil_arvalid = read_pending_sync2;
    assign m_axil_araddr = araddr_reg;
    assign m_axil_arprot = arprot_reg;

    // Capture R data and response from master
    always @(posedge m_clk) begin
        if (m_rst) begin
            rdata_reg <= 0;
            rresp_reg <= 0;
        end else if (m_axil_rvalid && m_axil_rready) begin
            rdata_reg <= m_axil_rdata;
            rresp_reg <= m_axil_rresp;
        end
    end

    assign m_axil_rready = 1'b1;

    // Generate read done pulse
    reg read_done_pulse;
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_done_pulse <= 0;
        end else begin
            read_done_pulse <= m_axil_rvalid && m_axil_rready;
        end
    end

    // Synchronize read done to s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_done_sync1 <= 0;
            read_done_sync2 <= 0;
        end else begin
            read_done_sync1 <= read_done_pulse;
            read_done_sync2 <= read_done_sync1;
        end
    end

    assign s_axil_rdata = rdata_reg;
    assign s_axil_rresp = rresp_reg;
    assign s_axil_rvalid = read_done_sync2;

endmodule
