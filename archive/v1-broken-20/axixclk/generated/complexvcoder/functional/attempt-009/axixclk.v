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

    wire [C_S_AXI_ID_WIDTH-1 : 0] m_awid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_awaddr;
    wire [7 : 0] m_awlen;
    wire [2 : 0] m_awsize;
    wire [1 : 0] m_awburst;
    wire m_awlock;
    wire [3 : 0] m_awcache;
    wire [2 : 0] m_awprot;
    wire [3 : 0] m_awqos;
    wire m_awvalid;
    wire m_awready;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb;
    wire m_wlast;
    wire m_wvalid;
    wire m_wready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] m_bid;
    wire [1 : 0] m_bresp;
    wire m_bvalid;
    wire m_bready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] m_arid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] m_araddr;
    wire [7 : 0] m_arlen;
    wire [2 : 0] m_arsize;
    wire [1 : 0] m_arburst;
    wire m_arlock;
    wire [3 : 0] m_arcache;
    wire [2 : 0] m_arprot;
    wire [3 : 0] m_arqos;
    wire m_arvalid;
    wire m_arready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] m_rid;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] m_rdata;
    wire [1 : 0] m_rresp;
    wire m_rlast;
    wire m_rvalid;
    wire m_rready;

    assign S_AXI_AWREADY = m_awready;
    assign S_AXI_WREADY = m_wready;
    assign S_AXI_BID = m_bid;
    assign S_AXI_BRESP = m_bresp;
    assign S_AXI_BVALID = m_bvalid;
    assign S_AXI_ARREADY = m_arready;
    assign S_AXI_RID = m_rid;
    assign S_AXI_RDATA = m_rdata;
    assign S_AXI_RRESP = m_rresp;
    assign S_AXI_RLAST = m_rlast;
    assign S_AXI_RVALID = m_rvalid;

    assign M_AXI_AWID = s_awid;
    assign M_AXI_AWADDR = s_awaddr;
    assign M_AXI_AWLEN = s_awlen;
    assign M_AXI_AWSIZE = s_awsize;
    assign M_AXI_AWBURST = s_awburst;
    assign M_AXI_AWLOCK = s_awlock;
    assign M_AXI_AWCACHE = s_awcache;
    assign M_AXI_AWPROT = s_awprot;
    assign M_AXI_AWQOS = s_awqos;
    assign M_AXI_AWVALID = s_awvalid;
    assign m_awready = s_awready;
    assign M_AXI_WDATA = s_wdata;
    assign M_AXI_WSTRB = s_wstrb;
    assign M_AXI_WLAST = s_wlast;
    assign M_AXI_WVALID = s_wvalid;
    assign m_wready = s_wready;
    assign M_AXI_BREADY = s_bready;
    assign M_AXI_ARID = s_arid;
    assign M_AXI_ARADDR = s_araddr;
    assign M_AXI_ARLEN = s_arlen;
    assign M_AXI_ARSIZE = s_arsize;
    assign M_AXI_ARBURST = s_arburst;
    assign M_AXI_ARLOCK = s_arlock;
    assign M_AXI_ARCACHE = s_arcache;
    assign M_AXI_ARPROT = s_arprot;
    assign M_AXI_ARQOS = s_arqos;
    assign M_AXI_ARVALID = s_arvalid;
    assign m_arready = s_arready;
    assign M_AXI_RREADY = s_rready;
    assign M_AXI_ARESETN = ~S_AXI_ARESETN;

    // AXI4 Master and Slave interfaces
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_awid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_awaddr;
    wire [7 : 0] s_awlen;
    wire [2 : 0] s_awsize;
    wire [1 : 0] s_awburst;
    wire s_awlock;
    wire [3 : 0] s_awcache;
    wire [2 : 0] s_awprot;
    wire [3 : 0] s_awqos;
    wire s_awvalid;
    wire s_awready;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s_wdata;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb;
    wire s_wlast;
    wire s_wvalid;
    wire s_wready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_bid;
    wire [1 : 0] s_bresp;
    wire s_bvalid;
    wire s_bready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_arid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_araddr;
    wire [7 : 0] s_arlen;
    wire [2 : 0] s_arsize;
    wire [1 : 0] s_arburst;
    wire s_arlock;
    wire [3 : 0] s_arcache;
    wire [2 : 0] s_arprot;
    wire [3 : 0] s_arqos;
    wire s_arvalid;
    wire s_arready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] s_rid;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata;
    wire [1 : 0] s_rresp;
    wire s_rlast;
    wire s_rvalid;
    wire s_rready;

    // FIFOs for AXI4 transactions
    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) aw_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWID),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awaddr_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWADDR),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awaddr)
    );

    axi_fifo #(
        .ID_WIDTH(8),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awlen_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWLEN),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awlen)
    );

    axi_fifo #(
        .ID_WIDTH(3),
        .DATA_WIDTH(3),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awsize_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWSIZE),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awsize)
    );

    axi_fifo #(
        .ID_WIDTH(2),
        .DATA_WIDTH(2),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awburst_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWBURST),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awburst)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awlock_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWLOCK),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awlock)
    );

    axi_fifo #(
        .ID_WIDTH(4),
        .DATA_WIDTH(4),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awcache_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWCACHE),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awcache)
    );

    axi_fifo #(
        .ID_WIDTH(3),
        .DATA_WIDTH(3),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awprot_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWPROT),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awprot)
    );

    axi_fifo #(
        .ID_WIDTH(4),
        .DATA_WIDTH(4),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awqos_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWQOS),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awqos)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) awvalid_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWVALID),
        .wr_en(S_AXI_AWVALID),
        .rd_en(m_awready),
        .full(m_awready),
        .empty(s_awready),
        .dout(s_awvalid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) wdata_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WDATA),
        .wr_en(S_AXI_WVALID),
        .rd_en(m_wready),
        .full(m_wready),
        .empty(s_wready),
        .dout(s_wdata)
    );

    axi_fifo #(
        .ID_WIDTH((C_S_AXI_DATA_WIDTH/8)),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) wstrb_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WSTRB),
        .wr_en(S_AXI_WVALID),
        .rd_en(m_wready),
        .full(m_wready),
        .empty(s_wready),
        .dout(s_wstrb)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) wlast_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WLAST),
        .wr_en(S_AXI_WVALID),
        .rd_en(m_wready),
        .full(m_wready),
        .empty(s_wready),
        .dout(s_wlast)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) wvalid_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WVALID),
        .wr_en(S_AXI_WVALID),
        .rd_en(m_wready),
        .full(m_wready),
        .empty(s_wready),
        .dout(s_wvalid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(2),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) bresp_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_bresp),
        .wr_en(m_bvalid),
        .rd_en(s_bready),
        .full(s_bready),
        .empty(m_bready),
        .dout(s_bresp)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(2),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) bid_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_bid),
        .wr_en(m_bvalid),
        .rd_en(s_bready),
        .full(s_bready),
        .empty(m_bready),
        .dout(s_bid)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) bvalid_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_bvalid),
        .wr_en(m_bvalid),
        .rd_en(s_bready),
        .full(s_bready),
        .empty(m_bready),
        .dout(s_bvalid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arid_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARID),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ADDR_WIDTH),
        .DATA_WIDTH(C_S_AXI_ADDR_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) araddr_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARADDR),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_araddr)
    );

    axi_fifo #(
        .ID_WIDTH(8),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arlen_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARLEN),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arlen)
    );

    axi_fifo #(
        .ID_WIDTH(3),
        .DATA_WIDTH(3),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arsize_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARSIZE),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arsize)
    );

    axi_fifo #(
        .ID_WIDTH(2),
        .DATA_WIDTH(2),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arburst_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARBURST),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arburst)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arlock_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARLOCK),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arlock)
    );

    axi_fifo #(
        .ID_WIDTH(4),
        .DATA_WIDTH(4),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arcache_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARCACHE),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arcache)
    );

    axi_fifo #(
        .ID_WIDTH(3),
        .DATA_WIDTH(3),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arprot_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARPROT),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arprot)
    );

    axi_fifo #(
        .ID_WIDTH(4),
        .DATA_WIDTH(4),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arqos_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARQOS),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arqos)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) arvalid_fifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_ARVALID),
        .wr_en(S_AXI_ARVALID),
        .rd_en(m_arready),
        .full(m_arready),
        .empty(s_arready),
        .dout(s_arvalid)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) rdata_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_rdata),
        .wr_en(m_rvalid),
        .rd_en(s_rready),
        .full(s_rready),
        .empty(m_rready),
        .dout(s_rdata)
    );

    axi_fifo #(
        .ID_WIDTH(2),
        .DATA_WIDTH(2),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) rresp_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_rresp),
        .wr_en(m_rvalid),
        .rd_en(s_rready),
        .full(s_rready),
        .empty(m_rready),
        .dout(s_rresp)
    );

    axi_fifo #(
        .ID_WIDTH(1),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) rlast_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_rlast),
        .wr_en(m_rvalid),
        .rd_en(s_rready),
        .full(s_rready),
        .empty(m_rready),
        .dout(s_rlast)
    );

    axi_fifo #(
        .ID_WIDTH(C_S_AXI_ID_WIDTH),
        .DATA_WIDTH(1),
        .ADDR_WIDTH(8),
        .FIFO_DEPTH(2**LGFIFO)
    ) rvalid_fifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(m_rvalid),
        .wr_en(m_rvalid),
        .rd_en(s_rready),
        .full(s_rready),
        .empty(m_rready),
        .dout(s_rvalid)
    );

    // AXI4 transactions handling
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            m_awready <= 1'b0;
            m_wready <= 1'b0;
            m_bvalid <= 1'b0;
            m_arready <= 1'b0;
            m_rvalid <= 1'b0;
        end else begin
            m_awready <= M_AXI_AWREADY;
            m_wready <= M_AXI_WREADY;
            m_bvalid <= M_AXI_BVALID;
            m_arready <= M_AXI_ARREADY;
            m_rvalid <= M_AXI_RVALID;
        end
    end

    // AXI4 transactions handling
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            s_awready <= 1'b0;
            s_wready <= 1'b0;
            s_bready <= 1'b0;
            s_arready <= 1'b0;
            s_rready <= 1'b0;
        end else begin
            s_awready <= S_AXI_AWREADY;
            s_wready <= S_AXI_WREADY;
            s_bready <= S_AXI_BREADY;
            s_arready <= S_AXI_ARREADY;
            s_rready <= S_AXI_RREADY;
        end
    end

endmodule

module axi_fifo #(
    parameter ID_WIDTH = 2,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter FIFO_DEPTH = 256
) (
    input wire clk,
    input wire rst,
    input wire [ID_WIDTH-1 : 0] din,
    input wire wr_en,
    input wire rd_en,
    output wire full,
    output wire empty,
    output wire [ID_WIDTH-1 : 0] dout
);

    reg [ID_WIDTH-1 : 0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1 : 0] wr_ptr, rd_ptr;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    assign full = (wr_ptr + 1 == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);
    assign dout = mem[rd_ptr];

endmodule
