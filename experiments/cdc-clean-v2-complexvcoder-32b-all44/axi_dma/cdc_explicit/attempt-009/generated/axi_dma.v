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

    // Internal signals for read operations
    reg  [AXI_ADDR_WIDTH-1:0]         read_addr;
    reg  [LEN_WIDTH-1:0]              read_len;
    reg  [TAG_WIDTH-1:0]              read_tag;
    reg  [AXIS_ID_WIDTH-1:0]          read_id;
    reg  [AXIS_DEST_WIDTH-1:0]        read_dest;
    reg  [AXIS_USER_WIDTH-1:0]        read_user;
    reg                               read_desc_valid;
    reg                               read_desc_ready;
    reg  [AXI_ADDR_WIDTH-1:0]         read_current_addr;
    reg  [LEN_WIDTH-1:0]              read_current_len;
    reg  [TAG_WIDTH-1:0]              read_current_tag;
    reg  [AXIS_ID_WIDTH-1:0]          read_current_id;
    reg  [AXIS_DEST_WIDTH-1:0]        read_current_dest;
    reg  [AXIS_USER_WIDTH-1:0]        read_current_user;
    reg                               read_active;
    reg  [AXI_MAX_BURST_LEN-1:0]      read_burst_count;
    reg  [3:0]                        read_error;
    reg                               read_status_valid;

    // Internal signals for write operations
    reg  [AXI_ADDR_WIDTH-1:0]         write_addr;
    reg  [LEN_WIDTH-1:0]              write_len;
    reg  [TAG_WIDTH-1:0]              write_tag;
    reg                               write_desc_valid;
    reg                               write_desc_ready;
    reg  [AXI_ADDR_WIDTH-1:0]         write_current_addr;
    reg  [LEN_WIDTH-1:0]              write_current_len;
    reg  [TAG_WIDTH-1:0]              write_current_tag;
    reg  [AXIS_ID_WIDTH-1:0]          write_current_id;
    reg  [AXIS_DEST_WIDTH-1:0]        write_current_dest;
    reg  [AXIS_USER_WIDTH-1:0]        write_current_user;
    reg                               write_active;
    reg  [AXI_MAX_BURST_LEN-1:0]      write_burst_count;
    reg  [3:0]                        write_error;
    reg                               write_status_valid;

    // AXI read descriptor FSM states
    typedef enum reg [2:0] {
        READ_IDLE,
        READ_WAIT_ADDR,
        READ_WAIT_DATA,
        READ_COMPLETE
    } read_state_t;

    read_state_t read_state, read_next_state;

    // AXI write descriptor FSM states
    typedef enum reg [2:0] {
        WRITE_IDLE,
        WRITE_WAIT_ADDR,
        WRITE_WAIT_DATA,
        WRITE_COMPLETE
    } write_state_t;

    write_state_t write_state, write_next_state;

    // AXI read descriptor FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= READ_IDLE;
        end else begin
            read_state <= read_next_state;
        end
    end

    always @(*) begin
        read_next_state = read_state;
        read_desc_ready = 1'b0;
        read_active = 1'b0;
        read_error = 4'b0;
        read_status_valid = 1'b0;

        case (read_state)
            READ_IDLE: begin
                if (s_axis_read_desc_valid && read_enable) begin
                    read_desc_ready = 1'b1;
                    if (s_axis_read_desc_ready) begin
                        read_addr = s_axis_read_desc_addr;
                        read_len = s_axis_read_desc_len;
                        read_tag = s_axis_read_desc_tag;
                        read_id = s_axis_read_desc_id;
                        read_dest = s_axis_read_desc_dest;
                        read_user = s_axis_read_desc_user;
                        read_next_state = READ_WAIT_ADDR;
                    end
                end
            end
            READ_WAIT_ADDR: begin
                read_active = 1'b1;
                if (m_axi_arready) begin
                    read_next_state = READ_WAIT_DATA;
                end
            end
            READ_WAIT_DATA: begin
                read_active = 1'b1;
                if (m_axi_rvalid) begin
                    if (m_axi_rlast) begin
                        read_next_state = READ_COMPLETE;
                    end
                end
            end
            READ_COMPLETE: begin
                read_status_valid = 1'b1;
                if (m_axis_read_desc_status_valid) begin
                    read_next_state = READ_IDLE;
                end
            end
            default: begin
                read_next_state = READ_IDLE;
            end
        endcase
    end

    // AXI write descriptor FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
        end else begin
            write_state <= write_next_state;
        end
    end

    always @(*) begin
        write_next_state = write_state;
        write_desc_ready = 1'b0;
        write_active = 1'b0;
        write_error = 4'b0;
        write_status_valid = 1'b0;

        case (write_state)
            WRITE_IDLE: begin
                if (s_axis_write_desc_valid && write_enable) begin
                    write_desc_ready = 1'b1;
                    if (s_axis_write_desc_ready) begin
                        write_addr = s_axis_write_desc_addr;
                        write_len = s_axis_write_desc_len;
                        write_tag = s_axis_write_desc_tag;
                        write_next_state = WRITE_WAIT_ADDR;
                    end
                end
            end
            WRITE_WAIT_ADDR: begin
                write_active = 1'b1;
                if (m_axi_awready) begin
                    write_next_state = WRITE_WAIT_DATA;
                end
            end
            WRITE_WAIT_DATA: begin
                write_active = 1'b1;
                if (m_axi_bvalid) begin
                    if (m_axi_bresp != 2'b00) begin
                        write_error = 4'b0001; // Assume write error
                    end
                    write_next_state = WRITE_COMPLETE;
                end
            end
            WRITE_COMPLETE: begin
                write_status_valid = 1'b1;
                if (m_axis_write_desc_status_valid) begin
                    write_next_state = WRITE_IDLE;
                end
            end
            default: begin
                write_next_state = WRITE_IDLE;
            end
        endcase
    end

    // Read descriptor status output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_desc_status_tag <= 0;
            m_axis_read_desc_status_error <= 0;
            m_axis_read_desc_status_valid <= 0;
        end else if (read_status_valid) begin
            m_axis_read_desc_status_tag <= read_current_tag;
            m_axis_read_desc_status_error <= read_error;
            m_axis_read_desc_status_valid <= 1'b1;
        end else if (m_axis_read_desc_status_valid) begin
            m_axis_read_desc_status_valid <= 1'b0;
        end
    end

    // Write descriptor status output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 0;
            m_axis_write_desc_status_valid <= 0;
        end else if (write_status_valid) begin
            m_axis_write_desc_status_len <= write_current_len;
            m_axis_write_desc_status_tag <= write_current_tag;
            m_axis_write_desc_status_id <= write_current_id;
            m_axis_write_desc_status_dest <= write_current_dest;
            m_axis_write_desc_status_user <= write_current_user;
            m_axis_write_desc_status_error <= write_error;
            m_axis_write_desc_status_valid <= 1'b1;
        end else if (m_axis_write_desc_status_valid) begin
            m_axis_write_desc_status_valid <= 1'b0;
        end
    end

    // Read data output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_data_tdata <= 0;
            m_axis_read_data_tkeep <= 0;
            m_axis_read_data_tvalid <= 0;
            m_axis_read_data_tlast <= 0;
            m_axis_read_data_tid <= 0;
            m_axis_read_data_tdest <= 0;
            m_axis_read_data_tuser <= 0;
        end else if (m_axi_rvalid) begin
            m_axis_read_data_tdata <= m_axi_rdata;
            m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
            m_axis_read_data_tvalid <= 1'b1;
            m_axis_read_data_tlast <= m_axi_rlast;
            m_axis_read_data_tid <= read_current_id;
            m_axis_read_data_tdest <= read_current_dest;
            m_axis_read_data_tuser <= read_current_user;
        end else if (m_axis_read_data_tvalid && m_axis_read_data_tready) begin
            m_axis_read_data_tvalid <= 1'b0;
        end
    end

    // Write data input
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
        end else if (s_axis_write_data_tvalid && write_active) begin
            m_axi_wdata <= s_axis_write_data_tdata;
            m_axi_wstrb <= s_axis_write_data_tkeep;
            m_axi_wlast <= s_axis_write_data_tlast;
            m_axi_wvalid <= 1'b1;
        end else if (m_axi_wvalid && m_axi_wready) begin
            m_axi_wvalid <= 1'b0;
        end
    end

    // AXI read address channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_arid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 0;
            m_axi_arburst <= 0;
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            m_axi_arvalid <= 0;
        end else if (read_state == READ_WAIT_ADDR) begin
            m_axi_arid <= read_id;
            m_axi_araddr <= read_addr;
            m_axi_arlen <= read_len - 1;
            m_axi_arsize <= 3'b010; // 32-bit
            m_axi_arburst <= 2'b01; // INCR
            m_axi_arlock <= 1'b0;
            m_axi_arcache <= 4'b0011; // Non-cacheable, no buffer
            m_axi_arprot <= 3'b000; // Normal, non-secure, data
            m_axi_arvalid <= 1'b1;
        end else if (m_axi_arvalid && m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
        end
    end

    // AXI write address channel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 0;
            m_axi_awburst <= 0;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= 0;
            m_axi_awvalid <= 0;
        end else if (write_state == WRITE_WAIT_ADDR) begin
            m_axi_awid <= write_id;
            m_axi_awaddr <= write_addr;
            m_axi_awlen <= write_len - 1;
            m_axi_awsize <= 3'b010; // 32-bit
            m_axi_awburst <= 2'b01; // INCR
            m_axi_awlock <= 1'b0;
            m_axi_awcache <= 4'b0011; // Non-cacheable, no buffer
            m_axi_awprot <= 3'b000; // Normal, non-secure, data
            m_axi_awvalid <= 1'b1;
        end else if (m_axi_awvalid && m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
        end
    end

    // AXI read data channel
    assign m_axi_rready = m_axis_read_data_tready;

    // AXI write data channel
    assign s_axis_write_data_tready = m_axi_wready;

    // AXI read response channel
    assign m_axi_bready = write_status_valid;

    // AXI write response channel
    assign m_axi_arready = read_status_valid;

    // Read descriptor handshake
    assign s_axis_read_desc_ready = read_desc_ready;

    // Write descriptor handshake
    assign s_axis_write_desc_ready = write_desc_ready;

endmodule
