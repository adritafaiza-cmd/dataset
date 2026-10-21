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
    
    // AXI Burst Types
    localparam [1:0] AXI_BURST_FIXED = 2'b00;
    localparam [1:0] AXI_BURST_INCR  = 2'b01;
    localparam [1:0] AXI_BURST_WRAP  = 2'b10;
    
    // AXI Prototypes
    localparam [2:0] AXI_PROT_NORMAL = 3'b000;
    localparam [2:0] AXI_PROT_SECURE = 3'b001;
    localparam [2:0] AXI_PROT_PRIV   = 3'b010;
    localparam [2:0] AXI_PROT_SAP    = 3'b011;
    localparam [2:0] AXI_PROT_SAPU   = 3'b100;
    localparam [2:0] AXI_PROT_SAPR   = 3'b101;
    localparam [2:0] AXI_PROT_SAPRU  = 3'b110;
    localparam [2:0] AXI_PROT_SAPRUW = 3'b111;

    // -----------------------------------------------------------------------
    // Internal Signals
    // -----------------------------------------------------------------------
    reg        read_state;
    reg        write_state;
    reg        read_done;
    reg        write_done;
    reg        read_error;
    reg        write_error;
    reg        read_abort;
    reg        write_abort;
    
    reg        read_aw_valid;
    reg        read_aw_ready;
    reg        read_w_valid;
    reg        read_w_ready;
    reg        read_b_valid;
    reg        read_b_ready;
    reg        read_ar_valid;
    reg        read_ar_ready;
    reg        read_r_valid;
    reg        read_r_ready;
    
    reg        write_aw_valid;
    reg        write_aw_ready;
    reg        write_w_valid;
    reg        write_w_ready;
    reg        write_b_valid;
    reg        write_b_ready;
    
    reg        [AXI_ADDR_WIDTH-1:0] read_addr;
    reg        [AXI_ADDR_WIDTH-1:0] write_addr;
    reg        [LEN_WIDTH-1:0]      read_len;
    reg        [LEN_WIDTH-1:0]      write_len;
    reg        [TAG_WIDTH-1:0]      read_tag;
    reg        [TAG_WIDTH-1:0]      write_tag;
    reg        [AXIS_ID_WIDTH-1:0]  read_id;
    reg        [AXIS_ID_WIDTH-1:0]  write_id;
    reg        [AXIS_DEST_WIDTH-1:0] read_dest;
    reg        [AXIS_DEST_WIDTH-1:0] write_dest;
    reg        [AXIS_USER_WIDTH-1:0] read_user;
    reg        [AXIS_USER_WIDTH-1:0] write_user;
    
    reg        [AXI_ID_WIDTH-1:0]   read_awid;
    reg        [AXI_ID_WIDTH-1:0]   read_arid;
    reg        [AXI_ID_WIDTH-1:0]   write_awid;
    
    reg        [7:0]                read_awlen;
    reg        [7:0]                read_arlen;
    reg        [7:0]                write_awlen;
    
    reg        [2:0]                read_awsize;
    reg        [2:0]                read_arsize;
    reg        [2:0]                write_awsize;
    
    reg        [1:0]                read_awburst;
    reg        [1:0]                read_arburst;
    reg        [1:0]                write_awburst;
    
    reg        [3:0]                read_awcache;
    reg        [3:0]                read_arcache;
    reg        [3:0]                write_awcache;
    
    reg        [2:0]                read_awprot;
    reg        [2:0]                read_arprot;
    reg        [2:0]                write_awprot;
    
    reg        [AXI_DATA_WIDTH-1:0] read_wdata;
    reg        [AXI_STRB_WIDTH-1:0] read_wstrb;
    reg        [AXI_DATA_WIDTH-1:0] write_wdata;
    reg        [AXI_STRB_WIDTH-1:0] write_wstrb;
    
    reg        [AXIS_DATA_WIDTH-1:0] read_tdata;
    reg        [AXIS_KEEP_WIDTH-1:0] read_tkeep;
    reg        [AXIS_ID_WIDTH-1:0]   read_tid;
    reg        [AXIS_DEST_WIDTH-1:0] read_tdest;
    reg        [AXIS_USER_WIDTH-1:0] read_tuser;
    reg        [AXIS_DATA_WIDTH-1:0] write_tdata;
    reg        [AXIS_KEEP_WIDTH-1:0] write_tkeep;
    reg        [AXIS_ID_WIDTH-1:0]   write_tid;
    reg        [AXIS_DEST_WIDTH-1:0] write_tdest;
    reg        [AXIS_USER_WIDTH-1:0] write_tuser;
    
    reg        [LEN_WIDTH-1:0]      read_remaining_len;
    reg        [LEN_WIDTH-1:0]      write_remaining_len;
    reg        [LEN_WIDTH-1:0]      write_received_len;
    
    reg        [AXI_ADDR_WIDTH-1:0] read_current_addr;
    reg        [AXI_ADDR_WIDTH-1:0] write_current_addr;
    
    reg        [AXI_DATA_WIDTH-1:0] read_data_buffer;
    reg        [AXI_DATA_WIDTH-1:0] write_data_buffer;
    reg        [AXIS_KEEP_WIDTH-1:0] write_keep_buffer;
    
    reg        [LEN_WIDTH-1:0]      read_total_len;
    reg        [LEN_WIDTH-1:0]      write_total_len;
    
    reg        [TAG_WIDTH-1:0]      read_status_tag;
    reg        [3:0]                read_status_error;
    reg        [TAG_WIDTH-1:0]      write_status_tag;
    reg        [3:0]                write_status_error;
    reg        [LEN_WIDTH-1:0]      write_status_len;
    
    // -----------------------------------------------------------------------
    // State Machines
    // -----------------------------------------------------------------------
    
    // Read State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_state <= 0; // IDLE
            read_done  <= 0;
            read_error <= 0;
            read_abort <= 0;
            read_remaining_len <= 0;
            read_total_len <= 0;
            read_current_addr <= 0;
            read_aw_valid <= 0;
            read_w_valid <= 0;
            read_b_valid <= 0;
            read_ar_valid <= 0;
            read_r_valid <= 0;
            read_aw_ready <= 1;
            read_w_ready <= 1;
            read_b_ready <= 1;
            read_ar_ready <= 1;
            read_r_ready <= 1;
            read_tvalid <= 0;
            read_tlast <= 0;
            read_tid <= 0;
            read_tdest <= 0;
            read_tuser <= 0;
            read_tdata <= 0;
            read_tkeep <= 0;
            s_axis_read_desc_ready <= 0;
            m_axis_read_desc_status_valid <= 0;
            m_axis_read_data_tvalid <= 0;
        end
        else begin
            // State Logic
            case (read_state)
                0: begin // IDLE
                    if (read_enable && s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                        read_state <= 1;
                        read_addr <= s_axis_read_desc_addr;
                        read_len  <= s_axis_read_desc_len;
                        read_tag  <= s_axis_read_desc_tag;
                        read_id   <= s_axis_read_desc_id;
                        read_dest <= s_axis_read_desc_dest;
                        read_user <= s_axis_read_desc_user;
                        read_remaining_len <= s_axis_read_desc_len;
                        read_total_len <= s_axis_read_desc_len;
                        read_current_addr <= s_axis_read_desc_addr;
                        read_aw_valid <= 1;
                        s_axis_read_desc_ready <= 1;
                    end
                    else begin
                        s_axis_read_desc_ready <= 0;
                    end
                end
                
                1: begin // AW VALID
                    if (read_aw_valid && m_axi_awready) begin
                        read_aw_valid <= 0;
                        read_aw_ready <= 1;
                        read_state <= 2;
                        read_current_addr <= read_addr;
                    end
                    else begin
                        read_aw_ready <= 0;
                    end
                end
                
                2: begin // AW READY
                    read_aw_valid <= 1;
                    read_aw_ready <= 0;
                    read_state <= 3;
                end
                
                3: begin // W VALID
                    if (read_w_valid && m_axi_wready) begin
                        read_w_valid <= 0;
                        read_w_ready <= 1;
                        read_state <= 4;
                    end
                    else begin
                        read_w_ready <= 0;
                    end
                end
                
                4: begin // W READY
                    read_w_valid <= 1;
                    read_w_ready <= 0;
                    read_state <= 5;
                end
                
                5: begin // B VALID
                    if (read_b_valid && m_axi_bready) begin
                        read_b_valid <= 0;
                        read_b_ready <= 1;
                        read_state <= 6;
                    end
                    else begin
                        read_b_ready <= 0;
                    end
                end
                
                6: begin // B READY
                    read_b_valid <= 1;
                    read_b_ready <= 0;
                    read_state <= 7;
                end
                
                7: begin // AR VALID
                    if (read_ar_valid && m_axi_arready) begin
                        read_ar_valid <= 0;
                        read_ar_ready <= 1;
                        read_state <= 8;
                        read_current_addr <= read_addr;
                    end
                    else begin
                        read_ar_ready <= 0;
                    end
                end
                
                8: begin // AR READY
                    read_ar_valid <= 1;
                    read_ar_ready <= 0;
                    read_state <= 9;
                end
                
                9: begin // R VALID
                    if (read_r_valid && m_axi_rready) begin
                        read_r_valid <= 0;
                        read_r_ready <= 1;
                        read_state <= 10;
                    end
                    else begin
                        read_r_ready <= 0;
                    end
                end
                
                10: begin // R READY
                    read_r_valid <= 1;
                    read_r_ready <= 0;
                    read_state <= 11;
                end
                
                11: begin // PROCESS DATA
                    if (read_remaining_len > 0) begin
                        // Generate AXI Stream Data
                        if (AXIS_LAST_ENABLE) begin
                            m_axis_read_data_tlast <= 1;
                        end
                        else begin
                            m_axis_read_data_tlast <= 0;
                        end
                        
                        if (AXIS_ID_ENABLE) begin
                            m_axis_read_data_tid <= read_id;
                        end
                        else begin
                            m_axis_read_data_tid <= 0;
                        end
                        
                        if (AXIS_DEST_ENABLE) begin
                            m_axis_read_data_tdest <= read_dest;
                        end
                        else begin
                            m_axis_read_data_tdest <= 0;
                        end
                        
                        if (AXIS_USER_ENABLE) begin
                            m_axis_read_data_tuser <= read_user;
                        end
                        else begin
                            m_axis_read_data_tuser <= 0;
                        end
                        
                        // Handle Keep
                        if (AXIS_KEEP_ENABLE) begin
                            m_axis_read_data_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                        end
                        else begin
                            m_axis_read_data_tkeep <= 0;
                        end
                        
                        // Data
                        m_axis_read_data_tdata <= read_data_buffer;
                        m_axis_read_data_tvalid <= 1;
                        
                        if (m_axis_read_data_tready) begin
                            read_remaining_len <= read_remaining_len - 1;
                            read_current_addr <= read_current_addr + (AXI_DATA_WIDTH/8);
                            read_state <= 12;
                        end
                        else begin
                            m_axis_read_data_tvalid <= 0;
                        end
                    end
                    else begin
                        // Done
                        read_done <= 1;
                        read_state <= 0;
                        read_aw_valid <= 0;
                        read_w_valid <= 0;
                        read_b_valid <= 0;
                        read_ar_valid <= 0;
                        read_r_valid <= 0;
                        read_aw_ready <= 1;
                        read_w_ready <= 1;
                        read_b_ready <= 1;
                        read_ar_ready <= 1;
                        read_r_ready <= 1;
                        m_axis_read_data_tvalid <= 0;
                        
                        // Send Status
                        if (m_axis_read_desc_status_valid) begin
                            m_axis_read_desc_status_valid <= 0;
                        end
                        m_axis_read_desc_status_tag <= read_tag;
                        m_axis_read_desc_status_error <= read_error;
                        m_axis_read_desc_status_valid <= 1;
                    end
                end
                
                12: begin // WAIT FOR DATA
                    if (m_axis_read_data_tready && m_axis_read_data_tvalid) begin
                        read_state <= 11;
                    end
                    else begin
                        m_axis_read_data_tvalid <= 0;
                    end
                end
                
                default: begin
                    read_state <= 0;
                    read_aw_valid <= 0;
                    read_w_valid <= 0;
                    read_b_valid <= 0;
                    read_ar_valid <= 0;
                    read_r_valid <= 0;
                    read_aw_ready <= 1;
                    read_w_ready <= 1;
                    read_b_ready <= 1;
                    read_ar_ready <= 1;
                    read_r_ready <= 1;
                    m_axis_read_data_tvalid <= 0;
                    s_axis_read_desc_ready <= 0;
                    m_axis_read_desc_status_valid <= 0;
                end
            endcase
        end
    end
    
    // Write State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_state <= 0; // IDLE
            write_done  <= 0;
            write_error <= 0;
            write_abort <= 0;
            write_remaining_len <= 0;
            write_total_len <= 0;
            write_received_len <= 0;
            write_current_addr <= 0;
            write_aw_valid <= 0;
            write_w_valid <= 0;
            write_b_valid <= 0;
            write_aw_ready <= 1;
            write_w_ready <= 1;
            write_b_ready <= 1;
            write_tvalid <= 0;
            write_tlast <= 0;
            write_tid <= 0;
            write_tdest <= 0;
            write_tuser <= 0;
            write_tdata <= 0;
            write_tkeep <= 0;
            s_axis_write_desc_ready <= 0;
            m_axis_write_desc_status_valid <= 0;
            s_axis_write_data_tready <= 0;
        end
        else begin
            // State Logic
            case (write_state)
                0: begin // IDLE
                    if (write_enable && s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                        write_state <= 1;
                        write_addr <= s_axis_write_desc_addr;
                        write_len  <= s_axis_write_desc_len;
                        write_tag  <= s_axis_write_desc_tag;
                        write_id   <= s_axis_write_data_tid; // Use ID from first data packet if available, else 0
                        write_dest <= s_axis_write_data_tdest;
                        write_user <= s_axis_write_data_tuser;
                        write_remaining_len <= s_axis_write_desc_len;
                        write_total_len <= s_axis_write_desc_len;
                        write_current_addr <= s_axis_write_desc_addr;
                        write_aw_valid <= 1;
                        s_axis_write_desc_ready <= 1;
                    end
                    else begin
                        s_axis_write_desc_ready <= 0;
                    end
                end
                
                1: begin // AW VALID
                    if (write_aw_valid && m_axi_awready) begin
                        write_aw_valid <= 0;
                        write_aw_ready <= 1;
                        write_state <= 2;
                        write_current_addr <= write_addr;
                    end
                    else begin
                        write_aw_ready <= 0;
                    end
                end
                
                2: begin // AW READY
                    write_aw_valid <= 1;
                    write_aw_ready <= 0;
                    write_state <= 3;
                end
                
                3: begin // W VALID
                    if (write_w_valid && m_axi_wready) begin
                        write_w_valid <= 0;
                        write_w_ready <= 1;
                        write_state <= 4;
                    end
                    else begin
                        write_w_ready <= 0;
                    end
                end
                
                4: begin // W READY
                    write_w_valid <= 1;
                    write_w_ready <= 0;
                    write_state <= 5;
                end
                
                5: begin // B VALID
                    if (write_b_valid && m_axi_bready) begin
                        write_b_valid <= 0;
                        write_b_ready <= 1;
                        write_state <= 6;
                    end
                    else begin
                        write_b_ready <= 0;
                    end
                end
                
                6: begin // B READY
                    write_b_valid <= 1;
                    write_b_ready <= 0;
                    write_state <= 7;
                end
                
                7: begin // PROCESS DATA
                    if (write_remaining_len > 0) begin
                        // Generate AXI Stream Data
                        if (AXIS_LAST_ENABLE) begin
                            m_axis_write_desc_status_valid <= 1;
                            m_axis_write_desc_status_len <= write_remaining_len;
                            m_axis_write_desc_status_tag <= write_tag;
                            m_axis_write_desc_status_id <= write_id;
                            m_axis_write_desc_status_dest <= write_dest;
                            m_axis_write_desc_status_user <= write_user;
                            m_axis_write_desc_status_error <= write_error;
                        end
                        else begin
                            m_axis_write_desc_status_valid <= 0;
                        end
                        
                        if (AXIS_ID_ENABLE) begin
                            write_tid <= write_id;
                        end
                        else begin
                            write_tid <= 0;
                        end
                        
                        if (AXIS_DEST_ENABLE) begin
                            write_tdest <= write_dest;
                        end
                        else begin
                            write_tdest <= 0;
                        end
                        
                        if (AXIS_USER_ENABLE) begin
                            write_tuser <= write_user;
                        end
                        else begin
                            write_tuser <= 0;
                        end
                        
                        // Handle Keep
                        if (AXIS_KEEP_ENABLE) begin
                            write_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
                        end
                        else begin
                            write_tkeep <= 0;
                        end
                        
                        // Data
                        write_tdata <= write_data_buffer;
                        write_tvalid <= 1;
                        
                        if (m_axis_write_data_tready) begin
                            write_remaining_len <= write_remaining_len - 1;
                            write_current_addr <= write_current_addr + (AXI_DATA_WIDTH/8);
                            write_state <= 8;
                        end
                        else begin
                            write_tvalid <= 0;
                        end
                    end
                    else begin
                        // Done
                        write_done <= 1;
                        write_state <= 0;
                        write_aw_valid <= 0;
                        write_w_valid <= 0;
                        write_b_valid <= 0;
                        write_aw_ready <= 1;
                        write_w_ready <= 1;
                        write_b_ready <= 1;
                        write_tvalid <= 0;
                        m_axis_write_desc_status_valid <= 0;
                        s_axis_write_data_tready <= 0;
                    end
                end
                
                8: begin // WAIT FOR DATA
                    if (m_axis_write_data_tready && write_tvalid) begin
                        write_state <= 7;
                    end
                    else begin
                        write_tvalid <= 0;
                    end
                end
                
                default: begin
                    write_state <= 0;
                    write_aw_valid <= 0;
                    write_w_valid <= 0;
                    write_b_valid <= 0;
                    write_aw_ready <= 1;
                    write_w_ready <= 1;
                    write_b_ready <= 1;
                    write_tvalid <= 0;
                    s_axis_write_desc_ready <= 0;
                    m_axis_write_desc_status_valid <= 0;
                    s_axis_write_data_tready <= 0;
                end
            endcase
        end
    end
    
    // -----------------------------------------------------------------------
    // AXI Master Interface Logic
    // -----------------------------------------------------------------------
    
    // Read AW
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 0;
            m_axi_awburst <= AXI_BURST_FIXED;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= AXI_PROT_NORMAL;
            m_axi_awvalid <= 0;
            m_axi_awready <= 1;
        end
        else begin
            if (read_state == 1) begin
                m_axi_awid <= read_awid;
                m_axi_awaddr <= read_addr;
                m_axi_awlen <= read_awlen;
                m_axi_awsize <= read_awsize;
                m_axi_awburst <= read_awburst;
                m_axi_awlock <= 0;
                m_axi_awcache <= read_awcache;
                m_axi_awprot <= read_awprot;
                m_axi_awvalid <= 1;
                m_axi_awready <= 0;
            end
            else begin
                m_axi_awvalid <= 0;
                m_axi_awready <= 1;
            end
        end
    end
    
    // Read W
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
            m_axi_wready <= 1;
        end
        else begin
            if (read_state == 3) begin
                m_axi_wdata <= read_wdata;
                m_axi_wstrb <= read_wstrb;
                m_axi_wlast <= 0;
                m_axi_wvalid <= 1;
                m_axi_wready <= 0;
            end
            else begin
                m_axi_wvalid <= 0;
                m_axi_wready <= 1;
            end
        end
    end
    
    // Read B
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_bready <= 1;
        end
        else begin
            if (read_state == 5) begin
                m_axi_bready <= 0;
            end
            else begin
                m_axi_bready <= 1;
            end
        end
    end
    
    // Read AR
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_arid <= 0;
            m_axi_araddr <= 0;
            m_axi_arlen <= 0;
            m_axi_arsize <= 0;
            m_axi_arburst <= AXI_BURST_FIXED;
            m_axi_arlock <= 0;
            m_axi_arcache <= 0;
            m_axi_arprot <= AXI_PROT_NORMAL;
            m_axi_arvalid <= 0;
            m_axi_arready <= 1;
        end
        else begin
            if (read_state == 7) begin
                m_axi_arid <= read_arid;
                m_axi_araddr <= read_addr;
                m_axi_arlen <= read_arlen;
                m_axi_arsize <= read_arsize;
                m_axi_arburst <= read_arburst;
                m_axi_arlock <= 0;
                m_axi_arcache <= read_arcache;
                m_axi_arprot <= read_arprot;
                m_axi_arvalid <= 1;
                m_axi_arready <= 0;
            end
            else begin
                m_axi_arvalid <= 0;
                m_axi_arready <= 1;
            end
        end
    end
    
    // Read R
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_rready <= 1;
        end
        else begin
            if (read_state == 9) begin
                m_axi_rready <= 0;
            end
            else begin
                m_axi_rready <= 1;
            end
        end
    end
    
    // Write AW
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_awid <= 0;
            m_axi_awaddr <= 0;
            m_axi_awlen <= 0;
            m_axi_awsize <= 0;
            m_axi_awburst <= AXI_BURST_FIXED;
            m_axi_awlock <= 0;
            m_axi_awcache <= 0;
            m_axi_awprot <= AXI_PROT_NORMAL;
            m_axi_awvalid <= 0;
            m_axi_awready <= 1;
        end
        else begin
            if (write_state == 1) begin
                m_axi_awid <= write_awid;
                m_axi_awaddr <= write_addr;
                m_axi_awlen <= write_awlen;
                m_axi_awsize <= write_awsize;
                m_axi_awburst <= write_awburst;
                m_axi_awlock <= 0;
                m_axi_awcache <= write_awcache;
                m_axi_awprot <= write_awprot;
                m_axi_awvalid <= 1;
                m_axi_awready <= 0;
            end
            else begin
                m_axi_awvalid <= 0;
                m_axi_awready <= 1;
            end
        end
    end
    
    // Write W
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_wdata <= 0;
            m_axi_wstrb <= 0;
            m_axi_wlast <= 0;
            m_axi_wvalid <= 0;
            m_axi_wready <= 1;
        end
        else begin
            if (write_state == 3) begin
                m_axi_wdata <= write_wdata;
                m_axi_wstrb <= write_wstrb;
                m_axi_wlast <= 0;
                m_axi_wvalid <= 1;
                m_axi_wready <= 0;
            end
            else begin
                m_axi_wvalid <= 0;
                m_axi_wready <= 1;
            end
        end
    end
    
    // Write B
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axi_bready <= 1;
        end
        else begin
            if (write_state == 5) begin
                m_axi_bready <= 0;
            end
            else begin
                m_axi_bready <= 1;
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // AXI Master Interface Response Handling
    // ----------------------------------------------------------------