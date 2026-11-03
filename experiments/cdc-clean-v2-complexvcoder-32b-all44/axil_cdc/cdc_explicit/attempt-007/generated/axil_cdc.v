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
     * FIFOs for AW, W, B, AR, R channels
     */
    wire [ADDR_WIDTH-1:0] aw_fifo_din, aw_fifo_dout;
    wire aw_fifo_wr_en, aw_fifo_rd_en, aw_fifo_full, aw_fifo_empty;
    wire [DATA_WIDTH-1:0] w_fifo_din, w_fifo_dout;
    wire [STRB_WIDTH-1:0] w_fifo_din_strb, w_fifo_dout_strb;
    wire w_fifo_wr_en, w_fifo_rd_en, w_fifo_full, w_fifo_empty;
    wire [1:0] b_fifo_din, b_fifo_dout;
    wire b_fifo_wr_en, b_fifo_rd_en, b_fifo_full, b_fifo_empty;
    wire [ADDR_WIDTH-1:0] ar_fifo_din, ar_fifo_dout;
    wire ar_fifo_wr_en, ar_fifo_rd_en, ar_fifo_full, ar_fifo_empty;
    wire [DATA_WIDTH-1:0] r_fifo_din, r_fifo_dout;
    wire [1:0] r_fifo_din_resp;
    wire r_fifo_wr_en, r_fifo_rd_en, r_fifo_full, r_fifo_empty;

    /*
     * AW Channel FIFO
     */
    async_fifo #(
        .WIDTH(ADDR_WIDTH + 3)
    ) aw_fifo_inst (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .din({s_axil_awaddr, s_axil_awprot}),
        .wr_en(aw_fifo_wr_en),
        .full(aw_fifo_full),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .dout({m_axil_awaddr, m_axil_awprot}),
        .rd_en(aw_fifo_rd_en),
        .empty(aw_fifo_empty)
    );

    /*
     * W Channel FIFO
     */
    async_fifo #(
        .WIDTH(DATA_WIDTH + STRB_WIDTH)
    ) w_fifo_inst (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .din({s_axil_wdata, s_axil_wstrb}),
        .wr_en(w_fifo_wr_en),
        .full(w_fifo_full),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .dout({m_axil_wdata, m_axil_wstrb}),
        .rd_en(w_fifo_rd_en),
        .empty(w_fifo_empty)
    );

    /*
     * B Channel FIFO
     */
    async_fifo #(
        .WIDTH(2)
    ) b_fifo_inst (
        .clk_w(m_clk),
        .rst_w(m_rst),
        .din(m_axil_bresp),
        .wr_en(b_fifo_wr_en),
        .full(b_fifo_full),
        .clk_r(s_clk),
        .rst_r(s_rst),
        .dout(s_axil_bresp),
        .rd_en(b_fifo_rd_en),
        .empty(b_fifo_empty)
    );

    /*
     * AR Channel FIFO
     */
    async_fifo #(
        .WIDTH(ADDR_WIDTH + 3)
    ) ar_fifo_inst (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .din({s_axil_araddr, s_axil_arprot}),
        .wr_en(ar_fifo_wr_en),
        .full(ar_fifo_full),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .dout({m_axil_araddr, m_axil_arprot}),
        .rd_en(ar_fifo_rd_en),
        .empty(ar_fifo_empty)
    );

    /*
     * R Channel FIFO
     */
    async_fifo #(
        .WIDTH(DATA_WIDTH + 2)
    ) r_fifo_inst (
        .clk_w(m_clk),
        .rst_w(m_rst),
        .din({m_axil_rdata, m_axil_rresp}),
        .wr_en(r_fifo_wr_en),
        .full(r_fifo_full),
        .clk_r(s_clk),
        .rst_r(s_rst),
        .dout({s_axil_rdata, s_axil_rresp}),
        .rd_en(r_fifo_rd_en),
        .empty(r_fifo_empty)
    );

    /*
     * AW Channel Control Logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_awready <= 1'b0;
        end else begin
            s_axil_awready <= ~aw_fifo_full;
        end
    end

    assign aw_fifo_wr_en = s_axil_awvalid & s_axil_awready;
    assign m_axil_awvalid = ~aw_fifo_empty;
    assign aw_fifo_rd_en = m_axil_awready & m_axil_awvalid;

    /*
     * W Channel Control Logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_wready <= 1'b0;
        end else begin
            s_axil_wready <= ~w_fifo_full;
        end
    end

    assign w_fifo_wr_en = s_axil_wvalid & s_axil_wready;
    assign m_axil_wvalid = ~w_fifo_empty;
    assign w_fifo_rd_en = m_axil_wready & m_axil_wvalid;

    /*
     * B Channel Control Logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_bvalid <= 1'b0;
        end else begin
            s_axil_bvalid <= ~b_fifo_empty;
        end
    end

    assign b_fifo_wr_en = m_axil_bvalid & ~b_fifo_full;
    assign b_fifo_rd_en = s_axil_bready & s_axil_bvalid;

    /*
     * AR Channel Control Logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_arready <= 1'b0;
        end else begin
            s_axil_arready <= ~ar_fifo_full;
        end
    end

    assign ar_fifo_wr_en = s_axil_arvalid & s_axil_arready;
    assign m_axil_arvalid = ~ar_fifo_empty;
    assign ar_fifo_rd_en = m_axil_arready & m_axil_arvalid;

    /*
     * R Channel Control Logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axil_rvalid <= 1'b0;
        end else begin
            s_axil_rvalid <= ~r_fifo_empty;
        end
    end

    assign r_fifo_wr_en = m_axil_rvalid & ~r_fifo_full;
    assign r_fifo_rd_en = s_axil_rready & s_axil_rvalid;

    /*
     * B Ready Control Logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_bready <= 1'b0;
        end else begin
            m_axil_bready <= ~b_fifo_full;
        end
    end

    /*
     * R Ready Control Logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axil_rready <= 1'b0;
        end else begin
            m_axil_rready <= ~r_fifo_full;
        end
    end

endmodule

/*
 * Asynchronous FIFO Module
 */
module async_fifo #
(
    parameter WIDTH = 32
)
(
    input wire clk_w,
    input wire rst_w,
    input wire [WIDTH-1:0] din,
    input wire wr_en,
    output wire full,
    input wire clk_r,
    input wire rst_r,
    output wire [WIDTH-1:0] dout,
    input wire rd_en,
    output wire empty
);

    reg [WIDTH-1:0] mem [0:7];
    reg [2:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync;

    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            wr_ptr <= 3'b000;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk_w) begin
        wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
    end

    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            rd_ptr_gray_sync <= 3'b000;
        end else begin
            rd_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            rd_ptr <= 3'b000;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign dout = mem[rd_ptr];

    assign full = (wr_ptr_gray == (rd_ptr_gray_sync ^ (rd_ptr_gray_sync >> 1))) && (wr_ptr[2] != rd_ptr_gray_sync[2]);
    assign empty = (wr_ptr_gray == rd_ptr_gray);

endmodule
