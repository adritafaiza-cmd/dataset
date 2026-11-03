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

    // FIFO for read descriptors
    reg [AXI_ADDR_WIDTH-1:0]  read_desc_addr_reg;
    reg [LEN_WIDTH-1:0]       read_desc_len_reg;
    reg [TAG_WIDTH-1:0]       read_desc_tag_reg;
    reg [AXIS_ID_WIDTH-1:0]   read_desc_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_desc_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_desc_user_reg;
    reg                       read_desc_valid_reg;
    reg                       read_desc_ready_reg;

    // FIFO for write descriptors
    reg [AXI_ADDR_WIDTH-1:0]  write_desc_addr_reg;
    reg [LEN_WIDTH-1:0]       write_desc_len_reg;
    reg [TAG_WIDTH-1:0]       write_desc_tag_reg;
    reg                       write_desc_valid_reg;
    reg                       write_desc_ready_reg;

    // FIFO for read data
    reg [AXIS_DATA_WIDTH-1:0] read_data_reg;
    reg                       read_data_valid_reg;
    reg                       read_data_ready_reg;

    // FIFO for write data
    reg [AXIS_DATA_WIDTH-1:0] write_data_reg;
    reg                       write_data_valid_reg;
    reg                       write_data_ready_reg;

    // State machines for read and write operations
    typedef enum reg [1:0] {
        IDLE,
        ACTIVE,
        DONE
    } state_t;

    state_t read_state, read_next_state;
    state_t write_state, write_next_state;

    // Read FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= IDLE;
        end else begin
            read_state <= read_next_state;
        end
    end

    always @(*) begin
        read_next_state = read_state;
        case (read_state)
            IDLE: begin
                if (read_enable && read_desc_valid_reg) begin
                    read_next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (m_axi_rlast && m_axi_rvalid && m_axi_rready) begin
                    read_next_state = DONE;
                end
            end
            DONE: begin
                if (m_axis_read_desc_status_valid) begin
                    read_next_state = IDLE;
                end
            end
        endcase
    end

    // Write FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= IDLE;
        end else begin
            write_state <= write_next_state;
        end
    end

    always @(*) begin
        write_next_state = write_state;
        case (write_state)
            IDLE: begin
                if (write_enable && write_desc_valid_reg) begin
                    write_next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (m_axi_bvalid && m_axi_bready) begin
                    write_next_state = DONE;
                end
            end
            DONE: begin
                if (m_axis_write_desc_status_valid) begin
                    write_next_state = IDLE;
                end
            end
        endcase
    end

    // Read descriptor FIFO
    read_desc_fifo #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH(AXIS_USER_WIDTH)
    ) read_desc_fifo_inst (
        .clk(clk),
        .rst(rst),
        .din_addr(s_axis_read_desc_addr),
        .din_len(s_axis_read_desc_len),
        .din_tag(s_axis_read_desc_tag),
        .din_id(s_axis_read_desc_id),
        .din_dest(s_axis_read_desc_dest),
        .din_user(s_axis_read_desc_user),
        .din_valid(s_axis_read_desc_valid),
        .din_ready(s_axis_read_desc_ready),
        .dout_addr(read_desc_addr_reg),
        .dout_len(read_desc_len_reg),
        .dout_tag(read_desc_tag_reg),
        .dout_id(read_desc_id_reg),
        .dout_dest(read_desc_dest_reg),
        .dout_user(read_desc_user_reg),
        .dout_valid(read_desc_valid_reg),
        .dout_ready(read_desc_ready_reg)
    );

    // Write descriptor FIFO
    write_desc_fifo #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    ) write_desc_fifo_inst (
        .clk(clk),
        .rst(rst),
        .din_addr(s_axis_write_desc_addr),
        .din_len(s_axis_write_desc_len),
        .din_tag(s_axis_write_desc_tag),
        .din_valid(s_axis_write_desc_valid),
        .din_ready(s_axis_write_desc_ready),
        .dout_addr(write_desc_addr_reg),
        .dout_len(write_desc_len_reg),
        .dout_tag(write_desc_tag_reg),
        .dout_valid(write_desc_valid_reg),
        .dout_ready(write_desc_ready_reg)
    );

    // Read data FIFO
    read_data_fifo #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
    ) read_data_fifo_inst (
        .clk(clk),
        .rst(rst),
        .din_data(m_axi_rdata),
        .din_valid(m_axi_rvalid),
        .din_ready(m_axi_rready),
        .din_last(m_axi_rlast),
        .dout_data(m_axis_read_data_tdata),
        .dout_valid(m_axis_read_data_tvalid),
        .dout_ready(m_axis_read_data_tready),
        .dout_last(m_axis_read_data_tlast)
    );

    // Write data FIFO
    write_data_fifo #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
    ) write_data_fifo_inst (
        .clk(clk),
        .rst(rst),
        .din_data(s_axis_write_data_tdata),
        .din_valid(s_axis_write_data_tvalid),
        .din_ready(s_axis_write_data_tready),
        .din_last(s_axis_write_data_tlast),
        .dout_data(m_axi_wdata),
        .dout_valid(m_axi_wvalid),
        .dout_ready(m_axi_wready),
        .dout_last(m_axi_wlast)
    );

    // Read control logic
    reg [7:0] read_burst_count;
    reg [LEN_WIDTH-1:0] read_remaining_len;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_burst_count <= 0;
            read_remaining_len <= 0;
            m_axi_arid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 2; // 32-bit transfers
            m_axi_arburst <= 2'b01; // INCR burst
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= 0;
            m_axi_arvalid <= 0;
        end else begin
            case (read_state)
                IDLE: begin
                    read_burst_count <= 0;
                    read_remaining_len <= read_desc_len_reg;
                    m_axi_arid <= read_desc_id_reg;
                    m_axi_araddr <= read_desc_addr_reg;
                    m_axi_arlen <= (read_desc_len_reg < 256) ? read_desc_len_reg - 1 : 255;
                    m_axi_arvalid <= read_desc_valid_reg;
                end
                ACTIVE: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 0;
                    end
                    if (m_axi_rvalid && m_axi_rready) begin
                        if (m_axi_rlast) begin
                            read_remaining_len <= read_remaining_len - (read_burst_count + 1);
                            read_burst_count <= 0;
                            if (read_remaining_len > 0) begin
                                m_axi_arvalid <= 1;
                                m_axi_arlen <= (read_remaining_len < 256) ? read_remaining_len - 1 : 255;
                            end
                        end else begin
                            read_burst_count <= read_burst_count + 1;
                        end
                    end
                end
                DONE: begin
                    m_axi_arvalid <= 0;
                end
            endcase
        end
    end

    // Write control logic
    reg [7:0] write_burst_count;
    reg [LEN_WIDTH-1:0] write_remaining_len;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_burst_count <= 0;
            write_remaining_len <= 0;
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 2; // 32-bit transfers
            m_axi_awburst <= 2'b01; // INCR burst
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= 0;
            m_axi_awvalid <= 0;
            m_axi_wdata <= 0;
            m_axi_wstrb <= {AXI_STRB_WIDTH{1'b1}};
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
        end else begin
            case (write_state)
                IDLE: begin
                    write_burst_count <= 0;
                    write_remaining_len <= write_desc_len_reg;
                    m_axi_awid <= 0;
                    m_axi_awaddr <= write_desc_addr_reg;
                    m_axi_awlen <= (write_desc_len_reg < 256) ? write_desc_len_reg - 1 : 255;
                    m_axi_awvalid <= write_desc_valid_reg;
                    m_axi_wdata <= write_data_reg;
                    m_axi_wlast <= (write_remaining_len <= 256);
                    m_axi_wvalid <= write_data_valid_reg;
                end
                ACTIVE: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 0;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        if (m_axi_wlast) begin
                            write_remaining_len <= write_remaining_len - (write_burst_count + 1);
                            write_burst_count <= 0;
                            if (write_remaining_len > 0) begin
                                m_axi_awvalid <= 1;
                                m_axi_awlen <= (write_remaining_len < 256) ? write_remaining_len - 1 : 255;
                                m_axi_wlast <= (write_remaining_len <= 256);
                            end
                        end else begin
                            write_burst_count <= write_burst_count + 1;
                            m_axi_wlast <= (write_remaining_len <= write_burst_count + 1);
                        end
                        m_axi_wdata <= write_data_reg;
                        m_axi_wvalid <= write_data_valid_reg;
                    end
                end
                DONE: begin
                    m_axi_awvalid <= 0;
                    m_axi_wvalid <= 0;
                end
            endcase
        end
    end

    // Read descriptor status
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    reg read_status_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_status_tag <= 0;
            read_status_error <= 0;
            read_status_valid <= 0;
        end else begin
            case (read_state)
                DONE: begin
                    read_status_tag <= read_desc_tag_reg;
                    read_status_error <= (m_axi_rresp == 2'b00) ? 0 : 4'b1111;
                    read_status_valid <= 1;
                end
                default: begin
                    if (m_axis_read_desc_status_valid) begin
                        read_status_valid <= 0;
                    end
                end
            endcase
        end
    end

    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    // Write descriptor status
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;
    reg write_status_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_status_len <= 0;
            write_status_tag <= 0;
            write_status_id <= 0;
            write_status_dest <= 0;
            write_status_user <= 0;
            write_status_error <= 0;
            write_status_valid <= 0;
        end else begin
            case (write_state)
                DONE: begin
                    write_status_len <= write_desc_len_reg;
                    write_status_tag <= write_desc_tag_reg;
                    write_status_id <= 0;
                    write_status_dest <= 0;
                    write_status_user <= 0;
                    write_status_error <= (m_axi_bresp == 2'b00) ? 0 : 4'b1111;
                    write_status_valid <= 1;
                end
                default: begin
                    if (m_axis_write_desc_status_valid) begin
                        write_status_valid <= 0;
                    end
                end
            endcase
        end
    end

    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    // FIFOs for read and write data
    module read_desc_fifo #
    (
        parameter AXI_ADDR_WIDTH = 16,
        parameter LEN_WIDTH = 20,
        parameter TAG_WIDTH = 8,
        parameter AXIS_ID_WIDTH = 8,
        parameter AXIS_DEST_WIDTH = 8,
        parameter AXIS_USER_WIDTH = 1
    )
    (
        input  wire                       clk,
        input  wire                       rst,
        input  wire [AXI_ADDR_WIDTH-1:0]  din_addr,
        input  wire [LEN_WIDTH-1:0]       din_len,
        input  wire [TAG_WIDTH-1:0]       din_tag,
        input  wire [AXIS_ID_WIDTH-1:0]   din_id,
        input  wire [AXIS_DEST_WIDTH-1:0] din_dest,
        input  wire [AXIS_USER_WIDTH-1:0] din_user,
        input  wire                       din_valid,
        output wire                       din_ready,
        output wire [AXI_ADDR_WIDTH-1:0]  dout_addr,
        output wire [LEN_WIDTH-1:0]       dout_len,
        output wire [TAG_WIDTH-1:0]       dout_tag,
        output wire [AXIS_ID_WIDTH-1:0]   dout_id,
        output wire [AXIS_DEST_WIDTH-1:0] dout_dest,
        output wire [AXIS_USER_WIDTH-1:0] dout_user,
        output wire                       dout_valid,
        input  wire                       dout_ready
    );

        reg [AXI_ADDR_WIDTH-1:0]  addr_fifo [0:15];
        reg [LEN_WIDTH-1:0]       len_fifo [0:15];
        reg [TAG_WIDTH-1:0]       tag_fifo [0:15];
        reg [AXIS_ID_WIDTH-1:0]   id_fifo [0:15];
        reg [AXIS_DEST_WIDTH-1:0] dest_fifo [0:15];
        reg [AXIS_USER_WIDTH-1:0] user_fifo [0:15];
        reg [3:0]                 wr_ptr;
        reg [3:0]                 rd_ptr;
        reg                       full;
        reg                       empty;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else begin
                if (din_valid && din_ready && !full) begin
                    addr_fifo[wr_ptr] <= din_addr;
                    len_fifo[wr_ptr] <= din_len;
                    tag_fifo[wr_ptr] <= din_tag;
                    id_fifo[wr_ptr] <= din_id;
                    dest_fifo[wr_ptr] <= din_dest;
                    user_fifo[wr_ptr] <= din_user;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == 15) begin
                        full <= 1;
                    end
                    if (rd_ptr != wr_ptr) begin
                        empty <= 0;
                    end
                end
                if (dout_valid && dout_ready && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == 15) begin
                        empty <= 1;
                    end
                    if (wr_ptr != rd_ptr) begin
                        full <= 0;
                    end
                end
            end
        end

        assign din_ready = !full;
        assign dout_valid = !empty;
        assign dout_addr = addr_fifo[rd_ptr];
        assign dout_len = len_fifo[rd_ptr];
        assign dout_tag = tag_fifo[rd_ptr];
        assign dout_id = id_fifo[rd_ptr];
        assign dout_dest = dest_fifo[rd_ptr];
        assign dout_user = user_fifo[rd_ptr];

    endmodule

    module write_desc_fifo #
    (
        parameter AXI_ADDR_WIDTH = 16,
        parameter LEN_WIDTH = 20,
        parameter TAG_WIDTH = 8
    )
    (
        input  wire                       clk,
        input  wire                       rst,
        input  wire [AXI_ADDR_WIDTH-1:0]  din_addr,
        input  wire [LEN_WIDTH-1:0]       din_len,
        input  wire [TAG_WIDTH-1:0]       din_tag,
        input  wire                       din_valid,
        output wire                       din_ready,
        output wire [AXI_ADDR_WIDTH-1:0]  dout_addr,
        output wire [LEN_WIDTH-1:0]       dout_len,
        output wire [TAG_WIDTH-1:0]       dout_tag,
        output wire                       dout_valid,
        input  wire                       dout_ready
    );

        reg [AXI_ADDR_WIDTH-1:0]  addr_fifo [0:15];
        reg [LEN_WIDTH-1:0]       len_fifo [0:15];
        reg [TAG_WIDTH-1:0]       tag_fifo [0:15];
        reg [3:0]                 wr_ptr;
        reg [3:0]                 rd_ptr;
        reg                       full;
        reg                       empty;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else begin
                if (din_valid && din_ready && !full) begin
                    addr_fifo[wr_ptr] <= din_addr;
                    len_fifo[wr_ptr] <= din_len;
                    tag_fifo[wr_ptr] <= din_tag;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == 15) begin
                        full <= 1;
                    end
                    if (rd_ptr != wr_ptr) begin
                        empty <= 0;
                    end
                end
                if (dout_valid && dout_ready && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == 15) begin
                        empty <= 1;
                    end
                    if (wr_ptr != rd_ptr) begin
                        full <= 0;
                    end
                end
            end
        end

        assign din_ready = !full;
        assign dout_valid = !empty;
        assign dout_addr = addr_fifo[rd_ptr];
        assign dout_len = len_fifo[rd_ptr];
        assign dout_tag = tag_fifo[rd_ptr];

    endmodule

    module read_data_fifo #
    (
        parameter AXIS_DATA_WIDTH = 32
    )
    (
        input  wire                       clk,
        input  wire                       rst,
        input  wire [AXIS_DATA_WIDTH-1:0] din_data,
        input  wire                       din_valid,
        output wire                       din_ready,
        input  wire                       din_last,
        output wire [AXIS_DATA_WIDTH-1:0] dout_data,
        output wire                       dout_valid,
        input  wire                       dout_ready,
        output wire                       dout_last
    );

        reg [AXIS_DATA_WIDTH-1:0]  data_fifo [0:15];
        reg [3:0]                 wr_ptr;
        reg [3:0]                 rd_ptr;
        reg                       full;
        reg                       empty;
        reg                       last_fifo [0:15];

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else begin
                if (din_valid && din_ready && !full) begin
                    data_fifo[wr_ptr] <= din_data;
                    last_fifo[wr_ptr] <= din_last;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == 15) begin
                        full <= 1;
                    end
                    if (rd_ptr != wr_ptr) begin
                        empty <= 0;
                    end
                end
                if (dout_valid && dout_ready && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == 15) begin
                        empty <= 1;
                    end
                    if (wr_ptr != rd_ptr) begin
                        full <= 0;
                    end
                end
            end
        end

        assign din_ready = !full;
        assign dout_valid = !empty;
        assign dout_data = data_fifo[rd_ptr];
        assign dout_last = last_fifo[rd_ptr];

    endmodule

    module write_data_fifo #
    (
        parameter AXIS_DATA_WIDTH = 32
    )
    (
        input  wire                       clk,
        input  wire                       rst,
        input  wire [AXIS_DATA_WIDTH-1:0] din_data,
        input  wire                       din_valid,
        output wire                       din_ready,
        input  wire                       din_last,
        output wire [AXIS_DATA_WIDTH-1:0] dout_data,
        output wire                       dout_valid,
        input  wire                       dout_ready,
        output wire                       dout_last
    );

        reg [AXIS_DATA_WIDTH-1:0]  data_fifo [0:15];
        reg [3:0]                 wr_ptr;
        reg [3:0]                 rd_ptr;
        reg                       full;
        reg                       empty;
        reg                       last_fifo [0:15];

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else begin
                if (din_valid && din_ready && !full) begin
                    data_fifo[wr_ptr] <= din_data;
                    last_fifo[wr_ptr] <= din_last;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == 15) begin
                        full <= 1;
                    end
                    if (rd_ptr != wr_ptr) begin
                        empty <= 0;
                    end
                end
                if (dout_valid && dout_ready && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == 15) begin
                        empty <= 1;
                    end
                    if (wr_ptr != rd_ptr) begin
                        full <= 0;
                    end
                end
            end
        end

        assign din_ready = !full;
        assign dout_valid = !empty;
        assign dout_data = data_fifo[rd_ptr];
        assign dout_last = last_fifo[rd_ptr];

    endmodule

endmodule
