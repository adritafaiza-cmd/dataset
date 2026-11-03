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

    // Internal signals for read descriptor
    reg [AXI_ADDR_WIDTH-1:0]          read_addr_reg;
    reg [LEN_WIDTH-1:0]               read_len_reg;
    reg [TAG_WIDTH-1:0]               read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0]           read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0]         read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0]         read_user_reg;
    reg                               read_desc_valid_reg;
    reg                               read_desc_ready_reg;
    reg [7:0]                         read_burst_len;
    reg [LEN_WIDTH-1:0]               read_bytes_remaining;
    reg                               read_active;
    reg                               read_last;
    reg                               read_error;

    // Internal signals for write descriptor
    reg [AXI_ADDR_WIDTH-1:0]          write_addr_reg;
    reg [LEN_WIDTH-1:0]               write_len_reg;
    reg [TAG_WIDTH-1:0]               write_tag_reg;
    reg [AXIS_ID_WIDTH-1:0]           write_id_reg;
    reg [AXIS_DEST_WIDTH-1:0]         write_dest_reg;
    reg [AXIS_USER_WIDTH-1:0]         write_user_reg;
    reg                               write_desc_valid_reg;
    reg                               write_desc_ready_reg;
    reg [7:0]                         write_burst_len;
    reg [LEN_WIDTH-1:0]               write_bytes_remaining;
    reg                               write_active;
    reg                               write_last;
    reg                               write_error;

    // AXI read descriptor FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_desc_valid_reg <= 0;
            read_active <= 0;
            read_error <= 0;
            read_bytes_remaining <= 0;
        end else begin
            if (read_enable && s_axis_read_desc_valid && !read_active) begin
                read_addr_reg <= s_axis_read_desc_addr;
                read_len_reg <= s_axis_read_desc_len;
                read_tag_reg <= s_axis_read_desc_tag;
                read_id_reg <= s_axis_read_desc_id;
                read_dest_reg <= s_axis_read_desc_dest;
                read_user_reg <= s_axis_read_desc_user;
                read_desc_valid_reg <= 1;
                read_active <= 1;
                read_error <= 0;
                read_bytes_remaining <= s_axis_read_desc_len;
                read_burst_len <= (s_axis_read_desc_len < AXI_MAX_BURST_LEN) ? s_axis_read_desc_len[7:0] : AXI_MAX_BURST_LEN - 1;
            end else if (m_axi_arvalid && m_axi_arready) begin
                read_bytes_remaining <= read_bytes_remaining - (read_burst_len + 1);
                if (read_bytes_remaining == 0) begin
                    read_active <= 0;
                    read_desc_valid_reg <= 0;
                end else begin
                    read_burst_len <= (read_bytes_remaining < AXI_MAX_BURST_LEN) ? read_bytes_remaining[7:0] : AXI_MAX_BURST_LEN - 1;
                end
            end else if (m_axi_rvalid && m_axi_rready && m_axi_rlast) begin
                read_active <= 0;
                read_desc_valid_reg <= 0;
            end
        end
    end

    // AXI write descriptor FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_desc_valid_reg <= 0;
            write_active <= 0;
            write_error <= 0;
            write_bytes_remaining <= 0;
        end else begin
            if (write_enable && s_axis_write_desc_valid && !write_active) begin
                write_addr_reg <= s_axis_write_desc_addr;
                write_len_reg <= s_axis_write_desc_len;
                write_tag_reg <= s_axis_write_desc_tag;
                write_id_reg <= s_axis_write_desc_id;
                write_dest_reg <= s_axis_write_desc_dest;
                write_user_reg <= s_axis_write_desc_user;
                write_desc_valid_reg <= 1;
                write_active <= 1;
                write_error <= 0;
                write_bytes_remaining <= s_axis_write_desc_len;
                write_burst_len <= (s_axis_write_desc_len < AXI_MAX_BURST_LEN) ? s_axis_write_desc_len[7:0] : AXI_MAX_BURST_LEN - 1;
            end else if (m_axi_awvalid && m_axi_awready) begin
                write_bytes_remaining <= write_bytes_remaining - (write_burst_len + 1);
                if (write_bytes_remaining == 0) begin
                    write_active <= 0;
                    write_desc_valid_reg <= 0;
                end else begin
                    write_burst_len <= (write_bytes_remaining < AXI_MAX_BURST_LEN) ? write_bytes_remaining[7:0] : AXI_MAX_BURST_LEN - 1;
                end
            end else if (m_axi_wvalid && m_axi_wready && m_axi_wlast) begin
                write_active <= 0;
                write_desc_valid_reg <= 0;
            end else if (write_abort) begin
                write_active <= 0;
                write_desc_valid_reg <= 0;
                write_error <= 1;
            end
        end
    end

    // AXI read data output
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = read_id_reg;
    assign m_axis_read_data_tdest = read_dest_reg;
    assign m_axis_read_data_tuser = read_user_reg;
    assign m_axi_rready = m_axis_read_data_tready;

    // AXI write data input
    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = write_bytes_remaining <= AXI_MAX_BURST_LEN ? write_last : 1'b0;
    assign m_axi_wvalid = write_active && s_axis_write_data_tvalid;
    assign s_axis_write_data_tready = m_axi_wready;

    // AXI read descriptor status output
    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = read_error ? 4'b1000 : 4'b0000;
    assign m_axis_read_desc_status_valid = !read_active && read_desc_valid_reg;

    // AXI write descriptor status output
    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = write_id_reg;
    assign m_axis_write_desc_status_dest = write_dest_reg;
    assign m_axis_write_desc_status_user = write_user_reg;
    assign m_axis_write_desc_status_error = write_error ? 4'b1000 : 4'b0000;
    assign m_axis_write_desc_status_valid = !write_active && write_desc_valid_reg;

    // AXI read descriptor ready
    assign s_axis_read_desc_ready = !read_active;

    // AXI write descriptor ready
    assign s_axis_write_desc_ready = !write_active;

    // AXI read address channel
    assign m_axi_arid = read_id_reg;
    assign m_axi_araddr = read_active ? read_addr_reg : s_axis_read_desc_addr;
    assign m_axi_arlen = read_active ? read_burst_len : s_axis_read_desc_len[7:0];
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Non-cacheable, buffered, modify write
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = read_enable && read_active && !m_axi_arvalid;

    // AXI write address channel
    assign m_axi_awid = write_id_reg;
    assign m_axi_awaddr = write_active ? write_addr_reg : s_axis_write_desc_addr;
    assign m_axi_awlen = write_active ? write_burst_len : s_axis_write_desc_len[7:0];
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Non-cacheable, buffered, modify write
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = write_enable && write_active && !m_axi_awvalid;

    // AXI write response channel
    assign m_axi_bready = write_active;

endmodule
