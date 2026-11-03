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

    // Internal state registers
    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [TAG_WIDTH-1:0] read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_user_reg;
    reg read_desc_valid_reg;

    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [TAG_WIDTH-1:0] write_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] write_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] write_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] write_user_reg;
    reg write_desc_valid_reg;

    reg [AXI_ADDR_WIDTH-1:0] read_current_addr;
    reg [LEN_WIDTH-1:0] read_current_len;
    reg read_data_valid;
    reg read_data_last;

    reg [AXI_ADDR_WIDTH-1:0] write_current_addr;
    reg [LEN_WIDTH-1:0] write_current_len;
    reg write_data_valid;
    reg write_data_last;

    reg [3:0] read_error;
    reg [3:0] write_error;

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        READ_DESC,
        WRITE_DESC,
        READ_DATA,
        WRITE_DATA,
        READ_STATUS,
        WRITE_STATUS
    } state_t;

    state_t state, next_state;

    // State machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        s_axis_read_desc_ready = 0;
        s_axis_write_desc_ready = 0;
        m_axi_awvalid = 0;
        m_axi_wvalid = 0;
        m_axi_bready = 0;
        m_axi_arvalid = 0;
        m_axi_rready = 0;
        m_axis_read_data_tvalid = 0;
        m_axis_read_data_tlast = 0;
        s_axis_write_data_tready = 0;
        m_axis_write_desc_status_valid = 0;
        m_axis_read_desc_status_valid = 0;

        case (state)
            IDLE: begin
                if (s_axis_read_desc_valid && read_enable) begin
                    next_state = READ_DESC;
                    s_axis_read_desc_ready = 1;
                end else if (s_axis_write_desc_valid && write_enable) begin
                    next_state = WRITE_DESC;
                    s_axis_write_desc_ready = 1;
                end
            end
            READ_DESC: begin
                if (s_axis_read_desc_ready) begin
                    read_addr_reg = s_axis_read_desc_addr;
                    read_len_reg = s_axis_read_desc_len;
                    read_tag_reg = s_axis_read_desc_tag;
                    read_id_reg = s_axis_read_desc_id;
                    read_dest_reg = s_axis_read_desc_dest;
                    read_user_reg = s_axis_read_desc_user;
                    read_desc_valid_reg = 1;
                    next_state = READ_DATA;
                end
            end
            WRITE_DESC: begin
                if (s_axis_write_desc_ready) begin
                    write_addr_reg = s_axis_write_desc_addr;
                    write_len_reg = s_axis_write_desc_len;
                    write_tag_reg = s_axis_write_desc_tag;
                    write_id_reg = s_axis_write_desc_id;
                    write_dest_reg = s_axis_write_desc_dest;
                    write_user_reg = s_axis_write_desc_user;
                    write_desc_valid_reg = 1;
                    next_state = WRITE_DATA;
                end
            end
            READ_DATA: begin
                if (m_axi_arready) begin
                    m_axi_arvalid = 1;
                    m_axi_arid = read_id_reg;
                    m_axi_araddr = read_addr_reg;
                    m_axi_arlen = read_len_reg[7:0];
                    m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
                    m_axi_arburst = 2'b01; // INCR
                    m_axi_arlock = 0;
                    m_axi_arcache = 0;
                    m_axi_arprot = 0;
                    next_state = READ_DATA_WAIT;
                end
            end
            READ_DATA_WAIT: begin
                if (m_axi_rvalid) begin
                    m_axi_rready = 1;
                    m_axis_read_data_tdata = m_axi_rdata;
                    m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
                    m_axis_read_data_tvalid = 1;
                    m_axis_read_data_tlast = m_axi_rlast;
                    m_axis_read_data_tid = read_id_reg;
                    m_axis_read_data_tdest = read_dest_reg;
                    m_axis_read_data_tuser = read_user_reg;
                    read_current_addr = read_current_addr + AXI_DATA_WIDTH/8;
                    read_current_len = read_current_len - (AXI_DATA_WIDTH/8);
                    if (m_axi_rlast) begin
                        next_state = READ_STATUS;
                    end
                end
            end
            WRITE_DATA: begin
                if (s_axis_write_data_valid && m_axi_wready) begin
                    m_axi_wvalid = 1;
                    m_axi_wdata = s_axis_write_data_tdata;
                    m_axi_wstrb = s_axis_write_data_tkeep;
                    m_axi_wlast = s_axis_write_data_tlast;
                    s_axis_write_data_tready = 1;
                    write_current_addr = write_current_addr + AXI_DATA_WIDTH/8;
                    write_current_len = write_current_len - (AXI_DATA_WIDTH/8);
                    if (s_axis_write_data_tlast) begin
                        next_state = WRITE_STATUS;
                    end
                end
                if (m_axi_awready) begin
                    m_axi_awvalid = 1;
                    m_axi_awid = write_id_reg;
                    m_axi_awaddr = write_addr_reg;
                    m_axi_awlen = write_len_reg[7:0];
                    m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
                    m_axi_awburst = 2'b01; // INCR
                    m_axi_awlock = 0;
                    m_axi_awcache = 0;
                    m_axi_awprot = 0;
                end
            end
            READ_STATUS: begin
                if (m_axi_rvalid) begin
                    m_axi_rready = 1;
                    m_axis_read_desc_status_tag = read_tag_reg;
                    m_axis_read_desc_status_error = read_error;
                    m_axis_read_desc_status_valid = 1;
                    next_state = IDLE;
                end
            end
            WRITE_STATUS: begin
                if (m_axi_bvalid) begin
                    m_axi_bready = 1;
                    m_axis_write_desc_status_len = write_len_reg;
                    m_axis_write_desc_status_tag = write_tag_reg;
                    m_axis_write_desc_status_id = write_id_reg;
                    m_axis_write_desc_status_dest = write_dest_reg;
                    m_axis_write_desc_status_user = write_user_reg;
                    m_axis_write_desc_status_error = write_error;
                    m_axis_write_desc_status_valid = 1;
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
