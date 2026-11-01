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
    localparam AXI_DATA_LOG2 = $clog2(AXI_DATA_BYTES);
    localparam AXI_MAX_BURST_LEN_LOG2 = $clog2(AXI_MAX_BURST_LEN);
    localparam BURST_LEN_WIDTH = (AXI_MAX_BURST_LEN_LOG2 > 8) ? AXI_MAX_BURST_LEN_LOG2 : 8;
    
    // State machines
    localparam READ_IDLE = 2'd0;
    localparam READ_ADDR = 2'd1;
    localparam READ_DATA = 2'd2;
    localparam READ_DONE = 2'd3;
    
    localparam WRITE_IDLE = 2'd0;
    localparam WRITE_ADDR = 2'd1;
    localparam WRITE_DATA = 2'd2;
    localparam WRITE_RESP = 2'd3;
    localparam WRITE_DONE = 2'd4;

    // Read channel signals
    reg [1:0] read_state;
    reg [AXI_ADDR_WIDTH-1:0] read_addr_reg;
    reg [LEN_WIDTH-1:0] read_len_reg;
    reg [LEN_WIDTH-1:0] read_len_remaining;
    reg [TAG_WIDTH-1:0] read_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] read_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] read_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] read_user_reg;
    reg [BURST_LEN_WIDTH-1:0] read_burst_len;
    reg [LEN_WIDTH-1:0] read_burst_remaining;
    reg [AXI_ADDR_WIDTH-1:0] read_addr_next;
    reg [3:0] read_error;
    reg read_status_valid;
    reg [TAG_WIDTH-1:0] read_status_tag;
    reg [3:0] read_status_error;
    
    // Write channel signals
    reg [1:0] write_state;
    reg [AXI_ADDR_WIDTH-1:0] write_addr_reg;
    reg [LEN_WIDTH-1:0] write_len_reg;
    reg [LEN_WIDTH-1:0] write_len_remaining;
    reg [TAG_WIDTH-1:0] write_tag_reg;
    reg [AXIS_ID_WIDTH-1:0] write_id_reg;
    reg [AXIS_DEST_WIDTH-1:0] write_dest_reg;
    reg [AXIS_USER_WIDTH-1:0] write_user_reg;
    reg [BURST_LEN_WIDTH-1:0] write_burst_len;
    reg [LEN_WIDTH-1:0] write_burst_remaining;
    reg [AXI_ADDR_WIDTH-1:0] write_addr_next;
    reg [3:0] write_error;
    reg write_status_valid;
    reg [LEN_WIDTH-1:0] write_status_len;
    reg [TAG_WIDTH-1:0] write_status_tag;
    reg [AXIS_ID_WIDTH-1:0] write_status_id;
    reg [AXIS_DEST_WIDTH-1:0] write_status_dest;
    reg [AXIS_USER_WIDTH-1:0] write_status_user;
    reg [3:0] write_status_error;

    // AXI AW channel
    reg [AXI_ID_WIDTH-1:0] awid_reg;
    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [7:0] awlen_reg;
    reg [2:0] awsize_reg;
    reg [1:0] awburst_reg;
    reg awlock_reg;
    reg [3:0] awcache_reg;
    reg [2:0] awprot_reg;
    reg awvalid_reg;
    
    // AXI W channel
    reg [AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [AXI_STRB_WIDTH-1:0] wstrb_reg;
    reg wlast_reg;
    reg wvalid_reg;
    
    // AXI B channel
    reg bready_reg;
    
    // AXI AR channel
    reg [AXI_ID_WIDTH-1:0] arid_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg [2:0] arsize_reg;
    reg [1:0] arburst_reg;
    reg arlock_reg;
    reg [3:0] arcache_reg;
    reg [2:0] arprot_reg;
    reg arvalid_reg;
    
    // AXI R channel
    reg rready_reg;
    
    // Read data output
    reg [AXIS_DATA_WIDTH-1:0] read_data_out;
    reg [AXIS_KEEP_WIDTH-1:0] read_keep_out;
    reg read_valid_out;
    reg read_last_out;
    reg [AXIS_ID_WIDTH-1:0] read_tid_out;
    reg [AXIS_DEST_WIDTH-1:0] read_tdest_out;
    reg [AXIS_USER_WIDTH-1:0] read_tuser_out;

    // Write data input
    reg write_ready_out;

    // Helper functions
    function [BURST_LEN_WIDTH-1:0] calc_burst_len;
        input [LEN_WIDTH-1:0] len;
        begin
            if (len == 0)
                calc_burst_len = 0;
            else if (len >= AXI_MAX_BURST_LEN)
                calc_burst_len = AXI_MAX_BURST_LEN - 1;
            else
                calc_burst_len = len - 1;
        end
    endfunction

    // Read descriptor acceptance
    wire read_desc_accept = s_axis_read_desc_valid && s_axis_read_desc_ready && read_enable;
    assign s_axis_read_desc_ready = (read_state == READ_IDLE) && read_enable;

    // Write descriptor acceptance
    wire write_desc_accept = s_axis_write_desc_valid && s_axis_write_desc_ready && write_enable;
    assign s_axis_write_desc_ready = (write_state == WRITE_IDLE) && write_enable;

    // Read state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= READ_IDLE;
            read_addr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            read_len_reg <= {LEN_WIDTH{1'b0}};
            read_len_remaining <= {LEN_WIDTH{1'b0}};
            read_tag_reg <= {TAG_WIDTH{1'b0}};
            read_id_reg <= {AXIS_ID_WIDTH{1'b0}};
            read_dest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            read_user_reg <= {AXIS_USER_WIDTH{1'b0}};
            read_burst_len <= {BURST_LEN_WIDTH{1'b0}};
            read_burst_remaining <= {LEN_WIDTH{1'b0}};
            read_addr_next <= {AXI_ADDR_WIDTH{1'b0}};
            read_error <= 4'b0000;
            read_status_valid <= 1'b0;
            read_status_tag <= {TAG_WIDTH{1'b0}};
            read_status_error <= 4'b0000;
            arid_reg <= {AXI_ID_WIDTH{1'b0}};
            araddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            arlen_reg <= 8'd0;
            arsize_reg <= 3'b000;
            arburst_reg <= 2'b01;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 3'b000;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            read_data_out <= {AXIS_DATA_WIDTH{1'b0}};
            read_keep_out <= {AXIS_KEEP_WIDTH{1'b0}};
            read_valid_out <= 1'b0;
            read_last_out <= 1'b0;
            read_tid_out <= {AXIS_ID_WIDTH{1'b0}};
            read_tdest_out <= {AXIS_DEST_WIDTH{1'b0}};
            read_tuser_out <= {AXIS_USER_WIDTH{1'b0}};
        end else begin
            // Default assignments
            read_status_valid <= 1'b0;
            read_valid_out <= 1'b0;
            
            case (read_state)
                READ_IDLE: begin
                    if (read_desc_accept) begin
                        read_addr_reg <= s_axis_read_desc_addr;
                        read_len_reg <= s_axis_read_desc_len;
                        read_len_remaining <= s_axis_read_desc_len;
                        read_tag_reg <= s_axis_read_desc_tag;
                        read_id_reg <= s_axis_read_desc_id;
                        read_dest_reg <= s_axis_read_desc_dest;
                        read_user_reg <= s_axis_read_desc_user;
                        read_addr_next <= s_axis_read_desc_addr;
                        read_error <= 4'b0000;
                        
                        if (s_axis_read_desc_len == 0) begin
                            read_status_valid <= 1'b1;
                            read_status_tag <= s_axis_read_desc_tag;
                            read_status_error <= 4'b0000;
                        end else begin
                            read_burst_len <= calc_burst_len(s_axis_read_desc_len);
                            read_burst_remaining <= s_axis_read_desc_len;
                            read_state <= READ_ADDR;
                        end
                    end
                end
                
                READ_ADDR: begin
                    arid_reg <= read_tag_reg;
                    araddr_reg <= read_addr_next;
                    arlen_reg <= read_burst_len;
                    arsize_reg <= AXI_DATA_LOG2[2:0];
                    arburst_reg <= 2'b01; // INCR
                    arlock_reg <= 1'b0;
                    arcache_reg <= 4'b0000;
                    arprot_reg <= 3'b000;
                    arvalid_reg <= 1'b1;
                    
                    if (arvalid_reg && m_axi_arready) begin
                        arvalid_reg <= 1'b0;
                        rready_reg <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    if (m_axi_rvalid && rready_reg) begin
                        read_data_out <= m_axi_rdata;
                        read_keep_out <= {AXIS_KEEP_WIDTH{1'b1}};
                        read_tid_out <= read_id_reg;
                        read_tdest_out <= read_dest_reg;
                        read_tuser_out <= read_user_reg;
                        read_valid_out <= 1'b1;
                        
                        if (m_axi_rlast) begin
                            read_last_out <= 1'b1;
                            rready_reg <= 1'b0;
                            
                            // Check if more data to read
                            if (read_burst_remaining > read_burst_len + 1) begin
                                read_burst_remaining <= read_burst_remaining - (read_burst_len + 1);
                                read_len_remaining <= read_len_remaining - (read_burst_len + 1);
                                read_addr_next <= read_addr_next + (read_burst_len + 1) * AXI_DATA_BYTES;
                                read_burst_len <= calc_burst_len(read_burst_remaining);
                                read_state <= READ_ADDR;
                            end else begin
                                // Done
                                read_status_valid <= 1'b1;
                                read_status_tag <= read_tag_reg;
                                read_status_error <= read_error;
                                read_state <= READ_IDLE;
                            end
                        end else begin
                            read_last_out <= 1'b0;
                        end
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end

    // Write state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            write_addr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            write_len_reg <= {LEN_WIDTH{1'b0}};
            write_len_remaining <= {LEN_WIDTH{1'b0}};
            write_tag_reg <= {TAG_WIDTH{1'b0}};
            write_id_reg <= {AXIS_ID_WIDTH{1'b0}};
            write_dest_reg <= {AXIS_DEST_WIDTH{1'b0}};
            write_user_reg <= {AXIS_USER_WIDTH{1'b0}};
            write_burst_len <= {BURST_LEN_WIDTH{1'b0}};
            write_burst_remaining <= {LEN_WIDTH{1'b0}};
            write_addr_next <= {AXI_ADDR_WIDTH{1'b0}};
            write_error <= 4'b0000;
            write_status_valid <= 1'b0;
            write_status_len <= {LEN_WIDTH{1'b0}};
            write_status_tag <= {TAG_WIDTH{1'b0}};
            write_status_id <= {AXIS_ID_WIDTH{1'b0}};
            write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
            write_status_user <= {AXIS_USER_WIDTH{1'b0}};
            write_status_error <= 4'b0000;
            awid_reg <= {AXI_ID_WIDTH{1'b0}};
            awaddr_reg <= {AXI_ADDR_WIDTH{1'b0}};
            awlen_reg <= 8'd0;
            awsize_reg <= 3'b000;
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
            write_ready_out <= 1'b0;
        end else begin
            // Default assignments
            write_status_valid <= 1'b0;
            write_ready_out <= 1'b0;
            
            case (write_state)
                WRITE_IDLE: begin
                    if (write_desc_accept) begin
                        write_addr_reg <= s_axis_write_desc_addr;
                        write_len_reg <= s_axis_write_desc_len;
                        write_len_remaining <= s_axis_write_desc_len;
                        write_tag_reg <= s_axis_write_desc_tag;
                        write_addr_next <= s_axis_write_desc_addr;
                        write_error <= 4'b0000;
                        
                        if (s_axis_write_desc_len == 0) begin
                            write_status_valid <= 1'b1;
                            write_status_len <= s_axis_write_desc_len;
                            write_status_tag <= s_axis_write_desc_tag;
                            write_status_id <= {AXIS_ID_WIDTH{1'b0}};
                            write_status_dest <= {AXIS_DEST_WIDTH{1'b0}};
                            write_status_user <= {AXIS_USER_WIDTH{1'b0}};
                            write_status_error <= 4'b0000;
                        end else begin
                            write_burst_len <= calc_burst_len(s_axis_write_desc_len);
                            write_burst_remaining <= s_axis_write_desc_len;
                            write_state <= WRITE_ADDR;
                        end
                    end
                end
                
                WRITE_ADDR: begin
                    awid_reg <= write_tag_reg;
                    awaddr_reg <= write_addr_next;
                    awlen_reg <= write_burst_len;
                    awsize_reg <= AXI_DATA_LOG2[2:0];
                    awburst_reg <= 2'b01; // INCR
                    awlock_reg <= 1'b0;
                    awcache_reg <= 4'b0000;
                    awprot_reg <= 3'b000;
                    awvalid_reg <= 1'b1;
                    
                    if (awvalid_reg && m_axi_awready) begin
                        awvalid_reg <= 1'b0;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axis_write_data_tvalid) begin
                        write_ready_out <= 1'b1;
                        wdata_reg <= s_axis_write_data_tdata;
                        wstrb_reg <= s_axis_write_data_tkeep;
                        wlast_reg <= s_axis_write_data_tlast;
                        wvalid_reg <= 1'b1;
                        
                        if (wvalid_reg && m_axi_wready) begin
                            wvalid_reg <= 1'b0;
                            
                            if (s_axis_write_data_tlast) begin
                                // End of burst
                                write_state <= WRITE_RESP;
                                bready_reg <= 1'b1;
                            end
                        end
                    end
                end
                
                WRITE_RESP: begin
                    if (m_axi_bvalid && bready_reg) begin
                        bready_reg <= 1'b0;
                        
                        // Check for errors
                        if (m_axi_bresp != 2'b00) begin
                            write_error <= {2'b00, m_axi_bresp};
                        end
                        
                        // Check if more data to write
                        if (write_burst_remaining > write_burst_len + 1) begin
                            write_burst_remaining <= write_burst_remaining - (write_burst_len + 1);
                            write_len_remaining <= write_len_remaining - (write_burst_len + 1);
                            write_addr_next <= write_addr_next + (write_burst_len + 1) * AXI_DATA_BYTES;
                            write_burst_len <= calc_burst_len(write_burst_remaining);
                            write_state <= WRITE_ADDR;
                        end else begin
                            // Done
                            write_status_valid <= 1'b1;
                            write_status_len <= write_len_reg;
                            write_status_tag <= write_tag_reg;
                            write_status_id <= write_id_reg;
                            write_status_dest <= write_dest_reg;
                            write_status_user <= write_user_reg;
                            write_status_error <= write_error;
                            write_state <= WRITE_IDLE;
                        end
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end

    // Handle write abort
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset handled above
        end else if (write_abort && write_state != WRITE_IDLE) begin
            write_state <= WRITE_IDLE;
            awvalid_reg <= 1'b0;
            wvalid_reg <= 1'b0;
            bready_reg <= 1'b0;
            write_ready_out <= 1'b0;
            write_status_valid <= 1'b1;
            write_status_len <= write_len_reg;
            write_status_tag <= write_tag_reg;
            write_status_id <= write_id_reg;
            write_status_dest <= write_dest_reg;
            write_status_user <= write_user_reg;
            write_status_error <= 4'b0001; // Abort error
        end
    end

    // Assign outputs
    assign m_axis_read_desc_status_tag = read_status_tag;
    assign m_axis_read_desc_status_error = read_status_error;
    assign m_axis_read_desc_status_valid = read_status_valid;
    
    assign m_axis_read_data_tdata = read_data_out;
    assign m_axis_read_data_tkeep = read_keep_out;
    assign m_axis_read_data_tvalid = read_valid_out;
    assign m_axis_read_data_tlast = read_last_out;
    assign m_axis_read_data_tid = read_tid_out;
    assign m_axis_read_data_tdest = read_tdest_out;
    assign m_axis_read_data_tuser = read_tuser_out;
    
    assign m_axis_write_desc_status_len = write_status_len;
    assign m_axis_write_desc_status_tag = write_status_tag;
    assign m_axis_write_desc_status_id = write_status_id;
    assign m_axis_write_desc_status_dest = write_status_dest;
    assign m_axis_write_desc_status_user = write_status_user;
    assign m_axis_write_desc_status_error = write_status_error;
    assign m_axis_write_desc_status_valid = write_status_valid;
    
    assign s_axis_write_data_tready = write_ready_out;
    
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
