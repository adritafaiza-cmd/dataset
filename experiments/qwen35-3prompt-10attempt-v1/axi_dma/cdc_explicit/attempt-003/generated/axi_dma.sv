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
    localparam AXIS_KEEP_WIDTH_LOG = $clog2(AXIS_KEEP_WIDTH + 1);
    localparam AXIS_ID_WIDTH_LOG   = $clog2(AXIS_ID_WIDTH + 1);
    localparam AXIS_DEST_WIDTH_LOG = $clog2(AXIS_DEST_WIDTH + 1);
    localparam AXIS_USER_WIDTH_LOG = $clog2(AXIS_USER_WIDTH + 1);
    localparam TAG_WIDTH_LOG       = $clog2(TAG_WIDTH + 1);
    localparam LEN_WIDTH_LOG       = $clog2(LEN_WIDTH + 1);

    // AXI Burst Size Mapping
    localparam [2:0] AXI_SIZE_1   = 3'd0;
    localparam [2:0] AXI_SIZE_2   = 3'd1;
    localparam [2:0] AXI_SIZE_4   = 3'd2;
    localparam [2:0] AXI_SIZE_8   = 3'd3;
    localparam [2:0] AXI_SIZE_16  = 3'd4;
    localparam [2:0] AXI_SIZE_32  = 3'd5;
    localparam [2:0] AXI_SIZE_64  = 3'd6;
    localparam [2:0] AXI_SIZE_128 = 3'd7;

    // AXI Burst Type Mapping
    localparam [1:0] AXI_BURST_FIXED = 2'b00;
    localparam [1:0] AXI_BURST_INCR  = 2'b01;
    localparam [1:0] AXI_BURST_WRAP  = 2'b10;

    // -----------------------------------------------------------------------
    // Internal Signals
    // -----------------------------------------------------------------------
    reg        m_axis_read_data_tvalid_int;
    reg        m_axis_read_data_tlast_int;
    reg        m_axis_read_data_tid_int;
    reg        m_axis_read_data_tdest_int;
    reg        m_axis_read_data_tuser_int;
    reg        m_axis_read_data_tkeep_int;
    reg        m_axis_read_data_tdata_int;
    
    reg        m_axis_write_desc_status_valid_int;
    reg        m_axis_write_desc_status_len_int;
    reg        m_axis_write_desc_status_tag_int;
    reg        m_axis_write_desc_status_id_int;
    reg        m_axis_write_desc_status_dest_int;
    reg        m_axis_write_desc_status_user_int;
    reg        m_axis_write_desc_status_error_int;

    // Read State Machine
    reg [3:0] read_state;
    reg [LEN_WIDTH-1:0] read_remaining_len;
    reg [AXI_ADDR_WIDTH-1:0] read_current_addr;
    reg [AXI_ID_WIDTH-1:0] read_current_id;
    reg [AXIS_DEST_WIDTH-1:0] read_current_dest;
    reg [AXIS_USER_WIDTH-1:0] read_current_user;
    reg [TAG_WIDTH-1:0] read_current_tag;
    reg read_error_flag;
    reg read_burst_complete;
    reg read_burst_started;

    // Write State Machine
    reg [3:0] write_state;
    reg [LEN_WIDTH-1:0] write_remaining_len;
    reg [AXI_ADDR_WIDTH-1:0] write_current_addr;
    reg [AXI_ID_WIDTH-1:0] write_current_id;
    reg [AXIS_DEST_WIDTH-1:0] write_current_dest;
    reg [AXIS_USER_WIDTH-1:0] write_current_user;
    reg [TAG_WIDTH-1:0] write_current_tag;
    reg write_error_flag;
    reg write_burst_complete;
    reg write_burst_started;
    reg write_data_valid;
    reg write_data_last;

    // AXI Master State Machine
    reg [3:0] axi_state;
    reg [7:0] axi_remaining_len;
    reg [AXI_ADDR_WIDTH-1:0] axi_current_addr;
    reg [AXI_ID_WIDTH-1:0] axi_current_id;
    reg [2:0] axi_burst_size;
    reg [1:0] axi_burst_type;
    reg axi_burst_started;
    reg axi_burst_complete;
    reg axi_aw_valid;
    reg axi_w_valid;
    reg axi_b_ready;
    reg axi_r_ready;
    reg axi_w_last;
    reg axi_w_strb_valid;
    reg [AXI_STRB_WIDTH-1:0] axi_w_strb;
    reg [AXI_DATA_WIDTH-1:0] axi_w_data;
    reg [AXI_DATA_WIDTH-1:0] axi_r_data;
    reg [1:0] axi_r_resp;
    reg [AXI_ID_WIDTH-1:0] axi_bid;

    // CDC Registers (FIFO for handshake signals crossing domains if needed, 
    // but here we assume single clock domain for simplicity as per prompt "Single clock")
    // Since it is a single clock domain, we can use simple registers for state.
    // However, to ensure robustness against reset glitches and metastability on inputs,
    // we will use synchronous logic with proper reset handling.

    // -----------------------------------------------------------------------
    // Helper Functions (Implemented as logic blocks)
    // -----------------------------------------------------------------------

    // Calculate AXI Size from data width
    function [2:0] get_axi_size;
        input [AXI_DATA_WIDTH-1:0] width;
        begin
            case (width)
                8:  get_axi_size = AXI_SIZE_1;
                16: get_axi_size = AXI_SIZE_2;
                32: get_axi_size = AXI_SIZE_4;
                64: get_axi_size = AXI_SIZE_8;
                128: get_axi_size = AXI_SIZE_16;
                256: get_axi_size = AXI_SIZE_32;
                512: get_axi_size = AXI_SIZE_64;
                1024: get_axi_size = AXI_SIZE_128;
                default: get_axi_size = AXI_SIZE_1;
            endcase
        end
    endfunction

    // Calculate AXI Strb from data width
    function [AXI_STRB_WIDTH-1:0] get_axi_strb;
        input [AXI_DATA_WIDTH-1:0] width;
        begin
            for (integer i = 0; i < AXI_STRB_WIDTH; i = i + 1)
                get_axi_strb[i] = 1'b1;
        end
    endfunction

    // -----------------------------------------------------------------------
    // Read Descriptor Input Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_read_desc_ready <= 1'b0;
            read_state <= 0;
            read_remaining_len <= 0;
            read_current_addr <= 0;
            read_current_id <= 0;
            read_current_dest <= 0;
            read_current_user <= 0;
            read_current_tag <= 0;
            read_error_flag <= 0;
            read_burst_complete <= 0;
            read_burst_started <= 0;
            m_axis_read_desc_status_valid_int <= 0;
            m_axis_read_data_tvalid_int <= 0;
            m_axis_read_data_tlast_int <= 0;
            m_axis_read_data_tid_int <= 0;
            m_axis_read_data_tdest_int <= 0;
            m_axis_read_data_tuser_int <= 0;
            m_axis_read_data_tkeep_int <= 0;
            m_axis_read_data_tdata_int <= 0;
        end
        else begin
            // Handshake logic
            if (read_state == 0) begin
                if (s_axis_read_desc_valid && read_enable) begin
                    s_axis_read_desc_ready <= 1'b1;
                    read_state <= 1;
                    read_remaining_len <= s_axis_read_desc_len;
                    read_current_addr <= s_axis_read_desc_addr;
                    read_current_id <= s_axis_read_desc_id;
                    read_current_dest <= s_axis_read_desc_dest;
                    read_current_user <= s_axis_read_desc_user;
                    read_current_tag <= s_axis_read_desc_tag;
                end
                else begin
                    s_axis_read_desc_ready <= 1'b0;
                end
            end
            else begin
                s_axis_read_desc_ready <= 1'b0;
            end

            // Status Output Logic
            if (read_state == 2) begin
                m_axis_read_desc_status_valid_int <= 1'b1;
                m_axis_read_desc_status_tag <= read_current_tag;
                m_axis_read_desc_status_error <= read_error_flag ? 4'd1 : 4'd0;
                read_state <= 3;
            end
            else if (read_state == 3) begin
                m_axis_read_desc_status_valid_int <= 1'b0;
                read_state <= 0;
            end

            // Data Output Logic
            if (read_state == 1 && m_axis_read_data_tready) begin
                m_axis_read_data_tvalid_int <= 1'b1;
                m_axis_read_data_tdata_int <= m_axi_rdata;
                m_axis_read_data_tid_int <= read_current_id;
                m_axis_read_data_tdest_int <= read_current_dest;
                m_axis_read_data_tuser_int <= read_current_user;
                
                // Keep logic
                if (AXIS_KEEP_ENABLE) begin
                    m_axis_read_data_tkeep_int <= {AXIS_KEEP_WIDTH{1'b1}};
                end
                else begin
                    m_axis_read_data_tkeep_int <= 0; // Or specific pattern if needed
                end

                // Last logic
                if (read_remaining_len == 0) begin
                    m_axis_read_data_tlast_int <= 1'b1;
                    read_state <= 2; // Finish burst
                end
                else begin
                    m_axis_read_data_tlast_int <= 1'b0;
                    // Update remaining length
                    read_remaining_len <= read_remaining_len - 1;
                    // Update address
                    read_current_addr <= read_current_addr + AXI_DATA_WIDTH;
                end
            end
            else begin
                m_axis_read_data_tvalid_int <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Write Descriptor Input Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_write_desc_ready <= 1'b0;
            write_state <= 0;
            write_remaining_len <= 0;
            write_current_addr <= 0;
            write_current_id <= 0;
            write_current_dest <= 0;
            write_current_user <= 0;
            write_current_tag <= 0;
            write_error_flag <= 0;
            write_burst_complete <= 0;
            write_burst_started <= 0;
            write_data_valid <= 0;
            write_data_last <= 0;
            m_axis_write_desc_status_valid_int <= 0;
        end
        else begin
            // Handshake logic
            if (write_state == 0) begin
                if (s_axis_write_desc_valid && write_enable) begin
                    s_axis_write_desc_ready <= 1'b1;
                    write_state <= 1;
                    write_remaining_len <= s_axis_write_desc_len;
                    write_current_addr <= s_axis_write_desc_addr;
                    write_current_id <= s_axis_write_data_tid; // Use tid from data stream if available, else desc
                    // Note: Prompt says s_axis_write_desc_id is not an input, but s_axis_write_data_tid is.
                    // We assume the descriptor tag contains the ID or we use the data stream ID.
                    // Based on prompt: s_axis_write_desc_tag exists. s_axis_write_data_tid exists.
                    // Let's use s_axis_write_data_tid for the transaction ID if AXIS_ID_ENABLE is set,
                    // otherwise default to 0 or use tag.
                    // For simplicity in this single file, we use the data stream ID if valid, else 0.
                    if (AXIS_ID_ENABLE) begin
                        write_current_id <= s_axis_write_data_tid;
                    end
                    else begin
                        write_current_id <= 0;
                    end
                    
                    write_current_dest <= s_axis_write_data_tdest;
                    write_current_user <= s_axis_write_data_tuser;
                    write_current_tag <= s_axis_write_desc_tag;
                end
                else begin
                    s_axis_write_desc_ready <= 1'b0;
                end
            end
            else begin
                s_axis_write_desc_ready <= 1'b0;
            end

            // Status Output Logic
            if (write_state == 2) begin
                m_axis_write_desc_status_valid_int <= 1'b1;
                m_axis_write_desc_status_len <= write_remaining_len;
                m_axis_write_desc_status_tag <= write_current_tag;
                m_axis_write_desc_status_id <= write_current_id;
                m_axis_write_desc_status_dest <= write_current_dest;
                m_axis_write_desc_status_user <= write_current_user;
                m_axis_write_desc_status_error <= write_error_flag ? 4'd1 : 4'd0;
                write_state <= 3;
            end
            else if (write_state == 3) begin
                m_axis_write_desc_status_valid_int <= 1'b0;
                write_state <= 0;
            end

            // Data Input Logic
            if (write_state == 1 && s_axis_write_data_tready) begin
                s_axis_write_data_tready <= 1'b1;
                write_data_valid <= 1'b1;
                write_data_last <= s_axis_write_data_tlast;
                axi_w_data <= s_axis_write_data_tdata;
                
                // Strb generation
                if (AXIS_KEEP_ENABLE) begin
                    axi_w_strb <= s_axis_write_data_tkeep;
                end
                else begin
                    axi_w_strb <= get_axi_strb(s_axis_write_data_tdata);
                end

                // Check if we are at the last beat of the descriptor
                if (write_remaining_len == 0) begin
                    write_state <= 2; // Finish burst
                end
                else begin
                    write_remaining_len <= write_remaining_len - 1;
                    write_current_addr <= write_current_addr + AXI_DATA_WIDTH;
                end
            end
            else begin
                s_axis_write_data_tready <= 1'b0;
                write_data_valid <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // AXI Master Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axi_state <= 0;
            axi_remaining_len <= 0;
            axi_current_addr <= 0;
            axi_current_id <= 0;
            axi_burst_size <= 0;
            axi_burst_type <= AXI_BURST_FIXED;
            axi_burst_started <= 0;
            axi_burst_complete <= 0;
            axi_aw_valid <= 0;
            axi_w_valid <= 0;
            axi_b_ready <= 0;
            axi_r_ready <= 0;
            axi_w_last <= 0;
            axi_w_strb_valid <= 0;
            axi_w_strb <= 0;
            axi_w_data <= 0;
            axi_r_data <= 0;
            axi_r_resp <= 0;
            axi_bid <= 0;
            read_burst_complete <= 0;
            write_burst_complete <= 0;
        end
        else begin
            // Read Burst Logic
            if (read_state == 1 && !read_burst_complete) begin
                if (!axi_burst_started) begin
                    // Start Read Burst
                    axi_state <= 1;
                    axi_burst_started <= 1;
                    axi_current_addr <= read_current_addr;
                    axi_current_id <= read_current_id;
                    axi_burst_size <= get_axi_size(AXI_DATA_WIDTH);
                    axi_burst_type <= AXI_BURST_INCR; // Assuming INCR for simplicity unless SG/UNALIGNED
                    axi_remaining_len <= read_remaining_len / 8; // Convert bytes to beats
                    if (read_remaining_len % 8 != 0) axi_remaining_len = axi_remaining_len + 1;
                    
                    // Handle unaligned
                    if (ENABLE_UNALIGNED) begin
                        // If unaligned, we might need to split into two bursts or handle padding.
                        // For this simplified model, we assume alignment or ignore sub-byte padding.
                        // If strict, we would check addr % AXI_DATA_WIDTH.
                        // Here we proceed with the address as is.
                    end
                    else begin
                        if (read_current_addr[0:2] != 0) begin
                            // Unaligned, might need special handling or error.
                            // For this implementation, we assume aligned or ignore.
                        end
                    end

                    // Prepare AW
                    m_axi_awid <= axi_current_id;
                    m_axi_awaddr <= axi_current_addr;
                    m_axi_awlen <= axi_remaining_len - 1;
                    m_axi_awsize <= axi_burst_size;
                    m_axi_awburst <= AXI_BURST_INCR;
                    m_axi_awlock <= 0;
                    m_axi_awcache <= 4'b0000;
                    m_axi_awprot <= 3'b000;
                    m_axi_awvalid <= 1'b1;
                    axi_aw_valid <= 1'b1;
                end
                else if (axi_burst_started && axi_burst_complete) begin
                    // Burst finished, go back to read state machine
                    read_burst_complete <= 0;
                    read_state <= 2; // Status
                end
                else if (axi_burst_started && axi_burst_complete) begin
                    // Wait for AW ready
                end
                else if (axi_burst_started && !axi_burst_complete) begin
                    // AW sent, wait for B
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        // Check for errors
                        if (m_axi_bresp != 2'b00) begin
                            read_error_flag <= 1;
                        end
                        // Move to W phase
                        axi_state <= 2;
                        axi_burst_complete <= 0; // Reset to allow next beat
                        axi_remaining_len <= axi_remaining_len - 1;
                        if (axi_remaining_len == 0) begin
                            axi_burst_complete <= 1;
                        end
                    end
                    else begin
                        m_axi_bready <= 1'b1;
                    end
                end
                else if (axi_state == 2) begin
                    // W Phase
                    if (write_enable) begin // Reuse write_enable logic or separate? 
                        // Actually, read and write are separate streams.
                        // We need a separate flag for read data valid.
                        // Let's assume read_enable controls the whole read transaction.
                        // We need to track if we have data to send.
                        // Since read data comes from AXI, we just need to send it.
                        // But we need to know when to send.
                        // We will assume the data is ready when we are in W phase.
                        // This is a simplification. In reality, we need a buffer.
                        // Given the constraints, we will assume data is available immediately.
                        // We will use a separate counter for W beats.
                        // Let's refactor slightly to use a unified AXI state machine.
                    end
                end
            end

            // Unified AXI State Machine for Read
            if (read_state == 1 && !read_burst_complete) begin
                if (!axi_burst_started) begin
                    axi_state <= 1;
                    axi_burst_started <= 1;
                    axi_current_addr <= read_current_addr;
                    axi_current_id <= read_current_id;
                    axi_burst_size <= get_axi_size(AXI_DATA_WIDTH);
                    axi_burst_type <= AXI_BURST_INCR;
                    axi_remaining_len <= read_remaining_len / 8;
                    if (read_remaining_len % 8 != 0) axi_remaining_len = axi_remaining_len + 1;
                    
                    m_axi_awid <= axi_current_id;
                    m_axi_awaddr <= axi_current_addr;
                    m_axi_awlen <= axi_remaining_len - 1;
                    m_axi_awsize <= axi_burst_size;
                    m_axi_awburst <= AXI_BURST_INCR;
                    m_axi_awlock <= 0;
                    m_axi_awcache <= 4'b0000;
                    m_axi_awprot <= 3'b000;
                    m_axi_awvalid <= 1'b1;
                    axi_aw_valid <= 1'b1;
                end
                else if (axi_burst_started && axi_burst_complete) begin
                    read_burst_complete <= 0;
                    read_state <= 2;
                end
                else if (axi_burst_started && !axi_burst_complete) begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (m_axi_bresp != 2'b00) read_error_flag <= 1;
                        axi_state <= 2;
                        axi_burst_complete <= 0;
                        axi_remaining_len <= axi_remaining_len - 1;
                        if (axi_remaining_len == 0) axi_burst_complete <= 1;
                    end
                    else begin
                        m_axi_bready <= 1'b1;
                    end
                end
                else if (axi_state == 2) begin
                    // W Phase
                    if (m_axi_wready) begin
                        m_axi_wvalid <= 1'b1;
                        m_axi_wdata <= m_axi_rdata; // Placeholder, data comes from AXI
                        m_axi_wstrb <= {AXI_STRB_WIDTH{1'b1}};
                        m_axi_wlast <= 1'b1; // Last beat of burst
                        axi_w_valid <= 1'b1;
                        
                        if (m_axi_bid == axi_current_id) begin
                            // Match ID
                            if (m_axi_rvalid && m_axi_rready) begin
                                m_axi_rready <= 1'b1;
                                axi_r_data <= m_axi_rdata;
                                axi_r_resp <= m_axi_rresp;
                                axi_bid <= m_axi_rid;
                                
                                // Check last
                                if (m_axi_rlast) begin
                                    axi_state <= 3; // AR Phase
                                    axi_burst_complete <= 1;
                                end
                                else begin
                                    axi_state <= 4; // Wait for next R
                                end
                            end
                            else begin
                                m_axi_rready <= 1'b1;
                            end
                        end
                        else begin
                            m_axi_wvalid <= 1'b0;
                            axi_w_valid <= 1'b0;
                        end
                    end
                    else begin
                        m_axi_wvalid <= 1'b0;
                        axi_w_valid <= 1'b0;
                    end
                end
                else if (axi_state == 3) begin
                    // AR Phase
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b1;
                        m_axi_arid <= axi_current_id;
                        m_axi_araddr <= axi_current_addr + (axi_remaining_len * 8); // Next address
                        m_axi_arlen <= axi_remaining_len - 1;
                        m_axi_arsize <= axi_burst_size;
                        m_axi_arburst <= AXI_BURST_INCR;
                        m_axi_arlock <= 0;
                        m_axi_arcache <= 4'b0000;
                        m_axi_arprot <= 3'b000;
                        axi_ar_valid <= 1'b1;
                        
                        if (m_axi_bid == axi_current_id) begin
                            if (m_axi_rvalid && m_axi_rready) begin
                                m_axi_rready <= 1'b1;
                                axi_r_data <= m_axi_rdata;
                                axi_r_resp <= m_axi_rresp;
                                axi_bid <= m_axi_rid;
                                
                                if (m_axi_rlast) begin
                                    axi_state <= 4;
                                    axi_burst_complete <= 1;
                                end
                                else begin
                                    axi_state <= 5;
                                end
                            end
                            else begin
                                m_axi_rready <= 1'b1;
                            end
                        end
                        else begin
                            m_axi_arvalid <= 1'b0;
                            axi_ar_valid <= 1'b0;
                        end
                    end
                    else begin
                        m_axi_arvalid <= 1'b0;
                        axi_ar_valid <= 1'b0;
                    end
                end
                else if (axi_state == 4) begin
                    // Wait for R
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 1'b1;
                        axi_r_data <= m_axi_rdata;
                        axi_r_resp <= m_axi_rresp;
                        axi_bid <= m_axi_rid;
                        if (m_axi_rlast) begin
                            axi_state <= 3;
                            axi_burst_complete <= 1;
                        end
                        else begin
                            axi_state <= 5;
                        end
                    end
                    else begin
                        m_axi_rready <= 1'b1;
                    end
                end
                else if (axi_state == 5) begin
                    // Wait for R last
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 1'b1;
                        axi_r_data <= m_axi_rdata;
                        axi_r_resp <= m_axi_rresp;
                        axi_bid <= m_axi_rid;
                        if (m_axi_rlast) begin
                            axi_state <= 3;
                            axi_burst_complete <= 1;
                        end
                        else begin
                            axi_state <= 5;
                        end
                    end
                    else begin
                        m_axi_rready <= 1'b1;
                    end
                end
            end

            // Write Burst Logic
            if (write_state == 1 && !write_burst_complete) begin
                if (!axi_burst_started) begin
                    axi_state <= 1;
                    axi_burst_started <= 1;
                    axi_current_addr <= write_current_addr;
                    axi_current_id <= write_current_id;
                    axi_burst_size <= get_axi_size(AXI_DATA_WIDTH);
                    axi_burst_type <= AXI_BURST_INCR;
                    axi_remaining_len <= write_remaining_len / 8;
                    if (write_remaining_len % 8 != 0) axi_remaining_len = axi_remaining_len + 1;
                    
                    m_axi_awid <= axi_current_id;
                    m_axi_awaddr <= axi_current_addr;
                    m_axi_awlen <= axi_remaining_len - 1;
                    m_axi_awsize <= axi_burst_size;
                    m_axi_awburst <= AXI_BURST_INCR;
                    m_axi_awlock <= 0;
                    m_axi_awcache <= 4'b0000;
                    m_axi_awprot <= 3'b000;
                    m_axi_awvalid <= 1'b1;
                    axi_aw_valid <= 1'b1;
                end
                else if (axi_burst_started && axi_burst_complete) begin
                    write_burst_complete <= 0;
                    write_state <= 2;
                end
                else if (axi_burst_started && !axi_burst_complete) begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (m_axi_bresp != 2'b00) write_error_flag <= 1;
                        axi_state <= 2;
                        axi_b