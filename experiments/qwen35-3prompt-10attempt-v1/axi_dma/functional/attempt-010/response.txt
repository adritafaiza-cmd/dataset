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

    // --------------------------------------------------------------------------
    // Internal Parameters and Constants
    // --------------------------------------------------------------------------
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_DATA_WIDTH    = $clog2(AXI_DATA_WIDTH);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);
    
    // State encoding
    localparam IDLE = 2'd0;
    localparam AW_PREPARE = 2'd1;
    localparam AW_SEND = 2'd2;
    localparam W_PREPARE = 2'd3;
    localparam W_SEND = 2'd4;
    localparam B_WAIT = 2'd5;
    localparam AR_PREPARE = 2'd6;
    localparam AR_SEND = 2'd7;
    localparam R_PREPARE = 2'd8;
    localparam R_WAIT = 2'd9;
    localparam DONE = 2'd10;

    // --------------------------------------------------------------------------
    // Internal Registers
    // --------------------------------------------------------------------------
    reg [1:0] state;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [LEN_WIDTH-1:0] current_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [AXIS_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    
    // Write specific
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [LEN_WIDTH-1:0] write_len;
    reg [TAG_WIDTH-1:0] write_tag;
    reg write_abort_flag;
    
    // AXI Transaction State
    reg [7:0] axi_len;
    reg [2:0] axi_size;
    reg [1:0] axi_burst;
    reg [7:0] axi_burst_count;
    reg [7:0] axi_burst_remaining;
    reg [1:0] axi_burst_type; // 0: FIXED, 1: INCR
    reg [AXI_ID_WIDTH-1:0] axi_id;
    reg [AXI_ADDR_WIDTH-1:0] axi_addr;
    reg [AXI_DATA_WIDTH-1:0] axi_wdata;
    reg [AXI_STRB_WIDTH-1:0] axi_wstrb;
    reg axi_wlast;
    reg axi_awvalid;
    reg axi_wvalid;
    reg axi_arvalid;
    reg axi_bready;
    reg axi_rready;
    
    // Stream Data State
    reg [AXI_DATA_WIDTH-1:0] stream_data;
    reg [AXIS_KEEP_WIDTH-1:0] stream_keep;
    reg stream_valid;
    reg stream_last;
    reg stream_tid;
    reg stream_tdest;
    reg stream_tuser;
    reg stream_tkeep;
    reg stream_tdata;
    reg stream_tready;
    
    // Status Output
    reg [TAG_WIDTH-1:0] status_tag;
    reg [LEN_WIDTH-1:0] status_len;
    reg [AXIS_ID_WIDTH-1:0] status_id;
    reg [AXIS_DEST_WIDTH-1:0] status_dest;
    reg [AXIS_USER_WIDTH-1:0] status_user;
    reg [3:0] status_error;
    reg status_valid;
    
    // Counters
    reg [LEN_WIDTH-1:0] len_counter;
    reg [7:0] w_byte_count;
    reg [7:0] r_byte_count;
    reg [7:0] w_byte_remaining;
    reg [7:0] r_byte_remaining;
    reg [AXI_STRB_WIDTH-1:0] w_strb;
    reg [AXI_STRB_WIDTH-1:0] r_strb;
    
    // --------------------------------------------------------------------------
    // Combinational Logic for Outputs
    // --------------------------------------------------------------------------
    always @(*) begin
        // Default assignments
        s_axis_read_desc_ready = 1'b0;
        m_axis_read_desc_status_tag = 0;
        m_axis_read_desc_status_error = 4'hF;
        m_axis_read_desc_status_valid = 1'b0;
        
        m_axis_read_data_tdata = 0;
        m_axis_read_data_tkeep = 0;
        m_axis_read_data_tvalid = 1'b0;
        m_axis_read_data_tlast = 1'b0;
        m_axis_read_data_tid = 0;
        m_axis_read_data_tdest = 0;
        m_axis_read_data_tuser = 0;
        
        s_axis_write_desc_ready = 1'b0;
        m_axis_write_desc_status_len = 0;
        m_axis_write_desc_status_tag = 0;
        m_axis_write_desc_status_id = 0;
        m_axis_write_desc_status_dest = 0;
        m_axis_write_desc_status_user = 0;
        m_axis_write_desc_status_error = 4'hF;
        m_axis_write_desc_status_valid = 1'b0;
        
        s_axis_write_data_tready = 1'b0;
        m_axi_awid = 0;
        m_axi_awaddr = 0;
        m_axi_awlen = 0;
        m_axi_awsize = 0;
        m_axi_awburst = 0;
        m_axi_awlock = 0;
        m_axi_awcache = 0;
        m_axi_awprot = 0;
        m_axi_awvalid = 0;
        m_axi_wdata = 0;
        m_axi_wstrb = 0;
        m_axi_wlast = 0;
        m_axi_wvalid = 0;
        m_axi_bready = 0;
        m_axi_arid = 0;
        m_axi_araddr = 0;
        m_axi_arlen = 0;
        m_axi_arsize = 0;
        m_axi_arburst = 0;
        m_axi_arlock = 0;
        m_axi_arcache = 0;
        m_axi_arprot = 0;
        m_axi_arvalid = 0;
        m_axi_rready = 0;
        
        // Read Descriptor Input
        if (read_enable) begin
            s_axis_read_desc_ready = 1'b1;
        end
        
        // Read Data Output
        if (stream_valid && m_axis_read_data_tready) begin
            m_axis_read_data_tvalid = 1'b1;
            m_axis_read_data_tdata = stream_tdata;
            m_axis_read_data_tkeep = stream_tkeep;
            m_axis_read_data_tlast = stream_last;
            m_axis_read_data_tid = stream_tid;
            m_axis_read_data_tdest = stream_tdest;
            m_axis_read_data_tuser = stream_tuser;
        end else begin
            m_axis_read_data_tvalid = 1'b0;
        end
        
        // Read Status Output
        if (state == DONE && m_axis_read_desc_status_valid) begin
            m_axis_read_desc_status_tag = status_tag;
            m_axis_read_desc_status_error = status_error;
            m_axis_read_desc_status_valid = 1'b1;
        end else begin
            m_axis_read_desc_status_valid = 1'b0;
        end
        
        // Write Descriptor Input
        if (write_enable && !write_abort_flag) begin
            s_axis_write_desc_ready = 1'b1;
        end
        
        // Write Status Output
        if (state == DONE && m_axis_write_desc_status_valid) begin
            m_axis_write_desc_status_len = status_len;
            m_axis_write_desc_status_tag = status_tag;
            m_axis_write_desc_status_id = status_id;
            m_axis_write_desc_status_dest = status_dest;
            m_axis_write_desc_status_user = status_user;
            m_axis_write_desc_status_error = status_error;
            m_axis_write_desc_status_valid = 1'b1;
        end else begin
            m_axis_write_desc_status_valid = 1'b0;
        end
        
        // Write Data Input
        if (write_enable && !write_abort_flag && s_axis_write_data_tready) begin
            s_axis_write_data_tready = 1'b1;
        end
        
        // AXI Write Address
        if (state == AW_PREPARE) begin
            m_axi_awid = axi_id;
            m_axi_awaddr = axi_addr;
            m_axi_awlen = axi_len;
            m_axi_awsize = axi_size;
            m_axi_awburst = axi_burst;
            m_axi_awlock = 1'b0;
            m_axi_awcache = 4'h0;
            m_axi_awprot = 3'h0;
            m_axi_awvalid = 1'b1;
        end else begin
            m_axi_awvalid = 1'b0;
        end
        
        // AXI Write Data
        if (state == W_SEND) begin
            m_axi_wdata = axi_wdata;
            m_axi_wstrb = axi_wstrb;
            m_axi_wlast = axi_wlast;
            m_axi_wvalid = 1'b1;
        end else begin
            m_axi_wvalid = 1'b0;
        end
        
        // AXI Write Response Ready
        if (state == B_WAIT) begin
            m_axi_bready = 1'b1;
        end else begin
            m_axi_bready = 1'b0;
        end
        
        // AXI Read Address
        if (state == AR_PREPARE) begin
            m_axi_arid = axi_id;
            m_axi_araddr = axi_addr;
            m_axi_arlen = axi_len;
            m_axi_arsize = axi_size;
            m_axi_arburst = axi_burst;
            m_axi_arlock = 1'b0;
            m_axi_arcache = 4'h0;
            m_axi_arprot = 3'h0;
            m_axi_arvalid = 1'b1;
        end else begin
            m_axi_arvalid = 1'b0;
        end
        
        // AXI Read Response Ready
        if (state == R_PREPARE || state == R_WAIT) begin
            m_axi_rready = 1'b1;
        end else begin
            m_axi_rready = 1'b0;
        end
    end

    // --------------------------------------------------------------------------
    // Sequential Logic
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_tag <= 0;
            current_len <= 0;
            current_addr <= 0;
            current_id <= 0;
            current_dest <= 0;
            current_user <= 0;
            write_addr <= 0;
            write_len <= 0;
            write_tag <= 0;
            write_abort_flag <= 0;
            axi_len <= 0;
            axi_size <= 0;
            axi_burst <= 0;
            axi_burst_count <= 0;
            axi_burst_remaining <= 0;
            axi_burst_type <= 0;
            axi_id <= 0;
            axi_addr <= 0;
            axi_wdata <= 0;
            axi_wstrb <= 0;
            axi_wlast <= 0;
            axi_awvalid <= 0;
            axi_wvalid <= 0;
            axi_arvalid <= 0;
            axi_bready <= 0;
            axi_rready <= 0;
            stream_data <= 0;
            stream_keep <= 0;
            stream_valid <= 0;
            stream_last <= 0;
            stream_tid <= 0;
            stream_tdest <= 0;
            stream_tuser <= 0;
            stream_tkeep <= 0;
            stream_tdata <= 0;
            stream_tready <= 0;
            status_tag <= 0;
            status_len <= 0;
            status_id <= 0;
            status_dest <= 0;
            status_user <= 0;
            status_error <= 4'hF;
            status_valid <= 0;
            len_counter <= 0;
            w_byte_count <= 0;
            w_byte_remaining <= 0;
            r_byte_count <= 0;
            r_byte_remaining <= 0;
            w_strb <= 0;
            r_strb <= 0;
        end else begin
            // Reset abort flag on reset
            write_abort_flag <= write_abort;
            
            // --------------------------------------------------------------------
            // Read Path State Machine
            // --------------------------------------------------------------------
            if (state == IDLE) begin
                if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                    state <= AW_PREPARE;
                    current_tag <= s_axis_read_desc_tag;
                    current_len <= s_axis_read_desc_len;
                    current_addr <= s_axis_read_desc_addr;
                    current_id <= s_axis_read_desc_id;
                    current_dest <= s_axis_read_desc_dest;
                    current_user <= s_axis_read_desc_user;
                    len_counter <= s_axis_read_desc_len;
                    axi_len <= 0;
                    axi_size <= 0;
                    axi_burst <= 2'b01; // INCR
                    axi_burst_type <= 2'b01;
                    axi_burst_remaining <= s_axis_read_desc_len;
                    axi_addr <= s_axis_read_desc_addr;
                    axi_id <= s_axis_read_desc_id;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == AW_PREPARE) begin
                if (m_axi_awvalid && m_axi_awready) begin
                    state <= W_PREPARE;
                    axi_awvalid <= 0;
                    axi_burst_count <= 0;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == W_PREPARE) begin
                if (write_enable) begin
                    state <= W_SEND;
                    axi_wdata <= 0;
                    axi_wstrb <= 0;
                    axi_wlast <= 0;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == W_SEND) begin
                if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                    // Process data
                    if (s_axis_write_data_tlast) begin
                        // Last beat
                        axi_wlast <= 1'b1;
                        w_byte_count <= s_axis_write_data_tkeep;
                        w_byte_remaining <= s_axis_write_data_tkeep;
                        r_byte_count <= s_axis_write_data_tkeep;
                        r_byte_remaining <= s_axis_write_data_tkeep;
                        
                        // Update stream
                        stream_tdata <= s_axis_write_data_tdata;
                        stream_tkeep <= s_axis_write_data_tkeep;
                        stream_last <= 1'b1;
                        stream_tid <= s_axis_write_data_tid;
                        stream_tdest <= s_axis_write_data_tdest;
                        stream_tuser <= s_axis_write_data_tuser;
                        stream_valid <= 1'b1;
                        stream_tready <= 0; // Handled in combinational
                    end else begin
                        // Middle beat
                        axi_wlast <= 1'b0;
                        w_byte_count <= s_axis_write_data_tkeep;
                        w_byte_remaining <= s_axis_write_data_tkeep;
                        r_byte_count <= s_axis_write_data_tkeep;
                        r_byte_remaining <= s_axis_write_data_tkeep;
                        
                        // Update stream
                        stream_tdata <= s_axis_write_data_tdata;
                        stream_tkeep <= s_axis_write_data_tkeep;
                        stream_last <= 1'b0;
                        stream_tid <= s_axis_write_data_tid;
                        stream_tdest <= s_axis_write_data_tdest;
                        stream_tuser <= s_axis_write_data_tuser;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end
                    
                    // Update AXI W data
                    axi_wdata <= s_axis_write_data_tdata;
                    axi_wstrb <= s_axis_write_data_tkeep;
                    
                    // Check if we need to send next beat
                    if (w_byte_remaining > 0) begin
                        if (m_axi_wvalid && m_axi_wready) begin
                            // Send beat
                            m_axi_wvalid <= 0;
                            w_byte_remaining <= w_byte_remaining - 1;
                            r_byte_remaining <= r_byte_remaining - 1;
                            axi_burst_count <= axi_burst_count + 1;
                            
                            // Check if burst is done
                            if (axi_burst_count >= axi_len) begin
                                state <= B_WAIT;
                            end
                        end
                    end else begin
                        // Burst done, wait for response
                        state <= B_WAIT;
                    end
                end
            end 
            else if (state == B_WAIT) begin
                if (m_axi_bvalid && m_axi_bready) begin
                    state <= AR_PREPARE;
                    m_axi_bready <= 0;
                    axi_addr <= current_addr + (axi_burst_count * 8); // Simplified address update
                    axi_len <= 0;
                    axi_size <= 0;
                    axi_burst <= 2'b01;
                    axi_burst_type <= 2'b01;
                    axi_burst_remaining <= current_len - axi_burst_count;
                    axi_id <= current_id;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == AR_PREPARE) begin
                if (m_axi_arvalid && m_axi_arready) begin
                    state <= R_PREPARE;
                    m_axi_arvalid <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == R_PREPARE) begin
                if (read_enable) begin
                    state <= R_WAIT;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == R_WAIT) begin
                if (m_axi_rvalid && m_axi_rready) begin
                    // Process data
                    if (m_axi_rlast) begin
                        // Last beat
                        r_byte_count <= m_axi_rlast ? 8'd1 : 0; // Simplified
                        r_byte_remaining <= r_byte_remaining - 1;
                        
                        // Update stream
                        stream_tdata <= m_axi_rdata;
                        stream_tkeep <= 8'd1; // Simplified keep
                        stream_last <= 1'b1;
                        stream_tid <= current_id;
                        stream_tdest <= current_dest;
                        stream_tuser <= current_user;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end else begin
                        // Middle beat
                        r_byte_count <= 0;
                        r_byte_remaining <= r_byte_remaining - 1;
                        
                        // Update stream
                        stream_tdata <= m_axi_rdata;
                        stream_tkeep <= 8'd1;
                        stream_last <= 1'b0;
                        stream_tid <= current_id;
                        stream_tdest <= current_dest;
                        stream_tuser <= current_user;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end
                    
                    // Check if burst is done
                    if (r_byte_remaining == 0) begin
                        state <= DONE;
                        status_tag <= current_tag;
                        status_len <= current_len;
                        status_id <= current_id;
                        status_dest <= current_dest;
                        status_user <= current_user;
                        status_error <= 0;
                        status_valid <= 1'b1;
                    end
                end
            end 
            else if (state == DONE) begin
                // Idle
                if (m_axis_read_data_tready && stream_valid) begin
                    // Send data
                    m_axis_read_data_tvalid <= 1'b1;
                    m_axis_read_data_tdata <= stream_tdata;
                    m_axis_read_data_tkeep <= stream_tkeep;
                    m_axis_read_data_tlast <= stream_last;
                    m_axis_read_data_tid <= stream_tid;
                    m_axis_read_data_tdest <= stream_tdest;
                    m_axis_read_data_tuser <= stream_tuser;
                    stream_valid <= 0;
                    stream_tready <= 1'b1;
                end else begin
                    m_axis_read_data_tvalid <= 0;
                    stream_tready <= 1'b1;
                end
            end
            
            // --------------------------------------------------------------------
            // Write Path State Machine
            // --------------------------------------------------------------------
            if (state == IDLE) begin
                if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                    state <= AW_PREPARE;
                    write_addr <= s_axis_write_desc_addr;
                    write_len <= s_axis_write_desc_len;
                    write_tag <= s_axis_write_desc_tag;
                    status_tag <= s_axis_write_desc_tag;
                    status_len <= s_axis_write_desc_len;
                    status_id <= s_axis_write_desc_id;
                    status_dest <= s_axis_write_desc_dest;
                    status_user <= s_axis_write_desc_user;
                    axi_len <= 0;
                    axi_size <= 0;
                    axi_burst <= 2'b01;
                    axi_burst_type <= 2'b01;
                    axi_burst_remaining <= s_axis_write_desc_len;
                    axi_addr <= s_axis_write_desc_addr;
                    axi_id <= s_axis_write_desc_id;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == AW_PREPARE) begin
                if (m_axi_awvalid && m_axi_awready) begin
                    state <= W_PREPARE;
                    axi_awvalid <= 0;
                    axi_burst_count <= 0;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == W_PREPARE) begin
                if (write_enable && !write_abort_flag) begin
                    state <= W_SEND;
                    axi_wdata <= 0;
                    axi_wstrb <= 0;
                    axi_wlast <= 0;
                    w_byte_count <= 0;
                    w_byte_remaining <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == W_SEND) begin
                if (s_axis_write_data_tvalid && s_axis_write_data_tready) begin
                    // Process data
                    if (s_axis_write_data_tlast) begin
                        // Last beat
                        axi_wlast <= 1'b1;
                        w_byte_count <= s_axis_write_data_tkeep;
                        w_byte_remaining <= s_axis_write_data_tkeep;
                        r_byte_count <= s_axis_write_data_tkeep;
                        r_byte_remaining <= s_axis_write_data_tkeep;
                        
                        // Update stream
                        stream_tdata <= s_axis_write_data_tdata;
                        stream_tkeep <= s_axis_write_data_tkeep;
                        stream_last <= 1'b1;
                        stream_tid <= s_axis_write_data_tid;
                        stream_tdest <= s_axis_write_data_tdest;
                        stream_tuser <= s_axis_write_data_tuser;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end else begin
                        // Middle beat
                        axi_wlast <= 1'b0;
                        w_byte_count <= s_axis_write_data_tkeep;
                        w_byte_remaining <= s_axis_write_data_tkeep;
                        r_byte_count <= s_axis_write_data_tkeep;
                        r_byte_remaining <= s_axis_write_data_tkeep;
                        
                        // Update stream
                        stream_tdata <= s_axis_write_data_tdata;
                        stream_tkeep <= s_axis_write_data_tkeep;
                        stream_last <= 1'b0;
                        stream_tid <= s_axis_write_data_tid;
                        stream_tdest <= s_axis_write_data_tdest;
                        stream_tuser <= s_axis_write_data_tuser;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end
                    
                    // Update AXI W data
                    axi_wdata <= s_axis_write_data_tdata;
                    axi_wstrb <= s_axis_write_data_tkeep;
                    
                    // Check if we need to send next beat
                    if (w_byte_remaining > 0) begin
                        if (m_axi_wvalid && m_axi_wready) begin
                            // Send beat
                            m_axi_wvalid <= 0;
                            w_byte_remaining <= w_byte_remaining - 1;
                            r_byte_remaining <= r_byte_remaining - 1;
                            axi_burst_count <= axi_burst_count + 1;
                            
                            // Check if burst is done
                            if (axi_burst_count >= axi_len) begin
                                state <= B_WAIT;
                            end
                        end
                    end else begin
                        // Burst done, wait for response
                        state <= B_WAIT;
                    end
                end
            end 
            else if (state == B_WAIT) begin
                if (m_axi_bvalid && m_axi_bready) begin
                    state <= AR_PREPARE;
                    m_axi_bready <= 0;
                    axi_addr <= write_addr + (axi_burst_count * 8);
                    axi_len <= 0;
                    axi_size <= 0;
                    axi_burst <= 2'b01;
                    axi_burst_type <= 2'b01;
                    axi_burst_remaining <= write_len - axi_burst_count;
                    axi_id <= write_tag;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == AR_PREPARE) begin
                if (m_axi_arvalid && m_axi_arready) begin
                    state <= R_PREPARE;
                    m_axi_arvalid <= 0;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == R_PREPARE) begin
                if (read_enable) begin
                    state <= R_WAIT;
                    r_byte_count <= 0;
                    r_byte_remaining <= 0;
                end
            end 
            else if (state == R_WAIT) begin
                if (m_axi_rvalid && m_axi_rready) begin
                    // Process data
                    if (m_axi_rlast) begin
                        // Last beat
                        r_byte_count <= m_axi_rlast ? 8'd1 : 0;
                        r_byte_remaining <= r_byte_remaining - 1;
                        
                        // Update stream
                        stream_tdata <= m_axi_rdata;
                        stream_tkeep <= 8'd1;
                        stream_last <= 1'b1;
                        stream_tid <= write_tag;
                        stream_tdest <= write_dest;
                        stream_tuser <= write_user;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end else begin
                        // Middle beat
                        r_byte_count <= 0;
                        r_byte_remaining <= r_byte_remaining - 1;
                        
                        // Update stream
                        stream_tdata <= m_axi_rdata;
                        stream_tkeep <= 8'd1;
                        stream_last <= 1'b0;
                        stream_tid <= write_tag;
                        stream_tdest <= write_dest;
                        stream_tuser <= write_user;
                        stream_valid <= 1'b1;
                        stream_tready <= 0;
                    end
                    
                    // Check if burst is done
                    if (r_byte_remaining == 0) begin
                        state <= DONE;
                        status_tag <= write_tag;
                        status_len <= write_len;