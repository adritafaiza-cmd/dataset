```verilog
`timescale 1ns/1ps

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
    localparam AXIS_KEEP_WIDTH_LOG = $clog2(AXIS_KEEP_WIDTH + 1);
    localparam AXIS_USER_WIDTH_LOG = $clog2(AXIS_USER_WIDTH + 1);
    localparam AXIS_DEST_WIDTH_LOG = $clog2(AXIS_DEST_WIDTH + 1);
    localparam AXIS_ID_WIDTH_LOG   = $clog2(AXIS_ID_WIDTH + 1);
    localparam AXI_STRB_WIDTH_LOG  = $clog2(AXI_STRB_WIDTH + 1);
    localparam AXI_ADDR_WIDTH_LOG  = $clog2(AXI_ADDR_WIDTH + 1);
    localparam AXI_ID_WIDTH_LOG    = $clog2(AXI_ID_WIDTH + 1);
    localparam LEN_WIDTH_LOG       = $clog2(LEN_WIDTH + 1);

    // State Machine States
    localparam IDLE = 2'd0;
    localparam READ_DESC = 2'd1;
    localparam WRITE_DESC = 2'd2;
    localparam READ_STREAM = 2'd3;
    localparam WRITE_STREAM = 2'd4;
    localparam READ_STREAM_DONE = 2'd5;
    localparam WRITE_STREAM_DONE = 2'd6;
    localparam ERROR = 2'd7;

    // Internal Registers
    reg [1:0] state;
    reg [LEN_WIDTH-1:0] remaining_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [AXIS_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [AXI_ID_WIDTH-1:0] axi_id;
    reg [AXI_ADDR_WIDTH-1:0] axi_addr;
    reg [7:0] axi_len;
    reg [2:0] axi_size;
    reg [1:0] axi_burst;
    reg [3:0] axi_cache;
    reg [2:0] axi_prot;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_reg;
    reg rlast_reg;
    reg [AXI_ID_WIDTH-1:0] rid_reg;
    reg [1:0] bresp_reg;
    reg [AXI_DATA_WIDTH-1:0] rdata_valid_reg;
    reg rdata_valid_reg_en;
    reg [AXI_ID_WIDTH-1:0] bid_reg;
    reg [1:0] bresp_valid_reg;
    reg [AXI_DATA_WIDTH-1:0] wdata_valid_reg;
    reg wdata_valid_reg_en;
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg awvalid_reg;
    reg arvalid_reg;
    reg wvalid_reg;
    reg bready_reg;
    reg rready_reg;
    reg [3:0] error_code;
    reg [LEN_WIDTH-1:0] total_len;
    reg [LEN_WIDTH-1:0] desc_len;
    reg [TAG_WIDTH-1:0] desc_tag;
    reg [AXIS_ID_WIDTH-1:0] desc_id;
    reg [AXIS_DEST_WIDTH-1:0] desc_dest;
    reg [AXIS_USER_WIDTH-1:0] desc_user;
    reg read_desc_valid_reg;
    reg write_desc_valid_reg;
    reg write_abort_reg;
    reg stream_read_valid_reg;
    reg stream_write_valid_reg;
    reg stream_write_last_reg;
    reg stream_write_tid_reg;
    reg stream_write_dest_reg;
    reg stream_write_user_reg;
    reg stream_write_keep_reg;
    reg stream_write_data_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream_write_data_dest_reg;
    reg stream_write_data_user_reg;
    reg stream_write_data_keep_reg;
    reg stream_write_data_valid_reg;
    reg stream_write_data_ready_reg;
    reg stream_write_data_last_reg;
    reg stream_write_data_tid_reg;
    reg stream