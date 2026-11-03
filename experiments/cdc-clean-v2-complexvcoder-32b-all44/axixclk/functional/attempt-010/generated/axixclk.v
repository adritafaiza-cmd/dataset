module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH    = 2,
    parameter integer C_S_AXI_DATA_WIDTH  = 32,
    parameter integer C_S_AXI_ADDR_WIDTH  = 6,
    parameter [0:0] OPT_WRITE_ONLY      = 1'b0,
    parameter [0:0] OPT_READ_ONLY       = 1'b0,
    parameter       XCLOCK_FFS          = 2,
    parameter       LGFIFO              = 5
) (
    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]     S_AXI_AWID,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_AWADDR,
    input  wire [7 : 0]                      S_AXI_AWLEN,
    input  wire [2 : 0]                      S_AXI_AWSIZE,
    input  wire [1 : 0]                      S_AXI_AWBURST,
    input  wire                                S_AXI_AWLOCK,
    input  wire [3 : 0]                      S_AXI_AWCACHE,
    input  wire [2 : 0]                      S_AXI_AWPROT,
    input  wire [3 : 0]                      S_AXI_AWQOS,
    input  wire                                S_AXI_AWVALID,
    output wire                                S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire                                S_AXI_WLAST,
    input  wire                                S_AXI_WVALID,
    output wire                                S_AXI_WREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]     S_AXI_BID,
    output wire [1 : 0]                      S_AXI_BRESP,
    output wire                                S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]     S_AXI_ARID,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_ARADDR,
    input  wire [7 : 0]                      S_AXI_ARLEN,
    input  wire [2 : 0]                      S_AXI_ARSIZE,
    input  wire [1 : 0]                      S_AXI_ARBURST,
    input  wire                                S_AXI_ARLOCK,
    input  wire [3 : 0]                      S_AXI_ARCACHE,
    input  wire [2 : 0]                      S_AXI_ARPROT,
    input  wire [3 : 0]                      S_AXI_ARQOS,
    input  wire                                S_AXI_ARVALID,
    output wire                                S_AXI_ARREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]     S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_RDATA,
    output wire [1 : 0]                      S_AXI_RRESP,
    output wire                                S_AXI_RLAST,
    output wire                                S_AXI_RVALID,
    input  wire                                S_AXI_RREADY,
    input  wire                                M_AXI_ACLK,
    output wire                                M_AXI_ARESETN,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]     M_AXI_AWID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0]   M_AXI_AWADDR,
    output wire [7 : 0]                      M_AXI_AWLEN,
    output wire [2 : 0]                      M_AXI_AWSIZE,
    output wire [1 : 0]                      M_AXI_AWBURST,
    output wire                                M_AXI_AWLOCK,
    output wire [3 : 0]                      M_AXI_AWCACHE,
    output wire [2 : 0]                      M_AXI_AWPROT,
    output wire [3 : 0]                      M_AXI_AWQOS,
    output wire                                M_AXI_AWVALID,
    input  wire                                M_AXI_AWREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]   M_AXI_WDATA,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output wire                                M_AXI_WLAST,
    output wire                                M_AXI_WVALID,
    input  wire                                M_AXI_WREADY,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]     M_AXI_BID,
    input  wire [1 : 0]                      M_AXI_BRESP,
    input  wire                                M_AXI_BVALID,
    output wire                                M_AXI_BREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]     M_AXI_ARID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0]   M_AXI_ARADDR,
    output wire [7 : 0]                      M_AXI_ARLEN,
    output wire [2 : 0]                      M_AXI_ARSIZE,
    output wire [1 : 0]                      M_AXI_ARBURST,
    output wire                                M_AXI_ARLOCK,
    output wire [3 : 0]                      M_AXI_ARCACHE,
    output wire [2 : 0]                      M_AXI_ARPROT,
    output wire [3 : 0]                      M_AXI_ARQOS,
    output wire                                M_AXI_ARVALID,
    input  wire                                M_AXI_ARREADY,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]     M_AXI_RID,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]   M_AXI_RDATA,
    input  wire [1 : 0]                      M_AXI_RRESP,
    input  wire                                M_AXI_RLAST,
    input  wire                                M_AXI_RVALID,
    output wire                                M_AXI_RREADY
);

    // Internal signals
    reg [C_S_AXI_ID_WIDTH-1 : 0]     s_awid_reg, m_awid_reg;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]   s_awaddr_reg, m_awaddr_reg;
    reg [7 : 0]                      s_awlen_reg, m_awlen_reg;
    reg [2 : 0]                      s_awsize_reg, m_awsize_reg;
    reg [1 : 0]                      s_awburst_reg, m_awburst_reg;
    reg                                s_awlock_reg, m_awlock_reg;
    reg [3 : 0]                      s_awcache_reg, m_awcache_reg;
    reg [2 : 0]                      s_awprot_reg, m_awprot_reg;
    reg [3 : 0]                      s_awqos_reg, m_awqos_reg;
    reg                                s_awvalid_reg, m_awvalid_reg;
    reg                                s_awready_reg, m_awready_reg;

    reg [C_S_AXI_ID_WIDTH-1 : 0]     s_wid_reg, m_wid_reg;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]   s_wdata_reg, m_wdata_reg;
    reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_wstrb_reg, m_wstrb_reg;
    reg                                s_wlast_reg, m_wlast_reg;
    reg                                s_wvalid_reg, m_wvalid_reg;
    reg                                s_wready_reg, m_wready_reg;

    reg [C_S_AXI_ID_WIDTH-1 : 0]     s_bid_reg, m_bid_reg;
    reg [1 : 0]                      s_bresp_reg, m_bresp_reg;
    reg                                s_bvalid_reg, m_bvalid_reg;
    reg                                s_bready_reg, m_bready_reg;

    reg [C_S_AXI_ID_WIDTH-1 : 0]     s_arid_reg, m_arid_reg;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]   s_araddr_reg, m_araddr_reg;
    reg [7 : 0]                      s_arlen_reg, m_arlen_reg;
    reg [2 : 0]                      s_arsize_reg, m_arsize_reg;
    reg [1 : 0]                      s_arburst_reg, m_arburst_reg;
    reg                                s_arlock_reg, m_arlock_reg;
    reg [3 : 0]                      s_arcache_reg, m_arcache_reg;
    reg [2 : 0]                      s_arprot_reg, m_arprot_reg;
    reg [3 : 0]                      s_arqos_reg, m_arqos_reg;
    reg                                s_arvalid_reg, m_arvalid_reg;
    reg                                s_arready_reg, m_arready_reg;

    reg [C_S_AXI_ID_WIDTH-1 : 0]     s_rid_reg, m_rid_reg;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]   s_rdata_reg, m_rdata_reg;
    reg [1 : 0]                      s_rresp_reg, m_rresp_reg;
    reg                                s_rlast_reg, m_rlast_reg;
    reg                                s_rvalid_reg, m_rvalid_reg;
    reg                                s_rready_reg, m_rready_reg;

    // Cross-clock domain FIFOs
    wire [C_S_AXI_ID_WIDTH-1 : 0]     awid_fifo_out;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0]   awaddr_fifo_out;
    wire [7 : 0]                      awlen_fifo_out;
    wire [2 : 0]                      awsize_fifo_out;
    wire [1 : 0]                      awburst_fifo_out;
    wire                              awlock_fifo_out;
    wire [3 : 0]                      awcache_fifo_out;
    wire [2 : 0]                      awprot_fifo_out;
    wire [3 : 0]                      awqos_fifo_out;
    wire                              awvalid_fifo_out;
    wire                              awready_fifo_out;

    wire [C_S_AXI_DATA_WIDTH-1 : 0]   wdata_fifo_out;
    wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb_fifo_out;
    wire                              wlast_fifo_out;
    wire                              wvalid_fifo_out;
    wire                              wready_fifo_out;

    wire [C_S_AXI_ID_WIDTH-1 : 0]     bid_fifo_out;
    wire [1 : 0]                      bresp_fifo_out;
    wire                              bvalid_fifo_out;
    wire                              bready_fifo_out;

    wire [C_S_AXI_ID_WIDTH-1 : 0]     arid_fifo_out;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0]   araddr_fifo_out;
    wire [7 : 0]                      arlen_fifo_out;
    wire [2 : 0]                      arsize_fifo_out;
    wire [1 : 0]                      arburst_fifo_out;
    wire                              arlock_fifo_out;
    wire [3 : 0]                      arcache_fifo_out;
    wire [2 : 0]                      arprot_fifo_out;
    wire [3 : 0]                      arqos_fifo_out;
    wire                              arvalid_fifo_out;
    wire                              arready_fifo_out;

    wire [C_S_AXI_ID_WIDTH-1 : 0]     rid_fifo_out;
    wire [C_S_AXI_DATA_WIDTH-1 : 0]   rdata_fifo_out;
    wire [1 : 0]                      rresp_fifo_out;
    wire                              rlast_fifo_out;
    wire                              rvalid_fifo_out;
    wire                              rready_fifo_out;

    // FIFOs for AW channel
    fifo_sync #(
        .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
        .DEPTH(2**LGFIFO)
    ) aw_fifo (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(~S_AXI_ARESETN),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(~M_AXI_ARESETN),
        .din({s_awid_reg, s_awaddr_reg, s_awlen_reg, s_awsize_reg, s_awburst_reg, s_awlock_reg, s_awcache_reg, s_awprot_reg, s_awqos_reg}),
        .wr_en(s_awvalid_reg & s_awready_reg),
        .rd_en(m_awready_reg & m_awvalid_reg),
        .dout({m_awid_reg, m_awaddr_reg, m_awlen_reg, m_awsize_reg, m_awburst_reg, m_awlock_reg, m_awcache_reg, m_awprot_reg, m_awqos_reg}),
        .full(),
        .empty(),
        .valid(m_awvalid_reg)
    );

    // FIFOs for W channel
    fifo_sync #(
        .DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 + 1),
        .DEPTH(2**LGFIFO)
    ) w_fifo (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(~S_AXI_ARESETN),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(~M_AXI_ARESETN),
        .din({s_wdata_reg, s_wstrb_reg, s_wlast_reg, s_wvalid_reg}),
        .wr_en(s_wvalid_reg & s_wready_reg),
        .rd_en(m_wready_reg & m_wvalid_reg),
        .dout({m_wdata_reg, m_wstrb_reg, m_wlast_reg, m_wvalid_reg}),
        .full(),
        .empty(),
        .valid(m_wvalid_reg)
    );

    // FIFOs for B channel
    fifo_sync #(
        .DATA_WIDTH(C_S_AXI_ID_WIDTH + 2 + 1),
        .DEPTH(2**LGFIFO)
    ) b_fifo (
        .clk_wr(M_AXI_ACLK),
        .rst_wr(~M_AXI_ARESETN),
        .clk_rd(S_AXI_ACLK),
        .rst_rd(~S_AXI_ARESETN),
        .din({m_bid_reg, m_bresp_reg, m_bvalid_reg}),
        .wr_en(m_bvalid_reg & m_bready_reg),
        .rd_en(s_bready_reg & s_bvalid_reg),
        .dout({s_bid_reg, s_bresp_reg, s_bvalid_reg}),
        .full(),
        .empty(),
        .valid(s_bvalid_reg)
    );

    // FIFOs for AR channel
    fifo_sync #(
        .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
        .DEPTH(2**LGFIFO)
    ) ar_fifo (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(~S_AXI_ARESETN),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(~M_AXI_ARESETN),
        .din({s_arid_reg, s_araddr_reg, s_arlen_reg, s_arsize_reg, s_arburst_reg, s_arlock_reg, s_arcache_reg, s_arprot_reg, s_arqos_reg}),
        .wr_en(s_arvalid_reg & s_arready_reg),
        .rd_en(m_arready_reg & m_arvalid_reg),
        .dout({m_arid_reg, m_araddr_reg, m_arlen_reg, m_arsize_reg, m_arburst_reg, m_arlock_reg, m_arcache_reg, m_arprot_reg, m_arqos_reg}),
        .full(),
        .empty(),
        .valid(m_arvalid_reg)
    );

    // FIFOs for R channel
    fifo_sync #(
        .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 + 1),
        .DEPTH(2**LGFIFO)
    ) r_fifo (
        .clk_wr(M_AXI_ACLK),
        .rst_wr(~M_AXI_ARESETN),
        .clk_rd(S_AXI_ACLK),
        .rst_rd(~S_AXI_ARESETN),
        .din({m_rid_reg, m_rdata_reg, m_rresp_reg, m_rlast_reg, m_rvalid_reg}),
        .wr_en(m_rvalid_reg & m_rready_reg),
        .rd_en(s_rready_reg & s_rvalid_reg),
        .dout({s_rid_reg, s_rdata_reg, s_rresp_reg, s_rlast_reg, s_rvalid_reg}),
        .full(),
        .empty(),
        .valid(s_rvalid_reg)
    );

    // AW channel register logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_awid_reg    <= 0;
            s_awaddr_reg  <= 0;
            s_awlen_reg   <= 0;
            s_awsize_reg  <= 0;
            s_awburst_reg <= 0;
            s_awlock_reg  <= 0;
            s_awcache_reg <= 0;
            s_awprot_reg  <= 0;
            s_awqos_reg   <= 0;
            s_awvalid_reg <= 0;
        end else begin
            if (s_awvalid_reg & s_awready_reg) begin
                s_awid_reg    <= 0;
                s_awaddr_reg  <= 0;
                s_awlen_reg   <= 0;
                s_awsize_reg  <= 0;
                s_awburst_reg <= 0;
                s_awlock_reg  <= 0;
                s_awcache_reg <= 0;
                s_awprot_reg  <= 0;
                s_awqos_reg   <= 0;
                s_awvalid_reg <= 0;
            end else if (S_AXI_AWVALID) begin
                s_awid_reg    <= S_AXI_AWID;
                s_awaddr_reg  <= S_AXI_AWADDR;
                s_awlen_reg   <= S_AXI_AWLEN;
                s_awsize_reg  <= S_AXI_AWSIZE;
                s_awburst_reg <= S_AXI_AWBURST;
                s_awlock_reg  <= S_AXI_AWLOCK;
                s_awcache_reg <= S_AXI_AWCACHE;
                s_awprot_reg  <= S_AXI_AWPROT;
                s_awqos_reg   <= S_AXI_AWQOS;
                s_awvalid_reg <= 1;
            end
        end
    end

    assign s_awready = m_awready_reg;

    // W channel register logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_wdata_reg   <= 0;
            s_wstrb_reg   <= 0;
            s_wlast_reg   <= 0;
            s_wvalid_reg  <= 0;
        end else begin
            if (s_wvalid_reg & s_wready_reg) begin
                s_wdata_reg   <= 0;
                s_wstrb_reg   <= 0;
                s_wlast_reg   <= 0;
                s_wvalid_reg  <= 0;
            end else if (S_AXI_WVALID) begin
                s_wdata_reg   <= S_AXI_WDATA;
                s_wstrb_reg   <= S_AXI_WSTRB;
                s_wlast_reg   <= S_AXI_WLAST;
                s_wvalid_reg  <= 1;
            end
        end
    end

    assign s_wready = m_wready_reg;

    // B channel register logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_bid_reg     <= 0;
            s_bresp_reg   <= 0;
            s_bvalid_reg  <= 0;
        end else begin
            if (s_bvalid_reg & s_bready_reg) begin
                s_bid_reg     <= 0;
                s_bresp_reg   <= 0;
                s_bvalid_reg  <= 0;
            end else if (b_fifo.valid) begin
                s_bid_reg     <= b_fifo_out[C_S_AXI_ID_WIDTH + 2 +: C_S_AXI_ID_WIDTH];
                s_bresp_reg   <= b_fifo_out[2 +: 2];
                s_bvalid_reg  <= b_fifo_out[0];
            end
        end
    end

    assign s_bready = b_fifo.valid;

    // AR channel register logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_arid_reg    <= 0;
            s_araddr_reg  <= 0;
            s_arlen_reg   <= 0;
            s_arsize_reg  <= 0;
            s_arburst_reg <= 0;
            s_arlock_reg  <= 0;
            s_arcache_reg <= 0;
            s_arprot_reg  <= 0;
            s_arqos_reg   <= 0;
            s_arvalid_reg <= 0;
        end else begin
            if (s_arvalid_reg & s_arready_reg) begin
                s_arid_reg    <= 0;
                s_araddr_reg  <= 0;
                s_arlen_reg   <= 0;
                s_arsize_reg  <= 0;
                s_arburst_reg <= 0;
                s_arlock_reg  <= 0;
                s_arcache_reg <= 0;
                s_arprot_reg  <= 0;
                s_arqos_reg   <= 0;
                s_arvalid_reg <= 0;
            end else if (S_AXI_ARVALID) begin
                s_arid_reg    <= S_AXI_ARID;
                s_araddr_reg  <= S_AXI_ARADDR;
                s_arlen_reg   <= S_AXI_ARLEN;
                s_arsize_reg  <= S_AXI_ARSIZE;
                s_arburst_reg <= S_AXI_ARBURST;
                s_arlock_reg  <= S_AXI_ARLOCK;
                s_arcache_reg <= S_AXI_ARCACHE;
                s_arprot_reg  <= S_AXI_ARPROT;
                s_arqos_reg   <= S_AXI_ARQOS;
                s_arvalid_reg <= 1;
            end
        end
    end

    assign s_arready = m_arready_reg;

    // R channel register logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_rid_reg     <= 0;
            s_rdata_reg   <= 0;
            s_rresp_reg   <= 0;
            s_rlast_reg   <= 0;
            s_rvalid_reg  <= 0;
        end else begin
            if (s_rvalid_reg & s_rready_reg) begin
                s_rid_reg     <= 0;
                s_rdata_reg   <= 0;
                s_rresp_reg   <= 0;
                s_rlast_reg   <= 0;
                s_rvalid_reg  <= 0;
            end else if (r_fifo.valid) begin
                s_rid_reg     <= r_fifo_out[C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2 + 1 +: C_S_AXI_ID_WIDTH];
                s_rdata_reg   <= r_fifo_out[C_S_AXI_DATA_WIDTH + 2 + 1 +: C_S_AXI_DATA_WIDTH];
                s_rresp_reg   <= r_fifo_out[2 + 1 +: 2];
                s_rlast_reg   <= r_fifo_out[1];
                s_rvalid_reg  <= r_fifo_out[0];
            end
        end
    end

    assign s_rready = r_fifo.valid;

    // M_AXI reset logic
    always @(posedge M_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            M_AXI_ARESETN <= 0;
        end else begin
            M_AXI_ARESETN <= 1;
        end
    end

    // M_AXI AW channel
    assign M_AXI_AWID    = m_awid_reg;
    assign M_AXI_AWADDR  = m_awaddr_reg;
    assign M_AXI_AWLEN   = m_awlen_reg;
    assign M_AXI_AWSIZE  = m_awsize_reg;
    assign M_AXI_AWBURST = m_awburst_reg;
    assign M_AXI_AWLOCK  = m_awlock_reg;
    assign M_AXI_AWCACHE = m_awcache_reg;
    assign M_AXI_AWPROT  = m_awprot_reg;
    assign M_AXI_AWQOS   = m_awqos_reg;
    assign M_AXI_AWVALID = m_awvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_awready_reg <= 0;
        end else begin
            m_awready_reg <= M_AXI_AWREADY;
        end
    end

    // M_AXI W channel
    assign M_AXI_WDATA = m_wdata_reg;
    assign M_AXI_WSTRB = m_wstrb_reg;
    assign M_AXI_WLAST = m_wlast_reg;
    assign M_AXI_WVALID = m_wvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_wready_reg <= 0;
        end else begin
            m_wready_reg <= M_AXI_WREADY;
        end
    end

    // M_AXI B channel
    assign M_AXI_BREADY = m_bready_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_bid_reg     <= 0;
            m_bresp_reg   <= 0;
            m_bvalid_reg  <= 0;
        end else begin
            m_bid_reg     <= M_AXI_BID;
            m_bresp_reg   <= M_AXI_BRESP;
            m_bvalid_reg  <= M_AXI_BVALID;
        end
    end

    // M_AXI AR channel
    assign M_AXI_ARID    = m_arid_reg;
    assign M_AXI_ARADDR  = m_araddr_reg;
    assign M_AXI_ARLEN   = m_arlen_reg;
    assign M_AXI_ARSIZE  = m_arsize_reg;
    assign M_AXI_ARBURST = m_arburst_reg;
    assign M_AXI_ARLOCK  = m_arlock_reg;
    assign M_AXI_ARCACHE = m_arcache_reg;
    assign M_AXI_ARPROT  = m_arprot_reg;
    assign M_AXI_ARQOS   = m_arqos_reg;
    assign M_AXI_ARVALID = m_arvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_arready_reg <= 0;
        end else begin
            m_arready_reg <= M_AXI_ARREADY;
        end
    end

    // M_AXI R channel
    assign M_AXI_RREADY = m_rready_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_rid_reg     <= 0;
            m_rdata_reg   <= 0;
            m_rresp_reg   <= 0;
            m_rlast_reg   <= 0;
            m_rvalid_reg  <= 0;
        end else begin
            m_rid_reg     <= M_AXI_RID;
            m_rdata_reg   <= M_AXI_RDATA;
            m_rresp_reg   <= M_AXI_RRESP;
            m_rlast_reg   <= M_AXI_RLAST;
            m_rvalid_reg  <= M_AXI_RVALID;
        end
    end

endmodule

// Synchronous FIFO module
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
) (
    input wire clk_wr,
    input wire rst_wr,
    input wire clk_rd,
    input wire rst_rd,
    input wire [DATA_WIDTH-1:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty,
    output wire valid
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;

    wire wr_en_int = wr_en & ~full;
    wire rd_en_int = rd_en & valid;

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            count  <= 0;
        end else if (wr_en_int) begin
            mem[wr_ptr] <= din;
            wr_ptr      <= wr_ptr + 1;
            count       <= count + 1;
        end else if (rd_en_int) begin
            count       <= count - 1;
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
        end else if (rd_en_int) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign dout  = mem[rd_ptr];
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    assign valid = (count != 0);

endmodule
