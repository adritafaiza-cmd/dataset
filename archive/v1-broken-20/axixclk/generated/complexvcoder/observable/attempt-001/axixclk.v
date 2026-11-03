module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH    = 2,
    parameter integer C_S_AXI_DATA_WIDTH    = 32,
    parameter integer C_S_AXI_ADDR_WIDTH    = 6,
    parameter [0:0] OPT_WRITE_ONLY        = 1'b0,
    parameter [0:0] OPT_READ_ONLY         = 1'b0,
    parameter integer XCLOCK_FFS            = 2,
    parameter integer LGFIFO                = 5
) (
    input wire                S_AXI_ACLK,
    input wire                S_AXI_ARESETN,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [7 : 0]              S_AXI_AWLEN,
    input wire [2 : 0]              S_AXI_AWSIZE,
    input wire [1 : 0]              S_AXI_AWBURST,
    input wire                      S_AXI_AWLOCK,
    input wire [3 : 0]              S_AXI_AWCACHE,
    input wire [2 : 0]              S_AXI_AWPROT,
    input wire [3 : 0]              S_AXI_AWQOS,
    input wire                      S_AXI_AWVALID,
    output wire                     S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire                      S_AXI_WLAST,
    input wire                      S_AXI_WVALID,
    output wire                     S_AXI_WREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output wire [1 : 0]             S_AXI_BRESP,
    output wire                     S_AXI_BVALID,
    input wire                      S_AXI_BREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [7 : 0]              S_AXI_ARLEN,
    input wire [2 : 0]              S_AXI_ARSIZE,
    input wire [1 : 0]              S_AXI_ARBURST,
    input wire                      S_AXI_ARLOCK,
    input wire [3 : 0]              S_AXI_ARCACHE,
    input wire [2 : 0]              S_AXI_ARPROT,
    input wire [3 : 0]              S_AXI_ARQOS,
    input wire                      S_AXI_ARVALID,
    output wire                     S_AXI_ARREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0]             S_AXI_RRESP,
    output wire                     S_AXI_RLAST,
    output wire                     S_AXI_RVALID,
    input wire                      S_AXI_RREADY,
    input wire                      M_AXI_ACLK,
    output wire                     M_AXI_ARESETN,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [7 : 0]              M_AXI_AWLEN,
    output wire [2 : 0]              M_AXI_AWSIZE,
    output wire [1 : 0]              M_AXI_AWBURST,
    output wire                     M_AXI_AWLOCK,
    output wire [3 : 0]              M_AXI_AWCACHE,
    output wire [2 : 0]              M_AXI_AWPROT,
    output wire [3 : 0]              M_AXI_AWQOS,
    output wire                     M_AXI_AWVALID,
    input wire                      M_AXI_AWREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
    output wire                     M_AXI_WLAST,
    output wire                     M_AXI_WVALID,
    input wire                      M_AXI_WREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
    input wire [1 : 0]              M_AXI_BRESP,
    input wire                      M_AXI_BVALID,
    output wire                     M_AXI_BREADY,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [7 : 0]              M_AXI_ARLEN,
    output wire [2 : 0]              M_AXI_ARSIZE,
    output wire [1 : 0]              M_AXI_ARBURST,
    output wire                     M_AXI_ARLOCK,
    output wire [3 : 0]              M_AXI_ARCACHE,
    output wire [2 : 0]              M_AXI_ARPROT,
    output wire [3 : 0]              M_AXI_ARQOS,
    output wire                     M_AXI_ARVALID,
    input wire                      M_AXI_ARREADY,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0]              M_AXI_RRESP,
    input wire                      M_AXI_RLAST,
    input wire                      M_AXI_RVALID,
    output wire                     M_AXI_RREADY
);

    wire slave_reset_sync_out;
    wire master_reset_sync_out;

    sync_reset slave_reset_sync (
        .in(S_AXI_ARESETN),
        .out(slave_reset_sync_out)
    );

    sync_reset master_reset_sync (
        .in(M_AXI_ARESETN),
        .out(master_reset_sync_out)
    );

    wire [C_S_AXI_DATA_WIDTH-1 : 0] write_fifo_data;
    wire write_fifo_valid;
    wire write_fifo_ready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] write_fifo_id;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] write_fifo_addr;
    wire [7 : 0] write_fifo_len;
    wire [2 : 0] write_fifo_size;
    wire [1 : 0] write_fifo_burst;
    wire write_fifo_lock;
    wire [3 : 0] write_fifo_cache;
    wire [2 : 0] write_fifo_prot;
    wire [3 : 0] write_fifo_qos;
    wire write_fifo_awvalid;
    wire write_fifo_awready;

    fifo #(
        .DEPTH(LGFIFO),
        .WIDTH(C_S_AXI_DATA_WIDTH)
    ) write_fifo (
        .din(S_AXI_WDATA),
        .wr_en(S_AXI_WVALID),
        .rd_clk(M_AXI_ACLK),
        .wr_clk(S_AXI_ACLK),
        .full(S_AXI_WREADY),
        . dout(write_fifo_data),
        .rd_en(write_fifo_valid),
        .empty(write_fifo_ready),
        .id(write_fifo_id),
        .addr(write_fifo_addr),
        .len(write_fifo_len),
        .size(write_fifo_size),
        .burst(write_fifo_burst),
        .lock(write_fifo_lock),
        .cache(write_fifo_cache),
        .prot(write_fifo_prot),
        .qos(write_fifo_qos),
        .awvalid(write_fifo_awvalid),
        .awready(write_fifo_awready)
    );

    wire [C_S_AXI_DATA_WIDTH-1 : 0] read_fifo_data;
    wire read_fifo_valid;
    wire read_fifo_ready;
    wire [C_S_AXI_ID_WIDTH-1 : 0] read_fifo_id;
    wire [C_S_AXI_ADDR_WIDTH-1 : 0] read_fifo_addr;
    wire [7 : 0] read_fifo_len;
    wire [2 : 0] read_fifo_size;
    wire [1 : 0] read_fifo_burst;
    wire read_fifo_lock;
    wire [3 : 0] read_fifo_cache;
    wire [2 : 0] read_fifo_prot;
    wire [3 : 0] read_fifo_qos;
    wire read_fifo_arvalid;
    wire read_fifo_arready;

    fifo #(
        .DEPTH(LGFIFO),
        .WIDTH(C_S_AXI_DATA_WIDTH)
    ) read_fifo (
        .din(M_AXI_RDATA),
        .wr_en(M_AXI_RVALID),
        .rd_clk(S_AXI_ACLK),
        .wr_clk(M_AXI_ACLK),
        .full(M_AXI_RREADY),
        . dout(read_fifo_data),
        .rd_en(read_fifo_valid),
        .empty(read_fifo_ready),
        .id(read_fifo_id),
        .addr(read_fifo_addr),
        .len(read_fifo_len),
        .size(read_fifo_size),
        .burst(read_fifo_burst),
        .lock(read_fifo_lock),
        .cache(read_fifo_cache),
        .prot(read_fifo_prot),
        .qos(read_fifo_qos),
        .arvalid(read_fifo_arvalid),
        .arready(read_fifo_arready)
    );

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

    wire [C_S_AXI_ID_WIDTH-1 : 0] wdata_reg;
    wire [C_S_AXI_DATA_WIDTH/8-1 : 0] wstrb_reg;
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

    always @(posedge S_AXI_ACLK or negedge slave_reset_sync_out) begin
        if (!slave_reset_sync_out) begin
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
            awready_reg <= 0;

            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;

            bid_reg <= 0;
            bresp_reg <= 0;
            bvalid_reg <= 0;
            bready_reg <= 0;

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
            arready_reg <= 0;

            rid_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
            rlast_reg <= 0;
            rvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            if (S_AXI_AWVALID && !write_fifo_full) begin
                awid_reg <= S_AXI_AWID;
                awaddr_reg <= S_AXI_AWADDR;
                awlen_reg <= S_AXI_AWLEN;
                awsize_reg <= S_AXI_AWSIZE;
                awburst_reg <= S_AXI_AWBURST;
                awlock_reg <= S_AXI_AWLOCK;
                awcache_reg <= S_AXI_AWCACHE;
                awprot_reg <= S_AXI_AWPROT;
                awqos_reg <= S_AXI_AWQOS;
                awvalid_reg <= S_AXI_AWVALID;
                awready_reg <= write_fifo_ready;

                write_fifo_valid <= 1;
                write_fifo_data <= S_AXI_WDATA;
                write_fifo_strb <= S_AXI_WSTRB;
                write_fifo_last <= S_AXI_WLAST;
                write_fifo_id <= S_AXI_AWID;
                write_fifo_addr <= S_AXI_AWADDR;
                write_fifo_len <= S_AXI_AWLEN;
                write_fifo_size <= S_AXI_AWSIZE;
                write_fifo_burst <= S_AXI_AWBURST;
                write_fifo_lock <= S_AXI_AWLOCK;
                write_fifo_cache <= S_AXI_AWCACHE;
                write_fifo_prot <= S_AXI_AWPROT;
                write_fifo_qos <= S_AXI_AWQOS;
            end else begin
                awvalid_reg <= 0;
                awready_reg <= 0;
            end

            if (write_fifo_valid && write_fifo_ready) begin
                write_fifo_valid <= 0;
            end

            if (S_AXI_WVALID && write_fifo_valid && write_fifo_ready) begin
                wdata_reg <= S_AXI_WDATA;
                wstrb_reg <= S_AXI_WSTRB;
                wlast_reg <= S_AXI_WLAST;
                wvalid_reg <= S_AXI_WVALID;
                wready_reg <= write_fifo_ready;

                write_fifo_valid <= 0;
            end else begin
                wvalid_reg <= 0;
                wready_reg <= 0;
            end

            if (write_fifo_valid && write_fifo_ready && wvalid_reg && wready_reg) begin
                write_fifo_valid <= 0;
            end

            if (M_AXI_BVALID && !bvalid_reg) begin
                bid_reg <= M_AXI_BID;
                bresp_reg <= M_AXI_BRESP;
                bvalid_reg <= M_AXI_BVALID;
                bready_reg <= M_AXI_BREADY;
            end else begin
                bvalid_reg <= 0;
                bready_reg <= 0;
            end

            if (M_AXI_ARVALID && !arvalid_reg) begin
                arid_reg <= M_AXI_ARID;
                araddr_reg <= M_AXI_ARADDR;
                arlen_reg <= M_AXI_ARLEN;
                arsize_reg <= M_AXI_ARSIZE;
                arburst_reg <= M_AXI_ARBURST;
                arlock_reg <= M_AXI_ARLOCK;
                arcache_reg <= M_AXI_ARCACHE;
                arprot_reg <= M_AXI_ARPROT;
                arqos_reg <= M_AXI_ARQOS;
                arvalid_reg <= M_AXI_ARVALID;
                arready_reg <= M_AXI_ARREADY;
            end else begin
                arvalid_reg <= 0;
                arready_reg <= 0;
            end

            if (M_AXI_RVALID && !rvalid_reg) begin
                rid_reg <= M_AXI_RID;
                rdata_reg <= M_AXI_RDATA;
                rresp_reg <= M_AXI_RRESP;
                rlast_reg <= M_AXI_RLAST;
                rvalid_reg <= M_AXI_RVALID;
                rready_reg <= M_AXI_RREADY;
            end else begin
                rvalid_reg <= 0;
                rready_reg <= 0;
            end
        end
    end

    assign S_AXI_AWID = awid_reg;
    assign S_AXI_AWADDR = awaddr_reg;
    assign S_AXI_AWLEN = awlen_reg;
    assign S_AXI_AWSIZE = awsize_reg;
    assign S_AXI_AWBURST = awburst_reg;
    assign S_AXI_AWLOCK = awlock_reg;
    assign S_AXI_AWCACHE = awcache_reg;
    assign S_AXI_AWPROT = awprot_reg;
    assign S_AXI_AWQOS = awqos_reg;
    assign S_AXI_AWVALID = awvalid_reg;
    assign S_AXI_AWREADY = awready_reg;

    assign S_AXI_WDATA = wdata_reg;
    assign S_AXI_WSTRB = wstrb_reg;
    assign S_AXI_WLAST = wlast_reg;
    assign S_AXI_WVALID = wvalid_reg;
    assign S_AXI_WREADY = wready_reg;

    assign S_AXI_BID = bid_reg;
    assign S_AXI_BRESP = bresp_reg;
    assign S_AXI_BVALID = bvalid_reg;
    assign S_AXI_BREADY = bready_reg;

    assign S_AXI_ARID = arid_reg;
    assign S_AXI_ARADDR = araddr_reg;
    assign S_AXI_ARLEN = arlen_reg;
    assign S_AXI_ARSIZE = arsize_reg;
    assign S_AXI_ARBURST = arburst_reg;
    assign S_AXI_ARLOCK = arlock_reg;
    assign S_AXI_ARCACHE = arcache_reg;
    assign S_AXI_ARPROT = arprot_reg;
    assign S_AXI_ARQOS = arqos_reg;
    assign S_AXI_ARVALID = arvalid_reg;
    assign S_AXI_ARREADY = arready_reg;

    assign S_AXI_RID = rid_reg;
    assign S_AXI_RDATA = rdata_reg;
    assign S_AXI_RRESP = rresp_reg;
    assign S_AXI_RLAST = rlast_reg;
    assign S_AXI_RVALID = rvalid_reg;
    assign S_AXI_RREADY = rready_reg;

endmodule

module sync_reset (
    input wire in,
    output wire out
);

    reg out_reg;

    always @(posedge in) begin
        out_reg <= in;
    end

    assign out = out_reg;

endmodule

module fifo #(
    parameter integer DEPTH = 5,
    parameter integer WIDTH = 32
) (
    input wire [WIDTH-1 : 0] din,
    input wire wr_en,
    input wire rd_clk,
    input wire wr_clk,
    output wire full,
    output wire [WIDTH-1 : 0] dout,
    input wire rd_en,
    output wire empty,
    input wire [WIDTH-1 : 0] id,
    input wire [WIDTH-1 : 0] addr,
    input wire [WIDTH-1 : 0] len,
    input wire [WIDTH-1 : 0] size,
    input wire [WIDTH-1 : 0] burst,
    input wire [WIDTH-1 : 0] lock,
    input wire [WIDTH-1 : 0] cache,
    input wire [WIDTH-1 : 0] prot,
    input wire [WIDTH-1 : 0] qos,
    input wire awvalid,
    output wire awready,
    output wire [WIDTH-1 : 0] awid,
    output wire [WIDTH-1 : 0] awaddr,
    output wire [WIDTH-1 : 0] awlen,
    output wire [WIDTH-1 : 0] awsize,
    output wire [WIDTH-1 : 0] awburst,
    output wire awlock,
    output wire [WIDTH-1 : 0] awcache,
    output wire [WIDTH-1 : 0] awprot,
    output wire [WIDTH-1 : 0] awqos,
    input wire wdata,
    input wire wstrb,
    input wire wlast,
    input wire wvalid,
    output wire wready,
    input wire bvalid,
    output wire bready,
    input wire [WIDTH-1 : 0] bid,
    input wire [WIDTH-1 : 0] bresp,
    output wire [WIDTH-1 : 0] bid_out,
    output wire [WIDTH-1 : 0] bresp_out,
    input wire arvalid,
    output wire arready,
    input wire [WIDTH-1 : 0] arid,
    input wire [WIDTH-1 : 0] araddr,
    input wire [WIDTH-1 : 0] arlen,
    input wire [WIDTH-1 : 0] arsize,
    input wire [WIDTH-1 : 0] arburst,
    input wire arlock,
    input wire [WIDTH-1 : 0] arcache,
    input wire [WIDTH-1 : 0] arprot,
    input wire [WIDTH-1 : 0] arqos,
    input wire rvalid,
    output wire rready,
    input wire [WIDTH-1 : 0] rid,
    input wire [WIDTH-1 : 0] rdata,
    input wire rresp,
    input wire rlast,
    output wire [WIDTH-1 : 0] rid_out,
    output wire [WIDTH-1 : 0] rdata_out,
    output wire rresp_out,
    output wire rlast_out
);

    reg [WIDTH-1 : 0] mem [0 : DEPTH-1];
    reg [WIDTH-1 : 0] awid_reg;
    reg [WIDTH-1 : 0] awaddr_reg;
    reg [WIDTH-1 : 0] awlen_reg;
    reg [WIDTH-1 : 0] awsize_reg;
    reg [WIDTH-1 : 0] awburst_reg;
    reg awlock_reg;
    reg [WIDTH-1 : 0] awcache_reg;
    reg [WIDTH-1 : 0] awprot_reg;
    reg [WIDTH-1 : 0] awqos_reg;
    reg awvalid_reg;
    reg awready_reg;

    reg [WIDTH-1 : 0] wdata_reg;
    reg [WIDTH-1 : 0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg wready_reg;

    reg [WIDTH-1 : 0] bid_reg;
    reg [WIDTH-1 : 0] bresp_reg;
    reg bvalid_reg;
    reg bready_reg;

    reg [WIDTH-1 : 0] arid_reg;
    reg [WIDTH-1 : 0] araddr_reg;
    reg [WIDTH-1 : 0] arlen_reg;
    reg [WIDTH-1 : 0] arsize_reg;
    reg [WIDTH-1 : 0] arburst_reg;
    reg arlock_reg;
    reg [WIDTH-1 : 0] arcache_reg;
    reg [WIDTH-1 : 0] arprot_reg;
    reg [WIDTH-1 : 0] arqos_reg;
    reg arvalid_reg;
    reg arready_reg;

    reg [WIDTH-1 : 0] rid_reg;
    reg [WIDTH-1 : 0] rdata_reg;
    reg [WIDTH-1 : 0] rresp_reg;
    reg rlast_reg;
    reg rvalid_reg;
    reg rready_reg;

    always @(posedge wr_clk or negedge wr_clk) begin
        if (!wr_clk) begin
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
            awready_reg <= 0;

            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;

            bid_reg <= 0;
            bresp_reg <= 0;
            bvalid_reg <= 0;
            bready_reg <= 0;

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
            arready_reg <= 0;

            rid_reg <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
            rlast_reg <= 0;
            rvalid_reg <= 0;
            rready_reg <= 0;
        end else begin
            if (awvalid && !full) begin
                awid_reg <= id;
                awaddr_reg <= addr;
                awlen_reg <= len;
                awsize_reg <= size;
                awburst_reg <= burst;
                awlock_reg <= lock;
                awcache_reg <= cache;
                awprot_reg <= prot;
                awqos_reg <= qos;
                awvalid_reg <= awvalid;
                awready_reg <= full;

                mem[0] <= din;
            end else begin
                awvalid_reg <= 0;
                awready_reg <= 0;
            end

            if (awvalid && awready && wvalid && wready) begin
                mem[0] <= wdata;
            end

            if (bvalid && bready) begin
                bvalid_reg <= 0;
            end

            if (arvalid && !empty) begin
                arid_reg <= id;
                araddr_reg <= addr;
                arlen_reg <= len;
                arsize_reg <= size;
                arburst_reg <= burst;
                arlock_reg <= lock;
                arcache_reg <= cache;
                arprot_reg <= prot;
                arqos_reg <= qos;
                arvalid_reg <= arvalid;
                arready_reg <= empty;

                mem[0] <= din;
            end else begin
                arvalid_reg <= 0;
                arready_reg <= 0;
            end

            if (arvalid && arready && rvalid && rready) begin
                mem[0] <= rdata;
            end

            if (rvalid && rready) begin
                rvalid_reg <= 0;
            end
        end
    end

    assign awid = awid_reg;
    assign awaddr = awaddr_reg;
    assign awlen = awlen_reg;
    assign awsize = awsize_reg;
    assign awburst = awburst_reg;
    assign awlock = awlock_reg;
    assign awcache = awcache_reg;
    assign awprot = awprot_reg;
    assign awqos = awqos_reg;
    assign awvalid = awvalid_reg;
    assign awready = awready_reg;

    assign wdata = wdata_reg;
    assign wstrb = wstrb_reg;
    assign wlast = wlast_reg;
    assign wvalid = wvalid_reg;
    assign wready = wready_reg;

    assign bid = bid_reg;
    assign bresp = bresp_reg;
    assign bvalid = bvalid_reg;
    assign bready = bready_reg;

    assign arid = arid_reg;
    assign araddr = araddr_reg;
    assign arlen = arlen_reg;
    assign arsize = arsize_reg;
    assign arburst = arburst_reg;
    assign arlock = arlock_reg;
    assign arcache = arcache_reg;
    assign arprot = arprot_reg;
    assign arqos = arqos_reg;
    assign arvalid = arvalid_reg;
    assign arready = arready_reg;

    assign rid = rid_reg;
    assign rdata = rdata_reg;
    assign rresp = rresp_reg;
    assign rlast = rlast_reg;
    assign rvalid = rvalid_reg;
    assign rready = rready_reg;

endmodule
