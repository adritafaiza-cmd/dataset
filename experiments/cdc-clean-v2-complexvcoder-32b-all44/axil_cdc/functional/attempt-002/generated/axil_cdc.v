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

    /*
     * Asynchronous FIFO for AW channel
     */
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 3)
    ) aw_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_awaddr, s_axil_awprot}),
        .wr_en(s_axil_awvalid),
        .full_n(s_axil_awready),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout({m_axil_awaddr, m_axil_awprot}),
        .rd_en(m_axil_awvalid),
        .empty_n(m_axil_awready)
    );

    /*
     * Asynchronous FIFO for W channel
     */
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)
    ) w_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_wdata, s_axil_wstrb}),
        .wr_en(s_axil_wvalid),
        .full_n(s_axil_wready),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout({m_axil_wdata, m_axil_wstrb}),
        .rd_en(m_axil_wvalid),
        .empty_n(m_axil_wready)
    );

    /*
     * Asynchronous FIFO for B channel
     */
    async_fifo #(
        .DATA_WIDTH(3)
    ) b_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .din({m_axil_bresp, m_axil_bvalid}),
        .wr_en(m_axil_bvalid),
        .full_n(m_axil_bready),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .dout({s_axil_bresp, s_axil_bvalid}),
        .rd_en(s_axil_bready),
        .empty_n(s_axil_bready)
    );

    /*
     * Asynchronous FIFO for AR channel
     */
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 3)
    ) ar_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .din({s_axil_araddr, s_axil_arprot}),
        .wr_en(s_axil_arvalid),
        .full_n(s_axil_arready),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .dout({m_axil_araddr, m_axil_arprot}),
        .rd_en(m_axil_arvalid),
        .empty_n(m_axil_arready)
    );

    /*
     * Asynchronous FIFO for R channel
     */
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 2)
    ) r_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .din({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .wr_en(m_axil_rvalid),
        .full_n(m_axil_rready),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .dout({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .rd_en(s_axil_rready),
        .empty_n(s_axil_rready)
    );

endmodule

module async_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire clk_wr,
    input  wire rst_wr,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire wr_en,
    output wire full_n,
    input  wire clk_rd,
    input  wire rst_rd,
    output wire [DATA_WIDTH-1:0] dout,
    input  wire rd_en,
    output wire empty_n
);

    reg [DATA_WIDTH-1:0] mem [0:3];
    reg [1:0] wr_ptr, rd_ptr;
    reg [1:0] wr_ptr_gray, rd_ptr_gray;
    reg [1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    wire wr_ptr_gray_next;
    wire rd_ptr_gray_next;
    wire wr_ptr_gray_sync_next;
    wire rd_ptr_gray_sync_next;

    wire wr_en_gray;
    wire rd_en_gray;

    assign wr_ptr_gray_next = (wr_ptr[1] ^ wr_ptr[0]);
    assign rd_ptr_gray_next = (rd_ptr[1] ^ rd_ptr[0]);

    assign wr_en_gray = wr_en & ~full_n;
    assign rd_en_gray = rd_en & ~empty_n;

    assign full_n = (wr_ptr_gray_next == rd_ptr_gray_sync) & (wr_ptr[1] != rd_ptr_gray_sync[1]);
    assign empty_n = (wr_ptr_gray_sync == rd_ptr_gray_next);

    always @(posedge clk_wr or posedge rst_wr)
    begin
        if (rst_wr)
        begin
            wr_ptr <= 2'b00;
            wr_ptr_gray <= 2'b00;
        end
        else if (wr_en_gray)
        begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= {wr_ptr_gray_next, wr_ptr[1]};
        end
    end

    always @(posedge clk_rd or posedge rst_rd)
    begin
        if (rst_rd)
        begin
            rd_ptr <= 2'b00;
            rd_ptr_gray <= 2'b00;
        end
        else if (rd_en_gray)
        begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= {rd_ptr_gray_next, rd_ptr[1]};
        end
    end

    always @(posedge clk_wr or posedge rst_wr)
    begin
        if (rst_wr)
            wr_ptr_gray_sync <= 2'b00;
        else
            wr_ptr_gray_sync <= {wr_ptr_gray_next, wr_ptr[1]};
    end

    always @(posedge clk_rd or posedge rst_rd)
    begin
        if (rst_rd)
            rd_ptr_gray_sync <= 2'b00;
        else
            rd_ptr_gray_sync <= {rd_ptr_gray_next, rd_ptr[1]};
    end

    always @(posedge clk_wr or posedge rst_wr)
    begin
        if (rst_wr && wr_en_gray)
            mem[wr_ptr] <= din;
        else if (wr_en_gray)
            mem[wr_ptr] <= din;
    end

    always @(posedge clk_rd or posedge rst_rd)
    begin
        if (rst_rd && rd_en_gray)
            dout <= mem[rd_ptr];
        else if (rd_en_gray)
            dout <= mem[rd_ptr];
    end

endmodule
