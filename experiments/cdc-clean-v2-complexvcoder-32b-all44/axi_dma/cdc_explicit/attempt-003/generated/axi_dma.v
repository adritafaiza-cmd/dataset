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

// Internal signals
reg [AXI_ADDR_WIDTH-1:0] read_addr;
reg [LEN_WIDTH-1:0] read_len;
reg [TAG_WIDTH-1:0] read_tag;
reg [AXIS_ID_WIDTH-1:0] read_id;
reg [AXIS_DEST_WIDTH-1:0] read_dest;
reg [AXIS_USER_WIDTH-1:0] read_user;
reg read_desc_valid;
reg read_desc_ready;

reg [AXI_ADDR_WIDTH-1:0] write_addr;
reg [LEN_WIDTH-1:0] write_len;
reg [TAG_WIDTH-1:0] write_tag;
reg [AXIS_ID_WIDTH-1:0] write_id;
reg [AXIS_DEST_WIDTH-1:0] write_dest;
reg [AXIS_USER_WIDTH-1:0] write_user;
reg write_desc_valid;
reg write_desc_ready;

reg [AXI_ADDR_WIDTH-1:0] read_current_addr;
reg [LEN_WIDTH-1:0] read_current_len;
reg read_data_valid;
reg read_data_last;
reg [AXIS_DATA_WIDTH-1:0] read_data;
reg [AXIS_KEEP_WIDTH-1:0] read_keep;

reg [AXI_ADDR_WIDTH-1:0] write_current_addr;
reg [LEN_WIDTH-1:0] write_current_len;
reg write_data_valid;
reg write_data_last;
reg [AXIS_DATA_WIDTH-1:0] write_data;
reg [AXIS_KEEP_WIDTH-1:0] write_keep;

reg [3:0] read_error;
reg read_status_valid;

reg [3:0] write_error;
reg write_status_valid;

// Read state machine
typedef enum reg [2:0] {
    READ_IDLE,
    READ_WAIT_DESC,
    READ_WAIT_ARREADY,
    READ_WAIT_RVALID,
    READ_WAIT_RLAST
} read_state_t;

read_state_t read_state, read_next_state;

// Write state machine
typedef enum reg [2:0] {
    WRITE_IDLE,
    WRITE_WAIT_DESC,
    WRITE_WAIT_AWREADY,
    WRITE_WAIT_WREADY,
    WRITE_WAIT_BVALID
} write_state_t;

write_state_t write_state, write_next_state;

// Read state machine logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        read_state <= READ_IDLE;
        read_desc_ready <= 0;
        read_current_addr <= 0;
        read_current_len <= 0;
        read_data_valid <= 0;
        read_data_last <= 0;
        read_data <= 0;
        read_keep <= 0;
        read_error <= 0;
        read_status_valid <= 0;
    end else begin
        read_state <= read_next_state;
        case (read_state)
            READ_IDLE: begin
                if (s_axis_read_desc_valid && read_enable) begin
                    read_desc_ready <= 1;
                    read_current_addr <= s_axis_read_desc_addr;
                    read_current_len <= s_axis_read_desc_len;
                    read_error <= 0;
                end else begin
                    read_desc_ready <= 0;
                end
                if (read_desc_ready && s_axis_read_desc_ready) begin
                    read_desc_ready <= 0;
                    read_next_state <= READ_WAIT_ARREADY;
                end
            end
            READ_WAIT_ARREADY: begin
                if (m_axi_arready) begin
                    read_next_state <= READ_WAIT_RVALID;
                end
            end
            READ_WAIT_RVALID: begin
                if (m_axi_rvalid) begin
                    read_data <= m_axi_rdata;
                    read_keep <= {AXIS_KEEP_WIDTH{1'b1}};
                    read_data_valid <= 1;
                    if (m_axi_rlast) begin
                        read_data_last <= 1;
                        read_next_state <= READ_WAIT_RLAST;
                    end
                end
            end
            READ_WAIT_RLAST: begin
                if (m_axis_read_data_tready && read_data_last) begin
                    read_data_valid <= 0;
                    read_data_last <= 0;
                    read_status_valid <= 1;
                    read_next_state <= READ_IDLE;
                end
            end
            default: read_next_state <= READ_IDLE;
        endcase
    end
end

// Write state machine logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        write_state <= WRITE_IDLE;
        write_desc_ready <= 0;
        write_current_addr <= 0;
        write_current_len <= 0;
        write_data_valid <= 0;
        write_data_last <= 0;
        write_error <= 0;
        write_status_valid <= 0;
    end else begin
        write_state <= write_next_state;
        case (write_state)
            WRITE_IDLE: begin
                if (s_axis_write_desc_valid && write_enable) begin
                    write_desc_ready <= 1;
                    write_current_addr <= s_axis_write_desc_addr;
                    write_current_len <= s_axis_write_desc_len;
                    write_error <= 0;
                end else begin
                    write_desc_ready <= 0;
                end
                if (write_desc_ready && s_axis_write_desc_ready) begin
                    write_desc_ready <= 0;
                    write_next_state <= WRITE_WAIT_AWREADY;
                end
            end
            WRITE_WAIT_AWREADY: begin
                if (m_axi_awready) begin
                    write_next_state <= WRITE_WAIT_WREADY;
                end
            end
            WRITE_WAIT_WREADY: begin
                if (m_axi_wready && s_axis_write_data_valid) begin
                    write_data <= s_axis_write_data_tdata;
                    write_keep <= s_axis_write_data_tkeep;
                    write_data_valid <= 1;
                    if (s_axis_write_data_tlast) begin
                        write_data_last <= 1;
                        write_next_state <= WRITE_WAIT_BVALID;
                    end
                end
            end
            WRITE_WAIT_BVALID: begin
                if (m_axi_bvalid) begin
                    write_data_valid <= 0;
                    write_data_last <= 0;
                    write_status_valid <= 1;
                    write_next_state <= WRITE_IDLE;
                end
            end
            default: write_next_state <= WRITE_IDLE;
        endcase
    end
end

// AXI read interface
assign m_axi_arid = read_id;
assign m_axi_araddr = read_current_addr;
assign m_axi_arlen = (read_current_len > AXI_MAX_BURST_LEN) ? (AXI_MAX_BURST_LEN - 1) : (read_current_len - 1);
assign m_axi_arsize = $clog2(AXI_DATA_WIDTH / 8);
assign m_axi_arburst = 2'b01; // INCR
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0011; // Non-cacheable, buffered, no allocate
assign m_axi_arprot = 3'b000;
assign m_axi_arvalid = (read_state == READ_WAIT_ARREADY) && !m_axi_arready;

assign m_axi_rready = (read_state == READ_WAIT_RVALID) && !m_axis_read_data_tready;

// AXI write interface
assign m_axi_awid = write_id;
assign m_axi_awaddr = write_current_addr;
assign m_axi_awlen = (write_current_len > AXI_MAX_BURST_LEN) ? (AXI_MAX_BURST_LEN - 1) : (write_current_len - 1);
assign m_axi_awsize = $clog2(AXI_DATA_WIDTH / 8);
assign m_axi_awburst = 2'b01; // INCR
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011; // Non-cacheable, buffered, no allocate
assign m_axi_awprot = 3'b000;
assign m_axi_awvalid = (write_state == WRITE_WAIT_AWREADY) && !m_axi_awready;

assign m_axi_wdata = write_data;
assign m_axi_wstrb = write_keep;
assign m_axi_wlast = write_data_last;
assign m_axi_wvalid = (write_state == WRITE_WAIT_WREADY) && !m_axi_wready;

assign m_axi_bready = (write_state == WRITE_WAIT_BVALID) && !m_axis_write_desc_status_valid;

// AXI stream read data output
assign m_axis_read_data_tdata = read_data;
assign m_axis_read_data_tkeep = read_keep;
assign m_axis_read_data_tvalid = read_data_valid;
assign m_axis_read_data_tlast = read_data_last;
assign m_axis_read_data_tid = read_id;
assign m_axis_read_data_tdest = read_dest;
assign m_axis_read_data_tuser = read_user;

// AXI stream write data input
assign s_axis_write_data_tready = (write_state == WRITE_WAIT_WREADY) && m_axi_wready;

// AXI read descriptor input
assign s_axis_read_desc_ready = read_desc_ready;

// AXI write descriptor input
assign s_axis_write_desc_ready = write_desc_ready;

// AXI read descriptor status output
assign m_axis_read_desc_status_tag = read_tag;
assign m_axis_read_desc_status_error = read_error;
assign m_axis_read_desc_status_valid = read_status_valid;

// AXI write descriptor status output
assign m_axis_write_desc_status_len = write_len;
assign m_axis_write_desc_status_tag = write_tag;
assign m_axis_write_desc_status_id = write_id;
assign m_axis_write_desc_status_dest = write_dest;
assign m_axis_write_desc_status_user = write_user;
assign m_axis_write_desc_status_error = write_error;
assign m_axis_write_desc_status_valid = write_status_valid;

endmodule
