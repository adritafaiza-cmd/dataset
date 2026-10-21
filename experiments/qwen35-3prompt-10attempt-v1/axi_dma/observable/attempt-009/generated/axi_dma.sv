```verilog
`timescale 1ns/1ps

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

    // --------------------------------------------------------------------------
    // Internal Parameters and Constants
    // --------------------------------------------------------------------------
    localparam AXI_BURST_TYPE = 2'b01; // FIXED
    localparam AXI_BURST_LEN_MASK = (1 << AXI_MAX_BURST_LEN) - 1;
    localparam AXIS_KEEP_MASK = (1 << AXIS_KEEP_WIDTH) - 1;
    localparam AXIS_USER_MASK = (1 << AXIS_USER_WIDTH) - 1;
    localparam AXIS_DEST_MASK = (1 << AXIS_DEST_WIDTH) - 1;
    localparam AXIS_ID_MASK = (1 << AXIS_ID_WIDTH) - 1;
    localparam AXIS_LAST_MASK = 1;

    // --------------------------------------------------------------------------
    // State Machine Definition
    // --------------------------------------------------------------------------
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_READ_DESC,
        STATE_WRITE_DESC,
        STATE_READ_STREAM,
        STATE_WRITE_STREAM,
        STATE_READ_RESP,
        STATE_WRITE_RESP,
        STATE_ERROR
    } state_t;

    state_t current_state, next_state;

    // --------------------------------------------------------------------------
    // AXI Master Control Signals
    // --------------------------------------------------------------------------
    logic aw_valid, aw_ready;
    logic ar_valid, ar_ready;
    logic w_valid, w_ready;
    logic b_valid, b_ready;
    logic r_valid, r_ready;

    logic aw_start;
    logic ar_start;
    logic w_start;
    logic b_start;
    logic r_start;

    logic [AXI_ADDR_WIDTH-1:0] aw_addr;
    logic [AXI_ADDR_WIDTH-1:0] ar_addr;
    logic [7:0] aw_len, ar_len;
    logic [2:0] aw_size, ar_size;
    logic [1:0] aw_burst, ar_burst;
    logic [AXI_DATA_WIDTH-1:0] w_data;
    logic [AXI_STRB_WIDTH-1:0] w_strb;
    logic w_last;
    logic w_first;
    logic [AXI_ID_WIDTH-1:0] aw_id;
    logic [AXI_ID_WIDTH-1:0] ar_id;
    logic [AXI_ID_WIDTH-1:0] bid;
    logic [AXI_ID_WIDTH-1:0] rid;

    // --------------------------------------------------------------------------
    // Stream Interface Registers
    // --------------------------------------------------------------------------
    logic [AXI_DATA_WIDTH-1:0] read_data_reg;
    logic [AXIS_KEEP_WIDTH-1:0] read_keep_reg;
    logic read_last_reg;
    logic read_valid_reg;
    logic read_ready_reg;

    logic [AXI_DATA_WIDTH-1:0] write_data_reg;
    logic [AXIS_KEEP_WIDTH-1:0] write_keep_reg;
    logic write_last_reg;
    logic write_valid_reg;
    logic write_ready_reg;

    logic [AXIS_ID_WIDTH-1:0] write_tid_reg;
    logic [AXIS_DEST_WIDTH-1:0] write_tdest_reg;
    logic [AXIS_USER_WIDTH-1:0] write_tuser_reg;

    // --------------------------------------------------------------------------
    // Descriptor Status Registers
    // --------------------------------------------------------------------------
    logic [TAG_WIDTH-1:0] read_status_tag;
    logic [3:0] read_status_error;
    logic read_status_valid;

    logic [LEN_WIDTH-1:0] write_status_len;
    logic [TAG_WIDTH-1:0] write_status_tag;
    logic [AXIS_ID_WIDTH-1:0] write_status_id;
    logic [AXIS_DEST_WIDTH-1:0] write_status_dest;
    logic [AXIS_USER_WIDTH-1:0] write_status_user;
    logic [3:0] write_status_error;
    logic write_status_valid;

    // --------------------------------------------------------------------------
    // AXI Master State Machine
    // --------------------------------------------------------------------------
    logic [7:0] axi_burst_count;
    logic axi_burst_done;
    logic axi_transfer_active;
    logic axi_transfer_type; // 0: Write, 1: Read

    // Write State
    logic write_state_idle;
    logic write_state_data;
    logic write_state_resp;
    logic write_state_abort;

    // Read State
    logic read_state_idle;
    logic read_state_data;
    logic read_state_resp;
    logic read_state_abort;

    // --------------------------------------------------------------------------
    // Logic: Next State Calculation
    // --------------------------------------------------------------------------
    assign next_state = current_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            axi_transfer_active <= 1'b0;
            axi_burst_count <= 0;
            axi_burst_done <= 0;
            write_state_idle <= 1;
            read_state_idle <= 1;
            write_state_abort <= 0;
            read_state_abort <= 0;
        end else begin
            current_state <= next_state;
            axi_transfer_active <= (write_state_idle == 0 || read_state_idle == 0);
            axi_burst_count <= axi_burst_count;
            axi_burst_done <= axi_burst_done;
            write_state_idle <= write_state_idle;
            read_state_idle <= read_state_idle;
            write_state_abort <= write_state_abort;
            read_state_abort <= read_state_abort;
        end
    end

    // --------------------------------------------------------------------------
    // Logic: State Transitions
    // --------------------------------------------------------------------------
    always @(*) begin
        next_state = STATE_IDLE;
        axi_transfer_type = 1'b0; // Default Write

        case (current_state)
            STATE_IDLE: begin
                if (read_enable && s_axis_read_desc_valid && s_axis_read_desc_ready)
                    next_state = STATE_READ_DESC;
                else if (write_enable && s_axis_write_desc_valid && s_axis_write_desc_ready)
                    next_state = STATE_WRITE_DESC;
            end

            STATE_READ_DESC: begin
                if (s_axis_read_desc_valid && s_axis_read_desc_ready)
                    next_state = STATE_READ_STREAM;
                else
                    next_state = STATE_IDLE;
            end

            STATE_WRITE_DESC: begin
                if (s_axis_write_desc_valid && s_axis_write_desc_ready)
                    next_state = STATE_WRITE_STREAM;
                else
                    next_state = STATE_IDLE;
            end

            STATE_READ_STREAM: begin
                if (m_axis_read_data_tready && !m_axis_read_data_tvalid)
                    next_state = STATE_READ_STREAM; // Keep streaming
                else if (m_axis_read_data_tvalid && m_axis_read_data_tready)
                    next_state = STATE_READ_RESP;
                else if (write_abort)
                    next_state = STATE_ERROR;
                else
                    next_state = STATE_IDLE;
            end

            STATE_WRITE_STREAM: begin
                if (s_axis_write_data_tready && !s_axis_write_data_tvalid)
                    next_state = STATE_WRITE_STREAM; // Keep streaming
                else if (s_axis_write_data_tvalid && s_axis_write_data_tready)
                    next_state = STATE_WRITE_RESP;
                else if (write_abort)
                    next_state = STATE_ERROR;
                else
                    next_state = STATE_IDLE;
            end

            STATE_READ_RESP: begin
                if (m_axi_rvalid && m_axi_rready)
                    next_state = STATE_READ_STREAM; // Continue reading if more data
                else if (m_axi_rvalid && !m_axi_rready)
                    next_state = STATE_READ_RESP; // Wait for ready
                else
                    next_state = STATE_IDLE;
            end

            STATE_WRITE_RESP: begin
                if (m_axi_bvalid && m_axi_bready)
                    next_state = STATE_WRITE_STREAM; // Continue writing if more data
                else if (m_axi_bvalid && !m_axi_bready)
                    next_state = STATE_WRITE_RESP; // Wait for ready
                else
                    next_state = STATE_IDLE;
            end

            STATE_ERROR: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // --------------------------------------------------------------------------
    // Logic: AXI Master Control Signals Generation
    // --------------------------------------------------------------------------
    always @(*) begin
        // Write Address Channel
        m_axi_awid = aw_id;
        m_axi_awaddr = aw_addr;
        m_axi_awlen = aw_len;
        m_axi_awsize = aw_size;
        m_axi_awburst = AXI_BURST_TYPE;
        m_axi_awlock = 1'b0;
        m_axi_awcache = 4'b0000;
        m_axi_awprot = 3'b000;
        m_axi_awvalid = aw_valid;
        m_axi_awready = aw_ready;

        // Write Data Channel
        m_axi_wdata = w_data;
        m_axi_wstrb = w_strb;
        m_axi_wlast = w_last;
        m_axi_wvalid = w_valid;
        m_axi_wready = w_ready;

        // Write Response Channel
        m_axi_bready = b_ready;
        m_axi_bvalid = b_valid;
        m_axi_bid = bid;
        m_axi_bresp = 2'b00;

        // Read Address Channel
        m_axi_arid = ar_id;
        m_axi_araddr = ar_addr;
        m_axi_arlen = ar_len;
        m_axi_arsize = ar_size;
        m_axi_arburst = AXI_BURST_TYPE;
        m_axi_arlock = 1'b0;
        m_axi_arcache = 4'b0000;
        m_axi_arprot = 3'b000;
        m_axi_arvalid = ar_valid;
        m_axi_arready = ar_ready;

        // Read Response Channel
        m_axi_rready = r_ready;
        m_axi_rvalid = r_valid;
        m_axi_rid = rid;
        m_axi_rdata = 32'h0; // Dummy for simulation, actual data comes from AXI
        m_axi_rresp = 2'b00;
        m_axi_rlast = r_last;
    end

    // --------------------------------------------------------------------------
    // Logic: AXI Master State Machine Updates
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aw_valid <= 1'b0;
            ar_valid <= 1'b0;
            w_valid <= 1'b0;
            b_ready <= 1'b0;
            r_ready <= 1'b0;
            aw_start <= 1'b0;
            ar_start <= 1'b0;
            w_start <= 1'b0;
            b_start <= 1'b0;
            r_start <= 1'b0;
            w_last <= 1'b0;
            w_first <= 1'b0;
            axi_burst_count <= 0;
            axi_burst_done <= 0;
            write_state_idle <= 1;
            read_state_idle <= 1;
            write_state_abort <= 0;
            read_state_abort <= 0;
        end else begin
            // Reset flags
            aw_valid <= 1'b0;
            ar_valid <= 1'b0;
            w_valid <= 1'b0;
            b_ready <= 1'b0;
            r_ready <= 1'b0;
            aw_start <= 1'b0;
            ar_start <= 1'b0;
            w_start <= 1'b0;
            b_start <= 1'b0;
            r_start <= 1'b0;
            w_last <= 1'b0;
            w_first <= 1'b0;
            axi_burst_count <= 0;
            axi_burst_done <= 0;
            write_state_idle <= 1;
            read_state_idle <= 1;
            write_state_abort <= 0;
            read_state_abort <= 0;

            // Write State Machine
            if (write_state_idle) begin
                if (write_abort) begin
                    write_state_idle <= 0;
                    write_state_abort <= 1;
                end else if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                    write_state_idle <= 0;
                    write_state_data <= 1;
                    // Setup Write Transaction
                    aw_addr <= s_axis_write_desc_addr;
                    aw_len <= s_axis_write_desc_len[7:0]; // Burst length
                    aw_size <= 3'b000; // 32-bit transfer
                    aw_id <= s_axis_write_desc_id;
                    w_first <= 1;
                    axi_burst_count <= s_axis_write_desc_len[7:0];
                    axi_burst_done <= 0;
                end
            end else if (write_state_data) begin
                if (write_abort) begin
                    write_state_data <= 0;
                    write_state_abort <= 1;
                end else if (m_axi_wready && !m_axi_wvalid) begin
                    w_valid <= 1;
                    w_data <= s_axis_write_data_tdata;
                    w_strb <= s_axis_write_data_tkeep ? (AXI_STRB_WIDTH[AXIS_KEEP_WIDTH-1:0] - 1) : (AXI_STRB_WIDTH[AXIS_KEEP_WIDTH-1:0] - 1);
                    w_last <= 0;
                    w_start <= 1;
                    axi_burst_count <= axi_burst_count - 1;
                    if (axi_burst_count == 0) axi_burst_done <= 1;
                end else if (m_axi_wvalid && m_axi_wready) begin
                    w_valid <= 0;
                    w_start <= 0;
                    if (axi_burst_done) begin
                        write_state_data <= 0;
                        write_state_resp <= 1;
                        // Setup Response
                        b_ready <= 1;
                        bid <= s_axis_write_desc_id;
                    end
                end else if (m_axi_wvalid && !m_axi_wready) begin
                    // Wait for ready
                end else if (m_axi_bvalid && m_axi_bready) begin
                    write_state_resp <= 0;
                    write_state_idle <= 1;
                    // Update Status
                    write_status_len <= s_axis_write_desc_len;
                    write_status_tag <= s_axis_write_desc_tag;
                    write_status_id <= s_axis_write_desc_id;
                    write_status_dest <= s_axis_write_desc_dest;
                    write_status_user <= s_axis_write_desc_user;
                    write_status_error <= 4'b0000;
                    write_status_valid <= 1;
                    s_axis_write_desc_ready <= 1;
                end else if (m_axi_bvalid && !m_axi_bready) begin
                    // Wait for ready
                end else if (m_axi_bready && !m_axi_bvalid) begin
                    b_ready <= 0;
                end
            end else if (write_state_resp) begin
                if (m_axi_bvalid && m_axi_bready) begin
                    write_state_resp <= 0;
                    write_state_idle <= 1;
                    // Update Status
                    write_status_len <= s_axis_write_desc_len;
                    write_status_tag <= s_axis_write_desc_tag;
                    write_status_id <= s_axis_write_desc_id;
                    write_status_dest <= s_axis_write_desc_dest;
                    write_status_user <= s_axis_write_desc_user;
                    write_status_error <= m_axi_bresp;
                    write_status_valid <= 1;
                    s_axis_write_desc_ready <= 1;
                end else if (m_axi_bvalid && !m_axi_bready) begin
                    // Wait for ready
                end else if (m_axi_bready && !m_axi_bvalid) begin
                    b_ready <= 0;
                end
            end

            // Read State Machine
            if (read_state_idle) begin
                if (read_abort) begin
                    read_state_idle <= 0;
                    read_state_abort <= 1;
                end else if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                    read_state_idle <= 0;
                    read_state_data <= 1;
                    // Setup Read Transaction
                    ar_addr <= s_axis_read_desc_addr;
                    ar_len <= s_axis_read_desc_len[7:0]; // Burst length
                    ar_size <= 3'b000; // 32-bit transfer
                    ar_id <= s_axis_read_desc_id;
                    r_last <= 0;
                    axi_burst_count <= s_axis_read_desc_len[7:0];
                    axi_burst_done <= 0;
                end
            end else if (read_state_data) begin
                if (read_abort) begin
                    read_state_data <= 0;
                    read_state_abort <= 1;
                end else if (m_axi_rready && !m_axi_rvalid) begin
                    r_valid <= 1;
                    r_last <= 0;
                    r_start <= 1;
                    axi_burst_count <= axi_burst_count - 1;
                    if (axi_burst_count == 0) axi_burst_done <= 1;
                end else if (m_axi_rvalid && m_axi_rready) begin
                    r_valid <= 0;
                    r_start <= 0;
                    if (axi_burst_done) begin
                        read_state_data <= 0;
                        read_state_resp <= 1;
                        // Setup Response
                        b_ready <= 1;
                        bid <= s_axis_read_desc_id;
                    end
                end else if (m_axi_rvalid && !m_axi_rready) begin
                    // Wait for ready
                end else if (m_axi_rvalid && m_axi_rlast) begin
                    // Last beat received
                    read_state_data <= 0;
                    read_state_resp <= 1;
                    // Setup Response
                    b_ready <= 1;
                    bid <= s_axis_read_desc_id;
                end else if (m_axi_rvalid && !m_axi_rlast) begin
                    // More data coming
                    read_state_data <= 1;
                end else if (m_axi_bvalid && m_axi_bready) begin
                    read_state_resp <= 0;
                    read_state_idle <= 1;
                    // Update Status
                    read_status_tag <= s_axis_read_desc_tag;
                    read_status_error <= m_axi_bresp;
                    read_status_valid <= 1;
                    s_axis_read_desc_ready <= 1;
                end else if (m_axi_bvalid && !m_axi_bready) begin
                    // Wait for ready
                end else if (m_axi_bready && !m_axi_bvalid) begin
                    b_ready <= 0;
                end
            end else if (read_state_resp) begin
                if (m_axi_bvalid && m_axi_bready) begin
                    read_state_resp <= 0;
                    read_state_idle <= 1;
                    // Update Status
                    read_status_tag <= s_axis_read_desc_tag;
                    read_status_error <= m_axi_bresp;
                    read_status_valid <= 1;
                    s_axis_read_desc_ready <= 1;
                end else if (m_axi_bvalid && !m_axi_bready) begin
                    // Wait for ready
                end else if (m_axi_bready && !m_axi_bvalid) begin
                    b_ready <= 0;
                end
            end
        end
    end

    // --------------------------------------------------------------------------
    // Logic: Stream Interface Updates
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_reg <= 0;
            read_keep_reg <= 0;
            read_last_reg <= 0;
            read_valid_reg <= 0;
            read_ready_reg <= 0;

            write_data_reg <= 0;
            write_keep_reg <= 0;
            write_last_reg <= 0;
            write_valid_reg <= 0;
            write_ready_reg <= 0;

            write_tid_reg <= 0;
            write_tdest_reg <= 0;
            write_tuser_reg <= 0;
        end else begin
            // Read Stream
            if (current_state == STATE_READ_STREAM) begin
                if (m_axi_rvalid && m_axi_rready) begin
                    read_data_reg <= m_axi_rdata;
                    read_keep_reg <= AXIS_KEEP_MASK;
                    read_last_reg <= m_axi_rlast;
                    read_valid_reg <= 1;
                    read_ready_reg <= 0;
                    m_axis_read_data_tdata <= read_data_reg;
                    m_axis_read_data_tkeep <= read_keep_reg;
                    m_axis_read_data_tvalid <= read_valid_reg;
                    m_axis_read_data_tlast <= read_last_reg;
                    m_axis_read_data_tid <= s_axis_read_desc_id;
                    m_axis_read_data_tdest <= s_axis_read_desc_dest;
                    m_axis_read_data_tuser <= s_axis_read_desc_user;
                end else if (m_axis_read_data_tready && read_valid_reg) begin
                    read_valid_reg <= 0;
                    read_ready_reg <= 1;
                    s_axis_read_desc_ready <= 1; // Descriptor ready after stream
                end else if (!m_axis_read_data_tready && !read_valid_reg) begin
                    read_ready_reg <= 0;
                end
            end

            // Write Stream
            if (current_state == STATE_WRITE_STREAM) begin
                if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                    write_data_reg <= s_axis_write_data_tdata;
                    write_keep_reg <= s_axis_write_data_tkeep;
                    write_last_reg <= s_axis_write_data_tlast;
                    write_valid_reg <= 1;
                    write_ready_reg <= 0;
                    s_axis_write_data_tready <= 1;
                    m_axi_wdata <= write_data_reg;
                    m_axi_wstrb <= write_keep_reg;
                    m_axi_wlast <= write_last_reg;
                    m_axi_wvalid <= write_valid_reg;
                    m_axi_wready <= 1;
                    m_axi_awvalid <= 1;
                    m_axi_awready <= 1;
                end else if (s_axis_write_data_tready && !write_valid_reg) begin
                    write_ready_reg <= 1;
                    s_axis_write_data_tready <= 1;
                end else if (!s_axis_write_data_tready && write_valid_reg) begin
                    write_ready_reg <= 0;
                    s_axis_write_data_tready <= 0;
                end
            end
        end
    end

    // --------------------------------------------------------------------------
    // Logic: Status Output Updates
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_desc_status_tag <= 0;
            m_axis_read_desc_status_error <= 4'b0000;
            m_axis_read_desc_status_valid <= 0;

            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 4'b0000;
            m_axis_write_desc_status_valid <= 0;
        end else begin
            if (current_state == STATE_READ_RESP) begin
                m_axis_read_desc_status_tag <= read_status_tag;
                m_axis_read_desc_status_error <= read_status_error;
                m_axis_read_desc_status_valid <= read_status_valid;
            end

            if (current_state == STATE_WRITE_RESP) begin
                m_axis_write_desc_status_len <= write_status_len;
                m_axis_write_desc_status_tag <= write_status_tag;
                m_axis_write_desc_status_id <= write_status_id;
                m_axis_write_desc_status_dest <= write_status_dest;
                m_axis_write_desc_status_user <= write_status_user;
                m_axis_write_desc_status_error <= write_status_error;
                m_axis_write_desc_status_valid <= write_status_valid;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Logic: Error Handling
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_abort <= 0;
            read_abort <= 0;
        end else begin
            write_abort <= write_abort;
            read_abort <= read_abort;
        end
    end

    // --------------------------------------------------------------------------
    // Logic: AXI Master Control Signals Assignment
    // --------------------------------------------------------------------------
    always @(*) begin
        // Write Address Channel
        m_axi_awid = aw_id;
        m_axi_awaddr = aw_addr;
        m_axi_awlen = aw_len;
        m_axi_awsize = aw_size;
        m_axi_awburst = AXI_BURST_TYPE;
        m_axi_awlock = 1'b0;
        m_axi_awcache = 4'b0000;
        m_axi_awprot = 3'b000;
        m_axi_awvalid = aw_valid;
        m_axi_awready = aw_ready;

        // Write Data Channel
        m_axi_wdata = w_data;
        m_axi_wstrb = w_strb;
        m_axi_wlast = w_last;
        m_axi_wvalid = w_valid;
        m_axi_wready = w_ready;

        // Write Response Channel
        m_axi_bready = b_ready;
        m_axi_bvalid = b_valid;
        m_axi_bid = bid;
        m_axi_bresp = 2'b00;

        // Read Address Channel
        m_axi_arid = ar_id;
        m_axi_araddr = ar_addr;
        m_axi_arlen = ar_len;
        m_axi_arsize = ar_size;
        m_axi_arburst = AXI_BURST_TYPE;
        m_axi_arlock = 1'b0;
        m_axi_arcache = 4'b0000;
        m_axi_arprot = 3'b000;
        m_axi_arvalid = ar_valid;
        m_axi_arready = ar_ready;

        // Read Response Channel
        m_axi_rready = r_ready;
        m_axi_rvalid = r_valid;
        m_axi_rid = rid;
        m_axi_rdata = 32'h0; // Dummy for simulation, actual data comes from AXI
        m_axi_rresp = 2'b00;
        m_axi_rlast = r_last;
    end

    // --------------------------------------------------------------------------
    // Logic: AXI Master State Machine Updates
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aw_valid <= 1'b0;
            ar_valid <= 1'b0;
            w_valid <= 1'b0;
            b_ready <= 1'b0;
            r_ready <= 1'b0;
            aw_start <= 1'b0;
            ar_start <= 1'b0;
            w_start <= 1'b0;
            b_start <= 1'b0;
            r_start <= 1'b0;
            w_last <= 1'b0;
            w_first <= 1'b0;
            axi_burst_count <= 0;
            axi_burst_done <= 0;
            write_state_idle <= 1;
            read_state_idle <= 1;
            write_state_abort <= 0;
            read_state_abort <= 0;
        end else begin
            // Reset flags
            aw_valid <= 1'b0;
            ar_valid <= 1'b0;
            w_valid <= 1'b0;
            b_ready <= 1'b0;
            r_ready <= 1'b0;
            aw_start <= 1'b0;
            ar_start <= 1'b0;
            w_start <= 1'b0;
            b_start <= 1'b0;
            r_start <= 1'b0;
            w_last <= 1'b0;
            w_first <= 1'b0;
            axi_burst_count <= 0;
            axi_burst_done <= 0;
            write_state_idle <= 1;
            read_state_idle <= 1;
            write_state_abort <= 0;
            read_state_abort <= 0;

            // Write State Machine
            if (write_state_idle) begin
                if (write_abort) begin
                    write_state_idle <= 0;
                    write_state_abort <= 1;
                end else if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                    write_state_idle <= 0;
                    write_state_data <= 1;
                    // Setup Write Transaction
                    aw_addr <= s_axis_write_desc_addr;
                    aw_len <= s