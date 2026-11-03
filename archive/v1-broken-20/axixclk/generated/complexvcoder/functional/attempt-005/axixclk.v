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

    wire m_axi_awvalid;
    wire m_axi_wvalid;
    wire m_axi_bready;
    wire m_axi_arvalid;
    wire m_axi_rready;

    assign S_AXI_AWREADY = s_axi_awready;
    assign S_AXI_WREADY = s_axi_wready;
    assign S_AXI_BVALID = s_axi_bvalid;
    assign S_AXI_ARREADY = s_axi_arready;
    assign S_AXI_RVALID = s_axi_rvalid;

    assign M_AXI_ARESETN = ~S_AXI_ARESETN;

    assign M_AXI_AWVALID = s_axi_awvalid;
    assign M_AXI_WVALID = s_axi_wvalid;
    assign M_AXI_BREADY = s_axi_bvalid;
    assign M_AXI_ARVALID = s_axi_arready;
    assign M_AXI_RREADY = s_axi_rvalid;

    assign M_AXI_AWID = S_AXI_AWID;
    assign M_AXI_AWADDR = S_AXI_AWADDR;
    assign M_AXI_AWLEN = S_AXI_AWLEN;
    assign M_AXI_AWSIZE = S_AXI_AWSIZE;
    assign M_AXI_AWBURST = S_AXI_AWBURST;
    assign M_AXI_AWLOCK = S_AXI_AWLOCK;
    assign M_AXI_AWCACHE = S_AXI_AWCACHE;
    assign M_AXI_AWPROT = S_AXI_AWPROT;
    assign M_AXI_AWQOS = S_AXI_AWQOS;

    assign M_AXI_WDATA = S_AXI_WDATA;
    assign M_AXI_WSTRB = S_AXI_WSTRB;
    assign M_AXI_WLAST = S_AXI_WLAST;

    assign S_AXI_BID = M_AXI_BID;
    assign S_AXI_BRESP = M_AXI_BRESP;

    assign S_AXI_ARID = M_AXI_ARID;
    assign S_AXI_ARADDR = M_AXI_ARADDR;
    assign S_AXI_ARLEN = M_AXI_ARLEN;
    assign S_AXI_ARSIZE = M_AXI_ARSIZE;
    assign S_AXI_ARBURST = M_AXI_ARBURST;
    assign S_AXI_ARLOCK = M_AXI_ARLOCK;
    assign S_AXI_ARCACHE = M_AXI_ARCACHE;
    assign S_AXI_ARPROT = M_AXI_ARPROT;
    assign S_AXI_ARQOS = M_AXI_ARQOS;

    assign S_AXI_RID = M_AXI_RID;
    assign S_AXI_RDATA = M_AXI_RDATA;
    assign S_AXI_RRESP = M_AXI_RRESP;
    assign S_AXI_RLAST = M_AXI_RLAST;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end else begin
            s_axi_awready <= M_AXI_AWREADY;
            s_axi_wready <= M_AXI_WREADY;
            s_axi_bvalid <= M_AXI_BVALID;
            s_axi_arready <= M_AXI_ARREADY;
            s_axi_rvalid <= M_AXI_RVALID;
        end
    end

endmodule
