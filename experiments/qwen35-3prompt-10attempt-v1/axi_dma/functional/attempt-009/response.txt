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
    localparam LOG2_AXIS_KEEP_WIDTH   = $clog2(AXIS_KEEP_WIDTH);

    // State Enums
    typedef enum logic [1:0] {
        IDLE,
        AW_PREPARE,
        AW_SEND,
        AW_WAIT_B,
        AR_PREPARE,
        AR_SEND,
        AR_WAIT_R,
        WR_PREPARE,
        WR_SEND,
        WR_WAIT_B,
        WR_COMPLETE
    } state_t;

    // Internal Signals
    state_t current_state, next_state;
    
    // Read Descriptor State
    logic read_desc_valid;
    logic read_desc_ready;
    logic read_desc_done;
    logic read_desc_error;
    logic read_desc_last;
    logic [LEN_WIDTH-1:0] read_desc_len;
    logic [AXI_ADDR_WIDTH-1:0] read_desc_addr;
    logic [TAG_WIDTH-1:0] read_desc_tag;
    logic [AXIS_ID_WIDTH-1:0] read_desc_id;
    logic [AXIS_DEST_WIDTH-1:0] read_desc_dest;
    logic [AXIS_USER_WIDTH-1:0] read_desc_user;
    logic [7:0] read_desc_burst_len; // AXI burst length
    logic [2:0] read_desc_burst_size;
    logic [1:0] read_desc_burst_type;
    logic [LEN_WIDTH-1:0] read_desc_remaining_len;
    logic [AXI_ADDR_WIDTH-1:0] read_desc_current_addr;
    logic [AXI_DATA_WIDTH-1:0] read_desc_current_data;
    logic [AXIS_ID_WIDTH-1:0] read_desc_current_tid;
    logic [AXIS_DEST_WIDTH-1:0] read_desc_current_tdest;
    logic [AXIS_USER_WIDTH-1:0] read_desc_current_tuser;
    logic read_desc_current_tlast;
    logic read_desc_current_tvalid;
    logic read_desc_current_tready;
    logic read_desc_current_tkeep;

    // Write Descriptor State
    logic write_desc_valid;
    logic write_desc_ready;
    logic write_desc_done;
    logic write_desc_error;
    logic write_desc_last;
    logic [LEN_WIDTH-1:0] write_desc_len;
    logic [AXI_ADDR_WIDTH-1:0] write_desc_addr;
    logic [TAG_WIDTH-1:0] write_desc_tag;
    logic [AXIS_ID_WIDTH-1:0] write_desc_id;
    logic [AXIS_DEST_WIDTH-1:0] write_desc_dest;
    logic [AXIS_USER_WIDTH-1:0] write_desc_user;
    logic [7:0] write_desc_burst_len;
    logic [2:0] write_desc_burst_size;
    logic [1:0] write_desc_burst_type;
    logic [LEN_WIDTH-1:0] write_desc_remaining_len;
    logic [AXI_ADDR_WIDTH-1:0] write_desc_current_addr;
    logic [AXI_DATA_WIDTH-1:0] write_desc_current_data;
    logic [AXIS_ID_WIDTH-1:0] write_desc_current_tid;
    logic [AXIS_DEST_WIDTH-1:0] write_desc_current_tdest;
    logic [AXIS_USER_WIDTH-1:0] write_desc_current_tuser;
    logic write_desc_current_tlast;
    logic write_desc_current_tvalid;
    logic write_desc_current_tready;
    logic write_desc_current_tkeep;

    // AXI Master State
    logic axi_aw_valid;
    logic axi_ar_valid;
    logic axi_w_valid;
    logic axi_b_ready;
    logic axi_r_ready;
    logic axi_aw_ready;
    logic axi_ar_ready;
    logic axi_w_ready;
    logic axi_b_valid;
    logic axi_r_valid;
    logic axi_b_ready_int;
    logic axi_r_ready_int;

    logic [AXI_ID_WIDTH-1:0] axi_awid;
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [7:0] axi_awlen;
    logic [2:0] axi_awsize;
    logic [1:0] axi_awburst;
    logic axi_awlock;
    logic [3:0] axi_awcache;
    logic [2:0] axi_awprot;

    logic [AXI_DATA_WIDTH-1:0] axi_wdata;
    logic [AXI_STRB_WIDTH-1:0] axi_wstrb;
    logic axi_wlast;

    logic [AXI_ID_WIDTH-1:0] axi_arid;
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic [7:0] axi_arlen;
    logic [2:0] axi_arsize;
    logic [1:0] axi_arburst;
    logic axi_arlock;
    logic [3:0] axi_arcache;
    logic [2:0] axi_arprot;

    logic [AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0] axi_rresp;
    logic axi_rlast;

    // Status Output Registers
    logic [TAG_WIDTH-1:0] read_status_tag;
    logic [3:0] read_status_error;
    logic read_status_valid;
    
    logic [LEN_WIDTH-1:0] write_status_len;
    logic [TAG_WIDTH-1:0] write_status_tag;
    logic [AXIS_ID_WIDTH-1:0] write_status_id;
    logic [AXIS_DEST_WIDTH-1:0] write_status_dest;
    logic [AXIS_USER_WIDTH-1:0] write_status_user;
    logic [3:0] write_status_error;
    logic write_status_valid;

    // Helper: Calculate AXI Burst Size based on data width
    function automatic logic [2:0] calc_axi_size;
        input logic [AXI_DATA_WIDTH-1:0] data_width;
        begin
            if (data_width == 8) calc_axi_size := 3'd0; // BYTE
            else if (data_width == 16) calc_axi_size := 3'd1; // HALFWORD
            else if (data_width == 32) calc_axi_size := 3'd2; // WORD
            else if (data_width == 64) calc_axi_size := 3'd3; // DOUBLEWORD
            else if (data_width == 128) calc_axi_size := 3'd4; // QUADWORD
            else if (data_width == 256) calc_axi_size := 3'd5; // OCTWORD
            else if (data_width == 512) calc_axi_size := 3'd6; // HEXWORD
            else if (data_width == 1024) calc_axi_size := 3'd7; // DECAWORD
            else calc_axi_size := 3'd0; // Default to BYTE
        end
    endfunction

    // Helper: Calculate AXI Burst Length
    function automatic logic [7:0] calc_axi_burst_len;
        input logic [LEN_WIDTH-1:0] len;
        input logic [2:0] size;
        begin
            // len is in bytes. AXI len is in beats.
            // beats = ceil(len / (2^size))
            localparam LOG2_SIZE = $clog2(1 << size);
            localparam DIVISOR = 1 << LOG2_SIZE;
            
            if (len == 0) begin
                calc_axi_burst_len := 8'd0;
            end else begin
                calc_axi_burst_len = (len + DIVISOR - 1) / DIVISOR;
                if (calc_axi_burst_len > AXI_MAX_BURST_LEN) begin
                    calc_axi_burst_len = AXI_MAX_BURST_LEN;
                end
            end
        end
    endfunction

    // Helper: Calculate AXI Strb
    function automatic logic [AXI_STRB_WIDTH-1:0] calc_strb;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_strb = keep;
            end else begin
                calc_strb = {AXI_STRB_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WLast
    function automatic logic calc_wlast;
        input logic [LEN_WIDTH-1:0] remaining_len;
        input logic [2:0] size;
        begin
            if (remaining_len <= (1 << size)) begin
                calc_wlast := 1'b1;
            end else begin
                calc_wlast := 1'b0;
            end
        end
    endfunction

    // Helper: Calculate AXI RLast
    function automatic logic calc_rlast;
        input logic [LEN_WIDTH-1:0] remaining_len;
        input logic [2:0] size;
        begin
            if (remaining_len <= (1 << size)) begin
                calc_rlast := 1'b1;
            end else begin
                calc_rlast := 1'b0;
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_wkeep;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_wkeep = keep;
            end else begin
                calc_wkeep = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WData
    function automatic logic [AXI_DATA_WIDTH-1:0] calc_wdata;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_wdata = data;
            end else begin
                calc_wdata = {AXI_DATA_WIDTH{1'b0}};
            end
        end
    endfunction

    // Helper: Calculate AXI RData
    function automatic logic [AXI_DATA_WIDTH-1:0] calc_rdata;
        input logic [AXI_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_rdata = data;
            end else begin
                calc_rdata = {AXI_DATA_WIDTH{1'b0}};
            end
        endfunction
    endfunction

    // Helper: Calculate AXI WStrb
    function automatic logic [AXI_STRB_WIDTH-1:0] calc_wstrb;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_wstrb = keep;
            end else begin
                calc_wstrb = {AXI_STRB_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep = keep;
            end else begin
                calc_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for input
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_in;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_in = keep;
            end else begin
                calc_tkeep_in = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out = keep;
            end else begin
                calc_tkeep_out = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out2;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out2 = keep;
            end else begin
                calc_tkeep_out2 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out3;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out3 = keep;
            end else begin
                calc_tkeep_out3 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out4;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out4 = keep;
            end else begin
                calc_tkeep_out4 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out5;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out5 = keep;
            end else begin
                calc_tkeep_out5 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out6;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out6 = keep;
            end else begin
                calc_tkeep_out6 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out7;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out7 = keep;
            end else begin
                calc_tkeep_out7 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out8;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out8 = keep;
            end else begin
                calc_tkeep_out8 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out9;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out9 = keep;
            end else begin
                calc_tkeep_out9 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out10;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out10 = keep;
            end else begin
                calc_tkeep_out10 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out11;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out11 = keep;
            end else begin
                calc_tkeep_out11 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out12;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out12 = keep;
            end else begin
                calc_tkeep_out12 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out13;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out13 = keep;
            end else begin
                calc_tkeep_out13 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out14;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out14 = keep;
            end else begin
                calc_tkeep_out14 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out15;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out15 = keep;
            end else begin
                calc_tkeep_out15 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out16;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out16 = keep;
            end else begin
                calc_tkeep_out16 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out17;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out17 = keep;
            end else begin
                calc_tkeep_out17 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out18;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out18 = keep;
            end else begin
                calc_tkeep_out18 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out19;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out19 = keep;
            end else begin
                calc_tkeep_out19 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out20;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out20 = keep;
            end else begin
                calc_tkeep_out20 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out21;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out21 = keep;
            end else begin
                calc_tkeep_out21 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out22;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out22 = keep;
            end else begin
                calc_tkeep_out22 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out23;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out23 = keep;
            end else begin
                calc_tkeep_out23 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out24;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out24 = keep;
            end else begin
                calc_tkeep_out24 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out25;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out25 = keep;
            end else begin
                calc_tkeep_out25 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out26;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out26 = keep;
            end else begin
                calc_tkeep_out26 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out27;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out27 = keep;
            end else begin
                calc_tkeep_out27 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out28;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out28 = keep;
            end else begin
                calc_tkeep_out28 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out29;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out29 = keep;
            end else begin
                calc_tkeep_out29 = {AXIS_KEEP_WIDTH{1'b1}};
            end
        end
    endfunction

    // Helper: Calculate AXI WKeep for output
    function automatic logic [AXIS_KEEP_WIDTH-1:0] calc_tkeep_out30;
        input logic [AXIS_DATA_WIDTH-1:0] data;
        input logic [AXIS_KEEP_WIDTH-1:0] keep;
        begin
            if (AXIS_KEEP_ENABLE) begin
                calc_tkeep_out30 = keep;
            end else begin
                calc_tkeep_out30 = {AXIS