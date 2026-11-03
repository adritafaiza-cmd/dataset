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

    // Internal signals for read descriptor handling
    reg [AXI_ADDR_WIDTH-1:0]          read_addr;
    reg [LEN_WIDTH-1:0]               read_len;
    reg [TAG_WIDTH-1:0]               read_tag;
    reg [AXIS_ID_WIDTH-1:0]           read_id;
    reg [AXIS_DEST_WIDTH-1:0]         read_dest;
    reg [AXIS_USER_WIDTH-1:0]         read_user;
    reg                               read_desc_valid;
    reg                               read_desc_ready;

    // Internal signals for write descriptor handling
    reg [AXI_ADDR_WIDTH-1:0]          write_addr;
    reg [LEN_WIDTH-1:0]               write_len;
    reg [TAG_WIDTH-1:0]               write_tag;
    reg                               write_desc_valid;
    reg                               write_desc_ready;

    // Internal signals for read data handling
    reg [AXIS_DATA_WIDTH-1:0]         read_data;
    reg [AXIS_KEEP_WIDTH-1:0]         read_keep;
    reg                               read_data_valid;
    reg                               read_data_last;
    reg [AXIS_ID_WIDTH-1:0]           read_data_id;
    reg [AXIS_DEST_WIDTH-1:0]         read_data_dest;
    reg [AXIS_USER_WIDTH-1:0]         read_data_user;

    // Internal signals for write data handling
    reg [AXIS_DATA_WIDTH-1:0]         write_data;
    reg [AXIS_KEEP_WIDTH-1:0]         write_keep;
    reg                               write_data_valid;
    reg                               write_data_last;
    reg [AXIS_ID_WIDTH-1:0]           write_data_id;
    reg [AXIS_DEST_WIDTH-1:0]         write_data_dest;
    reg [AXIS_USER_WIDTH-1:0]         write_data_user;

    // Internal signals for read/write status
    reg [TAG_WIDTH-1:0]               read_status_tag;
    reg [3:0]                         read_status_error;
    reg                               read_status_valid;
    reg [LEN_WIDTH-1:0]               write_status_len;
    reg [TAG_WIDTH-1:0]               write_status_tag;
    reg [AXIS_ID_WIDTH-1:0]           write_status_id;
    reg [AXIS_DEST_WIDTH-1:0]         write_status_dest;
    reg [AXIS_USER_WIDTH-1:0]         write_status_user;
    reg [3:0]                         write_status_error;
    reg                               write_status_valid;

    // Internal state machines
    reg [1:0]                         read_state;
    reg [1:0]                         write_state;

    // State definitions
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam DONE = 2'b10;

    // AXI read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE;
            read_desc_ready <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
            read_status_valid <= 0;
        end else begin
            case (read_state)
                IDLE: begin
                    read_desc_ready <= 1;
                    if (s_axis_read_desc_valid && read_enable) begin
                        read_desc_ready <= 0;
                        read_addr <= s_axis_read_desc_addr;
                        read_len <= s_axis_read_desc_len;
                        read_tag <= s_axis_read_desc_tag;
                        read_id <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_state <= ACTIVE;
                        m_axi_arid <= s_axis_read_desc_id;
                        m_axi_araddr <= s_axis_read_desc_addr;
                        m_axi_arlen <= s_axis_read_desc_len[7:0] - 1; // AXI len is one less than transfer size
                        m_axi_arsize <= $clog2(AXI_DATA_WIDTH / 8); // size in bytes
                        m_axi_arburst <= 2'b01; // INCR
                        m_axi_arlock <= 1'b0;
                        m_axi_arcache <= 4'b0011; // Non-cacheable, Bufferable, Modifiable
                        m_axi_arprot <= 3'b000; // Normal, Non-secure, Data
                        m_axi_arvalid <= 1;
                    end
                end
                ACTIVE: begin
                    m_axi_arvalid <= 0;
                    if (m_axi_arready) begin
                        read_state <= ACTIVE;
                    end
                    if (m_axi_rvalid) begin
                        read_data <= m_axi_rdata;
                        read_keep <= {AXIS_KEEP_WIDTH{1'b1}};
                        read_data_valid <= 1;
                        read_data_last <= m_axi_rlast;
                        m_axi_rready <= 1;
                        if (m_axi_rlast) begin
                            read_data_last <= 1;
                            read_state <= DONE;
                            read_status_tag <= read_tag;
                            read_status_error <= m_axi_rresp == 2'b00 ? 4'b0000 : 4'b0001;
                            read_status_valid <= 1;
                        end
                    end
                end
                DONE: begin
                    read_data_valid <= 0;
                    read_data_last <= 0;
                    read_status_valid <= 0;
                    if (!m_axi_rvalid) begin
                        read_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // AXI write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= IDLE;
            write_desc_ready <= 0;
            write_data_valid <= 0;
            write_data_last <= 0;
            write_status_valid <= 0;
        end else begin
            case (write_state)
                IDLE: begin
                    write_desc_ready <= 1;
                    if (s_axis_write_desc_valid && write_enable) begin
                        write_desc_ready <= 0;
                        write_addr <= s_axis_write_desc_addr;
                        write_len <= s_axis_write_desc_len;
                        write_tag <= s_axis_write_desc_tag;
                        write_state <= ACTIVE;
                        m_axi_awid <= 0;
                        m_axi_awaddr <= s_axis_write_desc_addr;
                        m_axi_awlen <= s_axis_write_desc_len[7:0] - 1; // AXI len is one less than transfer size
                        m_axi_awsize <= $clog2(AXI_DATA_WIDTH / 8); // size in bytes
                        m_axi_awburst <= 2'b01; // INCR
                        m_axi_awlock <= 1'b0;
                        m_axi_awcache <= 4'b0011; // Non-cacheable, Bufferable, Modifiable
                        m_axi_awprot <= 3'b000; // Normal, Non-secure, Data
                        m_axi_awvalid <= 1;
                    end
                end
                ACTIVE: begin
                    m_axi_awvalid <= 0;
                    if (m_axi_awready) begin
                        write_state <= ACTIVE;
                    end
                    if (s_axis_write_data_valid) begin
                        write_data <= s_axis_write_data_tdata;
                        write_keep <= s_axis_write_data_tkeep;
                        write_data_valid <= 1;
                        write_data_last <= s_axis_write_data_tlast;
                        m_axi_wdata <= s_axis_write_data_tdata;
                        m_axi_wstrb <= s_axis_write_data_tkeep;
                        m_axi_wlast <= s_axis_write_data_tlast;
                        m_axi_wvalid <= 1;
                        s_axis_write_data_tready <= 1;
                        if (s_axis_write_data_tlast) begin
                            write_state <= DONE;
                            write_status_len <= write_len;
                            write_status_tag <= write_tag;
                            write_status_id <= write_id;
                            write_status_dest <= write_dest;
                            write_status_user <= write_user;
                            write_status_error <= 4'b0000;
                            write_status_valid <= 1;
                        end
                    end
                end
                DONE: begin
                    write_data_valid <= 0;
                    write_data_last <= 0;
                    write_status_valid <= 0;
                    m_axi_wvalid <= 0;
                    s_axis_write_data_tready <= 0;
                    if (m_axi_bvalid) begin
                        write_status_error <= m_axi_bresp == 2'b00 ? 4'b0000 : 4'b0001;
                        write_status_valid <= 1;
                        m_axi_bready <= 1;
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign s_axis_read_desc_ready = read_desc_ready;
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;
    assign m_axis_read_data_tdata = read_data;
    assign m_axis_read_data_tkeep = read_keep;
    assign m_axis_read_data_tvalid = read_data_valid;
    assign m_axis_read_data_tlast = read_data_last;
    assign m_axis_read_data_tid = read_data_id;
    assign m_axis_read_data_tdest = read_data_dest;
    assign m_axis_read_data_tuser = read_data_user;

    assign s_axis_write_desc_ready = write_desc_ready;
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;
    assign s_axis_write_data_tready = (write_state == ACTIVE) && m_axi_wready;

endmodule
