module axixclk #(
        parameter integer C_S_AXI_ID_WIDTH    = 2,
        parameter integer C_S_AXI_DATA_WIDTH  = 32,
        parameter integer C_S_AXI_ADDR_WIDTH  = 6,
        parameter [0:0]   OPT_WRITE_ONLY = 1'b0,
        parameter [0:0]   OPT_READ_ONLY = 1'b0,
        parameter         XCLOCK_FFS = 2,
        parameter         LGFIFO = 5
    ) (
        input   wire                            S_AXI_ACLK,
        input   wire                            S_AXI_ARESETN,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]   S_AXI_AWID,
        input   wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
        input   wire [7 : 0]                    S_AXI_AWLEN,
        input   wire [2 : 0]                    S_AXI_AWSIZE,
        input   wire [1 : 0]                    S_AXI_AWBURST,
        input   wire                            S_AXI_AWLOCK,
        input   wire [3 : 0]                    S_AXI_AWCACHE,
        input   wire [2 : 0]                    S_AXI_AWPROT,
        input   wire [3 : 0]                    S_AXI_AWQOS,
        input   wire                            S_AXI_AWVALID,
        output  wire                            S_AXI_AWREADY,
        input   wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
        input   wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
        input   wire                            S_AXI_WLAST,
        input   wire                            S_AXI_WVALID,
        output  wire                            S_AXI_WREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]   S_AXI_BID,
        output  wire [1 : 0]                    S_AXI_BRESP,
        output  wire                            S_AXI_BVALID,
        input   wire                            S_AXI_BREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]   S_AXI_ARID,
        input   wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
        input   wire [7 : 0]                    S_AXI_ARLEN,
        input   wire [2 : 0]                    S_AXI_ARSIZE,
        input   wire [1 : 0]                    S_AXI_ARBURST,
        input   wire                            S_AXI_ARLOCK,
        input   wire [3 : 0]                    S_AXI_ARCACHE,
        input   wire [2 : 0]                    S_AXI_ARPROT,
        input   wire [3 : 0]                    S_AXI_ARQOS,
        input   wire                            S_AXI_ARVALID,
        output  wire                            S_AXI_ARREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]   S_AXI_RID,
        output  wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
        output  wire [1 : 0]                    S_AXI_RRESP,
        output  wire                            S_AXI_RLAST,
        output  wire                            S_AXI_RVALID,
        input   wire                            S_AXI_RREADY,
        input   wire                            M_AXI_ACLK,
        output  wire                            M_AXI_ARESETN,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]   M_AXI_AWID,
        output  wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
        output  wire [7 : 0]                    M_AXI_AWLEN,
        output  wire [2 : 0]                    M_AXI_AWSIZE,
        output  wire [1 : 0]                    M_AXI_AWBURST,
        output  wire                            M_AXI_AWLOCK,
        output  wire [3 : 0]                    M_AXI_AWCACHE,
        output  wire [2 : 0]                    M_AXI_AWPROT,
        output  wire [3 : 0]                    M_AXI_AWQOS,
        output  wire                            M_AXI_AWVALID,
        input   wire                            M_AXI_AWREADY,
        output  wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
        output  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
        output  wire                            M_AXI_WLAST,
        output  wire                            M_AXI_WVALID,
        input   wire                            M_AXI_WREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]   M_AXI_BID,
        input   wire [1 : 0]                    M_AXI_BRESP,
        input   wire                            M_AXI_BVALID,
        output  wire                            M_AXI_BREADY,
        output  wire [C_S_AXI_ID_WIDTH-1 : 0]   M_AXI_ARID,
        output  wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
        output  wire [7 : 0]                    M_AXI_ARLEN,
        output  wire [2 : 0]                    M_AXI_ARSIZE,
        output  wire [1 : 0]                    M_AXI_ARBURST,
        output  wire                            M_AXI_ARLOCK,
        output  wire [3 : 0]                    M_AXI_ARCACHE,
        output  wire [2 : 0]                    M_AXI_ARPROT,
        output  wire [3 : 0]                    M_AXI_ARQOS,
        output  wire                            M_AXI_ARVALID,
        input   wire                            M_AXI_ARREADY,
        input   wire [C_S_AXI_ID_WIDTH-1 : 0]   M_AXI_RID,
        input   wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
        input   wire [1 : 0]                    M_AXI_RRESP,
        input   wire                            M_AXI_RLAST,
        input   wire                            M_AXI_RVALID,
        output  wire                            M_AXI_RREADY
    );

    // FIFOs for AW channel
    reg [C_S_AXI_ID_WIDTH-1:0]    awid_fifo [0:(1<<LGFIFO)-1];
    reg [C_S_AXI_ADDR_WIDTH-1:0]  awaddr_fifo [0:(1<<LGFIFO)-1];
    reg [7:0]                     awlen_fifo [0:(1<<LGFIFO)-1];
    reg [2:0]                     awsize_fifo [0:(1<<LGFIFO)-1];
    reg [1:0]                     awburst_fifo [0:(1<<LGFIFO)-1];
    reg                           awlock_fifo [0:(1<<LGFIFO)-1];
    reg [3:0]                     awcache_fifo [0:(1<<LGFIFO)-1];
    reg [2:0]                     awprot_fifo [0:(1<<LGFIFO)-1];
    reg [3:0]                     awqos_fifo [0:(1<<LGFIFO)-1];
    reg                           awvalid_fifo [0:(1<<LGFIFO)-1];
    reg [$clog2((1<<LGFIFO))-1:0] awfifo_wr_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] awfifo_rd_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] awfifo_count;

    // FIFOs for W channel
    reg [C_S_AXI_DATA_WIDTH-1:0]  wdata_fifo [0:(1<<LGFIFO)-1];
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_fifo [0:(1<<LGFIFO)-1];
    reg                           wlast_fifo [0:(1<<LGFIFO)-1];
    reg                           wvalid_fifo [0:(1<<LGFIFO)-1];
    reg [$clog2((1<<LGFIFO))-1:0] wfifo_wr_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] wfifo_rd_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] wfifo_count;

    // FIFOs for B channel
    reg [C_S_AXI_ID_WIDTH-1:0]    bid_fifo [0:(1<<LGFIFO)-1];
    reg [1:0]                     bresp_fifo [0:(1<<LGFIFO)-1];
    reg                           bvalid_fifo [0:(1<<LGFIFO)-1];
    reg [$clog2((1<<LGFIFO))-1:0] bfifo_wr_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] bfifo_rd_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] bfifo_count;

    // FIFOs for AR channel
    reg [C_S_AXI_ID_WIDTH-1:0]    arid_fifo [0:(1<<LGFIFO)-1];
    reg [C_S_AXI_ADDR_WIDTH-1:0]  araddr_fifo [0:(1<<LGFIFO)-1];
    reg [7:0]                     arlen_fifo [0:(1<<LGFIFO)-1];
    reg [2:0]                     arsize_fifo [0:(1<<LGFIFO)-1];
    reg [1:0]                     arburst_fifo [0:(1<<LGFIFO)-1];
    reg                           arlock_fifo [0:(1<<LGFIFO)-1];
    reg [3:0]                     arcache_fifo [0:(1<<LGFIFO)-1];
    reg [2:0]                     arprot_fifo [0:(1<<LGFIFO)-1];
    reg [3:0]                     arqos_fifo [0:(1<<LGFIFO)-1];
    reg                           arvalid_fifo [0:(1<<LGFIFO)-1];
    reg [$clog2((1<<LGFIFO))-1:0] arfifo_wr_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] arfifo_rd_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] arfifo_count;

    // FIFOs for R channel
    reg [C_S_AXI_ID_WIDTH-1:0]    rid_fifo [0:(1<<LGFIFO)-1];
    reg [C_S_AXI_DATA_WIDTH-1:0]  rdata_fifo [0:(1<<LGFIFO)-1];
    reg [1:0]                     rresp_fifo [0:(1<<LGFIFO)-1];
    reg                           rlast_fifo [0:(1<<LGFIFO)-1];
    reg                           rvalid_fifo [0:(1<<LGFIFO)-1];
    reg [$clog2((1<<LGFIFO))-1:0] rfifo_wr_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] rfifo_rd_ptr;
    reg [$clog2((1<<LGFIFO))-1:0] rfifo_count;

    // Clock crossing registers for AW channel
    reg [XCLOCK_FFS-1:0]          awid_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awaddr_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awlen_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awsize_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awburst_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awlock_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awcache_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awprot_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awqos_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          awvalid_cross [0:(1<<LGFIFO)-1];

    // Clock crossing registers for W channel
    reg [XCLOCK_FFS-1:0]          wdata_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          wstrb_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          wlast_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          wvalid_cross [0:(1<<LGFIFO)-1];

    // Clock crossing registers for B channel
    reg [XCLOCK_FFS-1:0]          bid_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          bresp_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          bvalid_cross [0:(1<<LGFIFO)-1];

    // Clock crossing registers for AR channel
    reg [XCLOCK_FFS-1:0]          arid_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          araddr_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arlen_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arsize_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arburst_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arlock_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arcache_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arprot_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arqos_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          arvalid_cross [0:(1<<LGFIFO)-1];

    // Clock crossing registers for R channel
    reg [XCLOCK_FFS-1:0]          rid_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          rdata_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          rresp_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          rlast_cross [0:(1<<LGFIFO)-1];
    reg [XCLOCK_FFS-1:0]          rvalid_cross [0:(1<<LGFIFO)-1];

    // AW channel FIFO write logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awfifo_wr_ptr <= 0;
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
            awvalid_fifo[awfifo_wr_ptr] <= 1;
            awfifo_wr_ptr <= awfifo_wr_ptr + 1;
            if (awfifo_count != (1<<LGFIFO))
                awfifo_count <= awfifo_count + 1;
        end
    end

    // AW channel FIFO read logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awfifo_rd_ptr <= 0;
        end else if (M_AXI_AWREADY && awvalid_cross[awfifo_rd_ptr][XCLOCK_FFS-1]) begin
            awvalid_fifo[awfifo_rd_ptr] <= 0;
            awfifo_rd_ptr <= awfifo_rd_ptr + 1;
            if (awfifo_count != 0)
                awfifo_count <= awfifo_count - 1;
        end
    end

    // AW channel clock crossing
    genvar i;
    generate
        for (i = 0; i < (1<<LGFIFO); i = i + 1) begin : gen_aw_cross
            always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
                if (!S_AXI_ARESETN) begin
                    awid_cross[i] <= 0;
                    awaddr_cross[i] <= 0;
                    awlen_cross[i] <= 0;
                    awsize_cross[i] <= 0;
                    awburst_cross[i] <= 0;
                    awlock_cross[i] <= 0;
                    awcache_cross[i] <= 0;
                    awprot_cross[i] <= 0;
                    awqos_cross[i] <= 0;
                    awvalid_cross[i] <= 0;
                end else begin
                    awid_cross[i] <= {awid_cross[i][XCLOCK_FFS-2:0], awid_fifo[i]};
                    awaddr_cross[i] <= {awaddr_cross[i][XCLOCK_FFS-2:0], awaddr_fifo[i]};
                    awlen_cross[i] <= {awlen_cross[i][XCLOCK_FFS-2:0], awlen_fifo[i]};
                    awsize_cross[i] <= {awsize_cross[i][XCLOCK_FFS-2:0], awsize_fifo[i]};
                    awburst_cross[i] <= {awburst_cross[i][XCLOCK_FFS-2:0], awburst_fifo[i]};
                    awlock_cross[i] <= {awlock_cross[i][XCLOCK_FFS-2:0], awlock_fifo[i]};
                    awcache_cross[i] <= {awcache_cross[i][XCLOCK_FFS-2:0], awcache_fifo[i]};
                    awprot_cross[i] <= {awprot_cross[i][XCLOCK_FFS-2:0], awprot_fifo[i]};
                    awqos_cross[i] <= {awqos_cross[i][XCLOCK_FFS-2:0], awqos_fifo[i]};
                    awvalid_cross[i] <= {awvalid_cross[i][XCLOCK_FFS-2:0], awvalid_fifo[i]};
                end
            end
        end
    endgenerate

    // AW channel output
    assign M_AXI_AWID = awid_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWADDR = awaddr_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWLEN = awlen_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWSIZE = awsize_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWBURST = awburst_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWLOCK = awlock_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWCACHE = awcache_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWPROT = awprot_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWQOS = awqos_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_AWVALID = awvalid_cross[awfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_AWREADY = (awfifo_count != (1<<LGFIFO));

    // W channel FIFO write logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wfifo_wr_ptr <= 0;
            wfifo_count <= 0;
        end else if (S_AXI_WVALID && S_AXI_WREADY) begin
            wdata_fifo[wfifo_wr_ptr] <= S_AXI_WDATA;
            wstrb_fifo[wfifo_wr_ptr] <= S_AXI_WSTRB;
            wlast_fifo[wfifo_wr_ptr] <= S_AXI_WLAST;
            wvalid_fifo[wfifo_wr_ptr] <= 1;
            wfifo_wr_ptr <= wfifo_wr_ptr + 1;
            if (wfifo_count != (1<<LGFIFO))
                wfifo_count <= wfifo_count + 1;
        end
    end

    // W channel FIFO read logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wfifo_rd_ptr <= 0;
        end else if (M_AXI_WREADY && wvalid_cross[wfifo_rd_ptr][XCLOCK_FFS-1]) begin
            wvalid_fifo[wfifo_rd_ptr] <= 0;
            wfifo_rd_ptr <= wfifo_rd_ptr + 1;
            if (wfifo_count != 0)
                wfifo_count <= wfifo_count - 1;
        end
    end

    // W channel clock crossing
    generate
        for (i = 0; i < (1<<LGFIFO); i = i + 1) begin : gen_w_cross
            always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
                if (!S_AXI_ARESETN) begin
                    wdata_cross[i] <= 0;
                    wstrb_cross[i] <= 0;
                    wlast_cross[i] <= 0;
                    wvalid_cross[i] <= 0;
                end else begin
                    wdata_cross[i] <= {wdata_cross[i][XCLOCK_FFS-2:0], wdata_fifo[i]};
                    wstrb_cross[i] <= {wstrb_cross[i][XCLOCK_FFS-2:0], wstrb_fifo[i]};
                    wlast_cross[i] <= {wlast_cross[i][XCLOCK_FFS-2:0], wlast_fifo[i]};
                    wvalid_cross[i] <= {wvalid_cross[i][XCLOCK_FFS-2:0], wvalid_fifo[i]};
                end
            end
        end
    endgenerate

    // W channel output
    assign M_AXI_WDATA = wdata_cross[wfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_WSTRB = wstrb_cross[wfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_WLAST = wlast_cross[wfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_WVALID = wvalid_cross[wfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_WREADY = (wfifo_count != (1<<LGFIFO));

    // B channel FIFO write logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            bfifo_wr_ptr <= 0;
            bfifo_count <= 0;
        end else if (M_AXI_BVALID && M_AXI_BREADY) begin
            bid_fifo[bfifo_wr_ptr] <= M_AXI_BID;
            bresp_fifo[bfifo_wr_ptr] <= M_AXI_BRESP;
            bvalid_fifo[bfifo_wr_ptr] <= 1;
            bfifo_wr_ptr <= bfifo_wr_ptr + 1;
            if (bfifo_count != (1<<LGFIFO))
                bfifo_count <= bfifo_count + 1;
        end
    end

    // B channel FIFO read logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            bfifo_rd_ptr <= 0;
        end else if (S_AXI_BREADY && bvalid_cross[bfifo_rd_ptr][XCLOCK_FFS-1]) begin
            bvalid_fifo[bfifo_rd_ptr] <= 0;
            bfifo_rd_ptr <= bfifo_rd_ptr + 1;
            if (bfifo_count != 0)
                bfifo_count <= bfifo_count - 1;
        end
    end

    // B channel clock crossing
    generate
        for (i = 0; i < (1<<LGFIFO); i = i + 1) begin : gen_b_cross
            always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
                if (!S_AXI_ARESETN) begin
                    bid_cross[i] <= 0;
                    bresp_cross[i] <= 0;
                    bvalid_cross[i] <= 0;
                end else begin
                    bid_cross[i] <= {bid_cross[i][XCLOCK_FFS-2:0], bid_fifo[i]};
                    bresp_cross[i] <= {bresp_cross[i][XCLOCK_FFS-2:0], bresp_fifo[i]};
                    bvalid_cross[i] <= {bvalid_cross[i][XCLOCK_FFS-2:0], bvalid_fifo[i]};
                end
            end
        end
    endgenerate

    // B channel output
    assign S_AXI_BID = bid_cross[bfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_BRESP = bresp_cross[bfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_BVALID = bvalid_cross[bfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_BREADY = (bfifo_count != (1<<LGFIFO));

    // AR channel FIFO write logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            arfifo_wr_ptr <= 0;
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
            arvalid_fifo[arfifo_wr_ptr] <= 1;
            arfifo_wr_ptr <= arfifo_wr_ptr + 1;
            if (arfifo_count != (1<<LGFIFO))
                arfifo_count <= arfifo_count + 1;
        end
    end

    // AR channel FIFO read logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            arfifo_rd_ptr <= 0;
        end else if (M_AXI_ARREADY && arvalid_cross[arfifo_rd_ptr][XCLOCK_FFS-1]) begin
            arvalid_fifo[arfifo_rd_ptr] <= 0;
            arfifo_rd_ptr <= arfifo_rd_ptr + 1;
            if (arfifo_count != 0)
                arfifo_count <= arfifo_count - 1;
        end
    end

    // AR channel clock crossing
    generate
        for (i = 0; i < (1<<LGFIFO); i = i + 1) begin : gen_ar_cross
            always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
                if (!S_AXI_ARESETN) begin
                    arid_cross[i] <= 0;
                    araddr_cross[i] <= 0;
                    arlen_cross[i] <= 0;
                    arsize_cross[i] <= 0;
                    arburst_cross[i] <= 0;
                    arlock_cross[i] <= 0;
                    arcache_cross[i] <= 0;
                    arprot_cross[i] <= 0;
                    arqos_cross[i] <= 0;
                    arvalid_cross[i] <= 0;
                end else begin
                    arid_cross[i] <= {arid_cross[i][XCLOCK_FFS-2:0], arid_fifo[i]};
                    araddr_cross[i] <= {araddr_cross[i][XCLOCK_FFS-2:0], araddr_fifo[i]};
                    arlen_cross[i] <= {arlen_cross[i][XCLOCK_FFS-2:0], arlen_fifo[i]};
                    arsize_cross[i] <= {arsize_cross[i][XCLOCK_FFS-2:0], arsize_fifo[i]};
                    arburst_cross[i] <= {arburst_cross[i][XCLOCK_FFS-2:0], arburst_fifo[i]};
                    arlock_cross[i] <= {arlock_cross[i][XCLOCK_FFS-2:0], arlock_fifo[i]};
                    arcache_cross[i] <= {arcache_cross[i][XCLOCK_FFS-2:0], arcache_fifo[i]};
                    arprot_cross[i] <= {arprot_cross[i][XCLOCK_FFS-2:0], arprot_fifo[i]};
                    arqos_cross[i] <= {arqos_cross[i][XCLOCK_FFS-2:0], arqos_fifo[i]};
                    arvalid_cross[i] <= {arvalid_cross[i][XCLOCK_FFS-2:0], arvalid_fifo[i]};
                end
            end
        end
    endgenerate

    // AR channel output
    assign M_AXI_ARID = arid_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARADDR = araddr_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARLEN = arlen_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARSIZE = arsize_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARBURST = arburst_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARLOCK = arlock_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARCACHE = arcache_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARPROT = arprot_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARQOS = arqos_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_ARVALID = arvalid_cross[arfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_ARREADY = (arfifo_count != (1<<LGFIFO));

    // R channel FIFO write logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            rfifo_wr_ptr <= 0;
            rfifo_count <= 0;
        end else if (M_AXI_RVALID && M_AXI_RREADY) begin
            rid_fifo[rfifo_wr_ptr] <= M_AXI_RID;
            rdata_fifo[rfifo_wr_ptr] <= M_AXI_RDATA;
            rresp_fifo[rfifo_wr_ptr] <= M_AXI_RRESP;
            rlast_fifo[rfifo_wr_ptr] <= M_AXI_RLAST;
            rvalid_fifo[rfifo_wr_ptr] <= 1;
            rfifo_wr_ptr <= rfifo_wr_ptr + 1;
            if (rfifo_count != (1<<LGFIFO))
                rfifo_count <= rfifo_count + 1;
        end
    end

    // R channel FIFO read logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            rfifo_rd_ptr <= 0;
        end else if (S_AXI_RREADY && rvalid_cross[rfifo_rd_ptr][XCLOCK_FFS-1]) begin
            rvalid_fifo[rfifo_rd_ptr] <= 0;
            rfifo_rd_ptr <= rfifo_rd_ptr + 1;
            if (rfifo_count != 0)
                rfifo_count <= rfifo_count - 1;
        end
    end

    // R channel clock crossing
    generate
        for (i = 0; i < (1<<LGFIFO); i = i + 1) begin : gen_r_cross
            always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
                if (!S_AXI_ARESETN) begin
                    rid_cross[i] <= 0;
                    rdata_cross[i] <= 0;
                    rresp_cross[i] <= 0;
                    rlast_cross[i] <= 0;
                    rvalid_cross[i] <= 0;
                end else begin
                    rid_cross[i] <= {rid_cross[i][XCLOCK_FFS-2:0], rid_fifo[i]};
                    rdata_cross[i] <= {rdata_cross[i][XCLOCK_FFS-2:0], rdata_fifo[i]};
                    rresp_cross[i] <= {rresp_cross[i][XCLOCK_FFS-2:0], rresp_fifo[i]};
                    rlast_cross[i] <= {rlast_cross[i][XCLOCK_FFS-2:0], rlast_fifo[i]};
                    rvalid_cross[i] <= {rvalid_cross[i][XCLOCK_FFS-2:0], rvalid_fifo[i]};
                end
            end
        end
    endgenerate

    // R channel output
    assign S_AXI_RID = rid_cross[rfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_RDATA = rdata_cross[rfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_RRESP = rresp_cross[rfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_RLAST = rlast_cross[rfifo_rd_ptr][XCLOCK_FFS-1];
    assign S_AXI_RVALID = rvalid_cross[rfifo_rd_ptr][XCLOCK_FFS-1];
    assign M_AXI_RREADY = (rfifo_count != (1<<LGFIFO));

    // Master reset
    reg [XCLOCK_FFS-1:0] m_reset_cross;

    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            m_reset_cross <= 0;
        end else begin
            m_reset_cross <= {m_reset_cross[XCLOCK_FFS-2:0], 1'b1};
        end
    end

    assign M_AXI_ARESETN = m_reset_cross[XCLOCK_FFS-1];

endmodule
