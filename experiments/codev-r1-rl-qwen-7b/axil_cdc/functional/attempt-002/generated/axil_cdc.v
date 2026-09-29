module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH/8
)(
    // Slave interface
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output reg                    s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output reg                    s_axil_wready,
    output reg  [1:0]             s_axil_bresp,
    output reg                    s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output reg                    s_axil_arready,
    output reg  [DATA_WIDTH-1:0]  s_axil_rdata,
    output reg  [1:0]             s_axil_rresp,
    output reg                    s_axil_rvalid,
    input  wire                   s_axil_rready,

    // Master interface
    input  wire                   m_clk,
    input  wire                   m_rst,
    output reg  [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output reg  [2:0]             m_axil_awprot,
    output reg                    m_axil_awvalid,
    input  wire                   m_axil_awready,
    output reg  [DATA_WIDTH-1:0]  m_axil_wdata,
    output reg  [STRB_WIDTH-1:0]  m_axil_wstrb,
    output reg                    m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output reg                    m_axil_bready,
    output reg  [ADDR_WIDTH-1:0]  m_axil_araddr,
    output reg  [2:0]             m_axil_arprot,
    output reg                    m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output reg                    m_axil_rready
);

    // Write channel handling
    reg write_pending;
    reg [ADDR_WIDTH-1:0] awaddr_s2m;
    reg [2:0] awprot_s2m;
    reg [DATA_WIDTH-1:0] wdata_s2m;
    reg [STRB_WIDTH-1:0] wstrb_s2m;

    // Synchronizers for write_pending to m_clk
    reg write_trigger_mclk_sync1, write_trigger_mclk_sync2;

    // m_clk domain signals
    reg write_in_progress;
    reg [ADDR_WIDTH-1:0] awaddr_m2s;
    reg [2:0] awprot_m2s;
    reg [DATA_WIDTH-1:0] wdata_m2s;
    reg [STRB_WIDTH-1:0] wstrb_m2s;

    // Done signal from m_clk to s_clk
    reg done_mclk;
    reg done_mclk_sync1, done_mclk_sync2;

    // Read channel handling
    reg read_pending;
    reg [ADDR_WIDTH-1:0] araddr_s2m;
    reg [2:0] arprot_s2m;

    // Synchronizers for read_pending to m_clk
    reg read_trigger_mclk_sync1, read_trigger_mclk_sync2;

    // m_clk domain read signals
    reg read_in_progress;
    reg [ADDR_WIDTH-1:0] araddr_m2s;
    reg [2:0] arprot_m2s;

    // Done signal from m_clk to s_clk for read
    reg done_read_mclk;
    reg done_read_mclk_sync1, done_read_mclk_sync2;

    // Write channel in s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_pending <= 0;
            awaddr_s2m <= 0;
            awprot_s2m <= 0;
            wdata_s2m <= 0;
            wstrb_s2m <= 0;
            s_axil_awready <= 0;
            s_axil_wready <= 0;
            s_axil_bvalid <= 0;
            s_axil_bresp <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_wvalid && !write_pending) begin
                s_axil_awready <= 1;
                s_axil_wready <= 1;
                awaddr_s2m <= s_axil_awaddr;
                awprot_s2m <= s_axil_awprot;
                wdata_s2m <= s_axil_wdata;
                wstrb_s2m <= s_axil_wstrb;
                write_pending <= 1;
            end else begin
                s_axil_awready <= 0;
                s_axil_wready <= 0;
            end

            if (done_mclk_sync2 && !s_axil_bvalid) begin
                s_axil_bvalid <= 1;
                s_axil_bresp <= 2'b00;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 0;
            end
        end
    end

    // Synchronize write_pending to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_trigger_mclk_sync1 <= 0;
            write_trigger_mclk_sync2 <= 0;
        end else begin
            write_trigger_mclk_sync1 <= write_pending;
            write_trigger_mclk_sync2 <= write_trigger_mclk_sync1;
        end
    end

    // m_clk domain write processing
    always @(posedge m_clk) begin
        if (m_rst) begin
            write_in_progress <= 0;
            awaddr_m2s <= 0;
            awprot_m2s <= 0;
            wdata_m2s <= 0;
            wstrb_m2s <= 0;
            m_axil_awvalid <= 0;
            m_axil_wvalid <= 0;
            done_mclk <= 0;
        end else begin
            done_mclk <= 0;

            if (write_trigger_mclk_sync2 && !write_in_progress) begin
                awaddr_m2s <= awaddr_s2m;
                awprot_m2s <= awprot_s2m;
                wdata_m2s <= wdata_s2m;
                wstrb_m2s <= wstrb_s2m;
                write_in_progress <= 1;
                m_axil_awvalid <= 1;
                m_axil_wvalid <= 1;
            end

            if (write_in_progress) begin
                if (m_axil_awready && m_axil_wready) begin
                    write_in_progress <= 0;
                    m_axil_awvalid <= 0;
                    m_axil_wvalid <= 0;
                    done_mclk <= 1;
                end
            end
        end
    end

    // Synchronize done_mclk to s_clk
    always @(posedge s_clk) begin
        if (s_rst) begin
            done_mclk_sync1 <= 0;
            done_mclk_sync2 <= 0;
        end else begin
            done_mclk_sync1 <= done_mclk;
            done_mclk_sync2 <= done_mclk_sync1;
        end
    end

    // Read channel in s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_pending <= 0;
            araddr_s2m <= 0;
            arprot_s2m <= 0;
            s_axil_arready <= 0;
            s_axil_rvalid <= 0;
            s_axil_rdata <= 0;
            s_axil_rresp <= 0;
            done_read_mclk_sync1 <= 0;
            done_read_mclk_sync2 <= 0;
        end else begin
            if (s_axil_arvalid && !read_pending) begin
                s_axil_arready <= 1;
                araddr_s2m <= s_axil_araddr;
                arprot_s2m <= s_axil_arprot;
                read_pending <= 1;
            end else begin
                s_axil_arready <= 0;
            end

            if (done_read_mclk_sync2 && !s_axil_rvalid) begin
                s_axil_rvalid <= 1;
                s_axil_rdata <= m_axil_rdata;
                s_axil_rresp <= m_axil_rresp;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 0;
            end
        end
    end

    // Synchronize read_pending to m_clk
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_trigger_mclk_sync1 <= 0;
            read_trigger_mclk_sync2 <= 0;
        end else begin
            read_trigger_mclk_sync1 <= read_pending;
            read_trigger_mclk_sync2 <= read_trigger_mclk_sync1;
        end
    end

    // m_clk domain read processing
    always @(posedge m_clk) begin
        if (m_rst) begin
            read_in_progress <= 0;
            araddr_m2s <= 0;
            arprot_m2s <= 0;
            m_axil_arvalid <= 0;
            done_read_mclk <= 0;
        end else begin
            done_read_mclk <= 0;

            if (read_trigger_mclk_sync2 && !read_in_progress) begin
                araddr_m2s <= araddr_s2m;
                arprot_m2s <= arprot_s2m;
                read_in_progress <= 1;
                m_axil_arvalid <= 1;
            end

            if (read_in_progress) begin
                if (m_axil_arready) begin
                    read_in_progress <= 0;
                    m_axil_arvalid <= 0;
                    done_read_mclk <= 1;
                end
            end
        end
    end

    // Synchronize done_read_mclk to s_clk
    always @(posedge s_clk) begin
        if (s_rst) begin
            done_read_mclk_sync1 <= 0;
            done_read_mclk_sync2 <= 0;
        end else begin
            done_read_mclk_sync1 <= done_read_mclk;
            done_read_mclk_sync2 <= done_read_mclk_sync1;
        end
    end

endmodule
