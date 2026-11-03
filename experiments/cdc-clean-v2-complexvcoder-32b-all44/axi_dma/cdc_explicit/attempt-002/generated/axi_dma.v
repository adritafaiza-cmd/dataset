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

    // Internal states
    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [TAG_WIDTH-1:0] read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_user_reg;
    reg read_desc_valid_reg;
    reg read_desc_ready_reg;
    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [TAG_WIDTH-1:0] write_tag_reg;
    reg write_desc_valid_reg;
    reg write_desc_ready_reg;
    reg [LEN_WIDTH-1:0] write_len_counter;
    reg [LEN_WIDTH-1:0] read_len_counter;
    reg [AXI_ADDR_WIDTH-1:0] write_addr_counter;
    reg [AXI_ADDR_WIDTH-1:0] read_addr_counter;
    reg [3:0] read_error_reg;
    reg [3:0] write_error_reg;
    reg read_desc_status_valid_reg;
    reg write_desc_status_valid_reg;

    // Read state machine
    typedef enum reg [2:0] {
        IDLE,
        READ_ADDR,
        READ_DATA,
        READ_WAIT_RESP
    } read_state_t;

    read_state_t read_state, read_next_state;

    // Write state machine
    typedef enum reg [2:0] {
        WRITE_IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_WAIT_RESP
    } write_state_t;

    write_state_t write_state, write_next_state;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE;
            read_addr_reg <= 0;
            read_len_reg <= 0;
            read_tag_reg <= 0;
            read_id_reg <= 0;
            read_dest_reg <= 0;
            read_user_reg <= 0;
            read_desc_valid_reg <= 0;
            read_desc_ready_reg <= 0;
            read_error_reg <= 0;
            read_len_counter <= 0;
            read_addr_counter <= 0;
            read_desc_status_valid_reg <= 0;
        end else begin
            read_state <= read_next_state;
            case (read_state)
                IDLE: begin
                    read_addr_reg <= s_axis_read_desc_addr;
                    read_len_reg <= s_axis_read_desc_len;
                    read_tag_reg <= s_axis_read_desc_tag;
                    read_id_reg <= s_axis_read_desc_id;
                    read_dest_reg <= s_axis_read_desc_dest;
                    read_user_reg <= s_axis_read_desc_user;
                    read_desc_valid_reg <= s_axis_read_desc_valid;
                    read_desc_ready_reg <= 1;
                    read_error_reg <= 0;
                    read_len_counter <= s_axis_read_desc_len;
                    read_addr_counter <= s_axis_read_desc_addr;
                    read_desc_status_valid_reg <= 0;
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_next_state <= READ_ADDR;
                        read_desc_ready_reg <= 0;
                    end else begin
                        read_next_state <= IDLE;
                    end
                end
                READ_ADDR: begin
                    if (m_axi_arready) begin
                        read_next_state <= READ_DATA;
                    end else begin
                        read_next_state <= READ_ADDR;
                    end
                end
                READ_DATA: begin
                    if (m_axi_rvalid && m_axis_read_data_tready) begin
                        read_len_counter <= read_len_counter - 1;
                        read_addr_counter <= read_addr_counter + AXI_DATA_WIDTH/8;
                        if (read_len_counter == 1) begin
                            read_next_state <= READ_WAIT_RESP;
                        end else begin
                            read_next_state <= READ_DATA;
                        end
                    end else begin
                        read_next_state <= READ_DATA;
                    end
                end
                READ_WAIT_RESP: begin
                    if (m_axi_rvalid && m_axi_rlast) begin
                        read_next_state <= IDLE;
                        read_desc_status_valid_reg <= 1;
                    end else begin
                        read_next_state <= READ_WAIT_RESP;
                    end
                end
                default: begin
                    read_next_state <= IDLE;
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            write_addr_reg <= 0;
            write_len_reg <= 0;
            write_tag_reg <= 0;
            write_desc_valid_reg <= 0;
            write_desc_ready_reg <= 0;
            write_error_reg <= 0;
            write_len_counter <= 0;
            write_addr_counter <= 0;
            write_desc_status_valid_reg <= 0;
        end else begin
            write_state <= write_next_state;
            case (write_state)
                WRITE_IDLE: begin
                    write_addr_reg <= s_axis_write_desc_addr;
                    write_len_reg <= s_axis_write_desc_len;
                    write_tag_reg <= s_axis_write_desc_tag;
                    write_desc_valid_reg <= s_axis_write_desc_valid;
                    write_desc_ready_reg <= 1;
                    write_error_reg <= 0;
                    write_len_counter <= s_axis_write_desc_len;
                    write_addr_counter <= s_axis_write_desc_addr;
                    write_desc_status_valid_reg <= 0;
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_next_state <= WRITE_ADDR;
                        write_desc_ready_reg <= 0;
                    end else begin
                        write_next_state <= WRITE_IDLE;
                    end
                end
                WRITE_ADDR: begin
                    if (m_axi_awready) begin
                        write_next_state <= WRITE_DATA;
                    end else begin
                        write_next_state <= WRITE_ADDR;
                    end
                end
                WRITE_DATA: begin
                    if (m_axi_wready && s_axis_write_data_tvalid) begin
                        write_len_counter <= write_len_counter - 1;
                        write_addr_counter <= write_addr_counter + AXI_DATA_WIDTH/8;
                        if (write_len_counter == 1) begin
                            write_next_state <= WRITE_WAIT_RESP;
                        end else begin
                            write_next_state <= WRITE_DATA;
                        end
                    end else begin
                        write_next_state <= WRITE_DATA;
                    end
                end
                WRITE_WAIT_RESP: begin
                    if (m_axi_bvalid) begin
                        write_next_state <= WRITE_IDLE;
                        write_desc_status_valid_reg <= 1;
                    end else begin
                        write_next_state <= WRITE_WAIT_RESP;
                    end
                end
                default: begin
                    write_next_state <= WRITE_IDLE;
                end
            endcase
        end
    end

    // Read descriptor status output
    assign m_axis_read_desc_status_tag = read_tag_reg;
    assign m_axis_read_desc_status_error = read_error_reg;
    assign m_axis_read_desc_status_valid = read_desc_status_valid_reg;

    // Read data output
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};
    assign m_axis_read_data_tvalid = m_axi_rvalid && (read_state == READ_DATA);
    assign m_axis_read_data_tlast = m_axi_rlast && (read_state == READ_DATA);
    assign m_axis_read_data_tid = read_id_reg;
    assign m_axis_read_data_tdest = read_dest_reg;
    assign m_axis_read_data_tuser = read_user_reg;
    assign m_axi_rready = (read_state == READ_DATA);

    // Write descriptor status output
    assign m_axis_write_desc_status_len = write_len_reg;
    assign m_axis_write_desc_status_tag = write_tag_reg;
    assign m_axis_write_desc_status_id = s_axis_write_desc_id;
    assign m_axis_write_desc_status_dest = s_axis_write_desc_dest;
    assign m_axis_write_desc_status_user = s_axis_write_desc_user;
    assign m_axis_write_desc_status_error = write_error_reg;
    assign m_axis_write_desc_status_valid = write_desc_status_valid_reg;

    // Write data input
    assign s_axis_write_data_tready = (write_state == WRITE_DATA) && m_axi_wready;
    assign m_axi_wdata = s_axis_write_data_tdata;
    assign m_axi_wstrb = s_axis_write_data_tkeep;
    assign m_axi_wlast = (write_len_counter == 1) && (write_state == WRITE_DATA);
    assign m_axi_wvalid = s_axis_write_data_tvalid && (write_state == WRITE_DATA);

    // AXI write address channel
    assign m_axi_awid = write_id_reg;
    assign m_axi_awaddr = write_addr_counter;
    assign m_axi_awlen = write_len_counter - 1;
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011; // Normal Non-cacheable Bufferable
    assign m_axi_awprot = 3'b000;
    assign m_axi_awvalid = (write_state == WRITE_ADDR);

    // AXI read address channel
    assign m_axi_arid = read_id_reg;
    assign m_axi_araddr = read_addr_counter;
    assign m_axi_arlen = read_len_counter - 1;
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011; // Normal Non-cacheable Bufferable
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = (read_state == READ_ADDR);

    // AXI write response channel
    assign m_axi_bready = (write_state == WRITE_WAIT_RESP);

    // Descriptor ready outputs
    assign s_axis_read_desc_ready = read_desc_ready_reg;
    assign s_axis_write_desc_ready = write_desc_ready_reg;

endmodule
