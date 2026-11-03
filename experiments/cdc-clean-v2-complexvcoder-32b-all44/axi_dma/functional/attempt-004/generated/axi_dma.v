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

    // Internal states and signals
    reg  [AXI_ADDR_WIDTH-1:0] read_addr;
    reg  [LEN_WIDTH-1:0]      read_len;
    reg  [TAG_WIDTH-1:0]      read_tag;
    reg  [AXIS_ID_WIDTH-1:0]  read_id;
    reg  [AXIS_DEST_WIDTH-1:0]read_dest;
    reg  [AXIS_USER_WIDTH-1:0]read_user;
    reg                       read_desc_valid;
    reg                       read_desc_ready;
    reg  [AXI_ADDR_WIDTH-1:0] write_addr;
    reg  [LEN_WIDTH-1:0]      write_len;
    reg  [TAG_WIDTH-1:0]      write_tag;
    reg                       write_desc_valid;
    reg                       write_desc_ready;
    reg  [AXIS_DATA_WIDTH-1:0]write_data;
    reg  [AXIS_KEEP_WIDTH-1:0]write_keep;
    reg                       write_last;
    reg  [AXIS_ID_WIDTH-1:0]  write_id;
    reg  [AXIS_DEST_WIDTH-1:0]write_dest;
    reg  [AXIS_USER_WIDTH-1:0]write_user;
    reg                       write_data_valid;
    reg                       write_data_ready;
    reg  [7:0]                axi_awlen;
    reg  [7:0]                axi_arlen;
    reg                       read_active;
    reg                       write_active;
    reg  [3:0]                read_error;
    reg  [3:0]                write_error;
    reg  [7:0]                read_burst_count;
    reg  [7:0]                write_burst_count;

    // Read descriptor FSM
    typedef enum logic [1:0] {
        IDLE,
        START_READ,
        WAIT_READ_DATA
    } read_state_t;
    read_state_t read_state, read_next_state;

    // Write descriptor FSM
    typedef enum logic [1:0] {
        IDLE,
        START_WRITE,
        WAIT_WRITE_DATA,
        WAIT_WRITE_RESP
    } write_state_t;
    write_state_t write_state, write_next_state;

    // Read descriptor FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE;
            read_addr <= 0;
            read_len <= 0;
            read_tag <= 0;
            read_id <= 0;
            read_dest <= 0;
            read_user <= 0;
            read_desc_valid <= 0;
            read_desc_ready <= 0;
            read_active <= 0;
            read_error <= 0;
            read_burst_count <= 0;
        end else begin
            read_state <= read_next_state;
            read_desc_ready <= 0;

            case (read_state)
                IDLE: begin
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_addr <= s_axis_read_desc_addr;
                        read_len <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_desc_valid <= 1;
                        read_desc_ready <= 1;
                        read_next_state <= START_READ;
                    end else begin
                        read_next_state <= IDLE;
                    end
                end
                START_READ: begin
                    if (m_axi_arready) begin
                        read_active <= 1;
                        read_next_state <= WAIT_READ_DATA;
                    end else begin
                        read_next_state <= START_READ;
                    end
                end
                WAIT_READ_DATA: begin
                    if (m_axi_rvalid && m_axi_rlast) begin
                        read_active <= 0;
                        read_desc_valid <= 0;
                        read_next_state <= IDLE;
                    end else begin
                        read_next_state <= WAIT_READ_DATA;
                    end
                end
            endcase
        end
    end

    // Write descriptor FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= IDLE;
            write_addr <= 0;
            write_len <= 0;
            write_tag <= 0;
            write_id <= 0;
            write_dest <= 0;
            write_user <= 0;
            write_desc_valid <= 0;
            write_desc_ready <= 0;
            write_active <= 0;
            write_error <= 0;
            write_burst_count <= 0;
        end else begin
            write_state <= write_next_state;
            write_desc_ready <= 0;

            case (write_state)
                IDLE: begin
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_addr <= s_axis_write_desc_addr;
                        write_len <= s_axis_write_desc_len;
                        write_tag <= s_axis_write_desc_tag;
                        write_id <= s_axis_write_data_tid;
                        write_dest <= s_axis_write_data_tdest;
                        write_user <= s_axis_write_data_tuser;
                        write_desc_valid <= 1;
                        write_desc_ready <= 1;
                        write_next_state <= START_WRITE;
                    end else begin
                        write_next_state <= IDLE;
                    end
                end
                START_WRITE: begin
                    if (m_axi_awready) begin
                        write_active <= 1;
                        write_next_state <= WAIT_WRITE_DATA;
                    end else begin
                        write_next_state <= START_WRITE;
                    end
                end
                WAIT_WRITE_DATA: begin
                    if (m_axi_wlast && m_axi_wready) begin
                        write_next_state <= WAIT_WRITE_RESP;
                    end else begin
                        write_next_state <= WAIT_WRITE_DATA;
                    end
                end
                WAIT_WRITE_RESP: begin
                    if (m_axi_bvalid) begin
                        write_active <= 0;
                        write_desc_valid <= 0;
                        write_next_state <= IDLE;
                    end else begin
                        write_next_state <= WAIT_WRITE_RESP;
                    end
                end
            endcase
        end
    end

    // AXI read address channel
    assign m_axi_arid = read_id;
    assign m_axi_araddr = read_addr;
    assign m_axi_arlen = read_len[7:0] < AXI_MAX_BURST_LEN ? read_len[7:0] : AXI_MAX_BURST_LEN - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Non-cacheable, bufferable
    assign m_axi_arprot = 3'b000; // Normal, non-secure, data
    assign m_axi_arvalid = read_active && !m_axi_arready;

    // AXI read data channel
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid;
    assign m_axis_read_data_tlast = m_axi_rlast;
    assign m_axis_read_data_tid = read_id;
    assign m_axis_read_data_tdest = read_dest;
    assign m_axis_read_data_tuser = read_user;
    assign m_axi_rready = m_axis_read_data_tready;

    // AXI write address channel
    assign m_axi_awid = write_id;
    assign m_axi_awaddr = write_addr;
    assign m_axi_awlen = write_len[7:0] < AXI_MAX_BURST_LEN ? write_len[7:0] : AXI_MAX_BURST_LEN - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Non-cacheable, bufferable
    assign m_axi_awprot = 3'b000; // Normal, non-secure, data
    assign m_axi_awvalid = write_active && !m_axi_awready;

    // AXI write data channel
    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = s_axis_write_data_tlast;
    assign m_axi_wvalid = write_active && s_axis_write_data_tvalid;
    assign s_axis_write_data_tready = m_axi_wready;

    // AXI write response channel
    assign m_axi_bready = 1'b1;

    // Output assignments
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_tag;
    assign m_axis_read_desc_status_error = read_error;
    assign m_axis_read_desc_status_valid = !read_active && read_desc_valid;

    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_len;
    assign m_axis_write_desc_status_tag = write_tag;
    assign m_axis_write_desc_status_id = write_id;
    assign m_axis_write_desc_status_dest = write_dest;
    assign m_axis_write_desc_status_user = write_user;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = !write_active && write_desc_valid;

endmodule
