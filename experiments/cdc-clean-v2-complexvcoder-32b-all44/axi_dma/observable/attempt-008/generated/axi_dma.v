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

    // Read state machine states
    typedef enum logic [2:0] {
        READ_IDLE,
        READ_DESC,
        READ_DATA,
        READ_WAIT_RESP
    } read_state_t;

    // Write state machine states
    typedef enum logic [2:0] {
        WRITE_IDLE,
        WRITE_DESC,
        WRITE_DATA,
        WRITE_WAIT_RESP
    } write_state_t;

    // Read state machine
    read_state_t read_state, read_next_state;
    reg [LEN_WIDTH-1:0] read_len;
    reg [AXI_ADDR_WIDTH-1:0] read_addr;
    reg [TAG_WIDTH-1:0] read_tag;
    reg [AXIS_ID_WIDTH-1:0] read_id;
    reg [AXIS_DEST_WIDTH-1:0] read_dest;
    reg [AXIS_USER_WIDTH-1:0] read_user;
    reg [7:0] read_burst_len;
    reg [7:0] read_burst_count;
    reg read_burst_last;

    // Write state machine
    write_state_t write_state, write_next_state;
    reg [LEN_WIDTH-1:0] write_len;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [TAG_WIDTH-1:0] write_tag;
    reg [AXIS_ID_WIDTH-1:0] write_id;
    reg [AXIS_DEST_WIDTH-1:0] write_dest;
    reg [AXIS_USER_WIDTH-1:0] write_user;
    reg [7:0] write_burst_len;
    reg [7:0] write_burst_count;
    reg write_burst_last;

    // Status registers
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    reg read_status_valid;
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;
    reg write_status_valid;

    // Handshake signals
    reg s_axis_read_desc_ready_reg;
    reg s_axis_write_desc_ready_reg;
    reg s_axis_write_data_tready_reg;

    // AXI read signals
    reg m_axi_arvalid_reg;
    reg m_axi_rready_reg;

    // AXI write signals
    reg m_axi_awvalid_reg;
    reg m_axi_wvalid_reg;
    reg m_axi_bready_reg;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= READ_IDLE;
            read_len <= 0;
            read_addr <= 0;
            read_tag <= 0;
            read_id <= 0;
            read_dest <= 0;
            read_user <= 0;
            read_burst_len <= 0;
            read_burst_count <= 0;
            read_burst_last <= 0;
            read_status_tag <= 0;
            read_status_error <= 0;
            read_status_valid <= 0;
            s_axis_read_desc_ready_reg <= 0;
            m_axi_arvalid_reg <= 0;
            m_axi_rready_reg <= 0;
        end else begin
            read_state <= read_next_state;
            case (read_state)
                READ_IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_len <= s_axis_read_desc_len;
                        read_addr <= s_axis_read_desc_addr;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_burst_len <= (read_len < 8'd16) ? read_len[3:0] : 8'd15;
                        read_burst_count <= 0;
                        read_burst_last <= (read_len < 8'd16);
                        read_status_valid <= 0;
                        s_axis_read_desc_ready_reg <= 1;
                    end else begin
                        s_axis_read_desc_ready_reg <= 0;
                    end
                    if (read_len != 0 && read_enable) begin
                        read_next_state <= READ_DESC;
                    end else begin
                        read_next_state <= READ_IDLE;
                    end
                end
                READ_DESC: begin
                    m_axi_arvalid_reg <= 1;
                    if (m_axi_arready) begin
                        m_axi_arvalid_reg <= 0;
                        read_next_state <= READ_DATA;
                    end else begin
                        read_next_state <= READ_DESC;
                    end
                end
                READ_DATA: begin
                    m_axi_rready_reg <= 1;
                    if (m_axi_rvalid) begin
                        m_axis_read_data_tdata <= m_axi_rdata;
                        m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                        m_axis_read_data_tvalid <= 1;
                        m_axis_read_data_tlast <= (read_burst_count == read_burst_len - 1) ? read_burst_last : 0;
                        m_axis_read_data_tid <= read_id;
                        m_axis_read_data_tdest <= read_dest;
                        m_axis_read_data_tuser <= read_user;
                        if (m_axis_read_data_tready) begin
                            if (read_burst_count == read_burst_len - 1) begin
                                read_burst_count <= 0;
                                if (read_len > read_burst_len) begin
                                    read_burst_len <= (read_len - read_burst_len < 8'd16) ? read_len[3:0] : 8'd15;
                                    read_burst_last <= (read_len - read_burst_len < 8'd16);
                                    read_addr <= read_addr + read_burst_len * (AXI_DATA_WIDTH / 8);
                                    read_len <= read_len - read_burst_len;
                                    read_next_state <= READ_DESC;
                                end else begin
                                    read_next_state <= READ_WAIT_RESP;
                                end
                            end else begin
                                read_burst_count <= read_burst_count + 1;
                                read_next_state <= READ_DATA;
                            end
                        end else begin
                            read_next_state <= READ_DATA;
                        end
                    end else begin
                        read_next_state <= READ_DATA;
                    end
                end
                READ_WAIT_RESP: begin
                    if (m_axi_rlast && m_axi_rvalid) begin
                        read_status_tag <= read_tag;
                        read_status_error <= (m_axi_rresp == 2'b00) ? 4'b0000 : 4'b0001;
                        read_status_valid <= 1;
                        read_next_state <= READ_IDLE;
                    end else begin
                        read_next_state <= READ_WAIT_RESP;
                    end
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            write_len <= 0;
            write_addr <= 0;
            write_tag <= 0;
            write_id <= 0;
            write_dest <= 0;
            write_user <= 0;
            write_burst_len <= 0;
            write_burst_count <= 0;
            write_burst_last <= 0;
            write_status_len <= 0;
            write_status_tag <= 0;
            write_status_id <= 0;
            write_status_dest <= 0;
            write_status_user <= 0;
            write_status_error <= 0;
            write_status_valid <= 0;
            s_axis_write_desc_ready_reg <= 0;
            s_axis_write_data_tready_reg <= 0;
            m_axi_awvalid_reg <= 0;
            m_axi_wvalid_reg <= 0;
            m_axi_bready_reg <= 0;
        end else begin
            write_state <= write_next_state;
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_len <= s_axis_write_desc_len;
                        write_addr <= s_axis_write_desc_addr;
                        write_tag <= s_axis_write_desc_tag;
                        write_id <= s_axis_write_desc_id;
                        write_dest <= s_axis_write_desc_dest;
                        write_user <= s_axis_write_desc_user;
                        write_burst_len <= (write_len < 8'd16) ? write_len[3:0] : 8'd15;
                        write_burst_count <= 0;
                        write_burst_last <= (write_len < 8'd16);
                        write_status_valid <= 0;
                        s_axis_write_desc_ready_reg <= 1;
                    end else begin
                        s_axis_write_desc_ready_reg <= 0;
                    end
                    if (write_len != 0 && write_enable) begin
                        write_next_state <= WRITE_DESC;
                    end else begin
                        write_next_state <= WRITE_IDLE;
                    end
                end
                WRITE_DESC: begin
                    m_axi_awvalid_reg <= 1;
                    if (m_axi_awready) begin
                        m_axi_awvalid_reg <= 0;
                        write_next_state <= WRITE_DATA;
                    end else begin
                        write_next_state <= WRITE_DESC;
                    end
                end
                WRITE_DATA: begin
                    m_axi_wvalid_reg <= 1;
                    s_axis_write_data_tready_reg <= 1;
                    if (s_axis_write_data_tvalid) begin
                        m_axi_wdata <= s_axis_write_data_tdata;
                        m_axi_wstrb <= s_axis_write_data_tkeep;
                        m_axi_wlast <= (write_burst_count == write_burst_len - 1) ? write_burst_last : 0;
                        if (m_axi_wready) begin
                            if (write_burst_count == write_burst_len - 1) begin
                                write_burst_count <= 0;
                                if (write_len > write_burst_len) begin
                                    write_burst_len <= (write_len - write_burst_len < 8'd16) ? write_len[3:0] : 8'd15;
                                    write_burst_last <= (write_len - write_burst_len < 8'd16);
                                    write_addr <= write_addr + write_burst_len * (AXI_DATA_WIDTH / 8);
                                    write_len <= write_len - write_burst_len;
                                    write_next_state <= WRITE_DESC;
                                end else begin
                                    write_next_state <= WRITE_WAIT_RESP;
                                end
                            end else begin
                                write_burst_count <= write_burst_count + 1;
                                write_next_state <= WRITE_DATA;
                            end
                        end else begin
                            write_next_state <= WRITE_DATA;
                        end
                    end else begin
                        write_next_state <= WRITE_DATA;
                    end
                    if (write_abort) begin
                        write_next_state <= WRITE_IDLE;
                        write_status_len <= write_len;
                        write_status_tag <= write_tag;
                        write_status_id <= write_id;
                        write_status_dest <= write_dest;
                        write_status_user <= write_user;
                        write_status_error <= 4'b0010;
                        write_status_valid <= 1;
                    end
                end
                WRITE_WAIT_RESP: begin
                    m_axi_bready_reg <= 1;
                    if (m_axi_bvalid) begin
                        write_status_len <= write_len;
                        write_status_tag <= write_tag;
                        write_status_id <= write_id;
                        write_status_dest <= write_dest;
                        write_status_user <= write_user;
                        write_status_error <= (m_axi_bresp == 2'b00) ? 4'b0000 : 4'b0001;
                        write_status_valid <= 1;
                        write_next_state <= WRITE_IDLE;
                    end else begin
                        write_next_state <= WRITE_WAIT_RESP;
                    end
                end
            endcase
        end
    end

    // Outputs
    assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;
    assign m_axis_read_data_tdata = m_axis_read_data_tdata;
    assign m_axis_read_data_tkeep = m_axis_read_data_tkeep;
    assign m_axis_read_data_tvalid = m_axis_read_data_tvalid;
    assign m_axis_read_data_tlast = m_axis_read_data_tlast;
    assign m_axis_read_data_tid = m_axis_read_data_tid;
    assign m_axis_read_data_tdest = m_axis_read_data_tdest;
    assign m_axis_read_data_tuser = m_axis_read_data_tuser;
    assign s_axis_write_desc_ready = s_axis_write_desc_ready_reg;
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;
    assign s_axis_write_data_tready = s_axis_write_data_tready_reg;
    assign m_axi_awid = write_id;
    assign m_axi_awaddr = write_addr;
    assign m_axi_awlen = write_burst_len - 1;
    assign m_axi_awsize = 2'b10; // 32-bit (AXI_DATA_WIDTH = 32)
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Non-cacheable, buffered
    assign m_axi_awprot = 3'b000; // Normal, no security, data
    assign m_axi_awvalid = m_axi_awvalid_reg;
    assign m_axi_wdata = m_axi_wdata;
    assign m_axi_wstrb = m_axi_wstrb;
    assign m_axi_wlast = m_axi_wlast;
    assign m_axi_wvalid = m_axi_wvalid_reg;
    assign m_axi_bready = m_axi_bready_reg;
    assign m_axi_arid = read_id;
    assign m_axi_araddr = read_addr;
    assign m_axi_arlen = read_burst_len - 1;
    assign m_axi_arsize = 2'b10; // 32-bit (AXI_DATA_WIDTH = 32)
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Non-cacheable, buffered
    assign m_axi_arprot = 3'b000; // Normal, no security, data
    assign m_axi_arvalid = m_axi_arvalid_reg;
    assign m_axi_rready = m_axi_rready_reg;

endmodule
