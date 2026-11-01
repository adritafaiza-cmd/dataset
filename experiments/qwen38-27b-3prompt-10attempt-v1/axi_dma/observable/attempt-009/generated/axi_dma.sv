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

    localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AXI_DATA_BYTES_LOG2 = $clog2(AXI_DATA_BYTES);
    localparam AXI_MAX_BURST_LEN_LOG2 = $clog2(AXI_MAX_BURST_LEN);
    localparam AXI_AWLEN_WIDTH = 8;
    localparam AXI_AWLEN_MAX = 255;
    localparam AXI_AWLEN_MIN = 1;
    localparam AXI_AWLEN_MASK = (1 << AXI_AWLEN_WIDTH) - 1;
    localparam AXI_AWLEN_MASK_1 = (1 << (AXI_AWLEN_WIDTH - 1)) - 1;
    localparam AXI_AWLEN_MASK_2 = (1 << (AXI_AWLEN_WIDTH - 2)) - 1;
    localparam AXI_AWLEN_MASK_3 = (1 << (AXI_AWLEN_WIDTH - 3)) - 1;
    localparam AXI_AWLEN_MASK_4 = (1 << (AXI_AWLEN_WIDTH - 4)) - 1;
    localparam AXI_AWLEN_MASK_5 = (1 << (AXI_AWLEN_WIDTH - 5)) - 1;
    localparam AXI_AWLEN_MASK_6 = (1 << (AXI_AWLEN_WIDTH - 6)) - 1;
    localparam AXI_AWLEN_MASK_7 = (1 << (AXI_AWLEN_WIDTH - 7)) - 1;
    localparam AXI_AWLEN_MASK_8 = (1 << (AXI_AWLEN_WIDTH - 8)) - 1;
    localparam AXI_AWLEN_MASK_9 = (1 << (AXI_AWLEN_WIDTH - 9)) - 1;
    localparam AXI_AWLEN_MASK_10 = (1 << (AXI_AWLEN_WIDTH - 10)) - 1;
    localparam AXI_AWLEN_MASK_11 = (1 << (AXI_AWLEN_WIDTH - 11)) - 1;
    localparam AXI_AWLEN_MASK_12 = (1 << (AXI_AWLEN_WIDTH - 12)) - 1;
    localparam AXI_AWLEN_MASK_13 = (1 << (AXI_AWLEN_WIDTH - 13)) - 1;
    localparam AXI_AWLEN_MASK_14 = (1 << (AXI_AWLEN_WIDTH - 14)) - 1;
    localparam AXI_AWLEN_MASK_15 = (1 << (AXI_AWLEN_WIDTH - 15)) - 1;
    localparam AXI_AWLEN_MASK_16 = (1 << (AXI_AWLEN_WIDTH - 16)) - 1;
    localparam AXI_AWLEN_MASK_17 = (1 << (AXI_AWLEN_WIDTH - 17)) - 1;
    localparam AXI_AWLEN_MASK_18 = (1 << (AXI_AWLEN_WIDTH - 18)) - 1;
    localparam AXI_AWLEN_MASK_19 = (1 << (AXI_AWLEN_WIDTH - 19)) - 1;
    localparam AXI_AWLEN_MASK_20 = (1 << (AXI_AWLEN_WIDTH - 20)) - 1;
    localparam AXI_AWLEN_MASK_21 = (1 << (AXI_AWLEN_WIDTH - 21)) - 1;
    localparam AXI_AWLEN_MASK_22 = (1 << (AXI_AWLEN_WIDTH - 22)) - 1;
    localparam AXI_AWLEN_MASK_23 = (1 << (AXI_AWLEN_WIDTH - 23)) - 1;
    localparam AXI_AWLEN_MASK_24 = (1 << (AXI_AWLEN_WIDTH - 24)) - 1;
    localparam AXI_AWLEN_MASK_25 = (1 << (AXI_AWLEN_WIDTH - 25)) - 1;
    localparam AXI_AWLEN_MASK_26 = (1 << (AXI_AWLEN_WIDTH - 26)) - 1;
    localparam AXI_AWLEN_MASK_27 = (1 << (AXI_AWLEN_WIDTH - 27)) - 1;
    localparam AXI_AWLEN_MASK_28 = (1 << (AXI_AWLEN_WIDTH - 28)) - 1;
    localparam AXI_AWLEN_MASK_29 = (1 << (AXI_AWLEN_WIDTH - 29)) - 1;
    localparam AXI_AWLEN_MASK_30 = (1 << (AXI_AWLEN_WIDTH - 30)) - 1;
    localparam AXI_AWLEN_MASK_31 = (1 << (AXI_AWLEN_WIDTH - 31)) - 1;
    localparam AXI_AWLEN_MASK_32 = (1 << (AXI_AWLEN_WIDTH - 32)) - 1;
    localparam AXI_AWLEN_MASK_33 = (1 << (AXI_AWLEN_WIDTH - 33)) - 1;
    localparam AXI_AWLEN_MASK_34 = (1 << (AXI_AWLEN_WIDTH - 34)) - 1;
    localparam AXI_AWLEN_MASK_35 = (1 << (AXI_AWLEN_WIDTH - 35)) - 1;
    localparam AXI_AWLEN_MASK_36 = (1 << (AXI_AWLEN_WIDTH - 36)) - 1;
    localparam AXI_AWLEN_MASK_37 = (1 << (AXI_AWLEN_WIDTH - 37)) - 1;
    localparam AXI_AWLEN_MASK_38 = (1 << (AXI_AWLEN_WIDTH - 38)) - 1;
    localparam AXI_AWLEN_MASK_39 = (1 << (AXI_AWLEN_WIDTH - 39)) - 1;
    localparam AXI_AWLEN_MASK_40 = (1 << (AXI_AWLEN_WIDTH - 40)) - 1;
    localparam AXI_AWLEN_MASK_41 = (1 << (AXI_AWLEN_WIDTH - 41)) - 1;
    localparam AXI_AWLEN_MASK_42 = (1 << (AXI_AWLEN_WIDTH - 42)) - 1;
    localparam AXI_AWLEN_MASK_43 = (1 << (AXI_AWLEN_WIDTH - 43)) - 1;
    localparam AXI_AWLEN_MASK_44 = (1 << (AXI_AWLEN_WIDTH - 44)) - 1;
    localparam AXI_AWLEN_MASK_45 = (1 << (AXI_AWLEN_WIDTH - 45)) - 1;
    localparam AXI_AWLEN_MASK_46 = (1 << (AXI_AWLEN_WIDTH - 46)) - 1;
    localparam AXI_AWLEN_MASK_47 = (1 << (AXI_AWLEN_WIDTH - 47)) - 1;
    localparam AXI_AWLEN_MASK_48 = (1 << (AXI_AWLEN_WIDTH - 48)) - 1;
    localparam AXI_AWLEN_MASK_49 = (1 << (AXI_AWLEN_WIDTH - 49)) - 1;
    localparam AXI_AWLEN_MASK_50 = (1 << (AXI_AWLEN_WIDTH - 50)) - 1;
    localparam AXI_AWLEN_MASK_51 = (1 << (AXI_AWLEN_WIDTH - 51)) - 1;
    localparam AXI_AWLEN_MASK_52 = (1 << (AXI_AWLEN_WIDTH - 52)) - 1;
    localparam AXI_AWLEN_MASK_53 = (1 << (AXI_AWLEN_WIDTH - 53)) - 1;
    localparam AXI_AWLEN_MASK_54 = (1 << (AXI_AWLEN_WIDTH - 54)) - 1;
    localparam AXI_AWLEN_MASK_55 = (1 << (AXI_AWLEN_WIDTH - 55)) - 1;
    localparam AXI_AWLEN_MASK_56 = (1 << (AXI_AWLEN_WIDTH - 56)) - 1;
    localparam AXI_AWLEN_MASK_57 = (1 << (AXI_AWLEN_WIDTH - 57)) - 1;
    localparam AXI_AWLEN_MASK_58 = (1 << (AXI_AWLEN_WIDTH - 58)) - 1;
    localparam AXI_AWLEN_MASK_59 = (1 << (AXI_AWLEN_WIDTH - 59)) - 1;
    localparam AXI_AWLEN_MASK_60 = (1 << (AXI_AWLEN_WIDTH - 60)) - 1;
    localparam AXI_AWLEN_MASK_61 = (1 << (AXI_AWLEN_WIDTH - 61)) - 1;
    localparam AXI_AWLEN_MASK_62 = (1 << (AXI_AWLEN_WIDTH - 62)) - 1;
    localparam AXI_AWLEN_MASK_63 = (1 << (AXI_AWLEN_WIDTH - 63)) - 1;
    localparam AXI_AWLEN_MASK_64 = (1 << (AXI_AWLEN_WIDTH - 64)) - 1;
    localparam AXI_AWLEN_MASK_65 = (1 << (AXI_AWLEN_WIDTH - 65)) - 1;
    localparam AXI_AWLEN_MASK_66 = (1 << (AXI_AWLEN_WIDTH - 66)) - 1;
    localparam AXI_AWLEN_MASK_67 = (1 << (AXI_AWLEN_WIDTH - 67)) - 1;
    localparam AXI_AWLEN_MASK_68 = (1 << (AXI_AWLEN_WIDTH - 68)) - 1;
    localparam AXI_AWLEN_MASK_69 = (1 << (AXI_AWLEN_WIDTH - 69)) - 1;
    localparam AXI_AWLEN_MASK_70 = (1 << (AXI_AWLEN_WIDTH - 70)) - 1;
    localparam AXI_AWLEN_MASK_71 = (1 << (AXI_AWLEN_WIDTH - 71)) - 1;
    localparam AXI_AWLEN_MASK_72 = (1 << (AXI_AWLEN_WIDTH - 72)) - 1;
    localparam AXI_AWLEN_MASK_73 = (1 << (AXI_AWLEN_WIDTH - 73)) - 1;
    localparam AXI_AWLEN_MASK_74 = (1 << (AXI_AWLEN_WIDTH - 74)) - 1;
    localparam AXI_AWLEN_MASK_75 = (1 << (AXI_AWLEN_WIDTH - 75)) - 1;
    localparam AXI_AWLEN_MASK_76 = (1 << (AXI_AWLEN_WIDTH - 76)) - 1;
    localparam AXI_AWLEN_MASK_77 = (1 << (AXI_AWLEN_WIDTH - 77)) - 1;
    localparam AXI_AWLEN_MASK_78 = (1 << (AXI_AWLEN_WIDTH - 78)) - 1;
    localparam AXI_AWLEN_MASK_79 = (1 << (AXI_AWLEN_WIDTH - 79)) - 1;
    localparam AXI_AWLEN_MASK_80 = (1 << (AXI_AWLEN_WIDTH - 80)) - 1;
    localparam AXI_AWLEN_MASK_81 = (1 << (AXI_AWLEN_WIDTH - 81)) - 1;
    localparam AXI_AWLEN_MASK_82 = (1 << (AXI_AWLEN_WIDTH - 82)) - 1;
    localparam AXI_AWLEN_MASK_83 = (1 << (AXI_AWLEN_WIDTH - 83)) - 1;
    localparam AXI_AWLEN_MASK_84 = (1 << (AXI_AWLEN_WIDTH - 84)) - 1;
    localparam AXI_AWLEN_MASK_85 = (1 << (AXI_AWLEN_WIDTH - 85)) - 1;
    localparam AXI_AWLEN_MASK_86 = (1 << (AXI_AWLEN_WIDTH - 86)) - 1;
    localparam AXI_AWLEN_MASK_87 = (1 << (AXI_AWLEN_WIDTH - 87)) - 1;
    localparam AXI_AWLEN_MASK_88 = (1 << (AXI_AWLEN_WIDTH - 88)) - 1;
    localparam AXI_AWLEN_MASK_89 = (1 << (AXI_AWLEN_WIDTH - 89)) - 1;
    localparam AXI_AWLEN_MASK_90 = (1 << (AXI_AWLEN_WIDTH - 90)) - 1;
    localparam AXI_AWLEN_MASK_91 = (1 << (AXI_AWLEN_WIDTH - 91)) - 1;
    localparam AXI_AWLEN_MASK_92 = (1 << (AXI_AWLEN_WIDTH - 92)) - 1;
    localparam AXI_AWLEN_MASK_93 = (1 << (AXI_AWLEN_WIDTH - 93)) - 1;
    localparam AXI_AWLEN_MASK_94 = (1 << (AXI_AWLEN_WIDTH - 94)) - 1;
    localparam AXI_AWLEN_MASK_95 = (1 << (AXI_AWLEN_WIDTH - 95)) - 1;
    localparam AXI_AWLEN_MASK_96 = (1 << (AXI_AWLEN_WIDTH - 96)) - 1;
    localparam AXI_AWLEN_MASK_97 = (1 << (AXI_AWLEN_WIDTH - 97)) - 1;
    localparam AXI_AWLEN_MASK_98 = (1 << (AXI_AWLEN_WIDTH - 98)) - 1;
    localparam AXI_AWLEN_MASK_99 = (1 << (AXI_AWLEN_WIDTH - 99)) - 1;
    localparam AXI_AWLEN_MASK_100 = (1 << (AXI_AWLEN_WIDTH - 100)) - 1;
    localparam AXI_AWLEN_MASK_101 = (1 << (AXI_AWLEN_WIDTH - 101)) - 1;
    localparam AXI_AWLEN_MASK_102 = (1 << (AXI_AWLEN_WIDTH - 102)) - 1;
    localparam AXI_AWLEN_MASK_103 = (1 << (AXI_AWLEN_WIDTH - 103)) - 1;
    localparam AXI_AWLEN_MASK_104 = (1 << (AXI_AWLEN_WIDTH - 104)) - 1;
    localparam AXI_AWLEN_MASK_105 = (1 << (AXI_AWLEN_WIDTH - 105)) - 1;
    localparam AXI_AWLEN_MASK_106 = (1 << (AXI_AWLEN_WIDTH - 106)) - 1;
    localparam AXI_AWLEN_MASK_107 = (1 << (AXI_AWLEN_WIDTH - 107)) - 1;
    localparam AXI_AWLEN_MASK_108 = (1 << (AXI_AWLEN_WIDTH - 108)) - 1;
    localparam AXI_AWLEN_MASK_109 = (1 << (AXI_AWLEN_WIDTH - 109)) - 1;
    localparam AXI_AWLEN_MASK_110 = (1 << (AXI_AWLEN_WIDTH - 110)) - 1;
    localparam AXI_AWLEN_MASK_111 = (1 << (AXI_AWLEN_WIDTH - 111)) - 1;
    localparam AXI_AWLEN_MASK_112 = (1 << (AXI_AWLEN_WIDTH - 112)) - 1;
    localparam AXI_AWLEN_MASK_113 = (1 << (AXI_AWLEN_WIDTH - 113)) - 1;
    localparam AXI_AWLEN_MASK_114 = (1 << (AXI_AWLEN_WIDTH - 114)) - 1;
    localparam AXI_AWLEN_MASK_115 = (1 << (AXI_AWLEN_WIDTH - 115)) - 1;
    localparam AXI_AWLEN_MASK_116 = (1 << (AXI_AWLEN_WIDTH - 116)) - 1;
    localparam AXI_AWLEN_MASK_117 = (1 << (AXI_AWLEN_WIDTH - 117)) - 1;
    localparam AXI_AWLEN_MASK_118 = (1 << (AXI_AWLEN_WIDTH - 118)) - 1;
    localparam AXI_AWLEN_MASK_119 = (1 << (AXI_AWLEN_WIDTH - 119)) - 1;
    localparam AXI_AWLEN_MASK_120 = (1 << (AXI_AWLEN_WIDTH - 120)) - 1;
    localparam AXI_AWLEN_MASK_121 = (1 << (AXI_AWLEN_WIDTH - 121)) - 1;
    localparam AXI_AWLEN_MASK_122 = (1 << (AXI_AWLEN_WIDTH - 122)) - 1;
    localparam AXI_AWLEN_MASK_123 = (1 << (AXI_AWLEN_WIDTH - 123)) - 1;
    localparam AXI_AWLEN_MASK_124 = (1 << (AXI_AWLEN_WIDTH - 124)) - 1;
    localparam AXI_AWLEN_MASK_125 = (1 << (AXI_AWLEN_WIDTH - 125)) - 1;
    localparam AXI_AWLEN_MASK_126 = (1 << (AXI_AWLEN_WIDTH - 126)) - 1;
    localparam AXI_AWLEN_MASK_127 = (1 << (AXI_AWLEN_WIDTH - 127)) - 1;
    localparam AXI_AWLEN_MASK_128 = (1 << (AXI_AWLEN_WIDTH - 128)) - 1;
    localparam AXI_AWLEN_MASK_129 = (1 << (AXI_AWLEN_WIDTH - 129)) - 1;
    localparam AXI_AWLEN_MASK_130 = (1 << (AXI_AWLEN_WIDTH - 130)) - 1;
    localparam AXI_AWLEN_MASK_131 = (1 << (AXI_AWLEN_WIDTH - 131)) - 1;
    localparam AXI_AWLEN_MASK_132 = (1 << (AXI_AWLEN_WIDTH - 132)) - 1;
    localparam AXI_AWLEN_MASK_133 = (1 << (AXI_AWLEN_WIDTH - 133)) - 1;
    localparam AXI_AWLEN_MASK_134 = (1 << (AXI_AWLEN_WIDTH - 134)) - 1;
    localparam AXI_AWLEN_MASK_135 = (1 << (AXI_AWLEN_WIDTH - 135)) - 1;
    localparam AXI_AWLEN_MASK_136 = (1 << (AXI_AWLEN_WIDTH - 136)) - 1;
    localparam AXI_AWLEN_MASK_137 = (1 << (AXI_AWLEN_WIDTH - 137)) - 1;
    localparam AXI_AWLEN_MASK_138 = (1 << (AXI_AWLEN_WIDTH - 138)) - 1;
    localparam AXI_AWLEN_MASK_139 = (1 << (AXI_AWLEN_WIDTH - 139)) - 1;
    localparam AXI_AWLEN_MASK_140 = (1 << (AXI_AWLEN_WIDTH - 140)) - 1;
    localparam AXI_AWLEN_MASK_141 = (1 << (AXI_AWLEN_WIDTH - 141)) - 1;
    localparam AXI_AWLEN_MASK_142 = (1 << (AXI_AWLEN_WIDTH - 142)) - 1;
    localparam AXI_AWLEN_MASK_143 = (1 << (AXI_AWLEN_WIDTH - 143)) - 1;
    localparam AXI_AWLEN_MASK_144 = (1 << (AXI_AWLEN_WIDTH - 144)) - 1;
    localparam AXI_AWLEN_MASK_145 = (1 << (AXI_AWLEN_WIDTH - 145)) - 1;
    localparam AXI_AWLEN_MASK_146 = (1 << (AXI_AWLEN_WIDTH - 146)) - 1;
    localparam AXI_AWLEN_MASK_147 = (1 << (AXI_AWLEN_WIDTH - 147)) - 1;
    localparam AXI_AWLEN_MASK_148 = (1 << (AXI_AWLEN_WIDTH - 148)) - 1;
    localparam AXI_AWLEN_MASK_149 = (1 << (AXI_AWLEN_WIDTH - 149)) - 1;
    localparam AXI_AWLEN_MASK_150 = (1 << (AXI_AWLEN_WIDTH - 150)) - 1;
    localparam AXI_AWLEN_MASK_151 = (1 << (AXI_AWLEN_WIDTH - 151)) - 1;
    localparam AXI_AWLEN_MASK_152 = (1 << (AXI_AWLEN_WIDTH - 152)) - 1;
    localparam AXI_AWLEN_MASK_153 = (1 << (AXI_AWLEN_WIDTH - 153)) - 1;
    localparam AXI_AWLEN_MASK_154 = (1 << (AXI_AWLEN_WIDTH - 154)) - 1;
    localparam AXI_AWLEN_MASK_155 = (1 << (AXI_AWLEN_WIDTH - 155)) - 1;
    localparam AXI_AWLEN_MASK_156 = (1 << (AXI_AWLEN_WIDTH - 156)) - 1;
    localparam AXI_AWLEN_MASK_157 = (1 << (AXI_AWLEN_WIDTH - 157)) - 1;
    localparam AXI_AWLEN_MASK_158 = (1 << (AXI_AWLEN_WIDTH - 158)) - 1;
    localparam AXI_AWLEN_MASK_159 = (1 << (AXI_AWLEN_WIDTH - 159)) - 1;
    localparam AXI_AWLEN_MASK_160 = (1 << (AXI_AWLEN_WIDTH - 160)) - 1;
    localparam AXI_AWLEN_MASK_161 = (1 << (AXI_AWLEN_WIDTH - 161)) - 1;
    localparam AXI_AWLEN_MASK_162 = (1 << (AXI_AWLEN_WIDTH - 162)) - 1;
    localparam AXI_AWLEN_MASK_163 = (1 << (AXI_AWLEN_WIDTH - 163)) - 1;
    localparam AXI_AWLEN_MASK_164 = (1 << (AXI_AWLEN_WIDTH - 164)) - 1;
    localparam AXI_AWLEN_MASK_165 = (1 << (AXI_AWLEN_WIDTH - 165)) - 1;
    localparam AXI_AWLEN_MASK_166 = (1 << (AXI_AWLEN_WIDTH - 166)) - 1;
    localparam AXI_AWLEN_MASK_167 = (1 << (AXI_AWLEN_WIDTH - 167)) - 1;
    localparam AXI_AWLEN_MASK_168 = (1 << (AXI_AWLEN_WIDTH - 168)) - 1;
    localparam AXI_AWLEN_MASK_169 = (1 << (AXI_AWLEN_WIDTH - 169)) - 1;
    localparam AXI_AWLEN_MASK_170 = (1 << (AXI_AWLEN_WIDTH - 170)) - 1;
    localparam AXI_AWLEN_MASK_171 = (1 << (AXI_AWLEN_WIDTH - 171)) - 1;
    localparam AXI_AWLEN_MASK_172 = (1 << (AXI_AWLEN_WIDTH - 172)) - 1;
    localparam AXI_AWLEN_MASK_173 = (1 << (AXI_AWLEN_WIDTH - 173)) - 1;
    localparam AXI_AWLEN_MASK_174 = (1 << (AXI_AWLEN_WIDTH - 174)) - 1;
    localparam AXI_AWLEN_MASK_175 = (1 << (AXI_AWLEN_WIDTH - 175)) - 1;
    localparam AXI_AWLEN_MASK_176 = (1 << (AXI_AWLEN_WIDTH - 176)) - 1;
    localparam AXI_AWLEN_MASK_177 = (1 << (AXI_AWLEN_WIDTH - 177)) - 1;
    localparam AXI_AWLEN_MASK_178 = (1 << (AXI_AWLEN_WIDTH - 178)) - 1;
    localparam AXI_AWLEN_MASK_179 = (1 << (AXI_AWLEN_WIDTH - 179)) - 1;
    localparam AXI_AWLEN_MASK_180 = (1 << (AXI_AWLEN_WIDTH - 180)) - 1;
    localparam AXI_AWLEN_MASK_181 = (1 << (AXI_AWLEN_WIDTH - 181)) - 1;
    localparam AXI_AWLEN_MASK_182 = (1 << (AXI_AWLEN_WIDTH - 182)) - 1;
    localparam AXI_AWLEN_MASK_183 = (1 << (AXI_AWLEN_WIDTH - 183)) - 1;
    localparam AXI_AWLEN_MASK_184 = (1 << (AXI_AWLEN_WIDTH - 184)) - 1;
    localparam AXI_AWLEN_MASK_185 = (1 << (AXI_AWLEN_WIDTH - 185)) - 1;
    localparam AXI_AWLEN_MASK_186 = (1 << (AXI_AWLEN_WIDTH - 186)) - 1;
    localparam AXI_AWLEN_MASK_187 = (1 << (AXI_AWLEN_WIDTH - 187)) - 1;
    localparam AXI_AWLEN_MASK_188 = (1 << (AXI_AWLEN_WIDTH - 188)) - 1;
    localparam AXI_AWLEN_MASK_189 = (1 << (AXI_AWLEN_WIDTH - 189)) - 1;
    localparam AXI_AWLEN_MASK_190 = (1