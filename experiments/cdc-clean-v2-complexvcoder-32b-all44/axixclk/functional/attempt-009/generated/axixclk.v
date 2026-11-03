module axixclk #(
        parameter integer C_S_AXI_ID_WIDTH    = 2,
        parameter integer C_S_AXI_DATA_WIDTH  = 32,
        parameter integer C_S_AXI_ADDR_WIDTH  = 6,
        parameter [0:0]   OPT_WRITE_ONLY      = 1'b0,
        parameter [0:0]   OPT_READ_ONLY       = 1'b0,
        parameter         XCLOCK_FFS          = 2,
        parameter         LGFIFO              = 5
    ) (
        input   wire                                S_AXI_ACLK,
        input   wire                                S_AXI_ARESETN,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]       S_AXI_AWID,
        input   wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
        input   wire [7 : 0]                        S_AXI_AWLEN,
        input   wire [2 : 0]                        S_AXI_AWSIZE,
        input   wire [1 : 0]                        S_AXI_AWBURST,
        input   wire                                S_AXI_AWLOCK,
        input   wire [3 : 0]                        S_AXI_AWCACHE,
        input   wire [2 : 0]                        S_AXI_AWPROT,
        input   wire [3 : 0]                        S_AXI_AWQOS,
        input   wire                                S_AXI_AWVALID,
        output  wire                                S_AXI_AWREADY,
        input   wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
        input   wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
        input   wire                                S_AXI_WLAST,
        input   wire                                S_AXI_WVALID,
        output  wire                                S_AXI_WREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]       S_AXI_BID,
        output  wire [1 : 0]                        S_AXI_BRESP,
        output  wire                                S_AXI_BVALID,
        input   wire                                S_AXI_BREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]       S_AXI_ARID,
        input   wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
        input   wire [7 : 0]                        S_AXI_ARLEN,
        input   wire [2 : 0]                        S_AXI_ARSIZE,
        input   wire [1 : 0]                        S_AXI_ARBURST,
        input   wire                                S_AXI_ARLOCK,
        input   wire [3 : 0]                        S_AXI_ARCACHE,
        input   wire [2 : 0]                        S_AXI_ARPROT,
        input   wire [3 : 0]                        S_AXI_ARQOS,
        input   wire                                S_AXI_ARVALID,
        output  wire                                S_AXI_ARREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]       S_AXI_RID,
        output  wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
        output  wire [1 : 0]                        S_AXI_RRESP,
        output  wire                                S_AXI_RLAST,
        output  wire                                S_AXI_RVALID,
        input   wire                                S_AXI_RREADY,
        input   wire                                M_AXI_ACLK,
        output  wire                                M_AXI_ARESETN,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]       M_AXI_AWID,
        output  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     M_AXI_AWADDR,
        output  wire [7 : 0]                        M_AXI_AWLEN,
        output  wire [2 : 0]                        M_AXI_AWSIZE,
        output  wire [1 : 0]                        M_AXI_AWBURST,
        output  wire                                M_AXI_AWLOCK,
        output  wire [3 : 0]                        M_AXI_AWCACHE,
        output  wire [2 : 0]                        M_AXI_AWPROT,
        output  wire [3 : 0]                        M_AXI_AWQOS,
        output  wire                                M_AXI_AWVALID,
        input   wire                                M_AXI_AWREADY,
        output  wire [C_S_AXI_DATA_WIDTH-1 : 0]     M_AXI_WDATA,
        output  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
        output  wire                                M_AXI_WLAST,
        output  wire                                M_AXI_WVALID,
        input   wire                                M_AXI_WREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]       M_AXI_BID,
        input   wire [1 : 0]                        M_AXI_BRESP,
        input   wire                                M_AXI_BVALID,
        output  wire                                M_AXI_BREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]       M_AXI_ARID,
        output  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     M_AXI_ARADDR,
        output  wire [7 : 0]                        M_AXI_ARLEN,
        output  wire [2 : 0]                        M_AXI_ARSIZE,
        output  wire [1 : 0]                        M_AXI_ARBURST,
        output  wire                                M_AXI_ARLOCK,
        output  wire [3 : 0]                        M_AXI_ARCACHE,
        output  wire [2 : 0]                        M_AXI_ARPROT,
        output  wire [3 : 0]                        M_AXI_ARQOS,
        output  wire                                M_AXI_ARVALID,
        input   wire                                M_AXI_ARREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]       M_AXI_RID,
        input   wire [C_S_AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA,
        input   wire [1 : 0]                        M_AXI_RRESP,
        input   wire                                M_AXI_RLAST,
        input   wire                                M_AXI_RVALID,
        output  wire                                M_AXI_RREADY
    );

    // FIFOs for Write Address Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0]    awid_fifo [0 : (1<<LGFIFO)-1];
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  awaddr_fifo [0 : (1<<LGFIFO)-1];
    reg [7 : 0]                     awlen_fifo [0 : (1<<LGFIFO)-1];
    reg [2 : 0]                     awsize_fifo [0 : (1<<LGFIFO)-1];
    reg [1 : 0]                     awburst_fifo [0 : (1<<LGFIFO)-1];
    reg                             awlock_fifo [0 : (1<<LGFIFO)-1];
    reg [3 : 0]                     awcache_fifo [0 : (1<<LGFIFO)-1];
    reg [2 : 0]                     awprot_fifo [0 : (1<<LGFIFO)-1];
    reg [3 : 0]                     awqos_fifo [0 : (1<<LGFIFO)-1];
    reg                             awvalid_fifo [0 : (1<<LGFIFO)-1];
    reg [$clog2(1<<LGFIFO)-1 : 0]   awfifo_wr_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   awfifo_rd_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   awfifo_count;

    // FIFOs for Write Data Channel
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  wdata_fifo [0 : (1<<LGFIFO)-1];
    reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_fifo [0 : (1<<LGFIFO)-1];
    reg                             wlast_fifo [0 : (1<<LGFIFO)-1];
    reg                             wvalid_fifo [0 : (1<<LGFIFO)-1];
    reg [$clog2(1<<LGFIFO)-1 : 0]   wfifo_wr_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   wfifo_rd_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   wfifo_count;

    // FIFOs for Write Response Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0]    bid_fifo [0 : (1<<LGFIFO)-1];
    reg [1 : 0]                     bresp_fifo [0 : (1<<LGFIFO)-1];
    reg                             bvalid_fifo [0 : (1<<LGFIFO)-1];
    reg [$clog2(1<<LGFIFO)-1 : 0]   bfifo_wr_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   bfifo_rd_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   bfifo_count;

    // FIFOs for Read Address Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0]    arid_fifo [0 : (1<<LGFIFO)-1];
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  araddr_fifo [0 : (1<<LGFIFO)-1];
    reg [7 : 0]                     arlen_fifo [0 : (1<<LGFIFO)-1];
    reg [2 : 0]                     arsize_fifo [0 : (1<<LGFIFO)-1];
    reg [1 : 0]                     arburst_fifo [0 : (1<<LGFIFO)-1];
    reg                             arlock_fifo [0 : (1<<LGFIFO)-1];
    reg [3 : 0]                     arcache_fifo [0 : (1<<LGFIFO)-1];
    reg [2 : 0]                     arprot_fifo [0 : (1<<LGFIFO)-1];
    reg [3 : 0]                     arqos_fifo [0 : (1<<LGFIFO)-1];
    reg                             arvalid_fifo [0 : (1<<LGFIFO)-1];
    reg [$clog2(1<<LGFIFO)-1 : 0]   arfifo_wr_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   arfifo_rd_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   arfifo_count;

    // FIFOs for Read Data Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0]    rid_fifo [0 : (1<<LGFIFO)-1];
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  rdata_fifo [0 : (1<<LGFIFO)-1];
    reg [1 : 0]                     rresp_fifo [0 : (1<<LGFIFO)-1];
    reg                             rlast_fifo [0 : (1<<LGFIFO)-1];
    reg                             rvalid_fifo [0 : (1<<LGFIFO)-1];
    reg [$clog2(1<<LGFIFO)-1 : 0]   rfifo_wr_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   rfifo_rd_ptr;
    reg [$clog2(1<<LGFIFO)-1 : 0]   rfifo_count;

    // Cross-clock domain synchronization
    reg [XCLOCK_FFS-1 : 0] s_axi_reset_sync;
    reg [XCLOCK_FFS-1 : 0] m_axi_reset_sync;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_axi_reset_sync <= {XCLOCK_FFS{1'b1}};
        end else begin
            s_axi_reset_sync <= {s_axi_reset_sync[XCLOCK_FFS-2:0], 1'b0};
        end
    end

    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            m_axi_reset_sync <= {XCLOCK_FFS{1'b1}};
        end else begin
            m_axi_reset_sync <= {m_axi_reset_sync[XCLOCK_FFS-2:0], 1'b0};
        end
    end

    assign M_AXI_ARESETN = !m_axi_reset_sync[XCLOCK_FFS-1];

    // Write Address Channel FIFO
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awfifo_wr_ptr <= 0;
            awfifo_rd_ptr <= 0;
            awfifo_count <= 0;
        end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
            awid_fifo[awfifo_wr_ptr] <= S_AXI_AWID;
            awaddr_fifo[awfifo_wr_ptr] <= S_AXI_AWADDR;
            awlen_fifo[awfifo_wr_ptr] <= S_AXI_AWLEN;
            awsize_fifo[awfifo_wr_ptr] <= S_AXI_AWSIZE;
            awburst_fifo[awfifo_wr_ptr] <= S_AXI_AWBURST;
            awlock_fifo[awfifo_wr_ptr] <= S_AXI_AWLOCK;
            awcache_fifo[awfifo_wr_ptr] <= S_AXI_AWCACHE;
            awprot_fifo[awfifo_wr_ptr] <= S_AXI_AWPROT;
            awqos_fifo[awfifo_wr_ptr] <= S_AXI_AWQOS;
            awvalid_fifo[awfifo_wr_ptr] <= 1'b1;
            awfifo_wr_ptr <= awfifo_wr_ptr + 1;
            awfifo_count <= awfifo_count + 1;
        end else if (M_AXI_AWREADY && awfifo_count > 0) begin
            awvalid_fifo[awfifo_rd_ptr] <= 1'b0;
            awfifo_rd_ptr <= awfifo_rd_ptr + 1;
            awfifo_count <= awfifo_count - 1;
        end
    end

    assign S_AXI_AWREADY = (awfifo_count < (1<<LGFIFO));
    assign M_AXI_AWID = awid_fifo[awfifo_rd_ptr];
    assign M_AXI_AWADDR = awaddr_fifo[awfifo_rd_ptr];
    assign M_AXI_AWLEN = awlen_fifo[awfifo_rd_ptr];
    assign M_AXI_AWSIZE = awsize_fifo[awfifo_rd_ptr];
    assign M_AXI_AWBURST = awburst_fifo[awfifo_rd_ptr];
    assign M_AXI_AWLOCK = awlock_fifo[awfifo_rd_ptr];
    assign M_AXI_AWCACHE = awcache_fifo[awfifo_rd_ptr];
    assign M_AXI_AWPROT = awprot_fifo[awfifo_rd_ptr];
    assign M_AXI_AWQOS = awqos_fifo[awfifo_rd_ptr];
    assign M_AXI_AWVALID = awvalid_fifo[awfifo_rd_ptr];

    // Write Data Channel FIFO
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wfifo_wr_ptr <= 0;
            wfifo_rd_ptr <= 0;
            wfifo_count <= 0;
        end else if (S_AXI_WVALID && S_AXI_WREADY) begin
            wdata_fifo[wfifo_wr_ptr] <= S_AXI_WDATA;
            wstrb_fifo[wfifo_wr_ptr] <= S_AXI_WSTRB;
            wlast_fifo[wfifo_wr_ptr] <= S_AXI_WLAST;
            wvalid_fifo[wfifo_wr_ptr] <= 1'b1;
            wfifo_wr_ptr <= wfifo_wr_ptr + 1;
            wfifo_count <= wfifo_count + 1;
        end else if (M_AXI_WREADY && wfifo_count > 0) begin
            wvalid_fifo[wfifo_rd_ptr] <= 1'b0;
            wfifo_rd_ptr <= wfifo_rd_ptr + 1;
            wfifo_count <= wfifo_count - 1;
        end
    end

    assign S_AXI_WREADY = (wfifo_count < (1<<LGFIFO));
    assign M_AXI_WDATA = wdata_fifo[wfifo_rd_ptr];
    assign M_AXI_WSTRB = wstrb_fifo[wfifo_rd_ptr];
    assign M_AXI_WLAST = wlast_fifo[wfifo_rd_ptr];
    assign M_AXI_WVALID = wvalid_fifo[wfifo_rd_ptr];

    // Write Response Channel FIFO
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            bfifo_wr_ptr <= 0;
            bfifo_rd_ptr <= 0;
            bfifo_count <= 0;
        end else if (M_AXI_BVALID && M_AXI_BREADY) begin
            bid_fifo[bfifo_wr_ptr] <= M_AXI_BID;
            bresp_fifo[bfifo_wr_ptr] <= M_AXI_BRESP;
            bvalid_fifo[bfifo_wr_ptr] <= 1'b1;
            bfifo_wr_ptr <= bfifo_wr_ptr + 1;
            bfifo_count <= bfifo_count + 1;
        end else if (S_AXI_BREADY && bfifo_count > 0) begin
            bvalid_fifo[bfifo_rd_ptr] <= 1'b0;
            bfifo_rd_ptr <= bfifo_rd_ptr + 1;
            bfifo_count <= bfifo_count - 1;
        end
    end

    assign M_AXI_BREADY = (bfifo_count < (1<<LGFIFO));
    assign S_AXI_BID = bid_fifo[bfifo_rd_ptr];
    assign S_AXI_BRESP = bresp_fifo[bfifo_rd_ptr];
    assign S_AXI_BVALID = bvalid_fifo[bfifo_rd_ptr];

    // Read Address Channel FIFO
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            arfifo_wr_ptr <= 0;
            arfifo_rd_ptr <= 0;
            arfifo_count <= 0;
        end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            arid_fifo[arfifo_wr_ptr] <= S_AXI_ARID;
            araddr_fifo[arfifo_wr_ptr] <= S_AXI_ARADDR;
            arlen_fifo[arfifo_wr_ptr] <= S_AXI_ARLEN;
            arsize_fifo[arfifo_wr_ptr] <= S_AXI_ARSIZE;
            arburst_fifo[arfifo_wr_ptr] <= S_AXI_ARBURST;
            arlock_fifo[arfifo_wr_ptr] <= S_AXI_ARLOCK;
            arcache_fifo[arfifo_wr_ptr] <= S_AXI_ARCACHE;
            arprot_fifo[arfifo_wr_ptr] <= S_AXI_ARPROT;
            arqos_fifo[arfifo_wr_ptr] <= S_AXI_ARQOS;
            arvalid_fifo[arfifo_wr_ptr] <= 1'b1;
            arfifo_wr_ptr <= arfifo_wr_ptr + 1;
            arfifo_count <= arfifo_count + 1;
        end else if (M_AXI_ARREADY && arfifo_count > 0) begin
            arvalid_fifo[arfifo_rd_ptr] <= 1'b0;
            arfifo_rd_ptr <= arfifo_rd_ptr + 1;
            arfifo_count <= arfifo_count - 1;
        end
    end

    assign S_AXI_ARREADY = (arfifo_count < (1<<LGFIFO));
    assign M_AXI_ARID = arid_fifo[arfifo_rd_ptr];
    assign M_AXI_ARADDR = araddr_fifo[arfifo_rd_ptr];
    assign M_AXI_ARLEN = arlen_fifo[arfifo_rd_ptr];
    assign M_AXI_ARSIZE = arsize_fifo[arfifo_rd_ptr];
    assign M_AXI_ARBURST = arburst_fifo[arfifo_rd_ptr];
    assign M_AXI_ARLOCK = arlock_fifo[arfifo_rd_ptr];
    assign M_AXI_ARCACHE = arcache_fifo[arfifo_rd_ptr];
    assign M_AXI_ARPROT = arprot_fifo[arfifo_rd_ptr];
    assign M_AXI_ARQOS = arqos_fifo[arfifo_rd_ptr];
    assign M_AXI_ARVALID = arvalid_fifo[arfifo_rd_ptr];

    // Read Data Channel FIFO
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            rfifo_wr_ptr <= 0;
            rfifo_rd_ptr <= 0;
            rfifo_count <= 0;
        end else if (M_AXI_RVALID && M_AXI_RREADY) begin
            rid_fifo[rfifo_wr_ptr] <= M_AXI_RID;
            rdata_fifo[rfifo_wr_ptr] <= M_AXI_RDATA;
            rresp_fifo[rfifo_wr_ptr] <= M_AXI_RRESP;
            rlast_fifo[rfifo_wr_ptr] <= M_AXI_RLAST;
            rvalid_fifo[rfifo_wr_ptr] <= 1'b1;
            rfifo_wr_ptr <= rfifo_wr_ptr + 1;
            rfifo_count <= rfifo_count + 1;
        end else if (S_AXI_RREADY && rfifo_count > 0) begin
            rvalid_fifo[rfifo_rd_ptr] <= 1'b0;
            rfifo_rd_ptr <= rfifo_rd_ptr + 1;
            rfifo_count <= rfifo_count - 1;
        end
    end

    assign M_AXI_RREADY = (rfifo_count < (1<<LGFIFO));
    assign S_AXI_RID = rid_fifo[rfifo_rd_ptr];
    assign S_AXI_RDATA = rdata_fifo[rfifo_rd_ptr];
    assign S_AXI_RRESP = rresp_fifo[rfifo_rd_ptr];
    assign S_AXI_RLAST = rlast_fifo[rfifo_rd_ptr];
    assign S_AXI_RVALID = rvalid_fifo[rfifo_rd_ptr];

endmodule
