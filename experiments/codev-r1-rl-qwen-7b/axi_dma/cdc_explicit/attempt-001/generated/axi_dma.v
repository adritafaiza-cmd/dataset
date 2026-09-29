module axi_dma #(
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
)(
    input  wire                       clk,
    input  wire                       rst,
    // Read descriptor input
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input  wire                       s_axis_read_desc_valid,
    output wire                       s_axis_read_desc_ready,
    // Read descriptor status output
    output wire [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output wire [3:0]                 m_axis_read_desc_status_error,
    output wire                       m_axis_read_desc_status_valid,
    // Read data output
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output wire                       m_axis_read_data_tvalid,
    input  wire                       m_axis_read_data_tready,
    output wire                       m_axis_read_data_tlast,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,
    // Write descriptor input
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input  wire [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input  wire [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input  wire                       s_axis_write_desc_valid,
    output wire                       s_axis_write_desc_ready,
    // Write descriptor status output
    output wire [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output wire [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output wire [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output wire [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output wire [3:0]                 m_axis_write_desc_status_error,
    output wire                       m_axis_write_desc_status_valid,
    // Write data input
    input  wire [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input  wire                       s_axis_write_data_tvalid,
    output wire                       s_axis_write_data_tready,
    input  wire                       s_axis_write_data_tlast,
    input  wire [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input  wire [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input  wire [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,
    // AXI master interface
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
    // Configuration
    input  wire                       read_enable,
    input  wire                       write_enable,
    input  wire                       write_abort
);

    // Read descriptor handling
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [LEN_WIDTH-1:0]      rd_len;
    reg [TAG_WIDTH-1:0]      rd_tag;
    reg                      rd_valid;

    // Write descriptor handling
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [LEN_WIDTH-1:0]      wr_len;
    reg [TAG_WIDTH-1:0]      wr_tag;
    reg                      wr_valid;

    // Read data stream
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = s_axis_read_desc_id;
    assign m_axis_read_data_tdest = s_axis_read_desc_dest;
    assign m_axis_read_data_tuser = s_axis_read_desc_user;

    // Write data stream
    assign s_axis_write_data_tready = m_axi_wready;

    // AXI write signals
    assign m_axi_awid = wr_addr[AXI_ID_WIDTH-1:0];
    assign m_axi_awaddr = wr_addr;
    assign m_axi_awlen = wr_len[7:0];
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0010;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = wr_valid && write_enable;

    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = s_axis_write_data_tlast;
    assign m_axi_wvalid = s_axis_write_data_tvalid && write_enable;

    // AXI read signals
    assign m_axi_arid = rd_addr[AXI_ID_WIDTH-1:0];
    assign m_axi_araddr = rd_addr;
    assign m_axi_arlen = rd_len[7:0];
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0010;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = rd_valid && read_enable;

    // Read descriptor ready
    assign s_axis_read_desc_ready = !rd_valid;

    // Write descriptor ready
    assign s_axis_write_desc_ready = !wr_valid;

    // Read descriptor status
    assign m_axis_read_desc_status_tag = rd_tag;
    assign m_axis_read_desc_status_error = 4'b0;
    assign m_axis_read_desc_status_valid = rd_valid && !read_enable;

    // Write descriptor status
    assign m_axis_write_desc_status_len = wr_len;
    assign m_axis_write_desc_status_tag = wr_tag;
    assign m_axis_write_desc_status_id = wr_addr[AXIS_ID_WIDTH-1:0];
    assign m_axis_write_desc_status_dest = wr_addr[AXIS_DEST_WIDTH-1:0];
    assign m_axis_write_desc_status_user = wr_addr[AXIS_USER_WIDTH-1:0];
    assign m_axis_write_desc_status_error = 4'b0;
    assign m_axis_write_desc_status_valid = wr_valid && !write_enable;

    // Read process
    always @(posedge clk) begin
        if (rst) begin
            rd_valid <= 0;
            rd_addr <= 0;
            rd_len <= 0;
            rd_tag <= 0;
        end else begin
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                rd_valid <= 1;
                rd_addr <= s_axis_read_desc_addr;
                rd_len <= s_axis_read_desc_len;
                rd_tag <= s_axis_read_desc_tag;
            end else if (m_axi_rvalid && m_axi_rlast && m_axi_rready) begin
                rd_valid <= 0;
            end
        end
    end

    // Write process
    always @(posedge clk) begin
        if (rst) begin
            wr_valid <= 0;
            wr_addr <= 0;
            wr_len <= 0;
            wr_tag <= 0;
        end else begin
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                wr_valid <= 1;
                wr_addr <= s_axis_write_desc_addr;
                wr_len <= s_axis_write_desc_len;
                wr_tag <= s_axis_write_desc_tag;
            end else if (s_axis_write_data_tlast && s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                wr_valid <= 0;
            end
        end
    end

    // AXI read handshake
    assign m_axi_rready = m_axis_read_data_tready;

    // AXI write handshake
    assign m_axi_bready = 1'b1;

endmodule
