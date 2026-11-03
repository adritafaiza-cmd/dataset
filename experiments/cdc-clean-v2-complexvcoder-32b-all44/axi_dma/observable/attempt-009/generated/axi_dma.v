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

    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [TAG_WIDTH-1:0] read_tag_reg;
    reg read_desc_valid_reg;
    reg read_desc_ready_reg;
    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [TAG_WIDTH-1:0] write_tag_reg;
    reg write_desc_valid_reg;
    reg write_desc_ready_reg;

    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [LEN_WIDTH-1:0] read_len;
    reg [TAG_WIDTH-1:0] read_tag;
    reg read_valid;
    reg read_last;
    reg [AXIS_DATA_WIDTH-1:0] read_data;
    reg [AXIS_KEEP_WIDTH-1:0] read_keep;

    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len;
    reg [TAG_WIDTH-1:0] write_tag;
    reg write_valid;
    reg write_last;
    reg [AXIS_DATA_WIDTH-1:0] write_data;
    reg [AXIS_KEEP_WIDTH-1:0] write_keep;

    reg [3:0] read_error;
    reg [3:0] write_error;

    reg [LEN_WIDTH-1:0] read_len_cnt;
    reg [LEN_WIDTH-1:0] write_len_cnt;

    reg read_desc_status_valid;
    reg write_desc_status_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_addr_reg <= 0;
            read_len_reg <= 0;
            read_tag_reg <= 0;
            read_desc_valid_reg <= 0;
            read_desc_ready_reg <= 0;
            write_addr_reg <= 0;
            write_len_reg <= 0;
            write_tag_reg <= 0;
            write_desc_valid_reg <= 0;
            write_desc_ready_reg <= 0;
            read_error <= 0;
            write_error <= 0;
            read_len_cnt <= 0;
            write_len_cnt <= 0;
            read_desc_status_valid <= 0;
            write_desc_status_valid <= 0;
        end else begin
            if (read_enable) begin
                if (s_axis_read_desc_valid && read_desc_ready_reg) begin
                    read_addr_reg <= s_axis_read_desc_addr;
                    read_len_reg <= s_axis_read_desc_len;
                    read_tag_reg <= s_axis_read_desc_tag;
                    read_desc_valid_reg <= 1;
                end else if (m_axi_rvalid && m_axis_read_data_tready) begin
                    read_len_cnt <= read_len_cnt - 1;
                    if (read_len_cnt == 1) begin
                        read_desc_valid_reg <= 0;
                        read_desc_status_valid <= 1;
                    end
                end
            end

            if (write_enable && !write_abort) begin
                if (s_axis_write_desc_valid && write_desc_ready_reg) begin
                    write_addr_reg <= s_axis_write_desc_addr;
                    write_len_reg <= s_axis_write_desc_len;
                    write_tag_reg <= s_axis_write_desc_tag;
                    write_desc_valid_reg <= 1;
                end else if (m_axi_wvalid && m_axi_wready) begin
                    write_len_cnt <= write_len_cnt - 1;
                    if (write_len_cnt == 1) begin
                        write_desc_valid_reg <= 0;
                        write_desc_status_valid <= 1;
                    end
                end
            end else if (write_abort) begin
                write_desc_valid_reg <= 0;
                write_desc_status_valid <= 1;
                write_error <= 4'b1000; // Assuming error code 4'b1000 for abort
            end
        end
    end

    assign s_axis_read_desc_ready = read_desc_ready_reg;
    assign s_axis_write_desc_ready = write_desc_ready_reg;

    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = read_error;
    assign m_axis_read_desc_status_valid = read_desc_status_valid;

    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = s_axis_write_desc_id;
    assign m_axis_write_desc_status_dest = s_axis_write_desc_dest;
    assign m_axis_write_desc_status_user = s_axis_write_desc_user;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = write_desc_status_valid;

    assign m_axi_awid = s_axis_write_desc_id;
    assign m_axi_awaddr = write_addr;
    assign m_axi_awlen = write_len - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH / 8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Non-cacheable, bufferable, modifiable
    assign m_axi_awprot = 3'b000; // Normal, non-secure, data
    assign m_axi_awvalid = write_desc_valid_reg && !write_len_cnt;
    assign write_desc_ready_reg = m_axi_awready && !write_desc_valid_reg;

    assign m_axi_wdata = write_data;
    assign m_axi_wstrb = write_keep;
    assign m_axi_wlast = write_last;
    assign m_axi_wvalid = write_desc_valid_reg;
    assign write_desc_ready_reg = m_axi_wready && !write_desc_valid_reg;

    assign m_axi_arid = s_axis_read_desc_id;
    assign m_axi_araddr = read_addr;
    assign m_axi_arlen = read_len - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH / 8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Non-cacheable, bufferable, modifiable
    assign m_axi_arprot = 3'b000; // Normal, non-secure, data
    assign m_axi_arvalid = read_desc_valid_reg && !read_len_cnt;
    assign read_desc_ready_reg = m_axi_arready && !read_desc_valid_reg;

    assign m_axis_read_data_tdata = read_data;
    assign m_axis_read_data_tkeep = read_keep;
    assign m_axis_read_data_tvalid = read_desc_valid_reg;
    assign m_axis_read_data_tlast = read_last;
    assign m_axis_read_data_tid = s_axis_read_desc_id;
    assign m_axis_read_data_tdest = s_axis_read_desc_dest;
    assign m_axis_read_data_tuser = s_axis_read_desc_user;
    assign read_desc_ready_reg = m_axis_read_data_tready && !read_desc_valid_reg;

    assign m_axi_rready = read_desc_valid_reg;
    assign m_axi_bready = write_desc_valid_reg;

    assign read_data = m_axi_rdata;
    assign read_keep = {AXIS_KEEP_WIDTH{1'b1}};
    assign read_last = m_axi_rlast;
    assign read_valid = m_axi_rvalid;
    assign read_len_cnt = read_len_reg;

    assign write_data = s_axis_write_data_tdata;
    assign write_keep = s_axis_write_data_tkeep;
    assign write_last = s_axis_write_data_tlast;
    assign write_valid = s_axis_write_data_tvalid;
    assign write_len_cnt = write_len_reg;

endmodule
