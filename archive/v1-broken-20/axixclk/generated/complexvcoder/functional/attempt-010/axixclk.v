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

    // Internal signals
    wire [C_S_AXI_ID_WIDTH-1 : 0] awid_reg;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_reg;
    wire [7 : 0] awlen_reg;
    wire [2 : 0] awsize_reg;
    wire [1 : 0] awburst_reg;
    wire awlock_reg;
    wire [3 : 0] awcache_reg;
    wire [2 : 0] awprot_reg;
    wire [3 : 0] awqos_reg;
    wire awvalid_reg;
    wire awready_reg;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata_reg;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_reg;
    wire wlast_reg;
    wire wvalid_reg;
    wire wready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] bid_reg;
    wire [1 : 0] bresp_reg;
    wire bvalid_reg;
    wire bready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] arid_reg;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_reg;
    wire [7 : 0] arlen_reg;
    wire [2 : 0] arsize_reg;
    wire [1 : 0] arburst_reg;
    wire arlock_reg;
    wire [3 : 0] arcache_reg;
    wire [2 : 0] arprot_reg;
    wire [3 : 0] arqos_reg;
    wire arvalid_reg;
    wire arready_reg;
    wire [C_S_AXI_ID_WIDTH-1 : 0] rid_reg;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata_reg;
    wire [1 : 0] rresp_reg;
    wire rlast_reg;
    wire rvalid_reg;
    wire rready_reg;

    // FIFOs for buffering
    fifo_256x34 awfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWID),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awid_reg),
        .full(),
        .empty()
    );

    fifo_256x34 awaddrfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWADDR),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awaddr_reg),
        .full(),
        .empty()
    );

    fifo_256x8 awlenfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWLEN),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awlen_reg),
        .full(),
        .empty()
    );

    fifo_256x3 awsizefifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWSIZE),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awsize_reg),
        .full(),
        .empty()
    );

    fifo_256x2 awburstfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWBURST),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awburst_reg),
        .full(),
        .empty()
    );

    fifo_256x1 awlockfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWLOCK),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awlock_reg),
        .full(),
        .empty()
    );

    fifo_256x4 awcachefifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWCACHE),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awcache_reg),
        .full(),
        .empty()
    );

    fifo_256x3 awprotfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWPROT),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awprot_reg),
        .full(),
        .empty()
    );

    fifo_256x4 awqosfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWQOS),
        .wr_en(S_AXI_AWVALID),
        .rd_en(M_AXI_AWREADY),
        .dout(awqos_reg),
        .full(),
        .empty()
    );

    fifo_256x1 awvalidfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_AWVALID),
        .wr_en(1'b1),
        .rd_en(M_AXI_AWREADY),
        .dout(awvalid_reg),
        .full(),
        .empty()
    );

    fifo_256x1 awreadyfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(M_AXI_AWREADY),
        .wr_en(1'b1),
        .rd_en(awvalid_reg),
        .dout(awready_reg),
        .full(),
        .empty()
    );

    fifo_256x32 wdatafifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WDATA),
        .wr_en(S_AXI_WVALID),
        .rd_en(M_AXI_WREADY),
        .dout(wdata_reg),
        .full(),
        .empty()
    );

    fifo_256x4 wstrbfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WSTRB),
        .wr_en(S_AXI_WVALID),
        .rd_en(M_AXI_WREADY),
        .dout(wstrb_reg),
        .full(),
        .empty()
    );

    fifo_256x1 wlastfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WLAST),
        .wr_en(S_AXI_WVALID),
        .rd_en(M_AXI_WREADY),
        .dout(wlast_reg),
        .full(),
        .empty()
    );

    fifo_256x1 wvalidfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_WVALID),
        .wr_en(1'b1),
        .rd_en(M_AXI_WREADY),
        .dout(wvalid_reg),
        .full(),
        .empty()
    );

    fifo_256x1 wreadyfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(M_AXI_WREADY),
        .wr_en(1'b1),
        .rd_en(wvalid_reg),
        .dout(wready_reg),
        .full(),
        .empty()
    );

    fifo_256x32 bdatafifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_BID),
        .wr_en(M_AXI_BVALID),
        .rd_en(S_AXI_BREADY),
        .dout(bid_reg),
        .full(),
        .empty()
    );

    fifo_256x2 brespfifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_BRESP),
        .wr_en(M_AXI_BVALID),
        .rd_en(S_AXI_BREADY),
        .dout(bresp_reg),
        .full(),
        .empty()
    );

    fifo_256x1 bvalidfifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_BVALID),
        .wr_en(1'b1),
        .rd_en(S_AXI_BREADY),
        .dout(bvalid_reg),
        .full(),
        .empty()
    );

    fifo_256x1 breadyfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_BREADY),
        .wr_en(1'b1),
        .rd_en(bvalid_reg),
        .dout(bready_reg),
        .full(),
        .empty()
    );

    fifo_256x32 rdatafifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_RID),
        .wr_en(M_AXI_RVALID),
        .rd_en(S_AXI_RREADY),
        .dout(rid_reg),
        .full(),
        .empty()
    );

    fifo_256x32 rdatafifo2 (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_RDATA),
        .wr_en(M_AXI_RVALID),
        .rd_en(S_AXI_RREADY),
        .dout(rdata_reg),
        .full(),
        .empty()
    );

    fifo_256x2 rrespfifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_RRESP),
        .wr_en(M_AXI_RVALID),
        .rd_en(S_AXI_RREADY),
        .dout(rresp_reg),
        .full(),
        .empty()
    );

    fifo_256x1 rlastfifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_RLAST),
        .wr_en(M_AXI_RVALID),
        .rd_en(S_AXI_RREADY),
        .dout(rlast_reg),
        .full(),
        .empty()
    );

    fifo_256x1 rvalidfifo (
        .clk(M_AXI_ACLK),
        .rst(!M_AXI_ARESETN),
        .din(M_AXI_RVALID),
        .wr_en(1'b1),
        .rd_en(S_AXI_RREADY),
        .dout(rvalid_reg),
        .full(),
        .empty()
    );

    fifo_256x1 rreadyfifo (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN),
        .din(S_AXI_RREADY),
        .wr_en(1'b1),
        .rd_en(rvalid_reg),
        .dout(rready_reg),
        .full(),
        .empty()
    );

    // AXI4 Slave to Master Interface
    assign M_AXI_ARESETN = S_AXI_ARESETN;
    assign M_AXI_AWID = awid_reg;
    assign M_AXI_AWADDR = awaddr_reg;
    assign M_AXI_AWLEN = awlen_reg;
    assign M_AXI_AWSIZE = awsize_reg;
    assign M_AXI_AWBURST = awburst_reg;
    assign M_AXI_AWLOCK = awlock_reg;
    assign M_AXI_AWCACHE = awcache_reg;
    assign M_AXI_AWPROT = awprot_reg;
    assign M_AXI_AWQOS = awqos_reg;
    assign M_AXI_AWVALID = awvalid_reg;

    assign S_AXI_AWREADY = awready_reg;

    assign M_AXI_WDATA = wdata_reg;
    assign M_AXI_WSTRB = wstrb_reg;
    assign M_AXI_WLAST = wlast_reg;
    assign M_AXI_WVALID = wvalid_reg;

    assign S_AXI_WREADY = wready_reg;

    assign M_AXI_BREADY = bready_reg;

    assign M_AXI_ARID = arid_reg;
    assign M_AXI_ARADDR = araddr_reg;
    assign M_AXI_ARLEN = arlen_reg;
    assign M_AXI_ARSIZE = arsize_reg;
    assign M_AXI_ARBURST = arburst_reg;
    assign M_AXI_ARLOCK = arlock_reg;
    assign M_AXI_ARCACHE = arcache_reg;
    assign M_AXI_ARPROT = arprot_reg;
    assign M_AXI_ARQOS = arqos_reg;
    assign M_AXI_ARVALID = arvalid_reg;

    assign S_AXI_ARREADY = arready_reg;

    assign M_AXI_RREADY = rready_reg;

    // AXI4 Master to Slave Interface
    assign S_AXI_BID = bid_reg;
    assign S_AXI_BRESP = bresp_reg;
    assign S_AXI_BVALID = bvalid_reg;

    assign M_AXI_RID = rid_reg;
    assign M_AXI_RDATA = rdata_reg;
    assign M_AXI_RRESP = rresp_reg;
    assign M_AXI_RLAST = rlast_reg;
    assign M_AXI_RVALID = rvalid_reg;

endmodule
