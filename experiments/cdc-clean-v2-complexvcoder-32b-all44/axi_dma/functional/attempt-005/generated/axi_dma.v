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
    reg  [AXI_ADDR_WIDTH-1:0]  read_addr;
    reg  [LEN_WIDTH-1:0]       read_len;
    reg  [TAG_WIDTH-1:0]       read_tag;
    reg  [AXIS_ID_WIDTH-1:0]   read_id;
    reg  [AXIS_DEST_WIDTH-1:0] read_dest;
    reg  [AXIS_USER_WIDTH-1:0] read_user;
    reg                        read_desc_valid;
    reg  [AXI_ADDR_WIDTH-1:0]  write_addr;
    reg  [LEN_WIDTH-1:0]       write_len;
    reg  [TAG_WIDTH-1:0]       write_tag;
    reg  [AXIS_ID_WIDTH-1:0]   write_id;
    reg  [AXIS_DEST_WIDTH-1:0] write_dest;
    reg  [AXIS_USER_WIDTH-1:0] write_user;
    reg                        write_desc_valid;
    reg  [7:0]                 read_burst_count;
    reg  [7:0]                 write_burst_count;
    reg  [LEN_WIDTH-1:0]       read_remaining_len;
    reg  [LEN_WIDTH-1:0]       write_remaining_len;
    reg  [3:0]                 read_error;
    reg  [3:0]                 write_error;

    // State machine states
    localparam IDLE = 2'b00;
    localparam READ_DESC = 2'b01;
    localparam WRITE_DESC = 2'b10;
    localparam READ_DATA = 2'b11;
    localparam WRITE_DATA = 2'b10;

    reg [1:0] state, next_state;

    // AXI signals
    reg [AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
    reg [7:0] axi_arlen_reg;
    reg [2:0] axi_arsize_reg;
    reg [1:0] axi_arburst_reg;
    reg axi_arvalid_reg;
    reg [AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
    reg [7:0] axi_awlen_reg;
    reg [2:0] axi_awsize_reg;
    reg [1:0] axi_awburst_reg;
    reg axi_awvalid_reg;
    reg [AXI_DATA_WIDTH-1:0] axi_wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] axi_wstrb_reg;
    reg axi_wlast_reg;
    reg axi_wvalid_reg;
    reg axi_rready_reg;
    reg axi_bready_reg;

    // Outputs
    assign s_axis_read_desc_ready = (state == IDLE) & read_enable;
    assign m_axis_read_desc_status_tag = read_tag;
    assign m_axis_read_desc_status_error = read_error;
    assign m_axis_read_desc_status_valid = (state == IDLE) & read_desc_valid;
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;
    assign s_axis_write_desc_ready = (state == IDLE) & write_enable;
    assign m_axis_write_desc_status_len = write_len;
    assign m_axis_write_desc_status_tag = write_tag;
    assign m_axis_write_desc_status_id = write_id;
    assign m_axis_write_desc_status_dest = write_dest;
    assign m_axis_write_desc_status_user = write_user;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = (state == IDLE) & write_desc_valid;
    assign s_axis_write_data_tready = m_axi_wready & (state == WRITE_DATA);
    assign m_axi_awid = write_id;
    assign m_axi_awaddr = axi_awaddr_reg;
    assign m_axi_awlen = axi_awlen_reg;
    assign m_axi_awsize = axi_awsize_reg;
    assign m_axi_awburst = axi_awburst_reg;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = axi_awvalid_reg;
    assign m_axi_wdata = axi_wdata_reg;
    assign m_axi_wstrb = axi_wstrb_reg;
    assign m_axi_wlast = axi_wlast_reg;
    assign m_axi_wvalid = axi_wvalid_reg;
    assign m_axi_bready = axi_bready_reg;
    assign m_axi_arid = read_id;
    assign m_axi_araddr = axi_araddr_reg;
    assign m_axi_arlen = axi_arlen_reg;
    assign m_axi_arsize = axi_arsize_reg;
    assign m_axi_arburst = axi_arburst_reg;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = axi_arvalid_reg;
    assign m_axi_rready = axi_rready_reg;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        axi_araddr_reg = read_addr;
        axi_arlen_reg = read_len[7:0];
        axi_arsize_reg = $clog2(AXI_DATA_WIDTH/8);
        axi_arburst_reg = 2'b01; // INCR
        axi_arvalid_reg = (state == READ_DESC) & read_enable;
        axi_awaddr_reg = write_addr;
        axi_awlen_reg = write_len[7:0];
        axi_awsize_reg = $clog2(AXI_DATA_WIDTH/8);
        axi_awburst_reg = 2'b01; // INCR
        axi_awvalid_reg = (state == WRITE_DESC) & write_enable;
        axi_wdata_reg = s_axis_write_data_tdata;
        axi_wstrb_reg = s_axis_write_data_tkeep;
        axi_wlast_reg = s_axis_write_data_tlast;
        axi_wvalid_reg = s_axis_write_data_tvalid & (state == WRITE_DATA);
        axi_rready_reg = (state == READ_DATA);
        axi_bready_reg = (state == WRITE_DATA) & m_axi_bvalid;

        case (state)
            IDLE: begin
                if (s_axis_read_desc_valid & read_enable) begin
                    read_addr <= s_axis_read_desc_addr;
                    read_len <= s_axis_read_desc_len;
                    read_tag <= s_axis_read_desc_tag;
                    read_id <= s_axis_read_desc_id;
                    read_dest <= s_axis_read_desc_dest;
                    read_user <= s_axis_read_desc_user;
                    read_desc_valid <= 1'b1;
                    read_remaining_len <= s_axis_read_desc_len;
                    read_burst_count <= 0;
                    read_error <= 4'b0000;
                    next_state = READ_DESC;
                end else if (s_axis_write_desc_valid & write_enable) begin
                    write_addr <= s_axis_write_desc_addr;
                    write_len <= s_axis_write_desc_len;
                    write_tag <= s_axis_write_desc_tag;
                    write_id <= s_axis_write_desc_id;
                    write_dest <= s_axis_write_desc_dest;
                    write_user <= s_axis_write_desc_user;
                    write_desc_valid <= 1'b1;
                    write_remaining_len <= s_axis_write_desc_len;
                    write_burst_count <= 0;
                    write_error <= 4'b0000;
                    next_state = WRITE_DESC;
                end
            end
            READ_DESC: begin
                if (m_axi_arready) begin
                    read_desc_valid <= 1'b0;
                    next_state = READ_DATA;
                end
            end
            WRITE_DESC: begin
                if (m_axi_awready) begin
                    write_desc_valid <= 1'b0;
                    next_state = WRITE_DATA;
                end
            end
            READ_DATA: begin
                if (m_axi_rvalid & m_axi_rready) begin
                    if (m_axi_rlast) begin
                        read_remaining_len <= 0;
                        next_state = IDLE;
                    end else begin
                        read_remaining_len <= read_remaining_len - AXI_DATA_WIDTH/8;
                    end
                end
            end
            WRITE_DATA: begin
                if (m_axi_wready & axi_wvalid_reg) begin
                    if (axi_wlast_reg) begin
                        write_remaining_len <= 0;
                        next_state = IDLE;
                    end else begin
                        write_remaining_len <= write_remaining_len - AXI_DATA_WIDTH/8;
                    end
                end
                if (write_abort) begin
                    write_error <= 4'b0001;
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
