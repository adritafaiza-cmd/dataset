```verilog
module axi_dma #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8,
    parameter ENABLE_SG = 0,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    /*
     * AXI read descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    /*
     * AXI read descriptor status output
     */
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    /*
     * AXI stream read data output
     */
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    /*
     * AXI write descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    /*
     * AXI write descriptor status output
     */
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    /*
     * AXI stream write data input
     */
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready,
    /*
     * Configuration
     */
    input  wire                       read_enable,
    input  wire                       write_enable,
    input  wire                       write_abort
);

    /*
     * Read Engine
     */
    wire read_desc_ready;
    wire [TAG_WIDTH-1:0] read_desc_status_tag;
    wire [3:0] read_desc_status_error;
    wire read_desc_status_valid;
    wire [AXIS_DATA_WIDTH-1:0] read_data_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] read_data_tkeep;
    wire read_data_tvalid;
    wire read_data_tlast;
    wire [AXIS_ID_WIDTH-1:0] read_data_tid;
    wire [AXIS_DEST_WIDTH-1:0] read_data_tdest;
    wire [AXIS_USER_WIDTH-1:0] read_data_tuser;
    wire [AXI_ID_WIDTH-1:0] read_arid;
    wire [AXI_ADDR_WIDTH-1:0] read_araddr;
    wire [7:0] read_arlen;
    wire [2:0] read_arsize;
    wire [1:0] read_arburst;
    wire read_arlock;
    wire [3:0] read_arcache;
    wire [2:0] read_arprot;
    wire read_arvalid;
    wire read_arready;
    wire [AXI_ID_WIDTH-1:0] read_rid;
    wire [AXI_DATA_WIDTH-1:0] read_rdata;
    wire [1:0] read_rresp;
    wire read_rlast;
    wire read_rvalid;
    wire read_rready;

    read_engine #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
        .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
        .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
        .AXIS_USER_ENABLE(AXIS_USER_ENABLE),
        .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .ENABLE_SG(ENABLE_SG),
        .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
    ) read_engine_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_read_desc_addr(s_axis_read_desc_addr),
        .s_axis_read_desc_len(s_axis_read_desc_len),
        .s_axis_read_desc_tag(s_axis_read_desc_tag),
        .s_axis_read_desc_id(s_axis_read_desc_id),
        .s_axis_read_desc_dest(s_axis_read_desc_dest),
        .s_axis_read_desc_user(s_axis_read_desc_user),
        .s_axis_read_desc_valid(s_axis_read_desc_valid),
        .s_axis_read_desc_ready(read_desc_ready),
        .m_axis_read_desc_status_tag(read_desc_status_tag),
        .m_axis_read_desc_status_error(read_desc_status_error),
        .m_axis_read_desc_status_valid(read_desc_status_valid),
        .m_axis_read_data_tdata(read_data_tdata),
        .m_axis_read_data_tkeep(read_data_tkeep),
        .m_axis_read_data_tvalid(read_data_tvalid),
        .m_axis_read_data_tready(m_axis_read_data_tready),
        .m_axis_read_data_tlast(read_data_tlast),
        .m_axis_read_data_tid(read_data_tid),
        .m_axis_read_data_tdest(read_data_tdest),
        .m_axis_read_data_tuser(read_data_tuser),
        .m_axi_arid(read_arid),
        .m_axi_araddr(read_araddr),
        .m_axi_arlen(read_arlen),
        .m_axi_arsize(read_arsize),
        .m_axi_arburst(read_arburst),
        .m_axi_arlock(read_arlock),
        .m_axi_arcache(read_arcache),
        .m_axi_arprot(read_arprot),
        .m_axi_arvalid(read_arvalid),
        .m_axi_arready(read_arready),
        .m_axi_rid(read_rid),
        .m_axi_rdata(read_rdata),
        .m_axi_rresp(read_rresp),
        .m_axi_rlast(read_rlast),
        .m_axi_rvalid(read_rvalid),
        .m_axi_rready(read_rready),
        .read_enable(read_enable)
    );

    /*
     * Write Engine
     */
    wire write_desc_ready;
    wire [LEN_WIDTH-1:0] write_desc_status_len;
    wire [TAG_WIDTH-1:0] write_desc_status_tag;
    wire [AXIS_ID_WIDTH-1:0] write_desc_status_id;
    wire [AXIS_DEST_WIDTH-1:0] write_desc_status_dest;
    wire [AXIS_USER_WIDTH-1:0] write_desc_status_user;
    wire [3:0] write_desc_status_error;
    wire write_desc_status_valid;
    wire write_data_tready;
    wire [AXI_ID_WIDTH-1:0] write_awid;
    wire [AXI_ADDR_WIDTH-1:0] write_awaddr;
    wire [7:0] write_awlen;
    wire [2:0] write_awsize;
    wire [1:0] write_awburst;
    wire write_awlock;
    wire [3:0] write_awcache;
    wire [2:0] write_awprot;
    wire write_awvalid;
    wire write_awready;
    wire [AXI_DATA_WIDTH-1:0] write_wdata;
    wire [AXI_STRB_WIDTH-1:0] write_wstrb;
    wire write_wlast;
    wire write_wvalid;
    wire write_wready;
    wire [AXI_ID_WIDTH-1:0] write_bid;
    wire [1:0] write_bresp;
    wire write_bvalid;
    wire write_bready;

    write_engine #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
        .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
        .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
        .AXIS_USER_ENABLE(AXIS_USER_ENABLE),
        .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .ENABLE_SG(ENABLE_SG),
        .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
    ) write_engine_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_write_desc_addr(s_axis_write_desc_addr),
        .s_axis_write_desc_len(s_axis_write_desc_len),
        .s_axis_write_desc_tag(s_axis_write_desc_tag),
        .s_axis_write_desc_valid(s_axis_write_desc_valid),
        .s_axis_write_desc_ready(write_desc_ready),
        .s_axis_write_data_tdata(s_axis_write_data_tdata),
        .s_axis_write_data_tkeep(s_axis_write_data_tkeep),
        .s_axis_write_data_tvalid(s_axis_write_data_tvalid),
        .s_axis_write_data_tready(write_data_tready),
        .s_axis_write_data_tlast(s_axis_write_data_tlast),
        .s_axis_write_data_tid(s_axis_write_data_tid),
        .s_axis_write_data_tdest(s_axis_write_data_tdest),
        .s_axis_write_data_tuser(s_axis_write_data_tuser),
        .m_axis_write_desc_status_len(write_desc_status_len),
        .m_axis_write_desc_status_tag(write_desc_status_tag),
        .m_axis_write_desc_status_id(write_desc_status_id),
        .m_axis_write_desc_status_dest(write_desc_status_dest),
        .m_axis_write_desc_status_user(write_desc_status_user),
        .m_axis_write_desc_status_error(write_desc_status_error),
        .m_axis_write_desc_status_valid(write_desc_status_valid),
        .m_axi_awid(write_awid),
        .m_axi_awaddr(write_awaddr),
        .m_axi_awlen(write_awlen),
        .m_axi_awsize(write_awsize),
        .m_axi_awburst(write_awburst),
        .m_axi_awlock(write_awlock),
        .m_axi_awcache(write_awcache),
        .m_axi_awprot(write_awprot),
        .m_axi_awvalid(write_awvalid),
        .m_axi_awready(write_awready),
        .m_axi_wdata(write_wdata),
        .m_axi_wstrb(write_wstrb),
        .m_axi_wlast(write_wlast),
        .m_axi_wvalid(write_wvalid),
        .m_axi_wready(write_wready),
        .m_axi_bid(write_bid),
        .m_axi_bresp(write_bresp),
        .m_axi_bvalid(write_bvalid),
        .m_axi_bready(write_bready),
        .write_enable(write_enable),
        .write_abort(write_abort)
    );

    /*
     * Read Engine Connections
     */
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_desc_status_tag;
    assign m_axis_read_desc_status_error = read_desc_status_error;
    assign m_axis_read_desc_status_valid = read_desc_status_valid;
    assign m_axis_read_data_tdata = read_data_tdata;
    assign m_axis_read_data_tkeep = read_data_tkeep;
    assign m_axis_read_data_tvalid = read_data_tvalid;
    assign m_axis_read_data_tlast = read_data_tlast;
    assign m_axis_read_data_tid = read_data_tid;
    assign m_axis_read_data_tdest = read_data_tdest;
    assign m_axis_read_data_tuser = read_data_tuser;
    assign m_axi_arid = read_arid;
    assign m_axi_araddr = read_araddr;
    assign m_axi_arlen = read_arlen;
    assign m_axi_arsize = read_arsize;
    assign m_axi_arburst = read_arburst;
    assign m_axi_arlock = read_arlock;
    assign m_axi_arcache = read_arcache;
    assign m_axi_arprot = read_arprot;
    assign m_axi_arvalid = read_arvalid;
    assign read_arready = m_axi_arready;
    assign read_rid = m_axi_rid;
    assign read_rdata = m_axi_rdata;
    assign read_rresp = m_axi_rresp;
    assign read_rlast = m_axi_rlast;
    assign read_rvalid = m_axi_rvalid;
    assign m_axi_rready = read_rready;

    /*
     * Write Engine Connections
     */
    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_desc_status_len;
    assign m_axis_write_desc_status_tag = write_desc_status_tag;
    assign m_axis_write_desc_status_id = write_desc_status_id;
    assign m_axis_write_desc_status_dest = write_desc_status_dest;
    assign m_axis_write_desc_status_user = write_desc_status_user;
    assign m_axis_write_desc_status_error = write_desc_status_error;
    assign m_axis_write_desc_status_valid = write_desc_status_valid;
    assign s_axis_write_data_tready = write_data_tready;
    assign m_axi_awid = write_awid;
    assign m_axi_awaddr = write_awaddr;
    assign m_axi_awlen = write_awlen;
    assign m_axi_awsize = write_awsize;
    assign m_axi_awburst = write_awburst;
    assign m_axi_awlock = write_awlock;
    assign m_axi_awcache = write_awcache;
    assign m_axi_awprot = write_awprot;
    assign m_axi_awvalid = write_awvalid;
    assign write_awready = m_axi_awready;
    assign m_axi_wdata = write_wdata;
    assign m_axi_wstrb = write_wstrb;
    assign m_axi_wlast = write_wlast;
    assign m_axi_wvalid = write_wvalid;
    assign write_wready = m_axi_wready;
    assign write_bid = m_axi_bid;
    assign write_bresp = m_axi_bresp;
    assign write_bvalid = m_axi_bvalid;
    assign m_axi_bready = write_bready;

endmodule

module read_engine #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8,
    parameter ENABLE_SG = 0,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    /*
     * AXI read descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    /*
     * AXI read descriptor status output
     */
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    /*
     * AXI stream read data output
     */
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready,
    /*
     * Configuration
     */
    input  wire                       read_enable
);

    reg [AXI_ADDR_WIDTH-1:0] addr_reg;
    reg [LEN_WIDTH-1:0] len_reg;
    reg [TAG_WIDTH-1:0] tag_reg;
    reg [AXIS_ID_WIDTH-1:0] id_reg;
    reg [AXIS_DEST_WIDTH-1:0] dest_reg;
    reg [AXIS_USER_WIDTH-1:0] user_reg;
    reg desc_valid_reg;
    reg desc_ready_reg;
    reg [3:0] status_error_reg;
    reg status_valid_reg;
    reg [AXIS_DATA_WIDTH-1:0] data_tdata_reg;
    reg [AXIS_KEEP_WIDTH-1:0] data_tkeep_reg;
    reg data_tvalid_reg;
    reg data_tlast_reg;
    reg [AXIS_ID_WIDTH-1:0] data_tid_reg;
    reg [AXIS_DEST_WIDTH-1:0] data_tdest_reg;
    reg [AXIS_USER_WIDTH-1:0] data_tuser_reg;
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg rready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 0;
            len_reg <= 0;
            tag_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
            desc_valid_reg <= 0;
            desc_ready_reg <= 0;
            status_error_reg <= 0;
            status_valid_reg <= 0;
            data_tdata_reg <= 0;
            data_tkeep_reg <= 0;
            data_tvalid_reg <= 0;
            data_tlast_reg <= 0;
            data_tid_reg <= 0;
            data_tdest_reg <= 0;
            data_tuser_reg <= 0;
            arid_reg <= 0;
            araddr_reg <= 0;
            arlen_reg <= 0;
            arsize_reg <= 0;
            arburst_reg <= 0;
            arlock_reg <= 0;
            arcache_reg <= 0;
            arprot_reg <= 0;
            arvalid_reg <= 0;
            rready_reg <= 0;
        end else if (read_enable) begin
            // Descriptor Handling
            if (s_axis_read_desc_valid && !desc_valid_reg) begin
                addr_reg <= s_axis_read_desc_addr;
                len_reg <= s_axis_read_desc_len;
                tag_reg <= s_axis_read_desc_tag;
                id_reg <= s_axis_read_desc_id;
                dest_reg <= s_axis_read_desc_dest;
                user_reg <= s_axis_read_desc_user;
                desc_valid_reg <= 1;
                desc_ready_reg <= 1;
            end else if (m_axi_arready && arvalid_reg) begin
                arvalid_reg <= 0;
            end else if (m_axi_rvalid && rready_reg) begin
                if (m_axi_rlast) begin
                    desc_valid_reg <= 0;
                    status_valid_reg <= 1;
                end
                rready_reg <= 0;
            end else if (!arvalid_reg && desc_valid_reg) begin
                arid_reg <= id_reg;
                araddr_reg <= addr_reg;
                arlen_reg <= (len_reg >> 3) - 1; // Assuming 1 beat = 4 bytes
                arsize_reg <= 2; // 4 bytes
                arburst_reg <= 1; // INCR
                arlock_reg <= 0;
                arcache_reg <= 3; // Modifiable
                arprot_reg <= 0;
                arvalid_reg <= 1;
                desc_ready_reg <= 0;
            end

            // Data Handling
            if (m_axi_rvalid && !data_tvalid_reg && !m_axi_rlast) begin
                data_tdata_reg <= m_axi_rdata;
                data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                data_tvalid_reg <= 1;
                data_tlast_reg <= m_axi_rlast;
                data_tid_reg <= id_reg;
                data_tdest_reg <= dest_reg;
                data_tuser_reg <= user_reg;
                rready_reg <= 1;
            end else if (m_axis_read_data_tready && data_tvalid_reg) begin
                data_tvalid_reg <= 0;
            end
        end
    end

    assign s_axis_read_desc_ready = desc_ready_reg;
    assign m_axis_read_desc_status_tag = tag_reg;
    assign m_axis_read_desc_status_error = status_error_reg;
    assign m_axis_read_desc_status_valid = status_valid_reg;
    assign m_axis_read_data_tdata = data_tdata_reg;
    assign m_axis_read_data_tkeep = data_tkeep_reg;
    assign m_axis_read_data_tvalid = data_tvalid_reg;
    assign m_axis_read_data_tlast = data_tlast_reg;
    assign m_axis_read_data_tid = data_tid_reg;
    assign m_axis_read_data_tdest = data_tdest_reg;
    assign m_axis_read_data_tuser = data_tuser_reg;
    assign m_axi_arid = arid_reg;
    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = arsize_reg;
    assign m_axi_arburst = arburst_reg;
    assign m_axi_arlock = arlock_reg;
    assign m_axi_arcache = arcache_reg;
    assign m_axi_arprot = arprot_reg;
    assign m_axi_arvalid = arvalid_reg;
    assign m_axi_rready = rready_reg;

endmodule

module write_engine #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 16,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8,
    parameter ENABLE_SG = 0,
    parameter ENABLE_UNALIGNED = 0
)
(
    input  wire                       clk,
    input  wire                       rst,
    /*
     * AXI write descriptor input
     */
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    /*
     * AXI stream write data input
     */
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    /*
     * AXI write descriptor status output
     */
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    /*
     * Configuration
     */
    input  wire                       write_enable,
    input  wire                       write_abort
);

    reg [AXI_ADDR_WIDTH-1:0] addr_reg;
    reg [LEN_WIDTH-1:0] len_reg;
    reg [TAG_WIDTH-1:0] tag_reg;
    reg [AXIS_ID_WIDTH-1:0] id_reg;
    reg [AXIS_DEST_WIDTH-1:0] dest_reg;
    reg [AXIS_USER_WIDTH-1:0] user_reg;
    reg desc_valid_reg;
    reg desc_ready_reg;
    reg [3:0] status_error_reg;
    reg status_valid_reg;
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg bready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 0;
            len_reg <= 0;
            tag_reg <= 0;
            id_reg <= 0;
            dest_reg <= 0;
            user_reg <= 0;
            desc_valid_reg <= 0;
            desc_ready_reg <= 0;
            status_error_reg <= 0;
            status_valid_reg <= 0;
            awid_reg <= 0;
            awaddr_reg <= 0;
            awlen_reg <= 0;
            awsize_reg <= 0;
            awburst_reg <= 0;
            awlock_reg <= 0;
            awcache_reg <= 0;
            awprot_reg <= 0;
            awvalid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            wvalid_reg <= 0;
            bready_reg <= 0;
        end else if (write_enable) begin
            // Descriptor Handling
            if (s_axis_write_desc_valid && !desc_valid_reg) begin
                addr_reg <= s_axis_write_desc_addr;
                len_reg <= s_axis_write_desc_len;
                tag_reg <= s_axis_write_desc_tag;
                id_reg <= s_axis_write_data_tid;
                dest_reg <= s_axis_write_data_tdest;
                user_reg <= s_axis_write_data_tuser;
                desc_valid_reg <= 1;
                desc_ready_reg <= 1;
            end else if (m_axi_awready && awvalid_reg) begin
                awvalid_reg <= 0;
            end else if (m_axi_bvalid && bready_reg) begin
                desc_valid_reg <= 0;
                status_valid_reg <= 1;
                bready_reg <= 0;
            end else if (!awvalid_reg && desc_valid_reg) begin
                awid_reg <= id_reg;
                awaddr_reg <= addr_reg;
                awlen_reg <= (len_reg >> 3) - 1; // Assuming 1 beat = 4 bytes
                awsize_reg <= 2; // 4 bytes
                awburst_reg <= 1; // INCR
                awlock_reg <= 0;
                awcache_reg <= 3; // Modifiable
                awprot_reg <= 0;
                awvalid_reg <= 1;
                desc_ready_reg <= 0;
            end

            // Data Handling
            if (s_axis_write_data_tvalid && !wvalid_reg) begin
                wdata_reg <= s_axis_write_data_tdata;
                wstrb_reg <= s_axis_write_data_tkeep;
                wlast_reg <= s_axis_write_data_tlast;
                wvalid_reg <= 