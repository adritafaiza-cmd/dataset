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

    // Internal signals for FIFOs
    wire [ADDR_WIDTH-1:0] awfifo_din, awfifo_dout;
    wire [2:0] awfifo_prot_in, awfifo_prot_out;
    wire awfifo_wren, awfifo_rden, awfifo_full, awfifo_empty;

    wire [DATA_WIDTH-1:0] wfifo_din, wfifo_dout;
    wire [STRB_WIDTH-1:0] wfifo_strb_in, wfifo_strb_out;
    wire wfifo_wren, wfifo_rden, wfifo_full, wfifo_empty;

    wire [1:0] bfifo_din, bfifo_dout;
    wire bfifo_wren, bfifo_rden, bfifo_full, bfifo_empty;

    wire [ADDR_WIDTH-1:0] arfifo_din, arfifo_dout;
    wire [2:0] arfifo_prot_in, arfifo_prot_out;
    wire arfifo_wren, arfifo_rden, arfifo_full, arfifo_empty;

    wire [DATA_WIDTH-1:0] rfifo_din, rfifo_dout;
    wire [1:0] rfifo_resp_in, rfifo_resp_out;
    wire rfifo_wren, rfifo_rden, rfifo_full, rfifo_empty;

    // AW Channel FIFO
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 3)
    ) aw_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({s_axil_awaddr, s_axil_awprot}),
        .dout({awfifo_dout, awfifo_prot_out}),
        .wren(awfifo_wren),
        .rden(awfifo_rden),
        .full(awfifo_full),
        .empty(awfifo_empty)
    );

    // W Channel FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + STRB_WIDTH)
    ) w_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({s_axil_wdata, s_axil_wstrb}),
        .dout({wfifo_dout, wfifo_strb_out}),
        .wren(wfifo_wren),
        .rden(wfifo_rden),
        .full(wfifo_full),
        .empty(wfifo_empty)
    );

    // B Channel FIFO
    async_fifo #(
        .DATA_WIDTH(2)
    ) b_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din(m_axil_bresp),
        .dout(bfifo_dout),
        .wren(bfifo_wren),
        .rden(bfifo_rden),
        .full(bfifo_full),
        .empty(bfifo_empty)
    );

    // AR Channel FIFO
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 3)
    ) ar_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({s_axil_araddr, s_axil_arprot}),
        .dout({arfifo_dout, arfifo_prot_out}),
        .wren(arfifo_wren),
        .rden(arfifo_rden),
        .full(arfifo_full),
        .empty(arfifo_empty)
    );

    // R Channel FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 2)
    ) r_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .din({m_axil_rdata, m_axil_rresp}),
        .dout({rfifo_dout, rfifo_resp_out}),
        .wren(rfifo_wren),
        .rden(rfifo_rden),
        .full(rfifo_full),
        .empty(rfifo_empty)
    );

    // AW Channel Control
    assign s_axil_awready = ~awfifo_full;
    assign awfifo_wren = s_axil_awvalid & s_axil_awready;
    assign m_axil_awaddr = awfifo_dout;
    assign m_axil_awprot = awfifo_prot_out;
    assign m_axil_awvalid = ~awfifo_empty;
    assign awfifo_rden = m_axil_awready & m_axil_awvalid;

    // W Channel Control
    assign s_axil_wready = ~wfifo_full;
    assign wfifo_wren = s_axil_wvalid & s_axil_wready;
    assign m_axil_wdata = wfifo_dout;
    assign m_axil_wstrb = wfifo_strb_out;
    assign m_axil_wvalid = ~wfifo_empty;
    assign wfifo_rden = m_axil_wready & m_axil_wvalid;

    // B Channel Control
    assign s_axil_bresp = bfifo_dout;
    assign s_axil_bvalid = ~bfifo_empty;
    assign bfifo_rden = s_axil_bready & s_axil_bvalid;
    assign m_axil_bready = ~bfifo_full;
    assign bfifo_wren = m_axil_bvalid & m_axil_bready;

    // AR Channel Control
    assign s_axil_arready = ~arfifo_full;
    assign arfifo_wren = s_axil_arvalid & s_axil_arready;
    assign m_axil_araddr = arfifo_dout;
    assign m_axil_arprot = arfifo_prot_out;
    assign m_axil_arvalid = ~arfifo_empty;
    assign arfifo_rden = m_axil_arready & m_axil_arvalid;

    // R Channel Control
    assign s_axil_rdata = rfifo_dout;
    assign s_axil_rresp = rfifo_resp_out;
    assign s_axil_rvalid = ~rfifo_empty;
    assign rfifo_rden = s_axil_rready & s_axil_rvalid;
    assign m_axil_rready = ~rfifo_full;
    assign rfifo_wren = m_axil_rvalid & m_axil_rready;

endmodule

module async_fifo #
(
    parameter DATA_WIDTH = 32
)
(
    input  wire clk,
    input  wire rst,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input  wire wren,
    input  wire rden,
    output wire full,
    output wire empty
);

    localparam DEPTH = 4;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    wire wr_en = wren & ~full;
    wire rd_en = rden & ~empty;

    // Write Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Gray Code Conversion for Write Pointer
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    // Synchronize Write Pointer to Read Clock Domain
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Read Pointer Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray Code Conversion for Read Pointer
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Synchronize Read Pointer to Write Clock Domain
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // FIFO Memory
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_ptr] <= din;
        end
    end

    // FIFO Output
    assign dout = mem[rd_ptr];

    // FIFO Status Flags
    assign full = (wr_ptr_gray_sync[ADDR_WIDTH-1:0] ^ rd_ptr_gray[ADDR_WIDTH-1:0]) == {ADDR_WIDTH{1'b1}};
    assign empty = wr_ptr_gray == rd_ptr_gray;

endmodule
