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

    // Internal signals for read operations
    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [LEN_WIDTH-1:0] read_len;
    reg [TAG_WIDTH-1:0] read_tag;
    reg [AXIS_ID_WIDTH-1:0] read_id;
    reg [AXIS_DEST_WIDTH-1:0] read_dest;
    reg [AXIS_USER_WIDTH-1:0] read_user;
    reg read_desc_valid;
    reg read_desc_ready;
    reg [TAG_WIDTH-1:0] read_desc_status_tag;
    reg [3:0] read_desc_status_error;
    reg read_desc_status_valid;
    reg [AXIS_DATA_WIDTH-1:0] read_data_tdata;
    reg [AXIS_KEEP_WIDTH-1:0] read_data_tkeep;
    reg read_data_tvalid;
    reg read_data_tready;
    reg read_data_tlast;
    reg [AXIS_ID_WIDTH-1:0] read_data_tid;
    reg [AXIS_DEST_WIDTH-1:0] read_data_tdest;
    reg [AXIS_USER_WIDTH-1:0] read_data_tuser;

    // Internal signals for write operations
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [AXIS_ID_WIDTH-1:0] write_id;
    reg [AXIS_DEST_WIDTH-1:0] write_dest;
    reg [AXIS_USER_WIDTH-1:0] write_user;
    reg write_desc_valid;
    reg write_desc_ready;
    reg [LEN_WIDTH-1:0] write_desc_status_len;
    reg [TAG_WIDTH-1:0] write_desc_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_desc_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_desc_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_desc_status_user;
    reg [3:0] write_desc_status_error;
    reg write_desc_status_valid;
    reg [AXIS_DATA_WIDTH-1:0] write_data_tdata;
    reg [AXIS_KEEP_WIDTH-1:0] write_data_tkeep;
    reg write_data_tvalid;
    reg write_data_tready;
    reg write_data_tlast;
    reg [AXIS_ID_WIDTH-1:0] write_data_tid;
    reg [AXIS_DEST_WIDTH-1:0] write_data_tdest;
    reg [AXIS_USER_WIDTH-1:0] write_data_tuser;

    // Instantiate read descriptor handler
    read_desc_handler read_desc_inst (
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
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock(m_axi_arlock),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axis_read_desc_status_tag(read_desc_status_tag),
        .m_axis_read_desc_status_error(read_desc_status_error),
        .m_axis_read_desc_status_valid(read_desc_status_valid),
        .read_enable(read_enable)
    );

    // Instantiate write descriptor handler
    write_desc_handler write_desc_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_write_desc_addr(s_axis_write_desc_addr),
        .s_axis_write_desc_len(s_axis_write_desc_len),
        .s_axis_write_desc_tag(s_axis_write_desc_tag),
        .s_axis_write_desc_valid(s_axis_write_desc_valid),
        .s_axis_write_desc_ready(write_desc_ready),
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axis_write_desc_status_len(write_desc_status_len),
        .m_axis_write_desc_status_tag(write_desc_status_tag),
        .m_axis_write_desc_status_id(write_desc_status_id),
        .m_axis_write_desc_status_dest(write_desc_status_dest),
        .m_axis_write_desc_status_user(write_desc_status_user),
        .m_axis_write_desc_status_error(write_desc_status_error),
        .m_axis_write_desc_status_valid(write_desc_status_valid),
        .write_enable(write_enable),
        .write_abort(write_abort)
    );

    // Instantiate read data handler
    read_data_handler read_data_inst (
        .clk(clk),
        .rst(rst),
        .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        .m_axis_read_data_tdata(read_data_tdata),
        .m_axis_read_data_tkeep(read_data_tkeep),
        .m_axis_read_data_tvalid(read_data_tvalid),
        .m_axis_read_data_tready(m_axis_read_data_tready),
        .m_axis_read_data_tlast(read_data_tlast),
        .m_axis_read_data_tid(read_data_tid),
        .m_axis_read_data_tdest(read_data_tdest),
        .m_axis_read_data_tuser(read_data_tuser)
    );

    // Instantiate write data handler
    write_data_handler write_data_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_write_data_tdata(s_axis_write_data_tdata),
        .s_axis_write_data_tkeep(s_axis_write_data_tkeep),
        .s_axis_write_data_tvalid(s_axis_write_data_tvalid),
        .s_axis_write_data_tready(write_data_tready),
        .s_axis_write_data_tlast(s_axis_write_data_tlast),
        .s_axis_write_data_tid(s_axis_write_data_tid),
        .s_axis_write_data_tdest(s_axis_write_data_tdest),
        .s_axis_write_data_tuser(s_axis_write_data_tuser),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );

    // Output assignments
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_desc_status_tag;
    assign m_axis_read_desc_status_error = read_desc_status_error;
    assign m_axis_read_desc_status_valid = read_desc_status_valid;
    assign m_axis_read_data_tdata = read_data_tdata;
    assign m_axis_read_data_tkeep = read_data_tkeep;
    assign m_axis_read_data_tvalid = read_data_tvalid;
    assign read_data_tready = m_axis_read_data_tready;
    assign m_axis_read_data_tlast = read_data_tlast;
    assign m_axis_read_data_tid = read_data_tid;
    assign m_axis_read_data_tdest = read_data_tdest;
    assign m_axis_read_data_tuser = read_data_tuser;
    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_desc_status_len;
    assign m_axis_write_desc_status_tag = write_desc_status_tag;
    assign m_axis_write_desc_status_id = write_desc_status_id;
    assign m_axis_write_desc_status_dest = write_desc_status_dest;
    assign m_axis_write_desc_status_user = write_desc_status_user;
    assign m_axis_write_desc_status_error = write_desc_status_error;
    assign m_axis_write_desc_status_valid = write_desc_status_valid;
    assign s_axis_write_data_tready = write_data_tready;

endmodule

module read_desc_handler #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_ID_WIDTH = 8,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXI_ID_WIDTH-1:0]    s_axis_read_desc_id,
    input  wire [8-1:0]               s_axis_read_desc_dest,
    input  wire [1-1:0]               s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
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
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    input  wire                       read_enable
);

    reg s_axis_read_desc_ready_reg;
    reg m_axi_arvalid_reg;
    reg m_axis_read_desc_status_valid_reg;
    reg [TAG_WIDTH-1:0] m_axis_read_desc_status_tag_reg;
    reg [3:0] m_axis_read_desc_status_error_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_read_desc_ready_reg <= 0;
            m_axi_arvalid_reg <= 0;
            m_axis_read_desc_status_valid_reg <= 0;
            m_axis_read_desc_status_tag_reg <= 0;
            m_axis_read_desc_status_error_reg <= 0;
        end else begin
            s_axis_read_desc_ready_reg <= read_enable && !m_axi_arvalid_reg && s_axis_read_desc_valid;
            m_axi_arvalid_reg <= read_enable && s_axis_read_desc_ready_reg && !m_axi_arready;
            if (m_axi_arready) begin
                m_axi_arvalid_reg <= 0;
            end
            if (m_axi_rvalid && m_axi_rlast) begin
                m_axis_read_desc_status_tag_reg <= s_axis_read_desc_tag;
                m_axis_read_desc_status_error_reg <= m_axi_rresp == 2'b00 ? 0 : 1;
                m_axis_read_desc_status_valid_reg <= 1;
            end else if (m_axis_read_desc_status_valid_reg && m_axis_read_desc_status_ready) begin
                m_axis_read_desc_status_valid_reg <= 0;
            end
        end
    end

    assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;
    assign m_axi_arid = s_axis_read_desc_id;
    assign m_axi_araddr = s_axis_read_desc_addr;
    assign m_axi_arlen = s_axis_read_desc_len[7:0] - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 0;
    assign m_axi_arprot = 0;
    assign m_axi_arvalid = m_axi_arvalid_reg;
    assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_reg;
    assign m_axis_read_desc_status_error = m_axis_read_desc_status_error_reg;
    assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_reg;

endmodule

module write_desc_handler #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_ID_WIDTH = 8,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
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
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXI_ID_WIDTH-1:0]    m_axis_write_desc_status_id,
    output wire [8-1:0]               m_axis_write_desc_status_dest,
    output wire [1-1:0]               m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    input  wire                       write_enable,
    input  wire                       write_abort
);

    reg s_axis_write_desc_ready_reg;
    reg m_axi_awvalid_reg;
    reg m_axis_write_desc_status_valid_reg;
    reg [TAG_WIDTH-1:0] m_axis_write_desc_status_tag_reg;
    reg [AXI_ID_WIDTH-1:0] m_axis_write_desc_status_id_reg;
    reg [3:0] m_axis_write_desc_status_error_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_write_desc_ready_reg <= 0;
            m_axi_awvalid_reg <= 0;
            m_axis_write_desc_status_valid_reg <= 0;
            m_axis_write_desc_status_tag_reg <= 0;
            m_axis_write_desc_status_id_reg <= 0;
            m_axis_write_desc_status_error_reg <= 0;
        end else begin
            s_axis_write_desc_ready_reg <= write_enable && !m_axi_awvalid_reg && s_axis_write_desc_valid;
            m_axi_awvalid_reg <= write_enable && s_axis_write_desc_ready_reg && !m_axi_awready;
            if (m_axi_awready) begin
                m_axi_awvalid_reg <= 0;
            end
            if (m_axi_bvalid && m_axi_bresp == 2'b00) begin
                m_axis_write_desc_status_tag_reg <= s_axis_write_desc_tag;
                m_axis_write_desc_status_id_reg <= s_axis_write_desc_id;
                m_axis_write_desc_status_error_reg <= 0;
                m_axis_write_desc_status_valid_reg <= 1;
            end else if (m_axi_bvalid && m_axi_bresp != 2'b00) begin
                m_axis_write_desc_status_tag_reg <= s_axis_write_desc_tag;
                m_axis_write_desc_status_id_reg <= s_axis_write_desc_id;
                m_axis_write_desc_status_error_reg <= 1;
                m_axis_write_desc_status_valid_reg <= 1;
            end else if (m_axis_write_desc_status_valid_reg && m_axis_write_desc_status_ready) begin
                m_axis_write_desc_status_valid_reg <= 0;
            end
            if (write_abort && m_axi_awvalid_reg) begin
                m_axi_awvalid_reg <= 0;
                m_axis_write_desc_status_error_reg <= 1;
                m_axis_write_desc_status_valid_reg <= 1;
            end
        end
    end

    assign s_axis_write_desc_ready = s_axis_write_desc_ready_reg;
    assign m_axi_awid = s_axis_write_desc_id;
    assign m_axi_awaddr = s_axis_write_desc_addr;
    assign m_axi_awlen = s_axis_write_desc_len[7:0] - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 0;
    assign m_axi_awprot = 0;
    assign m_axi_awvalid = m_axi_awvalid_reg;
    assign m_axis_write_desc_status_len = s_axis_write_desc_len;
    assign m_axis_write_desc_status_tag = m_axis_write_desc_status_tag_reg;
    assign m_axis_write_desc_status_id = m_axis_write_desc_status_id_reg;
    assign m_axis_write_desc_status_dest = 0;
    assign m_axis_write_desc_status_user = 0;
    assign m_axis_write_desc_status_error = m_axis_write_desc_status_error_reg;
    assign m_axis_write_desc_status_valid = m_axis_write_desc_status_valid_reg;

endmodule

module read_data_handler #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready,
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser
);

    reg m_axi_rready_reg;
    reg m_axis_read_data_tvalid_reg;
    reg m_axis_read_data_tlast_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_rready_reg <= 0;
            m_axis_read_data_tvalid_reg <= 0;
            m_axis_read_data_tlast_reg <= 0;
        end else begin
            m_axi_rready_reg <= m_axis_read_data_tready || !m_axis_read_data_tvalid_reg;
            m_axis_read_data_tvalid_reg <= m_axi_rvalid && m_axi_rready_reg;
            m_axis_read_data_tlast_reg <= m_axi_rlast;
        end
    end

    assign m_axi_rready = m_axi_rready_reg;
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axis_read_data_tvalid_reg;
    assign m_axis_read_data_tlast = m_axis_read_data_tlast_reg;
    assign m_axis_read_data_tid = AXIS_ID_ENABLE ? m_axi_rid : 0;
    assign m_axis_read_data_tdest = AXIS_DEST_ENABLE ? 0 : 0;
    assign m_axis_read_data_tuser = AXIS_USER_ENABLE ? 0 : 0;

endmodule

module write_data_handler #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    parameter AXIS_LAST_ENABLE = 1,
    parameter AXIS_ID_ENABLE = 0,
    parameter AXIS_ID_WIDTH = 8,
    parameter AXIS_DEST_ENABLE = 0,
    parameter AXIS_DEST_WIDTH = 8,
    parameter AXIS_USER_ENABLE = 1,
    parameter AXIS_USER_WIDTH = 1
)
(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready
);

    reg s_axis_write_data_tready_reg;
    reg m_axi_wvalid_reg;
    reg m_axi_wlast_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_write_data_tready_reg <= 0;
            m_axi_wvalid_reg <= 0;
            m_axi_wlast_reg <= 0;
        end else begin
            s_axis_write_data_tready_reg <= m_axi_wready || !m_axi_wvalid_reg;
            m_axi_wvalid_reg <= s_axis_write_data_tvalid && s_axis_write_data_tready_reg;
            m_axi_wlast_reg <= s_axis_write_data_tlast;
        end
    end

    assign s_axis_write_data_tready = s_axis_write_data_tready_reg;
    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = m_axi_wlast_reg;
    assign m_axi_wvalid = m_axi_wvalid_reg;
    assign m_axi_bready = 1;

endmodule
