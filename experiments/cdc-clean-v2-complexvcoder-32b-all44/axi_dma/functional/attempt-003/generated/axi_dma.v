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

    // Internal state and control signals
    reg  [AXI_ADDR_WIDTH-1:0]         read_addr_reg;
    reg  [LEN_WIDTH-1:0]              read_len_reg;
    reg  [TAG_WIDTH-1:0]              read_tag_reg;
    reg  [AXIS_ID_WIDTH-1:0]          read_id_reg;
    reg  [AXIS_DEST_WIDTH-1:0]        read_dest_reg;
    reg  [AXIS_USER_WIDTH-1:0]        read_user_reg;
    reg  [AXI_ADDR_WIDTH-1:0]         write_addr_reg;
    reg  [LEN_WIDTH-1:0]              write_len_reg;
    reg  [TAG_WIDTH-1:0]              write_tag_reg;
    reg  [AXIS_ID_WIDTH-1:0]          write_id_reg;
    reg  [AXIS_DEST_WIDTH-1:0]        write_dest_reg;
    reg  [AXIS_USER_WIDTH-1:0]        write_user_reg;
    reg                               read_desc_ready;
    reg                               write_desc_ready;
    reg                               read_data_valid;
    reg                               read_data_last;
    reg  [AXIS_DATA_WIDTH-1:0]        read_data_reg;
    reg  [AXIS_KEEP_WIDTH-1:0]        read_data_keep_reg;
    reg                               write_data_ready;
    reg                               read_desc_status_valid;
    reg  [TAG_WIDTH-1:0]              read_desc_status_tag_reg;
    reg  [3:0]                        read_desc_status_error_reg;
    reg                               write_desc_status_valid;
    reg  [LEN_WIDTH-1:0]              write_desc_status_len_reg;
    reg  [TAG_WIDTH-1:0]              write_desc_status_tag_reg;
    reg  [AXIS_ID_WIDTH-1:0]          write_desc_status_id_reg;
    reg  [AXIS_DEST_WIDTH-1:0]        write_desc_status_dest_reg;
    reg  [AXIS_USER_WIDTH-1:0]        write_desc_status_user_reg;
    reg  [3:0]                        write_desc_status_error_reg;
    reg  [7:0]                        axi_awlen_reg;
    reg  [7:0]                        axi_arlen_reg;
    reg                               axi_awvalid_reg;
    reg                               axi_arvalid_reg;
    reg                               axi_wvalid_reg;
    reg                               axi_wlast_reg;
    reg                               axi_bready_reg;
    reg                               axi_rready_reg;
    reg  [AXI_DATA_WIDTH-1:0]         axi_wdata_reg;
    reg  [AXI_STRB_WIDTH-1:0]         axi_wstrb_reg;

    // State machines
    typedef enum logic [1:0] {IDLE, READ_ADDR, READ_DATA, WRITE_ADDR, WRITE_DATA, WRITE_BRESP} state_t;
    state_t read_state;
    state_t write_state;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE;
            read_addr_reg <= 0;
            read_len_reg <= 0;
            read_tag_reg <= 0;
            read_id_reg <= 0;
            read_dest_reg <= 0;
            read_user_reg <= 0;
            read_desc_ready <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
            read_data_reg <= 0;
            read_data_keep_reg <= 0;
            read_desc_status_valid <= 0;
            read_desc_status_tag_reg <= 0;
            read_desc_status_error_reg <= 0;
            axi_arlen_reg <= 0;
            axi_arvalid_reg <= 0;
            axi_rready_reg <= 0;
        end else begin
            case (read_state)
                IDLE: begin
                    read_desc_ready <= 0;
                    read_data_valid <= 0;
                    read_data_last <= 0;
                    axi_arvalid_reg <= 0;
                    axi_rready_reg <= 0;
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_addr_reg <= s_axis_read_desc_addr;
                        read_len_reg <= s_axis_read_desc_len;
                        read_tag_reg <= s_axis_read_desc_tag;
                        read_id_reg <= s_axis_read_desc_id;
                        read_dest_reg <= s_axis_read_desc_dest;
                        read_user_reg <= s_axis_read_desc_user;
                        read_desc_ready <= 1;
                        axi_arlen_reg <= s_axis_read_desc_len[7:0]; // Simplified for burst length
                        axi_arvalid_reg <= 1;
                        read_state <= READ_ADDR;
                    end
                end
                READ_ADDR: begin
                    if (m_axi_arready) begin
                        axi_arvalid_reg <= 0;
                        read_state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (m_axi_rvalid) begin
                        read_data_reg <= m_axi_rdata;
                        read_data_keep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                        read_data_valid <= 1;
                        read_data_last <= m_axi_rlast;
                        axi_rready_reg <= 1;
                        if (m_axi_rlast) begin
                            read_state <= IDLE;
                            read_desc_status_valid <= 1;
                            read_desc_status_tag_reg <= read_tag_reg;
                            read_desc_status_error_reg <= 0;
                        end
                    end
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= IDLE;
            write_addr_reg <= 0;
            write_len_reg <= 0;
            write_tag_reg <= 0;
            write_id_reg <= 0;
            write_dest_reg <= 0;
            write_user_reg <= 0;
            write_desc_ready <= 0;
            write_data_ready <= 0;
            write_desc_status_valid <= 0;
            write_desc_status_len_reg <= 0;
            write_desc_status_tag_reg <= 0;
            write_desc_status_id_reg <= 0;
            write_desc_status_dest_reg <= 0;
            write_desc_status_user_reg <= 0;
            write_desc_status_error_reg <= 0;
            axi_awlen_reg <= 0;
            axi_awvalid_reg <= 0;
            axi_wvalid_reg <= 0;
            axi_wlast_reg <= 0;
            axi_wdata_reg <= 0;
            axi_wstrb_reg <= 0;
            axi_bready_reg <= 0;
        end else begin
            case (write_state)
                IDLE: begin
                    write_desc_ready <= 0;
                    write_data_ready <= 0;
                    axi_awvalid_reg <= 0;
                    axi_wvalid_reg <= 0;
                    axi_wlast_reg <= 0;
                    axi_bready_reg <= 0;
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_addr_reg <= s_axis_write_desc_addr;
                        write_len_reg <= s_axis_write_desc_len;
                        write_tag_reg <= s_axis_write_desc_tag;
                        write_id_reg <= s_axis_write_desc_id;
                        write_dest_reg <= s_axis_write_desc_dest;
                        write_user_reg <= s_axis_write_desc_user;
                        write_desc_ready <= 1;
                        axi_awlen_reg <= s_axis_write_desc_len[7:0]; // Simplified for burst length
                        axi_awvalid_reg <= 1;
                        write_state <= WRITE_ADDR;
                    end
                end
                WRITE_ADDR: begin
                    if (m_axi_awready) begin
                        axi_awvalid_reg <= 0;
                        write_state <= WRITE_DATA;
                    end
                end
                WRITE_DATA: begin
                    if (s_axis_write_data_valid && write_data_ready) begin
                        axi_wdata_reg <= s_axis_write_data_tdata;
                        axi_wstrb_reg <= s_axis_write_data_tkeep;
                        axi_wvalid_reg <= 1;
                        axi_wlast_reg <= s_axis_write_data_tlast;
                        if (s_axis_write_data_tlast) begin
                            write_state <= WRITE_BRESP;
                        end
                    end
                    write_data_ready <= m_axi_wready;
                end
                WRITE_BRESP: begin
                    if (m_axi_bvalid) begin
                        axi_bready_reg <= 1;
                        write_state <= IDLE;
                        write_desc_status_valid <= 1;
                        write_desc_status_len_reg <= write_len_reg;
                        write_desc_status_tag_reg <= write_tag_reg;
                        write_desc_status_id_reg <= write_id_reg;
                        write_desc_status_dest_reg <= write_dest_reg;
                        write_desc_status_user_reg <= write_user_reg;
                        write_desc_status_error_reg <= 0;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_desc_status_tag_reg;
    assign m_axis_read_desc_status_error = read_desc_status_error_reg;
    assign m_axis_read_desc_status_valid = read_desc_status_valid;
    assign m_axis_read_data_tdata = read_data_reg;
    assign m_axis_read_data_tkeep = read_data_keep_reg;
    assign m_axis_read_data_tvalid = read_data_valid;
    assign m_axis_read_data_tlast = read_data_last;
    assign m_axis_read_data_tid = read_id_reg;
    assign m_axis_read_data_tdest = read_dest_reg;
    assign m_axis_read_data_tuser = read_user_reg;
    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_desc_status_len_reg;
    assign m_axis_write_desc_status_tag = write_desc_status_tag_reg;
    assign m_axis_write_desc_status_id = write_desc_status_id_reg;
    assign m_axis_write_desc_status_dest = write_desc_status_dest_reg;
    assign m_axis_write_desc_status_user = write_desc_status_user_reg;
    assign m_axis_write_desc_status_error = write_desc_status_error_reg;
    assign m_axis_write_desc_status_valid = write_desc_status_valid;
    assign s_axis_write_data_tready = write_data_ready;
    assign m_axi_awid = write_id_reg;
    assign m_axi_awaddr = write_addr_reg;
    assign m_axi_awlen = axi_awlen_reg;
    assign m_axi_awsize = 2; // 32-bit transfers
    assign m_axi_awburst = 1; // INCR burst
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 0;
    assign m_axi_awprot = 0;
    assign m_axi_awvalid = axi_awvalid_reg;
    assign m_axi_wdata = axi_wdata_reg;
    assign m_axi_wstrb = axi_wstrb_reg;
    assign m_axi_wlast = axi_wlast_reg;
    assign m_axi_wvalid = axi_wvalid_reg;
    assign m_axi_bready = axi_bready_reg;
    assign m_axi_arid = read_id_reg;
    assign m_axi_araddr = read_addr_reg;
    assign m_axi_arlen = axi_arlen_reg;
    assign m_axi_arsize = 2; // 32-bit transfers
    assign m_axi_arburst = 1; // INCR burst
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 0;
    assign m_axi_arprot = 0;
    assign m_axi_arvalid = axi_arvalid_reg;
    assign m_axi_rready = axi_rready_reg;

endmodule
