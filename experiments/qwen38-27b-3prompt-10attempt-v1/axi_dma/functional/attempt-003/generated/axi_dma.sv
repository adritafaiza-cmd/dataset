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

    // Local parameters
    localparam AXI_DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam AXI_MAX_BURST_LEN_LOG2 = (AXI_MAX_BURST_LEN == 1) ? 0 :
                                       (AXI_MAX_BURST_LEN == 2) ? 1 :
                                       (AXI_MAX_BURST_LEN == 4) ? 2 :
                                       (AXI_MAX_BURST_LEN == 8) ? 3 :
                                       (AXI_MAX_BURST_LEN == 16) ? 4 :
                                       (AXI_MAX_BURST_LEN == 32) ? 5 :
                                       (AXI_MAX_BURST_LEN == 64) ? 6 :
                                       (AXI_MAX_BURST_LEN == 128) ? 7 : 8;
    localparam AXI_MAX_BURST_LEN_MINUS_1 = AXI_MAX_BURST_LEN - 1;
    
    // Read Channel State
    localparam R_IDLE = 2'd0;
    localparam R_ADDR = 2'd1;
    localparam R_DATA = 2'd2;
    localparam R_DONE = 2'd3;
    
    // Write Channel State
    localparam W_IDLE = 2'd0;
    localparam W_ADDR = 2'd1;
    localparam W_DATA = 2'd2;
    localparam W_RESP = 2'd3;
    localparam W_DONE = 2'd4;

    // Read State Registers
    reg [1:0] r_state;
    reg [AXI_ADDR_WIDTH-1:0] r_addr;
    reg [LEN_WIDTH-1:0] r_len;
    reg [LEN_WIDTH-1:0] r_remaining;
    reg [TAG_WIDTH-1:0] r_tag;
    reg [AXIS_ID_WIDTH-1:0] r_id;
    reg [AXIS_DEST_WIDTH-1:0] r_dest;
    reg [AXIS_USER_WIDTH-1:0] r_user;
    reg [7:0] r_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] r_cur_addr;
    reg [LEN_WIDTH-1:0] r_burst_remaining;
    reg [3:0] r_error;
    reg r_status_valid;
    reg [TAG_WIDTH-1:0] r_status_tag;
    reg [3:0] r_status_error;

    // Write State Registers
    reg [1:0] w_state;
    reg [AXI_ADDR_WIDTH-1:0] w_addr;
    reg [LEN_WIDTH-1:0] w_len;
    reg [LEN_WIDTH-1:0] w_remaining;
    reg [TAG_WIDTH-1:0] w_tag;
    reg [7:0] w_burst_len;
    reg [AXI_ADDR_WIDTH-1:0] w_cur_addr;
    reg [LEN_WIDTH-1:0] w_burst_remaining;
    reg [3:0] w_error;
    reg w_status_valid;
    reg [LEN_WIDTH-1:0] w_status_len;
    reg [TAG_WIDTH-1:0] w_status_tag;
    reg [AXIS_ID_WIDTH-1:0] w_status_id;
    reg [AXIS_DEST_WIDTH-1:0] w_status_dest;
    reg [AXIS_USER_WIDTH-1:0] w_status_user;
    reg [3:0] w_status_error;

    // AXI Write Address Channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;

    // AXI Write Data Channel
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;

    // AXI Write Response Channel
    reg bready_reg;

    // AXI Read Address Channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;

    // AXI Read Data Channel
    reg rready_reg;

    // AXI Stream Read Data Output
    reg [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata_reg;
    reg [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep_reg;
    reg m_axis_read_data_tvalid_reg;
    reg m_axis_read_data_tlast_reg;
    reg [AXIS_ID_WIDTH-1:0] m_axis_read_data_tid_reg;
    reg [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest_reg;
    reg [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser_reg;

    // AXI Stream Write Data Input
    reg s_axis_write_data_tready_reg;

    // Descriptor Status Outputs
    reg [TAG_WIDTH-1:0] m_axis_read_desc_status_tag_reg;
    reg [3:0] m_axis_read_desc_status_error_reg;
    reg m_axis_read_desc_status_valid_reg;
    
    reg [LEN_WIDTH-1:0] m_axis_write_desc_status_len_reg;
    reg [TAG_WIDTH-1:0] m_axis_write_desc_status_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] m_axis_write_desc_status_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user_reg;
    reg [3:0] m_axis_write_desc_status_error_reg;
    reg m_axis_write_desc_status_valid_reg;

    // Descriptor Ready Outputs
    reg s_axis_read_desc_ready_reg;
    reg s_axis_write_desc_ready_reg;

    // Helper signals
    wire r_desc_accept = s_axis_read_desc_valid && s_axis_read_desc_ready_reg && read_enable;
    wire w_desc_accept = s_axis_write_desc_valid && s_axis_write_desc_ready_reg && write_enable;
    
    wire r_data_accept = m_axis_read_data_tvalid_reg && m_axis_read_data_tready;
    wire w_data_accept = s_axis_write_data_tvalid && s_axis_write_data_tready_reg;

    // Calculate AXI size
    wire [2:0] axi_size = $clog2(AXI_DATA_BYTES);

    // Read Channel Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state <= R_IDLE;
            r_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_len <= {LEN_WIDTH{1'b0}};
            r_remaining <= {LEN_WIDTH{1'b0}};
            r_tag <= {TAG_WIDTH{1'b0}};
            r_id <= {AXIS_ID_WIDTH{1'b0}};
            r_dest <= {AXIS_DEST_WIDTH{1'b0}};
            r_user <= {AXIS_USER_WIDTH{1'b0}};
            r_burst_len <= 8'd0;
            r_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            r_burst_remaining <= {LEN_WIDTH{1'b0}};
            r_error <= 4'd0;
            r_status_valid <= 1'b0;
            r_status_tag <= {TAG_WIDTH{1'b0}};
            r_status_error <= 4'd0;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'd0;
            arburst_reg <= 2'b01;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            m_axis_read_data_tdata_reg <= {AXIS_DATA_WIDTH{1'b0}};
            m_axis_read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b0}};
            m_axis_read_data_tvalid_reg <= 1'b0;
            m_axis_read_data_tlast_reg <= 1'b0;
            m_axis_read_data_tid_reg <= {AXIS_ID_WIDTH{1'b0}};
            m_axis_read_data_tdest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            m_axis_read_data_tuser_reg <= {AXIS_USER_WIDTH{1'b0}};
            s_axis_read_desc_ready_reg <= 1'b0;
            m_axis_read_desc_status_tag_reg <= {TAG_WIDTH{1'b0}};
            m_axis_read_desc_status_error_reg <= 4'd0;
            m_axis_read_desc_status_valid_reg <= 1'b0;
        end else begin
            // Default assignments
            s_axis_read_desc_ready_reg <= (r_state == R_IDLE) && read_enable;
            m_axis_read_desc_status_valid_reg <= 1'b0;
            m_axis_read_desc_status_tag_reg <= r_status_tag;
            m_axis_read_desc_status_error_reg <= r_status_error;
            
            // AXI Read Address Channel
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= r_cur_addr;
            arlen_reg <= r_burst_len;
            arsize_reg <= axi_size;
            arburst_reg <= 2'b01; // INCR
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;
            
            // AXI Read Data Channel
            rready_reg <= 1'b0;
            
            // AXI Stream Read Data Output
            m_axis_read_data_tvalid_reg <= 1'b0;
            m_axis_read_data_tlast_reg <= 1'b0;
            m_axis_read_data_tid_reg <= r_id;
            m_axis_read_data_tdest_reg <= r_dest;
            m_axis_read_data_tuser_reg <= r_user;
            m_axis_read_data_tkeep_reg <= {AXIS_KEEP_WIDTH{1'b1}};
            m_axis_read_data_tdata_reg <= {AXIS_DATA_WIDTH{1'b0}};

            case (r_state)
                R_IDLE: begin
                    if (r_desc_accept) begin
                        r_addr <= s_axis_read_desc_addr;
                        r_len <= s_axis_read_desc_len;
                        r_remaining <= s_axis_read_desc_len;
                        r_tag <= s_axis_read_desc_tag;
                        r_id <= s_axis_read_desc_id;
                        r_dest <= s_axis_read_desc_dest;
                        r_user <= s_axis_read_desc_user;
                        r_cur_addr <= s_axis_read_desc_addr;
                        r_error <= 4'd0;
                        r_state <= R_ADDR;
                    end
                end
                
                R_ADDR: begin
                    // Calculate burst length
                    if (r_remaining > AXI_MAX_BURST_LEN) begin
                        r_burst_len <= AXI_MAX_BURST_LEN_MINUS_1;
                        r_burst_remaining <= AXI_MAX_BURST_LEN;
                    end else begin
                        r_burst_len <= r_remaining[7:0];
                        r_burst_remaining <= r_remaining;
                    end
                    
                    // Issue AXI Read Address
                    arvalid_reg <= 1'b1;
                    araddr_reg <= r_cur_addr;
                    arlen_reg <= r_burst_len;
                    
                    if (m_axi_arready) begin
                        r_state <= R_DATA;
                        rready_reg <= 1'b1;
                    end
                end
                
                R_DATA: begin
                    // Handle AXI Read Address handshake
                    if (arvalid_reg && m_axi_arready) begin
                        arvalid_reg <= 1'b0;
                    end
                    
                    // Handle AXI Read Data
                    if (m_axi_rvalid && rready_reg) begin
                        // Update stream output
                        m_axis_read_data_tdata_reg <= m_axi_rdata;
                        m_axis_read_data_tvalid_reg <= 1'b1;
                        
                        // Check for last beat of burst
                        if (m_axi_rlast) begin
                            r_burst_remaining <= r_burst_remaining - 1;
                            r_cur_addr <= r_cur_addr + AXI_DATA_BYTES;
                            
                            // Check if descriptor is complete
                            if (r_remaining <= r_burst_remaining) begin
                                // Descriptor complete
                                r_remaining <= {LEN_WIDTH{1'b0}};
                                r_state <= R_DONE;
                                m_axis_read_data_tlast_reg <= 1'b1;
                                
                                // Prepare status
                                r_status_tag <= r_tag;
                                r_status_error <= r_error;
                                r_status_valid <= 1'b1;
                            end else begin
                                // More bursts needed
                                r_remaining <= r_remaining - r_burst_remaining;
                                r_state <= R_ADDR;
                                m_axis_read_data_tlast_reg <= 1'b0;
                            end
                        end else begin
                            r_burst_remaining <= r_burst_remaining - 1;
                            r_cur_addr <= r_cur_addr + AXI_DATA_BYTES;
                            m_axis_read_data_tlast_reg <= 1'b0;
                        end
                        
                        // Check for error
                        if (m_axi_rresp != 2'b00) begin
                            r_error <= 4'b0001;
                        end
                    end
                end
                
                R_DONE: begin
                    // Wait for stream data to be accepted
                    if (m_axis_read_data_tvalid_reg && m_axis_read_data_tready) begin
                        m_axis_read_data_tvalid_reg <= 1'b0;
                        r_state <= R_IDLE;
                    end
                end
                
                default: begin
                    r_state <= R_IDLE;
                end
            end
            
            // Handle status valid pulse
            if (r_status_valid) begin
                m_axis_read_desc_status_valid_reg <= 1'b1;
                m_axis_read_desc_status_tag_reg <= r_status_tag;
                m_axis_read_desc_status_error_reg <= r_status_error;
                r_status_valid <= 1'b0;
            end
        end
    end

    // Write Channel Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_state <= W_IDLE;
            w_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_len <= {LEN_WIDTH{1'b0}};
            w_remaining <= {LEN_WIDTH{1'b0}};
            w_tag <= {TAG_WIDTH{1'b0}};
            w_burst_len <= 8'd0;
            w_cur_addr <= {AXI_ADDR_WIDTH{1'b0}};
            w_burst_remaining <= {LEN_WIDTH{1'b0}};
            w_error <= 4'd0;
            w_status_valid <= 1'b0;
            w_status_len <= {LEN_WIDTH{1'b0}};
            w_status_tag <= {TAG_WIDTH{1'b0}};
            w_status_id <= {AXIS_ID_WIDTH{1'b0}};
            w_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            w_status_user <= {AXIS_USER_WIDTH{1'b0}};
            w_status_error <= 4'd0;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'd0;
            awburst_reg <= 2'b01;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg <= 3'b000;
            awvalid_reg <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b0}};
            wlast_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            s_axis_write_data_tready_reg <= 1'b0;
            m_axis_write_desc_status_len_reg <= {LEN_WIDTH{1'b0}};
            m_axis_write_desc_status_tag_reg <= {TAG_WIDTH{1'b0}};
            m_axis_write_desc_status_id_reg <= {AXIS_ID_WIDTH{1'b0}};
            m_axis_write_desc_status_dest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            m_axis_write_desc_status_user_reg <= {AXIS_USER_WIDTH{1'b0}};
            m_axis_write_desc_status_error_reg <= 4'd0;
            m_axis_write_desc_status_valid_reg <= 1'b0;
            s_axis_write_desc_ready_reg <= 1'b0;
        end else begin
            // Default assignments
            s_axis_write_desc_ready_reg <= (w_state == W_IDLE) && write_enable;
            m_axis_write_desc_status_valid_reg <= 1'b0;
            m_axis_write_desc_status_len_reg <= w_status_len;
            m_axis_write_desc_status_tag_reg <= w_status_tag;
            m_axis_write_desc_status_id_reg <= w_status_id;
            m_axis_write_desc_status_dest_reg <= w_status_dest;
            m_axis_write_desc_status_user_reg <= w_status_user;
            m_axis_write_desc_status_error_reg <= w_status_error;
            
            // AXI Write Address Channel
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= w_cur_addr;
            awlen_reg <= w_burst_len;
            awsize_reg <= axi_size;
            awburst_reg <= 2'b01; // INCR
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg <= 3'b000;
            awvalid_reg <= 1'b0;
            
            // AXI Write Data Channel
            wvalid_reg <= 1'b0;
            wlast_reg <= 1'b0;
            wdata_reg <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg <= {AXI_STRB_WIDTH{1'b1}};
            
            // AXI Write Response Channel
            bready_reg <= 1'b0;
            
            // AXI Stream Write Data Input
            s_axis_write_data_tready_reg <= 1'b0;

            case (w_state)
                W_IDLE: begin
                    if (w_desc_accept) begin
                        w_addr <= s_axis_write_desc_addr;
                        w_len <= s_axis_write_desc_len;
                        w_remaining <= s_axis_write_desc_len;
                        w_tag <= s_axis_write_desc_tag;
                        w_cur_addr <= s_axis_write_desc_addr;
                        w_error <= 4'd0;
                        w_state <= W_ADDR;
                    end
                end
                
                W_ADDR: begin
                    // Calculate burst length
                    if (w_remaining > AXI_MAX_BURST_LEN) begin
                        w_burst_len <= AXI_MAX_BURST_LEN_MINUS_1;
                        w_burst_remaining <= AXI_MAX_BURST_LEN;
                    end else begin
                        w_burst_len <= w_remaining[7:0];
                        w_burst_remaining <= w_remaining;
                    end
                    
                    // Issue AXI Write Address
                    awvalid_reg <= 1'b1;
                    awaddr_reg <= w_cur_addr;
                    awlen_reg <= w_burst_len;
                    
                    if (m_axi_awready) begin
                        w_state <= W_DATA;
                        s_axis_write_data_tready_reg <= 1'b1;
                    end
                end
                
                W_DATA: begin
                    // Handle AXI Write Address handshake
                    if (awvalid_reg && m_axi_awready) begin
                        awvalid_reg <= 1'b0;
                    end
                    
                    // Handle AXI Stream Write Data Input
                    if (s_axis_write_data_tvalid && s_axis_write_data_tready_reg) begin
                        // Prepare AXI Write Data
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= {AXI_STRB_WIDTH{1'b1}};
                        wvalid_reg <= 1'b1;
                        
                        // Check for last beat of burst
                        if (s_axis_write_data_tlast) begin
                            w_burst_remaining <= w_burst_remaining - 1;
                            w_cur_addr <= w_cur_addr + AXI_DATA_BYTES;
                            wlast_reg <= 1'b1;
                            
                            // Check if descriptor is complete
                            if (w_remaining <= w_burst_remaining) begin
                                // Descriptor complete
                                w_remaining <= {LEN_WIDTH{1'b0}};
                                w_state <= W_RESP;
                                
                                // Prepare status
                                w_status_len <= w_len;
                                w_status_tag <= w_tag;
                                w_status_id <= s_axis_write_data_tid;
                                w_status_dest <= s_axis_write_data_tdest;
                                w_status_user <= s_axis_write_data_tuser;
                                w_status_error <= w_error;
                                w_status_valid <= 1'b1;
                            end else begin
                                // More bursts needed
                                w_remaining <= w_remaining - w_burst_remaining;
                                w_state <= W_ADDR;
                            end
                        end else begin
                            w_burst_remaining <= w_burst_remaining - 1;
                            w_cur_addr <= w_cur_addr + AXI_DATA_BYTES;
                        end
                    end
                end
                
                W_RESP: begin
                    // Wait for AXI Write Response
                    bready_reg <= 1'b1;
                    
                    if (m_axi_bvalid && bready_reg) begin
                        bready_reg <= 1'b0;
                        
                        // Check for error
                        if (m_axi_bresp != 2'b00) begin
                            w_status_error <= 4'b0001;
                        end
                        
                        w_state <= W_IDLE;
                    end
                end
                
                default: begin
                    w_state <= W_IDLE;
                end
            end
            
            // Handle status valid pulse
            if (w_status_valid) begin
                m_axis_write_desc_status_valid_reg <= 1'b1;
                m_axis_write_desc_status_len_reg <= w_status_len;
                m_axis_write_desc_status_tag_reg <= w_status_tag;
                m_axis_write_desc_status_id_reg <= w_status_id;
                m_axis_write_desc_status_dest_reg <= w_status_dest;
                m_axis_write_desc_status_user_reg <= w_status_user;
                m_axis_write_desc_status_error_reg <= w_status_error;
                w_status_valid <= 1'b0;
            end
        end
    end

    // Assign outputs
    assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;
    assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_reg;
    assign m_axis_read_desc_status_error = m_axis_read_desc_status_error_reg;
    assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_reg;
    
    assign m_axis_read_data_tdata = m_axis_read_data_tdata_reg;
    assign m_axis_read_data_tkeep = m_axis_read_data_tkeep_reg;
    assign m_axis_read_data_tvalid = m_axis_read_data_tvalid_reg;
    assign m_axis_read_data_tlast = m_axis_read_data_tlast_reg;
    assign m_axis_read_data_tid = m_axis_read_data_tid_reg;
    assign m_axis_read_data_tdest = m_axis_read_data_tdest_reg;
    assign m_axis_read_data_tuser = m_axis_read_data_tuser_reg;
    
    assign s_axis_write_desc_ready = s_axis_write_desc_ready_reg;
    assign m_axis_write_desc_status_len = m_axis_write_desc_status_len_reg;
    assign m_axis_write_desc_status_tag = m_axis_write_desc_status_tag_reg;
    assign m_axis_write_desc_status_id = m_axis_write_desc_status_id_reg;
    assign m_axis_write_desc_status_dest = m_axis_write_desc_status_dest_reg;
    assign m_axis_write_desc_status_user = m_axis_write_desc_status_user_reg;
    assign m_axis_write_desc_status_error = m_axis_write_desc_status_error_reg;
    assign m_axis_write_desc_status_valid = m_axis_write_desc_status_valid_reg;
    
    assign s_axis_write_data_tready = s_axis_write_data_tready_reg;
    
    assign m_axi_awid = awid_reg;
    assign m_axi_awaddr = awaddr_reg;
    assign m_axi_awlen = awlen_reg;
    assign m_axi_awsize = awsize_reg;
    assign m_axi_awburst = awburst_reg;
    assign m_axi_awlock = awlock_reg;
    assign m_axi_awcache = awcache_reg;
    assign m_axi_awprot = awprot_reg;
    assign m_axi_awvalid = awvalid_reg;
    
    assign m_axi_wdata = wdata_reg;
    assign m_axi_wstrb = wstrb_reg;
    assign m_axi_wlast = wlast_reg;
    assign m_axi_wvalid = wvalid_reg;
    
    assign m_axi_bready = bready_reg;
    
    assign m_axi_arid = arid_reg;
    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = arsize_reg;
    assign m_axi_arburst = arburst_reg;
    assign m_axi_arlock = arlock_reg;
    assign m_axi_arcache = arcache_reg;
    assign m_axi_arprot = arprot_reg;
    assign m_axi_arvalid = arvalid_reg;
    
    assign m_axi_rready = rready_reg;

endmodule
