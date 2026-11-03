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
    reg  [AXI_ADDR_WIDTH-1:0]         read_addr;
    reg  [LEN_WIDTH-1:0]              read_len;
    reg  [TAG_WIDTH-1:0]              read_tag;
    reg  [AXIS_ID_WIDTH-1:0]          read_id;
    reg  [AXIS_DEST_WIDTH-1:0]        read_dest;
    reg  [AXIS_USER_WIDTH-1:0]        read_user;
    reg                               read_desc_ready;
    reg                               read_active;
    reg  [AXI_ADDR_WIDTH-1:0]         write_addr;
    reg  [LEN_WIDTH-1:0]              write_len;
    reg  [TAG_WIDTH-1:0]              write_tag;
    reg  [AXIS_ID_WIDTH-1:0]          write_id;
    reg  [AXIS_DEST_WIDTH-1:0]        write_dest;
    reg  [AXIS_USER_WIDTH-1:0]        write_user;
    reg                               write_desc_ready;
    reg                               write_active;
    reg  [3:0]                        write_error;
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
    reg  [AXI_ADDR_WIDTH-1:0]         read_addr_cnt;
    reg  [LEN_WIDTH-1:0]              read_len_cnt;
    reg  [AXI_ADDR_WIDTH-1:0]         write_addr_cnt;
    reg  [LEN_WIDTH-1:0]              write_len_cnt;
    reg                               read_burst_done;
    reg                               write_burst_done;
    reg                               read_burst_active;
    reg                               write_burst_active;
    reg  [3:0]                        read_error;
    reg  [3:0]                        read_error_reg;
    reg                               read_status_valid;
    reg                               write_status_valid;
    reg  [AXIS_DATA_WIDTH-1:0]        read_data_reg;
    reg  [AXIS_KEEP_WIDTH-1:0]        read_keep_reg;
    reg                               read_last_reg;
    reg  [AXIS_ID_WIDTH-1:0]          read_id_reg_out;
    reg  [AXIS_DEST_WIDTH-1:0]        read_dest_reg_out;
    reg  [AXIS_USER_WIDTH-1:0]        read_user_reg_out;
    reg                               read_data_valid;
    reg                               read_data_last;
    reg  [AXIS_DATA_WIDTH-1:0]        write_data_reg;
    reg  [AXIS_KEEP_WIDTH-1:0]        write_keep_reg;
    reg                               write_last_reg;
    reg  [AXIS_ID_WIDTH-1:0]          write_id_reg_out;
    reg  [AXIS_DEST_WIDTH-1:0]        write_dest_reg_out;
    reg  [AXIS_USER_WIDTH-1:0]        write_user_reg_out;
    reg                               write_data_ready;

    // AXI read descriptor handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_desc_ready <= 0;
            read_active <= 0;
            read_addr_reg <= 0;
            read_len_reg <= 0;
            read_tag_reg <= 0;
            read_id_reg <= 0;
            read_dest_reg <= 0;
            read_user_reg <= 0;
            read_error_reg <= 0;
        end else begin
            if (!read_active && s_axis_read_desc_valid && read_enable) begin
                read_desc_ready <= 1;
                read_active <= 1;
                read_addr_reg <= s_axis_read_desc_addr;
                read_len_reg <= s_axis_read_desc_len;
                read_tag_reg <= s_axis_read_desc_tag;
                read_id_reg <= s_axis_read_desc_id;
                read_dest_reg <= s_axis_read_desc_dest;
                read_user_reg <= s_axis_read_desc_user;
            end else if (read_burst_done) begin
                read_active <= 0;
                read_desc_ready <= 0;
                read_status_valid <= 1;
                read_error_reg <= read_error;
            end else if (m_axis_read_desc_status_valid && m_axis_read_data_tready) begin
                read_status_valid <= 0;
            end
        end
    end

    // AXI read descriptor status output
    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = read_error_reg;
    assign m_axis_read_desc_status_valid = read_status_valid;

    // AXI read data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_arvalid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 2;
            m_axi_arburst <= 2;
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            read_addr_cnt <= 0;
            read_len_cnt <= 0;
            read_burst_done <= 0;
            read_burst_active <= 0;
            read_error <= 0;
            read_data_reg <= 0;
            read_keep_reg <= 0;
            read_last_reg <= 0;
            read_id_reg_out <= 0;
            read_dest_reg_out <= 0;
            read_user_reg_out <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
        end else begin
            if (read_active && !read_burst_active && m_axi_arready) begin
                m_axi_arvalid <= 1;
                m_axi_araddr <= read_addr_reg;
                m_axi_arlen <= read_len_reg[7:0] - 1;
                read_burst_active <= 1;
                read_addr_cnt <= read_addr_reg;
                read_len_cnt <= read_len_reg;
                read_id_reg_out <= read_id_reg;
                read_dest_reg_out <= read_dest_reg;
                read_user_reg_out <= read_user_reg;
            end else if (m_axi_arvalid && m_axi_arready) begin
                m_axi_arvalid <= 0;
            end

            if (m_axi_rvalid && m_axi_rready) begin
                read_data_reg <= m_axi_rdata;
                read_keep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
                read_last_reg <= m_axi_rlast;
                read_data_valid <= 1;
                read_data_last <= m_axi_rlast;
                if (m_axi_rlast) begin
                    read_burst_done <= 1;
                    read_burst_active <= 0;
                end else begin
                    read_addr_cnt <= read_addr_cnt + AXI_DATA_WIDTH/8;
                    read_len_cnt <= read_len_cnt - (AXI_DATA_WIDTH/8);
                end
            end else if (read_data_valid && m_axis_read_data_tready) begin
                read_data_valid <= 0;
                read_data_last <= 0;
            end

            if (m_axi_rvalid && !m_axi_rready) begin
                read_error <= (m_axi_rresp == 2'b10) ? 4'b0001 : 4'b0000;
            end
        end
    end

    assign m_axi_arid = read_id_reg_out;
    assign m_axi_araddr = read_addr_cnt;
    assign m_axi_arlen = read_len_cnt[7:0] - 1;
    assign m_axi_arsize = 2;
    assign m_axi_arburst = 2;
    assign m_axi_arlock = 0;
    assign m_axi_arcache = 0;
    assign m_axi_arprot = 0;
    assign m_axi_arvalid = read_active && !read_burst_active && m_axi_arready;
    assign m_axi_rready = 1;

    assign m_axis_read_data_tdata = read_data_reg;
    assign m_axis_read_data_tkeep = read_keep_reg;
    assign m_axis_read_data_tvalid = read_data_valid;
    assign m_axis_read_data_tlast = read_data_last;
    assign m_axis_read_data_tid = read_id_reg_out;
    assign m_axis_read_data_tdest = read_dest_reg_out;
    assign m_axis_read_data_tuser = read_user_reg_out;

    // AXI write descriptor handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_desc_ready <= 0;
            write_active <= 0;
            write_addr_reg <= 0;
            write_len_reg <= 0;
            write_tag_reg <= 0;
            write_id_reg <= 0;
            write_dest_reg <= 0;
            write_user_reg <= 0;
            write_error <= 0;
        end else begin
            if (!write_active && s_axis_write_desc_valid && write_enable) begin
                write_desc_ready <= 1;
                write_active <= 1;
                write_addr_reg <= s_axis_write_desc_addr;
                write_len_reg <= s_axis_write_desc_len;
                write_tag_reg <= s_axis_write_desc_tag;
                write_id_reg <= s_axis_write_desc_id;
                write_dest_reg <= s_axis_write_desc_dest;
                write_user_reg <= s_axis_write_desc_user;
            end else if (write_burst_done) begin
                write_active <= 0;
                write_desc_ready <= 0;
                write_status_valid <= 1;
                write_error <= write_error;
            end else if (m_axis_write_desc_status_valid && s_axis_write_data_tready) begin
                write_status_valid <= 0;
            end
        end
    end

    // AXI write descriptor status output
    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = write_id_reg;
    assign m_axis_write_desc_status_dest = write_dest_reg;
    assign m_axis_write_desc_status_user = write_user_reg;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    // AXI write data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awvalid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 2;
            m_axi_awburst <= 2;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= 0;
            m_axi_wvalid <= 0;
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            write_addr_cnt <= 0;
            write_len_cnt <= 0;
            write_burst_done <= 0;
            write_burst_active <= 0;
            write_error <= 0;
            write_data_ready <= 0;
        end else begin
            if (write_active && !write_burst_active && m_axi_awready) begin
                m_axi_awvalid <= 1;
                m_axi_awaddr <= write_addr_reg;
                m_axi_awlen <= write_len_reg[7:0] - 1;
                write_burst_active <= 1;
                write_addr_cnt <= write_addr_reg;
                write_len_cnt <= write_len_reg;
            end else if (m_axi_awvalid && m_axi_awready) begin
                m_axi_awvalid <= 0;
            end

            if (s_axis_write_data_tvalid && write_data_ready) begin
                m_axi_wvalid <= 1;
                m_axi_wdata <= s_axis_write_data_tdata;
                m_axi_wstrb <= s_axis_write_data_tkeep;
                m_axi_wlast <= s_axis_write_data_tlast;
                if (s_axis_write_data_tlast) begin
                    write_burst_done <= 1;
                    write_burst_active <= 0;
                end else begin
                    write_addr_cnt <= write_addr_cnt + AXI_DATA_WIDTH/8;
                    write_len_cnt <= write_len_cnt - (AXI_DATA_WIDTH/8);
                end
            end else if (m_axi_wvalid && m_axi_wready) begin
                m_axi_wvalid <= 0;
            end

            if (m_axi_bvalid && m_axi_bready) begin
                write_data_ready <= 0;
            end

            if (m_axi_bvalid && !m_axi_bready) begin
                write_error <= (m_axi_bresp == 2'b10) ? 4'b0001 : 4'b0000;
            end
        end
    end

    assign m_axi_awid = write_id_reg;
    assign m_axi_awaddr = write_addr_cnt;
    assign m_axi_awlen = write_len_cnt[7:0] - 1;
    assign m_axi_awsize = 2;
    assign m_axi_awburst = 2;
    assign m_axi_awlock = 0;
    assign m_axi_awcache = 0;
    assign m_axi_awprot = 0;
    assign m_axi_awvalid = write_active && !write_burst_active && m_axi_awready;
    assign m_axi_wvalid = write_active && write_burst_active && s_axis_write_data_tvalid && write_data_ready;
    assign m_axi_wdata = write_data_reg;
    assign m_axi_wstrb = write_keep_reg;
    assign m_axi_wlast = write_last_reg;
    assign m_axi_bready = 1;

    assign s_axis_write_data_tready = write_active && write_burst_active && write_data_ready;

endmodule
