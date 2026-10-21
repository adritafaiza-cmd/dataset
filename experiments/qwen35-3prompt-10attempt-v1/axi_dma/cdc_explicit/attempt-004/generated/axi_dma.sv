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
    // Internal Parameters and Types
    // -----------------------------------------------------------------------
    localparam int unsigned AXIS_KEEP_WIDTH_LOG = $clog2(AXIS_KEEP_WIDTH + 1);
    localparam int unsigned AXIS_ID_WIDTH_LOG   = $clog2(AXIS_ID_WIDTH + 1);
    localparam int unsigned AXIS_DEST_WIDTH_LOG = $clog2(AXIS_DEST_WIDTH + 1);
    localparam int unsigned AXIS_USER_WIDTH_LOG = $clog2(AXIS_USER_WIDTH + 1);
    localparam int unsigned TAG_WIDTH_LOG       = $clog2(TAG_WIDTH + 1);
    localparam int unsigned LEN_WIDTH_LOG       = $clog2(LEN_WIDTH + 1);

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
    localparam [1:0] AXI_BURST_FIXED = 2'd0;
    localparam [1:0] AXI_BURST_INCR  = 2'd1;

    // -----------------------------------------------------------------------
    // Internal Registers (CDC Safe: Single Clock Domain)
    // -----------------------------------------------------------------------
    reg [TAG_WIDTH-1:0]       i_read_tag;
    reg [LEN_WIDTH-1:0]       i_read_len;
    reg [AXI_ADDR_WIDTH-1:0]  i_read_addr;
    reg [AXIS_ID_WIDTH-1:0]   i_read_id;
    reg [AXIS_DEST_WIDTH-1:0] i_read_dest;
    reg [AXIS_USER_WIDTH-1:0] i_read_user;
    reg                       i_read_valid;
    reg                       i_read_done;
    reg                       i_read_error;
    reg                       i_read_streaming;
    reg [AXI_DATA_WIDTH-1:0]  i_read_data;
    reg [AXIS_KEEP_WIDTH-1:0] i_read_keep;
    reg                       i_read_last;
    reg                       i_read_streaming_valid;

    reg [TAG_WIDTH-1:0]       i_write_tag;
    reg [LEN_WIDTH-1:0]       i_write_len;
    reg [AXI_ADDR_WIDTH-1:0]  i_write_addr;
    reg                       i_write_valid;
    reg                       i_write_done;
    reg                       i_write_error;
    reg                       i_write_streaming;
    reg [AXI_DATA_WIDTH-1:0]  i_write_data;
    reg [AXIS_KEEP_WIDTH-1:0] i_write_keep;
    reg                       i_write_last;
    reg                       i_write_streaming_valid;

    // AXI Master State
    reg [2:0]                 i_axi_state; // 0: Idle, 1: AW, 2: W, 3: B, 4: AR, 5: R
    reg [AXI_ADDR_WIDTH-1:0]  i_axi_addr;
    reg [7:0]                 i_axi_len;
    reg [2:0]                 i_axi_size;
    reg [1:0]                 i_axi_burst;
    reg [AXI_DATA_WIDTH-1:0]  i_axi_wdata;
    reg [AXI_STRB_WIDTH-1:0]  i_axi_wstrb;
    reg                       i_axi_wlast;
    reg                       i_axi_awvalid;
    reg                       i_axi_wvalid;
    reg                       i_axi_arvalid;
    reg                       i_axi_awready_ack;
    reg                       i_axi_wready_ack;
    reg                       i_axi_bready_ack;
    reg                       i_axi_arready_ack;
    reg                       i_axi_bvalid_ack;
    reg                       i_axi_rvalid_ack;
    reg [AXI_ID_WIDTH-1:0]    i_axi_bid;
    reg [AXI_ID_WIDTH-1:0]    i_axi_rid;
    reg [1:0]                 i_axi_bresp;
    reg                       i_axi_rlast;
    reg                       i_axi_rvalid;
    reg                       i_axi_aw_done;
    reg                       i_axi_w_done;
    reg                       i_axi_b_done;
    reg                       i_axi_ar_done;
    reg                       i_axi_r_done;

    // -----------------------------------------------------------------------
    // AXI Master Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_axi_state <= 3'd0;
            i_axi_addr  <= 0;
            i_axi_len   <= 0;
            i_axi_size  <= AXI_SIZE_1;
            i_axi_burst <= AXI_BURST_FIXED;
            i_axi_wdata <= 0;
            i_axi_wstrb <= 0;
            i_axi_wlast <= 0;
            i_axi_awvalid <= 0;
            i_axi_wvalid <= 0;
            i_axi_arvalid <= 0;
            i_axi_awready_ack <= 0;
            i_axi_wready_ack <= 0;
            i_axi_bready_ack <= 0;
            i_axi_arready_ack <= 0;
            i_axi_bvalid_ack <= 0;
            i_axi_rvalid_ack <= 0;
            i_axi_bid <= 0;
            i_axi_rid <= 0;
            i_axi_bresp <= 0;
            i_axi_rlast <= 0;
            i_axi_rvalid <= 0;
            i_axi_aw_done <= 0;
            i_axi_w_done <= 0;
            i_axi_b_done <= 0;
            i_axi_ar_done <= 0;
            i_axi_r_done <= 0;
        end else begin
            // State Machine
            case (i_axi_state)
                3'd0: begin // Idle
                    if (read_enable && i_read_valid && !i_read_done) begin
                        i_axi_addr <= i_read_addr;
                        i_axi_len  <= i_read_len - 1; // Decrement before sending
                        i_axi_size <= AXI_SIZE_1;
                        i_axi_burst <= AXI_BURST_INCR;
                        i_axi_awvalid <= 1;
                        i_axi_awready_ack <= 0;
                        i_axi_state <= 3'd1;
                    end else if (write_enable && i_write_valid && !i_write_done) begin
                        i_axi_addr <= i_write_addr;
                        i_axi_len  <= i_write_len - 1;
                        i_axi_size <= AXI_SIZE_1;
                        i_axi_burst <= AXI_BURST_INCR;
                        i_axi_wlast <= 0;
                        i_axi_wvalid <= 1;
                        i_axi_awvalid <= 1;
                        i_axi_awready_ack <= 0;
                        i_axi_state <= 3'd2;
                    end
                end

                3'd1: begin // AW Handshake
                    if (i_axi_awready) begin
                        i_axi_awvalid <= 0;
                        i_axi_awready_ack <= 1;
                        i_axi_aw_done <= 1;
                        i_axi_state <= 3'd2;
                    end
                end

                3'd2: begin // W Handshake
                    if (i_axi_wready) begin
                        i_axi_wvalid <= 0;
                        i_axi_wready_ack <= 1;
                        i_axi_w_done <= 1;
                        i_axi_state <= 3'd3;
                    end
                end

                3'd3: begin // B Handshake
                    if (i_axi_bvalid) begin
                        i_axi_bready <= 1;
                        i_axi_bvalid_ack <= 1;
                        i_axi_b_done <= 1;
                        i_axi_state <= 3'd4;
                    end
                end

                3'd4: begin // AR Handshake
                    if (i_axi_arready) begin
                        i_axi_arvalid <= 1;
                        i_axi_arready_ack <= 1;
                        i_axi_ar_done <= 1;
                        i_axi_state <= 3'd5;
                    end
                end

                3'd5: begin // R Handshake
                    if (i_axi_rvalid) begin
                        i_axi_rready <= 1;
                        i_axi_rvalid_ack <= 1;
                        i_axi_r_done <= 1;
                        i_axi_state <= 3'd0;
                    end
                end
            endcase

            // Update internal data registers on valid handshakes
            if (i_axi_awready && i_axi_awvalid) begin
                i_axi_bid <= m_axi_awid;
            end
            if (i_axi_wready && i_axi_wvalid) begin
                i_axi_wdata <= m_axi_wdata;
                i_axi_wstrb <= m_axi_wstrb;
                if (i_axi_wlast) i_axi_wlast <= 1;
            end
            if (i_axi_bvalid && i_axi_bready) begin
                i_axi_bresp <= m_axi_bresp;
                i_axi_bid   <= m_axi_bid;
            end
            if (i_axi_arready && i_axi_arvalid) begin
                i_axi_rid <= m_axi_arid;
            end
            if (i_axi_rvalid && i_axi_rready) begin
                i_axi_rdata <= m_axi_rdata;
                i_axi_rresp <= m_axi_rresp;
                i_axi_rlast <= m_axi_rlast;
                i_axi_rid   <= m_axi_rid;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Read Path Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_read_tag       <= 0;
            i_read_len       <= 0;
            i_read_addr      <= 0;
            i_read_id        <= 0;
            i_read_dest      <= 0;
            i_read_user      <= 0;
            i_read_valid     <= 0;
            i_read_done      <= 0;
            i_read_error     <= 0;
            i_read_streaming <= 0;
            i_read_data      <= 0;
            i_read_keep      <= 0;
            i_read_last      <= 0;
            i_read_streaming_valid <= 0;
        end else begin
            // Descriptor Input
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                i_read_tag       <= s_axis_read_desc_tag;
                i_read_len       <= s_axis_read_desc_len;
                i_read_addr      <= s_axis_read_desc_addr;
                i_read_id        <= s_axis_read_desc_id;
                i_read_dest      <= s_axis_read_desc_dest;
                i_read_user      <= s_axis_read_desc_user;
                i_read_valid     <= 1;
                s_axis_read_desc_ready <= 0;
            end else begin
                s_axis_read_desc_ready <= 1;
            end

            // Status Output
            m_axis_read_desc_status_tag <= i_read_tag;
            m_axis_read_desc_status_error <= i_read_error ? 4'd1 : 4'd0;
            m_axis_read_desc_status_valid <= i_read_done;

            // Stream Output
            m_axis_read_data_tdata <= i_read_data;
            m_axis_read_data_tkeep <= i_read_keep;
            m_axis_read_data_tvalid <= i_read_streaming_valid;
            m_axis_read_data_tlast  <= i_read_last;
            m_axis_read_data_tid    <= i_read_id;
            m_axis_read_data_tdest  <= i_read_dest;
            m_axis_read_data_tuser  <= i_read_user;

            // Stream Ready Logic
            if (m_axis_read_data_tready && i_read_streaming_valid) begin
                i_read_streaming_valid <= 0;
            end

            // State Machine for Read
            if (i_read_valid && !i_read_done) begin
                if (i_axi_state == 3'd0) begin
                    // Start Read
                    i_axi_addr <= i_read_addr;
                    i_axi_len  <= i_read_len - 1;
                    i_axi_size <= AXI_SIZE_1;
                    i_axi_burst <= AXI_BURST_INCR;
                    i_axi_awvalid <= 1;
                    i_axi_awready_ack <= 0;
                    i_axi_state <= 3'd1;
                    i_read_streaming <= 1;
                    i_read_streaming_valid <= 0;
                    i_read_last <= 0;
                    i_read_error <= 0;
                end
            end

            // Handle AW Response
            if (i_axi_state == 3'd1 && i_axi_awready) begin
                i_axi_awvalid <= 0;
                i_axi_awready_ack <= 1;
                i_axi_aw_done <= 1;
                i_axi_state <= 3'd2;
            end

            // Handle W Response
            if (i_axi_state == 3'd2 && i_axi_wready) begin
                i_axi_wvalid <= 0;
                i_axi_wready_ack <= 1;
                i_axi_w_done <= 1;
                i_axi_state <= 3'd3;
            end

            // Handle B Response
            if (i_axi_state == 3'd3 && i_axi_bvalid) begin
                i_axi_bready <= 1;
                i_axi_bvalid_ack <= 1;
                i_axi_b_done <= 1;
                i_axi_state <= 3'd4;
            end

            // Handle AR Response
            if (i_axi_state == 3'd4 && i_axi_arready) begin
                i_axi_arvalid <= 1;
                i_axi_arready_ack <= 1;
                i_axi_ar_done <= 1;
                i_axi_state <= 3'd5;
            end

            // Handle R Response
            if (i_axi_state == 3'd5 && i_axi_rvalid) begin
                i_axi_rready <= 1;
                i_axi_rvalid_ack <= 1;
                i_axi_r_done <= 1;
                i_axi_state <= 3'd0;

                // Update Stream Data
                if (i_axi_rlast) begin
                    i_read_last <= 1;
                    i_read_streaming_valid <= 0;
                end else begin
                    i_read_last <= 0;
                    i_read_streaming_valid <= 1;
                end
                i_read_data <= i_axi_rdata;
                i_read_keep <= m_axis_read_data_tkeep; // Placeholder, needs calculation
            end
        end
    end

    // -----------------------------------------------------------------------
    // Write Path Logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_write_tag       <= 0;
            i_write_len       <= 0;
            i_write_addr      <= 0;
            i_write_valid     <= 0;
            i_write_done      <= 0;
            i_write_error     <= 0;
            i_write_streaming <= 0;
            i_write_data      <= 0;
            i_write_keep      <= 0;
            i_write_last      <= 0;
            i_write_streaming_valid <= 0;
        end else begin
            // Descriptor Input
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                i_write_tag       <= s_axis_write_desc_tag;
                i_write_len       <= s_axis_write_desc_len;
                i_write_addr      <= s_axis_write_desc_addr;
                i_write_valid     <= 1;
                s_axis_write_desc_ready <= 0;
            end else begin
                s_axis_write_desc_ready <= 1;
            end

            // Status Output
            m_axis_write_desc_status_len <= i_write_len;
            m_axis_write_desc_status_tag <= i_write_tag;
            m_axis_write_desc_status_id  <= 0; // Not used in write desc status per spec
            m_axis_write_desc_status_dest <= 0;
            m_axis_write_desc_status_user <= 0;
            m_axis_write_desc_status_error <= i_write_error ? 4'd1 : 4'd0;
            m_axis_write_desc_status_valid <= i_write_done;

            // Stream Input Ready
            s_axis_write_data_tready <= i_write_streaming_valid;

            // State Machine for Write
            if (i_write_valid && !i_write_done) begin
                if (i_axi_state == 3'd0) begin
                    // Start Write
                    i_axi_addr <= i_write_addr;
                    i_axi_len  <= i_write_len - 1;
                    i_axi_size <= AXI_SIZE_1;
                    i_axi_burst <= AXI_BURST_INCR;
                    i_axi_wlast <= 0;
                    i_axi_wvalid <= 1;
                    i_axi_awvalid <= 1;
                    i_axi_awready_ack <= 0;
                    i_axi_state <= 3'd2;
                    i_write_streaming <= 1;
                    i_write_streaming_valid <= 0;
                    i_write_last <= 0;
                    i_write_error <= 0;
                end
            end

            // Handle AW Response
            if (i_axi_state == 3'd2 && i_axi_awready) begin
                i_axi_awvalid <= 0;
                i_axi_awready_ack <= 1;
                i_axi_aw_done <= 1;
                i_axi_state <= 3'd3;
            end

            // Handle W Response
            if (i_axi_state == 3'd3 && i_axi_wready) begin
                i_axi_wvalid <= 0;
                i_axi_wready_ack <= 1;
                i_axi_w_done <= 1;
                i_axi_state <= 3'd4;
            end

            // Handle B Response
            if (i_axi_state == 3'd4 && i_axi_bvalid) begin
                i_axi_bready <= 1;
                i_axi_bvalid_ack <= 1;
                i_axi_b_done <= 1;
                i_axi_state <= 3'd0;
                i_write_done <= 1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Stream Data Logic (Read Path)
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_read_data      <= 0;
            i_read_keep      <= 0;
            i_read_last      <= 0;
            i_read_streaming_valid <= 0;
        end else begin
            // Calculate Keep Mask
            if (AXIS_KEEP_ENABLE) begin
                i_read_keep <= {AXIS_KEEP_WIDTH{1'b1}}; // Default all valid
                // If we had partial keep logic, it would go here
            end else begin
                i_read_keep <= 0;
            end

            // Stream Valid Logic
            if (i_axi_rvalid && i_axi_rready && i_axi_rlast) begin
                i_read_data      <= m_axi_rdata;
                i_read_streaming_valid <= 0;
                i_read_last      <= 1;
            end else if (i_axi_rvalid && i_axi_rready && !i_axi_rlast) begin
                i_read_data      <= m_axi_rdata;
                i_read_streaming_valid <= 1;
                i_read_last      <= 0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Stream Data Logic (Write Path)
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_write_data      <= 0;
            i_write_keep      <= 0;
            i_write_last      <= 0;
            i_write_streaming_valid <= 0;
        end else begin
            // Stream Valid Logic
            if (i_axi_wvalid && i_axi_wready) begin
                i_write_data      <= m_axi_wdata;
                i_write_streaming_valid <= 1;
                if (i_axi_wlast) begin
                    i_write_last <= 1;
                end else begin
                    i_write_last <= 0;
                end
            end else if (i_axi_wready && !i_axi_wvalid) begin
                // If AW is done but W is not, we might be in a weird state, 
                // but typically we wait for W valid.
                // If W is invalid and ready is high, we just don't update data.
            end
        end
    end

    // -----------------------------------------------------------------------
    // Output Logic (Stream Write Data)
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_write_data_tdata <= 0;
            m_axis_write_data_tkeep <= 0;
            m_axis_write_data_tvalid <= 0;
            m_axis_write_data_tlast <= 0;
            m_axis_write_data_tid   <= 0;
            m_axis_write_data_tdest <= 0;
            m_axis_write_data_tuser <= 0;
        end else begin
            m_axis_write_data_tdata <= i_write_data;
            m_axis_write_data_tkeep <= i_write_keep;
            m_axis_write_data_tvalid <= i_write_streaming_valid;
            m_axis_write_data_tlast  <= i_write_last;
            m_axis_write_data_tid    <= 0; // Not provided in write desc
            m_axis_write_data_tdest  <= 0;
            m_axis_write_data_tuser  <= 0;
        end
    end

    // -----------------------------------------------------------------------
    // AXI Master Output Logic
    // -----------------------------------------------------------------------
    assign m_axi_awid      = i_axi_bid;
    assign m_axi_awaddr    = i_axi_addr;
    assign m_axi_awlen     = i_axi_len;
    assign m_axi_awsize    = i_axi_size;
    assign m_axi_awburst   = i_axi_burst;
    assign m_axi_awlock    = 1'b0;
    assign m_axi_awcache   = 4'd0;
    assign m_axi_awprot    = 3'd0;
    assign m_axi_awvalid   = i_axi_awvalid;
    assign m_axi_wdata     = i_axi_wdata;
    assign m_axi_wstrb     = i_axi_wstrb;
    assign m_axi_wlast     = i_axi_wlast;
    assign m_axi_wvalid    = i_axi_wvalid;
    assign m_axi_bready    = i_axi_bready;
    assign m_axi_arid      = i_axi_rid;
    assign m_axi_araddr    = i_axi_addr;
    assign m_axi_arlen     = i_axi_len;
    assign m_axi_arsize    = i_axi_size;
    assign m_axi_arburst   = i_axi_burst;
    assign m_axi_arlock    = 1'b0;
    assign m_axi_arcache   = 4'd0;
    assign m_axi_arprot    = 3'd0;
    assign m_axi_arvalid   = i_axi_arvalid;
    assign m_axi_rready    = i_axi_rready;

    // -----------------------------------------------------------------------
    // Internal Wire Assignments for Keep Mask Calculation (Read Path)
    // -----------------------------------------------------------------------
    // Since we don't have a specific keep mask input for reads, we assume full width
    // unless AXIS_KEEP_ENABLE is 0.
    wire [AXIS_KEEP_WIDTH-1:0] calc_read_keep;
    assign calc_read_keep = AXIS_KEEP_ENABLE ? {AXIS_KEEP_WIDTH{1'b1}} : 0;
    assign m_axis_read_data_tkeep = calc_read_keep;

endmodule
```<|im_end|>
