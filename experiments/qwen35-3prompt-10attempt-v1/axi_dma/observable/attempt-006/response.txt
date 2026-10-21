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

    // -----------------------------------------------------------------------
    // Internal Parameters and Constants
    // -----------------------------------------------------------------------
    localparam AXI_BURST_TYPE = 2'd0; // FIXED
    localparam AXI_BURST_LEN_MASK = (1 << AXI_MAX_BURST_LEN) - 1;
    localparam AXIS_KEEP_MASK = (1 << AXIS_KEEP_WIDTH) - 1;
    localparam AXIS_USER_MASK = (1 << AXIS_USER_WIDTH) - 1;
    localparam AXIS_DEST_MASK = (1 << AXIS_DEST_WIDTH) - 1;
    localparam AXIS_ID_MASK = (1 << AXIS_ID_WIDTH) - 1;
    localparam AXIS_LAST_MASK = 1'd1;
    
    // Size mapping for AXI
    localparam [2:0] SIZE_8 = 3'd0;
    localparam [2:0] SIZE_16 = 3'd1;
    localparam [2:0] SIZE_32 = 3'd2;
    localparam [2:0] SIZE_64 = 3'd3;
    localparam [2:0] SIZE_128 = 3'd4;
    localparam [2:0] SIZE_256 = 3'd5;
    localparam [2:0] SIZE_512 = 3'd6;
    localparam [2:0] SIZE_1024 = 3'd7;

    // -----------------------------------------------------------------------
    // State Machine Definition
    // -----------------------------------------------------------------------
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_READ_DESC,
        STATE_READ_DATA,
        STATE_WRITE_DESC,
        STATE_WRITE_DATA,
        STATE_WRITE_RESP,
        STATE_ERROR
    } state_t;

    state_t current_state, next_state;

    // -----------------------------------------------------------------------
    // AXI Master Control Signals
    // -----------------------------------------------------------------------
    logic aw_valid, aw_ready;
    logic ar_valid, ar_ready;
    logic w_valid, w_ready;
    logic b_valid, b_ready;
    logic r_valid, r_ready;

    logic aw_start, ar_start;
    logic w_start, r_start;
    logic burst_complete;
    logic data_transfer_complete;

    // -----------------------------------------------------------------------
    // AXI Address Calculation
    // -----------------------------------------------------------------------
    logic [AXI_ADDR_WIDTH-1:0] axi_addr;
    logic [LEN_WIDTH-1:0] axi_len;
    logic [7:0] axi_len_8;
    logic [2:0] axi_size;
    logic [1:0] axi_burst;
    logic [AXI_DATA_WIDTH-1:0] axi_strb;

    // -----------------------------------------------------------------------
    // Stream Data Buffers
    // -----------------------------------------------------------------------
    logic [AXIS_DATA_WIDTH-1:0] read_data_reg;
    logic [AXIS_KEEP_WIDTH-1:0] read_keep_reg;
    logic read_last_reg;
    logic read_valid_reg;
    logic read_ready_reg;

    logic [AXIS_DATA_WIDTH-1:0] write_data_reg;
    logic [AXIS_KEEP_WIDTH-1:0] write_keep_reg;
    logic write_last_reg;
    logic write_valid_reg;
    logic write_ready_reg;

    // -----------------------------------------------------------------------
    // Status Registers
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // AXI Master State Machine
    // -----------------------------------------------------------------------
    logic [AXI_ID_WIDTH-1:0] axi_awid_reg;
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr_reg;
    logic [7:0] axi_awlen_reg;
    logic [2:0] axi_awsize_reg;
    logic [1:0] axi_awburst_reg;
    logic [3:0] axi_awcache_reg;
    logic [2:0] axi_awprot_reg;
    
    logic [AXI_ID_WIDTH-1:0] axi_arid_reg;
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
    logic [7:0] axi_arlen_reg;
    logic [2:0] axi_arsize_reg;
    logic [1:0] axi_arburst_reg;
    logic [3:0] axi_arcache_reg;
    logic [2:0] axi_arprot_reg;

    logic [AXI_DATA_WIDTH-1:0] axi_wdata_reg;
    logic [AXI_STRB_WIDTH-1:0] axi_wstrb_reg;
    logic axi_wlast_reg;

    logic [AXI_ID_WIDTH-1:0] axi_bid_reg;
    logic [1:0] axi_bresp_reg;

    logic [AXI_DATA_WIDTH-1:0] axi_rdata_reg;
    logic [1:0] axi_rresp_reg;
    logic axi_rlast_reg;

    logic axi_aw_valid_int, axi_ar_valid_int, axi_w_valid_int, axi_b_valid_int, axi_r_valid_int;
    logic axi_aw_ready_int, axi_ar_ready_int, axi_w_ready_int, axi_b_ready_int, axi_r_ready_int;

    // -----------------------------------------------------------------------
    // Logic: Address and Length Setup
    // -----------------------------------------------------------------------
    assign axi_addr = (current_state == STATE_READ_DATA) ? s_axis_read_desc_addr : 
                      (current_state == STATE_WRITE_DATA) ? s_axis_write_desc_addr : 0;
    
    assign axi_len = (current_state == STATE_READ_DATA) ? s_axis_read_desc_len : 
                     (current_state == STATE_WRITE_DATA) ? s_axis_write_desc_len : 0;
    
    // Calculate AXI length (in beats)
    // Assuming data width is multiple of 8. 
    // If data width is not multiple of 8, we assume padding or error, but per spec AXI_STRB_WIDTH = DATA/8.
    // We assume data width is power of 2 and aligned to byte.
    // Simple division: len / (data_width/8)
    // Since LEN_WIDTH is 20, we need to be careful with division.
    // We will implement a simple shift if data_width is 32 (4 bytes). 
    // For generality, we assume data_width is 32, 64, 128, etc.
    // If AXI_DATA_WIDTH is 32, 1 beat = 4 bytes.
    // If AXI_DATA_WIDTH is 64, 1 beat = 8 bytes.
    
    // Helper to calculate beats based on data width
    // Since we cannot use div operator easily in combinational without large LUTs for wide widths,
    // and assuming standard widths (32, 64, 128...), we can use shifts.
    // Let's assume the most common case or use a generic approach if possible.
    // However, for a single file implementation without complex div logic, 
    // we will assume AXI_DATA_WIDTH is a power of 2 and calculate beats.
    // If DATA_WIDTH = 32, shift right by 2.
    // If DATA_WIDTH = 64, shift right by 3.
    // If DATA_WIDTH = 128, shift right by 4.
    // We will use a case statement for size mapping and assume standard widths for length calc.
    // To be safe and generic, we'll assume the user provides a width that allows simple shifting 
    // or we implement a small divider. Given the constraints, let's assume standard widths.
    // Actually, let's implement a simple divider for the length.
    
    logic [LEN_WIDTH-1:0] axi_len_beats;
    
    // Simple divider logic for common widths (32, 64, 128, 256, 512, 1024)
    // We assume data_width is power of 2.
    // beats = len / (data_width/8)
    // Let's assume data_width is 32 for this example logic to keep it simple, 
    // but we will try to make it generic using a case on data_width if needed.
    // For a robust single file, let's assume data_width is 32, 64, 128, 256, 512, 1024.
    // We will use a case statement to select the shift amount.
    
    logic [2:0] shift_amt;
    assign shift_amt = (AXI_DATA_WIDTH == 32) ? 3'd2 :
                       (AXI_DATA_WIDTH == 64) ? 3'd3 :
                       (AXI_DATA_WIDTH == 128) ? 3'd4 :
                       (AXI_DATA_WIDTH == 256) ? 3'd5 :
                       (AXI_DATA_WIDTH == 512) ? 3'd6 :
                       (AXI_DATA_WIDTH == 1024) ? 3'd7 : 3'd0;
                       
    assign axi_len_beats = axi_len >> shift_amt;

    // Size mapping
    assign axi_size = (AXI_DATA_WIDTH == 8) ? SIZE_8 :
                      (AXI_DATA_WIDTH == 16) ? SIZE_16 :
                      (AXI_DATA_WIDTH == 32) ? SIZE_32 :
                      (AXI_DATA_WIDTH == 64) ? SIZE_64 :
                      (AXI_DATA_WIDTH == 128) ? SIZE_128 :
                      (AXI_DATA_WIDTH == 256) ? SIZE_256 :
                      (AXI_DATA_WIDTH == 512) ? SIZE_512 :
                      (AXI_DATA_WIDTH == 1024) ? SIZE_1024 : 3'd0;

    // Burst length
    assign axi_awlen = axi_len_beats - 1;
    assign axi_arlen = axi_len_beats - 1;
    assign axi_burst = AXI_BURST_TYPE; // FIXED

    // Strb generation (all 1s)
    assign axi_strb = AXIS_KEEP_ENABLE ? AXIS_KEEP_MASK : AXIS_STRB_WIDTH{1'b1};

    // -----------------------------------------------------------------------
    // Logic: Stream Data Handling
    // -----------------------------------------------------------------------
    
    // Read Stream Logic
    assign m_axis_read_data_tdata = read_data_reg;
    assign m_axis_read_data_tkeep = read_keep_reg;
    assign m_axis_read_data_tvalid = read_valid_reg;
    assign m_axis_read_data_tready = m_axis_read_data_tready;
    assign m_axis_read_data_tlast = read_last_reg;
    assign m_axis_read_data_tid = s_axis_read_desc_id;
    assign m_axis_read_data_tdest = s_axis_read_desc_dest;
    assign m_axis_read_data_tuser = s_axis_read_desc_user;

    // Write Stream Logic
    assign s_axis_write_data_tready = write_ready_reg;
    assign s_axis_write_data_tdata = write_data_reg;
    assign s_axis_write_data_tkeep = write_keep_reg;
    assign s_axis_write_data_tlast = write_last_reg;
    assign s_axis_write_data_tid = s_axis_write_data_tid;
    assign s_axis_write_data_tdest = s_axis_write_data_tdest;
    assign s_axis_write_data_tuser = s_axis_write_data_tuser;

    // -----------------------------------------------------------------------
    // Logic: Descriptor Input/Output
    // -----------------------------------------------------------------------
    
    // Read Descriptor Input
    assign s_axis_read_desc_ready = (current_state == STATE_IDLE) && s_axis_read_desc_valid;
    
    // Write Descriptor Input
    assign s_axis_write_desc_ready = (current_state == STATE_IDLE) && s_axis_write_desc_valid;

    // Read Descriptor Status Output
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;

    // Write Descriptor Status Output
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;

    // -----------------------------------------------------------------------
    // Logic: AXI Master Control
    // -----------------------------------------------------------------------
    
    // AW Channel
    assign m_axi_awid = axi_awid_reg;
    assign m_axi_awaddr = axi_awaddr_reg;
    assign m_axi_awlen = axi_awlen;
    assign m_axi_awsize = axi_awsize;
    assign m_axi_awburst = axi_awburst;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = axi_awcache_reg;
    assign m_axi_awprot = axi_awprot_reg;
    assign m_axi_awvalid = aw_valid;
    assign aw_ready = m_axi_awready;

    // W Channel
    assign m_axi_wdata = axi_wdata_reg;
    assign m_axi_wstrb = axi_wstrb_reg;
    assign m_axi_wlast = axi_wlast_reg;
    assign m_axi_wvalid = w_valid;
    assign w_ready = m_axi_wready;

    // B Channel
    assign m_axi_bready = b_ready;
    assign b_valid = m_axi_bvalid;
    assign axi_bid_reg = m_axi_bid;
    assign axi_bresp_reg = m_axi_bresp;

    // AR Channel
    assign m_axi_arid = axi_arid_reg;
    assign m_axi_araddr = axi_araddr_reg;
    assign m_axi_arlen = axi_arlen;
    assign m_axi_arsize = axi_arsize;
    assign m_axi_arburst = axi_arburst;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = axi_arcache_reg;
    assign m_axi_arprot = axi_arprot_reg;
    assign m_axi_arvalid = ar_valid;
    assign ar_ready = m_axi_arready;

    // R Channel
    assign m_axi_rready = r_ready;
    assign r_valid = m_axi_rvalid;
    assign axi_rdata_reg = m_axi_rdata;
    assign axi_rresp_reg = m_axi_rresp;
    assign axi_rlast_reg = m_axi_rlast;

    // -----------------------------------------------------------------------
    // Logic: AXI Master State Machine Implementation
    // -----------------------------------------------------------------------
    
    // AW State
    assign axi_aw_valid_int = aw_valid && aw_ready;
    assign axi_awaddr_reg = axi_addr;
    assign axi_awlen_reg = axi_len_beats;
    assign axi_awsize_reg = axi_size;
    assign axi_awburst_reg = axi_burst;
    assign axi_awcache_reg = 4'b0000; // Write-through
    assign axi_awprot_reg = 3'b000; // Normal

    // W State
    assign axi_wdata_reg = AXI_DATA_WIDTH == 32 ? m_axi_wdata : 
                           (AXI_DATA_WIDTH == 64 ? m_axi_wdata : 
                           (AXI_DATA_WIDTH == 128 ? m_axi_wdata : 
                           (AXI_DATA_WIDTH == 256 ? m_axi_wdata : 
                           (AXI_DATA_WIDTH == 512 ? m_axi_wdata : 
                           (AXI_DATA_WIDTH == 1024 ? m_axi_wdata : 0))));
    assign axi_wstrb_reg = axi_strb;
    assign axi_wlast_reg = 1'b0; // Handled in state machine

    // B State
    assign b_ready = m_axi_bready;

    // AR State
    assign axi_arid_reg = AXI_ID_ENABLE ? s_axis_read_desc_id : 8'd0;
    assign axi_araddr_reg = axi_addr;
    assign axi_arlen_reg = axi_len_beats;
    assign axi_arsize_reg = axi_size;
    assign axi_arburst_reg = axi_burst;
    assign axi_arcache_reg = 4'b0000; // Write-through
    assign axi_arprot_reg = 3'b000; // Normal

    // R State
    assign r_ready = m_axi_rready;

    // -----------------------------------------------------------------------
    // Logic: Main State Machine
    // -----------------------------------------------------------------------
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            burst_complete <= 1'b0;
            data_transfer_complete <= 1'b0;
            // Reset registers
            read_data_reg <= 0;
            read_keep_reg <= 0;
            read_last_reg <= 0;
            read_valid_reg <= 0;
            read_status_tag <= 0;
            read_status_error <= 4'd0;
            read_status_valid <= 0;
            
            write_data_reg <= 0;
            write_keep_reg <= 0;
            write_last_reg <= 0;
            write_valid_reg <= 0;
            write_status_len <= 0;
            write_status_tag <= 0;
            write_status_id <= 0;
            write_status_dest <= 0;
            write_status_user <= 0;
            write_status_error <= 4'd0;
            write_status_valid <= 0;
            
            // Reset AXI registers
            axi_awid_reg <= 0;
            axi_awaddr_reg <= 0;
            axi_awlen_reg <= 0;
            axi_awsize_reg <= 0;
            axi_awburst_reg <= 0;
            axi_awcache_reg <= 0;
            axi_awprot_reg <= 0;
            
            axi_arid_reg <= 0;
            axi_araddr_reg <= 0;
            axi_arlen_reg <= 0;
            axi_arsize_reg <= 0;
            axi_arburst_reg <= 0;
            axi_arcache_reg <= 0;
            axi_arprot_reg <= 0;
            
            axi_wdata_reg <= 0;
            axi_wstrb_reg <= 0;
            axi_wlast_reg <= 0;
            
            axi_bid_reg <= 0;
            axi_bresp_reg <= 0;
            
            axi_rdata_reg <= 0;
            axi_rresp_reg <= 0;
            axi_rlast_reg <= 0;
            
            // Reset AXI control signals
            aw_valid <= 1'b0;
            ar_valid <= 1'b0;
            w_valid <= 1'b0;
            b_ready <= 1'b0;
            r_ready <= 1'b0;
            
            axi_aw_valid_int <= 1'b0;
            axi_ar_valid_int <= 1'b0;
            axi_w_valid_int <= 1'b0;
            axi_b_valid_int <= 1'b0;
            axi_r_valid_int <= 1'b0;
            
            burst_complete <= 1'b0;
            data_transfer_complete <= 1'b0;
        end else begin
            current_state <= next_state;
            
            // Reset burst complete flag if not in transfer states
            if (current_state == STATE_IDLE) burst_complete <= 1'b0;
            if (current_state == STATE_ERROR) burst_complete <= 1'b0;
            
            // Reset data transfer complete flag if not in transfer states
            if (current_state == STATE_IDLE) data_transfer_complete <= 1'b0;
            if (current_state == STATE_ERROR) data_transfer_complete <= 1'b0;
        end
    end

    always @(*) begin
        next_state = current_state;
        burst_complete = 1'b0;
        data_transfer_complete = 1'b0;
        
        case (current_state)
            STATE_IDLE: begin
                if (read_enable && s_axis_read_desc_valid) begin
                    next_state = STATE_READ_DESC;
                end else if (write_enable && s_axis_write_desc_valid) begin
                    next_state = STATE_WRITE_DESC;
                end
            end

            STATE_READ_DESC: begin
                if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                    // Load descriptor info
                    read_status_tag <= s_axis_read_desc_tag;
                    read_status_error <= 4'd0;
                    read_status_valid <= 1'b0;
                    
                    // Start AXI Read
                    axi_aw_valid_int = 1'b1;
                    axi_ar_valid_int = 1'b1;
                    axi_w_valid_int = 1'b0;
                    axi_b_valid_int = 1'b0;
                    axi_r_valid_int = 1'b0;
                    
                    // Wait for AW and AR ready
                    if (aw_ready && ar_ready) begin
                        // Start W transfer
                        axi_w_valid_int = 1'b1;
                        axi_wlast_reg = 1'b0;
                        next_state = STATE_READ_DATA;
                    end else if (aw_ready) begin
                        // Wait for AR
                        next_state = STATE_READ_DATA;
                    end else if (ar_ready) begin
                        // Wait for AW
                        next_state = STATE_READ_DATA;
                    end
                end
            end

            STATE_READ_DATA: begin
                // Handle Write Response (B)
                if (b_valid && b_ready) begin
                    axi_b_ready = 1'b1;
                    axi_b_valid_int = 1'b0;
                    // Check for errors
                    if (m_axi_bresp != 2'b00) begin
                        read_status_error <= 4'd1; // Write Error
                        next_state = STATE_ERROR;
                    end else begin
                        // Start Read
                        axi_r_valid_int = 1'b1;
                        axi_r_ready = 1'b0; // Will be set in next cycle
                        next_state = STATE_READ_DATA;
                    end
                }
                
                // Handle Read Response (R)
                if (r_valid && r_ready) begin
                    axi_r_ready = 1'b1;
                    axi_r_valid_int = 1'b0;
                    
                    // Check for errors
                    if (m_axi_rresp != 2'b00) begin
                        read_status_error <= 4'd2; // Read Error
                        next_state = STATE_ERROR;
                    end else begin
                        // Update stream data
                        read_data_reg <= m_axi_rdata;
                        read_keep_reg <= AXIS_KEEP_MASK;
                        read_last_reg <= m_axi_rlast;
                        read_valid_reg <= 1'b1;
                        
                        // Check if last beat
                        if (m_axi_rlast) begin
                            data_transfer_complete = 1'b1;
                            // Prepare status
                            read_status_valid <= 1'b1;
                            next_state = STATE_IDLE;
                        end else begin
                            // Continue reading
                            axi_r_valid_int = 1'b1;
                            next_state = STATE_READ_DATA;
                        end
                    end
                }
                
                // Handle Write Data (W)
                if (w_valid && w_ready) begin
                    axi_w_ready = 1'b1;
                    axi_w_valid_int = 1'b0;
                    
                    // Check if last beat
                    if (m_axi_wlast) begin
                        axi_wlast_reg = 1'b1;
                        // Start Read
                        axi_r_valid_int = 1'b1;
                        axi_r_ready = 1'b0;
                        next_state = STATE_READ_DATA;
                    end else begin
                        // Continue writing
                        axi_w_valid_int = 1'b1;
                        axi_wlast_reg = 1'b0;
                        next_state = STATE_READ_DATA;
                    end
                }
                
                // Handle Write Response (B)
                if (b_valid && b_ready) begin
                    axi_b_ready = 1'b1;
                    axi_b_valid_int = 1'b0;
                    // Check for errors
                    if (m_axi_bresp != 2'b00) begin
                        read_status_error <= 4'd1; // Write Error
                        next_state = STATE_ERROR;
                    end else begin
                        // Start Read
                        axi_r_valid_int = 1'b1;
                        axi_r_ready = 1'b0;
                        next_state = STATE_READ_DATA;
                    end
                }
            end

            STATE_WRITE_DESC: begin
                if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                    // Load descriptor info
                    write_status_len <= s_axis_write_desc_len;
                    write_status_tag <= s_axis_write_desc_tag;
                    write_status_id <= s_axis_write_desc_id;
                    write_status_dest <= s_axis_write_desc_dest;
                    write_status_user <= s_axis_write_desc_user;
                    write_status_error <= 4'd0;
                    write_status_valid <= 1'b0;
                    
                    // Start AXI Write
                    axi_aw_valid_int = 1'b1;
                    axi_ar_valid_int = 1'b0;
                    axi_w_valid_int = 1'b0;
                    axi_b_valid_int = 1'b0;
                    axi_r_valid_int = 1'b0;
                    
                    // Wait for AW ready
                    if (aw_ready) begin
                        // Start W transfer
                        axi_w_valid_int = 1'b1;
                        axi_wlast_reg = 1'b0;
                        next_state = STATE_WRITE_DATA;
                    end
                end
            end

            STATE_WRITE_DATA: begin
                // Handle Write Data (W)
                if (w_valid && w_ready) begin
                    axi_w_ready = 1'b1;
                    axi_w_valid_int = 1'b0;
                    
                    // Check if last beat
                    if (m_axi_wlast) begin
                        axi_wlast_reg = 1'b1;
                        // Start Read Response
                        axi_b_valid_int = 1'b1;
                        axi_b_ready = 1'b0;
                        next_state = STATE_WRITE_RESP;
                    end else begin
                        // Continue writing
                        axi_w_valid_int = 1'b1;
                        axi_wlast_reg = 1'b0;
                        next_state = STATE_WRITE_DATA;
                    end
                }
                
                // Handle Write Response (B)
                if (b_valid && b_ready) begin
                    axi_b_ready = 1'b1;
                    axi_b_valid_int = 1'b0;
                    
                    // Check for errors
                    if (m_axi_bresp != 2'b00) begin
                        write_status_error <= 4'd1; // Write Error
                        next_state = STATE_ERROR;
                    end else begin
                        // Prepare status
                        write_status_valid <= 1'b1;
                        next_state = STATE_IDLE;
                    end
                }
            end

            STATE_WRITE_RESP: begin
                // Wait for B ready
                if (b_ready) begin
                    axi_b_ready = 1'b1;
                    // Check for errors
                    if (m_axi_bresp != 2'b00) begin
                        write_status_error <= 4'd1; // Write Error
                        next_state = STATE_ERROR;
                    end else begin
                        // Prepare status
                        write_status_valid <= 1'b1;
                        next_state = STATE_IDLE;
                    end
                end
            end

            STATE_ERROR: begin
                // Stay in error state until reset
            end

            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // -----------------------------------------------------------------------
    // Logic: AXI Control Signal Updates
    // -----------------------------------------------------------------------
    
    // AW Control
    assign aw_valid = (current_state == STATE_READ_DESC) || 
                      (current_state == STATE_WRITE_DESC) ||
                      (current_state == STATE_READ_DATA && axi_aw_valid_int) ||
                      (current_state == STATE_WRITE_DATA && axi_aw_valid_int);
                      
    // AR Control
    assign ar_valid =