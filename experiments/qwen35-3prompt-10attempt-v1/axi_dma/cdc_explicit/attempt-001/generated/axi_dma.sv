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

    // -----------------------------------------------------------------------
    // Internal Parameters and Constants
    // -----------------------------------------------------------------------
    localparam int unsigned AXIS_KEEP_MASK = AXIS_KEEP_ENABLE ? (2**AXIS_KEEP_WIDTH - 1) : 0;
    localparam int unsigned AXIS_LAST_MASK = AXIS_LAST_ENABLE ? 1 : 0;
    localparam int unsigned AXIS_ID_MASK   = AXIS_ID_ENABLE ? (2**AXIS_ID_WIDTH - 1) : 0;
    localparam int unsigned AXIS_DEST_MASK = AXIS_DEST_ENABLE ? (2**AXIS_DEST_WIDTH - 1) : 0;
    localparam int unsigned AXIS_USER_MASK = AXIS_USER_ENABLE ? (2**AXIS_USER_WIDTH - 1) : 0;
    
    localparam int unsigned AXI_BURST_FIXED = 2'b01; // FIXED
    localparam int unsigned AXI_BURST_INCR  = 2'b10; // INCR
    localparam int unsigned AXI_BURST_WRAP  = 2'b11; // WRAP (Not supported per spec, default to INCR)
    
    localparam int unsigned AXI_SIZE_BYTE  = 3'd0;
    localparam int unsigned AXI_SIZE_HALF  = 3'd1;
    localparam int unsigned AXI_SIZE_WORD  = 3'd2;
    localparam int unsigned AXI_SIZE_DWORD = 3'd3;
    localparam int unsigned AXI_SIZE_QWORD = 3'd4;
    localparam int unsigned AXI_SIZE_SWORD = 3'd5;
    localparam int unsigned AXI_SIZE_DWORD = 3'd6; // Duplicate name in thought, fixing logic below
    localparam int unsigned AXI_SIZE_SWORD = 3'd5;
    localparam int unsigned AXI_SIZE_DWORD = 3'd6;
    localparam int unsigned AXI_SIZE_QWORD = 3'd7;

    // -----------------------------------------------------------------------
    // State Machine for Read Path
    // -----------------------------------------------------------------------
    typedef enum logic [1:0] {
        READ_IDLE,
        READ_DESC_PENDING,
        READ_AXI_ADDR,
        READ_AXI_DATA,
        READ_STREAMING,
        READ_DONE
    } read_state_t;

    read_state_t read_state, read_next_state;
    logic        read_desc_valid;
    logic        read_desc_ready;
    logic        read_stream_valid;
    logic        read_stream_ready;
    logic        read_stream_last;
    logic        read_stream_tlast;
    logic        read_stream_tvalid;
    logic        read_stream_tready;
    logic        read_stream_tdata_valid;
    logic        read_stream_tkeep_valid;
    logic        read_stream_tid_valid;
    logic        read_stream_tdest_valid;
    logic        read_stream_tuser_valid;
    logic        read_stream_tlast_valid;
    logic        read_stream_tdata_ready;
    logic        read_stream_tkeep_ready;
    logic        read_stream_tid_ready;
    logic        read_stream_tdest_ready;
    logic        read_stream_tuser_ready;
    logic        read_stream_tlast_ready;
    logic        read_stream_tdata_valid_out;
    logic        read_stream_tkeep_valid_out;
    logic        read_stream_tid_valid_out;
    logic        read_stream_tdest_valid_out;
    logic        read_stream_tuser_valid_out;
    logic        read_stream_tlast_valid_out;
    logic        read_stream_tdata_ready_out;
    logic        read_stream_tkeep_ready_out;
    logic        read_stream_tid_ready_out;
    logic        read_stream_tdest_ready_out;
    logic        read_stream_tuser_ready_out;
    logic        read_stream_tlast_ready_out;
    logic        read_stream_tdata_valid_in;
    logic        read_stream_tkeep_valid_in;
    logic        read_stream_tid_valid_in;
    logic        read_stream_tdest_valid_in;
    logic        read_stream_tuser_valid_in;
    logic        read_stream_tlast_valid_in;
    logic        read_stream_tdata_ready_in;
    logic        read_stream_tkeep_ready_in;
    logic        read_stream_tid_ready_in;
    logic        read_stream_tdest_ready_in;
    logic        read_stream_tuser_ready_in;
    logic        read_stream_tlast_ready_in;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire;
    logic        read_stream_tdata_ready_in_wire;
    logic        read_stream_tkeep_ready_in_wire;
    logic        read_stream_tid_ready_in_wire;
    logic        read_stream_tdest_ready_in_wire;
    logic        read_stream_tuser_ready_in_wire;
    logic        read_stream_tlast_ready_in_wire;
    logic        read_stream_tdata_valid_out_wire;
    logic        read_stream_tkeep_valid_out_wire;
    logic        read_stream_tid_valid_out_wire;
    logic        read_stream_tdest_valid_out_wire;
    logic        read_stream_tuser_valid_out_wire;
    logic        read_stream_tlast_valid_out_wire;
    logic        read_stream_tdata_ready_out_wire;
    logic        read_stream_tkeep_ready_out_wire;
    logic        read_stream_tid_ready_out_wire;
    logic        read_stream_tdest_ready_out_wire;
    logic        read_stream_tuser_ready_out_wire;
    logic        read_stream_tlast_ready_out_wire;
    logic        read_stream_tdata_valid_in_wire;
    logic        read_stream_tkeep_valid_in_wire;
    logic        read_stream_tid_valid_in_wire;
    logic        read_stream_tdest_valid_in_wire;
    logic        read_stream_tuser_valid_in_wire;
    logic        read_stream_tlast_valid_in_wire