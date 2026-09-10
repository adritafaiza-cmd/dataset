Please act as a professional Verilog designer.

Implement a single-clock AXI DMA engine.

Module name:
    axi_dma

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rst: active-high.

Input ports:
    clk: Clock.
    rst: Active-high reset.
    s_axis_read_desc_addr: Address.
    s_axis_read_desc_len: See Behavior.
    s_axis_read_desc_tag: See Behavior.
    s_axis_read_desc_id: See Behavior.
    s_axis_read_desc_dest: See Behavior.
    s_axis_read_desc_user: See Behavior.
    s_axis_read_desc_valid: Handshake valid.
    m_axis_read_data_tready: Handshake ready.
    s_axis_write_desc_addr: Address.
    s_axis_write_desc_len: See Behavior.
    s_axis_write_desc_tag: See Behavior.
    s_axis_write_desc_valid: Handshake valid.
    s_axis_write_data_tdata: Data payload.
    s_axis_write_data_tkeep: Data payload.
    s_axis_write_data_tvalid: Handshake valid.
    s_axis_write_data_tlast: Data payload.
    s_axis_write_data_tid: Data payload.
    s_axis_write_data_tdest: Data payload.
    s_axis_write_data_tuser: Data payload.
    m_axi_awready: Handshake ready.
    m_axi_wready: Handshake ready.
    m_axi_bid: See Behavior.
    m_axi_bresp: Response status.
    m_axi_bvalid: Handshake valid.
    m_axi_arready: Handshake ready.
    m_axi_rid: See Behavior.
    m_axi_rdata: Data payload.
    m_axi_rresp: Response status.
    m_axi_rlast: See Behavior.
    m_axi_rvalid: Handshake valid.
    read_enable: See Behavior.
    write_enable: See Behavior.
    write_abort: See Behavior.

Output ports:
    s_axis_read_desc_ready: Handshake ready.
    m_axis_read_desc_status_tag: See Behavior.
    m_axis_read_desc_status_error: See Behavior.
    m_axis_read_desc_status_valid: Handshake valid.
    m_axis_read_data_tdata: Data payload.
    m_axis_read_data_tkeep: Data payload.
    m_axis_read_data_tvalid: Handshake valid.
    m_axis_read_data_tlast: Data payload.
    m_axis_read_data_tid: Data payload.
    m_axis_read_data_tdest: Data payload.
    m_axis_read_data_tuser: Data payload.
    s_axis_write_desc_ready: Handshake ready.
    m_axis_write_desc_status_len: See Behavior.
    m_axis_write_desc_status_tag: See Behavior.
    m_axis_write_desc_status_id: See Behavior.
    m_axis_write_desc_status_dest: See Behavior.
    m_axis_write_desc_status_user: See Behavior.
    m_axis_write_desc_status_error: See Behavior.
    m_axis_write_desc_status_valid: Handshake valid.
    s_axis_write_data_tready: Handshake ready.
    m_axi_awid: See Behavior.
    m_axi_awaddr: Address.
    m_axi_awlen: See Behavior.
    m_axi_awsize: See Behavior.
    m_axi_awburst: Reset reset.
    m_axi_awlock: See Behavior.
    m_axi_awcache: See Behavior.
    m_axi_awprot: Protection bits.
    m_axi_awvalid: Handshake valid.
    m_axi_wdata: Data payload.
    m_axi_wstrb: Write strobes.
    m_axi_wlast: See Behavior.
    m_axi_wvalid: Handshake valid.
    m_axi_bready: Handshake ready.
    m_axi_arid: See Behavior.
    m_axi_araddr: Address.
    m_axi_arlen: See Behavior.
    m_axi_arsize: See Behavior.
    m_axi_arburst: Reset reset.
    m_axi_arlock: See Behavior.
    m_axi_arcache: See Behavior.
    m_axi_arprot: Protection bits.
    m_axi_arvalid: Handshake valid.
    m_axi_rready: Handshake ready.

Parameters:
    AXI_DATA_WIDTH: See Behavior.
    AXI_ADDR_WIDTH: See Behavior.
    AXI_STRB_WIDTH: See Behavior.
    AXI_ID_WIDTH: See Behavior.
    AXI_MAX_BURST_LEN: See Behavior.
    AXIS_DATA_WIDTH: See Behavior.
    AXIS_KEEP_ENABLE: See Behavior.
    AXIS_KEEP_WIDTH: See Behavior.
    AXIS_LAST_ENABLE: See Behavior.
    AXIS_ID_ENABLE: See Behavior.
    AXIS_ID_WIDTH: See Behavior.
    AXIS_DEST_ENABLE: See Behavior.
    AXIS_DEST_WIDTH: See Behavior.
    AXIS_USER_ENABLE: See Behavior.
    AXIS_USER_WIDTH: See Behavior.
    LEN_WIDTH: See Behavior.
    TAG_WIDTH: See Behavior.
    ENABLE_SG: See Behavior.
    ENABLE_UNALIGNED: See Behavior.

Behavior:
    - Accept read and write descriptors on the AXIS descriptor inputs.
    - Perform AXI memory reads/writes and stream data on the AXI-Stream data ports.
    - Return descriptor status with the original tag.
    - Honor LEN_WIDTH, AXI_MAX_BURST_LEN, and the AXIS sideband enables.
    - After reset all interfaces are idle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
