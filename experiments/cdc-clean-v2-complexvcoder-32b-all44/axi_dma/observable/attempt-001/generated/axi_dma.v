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

// Internal state signals
reg [AXI_ADDR_WIDTH-1:0]  read_addr_reg;
reg [LEN_WIDTH-1:0]       read_len_reg;
reg [TAG_WIDTH-1:0]       read_tag_reg;
reg [AXIS_ID_WIDTH-1:0]   read_id_reg;
reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
reg [AXIS_USER_WIDTH-1:0] read_user_reg;
reg                       read_desc_valid_reg;
reg                       read_desc_ready_reg;
reg                       read_data_tvalid_reg;
reg                       read_data_tlast_reg;
reg [AXIS_DATA_WIDTH-1:0] read_data_tdata_reg;
reg [AXIS_KEEP_WIDTH-1:0] read_data_tkeep_reg;
reg [AXIS_ID_WIDTH-1:0]   read_data_tid_reg;
reg [AXIS_DEST_WIDTH-1:0] read_data_tdest_reg;
reg [AXIS_USER_WIDTH-1:0] read_data_tuser_reg;
reg [3:0]                 read_error_reg;
reg                       read_status_valid_reg;

reg [AXI_ADDR_WIDTH-1:0]  write_addr_reg;
reg [LEN_WIDTH-1:0]       write_len_reg;
reg [TAG_WIDTH-1:0]       write_tag_reg;
reg [AXIS_ID_WIDTH-1:0]   write_id_reg;
reg [AXIS_DEST_WIDTH-1:0] write_dest_reg;
reg [AXIS_USER_WIDTH-1:0] write_user_reg;
reg                       write_desc_valid_reg;
reg                       write_desc_ready_reg;
reg                       write_data_tready_reg;
reg [AXIS_DATA_WIDTH-1:0] write_data_tdata_reg;
reg [AXIS_KEEP_WIDTH-1:0] write_data_tkeep_reg;
reg                       write_data_tlast_reg;
reg [3:0]                 write_error_reg;
reg                       write_status_valid_reg;

reg [7:0]                 read_burst_len;
reg [AXI_ADDR_WIDTH-1:0]  read_curr_addr;
reg [LEN_WIDTH-1:0]       read_curr_len;
reg [7:0]                 write_burst_len;
reg [AXI_ADDR_WIDTH-1:0]  write_curr_addr;
reg [LEN_WIDTH-1:0]       write_curr_len;

typedef enum logic [2:0] {
    IDLE = 3'b000,
    READ_ADDR = 3'b001,
    READ_DATA = 3'b010,
    READ_STATUS = 3'b011,
    WRITE_ADDR = 3'b100,
    WRITE_DATA = 3'b101,
    WRITE_STATUS = 3'b110
} state_t;

state_t state, next_state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        read_addr_reg <= 0;
        read_len_reg <= 0;
        read_tag_reg <= 0;
        read_id_reg <= 0;
        read_dest_reg <= 0;
        read_user_reg <= 0;
        read_desc_valid_reg <= 0;
        read_desc_ready_reg <= 0;
        read_data_tvalid_reg <= 0;
        read_data_tlast_reg <= 0;
        read_data_tdata_reg <= 0;
        read_data_tkeep_reg <= 0;
        read_data_tid_reg <= 0;
        read_data_tdest_reg <= 0;
        read_data_tuser_reg <= 0;
        read_error_reg <= 0;
        read_status_valid_reg <= 0;
        write_addr_reg <= 0;
        write_len_reg <= 0;
        write_tag_reg <= 0;
        write_id_reg <= 0;
        write_dest_reg <= 0;
        write_user_reg <= 0;
        write_desc_valid_reg <= 0;
        write_desc_ready_reg <= 0;
        write_data_tready_reg <= 0;
        write_data_tdata_reg <= 0;
        write_data_tkeep_reg <= 0;
        write_data_tlast_reg <= 0;
        write_error_reg <= 0;
        write_status_valid_reg <= 0;
        read_burst_len <= 0;
        read_curr_addr <= 0;
        read_curr_len <= 0;
        write_burst_len <= 0;
        write_curr_addr <= 0;
        write_curr_len <= 0;
    end else begin
        state <= next_state;
        case (state)
            IDLE: begin
                if (read_enable && s_axis_read_desc_valid) begin
                    read_addr_reg <= s_axis_read_desc_addr;
                    read_len_reg <= s_axis_read_desc_len;
                    read_tag_reg <= s_axis_read_desc_tag;
                    read_id_reg <= s_axis_read_desc_id;
                    read_dest_reg <= s_axis_read_desc_dest;
                    read_user_reg <= s_axis_read_desc_user;
                    read_desc_valid_reg <= 1;
                    read_desc_ready_reg <= 1;
                end else begin
                    read_desc_ready_reg <= 0;
                end

                if (write_enable && s_axis_write_desc_valid) begin
                    write_addr_reg <= s_axis_write_desc_addr;
                    write_len_reg <= s_axis_write_desc_len;
                    write_tag_reg <= s_axis_write_desc_tag;
                    write_id_reg <= s_axis_write_desc_id;
                    write_dest_reg <= s_axis_write_desc_dest;
                    write_user_reg <= s_axis_write_desc_user;
                    write_desc_valid_reg <= 1;
                    write_desc_ready_reg <= 1;
                end else begin
                    write_desc_ready_reg <= 0;
                end
            end

            READ_ADDR: begin
                if (m_axi_arready) begin
                    read_desc_valid_reg <= 0;
                    read_curr_addr <= read_addr_reg;
                    read_curr_len <= read_len_reg;
                    read_burst_len <= (read_len_reg < 16) ? read_len_reg[3:0] : 15;
                    read_curr_len <= read_curr_len - (read_burst_len + 1);
                end
            end

            READ_DATA: begin
                if (m_axi_rvalid && m_axis_read_data_tready) begin
                    read_data_tdata_reg <= m_axi_rdata;
                    read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                    read_data_tvalid_reg <= 1;
                    read_curr_len <= read_curr_len - 1;
                    if (m_axi_rlast) begin
                        read_data_tlast_reg <= 1;
                        read_status_valid_reg <= 1;
                    end
                end

                if (m_axis_read_data_tready) begin
                    read_data_tvalid_reg <= 0;
                    read_data_tlast_reg <= 0;
                end

                if (m_axi_rvalid && m_axi_rlast) begin
                    read_data_tdata_reg <= m_axi_rdata;
                    read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                    read_data_tvalid_reg <= 1;
                    read_data_tlast_reg <= 1;
                    read_status_valid_reg <= 1;
                end
            end

            READ_STATUS: begin
                if (m_axis_read_desc_status_valid) begin
                    read_status_valid_reg <= 0;
                    state <= IDLE;
                end
            end

            WRITE_ADDR: begin
                if (m_axi_awready) begin
                    write_desc_valid_reg <= 0;
                    write_curr_addr <= write_addr_reg;
                    write_curr_len <= write_len_reg;
                    write_burst_len <= (write_len_reg < 16) ? write_len_reg[3:0] : 15;
                    write_curr_len <= write_curr_len - (write_burst_len + 1);
                end
            end

            WRITE_DATA: begin
                if (m_axi_wready && s_axis_write_data_tvalid) begin
                    write_data_tdata_reg <= s_axis_write_data_tdata;
                    write_data_tkeep_reg <= s_axis_write_data_tkeep;
                    write_data_tlast_reg <= s_axis_write_data_tlast;
                    write_data_tready_reg <= 1;
                    write_curr_len <= write_curr_len - 1;
                end

                if (s_axis_write_data_tvalid && m_axi_wready) begin
                    write_data_tready_reg <= 0;
                end

                if (s_axis_write_data_tlast && m_axi_wready) begin
                    write_data_tready_reg <= 0;
                    write_status_valid_reg <= 1;
                end
            end

            WRITE_STATUS: begin
                if (m_axis_write_desc_status_valid) begin
                    write_status_valid_reg <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
end

// Output assignments
assign s_axis_read_desc_ready = read_desc_ready_reg;
assign m_axis_read_desc_status_tag = read_tag_reg;
assign m_axis_read_desc_status_error = read_error_reg;
assign m_axis_read_desc_status_valid = read_status_valid_reg;
assign m_axis_read_data_tdata = read_data_tdata_reg;
assign m_axis_read_data_tkeep = read_data_tkeep_reg;
assign m_axis_read_data_tvalid = read_data_tvalid_reg;
assign m_axis_read_data_tlast = read_data_tlast_reg;
assign m_axis_read_data_tid = read_data_tid_reg;
assign m_axis_read_data_tdest = read_data_tdest_reg;
assign m_axis_read_data_tuser = read_data_tuser_reg;
assign s_axis_write_desc_ready = write_desc_ready_reg;
assign m_axis_write_desc_status_len = write_len_reg;
assign m_axis_write_desc_status_tag = write_tag_reg;
assign m_axis_write_desc_status_id = write_id_reg;
assign m_axis_write_desc_status_dest = write_dest_reg;
assign m_axis_write_desc_status_user = write_user_reg;
assign m_axis_write_desc_status_error = write_error_reg;
assign m_axis_write_desc_status_valid = write_status_valid_reg;
assign s_axis_write_data_tready = write_data_tready_reg;
assign m_axi_awid = write_id_reg;
assign m_axi_awaddr = write_curr_addr;
assign m_axi_awlen = write_burst_len;
assign m_axi_awsize = 3'b010; // 4 bytes
assign m_axi_awburst = 2'b01; // INCR
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011; // Non-cacheable, no buffer
assign m_axi_awprot = 3'b000; // Normal, non-secure, data
assign m_axi_awvalid = write_desc_valid_reg && (state == WRITE_ADDR);
assign m_axi_wdata = write_data_tdata_reg;
assign m_axi_wstrb = write_data_tkeep_reg;
assign m_axi_wlast = write_data_tlast_reg;
assign m_axi_wvalid = write_data_tvalid_reg;
assign m_axi_bready = write_status_valid_reg;
assign m_axi_arid = read_id_reg;
assign m_axi_araddr = read_curr_addr;
assign m_axi_arlen = read_burst_len;
assign m_axi_arsize = 3'b010; // 4 bytes
assign m_axi_arburst = 2'b01; // INCR
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0011; // Non-cacheable, no buffer
assign m_axi_arprot = 3'b000; // Normal, non-secure, data
assign m_axi_arvalid = read_desc_valid_reg && (state == READ_ADDR);
assign m_axi_rready = read_data_tready;

// State transitions
always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            if (read_enable && read_desc_valid_reg)
                next_state = READ_ADDR;
            else if (write_enable && write_desc_valid_reg)
                next_state = WRITE_ADDR;
        end

        READ_ADDR: begin
            if (m_axi_arready)
                next_state = READ_DATA;
        end

        READ_DATA: begin
            if (m_axi_rvalid && m_axi_rlast)
                next_state = READ_STATUS;
        end

        READ_STATUS: begin
            if (m_axis_read_desc_status_valid)
                next_state = IDLE;
        end

        WRITE_ADDR: begin
            if (m_axi_awready)
                next_state = WRITE_DATA;
        end

        WRITE_DATA: begin
            if (write_data_tlast_reg && m_axi_wready)
                next_state = WRITE_STATUS;
        end

        WRITE_STATUS: begin
            if (m_axis_write_desc_status_valid)
                next_state = IDLE;
        end
    endcase
end

endmodule
