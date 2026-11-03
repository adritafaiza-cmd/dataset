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
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam READ_DESC = 3'b001;
    localparam WRITE_DESC = 3'b010;
    localparam READ_DATA = 3'b011;
    localparam WRITE_DATA = 3'b100;
    localparam READ_STATUS = 3'b101;
    localparam WRITE_STATUS = 3'b110;

    // Read descriptor registers
    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [TAG_WIDTH-1:0] read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_user_reg;

    // Write descriptor registers
    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [TAG_WIDTH-1:0] write_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] write_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] write_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] write_user_reg;

    // Data transfer registers
    reg [LEN_WIDTH-1:0] data_len_reg;
    reg [AXI_ADDR_WIDTH-1:0] data_addr_reg;
    reg [3:0] error_reg;

    // AXI signals
    reg [AXI_ADDR_WIDTH-1:0] axi_addr_reg;
    reg [LEN_WIDTH-1:0] axi_len_reg;
    reg [7:0] axi_awlen_reg;
    reg [7:0] axi_arlen_reg;

    // Stream signals
    reg [AXIS_DATA_WIDTH-1:0] stream_data_reg;
    reg [AXIS_KEEP_WIDTH-1:0] stream_keep_reg;
    reg stream_last_reg;
    reg stream_valid_reg;

    // Ready signals
    reg read_desc_ready_reg;
    reg write_desc_ready_reg;
    reg read_data_tready_reg;
    reg write_data_tready_reg;
    reg read_desc_status_valid_reg;
    reg write_desc_status_valid_reg;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            read_desc_ready_reg <= 0;
            write_desc_ready_reg <= 0;
            read_data_tready_reg <= 0;
            write_data_tready_reg <= 0;
            read_desc_status_valid_reg <= 0;
            write_desc_status_valid_reg <= 0;
            m_axi_awvalid <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
            m_axi_arvalid <= 0;
            m_axi_rready <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_addr_reg <= s_axis_read_desc_addr;
                        read_len_reg <= s_axis_read_desc_len;
                        read_tag_reg <= s_axis_read_desc_tag;
                        read_id_reg <= s_axis_read_desc_id;
                        read_dest_reg <= s_axis_read_desc_dest;
                        read_user_reg <= s_axis_read_desc_user;
                        state <= READ_DESC;
                    end else if (s_axis_write_desc_valid && write_enable) begin
                        write_addr_reg <= s_axis_write_desc_addr;
                        write_len_reg <= s_axis_write_desc_len;
                        write_tag_reg <= s_axis_write_desc_tag;
                        write_id_reg <= s_axis_write_desc_id;
                        write_dest_reg <= s_axis_write_desc_dest;
                        write_user_reg <= s_axis_write_desc_user;
                        state <= WRITE_DESC;
                    end
                end

                READ_DESC: begin
                    read_desc_ready_reg <= 1;
                    state <= READ_DATA;
                end

                WRITE_DESC: begin
                    write_desc_ready_reg <= 1;
                    state <= WRITE_DATA;
                end

                READ_DATA: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1;
                        m_axi_araddr <= read_addr_reg;
                        m_axi_arlen <= read_len_reg[7:0];
                        m_axi_arsize <= $clog2(AXI_DATA_WIDTH/8);
                        m_axi_arburst <= 2'b01; // INCR
                        state <= READ_DATA_WAIT;
                    end
                end

                READ_DATA_WAIT: begin
                    if (m_axi_rvalid) begin
                        m_axi_rready <= 1;
                        m_axis_read_data_tdata <= m_axi_rdata;
                        m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                        m_axis_read_data_tvalid <= 1;
                        m_axis_read_data_tlast <= m_axi_rlast;
                        m_axis_read_data_tid <= read_id_reg;
                        m_axis_read_data_tdest <= read_dest_reg;
                        m_axis_read_data_tuser <= read_user_reg;
                        if (m_axi_rlast) begin
                            state <= READ_STATUS;
                        end
                    end
                end

                WRITE_DATA: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid <= 1;
                        m_axi_awaddr <= write_addr_reg;
                        m_axi_awlen <= write_len_reg[7:0];
                        m_axi_awsize <= $clog2(AXI_DATA_WIDTH/8);
                        m_axi_awburst <= 2'b01; // INCR
                        state <= WRITE_DATA_WAIT;
                    end
                end

                WRITE_DATA_WAIT: begin
                    if (s_axis_write_data_tvalid && m_axi_wready) begin
                        m_axi_wdata <= s_axis_write_data_tdata;
                        m_axi_wstrb <= s_axis_write_data_tkeep;
                        m_axi_wlast <= s_axis_write_data_tlast;
                        m_axi_wvalid <= 1;
                        write_data_tready_reg <= 1;
                        if (s_axis_write_data_tlast) begin
                            state <= WRITE_STATUS_WAIT;
                        end
                    end
                end

                WRITE_STATUS_WAIT: begin
                    if (m_axi_bvalid) begin
                        m_axi_bready <= 1;
                        state <= WRITE_STATUS;
                    end
                end

                READ_STATUS: begin
                    m_axis_read_desc_status_tag <= read_tag_reg;
                    m_axis_read_desc_status_error <= 0; // Assuming no errors for simplicity
                    m_axis_read_desc_status_valid <= 1;
                    read_desc_status_valid_reg <= 1;
                    state <= IDLE;
                end

                WRITE_STATUS: begin
                    m_axis_write_desc_status_tag <= write_tag_reg;
                    m_axis_write_desc_status_id <= write_id_reg;
                    m_axis_write_desc_status_dest <= write_dest_reg;
                    m_axis_write_desc_status_user <= write_user_reg;
                    m_axis_write_desc_status_error <= 0; // Assuming no errors for simplicity
                    m_axis_write_desc_status_valid <= 1;
                    write_desc_status_valid_reg <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase

            // Reset AXI signals
            if (!m_axi_arready) begin
                m_axi_arvalid <= 0;
                m_axi_araddr <= 0;
                m_axi_arlen <= 0;
                m_axi_arsize <= 0;
                m_axi_arburst <= 0;
            end

            if (!m_axi_awready) begin
                m_axi_awvalid <= 0;
                m_axi_awaddr <= 0;
                m_axi_awlen <= 0;
                m_axi_awsize <= 0;
                m_axi_awburst <= 0;
            end

            if (!m_axi_wready) begin
                m_axi_wdata <= 0;
                m_axi_wstrb <= 0;
                m_axi_wlast <= 0;
                m_axi_wvalid <= 0;
            end

            if (!m_axi_bvalid) begin
                m_axi_bready <= 0;
            end

            if (!m_axi_rvalid) begin
                m_axi_rready <= 0;
                m_axis_read_data_tdata <= 0;
                m_axis_read_data_tkeep <= 0;
                m_axis_read_data_tvalid <= 0;
                m_axis_read_data_tlast <= 0;
                m_axis_read_data_tid <= 0;
                m_axis_read_data_tdest <= 0;
                m_axis_read_data_tuser <= 0;
            end

            // Reset ready signals
            if (!s_axis_read_desc_valid || !read_enable) begin
                read_desc_ready_reg <= 0;
            end

            if (!s_axis_write_desc_valid || !write_enable) begin
                write_desc_ready_reg <= 0;
            end

            if (!s_axis_write_data_tvalid || !write_enable) begin
                write_data_tready_reg <= 0;
            end

            if (!m_axis_read_desc_status_valid) begin
                read_desc_status_valid_reg <= 0;
            end

            if (!m_axis_write_desc_status_valid) begin
                write_desc_status_valid_reg <= 0;
            end
        end
    end

    // Assignments
    assign s_axis_read_desc_ready = read_desc_ready_reg;
    assign s_axis_write_desc_ready = write_desc_ready_reg;
    assign m_axis_read_data_tready = read_data_tready_reg;
    assign s_axis_write_data_tready = write_data_tready_reg;
    assign m_axis_read_desc_status_valid = read_desc_status_valid_reg;
    assign m_axis_write_desc_status_valid = write_desc_status_valid_reg;

    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = 0; // Assuming no errors for simplicity
    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = write_id_reg;
    assign m_axis_write_desc_status_dest = write_dest_reg;
    assign m_axis_write_desc_status_user = write_user_reg;
    assign m_axis_write_desc_status_error = 0; // Assuming no errors for simplicity

endmodule
