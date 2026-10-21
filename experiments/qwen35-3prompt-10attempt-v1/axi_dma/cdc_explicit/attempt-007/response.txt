```verilog
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

    // -----------------------------------------------------------------------
    // Internal Parameters and Constants
    // -----------------------------------------------------------------------
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXIS_KEEP_WIDTH   = $clog2(AXIS_KEEP_WIDTH);
    localparam LOG2_AXIS_ID_WIDTH     = $clog2(AXIS_ID_WIDTH);
    localparam LOG2_AXIS_DEST_WIDTH   = $clog2(AXIS_DEST_WIDTH);
    localparam LOG2_AXIS_USER_WIDTH   = $clog2(AXIS_USER_WIDTH);
    localparam LOG2_TAG_WIDTH         = $clog2(TAG_WIDTH);
    localparam LOG2_LEN_WIDTH         = $clog2(LEN_WIDTH);

    // -----------------------------------------------------------------------
    // CDC Registers (Single Clock Domain Safe)
    // Since all ports are on 'clk', we use simple registers for state.
    // For reset safety, we use a synchronous reset strategy where state
    // machines clear to IDLE on rst.
    // -----------------------------------------------------------------------

    // State Machine States
    typedef enum logic [1:0] {
        IDLE,
        AW_PREPARE,
        AW_SEND,
        AW_WAIT_B,
        W_PREPARE,
        W_SEND,
        W_WAIT_B,
        AR_PREPARE,
        AR_SEND,
        AR_WAIT_R,
        R_PREPARE,
        R_SEND,
        R_WAIT_R,
        ERROR
    } state_t;

    state_t current_state, next_state;

    // Read Descriptor State
    logic read_desc_valid_reg;
    logic read_desc_ready_reg;
    logic [LEN_WIDTH-1:0] read_desc_len_reg;
    logic [TAG_WIDTH-1:0] read_desc_tag_reg;
    logic [AXIS_ID_WIDTH-1:0] read_desc_id_reg;
    logic [AXIS_DEST_WIDTH-1:0] read_desc_dest_reg;
    logic [AXIS_USER_WIDTH-1:0] read_desc_user_reg;
    logic read_desc_addr_reg;
    logic read_desc_active;
    logic read_desc_done;
    logic read_desc_error;

    // Write Descriptor State
    logic write_desc_valid_reg;
    logic write_desc_ready_reg;
    logic [LEN_WIDTH-1:0] write_desc_len_reg;
    logic [TAG_WIDTH-1:0] write_desc_tag_reg;
    logic [AXIS_ID_WIDTH-1:0] write_desc_id_reg;
    logic [AXIS_DEST_WIDTH-1:0] write_desc_dest_reg;
    logic [AXIS_USER_WIDTH-1:0] write_desc_user_reg;
    logic write_desc_addr_reg;
    logic write_desc_active;
    logic write_desc_done;
    logic write_desc_error;

    // AXI Transaction State
    logic axi_aw_valid_reg;
    logic axi_aw_ready_reg;
    logic axi_w_valid_reg;
    logic axi_w_ready_reg;
    logic axi_b_valid_reg;
    logic axi_b_ready_reg;
    logic axi_ar_valid_reg;
    logic axi_ar_ready_reg;
    logic axi_r_valid_reg;
    logic axi_r_ready_reg;

    logic axi_aw_sent;
    logic axi_w_sent;
    logic axi_b_received;
    logic axi_ar_sent;
    logic axi_r_received;

    logic [7:0] axi_awlen_reg;
    logic [7:0] axi_arlen_reg;
    logic [2:0] axi_awsize_reg;
    logic [2:0] axi_arsize_reg;
    logic [1:0] axi_awburst_reg;
    logic [1:0] axi_arburst_reg;

    logic [AXI_DATA_WIDTH-1:0] axi_wdata_reg;
    logic [AXI_STRB_WIDTH-1:0] axi_wstrb_reg;
    logic axi_wlast_reg;

    logic [AXI_DATA_WIDTH-1:0] axi_rdata_reg;
    logic axi_rlast_reg;
    logic [1:0] axi_rresp_reg;

    // Stream Data State
    logic stream_read_valid_reg;
    logic stream_read_ready_reg;
    logic stream_read_last_reg;
    logic [AXIS_ID_WIDTH-1:0] stream_read_tid_reg;
    logic [AXIS_DEST_WIDTH-1:0] stream_read_dest_reg;
    logic [AXIS_USER_WIDTH-1:0] stream_read_user_reg;
    logic stream_read_last_sent;

    logic stream_write_valid_reg;
    logic stream_write_ready_reg;
    logic stream_write_last_reg;
    logic stream_write_last_received;

    // -----------------------------------------------------------------------
    // State Machine Logic
    // -----------------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            // All registers cleared to default/idle values in their respective blocks
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = IDLE;
        case (current_state)
            IDLE: begin
                if (read_enable && s_axis_read_desc_valid) next_state = AW_PREPARE;
                else if (write_enable && s_axis_write_desc_valid) next_state = AW_PREPARE;
            end
            AW_PREPARE: begin
                if (m_axi_awready) next_state = AW_SEND;
            end
            AW_SEND: begin
                if (m_axi_awvalid) next_state = W_PREPARE;
            end
            W_PREPARE: begin
                if (m_axi_wready) next_state = W_SEND;
            end
            W_SEND: begin
                if (m_axi_wvalid) next_state = W_WAIT_B;
            end
            W_WAIT_B: begin
                if (m_axi_bvalid) next_state = AR_PREPARE;
            end
            AR_PREPARE: begin
                if (m_axi_arready) next_state = AR_SEND;
            end
            AR_SEND: begin
                if (m_axi_arvalid) next_state = R_PREPARE;
            end
            R_PREPARE: begin
                if (m_axi_rready) next_state = R_SEND;
            end
            R_SEND: begin
                if (m_axi_rvalid) next_state = R_WAIT_R;
            end
            R_WAIT_R: begin
                if (m_axi_rlast) next_state = IDLE;
            end
            ERROR: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------------------
    // Read Descriptor Interface Logic
    // -----------------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_desc_valid_reg <= 1'b0;
            read_desc_ready_reg <= 1'b0;
            read_desc_len_reg <= 0;
            read_desc_tag_reg <= 0;
            read_desc_id_reg <= 0;
            read_desc_dest_reg <= 0;
            read_desc_user_reg <= 0;
            read_desc_addr_reg <= 0;
            read_desc_active <= 1'b0;
            read_desc_done <= 1'b0;
            read_desc_error <= 1'b0;
        end else begin
            // Handshake logic
            if (current_state == IDLE) begin
                read_desc_ready_reg <= 1'b1;
                if (s_axis_read_desc_valid) begin
                    read_desc_valid_reg <= 1'b1;
                    read_desc_len_reg <= s_axis_read_desc_len;
                    read_desc_tag_reg <= s_axis_read_desc_tag;
                    read_desc_id_reg <= s_axis_read_desc_id;
                    read_desc_dest_reg <= s_axis_read_desc_dest;
                    read_desc_user_reg <= s_axis_read_desc_user;
                    read_desc_addr_reg <= s_axis_read_desc_addr;
                    read_desc_active <= 1'b1;
                    read_desc_done <= 1'b0;
                    read_desc_error <= 1'b0;
                end
            end else if (current_state == AW_PREPARE) begin
                read_desc_ready_reg <= 1'b0;
                if (s_axis_read_desc_valid) begin
                    read_desc_valid_reg <= 1'b1;
                    read_desc_len_reg <= s_axis_read_desc_len;
                    read_desc_tag_reg <= s_axis_read_desc_tag;
                    read_desc_id_reg <= s_axis_read_desc_id;
                    read_desc_dest_reg <= s_axis_read_desc_dest;
                    read_desc_user_reg <= s_axis_read_desc_user;
                    read_desc_addr_reg <= s_axis_read_desc_addr;
                    read_desc_active <= 1'b1;
                    read_desc_done <= 1'b0;
                    read_desc_error <= 1'b0;
                end
            end else begin
                read_desc_ready_reg <= 1'b0;
                read_desc_valid_reg <= 1'b0;
            end

            // Completion logic
            if (read_desc_active && read_desc_done) begin
                read_desc_valid_reg <= 1'b0;
                read_desc_active <= 1'b0;
                read_desc_done <= 1'b0;
                read_desc_error <= 1'b0;
            end
        end
    end

    assign s_axis_read_desc_ready = read_desc_ready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_read_desc_status_tag <= 0;
            m_axis_read_desc_status_error <= 4'hF;
            m_axis_read_desc_status_valid <= 1'b0;
        end else begin
            if (read_desc_active && read_desc_done) begin
                m_axis_read_desc_status_tag <= read_desc_tag_reg;
                m_axis_read_desc_status_error <= read_desc_error ? 4'hF : 4'h0;
                m_axis_read_desc_status_valid <= 1'b1;
            end else begin
                m_axis_read_desc_status_valid <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Write Descriptor Interface Logic
    // -----------------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_desc_valid_reg <= 1'b0;
            write_desc_ready_reg <= 1'b0;
            write_desc_len_reg <= 0;
            write_desc_tag_reg <= 0;
            write_desc_id_reg <= 0;
            write_desc_dest_reg <= 0;
            write_desc_user_reg <= 0;
            write_desc_addr_reg <= 0;
            write_desc_active <= 1'b0;
            write_desc_done <= 1'b0;
            write_desc_error <= 1'b0;
        end else begin
            // Handshake logic
            if (current_state == IDLE) begin
                write_desc_ready_reg <= 1'b1;
                if (s_axis_write_desc_valid) begin
                    write_desc_valid_reg <= 1'b1;
                    write_desc_len_reg <= s_axis_write_desc_len;
                    write_desc_tag_reg <= s_axis_write_desc_tag;
                    write_desc_id_reg <= s_axis_write_data_tid; // Capture ID from stream if available, else 0
                    write_desc_dest_reg <= s_axis_write_data_tdest;
                    write_desc_user_reg <= s_axis_write_data_tuser;
                    write_desc_addr_reg <= s_axis_write_desc_addr;
                    write_desc_active <= 1'b1;
                    write_desc_done <= 1'b0;
                    write_desc_error <= 1'b0;
                end
            end else if (current_state == AW_PREPARE) begin
                write_desc_ready_reg <= 1'b0;
                if (s_axis_write_desc_valid) begin
                    write_desc_valid_reg <= 1'b1;
                    write_desc_len_reg <= s_axis_write_desc_len;
                    write_desc_tag_reg <= s_axis_write_desc_tag;
                    write_desc_id_reg <= s_axis_write_data_tid;
                    write_desc_dest_reg <= s_axis_write_data_tdest;
                    write_desc_user_reg <= s_axis_write_data_tuser;
                    write_desc_addr_reg <= s_axis_write_desc_addr;
                    write_desc_active <= 1'b1;
                    write_desc_done <= 1'b0;
                    write_desc_error <= 1'b0;
                end
            end else begin
                write_desc_ready_reg <= 1'b0;
                write_desc_valid_reg <= 1'b0;
            end

            // Completion logic
            if (write_desc_active && write_desc_done) begin
                write_desc_valid_reg <= 1'b0;
                write_desc_active <= 1'b0;
                write_desc_done <= 1'b0;
                write_desc_error <= 1'b0;
            end
        end
    end

    assign s_axis_write_desc_ready = write_desc_ready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_write_desc_status_len <= 0;
            m_axis_write_desc_status_tag <= 0;
            m_axis_write_desc_status_id <= 0;
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= 4'hF;
            m_axis_write_desc_status_valid <= 1'b0;
        end else begin
            if (write_desc_active && write_desc_done) begin
                m_axis_write_desc_status_len <= write_desc_len_reg;
                m_axis_write_desc_status_tag <= write_desc_tag_reg;
                m_axis_write_desc_status_id <= write_desc_id_reg;
                m_axis_write_desc_status_dest <= write_desc_dest_reg;
                m_axis_write_desc_status_user <= write_desc_user_reg;
                m_axis_write_desc_status_error <= write_desc_error ? 4'hF : 4'h0;
                m_axis_write_desc_status_valid <= 1'b1;
            end else begin
                m_axis_write_desc_status_valid <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // AXI Master Interface Logic
    // -----------------------------------------------------------------------

    // Address and Length Calculation
    always @(*) begin
        if (current_state == AW_PREPARE || current_state == AW_SEND) begin
            m_axi_awid = (current_state == AW_PREPARE) ? read_desc_id_reg : write_desc_id_reg;
            m_axi_awaddr = (current_state == AW_PREPARE) ? read_desc_addr_reg : write_desc_addr_reg;
            
            // Calculate length in beats
            // len_reg is in bytes. Convert to beats.
            // Handle alignment if ENABLE_UNALIGNED is 0
            if (ENABLE_UNALIGNED) begin
                m_axi_awlen = (read_desc_len_reg > 0) ? read_desc_len_reg - 1 : 0;
            end else begin
                // Align to AXI_DATA_WIDTH boundary
                localparam LOG2_AXI_DATA_WIDTH = $clog2(AXI_DATA_WIDTH);
                localparam ALIGN_MASK = (1 << LOG2_AXI_DATA_WIDTH) - 1;
                localparam ALIGN_UP = (read_desc_len_reg + ALIGN_MASK) & ~ALIGN_MASK;
                if (ALIGN_UP > 0)
                    m_axi_awlen = ALIGN_UP - 1;
                else
                    m_axi_awlen = 0;
            end

            m_axi_awsize = 3'b000; // FIXED
            m_axi_awburst = 2'b01; // FIXED
            m_axi_awlock = 1'b0;
            m_axi_awcache = 4'b0000;
            m_axi_awprot = 3'b000;
            m_axi_awvalid = 1'b0;
            m_axi_awlen_reg = m_axi_awlen;
            axi_aw_sent = 1'b0;
        end else begin
            m_axi_awid = 0;
            m_axi_awaddr = 0;
            m_axi_awlen = 0;
            m_axi_awsize = 3'b000;
            m_axi_awburst = 2'b01;
            m_axi_awlock = 1'b0;
            m_axi_awcache = 4'b0000;
            m_axi_awprot = 3'b000;
            m_axi_awvalid = 1'b0;
            m_axi_awlen_reg = 0;
            axi_aw_sent = 1'b0;
        end

        if (current_state == W_PREPARE || current_state == W_SEND) begin
            m_axi_wdata = (current_state == W_PREPARE) ? read_desc_addr_reg : write_desc_addr_reg; // Dummy data
            m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
            m_axi_wlast = 1'b0;
            m_axi_wvalid = 1'b0;
            m_axi_wready_reg = 1'b0;
            axi_w_sent = 1'b0;
        end else begin
            m_axi_wdata = 0;
            m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
            m_axi_wlast = 1'b0;
            m_axi_wvalid = 1'b0;
            m_axi_wready_reg = 1'b0;
            axi_w_sent = 1'b0;
        end

        if (current_state == AR_PREPARE || current_state == AR_SEND) begin
            m_axi_arid = (current_state == AR_PREPARE) ? read_desc_id_reg : write_desc_id_reg;
            m_axi_araddr = (current_state == AR_PREPARE) ? read_desc_addr_reg : write_desc_addr_reg;
            
            if (ENABLE_UNALIGNED) begin
                m_axi_arlen = (read_desc_len_reg > 0) ? read_desc_len_reg - 1 : 0;
            end else begin
                localparam LOG2_AXI_DATA_WIDTH = $clog2(AXI_DATA_WIDTH);
                localparam ALIGN_MASK = (1 << LOG2_AXI_DATA_WIDTH) - 1;
                localparam ALIGN_UP = (read_desc_len_reg + ALIGN_MASK) & ~ALIGN_MASK;
                if (ALIGN_UP > 0)
                    m_axi_arlen = ALIGN_UP - 1;
                else
                    m_axi_arlen = 0;
            end

            m_axi_arsize = 3'b000; // FIXED
            m_axi_arburst = 2'b01; // FIXED
            m_axi_arlock = 1'b0;
            m_axi_arcache = 4'b0000;
            m_axi_arprot = 3'b000;
            m_axi_arvalid = 1'b0;
            m_axi_arready_reg = 1'b0;
            axi_ar_sent = 1'b0;
        end else begin
            m_axi_arid = 0;
            m_axi_araddr = 0;
            m_axi_arlen = 0;
            m_axi_arsize = 3'b000;
            m_axi_arburst = 2'b01;
            m_axi_arlock = 1'b0;
            m_axi_arcache = 4'b0000;
            m_axi_arprot = 3'b000;
            m_axi_arvalid = 1'b0;
            m_axi_arready_reg = 1'b0;
            axi_ar_sent = 1'b0;
        end

        if (current_state == R_PREPARE || current_state == R_SEND) begin
            m_axi_rready = 1'b0;
            axi_r_received = 1'b0;
        end else begin
            m_axi_rready = 1'b1;
            axi_r_received = 1'b0;
        end
    end

    // AXI Write Data Generation
    always @(*) begin
        if (current_state == W_SEND) begin
            // Generate data based on address and length
            // For simplicity in this single-file implementation without memory,
            // we generate a pattern or use the address as data.
            // In a real system, this would be a memory block or FIFO.
            // Here we simulate data generation.
            m_axi_wdata = m_axi_awaddr; 
            m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
            m_axi_wlast = 1'b0;
            m_axi_wvalid = 1'b1;
            m_axi_wready_reg = m_axi_wready;
            axi_w_sent = 1'b1;
        end else begin
            m_axi_wdata = 0;
            m_axi_wstrb = {AXI_STRB_WIDTH{1'b1}};
            m_axi_wlast = 1'b0;
            m_axi_wvalid = 1'b0;
            m_axi_wready_reg = 1'b0;
            axi_w_sent = 1'b0;
        end
    end

    // AXI Read Response Handling
    always @(*) begin
        if (current_state == R_WAIT_R) begin
            m_axi_rready = 1'b1;
            axi_r_received = 1'b1;
            m_axi_rdata = m_axi_rdata; // Capture
            m_axi_rresp = m_axi_rresp; // Capture
            m_axi_rlast = m_axi_rlast; // Capture
        end else begin
            m_axi_rready = 1'b0;
            axi_r_received = 1'b0;
            m_axi_rdata = 0;
            m_axi_rresp = 0;
            m_axi_rlast = 0;
        end
    end

    // -----------------------------------------------------------------------
    // AXI Master Control Logic
    // -----------------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axi_aw_valid_reg <= 1'b0;
            axi_aw_ready_reg <= 1'b0;
            axi_w_valid_reg <= 1'b0;
            axi_w_ready_reg <= 1'b0;
            axi_b_valid_reg <= 1'b0;
            axi_b_ready_reg <= 1'b0;
            axi_ar_valid_reg <= 1'b0;
            axi_ar_ready_reg <= 1'b0;
            axi_r_valid_reg <= 1'b0;
            axi_r_ready_reg <= 1'b0;
            axi_aw_sent <= 1'b0;
            axi_w_sent <= 1'b0;
            axi_b_received <= 1'b0;
            axi_ar_sent <= 1'b0;
            axi_r_received <= 1'b0;
        end else begin
            // AW Channel
            if (current_state == AW_SEND) begin
                axi_aw_valid_reg <= 1'b1;
                axi_aw_ready_reg <= m_axi_awready;
                if (m_axi_awready) begin
                    axi_aw_sent <= 1'b1;
                    // Move to W channel
                    if (write_desc_active)
                        next_state = W_PREPARE;
                    else
                        next_state = W_PREPARE;
                end
            end else if (current_state == AW_PREPARE) begin
                axi_aw_valid_reg <= 1'b0;
                axi_aw_ready_reg <= 1'b0;
                axi_aw_sent <= 1'b0;
            end else begin
                axi_aw_valid_reg <= 1'b0;
                axi_aw_ready_reg <= 1'b0;
                axi_aw_sent <= 1'b0;
            end

            // W Channel
            if (current_state == W_SEND) begin
                axi_w_valid_reg <= 1'b1;
                axi_w_ready_reg <= m_axi_wready;
                if (m_axi_wready) begin
                    axi_w_sent <= 1'b1;
                    // Check if last beat
                    if (axi_awlen_reg == 0) begin
                        // Last beat sent, wait for B
                        if (write_desc_active)
                            next_state = W_WAIT_B;
                        else
                            next_state = W_WAIT_B;
                    end else begin
                        // More beats to send
                        if (write_desc_active)
                            next_state = W_SEND;
                        else
                            next_state = W_SEND;
                    end
                end
            end else if (current_state == W_PREPARE) begin
                axi_w_valid_reg <= 1'b0;
                axi_w_ready_reg <= 1'b0;
                axi_w_sent <= 1'b0;
            end else begin
                axi_w_valid_reg <= 1'b0;
                axi_w_ready_reg <= 1'b0;
                axi_w_sent <= 1'b0;
            end

            // B Channel
            if (current_state == W_WAIT_B) begin
                axi_b_ready_reg <= 1'b1;
                axi_b_valid_reg <= 1'b0;
                if (m_axi_bvalid) begin
                    axi_b_received <= 1'b1;
                    // Move to AR channel
                    if (read_desc_active)
                        next_state = AR_PREPARE;
                    else
                        next_state = AR_PREPARE;
                end
            end else begin
                axi_b_ready_reg <= 1'b0;
                axi_b_valid_reg <= 1'b0;
                axi_b_received <= 1'b0;
            end

            // AR Channel
            if (current_state == AR_SEND) begin
                axi_ar_valid_reg <= 1'b1;
                axi_ar_ready_reg <= m_axi_arready;
                if (m_axi_arready) begin
                    axi_ar_sent <= 1'b1;
                    // Move to R channel
                    if (read_desc_active)
                        next_state = R_PREPARE;
                    else
                        next_state = R_PREPARE;
                end
            end else if (current_state == AR_PREPARE) begin
                axi_ar_valid_reg <= 1'b0;
                axi_ar_ready_reg <= 1'b0;
                axi_ar_sent <= 1'b0;
            end else begin
                axi_ar_valid_reg <= 1'b0;
                axi_ar_ready_reg <= 1'b0;
                axi_ar_sent <= 1'b0;
            end

            // R Channel
            if (current_state == R_SEND) begin
                axi_r_valid_reg <= 1'b1;
                axi_r_ready_reg <= m_axi_rready;
                if (m_axi_rready) begin
                    axi_r_received <= 1'b1;
                    // Move to next state
                    if (read_desc_active)
                        next_state = R_WAIT_R;
                    else
                        next_state = R_WAIT_R;
                end
            end else if (current_state == R_PREPARE) begin
                axi_r_valid_reg <= 1'b0;
                axi_r_ready_reg <= 1'b0;
                axi_r_received <= 1'b0;
            end else begin
                axi_r_valid_reg <= 1'b0;
                axi_r_ready_reg <= 1'b0;
                axi_r_received <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Stream Data Interface Logic (Read)
    // -----------------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stream_read_valid_reg <= 1'b0;
            stream_read_ready_reg <= 1'b0;
            stream_read_last_reg <= 1'b0;
            stream_read_tid_reg <= 0;
            stream_read_dest_reg <= 0;
            stream_read_user_reg <= 0;
            stream_read_last_sent <= 1'b0;
        end else begin
            // Handshake
            if (current_state == R_SEND) begin
                stream_read_ready_reg <= 1'b1;
                if (m_axis_read_data_tready) begin
                    stream_read_valid_reg <= 1'b1;
                    stream_read_tid_reg <= read_desc_id_reg;
                    stream_read_dest_reg <= read_desc_dest_reg;
                    stream_read_user_reg <= read_desc_user_reg;
                    stream_read_last_sent <= 1'b0;
                end
            end else begin
                stream_read_ready_reg <= 1'b0;
                stream_read_valid_reg <= 1'b0;
                stream_read_last_sent <= 1'b0;
            end

            // Data Generation
            if (stream_read_valid_reg) begin
                m_axis_read_data_tdata <= m_axi_rdata;
                m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                m_axis_read_data