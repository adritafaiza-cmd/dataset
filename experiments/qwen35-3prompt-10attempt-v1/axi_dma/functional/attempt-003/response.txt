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
    localparam IDLE = 2'd0;
    localparam AW_PREPARE = 2'd1;
    localparam AW_SEND = 2'd2;
    localparam W_PREPARE = 2'd3;
    localparam W_SEND = 2'd4;
    localparam B_WAIT = 2'd5;
    localparam AR_PREPARE = 2'd6;
    localparam AR_SEND = 2'd7;
    localparam R_PREPARE = 2'd8;
    localparam R_WAIT = 2'd9;
    localparam R_DONE = 2'd10;
    localparam WRITE_ABORT = 2'd11;

    // State Register
    reg [1:0] state;
    reg [TAG_WIDTH-1:0] tag;
    reg [LEN_WIDTH-1:0] len;
    reg [AXI_ADDR_WIDTH-1:0] addr;
    reg [AXIS_ID_WIDTH-1:0] sid;
    reg [AXIS_DEST_WIDTH-1:0] sdest;
    reg [AXIS_USER_WIDTH-1:0] suser;
    reg [AXI_ID_WIDTH-1:0] axi_id;
    reg [7:0] axi_len;
    reg [2:0] axi_size;
    reg [1:0] axi_burst;
    reg [3:0] axi_cache;
    reg [2:0] axi_prot;
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    reg wready_reg;
    reg wdata_valid_reg;
    reg wdata_last_reg;
    reg wdata_keep_reg;
    reg [AXI_ID_WIDTH-1:0] wdata_tid_reg;
    reg [AXIS_DEST_WIDTH-1:0] wdata_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] wdata_user_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    reg arready_reg;
    reg ardata_valid_reg;
    reg ardata_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_reg;
    reg [1:0] arresp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_reg;
    reg [7:0] arlen_out_reg;
    reg [2:0] arsize_out_reg;
    reg [1:0] arburst_out_reg;
    reg [3:0] arcache_out_reg;
    reg [2:0] arprot_out_reg;
    reg arvalid_out_reg;
    reg arready_out_reg;
    reg ardata_out_valid_reg;
    reg ardata_out_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_reg;
    reg [1:0] arresp_out_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_reg;
    reg [7:0] arlen_out_len_reg;
    reg [2:0] arsize_out_size_reg;
    reg [1:0] arburst_out_burst_reg;
    reg [3:0] arcache_out_cache_reg;
    reg [2:0] arprot_out_prot_reg;
    reg arvalid_out_valid_reg;
    reg arready_out_ready_reg;
    reg ardata_out_data_valid_reg;
    reg ardata_out_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_reg;
    reg [1:0] arresp_out_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_reg;
    reg [7:0] arlen_out_len_len_reg;
    reg [2:0] arsize_out_size_size_reg;
    reg [1:0] arburst_out_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_reg;
    reg arvalid_out_valid_valid_reg;
    reg arready_out_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_reg;
    reg [1:0] arresp_out_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_reg;
    reg ardata_out_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_data_last_reg;
    reg [AXI_DATA_WIDTH-1:0] ardata_out_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_data_reg;
    reg [1:0] arresp_out_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_resp_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ID_WIDTH-1:0] arid_out_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_id_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_out_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_addr_reg;
    reg [7:0] arlen_out_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_len_reg;
    reg [2:0] arsize_out_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_size_reg;
    reg [1:0] arburst_out_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_burst_reg;
    reg [3:0] arcache_out_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_cache_reg;
    reg [2:0] arprot_out_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_prot_reg;
    reg arvalid_out_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_valid_reg;
    reg arready_out_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_ready_reg;
    reg ardata_out_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid_data_valid