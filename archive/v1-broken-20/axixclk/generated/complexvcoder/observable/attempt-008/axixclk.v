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

    wire [C_S_AXI_ID_WIDTH-1 : 0] axi_awid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    wire [7 : 0] axi_awlen;
    wire [2 : 0] axi_awsize;
    wire [1 : 0] axi_awburst;
    wire axi_awlock;
    wire [3 : 0] axi_awcache;
    wire [2 : 0] axi_awprot;
    wire [3 : 0] axi_awqos;
    wire axi_awvalid;
    wire axi_awready;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_wdata;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb;
    wire axi_wlast;
    wire axi_wvalid;
    wire axi_wready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] axi_bid;
    wire [1 : 0] axi_bresp;
    wire axi_bvalid;
    wire axi_bready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] axi_arid;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    wire [7 : 0] axi_arlen;
    wire [2 : 0] axi_arsize;
    wire [1 : 0] axi_arburst;
    wire axi_arlock;
    wire [3 : 0] axi_arcache;
    wire [2 : 0] axi_arprot;
    wire [3 : 0] axi_arqos;
    wire axi_arvalid;
    wire axi_arready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] axi_rid;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    wire [1 : 0] axi_rresp;
    wire axi_rlast;
    wire axi_rvalid;
    wire axi_rready;

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

    axi_crossbar axi_crossbar_inst (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWID(S_AXI_AWID),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWLEN(S_AXI_AWLEN),
        .S_AXI_AWSIZE(S_AXI_AWSIZE),
        .S_AXI_AWBURST(S_AXI_AWBURST),
        .S_AXI_AWLOCK(S_AXI_AWLOCK),
        .S_AXI_AWCACHE(S_AXI_AWCACHE),
        .S_AXI_AWPROT(S_AXI_AWPROT),
        .S_AXI_AWQOS(S_AXI_AWQOS),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WLAST(S_AXI_WLAST),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(s_axi_wready),
        .S_AXI_BID(axi_bid),
        .S_AXI_BRESP(axi_bresp),
        .S_AXI_BVALID(s_axi_bvalid),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARID(S_AXI_ARID),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARLEN(S_AXI_ARLEN),
        .S_AXI_ARSIZE(S_AXI_ARSIZE),
        .S_AXI_ARBURST(S_AXI_ARBURST),
        .S_AXI_ARLOCK(S_AXI_ARLOCK),
        .S_AXI_ARCACHE(S_AXI_ARCACHE),
        .S_AXI_ARPROT(S_AXI_ARPROT),
        .S_AXI_ARQOS(S_AXI_ARQOS),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(s_axi_arready),
        .S_AXI_RID(axi_rid),
        .S_AXI_RDATA(axi_rdata),
        .S_AXI_RRESP(axi_rresp),
        .S_AXI_RLAST(axi_rlast),
        .S_AXI_RVALID(s_axi_rvalid),
        .S_AXI_RREADY(S_AXI_RREADY),
        .M_AXI_ACLK(M_AXI_ACLK),
        .M_AXI_ARESETN(M_AXI_ARESETN),
        .M_AXI_AWID(axi_awid),
        .M_AXI_AWADDR(axi_awaddr),
        .M_AXI_AWLEN(axi_awlen),
        .M_AXI_AWSIZE(axi_awsize),
        .M_AXI_AWBURST(axi_awburst),
        .M_AXI_AWLOCK(axi_awlock),
        .M_AXI_AWCACHE(axi_awcache),
        .M_AXI_AWPROT(axi_awprot),
        .M_AXI_AWQOS(axi_awqos),
        .M_AXI_AWVALID(m_axi_awvalid),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_WDATA(axi_wdata),
        .M_AXI_WSTRB(axi_wstrb),
        .M_AXI_WLAST(axi_wlast),
        .M_AXI_WVALID(m_axi_wvalid),
        .M_AXI_WREADY(M_AXI_WREADY),
        .M_AXI_BID(M_AXI_BID),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(m_axi_bready),
        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARLOCK(M_AXI_ARLOCK),
        .M_AXI_ARCACHE(M_AXI_ARCACHE),
        .M_AXI_ARPROT(M_AXI_ARPROT),
        .M_AXI_ARQOS(M_AXI_ARQOS),
        .M_AXI_ARVALID(m_axi_arvalid),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_RID(M_AXI_RID),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(m_axi_rready)
    );

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY <= 0;
            S_AXI_BVALID <= 0;
            S_AXI_ARREADY <= 0;
            S_AXI_RVALID <= 0;
        end else begin
            S_AXI_AWREADY <= s_axi_awready;
            S_AXI_WREADY <= s_axi_wready;
            S_AXI_BVALID <= s_axi_bvalid;
            S_AXI_ARREADY <= s_axi_arready;
            S_AXI_RVALID <= s_axi_rvalid;
        end
    end

    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_ARESETN <= 0;
        end else begin
            M_AXI_ARESETN <= 1;
        end
    end

endmodule
