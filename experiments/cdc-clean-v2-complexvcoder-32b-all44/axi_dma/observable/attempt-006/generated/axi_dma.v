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
    reg [AXI_ADDR_WIDTH-1:0]          read_addr;
    reg [LEN_WIDTH-1:0]               read_len;
    reg [TAG_WIDTH-1:0]               read_tag;
    reg [AXIS_ID_WIDTH-1:0]           read_id;
    reg [AXIS_DEST_WIDTH-1:0]         read_dest;
    reg [AXIS_USER_WIDTH-1:0]         read_user;
    reg [AXI_ADDR_WIDTH-1:0]          write_addr;
    reg [LEN_WIDTH-1:0]               write_len;
    reg [TAG_WIDTH-1:0]               write_tag;
    reg [AXIS_ID_WIDTH-1:0]           write_id;
    reg [AXIS_DEST_WIDTH-1:0]         write_dest;
    reg [AXIS_USER_WIDTH-1:0]         write_user;
    reg [AXI_DATA_WIDTH-1:0]          read_data;
    reg [AXIS_KEEP_WIDTH-1:0]         read_keep;
    reg                               read_last;
    reg [AXIS_ID_WIDTH-1:0]           read_tid;
    reg [AXIS_DEST_WIDTH-1:0]         read_tdest;
    reg [AXIS_USER_WIDTH-1:0]         read_tuser;
    reg [LEN_WIDTH-1:0]               write_data_len;
    reg [3:0]                         read_error;
    reg [3:0]                         write_error;
    reg                               read_status_valid;
    reg                               write_status_valid;
    reg                               read_data_valid;
    reg                               read_data_last;
    reg                               write_data_ready;
    reg                               write_data_last;
    reg                               read_desc_ready;
    reg                               write_desc_ready;
    reg                               read_active;
    reg                               write_active;
    reg                               write_aborted;

    // State machine states
    typedef enum reg [2:0] {
        IDLE,
        READ_DESC,
        READ_DATA,
        WRITE_DESC,
        WRITE_DATA
    } state_t;

    state_t state, next_state;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (read_enable && s_axis_read_desc_valid) begin
                    next_state = READ_DESC;
                end else if (write_enable && s_axis_write_desc_valid) begin
                    next_state = WRITE_DESC;
                end
            end
            READ_DESC: begin
                next_state = READ_DATA;
            end
            READ_DATA: begin
                if (m_axis_read_data_tready && read_last) begin
                    next_state = IDLE;
                end
            end
            WRITE_DESC: begin
                next_state = WRITE_DATA;
            end
            WRITE_DATA: begin
                if (write_data_last && m_axi_bvalid) begin
                    next_state = IDLE;
                end else if (write_abort) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Read descriptor processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_addr <= 0;
            read_len <= 0;
            read_tag <= 0;
            read_id <= 0;
            read_dest <= 0;
            read_user <= 0;
            read_desc_ready <= 0;
            read_active <= 0;
            read_error <= 0;
        end else if (state == READ_DESC) begin
            read_addr <= s_axis_read_desc_addr;
            read_len <= s_axis_read_desc_len;
            read_tag <= s_axis_read_desc_tag;
            read_id <= s_axis_read_desc_id;
            read_dest <= s_axis_read_desc_dest;
            read_user <= s_axis_read_desc_user;
            read_desc_ready <= 1;
            read_active <= 1;
            read_error <= 0;
        end else if (state == READ_DATA && m_axis_read_data_tready && read_last) begin
            read_desc_ready <= 0;
            read_active <= 0;
        end
    end

    // Read data processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data <= 0;
            read_keep <= 0;
            read_last <= 0;
            read_tid <= 0;
            read_tdest <= 0;
            read_tuser <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
        end else if (state == READ_DATA && m_axi_rvalid) begin
            read_data <= m_axi_rdata;
            read_keep <= {AXIS_KEEP_WIDTH{1'b1}};
            read_last <= m_axi_rlast;
            read_tid <= read_id;
            read_tdest <= read_dest;
            read_tuser <= read_user;
            read_data_valid <= 1;
            read_data_last <= m_axi_rlast;
        end else if (state == READ_DATA && m_axis_read_data_tready) begin
            read_data_valid <= 0;
            read_data_last <= 0;
        end
    end

    // Write descriptor processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_addr <= 0;
            write_len <= 0;
            write_tag <= 0;
            write_id <= 0;
            write_dest <= 0;
            write_user <= 0;
            write_desc_ready <= 0;
            write_active <= 0;
            write_error <= 0;
            write_aborted <= 0;
        end else if (state == WRITE_DESC) begin
            write_addr <= s_axis_write_desc_addr;
            write_len <= s_axis_write_desc_len;
            write_tag <= s_axis_write_desc_tag;
            write_id <= s_axis_write_desc_id;
            write_dest <= s_axis_write_desc_dest;
            write_user <= s_axis_write_desc_user;
            write_desc_ready <= 1;
            write_active <= 1;
            write_error <= 0;
            write_aborted <= 0;
        end else if (state == WRITE_DATA && write_data_last && m_axi_bvalid) begin
            write_desc_ready <= 0;
            write_active <= 0;
        end else if (state == WRITE_DATA && write_abort) begin
            write_aborted <= 1;
            write_desc_ready <= 0;
            write_active <= 0;
        end
    end

    // Write data processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_data_ready <= 0;
            write_data_last <= 0;
            write_data_len <= 0;
        end else if (state == WRITE_DATA && s_axis_write_data_tvalid) begin
            write_data_ready <= 1;
            write_data_last <= s_axis_write_data_tlast;
            write_data_len <= write_data_len - 1;
        end else if (state == WRITE_DATA && m_axi_wready) begin
            write_data_ready <= 0;
        end
    end

    // AXI master read interface
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
        end else if (state == READ_DATA && !m_axi_arvalid) begin
            m_axi_arid <= read_id;
            m_axi_araddr <= read_addr;
            m_axi_arlen <= read_len[7:0] - 1;
            m_axi_arsize <= $clog2(AXI_DATA_WIDTH/8);
            m_axi_arburst <= 2'b01; // INCR
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            m_axi_arvalid <= 1;
        end else if (m_axi_arready) begin
            m_axi_arvalid <= 0;
        end
    end

    // AXI master write interface
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
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
        end else if (state == WRITE_DATA) begin
            if (!m_axi_awvalid) begin
                m_axi_awid <= write_id;
                m_axi_awaddr <= write_addr;
                m_axi_awlen <= write_len[7:0] - 1;
                m_axi_awsize <= $clog2(AXI_DATA_WIDTH/8);
                m_axi_awburst <= 2'b01; // INCR
                m_axi_awlock <= 0;
                m_axi_awcache <= 0;
                m_axi_awprot <= 0;
                m_axi_awvalid <= 1;
            end else if (m_axi_awready) begin
                m_axi_awvalid <= 0;
            end

            if (write_data_ready && s_axis_write_data_tvalid && !m_axi_wvalid) begin
                m_axi_wdata <= s_axis_write_data_tdata;
                m_axi_wstrb <= s_axis_write_data_tkeep;
                m_axi_wlast <= s_axis_write_data_tlast;
                m_axi_wvalid <= 1;
            end else if (m_axi_wready) begin
                m_axi_wvalid <= 0;
            end

            if (m_axi_bvalid) begin
                m_axi_bready <= 1;
            end else begin
                m_axi_bready <= 0;
            end
        end
    end

    // Status outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_desc_status_tag <= 0;
            m_axis_read_desc_status_error <= 0;
            m_axis_read_desc_status_valid <= 0;
            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 0;
            m_axis_write_desc_status_valid <= 0;
        end else begin
            if (state == READ_DATA && m_axis_read_data_tready && read_last) begin
                m_axis_read_desc_status_tag <= read_tag;
                m_axis_read_desc_status_error <= read_error;
                m_axis_read_desc_status_valid <= 1;
            end else if (m_axis_read_desc_status_valid && m_axis_read_data_tready) begin
                m_axis_read_desc_status_valid <= 0;
            end

            if (state == WRITE_DATA && write_data_last && m_axi_bvalid) begin
                m_axis_write_desc_status_len <= write_len;
                m_axis_write_desc_status_tag <= write_tag;
                m_axis_write_desc_status_id <= write_id;
                m_axis_write_desc_status_dest <= write_dest;
                m_axis_write_desc_status_user <= write_user;
                m_axis_write_desc_status_error <= write_error;
                m_axis_write_desc_status_valid <= 1;
            end else if (m_axis_write_desc_status_valid && m_axis_read_data_tready) begin
                m_axis_write_desc_status_valid <= 0;
            end
        end
    end

    // AXI stream outputs
    assign m_axis_read_data_tdata = read_data;
    assign m_axis_read_data_tkeep = read_keep;
    assign m_axis_read_data_tvalid = read_data_valid;
    assign m_axis_read_data_tlast = read_data_last;
    assign m_axis_read_data_tid = read_tid;
    assign m_axis_read_data_tdest = read_tdest;
    assign m_axis_read_data_tuser = read_tuser;

    // AXI stream inputs
    assign s_axis_write_data_tready = write_data_ready;

    // Descriptor ready outputs
    assign s_axis_read_desc_ready = read_desc_ready;
    assign s_axis_write_desc_ready = write_desc_ready;

    // Status outputs
    assign m_axis_read_desc_status_tag = read_tag;
    assign m_axis_read_desc_status_error = read_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    assign m_axis_write_desc_status_len = write_len;
    assign m_axis_write_desc_status_tag = write_tag;
    assign m_axis_write_desc_status_id = write_id;
    assign m_axis_write_desc_status_dest = write_dest;
    assign m_axis_write_desc_status_user = write_user;
    assign m_axis_write_desc_status_error = write_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

endmodule
