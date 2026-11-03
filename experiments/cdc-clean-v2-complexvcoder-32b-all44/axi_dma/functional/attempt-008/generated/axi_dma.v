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
    reg  [AXI_ADDR_WIDTH-1:0] read_addr;
    reg  [LEN_WIDTH-1:0]      read_len;
    reg  [TAG_WIDTH-1:0]      read_tag;
    reg  [AXIS_ID_WIDTH-1:0]  read_id;
    reg  [AXIS_DEST_WIDTH-1:0]read_dest;
    reg  [AXIS_USER_WIDTH-1:0]read_user;
    reg                       read_desc_ready;
    reg  [TAG_WIDTH-1:0]      read_status_tag;
    reg  [3:0]                read_status_error;
    reg                       read_status_valid;
    reg  [AXIS_DATA_WIDTH-1:0]read_data_tdata;
    reg  [AXIS_KEEP_WIDTH-1:0]read_data_tkeep;
    reg                       read_data_tvalid;
    reg                       read_data_tlast;
    reg  [AXIS_ID_WIDTH-1:0]  read_data_tid;
    reg  [AXIS_DEST_WIDTH-1:0]read_data_tdest;
    reg  [AXIS_USER_WIDTH-1:0]read_data_tuser;
    reg                       read_data_tready;

    reg  [AXI_ADDR_WIDTH-1:0] write_addr;
    reg  [LEN_WIDTH-1:0]      write_len;
    reg  [TAG_WIDTH-1:0]      write_tag;
    reg                       write_desc_ready;
    reg  [LEN_WIDTH-1:0]      write_status_len;
    reg  [TAG_WIDTH-1:0]      write_status_tag;
    reg  [AXIS_ID_WIDTH-1:0]  write_status_id;
    reg  [AXIS_DEST_WIDTH-1:0]write_status_dest;
    reg  [AXIS_USER_WIDTH-1:0]write_status_user;
    reg  [3:0]                write_status_error;
    reg                       write_status_valid;
    reg                       write_data_tready;

    // Read FSM states
    typedef enum logic [2:0] {
        IDLE_READ,
        START_READ,
        READ_DATA,
        FINISH_READ
    } read_state_t;

    read_state_t read_state, read_next_state;

    // Write FSM states
    typedef enum logic [2:0] {
        IDLE_WRITE,
        START_WRITE,
        WRITE_DATA,
        FINISH_WRITE
    } write_state_t;

    write_state_t write_state, write_next_state;

    // Read FSM logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE_READ;
        end else begin
            read_state <= read_next_state;
        end
    end

    always_comb begin
        read_next_state = read_state;
        read_addr = s_axis_read_desc_addr;
        read_len = s_axis_read_desc_len;
        read_tag = s_axis_read_desc_tag;
        read_id = s_axis_read_desc_id;
        read_dest = s_axis_read_desc_dest;
        read_user = s_axis_read_desc_user;
        read_desc_ready = 1'b0;
        read_status_tag = read_tag;
        read_status_error = 4'b0;
        read_status_valid = 1'b0;
        read_data_tdata = m_axi_rdata;
        read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
        read_data_tvalid = m_axi_rvalid;
        read_data_tlast = m_axi_rlast;
        read_data_tid = read_id;
        read_data_tdest = read_dest;
        read_data_tuser = read_user;
        read_data_tready = m_axi_rready;

        case (read_state)
            IDLE_READ: begin
                if (s_axis_read_desc_valid && read_enable) begin
                    read_next_state = START_READ;
                    read_desc_ready = 1'b1;
                end
            end
            START_READ: begin
                m_axi_arid = read_id;
                m_axi_araddr = read_addr;
                m_axi_arlen = read_len[7:0]; // Assuming LEN_WIDTH >= 8, truncate if necessary
                m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
                m_axi_arburst = 2'b01; // INCR burst type
                m_axi_arlock = 1'b0;
                m_axi_arcache = 4'b0011; // Non-cacheable, bufferable, modifiable
                m_axi_arprot = 3'b000; // Normal non-secure data access
                m_axi_arvalid = 1'b1;

                if (m_axi_arready) begin
                    read_next_state = READ_DATA;
                end
            end
            READ_DATA: begin
                if (m_axi_rvalid && read_data_tready) begin
                    if (m_axi_rlast) begin
                        read_next_state = FINISH_READ;
                        read_status_valid = 1'b1;
                    end
                end
            end
            FINISH_READ: begin
                if (read_status_valid && !m_axis_read_desc_status_valid) begin
                    read_next_state = IDLE_READ;
                end
            end
        endcase
    end

    // Write FSM logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= IDLE_WRITE;
        end else begin
            write_state <= write_next_state;
        end
    end

    always_comb begin
        write_next_state = write_state;
        write_addr = s_axis_write_desc_addr;
        write_len = s_axis_write_desc_len;
        write_tag = s_axis_write_desc_tag;
        write_desc_ready = 1'b0;
        write_status_len = write_len;
        write_status_tag = write_tag;
        write_status_id = s_axis_write_desc_id;
        write_status_dest = s_axis_write_desc_dest;
        write_status_user = s_axis_write_desc_user;
        write_status_error = 4'b0;
        write_status_valid = 1'b0;
        write_data_tready = m_axi_wready;

        case (write_state)
            IDLE_WRITE: begin
                if (s_axis_write_desc_valid && write_enable) begin
                    write_next_state = START_WRITE;
                    write_desc_ready = 1'b1;
                end
            end
            START_WRITE: begin
                m_axi_awid = write_status_id;
                m_axi_awaddr = write_addr;
                m_axi_awlen = write_len[7:0]; // Assuming LEN_WIDTH >= 8, truncate if necessary
                m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
                m_axi_awburst = 2'b01; // INCR burst type
                m_axi_awlock = 1'b0;
                m_axi_awcache = 4'b0011; // Non-cacheable, bufferable, modifiable
                m_axi_awprot = 3'b000; // Normal non-secure data access
                m_axi_awvalid = 1'b1;

                if (m_axi_awready) begin
                    write_next_state = WRITE_DATA;
                end
            end
            WRITE_DATA: begin
                m_axi_wdata = s_axis_write_data_tdata;
                m_axi_wstrb = s_axis_write_data_tkeep;
                m_axi_wlast = s_axis_write_data_tlast;
                m_axi_wvalid = s_axis_write_data_tvalid;

                if (m_axi_wvalid && m_axi_wready && s_axis_write_data_tlast) begin
                    write_next_state = FINISH_WRITE;
                end
            end
            FINISH_WRITE: begin
                if (m_axi_bvalid) begin
                    write_status_valid = 1'b1;
                    if (write_status_valid && !m_axis_write_desc_status_valid) begin
                        write_next_state = IDLE_WRITE;
                    end
                end
            end
        endcase
    end

    // Output assignments
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;
    assign m_axis_read_data_tdata = read_data_tdata;
    assign m_axis_read_data_tkeep = read_data_tkeep;
    assign m_axis_read_data_tvalid = read_data_tvalid;
    assign m_axis_read_data_tlast = read_data_tlast;
    assign m_axis_read_data_tid = read_data_tid;
    assign m_axis_read_data_tdest = read_data_tdest;
    assign m_axis_read_data_tuser = read_data_tuser;
    assign m_axis_read_data_tready = read_data_tready;

    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;
    assign s_axis_write_data_tready = write_data_tready;

endmodule
