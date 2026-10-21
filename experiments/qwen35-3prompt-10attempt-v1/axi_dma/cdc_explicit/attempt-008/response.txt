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

    // ------------------------------------------------------------------------
    // Internal Parameters and Constants
    // ------------------------------------------------------------------------
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_DATA_WIDTH    = $clog2(AXI_DATA_WIDTH);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);
    
    // Burst types: 0=FIXED, 1=INCR, 2=WRAP, 3=UNORDERED
    localparam BURST_FIXED = 2'b00;
    localparam BURST_INCR  = 2'b01;
    localparam BURST_WRAP  = 2'b10;
    
    // Protocols: 0=NONE, 1=SECURE, 2=ENCRYPTED, 3=SECURE+ENCRYPTED
    localparam PROT_NONE = 3'b000;
    localparam PROT_SECURE = 3'b001;
    localparam PROT_ENCRYPTED = 3'b010;
    localparam PROT_SECURE_ENCRYPTED = 3'b011;

    // ------------------------------------------------------------------------
    // CDC Registers (Synchronous to clk)
    // ------------------------------------------------------------------------
    wire rst_n = ~rst;
    
    // Read Descriptor Input
    reg s_axis_read_desc_valid_reg;
    reg s_axis_read_desc_addr_reg;
    reg s_axis_read_desc_len_reg;
    reg s_axis_read_desc_tag_reg;
    reg s_axis_read_desc_id_reg;
    reg s_axis_read_desc_dest_reg;
    reg s_axis_read_desc_user_reg;
    reg s_axis_read_desc_ready_reg;
    
    // Read Descriptor Status Output
    reg m_axis_read_desc_status_tag_reg;
    reg m_axis_read_desc_status_error_reg;
    reg m_axis_read_desc_status_valid_reg;
    
    // Read Data Output
    reg m_axis_read_data_tdata_reg;
    reg m_axis_read_data_tkeep_reg;
    reg m_axis_read_data_tvalid_reg;
    reg m_axis_read_data_tlast_reg;
    reg m_axis_read_data_tid_reg;
    reg m_axis_read_data_tdest_reg;
    reg m_axis_read_data_tuser_reg;
    
    // Write Descriptor Input
    reg s_axis_write_desc_valid_reg;
    reg s_axis_write_desc_addr_reg;
    reg s_axis_write_desc_len_reg;
    reg s_axis_write_desc_tag_reg;
    reg s_axis_write_desc_ready_reg;
    
    // Write Descriptor Status Output
    reg m_axis_write_desc_status_len_reg;
    reg m_axis_write_desc_status_tag_reg;
    reg m_axis_write_desc_status_id_reg;
    reg m_axis_write_desc_status_dest_reg;
    reg m_axis_write_desc_status_user_reg;
    reg m_axis_write_desc_status_error_reg;
    reg m_axis_write_desc_status_valid_reg;
    
    // Write Data Input
    reg s_axis_write_data_tvalid_reg;
    reg s_axis_write_data_tdata_reg;
    reg s_axis_write_data_tkeep_reg;
    reg s_axis_write_data_tlast_reg;
    reg s_axis_write_data_tid_reg;
    reg s_axis_write_data_tdest_reg;
    reg s_axis_write_data_tuser_reg;
    reg s_axis_write_data_tready_reg;

    // ------------------------------------------------------------------------
    // AXI Master State Machine
    // ------------------------------------------------------------------------
    // States: IDLE, AW_SEND, AW_WAIT, W_SEND, W_WAIT, B_WAIT, AR_SEND, AR_WAIT, R_WAIT
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_AW_SEND,
        STATE_AW_WAIT,
        STATE_W_SEND,
        STATE_W_WAIT,
        STATE_B_WAIT,
        STATE_AR_SEND,
        STATE_AR_WAIT,
        STATE_R_WAIT
    } state_t;

    state_t state, next_state;
    logic [2:0] state_next;
    
    // AXI Transaction Context
    logic [AXI_ID_WIDTH-1:0] axi_id;
    logic [AXI_ADDR_WIDTH-1:0] axi_addr;
    logic [LEN_WIDTH-1:0] axi_len;
    logic [2:0] axi_size;
    logic [1:0] axi_burst;
    logic [2:0] axi_prot;
    logic axi_wlast;
    logic axi_arlast;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;
    logic axi_rready_reg;
    logic axi_bresp_reg;
    logic axi_rresp_reg;
    logic axi_rlast_reg;
    logic axi_bid_reg;
    logic axi_rid_reg;
    logic axi_awid_reg;
    logic axi_arid_reg;
    logic axi_awaddr_reg;
    logic axi_araddr_reg;
    logic axi_awlen_reg;
    logic axi_arlen_reg;
    logic axi_awsize_reg;
    logic axi_arsize_reg;
    logic axi_awlock_reg;
    logic axi_arlock_reg;
    logic axi_awcache_reg;
    logic axi_arcache_reg;
    logic axi_awprot_reg;
    logic axi_arprot_reg;
    logic axi_awvalid_reg;
    logic axi_wvalid_reg;
    logic axi_arvalid_reg;
    logic axi_bvalid_reg;
    logic axi_rvalid_reg;
    logic axi_awready_reg;
    logic axi_wready_reg;
    logic axi_arready_reg;
    logic axi_bready_reg;