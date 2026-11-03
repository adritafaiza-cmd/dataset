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

    reg                               s_axis_read_desc_ready_reg;
    reg [TAG_WIDTH-1:0]               m_axis_read_desc_status_tag_reg;
    reg [3:0]                         m_axis_read_desc_status_error_reg;
    reg                               m_axis_read_desc_status_valid_reg;
    reg [AXIS_DATA_WIDTH-1:0]         m_axis_read_data_tdata_reg;
    reg [AXIS_KEEP_WIDTH-1:0]         m_axis_read_data_tkeep_reg;
    reg                               m_axis_read_data_tvalid_reg;
    reg                               m_axis_read_data_tlast_reg;
    reg [AXIS_ID_WIDTH-1:0]           m_axis_read_data_tid_reg;
    reg [AXIS_DEST_WIDTH-1:0]         m_axis_read_data_tdest_reg;
    reg [AXIS_USER_WIDTH-1:0]         m_axis_read_data_tuser_reg;
    reg                               s_axis_write_desc_ready_reg;
    reg [LEN_WIDTH-1:0]               m_axis_write_desc_status_len_reg;
    reg [TAG_WIDTH-1:0]               m_axis_write_desc_status_tag_reg;
    reg [AXIS_ID_WIDTH-1:0]           m_axis_write_desc_status_id_reg;
    reg [AXIS_DEST_WIDTH-1:0]         m_axis_write_desc_status_dest_reg;
    reg [AXIS_USER_WIDTH-1:0]         m_axis_write_desc_status_user_reg;
    reg [3:0]                         m_axis_write_desc_status_error_reg;
    reg                               m_axis_write_desc_status_valid_reg;
    reg                               s_axis_write_data_tready_reg;
    reg [AXI_ID_WIDTH-1:0]            m_axi_awid_reg;
    reg [AXI_ADDR_WIDTH-1:0]          m_axi_awaddr_reg;
    reg [7:0]                         m_axi_awlen_reg;
    reg [2:0]                         m_axi_awsize_reg;
    reg [1:0]                         m_axi_awburst_reg;
    reg                               m_axi_awlock_reg;
    reg [3:0]                         m_axi_awcache_reg;
    reg [2:0]                         m_axi_awprot_reg;
    reg                               m_axi_awvalid_reg;
    reg [AXI_DATA_WIDTH-1:0]          m_axi_wdata_reg;
    reg [AXI_STRB_WIDTH-1:0]          m_axi_wstrb_reg;
    reg                               m_axi_wlast_reg;
    reg                               m_axi_wvalid_reg;
    reg                               m_axi_bready_reg;
    reg [AXI_ID_WIDTH-1:0]            m_axi_arid_reg;
    reg [AXI_ADDR_WIDTH-1:0]          m_axi_araddr_reg;
    reg [7:0]                         m_axi_arlen_reg;
    reg [2:0]                         m_axi_arsize_reg;
    reg [1:0]                         m_axi_arburst_reg;
    reg                               m_axi_arlock_reg;
    reg [3:0]                         m_axi_arcache_reg;
    reg [2:0]                         m_axi_arprot_reg;
    reg                               m_axi_arvalid_reg;
    reg                               m_axi_rready_reg;

    reg                               read_state;
    reg [AXI_ADDR_WIDTH-1:0]          read_addr;
    reg [LEN_WIDTH-1:0]               read_len;
    reg [TAG_WIDTH-1:0]               read_tag;
    reg [AXIS_ID_WIDTH-1:0]           read_id;
    reg [AXIS_DEST_WIDTH-1:0]         read_dest;
    reg [AXIS_USER_WIDTH-1:0]         read_user;
    reg [AXI_ADDR_WIDTH-1:0]          read_addr_counter;
    reg [LEN_WIDTH-1:0]               read_len_counter;
    reg                               read_data_valid;
    reg                               read_data_last;

    reg                               write_state;
    reg [AXI_ADDR_WIDTH-1:0]          write_addr;
    reg [LEN_WIDTH-1:0]               write_len;
    reg [TAG_WIDTH-1:0]               write_tag;
    reg [AXIS_ID_WIDTH-1:0]           write_id;
    reg [AXIS_DEST_WIDTH-1:0]         write_dest;
    reg [AXIS_USER_WIDTH-1:0]         write_user;
    reg [AXI_ADDR_WIDTH-1:0]          write_addr_counter;
    reg [LEN_WIDTH-1:0]               write_len_counter;
    reg                               write_data_valid;
    reg                               write_data_last;
    reg [AXI_DATA_WIDTH-1:0]          write_data;
    reg [AXI_STRB_WIDTH-1:0]          write_strb;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_read_desc_ready_reg <= 0;
            m_axis_read_desc_status_tag_reg <= 0;
            m_axis_read_desc_status_error_reg <= 0;
            m_axis_read_desc_status_valid_reg <= 0;
            m_axis_read_data_tdata_reg <= 0;
            m_axis_read_data_tkeep_reg <= 0;
            m_axis_read_data_tvalid_reg <= 0;
            m_axis_read_data_tlast_reg <= 0;
            m_axis_read_data_tid_reg <= 0;
            m_axis_read_data_tdest_reg <= 0;
            m_axis_read_data_tuser_reg <= 0;
            s_axis_write_desc_ready_reg <= 0;
            m_axis_write_desc_status_len_reg <= 0;
            m_axis_write_desc_status_tag_reg <= 0;
            m_axis_write_desc_status_id_reg <= 0;
            m_axis_write_desc_status_dest_reg <= 0;
            m_axis_write_desc_status_user_reg <= 0;
            m_axis_write_desc_status_error_reg <= 0;
            m_axis_write_desc_status_valid_reg <= 0;
            s_axis_write_data_tready_reg <= 0;
            m_axi_awid_reg <= 0;
            m_axi_awaddr_reg <= 0;
            m_axi_awlen_reg <= 0;
            m_axi_awsize_reg <= 0;
            m_axi_awburst_reg <= 0;
            m_axi_awlock_reg <= 0;
            m_axi_awcache_reg <= 0;
            m_axi_awprot_reg <= 0;
            m_axi_awvalid_reg <= 0;
            m_axi_wdata_reg <= 0;
            m_axi_wstrb_reg <= 0;
            m_axi_wlast_reg <= 0;
            m_axi_wvalid_reg <= 0;
            m_axi_bready_reg <= 0;
            m_axi_arid_reg <= 0;
            m_axi_araddr_reg <= 0;
            m_axi_arlen_reg <= 0;
            m_axi_arsize_reg <= 0;
            m_axi_arburst_reg <= 0;
            m_axi_arlock_reg <= 0;
            m_axi_arcache_reg <= 0;
            m_axi_arprot_reg <= 0;
            m_axi_arvalid_reg <= 0;
            m_axi_rready_reg <= 0;

            read_state <= 0;
            read_addr <= 0;
            read_len <= 0;
            read_tag <= 0;
            read_id <= 0;
            read_dest <= 0;
            read_user <= 0;
            read_addr_counter <= 0;
            read_len_counter <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;

            write_state <= 0;
            write_addr <= 0;
            write_len <= 0;
            write_tag <= 0;
            write_id <= 0;
            write_dest <= 0;
            write_user <= 0;
            write_addr_counter <= 0;
            write_len_counter <= 0;
            write_data_valid <= 0;
            write_data_last <= 0;
            write_data <= 0;
            write_strb <= 0;
        end else begin
            // Read Path
            if (read_enable && !read_state && s_axis_read_desc_valid) begin
                read_state <= 1;
                read_addr <= s_axis_read_desc_addr;
                read_len <= s_axis_read_desc_len;
                read_tag <= s_axis_read_desc_tag;
                read_id <= s_axis_read_desc_id;
                read_dest <= s_axis_read_desc_dest;
                read_user <= s_axis_read_desc_user;
                read_addr_counter <= s_axis_read_desc_addr;
                read_len_counter <= s_axis_read_desc_len;
                s_axis_read_desc_ready_reg <= 1;
            end else if (read_state && m_axi_arready) begin
                m_axi_arid_reg <= read_id;
                m_axi_araddr_reg <= read_addr_counter;
                m_axi_arlen_reg <= (read_len_counter > AXI_MAX_BURST_LEN) ? AXI_MAX_BURST_LEN-1 : read_len_counter-1;
                m_axi_arsize_reg <= $clog2(AXI_DATA_WIDTH/8);
                m_axi_arburst_reg <= 2'b01; // INCR
                m_axi_arlock_reg <= 0;
                m_axi_arcache_reg <= 0;
                m_axi_arprot_reg <= 0;
                m_axi_arvalid_reg <= 1;
                read_state <= 2;
                s_axis_read_desc_ready_reg <= 0;
            end else if (read_state == 2 && m_axi_rvalid) begin
                m_axis_read_data_tdata_reg <= m_axi_rdata;
                m_axis_read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                m_axis_read_data_tvalid_reg <= 1;
                m_axis_read_data_tlast_reg <= (read_len_counter == AXI_DATA_WIDTH/8);
                m_axis_read_data_tid_reg <= read_id;
                m_axis_read_data_tdest_reg <= read_dest;
                m_axis_read_data_tuser_reg <= read_user;
                read_addr_counter <= read_addr_counter + AXI_DATA_WIDTH/8;
                read_len_counter <= read_len_counter - AXI_DATA_WIDTH/8;
                if (read_len_counter <= AXI_DATA_WIDTH/8) begin
                    read_state <= 0;
                    m_axis_read_desc_status_tag_reg <= read_tag;
                    m_axis_read_desc_status_error_reg <= 0;
                    m_axis_read_desc_status_valid_reg <= 1;
                end
            end else if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
                m_axis_read_data_tvalid_reg <= 0;
                if (m_axis_read_data_tlast_reg) begin
                    m_axis_read_desc_status_valid_reg <= 0;
                end
            end

            // Write Path
            if (write_enable && !write_state && s_axis_write_desc_valid) begin
                write_state <= 1;
                write_addr <= s_axis_write_desc_addr;
                write_len <= s_axis_write_desc_len;
                write_tag <= s_axis_write_desc_tag;
                write_id <= s_axis_write_desc_id;
                write_dest <= s_axis_write_desc_dest;
                write_user <= s_axis_write_desc_user;
                write_addr_counter <= s_axis_write_desc_addr;
                write_len_counter <= s_axis_write_desc_len;
                s_axis_write_desc_ready_reg <= 1;
            end else if (write_state && m_axi_awready) begin
                m_axi_awid_reg <= write_id;
                m_axi_awaddr_reg <= write_addr_counter;
                m_axi_awlen_reg <= (write_len_counter > AXI_MAX_BURST_LEN) ? AXI_MAX_BURST_LEN-1 : write_len_counter-1;
                m_axi_awsize_reg <= $clog2(AXI_DATA_WIDTH/8);
                m_axi_awburst_reg <= 2'b01; // INCR
                m_axi_awlock_reg <= 0;
                m_axi_awcache_reg <= 0;
                m_axi_awprot_reg <= 0;
                m_axi_awvalid_reg <= 1;
                write_state <= 2;
                s_axis_write_desc_ready_reg <= 0;
            end else if (write_state == 2 && s_axis_write_data_valid && m_axi_wready) begin
                m_axi_wdata_reg <= s_axis_write_data_tdata;
                m_axi_wstrb_reg <= s_axis_write_data_tkeep;
                m_axi_wlast_reg <= (write_len_counter <= AXI_DATA_WIDTH/8);
                m_axi_wvalid_reg <= 1;
                s_axis_write_data_tready_reg <= 1;
                write_addr_counter <= write_addr_counter + AXI_DATA_WIDTH/8;
                write_len_counter <= write_len_counter - AXI_DATA_WIDTH/8;
                if (write_len_counter <= AXI_DATA_WIDTH/8) begin
                    write_state <= 3;
                end
            end else if (write_state == 3 && m_axi_bvalid) begin
                m_axis_write_desc_status_len_reg <= write_len;
                m_axis_write_desc_status_tag_reg <= write_tag;
                m_axis_write_desc_status_id_reg <= write_id;
                m_axis_write_desc_status_dest_reg <= write_dest;
                m_axis_write_desc_status_user_reg <= write_user;
                m_axis_write_desc_status_error_reg <= 0;
                m_axis_write_desc_status_valid_reg <= 1;
                write_state <= 0;
                m_axi_awvalid_reg <= 0;
                m_axi_wvalid_reg <= 0;
                s_axis_write_data_tready_reg <= 0;
            end else if (m_axis_write_desc_status_valid && m_axi_bready) begin
                m_axis_write_desc_status_valid_reg <= 0;
            end

            // AXI Handshake
            if (m_axi_arvalid && m_axi_arready) begin
                m_axi_arvalid_reg <= 0;
            end

            if (m_axi_rvalid && m_axis_read_data_tready) begin
                m_axi_rready_reg <= 0;
            end

            if (m_axi_awvalid && m_axi_awready) begin
                m_axi_awvalid_reg <= 0;
            end

            if (m_axi_wvalid && m_axi_wready) begin
                m_axi_wvalid_reg <= 0;
            end

            if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bready_reg <= 0;
            end
        end
    end

    assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;
    assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_reg;
    assign m_axis_read_desc_status_error = m_axis_read_desc_status_error_reg;
    assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_reg;
    assign m_axis_read_data_tdata = m_axis_read_data_tdata_reg;
    assign m_axis_read_data_tkeep = m_axis_read_data_tkeep_reg;
    assign m_axis_read_data_tvalid = m_axis_read_data_tvalid_reg;
    assign m_axis_read_data_tlast = m_axis_read_data_tlast_reg;
    assign m_axis_read_data_tid = m_axis_read_data_tid_reg;
    assign m_axis_read_data_tdest = m_axis_read_data_tdest_reg;
    assign m_axis_read_data_tuser = m_axis_read_data_tuser_reg;
    assign s_axis_write_desc_ready = s_axis_write_desc_ready_reg;
    assign m_axis_write_desc_status_len = m_axis_write_desc_status_len_reg;
    assign m_axis_write_desc_status_tag = m_axis_write_desc_status_tag_reg;
    assign m_axis_write_desc_status_id = m_axis_write_desc_status_id_reg;
    assign m_axis_write_desc_status_dest = m_axis_write_desc_status_dest_reg;
    assign m_axis_write_desc_status_user = m_axis_write_desc_status_user_reg;
    assign m_axis_write_desc_status_error = m_axis_write_desc_status_error_reg;
    assign m_axis_write_desc_status_valid = m_axis_write_desc_status_valid_reg;
    assign s_axis_write_data_tready = s_axis_write_data_tready_reg;
    assign m_axi_awid = m_axi_awid_reg;
    assign m_axi_awaddr = m_axi_awaddr_reg;
    assign m_axi_awlen = m_axi_awlen_reg;
    assign m_axi_awsize = m_axi_awsize_reg;
    assign m_axi_awburst = m_axi_awburst_reg;
    assign m_axi_awlock = m_axi_awlock_reg;
    assign m_axi_awcache = m_axi_awcache_reg;
    assign m_axi_awprot = m_axi_awprot_reg;
    assign m_axi_awvalid = m_axi_awvalid_reg;
    assign m_axi_wdata = m_axi_wdata_reg;
    assign m_axi_wstrb = m_axi_wstrb_reg;
    assign m_axi_wlast = m_axi_wlast_reg;
    assign m_axi_wvalid = m_axi_wvalid_reg;
    assign m_axi_bready = m_axi_bready_reg;
    assign m_axi_arid = m_axi_arid_reg;
    assign m_axi_araddr = m_axi_araddr_reg;
    assign m_axi_arlen = m_axi_arlen_reg;
    assign m_axi_arsize = m_axi_arsize_reg;
    assign m_axi_arburst = m_axi_arburst_reg;
    assign m_axi_arlock = m_axi_arlock_reg;
    assign m_axi_arcache = m_axi_arcache_reg;
    assign m_axi_arprot = m_axi_arprot_reg;
    assign m_axi_arvalid = m_axi_arvalid_reg;
    assign m_axi_rready = m_axi_rready_reg;

endmodule
