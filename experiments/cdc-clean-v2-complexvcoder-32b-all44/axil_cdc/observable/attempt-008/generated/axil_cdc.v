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
     * FIFO for AW transactions
     */
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH+3)) write_address_fifo (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .data_in({s_axil_awaddr, s_axil_awprot}),
        .write(s_axil_awvalid),
        .read(s_axil_awready),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .data_out({m_axil_awaddr, m_axil_awprot}),
        .full(),
        .empty(m_axil_awready)
    );

    /*
     * FIFO for W transactions
     */
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH+STRB_WIDTH)) write_data_fifo (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .data_in({s_axil_wdata, s_axil_wstrb}),
        .write(s_axil_wvalid),
        .read(s_axil_wready),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .data_out({m_axil_wdata, m_axil_wstrb}),
        .full(),
        .empty(m_axil_wready)
    );

    /*
     * FIFO for B transactions
     */
    cdc_fifo #(.DATA_WIDTH(3)) write_response_fifo (
        .clk_w(m_clk),
        .rst_w(m_rst),
        .data_in({m_axil_bresp, m_axil_bvalid}),
        .write(m_axil_bvalid),
        .read(m_axil_bready),
        .clk_r(s_clk),
        .rst_r(s_rst),
        .data_out({s_axil_bresp, s_axil_bvalid}),
        .full(),
        .empty(s_axil_bready)
    );

    /*
     * FIFO for AR transactions
     */
    cdc_fifo #(.DATA_WIDTH(ADDR_WIDTH+3)) read_address_fifo (
        .clk_w(s_clk),
        .rst_w(s_rst),
        .data_in({s_axil_araddr, s_axil_arprot}),
        .write(s_axil_arvalid),
        .read(s_axil_arready),
        .clk_r(m_clk),
        .rst_r(m_rst),
        .data_out({m_axil_araddr, m_axil_arprot}),
        .full(),
        .empty(m_axil_arready)
    );

    /*
     * FIFO for R transactions
     */
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH+2)) read_data_fifo (
        .clk_w(m_clk),
        .rst_w(m_rst),
        .data_in({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .write(m_axil_rvalid),
        .read(m_axil_rready),
        .clk_r(s_clk),
        .rst_r(s_rst),
        .data_out({s_axil_rdata, s_axil_rresp, s_axil_rvalid}),
        .full(),
        .empty(s_axil_rready)
    );

endmodule

module cdc_fifo #(
    parameter DATA_WIDTH = 32
)
(
    input  wire                   clk_w,
    input  wire                   rst_w,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   write,
    output wire                   read,
    input  wire                   clk_r,
    input  wire                   rst_r,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire                   full,
    output wire                   empty
);

    reg [DATA_WIDTH-1:0] mem [0:7];
    reg [2:0] wptr, rptr;
    reg [2:0] wptr_gray, rptr_gray;
    reg [2:0] wptr_gray_sync, rptr_gray_sync;

    // Write Pointer Update
    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            wptr <= 3'b000;
        end else if (write && !full) begin
            mem[wptr] <= data_in;
            wptr <= wptr + 1;
        end
    end

    // Read Pointer Update
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            rptr <= 3'b000;
        end else if (read && !empty) begin
            rptr <= rptr + 1;
        end
    end

    // Write Pointer Gray Code
    always @(wptr) begin
        wptr_gray = (wptr >> 1) ^ wptr;
    end

    // Read Pointer Gray Code
    always @(rptr) begin
        rptr_gray = (rptr >> 1) ^ rptr;
    end

    // Synchronize Write Pointer Gray Code to Read Clock Domain
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            wptr_gray_sync <= 3'b000;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    // Synchronize Read Pointer Gray Code to Write Clock Domain
    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            rptr_gray_sync <= 3'b000;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    // Full Flag
    assign full = (wptr_gray_sync == (rptr_gray ^ 3'b100));

    // Empty Flag
    assign empty = (wptr_gray_sync == rptr_gray_sync);

    // Read Data Output
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (read && !empty) begin
            data_out <= mem[rptr];
        end
    end

    // Read Enable
    assign read = !empty;

endmodule
