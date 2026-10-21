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

    // Internal parameters
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_DATA_WIDTH    = $clog2(AXI_DATA_WIDTH);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);

    // State encoding
    localparam IDLE = 3'd0;
    localparam AW_PREPARE = 3'd1;
    localparam AW_SEND = 3'd2;
    localparam W_PREPARE = 3'd3;
    localparam W_SEND = 3'd4;
    localparam B_WAIT = 3'd5;
    localparam AR_PREPARE = 3'd6;
    localparam AR_SEND = 3'd7;
    localparam R_PREPARE = 3'd8;
    localparam R_SEND = 3'd9;
    localparam R_WAIT = 3'd10;
    localparam FINISHED = 3'd11;

    reg [2:0] state;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [LEN_WIDTH-1:0] current_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [AXIS_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [AXI_ID_WIDTH-1:0] current_bid;
    reg [AXI_ID_WIDTH-1:0] current_rid;
    reg [3:0] current_bresp;
    reg [3:0] current_rresp;
    reg current_error;
    reg current_last;
    reg current_wlast;
    reg current_rlast;
    reg [7:0] burst_count;
    reg [7:0] burst_remain;
    reg [7:0] w_count;
    reg [7:0] r_count;
    reg [7:0] w_burst_count;
    reg [7:0] r_burst_count;
    reg [7:0] w_burst_remain;
    reg [7:0] r_burst_remain;
    reg [7:0] w_byte_count;
    reg [7:0] r_byte_count;
    reg [7:0] w_byte_remain;
    reg [7:0] r_byte_remain;
    reg [AXI_DATA_WIDTH-1:0] w_data_reg;
    reg [AXI_STRB_WIDTH-1:0] w_strb_reg;
    reg [AXI_DATA_WIDTH-1:0] r_data_reg;
    reg [AXI_ADDR_WIDTH-1:0] next_addr;
    reg [7:0] next_len;
    reg [2:0] next_size;
    reg [1:0] next_burst;
    reg next_lock;
    reg [3:0] next_cache;
    reg [2:0] next_prot;
    reg next_awvalid;
    reg next_wvalid;
    reg next_arvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_awvalid;
    reg next_arvalid;
    reg next_wvalid;
    reg next_rready;
    reg next_bready;
    reg next_wlast;
    reg next_rlast;
    reg next_awaddr;
    reg next_araddr;
    reg next_awlen;
    reg next_arlen;
    reg next_wdata;
    reg next_wstrb;
    reg next_rdata;
    reg next_rresp;
    reg next_rlast;
    reg next_rvalid;
    reg next_bvalid;
    reg next_bresp;
    reg next_bid;
    reg next_rid;
    reg next_dest;
    reg next_user;
    reg next_tid;
    reg next_tkeep;
    reg next_tlast;
    reg next_tvalid;
    reg next_tready;
    reg next_read_status_valid;
    reg next_read_status_tag;
    reg next_read_status_error;
    reg next_write_status_valid;
    reg next_write_status_len;
    reg next_write_status_tag;
    reg next_write_status_id;
    reg next_write_status_dest;
    reg next_write_status_user;
    reg next_write_status_error;
    reg next_write_status_valid;
    reg next_awready;
    reg next_wready;
    reg next_arready;
    reg next_rvalid;
    reg next_rready;
    reg next_bready;
    reg next_bvalid;
    reg next_rlast;
    reg next_wlast;
    reg next_aw