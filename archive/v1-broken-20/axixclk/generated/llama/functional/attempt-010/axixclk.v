module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH    = 2,
    parameter integer C_S_AXI_DATA_WIDTH  = 32,
    parameter integer C_S_AXI_ADDR_WIDTH  = 6,
    parameter [0:0]    OPT_WRITE_ONLY = 1'b0,
    parameter [0:0]    OPT_READ_ONLY = 1'b0,
    parameter    XCLOCK_FFS = 2,
    parameter    LGFIFO = 5
) (
    input   wire                S_AXI_ACLK,
    input   wire                S_AXI_ARESETN,
    input   wire [C_S_AXI_ID_WIDTH-1 : 0]    S_AXI_AWID,
    input   wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input   wire [7 : 0]            S_AXI_AWLEN,
    input   wire [2 : 0]            S_AXI_AWSIZE,
    input   wire [1 : 0]            S_AXI_AWBURST,
    input   wire                S_AXI_AWLOCK,
    input   wire [3 : 0]            S_AXI_AWCACHE,
    input   wire [2 : 0]            S_AXI_AWPROT,
    input   wire [3 : 0]            S_AXI_AWQOS,
    input   wire                S_AXI_AWVALID,
    output  wire                S_AXI_AWREADY,
    input   wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input   wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input   wire                S_AXI_WLAST,
    input   wire                S_AXI_WVALID,
    output  wire                S_AXI_WREADY,
    output  wire [C_S_AXI_ID_WIDTH-1 : 0]    S_AXI_BID,
    output  wire [1 : 0]            S_AXI_BRESP,
    output  wire                S_AXI_BVALID,
    input   wire                S_AXI_BREADY,
    input   wire [C_S_AXI_ID_WIDTH-1 : 0]    S_AXI_ARID,
    input   wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input   wire [7 : 0]            S_AXI_ARLEN,
    input   wire [2 : 0]            S_AXI_ARSIZE,
    input   wire [1 : 0]            S_AXI_ARBURST,
    input   wire                S_AXI_ARLOCK,
    input   wire [3 : 0]            S_AXI_ARCACHE,
    input   wire [2 : 0]            S_AXI_ARPROT,
    input   wire [3 : 0]            S_AXI_ARQOS,
    input   wire                S_AXI_ARVALID,
    output  wire                S_AXI_ARREADY,
    output  wire [C_S_AXI_ID_WIDTH-1 : 0]    S_AXI_RID,
    output  wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output  wire [1 : 0]            S_AXI_RRESP,
    output  wire                S_AXI_RLAST,
    output  wire                S_AXI_RVALID,
    input   wire                S_AXI_RREADY,
    input   wire                M_AXI_ACLK,
    output  wire                M_AXI_ARESETN,
    output  wire [C_S_AXI_ID_WIDTH-1 : 0]    M_AXI_AWID,
    output  wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output  wire [7 : 0]            M_AXI_AWLEN,
    output  wire [2 : 0]            M_AXI_AWSIZE,
    output  wire [1 : 0]            M_AXI_AWBURST,
    output  wire                M_AXI_AWLOCK,
    output  wire [3 : 0]            M_AXI_AWCACHE,
    output  wire [2 : 0]            M_AXI_AWPROT,
    output  wire [3 : 0]            M_AXI_AWQOS,
    output  wire                M_AXI_AWVALID,
    input   wire                M_AXI_AWREADY,
    output  wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output  wire                M_AXI_WLAST,
    output  wire                M_AXI_WVALID,
    input   wire                M_AXI_WREADY,
    input   wire [C_S_AXI_ID_WIDTH-1 : 0]    M_AXI_BID,
    input   wire [1 : 0]            M_AXI_BRESP,
    input   wire                M_AXI_BVALID,
    output  wire                M_AXI_BREADY,
    output  wire [C_S_AXI_ID_WIDTH-1 : 0]    M_AXI_ARID,
    output  wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output  wire [7 : 0]            M_AXI_ARLEN,
    output  wire [2 : 0]            M_AXI_ARSIZE,
    output  wire [1 : 0]            M_AXI_ARBURST,
    output  wire                M_AXI_ARLOCK,
    output  wire [3 : 0]            M_AXI_ARCACHE,
    output  wire [2 : 0]            M_AXI_ARPROT,
    output  wire [3 : 0]            M_AXI_ARQOS,
    output  wire                M_AXI_ARVALID,
    input   wire                M_AXI_ARREADY,
    input   wire [C_S_AXI_ID_WIDTH-1 : 0]    M_AXI_RID,
    input   wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input   wire [1 : 0]            M_AXI_RRESP,
    input   wire                M_AXI_RLAST,
    input   wire                M_AXI_RVALID,
    output  wire                M_AXI_RREADY
);

// Reset logic
reg     s_axi_reset;
reg     m_axi_reset;
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (~S_AXI_ARESETN) begin
        s_axi_reset <= 1'b1;
    end else begin
        s_axi_reset <= 1'b0;
    end
end
always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
    if (~M_AXI_ARESETN) begin
        m_axi_reset <= 1'b1;
    end else begin
        m_axi_reset <= 1'b0;
    end
end
assign M_AXI_ARESETN = ~m_axi_reset;

// Write channel
reg [C_S_AXI_ID_WIDTH-1 : 0]    awid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr_reg;
reg [7 : 0]            awlen_reg;
reg [2 : 0]            awsize_reg;
reg [1 : 0]            awburst_reg;
reg                 awlock_reg;
reg [3 : 0]            awcache_reg;
reg [2 : 0]            awprot_reg;
reg [3 : 0]            awqos_reg;
reg                 awvalid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0] wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_reg;
reg                 wlast_reg;
reg                 wvalid_reg;
reg                 bready_reg;
reg [C_S_AXI_ID_WIDTH-1 : 0]    bid_reg;
reg [1 : 0]            bresp_reg;
reg                 bvalid_reg;
reg                 bready_m_reg;
reg                 awready_m_reg;
reg                 wready_m_reg;

// Read channel
reg [C_S_AXI_ID_WIDTH-1 : 0]    arid_reg;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] araddr_reg;
reg [7 : 0]            arlen_reg;
reg [2 : 0]            arsize_reg;
reg [1 : 0]            arburst_reg;
reg                 arlock_reg;
reg [3 : 0]            arcache_reg;
reg [2 : 0]            arprot_reg;
reg [3 : 0]            arqos_reg;
reg                 arvalid_reg;
reg [C_S_AXI_ID_WIDTH-1 : 0]    rid_reg;
reg [C_S_AXI_DATA_WIDTH-1 : 0] rdata_reg;
reg [1 : 0]            rresp_reg;
reg                 rlast_reg;
reg                 rvalid_reg;
reg                 rready_reg;
reg                 arready_m_reg;
reg                 rready_m_reg;

// Clock domain crossing
reg [XCLOCK_FFS-1 : 0]    aw_cross;
reg [XCLOCK_FFS-1 : 0]    w_cross;
reg [XCLOCK_FFS-1 : 0]    b_cross;
reg [XCLOCK_FFS-1 : 0]    ar_cross;
reg [XCLOCK_FFS-1 : 0]    r_cross;

// FIFOs
reg [LGFIFO-1 : 0]    aw_fifo;
reg [LGFIFO-1 : 0]    w_fifo;
reg [LGFIFO-1 : 0]    b_fifo;
reg [LGFIFO-1 : 0]    ar_fifo;
reg [LGFIFO-1 : 0]    r_fifo;

always @(posedge S_AXI_ACLK) begin
    // Write channel
    if (s_axi_reset) begin
        awid_reg <= 0;
        awaddr_reg <= 0;
        awlen_reg <= 0;
        awsize_reg <= 0;
        awburst_reg <= 0;
        awlock_reg <= 0;
        awcache_reg <= 0;
        awprot_reg <= 0;
        awqos_reg <= 0;
        awvalid_reg <= 0;
        wdata_reg <= 0;
        wstrb_reg <= 0;
        wlast_reg <= 0;
        wvalid_reg <= 0;
        bready_reg <= 0;
        bid_reg <= 0;
        bresp_reg <= 0;
        bvalid_reg <= 0;
    end else if (S_AXI_AWVALID && S_AXI_WVALID && S_AXI_WLAST) begin
        awid_reg <= S_AXI_AWID;
        awaddr_reg <= S_AXI_AWADDR;
        awlen_reg <= S_AXI_AWLEN;
        awsize_reg <= S_AXI_AWSIZE;
        awburst_reg <= S_AXI_AWBURST;
        awlock_reg <= S_AXI_AWLOCK;
        awcache_reg <= S_AXI_AWCACHE;
        awprot_reg <= S_AXI_AWPROT;
        awqos_reg <= S_AXI_AWQOS;
        awvalid_reg <= 1'b1;
        wdata_reg <= S_AXI_WDATA;
        wstrb_reg <= S_AXI_WSTRB;
        wlast_reg <= S_AXI_WLAST;
        wvalid_reg <= 1'b1;
        bready_reg <= 1'b1;
    end else if (S_AXI_BREADY && S_AXI_BVALID) begin
        bid_reg <= S_AXI_BID;
        bresp_reg <= S_AXI_BRESP;
        bvalid_reg <= 1'b1;
    end

    // Read channel
    if (s_axi_reset) begin
        arid_reg <= 0;
        araddr_reg <= 0;
        arlen_reg <= 0;
        arsize_reg <= 0;
        arburst_reg <= 0;
        arlock_reg <= 0;
        arcache_reg <= 0;
        arprot_reg <= 0;
        arqos_reg <= 0;
        arvalid_reg <= 0;
        rid_reg <= 0;
        rdata_reg <= 0;
        rresp_reg <= 0;
        rlast_reg <= 0;
        rvalid_reg <= 0;
        rready_reg <= 0;
    end else if (S_AXI_ARVALID) begin
        arid_reg <= S_AXI_ARID;
        araddr_reg <= S_AXI_ARADDR;
        arlen_reg <= S_AXI_ARLEN;
        arsize_reg <= S_AXI_ARSIZE;
        arburst_reg <= S_AXI_ARBURST;
        arlock_reg <= S_AXI_ARLOCK;
        arcache_reg <= S_AXI_ARCACHE;
        arprot_reg <= S_AXI_ARPROT;
        arqos_reg <= S_AXI_ARQOS;
        arvalid_reg <= 1'b1;
    end else if (S_AXI_RREADY && S_AXI_RVALID) begin
        rid_reg <= S_AXI_RID;
        rdata_reg <= S_AXI_RDATA;
        rresp_reg <= S_AXI_RRESP;
        rlast_reg <= S_AXI_RLAST;
        rvalid_reg <= 1'b1;
    end

    // Clock domain crossing
    aw_cross <= {aw_cross[XCLOCK_FFS-2 : 0], awvalid_reg};
    w_cross <= {w_cross[XCLOCK_FFS-2 : 0], wvalid_reg};
    b_cross <= {b_cross[XCLOCK_FFS-2 : 0], bvalid_reg};
    ar_cross <= {ar_cross[XCLOCK_FFS-2 : 0], arvalid_reg};
    r_cross <= {r_cross[XCLOCK_FFS-2 : 0], rvalid_reg};

    // FIFOs
    aw_fifo <= {aw_fifo[LGFIFO-2 : 0], aw_cross[XCLOCK_FFS-1]};
    w_fifo <= {w_fifo[LGFIFO-2 : 0], w_cross[XCLOCK_FFS-1]};
    b_fifo <= {b_fifo[LGFIFO-2 : 0], b_cross[XCLOCK_FFS-1]};
    ar_fifo <= {ar_fifo[LGFIFO-2 : 0], ar_cross[XCLOCK_FFS-1]};
    r_fifo <= {r_fifo[LGFIFO-2 : 0], r_cross[XCLOCK_FFS-1]};
end

always @(posedge M_AXI_ACLK) begin
    // Write channel
    if (m_axi_reset) begin
        M_AXI_AWID <= 0;
        M_AXI_AWADDR <= 0;
        M_AXI_AWLEN <= 0;
        M_AXI_AWSIZE <= 0;
        M_AXI_AWBURST <= 0;
        M_AXI_AWLOCK <= 0;
        M_AXI_AWCACHE <= 0;
        M_AXI_AWPROT <= 0;
        M_AXI_AWQOS <= 0;
        M_AXI_AWVALID <= 0;
        M_AXI_WDATA <= 0;
        M_AXI_WSTRB <= 0;
        M_AXI_WLAST <= 0;
        M_AXI_WVALID <= 0;
        M_AXI_BREADY <= 0;
    end else if (aw_fifo[LGFIFO-1]) begin
        M_AXI_AWID <= awid_reg;
        M_AXI_AWADDR <= awaddr_reg;
        M_AXI_AWLEN <= awlen_reg;
        M_AXI_AWSIZE <= awsize_reg;
        M_AXI_AWBURST <= awburst_reg;
        M_AXI_AWLOCK <= awlock_reg;
        M_AXI_AWCACHE <= awcache_reg;
        M_AXI_AWPROT <= awprot_reg;
        M_AXI_AWQOS <= awqos_reg;
        M_AXI_AWVALID <= 1'b1;
        M_AXI_WDATA <= wdata_reg;
        M_AXI_WSTRB <= wstrb_reg;
        M_AXI_WLAST <= wlast_reg;
        M_AXI_WVALID <= 1'b1;
        M_AXI_BREADY <= 1'b1;
    end else if (M_AXI_BVALID && M_AXI_BREADY) begin
        M_AXI_BREADY <= 1'b1;
    end

    // Read channel
    if (m_axi_reset) begin
        M_AXI_ARID <= 0;
        M_AXI_ARADDR <= 0;
        M_AXI_ARLEN <= 0;
        M_AXI_ARSIZE <= 0;
        M_AXI_ARBURST <= 0;
        M_AXI_ARLOCK <= 0;
        M_AXI_ARCACHE <= 0;
        M_AXI_ARPROT <= 0;
        M_AXI_ARQOS <= 0;
        M_AXI_ARVALID <= 0;
        M_AXI_RREADY <= 0;
    end else if (ar_fifo[LGFIFO-1]) begin
        M_AXI_ARID <= arid_reg;
        M_AXI_ARADDR <= araddr_reg;
        M_AXI_ARLEN <= arlen_reg;
        M_AXI_ARSIZE <= arsize_reg;
        M_AXI_ARBURST <= arburst_reg;
        M_AXI_ARLOCK <= arlock_reg;
        M_AXI_ARCACHE <= arcache_reg;
        M_AXI_ARPROT <= arprot_reg;
        M_AXI_ARQOS <= arqos_reg;
        M_AXI_ARVALID <= 1'b1;
    end else if (M_AXI_RVALID && M_AXI_RREADY) begin
        M_AXI_RREADY <= 1'b1;
    end
end

// Output assignments
assign S_AXI_AWREADY = awready_m_reg;
assign S_AXI_WREADY = wready_m_reg;
assign S_AXI_BID = bid_reg;
assign S_AXI_BRESP = bresp_reg;
assign S_AXI_BVALID = bvalid_reg;
assign S_AXI_ARREADY = arready_m_reg;
assign S_AXI_RID = rid_reg;
assign S_AXI_RDATA = rdata_reg;
assign S_AXI_RRESP = rresp_reg;
assign S_AXI_RLAST = rlast_reg;
assign S_AXI_RVALID = rvalid_reg;

assign M_AXI_BREADY = bready_m_reg;
assign M_AXI_RREADY = rready_m_reg;

endmodule
