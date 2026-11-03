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

    // Instantiate CDC FIFOs for AW, W, B, AR, and R channels
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) aw_fifo (
        .s_clk(s_clk), .s_rst(s_rst), .s_data({s_axil_awaddr, s_axil_awprot}), .s_valid(s_axil_awvalid), .s_ready(s_axil_awready),
        .m_clk(m_clk), .m_rst(m_rst), .m_data(), .m_valid(m_axil_awvalid), .m_ready(m_axil_awready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)) w_fifo (
        .s_clk(s_clk), .s_rst(s_rst), .s_data({s_axil_wdata, s_axil_wstrb}), .s_valid(s_axil_wvalid), .s_ready(s_axil_wready),
        .m_clk(m_clk), .m_rst(m_rst), .m_data(), .m_valid(m_axil_wvalid), .m_ready(m_axil_wready)
    );

    cdc_fifo #(.DATA_WIDTH(3)) b_fifo (
        .s_clk(m_clk), .s_rst(m_rst), .s_data({m_axil_bresp, m_axil_bvalid}), .s_valid(m_axil_bvalid), .s_ready(m_axil_bready),
        .m_clk(s_clk), .m_rst(s_rst), .m_data(), .m_valid(s_axil_bvalid), .m_ready(s_axil_bready)
    );

    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH + 3)) ar_fifo (
        .s_clk(s_clk), .s_rst(s_rst), .s_data({s_axil_araddr, s_axil_arprot}), .s_valid(s_axil_arvalid), .s_ready(s_axil_arready),
        .m_clk(m_clk), .m_rst(m_rst), .m_data(), .m_valid(m_axil_arvalid), .m_ready(m_axil_arready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH + 2)) r_fifo (
        .s_clk(m_clk), .s_rst(m_rst), .s_data({m_axil_rdata, m_axil_rresp, m_axil_rvalid}), .s_valid(m_axil_rvalid), .s_ready(m_axil_rready),
        .m_clk(s_clk), .m_rst(s_rst), .m_data(), .m_valid(s_axil_rvalid), .m_ready(s_axil_rready)
    );

    // Connect AW FIFO outputs to master AW interface
    assign {m_axil_awaddr, m_axil_awprot} = aw_fifo.m_data;

    // Connect W FIFO outputs to master W interface
    assign {m_axil_wdata, m_axil_wstrb} = w_fifo.m_data;

    // Connect B FIFO outputs to slave B interface
    assign {s_axil_bresp, s_axil_bvalid} = b_fifo.m_data;

    // Connect AR FIFO outputs to master AR interface
    assign {m_axil_araddr, m_axil_arprot} = ar_fifo.m_data;

    // Connect R FIFO outputs to slave R interface
    assign {s_axil_rdata, s_axil_rresp, s_axil_rvalid} = r_fifo.m_data;

endmodule

module cdc_fifo #(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_data,
    input  wire                   s_valid,
    output wire                   s_ready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_data,
    output wire                   m_valid,
    input  wire                   m_ready
);

    // FIFO memory and pointers
    reg [DATA_WIDTH-1:0] fifo_mem [0:15];
    reg [3:0] s_ptr, m_ptr;
    reg [3:0] s_ptr_gray, m_ptr_gray;
    reg [3:0] s_ptr_gray_sync, m_ptr_gray_sync;

    // Gray code conversion
    assign s_ptr_gray = s_ptr ^ (s_ptr >> 1);
    assign m_ptr_gray = m_ptr ^ (m_ptr >> 1);

    // FIFO flags
    wire fifo_full, fifo_empty;

    // FIFO full condition
    assign fifo_full = (s_ptr_gray == {~m_ptr_gray_sync[3], m_ptr_gray_sync[2:0]});

    // FIFO empty condition
    assign fifo_empty = (s_ptr_gray_sync == m_ptr_gray);

    // FIFO read/write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ptr <= 4'b0;
            s_ptr_gray_sync <= 4'b0;
        end else begin
            if (s_valid && !fifo_full) begin
                fifo_mem[s_ptr] <= s_data;
                s_ptr <= s_ptr + 1;
            end
            s_ptr_gray_sync <= s_ptr_gray;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ptr <= 4'b0;
            m_ptr_gray_sync <= 4'b0;
        end else begin
            if (m_valid && m_ready) begin
                m_ptr <= m_ptr + 1;
            end
            m_ptr_gray_sync <= m_ptr_gray;
        end
    end

    // FIFO outputs
    assign m_data = fifo_mem[m_ptr];
    assign m_valid = !fifo_empty;
    assign s_ready = !fifo_full;

endmodule
