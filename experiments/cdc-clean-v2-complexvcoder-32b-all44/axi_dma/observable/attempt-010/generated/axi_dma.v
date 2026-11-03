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

    // Internal signals for read operation
    reg [AXI_ADDR_WIDTH-1:0]  read_addr_reg;
    reg [LEN_WIDTH-1:0]       read_len_reg;
    reg [TAG_WIDTH-1:0]       read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0]   read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_user_reg;
    reg [LEN_WIDTH-1:0]       read_remaining_len;
    reg                       read_desc_valid;
    reg                       read_data_valid;
    reg                       read_data_last;
    reg [AXIS_DATA_WIDTH-1:0] read_data_reg;
    reg [AXIS_KEEP_WIDTH-1:0] read_data_keep_reg;
    reg [AXIS_ID_WIDTH-1:0]   read_data_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_data_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_data_user_reg;

    // Internal signals for write operation
    reg [AXI_ADDR_WIDTH-1:0]  write_addr_reg;
    reg [LEN_WIDTH-1:0]       write_len_reg;
    reg [TAG_WIDTH-1:0]       write_tag_reg;
    reg [LEN_WIDTH-1:0]       write_remaining_len;
    reg                       write_desc_valid;
    reg                       write_data_valid;
    reg                       write_data_last;
    reg [AXIS_DATA_WIDTH-1:0] write_data_reg;
    reg [AXIS_KEEP_WIDTH-1:0] write_data_keep_reg;
    reg [AXIS_ID_WIDTH-1:0]   write_data_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] write_data_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] write_data_user_reg;

    // Control states
    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE
    } state_t;

    state_t state, next_state;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_read_desc_valid && read_enable) begin
                    next_state = READ;
                end else if (s_axis_write_desc_valid && write_enable) begin
                    next_state = WRITE;
                end
            end
            READ: begin
                if (read_remaining_len == 0 || !read_enable) begin
                    next_state = IDLE;
                end
            end
            WRITE: begin
                if (write_remaining_len == 0 || write_abort || !write_enable) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Read operation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_addr_reg <= 0;
            read_len_reg <= 0;
            read_tag_reg <= 0;
            read_id_reg <= 0;
            read_dest_reg <= 0;
            read_user_reg <= 0;
            read_remaining_len <= 0;
            read_desc_valid <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
            read_data_reg <= 0;
            read_data_keep_reg <= 0;
            read_data_id_reg <= 0;
            read_data_dest_reg <= 0;
            read_data_user_reg <= 0;
        end else if (state == IDLE && s_axis_read_desc_valid && read_enable) begin
            read_addr_reg <= s_axis_read_desc_addr;
            read_len_reg <= s_axis_read_desc_len;
            read_tag_reg <= s_axis_read_desc_tag;
            read_id_reg <= s_axis_read_desc_id;
            read_dest_reg <= s_axis_read_desc_dest;
            read_user_reg <= s_axis_read_desc_user;
            read_remaining_len <= s_axis_read_desc_len;
            read_desc_valid <= 1;
        end else if (state == READ && m_axi_rvalid && m_axi_rready) begin
            read_data_reg <= m_axi_rdata;
            read_data_keep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
            read_data_id_reg <= read_id_reg;
            read_data_dest_reg <= read_dest_reg;
            read_data_user_reg <= read_user_reg;
            read_data_valid <= 1;
            read_data_last <= (read_remaining_len <= AXI_DATA_WIDTH/8);
            read_remaining_len <= read_remaining_len - (AXI_DATA_WIDTH/8);
            if (read_remaining_len <= AXI_DATA_WIDTH/8) begin
                read_desc_valid <= 0;
            end
        end else if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
            read_data_valid <= 0;
        end
    end

    // Write operation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_addr_reg <= 0;
            write_len_reg <= 0;
            write_tag_reg <= 0;
            write_remaining_len <= 0;
            write_desc_valid <= 0;
            write_data_valid <= 0;
            write_data_last <= 0;
            write_data_reg <= 0;
            write_data_keep_reg <= 0;
            write_data_id_reg <= 0;
            write_data_dest_reg <= 0;
            write_data_user_reg <= 0;
        end else if (state == IDLE && s_axis_write_desc_valid && write_enable) begin
            write_addr_reg <= s_axis_write_desc_addr;
            write_len_reg <= s_axis_write_desc_len;
            write_tag_reg <= s_axis_write_desc_tag;
            write_remaining_len <= s_axis_write_desc_len;
            write_desc_valid <= 1;
        end else if (state == WRITE && s_axis_write_data_tvalid && s_axis_write_data_tready) begin
            write_data_reg <= s_axis_write_data_tdata;
            write_data_keep_reg <= s_axis_write_data_tkeep;
            write_data_id_reg <= s_axis_write_data_tid;
            write_data_dest_reg <= s_axis_write_data_tdest;
            write_data_user_reg <= s_axis_write_data_tuser;
            write_data_valid <= 1;
            write_data_last <= s_axis_write_data_tlast;
            write_remaining_len <= write_remaining_len - (AXI_DATA_WIDTH/8);
            if (s_axis_write_data_tlast) begin
                write_desc_valid <= 0;
            end
        end else if (m_axi_wvalid && m_axi_wready) begin
            write_data_valid <= 0;
        end
    end

    // AXI read descriptor status
    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = 4'b0000;
    assign m_axis_read_desc_status_valid = (state == IDLE && read_remaining_len == 0 && read_desc_valid);

    // AXI stream read data output
    assign m_axis_read_data_tdata = read_data_reg;
    assign m_axis_read_data_tkeep = read_data_keep_reg;
    assign m_axis_read_data_tvalid = read_data_valid;
    assign m_axis_read_data_tlast = read_data_last;
    assign m_axis_read_data_tid = read_data_id_reg;
    assign m_axis_read_data_tdest = read_data_dest_reg;
    assign m_axis_read_data_tuser = read_data_user_reg;

    // AXI write descriptor status
    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = write_data_id_reg;
    assign m_axis_write_desc_status_dest = write_data_dest_reg;
    assign m_axis_write_desc_status_user = write_data_user_reg;
    assign m_axis_write_desc_status_error = 4'b0000;
    assign m_axis_write_desc_status_valid = (state == IDLE && write_remaining_len == 0 && write_desc_valid);

    // AXI stream write data input
    assign s_axis_write_data_tready = (state == WRITE && write_data_valid == 0);

    // AXI master interface for read
    assign m_axi_arid = read_id_reg;
    assign m_axi_araddr = read_addr_reg;
    assign m_axi_arlen = read_remaining_len[7:0];
    assign m_axi_arsize = 3'b010; // 32-bit
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Normal Non-cacheable
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = (state == READ && m_axi_arready == 0);
    assign m_axi_rready = (state == READ && read_data_valid == 0);

    // AXI master interface for write
    assign m_axi_awid = write_data_id_reg;
    assign m_axi_awaddr = write_addr_reg;
    assign m_axi_awlen = write_remaining_len[7:0];
    assign m_axi_awsize = 3'b010; // 32-bit
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Normal Non-cacheable
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = (state == WRITE && m_axi_awready == 0 && write_data_valid == 1);
    assign m_axi_wdata = write_data_reg;
    assign m_axi_wstrb = write_data_keep_reg;
    assign m_axi_wlast = write_data_last;
    assign m_axi_wvalid = (state == WRITE && m_axi_wready == 0 && write_data_valid == 1);
    assign m_axi_bready = (state == WRITE && write_desc_valid == 0);

    // AXI read descriptor ready
    assign s_axis_read_desc_ready = (state == IDLE);

endmodule
