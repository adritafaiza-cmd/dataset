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

    // Internal parameters
    localparam LOG2_AXI_MAX_BURST_LEN = $clog2(AXI_MAX_BURST_LEN);
    localparam LOG2_AXI_DATA_WIDTH    = $clog2(AXI_DATA_WIDTH);
    localparam LOG2_AXI_STRB_WIDTH    = $clog2(AXI_STRB_WIDTH);

    // State encoding
    localparam IDLE = 3'd0;
    localparam AW_PREPARE = 3'd1;
    localparam AW_SEND = 3'd2;
    localparam W_PREPARE = 3'd3;
    localparam W_SEND = 3'd4;
    localparam B_WAIT = 3'd5;
    localparam AR_PREPARE = 3'd6;
    localparam AR_SEND = 3'd7;
    localparam R_PREPARE = 3'd8;
    localparam R_SEND = 3'd9;
    localparam R_WAIT = 3'd10;

    // Internal state registers
    reg [2:0] state;
    reg [TAG_WIDTH-1:0] current_tag;
    reg [LEN_WIDTH-1:0] current_len;
    reg [AXI_ADDR_WIDTH-1:0] current_addr;
    reg [AXI_ID_WIDTH-1:0] current_id;
    reg [AXIS_DEST_WIDTH-1:0] current_dest;
    reg [AXIS_USER_WIDTH-1:0] current_user;
    reg [3:0] current_error;
    
    // AXI Transaction State
    reg [7:0] axi_len;
    reg [2:0] axi_size;
    reg [1:0] axi_burst;
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
    reg stream_tready;
    
    // Write Data State
    reg [AXI_DATA_WIDTH-1:0] write_data;
    reg [AXIS_KEEP_WIDTH-1:0] write_keep;
    reg write_valid;
    reg write_last;
    reg write_tid;
    reg write_tdest;
    reg write_tuser;
    reg write_tready;
    
    // Control signals
    reg read_req;
    reg write_req;
    reg write_abort_flag;
    reg write_abort_ack;
    
    // Counters
    reg [7:0] burst_count;
    reg [LEN_WIDTH-1:0] len_left;
    reg [LEN_WIDTH-1:0] wdata_left;
    reg [LEN_WIDTH-1:0] rdata_left;
    
    // Status Output Registers
    reg [TAG_WIDTH-1:0] status_tag;
    reg [LEN_WIDTH-1:0] status_len;
    reg [AXIS_ID_WIDTH-1:0] status_id;
    reg [AXIS_DEST_WIDTH-1:0] status_dest;
    reg [AXIS_USER_WIDTH-1:0] status_user;
    reg [3:0] status_error;
    reg status_valid;

    // AXI Address Alignment
    wire addr_aligned = (ENABLE_UNALIGNED || (current_addr[LOG2_AXI_DATA_WIDTH-1:0] == 0));
    wire addr_unaligned = (!ENABLE_UNALIGNED && !addr_aligned);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_tag <= 0;
            current_len <= 0;
            current_addr <= 0;
            current_id <= 0;
            current_dest <= 0;
            current_user <= 0;
            current_error <= 0;
            axi_len <= 0;
            axi_size <= 0;
            axi_burst <= 0;
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
            stream_tready <= 0;
            write_data <= 0;
            write_keep <= 0;
            write_valid <= 0;
            write_last <= 0;
            write_tid <= 0;
            write_tdest <= 0;
            write_tuser <= 0;
            write_tready <= 0;
            read_req <= 0;
            write_req <= 0;
            write_abort_flag <= 0;
            write_abort_ack <= 0;
            burst_count <= 0;
            len_left <= 0;
            wdata_left <= 0;
            rdata_left <= 0;
            status_tag <= 0;
            status_len <= 0;
            status_id <= 0;
            status_dest <= 0;
            status_user <= 0;
            status_error <= 0;
            status_valid <= 0;
        end else begin
            // State Machine Logic
            case (state)
                IDLE: begin
                    s_axis_read_desc_ready <= 0;
                    s_axis_write_desc_ready <= 0;
                    m_axis_read_desc_status_valid <= 0;
                    m_axis_write_desc_status_valid <= 0;
                    m_axi_awvalid <= 0;
                    m_axi_wvalid <= 0;
                    m_axi_arvalid <= 0;
                    m_axi_bready <= 0;
                    m_axi_rready <= 0;
                    stream_tready <= 0;
                    write_tready <= 0;
                    
                    if (read_enable && s_axis_read_desc_valid) begin
                        current_tag <= s_axis_read_desc_tag;
                        current_len <= s_axis_read_desc_len;
                        current_addr <= s_axis_read_desc_addr;
                        current_id <= s_axis_read_desc_id;
                        current_dest <= s_axis_read_desc_dest;
                        current_user <= s_axis_read_desc_user;
                        current_error <= 0;
                        s_axis_read_desc_ready <= 1;
                        read_req <= 1;
                        state <= AW_PREPARE;
                    end else if (write_enable && s_axis_write_desc_valid) begin
                        current_tag <= s_axis_write_desc_tag;
                        current_len <= s_axis_write_desc_len;
                        current_addr <= s_axis_write_desc_addr;
                        current_id <= 0; // Write ID usually comes from stream or is ignored
                        current_dest <= s_axis_write_desc_dest;
                        current_user <= s_axis_write_desc_user;
                        current_error <= 0;
                        s_axis_write_desc_ready <= 1;
                        write_req <= 1;
                        state <= AW_PREPARE;
                    end
                end

                AW_PREPARE: begin
                    if (m_axi_awready) begin
                        axi_addr <= current_addr;
                        axi_id <= current_id;
                        axi_len <= current_len[7:0]; // Limit to 8 bits for AXI len
                        axi_size <= 3'd0; // Assume 8-bit transfer base
                        axi_burst <= 2'd0; // FIXED
                        axi_awvalid <= 1;
                        state <= AW_SEND;
                    end
                end

                AW_SEND: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        axi_awvalid <= 0;
                        state <= W_PREPARE;
                    end
                end

                W_PREPARE: begin
                    if (write_req) begin
                        write_data <= s_axis_write_data_tdata;
                        write_keep <= s_axis_write_data_tkeep;
                        write_valid <= s_axis_write_data_tvalid;
                        write_last <= s_axis_write_data_tlast;
                        write_tid <= s_axis_write_data_tid;
                        write_tdest <= s_axis_write_data_tdest;
                        write_tuser <= s_axis_write_data_tuser;
                        write_tready <= 1;
                        wdata_left <= current_len;
                        state <= W_SEND;
                    end else if (m_axi_wready) begin
                        // If no data ready, wait for data
                        state <= W_SEND;
                    end
                end

                W_SEND: begin
                    if (write_valid && m_axi_wready) begin
                        m_axi_wdata <= write_data;
                        m_axi_wstrb <= write_keep;
                        m_axi_wlast <= write_last;
                        m_axi_wvalid <= 1;
                        write_valid <= 0;
                        write_tready <= 0;
                        
                        if (write_last) begin
                            state <= B_WAIT;
                        end else begin
                            state <= W_PREPARE;
                        end
                    end else if (write_valid) begin
                        // Data valid but not ready
                        state <= W_PREPARE;
                    end
                end

                B_WAIT: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 0;
                        if (write_abort_flag) begin
                            // Handle abort if needed, for now just finish
                            status_tag <= current_tag;
                            status_len <= wdata_left;
                            status_id <= current_id;
                            status_dest <= current_dest;
                            status_user <= current_user;
                            status_error <= 4'd0;
                            status_valid <= 1;
                            state <= IDLE;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                AR_PREPARE: begin
                    if (read_req) begin
                        axi_addr <= current_addr;
                        axi_id <= current_id;
                        axi_len <= current_len[7:0];
                        axi_size <= 3'd0;
                        axi_burst <= 2'd0;
                        axi_arvalid <= 1;
                        state <= AR_SEND;
                    end
                end

                AR_SEND: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        axi_arvalid <= 0;
                        state <= R_PREPARE;
                    end
                end

                R_PREPARE: begin
                    if (read_req) begin
                        rdata_left <= current_len;
                        state <= R_SEND;
                    end else if (m_axi_rready) begin
                        state <= R_SEND;
                    end
                end

                R_SEND: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 0;
                        if (rdata_left > 0) begin
                            state <= R_PREPARE;
                        end else begin
                            status_tag <= current_tag;
                            status_len <= rdata_left;
                            status_id <= current_id;
                            status_dest <= current_dest;
                            status_user <= current_user;
                            status_error <= 4'd0;
                            status_valid <= 1;
                            state <= IDLE;
                        end
                    end
                end

                R_WAIT: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 0;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
            
            // Handle Write Abort
            if (write_abort && write_req) begin
                write_abort_flag <= 1;
                write_abort_ack <= 1;
                // Force error status
                status_tag <= current_tag;
                status_len <= wdata_left;
                status_id <= current_id;
                status_dest <= current_dest;
                status_user <= current_user;
                status_error <= 4'd1; // Abort Error
                status_valid <= 1;
                write_abort_flag <= 0;
                write_abort_ack <= 0;
                state <= IDLE;
            end
        end
    end

    // AXI Master Interface Logic
    assign m_axi_awid = axi_id;
    assign m_axi_awaddr = axi_addr;
    assign m_axi_awlen = axi_len;
    assign m_axi_awsize = axi_size;
    assign m_axi_awburst = axi_burst;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'd0;
    assign m_axi_awprot = 3'd0;
    assign m_axi_awvalid = axi_awvalid;
    assign m_axi_awready = m_axi_awready;

    assign m_axi_wdata = axi_wdata;
    assign m_axi_wstrb = axi_wstrb;
    assign m_axi_wlast = axi_wlast;
    assign m_axi_wvalid = axi_wvalid;
    assign m_axi_wready = m_axi_wready;
    assign m_axi_bid = m_axi_bid;
    assign m_axi_bresp = m_axi_bresp;
    assign m_axi_bvalid = m_axi_bvalid;
    assign m_axi_bready = axi_bready;

    assign m_axi_arid = axi_id;
    assign m_axi_araddr = axi_addr;
    assign m_axi_arlen = axi_len;
    assign m_axi_arsize = axi_size;
    assign m_axi_arburst = axi_burst;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'd0;
    assign m_axi_arprot = 3'd0;
    assign m_axi_arvalid = axi_arvalid;
    assign m_axi_arready = m_axi_arready;
    assign m_axi_rid = m_axi_rid;
    assign m_axi_rdata = m_axi_rdata;
    assign m_axi_rresp = m_axi_rresp;
    assign m_axi_rlast = m_axi_rlast;
    assign m_axi_rvalid = m_axi_rvalid;
    assign m_axi_rready = axi_rready;

    // Stream Read Data Output Logic
    assign m_axis_read_data_tdata = m_axi_rdata;
    assign m_axis_read_data_tkeep = AXIS_KEEP_ENABLE ? {AXIS_KEEP_WIDTH{1'b1}} : 1'b1;
    assign m_axis_read_data_tvalid = m_axi_rvalid && (rdata_left > 0);
    assign m_axis_read_data_tlast = (rdata_left == 1);
    assign m_axis_read_data_tid = current_id;
    assign m_axis_read_data_tdest = current_dest;
    assign m_axis_read_data_tuser = current_user;
    assign stream_tready = m_axis_read_data_tready;

    // Stream Write Data Input Logic
    assign s_axis_write_data_tready = write_tready;
    assign write_data = s_axis_write_data_tdata;
    assign write_keep = s_axis_write_data_tkeep;
    assign write_valid = s_axis_write_data_tvalid;
    assign write_last = s_axis_write_data_tlast;
    assign write_tid = s_axis_write_data_tid;
    assign write_tdest = s_axis_write_data_tdest;
    assign write_tuser = s_axis_write_data_tuser;

    // Status Outputs
    assign m_axis_read_desc_status_tag = status_tag;
    assign m_axis_read_desc_status_error = status_error;
    assign m_axis_read_desc_status_valid = status_valid;

    assign m_axis_write_desc_status_len = status_len;
    assign m_axis_write_desc_status_tag = status_tag;
    assign m_axis_write_desc_status_id = status_id;
    assign m_axis_write_desc_status_dest = status_dest;
    assign m_axis_write_desc_status_user = status_user;
    assign m_axis_write_desc_status_error = status_error;
    assign m_axis_write_desc_status_valid = status_valid;

endmodule
```<|im_end|>
