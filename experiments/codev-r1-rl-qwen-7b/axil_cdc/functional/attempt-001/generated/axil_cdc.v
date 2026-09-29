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

    // Write channel handling
    reg write_pending;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;

    // Synchronize write_pending to m_clk
    reg write_pending_sync1, write_pending_sync2;

    // m_clk domain write signals
    reg m_awvalid, m_wvalid;
    reg [ADDR_WIDTH-1:0] m_awaddr;
    reg [DATA_WIDTH-1:0] m_wdata;
    reg [STRB_WIDTH-1:0] m_wstrb;
    reg [1:0] m_write_state;

    localparam M_WRITE_IDLE = 0;
    localparam M_WRITE_WAIT = 1;

    // Read channel handling
    reg read_pending;
    reg [ADDR_WIDTH-1:0] araddr_reg;

    // Synchronize read_pending to m_clk
    reg read_pending_sync1, read_pending_sync2;

    // m_clk domain read signals
    reg m_arvalid;
    reg [ADDR_WIDTH-1:0] m_araddr;
    reg [2:0] m_arprot;
    reg [1:0] m_read_state;

    localparam M_READ_IDLE = 0;
    localparam M_READ_WAIT = 1;

    // Assign master outputs
    assign m_axil_awaddr = m_awaddr;
    assign m_axil_awprot = 3'b000;
    assign m_axil_awvalid = m_awvalid;
    assign m_axil_wdata = m_wdata;
    assign m_axil_wstrb = m_wstrb;
    assign m_axil_wvalid = m_wvalid;
    assign m_axil_bready = 1'b1; // Always ready to accept write response
    assign m_axil_araddr = m_araddr;
    assign m_axil_arprot = 3'b000;
    assign m_axil_arvalid = m_arvalid;
    assign m_axil_rready = 1'b1; // Always ready to accept read data

    // Assign slave inputs
    assign s_axil_awready = !write_pending && s_axil_awvalid && s_axil_wvalid;
    assign s_axil_wready = !write_pending && s_axil_awvalid && s_axil_wvalid;
    assign s_axil_bresp = 2'b00; // Always OKAY
    assign s_axil_bvalid = m_axil_bvalid;
    assign s_axil_arready = !read_pending && s_axil_arvalid;
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;

    // Write handling in s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_pending <= 0;
            awaddr_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
        end else begin
            if (s_axil_awvalid && s_axil_wvalid && !write_pending) begin
                awaddr_reg <= s_axil_awaddr;
                wdata_reg <= s_axil_wdata;
                wstrb_reg <= s_axil_wstrb;
                write_pending <= 1;
            end else if (m_write_state == M_WRITE_WAIT && m_axil_awready && m_axil_wready) begin
                write_pending <= 0;
            end
        end
    end

    // Synchronize write_pending to m_clk
    always @(posedge m_clk) begin
        write_pending_sync1 <= write_pending;
        write_pending_sync2 <= write_pending_sync1;
    end

    // m_clk domain write state machine
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_write_state <= M_WRITE_IDLE;
            m_awvalid <= 0;
            m_wvalid <= 0;
            m_awaddr <= 0;
            m_wdata <= 0;
            m_wstrb <= 0;
        end else begin
            case (m_write_state)
                M_WRITE_IDLE: begin
                    if (write_pending_sync2) begin
                        m_awaddr <= awaddr_reg;
                        m_wdata <= wdata_reg;
                        m_wstrb <= wstrb_reg;
                        m_awvalid <= 1;
                        m_wvalid <= 1;
                        m_write_state <= M_WRITE_WAIT;
                    end
                end
                M_WRITE_WAIT: begin
                    if (m_axil_awready && m_axil_wready) begin
                        m_awvalid <= 0;
                        m_wvalid <= 0;
                        m_write_state <= M_WRITE_IDLE;
                    end
                end
            endcase
        end
    end

    // Read handling in s_clk domain
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_pending <= 0;
            araddr_reg <= 0;
        end else begin
            if (s_axil_arvalid && !read_pending) begin
                araddr_reg <= s_axil_araddr;
                read_pending <= 1;
            end else if (m_read_state == M_READ_WAIT && m_axil_rvalid) begin
                read_pending <= 0;
            end
        end
    end

    // Synchronize read_pending to m_clk
    always @(posedge m_clk) begin
        read_pending_sync1 <= read_pending;
        read_pending_sync2 <= read_pending_sync1;
    end

    // m_clk domain read state machine
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_read_state <= M_READ_IDLE;
            m_arvalid <= 0;
            m_araddr <= 0;
        end else begin
            case (m_read_state)
                M_READ_IDLE: begin
                    if (read_pending_sync2) begin
                        m_araddr <= araddr_reg;
                        m_arvalid <= 1;
                        m_read_state <= M_READ_WAIT;
                    end
                end
                M_READ_WAIT: begin
                    if (m_axil_rvalid) begin
                        m_arvalid <= 0;
                        m_read_state <= M_READ_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
