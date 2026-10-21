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

    // ---------------------------------------------------------------------------
    // Internal Parameters and Constants
    // ---------------------------------------------------------------------------
    localparam AXI_BURST_TYPE = 2'b01; // FIXED
    localparam AXI_ADDR_MASK  = (1 << AXI_ADDR_WIDTH) - 1;
    localparam AXI_STRB_MASK  = (1 << AXI_STRB_WIDTH) - 1;
    localparam AXIS_KEEP_MASK = (1 << AXIS_KEEP_WIDTH) - 1;

    // ---------------------------------------------------------------------------
    // Internal State Registers
    // ---------------------------------------------------------------------------
    reg [LEN_WIDTH-1:0]  g_read_remaining_len;
    reg [LEN_WIDTH-1:0]  g_write_remaining_len;
    reg                  g_read_active;
    reg                  g_write_active;
    reg                  g_read_done;
    reg                  g_write_done;
    reg                  g_read_error;
    reg                  g_write_error;
    
    reg [AXI_ADDR_WIDTH-1:0] g_read_current_addr;
    reg [AXI_ADDR_WIDTH-1:0] g_write_current_addr;
    
    reg [AXI_ID_WIDTH-1:0]  g_read_current_id;
    reg [AXIS_DEST_WIDTH-1:0] g_read_current_dest;
    reg [AXIS_USER_WIDTH-1:0] g_read_current_user;
    
    reg [AXIS_ID_WIDTH-1:0]  g_write_current_id;
    reg [AXIS_DEST_WIDTH-1:0] g_write_current_dest;
    reg [AXIS_USER_WIDTH-1:0] g_write_current_user;

    // AXI Master State Machine State
    typedef enum logic [2:0] {
        AXI_IDLE,
        AXI_AW_PREPARE,
        AXI_AW_SEND,
        AXI_W_SEND,
        AXI_B_WAIT,
        AXI_AR_PREPARE,
        AXI_AR_SEND,
        AXI_R_WAIT
    } axi_state_t;

    axi_state_t g_axi_state;
    reg [7:0]    g_axi_burst_len;
    reg [2:0]    g_axi_burst_size;
    reg          g_axi_burst_type;
    reg          g_axi_burst_lock;
    reg          g_axi_aw_valid;
    reg          g_axi_ar_valid;
    reg          g_axi_w_valid;
    reg          g_axi_w_last;
    reg          g_axi_r_ready;
    reg          g_axi_b_ready;
    reg          g_axi_aw_ready;
    reg          g_axi_ar_ready;
    reg          g_axi_w_ready;
    reg          g_axi_b_valid;
    reg          g_axi_r_valid;
    reg          g_axi_r_last;
    reg          g_axi_r_resp;
    reg          g_axi_b_resp;
    reg          g_axi_aw_id;
    reg          g_axi_ar_id;
    reg          g_axi_aw_addr;
    reg          g_axi_ar_addr;
    reg          g_axi_w_data;
    reg          g_axi_w_strb;
    reg          g_axi_r_data;
    reg          g_axi_r_last_flag;

    // ---------------------------------------------------------------------------
    // Helper Functions (Inline Logic)
    // ---------------------------------------------------------------------------
    // Calculate AXI Size based on data width
    function automatic [2:0] get_axi_size;
    begin
        case (AXI_DATA_WIDTH)
            8:  get_axi_size = 3'b000;
            16: get_axi_size = 3'b001;
            32: get_axi_size = 3'b010;
            64: get_axi_size = 3'b011;
            128: get_axi_size = 3'b100;
            256: get_axi_size = 3'b101;
            default: get_axi_size = 3'b111; // Error
        endcase
    end
    endfunction

    // Calculate AXI Burst Length (in beats)
    function automatic [7:0] get_axi_burst_len;
        input [LEN_WIDTH-1:0] len;
        input [2:0] size;
        input [2:0] burst_type;
        input [AXI_ADDR_WIDTH-1:0] addr;
        
        begin
            // Align address to size
            if (burst_type == 3'b00) begin // FIXED
                // For FIXED, we must align to size boundary
                // Calculate offset within the beat
                localparam [AXI_ADDR_WIDTH-1:0] byte_offset = addr % (1 << size);
                localparam [LEN_WIDTH-1:0] aligned_len = len - byte_offset;
                
                if (aligned_len > 0) begin
                    // Calculate beats needed
                    localparam [LEN_WIDTH-1:0] beats = aligned_len / (1 << size);
                    if (beats > AXI_MAX_BURST_LEN) begin
                        // Truncate to max supported
                        beats = AXI_MAX_BURST_LEN;
                    end
                    get_axi_burst_len = beats;
                end else begin
                    get_axi_burst_len = 0;
                end
            end else begin // INCR (default)
                // For INCR, alignment is less strict, but we align to byte boundary usually
                // Assuming byte aligned for simplicity in this single clock implementation
                localparam [LEN_WIDTH-1:0] beats = len / (1 << size);
                if (beats > AXI_MAX_BURST_LEN) begin
                    beats = AXI_MAX_BURST_LEN;
                end
                get_axi_burst_len = beats;
            end
        end
    endfunction

    // ---------------------------------------------------------------------------
    // AXI Master Interface Logic
    // ---------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            g_axi_state <= AXI_IDLE;
            g_axi_burst_len <= 0;
            g_axi_burst_size <= 0;
            g_axi_aw_valid <= 0;
            g_axi_ar_valid <= 0;
            g_axi_w_valid <= 0;
            g_axi_w_last <= 0;
            g_axi_r_ready <= 0;
            g_axi_b_ready <= 0;
            g_axi_aw_ready <= 0;
            g_axi_ar_ready <= 0;
            g_axi_w_ready <= 0;
            g_axi_b_valid <= 0;
            g_axi_r_valid <= 0;
            g_axi_r_last_flag <= 0;
            g_axi_r_resp <= 2'b00;
            g_axi_b_resp <= 2'b00;
            g_axi_aw_id <= 0;
            g_axi_ar_id <= 0;
            g_axi_aw_addr <= 0;
            g_axi_ar_addr <= 0;
            g_axi_w_data <= 0;
            g_axi_w_strb <= 0;
            g_axi_r_data <= 0;
        end else begin
            // State Machine Logic
            case (g_axi_state)
                AXI_IDLE: begin
                    if (read_enable && g_read_active && g_read_remaining_len > 0) begin
                        g_axi_state <= AXI_AW_PREPARE;
                        g_axi_aw_addr <= g_read_current_addr;
                        g_axi_aw_id <= g_read_current_id;
                        g_axi_burst_size <= get_axi_size;
                        g_axi_burst_type <= AXI_BURST_TYPE;
                        g_axi_burst_len <= get_axi_burst_len(g_read_remaining_len, g_axi_burst_size, AXI_BURST_TYPE, g_read_current_addr);
                        g_axi_aw_lock <= 1'b0;
                        g_axi_aw_cache <= 4'b0000;
                        g_axi_aw_prot <= 3'b000;
                        g_axi_aw_valid <= 1'b1;
                        g_axi_aw_ready <= m_axi_awready;
                        g_axi_ar_valid <= 1'b0;
                        g_axi_ar_addr <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_ar_len <= 0;
                        g_axi_ar_size <= 0;
                        g_axi_ar_burst <= 0;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_valid <= 1'b0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= 1'b1;
                        g_axi_r_ready <= 1'b0;
                        g_axi_b_ready <= 1'b0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else if (write_enable && g_write_active && g_write_remaining_len > 0) begin
                        g_axi_state <= AXI_AW_PREPARE;
                        g_axi_aw_addr <= g_write_current_addr;
                        g_axi_aw_id <= g_write_current_id;
                        g_axi_burst_size <= get_axi_size;
                        g_axi_burst_type <= AXI_BURST_TYPE;
                        g_axi_burst_len <= get_axi_burst_len(g_write_remaining_len, g_axi_burst_size, AXI_BURST_TYPE, g_write_current_addr);
                        g_axi_aw_lock <= 1'b0;
                        g_axi_aw_cache <= 4'b0000;
                        g_axi_aw_prot <= 3'b000;
                        g_axi_aw_valid <= 1'b1;
                        g_axi_aw_ready <= m_axi_awready;
                        g_axi_ar_valid <= 1'b0;
                        g_axi_ar_addr <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_ar_len <= 0;
                        g_axi_ar_size <= 0;
                        g_axi_ar_burst <= 0;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_valid <= 1'b0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= 1'b1;
                        g_axi_r_ready <= 1'b0;
                        g_axi_b_ready <= 1'b0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else begin
                        g_axi_aw_valid <= 0;
                        g_axi_ar_valid <= 0;
                        g_axi_w_valid <= 0;
                        g_axi_r_ready <= 0;
                        g_axi_b_ready <= 0;
                        g_axi_aw_ready <= 1'b1;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_ready <= 1'b1;
                        g_axi_aw_addr <= 0;
                        g_axi_ar_addr <= 0;
                        g_axi_aw_id <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_resp <= 0;
                    end
                end

                AXI_AW_PREPARE: begin
                    if (g_axi_aw_ready) begin
                        g_axi_state <= AXI_AW_SEND;
                        g_axi_aw_valid <= 0;
                        g_axi_aw_ready <= 1'b1;
                        g_axi_ar_valid <= 1'b1;
                        g_axi_ar_addr <= g_axi_aw_addr;
                        g_axi_ar_id <= g_axi_aw_id;
                        g_axi_ar_len <= g_axi_burst_len - 1;
                        g_axi_ar_size <= g_axi_burst_size;
                        g_axi_ar_burst <= AXI_BURST_TYPE;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= m_axi_arready;
                        g_axi_w_valid <= 1'b0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= 1'b1;
                        g_axi_r_ready <= 0;
                        g_axi_b_ready <= 0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else begin
                        g_axi_aw_ready <= 0;
                    end
                end

                AXI_AW_SEND: begin
                    if (g_axi_awready) begin
                        g_axi_state <= AXI_W_SEND;
                        g_axi_aw_valid <= 0;
                        g_axi_aw_ready <= 1'b1;
                        g_axi_ar_valid <= 0;
                        g_axi_ar_addr <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_ar_len <= 0;
                        g_axi_ar_size <= 0;
                        g_axi_ar_burst <= 0;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_valid <= 1'b1;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= m_axi_wready;
                        g_axi_r_ready <= 0;
                        g_axi_b_ready <= 0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else begin
                        g_axi_w_ready <= 0;
                    end
                end

                AXI_W_SEND: begin
                    if (g_axi_wready) begin
                        if (g_axi_burst_len == 1) begin
                            g_axi_state <= AXI_B_WAIT;
                            g_axi_w_valid <= 0;
                            g_axi_w_data <= 0;
                            g_axi_w_strb <= 0;
                            g_axi_w_last <= 1'b1;
                            g_axi_w_ready <= 1'b1;
                            g_axi_b_ready <= 1'b1;
                            g_axi_aw_valid <= 0;
                            g_axi_ar_valid <= 0;
                            g_axi_r_ready <= 0;
                            g_axi_b_valid <= 0;
                            g_axi_b_resp <= 0;
                            g_axi_r_valid <= 0;
                            g_axi_r_last_flag <= 0;
                            g_axi_r_data <= 0;
                            g_axi_r_resp <= 0;
                        end else begin
                            g_axi_state <= AXI_W_SEND;
                            g_axi_w_valid <= 0;
                            g_axi_w_data <= 0;
                            g_axi_w_strb <= 0;
                            g_axi_w_last <= 0;
                            g_axi_w_ready <= m_axi_wready;
                            g_axi_b_ready <= 0;
                            g_axi_aw_valid <= 0;
                            g_axi_ar_valid <= 0;
                            g_axi_r_ready <= 0;
                            g_axi_b_valid <= 0;
                            g_axi_b_resp <= 0;
                            g_axi_r_valid <= 0;
                            g_axi_r_last_flag <= 0;
                            g_axi_r_data <= 0;
                            g_axi_r_resp <= 0;
                        end
                    end else begin
                        g_axi_w_ready <= 0;
                    end
                end

                AXI_B_WAIT: begin
                    if (g_axi_bvalid) begin
                        g_axi_state <= AXI_IDLE;
                        g_axi_b_ready <= 0;
                        g_axi_aw_valid <= 0;
                        g_axi_ar_valid <= 0;
                        g_axi_w_valid <= 0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= 1'b1;
                        g_axi_r_ready <= 0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                        
                        // Update remaining length and address
                        if (read_enable && g_read_active) begin
                            g_read_remaining_len <= g_read_remaining_len - g_axi_burst_len;
                            g_read_current_addr <= g_read_current_addr + (g_axi_burst_len << g_axi_burst_size);
                            if (g_read_remaining_len == 0) begin
                                g_read_active <= 0;
                                g_read_done <= 1;
                            end
                        end else if (write_enable && g_write_active) begin
                            g_write_remaining_len <= g_write_remaining_len - g_axi_burst_len;
                            g_write_current_addr <= g_write_current_addr + (g_axi_burst_len << g_axi_burst_size);
                            if (g_write_remaining_len == 0) begin
                                g_write_active <= 0;
                                g_write_done <= 1;
                            end
                        end
                    end else begin
                        g_axi_b_ready <= 1'b1;
                    end
                end

                AXI_AR_PREPARE: begin
                    // Not used in this simplified single-clock implementation as we do AW then W then B
                    // If needed for read-only paths without write, logic would go here
                    g_axi_ar_valid <= 0;
                    g_axi_ar_addr <= 0;
                    g_axi_ar_id <= 0;
                    g_axi_ar_len <= 0;
                    g_axi_ar_size <= 0;
                    g_axi_ar_burst <= 0;
                    g_axi_ar_lock <= 0;
                    g_axi_ar_cache <= 0;
                    g_axi_ar_prot <= 0;
                    g_axi_ar_ready <= 1'b1;
                    g_axi_w_valid <= 0;
                    g_axi_w_data <= 0;
                    g_axi_w_strb <= 0;
                    g_axi_w_last <= 0;
                    g_axi_w_ready <= 1'b1;
                    g_axi_r_ready <= 0;
                    g_axi_b_ready <= 0;
                    g_axi_b_valid <= 0;
                    g_axi_b_resp <= 0;
                    g_axi_r_valid <= 0;
                    g_axi_r_last_flag <= 0;
                    g_axi_r_data <= 0;
                    g_axi_r_resp <= 0;
                end

                AXI_AR_SEND: begin
                    // Similar to AW_SEND but for read
                    if (g_axi_arready) begin
                        g_axi_state <= AXI_R_WAIT;
                        g_axi_ar_valid <= 0;
                        g_axi_ar_addr <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_ar_len <= 0;
                        g_axi_ar_size <= 0;
                        g_axi_ar_burst <= 0;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_valid <= 1'b1;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= m_axi_wready;
                        g_axi_r_ready <= 0;
                        g_axi_b_ready <= 0;
                        g_axi_b_valid <= 0;
                        g_axi_b_resp <= 0;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else begin
                        g_axi_ar_ready <= 0;
                    end
                end

                AXI_R_WAIT: begin
                    if (g_axi_rvalid) begin
                        g_axi_state <= AXI_IDLE;
                        g_axi_r_ready <= 0;
                        g_axi_ar_valid <= 0;
                        g_axi_ar_addr <= 0;
                        g_axi_ar_id <= 0;
                        g_axi_ar_len <= 0;
                        g_axi_ar_size <= 0;
                        g_axi_ar_burst <= 0;
                        g_axi_ar_lock <= 0;
                        g_axi_ar_cache <= 0;
                        g_axi_ar_prot <= 0;
                        g_axi_ar_ready <= 1'b1;
                        g_axi_w_valid <= 0;
                        g_axi_w_data <= 0;
                        g_axi_w_strb <= 0;
                        g_axi_w_last <= 0;
                        g_axi_w_ready <= 1'b1;
                        g_axi_r_valid <= 0;
                        g_axi_r_last_flag <= 0;
                        g_axi_r_data <= 0;
                        g_axi_r_resp <= 0;
                    end else begin
                        g_axi_r_ready <= 1'b1;
                    end
                end

                default: begin
                    g_axi_state <= AXI_IDLE;
                    g_axi_aw_valid <= 0;
                    g_axi_ar_valid <= 0;
                    g_axi_w_valid <= 0;
                    g_axi_r_ready <= 0;
                    g_axi_b_ready <= 0;
                    g_axi_aw_ready <= 1'b1;
                    g_axi_ar_ready <= 1'b1;
                    g_axi_w_ready <= 1'b1;
                    g_axi_aw_addr <= 0;
                    g_axi_ar_addr <= 0;
                    g_axi_aw_id <= 0;
                    g_axi_ar_id <= 0;
                    g_axi_w_data <= 0;
                    g_axi_w_strb <= 0;
                    g_axi_b_resp <= 0;
                    g_axi_r_resp <= 0;
                end
            endcase
        end
    end

    // ---------------------------------------------------------------------------
    // Read Path Logic
    // ---------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            g_read_active <= 0;
            g_read_remaining_len <= 0;
            g_read_current_addr <= 0;
            g_read_current_id <= 0;
            g_read_current_dest <= 0;
            g_read_current_user <= 0;
            g_read_done <= 0;
            g_read_error <= 0;
            s_axis_read_desc_ready <= 0;
            m_axis_read_desc_status_valid <= 0;
            m_axis_read_data_tvalid <= 0;
            m_axis_read_data_tlast <= 0;
        end else begin
            // Descriptor Input
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                g_read_active <= 1;
                g_read_remaining_len <= s_axis_read_desc_len;
                g_read_current_addr <= s_axis_read_desc_addr;
                g_read_current_id <= s_axis_read_desc_id;
                g_read_current_dest <= s_axis_read_desc_dest;
                g_read_current_user <= s_axis_read_desc_user;
                g_read_done <= 0;
                g_read_error <= 0;
                s_axis_read_desc_ready <= 1;
            end else begin
                s_axis_read_desc_ready <= 0;
            end

            // Status Output
            m_axis_read_desc_status_tag <= g_read_done ? g_read_current_tag : 0;
            m_axis_read_desc_status_error <= g_read_done ? (g_read_error ? 4'b1111 : 4'b0000) : 4'b0000;
            m_axis_read_desc_status_valid <= g_read_done;

            // Stream Data Output
            if (g_axi_state == AXI_B_WAIT && g_read_active) begin
                m_axis_read_data_tvalid <= 1;
                m_axis_read_data_tdata <= g_axi_r_data;
                m_axis_read_data_tkeep <= AXIS_KEEP_MASK;
                m_axis_read_data_tlast <= (g_read_remaining_len == 0) ? 1'b1 : 1'b0;
                m_axis_read_data_tid <= g_read_current_id;
                m_axis_read_data_tdest <= g_read_current_dest;
                m_axis_read_data_tuser <= g_read_current_user;
            end else begin
                m_axis_read_data_tvalid <= 0;
                m_axis_read_data_tdata <= 0;
                m_axis_read_data_tkeep <= 0;
                m_axis_read_data_tlast <= 0;
                m_axis_read_data_tid <= 0;
                m_axis_read_data_tdest <= 0;
                m_axis_read_data_tuser <= 0;
            end
        end
    end

    // ---------------------------------------------------------------------------
    // Write Path Logic
    // ---------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            g_write_active <= 0;
            g_write_remaining_len <= 0;
            g_write_current_addr <= 0;
            g_write_current_id <= 0;
            g_write_current_dest <= 0;
            g_write_current_user <= 0;
            g_write_done <= 0;
            g_write_error <= 0;
            s_axis_write_desc_ready <= 0;
            m_axis_write_desc_status_valid <= 0;
            s_axis_write_data_tready <= 0;
        end else begin
            // Descriptor Input
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                g_write_active <= 1;
                g_write_remaining_len <= s_axis_write_desc_len;
                g_write_current_addr <= s_axis_write_desc_addr;
                g_write_current_id <= s_axis_write_desc_id;
                g_write_current_dest <= s_axis_write_desc_dest;
                g_write_current_user <= s_axis_write_desc_user;
                g_write_done <= 0;
                g_write_error <= 0;
                s_axis_write_desc_ready <= 1;
            end else begin
                s_axis_write_desc_ready <= 0;
            end

            // Stream Data Input
            if (g_axi_state == AXI_W_SEND && g_write_active) begin
                s_axis_write_data_tready <= 1;
                g_axi_w_data <= s_axis_write_data_tdata;
                g_axi_w_strb <= AXIS_KEEP_MASK;
                g_axi_w_last <= s_axis_write_data_tlast;
            end else begin
                s_axis_write_data_tready <= 0;
                g_axi_w_data <= 0;
                g_axi_w_strb <= 0;
                g_axi_w_last <= 0;
            end

            // Status Output
            m_axis_write_desc_status_len <= g_write_done ? g_write_remaining_len : 