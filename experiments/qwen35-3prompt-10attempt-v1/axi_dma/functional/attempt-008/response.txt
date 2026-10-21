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

    // Local parameters for internal widths
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam AXIS_KEEP_WIDTH_LOG2 = $clog2(AXIS_KEEP_WIDTH + 1);

    // Internal State Registers
    reg [TAG_WIDTH-1:0]     read_desc_tag;
    reg [LEN_WIDTH-1:0]     read_desc_len;
    reg [AXIS_ID_WIDTH-1:0] read_desc_id;
    reg [AXIS_DEST_WIDTH-1:0] read_desc_dest;
    reg [AXIS_USER_WIDTH-1:0] read_desc_user;
    reg                     read_desc_valid;
    reg                     read_desc_done;
    reg                     read_desc_error;
    reg                     read_desc_active;

    reg [TAG_WIDTH-1:0]     write_desc_tag;
    reg [LEN_WIDTH-1:0]     write_desc_len;
    reg [AXIS_ID_WIDTH-1:0] write_desc_id;
    reg [AXIS_DEST_WIDTH-1:0] write_desc_dest;
    reg [AXIS_USER_WIDTH-1:0] write_desc_user;
    reg                     write_desc_valid;
    reg                     write_desc_done;
    reg                     write_desc_error;
    reg                     write_desc_active;

    // AXI Transaction State
    reg                     axi_aw_valid;
    reg                     axi_ar_valid;
    reg                     axi_w_valid;
    reg                     axi_b_ready;
    reg                     axi_r_ready;
    
    reg [AXI_ADDR_WIDTH-1:0] axi_aw_addr;
    reg [AXI_ADDR_WIDTH-1:0] axi_ar_addr;
    reg [7:0]                axi_aw_len;
    reg [7:0]                axi_ar_len;
    reg [2:0]                axi_aw_size;
    reg [2:0]                axi_ar_size;
    reg [1:0]                axi_aw_burst;
    reg [1:0]                axi_ar_burst;
    reg                      axi_w_last;
    reg                      axi_aw_valid_reg;
    reg                      axi_ar_valid_reg;
    reg                      axi_w_valid_reg;
    reg                      axi_b_valid_reg;
    reg                      axi_r_valid_reg;
    
    reg [AXI_DATA_WIDTH-1:0] axi_w_data;
    reg [AXI_STRB_WIDTH-1:0] axi_w_strb;
    
    reg [LEN_WIDTH-1:0]      axi_remaining_len;
    reg                      axi_burst_complete;
    reg                      axi_read_burst_complete;
    reg                      axi_write_burst_complete;
    reg                      axi_read_burst_active;
    reg                      axi_write_burst_active;
    reg                      axi_read_burst_done;
    reg                      axi_write_burst_done;
    reg                      axi_read_burst_error;
    reg                      axi_write_burst_error;

    // Stream Data State (Read)
    reg [AXI_DATA_WIDTH-1:0] stream_read_data;
    reg [AXIS_KEEP_WIDTH-1:0] stream_read_keep;
    reg                      stream_read_valid;
    reg                      stream_read_last;
    reg                      stream_read_active;
    reg                      stream_read_done;
    reg                      stream_read_error;

    // Stream Data State (Write)
    reg                      stream_write_valid;
    reg                      stream_write_last;
    reg                      stream_write_active;
    reg                      stream_write_done;
    reg                      stream_write_error;

    // AXI Master Control Signals
    wire                     m_axi_awid_signal;
    wire                     m_axi_awaddr_signal;
    wire                     m_axi_awlen_signal;
    wire                     m_axi_awsize_signal;
    wire                     m_axi_awburst_signal;
    wire                     m_axi_awlock_signal;
    wire                     m_axi_awcache_signal;
    wire                     m_axi_awprot_signal;
    wire                     m_axi_awvalid_signal;
    wire                     m_axi_wdata_signal;
    wire                     m_axi_wstrb_signal;
    wire                     m_axi_wlast_signal;
    wire                     m_axi_wvalid_signal;
    wire                     m_axi_bready_signal;
    wire                     m_axi_arid_signal;
    wire                     m_axi_araddr_signal;
    wire                     m_axi_arlen_signal;
    wire                     m_axi_arsize_signal;
    wire                     m_axi_arburst_signal;
    wire                     m_axi_arlock_signal;
    wire                     m_axi_arcache_signal;
    wire                     m_axi_arprot_signal;
    wire                     m_axi_arvalid_signal;
    wire                     m_axi_rready_signal;

    assign m_axi_awid = axi_aw_valid ? read_desc_id : 8'd0;
    assign m_axi_awaddr = axi_aw_valid ? axi_aw_addr : 16'd0;
    assign m_axi_awlen = axi_aw_valid ? axi_aw_len : 8'd0;
    assign m_axi_awsize = axi_aw_valid ? axi_aw_size : 3'd0;
    assign m_axi_awburst = axi_aw_valid ? axi_aw_burst : 2'd0;
    assign m_axi_awlock = axi_aw_valid ? 1'b0 : 1'b0;
    assign m_axi_awcache = axi_aw_valid ? 4'd0 : 4'd0;
    assign m_axi_awprot = axi_aw_valid ? 3'd0 : 3'd0;
    assign m_axi_awvalid = axi_aw_valid;
    
    assign m_axi_wdata = axi_w_valid ? axi_w_data : 32'd0;
    assign m_axi_wstrb = axi_w_valid ? axi_w_strb : 4'hF;
    assign m_axi_wlast = axi_w_valid ? axi_w_last : 1'b0;
    assign m_axi_wvalid = axi_w_valid;
    assign m_axi_bready = axi_b_ready;
    
    assign m_axi_arid = axi_ar_valid ? read_desc_id : 8'd0;
    assign m_axi_araddr = axi_ar_valid ? axi_ar_addr : 16'd0;
    assign m_axi_arlen = axi_ar_valid ? axi_ar_len : 8'd0;
    assign m_axi_arsize = axi_ar_valid ? axi_ar_size : 3'd0;
    assign m_axi_arburst = axi_ar_valid ? axi_ar_burst : 2'd0;
    assign m_axi_arlock = axi_ar_valid ? 1'b0 : 1'b0;
    assign m_axi_arcache = axi_ar_valid ? 4'd0 : 4'd0;
    assign m_axi_arprot = axi_ar_valid ? 3'd0 : 3'd0;
    assign m_axi_arvalid = axi_ar_valid;
    assign m_axi_rready = axi_r_ready;

    // ------------------------------------------------------------------
    // AXI Master State Machine
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axi_aw_valid <= 1'b0;
            axi_ar_valid <= 1'b0;
            axi_w_valid <= 1'b0;
            axi_b_ready <= 1'b0;
            axi_r_ready <= 1'b0;
            axi_aw_addr <= 16'd0;
            axi_ar_addr <= 16'd0;
            axi_aw_len <= 8'd0;
            axi_ar_len <= 8'd0;
            axi_aw_size <= 3'd0;
            axi_ar_size <= 3'd0;
            axi_aw_burst <= 2'd0;
            axi_ar_burst <= 2'd0;
            axi_w_last <= 1'b0;
            axi_w_data <= 32'd0;
            axi_w_strb <= 4'hF;
            axi_remaining_len <= 0;
            axi_burst_complete <= 1'b0;
            axi_read_burst_complete <= 1'b0;
            axi_write_burst_complete <= 1'b0;
            axi_read_burst_active <= 1'b0;
            axi_write_burst_active <= 1'b0;
            axi_read_burst_done <= 1'b0;
            axi_write_burst_done <= 1'b0;
            axi_read_burst_error <= 1'b0;
            axi_write_burst_error <= 1'b0;
        end else begin
            // Reset burst completion flags when new transaction starts
            if (axi_aw_valid && axi_awready) begin
                axi_burst_complete <= 1'b0;
                axi_read_burst_complete <= 1'b0;
                axi_write_burst_complete <= 1'b0;
                axi_read_burst_active <= 1'b0;
                axi_write_burst_active <= 1'b0;
                axi_read_burst_done <= 1'b0;
                axi_write_burst_done <= 1'b0;
                axi_read_burst_error <= 1'b0;
                axi_write_burst_error <= 1'b0;
            end

            // Address Phase (AW)
            if (axi_aw_valid && m_axi_awready) begin
                axi_aw_addr <= s_axis_read_desc_addr; // Use read addr for now, write will override logic
                axi_aw_len <= axi_aw_len;
                axi_aw_size <= axi_aw_size;
                axi_aw_burst <= axi_aw_burst;
                axi_burst_complete <= 1'b1;
                axi_read_burst_active <= 1'b1;
                axi_write_burst_active <= 1'b1;
            end

            // Write Data Phase (W)
            if (axi_w_valid && m_axi_wready) begin
                axi_w_data <= s_axis_write_data_tdata;
                axi_w_strb <= s_axis_write_data_tkeep;
                axi_w_last <= s_axis_write_data_tlast;
            end

            // Write Response Phase (B)
            if (m_axi_bvalid) begin
                axi_b_ready <= 1'b1;
                if (m_axi_bresp != 2'b00) begin
                    axi_read_burst_error <= 1'b1;
                    axi_write_burst_error <= 1'b1;
                end
                axi_burst_complete <= 1'b1;
                axi_read_burst_active <= 1'b0;
                axi_write_burst_active <= 1'b0;
            end

            // Read Address Phase (AR)
            if (axi_ar_valid && m_axi_arready) begin
                axi_ar_addr <= s_axis_read_desc_addr;
                axi_ar_len <= axi_ar_len;
                axi_ar_size <= axi_ar_size;
                axi_ar_burst <= axi_ar_burst;
                axi_read_burst_active <= 1'b1;
            end

            // Read Response Phase (R)
            if (m_axi_rvalid) begin
                axi_r_ready <= 1'b1;
                if (m_axi_rresp != 2'b00) begin
                    axi_read_burst_error <= 1'b1;
                end
                axi_read_burst_complete <= 1'b1;
                axi_read_burst_active <= 1'b0;
            end

            // Burst Completion Logic
            if (axi_burst_complete) begin
                axi_read_burst_done <= 1'b1;
                axi_write_burst_done <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Descriptor Processing Logic
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_desc_tag <= 8'd0;
            read_desc_len <= 0;
            read_desc_id <= 8'd0;
            read_desc_dest <= 8'd0;
            read_desc_user <= 1'd0;
            read_desc_valid <= 1'b0;
            read_desc_done <= 1'b0;
            read_desc_active <= 1'b0;
            read_desc_error <= 1'b0;

            write_desc_tag <= 8'd0;
            write_desc_len <= 0;
            write_desc_id <= 8'd0;
            write_desc_dest <= 8'd0;
            write_desc_user <= 1'd0;
            write_desc_valid <= 1'b0;
            write_desc_done <= 1'b0;
            write_desc_active <= 1'b0;
            write_desc_error <= 1'b0;
        end else begin
            // Read Descriptor Input
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                read_desc_tag <= s_axis_read_desc_tag;
                read_desc_len <= s_axis_read_desc_len;
                read_desc_id <= s_axis_read_desc_id;
                read_desc_dest <= s_axis_read_desc_dest;
                read_desc_user <= s_axis_read_desc_user;
                read_desc_valid <= 1'b1;
                read_desc_done <= 1'b0;
                read_desc_active <= 1'b1;
            end

            // Write Descriptor Input
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                write_desc_tag <= s_axis_write_desc_tag;
                write_desc_len <= s_axis_write_desc_len;
                write_desc_id <= s_axis_write_data_tid; // Use stream ID if available, else desc ID
                write_desc_dest <= s_axis_write_data_tdest;
                write_desc_user <= s_axis_write_data_tuser;
                write_desc_valid <= 1'b1;
                write_desc_done <= 1'b0;
                write_desc_active <= 1'b1;
            end

            // Read Descriptor Status Output
            if (read_desc_valid && read_desc_done) begin
                m_axis_read_desc_status_tag <= read_desc_tag;
                m_axis_read_desc_status_error <= read_desc_error ? 4'd1 : 4'd0;
                m_axis_read_desc_status_valid <= 1'b1;
                read_desc_valid <= 1'b0;
            end else begin
                m_axis_read_desc_status_tag <= 8'd0;
                m_axis_read_desc_status_error <= 4'd0;
                m_axis_read_desc_status_valid <= 1'b0;
            end

            // Write Descriptor Status Output
            if (write_desc_valid && write_desc_done) begin
                m_axis_write_desc_status_len <= write_desc_len;
                m_axis_write_desc_status_tag <= write_desc_tag;
                m_axis_write_desc_status_id <= write_desc_id;
                m_axis_write_desc_status_dest <= write_desc_dest;
                m_axis_write_desc_status_user <= write_desc_user;
                m_axis_write_desc_status_error <= write_desc_error ? 4'd1 : 4'd0;
                m_axis_write_desc_status_valid <= 1'b1;
                write_desc_valid <= 1'b0;
            end else begin
                m_axis_write_desc_status_len <= 0;
                m_axis_write_desc_status_tag <= 8'd0;
                m_axis_write_desc_status_id <= 8'd0;
                m_axis_write_desc_status_dest <= 8'd0;
                m_axis_write_desc_status_user <= 1'd0;
                m_axis_write_desc_status_error <= 4'd0;
                m_axis_write_desc_status_valid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // AXI Transaction Initiation
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axi_aw_valid <= 1'b0;
            axi_ar_valid <= 1'b0;
            axi_w_valid <= 1'b0;
            axi_w_last <= 1'b0;
            axi_remaining_len <= 0;
        end else begin
            // Read Transaction Initiation
            if (read_enable && read_desc_valid && !read_desc_active && !axi_read_burst_active) begin
                // Calculate burst length
                // Align length to AXI burst granularity if needed
                // For simplicity, assume we can burst up to AXI_MAX_BURST_LEN
                // If len > max, we might need multiple bursts, but for this single-clock engine,
                // we assume len <= AXI_MAX_BURST_LEN or handle overflow by truncation/error.
                // Here we assume len fits or we cap it.
                
                reg [7:0] burst_len;
                if (s_axis_read_desc_len > AXI_MAX_BURST_LEN) begin
                    burst_len = AXI_MAX_BURST_LEN;
                    // In a full implementation, we would queue multiple bursts.
                    // For this simplified single-clock engine, we assume the descriptor fits.
                    // If it doesn't, we might error out or truncate. Let's assume fit for now.
                end else begin
                    burst_len = s_axis_read_desc_len;
                end

                // Determine size and alignment
                // If ENABLE_UNALIGNED is 0, we must align.
                // For this implementation, we assume aligned access or handle misalignment by padding.
                // Simplified: Assume aligned for this demo.
                
                axi_aw_addr <= s_axis_read_desc_addr;
                axi_ar_addr <= s_axis_read_desc_addr;
                axi_aw_len <= burst_len - 1;
                axi_ar_len <= burst_len - 1;
                axi_aw_size <= 3'd0; // 32-bit
                axi_ar_size <= 3'd0;
                axi_aw_burst <= 2'd0; // FIXED
                axi_ar_burst <= 2'd0;
                axi_w_last <= 1'b0;
                axi_remaining_len <= burst_len;
                
                axi_read_burst_active <= 1'b1;
                axi_read_burst_done <= 1'b0;
                axi_read_burst_error <= 1'b0;
                
                // Start AW
                axi_aw_valid <= 1'b1;
                axi_w_valid <= 1'b0;
                axi_ar_valid <= 1'b0;
            end

            // Write Transaction Initiation
            if (write_enable && write_desc_valid && !write_desc_active && !axi_write_burst_active) begin
                reg [7:0] burst_len;
                if (s_axis_write_desc_len > AXI_MAX_BURST_LEN) begin
                    burst_len = AXI_MAX_BURST_LEN;
                end else begin
                    burst_len = s_axis_write_desc_len;
                end

                axi_aw_addr <= s_axis_write_desc_addr;
                axi_ar_addr <= s_axis_write_desc_addr;
                axi_aw_len <= burst_len - 1;
                axi_ar_len <= burst_len - 1;
                axi_aw_size <= 3'd0;
                axi_ar_size <= 3'd0;
                axi_aw_burst <= 2'd0;
                axi_ar_burst <= 2'd0;
                axi_w_last <= 1'b0;
                axi_remaining_len <= burst_len;
                
                axi_write_burst_active <= 1'b1;
                axi_write_burst_done <= 1'b0;
                axi_write_burst_error <= 1'b0;
                
                axi_aw_valid <= 1'b1;
                axi_w_valid <= 1'b0;
                axi_ar_valid <= 1'b0;
            end

            // Handle Write Abort
            if (write_abort && write_desc_active) begin
                write_desc_error <= 1'b1;
                write_desc_active <= 1'b0;
                write_desc_valid <= 1'b0;
                axi_aw_valid <= 1'b0;
                axi_w_valid <= 1'b0;
                axi_ar_valid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // AXI Burst Execution Logic
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stream_read_valid <= 1'b0;
            stream_read_last <= 1'b0;
            stream_read_active <= 1'b0;
            stream_read_done <= 1'b0;
            stream_read_error <= 1'b0;
            stream_write_valid <= 1'b0;
            stream_write_last <= 1'b0;
            stream_write_active <= 1'b0;
            stream_write_done <= 1'b0;
            stream_write_error <= 1'b0;
            m_axis_read_data_tvalid <= 1'b0;
            m_axis_read_data_tlast <= 1'b0;
            m_axis_read_data_tdata <= 32'd0;
            m_axis_read_data_tkeep <= 4'hF;
            m_axis_read_data_tid <= 8'd0;
            m_axis_read_data_tdest <= 8'd0;
            m_axis_read_data_tuser <= 1'd0;
            s_axis_write_data_tready <= 1'b0;
        end else begin
            // Read Stream Data Output
            if (axi_read_burst_active && m_axi_rvalid) begin
                m_axis_read_data_tdata <= m_axi_rdata;
                m_axis_read_data_tkeep <= 4'hF;
                m_axis_read_data_tid <= read_desc_id;
                m_axis_read_data_tdest <= read_desc_dest;
                m_axis_read_data_tuser <= read_desc_user;
                m_axis_read_data_tvalid <= 1'b1;
                
                if (m_axi_rlast) begin
                    m_axis_read_data_tlast <= 1'b1;
                    stream_read_last <= 1'b1;
                    axi_read_burst_active <= 1'b0;
                    axi_read_burst_complete <= 1'b1;
                    read_desc_done <= 1'b1;
                end else begin
                    m_axis_read_data_tlast <= 1'b0;
                    stream_read_last <= 1'b0;
                end
            end else begin
                m_axis_read_data_tvalid <= 1'b0;
                m_axis_read_data_tlast <= 1'b0;
                m_axis_read_data_tdata <= 32'd0;
                m_axis_read_data_tkeep <= 4'hF;
                m_axis_read_data_tid <= 8'd0;
                m_axis_read_data_tdest <= 8'd0;
                m_axis_read_data_tuser <= 1'd0;
            end

            // Write Stream Data Input
            if (axi_write_burst_active && m_axi_wready) begin
                m_axi_wdata <= s_axis_write_data_tdata;
                m_axi_wstrb <= s_axis_write_data_tkeep;
                m_axi_wlast <= s_axis_write_data_tlast;
                m_axi_wvalid <= 1'b1;
                s_axis_write_data_tready <= 1'b1;
            end else begin
                m_axi_wvalid <= 1'b0;
                s_axis_write_data_tready <= 1'b0;
            end

            // Stream Write Valid Logic
            if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                stream_write_valid <= 1'b1;
                stream_write_last <= s_axis_write_data_tlast;
                stream_write_active <= 1'b1;
            end else begin
                stream_write_valid <= 1'b0;
                stream_write_active <= 1'b0;
            end

            // Stream Write Done Logic
            if (stream_write_valid && stream_write_last && m_axi_wready) begin
                stream_write_done <= 1'b1;
                stream_write_valid <= 1'b0;
                axi_write_burst_active <= 1'b0;
                axi_write_burst_complete <= 1'b1;
                write_desc_done <= 1'b1;
            end

            // Error Handling
            if (axi_read_burst_error) begin
                read_desc_error <= 1'b1;
                read_desc_active <= 1'b0;
                read_desc_valid <= 1'b0;
                axi_aw_valid <= 1'b0;
                axi_w_valid <= 1'b0;
                axi_ar_valid <= 1'b0;
            end
            if (axi_write_burst_error) begin
                write_desc_error <= 1'b1;
                write_desc_active <= 1'b0;
                write_desc_valid <= 1'b0;
                axi_aw_valid <= 1'b0;
                axi_w_valid <= 1'b0;
                axi_ar_valid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // AXI Master Control Logic (AW/AR/W)
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axi_aw_valid <= 1'b0;
            axi_ar_valid <= 1'b0;
            axi_w_valid <= 1'b0;
            axi_w_last <= 1'b0;
            axi_remaining_len <= 0;
        end else begin
            // Address Phase (AW)
            if (axi_aw_valid && m_axi_awready) begin
                axi_aw_valid <= 1'b0;
                axi_w_valid <= 1'b1; // Start data phase immediately if W is ready
                axi_remaining_len <= axi_aw_len + 1;
            end

            // Write Data Phase (W)
            if (axi_w_valid && m_axi_wready) begin
                axi_w_valid <= 1'b0;
                if (axi_remaining_len > 1) begin
                    axi_w_valid <= 1'b1;
                    axi_remaining_len <= axi_remaining_len - 1;
                end else begin
                    axi_w_valid <= 1'b0;
                    axi_w_last <= 1'b1;
                    axi_remaining_len <= 0;
                end
            end

            // Address Phase (AR) - Initiated separately for reads
            if (axi_ar_valid && m_axi_arready) begin
                axi_ar_valid <= 1'b0;
                axi_w_valid <= 1'b1; // Start data phase immediately if W is ready
                axi_remaining_len <= axi_ar_len + 1;
            end

            // Write Data Phase (W) for Reads
            if (axi_w_valid && m_axi_wready) begin
                axi_w_valid <= 1'b0;
                if (axi_remaining_len > 1) begin
                    axi_w_valid <= 1'b1;
                    axi_remaining_len <= axi_remaining_len - 1;
                end else begin
                    axi_w_valid <= 1'b0;
                    axi_w_last <= 1'b1;
                    axi_remaining_len <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Output Assignments
    // ------------------------------------------------------------------
    assign s_axis_read_desc_ready = !read_desc_valid || read_desc_done;
    assign s_axis_write_desc_ready = !write_desc_valid || write_desc_done;
    assign s_axis_write_data_tready = (write_enable && write_desc_valid && !write_desc_active && !axi_write_burst_active) ? 1'b1 : (m_axi_wready);
    
    // Note: The above logic for s_axis_write_data_tready is simplified.
    // Ideally, it should be high when the engine is ready to accept data.
    // If a transaction is active, it should be low.
    // If no transaction is active, it should be high.
    
    // Corrected Write Data Ready Logic
    reg write_data_ready;
    always @(posedge clk or posedge rst) begin
        if (rst) write_data_ready <= 1'b0;
        else begin
            if (write_enable && write_desc_valid && !write_desc_active && !axi_write_burst_active) begin
                write_data_ready <= 1'b1;
            end else if (m_axi_wready) begin
                write_data_ready <= 1'b1;
            end else begin
                write_data_ready <= 1'b0;
            end
        end
    end
    assign s_axis_write_data_tready = write_data_ready;

    // AXI Master Output Assignments
    assign m_axi_awid = axi_aw_valid ? read_desc_id : 8'd0;
    assign m_axi_awaddr = axi_aw_valid ? axi_aw_addr : 16'd