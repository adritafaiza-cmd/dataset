module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH = 2,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
    parameter [0:0] OPT_WRITE_ONLY = 1'b0,
    parameter [0:0] OPT_READ_ONLY = 1'b0,
    parameter XCLOCK_FFS = 2,
    parameter LGFIFO = 5
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [7 : 0] S_AXI_AWLEN,
    input wire [2 : 0] S_AXI_AWSIZE,
    input wire [1 : 0] S_AXI_AWBURST,
    input wire S_AXI_AWLOCK,
    input wire [3 : 0] S_AXI_AWCACHE,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire [3 : 0] S_AXI_AWQOS,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WLAST,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [7 : 0] S_AXI_ARLEN,
    input wire [2 : 0] S_AXI_ARSIZE,
    input wire [1 : 0] S_AXI_ARBURST,
    input wire S_AXI_ARLOCK,
    input wire [3 : 0] S_AXI_ARCACHE,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire [3 : 0] S_AXI_ARQOS,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RLAST,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,
    input wire M_AXI_ACLK,
    output wire M_AXI_ARESETN,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [7 : 0] M_AXI_AWLEN,
    output wire [2 : 0] M_AXI_AWSIZE,
    output wire [1 : 0] M_AXI_AWBURST,
    output wire M_AXI_AWLOCK,
    output wire [3 : 0] M_AXI_AWCACHE,
    output wire [2 : 0] M_AXI_AWPROT,
    output wire [3 : 0] M_AXI_AWQOS,
    output wire M_AXI_AWVALID,
    input wire M_AXI_AWREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output wire M_AXI_WLAST,
    output wire M_AXI_WVALID,
    input wire M_AXI_WREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    input wire [1 : 0] M_AXI_BRESP,
    input wire M_AXI_BVALID,
    output wire M_AXI_BREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [7 : 0] M_AXI_ARLEN,
    output wire [2 : 0] M_AXI_ARSIZE,
    output wire [1 : 0] M_AXI_ARBURST,
    output wire M_AXI_ARLOCK,
    output wire [3 : 0] M_AXI_ARCACHE,
    output wire [2 : 0] M_AXI_ARPROT,
    output wire [3 : 0] M_AXI_ARQOS,
    output wire M_AXI_ARVALID,
    input wire M_AXI_ARREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire M_AXI_RLAST,
    input wire M_AXI_RVALID,
    output wire M_AXI_RREADY
);

    wire s_axi_awready;
    wire s_axi_wready;
    wire s_axi_bvalid;
    wire s_axi_arready;
    wire s_axi_rvalid;

    wire m_axi_awid;
    wire m_axi_awaddr;
    wire m_axi_awlen;
    wire m_axi_awsize;
    wire m_axi_awburst;
    wire m_axi_awlock;
    wire m_axi_awcache;
    wire m_axi_awprot;
    wire m_axi_awqos;
    wire m_axi_awvalid;
    wire m_axi_wdata;
    wire m_axi_wstrb;
    wire m_axi_wlast;
    wire m_axi_wvalid;
    wire m_axi_bready;
    wire m_axi_arid;
    wire m_axi_araddr;
    wire m_axi_arlen;
    wire m_axi_arsize;
    wire m_axi_arburst;
    wire m_axi_arlock;
    wire m_axi_arcache;
    wire m_axi_arprot;
    wire m_axi_arqos;
    wire m_axi_arvalid;
    wire m_axi_rready;

    wire write_fifo_full;
    wire write_fifo_empty;
    wire read_fifo_full;
    wire read_fifo_empty;

    fifo #(.WIDTH(C_S_AXI_DATA_WIDTH), .DEPTH(2**LGFIFO)) write_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WDATA),
        .wr_en(S_AXI_WVALID & S_AXI_WREADY),
        .rd_en(M_AXI_WVALID & M_AXI_WREADY),
        .full(write_fifo_full),
        .empty(write_fifo_empty)
    );

    fifo #(.WIDTH(C_S_AXI_DATA_WIDTH), .DEPTH(2**LGFIFO)) read_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(M_AXI_RDATA),
        .wr_en(M_AXI_RVALID & M_AXI_RREADY),
        .rd_en(S_AXI_RVALID & S_AXI_RREADY),
        .full(read_fifo_full),
        .empty(read_fifo_empty)
    );

    sync_reset #(.WIDTH(1)) s_axi_reset_sync (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .sync_rst(M_AXI_ARESETN)
    );

    assign S_AXI_AWREADY = write_fifo_full;
    assign S_AXI_WREADY = write_fifo_full;
    assign M_AXI_AWVALID = write_fifo.wr_en;
    assign M_AXI_WVALID = write_fifo.wr_en;
    assign S_AXI_BID = write_fifo.din;
    assign S_AXI_BRESP = write_fifo.din;
    assign S_AXI_BVALID = write_fifo.wr_en;
    assign S_AXI_ARREADY = read_fifo_full;
    assign S_AXI_RREADY = read_fifo_full;
    assign M_AXI_RVALID = read_fifo.wr_en;
    assign M_AXI_RVALID = read_fifo.wr_en;
    assign S_AXI_RID = read_fifo.din;
    assign S_AXI_RDATA = read_fifo.din;
    assign S_AXI_RRESP = read_fifo.din;
    assign S_AXI_RLAST = read_fifo.din;

endmodule

module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 4
) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire full,
    output wire empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] wr_ptr;
    reg [DEPTH-1:0] rd_ptr;
    reg [DEPTH-1:0] count;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH) begin
                    wr_ptr <= 0;
                end
                count <= count + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH) begin
                    rd_ptr <= 0;
                end
                count <= count - 1;
            end
        end
    end

    assign full = (count == DEPTH);
    assign empty = (count == 0);

endmodule

module sync_reset #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire rst,
    output wire sync_rst
);

    reg [WIDTH-1:0] rst_reg;

    always @(posedge clk) begin
        rst_reg <= {rst_reg[WIDTH-2:0], rst};
    end

    assign sync_rst = rst_reg[WIDTH-1];

endmodule
