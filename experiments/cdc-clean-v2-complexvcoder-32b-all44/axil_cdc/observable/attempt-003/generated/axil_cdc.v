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

    // FIFO instances for AW, W, B, AR, R transactions
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH)) s_to_m_aw_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_awaddr),
        .din_valid(s_axil_awvalid),
        .din_ready(s_axil_awready),
        .dout(m_axil_awaddr),
        .dout_valid(m_axil_awvalid),
        .dout_ready(m_axil_awready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH)) s_to_m_w_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_wdata),
        .din_valid(s_axil_wvalid),
        .din_ready(s_axil_wready),
        .dout(m_axil_wdata),
        .dout_valid(m_axil_wvalid),
        .dout_ready(m_axil_wready)
    );

    cdc_fifo #(.DATA_WIDTH(2)) m_to_s_b_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .din(m_axil_bresp),
        .din_valid(m_axil_bvalid),
        .din_ready(m_axil_bready),
        .dout(s_axil_bresp),
        .dout_valid(s_axil_bvalid),
        .dout_ready(s_axil_bready)
    );

    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH)) s_to_m_ar_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .din(s_axil_araddr),
        .din_valid(s_axil_arvalid),
        .din_ready(s_axil_arready),
        .dout(m_axil_araddr),
        .dout_valid(m_axil_arvalid),
        .dout_ready(m_axil_arready)
    );

    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH)) m_to_s_r_fifo (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .m_clk(s_clk),
        .m_rst(s_rst),
        .din(m_axil_rdata),
        .din_valid(m_axil_rvalid),
        .din_ready(m_axil_rready),
        .dout(s_axil_rdata),
        .dout_valid(s_axil_rvalid),
        .dout_ready(s_axil_rready)
    );

    // Directly connect the non-FIFO signals
    assign m_axil_awprot = s_axil_awprot;
    assign m_axil_wstrb  = s_axil_wstrb;
    assign s_axil_rresp  = m_axil_rresp;

endmodule

module cdc_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire                   m_clk,
    input  wire                   m_rst,
    input  wire [DATA_WIDTH-1:0]  din,
    input  wire                   din_valid,
    output wire                   din_ready,
    output wire [DATA_WIDTH-1:0]  dout,
    output wire                   dout_valid,
    input  wire                   dout_ready
);

    reg [DATA_WIDTH-1:0] fifo_mem [0:3]; // 4-entry FIFO
    reg [1:0]              wr_ptr, rd_ptr;
    reg [1:0]              wr_ptr_gray, rd_ptr_gray;
    reg [1:0]              wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion functions
    function [1:0] bin_to_gray;
        input [1:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [1:0] gray_to_bin;
        input [1:0] gray;
        reg [1:0]   bin;
        bin = gray;
        bin = bin ^ (bin >> 1);
        gray_to_bin = bin;
    endfunction

    // Write pointer logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 2'b00;
        end else if (din_valid && din_ready) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 2'b00;
        end else if (dout_valid && dout_ready) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion for pointers
    assign wr_ptr_gray = bin_to_gray(wr_ptr);
    assign rd_ptr_gray = bin_to_gray(rd_ptr);

    // Synchronize write pointer to master clock domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync <= 2'b00;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Synchronize read pointer to slave clock domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync <= 2'b00;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Write enable and read enable
    wire wr_en = din_valid && din_ready;
    wire rd_en = dout_valid && dout_ready;

    // FIFO write logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_mem[0] <= 0;
            fifo_mem[1] <= 0;
            fifo_mem[2] <= 0;
            fifo_mem[3] <= 0;
        end else if (wr_en) begin
            fifo_mem[wr_ptr] <= din;
        end
    end

    // FIFO read logic
    assign dout = fifo_mem[gray_to_bin(rd_ptr_gray_sync)];

    // FIFO status flags
    wire fifo_full  = (wr_ptr_gray_sync == bin_to_gray(rd_ptr + 2));
    wire fifo_empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

    // Ready and valid handshakes
    assign din_ready  = ~fifo_full;
    assign dout_valid = ~fifo_empty;

endmodule
